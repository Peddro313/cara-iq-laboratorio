import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/analysis.dart';
import '../services/analysis_repository.dart';
import '../services/scoring_engine.dart';
import '../services/landmark_service.dart';

final analysisRepositoryProvider = Provider<AnalysisRepository>((ref) {
  return AnalysisRepository();
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

/// Runs a full analysis from front + side landmarks and saves it.
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

    // Invalidate list so History updates
    ref.invalidate(analysesProvider);

    return result;
  };
});

/// Convenience provider that uses demo landmarks (until real MediaPipe is wired).
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
