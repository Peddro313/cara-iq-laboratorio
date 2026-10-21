import 'dart:math' as math;
import '../models/analysis.dart';

class FaceLandmarkIndex {
  static const int chin = 152;
  static const int foreheadTop = 10;
  static const int leftCheek = 234;
  static const int rightCheek = 454;
  static const int leftEyeOuter = 33;
  static const int leftEyeInner = 133;
  static const int rightEyeOuter = 263;
  static const int rightEyeInner = 362;
  static const int noseTip = 1;
  static const int noseBridge = 6;
  static const int noseLeft = 98;
  static const int noseRight = 327;
  static const int mouthLeft = 61;
  static const int mouthRight = 291;
  static const int leftJawAngle = 172;
  static const int rightJawAngle = 397;
}

class LandmarkService {
  static double distance(FacialLandmark a, FacialLandmark b) {
    final dx = a.x - b.x;
    final dy = a.y - b.y;
    return math.sqrt(dx * dx + dy * dy);
  }

  static double angle(FacialLandmark a, FacialLandmark b, FacialLandmark c) {
    final abx = a.x - b.x;
    final aby = a.y - b.y;
    final cbx = c.x - b.x;
    final cby = c.y - b.y;
    final dot = abx * cbx + aby * cby;
    final magAB = math.sqrt(abx * abx + aby * aby);
    final magCB = math.sqrt(cbx * cbx + cby * cby);
    if (magAB == 0 || magCB == 0) return 0;
    final cosTheta = (dot / (magAB * magCB)).clamp(-1.0, 1.0);
    return math.acos(cosTheta) * 180 / math.pi;
  }

  static FacialLandmark? byIndex(List<FacialLandmark> landmarks, int index) {
    try {
      return landmarks.firstWhere((l) => l.index == index);
    } catch (_) {
      return null;
    }
  }

  /// Compute ratios that actually vary with face shape.
  static Map<String, double> computeRatios({
    required List<FacialLandmark> front,
    List<FacialLandmark> side = const [],
  }) {
    final ratios = <String, double>{};
    FacialLandmark? get(int i) => byIndex(front, i);

    final forehead = get(FaceLandmarkIndex.foreheadTop);
    final chin = get(FaceLandmarkIndex.chin);
    final leftCheek = get(FaceLandmarkIndex.leftCheek);
    final rightCheek = get(FaceLandmarkIndex.rightCheek);
    final noseTip = get(FaceLandmarkIndex.noseTip);
    final noseBridge = get(FaceLandmarkIndex.noseBridge);
    final leftEyeOuter = get(FaceLandmarkIndex.leftEyeOuter);
    final rightEyeOuter = get(FaceLandmarkIndex.rightEyeOuter);
    final leftEyeInner = get(FaceLandmarkIndex.leftEyeInner);
    final rightEyeInner = get(FaceLandmarkIndex.rightEyeInner);
    final mouthLeft = get(FaceLandmarkIndex.mouthLeft);
    final mouthRight = get(FaceLandmarkIndex.mouthRight);
    final noseLeft = get(FaceLandmarkIndex.noseLeft);
    final noseRight = get(FaceLandmarkIndex.noseRight);
    final leftJaw = get(FaceLandmarkIndex.leftJawAngle);
    final rightJaw = get(FaceLandmarkIndex.rightJawAngle);

    if (forehead != null && chin != null) {
      final faceHeight = distance(forehead, chin);
      ratios['face_height'] = faceHeight;

      if (leftCheek != null && rightCheek != null) {
        final faceWidth = distance(leftCheek, rightCheek);
        ratios['face_width'] = faceWidth;
        if (faceHeight > 0) {
          ratios['face_width_to_height'] = faceWidth / faceHeight;
        }
      }
    }

    // Facial thirds — these change a lot between faces
    if (forehead != null && chin != null && noseBridge != null && noseTip != null) {
      final total = distance(forehead, chin);
      if (total > 0) {
        ratios['facial_thirds_upper'] = distance(forehead, noseBridge) / total;
        ratios['facial_thirds_middle'] = distance(noseBridge, noseTip) / total;
        ratios['facial_thirds_lower'] = distance(noseTip, chin) / total;
      }
    }

    // Eye spacing relative to eye width
    if (leftEyeOuter != null && rightEyeOuter != null &&
        leftEyeInner != null && rightEyeInner != null) {
      final leftW = distance(leftEyeOuter, leftEyeInner);
      final rightW = distance(rightEyeOuter, rightEyeInner);
      final avgEye = (leftW + rightW) / 2;
      final inter = distance(leftEyeInner, rightEyeInner);
      if (avgEye > 0) ratios['eye_spacing'] = inter / avgEye;

      // Canthal tilt (positive = outer higher than inner in image coords? depends on orientation)
      final dy = leftEyeOuter.y - leftEyeInner.y;
      final dx = leftEyeOuter.x - leftEyeInner.x;
      if (dx != 0) {
        ratios['canthal_tilt_left'] = math.atan(dy / dx) * 180 / math.pi;
      }
    }

    // Nose width vs mouth width
    if (noseLeft != null && noseRight != null && mouthLeft != null && mouthRight != null) {
      final noseW = distance(noseLeft, noseRight);
      final mouthW = distance(mouthLeft, mouthRight);
      if (mouthW > 0) ratios['nose_width_to_mouth'] = noseW / mouthW;
    }

    // Jaw vs cheek
    if (leftJaw != null && rightJaw != null && leftCheek != null && rightCheek != null) {
      final jawW = distance(leftJaw, rightJaw);
      final cheekW = distance(leftCheek, rightCheek);
      if (cheekW > 0) ratios['jaw_to_cheek_width'] = jawW / cheekW;
    }

    // Jaw angle at chin
    if (leftJaw != null && chin != null && rightJaw != null) {
      ratios['jaw_angle'] = angle(leftJaw, chin, rightJaw);
    }

    // Eye-to-eye distance relative to face width
    if (leftEyeOuter != null && rightEyeOuter != null && leftCheek != null && rightCheek != null) {
      final eyeSpan = distance(leftEyeOuter, rightEyeOuter);
      final faceW = distance(leftCheek, rightCheek);
      if (faceW > 0) ratios['eye_span_to_face'] = eyeSpan / faceW;
    }

    // Mouth width relative to face
    if (mouthLeft != null && mouthRight != null && leftCheek != null && rightCheek != null) {
      final mouthW = distance(mouthLeft, mouthRight);
      final faceW = distance(leftCheek, rightCheek);
      if (faceW > 0) ratios['mouth_to_face_width'] = mouthW / faceW;
    }

    return ratios;
  }

  static List<FacialLandmark> generateDemoLandmarks({bool sideView = false}) {
    if (sideView) {
      return [
        FacialLandmark(index: FaceLandmarkIndex.foreheadTop, x: 0.55, y: 0.15, z: 0),
        FacialLandmark(index: FaceLandmarkIndex.noseBridge, x: 0.62, y: 0.35, z: 0),
        FacialLandmark(index: FaceLandmarkIndex.noseTip, x: 0.72, y: 0.48, z: 0),
        FacialLandmark(index: FaceLandmarkIndex.chin, x: 0.58, y: 0.85, z: 0),
      ];
    }
    return [
      FacialLandmark(index: FaceLandmarkIndex.foreheadTop, x: 0.50, y: 0.12, z: 0),
      FacialLandmark(index: FaceLandmarkIndex.chin, x: 0.50, y: 0.92, z: 0),
      FacialLandmark(index: FaceLandmarkIndex.leftCheek, x: 0.18, y: 0.48, z: 0),
      FacialLandmark(index: FaceLandmarkIndex.rightCheek, x: 0.82, y: 0.48, z: 0),
      FacialLandmark(index: FaceLandmarkIndex.noseTip, x: 0.50, y: 0.52, z: 0),
      FacialLandmark(index: FaceLandmarkIndex.noseBridge, x: 0.50, y: 0.38, z: 0),
      FacialLandmark(index: FaceLandmarkIndex.noseLeft, x: 0.42, y: 0.50, z: 0),
      FacialLandmark(index: FaceLandmarkIndex.noseRight, x: 0.58, y: 0.50, z: 0),
      FacialLandmark(index: FaceLandmarkIndex.leftEyeOuter, x: 0.28, y: 0.35, z: 0),
      FacialLandmark(index: FaceLandmarkIndex.leftEyeInner, x: 0.40, y: 0.35, z: 0),
      FacialLandmark(index: FaceLandmarkIndex.rightEyeOuter, x: 0.72, y: 0.35, z: 0),
      FacialLandmark(index: FaceLandmarkIndex.rightEyeInner, x: 0.60, y: 0.35, z: 0),
      FacialLandmark(index: FaceLandmarkIndex.mouthLeft, x: 0.38, y: 0.68, z: 0),
      FacialLandmark(index: FaceLandmarkIndex.mouthRight, x: 0.62, y: 0.68, z: 0),
      FacialLandmark(index: FaceLandmarkIndex.leftJawAngle, x: 0.22, y: 0.72, z: 0),
      FacialLandmark(index: FaceLandmarkIndex.rightJawAngle, x: 0.78, y: 0.72, z: 0),
    ];
  }
}
