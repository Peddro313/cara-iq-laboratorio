import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/analysis.dart';
import '../services/analysis_repository.dart';
import '../services/scoring_engine.dart';
import '../services/face_detector_service.dart';

final analysisRepositoryProvider = Provider<AnalysisRepository>((ref) {
  return AnalysisRepository();
});

final faceDetectorProvider = Provider<FaceDetectorService>((ref) {
  final service = FaceDetectorService();
  ref.onDispose(() => service.dispose());
  return service;
});

final analysesProvider = FutureProvider<List<AnalysisResult>>((ref) async {
  final repo = ref.watch(analysisRepositoryProvider);
  return repo.getAll();
});

final analysisByIdProvider =
    FutureProvider.family<AnalysisResult?, String>((ref, id) async {
  final repo = ref.watch(analysisRepositoryProvider);
  return repo.getById(id);
});

final runAnalysisProvider = Provider((ref) {
  return ({
    required List<FacialLandmark> frontLandmarks,
    required List<FacialLandmark> sideLandmarks,
    String? frontPhotoPath,
    String? sidePhotoPath,
  }) async {
    final result = ScoringEngine.analyze(
      frontLandmarks: frontLandmarks,
      sideLandmarks: sideLandmarks,
      frontPhotoPath: frontPhotoPath,
      sidePhotoPath: sidePhotoPath,
    );
    final repo = ref.read(analysisRepositoryProvider);
    await repo.save(result);
    ref.invalidate(analysesProvider);
    return result;
  };
});

/// Front face is required and drives the scores.
/// Side is attempted but does not invent fake landmarks.
final runPhotoAnalysisProvider = Provider((ref) {
  return ({
    required String frontPhotoPath,
    required String sidePhotoPath,
  }) async {
    final detector = ref.read(faceDetectorProvider);

    final front = await detector.detectFromFile(frontPhotoPath);
    if (front.length < 5) {
      throw Exception('Could not detect enough facial points. Try a clearer front photo.');
    }

    List<FacialLandmark> side = const [];
    try {
      side = await detector.detectFromFile(sidePhotoPath);
    } catch (_) {
      // Side often fails on true profiles — scores still come from front
      side = const [];
    }

    final runner = ref.read(runAnalysisProvider);
    return runner(
      frontLandmarks: front,
      sideLandmarks: side,
      frontPhotoPath: frontPhotoPath,
      sidePhotoPath: sidePhotoPath,
    );
  };
});
