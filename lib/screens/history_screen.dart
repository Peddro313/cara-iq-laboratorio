import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  // Demo data until real storage is connected
  static final List<Map<String, dynamic>> _demoHistory = [
    {'date': '2026-10-01', 'overall': 5.8},
    {'date': '2026-10-08', 'overall': 6.1},
    {'date': '2026-10-15', 'overall': 6.4},
    {'date': '2026-10-19', 'overall': 6.7},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Progress & History'),
      ),
      body: SafeArea(
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
                            if (idx >= 0 && idx < _demoHistory.length) {
                              return Text(
                                _demoHistory[idx]['date'].toString().substring(5),
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
                          _demoHistory.length,
                          (i) => FlSpot(i.toDouble(), _demoHistory[i]['overall'] as double),
                        ),
                        isCurved: true,
                        color: Theme.of(context).colorScheme.primary,
                        barWidth: 3,
                        dotData: const FlDotData(show: true),
                        belowBarData: BarAreaData(
                          show: true,
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.15),
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
                  itemCount: _demoHistory.length,
                  itemBuilder: (context, index) {
                    final item = _demoHistory[_demoHistory.length - 1 - index];
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                          child: Text(
                            (item['overall'] as double).toStringAsFixed(1),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        title: Text('Analysis – ${item['date']}'),
                        subtitle: const Text('Tap to view details'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          // In future: navigate to real result
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Full history coming soon')),
                          );
                        },
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
      ),
    );
  }
}
