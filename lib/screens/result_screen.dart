import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/analysis.dart';
import '../providers/analysis_providers.dart';

class ResultScreen extends ConsumerWidget {
  final String analysisId;

  const ResultScreen({super.key, required this.analysisId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analysisAsync = ref.watch(analysisByIdProvider(analysisId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analysis Result'),
        leading: IconButton(
          icon: const Icon(Icons.home),
          onPressed: () => context.go('/'),
        ),
      ),
      body: analysisAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (result) {
          if (result == null) {
            return const Center(child: Text('Analysis not found'));
          }
          return _ResultBody(result: result);
        },
      ),
    );
  }
}

class _ResultBody extends StatelessWidget {
  final AnalysisResult result;

  const _ResultBody({required this.result});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Overall Score Card
          Card(
            color: Theme.of(context).colorScheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Text(
                    'Overall Score',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    result.overallScore.toStringAsFixed(1),
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                  ),
                  Text(
                    result.overallLabel,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Analyzed on ${result.createdAt.toLocal().toString().substring(0, 16)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          Text(
            'Pillars',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),

          _PillarCard(score: result.harmony),
          _PillarCard(score: result.structure),
          _PillarCard(score: result.dimorphism),
          _PillarCard(score: result.features),

          if (result.ratios.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text(
              'Key Ratios',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: result.ratios.entries.map((e) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              e.key.replaceAll('_', ' '),
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                          Text(
                            e.value.toStringAsFixed(3),
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],

          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => context.go('/'),
            child: const Text('Back to Home'),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () => context.push('/history'),
            child: const Text('View Progress History'),
          ),
        ],
      ),
    );
  }
}

class _PillarCard extends StatelessWidget {
  final PillarScore score;

  const _PillarCard({required this.score});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  score.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                Text(
                  '${score.score.toStringAsFixed(1)} / 10',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              score.label,
              style: TextStyle(color: Colors.grey[600]),
            ),
            if (score.strengths.isNotEmpty) ...[
              const SizedBox(height: 8),
              ...score.strengths.map(
                (s) => Row(
                  children: [
                    const Icon(Icons.check_circle, size: 16, color: Colors.green),
                    const SizedBox(width: 6),
                    Expanded(child: Text(s, style: const TextStyle(fontSize: 13))),
                  ],
                ),
              ),
            ],
            if (score.improvements.isNotEmpty) ...[
              const SizedBox(height: 4),
              ...score.improvements.map(
                (s) => Row(
                  children: [
                    const Icon(Icons.info_outline, size: 16, color: Colors.orange),
                    const SizedBox(width: 6),
                    Expanded(child: Text(s, style: const TextStyle(fontSize: 13))),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
