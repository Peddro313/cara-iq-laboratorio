import type { Pt } from "@/lib/face/score";

type Conn = { start: number; end: number };

type Landmarker = {
  detect: (image: CanvasImageSource) => { faceLandmarks: Pt[][] };
  close: () => void;
};

let pending: Promise<{ marker: Landmarker; links: Conn[] }> | null = null;

export async function getScanner() {
  if (!pending) pending = boot();
  return pending;
}

async function boot() {
  const vision = await import("@mediapipe/tasks-vision");
  const files = await vision.FilesetResolver.forVisionTasks("/mediapipe");
  const marker = await vision.FaceLandmarker.createFromOptions(files, {
    baseOptions: {
      modelAssetPath: "/models/face_landmarker.task",
      delegate: "CPU",
    },
    runningMode: "IMAGE",
    numFaces: 1,
    minFaceDetectionConfidence: 0.2,
    minFacePresenceConfidence: 0.2,
    outputFaceBlendshapes: false,
    outputFacialTransformationMatrixes: false,
  });
  const links = [
    ...vision.FaceLandmarker.FACE_LANDMARKS_FACE_OVAL,
    ...vision.FaceLandmarker.FACE_LANDMARKS_LEFT_EYE,
    ...vision.FaceLandmarker.FACE_LANDMARKS_RIGHT_EYE,
    ...vision.FaceLandmarker.FACE_LANDMARKS_LEFT_EYEBROW,
    ...vision.FaceLandmarker.FACE_LANDMARKS_RIGHT_EYEBROW,
    ...vision.FaceLandmarker.FACE_LANDMARKS_LIPS,
    ...vision.FaceLandmarker.FACE_LANDMARKS_LEFT_IRIS,
    ...vision.FaceLandmarker.FACE_LANDMARKS_RIGHT_IRIS,
  ];
  return { marker: marker as unknown as Landmarker, links };
}

export async function readFace(src: string): Promise<{ points: Pt[]; links: Conn[]; image: HTMLImageElement }> {
  const image = await loadImage(src);
  const canvas = document.createElement("canvas");
  const max = 1280;
  const scale = Math.min(1, max / Math.max(image.naturalWidth, image.naturalHeight));
  canvas.width = Math.max(1, Math.round(image.naturalWidth * scale));
  canvas.height = Math.max(1, Math.round(image.naturalHeight * scale));
  const ctx = canvas.getContext("2d");
  if (!ctx) throw new Error("Could not prepare the photo.");
  ctx.drawImage(image, 0, 0, canvas.width, canvas.height);

  const { marker, links } = await getScanner();
  const result = marker.detect(canvas);
  const points = result.faceLandmarks?.[0];
  if (!points || points.length < 400) {
    throw new Error("No face found. Use a photo where the whole face is visible — it does not have to be centered.");
  }
  return { points, links, image };
}

function loadImage(src: string) {
  return new Promise<HTMLImageElement>((resolve, reject) => {
    const img = new Image();
    img.onload = () => resolve(img);
    img.onerror = () => reject(new Error("Could not open that photo."));
    img.src = src;
  });
}

export type { Conn };
