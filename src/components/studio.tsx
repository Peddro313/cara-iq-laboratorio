import { useEffect, useMemo, useRef, useState, type ReactNode } from "react";
import { Camera, ChevronLeft, History, ImagePlus, ScanFace } from "lucide-react";
import { readFace, type Conn } from "@/lib/face/detect";
import {
  analyzeFace,
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
  | { name: "result"; front: Shot; report: Report; sideOk: boolean }
  | { name: "history" };

const PROFILE_KEY = "cara-iq-profile";
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
          side={phase.side}
          gender={profile.gender}
          onFail={() => setPhase({ name: "capture" })}
          onDone={(report, sideOk, thumb) => {
            remember({ ...report }, thumb);
            setPhase({ name: "result", front: phase.front, report, sideOk });
          }}
        />
      )}
      {phase.name === "result" && (
        <Result
          front={phase.front}
          report={phase.report}
          sideOk={phase.sideOk}
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
  const [draft, setDraft] = useState<Profile>({
    name: "",
    gender: "male",
    age: "",
    height: "",
    heard: "",
    goal: "",
    focus: [],
    skincare: "",
    training: "",
  });

  const steps = 5;
  const can =
    (step === 0 && draft.name.trim() && draft.age) ||
    (step === 1 && draft.heard && draft.goal) ||
    (step === 2 && draft.focus.length > 0) ||
    (step === 3 && draft.skincare && draft.training) ||
    step === 4;

  return (
    <Shell eyebrow={`${step + 1} / ${steps}`}>
      <div className="mb-8 flex gap-2">
        {Array.from({ length: steps }).map((_, i) => (
          <span
            key={i}
            className={`h-1 flex-1 rounded-full ${i <= step ? "bg-accent" : "bg-line"}`}
          />
        ))}
      </div>
      <div key={step} className="rise flex flex-1 flex-col">
        {step === 0 && (
          <About draft={draft} setDraft={setDraft} />
        )}
        {step === 1 && <Why draft={draft} setDraft={setDraft} />}
        {step === 2 && <Focus draft={draft} setDraft={setDraft} />}
        {step === 3 && <Habits draft={draft} setDraft={setDraft} />}
        {step === 4 && (
          <div className="max-w-xl">
            <h1 className="font-serif text-4xl leading-tight sm:text-5xl">
              The face can sit anywhere in the frame.
            </h1>
            <p className="mt-4 max-w-md text-muted">
              We map 478 landmarks on the photo itself. Scores follow the geometry, not a
              centered template.
            </p>
          </div>
        )}
        <div className="mt-auto flex items-center justify-between pt-10">
          <button
            type="button"
            className="min-h-11 px-2 text-muted"
            onClick={() => setStep((s) => Math.max(0, s - 1))}
            disabled={step === 0}
          >
            Back
          </button>
          <button
            type="button"
            disabled={!can}
            onClick={() => (step === 4 ? onDone(draft) : setStep((s) => s + 1))}
            className="min-h-12 rounded-full bg-accent px-6 font-medium text-accent-ink disabled:opacity-40"
          >
            {step === 4 ? "Enter the lab" : "Continue"}
          </button>
        </div>
      </div>
    </Shell>
  );
}

function About({
  draft,
  setDraft,
}: {
  draft: Profile;
  setDraft: (p: Profile) => void;
}) {
  return (
    <div>
      <h1 className="font-serif text-4xl sm:text-5xl">About you</h1>
      <p className="mt-2 text-muted">Used to tune dimorphism. Nothing leaves this device.</p>
      <label className="mt-8 block text-sm text-muted">
        Name
        <input
          value={draft.name}
          onChange={(e) => setDraft({ ...draft, name: e.target.value })}
          className="mt-2 w-full rounded-2xl border border-line bg-surface px-4 py-3 text-fg outline-none"
        />
      </label>
      <p className="mt-6 text-sm text-muted">Gender</p>
      <div className="mt-2 flex flex-wrap gap-2">
        {(["male", "female", "other"] as Gender[]).map((g) => (
          <Choice
            key={g}
            active={draft.gender === g}
            label={g === "other" ? "Prefer not to say" : g[0].toUpperCase() + g.slice(1)}
            onClick={() => setDraft({ ...draft, gender: g })}
          />
        ))}
      </div>
      <div className="mt-6 grid grid-cols-2 gap-3">
        <label className="text-sm text-muted">
          Age
          <input
            inputMode="numeric"
            value={draft.age}
            onChange={(e) => setDraft({ ...draft, age: e.target.value })}
            className="mt-2 w-full rounded-2xl border border-line bg-surface px-4 py-3 text-fg outline-none"
          />
        </label>
        <label className="text-sm text-muted">
          Height cm
          <input
            inputMode="numeric"
            value={draft.height}
            onChange={(e) => setDraft({ ...draft, height: e.target.value })}
            className="mt-2 w-full rounded-2xl border border-line bg-surface px-4 py-3 text-fg outline-none"
          />
        </label>
      </div>
    </div>
  );
}

function Why({ draft, setDraft }: { draft: Profile; setDraft: (p: Profile) => void }) {
  const heard = ["TikTok", "Instagram", "YouTube", "A friend", "Search"];
  const goals = ["See my rating", "Get tips", "Track progress", "Learn the features"];
  return (
    <div>
      <h1 className="font-serif text-4xl sm:text-5xl">Why you are here</h1>
      <p className="mt-6 text-sm text-muted">First heard from</p>
      <div className="mt-2 grid gap-2">
        {heard.map((h) => (
          <Row key={h} active={draft.heard === h} label={h} onClick={() => setDraft({ ...draft, heard: h })} />
        ))}
      </div>
      <p className="mt-6 text-sm text-muted">Main goal</p>
      <div className="mt-2 grid gap-2">
        {goals.map((h) => (
          <Row key={h} active={draft.goal === h} label={h} onClick={() => setDraft({ ...draft, goal: h })} />
        ))}
      </div>
    </div>
  );
}

function Focus({ draft, setDraft }: { draft: Profile; setDraft: (p: Profile) => void }) {
  const opts = ["Nose", "Lips", "Jaw", "Eyes", "Skin", "Harmony", "Cheekbones"];
  function toggle(o: string) {
    const focus = draft.focus.includes(o) ? draft.focus.filter((x) => x !== o) : [...draft.focus, o];
    setDraft({ ...draft, focus });
  }
  return (
    <div>
      <h1 className="font-serif text-4xl sm:text-5xl">What do you want to understand?</h1>
      <p className="mt-2 text-muted">Pick any that matter.</p>
      <div className="mt-6 flex flex-wrap gap-2">
        {opts.map((o) => (
          <Choice key={o} active={draft.focus.includes(o)} label={o} onClick={() => toggle(o)} />
        ))}
      </div>
    </div>
  );
}

function Habits({ draft, setDraft }: { draft: Profile; setDraft: (p: Profile) => void }) {
  const freq = ["Rarely", "A few times a month", "A few times a week", "Daily"];
  return (
    <div>
      <h1 className="font-serif text-4xl sm:text-5xl">Habits</h1>
      <p className="mt-6 text-sm text-muted">Skincare</p>
      <div className="mt-2 grid gap-2">
        {freq.map((h) => (
          <Row key={h} active={draft.skincare === h} label={h} onClick={() => setDraft({ ...draft, skincare: h })} />
        ))}
      </div>
      <p className="mt-6 text-sm text-muted">Jaw, posture, or face training</p>
      <div className="mt-2 grid gap-2">
        {freq.map((h) => (
          <Row key={`t-${h}`} active={draft.training === h} label={h} onClick={() => setDraft({ ...draft, training: h })} />
        ))}
      </div>
    </div>
  );
}

function Choice({ active, label, onClick }: { active: boolean; label: string; onClick: () => void }) {
  return (
    <button
      type="button"
      onClick={onClick}
      className={`min-h-11 rounded-full border px-4 text-sm transition-transform duration-200 ${
        active ? "scale-105 border-accent bg-accent text-accent-ink" : "border-line bg-surface text-fg"
      }`}
    >
      {label}
    </button>
  );
}

function Row({ active, label, onClick }: { active: boolean; label: string; onClick: () => void }) {
  return (
    <button
      type="button"
      onClick={onClick}
      className={`flex min-h-12 items-center justify-between rounded-2xl border px-4 text-left transition-colors ${
        active ? "border-accent bg-surface-2" : "border-line bg-surface"
      }`}
    >
      <span>{label}</span>
      <span className={`h-2.5 w-2.5 rounded-full ${active ? "bg-accent" : "bg-line"}`} />
    </button>
  );
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
  side,
  gender,
  onDone,
  onFail,
}: {
  front: Shot;
  side: Shot | null;
  gender: Gender;
  onDone: (report: Report, sideOk: boolean, thumb: string) => void;
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
        let sideOk = false;
        if (side) {
          try {
            await readFace(side.src);
            sideOk = true;
          } catch {
            sideOk = false;
          }
        }
        const report = analyzeFace(frontRead.points, gender, {
          w: frontRead.image.naturalWidth,
          h: frontRead.image.naturalHeight,
        });
        const thumb = thumbnail(frontRead.image);
        await wait(Math.max(0, 1800 - (performance.now() - started)));
        if (!stop) doneRef.current(report, side ? sideOk : true, thumb);
      } catch (err) {
        if (!stop) setError(err instanceof Error ? err.message : "Scan failed");
      }
    })();

    return () => {
      stop = true;
      cancelAnimationFrame(frame);
    };
  }, [front.src, side, gender]);

  return (
    <main className="mx-auto flex min-h-screen max-w-3xl flex-col px-5 py-8">
      <p className="text-sm text-muted">{status}</p>
      <h1 className="mt-2 font-serif text-4xl">Reading the mesh</h1>
      <div ref={box} className="frame-portrait relative mt-6 overflow-hidden rounded-card bg-surface">
        <img src={front.src} alt="" className="h-full w-full object-contain" />
        {points && <MeshOverlay points={points} links={links} progress={progress} />}
        <div className="scan-bar pointer-events-none absolute inset-x-0 h-16 bg-gradient-to-b from-transparent via-accent/40 to-transparent" />
      </div>
      {error && (
        <div className="mt-6">
          <p className="text-muted">{error}</p>
          <button type="button" onClick={onFail} className="mt-4 min-h-12 rounded-full bg-accent px-6 text-accent-ink">
            Try another photo
          </button>
        </div>
      )}
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

function Result({
  front,
  report,
  sideOk,
  onHome,
  onAgain,
}: {
  front: Shot;
  report: Report;
  sideOk: boolean;
  onHome: () => void;
  onAgain: () => void;
}) {
  const [pillar, setPillar] = useState<Pillar>("harmony");
  const rows = useMemo(() => report.metrics.filter((m) => m.pillar === pillar), [report, pillar]);

  return (
    <main className="mx-auto grid min-h-screen max-w-6xl lg:grid-cols-2">
      <div className="relative min-h-[42vh] bg-surface lg:min-h-screen">
        <img src={front.src} alt="Analyzed face" className="h-full w-full object-contain" />
        <button
          type="button"
          onClick={onHome}
          className="absolute left-4 top-4 inline-flex min-h-11 items-center gap-1 rounded-full bg-bg/80 px-3 text-sm"
        >
          <ChevronLeft className="h-4 w-4" /> Home
        </button>
      </div>
      <div className="px-5 py-6 sm:px-8">
        <p className="text-sm text-muted">{report.label}</p>
        <p className="font-serif text-7xl leading-none" style={{ color: scoreTone(report.overall) }}>
          {report.overall.toFixed(1)}
        </p>
        <p className="mt-3 max-w-md text-sm text-muted">{report.note}</p>
        {!sideOk && (
          <p className="mt-2 text-sm text-muted">
            Side photo was not readable as a face. Front landmarks still drove the score.
          </p>
        )}
        <div className="mt-6 grid grid-cols-2 gap-2">
          {PILLARS.map((p) => (
            <button
              key={p.id}
              type="button"
              onClick={() => setPillar(p.id)}
              className={`rounded-2xl border p-3 text-left ${pillar === p.id ? "border-accent bg-surface-2" : "border-line bg-surface"}`}
            >
              <p className="text-sm text-muted">{p.title}</p>
              <p className="font-serif text-3xl" style={{ color: scoreTone(report.pillars[p.id]) }}>
                {report.pillars[p.id].toFixed(1)}
              </p>
            </button>
          ))}
        </div>
        <ul className="mt-6 divide-y divide-line">
          {rows.map((row) => (
            <MetricRow key={row.id} metric={row} />
          ))}
        </ul>
        <button
          type="button"
          onClick={onAgain}
          className="mt-8 min-h-12 w-full rounded-full bg-accent font-medium text-accent-ink"
        >
          Analyze another face
        </button>
      </div>
    </main>
  );
}

function MetricRow({ metric }: { metric: Metric }) {
  return (
    <li className="flex items-center gap-3 py-3">
      <div className="min-w-0 flex-1">
        <p>{metric.label}</p>
        <p className="text-sm text-muted">{metric.display}</p>
      </div>
      <p className="font-serif text-2xl" style={{ color: scoreTone(metric.score) }}>
        {metric.score.toFixed(1)}
      </p>
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
