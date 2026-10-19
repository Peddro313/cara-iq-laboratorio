import 'dart:math' as math;
import '../models/analysis.dart';

/// MediaPipe Face Mesh landmark indices (478 points).
/// Official mapping from Google MediaPipe Face Landmarker.
class FaceLandmarkIndex {
  // Face oval / contour
  static const int chin = 152;
  static const int foreheadTop = 10;
  static const int leftCheek = 234;
  static const int rightCheek = 454;

  // Eyes
  static const int leftEyeOuter = 33;
  static const int leftEyeInner = 133;
  static const int rightEyeOuter = 263;
  static const int rightEyeInner = 362;
  static const int leftEyeUpper = 159;
  static const int leftEyeLower = 145;
  static const int rightEyeUpper = 386;
  static const int rightEyeLower = 374;

  // Nose
  static const int noseTip = 1;
  static const int noseBridge = 6;
  static const int noseLeft = 98;
  static const int noseRight = 327;
  static const int noseBottom = 2;

  // Mouth
  static const int mouthLeft = 61;
  static const int mouthRight = 291;
  static const int upperLip = 13;
  static const int lowerLip = 14;

  // Jaw / Angularity
  static const int leftJawAngle = 172;
  static const int rightJawAngle = 397;
  static const int leftMandible = 136;
  static const int rightMandible = 365;

  // Midface / cheeks
  static const int leftZygomatic = 116;
  static const int rightZygomatic = 345;

  // Eyebrows
  static const int leftBrowInner = 55;
  static const int leftBrowOuter = 70;
  static const int rightBrowInner = 285;
  static const int rightBrowOuter = 300;
}

class LandmarkService {
  /// Calculate Euclidean distance between two landmarks (2D for most ratios).
  static double distance(FacialLandmark a, FacialLandmark b) {
    final dx = a.x - b.x;
    final dy = a.y - b.y;
    return math.sqrt(dx * dx + dy * dy);
  }

  /// Calculate angle at point B formed by points A-B-C (in degrees).
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

  /// Find landmark by index. Returns null if not found.
  static FacialLandmark? byIndex(List<FacialLandmark> landmarks, int index) {
    try {
      return landmarks.firstWhere((l) => l.index == index);
    } catch (_) {
      return null;
    }
  }

  /// Compute a comprehensive set of facial ratios from front landmarks.
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

    // Face height & width
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

    // Facial thirds
    if (forehead != null && chin != null && noseBridge != null && noseTip != null) {
      final total = distance(forehead, chin);
      if (total > 0) {
        final upper = distance(forehead, noseBridge);
        final middle = distance(noseBridge, noseTip);
        final lower = distance(noseTip, chin);
        ratios['facial_thirds_upper'] = upper / total;
        ratios['facial_thirds_middle'] = middle / total;
        ratios['facial_thirds_lower'] = lower / total;
      }
    }

    // Eye spacing
    if (leftEyeOuter != null && rightEyeOuter != null &&
        leftEyeInner != null && rightEyeInner != null) {
      final leftEyeWidth = distance(leftEyeOuter, leftEyeInner);
      final rightEyeWidth = distance(rightEyeOuter, rightEyeInner);
      final avgEyeWidth = (leftEyeWidth + rightEyeWidth) / 2;
      final interInner = distance(leftEyeInner, rightEyeInner);

      if (avgEyeWidth > 0) {
        ratios['eye_spacing'] = interInner / avgEyeWidth;
      }
    }

    // Nose width to mouth width
    if (noseLeft != null && noseRight != null &&
        mouthLeft != null && mouthRight != null) {
      final noseWidth = distance(noseLeft, noseRight);
      final mouthWidth = distance(mouthLeft, mouthRight);
      if (mouthWidth > 0) {
        ratios['nose_width_to_mouth'] = noseWidth / mouthWidth;
      }
    }

    // Jaw to cheek width
    if (leftJaw != null && rightJaw != null &&
        leftCheek != null && rightCheek != null) {
      final jawWidth = distance(leftJaw, rightJaw);
      final cheekWidth = distance(leftCheek, rightCheek);
      if (cheekWidth > 0) {
        ratios['jaw_to_cheek_width'] = jawWidth / cheekWidth;
      }
    }

    // Jaw angle approximation
    if (leftJaw != null && chin != null && rightJaw != null) {
      final jawAngle = angle(leftJaw, chin, rightJaw);
      ratios['jaw_angle'] = jawAngle;
    }

    // Canthal tilt
    if (leftEyeOuter != null && leftEyeInner != null) {
      final dy = leftEyeInner.y - leftEyeOuter.y;
      final dx = leftEyeInner.x - leftEyeOuter.x;
      if (dx != 0) {
        final tilt = math.atan(dy / dx) * 180 / math.pi;
        ratios['canthal_tilt_left'] = tilt;
      }
    }

    return ratios;
  }

  /// Generate realistic demo landmarks for testing when MediaPipe is not yet connected.
  static List<FacialLandmark> generateDemoLandmarks({bool sideView = false}) {
    if (sideView) {
      return [
        FacialLandmark(index: FaceLandmarkIndex.foreheadTop, x: 0.55, y: 0.15, z: 0),
        FacialLandmark(index: FaceLandmarkIndex.noseBridge, x: 0.62, y: 0.35, z: 0),
        FacialLandmark(index: FaceLandmarkIndex.noseTip, x: 0.72, y: 0.48, z: 0),
        FacialLandmark(index: FaceLandmarkIndex.chin, x: 0.58, y: 0.85, z: 0),
        FacialLandmark(index: FaceLandmarkIndex.upperLip, x: 0.60, y: 0.62, z: 0),
        FacialLandmark(index: FaceLandmarkIndex.lowerLip, x: 0.59, y: 0.68, z: 0),
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
