import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        title: const Text('Cara IQ Laboratório'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history_outlined),
            onPressed: () => context.push('/history'),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),
              Text(
                'Your face.\nMeasured & tracked.',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      height: 1.2,
                      letterSpacing: -0.4,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              const Text(
                'Four pillars. Clear scores. Progress over time.',
                style: TextStyle(color: AppTheme.textMuted),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              const _FeatureCard(
                icon: Icons.face_retouching_natural_outlined,
                title: 'Harmony',
                subtitle: 'Proportions & balance',
              ),
              const SizedBox(height: 10),
              const _FeatureCard(
                icon: Icons.architecture_outlined,
                title: 'Structure',
                subtitle: 'Jawline & bone definition',
              ),
              const SizedBox(height: 10),
              const _FeatureCard(
                icon: Icons.people_outline,
                title: 'Dimorphism',
                subtitle: 'Gender-typical traits',
              ),
              const SizedBox(height: 10),
              const _FeatureCard(
                icon: Icons.auto_awesome_outlined,
                title: 'Features',
                subtitle: 'Surface & detail quality',
              ),
              const SizedBox(height: 28),
              FilledButton.icon(
                onPressed: () => context.push('/upload'),
                icon: const Icon(Icons.camera_alt_outlined),
                label: const Text('Start new analysis'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(54),
                ),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () => context.push('/examples'),
                icon: const Icon(Icons.grid_view_rounded),
                label: const Text('Reference faces'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => context.push('/history'),
                child: const Text('View progress',
                    style: TextStyle(color: AppTheme.textMuted)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppTheme.primarySoft.withOpacity(0.5),
          child: Icon(icon, color: AppTheme.primary, size: 22),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle, style: const TextStyle(color: AppTheme.textMuted)),
      ),
    );
  }
}
