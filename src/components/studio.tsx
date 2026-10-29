import { useEffect, useMemo, useRef, useState, type ReactNode } from "react";
import { Camera, ChevronLeft, History, ImagePlus, ScanFace } from "lucide-react";
import { readFace, type Conn } from "@/lib/face/detect";
import {
  analyzeFace,
  analyzeProfile,
  scoreTone,
  type Gender,
  type Metric,
  type Pillar,
  type Pt,
  type Report,
} from "@/lib/face/score";

type Profile = {
  name: string;
  gender: Gender;
  age: string;
  height: string;
  heard: string;
  goal: string;
  focus: string[];
  skincare: string;
  training: string;
};

type Shot = { src: string; name: string };

type Saved = {
  id: string;
  createdAt: string;
  overall: number;
  label: string;
  pillars: Report["pillars"];
  thumb: string;
};

type Phase =
  | { name: "boot" }
  | { name: "onboard" }
  | { name: "home" }
  | { name: "capture" }
  | { name: "scan"; front: Shot; side: Shot | null }
  | { name: "result"; front: Shot; side: Shot | null; report: Report; profile: Report; gender: Gender }
  | { name: "history" };

const PROFILE_KEY = "cara-iq-profile-2";
const HISTORY_KEY = "cara-iq-history";

const PILLARS: { id: Pillar; title: string; line: string }[] = [
  { id: "harmony", title: "Harmony", line: "Proportions and balance" },
  { id: "structure", title: "Structure", line: "Jaw, width, and thirds" },
  { id: "dimorphism", title: "Dimorphism", line: "Traits typical of your profile" },
  { id: "features", title: "Features", line: "Eyes, lips, and detail" },
];

export function Studio() {
  const [phase, setPhase] = useState<Phase>({ name: "boot" });
  const [profile, setProfile] = useState<Profile | null>(null);
  const [history, setHistory] = useState<Saved[]>([]);

  useEffect(() => {
    const raw = localStorage.getItem(PROFILE_KEY);
    const hist = localStorage.getItem(HISTORY_KEY);
    if (hist) {
      try {
        setHistory(JSON.parse(hist) as Saved[]);
      } catch {
        /* ignore */
      }
    }
    if (raw) {
      try {
        setProfile(JSON.parse(raw) as Profile);
        setPhase({ name: "home" });
        return;
      } catch {
        /* fall through */
      }
    }
    setPhase({ name: "onboard" });
  }, []);

  function saveProfile(next: Profile) {
    localStorage.setItem(PROFILE_KEY, JSON.stringify(next));
    setProfile(next);
    setPhase({ name: "home" });
  }

  function remember(report: Report, thumb: string) {
    const row: Saved = {
      id: report.id,
      createdAt: report.createdAt,
      overall: report.overall,
      label: report.label,
      pillars: report.pillars,
      thumb,
    };
    const next = [row, ...history].slice(0, 12);
    setHistory(next);
    try {
      localStorage.setItem(HISTORY_KEY, JSON.stringify(next));
    } catch {
      /* quota */
    }
  }

  return (
    <div className="min-h-screen bg-bg text-fg">
      {phase.name === "boot" && <Boot />}
      {phase.name === "onboard" && <Onboard onDone={saveProfile} />}
      {phase.name === "home" && profile && (
        <Home
          profile={profile}
          history={history}
          onStart={() => setPhase({ name: "capture" })}
          onHistory={() => setPhase({ name: "history" })}
        />
      )}
      {phase.name === "capture" && (
        <Capture
          onBack={() => setPhase({ name: "home" })}
          onScan={(front, side) => setPhase({ name: "scan", front, side })}
        />
      )}
      {phase.name === "scan" && profile && (
        <Scan
          front={phase.front}
          gender={profile.gender}
          onFail={() => setPhase({ name: "capture" })}
          onDone={(report, profileReport, thumb) => {
            remember({ ...report }, thumb);
            setPhase({
              name: "result",
              front: phase.front,
              side: phase.side,
              report,
              profile: profileReport,
              gender: profile.gender,
            });
          }}
        />
      )}
      {phase.name === "result" && (
        <Result
          front={phase.front}
          side={phase.side}
          report={phase.report}
          profile={phase.profile}
          gender={phase.gender}
          onHome={() => setPhase({ name: "home" })}
          onAgain={() => setPhase({ name: "capture" })}
        />
      )}
      {phase.name === "history" && (
        <HistoryView rows={history} onBack={() => setPhase({ name: "home" })} />
      )}
    </div>
  );
}

function Boot() {
  return (
    <main className="grid min-h-screen place-items-center">
      <div className="text-center">
        <p className="font-serif text-4xl">Cara IQ</p>
        <p className="mt-2 text-xs tracking-[0.28em] text-muted">LABORATÓRIO</p>
      </div>
    </main>
  );
}

function Shell({
  children,
  eyebrow,
}: {
  children: ReactNode;
  eyebrow?: string;
}) {
  return (
    <main className="mx-auto flex min-h-screen w-full max-w-5xl flex-col px-5 py-6 sm:px-8">
      <header className="mb-8 flex items-center justify-between">
        <div>
          <p className="font-serif text-xl leading-none">Cara IQ</p>
          <p className="mt-1 text-xs tracking-[0.22em] text-muted">LABORATÓRIO</p>
        </div>
        {eyebrow && <p className="text-sm text-muted">{eyebrow}</p>}
      </header>
      {children}
    </main>
  );
}

function Onboard({ onDone }: { onDone: (p: Profile) => void }) {
  const [step, setStep] = useState(0);
  const [pulse, setPulse] = useState("");
  const [draft, setDraft] = useState<Profile>({
    name: "",
    gender: "" as Gender,
    age: "",
    height: "",
    heard: "",
    goal: "",
    focus: [],
    skincare: "",
    training: "",
  });

  const questions: Question[] = [
    {
      key: "name",
      kicker: "Name",
      title: "What should we call you?",
      hint: "Only stored on this device.",
      kind: "text",
    },
    {
      key: "gender",
      kicker: "Reading",
      title: "How should we read the face?",
      options: [
        { id: "male", label: "Male" },
        { id: "female", label: "Female" },
        { id: "other", label: "Prefer not to say" },
      ],
    },
    {
      key: "age",
      kicker: "Age",
      title: "How old are you?",
      options: ["16–17", "18–21", "22–25", "26–30", "31–40", "41+"].map((id) => ({ id, label: id })),
    },
    {
      key: "height",
      kicker: "Height",
      title: "How tall are you?",
      options: ["Under 160 cm", "160–170 cm", "170–180 cm", "180–190 cm", "Over 190 cm"].map((id) => ({
        id,
        label: id,
      })),
    },
    {
      key: "heard",
      kicker: "Discovery",
      title: "Where did you first hear about this?",
      options: ["TikTok", "Instagram", "YouTube", "A friend", "Search"].map((id) => ({ id, label: id })),
    },
    {
      key: "goal",
      kicker: "Reason",
      title: "Why did you install it?",
      options: ["See my rating", "Get tips to improve", "Track progress", "Understand my features"].map((id) => ({
        id,
        label: id,
      })),
    },
    {
      key: "focus",
      kicker: "Focus",
      title: "What do you most want to change?",
      hint: "Choose every area that matters.",
      multi: true,
      options: ["Nose", "Lips", "Jaw", "Eyes", "Skin", "Cheekbones", "Chin"].map((id) => ({ id, label: id })),
    },
    {
      key: "skincare",
      kicker: "Skin",
      title: "How often do you take care of your skin?",
      options: ["Rarely", "A few times a month", "A few times a week", "Every day"].map((id) => ({ id, label: id })),
    },
    {
      key: "training",
      kicker: "Training",
      title: "How often do you train your face or posture?",
      hint: "Jaw work, mewing, or just holding yourself better.",
      options: ["Rarely", "A few times a month", "A few times a week", "Every day"].map((id) => ({ id, label: id })),
    },
  ];

  const current = questions[step];
  const total = questions.length;
  const selected = valueOf(draft, current.key);
  const ready =
    current.kind === "text"
      ? draft.name.trim().length > 0
      : current.multi
        ? draft.focus.length > 0
        : Boolean(selected);

  function choose(id: string) {
    setPulse(id);
    if (current.multi) {
      const focus = draft.focus.includes(id) ? draft.focus.filter((x) => x !== id) : [...draft.focus, id];
      setDraft({ ...draft, focus });
      return;
    }
    const next = applyAnswer(draft, current.key, id);
    setDraft(next);
    window.setTimeout(() => {
      if (step === total - 1) onDone(next);
      else setStep((s) => Math.min(total - 1, s + 1));
    }, 220);
  }

  return (
    <Shell eyebrow={`${step + 1} / ${total}`}>
      <div className="mb-8 h-1 overflow-hidden rounded-full bg-line">
        <div
          className="h-full rounded-full bg-accent transition-all duration-500"
          style={{ width: `${((step + 1) / total) * 100}%` }}
        />
      </div>
      <div key={current.key} className="rise flex flex-1 flex-col">
        <p className="text-xs tracking-[0.22em] text-accent">{current.kicker}</p>
        <h1 className="mt-3 max-w-xl font-serif text-4xl leading-[1.05] sm:text-6xl">{current.title}</h1>
        {current.hint && <p className="mt-3 max-w-md text-muted">{current.hint}</p>}
        {current.kind === "text" ? (
          <input
            autoFocus
            value={draft.name}
            placeholder="Your name"
            onChange={(e) => setDraft({ ...draft, name: e.target.value })}
            className="mt-10 w-full border-b border-line bg-transparent pb-3 font-serif text-4xl text-fg outline-none placeholder:text-line sm:text-5xl"
          />
        ) : (
          <div className={`mt-8 grid gap-3 ${current.multi ? "sm:grid-cols-2" : ""}`}>
            {current.options?.map((option) => {
              const on = current.multi ? draft.focus.includes(option.id) : selected === option.id;
              return (
                <button
                  key={option.id}
                  type="button"
                  onClick={() => choose(option.id)}
                  className={`opt flex min-h-16 items-center justify-between rounded-card border px-5 text-left text-lg ${
                    on ? "border-accent bg-surface-2" : "border-line bg-surface"
                  } ${pulse === option.id ? "pop" : ""}`}
                >
                  <span>{option.label}</span>
                  <span className={`grid h-6 w-6 place-items-center rounded-full border ${on ? "border-accent bg-accent" : "border-line"}`}>
                    {on && <span className="h-2 w-2 rounded-full bg-accent-ink" />}
                  </span>
                </button>
              );
            })}
          </div>
        )}
        <div className="mt-auto flex items-center justify-between pt-10">
          <button
            type="button"
            className="min-h-11 px-2 text-muted disabled:opacity-30"
            onClick={() => setStep((s) => Math.max(0, s - 1))}
            disabled={step === 0}
          >
            Back
          </button>
          {(current.kind === "text" || current.multi || step === total - 1) && (
            <button
              type="button"
              disabled={!ready}
              onClick={() => (step === total - 1 ? onDone(draft) : setStep((s) => s + 1))}
              className="min-h-12 rounded-full bg-accent px-6 font-medium text-accent-ink disabled:opacity-40"
            >
              {step === total - 1 ? "Enter the lab" : "Continue"}
            </button>
          )}
        </div>
      </div>
    </Shell>
  );
}

type Question = {
  key: keyof Profile | "focus";
  kicker: string;
  title: string;
  hint?: string;
  kind?: "text";
  multi?: boolean;
  options?: { id: string; label: string }[];
};

function valueOf(draft: Profile, key: Question["key"]) {
  if (key === "focus") return draft.focus[0] ?? "";
  return String(draft[key] ?? "");
}

function applyAnswer(draft: Profile, key: Question["key"], id: string): Profile {
  if (key === "gender") return { ...draft, gender: id as Gender };
  if (key === "age") return { ...draft, age: id };
  if (key === "height") return { ...draft, height: id };
  if (key === "heard") return { ...draft, heard: id };
  if (key === "goal") return { ...draft, goal: id };
  if (key === "skincare") return { ...draft, skincare: id };
  if (key === "training") return { ...draft, training: id };
  return draft;
}

function Home({
  profile,
  history,
  onStart,
  onHistory,
}: {
  profile: Profile;
  history: Saved[];
  onStart: () => void;
  onHistory: () => void;
}) {
  const last = history[0];
  return (
    <Shell>
      <div className="rise grid flex-1 items-end gap-10 lg:grid-cols-2">
        <div>
          <p className="text-sm text-muted">Hello, {profile.name.trim() || "there"}</p>
          <h1 className="mt-3 max-w-lg font-serif text-5xl leading-[1.05] sm:text-6xl">
            Your face. Measured where it actually is.
          </h1>
          <p className="mt-5 max-w-md text-muted">
            Front and side photos. A mesh that follows the face even if it is off to the side.
            Four pillars, each scored from the landmarks.
          </p>
          <div className="mt-8 flex flex-wrap gap-3">
            <button
              type="button"
              onClick={onStart}
              className="inline-flex min-h-12 items-center gap-2 rounded-full bg-accent px-6 font-medium text-accent-ink"
            >
              <ScanFace className="h-4 w-4" />
              New analysis
            </button>
            <button
              type="button"
              onClick={onHistory}
              className="inline-flex min-h-12 items-center gap-2 rounded-full border border-line px-5 text-fg"
            >
              <History className="h-4 w-4" />
              Progress
            </button>
          </div>
        </div>
        <div className="grid gap-3 sm:grid-cols-2">
          {PILLARS.map((p) => (
            <article key={p.id} className="rounded-card border border-line bg-surface p-5">
              <h2 className="font-serif text-2xl">{p.title}</h2>
              <p className="mt-1 text-sm text-muted">{p.line}</p>
            </article>
          ))}
          {last && (
            <article className="rounded-card border border-line bg-surface-2 p-5 sm:col-span-2">
              <p className="text-sm text-muted">Last reading</p>
              <p className="mt-1 font-serif text-4xl" style={{ color: scoreTone(last.overall) }}>
                {last.overall.toFixed(1)}
              </p>
              <p className="text-sm text-muted">{last.label}</p>
            </article>
          )}
        </div>
      </div>
    </Shell>
  );
}

function Capture({
  onBack,
  onScan,
}: {
  onBack: () => void;
  onScan: (front: Shot, side: Shot | null) => void;
}) {
  const [front, setFront] = useState<Shot | null>(null);
  const [side, setSide] = useState<Shot | null>(null);

  return (
    <Shell eyebrow="Photos">
      <button type="button" onClick={onBack} className="mb-4 inline-flex min-h-11 items-center gap-1 text-muted">
        <ChevronLeft className="h-4 w-4" /> Home
      </button>
      <h1 className="font-serif text-4xl sm:text-5xl">Two photos. Any position.</h1>
      <p className="mt-3 max-w-lg text-muted">
        The face does not need to be in the middle. Keep the whole face in frame, light even, expression
        neutral. Side is optional.
      </p>
      <div className="mt-8 grid gap-4 sm:grid-cols-2">
        <Slot label="Front" required shot={front} onPick={setFront} />
        <Slot label="Side" shot={side} onPick={setSide} />
      </div>
      <button
        type="button"
        disabled={!front}
        onClick={() => front && onScan(front, side)}
        className="mt-8 min-h-12 w-full rounded-full bg-accent font-medium text-accent-ink disabled:opacity-40 sm:w-auto sm:px-8"
      >
        Scan face
      </button>
    </Shell>
  );
}

function Slot({
  label,
  required,
  shot,
  onPick,
}: {
  label: string;
  required?: boolean;
  shot: Shot | null;
  onPick: (s: Shot) => void;
}) {
  const fileRef = useRef<HTMLInputElement>(null);
  const camRef = useRef<HTMLInputElement>(null);

  function take(file: File | undefined) {
    if (!file) return;
    const src = URL.createObjectURL(file);
    onPick({ src, name: file.name });
  }

  return (
    <div className="overflow-hidden rounded-card border border-line bg-surface">
      <div className="frame-portrait relative bg-surface-2">
        {shot ? (
          <img src={shot.src} alt="" className="h-full w-full object-contain" />
        ) : (
          <div className="grid h-full place-items-center text-muted">
            <div className="text-center">
              <ImagePlus className="mx-auto h-6 w-6" />
              <p className="mt-2 text-sm">
                {label}
                {required ? " · required" : " · optional"}
              </p>
            </div>
          </div>
        )}
      </div>
      <div className="flex gap-2 p-3">
        <button
          type="button"
          onClick={() => fileRef.current?.click()}
          className="min-h-11 flex-1 rounded-full border border-line text-sm"
        >
          Gallery
        </button>
        <button
          type="button"
          onClick={() => camRef.current?.click()}
          className="inline-flex min-h-11 flex-1 items-center justify-center gap-1 rounded-full border border-line text-sm"
        >
          <Camera className="h-4 w-4" /> Camera
        </button>
      </div>
      <input ref={fileRef} type="file" accept="image/*" hidden onChange={(e) => take(e.target.files?.[0])} />
      <input
        ref={camRef}
        type="file"
        accept="image/*"
        capture="user"
        hidden
        onChange={(e) => take(e.target.files?.[0])}
      />
    </div>
  );
}

function Scan({
  front,
  gender,
  onDone,
  onFail,
}: {
  front: Shot;
  gender: Gender;
  onDone: (report: Report, profile: Report, thumb: string) => void;
  onFail: () => void;
}) {
  const [status, setStatus] = useState("Finding the face…");
  const [error, setError] = useState("");
  const [points, setPoints] = useState<Pt[] | null>(null);
  const [links, setLinks] = useState<Conn[]>([]);
  const [progress, setProgress] = useState(0);
  const box = useRef<HTMLDivElement>(null);

  const doneRef = useRef(onDone);
  doneRef.current = onDone;

  useEffect(() => {
    let stop = false;
    const started = performance.now();
    let frame = 0;
    const tick = (now: number) => {
      const p = Math.min(1, (now - started) / 2200);
      setProgress(p);
      if (p < 1 && !stop) frame = requestAnimationFrame(tick);
    };
    frame = requestAnimationFrame(tick);

    (async () => {
      try {
        setStatus("Mapping landmarks…");
        const frontRead = await readFace(front.src);
        if (stop) return;
        setPoints(frontRead.points);
        setLinks(frontRead.links);
        setStatus("Scoring geometry…");
        const report = analyzeFace(frontRead.points, gender, {
          w: frontRead.image.naturalWidth,
          h: frontRead.image.naturalHeight,
        });
        const profile = analyzeProfile(frontRead.points, gender, {
          w: frontRead.image.naturalWidth,
          h: frontRead.image.naturalHeight,
        }, "depth");
        let thumb = "";
        try {
          thumb = thumbnail(frontRead.image);
        } catch {
          thumb = "";
        }
        await wait(Math.max(0, 700 - (performance.now() - started)));
        if (!stop) doneRef.current(report, profile, thumb);
      } catch (err) {
        if (!stop) setError(err instanceof Error ? err.message : "Scan failed");
      }
    })();

    return () => {
      stop = true;
      cancelAnimationFrame(frame);
    };
  }, [front.src, gender]);

  return (
    <main className="mx-auto flex min-h-screen max-w-3xl flex-col px-5 py-8">
      <p className="text-sm text-muted">{status}</p>
      <h1 className="mt-2 font-serif text-4xl">Reading the mesh</h1>
      {error && (
        <div className="mt-4">
          <p className="text-muted">{error}</p>
          <button type="button" onClick={onFail} className="mt-4 min-h-12 rounded-full bg-accent px-6 text-accent-ink">
            Try another photo
          </button>
        </div>
      )}
      <div ref={box} className="frame-portrait relative mt-6 overflow-hidden rounded-card bg-surface">
        <img src={front.src} alt="" className="h-full w-full object-contain" />
        {points && <MeshOverlay points={points} links={links} progress={progress} />}
        <div className="scan-bar pointer-events-none absolute inset-x-0 h-16 bg-gradient-to-b from-transparent via-accent/40 to-transparent" />
      </div>
    </main>
  );
}

function MeshOverlay({ points, links, progress }: { points: Pt[]; links: Conn[]; progress: number }) {
  const ref = useRef<HTMLCanvasElement>(null);

  useEffect(() => {
    const canvas = ref.current;
    const parent = canvas?.parentElement;
    const img = parent?.querySelector("img");
    if (!canvas || !parent || !(img instanceof HTMLImageElement)) return;

    const draw = () => {
      const rect = parent.getBoundingClientRect();
      const dpr = Math.min(2, window.devicePixelRatio || 1);
      canvas.width = Math.round(rect.width * dpr);
      canvas.height = Math.round(rect.height * dpr);
      canvas.style.width = `${rect.width}px`;
      canvas.style.height = `${rect.height}px`;
      const ctx = canvas.getContext("2d");
      if (!ctx) return;
      ctx.setTransform(dpr, 0, 0, dpr, 0, 0);
      ctx.clearRect(0, 0, rect.width, rect.height);
      const fit = contain(img.naturalWidth || 1, img.naturalHeight || 1, rect.width, rect.height);
      const visible = Math.floor(links.length * progress);
      ctx.strokeStyle = "rgba(196,165,116,0.9)";
      ctx.lineWidth = 1.1;
      ctx.beginPath();
      for (let i = 0; i < visible; i++) {
        const a = points[links[i].start];
        const b = points[links[i].end];
        if (!a || !b) continue;
        ctx.moveTo(fit.x + a.x * fit.w, fit.y + a.y * fit.h);
        ctx.lineTo(fit.x + b.x * fit.w, fit.y + b.y * fit.h);
      }
      ctx.stroke();
      ctx.fillStyle = "rgba(244,241,234,0.95)";
      const dots = Math.floor(points.length * progress);
      for (let i = 0; i < dots; i += 6) {
        const p = points[i];
        ctx.beginPath();
        ctx.arc(fit.x + p.x * fit.w, fit.y + p.y * fit.h, 1.4, 0, Math.PI * 2);
        ctx.fill();
      }
    };
    draw();
    const obs = new ResizeObserver(draw);
    obs.observe(parent);
    return () => obs.disconnect();
  }, [points, links, progress]);

  return <canvas ref={ref} className="pointer-events-none absolute inset-0 h-full w-full" />;
}

function contain(iw: number, ih: number, bw: number, bh: number) {
  const s = Math.min(bw / iw, bh / ih);
  const w = iw * s;
  const h = ih * s;
  return { x: (bw - w) / 2, y: (bh - h) / 2, w, h };
}

function thumbnail(image: HTMLImageElement) {
  const canvas = document.createElement("canvas");
  canvas.width = 160;
  canvas.height = 200;
  const ctx = canvas.getContext("2d");
  if (!ctx) return "";
  ctx.fillStyle = "#15171c";
  ctx.fillRect(0, 0, 160, 200);
  const s = Math.min(160 / image.naturalWidth, 200 / image.naturalHeight);
  const w = image.naturalWidth * s;
  const h = image.naturalHeight * s;
  ctx.drawImage(image, (160 - w) / 2, (200 - h) / 2, w, h);
  return canvas.toDataURL("image/jpeg", 0.72);
}

function wait(ms: number) {
  return new Promise((r) => setTimeout(r, ms));
}

function withTimeout<T>(work: Promise<T>, ms: number, message: string) {
  return new Promise<T>((resolve, reject) => {
    const timer = setTimeout(() => reject(new Error(message)), ms);
    work.then(
      (value) => {
        clearTimeout(timer);
        resolve(value);
      },
      (err) => {
        clearTimeout(timer);
        reject(err);
      },
    );
  });
}

function Result({
  front,
  side,
  report,
  profile,
  gender,
  onHome,
  onAgain,
}: {
  front: Shot;
  side: Shot | null;
  report: Report;
  profile: Report;
  gender: Gender;
  onHome: () => void;
  onAgain: () => void;
}) {
  const [profileReport, setProfileReport] = useState(profile);
  const [sideNote, setSideNote] = useState<string | null>(
    side ? "Checking the side photo…" : "Estimated from the depth of the front photo.",
  );

  useEffect(() => {
    if (!side) return;
    let stop = false;
    (async () => {
      try {
        const sideRead = await withTimeout(readFace(side.src), 12000, "The side photo took too long.");
        if (stop) return;
        setProfileReport(
          analyzeProfile(
            sideRead.points,
            gender,
            { w: sideRead.image.naturalWidth, h: sideRead.image.naturalHeight },
            "photo",
          ),
        );
        setSideNote("Measured on your side photo.");
      } catch (err) {
        if (!stop) {
          setSideNote(
            err instanceof Error
              ? `${err.message} Showing the profile estimated from the front photo instead.`
              : "Side photo failed. Showing the estimate from the front photo.",
          );
        }
      }
    })();
    return () => {
      stop = true;
    };
  }, [side, gender]);

  return (
    <main className="mx-auto max-w-6xl px-5 py-6 sm:px-8">
      <div className="mb-6 flex items-center justify-between">
        <button type="button" onClick={onHome} className="inline-flex min-h-11 items-center gap-1 text-muted">
          <ChevronLeft className="h-4 w-4" /> Home
        </button>
        <button
          type="button"
          onClick={onAgain}
          className="min-h-11 rounded-full bg-accent px-5 text-sm font-medium text-accent-ink"
        >
          New scan
        </button>
      </div>
      <ScoreBoard title="Front" photo={front.src} report={report} />
      <div className="my-10 h-px bg-line" />
      <ScoreBoard title="Side profile" photo={side?.src ?? front.src} report={profileReport} note={sideNote} />
    </main>
  );
}

function ScoreBoard({ title, photo, report, note }: { title: string; photo: string; report: Report; note?: string | null }) {
  const [pillar, setPillar] = useState<Pillar>("harmony");
  const [open, setOpen] = useState<string | null>(null);
  const shown = useMemo(() => report.metrics.filter((m) => m.pillar === pillar), [report, pillar]);

  return (
    <section className="grid items-start gap-8 lg:grid-cols-2">
      <div className="overflow-hidden rounded-card bg-surface">
        <img src={photo} alt="" className="max-h-[70vh] w-full object-contain" />
      </div>
      <div>
        <p className="text-xs tracking-[0.22em] text-accent">{title}</p>
        <p className="mt-2 font-serif text-7xl leading-none" style={{ color: scoreTone(report.overall) }}>
          {report.overall.toFixed(1)}
        </p>
        <p className="mt-2 text-sm text-muted">
          {report.label}
          {note ? ` · ${note}` : ""}
        </p>
        <p className="mt-3 max-w-md text-sm text-muted">{report.note}</p>
        <div className="mt-6 grid grid-cols-2 gap-2">
          {PILLARS.map((p) => (
            <button
              key={p.id}
              type="button"
              onClick={() => {
                setPillar(p.id);
                setOpen(null);
              }}
              className={`rounded-2xl border p-3 text-left transition-transform duration-200 ${
                pillar === p.id ? "scale-[1.02] border-accent bg-surface-2" : "border-line bg-surface"
              }`}
            >
              <p className="text-sm text-muted">{p.title}</p>
              <p className="font-serif text-3xl" style={{ color: scoreTone(report.pillars[p.id]) }}>
                {report.pillars[p.id].toFixed(1)}
              </p>
            </button>
          ))}
        </div>
        <ul className="mt-6">
          {shown.map((row) => (
            <MetricRow key={row.id} metric={row} open={open === row.id} onToggle={() => setOpen(open === row.id ? null : row.id)} />
          ))}
        </ul>
      </div>
    </section>
  );
}

function MetricRow({ metric, open, onToggle }: { metric: Metric; open: boolean; onToggle: () => void }) {
  return (
    <li className="border-b border-line">
      <button type="button" onClick={onToggle} className="flex w-full items-center gap-3 py-3 text-left">
        <div className="min-w-0 flex-1">
          <p>{metric.label}</p>
          <p className="text-sm text-muted">{metric.display}</p>
          <span className="mt-2 block h-1 overflow-hidden rounded-full bg-line">
            <span
              className="block h-full rounded-full transition-all duration-500"
              style={{ width: `${metric.score * 10}%`, background: scoreTone(metric.score) }}
            />
          </span>
        </div>
        <p className="font-serif text-2xl" style={{ color: scoreTone(metric.score) }}>
          {metric.score.toFixed(1)}
        </p>
      </button>
      {open && <p className="rise pb-3 text-sm text-muted">{metric.detail}</p>}
    </li>
  );
}

function HistoryView({ rows, onBack }: { rows: Saved[]; onBack: () => void }) {
  return (
    <Shell>
      <button type="button" onClick={onBack} className="mb-4 inline-flex min-h-11 items-center gap-1 text-muted">
        <ChevronLeft className="h-4 w-4" /> Home
      </button>
      <h1 className="font-serif text-4xl">Progress</h1>
      {rows.length === 0 ? (
        <p className="mt-4 text-muted">No readings yet.</p>
      ) : (
        <ul className="mt-6 grid gap-3">
          {rows.map((row) => (
            <li key={row.id} className="flex items-center gap-4 rounded-card border border-line bg-surface p-3">
              <img src={row.thumb} alt="" className="h-16 w-16 rounded-xl object-cover" />
              <div className="flex-1">
                <p className="text-sm text-muted">{new Date(row.createdAt).toLocaleString()}</p>
                <p>{row.label}</p>
              </div>
              <p className="font-serif text-3xl" style={{ color: scoreTone(row.overall) }}>
                {row.overall.toFixed(1)}
              </p>
            </li>
          ))}
        </ul>
      )}
    </Shell>
  );
}
