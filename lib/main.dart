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
      title: 'ExifGone',
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

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ImagePicker _picker = ImagePicker();
  List<XFile> _selectedImages = [];
  bool _isProcessing = false;

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
          if (file is File && p.basename(file.path).startsWith('cleaned_')) {
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
        setState(() => _selectedImages = images);
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

  Future<void> _cleanAndShare() async {
    if (_selectedImages.isEmpty) return;
    setState(() => _isProcessing = true);

    try {
      final l10n = AppLocalizations.of(context)!;
      final Directory tempDir = await getTemporaryDirectory();
      final List<XFile> cleanedFiles = [];

      for (var xFile in _selectedImages) {
        final String inputPath = xFile.path;
        final String fileName = 'cleaned_${DateTime.now().millisecondsSinceEpoch}_${p.basename(inputPath)}';
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
              const SizedBox(height: 48),
              
              Expanded(
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
                  child: _selectedImages.isNotEmpty
                      ? Stack(
                          children: [
                            PageView.builder(
                              itemCount: _selectedImages.length,
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
                                onPressed: () => setState(() => _selectedImages = []),
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
              
              const SizedBox(height: 32),
              
              if (_selectedImages.isEmpty)
                SizedBox(
                  width: double.infinity,
                  height: 64,
                  child: FilledButton.icon(
                    onPressed: _pickImages,
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
                        onPressed: _isProcessing ? null : _cleanAndShare,
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
                      onPressed: _pickImages,
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
}

class Position8 extends StatelessWidget {
  final double? top, right;
  final Widget child;
  const Position8({super.key, this.top, this.right, required this.child});
  @override
  Widget build(BuildContext context) => Positioned(top: top, right: right, child: child);
}
