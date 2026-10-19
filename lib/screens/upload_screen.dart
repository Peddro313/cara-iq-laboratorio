import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../services/scoring_engine.dart';
import '../models/analysis.dart';

class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  XFile? _frontPhoto;
  XFile? _sidePhoto;
  bool _isAnalyzing = false;
  final _picker = ImagePicker();

  Future<void> _pickImage(bool isFront) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    final file = await _picker.pickImage(
      source: source,
      maxWidth: 1600,
      imageQuality: 90,
    );

    if (file != null) {
      setState(() {
        if (isFront) {
          _frontPhoto = file;
        } else {
          _sidePhoto = file;
        }
      });
    }
  }

  Future<void> _runAnalysis() async {
    if (_frontPhoto == null || _sidePhoto == null) return;

    setState(() => _isAnalyzing = true);

    // Simulate landmark detection delay (real MediaPipe integration comes next)
    await Future.delayed(const Duration(seconds: 2));

    // Placeholder landmarks for now
    final dummyLandmarks = List.generate(
      20,
      (i) => FacialLandmark(index: i, x: 0.5, y: 0.5, z: 0.0),
    );

    final result = ScoringEngine.analyze(
      frontLandmarks: dummyLandmarks,
      sideLandmarks: dummyLandmarks,
      frontPhotoPath: _frontPhoto!.path,
      sidePhotoPath: _sidePhoto!.path,
    );

    if (!mounted) return;

    setState(() => _isAnalyzing = false);
    context.go('/result/${result.id}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Photos'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'For best results',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                '• Neutral expression, mouth closed\n'
                '• Good, even lighting\n'
                '• Camera at eye level\n'
                '• Front: looking straight at camera\n'
                '• Side: true profile (90°)',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[700],
                      height: 1.5,
                    ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: _PhotoSlot(
                        label: 'Front',
                        photo: _frontPhoto,
                        onTap: () => _pickImage(true),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _PhotoSlot(
                        label: 'Side Profile',
                        photo: _sidePhoto,
                        onTap: () => _pickImage(false),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: (_frontPhoto != null && _sidePhoto != null && !_isAnalyzing)
                    ? _runAnalysis
                    : null,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                ),
                child: _isAnalyzing
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Analyze Face'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PhotoSlot extends StatelessWidget {
  final String label;
  final XFile? photo;
  final VoidCallback onTap;

  const _PhotoSlot({
    required this.label,
    required this.photo,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: photo != null
                ? Theme.of(context).colorScheme.primary
                : Colors.grey.shade300,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(16),
          color: Colors.grey.shade50,
        ),
        child: photo == null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_a_photo, size: 40, color: Colors.grey[400]),
                  const SizedBox(height: 8),
                  Text(label, style: TextStyle(color: Colors.grey[600])),
                ],
              )
            : ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.file(
                  File(photo!.path),
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                ),
              ),
      ),
    );
  }
}
