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

/** Positive when the outer corner sits higher than the inner corner. */
function canthal(outer: Pt, inner: Pt) {
  return (Math.atan2(inner.y - outer.y, Math.abs(inner.x - outer.x)) * 180) / Math.PI;
}

/**
 * An exact hit is 8. A small miss is about 6. A clear miss is about 4.
 * The curve is steep enough that two different features do not both print 6.5.
 * Pillars are a plain average.
 */
function bell(value: number, ideal: number, sigma: number) {
  const z = (value - ideal) / Math.max(sigma, 1e-6);
  const s = 8 * Math.exp(-0.48 * z * z);
  return Math.round(Math.min(8, Math.max(1, s)) * 10) / 10;
}

function toPx(p: Pt | undefined, w: number, h: number): Pt {
  if (!p) return { x: 0, y: 0, z: 0 };
  return { x: p.x * w, y: p.y * h, z: (p.z ?? 0) * w };
}

function mix(xs: number[]) {
  if (!xs.length) return 5;
  const avg = xs.reduce((a, b) => a + b, 0) / xs.length;
  return Math.round(avg * 10) / 10;
}

export function labelFor(score: number) {
  if (score >= 7.3) return "High";
  if (score >= 6.2) return "Balanced";
  if (score >= 5.1) return "Average";
  if (score >= 3.8) return "Soft";
  return "Low";
}

export function scoreTone(score: number) {
  const t = Math.min(1, Math.max(0, (score - 2.5) / 7));
  const hue = 4 + t * 112;
  const light = 62 - t * 14;
  return `hsl(${hue.toFixed(0)} 72% ${light.toFixed(0)}%)`;
}

export function analyzeFace(landmarks: Pt[], gender: Gender, image: { w: number; h: number }): Report {
  const p = (i: number) => toPx(landmarks[i], image.w, image.h);
  if (landmarks.length < 400) {
    throw new Error("The face mesh was incomplete. Try a clearer photo.");
  }

  const faceH = d(p(I.forehead), p(I.chin)) || 1;
  const faceW = d(p(I.leftCheek), p(I.rightCheek)) || 1;
  const sellionY = p(I.nasion).y;
  const topY = p(I.forehead).y;
  const noseY = p(I.subnasale).y;
  const chinY = p(I.chin).y;
  const upper = Math.max(1, sellionY - topY);
  const middle = Math.max(1, noseY - sellionY);
  const lower = Math.max(1, chinY - noseY);
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
  const tilt = (canthal(p(I.leftOuter), p(I.leftInner)) + canthal(p(I.rightOuter), p(I.rightInner))) / 2;
  const jawAng = angleAt(p(I.jawLeft), p(I.chin), p(I.jawRight));
  const browGap =
    (Math.abs(p(105).y - p(I.leftEyeTop).y) + Math.abs(p(334).y - p(I.rightEyeTop).y)) / 2;

  const wh = faceW / faceH;
  const thirdsU = upper / thirds;
  const thirdsM = middle / thirds;
  const thirdsL = lower / thirds;
  const eyeSpace = inter / eyeAvg;
  const noseMouth = noseW / mouthW;
  const jawCheek = jawW / faceW;
  const mouthFace = mouthW / faceW;
  const lipRatio = lipH / mouthW;
  const lipBalance = upperLip / (lowerLip || 1);
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
  const noseShift = Math.abs(upright(p(I.noseTip)).x) / faceW;
  const mouthSkew = Math.abs(upright(p(I.mouthLeft)).y - upright(p(I.mouthRight)).y) / mouthW;
  const jawShift =
    Math.abs(Math.abs(upright(p(I.jawLeft)).x) - Math.abs(upright(p(I.jawRight)).x)) / faceW;

  const jawIdeal = gender === "female" ? 0.77 : gender === "male" ? 0.79 : 0.78;
  const whIdeal = gender === "female" ? 0.81 : gender === "male" ? 0.82 : 0.815;
  const lipIdeal = gender === "female" ? 0.36 : gender === "male" ? 0.33 : 0.345;
  const tiltIdeal = gender === "female" ? 5.6 : gender === "male" ? 5 : 5.3;
  const eyeIdeal = gender === "female" ? 1.1 : gender === "male" ? 1.25 : 1.18;
  const jawAngIdeal = 112;
  const chinLenIdeal = gender === "female" ? 0.165 : gender === "male" ? 0.186 : 0.176;
  const jawMouthIdeal = gender === "female" ? 2.05 : gender === "male" ? 2.1 : 2.08;
  const eyeDimIdeal = gender === "female" ? 0.36 : gender === "male" ? 0.33 : 0.345;
  const browIdeal = gender === "female" ? 0.126 : gender === "male" ? 0.1 : 0.113;

  const metrics: Metric[] = [
    m("thirds_upper", "Upper third", "harmony", thirdsU, pct(thirdsU), bell(thirdsU, 0.36, 0.018), "Share of the face above the brow. Off 36% by a clear margin, this drops."),
    m("thirds_mid", "Middle third", "harmony", thirdsM, pct(thirdsM), bell(thirdsM, 0.26, 0.014), "Brow to the base of the nose."),
    m("thirds_low", "Lower third", "harmony", thirdsL, pct(thirdsL), bell(thirdsL, 0.38, 0.016), "Nose base to chin. A long or short lower face drops this."),
    m("eye_space", "Eye spacing", "harmony", eyeSpace, ratio(eyeSpace), bell(eyeSpace, eyeIdeal, 0.06), "Gap between the eyes, in eye-widths. The target is slightly closer than a typical male photo."),
    m("nose_mouth", "Nose / mouth", "harmony", noseMouth, ratio(noseMouth), bell(noseMouth, 0.63, 0.035), "Nose width against mouth width. A bit narrower than average is the target."),
    m("face_wh", "Width / height", "harmony", wh, ratio(wh), bell(wh, whIdeal, 0.022), "Cheek width against face height. A leaner face scores higher than a wide one."),
    m("nose_mid", "Nose midline", "harmony", noseShift, pct(noseShift), bell(noseShift, 0, 0.016), "How far the nose tip sits off the center of the eyes. A crooked nose drops."),
    m("mouth_face", "Mouth / face", "features", mouthFace, ratio(mouthFace), bell(mouthFace, 0.39, 0.032), "Mouth width against cheek width."),
    m("jaw_cheek", "Jaw / cheek", "structure", jawCheek, ratio(jawCheek), bell(jawCheek, jawIdeal, 0.018), "Jaw width against the cheeks."),
    m("jaw_angle", "Jaw angle", "structure", jawAng, `${jawAng.toFixed(0)}°`, bell(jawAng, jawAngIdeal, 5), "Angle at the chin. On this mesh a balanced chin is about 112°."),
    m("lower_third", "Chin length", "structure", lipToChin, pct(lipToChin), bell(lipToChin, chinLenIdeal, 0.012), "Lower lip to the bottom of the chin."),
    m("jaw_shift", "Jaw balance", "structure", jawShift, pct(jawShift), bell(jawShift, 0, 0.018), "Left jaw against the right jaw. A clearly uneven jaw drops."),
    m("canthal", "Canthal tilt", "features", tilt, `${tilt.toFixed(1)}°`, bell(tilt, tiltIdeal, 1.05), "Positive means the outer eye corner sits higher than the inner corner."),
    m("lips", "Lip fullness", "features", lipRatio, ratio(lipRatio), bell(lipRatio, lipIdeal, 0.03), "Lip height divided by mouth width. Thin and very full lips move away from the target."),
    m("lip_balance", "Lip balance", "features", lipBalance, ratio(lipBalance), bell(lipBalance, 0.57, 0.08), "Upper lip height divided by lower lip height."),
    m("eye_open", "Eye aperture", "features", eyeRatio, ratio(eyeRatio), bell(eyeRatio, 0.33, 0.028), "How open the eyes are against their width."),
    m("eye_match", "Eye match", "features", eyeMismatch, pct(eyeMismatch), bell(eyeMismatch, 0, 0.03), "Left eye opening against the right. Uneven eyes drop."),
    m("mouth_level", "Mouth level", "features", mouthSkew, pct(mouthSkew), bell(mouthSkew, 0, 0.025), "One mouth corner against the other. A clearly uneven mouth drops."),
    m("brow", "Brow height", "dimorphism", browRatio, pct(browRatio), bell(browRatio, browIdeal, 0.012), "Vertical gap from the eyebrow to the eyelid. A lower male brow scores higher."),
    m("jaw_dim", "Jaw emphasis", "dimorphism", jawMouth, ratio(jawMouth), bell(jawMouth, jawMouthIdeal, 0.2), "Jaw width divided by mouth width."),
    m("tilt_dim", "Eye openness", "dimorphism", eyeRatio, ratio(eyeRatio), bell(eyeRatio, eyeDimIdeal, 0.028), "Eye opening scored for this profile."),
  ];

  return pack(
    metrics,
    gender === "other"
      ? "Rows spread on purpose. An 8 is a close match. A 4 is a real miss."
      : `Read as ${gender}. Rows are meant to spread. An 8 is a close match. A 4 is a real miss.`,
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
  const brow = midpoint(p(I.browLeft), p(I.browRight));
  const eye = midpoint(p(I.leftEyeTop), p(I.rightEyeTop));
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
  const browRidge = (forward(brow) - forward(eye)) / depthSpan;

  const noseIdeal = 0.62;
  const chinIdeal = gender === "female" ? -0.1 : gender === "male" ? 0 : -0.05;
  const emphasisIdeal = gender === "female" ? 0.22 : gender === "male" ? 0.34 : 0.28;
  const browIdeal = gender === "female" ? 0.06 : gender === "male" ? 0.18 : 0.1;
  const nasoIdeal = gender === "female" ? 104 : gender === "male" ? 96 : 100;

  const metrics: Metric[] = [
    m("nose_proj", "Nose projection", "structure", noseProj, ratio(noseProj), bell(noseProj, noseIdeal, 0.28), "How far the nose comes forward of the brow, compared with the depth of the face."),
    m("chin_proj", "Chin projection", "structure", chinProj, ahead(chinProj), bell(chinProj, chinIdeal, 0.22), "Front of the chin against the lower lip. Near zero means the chin is about as far forward as the lip. The old score used the underside of the chin, so almost everyone looked recessed."),
    m("nasolabial", "Nasolabial angle", "structure", nasolabial, `${nasolabial.toFixed(0)}°`, bell(nasolabial, nasoIdeal, 18), "Angle where the nose meets the upper lip."),
    m("convexity", "Facial convexity", "harmony", convexity, `${convexity.toFixed(0)}°`, bell(convexity, 165, 16), "Glabella to nose base to chin. Straighter profiles score higher."),
    m("eline", "Lips vs E-line", "harmony", lipBehind, ratio(lipBehind), bell(lipBehind, 0.05, 0.18), "Lips against the line from nose tip to chin."),
    m("brow_ridge", "Brow ridge", "dimorphism", browRidge, ratio(browRidge), bell(browRidge, browIdeal, 0.16), "How far the brow comes forward of the eye."),
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
