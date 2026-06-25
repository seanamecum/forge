// @forge/core — nutrition guidance engine.
// Turns "here are your macros" into "here's what to eat next" — a headline,
// actionable items (protein gap, deficiencies, hydration), and a concrete food
// pick that fits the remaining calorie budget. Pure, unit-tested.

import type { Tone } from "./types";

export interface NutritionFood {
  name: string;
  calories: number;
  protein: number;
}

export interface NutritionDeficiency {
  nutrient: string;
  pct: number; // % of target
}

export interface NutritionInput {
  caloriesRemaining: number;
  proteinRemaining: number;
  hydrationPct: number;
  deficiencies: NutritionDeficiency[];
}

export interface NutritionAction {
  text: string;
  tone: Tone;
}

export interface NutritionAdvice {
  headline: string;
  actions: NutritionAction[];
  pick: { name: string; detail: string } | null;
}

export function nutritionGuidance(input: NutritionInput, foods: NutritionFood[]): NutritionAdvice {
  const { caloriesRemaining, proteinRemaining, hydrationPct, deficiencies } = input;

  let headline: string;
  if (proteinRemaining >= 20) {
    headline = `Close your protein gap — ${proteinRemaining}g to go with ${grouped(caloriesRemaining)} kcal of room.`;
  } else if (caloriesRemaining >= 200) {
    headline = `Protein's on track — ${grouped(caloriesRemaining)} kcal of room left today.`;
  } else {
    headline = "You're dialed in — macros are covered for today.";
  }

  const actions: NutritionAction[] = [];
  if (proteinRemaining >= 20) {
    actions.push({ text: `Add ${proteinRemaining}g protein — a lean source closes it.`, tone: "amber" });
  }
  if (hydrationPct < 80) {
    actions.push({
      text: `Hydration ${hydrationPct}% — drink water now, add electrolytes.`,
      tone: hydrationPct < 60 ? "amber" : "gold",
    });
  }
  for (const d of [...deficiencies].sort((a, b) => a.pct - b.pct).slice(0, 3)) {
    if (d.pct < 80) {
      actions.push({ text: `${d.nutrient} at ${d.pct}% of target — top it up.`, tone: d.pct < 50 ? "ruby" : "amber" });
    }
  }
  if (actions.length === 0) {
    actions.push({ text: "Everything's on target — keep the streak.", tone: "green" });
  }

  return { headline, actions, pick: bestPick(caloriesRemaining, proteinRemaining, foods) };
}

/** The most protein-dense food that fits the remaining calorie budget. */
function bestPick(
  caloriesRemaining: number,
  proteinRemaining: number,
  foods: NutritionFood[]
): { name: string; detail: string } | null {
  if (proteinRemaining < 10) return null;
  const fits = foods.filter((f) => f.protein > 0 && f.calories <= Math.max(150, caloriesRemaining));
  const pool = fits.length ? fits : foods.filter((f) => f.protein > 0);
  if (pool.length === 0) return null;
  const best = [...pool].sort((a, b) => b.protein / b.calories - a.protein / a.calories)[0];
  return { name: best.name, detail: `${Math.round(best.protein)}g protein · ${best.calories} kcal` };
}

function grouped(n: number): string {
  return Math.round(n).toLocaleString("en-US");
}
