// @forge/core — fuel target engine.
// Derives calories / protein / carbs / fat / water from body, activity, and goal,
// so nutrition reflects the actual user. Calibrated identically to the native
// engine (200 lb, very active, building muscle => 3,200 / 200 / 120 / 95).

import type { ActivityLevel, BodyProfile, FuelTargets, Goal } from "./types";

export function fuelTargets(p: BodyProfile): FuelTargets {
  const calories = roundStep(p.weightLb * calPerLb(p.activity) * goalFactor(p.goal), 50);
  const protein = roundStep(p.weightLb * proteinPerLb(p.goal), 5);
  const fat = roundStep((calories * 0.27) / 9, 5);
  const carbs = Math.max(0, roundStep((calories - protein * 4 - fat * 9) / 4, 5));
  const waterOz = roundStep(p.weightLb * 0.6, 5);
  return { calories, protein, carbs, fat, waterOz };
}

function calPerLb(a: ActivityLevel): number {
  switch (a) {
    case "sedentary":
      return 11;
    case "light":
      return 12.5;
    case "moderate":
      return 13.5;
    case "active":
      return 14.5;
    case "very_active":
      return 15;
  }
}

function goalFactor(g: Goal): number {
  switch (g) {
    case "lose_fat":
      return 0.8;
    case "build_muscle":
      return 1.07;
    case "strength":
      return 1.05;
    case "athletic":
      return 1.02;
    case "endurance":
    case "health":
    case "injury_recovery":
      return 1.0;
  }
}

function proteinPerLb(g: Goal): number {
  switch (g) {
    case "build_muscle":
    case "strength":
      return 1.0;
    case "lose_fat":
      return 1.1;
    case "athletic":
    case "injury_recovery":
      return 0.9;
    case "endurance":
      return 0.75;
    case "health":
      return 0.7;
  }
}

function roundStep(value: number, step: number): number {
  return Math.round(value / step) * step;
}
