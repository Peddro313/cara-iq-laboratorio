export type Pillar = "harmony" | "structure" | "dimorphism" | "features";

export type Gender = "male" | "female" | "other";

export type Pt = { x: number; y: number; z?: number };

export type Metric = {
  id: string;
  label: string;
  pillar: Pillar;
  raw: number;
  display: string;
  score: number;
};

export type Report = {
  id: string;
  createdAt: string;
  overall: number;
  label: string;
  pillars: Record<Pillar, number>;
  metrics: Metric[];
  note: string;
};

const I = {
  forehead: 10,
  chin: 152,
  leftCheek: 234,
  rightCheek: 454,
  leftOuter: 33,
  leftInner: 133,
  rightOuter: 263,
  rightInner: 362,
  leftEyeTop: 159,
  leftEyeBot: 145,
  rightEyeTop: 386,
  rightEyeBot: 374,
  noseTip: 1,
  subnasale: 2,
  noseLeft: 98,
  noseRight: 327,
  mouthLeft: 61,
  mouthRight: 291,
  lipTop: 13,
  lipBot: 14,
  jawLeft: 172,
  jawRight: 397,
  browLeft: 70,
  browRight: 300,
} as const;

function d(a: Pt, b: Pt) {
  return Math.hypot(a.x - b.x, a.y - b.y);
}

function angleAt(a: Pt, b: Pt, c: Pt) {
  const abx = a.x - b.x;
  const aby = a.y - b.y;
  const cbx = c.x - b.x;
  const cby = c.y - b.y;
  const mag = Math.hypot(abx, aby) * Math.hypot(cbx, cby);
  if (mag === 0) return 0;
  const cos = Math.min(1, Math.max(-1, (abx * cbx + aby * cby) / mag));
  return (Math.acos(cos) * 180) / Math.PI;
}

/** Positive when the outer corner sits higher than the inner corner. */
function canthal(outer: Pt, inner: Pt) {
  return (Math.atan2(inner.y - outer.y, Math.abs(inner.x - outer.x)) * 180) / Math.PI;
}

function bell(value: number, ideal: number, sigma: number) {
  const z = (value - ideal) / sigma;
  const s = 10 * Math.exp(-0.5 * z * z);
  return Math.round(Math.min(9.8, Math.max(2.2, s)) * 10) / 10;
}

function toPx(p: Pt | undefined, w: number, h: number): Pt {
  if (!p) return { x: 0, y: 0 };
  return { x: p.x * w, y: p.y * h, z: p.z };
}

function mean(xs: number[]) {
  if (!xs.length) return 5;
  return Math.round((xs.reduce((a, b) => a + b, 0) / xs.length) * 10) / 10;
}

export function labelFor(score: number) {
  if (score >= 8.8) return "Exceptional";
  if (score >= 7.6) return "Strong";
  if (score >= 6.4) return "Balanced";
  if (score >= 5.2) return "Mixed";
  if (score >= 4) return "Soft";
  return "Low";
}

export function scoreTone(score: number) {
  const t = Math.min(1, Math.max(0, score / 10));
  const hue = t < 0.5 ? 4 + t * 70 : 39 + (t - 0.5) * 170;
  const light = t < 0.55 ? 62 : 58 - (t - 0.55) * 28;
  return `hsl(${hue.toFixed(0)} 68% ${light.toFixed(0)}%)`;
}

export function analyzeFace(landmarks: Pt[], gender: Gender, image: { w: number; h: number }): Report {
  const p = (i: number) => toPx(landmarks[i], image.w, image.h);
  if (!p(I.chin) || !p(I.forehead) || landmarks.length < 400) {
    throw new Error("The face mesh was incomplete. Try a clearer photo.");
  }

  const faceH = d(p(I.forehead), p(I.chin));
  const faceW = d(p(I.leftCheek), p(I.rightCheek));
  const sellionY = p(6).y;
  const topY = p(I.forehead).y;
  const noseY = p(I.subnasale).y;
  const chinY = p(I.chin).y;
  const upper = Math.max(1, sellionY - topY);
  const middle = Math.max(1, noseY - sellionY);
  const lower = Math.max(1, chinY - noseY);
  const thirds = upper + middle + lower || faceH || 1;

  const eyeL = d(p(I.leftOuter), p(I.leftInner));
  const eyeR = d(p(I.rightOuter), p(I.rightInner));
  const eyeAvg = (eyeL + eyeR) / 2 || 1;
  const inter = d(p(I.leftInner), p(I.rightInner));
  const mouthW = d(p(I.mouthLeft), p(I.mouthRight)) || 1;
  const noseW = d(p(I.noseLeft), p(I.noseRight));
  const jawW = d(p(I.jawLeft), p(I.jawRight));
  const lipH = d(p(I.lipTop), p(I.lipBot));
  const eyeOpen =
    (d(p(I.leftEyeTop), p(I.leftEyeBot)) + d(p(I.rightEyeTop), p(I.rightEyeBot))) / 2;
  const tilt =
    (canthal(p(I.leftOuter), p(I.leftInner)) + canthal(p(I.rightOuter), p(I.rightInner))) / 2;
  const jawAng = angleAt(p(I.jawLeft), p(I.chin), p(I.jawRight));
  const browGap = (d(p(I.browLeft), p(I.leftEyeTop)) + d(p(I.browRight), p(I.rightEyeTop))) / 2;

  const wh = faceW / (faceH || 1);
  const thirdsU = upper / thirds;
  const thirdsM = middle / thirds;
  const thirdsL = lower / thirds;
  const eyeSpace = inter / eyeAvg;
  const noseMouth = noseW / mouthW;
  const jawCheek = jawW / (faceW || 1);
  const mouthFace = mouthW / (faceW || 1);
  const lipRatio = lipH / mouthW;
  const eyeRatio = eyeOpen / eyeAvg;
  const browRatio = browGap / (faceH || 1);

  const jawIdeal = gender === "female" ? 0.74 : gender === "male" ? 0.86 : 0.8;
  const jawSigma = 0.08;
  const whIdeal = gender === "female" ? 0.74 : 0.78;

  const metrics: Metric[] = [
    m("thirds_upper", "Upper third", "harmony", thirdsU, pct(thirdsU), bell(thirdsU, 0.33, 0.06)),
    m("thirds_mid", "Middle third", "harmony", thirdsM, pct(thirdsM), bell(thirdsM, 0.28, 0.06)),
    m("thirds_low", "Lower third", "harmony", thirdsL, pct(thirdsL), bell(thirdsL, 0.39, 0.06)),
    m("eye_space", "Eye spacing", "harmony", eyeSpace, ratio(eyeSpace), bell(eyeSpace, 1.05, 0.16)),
    m("nose_mouth", "Nose / mouth", "harmony", noseMouth, ratio(noseMouth), bell(noseMouth, 0.68, 0.12)),
    m("face_wh", "Width / height", "harmony", wh, ratio(wh), bell(wh, whIdeal, 0.07)),
    m("mouth_face", "Mouth / face", "features", mouthFace, ratio(mouthFace), bell(mouthFace, 0.4, 0.06)),
    m("jaw_cheek", "Jaw / cheek", "structure", jawCheek, ratio(jawCheek), bell(jawCheek, jawIdeal, jawSigma)),
    m("jaw_angle", "Jaw angle", "structure", jawAng, `${jawAng.toFixed(0)}°`, bell(jawAng, gender === "male" ? 124 : 132, 12)),
    m("lower_third", "Chin length", "structure", thirdsL, pct(thirdsL), bell(thirdsL, gender === "male" ? 0.4 : 0.37, 0.05)),
    m("canthal", "Canthal tilt", "features", tilt, `${tilt.toFixed(1)}°`, bell(tilt, 6.5, 4.2)),
    m("lips", "Lip fullness", "features", lipRatio, ratio(lipRatio), bell(lipRatio, gender === "female" ? 0.32 : 0.26, 0.07)),
    m("eye_open", "Eye aperture", "features", eyeRatio, ratio(eyeRatio), bell(eyeRatio, 0.32, 0.08)),
    m("brow", "Brow height", "dimorphism", browRatio, ratio(browRatio), bell(browRatio, gender === "male" ? 0.055 : 0.072, 0.018)),
    m("jaw_dim", "Jaw emphasis", "dimorphism", jawCheek, ratio(jawCheek), bell(jawCheek, jawIdeal, jawSigma * 0.9)),
    m("tilt_dim", "Orbital tilt", "dimorphism", tilt, `${tilt.toFixed(1)}°`, bell(tilt, gender === "male" ? 5 : 7.5, 4)),
  ];

  const pillars: Record<Pillar, number> = {
    harmony: mean(metrics.filter((x) => x.pillar === "harmony").map((x) => x.score)),
    structure: mean(metrics.filter((x) => x.pillar === "structure").map((x) => x.score)),
    dimorphism: mean(metrics.filter((x) => x.pillar === "dimorphism").map((x) => x.score)),
    features: mean(metrics.filter((x) => x.pillar === "features").map((x) => x.score)),
  };

  const overall =
    Math.round(
      ((pillars.harmony * 1.25 + pillars.structure * 1.15 + pillars.dimorphism + pillars.features) / 4.4) * 10,
    ) / 10;

  return {
    id: typeof crypto !== "undefined" && typeof crypto.randomUUID === "function" ? crypto.randomUUID() : `scan-${Date.now()}`,
    createdAt: new Date().toISOString(),
    overall,
    label: labelFor(overall),
    pillars,
    metrics,
    note:
      gender === "other"
        ? "Dimorphism uses a neutral midpoint. Scores come only from this photo’s landmarks, not a template."
        : `Dimorphism is tuned for a ${gender} reading. Every number is measured from this face, wherever it sits in the frame.`,
  };
}

function m(
  id: string,
  label: string,
  pillar: Pillar,
  raw: number,
  display: string,
  score: number,
): Metric {
  return { id, label, pillar, raw, display, score };
}

function pct(n: number) {
  return `${Math.round(n * 100)}%`;
}

function ratio(n: number) {
  return n.toFixed(2);
}
