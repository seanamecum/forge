import { describe, it, expect } from "vitest";
import { forgeScore, scoreNarrative, scoreChanges, scoreLever } from "../score";
import type { ScoreComponent } from "../types";

const breakdown: ScoreComponent[] = [
  { label: "Sleep", value: 84, weight: 0.18 },
  { label: "Recovery (HRV)", value: 64, weight: 0.18 },
  { label: "Nutrition", value: 71, weight: 0.14 },
  { label: "Hydration", value: 57, weight: 0.08 },
  { label: "Training Load", value: 82, weight: 0.14 },
  { label: "Activity (Steps)", value: 64, weight: 0.08 },
  { label: "Stress", value: 73, weight: 0.1 },
  { label: "Injury Status", value: 72, weight: 0.1 },
];

describe("forge score engine", () => {
  it("equals the weighted breakdown (transparent)", () => {
    expect(forgeScore(breakdown)).toBe(72);
  });

  it("narrative names the weakest and strongest", () => {
    const n = scoreNarrative(breakdown);
    expect(n.startsWith("Held back by")).toBe(true);
    expect(n).toContain("Lifted by");
    expect(n).toContain("Hydration"); // the lowest component
  });

  it("lever targets the most recoverable points", () => {
    const l = scoreLever(breakdown);
    expect(l).toContain("biggest lever");
    // (100-64)*0.18 = 6.48 is the max => Recovery (HRV)
    expect(l).toContain("Recovery (HRV)");
  });

  it("changes react to day-over-day trend movement", () => {
    const changes = scoreChanges(breakdown, { recovery: [70, 76], sleep: [7.0, 7.4] });
    expect(changes.some((c) => c.positive)).toBe(true);
    expect(changes.some((c) => c.text.includes("Recovery improved"))).toBe(true);
  });
});
