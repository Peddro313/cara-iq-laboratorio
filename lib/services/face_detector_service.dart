import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import '../models/analysis.dart';
import 'landmark_service.dart';

/// Detects a face with Google ML Kit and builds reliable landmarks
/// in **normalized 0–1 coordinates** relative to the face bounding box
/// (so off-center faces still score correctly).
class FaceDetectorService {
  FaceDetectorService() {
    _detector = FaceDetector(
      options: FaceDetectorOptions(
        enableContours: true,
        enableLandmarks: true,
        enableClassification: false,
        performanceMode: FaceDetectorMode.accurate,
        minFaceSize: 0.1,
      ),
    );
  }

  late final FaceDetector _detector;

  Future<List<FacialLandmark>> detectFromFile(String path) async {
    final input = InputImage.fromFilePath(path);
    final faces = await _detector.processImage(input);

    if (faces.isEmpty) {
      throw Exception(
        'No face detected. Use a clear photo with the full face visible.',
      );
    }

    // Largest face (works even if not centered)
    faces.sort(
      (a, b) => (b.boundingBox.width * b.boundingBox.height)
          .compareTo(a.boundingBox.width * b.boundingBox.height),
    );
    final face = faces.first;

    final box = face.boundingBox;
    if (box.width < 40 || box.height < 40) {
      throw Exception('Face is too small in the frame. Move closer.');
    }

    return _buildLandmarks(face);
  }

  /// Normalize image-pixel point → 0–1 relative to face box
  FacialLandmark _n(int index, double x, double y, double left, double top,
      double w, double h) {
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
      points.add(_n(
        index,
        lm.position.x.toDouble(),
        lm.position.y.toDouble(),
        left,
        top,
        w,
        h,
      ));
    }

    addLm(FaceLandmarkType.leftEye, FaceLandmarkIndex.leftEyeOuter);
    addLm(FaceLandmarkType.rightEye, FaceLandmarkIndex.rightEyeOuter);
    addLm(FaceLandmarkType.noseBase, FaceLandmarkIndex.noseTip);
    addLm(FaceLandmarkType.leftMouth, FaceLandmarkIndex.mouthLeft);
    addLm(FaceLandmarkType.rightMouth, FaceLandmarkIndex.mouthRight);
    addLm(FaceLandmarkType.leftCheek, FaceLandmarkIndex.leftCheek);
    addLm(FaceLandmarkType.rightCheek, FaceLandmarkIndex.rightCheek);
    addLm(FaceLandmarkType.leftEar, FaceLandmarkIndex.leftJawAngle);
    addLm(FaceLandmarkType.rightEar, FaceLandmarkIndex.rightJawAngle);

    // Face oval contour → forehead + chin + better cheeks/jaw
    final oval = face.contours[FaceContourType.face]?.points;
    if (oval != null && oval.isNotEmpty) {
      var topP = oval.first;
      var bottomP = oval.first;
      var leftP = oval.first;
      var rightP = oval.first;
      for (final p in oval) {
        if (p.y < topP.y) topP = p;
        if (p.y > bottomP.y) bottomP = p;
        if (p.x < leftP.x) leftP = p;
        if (p.x > rightP.x) rightP = p;
      }
      points.add(_n(FaceLandmarkIndex.foreheadTop, topP.x.toDouble(),
          topP.y.toDouble(), left, top, w, h));
      points.add(_n(FaceLandmarkIndex.chin, bottomP.x.toDouble(),
          bottomP.y.toDouble(), left, top, w, h));

      // Approximate jaw angles from lower third of oval
      final lower = oval.where((p) => p.y > top + h * 0.55).toList();
      if (lower.length >= 2) {
        var jl = lower.first;
        var jr = lower.first;
        for (final p in lower) {
          if (p.x < jl.x) jl = p;
          if (p.x > jr.x) jr = p;
        }
        points.add(_n(FaceLandmarkIndex.leftJawAngle, jl.x.toDouble(),
            jl.y.toDouble(), left, top, w, h));
        points.add(_n(FaceLandmarkIndex.rightJawAngle, jr.x.toDouble(),
            jr.y.toDouble(), left, top, w, h));
      }
    } else {
      // Box-based fallback
      points.add(_n(FaceLandmarkIndex.foreheadTop, left + w / 2, top, left, top, w, h));
      points.add(_n(FaceLandmarkIndex.chin, left + w / 2, top + h, left, top, w, h));
    }

    // Nose bridge from contour
    final bridge = face.contours[FaceContourType.noseBridge]?.points;
    if (bridge != null && bridge.isNotEmpty) {
      final p = bridge.first;
      points.add(_n(FaceLandmarkIndex.noseBridge, p.x.toDouble(), p.y.toDouble(),
          left, top, w, h));
    } else {
      // Midpoint between eyes and nose tip
      final le = face.landmarks[FaceLandmarkType.leftEye];
      final re = face.landmarks[FaceLandmarkType.rightEye];
      final nose = face.landmarks[FaceLandmarkType.noseBase];
      if (le != null && re != null && nose != null) {
        final mx = (le.position.x + re.position.x) / 2;
        final my = (le.position.y + re.position.y) / 2;
        points.add(_n(
          FaceLandmarkIndex.noseBridge,
          mx,
          (my + nose.position.y) / 2,
          left,
          top,
          w,
          h,
        ));
      }
    }

    // Nose width from nose bottom contour
    final noseBottom = face.contours[FaceContourType.noseBottom]?.points;
    if (noseBottom != null && noseBottom.length >= 2) {
      var nl = noseBottom.first;
      var nr = noseBottom.first;
      for (final p in noseBottom) {
        if (p.x < nl.x) nl = p;
        if (p.x > nr.x) nr = p;
      }
      points.add(_n(FaceLandmarkIndex.noseLeft, nl.x.toDouble(), nl.y.toDouble(),
          left, top, w, h));
      points.add(_n(FaceLandmarkIndex.noseRight, nr.x.toDouble(),
          nr.y.toDouble(), left, top, w, h));
    }

    // Inner eye corners approximated between left/right eye landmarks
    final le = face.landmarks[FaceLandmarkType.leftEye];
    final re = face.landmarks[FaceLandmarkType.rightEye];
    if (le != null && re != null) {
      final midX = (le.position.x + re.position.x) / 2;
      points.add(_n(
        FaceLandmarkIndex.leftEyeInner,
        (le.position.x + midX) / 2,
        le.position.y.toDouble(),
        left,
        top,
        w,
        h,
      ));
      points.add(_n(
        FaceLandmarkIndex.rightEyeInner,
        (re.position.x + midX) / 2,
        re.position.y.toDouble(),
        left,
        top,
        w,
        h,
      ));
    }

    // Ensure cheeks exist
    final hasLeftCheek =
        points.any((p) => p.index == FaceLandmarkIndex.leftCheek);
    final hasRightCheek =
        points.any((p) => p.index == FaceLandmarkIndex.rightCheek);
    if (!hasLeftCheek || !hasRightCheek) {
      points.add(_n(FaceLandmarkIndex.leftCheek, left, top + h * 0.45, left, top, w, h));
      points.add(_n(
          FaceLandmarkIndex.rightCheek, left + w, top + h * 0.45, left, top, w, h));
    }

    return points;
  }

  void dispose() {
    _detector.close();
  }
}
