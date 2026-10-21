import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/analysis.dart';
import '../providers/analysis_providers.dart';
import '../theme/app_theme.dart';
import '../utils/score_color.dart';

class ResultScreen extends ConsumerWidget {
  final String analysisId;
  const ResultScreen({super.key, required this.analysisId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(analysisByIdProvider(analysisId));
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        title: const Text('Your analysis'),
        leading: IconButton(
          icon: const Icon(Icons.home_outlined),
          onPressed: () => context.go('/'),
        ),
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (r) {
          if (r == null) return const Center(child: Text('Not found'));
          return _Body(result: r);
        },
      ),
    );
  }
}

class _Body extends StatelessWidget {
  final AnalysisResult result;
  const _Body({required this.result});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth > 700;
        final photo = _PhotoPane(result: result);
        final scores = _ScoresPane(result: result);

        if (wide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(flex: 5, child: photo),
              Expanded(flex: 6, child: scores),
            ],
          );
        }

        return ListView(
          padding: const EdgeInsets.only(bottom: 32),
          children: [
            SizedBox(height: 320, child: photo),
            scores,
          ],
        );
      },
    );
  }
}

class _PhotoPane extends StatelessWidget {
  final AnalysisResult result;
  const _PhotoPane({required this.result});

  @override
  Widget build(BuildContext context) {
    final path = result.frontPhotoPath;
    return Container(
      color: AppTheme.surface,
      child: path != null && File(path).existsSync()
          ? Image.file(File(path), fit: BoxFit.cover)
          : const Center(
              child: Icon(Icons.person, size: 80, color: AppTheme.textMuted),
            ),
    );
  }
}

class _ScoresPane extends StatelessWidget {
  final AnalysisResult result;
  const _ScoresPane({required this.result});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                result.overallScore.toStringAsFixed(1),
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.w700,
                  color: scoreColor(result.overallScore),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Overall', style: TextStyle(color: AppTheme.textMuted)),
                    Text(result.overallLabel,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text('Pillars', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
          const SizedBox(height: 10),
          _PillarTile(
            score: result.harmony,
            onTap: () => context.push('/pillar/${result.id}/harmony'),
          ),
          _PillarTile(
            score: result.structure,
            onTap: () => context.push('/pillar/${result.id}/structure'),
          ),
          _PillarTile(
            score: result.dimorphism,
            onTap: () => context.push('/pillar/${result.id}/dimorphism'),
          ),
          _PillarTile(
            score: result.features,
            onTap: () => context.push('/pillar/${result.id}/features'),
          ),
          const SizedBox(height: 20),
          const Text('Key metrics', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
          const SizedBox(height: 10),
          ..._metricTiles(result),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () => context.go('/upload'),
            child: const Text('New analysis'),
          ),
          const SizedBox(height: 10),
          OutlinedButton(
            onPressed: () => context.push('/history'),
            child: const Text('History'),
          ),
        ],
      ),
    );
  }

  List<Widget> _metricTiles(AnalysisResult r) {
    final labels = {
      'facial_thirds_upper': 'Upper third',
      'facial_thirds_middle': 'Middle third',
      'facial_thirds_lower': 'Lower third',
      'eye_spacing': 'Eye spacing',
      'nose_width_to_mouth': 'Nose / mouth width',
      'jaw_to_cheek_width': 'Jaw / cheek width',
      'face_width_to_height': 'Width / height',
      'jaw_angle': 'Jaw angle',
      'canthal_tilt_left': 'Canthal tilt',
    };

    final widgets = <Widget>[];
    for (final e in r.ratios.entries) {
      final name = labels[e.key] ?? e.key.replaceAll('_', ' ');
      // Convert ratio into a 0-10 display score when possible
      final display = _ratioAsScore(e.key, e.value);
      widgets.add(_MetricRow(label: name, value: e.value, score: display));
    }
    if (widgets.isEmpty) {
      widgets.add(const Text('No metrics yet',
          style: TextStyle(color: AppTheme.textMuted)));
    }
    return widgets;
  }

  double _ratioAsScore(String key, double value) {
    // Rough mapping for color display
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
    final range = ideals[key];
    if (range == null) return 6.0;
    final (min, max) = range;
    final mid = (min + max) / 2;
    final half = (max - min) / 2;
    if (value >= min && value <= max) {
      final dist = (value - mid).abs() / half;
      return 10 - dist * 1.5;
    }
    final outside = value < min ? min - value : value - max;
    return (8 - (outside / half) * 3).clamp(1.0, 10.0);
  }
}

class _PillarTile extends StatelessWidget {
  final PillarScore score;
  final VoidCallback onTap;
  const _PillarTile({required this.score, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = scoreColor(score.score);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.border),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(score.name,
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      Text(score.label,
                          style: const TextStyle(
                              color: AppTheme.textMuted, fontSize: 12)),
                    ],
                  ),
                ),
                Text(
                  score.score.toStringAsFixed(1),
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: c,
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(Icons.chevron_right, color: AppTheme.textMuted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  final String label;
  final double value;
  final double score;
  const _MetricRow({
    required this.label,
    required this.value,
    required this.score,
  });

  @override
  Widget build(BuildContext context) {
    final c = scoreColor(score);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(fontSize: 13))),
          Text(
            value.toStringAsFixed(value.abs() > 20 ? 1 : 3),
            style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 36,
            child: Text(
              score.toStringAsFixed(1),
              textAlign: TextAlign.right,
              style: TextStyle(fontWeight: FontWeight.w700, color: c),
            ),
          ),
        ],
      ),
    );
  }
}
