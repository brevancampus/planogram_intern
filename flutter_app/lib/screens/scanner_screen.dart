import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import '../providers/validation_provider.dart';
import '../services/api_service.dart';
import 'result_screen.dart';

/// Scanner Screen - Multi-Photo Shelf Audit
/// 
/// Flow:
/// 1. User takes/selects multiple photos (kiri, tengah, kanan)
/// 2. Shows thumbnail grid of selected photos
/// 3. User clicks "Analyze" button
/// 4. Shows progress indicator while uploading & processing
/// 5. Navigates to ResultScreen ketika selesai
class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  final List<File> _selectedImages = [];
  final ImagePicker _imagePicker = ImagePicker();
  bool _isAnalyzing = false;
  int _currentPhotoProcessing = 0;

  /// Add image menggunakan image_picker
  /// 
  /// Optimization:
  /// - imageQuality: 50 untuk reduce file size tanpa merusak YOLO accuracy
  /// - maxWidth/maxHeight: kontrol resolution
  Future<void> _addImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        imageQuality: 50, // πŸ"Ή Compressed to 50% quality
        maxWidth: 1280,
        maxHeight: 720,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImages.add(File(pickedFile.path));
        });

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Foto ditambahkan'),
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Remove image dari list
  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Foto dihapus'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  /// Analyze all selected photos
  /// 
  /// Flow:
  /// 1. Validate images aren't empty
  /// 2. Show progress dialog
  /// 3. Call validateMultiple() with progress callback
  /// 4. Navigate to ResultScreen
  Future<void> _analyzePhotos() async {
    if (_selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih minimal 1 foto untuk audit'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isAnalyzing = true;
      _currentPhotoProcessing = 0;
    });

    try {
      final provider = context.read<ValidationProvider>();
      final apiService = context.read<ApiService>();

      // Call validateMultiple dengan progress tracking
      await apiService.validateMultiple(
        _selectedImages,
        onProgress: (current, total) {
          setState(() {
            _currentPhotoProcessing = current;
          });
        },
      ).then((response) {
        // Save response ke provider
        provider.setLastResult(response);

        // Navigate ke ResultScreen
        if (mounted) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const ResultScreen(),
            ),
          );
        }
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Audit gagal: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isAnalyzing = false;
          _currentPhotoProcessing = 0;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shelf Audit Scanner'),
        elevation: 0,
      ),
      body: Stack(
        children: [
          // Main content
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header card with instructions
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Multi-Photo Shelf Audit',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Ambil beberapa foto bagian rak (kiri, tengah, kanan) untuk validasi keseluruhan',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blue.shade200),
                          ),
                          child: const Text(
                            'Tips: Ambil foto minimal 2 bagian rak dengan overlap kecil untuk hasil akurat',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Add photo buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isAnalyzing
                            ? null
                            : () => _addImage(ImageSource.camera),
                        icon: const Icon(Icons.camera_alt),
                        label: const Text('Kamera'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isAnalyzing
                            ? null
                            : () => _addImage(ImageSource.gallery),
                        icon: const Icon(Icons.photo_library),
                        label: const Text('Galeri'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Photos count badge
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _selectedImages.isEmpty
                              ? Colors.red.shade50
                              : Colors.green.shade50,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _selectedImages.isEmpty
                                ? Colors.red.shade200
                                : Colors.green.shade200,
                          ),
                        ),
                        child: Text(
                          'Foto: ${_selectedImages.length}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _selectedImages.isEmpty
                                ? Colors.red
                                : Colors.green,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Photos grid
                if (_selectedImages.isNotEmpty) ...[
                  const Text(
                    'Preview Foto',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.0,
                    ),
                    itemCount: _selectedImages.length,
                    itemBuilder: (context, index) {
                      return Stack(
                        children: [
                          // Image thumbnail
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.grey.shade300,
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                _selectedImages[index],
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          // Index badge
                          Positioned(
                            top: 4,
                            left: 4,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blue,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${index + 1}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                          // Remove button
                          Positioned(
                            bottom: 4,
                            right: 4,
                            child: GestureDetector(
                              onTap: _isAnalyzing
                                  ? null
                                  : () => _removeImage(index),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                ],

                // Analyze button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isAnalyzing ? null : _analyzePhotos,
                    icon: const Icon(Icons.analytics_outlined),
                    label: const Text('Analisis Sekarang'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: Colors.green,
                      disabledBackgroundColor: Colors.grey.shade300,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),

          // Loading overlay dengan progress
          if (_isAnalyzing)
            Container(
              color: Colors.black.withValues(alpha: 0.6),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Progress indicator
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation(Colors.green),
                            strokeWidth: 3,
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'Menganalisis foto ke-$_currentPhotoProcessing',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'dari ${_selectedImages.length} foto',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Progress bar
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: _currentPhotoProcessing / _selectedImages.length,
                              minHeight: 6,
                              backgroundColor: Colors.grey.shade200,
                              valueColor: const AlwaysStoppedAnimation(
                                Colors.green,
                              ),
                            ),
                          ),
                        ],
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
