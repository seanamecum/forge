// @forge/core — cross-module intelligence.
// Turns isolated signals into connected explanations: a recovery attribution and
// causal chains (sleep -> recovery -> training -> injury -> fuel). Ported from the
// verified native engine. This is what makes Forge an OS, not twelve trackers.

import type { ForgeInsight, RecoveryDriver } from "./types";

export interface RecoveryDriverInput {
  recovery: number;
  sleepHours: number;
  sleepReference: number;
  hrv: number;
  hrvBaseline: number;
  strainYesterday: number;
  strainAvg: number;
  restingHr: number;
  restingHrBaseline: number;
  magnesiumPct: number;
  magnesiumDaysLow: number;
}

/** Decomposes "Recovery is X" into its causes, ordered by magnitude. */
export function recoveryDrivers(i: RecoveryDriverInput): RecoveryDriver[] {
  const out: RecoveryDriver[] = [];

  const sleepDelta = i.sleepHours - i.sleepReference;
  if (sleepDelta <= -0.2) {
    out.push({
      factor: "Sleep",
      detail: `${i.sleepHours.toFixed(1)}h — ${(-sleepDelta).toFixed(1)}h under your ${i.sleepReference.toFixed(1)}h target`,
      positive: false,
      weight: Math.round(-sleepDelta * 12),
    });
  } else if (sleepDelta >= 0.3) {
    out.push({
      factor: "Sleep",
      detail: `${i.sleepHours.toFixed(1)}h — at your ${i.sleepReference.toFixed(1)}h target`,
      positive: true,
      weight: 4,
    });
  }

  const hrvDelta = i.hrv - i.hrvBaseline;
  if (Math.abs(hrvDelta) >= 2) {
    out.push({
      factor: "HRV",
      detail: `${i.hrv}ms — ${signed(hrvDelta)}ms vs baseline (${signed(pct(hrvDelta, i.hrvBaseline))}%)`,
      positive: hrvDelta >= 0,
      weight: Math.abs(hrvDelta) * 2,
    });
  }

  const strainDelta = i.strainYesterday - i.strainAvg;
  if (Math.abs(strainDelta) >= 1.0) {
    out.push({
      factor: "Training strain",
      detail: `${i.strainYesterday.toFixed(1)} yesterday — ${signed(Math.round((strainDelta / Math.max(1, i.strainAvg)) * 100))}% vs your average`,
      positive: strainDelta <= 0,
      weight: Math.round(Math.abs(strainDelta) * 4),
    });
  }

  const rhrDelta = i.restingHr - i.restingHrBaseline;
  if (rhrDelta >= 3) {
    out.push({
      factor: "Resting HR",
      detail: `${i.restingHr}bpm — ${signed(rhrDelta)} above baseline`,
      positive: false,
      weight: rhrDelta,
    });
  }

  if (i.magnesiumPct < 70 && i.magnesiumDaysLow >= 3) {
    out.push({
      factor: "Magnesium",
      detail: `${i.magnesiumPct}% of target for ${i.magnesiumDaysLow} days — degrades deep sleep & HRV`,
      positive: false,
      weight: Math.floor((70 - i.magnesiumPct) / 4) + i.magnesiumDaysLow,
    });
  }

  return out.sort((a, b) => b.weight - a.weight);
}

export interface CrossModuleInput {
  recovery: number;
  sleepDebtHours: number;
  hrv: number;
  hrvBaseline: number;
  proteinRemaining: number;
  hydrationPct: number;
  injuryName?: string;
  injuryPhase?: string;
  injuryRiskPercent: number;
  injuryRiskBand: string;
  magnesiumPct: number;
  magnesiumDaysLow: number;
}

/** The causal chains linking the modules, most-severe first. */
export function crossModule(i: CrossModuleInput): ForgeInsight[] {
  const out: ForgeInsight[] = [];
  const hrvDelta = i.hrv - i.hrvBaseline;

  if (i.sleepDebtHours >= 1.5) {
    out.push({
      icon: "🌙",
      chain: `Sleep debt ${hoursLabel(i.sleepDebtHours)} → HRV ${signed(pct(hrvDelta, i.hrvBaseline))}% → recovery held at ${i.recovery}`,
      action: "Bank 8h tonight and tomorrow's training ceiling rises.",
      tone: "royal",
      severity: 80 + Math.floor(i.sleepDebtHours),
    });
  }
  if (i.magnesiumPct < 70 && i.magnesiumDaysLow >= 3) {
    out.push({
      icon: "💊",
      chain: `Magnesium ${i.magnesiumPct}% × ${i.magnesiumDaysLow}d → shallower deep sleep → suppressed HRV`,
      action: "400mg glycinate before bed — the upstream fix for sleep + recovery.",
      tone: "gold",
      severity: 68 + i.magnesiumDaysLow,
    });
  }
  if (i.injuryName && i.injuryRiskPercent >= 18) {
    const phase = i.injuryPhase ? ` (${i.injuryPhase.toLowerCase()})` : "";
    out.push({
      icon: "⚠️",
      chain: `Volume up while the ${i.injuryName.toLowerCase()} is mid-rehab${phase} → injury risk ${i.injuryRiskPercent}% (${i.injuryRiskBand.toLowerCase()})`,
      action: "Hold weekly volume flat and cap RPE 8.5 until it clears.",
      tone: "amber",
      severity: 55 + i.injuryRiskPercent,
    });
  }
  if (i.hydrationPct < 75) {
    out.push({
      icon: "💧",
      chain: `Hydration ${i.hydrationPct}% → blunted recovery & lower next-session output`,
      action: "Add electrolytes to your next two bottles.",
      tone: i.hydrationPct < 60 ? "amber" : "gold",
      severity: 35 + (75 - i.hydrationPct),
    });
  }
  if (i.proteinRemaining >= 30) {
    out.push({
      icon: "🍗",
      chain: `Protein ${i.proteinRemaining}g short → muscle left on the table this bulk`,
      action: "Protein-first dinner plus a casein bowl closes it.",
      tone: "gold",
      severity: 30 + Math.floor(i.proteinRemaining / 4),
    });
  }

  return out.sort((a, b) => b.severity - a.severity);
}

// --- helpers ---------------------------------------------------------------
function signed(n: number): string {
  return n >= 0 ? `+${n}` : `${n}`;
}
function pct(delta: number, base: number): number {
  return base === 0 ? 0 : Math.round((delta / base) * 100);
}
function hoursLabel(h: number): string {
  const whole = Math.floor(h);
  const mins = Math.floor((h - whole) * 60);
  return mins > 0 ? `${whole}h ${mins}m` : `${whole}h`;
}
