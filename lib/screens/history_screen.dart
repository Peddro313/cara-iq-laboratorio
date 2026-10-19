import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/analysis_providers.dart';
import '../models/analysis.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analysesAsync = ref.watch(analysesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Progress & History'),
      ),
      body: analysesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (analyses) {
          if (analyses.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  const Text('No analyses yet'),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () => context.push('/upload'),
                    child: const Text('Start First Analysis'),
                  ),
                ],
              ),
            );
          }

          // Sort oldest → newest for the chart
          final chronological = List<AnalysisResult>.from(analyses)
            ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Overall Score Over Time',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 220,
                    child: LineChart(
                      LineChartData(
                        gridData: const FlGridData(show: true),
                        titlesData: FlTitlesData(
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                final idx = value.toInt();
                                if (idx >= 0 && idx < chronological.length) {
                                  final d = chronological[idx].createdAt;
                                  return Text(
                                    '${d.month}/${d.day}',
                                    style: const TextStyle(fontSize: 10),
                                  );
                                }
                                return const Text('');
                              },
                            ),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 28,
                              getTitlesWidget: (value, meta) => Text(
                                value.toStringAsFixed(0),
                                style: const TextStyle(fontSize: 10),
                              ),
                            ),
                          ),
                          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        ),
                        borderData: FlBorderData(show: true),
                        minY: 0,
                        maxY: 10,
                        lineBarsData: [
                          LineChartBarData(
                            spots: List.generate(
                              chronological.length,
                              (i) => FlSpot(
                                i.toDouble(),
                                chronological[i].overallScore,
                              ),
                            ),
                            isCurved: true,
                            color: Theme.of(context).colorScheme.primary,
                            barWidth: 3,
                            dotData: const FlDotData(show: true),
                            belowBarData: BarAreaData(
                              show: true,
                              color: Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withOpacity(0.15),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'Past Analyses',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView.builder(
                      itemCount: analyses.length,
                      itemBuilder: (context, index) {
                        final item = analyses[index];
                        return Card(
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor:
                                  Theme.of(context).colorScheme.primaryContainer,
                              child: Text(
                                item.overallScore.toStringAsFixed(1),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.primary,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            title: Text(
                              'Analysis – ${item.createdAt.toLocal().toString().substring(0, 16)}',
                            ),
                            subtitle: Text(
                              '${item.overallLabel} • H:${item.harmony.score.toStringAsFixed(1)} S:${item.structure.score.toStringAsFixed(1)}',
                            ),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => context.push('/result/${item.id}'),
                          ),
                        );
                      },
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => context.push('/upload'),
                    icon: const Icon(Icons.add),
                    label: const Text('New Analysis'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
