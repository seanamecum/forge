import { describe, it, expect } from "vitest";
import { makeDirective, type DirectiveInput } from "../directive";

const base: DirectiveInput = {
  recovery: 78,
  sleepDebtHours: 0,
  calorieTarget: 0,
  proteinTarget: 0,
  proteinRemaining: 0,
  hydrationPct: 100,
  sleepTargetHours: 0,
  workoutName: "Lower — Posterior Chain",
};

describe("directive engine", () => {
  it("high recovery pushes hard", () => {
    expect(makeDirective({ ...base, recovery: 88 }).headline).toBe("Push hard today.");
  });

  it("moderate recovery is moderate", () => {
    expect(makeDirective({ ...base, recovery: 72 }).headline).toBe("Train at moderate intensity.");
  });

  it("low recovery pulls back", () => {
    const d = makeDirective({ ...base, recovery: 45 });
    expect(d.headline).toBe("Pull back and recover today.");
    expect(d.tone).toBe("ruby");
  });

  it("high soreness overrides good recovery", () => {
    const d = makeDirective({ ...base, recovery: 85, soreness: 8 });
    expect(d.headline).toBe("Pull back and recover today.");
    expect(d.priority.toLowerCase()).toContain("mobility");
  });

  it("injury pain is the top priority", () => {
    const d = makeDirective({ ...base, recovery: 82, injuryName: "Knee", injuryPain: 4 });
    expect(d.priority.toLowerCase()).toContain("knee");
    expect(d.priority).toContain("PT");
  });

  it("builds a full prescription with correct formatting", () => {
    const d = makeDirective({
      ...base,
      recovery: 78,
      calorieTarget: 3200,
      proteinTarget: 200,
      proteinRemaining: 72,
      rehabSummary: "20 min knee PT — Spanish Squat +3 more",
      keySupplement: "Magnesium 400 mg",
      sleepTargetHours: 8.25,
      workoutName: "Upper Push",
    });
    const kinds = d.actions.map((a) => a.kind);
    expect(kinds).toEqual(expect.arrayContaining(["train", "fuel", "protein", "mobility", "supplement", "sleep"]));
    expect(d.actions.find((a) => a.kind === "fuel")?.value).toBe("3,200 kcal");
    expect(d.actions.find((a) => a.kind === "protein")?.value).toBe("200 g · 72 g to go");
    expect(d.actions.find((a) => a.kind === "sleep")?.value).toBe("8h 15m target");
  });
});
