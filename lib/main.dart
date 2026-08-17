import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:share_plus/share_plus.dart';

void main() {
  runApp(const ExifGoneApp());
}

class ExifGoneApp extends StatelessWidget {
  const ExifGoneApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ExifGone',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
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
  XFile? _selectedImage;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _clearCache(); // Clean up old files on startup
  }

  Future<void> _clearCache() async {
    try {
      final Directory tempDir = await getTemporaryDirectory();
      if (await tempDir.exists()) {
        final List<FileSystemEntity> files = tempDir.listSync();
        for (var file in files) {
          if (file is File && p.basename(file.path).startsWith('cleaned_')) {
            await file.delete();
            debugPrint('Deleted cached file: ${file.path}');
          }
        }
      }
    } catch (e) {
      debugPrint('Error clearing cache: $e');
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          _selectedImage = image;
        });
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to pick image')),
        );
      }
    }
  }

  Future<void> _cleanAndShare() async {
    if (_selectedImage == null) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      final String inputPath = _selectedImage!.path;
      final Directory tempDir = await getTemporaryDirectory();
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String fileName = 'cleaned_$timestamp.jpg';
      final String outputPath = p.join(tempDir.path, fileName);

      // Run image stripping in a background isolate
      await compute(_stripExifTask, {
        'inputPath': inputPath,
        'outputPath': outputPath,
      });

      if (mounted) {
        // Share the cleaned image
        await Share.shareXFiles([XFile(outputPath)], text: 'Shared via ExifGone');
        // Optional: Clear cache after share to keep it extra clean
        _clearCache();
      }
    } catch (e) {
      debugPrint('Error processing image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  // Top-level function or static method required for compute
  static void _stripExifTask(Map<String, String> paths) {
    final String inputPath = paths['inputPath']!;
    final String outputPath = paths['outputPath']!;

    final File inputFile = File(inputPath);
    final Uint8List bytes = inputFile.readAsBytesSync();

    // Decode the image (this discards EXIF in the Image object)
    final img.Image? image = img.decodeImage(bytes);

    if (image == null) {
      throw Exception('Could not decode image');
    }

    // Re-encode to JPG (this creates a clean file without original metadata)
    final Uint8List cleanBytes = Uint8List.fromList(img.encodeJpg(image, quality: 90));

    // Save the clean image to the temporary directory
    final File outputFile = File(outputPath);
    outputFile.writeAsBytesSync(cleanBytes);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            title: const Text(
              'ExifGone',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            centerTitle: true,
            backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          ),
          SliverFillRemaining(
            hasScrollBody: false,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Image Preview Container
                  Container(
                    width: double.infinity,
                    height: 300,
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outlineVariant,
                        width: 2,
                      ),
                    ),
                    child: _selectedImage != null
                        ? Image.file(
                            File(_selectedImage!.path),
                            fit: BoxFit.cover,
                          )
                        : Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.image_outlined,
                                  size: 64,
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No Image Selected',
                                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                                      ),
                                ),
                              ],
                            ),
                          ),
                  ),
                  const SizedBox(height: 32),
                  // Select Photo Button
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.tonalIcon(
                      onPressed: _pickImage,
                      icon: const Icon(Icons.photo_library),
                      label: const Text('Select Photo'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Clean & Share Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _selectedImage == null || _isProcessing
                          ? null
                          : _cleanAndShare,
                      icon: _isProcessing
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.grey,
                              ),
                            )
                          : const Icon(Icons.auto_fix_high),
                      label: Text(_isProcessing ? 'Processing...' : 'Clean & Share'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                  const Spacer(),
                  const Text(
                    'Your photos stay local. Your privacy matters.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
