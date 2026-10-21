import 'dart:math' as math;
import '../models/analysis.dart';
import 'landmark_service.dart';

/// Original scoring engine for Cara IQ Laboratório.
class ScoringEngine {
  static const Map<String, (double, double)> idealRatios = {
    'facial_thirds_upper': (0.28, 0.38),
    'facial_thirds_middle': (0.28, 0.38),
    'facial_thirds_lower': (0.28, 0.40),
    'eye_spacing': (0.85, 1.25),
    'nose_width_to_mouth': (0.55, 0.95),
    'jaw_to_cheek_width': (0.70, 1.00),
    'face_width_to_height': (0.65, 0.90),
    'jaw_angle': (105.0, 145.0),
    'canthal_tilt_left': (-5.0, 12.0),
  };

  /// Softer curve: values near ideal stay high; outliers drop gradually.
  static double scoreAgainstRange(double value, double minIdeal, double maxIdeal) {
    final mid = (minIdeal + maxIdeal) / 2;
    final half = math.max((maxIdeal - minIdeal) / 2, 0.001);

    if (value >= minIdeal && value <= maxIdeal) {
      final dist = (value - mid).abs() / half;
      return 9.6 - dist * 1.2; // 8.4 – 9.6 inside band
    }

    final outside = value < minIdeal ? minIdeal - value : value - maxIdeal;
    final t = outside / half;
    // Gentle falloff, floor at 4.0 so one bad ratio cannot destroy the face
    return math.max(4.0, 8.2 - t * 1.8);
  }

  static String labelForScore(double score) {
    if (score >= 9.0) return 'Excellent';
    if (score >= 7.5) return 'Very Good';
    if (score >= 6.0) return 'Good';
    if (score >= 4.5) return 'Average';
    if (score >= 3.0) return 'Below Average';
    return 'Needs Work';
  }

  static double _avg(List<double> xs, [double fallback = 7.0]) {
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

    // Harmony
    final harmonyKeys = [
      'facial_thirds_upper',
      'facial_thirds_middle',
      'facial_thirds_lower',
      'eye_spacing',
      'nose_width_to_mouth',
      'face_width_to_height',
    ];
    final harmonyScores = <double>[];
    for (final key in harmonyKeys) {
      if (ratios[key] != null && idealRatios[key] != null) {
        final (min, max) = idealRatios[key]!;
        harmonyScores.add(scoreAgainstRange(ratios[key]!, min, max));
      }
    }
    final harmonyAvg = _avg(harmonyScores, 7.2);

    final harmony = PillarScore(
      name: 'Harmony',
      score: double.parse(harmonyAvg.toStringAsFixed(2)),
      label: labelForScore(harmonyAvg),
      strengths: harmonyAvg >= 7.5 ? ['Balanced facial proportions'] : [],
      improvements: harmonyAvg < 6.0
          ? ['Some proportions sit outside the preferred range']
          : [],
    );

    // Structure
    final structureKeys = ['jaw_angle', 'jaw_to_cheek_width', 'face_width_to_height'];
    final structureScores = <double>[];
    for (final key in structureKeys) {
      if (ratios[key] != null && idealRatios[key] != null) {
        final (min, max) = idealRatios[key]!;
        structureScores.add(scoreAgainstRange(ratios[key]!, min, max));
      }
    }
    final structureAvg = _avg(structureScores, 7.0);

    final structure = PillarScore(
      name: 'Structure',
      score: double.parse(structureAvg.toStringAsFixed(2)),
      label: labelForScore(structureAvg),
      strengths: structureAvg >= 7.5 ? ['Solid bone structure signals'] : [],
      improvements: structureAvg < 6.0
          ? ['Jaw / cheek definition could read stronger']
          : [],
    );

    // Dimorphism
    double dimorphismScore = 7.0;
    if (ratios['jaw_to_cheek_width'] != null) {
      dimorphismScore =
          scoreAgainstRange(ratios['jaw_to_cheek_width']!, 0.72, 1.0);
    }
    if (ratios['jaw_angle'] != null) {
      final ja = scoreAgainstRange(ratios['jaw_angle']!, 105, 145);
      dimorphismScore = (dimorphismScore + ja) / 2;
    }

    final dimorphism = PillarScore(
      name: 'Dimorphism',
      score: double.parse(dimorphismScore.toStringAsFixed(2)),
      label: labelForScore(dimorphismScore),
      strengths: dimorphismScore >= 7.5 ? ['Clear structural dimorphism cues'] : [],
      improvements: dimorphismScore < 6.0 ? ['Dimorphism reads moderate'] : [],
    );

    // Features — until skin AI exists, keep neutral-high so it does not tank overall
    const featuresScore = 7.4;
    final features = PillarScore(
      name: 'Features',
      score: featuresScore,
      label: labelForScore(featuresScore),
      strengths: ['Surface quality scoring will improve in a later update'],
      improvements: [],
    );

    final overall = math.pow(
          (math.pow(harmony.score, 1.4) +
                  math.pow(structure.score, 1.4) +
                  math.pow(dimorphism.score, 1.4) +
                  math.pow(features.score, 1.4)) /
              4,
          1 / 1.4,
        ) as double;

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
