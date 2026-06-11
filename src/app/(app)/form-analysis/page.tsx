"use client";

import { useState } from "react";
import { SectionTitle } from "@/components/ui/SectionTitle";

const LIFTS = ["Squat", "Bench Press", "Deadlift"];

const ANALYSES: Record<string, {
  score: number;
  good: string[];
  bad: string[];
  fixes: string[];
}> = {
  Squat: {
    score: 87,
    good: ["Depth at parallel ✓", "Bar over mid-foot ✓", "Heels stayed planted ✓", "Brace held to lockout ✓"],
    bad: ["Slight right-knee valgus at the bottom (~6°)", "Hips rise marginally before chest on rep 3"],
    fixes: [
      "Cue: 'spread the floor' — engage glute med through the ascent",
      "Add 2× banded clamshells before main sets to pre-activate",
      "If knee cave persists at heavier weights, drop one notch and reset bracing pattern",
    ],
  },
  "Bench Press": {
    score: 81,
    good: ["Bar path stacked over shoulders at lockout ✓", "Pause clean at chest ✓", "Feet drove through the floor ✓"],
    bad: ["Elbows flared ~75° on rep 4 (target 60°)", "Right scapula loses retraction near lockout"],
    fixes: [
      "Cue: 'tear the bar apart' to lock the lats",
      "Tuck elbows by half — pressing into the wrong line is your shoulder's #1 risk",
      "Set up: drag scaps down hard before the unrack",
    ],
  },
  Deadlift: {
    score: 92,
    good: ["Bar over mid-foot ✓", "Lat tension visible from setup ✓", "Lockout vertical, no hitching ✓"],
    bad: ["Slight T-spine round on top set (acceptable)"],
    fixes: [
      "Last set: hold the brace one breath longer at the floor",
      "Optional: add 2× 5 paused (1s) deadlifts at 70% for postural reinforcement",
    ],
  },
};

export default function FormAnalysisPage() {
  const [lift, setLift] = useState("Squat");
  const [analyzed, setAnalyzed] = useState(false);
  const [thinking, setThinking] = useState(false);
  const a = ANALYSES[lift];

  function analyze() {
    setAnalyzed(false);
    setThinking(true);
    setTimeout(() => {
      setThinking(false);
      setAnalyzed(true);
    }, 1500);
  }

  return (
    <div className="space-y-6">
      <SectionTitle
        eyebrow="Train · Vision"
        title="AI Form Analysis"
        subtitle="Upload or record a lift. Get a form score, mistakes, corrections, and coaching notes."
      />

      <div className="grid gap-6 lg:grid-cols-2">
        <div className="card p-6">
          <div className="text-[10px] uppercase tracking-[0.22em] text-gold-300">Pick a lift</div>
          <div className="mt-3 flex flex-wrap gap-1.5">
            {LIFTS.map((l) => (
              <button
                key={l}
                onClick={() => {
                  setLift(l);
                  setAnalyzed(false);
                }}
                className={`rounded-full border px-3 py-1.5 text-[12px] ${
                  lift === l
                    ? "border-gold-400/50 bg-gold-400/10 text-gold-200"
                    : "border-gold-400/10 text-cream-200 hover:border-gold-400/30"
                }`}
              >
                {l}
              </button>
            ))}
          </div>

          <div className="mt-6 rounded-lg border border-dashed border-gold-400/25 bg-obsidian-800/40 p-8 text-center">
            <div className="text-3xl text-gold-300/70">▶</div>
            <div className="display mt-2 text-lg text-cream-50">Drop video or record</div>
            <div className="mt-1 text-[12px] text-obsidian-200">Side view recommended · 2–5 reps clean lighting</div>
            <button onClick={analyze} className="btn-gold mt-4">
              {thinking ? "Analyzing pose…" : "Upload sample (demo)"}
            </button>
          </div>
        </div>

        <div className="card p-6">
          {!analyzed && !thinking && (
            <div className="grid h-full place-items-center text-center">
              <div>
                <div className="text-3xl text-gold-300/40">◬</div>
                <div className="display mt-2 text-lg text-cream-50">Awaiting upload</div>
                <div className="mt-1 text-[12px] text-obsidian-200">
                  Pose detection · joint angle analysis · bar path tracking
                </div>
              </div>
            </div>
          )}

          {thinking && (
            <div className="grid h-full place-items-center text-center">
              <div>
                <div className="text-3xl text-gold-300 animate-pulse-gold">◬</div>
                <div className="mt-2 text-[11px] uppercase tracking-[0.22em] text-gold-300">
                  Detecting 33 joints · 240 frames · scoring…
                </div>
              </div>
            </div>
          )}

          {analyzed && a && (
            <div>
              <div className="mb-4 flex items-center justify-between">
                <div>
                  <div className="text-[10px] uppercase tracking-[0.22em] text-gold-300">Form Score</div>
                  <div className="stat-num mt-1 text-5xl text-gold-grad">{a.score}</div>
                </div>
                <span className={`chip ${a.score >= 90 ? "chip-green" : a.score >= 80 ? "chip-gold" : "chip-amber"}`}>
                  {a.score >= 90 ? "Excellent" : a.score >= 80 ? "Strong" : "Needs work"}
                </span>
              </div>

              <Section title="What you did well" tone="green" items={a.good} />
              <Section title="Mistakes" tone="ruby" items={a.bad} />
              <Section title="Corrections" tone="gold" items={a.fixes} />
            </div>
          )}
        </div>
      </div>
    </div>
  );
}

function Section({
  title,
  tone,
  items,
}: {
  title: string;
  tone: "green" | "ruby" | "gold";
  items: string[];
}) {
  const color =
    tone === "green" ? "text-forge-green" : tone === "ruby" ? "text-forge-ruby" : "text-gold-300";
  const sym = tone === "green" ? "✓" : tone === "ruby" ? "×" : "✦";
  return (
    <div className="mt-4">
      <div className={`text-[10px] uppercase tracking-[0.22em] ${color}`}>{title}</div>
      <ul className="mt-2 space-y-1.5 text-sm text-cream-200">
        {items.map((s, i) => (
          <li key={i} className="flex gap-2">
            <span className={color}>{sym}</span>
            <span>{s}</span>
          </li>
        ))}
      </ul>
    </div>
  );
}
