import 'package:flutter/material.dart';

/// Maps 0–10 score to color: red near 0, yellow mid, green >5, darker green near 10.
Color scoreColor(double score) {
  final s = score.clamp(0.0, 10.0);
  if (s < 5) {
    // 0 → red, 5 → amber
    final t = s / 5;
    return Color.lerp(const Color(0xFFE53935), const Color(0xFFFFB300), t)!;
  }
  // 5 → light green, 10 → deep green
  final t = (s - 5) / 5;
  return Color.lerp(const Color(0xFF66BB6A), const Color(0xFF1B5E20), t)!;
}
