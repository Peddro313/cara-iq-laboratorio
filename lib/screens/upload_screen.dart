import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../providers/analysis_providers.dart';

class UploadScreen extends ConsumerStatefulWidget {
  const UploadScreen({super.key});

  @override
  ConsumerState<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends ConsumerState<UploadScreen> {
  XFile? _frontPhoto;
  XFile? _sidePhoto;
  bool _isAnalyzing = false;
  String _statusText = '';
  final _picker = ImagePicker();

  Future<void> _pickImage(bool isFront) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
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

    setState(() {
      _isAnalyzing = true;
      _statusText = 'Detecting face…';
    });

    try {
      final runner = ref.read(runPhotoAnalysisProvider);
      final result = await runner(
        frontPhotoPath: _frontPhoto!.path,
        sidePhotoPath: _sidePhoto!.path,
      );

      if (!mounted) return;
      context.go('/result/${result.id}');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Analysis failed: $e'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isAnalyzing = false;
          _statusText = '';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final canAnalyze =
        _frontPhoto != null && _sidePhoto != null && !_isAnalyzing;

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
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'For best results\n'
                  '• Neutral expression, mouth closed\n'
                  '• Good, even lighting\n'
                  '• Camera at eye level\n'
                  '• Front: looking straight at camera\n'
                  '• Side: true profile (90°)',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        height: 1.45,
                      ),
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: _PhotoSlot(
                        label: 'Front',
                        photo: _frontPhoto,
                        onTap: _isAnalyzing ? null : () => _pickImage(true),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _PhotoSlot(
                        label: 'Side Profile',
                        photo: _sidePhoto,
                        onTap: _isAnalyzing ? null : () => _pickImage(false),
                      ),
                    ),
                  ],
                ),
              ),
              if (_statusText.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  _statusText,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: canAnalyze ? _runAnalysis : null,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                ),
                child: _isAnalyzing
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
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
  final VoidCallback? onTap;

  const _PhotoSlot({
    required this.label,
    required this.photo,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasPhoto = photo != null;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          border: Border.all(
            color: hasPhoto
                ? Theme.of(context).colorScheme.primary
                : Colors.grey.shade300,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(16),
          color: Colors.grey.shade50,
        ),
        child: hasPhoto
            ? ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.file(
                  File(photo!.path),
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                ),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_a_photo, size: 40, color: Colors.grey[400]),
                  const SizedBox(height: 8),
                  Text(label, style: TextStyle(color: Colors.grey[600])),
                ],
              ),
      ),
    );
  }
}
