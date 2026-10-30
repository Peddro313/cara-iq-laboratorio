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
  detail: string;
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

/** Brow-based hairline. Landmark 10 follows hair, so a covered forehead uses this instead. */
export function foreheadGuide(points: Pt[]) {
  const y = (i: number) => points[i]?.y ?? 0;
  const brow = (y(105) + y(334) + y(66) + y(296)) / 4;
  const chin = y(152);
  const skin = brow - 0.26 * (chin - brow);
  const mesh = y(10);
  const span = Math.max(1e-4, chin - skin);
  const covered = Math.abs(mesh - skin) / span > 0.02;
  return { y: covered ? skin : mesh, covered };
}

const I = {
  forehead: 10,
  glabella: 9,
  nasion: 6,
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
  lipOuterTop: 0,
  lipInnerTop: 13,
  lipInnerBot: 14,
  lipOuterBot: 17,
  jawLeft: 172,
  jawRight: 397,
  browLeft: 70,
  browRight: 300,
} as const;

function d(a: Pt, b: Pt) {
  return Math.hypot(a.x - b.x, a.y - b.y);
}

function angle2(ax: number, ay: number, bx: number, by: number, cx: number, cy: number) {
  const abx = ax - bx;
  const aby = ay - by;
  const cbx = cx - bx;
  const cby = cy - by;
  const mag = Math.hypot(abx, aby) * Math.hypot(cbx, cby);
  if (mag === 0) return 0;
  const cos = Math.min(1, Math.max(-1, (abx * cbx + aby * cby) / mag));
  return (Math.acos(cos) * 180) / Math.PI;
}

function angleAt(a: Pt, b: Pt, c: Pt) {
  return angle2(a.x, a.y, b.x, b.y, c.x, c.y);
}

/**
 * 1 to 9. Inside the target band the row stays at 9.
 * A clear miss falls toward 4. A large miss falls to 1.
 * `above` softens the high side (tilt and lips).
 */
function bell(value: number, ideal: number, sigma: number, above = 1) {
  const z = (value - ideal) / Math.max(sigma, 1e-6);
  const w = z > 0 ? z / above : -z;
  const d = Math.max(0, w - 0.45);
  const s = 9 * Math.exp(-0.7 * d * d);
  return Math.round(Math.min(9, Math.max(1, s)) * 10) / 10;
}

function toPx(p: Pt | undefined, w: number, h: number): Pt {
  if (!p) return { x: 0, y: 0, z: 0 };
  return { x: p.x * w, y: p.y * h, z: (p.z ?? 0) * w };
}

function mix(xs: number[]) {
  if (!xs.length) return 5;
  const avg = xs.reduce((a, b) => a + b, 0) / xs.length;
  const low = Math.min(...xs);
  return Math.round((avg * 0.82 + low * 0.18) * 10) / 10;
}

export function labelFor(score: number) {
  if (score >= 8.2) return "Exceptional";
  if (score >= 7) return "Strong";
  if (score >= 5.8) return "Balanced";
  if (score >= 4.5) return "Average";
  if (score >= 3) return "Weak";
  return "Poor";
}

export function scoreTone(score: number) {
  const t = Math.min(1, Math.max(0, (score - 1.5) / 8));
  const hue = 4 + t * 118;
  const light = 62 - t * 16;
  return `hsl(${hue.toFixed(0)} 72% ${light.toFixed(0)}%)`;
}

export function analyzeFace(landmarks: Pt[], gender: Gender, image: { w: number; h: number }): Report {
  const p = (i: number) => toPx(landmarks[i], image.w, image.h);
  if (landmarks.length < 400) {
    throw new Error("The face mesh was incomplete. Try a clearer photo.");
  }

  const guide = foreheadGuide(landmarks);
  const sellionY = p(I.nasion).y;
  const noseY = p(I.subnasale).y;
  const chinY = p(I.chin).y;
  const topY = guide.y * image.h;
  const hairOnForehead = guide.covered;
  const middle = Math.max(1, noseY - sellionY);
  const lower = Math.max(1, chinY - noseY);
  const upper = Math.max(1, sellionY - topY);
  const faceH = hairOnForehead ? Math.max(1, chinY - topY) : d(p(I.forehead), p(I.chin)) || 1;
  const faceW = d(p(I.leftCheek), p(I.rightCheek)) || 1;
  const thirds = upper + middle + lower || faceH;

  const eyeL = d(p(I.leftOuter), p(I.leftInner));
  const eyeR = d(p(I.rightOuter), p(I.rightInner));
  const eyeAvg = (eyeL + eyeR) / 2 || 1;
  const inter = d(p(I.leftInner), p(I.rightInner));
  const mouthW = d(p(I.mouthLeft), p(I.mouthRight)) || 1;
  const noseW = d(p(I.noseLeft), p(I.noseRight));
  const jawW = d(p(I.jawLeft), p(I.jawRight));
  const upperLip = d(p(I.lipOuterTop), p(I.lipInnerTop));
  const lowerLip = d(p(I.lipInnerBot), p(I.lipOuterBot));
  const lipH = upperLip + lowerLip;
  const eyeOpen = (d(p(I.leftEyeTop), p(I.leftEyeBot)) + d(p(I.rightEyeTop), p(I.rightEyeBot))) / 2;
  let browGap =
    (Math.abs(p(105).y - p(I.leftEyeTop).y) + Math.abs(p(334).y - p(I.rightEyeTop).y)) / 2;
  const lowBrowGap =
    (Math.abs(p(52).y - p(I.leftEyeTop).y) + Math.abs(p(282).y - p(I.rightEyeTop).y)) / 2;
  // Hair sitting on the brow pulls the upper brow points up and the gap explodes.
  if (browGap > eyeOpen * 2.2) browGap = lowBrowGap;
  if (browGap > eyeOpen * 2.2) browGap = faceH * (gender === "female" ? 0.12 : 0.1);
  const roll = Math.atan2(p(I.rightOuter).y - p(I.leftOuter).y, p(I.rightOuter).x - p(I.leftOuter).x);
  const tiltOf = (outer: Pt, inner: Pt) => {
    const dx = inner.x - outer.x;
    const dy = inner.y - outer.y;
    const c = Math.cos(-roll);
    const s = Math.sin(-roll);
    const ry = dx * s + dy * c;
    const rx = dx * c - dy * s;
    return (Math.atan2(ry, Math.abs(rx)) * 180) / Math.PI;
  };
  const tilt = (tiltOf(p(I.leftOuter), p(I.leftInner)) + tiltOf(p(I.rightOuter), p(I.rightInner))) / 2;
  const jawAng = angleAt(p(I.jawLeft), p(I.chin), p(I.jawRight));

  const wh = faceW / faceH;
  const thirdsU = upper / thirds;
  const thirdsM = middle / thirds;
  const thirdsL = lower / thirds;
  const eyeSpace = inter / eyeAvg;
  const noseMouth = noseW / mouthW;
  const jawCheek = jawW / faceW;
  const mouthFace = mouthW / faceW;
  const lipRatioRaw = lipH / mouthW;
  const mouthGap = Math.abs(p(I.lipInnerTop).y - p(I.lipInnerBot).y) / mouthW;
  let lipBalance = upperLip / (lowerLip || 1);
  if (mouthGap > 0.045) {
    const trust = Math.max(0, 1 - (mouthGap - 0.045) / 0.08);
    lipBalance = lipBalance * trust + 0.618 * (1 - trust);
  }
  const eyeRatio = eyeOpen / eyeAvg;
  const browRatio = browGap / faceH;

  const lipToChin = Math.abs(p(I.chin).y - p(I.lipOuterBot).y) / faceH;
  const jawMouth = jawW / mouthW;
  const leftOpen = d(p(I.leftEyeTop), p(I.leftEyeBot));
  const rightOpen = d(p(I.rightEyeTop), p(I.rightEyeBot));
  const eyeMismatch = Math.abs(leftOpen - rightOpen) / eyeAvg;
  const midEye = midpoint(p(I.leftInner), p(I.rightInner));
  const eyeAngle = Math.atan2(p(I.rightOuter).y - p(I.leftOuter).y, p(I.rightOuter).x - p(I.leftOuter).x);
  const upright = (pt: Pt) => {
    const dx = pt.x - midEye.x;
    const dy = pt.y - midEye.y;
    const c = Math.cos(-eyeAngle);
    const s = Math.sin(-eyeAngle);
    return { x: dx * c - dy * s, y: dx * s + dy * c };
  };
  const noseCrook =
    Math.abs(upright(p(I.noseTip)).x - upright(p(I.subnasale)).x) / (noseW || 1);
  const mouthSkew = Math.abs(upright(p(I.mouthLeft)).y - upright(p(I.mouthRight)).y) / mouthW;
  const jawShift =
    Math.abs(Math.abs(upright(p(I.jawLeft)).x) - Math.abs(upright(p(I.jawRight)).x)) / faceW;

  const jawIdeal = gender === "female" ? 0.77 : gender === "male" ? 0.8 : 0.785;
  const whIdeal = gender === "female" ? 0.79 : gender === "male" ? 0.8 : 0.795;
  const mouthIdeal = gender === "female" ? 0.36 : gender === "male" ? 0.4 : 0.38;
  const lipIdeal = gender === "female" ? 0.38 : gender === "male" ? 0.33 : 0.355;
  const openIdeal = gender === "female" ? 0.35 : gender === "male" ? 0.32 : 0.335;
  let lipRatio = lipRatioRaw;
  if (mouthGap > 0.08) lipRatio = lipRatio * 0.55 + lipIdeal * 0.45;
  const tiltIdeal = gender === "female" ? 6 : gender === "male" ? 5 : 5.5;
  const eyeIdeal = gender === "female" ? 1.12 : gender === "male" ? 1.23 : 1.18;
  const jawAngIdeal = 112;
  const chinLenIdeal = gender === "female" ? 0.17 : gender === "male" ? 0.19 : 0.18;
  const jawMouthIdeal = gender === "female" ? 2 : gender === "male" ? 2.1 : 2.05;
  const eyeDimIdeal = gender === "female" ? 0.35 : gender === "male" ? 0.32 : 0.335;
  const browIdeal = gender === "female" ? 0.12 : gender === "male" ? 0.105 : 0.112;

  const metrics: Metric[] = [
    m("thirds_upper", "Upper third", "harmony", thirdsU, pct(thirdsU), bell(thirdsU, 0.36, 0.045), hairOnForehead ? "Hair covered the forehead, so this uses the brow-to-chin scale instead of the hairline." : "Share of the face above the brow."),
    m("thirds_mid", "Middle third", "harmony", thirdsM, pct(thirdsM), bell(thirdsM, 0.26, 0.04), "Brow to the base of the nose."),
    m("thirds_low", "Lower third", "harmony", thirdsL, pct(thirdsL), bell(thirdsL, 0.38, 0.045), "Nose base to chin. A long or short lower face drops this."),
    m("eye_space", "Eye spacing", "harmony", eyeSpace, ratio(eyeSpace), bell(eyeSpace, eyeIdeal, 0.1), "Gap between the eyes, in eye-widths. The target is slightly closer than a typical male photo."),
    m("nose_mouth", "Nose / mouth", "harmony", noseMouth, ratio(noseMouth), bell(noseMouth, 0.64, 0.08), "Nose width against mouth width. A bit narrower than average is the target."),
    m("face_wh", "Width / height", "harmony", wh, ratio(wh), bell(wh, whIdeal, 0.05), "Cheek width against face height. A leaner face scores higher than a wide one."),
    m("nose_mid", "Nose midline", "harmony", noseCrook, pct(noseCrook), bell(noseCrook, 0, 0.18), "Nose tip against the base of the nose. A turned head no longer counts as a crooked nose."),
    m("mouth_face", "Mouth / face", "features", mouthFace, ratio(mouthFace), bell(mouthFace, mouthIdeal, 0.07), "Mouth width against cheek width. A typical male reading is about 0.40."),
    m("jaw_cheek", "Jaw / cheek", "structure", jawCheek, ratio(jawCheek), bell(jawCheek, jawIdeal, 0.04), "Jaw width against the cheeks."),
    m("jaw_angle", "Jaw angle", "structure", jawAng, `${jawAng.toFixed(0)}°`, bell(jawAng, jawAngIdeal, 10), "Angle at the chin. On this mesh a balanced chin is about 112°."),
    m("lower_third", "Chin length", "structure", lipToChin, pct(lipToChin), bell(lipToChin, chinLenIdeal, 0.03), "Lower lip to the bottom of the chin."),
    m("jaw_shift", "Jaw balance", "structure", jawShift, pct(jawShift), bell(jawShift, 0, 0.04), "Left jaw against the right jaw. A clearly uneven jaw drops."),
    m("canthal", "Canthal tilt", "features", tilt, `${tilt.toFixed(1)}°`, bell(tilt, tiltIdeal, 3, 2), "Outer eye corner against the inner corner, after the head tilt is removed. Around 5° is the usual reading. A negative tilt drops faster than a higher one."),
    m("lips", "Lip fullness", "features", lipRatio, ratio(lipRatio), bell(lipRatio, lipIdeal, 0.06, 1.6), "Lip height divided by mouth width, not the gap of an open mouth. Thin lips drop faster than full ones."),
    m("lip_balance", "Lip balance", "features", lipBalance, ratio(lipBalance), bell(lipBalance, 0.618, 0.12), "Upper lip height divided by lower lip height. Ignored when the mouth is open."),
    m("eye_open", "Eye aperture", "features", eyeRatio, ratio(eyeRatio), bell(eyeRatio, openIdeal, 0.05), "How open the eyes are against their width."),
    m("eye_match", "Eye match", "features", eyeMismatch, pct(eyeMismatch), bell(eyeMismatch, 0, 0.035), "Left eye opening against the right. A 2% gap is normal."),
    m("mouth_level", "Mouth level", "features", mouthSkew, pct(mouthSkew), bell(mouthSkew, 0, 0.05), "One mouth corner against the other. A slight difference is normal."),
    m("brow", "Brow height", "dimorphism", browRatio, pct(browRatio), bell(browRatio, browIdeal, 0.025), "Vertical gap from the eyebrow to the eyelid. A lower male brow scores higher."),
    m("jaw_dim", "Jaw emphasis", "dimorphism", jawMouth, ratio(jawMouth), bell(jawMouth, jawMouthIdeal, 0.35), "Jaw width divided by mouth width."),
    m("tilt_dim", "Eye openness", "dimorphism", eyeRatio, ratio(eyeRatio), bell(eyeRatio, eyeDimIdeal, 0.05), "Eye opening scored for this profile."),
  ];

  return pack(
    metrics,
    gender === "other"
      ? "Each row runs from 1 to 9. Inside the target range it stays at 9. Far outside it, it falls toward 1."
      : `Read as ${gender}. Each row runs from 1 to 9. A face inside the target range stays high. A face far outside it falls toward 1.`,
  );
}

export function analyzeProfile(
  landmarks: Pt[],
  gender: Gender,
  image: { w: number; h: number },
  source: "depth" | "photo",
): Report {
  const p = (i: number) => toPx(landmarks[i], image.w, image.h);
  if (landmarks.length < 400) {
    throw new Error("The profile mesh was incomplete.");
  }

  const nose = p(I.noseTip);
  const nasion = p(I.nasion);
  const chin = p(I.chin);
  const sub = p(I.subnasale);
  const lip = p(I.lipOuterTop);
  const lowerLip = p(I.lipOuterBot);
  const glabella = p(I.glabella);
  const cheek = midpoint(p(I.leftCheek), p(I.rightCheek));
  const faceH = d(p(I.forehead), chin) || 1;
  const midX = (p(I.leftCheek).x + p(I.rightCheek).x) / 2;
  const sign = Math.sign(nose.x - midX) || 1;
  const forward = (pt: Pt) => (source === "photo" ? sign * (pt.x - midX) : -(pt.z ?? 0));
  const depthSpan = Math.max(
    Math.abs(forward(nose) - forward(cheek)),
    Math.abs(forward(nose) - forward(chin)),
    faceH * 0.02,
  );

  const noseProj = (forward(nose) - forward(nasion)) / depthSpan;
  const lipMid = midpoint(lip, lowerLip);
  const pogonion = mostForward([p(175), p(199), p(152)], forward);
  const chinProj = (forward(pogonion) - forward(p(I.lipOuterBot))) / depthSpan;
  const chinButton = (forward(pogonion) - forward(p(152))) / depthSpan;
  const t = clamp01((lip.y - nose.y) / (chin.y - nose.y || 1));
  const eline = forward(nose) + t * (forward(chin) - forward(nose));
  const lipBehind = (eline - forward(lipMid)) / depthSpan;

  const nasolabial =
    source === "photo"
      ? angleAt(nose, sub, lip)
      : angle2(nose.z ?? 0, nose.y, sub.z ?? 0, sub.y, lip.z ?? 0, lip.y);
  const convexity =
    source === "photo"
      ? angleAt(glabella, sub, chin)
      : angle2(glabella.z ?? 0, glabella.y, sub.z ?? 0, sub.y, chin.z ?? 0, chin.y);
  const browSamples = [52, 65, 105, 66, 107, 282, 295, 334, 296, 336].map((i) => forward(p(i))).sort((a, b) => a - b);
  const browMid = browSamples[Math.floor(browSamples.length / 2)];
  const eyeMid = (forward(p(I.leftEyeTop)) + forward(p(I.rightEyeTop))) / 2;
  let browRidge = (browMid - eyeMid) / depthSpan;

  const noseIdeal = 0.62;
  const chinIdeal = gender === "female" ? -0.1 : gender === "male" ? 0 : -0.05;
  const emphasisIdeal = gender === "female" ? 0.22 : gender === "male" ? 0.34 : 0.28;
  const browIdeal = gender === "female" ? 0.08 : gender === "male" ? 0.12 : 0.1;
  if (browRidge < -0.08 || browRidge > 0.42) browRidge = browIdeal;
  const nasoIdeal = gender === "female" ? 104 : gender === "male" ? 96 : 100;

  const metrics: Metric[] = [
    m("nose_proj", "Nose projection", "structure", noseProj, ratio(noseProj), bell(noseProj, noseIdeal, 0.28), "How far the nose comes forward of the brow, compared with the depth of the face."),
    m("chin_proj", "Chin projection", "structure", chinProj, ahead(chinProj), bell(chinProj, chinIdeal, 0.22), "Front of the chin against the lower lip. Near zero means the chin is about as far forward as the lip. The old score used the underside of the chin, so almost everyone looked recessed."),
    m("nasolabial", "Nasolabial angle", "structure", nasolabial, `${nasolabial.toFixed(0)}°`, bell(nasolabial, nasoIdeal, 18), "Angle where the nose meets the upper lip."),
    m("convexity", "Facial convexity", "harmony", convexity, `${convexity.toFixed(0)}°`, bell(convexity, 165, 16), "Glabella to nose base to chin. Straighter profiles score higher."),
    m("eline", "Lips vs E-line", "harmony", lipBehind, ratio(lipBehind), bell(lipBehind, 0.05, 0.18), "Lips against the line from nose tip to chin."),
    m("brow_ridge", "Brow ridge", "dimorphism", browRidge, ratio(browRidge), bell(browRidge, browIdeal, 0.14), "How far the brow bone comes forward of the eye. Hair on the forehead is ignored when it would fake a huge ridge."),
    m("chin_dim", "Chin emphasis", "dimorphism", chinButton, ahead(chinButton), bell(chinButton, emphasisIdeal, 0.16), "How far the front of the chin comes off the underside. A flat chin scores lower. This is separate from projection."),
    m("lip_profile", "Lip projection", "features", lipBehind, ratio(lipBehind), bell(lipBehind, gender === "female" ? 0.02 : 0.08, 0.18), "Where the lips sit against the nose-to-chin line."),
  ];

  return pack(
    metrics,
    source === "photo"
      ? "Side profile measured on the second photo. The nose is treated as the forward point."
      : "Side profile estimated from the depth in the front photo. Add a true side photo to replace this.",
  );
}

function mostForward(pts: Pt[], forward: (p: Pt) => number) {
  return pts.reduce((best, pt) => (forward(pt) > forward(best) ? pt : best));
}

function ahead(n: number) {
  if (!Number.isFinite(n)) return "—";
  const v = n.toFixed(2);
  if (n > 0.03) return `${v} ahead`;
  if (n < -0.03) return `${v} behind`;
  return `${v} even`;
}

function midpoint(a: Pt, b: Pt): Pt {
  return { x: (a.x + b.x) / 2, y: (a.y + b.y) / 2, z: ((a.z ?? 0) + (b.z ?? 0)) / 2 };
}

function clamp01(n: number) {
  return Math.min(1, Math.max(0, n));
}

function pack(metrics: Metric[], note: string): Report {
  const pillars: Record<Pillar, number> = {
    harmony: mix(metrics.filter((x) => x.pillar === "harmony").map((x) => x.score)),
    structure: mix(metrics.filter((x) => x.pillar === "structure").map((x) => x.score)),
    dimorphism: mix(metrics.filter((x) => x.pillar === "dimorphism").map((x) => x.score)),
    features: mix(metrics.filter((x) => x.pillar === "features").map((x) => x.score)),
  };
  const overall = mix([pillars.harmony, pillars.structure, pillars.dimorphism, pillars.features]);
  return {
    id: typeof crypto !== "undefined" && typeof crypto.randomUUID === "function" ? crypto.randomUUID() : `scan-${Date.now()}`,
    createdAt: new Date().toISOString(),
    overall,
    label: labelFor(overall),
    pillars,
    metrics,
    note,
  };
}

function m(
  id: string,
  label: string,
  pillar: Pillar,
  raw: number,
  display: string,
  score: number,
  detail: string,
): Metric {
  return { id, label, pillar, raw, display, score, detail };
}

function pct(n: number) {
  return `${Math.round(n * 100)}%`;
}

function ratio(n: number) {
  return Number.isFinite(n) ? n.toFixed(2) : "—";
}
