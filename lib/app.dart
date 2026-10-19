import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'theme/app_theme.dart';
import 'screens/home_screen.dart';
import 'screens/upload_screen.dart';
import 'screens/result_screen.dart';
import 'screens/history_screen.dart';

final _router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/upload',
      builder: (context, state) => const UploadScreen(),
    ),
    GoRoute(
      path: '/result/:id',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return ResultScreen(analysisId: id);
      },
    ),
    GoRoute(
      path: '/history',
      builder: (context, state) => const HistoryScreen(),
    ),
  ],
);

class CaraIqApp extends ConsumerWidget {
  const CaraIqApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'Cara IQ Laboratório',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      routerConfig: _router,
    );
  }
}
