import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'theme/app_theme.dart';
import 'screens/home_screen.dart';
import 'screens/upload_screen.dart';
import 'screens/result_screen.dart';
import 'screens/history_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/examples_screen.dart';
import 'screens/analyzing_screen.dart';
import 'screens/pillar_screen.dart';
import 'services/profile_repository.dart';

final _router = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(path: '/splash', builder: (c, s) => const _SplashGate()),
    GoRoute(path: '/onboarding', builder: (c, s) => const OnboardingScreen()),
    GoRoute(path: '/', builder: (c, s) => const HomeScreen()),
    GoRoute(path: '/upload', builder: (c, s) => const UploadScreen()),
    GoRoute(
      path: '/analyzing',
      builder: (c, s) {
        final extra = s.extra as Map<String, String>?;
        return AnalyzingScreen(
          frontPath: extra?['front'] ?? '',
          sidePath: extra?['side'] ?? '',
        );
      },
    ),
    GoRoute(
      path: '/result/:id',
      builder: (c, s) => ResultScreen(analysisId: s.pathParameters['id']!),
    ),
    GoRoute(
      path: '/pillar/:id/:pillar',
      builder: (c, s) => PillarScreen(
        analysisId: s.pathParameters['id']!,
        pillarKey: s.pathParameters['pillar']!,
      ),
    ),
    GoRoute(path: '/history', builder: (c, s) => const HistoryScreen()),
    GoRoute(path: '/examples', builder: (c, s) => const ExamplesScreen()),
  ],
);

class CaraIqApp extends ConsumerWidget {
  const CaraIqApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'Cara IQ Laboratório',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.dark,
      routerConfig: _router,
    );
  }
}

class _SplashGate extends StatefulWidget {
  const _SplashGate();
  @override
  State<_SplashGate> createState() => _SplashGateState();
}

class _SplashGateState extends State<_SplashGate> {
  @override
  void initState() {
    super.initState();
    _go();
  }

  Future<void> _go() async {
    await Future.delayed(const Duration(milliseconds: 700));
    final done = await ProfileRepository().isOnboardingDone();
    if (!mounted) return;
    context.go(done ? '/' : '/onboarding');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Cara IQ',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.5,
                  ),
            ),
            const SizedBox(height: 8),
            const Text(
              'LABORATÓRIO',
              style: TextStyle(
                color: AppTheme.textMuted,
                letterSpacing: 3,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 36),
            const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ],
        ),
      ),
    );
  }
}
