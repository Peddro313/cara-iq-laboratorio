import 'package:uuid/uuid.dart';

class FacialLandmark {
  final int index;
  final double x;
  final double y;
  final double z;

  const FacialLandmark({
    required this.index,
    required this.x,
    required this.y,
    required this.z,
  });

  Map<String, dynamic> toJson() => {
        'index': index,
        'x': x,
        'y': y,
        'z': z,
      };

  factory FacialLandmark.fromJson(Map<String, dynamic> json) => FacialLandmark(
        index: json['index'] as int,
        x: (json['x'] as num).toDouble(),
        y: (json['y'] as num).toDouble(),
        z: (json['z'] as num).toDouble(),
      );
}

class PillarScore {
  final String name;
  final double score; // 0.0 - 10.0
  final String label; // e.g. "Excellent", "Good", "Average"
  final List<String> strengths;
  final List<String> improvements;

  const PillarScore({
    required this.name,
    required this.score,
    required this.label,
    this.strengths = const [],
    this.improvements = const [],
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'score': score,
        'label': label,
        'strengths': strengths,
        'improvements': improvements,
      };

  factory PillarScore.fromJson(Map<String, dynamic> json) => PillarScore(
        name: json['name'] as String,
        score: (json['score'] as num).toDouble(),
        label: json['label'] as String,
        strengths: List<String>.from(json['strengths'] ?? []),
        improvements: List<String>.from(json['improvements'] ?? []),
      );
}

class AnalysisResult {
  final String id;
  final DateTime createdAt;
  final String? frontPhotoPath;
  final String? sidePhotoPath;
  final List<FacialLandmark> frontLandmarks;
  final List<FacialLandmark> sideLandmarks;
  final Map<String, double> ratios; // e.g. "facial_thirds": 0.98
  final PillarScore harmony;
  final PillarScore structure;
  final PillarScore dimorphism;
  final PillarScore features;
  final double overallScore;
  final String overallLabel;

  AnalysisResult({
    String? id,
    DateTime? createdAt,
    this.frontPhotoPath,
    this.sidePhotoPath,
    this.frontLandmarks = const [],
    this.sideLandmarks = const [],
    this.ratios = const {},
    required this.harmony,
    required this.structure,
    required this.dimorphism,
    required this.features,
    required this.overallScore,
    required this.overallLabel,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'createdAt': createdAt.toIso8601String(),
        'frontPhotoPath': frontPhotoPath,
        'sidePhotoPath': sidePhotoPath,
        'frontLandmarks': frontLandmarks.map((e) => e.toJson()).toList(),
        'sideLandmarks': sideLandmarks.map((e) => e.toJson()).toList(),
        'ratios': ratios,
        'harmony': harmony.toJson(),
        'structure': structure.toJson(),
        'dimorphism': dimorphism.toJson(),
        'features': features.toJson(),
        'overallScore': overallScore,
        'overallLabel': overallLabel,
      };

  factory AnalysisResult.fromJson(Map<String, dynamic> json) => AnalysisResult(
        id: json['id'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        frontPhotoPath: json['frontPhotoPath'] as String?,
        sidePhotoPath: json['sidePhotoPath'] as String?,
        frontLandmarks: (json['frontLandmarks'] as List? ?? [])
            .map((e) => FacialLandmark.fromJson(e))
            .toList(),
        sideLandmarks: (json['sideLandmarks'] as List? ?? [])
            .map((e) => FacialLandmark.fromJson(e))
            .toList(),
        ratios: Map<String, double>.from(json['ratios'] ?? {}),
        harmony: PillarScore.fromJson(json['harmony']),
        structure: PillarScore.fromJson(json['structure']),
        dimorphism: PillarScore.fromJson(json['dimorphism']),
        features: PillarScore.fromJson(json['features']),
        overallScore: (json['overallScore'] as num).toDouble(),
        overallLabel: json['overallLabel'] as String,
      );
}
