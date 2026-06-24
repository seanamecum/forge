// @forge/core — injury rehab engine.
// Turns an injury into a concrete daily PT plan and a return-to-sport readiness
// score. Pure, synchronous, unit-tested — ported from the native engine so injury
// work is prescribed, not just tracked.

import type { RehabExercise, RehabPlan, ReturnReadiness } from "./types";

export interface RehabInjury {
  area: string; // "shoulder"
  name: string;
  phase: string; // acute | subacute | rehab | return-to-sport | resolved
  painToday: number; // 0..10
}

export interface RehabPTExercise {
  id: string;
  name: string;
  area: string;
  sets: string;
  notes: string;
}

export interface RehabProtocol {
  area: string;
  recommendedPT: string[]; // PTExercise ids
}

const PHASE_ORDER = ["acute", "subacute", "rehab", "return-to-sport", "resolved"];

/** Today's PT — from the matching protocol, falling back to the library by area. */
export function rehabPlan(
  injury: RehabInjury,
  library: RehabPTExercise[],
  protocols: RehabProtocol[]
): RehabPlan {
  const proto = protocols.find((p) => p.area.toLowerCase().includes(injury.area.toLowerCase()));
  let picks: RehabPTExercise[] = [];
  if (proto) {
    picks = proto.recommendedPT
      .map((id) => library.find((e) => e.id === id))
      .filter((e): e is RehabPTExercise => Boolean(e));
  }
  if (picks.length === 0) {
    picks = library.filter((e) => e.area.toLowerCase().includes(injury.area.toLowerCase()));
  }
  if (picks.length === 0) picks = library.slice(0, 3);

  const exercises: RehabExercise[] = picks
    .slice(0, 4)
    .map((e) => ({ name: e.name, prescription: e.sets, note: e.notes }));
  const minutes = Math.max(10, roundTo5(exercises.length * 4 + 5));
  const area = injury.area.toLowerCase();
  const anchor = exercises[0]?.name ?? "mobility";
  const extra = exercises.length - 1;
  const summary =
    extra > 0
      ? `${minutes} min ${area} PT — ${anchor} +${extra} more`
      : `${minutes} min ${area} PT — ${anchor}`;

  return {
    title: `${capitalize(injury.area)} Rehab · ${phaseLabel(injury.phase)}`,
    focus: focusText(injury.phase),
    exercises,
    estMinutes: minutes,
    summary,
  };
}

/** Return-to-sport readiness — phase progress (60%) blended with current pain (40%). */
export function returnReadiness(injury: RehabInjury): ReturnReadiness {
  const idx = Math.max(0, PHASE_ORDER.indexOf(injury.phase));
  const phaseProgress = idx / (PHASE_ORDER.length - 1);
  const painScore = Math.max(0, 10 - injury.painToday) / 10;
  const percent = clamp(Math.round((phaseProgress * 0.6 + painScore * 0.4) * 100), 0, 100);

  let band: string;
  if (percent >= 90) band = "Cleared";
  else if (percent >= 70) band = "Nearly there";
  else if (percent >= 45) band = "On track";
  else band = "Early";

  return {
    percent,
    band,
    phaseLabel: phaseLabel(injury.phase),
    nextMilestone: nextMilestone(injury.phase),
    etaText: etaText(injury.phase),
  };
}

// --- helpers ---------------------------------------------------------------
function focusText(phase: string): string {
  switch (phase) {
    case "acute":
      return "Calm it down — reduce reactive pain";
    case "subacute":
      return "Restore motion and control";
    case "rehab":
      return "Progressive reload with control";
    case "return-to-sport":
      return "Full output + sport drills";
    case "resolved":
      return "Maintain — keep it resilient";
    default:
      return "Rebuild capacity";
  }
}

function nextMilestone(phase: string): string {
  switch (phase) {
    case "acute":
      return "Pain ≤ 3/10 in daily life";
    case "subacute":
      return "Restore full pain-free range";
    case "rehab":
      return "Reload to 80% strength, pain-free";
    case "return-to-sport":
      return "Full-intensity, no flare next day";
    default:
      return "Maintain";
  }
}

function etaText(phase: string): string {
  switch (phase) {
    case "acute":
      return "4+ weeks out";
    case "subacute":
      return "~3–4 weeks out";
    case "rehab":
      return "~2–3 weeks out";
    case "return-to-sport":
      return "~1 week out";
    default:
      return "Cleared for return";
  }
}

function phaseLabel(phase: string): string {
  switch (phase) {
    case "acute":
      return "Acute";
    case "subacute":
      return "Sub-acute";
    case "rehab":
      return "Rehab";
    case "return-to-sport":
      return "Return-to-Sport";
    case "resolved":
      return "Resolved";
    default:
      return capitalize(phase);
  }
}

function capitalize(s: string): string {
  return s.length ? s[0].toUpperCase() + s.slice(1) : s;
}
function roundTo5(n: number): number {
  return Math.round(n / 5) * 5;
}
function clamp(n: number, lo: number, hi: number): number {
  return Math.max(lo, Math.min(hi, n));
}
