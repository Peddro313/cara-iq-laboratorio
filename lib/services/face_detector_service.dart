import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import '../models/analysis.dart';
import 'landmark_service.dart';

/// Detects face with ML Kit and builds normalized landmarks from
/// both key landmarks and contours so measurements actually vary.
class FaceDetectorService {
  FaceDetectorService() {
    _detector = FaceDetector(
      options: FaceDetectorOptions(
        enableContours: true,
        enableLandmarks: true,
        enableClassification: true,
        performanceMode: FaceDetectorMode.accurate,
        minFaceSize: 0.08,
      ),
    );
  }

  late final FaceDetector _detector;

  Future<List<FacialLandmark>> detectFromFile(String path) async {
    final input = InputImage.fromFilePath(path);
    final faces = await _detector.processImage(input);

    if (faces.isEmpty) {
      throw Exception('No face detected. Use a clear photo with the full face visible.');
    }

    faces.sort((a, b) => (b.boundingBox.width * b.boundingBox.height)
        .compareTo(a.boundingBox.width * a.boundingBox.height));
    final face = faces.first;
    final box = face.boundingBox;

    if (box.width < 30 || box.height < 30) {
      throw Exception('Face is too small. Move closer or crop tighter.');
    }

    return _buildLandmarks(face);
  }

  FacialLandmark _n(int index, double x, double y, double left, double top, double w, double h) {
    return FacialLandmark(
      index: index,
      x: ((x - left) / w).clamp(0.0, 1.0),
      y: ((y - top) / h).clamp(0.0, 1.0),
      z: 0,
    );
  }

  List<FacialLandmark> _buildLandmarks(Face face) {
    final box = face.boundingBox;
    final left = box.left;
    final top = box.top;
    final w = box.width;
    final h = box.height;
    final points = <FacialLandmark>[];

    void addLm(FaceLandmarkType type, int index) {
      final lm = face.landmarks[type];
      if (lm == null) return;
      points.add(_n(index, lm.position.x.toDouble(), lm.position.y.toDouble(), left, top, w, h));
    }

    addLm(FaceLandmarkType.leftEye, FaceLandmarkIndex.leftEyeOuter);
    addLm(FaceLandmarkType.rightEye, FaceLandmarkIndex.rightEyeOuter);
    addLm(FaceLandmarkType.noseBase, FaceLandmarkIndex.noseTip);
    addLm(FaceLandmarkType.leftMouth, FaceLandmarkIndex.mouthLeft);
    addLm(FaceLandmarkType.rightMouth, FaceLandmarkIndex.mouthRight);
    addLm(FaceLandmarkType.leftCheek, FaceLandmarkIndex.leftCheek);
    addLm(FaceLandmarkType.rightCheek, FaceLandmarkIndex.rightCheek);

    // Face oval — most reliable for shape
    final oval = face.contours[FaceContourType.face]?.points;
    if (oval != null && oval.isNotEmpty) {
      var topP = oval.first, bottomP = oval.first, leftP = oval.first, rightP = oval.first;
      for (final p in oval) {
        if (p.y < topP.y) topP = p;
        if (p.y > bottomP.y) bottomP = p;
        if (p.x < leftP.x) leftP = p;
        if (p.x > rightP.x) rightP = p;
      }
      points.add(_n(FaceLandmarkIndex.foreheadTop, topP.x.toDouble(), topP.y.toDouble(), left, top, w, h));
      points.add(_n(FaceLandmarkIndex.chin, bottomP.x.toDouble(), bottomP.y.toDouble(), left, top, w, h));

      // Better jaw points from lower half of oval
      final lower = oval.where((p) => p.y > top + h * 0.50).toList();
      if (lower.length >= 2) {
        var jl = lower.first, jr = lower.first;
        for (final p in lower) {
          if (p.x < jl.x) jl = p;
          if (p.x > jr.x) jr = p;
        }
        points.add(_n(FaceLandmarkIndex.leftJawAngle, jl.x.toDouble(), jl.y.toDouble(), left, top, w, h));
        points.add(_n(FaceLandmarkIndex.rightJawAngle, jr.x.toDouble(), jr.y.toDouble(), left, top, w, h));
      }
    }

    // Nose bridge
    final bridge = face.contours[FaceContourType.noseBridge]?.points;
    if (bridge != null && bridge.isNotEmpty) {
      final p = bridge.first;
      points.add(_n(FaceLandmarkIndex.noseBridge, p.x.toDouble(), p.y.toDouble(), left, top, w, h));
    } else {
      final le = face.landmarks[FaceLandmarkType.leftEye];
      final re = face.landmarks[FaceLandmarkType.rightEye];
      final nose = face.landmarks[FaceLandmarkType.noseBase];
      if (le != null && re != null && nose != null) {
        final mx = (le.position.x + re.position.x) / 2.0;
        final my = (le.position.y + re.position.y) / 2.0;
        points.add(_n(FaceLandmarkIndex.noseBridge, mx, (my + nose.position.y) / 2.0, left, top, w, h));
      }
    }

    // Nose width
    final noseBot = face.contours[FaceContourType.noseBottom]?.points;
    if (noseBot != null && noseBot.length >= 2) {
      var nl = noseBot.first, nr = noseBot.first;
      for (final p in noseBot) {
        if (p.x < nl.x) nl = p;
        if (p.x > nr.x) nr = p;
      }
      points.add(_n(FaceLandmarkIndex.noseLeft, nl.x.toDouble(), nl.y.toDouble(), left, top, w, h));
      points.add(_n(FaceLandmarkIndex.noseRight, nr.x.toDouble(), nr.y.toDouble(), left, top, w, h));
    }

    // Eye inner approximation
    final le = face.landmarks[FaceLandmarkType.leftEye];
    final re = face.landmarks[FaceLandmarkType.rightEye];
    if (le != null && re != null) {
      final midX = (le.position.x + re.position.x) / 2.0;
      points.add(_n(FaceLandmarkIndex.leftEyeInner, (le.position.x + midX) / 2.0, le.position.y.toDouble(), left, top, w, h));
      points.add(_n(FaceLandmarkIndex.rightEyeInner, (re.position.x + midX) / 2.0, re.position.y.toDouble(), left, top, w, h));
    }

    // Cheeks fallback from oval extremes if missing
    if (!points.any((p) => p.index == FaceLandmarkIndex.leftCheek) && oval != null) {
      var leftMost = oval.first;
      for (final p in oval) {
        if (p.x < leftMost.x) leftMost = p;
      }
      points.add(_n(FaceLandmarkIndex.leftCheek, leftMost.x.toDouble(), leftMost.y.toDouble(), left, top, w, h));
    }
    if (!points.any((p) => p.index == FaceLandmarkIndex.rightCheek) && oval != null) {
      var rightMost = oval.first;
      for (final p in oval) {
        if (p.x > rightMost.x) rightMost = p;
      }
      points.add(_n(FaceLandmarkIndex.rightCheek, rightMost.x.toDouble(), rightMost.y.toDouble(), left, top, w, h));
    }

    return points;
  }

  void dispose() => _detector.close();
}
