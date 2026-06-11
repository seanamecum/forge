"use client";

import { useState } from "react";
import { SectionTitle } from "@/components/ui/SectionTitle";
import { today, injuries } from "@/lib/mock/user";

const GOALS = [
  { id: "strength", name: "Get Stronger" },
  { id: "size", name: "Build Muscle" },
  { id: "fat-loss", name: "Lose Fat" },
  { id: "endurance", name: "Endurance" },
  { id: "athletic", name: "Athletic Performance" },
];

const DURATIONS = ["30 min", "45 min", "60 min", "75 min", "90 min"];

const EQUIPMENT = ["Full Gym", "Home Gym", "Dumbbells", "Bands", "Bodyweight"];

export default function GeneratePage() {
  const [goal, setGoal] = useState("athletic");
  const [duration, setDuration] = useState("60 min");
  const [equipment, setEquipment] = useState("Full Gym");
  const [generated, setGenerated] = useState<null | typeof SAMPLE>(null);
  const [thinking, setThinking] = useState(false);

  function generate() {
    setThinking(true);
    setTimeout(() => {
      setGenerated(SAMPLE);
      setThinking(false);
    }, 1100);
  }

  return (
    <div className="space-y-6">
      <SectionTitle
        eyebrow="Train · Generator"
        title="AI Workout Generator"
        subtitle="Forge builds your session from your goal, recovery, time available, equipment, injuries, training history, and experience level."
      />

      <div className="grid gap-6 lg:grid-cols-[380px,1fr]">
        <div className="space-y-4">
          <div className="card p-5">
            <div className="text-[10px] uppercase tracking-[0.22em] text-gold-300">Goal</div>
            <div className="mt-3 flex flex-wrap gap-1.5">
              {GOALS.map((g) => (
                <Pill key={g.id} on={goal === g.id} onClick={() => setGoal(g.id)} label={g.name} />
              ))}
            </div>
          </div>

          <div className="card p-5">
            <div className="text-[10px] uppercase tracking-[0.22em] text-gold-300">Duration</div>
            <div className="mt-3 flex flex-wrap gap-1.5">
              {DURATIONS.map((d) => (
                <Pill key={d} on={duration === d} onClick={() => setDuration(d)} label={d} />
              ))}
            </div>
          </div>

          <div className="card p-5">
            <div className="text-[10px] uppercase tracking-[0.22em] text-gold-300">Equipment</div>
            <div className="mt-3 flex flex-wrap gap-1.5">
              {EQUIPMENT.map((e) => (
                <Pill key={e} on={equipment === e} onClick={() => setEquipment(e)} label={e} />
              ))}
            </div>
          </div>

          <div className="card p-5">
            <div className="text-[10px] uppercase tracking-[0.22em] text-gold-300">Live context</div>
            <div className="mt-3 space-y-1.5 text-xs">
              <Row label="Recovery" value={`${today.recovery} / moderate`} />
              <Row label="HRV" value={`${today.hrv} ms`} />
              <Row label="Sleep" value={`${today.sleepHours} h`} />
              <Row label="Injury" value={injuries[0]?.name ?? "None"} />
              <Row label="Equipment access" value={equipment} />
            </div>
            <div className="mt-3 rounded-md border border-forge-amber/30 bg-forge-amber/5 p-2.5 text-[11px] text-cream-200">
              ⚠ Auto-protective: Forge will avoid overhead pressing and limit shoulder ROM (active rehab).
            </div>
          </div>

          <button onClick={generate} className="btn-gold w-full">
            {thinking ? "Generating…" : "✺ Generate workout"}
          </button>
        </div>

        <div>
          {!generated && !thinking && (
            <div className="card flex h-[480px] items-center justify-center p-10 text-center">
              <div>
                <div className="text-4xl text-gold-300 animate-pulse-gold">✺</div>
                <div className="display mt-3 text-xl text-cream-50">Pick your inputs, then generate.</div>
                <div className="mt-1 text-sm text-obsidian-200">
                  Forge will write the full session — sets, reps, RPE, rest, and why each block is there.
                </div>
              </div>
            </div>
          )}

          {thinking && (
            <div className="card flex h-[480px] items-center justify-center">
              <div className="text-center">
                <div className="text-3xl text-gold-300 animate-pulse-gold">✦</div>
                <div className="mt-2 text-[11px] uppercase tracking-[0.22em] text-gold-300">
                  Reading recovery · injury filters · history…
                </div>
              </div>
            </div>
          )}

          {generated && (
            <div className="card p-6">
              <div className="mb-2 flex flex-wrap items-baseline justify-between gap-2">
                <h3 className="display text-2xl text-cream-50">{generated.name}</h3>
                <div className="flex gap-2">
                  <span className="chip chip-gold">{duration}</span>
                  <span className="chip">{equipment}</span>
                </div>
              </div>
              <div className="rounded-md border border-gold-400/15 bg-gold-400/5 p-3 text-[13px] text-cream-200">
                <span className="text-gold-200">Why this session:</span> {generated.rationale}
              </div>

              <div className="mt-4 space-y-2">
                {generated.blocks.map((b, i) => (
                  <div key={i} className="rounded-md border border-gold-400/10 bg-obsidian-800/50 p-3">
                    <div className="mb-2 flex items-center justify-between">
                      <div className="text-[11px] uppercase tracking-[0.18em] text-gold-300">
                        {b.label}
                      </div>
                      <span className="text-[11px] text-obsidian-200">{b.note}</span>
                    </div>
                    {b.items.map((it, j) => (
                      <div key={j} className="flex items-baseline justify-between border-t border-gold-400/5 py-1.5 text-sm">
                        <span className="text-cream-100">{it.name}</span>
                        <span className="text-[11px] text-obsidian-200">{it.scheme}</span>
                      </div>
                    ))}
                  </div>
                ))}
              </div>

              <div className="mt-4 flex gap-2">
                <button className="btn-gold">Use this session</button>
                <button className="btn-ghost" onClick={generate}>Regenerate</button>
                <button className="btn-ghost">Save</button>
              </div>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}

function Pill({
  on,
  onClick,
  label,
}: {
  on: boolean;
  onClick: () => void;
  label: string;
}) {
  return (
    <button
      onClick={onClick}
      className={`rounded-full border px-3 py-1.5 text-[12px] ${
        on
          ? "border-gold-400/50 bg-gold-400/10 text-gold-200"
          : "border-gold-400/10 text-cream-200 hover:border-gold-400/30"
      }`}
    >
      {label}
    </button>
  );
}

function Row({ label, value }: { label: string; value: string }) {
  return (
    <div className="flex justify-between border-b border-gold-400/5 pb-1.5">
      <span className="text-obsidian-200">{label}</span>
      <span className="text-cream-100">{value}</span>
    </div>
  );
}

const SAMPLE = {
  name: "Lower — Posterior Chain · Recovery-Adjusted",
  rationale:
    "Recovery 72 (moderate) → cap top sets at RPE 8.5 and pull total volume 12% from your 4-week average. Hip thrusts moved to the start to capture peak output. Heavy bilateral pressing is throttled in this phase given lumbar fatigue. Avoids any shoulder pressing — active rehab.",
  blocks: [
    {
      label: "Warm-up · 8 min",
      note: "Heart rate Z2",
      items: [
        { name: "Bike easy", scheme: "5 min" },
        { name: "Hip 90/90 + leg swings", scheme: "1 round" },
        { name: "Banded glute activation", scheme: "2 × 20" },
      ],
    },
    {
      label: "Main · Strength",
      note: "Rest 2:30",
      items: [
        { name: "Barbell Hip Thrust", scheme: "4 × 6 @ 170 kg · RPE 8" },
        { name: "Romanian Deadlift", scheme: "4 × 8 @ 130 kg · RPE 8" },
      ],
    },
    {
      label: "Accessory",
      note: "Rest 1:30",
      items: [
        { name: "Bulgarian Split Squat", scheme: "3 × 10 ea @ 24 kg DBs" },
        { name: "Leg Press · Quads", scheme: "3 × 12 @ 220 kg" },
      ],
    },
    {
      label: "Conditioning + Core",
      note: "Superset",
      items: [
        { name: "Copenhagen Plank", scheme: "3 × 20s ea" },
        { name: "Pallof Press", scheme: "3 × 12" },
        { name: "Cool-down walk", scheme: "10 min Z1" },
      ],
    },
  ],
};
