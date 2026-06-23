// @forge/core — Forge Score engine.
// The score is the weighted blend of its components (single source of truth), with
// a plain-language narrative, signed day-over-day changes, and the biggest lever.

import type { ScoreComponent, ScoreChange } from "./types";

export interface ScoreTrends {
  recovery?: number[];
  sleep?: number[];
}

/** 0..100 — the weighted blend. Always equals the breakdown (transparent). */
export function forgeScore(breakdown: ScoreComponent[]): number {
  return Math.round(breakdown.reduce((t, c) => t + c.value * c.weight, 0));
}

/** "Held back by X. Lifted by Y." */
export function scoreNarrative(breakdown: ScoreComponent[]): string {
  if (breakdown.length === 0) return "";
  const sorted = [...breakdown].sort((a, b) => a.value - b.value);
  const lowest = sorted[0];
  const second = sorted[1];
  const highest = sorted[sorted.length - 1];
  const drags =
    second && second.value < 75
      ? `${lowest.label} (${lowest.value}) and ${second.label} (${second.value})`
      : `${lowest.label} (${lowest.value})`;
  return `Held back by ${drags}. Lifted by ${highest.label} (${highest.value}).`;
}

/** Signed drivers — trend movement plus today's drags / strongest component. */
export function scoreChanges(breakdown: ScoreComponent[], trends: ScoreTrends = {}): ScoreChange[] {
  const out: ScoreChange[] = [];
  const move = (series?: number[]) =>
    series && series.length >= 2 ? series[series.length - 1] - series[series.length - 2] : undefined;

  const r = move(trends.recovery);
  if (r !== undefined) {
    if (r >= 1.5) out.push({ text: "Recovery improved", positive: true });
    else if (r <= -1.5) out.push({ text: "Recovery dipped", positive: false });
  }
  const s = move(trends.sleep);
  if (s !== undefined) {
    if (s >= 0.2) out.push({ text: "Better sleep last night", positive: true });
    else if (s <= -0.2) out.push({ text: "Shorter sleep last night", positive: false });
  }

  for (const c of [...breakdown].sort((a, b) => a.value - b.value).slice(0, 2)) {
    if (c.value < 65) out.push({ text: `${c.label} low (${c.value})`, positive: false });
  }
  if (!out.some((c) => c.positive)) {
    const top = [...breakdown].sort((a, b) => b.value - a.value)[0];
    if (top) out.push({ text: `${top.label} strong (${top.value})`, positive: true });
  }
  return out;
}

/** The single component with the most recoverable points = max (100 - value) * weight. */
export function scoreLever(breakdown: ScoreComponent[]): string {
  if (breakdown.length === 0) return "";
  const c = [...breakdown].sort(
    (a, b) => (100 - b.value) * b.weight - (100 - a.value) * a.weight
  )[0];
  const gain = Math.round((100 - c.value) * c.weight);
  if (gain <= 0) return "Every input is dialed — hold the line.";
  return `${c.label} is your biggest lever — up to +${gain} points on the table.`;
}
