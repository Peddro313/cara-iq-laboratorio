import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../theme/app_theme.dart';

class UploadScreen extends ConsumerStatefulWidget {
  const UploadScreen({super.key});

  @override
  ConsumerState<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends ConsumerState<UploadScreen> {
  XFile? _frontPhoto;
  XFile? _sidePhoto;
  final _picker = ImagePicker();

  Future<void> _pickImage(bool isFront) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Take photo'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Gallery'),
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
    if (file == null) return;
    setState(() {
      if (isFront) {
        _frontPhoto = file;
      } else {
        _sidePhoto = file;
      }
    });
  }

  void _analyze() {
    if (_frontPhoto == null || _sidePhoto == null) return;
    context.push('/analyzing', extra: {
      'front': _frontPhoto!.path,
      'side': _sidePhoto!.path,
    });
  }

  @override
  Widget build(BuildContext context) {
    final canAnalyze = _frontPhoto != null && _sidePhoto != null;

    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(title: const Text('Upload photos')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.surface2,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.border),
                ),
                child: const Text(
                  'Neutral face, even light, eye-level camera.\n'
                  'Front: straight on. Side: true 90° profile.',
                  style: TextStyle(color: AppTheme.textMuted, height: 1.45),
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: _Slot(
                        label: 'Front',
                        photo: _frontPhoto,
                        onTap: () => _pickImage(true),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _Slot(
                        label: 'Side',
                        photo: _sidePhoto,
                        onTap: () => _pickImage(false),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: canAnalyze ? _analyze : null,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(54),
                ),
                child: const Text('Analyze face'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Slot extends StatelessWidget {
  final String label;
  final XFile? photo;
  final VoidCallback onTap;

  const _Slot({required this.label, required this.photo, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final has = photo != null;
    return Material(
      color: AppTheme.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: has ? AppTheme.primary : AppTheme.border,
              width: 2,
            ),
          ),
          child: has
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(16),
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
                    Icon(Icons.add_a_photo_outlined,
                        size: 36, color: AppTheme.textMuted),
                    const SizedBox(height: 8),
                    Text(label,
                        style: const TextStyle(color: AppTheme.textMuted)),
                  ],
                ),
        ),
      ),
    );
  }
}
