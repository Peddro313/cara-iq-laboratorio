import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cara IQ Laboratório'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => context.push('/history'),
            tooltip: 'Progress & History',
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              Text(
                'Your Face.\nMeasured. Tracked. Improved.',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      height: 1.3,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Get a detailed facial analysis across four pillars and track your progress over time.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.grey[600],
                    ),
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              _FeatureCard(
                icon: Icons.face_retouching_natural,
                title: 'Harmony',
                subtitle: 'Proportions & balance',
              ),
              const SizedBox(height: 12),
              _FeatureCard(
                icon: Icons.architecture,
                title: 'Structure',
                subtitle: 'Jawline & bone definition',
              ),
              const SizedBox(height: 12),
              _FeatureCard(
                icon: Icons.people_outline,
                title: 'Dimorphism',
                subtitle: 'Gender-typical traits',
              ),
              const SizedBox(height: 12),
              _FeatureCard(
                icon: Icons.auto_awesome,
                title: 'Features',
                subtitle: 'Surface & detail quality',
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () => context.push('/upload'),
                icon: const Icon(Icons.camera_alt),
                label: const Text('Start New Analysis'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => context.push('/history'),
                child: const Text('View Progress'),
              ),
              const SizedBox(height: 24),
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
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child: Icon(icon, color: Theme.of(context).colorScheme.primary),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
      ),
    );
  }
}
