// @forge/core — Daily Directive engine.
// Synthesizes every signal into one prescribed plan + the reasoning. Pure logic,
// ported 1:1 from the verified native engine so web and mobile agree exactly.

import type { Directive, DirectiveAction, DirectiveActionKind, Tone } from "./types";

export interface DirectiveInput {
  recovery: number; // 0..100
  soreness?: number; // 0..10 (morning check-in)
  sleepDebtHours: number;
  calorieTarget: number;
  proteinTarget: number;
  proteinRemaining: number;
  hydrationPct: number;
  injuryName?: string;
  injuryPain?: number;
  injuryRiskBand?: string;
  injuryRiskPercent?: number;
  rehabSummary?: string;
  keySupplement?: string;
  sleepTargetHours: number;
  workoutName: string;
}

const KIND_META: Record<DirectiveActionKind, { label: string; icon: string }> = {
  train: { label: "Train", icon: "🏋️" },
  fuel: { label: "Fuel", icon: "🔥" },
  protein: { label: "Protein", icon: "🍗" },
  mobility: { label: "Mobility", icon: "🧘" },
  supplement: { label: "Supplement", icon: "💊" },
  sleep: { label: "Sleep", icon: "🌙" },
};

export function makeDirective(input: DirectiveInput): Directive {
  const {
    recovery,
    soreness = 0,
    sleepDebtHours,
    calorieTarget,
    proteinTarget,
    proteinRemaining,
    hydrationPct,
    injuryName,
    injuryPain,
    injuryRiskBand,
    injuryRiskPercent = 0,
    rehabSummary,
    keySupplement,
    sleepTargetHours,
    workoutName,
  } = input;

  // 1. Intensity follows recovery — high soreness overrides.
  let headline: string;
  let tone: Tone;
  if (recovery >= 80) {
    headline = "Push hard today.";
    tone = "green";
  } else if (recovery >= 60) {
    headline = "Train at moderate intensity.";
    tone = "gold";
  } else {
    headline = "Pull back and recover today.";
    tone = "ruby";
  }
  const verySore = soreness >= 7;
  if (verySore) {
    headline = "Pull back and recover today.";
    tone = "ruby";
  }

  // 2. Rationale stitches the live signals into one sentence.
  const parts = [`Recovery is ${recovery}%`];
  if (soreness >= 5) parts.push(`you logged soreness ${soreness}/10`);
  if (proteinRemaining > 0) parts.push(`protein is ${proteinRemaining}g behind`);
  if (hydrationPct < 80) parts.push(`hydration is at ${hydrationPct}%`);
  if (injuryRiskPercent >= 20 && injuryName) {
    parts.push(`${injuryName.toLowerCase()} risk is ${(injuryRiskBand ?? "elevated").toLowerCase()}`);
  }
  const rationale = sentence(parts);

  // 3. The ONE priority action, most-urgent-first.
  let priority: string;
  if (verySore) {
    priority = `Soreness is ${soreness}/10 — swap lifting for mobility and easy Zone 2 today.`;
  } else if (injuryPain !== undefined && injuryPain >= 3 && injuryName) {
    priority = `Complete ${injuryName.toLowerCase()} PT before lifting.`;
  } else if (recovery < 60) {
    priority = "Skip the top set — today is about recovery, not records.";
  } else if (sleepDebtHours >= 3) {
    priority = `Lights out by 22:30 — you're carrying ${hoursLabel(sleepDebtHours)} of sleep debt.`;
  } else if (proteinRemaining >= 40) {
    priority = `Front-load protein — ${proteinRemaining}g to go, start at lunch.`;
  } else if (hydrationPct < 70) {
    priority = `Hydrate before training — you're at ${hydrationPct}% of target.`;
  } else {
    priority = "You're cleared to progress — chase the top set.";
  }

  // 4. The prescribed plan.
  const actions: DirectiveAction[] = [];
  const trainTone: Tone = verySore ? "amber" : recovery >= 80 ? "green" : recovery < 60 ? "amber" : "gold";
  actions.push(action("train", workoutName, trainTone));
  if (calorieTarget > 0) actions.push(action("fuel", `${grouped(calorieTarget)} kcal`, "gold"));
  if (proteinTarget > 0) {
    const v = proteinRemaining > 0 ? `${proteinTarget} g · ${proteinRemaining} g to go` : `${proteinTarget} g · on track`;
    actions.push(action("protein", v, proteinRemaining >= 40 ? "amber" : "green"));
  }
  if (rehabSummary) {
    actions.push(action("mobility", rehabSummary, injuryName ? "amber" : "royal"));
  } else if (injuryName) {
    actions.push(action("mobility", `15 min ${injuryName.toLowerCase()} PT`, "amber"));
  }
  if (keySupplement) actions.push(action("supplement", keySupplement, "gold"));
  if (sleepTargetHours > 0) actions.push(action("sleep", `${clock(sleepTargetHours)} target`, "royal"));

  return { headline, rationale, priority, workoutName, tone, actions };
}

// --- helpers ---------------------------------------------------------------
function action(kind: DirectiveActionKind, value: string, tone: Tone): DirectiveAction {
  return { kind, value, tone, label: KIND_META[kind].label, icon: KIND_META[kind].icon };
}

function sentence(parts: string[]): string {
  if (parts.length === 0) return "";
  if (parts.length === 1) return parts[0] + ".";
  if (parts.length === 2) return parts[0] + " and " + parts[1] + ".";
  return parts.slice(0, -1).join(", ") + ", and " + parts[parts.length - 1] + ".";
}

function hoursLabel(h: number): string {
  const whole = Math.floor(h);
  const mins = Math.floor((h - whole) * 60);
  return mins > 0 ? `${whole}h ${mins}m` : `${whole}h`;
}

function clock(h: number): string {
  const whole = Math.floor(h);
  const mins = Math.round((h - whole) * 60);
  return mins > 0 ? `${whole}h ${mins}m` : `${whole}h`;
}

function grouped(n: number): string {
  return Math.round(n).toLocaleString("en-US");
}
