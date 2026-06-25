import { describe, it, expect } from "vitest";
import { nutritionGuidance, type NutritionFood } from "../nutrition";

const foods: NutritionFood[] = [
  { name: "Tuna, canned in water", calories: 130, protein: 30 },
  { name: "Chicken Breast", calories: 330, protein: 62 },
  { name: "Whey Isolate", calories: 120, protein: 25 },
  { name: "Olive Oil", calories: 120, protein: 0 },
  { name: "Brown Rice", calories: 218, protein: 5 },
];

describe("nutrition guidance engine", () => {
  it("answers what to do next when protein is short", () => {
    const a = nutritionGuidance(
      { caloriesRemaining: 940, proteinRemaining: 78, hydrationPct: 57, deficiencies: [] },
      foods
    );
    expect(a.headline).toContain("78g");
    expect(a.actions.some((x) => x.text.includes("78g protein"))).toBe(true);
    expect(a.actions.some((x) => x.text.toLowerCase().includes("hydration"))).toBe(true);
  });

  it("picks the most protein-dense food that fits the budget", () => {
    const a = nutritionGuidance(
      { caloriesRemaining: 940, proteinRemaining: 78, hydrationPct: 100, deficiencies: [] },
      foods
    );
    // Tuna (0.231 g/kcal) beats whey (0.208) and chicken (0.188)
    expect(a.pick?.name).toBe("Tuna, canned in water");
    expect(a.pick?.detail).toContain("30g protein");
  });

  it("surfaces the worst deficiencies first", () => {
    const a = nutritionGuidance(
      {
        caloriesRemaining: 100,
        proteinRemaining: 0,
        hydrationPct: 100,
        deficiencies: [
          { nutrient: "Magnesium", pct: 44 },
          { nutrient: "Omega-3", pct: 28 },
          { nutrient: "Vitamin D", pct: 48 },
        ],
      },
      foods
    );
    expect(a.actions[0].text).toContain("Omega-3"); // lowest pct first
    expect(a.actions[0].tone).toBe("ruby");
  });

  it("no food pick when protein is already met", () => {
    const a = nutritionGuidance(
      { caloriesRemaining: 300, proteinRemaining: 0, hydrationPct: 100, deficiencies: [] },
      foods
    );
    expect(a.pick).toBeNull();
  });
});
