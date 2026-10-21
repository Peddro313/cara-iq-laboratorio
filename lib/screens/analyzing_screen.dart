import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/analysis_providers.dart';
import '../theme/app_theme.dart';

class AnalyzingScreen extends ConsumerStatefulWidget {
  final String frontPath;
  final String sidePath;

  const AnalyzingScreen({
    super.key,
    required this.frontPath,
    required this.sidePath,
  });

  @override
  ConsumerState<AnalyzingScreen> createState() => _AnalyzingScreenState();
}

class _AnalyzingScreenState extends ConsumerState<AnalyzingScreen>
    with TickerProviderStateMixin {
  late final AnimationController _meshCtrl;
  late final AnimationController _pulseCtrl;
  String _status = 'Detecting facial landmarks…';

  @override
  void initState() {
    super.initState();
    _meshCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..forward();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _run();
  }

  Future<void> _run() async {
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    setState(() => _status = 'Mapping proportions…');

    try {
      final runner = ref.read(runPhotoAnalysisProvider);
      final result = await runner(
        frontPhotoPath: widget.frontPath,
        sidePhotoPath: widget.sidePath,
      );

      if (!mounted) return;
      setState(() => _status = 'Calculating scores…');
      await Future.delayed(const Duration(milliseconds: 600));
      if (!mounted) return;
      context.go('/result/${result.id}');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Analysis failed: $e')),
      );
      context.pop();
    }
  }

  @override
  void dispose() {
    _meshCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 24),
            Text(
              'Analyzing',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            AnimatedBuilder(
              animation: _pulseCtrl,
              builder: (_, __) => Opacity(
                opacity: 0.55 + _pulseCtrl.value * 0.45,
                child: Text(_status,
                    style: const TextStyle(color: AppTheme.textMuted)),
              ),
            ),
            const SizedBox(height: 28),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Center(
                  child: AspectRatio(
                    aspectRatio: 3 / 4,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.file(
                            File(widget.frontPath),
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: AppTheme.surface2,
                              child: const Icon(Icons.person, size: 64),
                            ),
                          ),
                          Container(color: Colors.black.withOpacity(0.25)),
                          AnimatedBuilder(
                            animation: _meshCtrl,
                            builder: (_, __) => CustomPaint(
                              painter: _MeshPainter(progress: _meshCtrl.value),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Padding(
              padding: EdgeInsets.only(bottom: 32),
              child: SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MeshPainter extends CustomPainter {
  final double progress;
  _MeshPainter({required this.progress});

  // Normalized face mesh points (approx)
  static const points = [
    Offset(0.50, 0.12), // forehead
    Offset(0.28, 0.32), // L eye outer
    Offset(0.40, 0.32), // L eye inner
    Offset(0.60, 0.32), // R eye inner
    Offset(0.72, 0.32), // R eye outer
    Offset(0.50, 0.42), // nose bridge
    Offset(0.50, 0.52), // nose tip
    Offset(0.42, 0.50), // nose L
    Offset(0.58, 0.50), // nose R
    Offset(0.18, 0.48), // L cheek
    Offset(0.82, 0.48), // R cheek
    Offset(0.38, 0.66), // mouth L
    Offset(0.62, 0.66), // mouth R
    Offset(0.50, 0.70), // mouth center
    Offset(0.22, 0.72), // L jaw
    Offset(0.78, 0.72), // R jaw
    Offset(0.50, 0.90), // chin
  ];

  static const edges = [
    [0, 1], [0, 4], [1, 2], [2, 3], [3, 4],
    [2, 5], [3, 5], [5, 6], [6, 7], [6, 8],
    [1, 9], [4, 10], [9, 14], [10, 15],
    [11, 12], [11, 13], [12, 13],
    [14, 16], [15, 16], [11, 14], [12, 15],
    [9, 11], [10, 12], [0, 9], [0, 10],
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.primary.withOpacity(0.85)
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final dotPaint = Paint()
      ..color = Colors.white.withOpacity(0.9)
      ..style = PaintingStyle.fill;

    final n = edges.length;
    final visible = (progress * n).ceil().clamp(0, n);

    for (var i = 0; i < visible; i++) {
      final e = edges[i];
      final a = points[e[0]];
      final b = points[e[1]];
      final p1 = Offset(a.dx * size.width, a.dy * size.height);
      final p2 = Offset(b.dx * size.width, b.dy * size.height);

      final edgeProgress = ((progress * n) - i).clamp(0.0, 1.0);
      final end = Offset.lerp(p1, p2, edgeProgress)!;
      canvas.drawLine(p1, end, paint);
    }

    final dotsVisible = (progress * points.length).ceil().clamp(0, points.length);
    for (var i = 0; i < dotsVisible; i++) {
      final p = points[i];
      canvas.drawCircle(
        Offset(p.dx * size.width, p.dy * size.height),
        2.2,
        dotPaint,
      );
    }

    // soft scan line
    final y = size.height * progress;
    final scan = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppTheme.primary.withOpacity(0),
          AppTheme.primary.withOpacity(0.35),
          AppTheme.primary.withOpacity(0),
        ],
      ).createShader(Rect.fromLTWH(0, y - 20, size.width, 40));
    canvas.drawRect(Rect.fromLTWH(0, y - 20, size.width, 40), scan);
  }

  @override
  bool shouldRepaint(covariant _MeshPainter old) => old.progress != progress;
}
