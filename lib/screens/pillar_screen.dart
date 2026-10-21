import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/analysis.dart';
import '../providers/analysis_providers.dart';
import '../theme/app_theme.dart';
import '../utils/score_color.dart';

class PillarScreen extends ConsumerWidget {
  final String analysisId;
  final String pillarKey; // harmony | structure | dimorphism | features

  const PillarScreen({
    super.key,
    required this.analysisId,
    required this.pillarKey,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(analysisByIdProvider(analysisId));

    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(title: Text(_title(pillarKey))),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (result) {
          if (result == null) return const Center(child: Text('Not found'));
          final pillar = _pillar(result, pillarKey);
          final metrics = _metricsFor(pillarKey, result);
          final isSide = pillarKey == 'structure' || pillarKey == 'dimorphism';
          final path = isSide ? result.sidePhotoPath : result.frontPhotoPath;

          return LayoutBuilder(
            builder: (context, c) {
              final wide = c.maxWidth > 700;
              final photo = _photo(path);
              final panel = _panel(context, pillar, metrics);

              if (wide) {
                return Row(
                  children: [
                    Expanded(flex: 5, child: photo),
                    Expanded(flex: 6, child: panel),
                  ],
                );
              }
              return ListView(
                children: [
                  SizedBox(height: 280, child: photo),
                  panel,
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _photo(String? path) {
    return Container(
      color: AppTheme.surface,
      child: path != null && File(path).existsSync()
          ? Image.file(File(path), fit: BoxFit.cover)
          : const Center(
              child: Icon(Icons.person, size: 72, color: AppTheme.textMuted),
            ),
    );
  }

  Widget _panel(BuildContext context, PillarScore pillar, List<_Metric> metrics) {
    final c = scoreColor(pillar.score);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            pillar.score.toStringAsFixed(1),
            style: TextStyle(fontSize: 52, fontWeight: FontWeight.w700, color: c),
          ),
          Text(pillar.label, style: const TextStyle(fontSize: 18)),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: pillar.score / 10,
              minHeight: 10,
              backgroundColor: AppTheme.border,
              color: c,
            ),
          ),
          const SizedBox(height: 24),
          const Text('Metrics', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
          const SizedBox(height: 12),
          ...metrics.map((m) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Expanded(child: Text(m.label)),
                    if (m.raw != null)
                      Text(
                        m.raw!.toStringAsFixed(m.raw!.abs() > 20 ? 1 : 3),
                        style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                      ),
                    const SizedBox(width: 12),
                    Text(
                      m.score.toStringAsFixed(1),
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                        color: scoreColor(m.score),
                      ),
                    ),
                  ],
                ),
              )),
          if (pillar.strengths.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text('Strengths', style: TextStyle(fontWeight: FontWeight.w600)),
            ...pillar.strengths.map((s) => ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.check_circle, color: Colors.green, size: 18),
                  title: Text(s, style: const TextStyle(fontSize: 13)),
                )),
          ],
          if (pillar.improvements.isNotEmpty) ...[
            const SizedBox(height: 8),
            const Text('Improve', style: TextStyle(fontWeight: FontWeight.w600)),
            ...pillar.improvements.map((s) => ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.info_outline, color: Colors.orange.shade400, size: 18),
                  title: Text(s, style: const TextStyle(fontSize: 13)),
                )),
          ],
        ],
      ),
    );
  }

  String _title(String key) {
    switch (key) {
      case 'harmony':
        return 'Harmony';
      case 'structure':
        return 'Structure';
      case 'dimorphism':
        return 'Dimorphism';
      case 'features':
        return 'Features';
      default:
        return 'Pillar';
    }
  }

  PillarScore _pillar(AnalysisResult r, String key) {
    switch (key) {
      case 'structure':
        return r.structure;
      case 'dimorphism':
        return r.dimorphism;
      case 'features':
        return r.features;
      default:
        return r.harmony;
    }
  }

  List<_Metric> _metricsFor(String key, AnalysisResult r) {
    double scoreRatio(String k, double v) {
      const ideals = {
        'facial_thirds_upper': (0.30, 0.36),
        'facial_thirds_middle': (0.30, 0.36),
        'facial_thirds_lower': (0.30, 0.36),
        'eye_spacing': (0.90, 1.15),
        'nose_width_to_mouth': (0.65, 0.85),
        'jaw_to_cheek_width': (0.75, 0.95),
        'face_width_to_height': (0.70, 0.85),
        'jaw_angle': (115.0, 135.0),
        'canthal_tilt_left': (0.0, 8.0),
      };
      final range = ideals[k];
      if (range == null) return 6.0;
      final (min, max) = range;
      final mid = (min + max) / 2;
      final half = (max - min) / 2;
      if (v >= min && v <= max) {
        return 10 - ((v - mid).abs() / half) * 1.5;
      }
      final outside = v < min ? min - v : v - max;
      return (8 - (outside / half) * 3).clamp(1.0, 10.0);
    }

    Map<String, String> keys;
    switch (key) {
      case 'structure':
        keys = {
          'jaw_angle': 'Jaw angle',
          'jaw_to_cheek_width': 'Jaw / cheek width',
          'face_width_to_height': 'Width / height',
        };
        break;
      case 'dimorphism':
        keys = {
          'jaw_to_cheek_width': 'Jaw / cheek width',
          'jaw_angle': 'Jaw angle',
        };
        break;
      case 'features':
        keys = {};
        break;
      default:
        keys = {
          'facial_thirds_upper': 'Upper third',
          'facial_thirds_middle': 'Middle third',
          'facial_thirds_lower': 'Lower third',
          'eye_spacing': 'Eye spacing',
          'nose_width_to_mouth': 'Nose / mouth',
          'canthal_tilt_left': 'Canthal tilt',
        };
    }

    final list = <_Metric>[];
    for (final e in keys.entries) {
      final raw = r.ratios[e.key];
      if (raw == null) continue;
      list.add(_Metric(label: e.value, raw: raw, score: scoreRatio(e.key, raw)));
    }
    if (list.isEmpty) {
      list.add(_Metric(label: 'Pillar score', raw: null, score: _pillar(r, key).score));
    }
    return list;
  }
}

class _Metric {
  final String label;
  final double? raw;
  final double score;
  _Metric({required this.label, required this.raw, required this.score});
}
