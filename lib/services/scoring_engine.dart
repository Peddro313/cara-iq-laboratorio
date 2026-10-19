import 'dart:math' as math;
import '../models/analysis.dart';

/// Original scoring engine for Cara IQ Laboratório.
/// Formulas are based on public anthropometric knowledge and are NOT a copy of any commercial product.
class ScoringEngine {
  /// Ideal ranges are approximate and intended as starting points.
  /// They can (and should) be refined with more data later.

  static const Map<String, (double, double)> idealRatios = {
    // Front view
    'facial_thirds_upper': (0.30, 0.36),   // forehead / total height
    'facial_thirds_middle': (0.30, 0.36),  // midface
    'facial_thirds_lower': (0.30, 0.36),   // lower face
    'eye_spacing': (0.90, 1.15),           // interpupillary / eye width
    'nose_width_to_mouth': (0.65, 0.85),
    'jaw_to_cheek_width': (0.75, 0.95),
    'face_width_to_height': (0.70, 0.85),

    // Side / angularity related
    'jaw_angle': (115.0, 135.0),           // degrees
    'nasofrontal_angle': (115.0, 135.0),
    'nasolabial_angle': (90.0, 110.0),
  };

  /// Compute a simple 0-10 score for a measured value against an ideal range.
  static double scoreAgainstRange(double value, double minIdeal, double maxIdeal) {
    final mid = (minIdeal + maxIdeal) / 2;
    final halfRange = (maxIdeal - minIdeal) / 2;

    if (value >= minIdeal && value <= maxIdeal) {
      // Inside ideal: score 8.5 – 10 depending on distance to mid
      final dist = (value - mid).abs() / halfRange;
      return 10.0 - (dist * 1.5);
    }

    // Outside ideal: decay
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

  /// Very simplified ratio calculation from landmarks.
  /// In production this will use proper MediaPipe indices and geometry.
  static Map<String, double> computeRatios(
    List<FacialLandmark> front,
    List<FacialLandmark> side,
  ) {
    // Placeholder ratios – real implementation will use specific landmark indices.
    // Example MediaPipe indices (approximate):
    // 10 = forehead, 152 = chin, 234/454 = cheeks, etc.
    return {
      'facial_thirds_upper': 0.33,
      'facial_thirds_middle': 0.34,
      'facial_thirds_lower': 0.33,
      'eye_spacing': 1.05,
      'nose_width_to_mouth': 0.75,
      'jaw_to_cheek_width': 0.88,
      'face_width_to_height': 0.78,
      'jaw_angle': 125.0,
      'nasofrontal_angle': 125.0,
      'nasolabial_angle': 100.0,
    };
  }

  static AnalysisResult analyze({
    required List<FacialLandmark> frontLandmarks,
    required List<FacialLandmark> sideLandmarks,
    String? frontPhotoPath,
    String? sidePhotoPath,
  }) {
    final ratios = computeRatios(frontLandmarks, sideLandmarks);

    // --- Harmony (proportions) ---
    final harmonyScores = <double>[];
    for (final entry in idealRatios.entries) {
      if (ratios.containsKey(entry.key) && !entry.key.contains('angle')) {
        final (min, max) = entry.value;
        harmonyScores.add(scoreAgainstRange(ratios[entry.key]!, min, max));
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
      improvements: harmonyAvg < 6.5 ? ['Some proportional ratios are outside ideal range'] : [],
    );

    // --- Structure / Angularity ---
    final structureScores = <double>[];
    for (final key in ['jaw_angle', 'jaw_to_cheek_width', 'face_width_to_height']) {
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
      improvements: structureAvg < 6.5 ? ['Jawline or cheek definition could be stronger'] : [],
    );

    // --- Dimorphism (placeholder for now) ---
    final dimorphismScore = 6.5 + (math.Random().nextDouble() * 1.5); // temporary
    final dimorphism = PillarScore(
      name: 'Dimorphism',
      score: double.parse(dimorphismScore.toStringAsFixed(2)),
      label: labelForScore(dimorphismScore),
      strengths: [],
      improvements: [],
    );

    // --- Features (placeholder) ---
    final featuresScore = 6.8;
    final features = PillarScore(
      name: 'Features',
      score: featuresScore,
      label: labelForScore(featuresScore),
      strengths: [],
      improvements: [],
    );

    // Overall = power mean of the four pillars (slightly favors higher scores)
    final overall = math.pow(
          (math.pow(harmony.score, 1.5) +
                  math.pow(structure.score, 1.5) +
                  math.pow(dimorphism.score, 1.5) +
                  math.pow(features.score, 1.5)) /
              4,
          1 / 1.5,
        )
        as double;

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
