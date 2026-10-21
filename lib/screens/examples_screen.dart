import 'package:flutter/material.dart';

/// Illustrative reference profiles for education only.
/// Scores are approximate examples based on commonly discussed facial traits,
/// not medical or official ratings.
class ExamplesScreen extends StatelessWidget {
  const ExamplesScreen({super.key});

  static final _highExamples = [
    _Example(
      name: 'Jordan Barrett (early career look)',
      overall: 8.6,
      harmony: 8.4,
      structure: 8.7,
      dimorphism: 8.5,
      features: 8.8,
      notes:
          'Strong eye area, balanced midface, clear skin texture. Often cited for model-tier harmony.',
    ),
    _Example(
      name: 'Sean O\'Pry',
      overall: 8.8,
      harmony: 8.7,
      structure: 9.0,
      dimorphism: 8.9,
      features: 8.6,
      notes:
          'Very strong jaw and bone structure, tall facial thirds balance, classic male model proportions.',
    ),
    _Example(
      name: 'Vito Basso',
      overall: 8.4,
      harmony: 8.3,
      structure: 8.5,
      dimorphism: 8.6,
      features: 8.2,
      notes:
          'Angular structure and defined lower third; high dimorphism profile.',
    ),
    _Example(
      name: 'Archie Madekwe',
      overall: 8.1,
      harmony: 8.2,
      structure: 7.9,
      dimorphism: 8.0,
      features: 8.3,
      notes:
          'Balanced features and soft-to-medium structure; strong overall harmony.',
    ),
  ];

  static final _mixedExamples = [
    _Example(
      name: 'Reference A (weaker jaw / soft lower third)',
      overall: 5.4,
      harmony: 5.8,
      structure: 4.6,
      dimorphism: 4.9,
      features: 6.2,
      notes:
          'Skin and upper face may be fine, but low jaw definition pulls structure and dimorphism down.',
    ),
    _Example(
      name: 'Reference B (uneven thirds / wide midface)',
      overall: 5.1,
      harmony: 4.5,
      structure: 5.5,
      dimorphism: 5.3,
      features: 5.8,
      notes:
          'Proportion imbalance (facial thirds / eye spacing) limits harmony even when bone is average.',
    ),
    _Example(
      name: 'Reference C (good bone, rough skin texture)',
      overall: 6.0,
      harmony: 6.4,
      structure: 7.0,
      dimorphism: 6.5,
      features: 4.2,
      notes:
          'Structure can be solid while features score drops due to skin quality, acne, or fatigue.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reference examples')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.amber.shade200),
            ),
            child: Text(
              'These are illustrative educational examples only. '
              'Scores are approximate and based on publicly discussed facial traits, '
              'not lab measurements or official ratings of any person.',
              style: TextStyle(color: Colors.brown.shade800, height: 1.4, fontSize: 13),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Higher-reference profiles',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Often used as visual references for strong harmony and structure.',
            style: TextStyle(color: Colors.grey[600], fontSize: 13),
          ),
          const SizedBox(height: 12),
          ..._highExamples.map((e) => _ExampleCard(example: e)),
          const SizedBox(height: 28),
          Text(
            'Lower / mixed profiles',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Shows how one weak area (jaw, proportions, or skin) can lower the overall score.',
            style: TextStyle(color: Colors.grey[600], fontSize: 13),
          ),
          const SizedBox(height: 12),
          ..._mixedExamples.map((e) => _ExampleCard(example: e)),
        ],
      ),
    );
  }
}

class _Example {
  final String name;
  final double overall;
  final double harmony;
  final double structure;
  final double dimorphism;
  final double features;
  final String notes;

  const _Example({
    required this.name,
    required this.overall,
    required this.harmony,
    required this.structure,
    required this.dimorphism,
    required this.features,
    required this.notes,
  });
}

class _ExampleCard extends StatelessWidget {
  final _Example example;

  const _ExampleCard({required this.example});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    example.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    example.overall.toStringAsFixed(1),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _mini('Harmony', example.harmony),
            _mini('Structure', example.structure),
            _mini('Dimorphism', example.dimorphism),
            _mini('Features', example.features),
            const SizedBox(height: 10),
            Text(
              example.notes,
              style: TextStyle(color: Colors.grey[700], fontSize: 13, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _mini(String label, double value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(width: 90, child: Text(label, style: const TextStyle(fontSize: 12))),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: value / 10,
                minHeight: 6,
                backgroundColor: Colors.grey.shade200,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(value.toStringAsFixed(1), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
