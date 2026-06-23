import { describe, it, expect } from "vitest";
import { fuelTargets } from "../targets";

describe("fuel target engine", () => {
  it("reproduces the calibrated demo athlete", () => {
    const t = fuelTargets({ weightLb: 200, activity: "very_active", goal: "build_muscle" });
    expect(t.calories).toBe(3200);
    expect(t.protein).toBe(200);
    expect(t.waterOz).toBe(120);
    expect(t.fat).toBe(95);
  });

  it("scales with bodyweight", () => {
    const small = fuelTargets({ weightLb: 140, activity: "very_active", goal: "build_muscle" });
    const big = fuelTargets({ weightLb: 240, activity: "very_active", goal: "build_muscle" });
    expect(small.calories).toBeLessThan(big.calories);
    expect(small.protein).toBeLessThan(big.protein);
  });

  it("goal shifts calories (cut < bulk)", () => {
    const cut = fuelTargets({ weightLb: 200, activity: "very_active", goal: "lose_fat" });
    const bulk = fuelTargets({ weightLb: 200, activity: "very_active", goal: "build_muscle" });
    expect(cut.calories).toBeLessThan(bulk.calories);
  });

  it("macros reconcile to calories", () => {
    const t = fuelTargets({ weightLb: 200, activity: "very_active", goal: "build_muscle" });
    const macroCalories = t.protein * 4 + t.carbs * 4 + t.fat * 9;
    expect(Math.abs(macroCalories - t.calories)).toBeLessThanOrEqual(60);
  });
});
