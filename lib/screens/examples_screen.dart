import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Illustrative reference profiles. Scores are educational examples only.
class ExamplesScreen extends StatelessWidget {
  const ExamplesScreen({super.key});

  static final examples = <_RefFace>[
    _RefFace(
      name: 'Jordan Barrett',
      subtitle: 'Early career look',
      asset: 'assets/examples/jordan_barrett.jpg',
      overall: 8.6,
      harmony: 8.4,
      structure: 8.7,
      dimorphism: 8.5,
      features: 8.8,
      notes:
          'Strong eye area, balanced midface, clear texture. Often used as a high-harmony model reference.',
      tier: _Tier.high,
    ),
    _RefFace(
      name: 'Sean O\'Pry',
      subtitle: 'Classic male model',
      asset: 'assets/examples/sean_opry.jpg',
      overall: 8.8,
      harmony: 8.7,
      structure: 9.0,
      dimorphism: 8.9,
      features: 8.6,
      notes:
          'Very strong jaw and bone structure, balanced thirds, high dimorphism.',
      tier: _Tier.high,
    ),
    _RefFace(
      name: 'Vito Basso',
      subtitle: 'Angular structure',
      asset: 'assets/examples/vito_basso.jpg',
      overall: 8.4,
      harmony: 8.3,
      structure: 8.5,
      dimorphism: 8.6,
      features: 8.2,
      notes: 'Defined lower third and angular bone; strong structure profile.',
      tier: _Tier.high,
    ),
    _RefFace(
      name: 'Archie Cranch',
      subtitle: 'Reference profile',
      asset: 'assets/examples/archie_cranch.jpg',
      overall: 8.2,
      harmony: 8.1,
      structure: 8.0,
      dimorphism: 8.3,
      features: 8.2,
      notes: 'Balanced features with solid overall harmony and structure.',
      tier: _Tier.high,
    ),
    _RefFace(
      name: 'Taylor Hill',
      subtitle: 'High harmony',
      asset: 'assets/examples/taylor_hill.jpg',
      overall: 8.7,
      harmony: 8.9,
      structure: 8.3,
      dimorphism: 8.0,
      features: 8.8,
      notes:
          'Excellent facial proportions and eye–nose–lip balance; features score typically high.',
      tier: _Tier.high,
    ),
    _RefFace(
      name: 'Yael Shelbia',
      subtitle: 'Soft + structured',
      asset: 'assets/examples/yael_shelbia.jpg',
      overall: 8.5,
      harmony: 8.6,
      structure: 8.2,
      dimorphism: 7.9,
      features: 8.7,
      notes:
          'Strong harmony and surface quality; widely cited for balanced beauty standards.',
      tier: _Tier.high,
    ),
    _RefFace(
      name: 'Reference — weak jaw',
      subtitle: 'Structure pull-down',
      asset: 'assets/examples/ref_weak_jaw.jpg',
      overall: 5.3,
      harmony: 5.8,
      structure: 4.4,
      dimorphism: 4.7,
      features: 6.1,
      notes:
          'Upper face can look fine while a soft jaw lowers structure and dimorphism hard.',
      tier: _Tier.low,
    ),
    _RefFace(
      name: 'Reference — uneven thirds',
      subtitle: 'Harmony issue',
      asset: 'assets/examples/ref_uneven.jpg',
      overall: 5.0,
      harmony: 4.3,
      structure: 5.5,
      dimorphism: 5.2,
      features: 5.7,
      notes:
          'Proportion imbalance (thirds / spacing) caps the overall score even with average bone.',
      tier: _Tier.low,
    ),
    _RefFace(
      name: 'Reference — skin texture',
      subtitle: 'Features pull-down',
      asset: 'assets/examples/ref_skin.jpg',
      overall: 5.9,
      harmony: 6.3,
      structure: 6.8,
      dimorphism: 6.4,
      features: 4.1,
      notes:
          'Solid bone can still score mid if skin quality, fatigue, or acne hits the features pillar.',
      tier: _Tier.low,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final high = examples.where((e) => e.tier == _Tier.high).toList();
    final low = examples.where((e) => e.tier == _Tier.low).toList();

    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(title: const Text('Reference faces')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.surface2,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.border),
            ),
            child: const Text(
              'Tap a face to open scores. These are illustrative educational examples only — not official ratings.',
              style: TextStyle(color: AppTheme.textMuted, height: 1.4, fontSize: 13),
            ),
          ),
          const SizedBox(height: 22),
          const Text(
            'Higher references',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
          ),
          const SizedBox(height: 12),
          _Grid(faces: high),
          const SizedBox(height: 28),
          const Text(
            'Weaker / mixed examples',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
          ),
          const SizedBox(height: 12),
          _Grid(faces: low),
        ],
      ),
    );
  }
}

enum _Tier { high, low }

class _RefFace {
  final String name;
  final String subtitle;
  final String asset;
  final double overall;
  final double harmony;
  final double structure;
  final double dimorphism;
  final double features;
  final String notes;
  final _Tier tier;

  const _RefFace({
    required this.name,
    required this.subtitle,
    required this.asset,
    required this.overall,
    required this.harmony,
    required this.structure,
    required this.dimorphism,
    required this.features,
    required this.notes,
    required this.tier,
  });
}

class _Grid extends StatelessWidget {
  final List<_RefFace> faces;
  const _Grid({required this.faces});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: faces.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.72,
      ),
      itemBuilder: (context, i) {
        final face = faces[i];
        return _FaceCard(
          face: face,
          onTap: () => _openDetail(context, face),
        );
      },
    );
  }

  void _openDetail(BuildContext context, _RefFace face) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _DetailSheet(face: face),
    );
  }
}

class _FaceCard extends StatelessWidget {
  final _RefFace face;
  final VoidCallback onTap;

  const _FaceCard({required this.face, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppTheme.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(17)),
                  child: _Photo(asset: face.asset, name: face.name),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      face.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      face.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Tap for scores',
                      style: TextStyle(color: AppTheme.primary.withOpacity(0.9), fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Photo extends StatelessWidget {
  final String asset;
  final String name;

  const _Photo({required this.asset, required this.name});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      asset,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) {
        // Placeholder until you add real photos into assets/examples/
        final initials = name
            .split(' ')
            .where((w) => w.isNotEmpty)
            .take(2)
            .map((w) => w[0].toUpperCase())
            .join();
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.surface2,
                AppTheme.primarySoft.withOpacity(0.55),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: AppTheme.primary.withOpacity(0.35),
                  child: Text(
                    initials,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Add photo in assets',
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 10),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _DetailSheet extends StatelessWidget {
  final _RefFace face;
  const _DetailSheet({required this.face});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.72,
      minChildSize: 0.45,
      maxChildSize: 0.92,
      builder: (context, controller) {
        return ListView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.border,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: AspectRatio(
                aspectRatio: 1,
                child: _Photo(asset: face.asset, name: face.name),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              face.name,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
            ),
            Text(face.subtitle, style: const TextStyle(color: AppTheme.textMuted)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surface2,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    face.overall.toStringAsFixed(1),
                    style: const TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text('Overall', style: TextStyle(color: AppTheme.textMuted)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _bar('Harmony', face.harmony),
            _bar('Structure', face.structure),
            _bar('Dimorphism', face.dimorphism),
            _bar('Features', face.features),
            const SizedBox(height: 14),
            Text(face.notes, style: const TextStyle(color: AppTheme.textMuted, height: 1.45)),
            const SizedBox(height: 8),
            const Text(
              'Illustrative example only.',
              style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
            ),
          ],
        );
      },
    );
  }

  Widget _bar(String label, double value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label),
              Text(value.toStringAsFixed(1),
                  style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: value / 10,
              minHeight: 8,
              backgroundColor: AppTheme.border,
              color: AppTheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}
