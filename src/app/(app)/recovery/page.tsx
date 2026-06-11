import { SectionTitle } from "@/components/ui/SectionTitle";
import { Ring } from "@/components/ui/Ring";
import { Bar } from "@/components/ui/Bar";
import { Sparkline, Barline } from "@/components/ui/Sparkline";
import { Stat } from "@/components/ui/Stat";
import {
  today,
  recoveryTrend,
  hrvTrend,
  sleepTrend,
} from "@/lib/mock/user";

export default function RecoveryPage() {
  return (
    <div className="space-y-6">
      <SectionTitle
        eyebrow="Recover"
        title="Recovery & Sleep"
        subtitle="HRV, RHR, sleep stages, debt, strain, readiness — synthesized into a daily decision."
      />

      {/* Rings */}
      <div className="grid gap-4 lg:grid-cols-4">
        <RingCard value={today.recovery} label="Recovery" sub={`Δ ${today.recoveryDelta} vs 7d`} tone="green" />
        <RingCard value={today.sleep} label="Sleep" sub={`${today.sleepHours} h`} tone="royal" />
        <RingCard value={Math.round((today.hrv / 80) * 100)} label="HRV" sub={`${today.hrv} ms`} tone="gold" />
        <RingCard value={Math.round((today.restingHr / 80) * 100)} label="RHR" sub={`${today.restingHr} bpm`} tone="ruby" inverted />
      </div>

      {/* Sleep breakdown + trends */}
      <div className="grid gap-4 lg:grid-cols-3">
        <div className="card p-6 lg:col-span-2">
          <div className="mb-3 flex items-baseline justify-between">
            <div className="display text-xl text-cream-50">Last night · {today.sleepHours} h</div>
            <span className="chip chip-gold">Sleep score 84</span>
          </div>
          <SleepBar />
          <div className="mt-4 grid grid-cols-2 gap-3 sm:grid-cols-4">
            <Stat label="Deep" value={today.sleepDeep} unit="h" hint="target 1.5+" />
            <Stat label="REM" value={today.sleepRem} unit="h" hint="target 1.6+" />
            <Stat label="Light" value={(today.sleepHours - today.sleepDeep - today.sleepRem).toFixed(1)} unit="h" />
            <Stat label="Wake" value="0.4" unit="h" />
          </div>
        </div>

        <div className="card p-6">
          <div className="mb-3 text-[10px] uppercase tracking-[0.22em] text-gold-300">Sleep debt</div>
          <div className="stat-num text-4xl text-forge-amber">4h 20m</div>
          <div className="mt-1 text-[12px] text-obsidian-200">7-day cumulative deficit</div>
          <div className="hairline my-4" />
          <div className="text-[10px] uppercase tracking-[0.22em] text-gold-300 mb-2">Recommendation</div>
          <p className="text-[13px] text-cream-200">
            Lights out 21:45 tonight (8.25h window). Add Mg-glycinate 400 mg pre-bed. Avoid screens for the
            last 60 minutes — the deepest part of your deep sleep window is the first 90 min.
          </p>
        </div>
      </div>

      {/* Trends */}
      <div className="grid gap-4 lg:grid-cols-3">
        <TrendCard title="HRV · 14d" data={hrvTrend} unit="ms" />
        <TrendCard title="Recovery · 14d" data={recoveryTrend} unit="/100" />
        <TrendCard title="Sleep hours · 14d" data={sleepTrend.map((s) => Math.round(s * 10) / 10)} unit="h" />
      </div>

      {/* Readiness */}
      <div className="card p-6">
        <div className="mb-2 display text-xl text-cream-50">Training Readiness</div>
        <div className="mb-4 text-sm text-obsidian-200">
          Synthesizing HRV trend, sleep, RHR, training strain, and stress markers.
        </div>
        <Bar value={65} max={100} tone="gold" height={12} />
        <div className="mt-2 flex justify-between text-[10px] uppercase tracking-wider text-obsidian-200">
          <span>Low</span>
          <span>Moderate</span>
          <span>High</span>
          <span>Peak</span>
        </div>
        <div className="mt-4 grid grid-cols-2 gap-3 text-[12px] sm:grid-cols-4">
          <Driver label="HRV trend" value="−12%" tone="bad" />
          <Driver label="Sleep adherence" value="71%" tone="warn" />
          <Driver label="ACR" value="1.38" tone="warn" />
          <Driver label="Subjective" value="6/10" tone="warn" />
        </div>
      </div>
    </div>
  );
}

function RingCard({
  value,
  label,
  sub,
  tone,
  inverted = false,
}: {
  value: number;
  label: string;
  sub: string;
  tone: "gold" | "green" | "ruby" | "royal";
  inverted?: boolean;
}) {
  return (
    <div className="card p-5">
      <div className="flex items-center gap-4">
        <Ring value={inverted ? 100 - value : value} size={96} stroke={7} tone={tone} />
        <div>
          <div className="text-[10px] uppercase tracking-[0.18em] text-obsidian-200">{label}</div>
          <div className="mt-0.5 text-xs text-cream-200">{sub}</div>
        </div>
      </div>
    </div>
  );
}

function SleepBar() {
  // Stylized sleep stages overnight: 23:30 → 06:54
  const stages = [
    { kind: "light", h: 0.4 },
    { kind: "deep", h: 0.8 },
    { kind: "rem", h: 0.4 },
    { kind: "light", h: 0.6 },
    { kind: "deep", h: 0.4 },
    { kind: "rem", h: 0.6 },
    { kind: "light", h: 0.9 },
    { kind: "rem", h: 0.6 },
    { kind: "wake", h: 0.2 },
    { kind: "light", h: 1.2 },
    { kind: "rem", h: 0.4 },
    { kind: "wake", h: 0.2 },
  ];
  const total = stages.reduce((s, x) => s + x.h, 0);
  const color = (k: string) =>
    k === "deep" ? "#3a5a8c" : k === "rem" ? "#a08540" : k === "light" ? "#5a6275" : "#9b2a3f";

  return (
    <div>
      <div className="flex h-14 overflow-hidden rounded-md border border-gold-400/10">
        {stages.map((s, i) => (
          <div
            key={i}
            style={{ width: `${(s.h / total) * 100}%`, background: color(s.kind) }}
            title={`${s.kind} ${s.h}h`}
          />
        ))}
      </div>
      <div className="mt-2 flex justify-between text-[10px] uppercase tracking-wider text-obsidian-200">
        <span>23:30</span>
        <span>06:54</span>
      </div>
      <div className="mt-2 flex gap-3 text-[11px]">
        <Legend color="#3a5a8c" label="Deep" />
        <Legend color="#a08540" label="REM" />
        <Legend color="#5a6275" label="Light" />
        <Legend color="#9b2a3f" label="Wake" />
      </div>
    </div>
  );
}

function Legend({ color, label }: { color: string; label: string }) {
  return (
    <span className="inline-flex items-center gap-1.5 text-obsidian-200">
      <span className="h-2.5 w-2.5 rounded-sm" style={{ background: color }} /> {label}
    </span>
  );
}

function TrendCard({ title, data, unit }: { title: string; data: number[]; unit: string }) {
  const last = data[data.length - 1];
  return (
    <div className="card p-5">
      <div className="mb-2 text-[10px] uppercase tracking-[0.22em] text-gold-300">{title}</div>
      <div className="stat-num text-3xl text-cream-50">{last}<span className="ml-1 text-xs text-obsidian-200">{unit}</span></div>
      <div className="mt-2"><Sparkline data={data} width={280} height={56} /></div>
    </div>
  );
}

function Driver({ label, value, tone }: { label: string; value: string; tone: "good" | "warn" | "bad" }) {
  const c = tone === "good" ? "text-forge-green" : tone === "warn" ? "text-forge-amber" : "text-forge-ruby";
  return (
    <div className="rounded-md border border-gold-400/10 bg-obsidian-800/40 px-3 py-2">
      <div className="text-[9px] uppercase tracking-wider text-obsidian-200">{label}</div>
      <div className={`mt-0.5 text-sm ${c}`}>{value}</div>
    </div>
  );
}
