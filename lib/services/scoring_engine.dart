import 'dart:math' as math;
import '../models/analysis.dart';
import 'landmark_service.dart';

/// Original scoring engine for Cara IQ Laboratório.
/// Formulas are based on public anthropometric knowledge and are NOT a copy of any commercial product.
class ScoringEngine {
  /// Ideal ranges are approximate and intended as starting points.
  /// They can (and should) be refined with more data later.

  static const Map<String, (double, double)> idealRatios = {
    // Front view
    'facial_thirds_upper': (0.30, 0.36),
    'facial_thirds_middle': (0.30, 0.36),
    'facial_thirds_lower': (0.30, 0.36),
    'eye_spacing': (0.90, 1.15),
    'nose_width_to_mouth': (0.65, 0.85),
    'jaw_to_cheek_width': (0.75, 0.95),
    'face_width_to_height': (0.70, 0.85),

    // Angularity related
    'jaw_angle': (115.0, 135.0),
  };

  static double scoreAgainstRange(double value, double minIdeal, double maxIdeal) {
    final mid = (minIdeal + maxIdeal) / 2;
    final halfRange = (maxIdeal - minIdeal) / 2;

    if (value >= minIdeal && value <= maxIdeal) {
      final dist = (value - mid).abs() / halfRange;
      return 10.0 - (dist * 1.5);
    }

    final distanceOutside = value < minIdeal
        ? minIdeal - value
        : value - maxIdeal;
    final penalty = distanceOutside / halfRange;
    return math.max(1.0, 8.0 - penalty * 3.0);
  }

  static String labelForScore(double score) {
    if (score >= 9.0) return 'Excellent';
    if (score >= 7.5) return 'Very Good';
    if (score >= 6.0) return 'Good';
    if (score >= 4.5) return 'Average';
    if (score >= 3.0) return 'Below Average';
    return 'Needs Work';
  }

  static AnalysisResult analyze({
    required List<FacialLandmark> frontLandmarks,
    required List<FacialLandmark> sideLandmarks,
    String? frontPhotoPath,
    String? sidePhotoPath,
  }) {
    // Real ratio calculation from landmarks
    final ratios = LandmarkService.computeRatios(
      front: frontLandmarks,
      side: sideLandmarks,
    );

    // --- Harmony (proportions) ---
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
      if (ratios.containsKey(key) && idealRatios.containsKey(key)) {
        final (min, max) = idealRatios[key]!;
        harmonyScores.add(scoreAgainstRange(ratios[key]!, min, max));
      }
    }
    final harmonyAvg = harmonyScores.isEmpty
        ? 6.0
        : harmonyScores.reduce((a, b) => a + b) / harmonyScores.length;

    final harmony = PillarScore(
      name: 'Harmony',
      score: double.parse(harmonyAvg.toStringAsFixed(2)),
      label: labelForScore(harmonyAvg),
      strengths: harmonyAvg >= 7.5 ? ['Balanced facial proportions'] : [],
      improvements: harmonyAvg < 6.5
          ? ['Some proportional ratios are outside the ideal range']
          : [],
    );

    // --- Structure / Angularity ---
    final structureKeys = ['jaw_angle', 'jaw_to_cheek_width', 'face_width_to_height'];
    final structureScores = <double>[];
    for (final key in structureKeys) {
      if (ratios.containsKey(key) && idealRatios.containsKey(key)) {
        final (min, max) = idealRatios[key]!;
        structureScores.add(scoreAgainstRange(ratios[key]!, min, max));
      }
    }
    final structureAvg = structureScores.isEmpty
        ? 6.0
        : structureScores.reduce((a, b) => a + b) / structureScores.length;

    final structure = PillarScore(
      name: 'Structure',
      score: double.parse(structureAvg.toStringAsFixed(2)),
      label: labelForScore(structureAvg),
      strengths: structureAvg >= 7.5 ? ['Good bone structure definition'] : [],
      improvements: structureAvg < 6.5
          ? ['Jawline or cheek definition could be stronger']
          : [],
    );

    // --- Dimorphism (still simplified) ---
    // Later we will use more specific traits (brow ridge, jaw width relative to face, etc.)
    double dimorphismScore = 6.2;
    if (ratios.containsKey('jaw_to_cheek_width')) {
      final jcw = ratios['jaw_to_cheek_width']!;
      // Slightly wider jaws relative to cheeks tend to score higher for masculine dimorphism
      dimorphismScore = scoreAgainstRange(jcw, 0.80, 0.98);
    }
    final dimorphism = PillarScore(
      name: 'Dimorphism',
      score: double.parse(dimorphismScore.toStringAsFixed(2)),
      label: labelForScore(dimorphismScore),
      strengths: dimorphismScore >= 7.5 ? ['Strong structural dimorphism signals'] : [],
      improvements: dimorphismScore < 6.0
          ? ['Dimorphism indicators are moderate']
          : [],
    );

    // --- Features (placeholder – needs image analysis later) ---
    final featuresScore = 6.8;
    final features = PillarScore(
      name: 'Features',
      score: featuresScore,
      label: labelForScore(featuresScore),
      strengths: [],
      improvements: ['Skin and feature quality analysis coming in a future update'],
    );

    // Overall = power mean of the four pillars
    final overall = math.pow(
          (math.pow(harmony.score, 1.5) +
                  math.pow(structure.score, 1.5) +
                  math.pow(dimorphism.score, 1.5) +
                  math.pow(features.score, 1.5)) /
              4,
          1 / 1.5,
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
