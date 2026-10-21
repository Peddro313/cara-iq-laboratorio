import 'dart:io';
import 'dart:math' as math;
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import '../models/analysis.dart';
import 'landmark_service.dart';

/// Detects faces with Google ML Kit and maps landmarks into our format.
class FaceDetectorService {
  FaceDetectorService() {
    _detector = FaceDetector(
      options: FaceDetectorOptions(
        enableContours: true,
        enableLandmarks: true,
        performanceMode: FaceDetectorMode.accurate,
        minFaceSize: 0.15,
      ),
    );
  }

  late final FaceDetector _detector;

  Future<List<FacialLandmark>> detectFromFile(String path) async {
    final input = InputImage.fromFilePath(path);
    final faces = await _detector.processImage(input);

    if (faces.isEmpty) {
      throw Exception('No face detected. Use a clear front-facing photo with good lighting.');
    }

    final face = faces.first;
    return _mapFaceToLandmarks(face);
  }

  List<FacialLandmark> _mapFaceToLandmarks(Face face) {
    final points = <FacialLandmark>[];

    void addLandmark(FaceLandmarkType type, int index) {
      final lm = face.landmarks[type];
      if (lm != null) {
        points.add(FacialLandmark(
          index: index,
          x: lm.position.x.toDouble(),
          y: lm.position.y.toDouble(),
          z: 0,
        ));
      }
    }

    // Map ML Kit landmarks to our MediaPipe-style indices
    addLandmark(FaceLandmarkType.leftEye, FaceLandmarkIndex.leftEyeOuter);
    addLandmark(FaceLandmarkType.rightEye, FaceLandmarkIndex.rightEyeOuter);
    addLandmark(FaceLandmarkType.noseBase, FaceLandmarkIndex.noseTip);
    addLandmark(FaceLandmarkType.leftMouth, FaceLandmarkIndex.mouthLeft);
    addLandmark(FaceLandmarkType.rightMouth, FaceLandmarkIndex.mouthRight);
    addLandmark(FaceLandmarkType.leftCheek, FaceLandmarkIndex.leftCheek);
    addLandmark(FaceLandmarkType.rightCheek, FaceLandmarkIndex.rightCheek);
    addLandmark(FaceLandmarkType.leftEar, FaceLandmarkIndex.leftJawAngle);
    addLandmark(FaceLandmarkType.rightEar, FaceLandmarkIndex.rightJawAngle);

    // Contours give denser geometry
    void addContour(FaceContourType type, int startIndex) {
      final contour = face.contours[type];
      if (contour == null) return;
      for (var i = 0; i < contour.points.length; i++) {
        final p = contour.points[i];
        points.add(FacialLandmark(
          index: startIndex + i,
          x: p.x.toDouble(),
          y: p.y.toDouble(),
          z: 0,
        ));
      }
    }

    addContour(FaceContourType.face, 1000);
    addContour(FaceContourType.leftEyebrowTop, 1100);
    addContour(FaceContourType.rightEyebrowTop, 1200);
    addContour(FaceContourType.upperLipTop, 1300);
    addContour(FaceContourType.lowerLipBottom, 1400);
    addContour(FaceContourType.noseBridge, 1500);
    addContour(FaceContourType.noseBottom, 1600);

    // Derive key points from bounding box + contours when landmarks are sparse
    final box = face.boundingBox;
    final cx = box.center.dx;
    final top = box.top;
    final bottom = box.bottom;

    // Forehead / chin approximations from face contour or box
    final faceContour = face.contours[FaceContourType.face];
    if (faceContour != null && faceContour.points.isNotEmpty) {
      final pts = faceContour.points;
      var topPt = pts.first;
      var bottomPt = pts.first;
      for (final p in pts) {
        if (p.y < topPt.y) topPt = p;
        if (p.y > bottomPt.y) bottomPt = p;
      }
      points.add(FacialLandmark(
        index: FaceLandmarkIndex.foreheadTop,
        x: topPt.x.toDouble(),
        y: topPt.y.toDouble(),
        z: 0,
      ));
      points.add(FacialLandmark(
        index: FaceLandmarkIndex.chin,
        x: bottomPt.x.toDouble(),
        y: bottomPt.y.toDouble(),
        z: 0,
      ));
    } else {
      points.add(FacialLandmark(
        index: FaceLandmarkIndex.foreheadTop,
        x: cx,
        y: top,
        z: 0,
      ));
      points.add(FacialLandmark(
        index: FaceLandmarkIndex.chin,
        x: cx,
        y: bottom,
        z: 0,
      ));
    }

    // Nose bridge from contour or midpoint
    final noseBridge = face.contours[FaceContourType.noseBridge];
    if (noseBridge != null && noseBridge.points.isNotEmpty) {
      final p = noseBridge.points.first;
      points.add(FacialLandmark(
        index: FaceLandmarkIndex.noseBridge,
        x: p.x.toDouble(),
        y: p.y.toDouble(),
        z: 0,
      ));
    }

    // Inner eye approx from eye positions
    final leftEye = face.landmarks[FaceLandmarkType.leftEye];
    final rightEye = face.landmarks[FaceLandmarkType.rightEye];
    if (leftEye != null && rightEye != null) {
      final midX = (leftEye.position.x + rightEye.position.x) / 2;
      points.add(FacialLandmark(
        index: FaceLandmarkIndex.leftEyeInner,
        x: (leftEye.position.x + midX) / 2,
        y: leftEye.position.y.toDouble(),
        z: 0,
      ));
      points.add(FacialLandmark(
        index: FaceLandmarkIndex.rightEyeInner,
        x: (rightEye.position.x + midX) / 2,
        y: rightEye.position.y.toDouble(),
        z: 0,
      ));
    }

    // Nose left/right from nose bottom contour
    final noseBottom = face.contours[FaceContourType.noseBottom];
    if (noseBottom != null && noseBottom.points.length >= 2) {
      final leftmost = noseBottom.points.reduce((a, b) => a.x < b.x ? a : b);
      final rightmost = noseBottom.points.reduce((a, b) => a.x > b.x ? a : b);
      points.add(FacialLandmark(
        index: FaceLandmarkIndex.noseLeft,
        x: leftmost.x.toDouble(),
        y: leftmost.y.toDouble(),
        z: 0,
      ));
      points.add(FacialLandmark(
        index: FaceLandmarkIndex.noseRight,
        x: rightmost.x.toDouble(),
        y: rightmost.y.toDouble(),
        z: 0,
      ));
    }

    return points;
  }

  void dispose() {
    _detector.close();
  }
}
