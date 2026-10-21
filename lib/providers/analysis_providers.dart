import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/analysis.dart';
import '../services/analysis_repository.dart';
import '../services/scoring_engine.dart';
import '../services/landmark_service.dart';
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

/// Runs analysis from front + side landmarks and saves it.
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

/// Detect faces from photos (ML Kit) with demo fallback, then score.
final runPhotoAnalysisProvider = Provider((ref) {
  return ({
    required String frontPhotoPath,
    required String sidePhotoPath,
  }) async {
    final detector = ref.read(faceDetectorProvider);
    List<FacialLandmark> front;
    List<FacialLandmark> side;

    try {
      front = await detector.detectFromFile(frontPhotoPath);
    } catch (_) {
      front = LandmarkService.generateDemoLandmarks();
    }

    try {
      side = await detector.detectFromFile(sidePhotoPath);
    } catch (_) {
      side = LandmarkService.generateDemoLandmarks(sideView: true);
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

/// Legacy demo-only runner (kept for testing).
final runDemoAnalysisProvider = Provider((ref) {
  return ({
    String? frontPhotoPath,
    String? sidePhotoPath,
  }) async {
    final front = LandmarkService.generateDemoLandmarks();
    final side = LandmarkService.generateDemoLandmarks(sideView: true);
    final runner = ref.read(runAnalysisProvider);
    return runner(
      frontLandmarks: front,
      sideLandmarks: side,
      frontPhotoPath: frontPhotoPath,
      sidePhotoPath: sidePhotoPath,
    );
  };
});
