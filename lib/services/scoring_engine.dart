import 'dart:math' as math;
import '../models/analysis.dart';
import 'landmark_service.dart';

/// Scoring that responds to real measured differences.
class ScoringEngine {
  /// Wider ideal ranges so different faces land in different parts of the scale.
  static const Map<String, (double, double)> ideal = {
    'facial_thirds_upper': (0.26, 0.40),
    'facial_thirds_middle': (0.26, 0.40),
    'facial_thirds_lower': (0.26, 0.42),
    'eye_spacing': (0.75, 1.40),
    'nose_width_to_mouth': (0.50, 1.05),
    'jaw_to_cheek_width': (0.62, 1.05),
    'face_width_to_height': (0.60, 0.95),
    'jaw_angle': (95.0, 155.0),
    'canthal_tilt_left': (-12.0, 15.0),
    'eye_span_to_face': (0.55, 0.85),
    'mouth_to_face_width': (0.28, 0.48),
  };

  /// Score 0–10. Closer to ideal center = higher. Stronger differentiation.
  static double scoreAgainstRange(double value, double minIdeal, double maxIdeal) {
    final mid = (minIdeal + maxIdeal) / 2;
    final half = math.max((maxIdeal - minIdeal) / 2, 0.001);
    final dist = (value - mid).abs() / half;

    // Inside ideal band: 7.5 – 9.8
    if (value >= minIdeal && value <= maxIdeal) {
      return 9.8 - dist * 2.3;
    }

    // Outside: drops further the farther you go (floor ~3.2)
    final outside = value < minIdeal ? minIdeal - value : value - maxIdeal;
    final t = outside / half;
    return math.max(3.2, 7.4 - t * 2.4);
  }

  static String labelForScore(double score) {
    if (score >= 9.0) return 'Excellent';
    if (score >= 7.8) return 'Very Good';
    if (score >= 6.5) return 'Good';
    if (score >= 5.0) return 'Average';
    if (score >= 3.5) return 'Below Average';
    return 'Needs Work';
  }

  static double _avg(List<double> xs, [double fallback = 6.5]) {
    if (xs.isEmpty) return fallback;
    return xs.reduce((a, b) => a + b) / xs.length;
  }

  static AnalysisResult analyze({
    required List<FacialLandmark> frontLandmarks,
    required List<FacialLandmark> sideLandmarks,
    String? frontPhotoPath,
    String? sidePhotoPath,
  }) {
    final ratios = LandmarkService.computeRatios(
      front: frontLandmarks,
      side: sideLandmarks,
    );

    // Harmony — proportions
    final harmonyKeys = [
      'facial_thirds_upper',
      'facial_thirds_middle',
      'facial_thirds_lower',
      'eye_spacing',
      'nose_width_to_mouth',
      'face_width_to_height',
      'eye_span_to_face',
      'mouth_to_face_width',
    ];
    final hScores = <double>[];
    for (final k in harmonyKeys) {
      if (ratios[k] != null && ideal[k] != null) {
        final (mn, mx) = ideal[k]!;
        hScores.add(scoreAgainstRange(ratios[k]!, mn, mx));
      }
    }
    final harmonyAvg = _avg(hScores);

    final harmony = PillarScore(
      name: 'Harmony',
      score: double.parse(harmonyAvg.toStringAsFixed(2)),
      label: labelForScore(harmonyAvg),
      strengths: harmonyAvg >= 7.8 ? ['Balanced proportions'] : [],
      improvements: harmonyAvg < 6.0 ? ['Some ratios outside preferred range'] : [],
    );

    // Structure — jaw / width
    final structureKeys = ['jaw_angle', 'jaw_to_cheek_width', 'face_width_to_height'];
    final sScores = <double>[];
    for (final k in structureKeys) {
      if (ratios[k] != null && ideal[k] != null) {
        final (mn, mx) = ideal[k]!;
        sScores.add(scoreAgainstRange(ratios[k]!, mn, mx));
      }
    }
    final structureAvg = _avg(sScores);

    final structure = PillarScore(
      name: 'Structure',
      score: double.parse(structureAvg.toStringAsFixed(2)),
      label: labelForScore(structureAvg),
      strengths: structureAvg >= 7.8 ? ['Defined bone structure'] : [],
      improvements: structureAvg < 6.0 ? ['Jaw or width ratios weaker'] : [],
    );

    // Dimorphism — jaw emphasis
    double dim = 6.5;
    if (ratios['jaw_to_cheek_width'] != null) {
      dim = scoreAgainstRange(ratios['jaw_to_cheek_width']!, 0.68, 1.02);
    }
    if (ratios['jaw_angle'] != null) {
      final ja = scoreAgainstRange(ratios['jaw_angle']!, 100, 150);
      dim = (dim + ja) / 2;
    }

    final dimorphism = PillarScore(
      name: 'Dimorphism',
      score: double.parse(dim.toStringAsFixed(2)),
      label: labelForScore(dim),
      strengths: dim >= 7.8 ? ['Strong structural dimorphism'] : [],
      improvements: dim < 6.0 ? ['Moderate dimorphism signals'] : [],
    );

    // Features — derive a light signal from available ratios so it is not fixed
    double feat = 6.8;
    if (ratios['canthal_tilt_left'] != null && ideal['canthal_tilt_left'] != null) {
      final (mn, mx) = ideal['canthal_tilt_left']!;
      feat = scoreAgainstRange(ratios['canthal_tilt_left']!, mn, mx);
    }
    if (ratios['nose_width_to_mouth'] != null) {
      final nw = scoreAgainstRange(ratios['nose_width_to_mouth']!, 0.50, 1.05);
      feat = (feat + nw) / 2;
    }

    final features = PillarScore(
      name: 'Features',
      score: double.parse(feat.toStringAsFixed(2)),
      label: labelForScore(feat),
      strengths: feat >= 7.5 ? ['Favorable feature proportions'] : [],
      improvements: feat < 6.0 ? ['Feature proportions could improve'] : [],
    );

    // Overall — weighted slightly toward harmony + structure
    final overall = (harmony.score * 1.2 +
            structure.score * 1.1 +
            dimorphism.score +
            features.score) /
        4.3;

    return AnalysisResult(
      frontPhotoPath: frontPhotoPath,
      sidePhotoPath: sidePhotoPath,
      frontLandmarks: frontLandmarks,
      sideLandmarks: sideLandmarks,
      ratios: ratios,
      harmony: harmony,
      structure: structure,
      dimorphism: dimorphism,
      features: features,
      overallScore: double.parse(overall.toStringAsFixed(2)),
      overallLabel: labelForScore(overall),
    );
  }
}
