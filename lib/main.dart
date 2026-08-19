import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:share_plus/share_plus.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:exif/exif.dart';
import 'package:flutter/services.dart';
import 'l10n/app_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ExifGoneApp());
}

class ExifGoneApp extends StatefulWidget {
  const ExifGoneApp({super.key});

  static void setLocale(BuildContext context, Locale? newLocale) {
    _ExifGoneAppState? state = context.findAncestorStateOfType<_ExifGoneAppState>();
    state?.setLocale(newLocale);
  }

  @override
  State<ExifGoneApp> createState() => _ExifGoneAppState();
}

class _ExifGoneAppState extends State<ExifGoneApp> {
  Locale? _locale;

  @override
  void initState() {
    super.initState();
    _loadLocale();
  }

  void _loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final String? languageCode = prefs.getString('language_code');
    if (languageCode != null && languageCode.isNotEmpty) {
      setState(() {
        _locale = Locale(languageCode);
      });
    }
  }

  void setLocale(Locale? locale) async {
    final prefs = await SharedPreferences.getInstance();
    if (locale == null) {
      await prefs.remove('language_code');
    } else {
      await prefs.setString('language_code', locale.languageCode);
    }
    setState(() {
      _locale = locale;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Exifgone',
      debugShowCheckedModeBanner: false,
      locale: _locale,
      localizationsDelegates: [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'), // English
        Locale('tr'), // Turkish
        Locale('de'), // German
      ],
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6366F1),
          brightness: Brightness.light,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6366F1),
          brightness: Brightness.dark,
          surface: const Color(0xFF0F172A),
        ),
      ),
      themeMode: ThemeMode.system,
      home: const HomePage(),
    );
  }
}

class PrivacyAnalysis {
  final bool hasGps;
  final String? deviceModel;
  final bool hasTimestamp;
  final int score;

  PrivacyAnalysis({
    required this.hasGps,
    this.deviceModel,
    required this.hasTimestamp,
    required this.score,
  });
}

class SummaryAnalysis {
  final int totalPhotos;
  final int gpsCount;
  final int deviceCount;
  final int timeCount;
  final int averageScore;

  SummaryAnalysis({
    required this.totalPhotos,
    required this.gpsCount,
    required this.deviceCount,
    required this.timeCount,
    required this.averageScore,
  });
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ImagePicker _picker = ImagePicker();
  List<XFile> _selectedImages = [];
  bool _isProcessing = false;
  bool _isPressed = false;
  PrivacyAnalysis? _currentAnalysis;
  SummaryAnalysis? _summaryAnalysis;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _clearCache();
  }

  Future<void> _clearCache() async {
    try {
      final Directory tempDir = await getTemporaryDirectory();
      if (await tempDir.exists()) {
        final List<FileSystemEntity> files = tempDir.listSync();
        for (var file in files) {
          if (file is File && p.basename(file.path).startsWith('anon_')) {
            await file.delete();
          }
        }
      }
    } catch (e) {
      debugPrint('Error clearing cache: $e');
    }
  }

  Future<void> _pickImages() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage();
      if (images.isNotEmpty) {
        setState(() {
          _selectedImages = images;
          _currentIndex = 0;
        });
        if (images.length > 1) {
          _analyzeSummary(images);
        } else {
          _analyzeImage(images[0]);
        }
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.error(e.toString())), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _analyzeImage(XFile xFile) async {
    final bytes = await xFile.readAsBytes();
    final data = await readExifFromBytes(bytes);

    bool hasGps = data.containsKey('GPS GPSLatitude');
    String? device = data['Image Model']?.toString() ?? data['Image Make']?.toString();
    bool hasTimestamp = data.containsKey('Image DateTime') || data.containsKey('EXIF DateTimeOriginal');

    int score = 0;
    if (hasGps) score += 60;
    if (device != null) score += 25;
    if (hasTimestamp) score += 15;
    if (score > 100) score = 100;

    setState(() {
      _summaryAnalysis = null;
      _currentAnalysis = PrivacyAnalysis(
        hasGps: hasGps,
        deviceModel: device,
        hasTimestamp: hasTimestamp,
        score: score,
      );
    });
  }

  Future<void> _analyzeSummary(List<XFile> images) async {
    int totalGps = 0;
    int totalDevices = 0;
    int totalTimes = 0;
    int totalScore = 0;

    for (var image in images) {
      final bytes = await image.readAsBytes();
      final data = await readExifFromBytes(bytes);

      bool hasGps = data.containsKey('GPS GPSLatitude');
      bool hasDevice = data.containsKey('Image Model') || data.containsKey('Image Make');
      bool hasTimestamp = data.containsKey('Image DateTime') || data.containsKey('EXIF DateTimeOriginal');

      if (hasGps) totalGps++;
      if (hasDevice) totalDevices++;
      if (hasTimestamp) totalTimes++;

      int score = 0;
      if (hasGps) score += 60;
      if (hasDevice) score += 25;
      if (hasTimestamp) score += 15;
      totalScore += score;
    }

    setState(() {
      _currentAnalysis = null;
      _summaryAnalysis = SummaryAnalysis(
        totalPhotos: images.length,
        gpsCount: totalGps,
        deviceCount: totalDevices,
        timeCount: totalTimes,
        averageScore: (totalScore / images.length).round(),
      );
    });
  }

  Future<void> _cleanAndShare() async {
    if (_selectedImages.isEmpty) return;
    setState(() => _isProcessing = true);

    try {
      final l10n = AppLocalizations.of(context)!;
      final Directory tempDir = await getTemporaryDirectory();
      final List<XFile> cleanedFiles = [];
      const uuid = Uuid();

      for (var xFile in _selectedImages) {
        final String inputPath = xFile.path;
        final String randomId = uuid.v4().split('-').first;
        final String fileName = 'anon_$randomId.jpg';
        final String outputPath = p.join(tempDir.path, fileName);

        await compute(_stripExifTask, {'inputPath': inputPath, 'outputPath': outputPath});
        cleanedFiles.add(XFile(outputPath));
      }

      if (mounted) {
        await Share.shareXFiles(cleanedFiles, text: l10n.cleanedWith);
        _clearCache();
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.error(e.toString())), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  static void _stripExifTask(Map<String, String> paths) {
    final bytes = File(paths['inputPath']!).readAsBytesSync();
    final image = img.decodeImage(bytes);
    if (image == null) throw Exception('Resim çözülemedi');
    final cleanBytes = img.encodeJpg(image, quality: 90);
    File(paths['outputPath']!).writeAsBytesSync(cleanBytes);
  }

  void _showSettings() {
    final l10n = AppLocalizations.of(context)!;
    final currentLocale = Localizations.localeOf(context);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.settings,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              _buildLanguageOption(
                context,
                l10n.systemDefault,
                null,
                currentLocale.languageCode,
                isSystem: true,
              ),
              _buildLanguageOption(context, l10n.english, const Locale('en'), currentLocale.languageCode),
              _buildLanguageOption(context, l10n.turkish, const Locale('tr'), currentLocale.languageCode),
              _buildLanguageOption(context, l10n.german, const Locale('de'), currentLocale.languageCode),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageOption(
    BuildContext context,
    String title,
    Locale? locale,
    String currentCode, {
    bool isSystem = false,
  }) {
    final isSelected = isSystem 
        ? !AppLocalizations.supportedLocales.any((l) => l.languageCode == currentCode)
        : currentCode == locale?.languageCode;

    return ListTile(
      leading: Icon(
        isSystem ? Icons.brightness_auto : Icons.language,
        color: isSelected ? Theme.of(context).colorScheme.primary : null,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? Theme.of(context).colorScheme.primary : null,
        ),
      ),
      trailing: isSelected ? Icon(Icons.check_circle, color: Theme.of(context).colorScheme.primary) : null,
      onTap: () {
        ExifGoneApp.setLocale(context, locale);
        Navigator.pop(context);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  onPressed: _showSettings,
                  icon: const Icon(Icons.settings_outlined),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shield_rounded, size: 32, color: colorScheme.primary),
                  const SizedBox(width: 12),
                  Text(
                    l10n.appTitle,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                          letterSpacing: -1,
                          color: colorScheme.onSurface,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                l10n.subtitle,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 32),
              
              Expanded(
                child: AnimatedScale(
                  scale: _isPressed ? 0.96 : 1.0,
                  duration: const Duration(milliseconds: 100),
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceVariant.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: colorScheme.outlineVariant.withOpacity(0.5),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        splashColor: colorScheme.primary.withOpacity(0.2),
                        highlightColor: colorScheme.primary.withOpacity(0.1),
                        onTapDown: (_) => setState(() => _isPressed = true),
                        onTapCancel: () => setState(() => _isPressed = false),
                        onTap: () {
                          setState(() => _isPressed = false);
                          if (_selectedImages.isEmpty) {
                            HapticFeedback.mediumImpact();
                            _pickImages();
                          }
                        },
                        child: _selectedImages.isNotEmpty
                          ? Stack(
                              children: [
                                PageView.builder(
                                  itemCount: _selectedImages.length,
                                  onPageChanged: (index) {
                                    setState(() => _currentIndex = index);
                                    if (_selectedImages.length == 1) {
                                      _analyzeImage(_selectedImages[index]);
                                    }
                                  },
                                  itemBuilder: (context, index) {
                                    return Image.file(
                                      File(_selectedImages[index].path),
                                      fit: BoxFit.cover,
                                    );
                                  },
                                ),
                                Positioned(
                                  top: 12,
                                  right: 12,
                                  child: IconButton.filled(
                                    onPressed: () => setState(() {
                                      _selectedImages = [];
                                      _currentAnalysis = null;
                                      _summaryAnalysis = null;
                                    }),
                                    icon: const Icon(Icons.close),
                                    style: IconButton.styleFrom(
                                      backgroundColor: Colors.black54,
                                    ),
                                  ),
                                ),
                                if (_selectedImages.length > 1)
                                  Positioned(
                                    bottom: 12,
                                    left: 0,
                                    right: 0,
                                    child: Center(
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: Colors.black54,
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          l10n.photosSelected(_selectedImages.length),
                                          style: const TextStyle(color: Colors.white, fontSize: 12),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_photo_alternate_rounded,
                                    size: 80, color: colorScheme.primary.withOpacity(0.5)),
                                const SizedBox(height: 16),
                                Text(
                                  l10n.startBySelecting,
                                  style: TextStyle(
                                    color: colorScheme.onSurfaceVariant,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                      ),
                    ),
                  ),
                ),
              ),
              
              if (_summaryAnalysis != null) ...[
                const SizedBox(height: 24),
                _buildSummaryReport(context, l10n),
              ] else if (_currentAnalysis != null) ...[
                const SizedBox(height: 24),
                _buildAnalysisReport(context, l10n),
              ],
              
              const SizedBox(height: 32),
              
              if (_selectedImages.isEmpty)
                SizedBox(
                  width: double.infinity,
                  height: 64,
                  child: FilledButton.icon(
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                      _pickImages();
                    },
                    icon: const Icon(Icons.photo_library_rounded),
                    label: Text(l10n.selectPhoto, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    style: FilledButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                  ),
                )
              else
                Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: 64,
                      child: FilledButton.icon(
                        onPressed: _isProcessing ? null : () {
                          HapticFeedback.mediumImpact();
                          _cleanAndShare();
                        },
                        icon: _isProcessing 
                          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                          : const Icon(Icons.auto_fix_high_rounded),
                        label: Text(_isProcessing ? l10n.processing : l10n.cleanAndShare, 
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () {
                        HapticFeedback.mediumImpact();
                        _pickImages();
                      },
                      child: Text(l10n.selectAnother),
                    ),
                  ],
                ),
              
              const SizedBox(height: 24),
              Text(
                l10n.deviceLocal,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant.withOpacity(0.7),
                    ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryReport(BuildContext context, AppLocalizations l10n) {
    final summary = _summaryAnalysis!;
    final colorScheme = Theme.of(context).colorScheme;
    
    Color statusColor;
    if (summary.averageScore >= 70) {
      statusColor = const Color(0xFFEF4444);
    } else if (summary.averageScore >= 30) {
      statusColor = const Color(0xFFF59E0B);
    } else {
      statusColor = const Color(0xFF10B981);
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: statusColor.withOpacity(0.2), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.assessment_rounded, color: statusColor, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.summaryReport,
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        color: statusColor,
                        fontSize: 16,
                        letterSpacing: -0.5,
                      ),
                    ),
                    Text(
                      l10n.totalAnalysis(summary.totalPhotos),
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurface.withOpacity(0.5),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '%${summary.averageScore}',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      color: statusColor,
                      fontSize: 20,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12.0),
            child: Divider(height: 1, thickness: 0.5),
          ),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              _buildSummaryItem(Icons.location_on, l10n.totalGps(summary.gpsCount), statusColor),
              _buildSummaryItem(Icons.smartphone, l10n.totalDevices(summary.deviceCount), statusColor),
              _buildSummaryItem(Icons.access_time_filled, l10n.totalTimes(summary.timeCount), statusColor),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(IconData icon, String text, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color.withOpacity(0.7)),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(fontSize: 11, color: color.withOpacity(0.8), fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildAnalysisReport(BuildContext context, AppLocalizations l10n) {
    final analysis = _currentAnalysis!;
    final colorScheme = Theme.of(context).colorScheme;
    
    String statusLabel;
    Color statusColor;
    IconData statusIcon;

    if (analysis.score >= 70) {
      statusLabel = l10n.critical;
      statusColor = const Color(0xFFEF4444);
      statusIcon = Icons.gpp_maybe_rounded;
    } else if (analysis.score >= 30) {
      statusLabel = l10n.fair;
      statusColor = const Color(0xFFF59E0B);
      statusIcon = Icons.privacy_tip_rounded;
    } else {
      statusLabel = l10n.good;
      statusColor = const Color(0xFF10B981);
      statusIcon = Icons.verified_user_rounded;
    }

    List<String> details = [];
    if (analysis.hasGps) details.add(l10n.gpsFound);
    if (analysis.deviceModel != null) details.add(l10n.deviceFound(analysis.deviceModel!));
    if (analysis.hasTimestamp) details.add(l10n.timeFound);

    String detailText = details.isEmpty ? "" : l10n.foundInPhoto(details.join(", "));

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: statusColor.withOpacity(0.2), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(statusIcon, color: statusColor, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      statusLabel,
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        color: statusColor,
                        fontSize: 16,
                        letterSpacing: -0.5,
                      ),
                    ),
                    Text(
                      l10n.privacyReport,
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurface.withOpacity(0.5),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '%${analysis.score}',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      color: statusColor,
                      fontSize: 20,
                    ),
                  ),
                  const SizedBox(height: 4),
                  SizedBox(
                    width: 60,
                    height: 4,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value: analysis.score / 100,
                        backgroundColor: statusColor.withOpacity(0.2),
                        valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (detailText.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12.0),
              child: Divider(height: 1, thickness: 0.5),
            ),
            Text(
              detailText,
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color: colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class Position8 extends StatelessWidget {
  final double? top, right;
  final Widget child;
  const Position8({super.key, this.top, this.right, required this.child});
  @override
  Widget build(BuildContext context) => Positioned(top: top, right: right, child: child);
}
