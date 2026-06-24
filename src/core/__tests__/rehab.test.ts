import { describe, it, expect } from "vitest";
import { rehabPlan, returnReadiness, type RehabPTExercise, type RehabProtocol, type RehabInjury } from "../rehab";

const library: RehabPTExercise[] = [
  { id: "pt1", name: "Rotator Cuff External Rotations", area: "Shoulder", sets: "3 × 15", notes: "Light band." },
  { id: "pt2", name: "Wall Slides", area: "Shoulder", sets: "3 × 10", notes: "Scap upward rotation." },
  { id: "pt3", name: "Band Pull-Aparts", area: "Shoulder", sets: "3 × 20", notes: "Daily." },
  { id: "pt7", name: "Terminal Knee Extensions", area: "Knee", sets: "3 × 15", notes: "Last 15°." },
];
const protocols: RehabProtocol[] = [
  { area: "Shoulder Impingement", recommendedPT: ["pt1", "pt2", "pt3"] },
];
const injury: RehabInjury = { area: "shoulder", name: "Right shoulder impingement", phase: "rehab", painToday: 3 };

describe("rehab engine", () => {
  it("plan uses the matching protocol", () => {
    const p = rehabPlan(injury, library, protocols);
    expect(p.exercises[0].name).toBe("Rotator Cuff External Rotations");
    expect(p.exercises.length).toBe(3);
    expect(p.summary.toLowerCase()).toContain("shoulder pt");
    expect(p.estMinutes).toBeGreaterThanOrEqual(10);
    expect(p.title).toContain("Shoulder");
  });

  it("falls back to library area match when no protocol", () => {
    const p = rehabPlan({ ...injury, area: "knee" }, library, []);
    expect(p.exercises.some((e) => e.name.includes("Knee"))).toBe(true);
  });

  it("readiness blends phase progress and pain", () => {
    const r = returnReadiness(injury);
    expect(r.percent).toBe(58);
    expect(r.band).toBe("On track");
    expect(r.phaseLabel).toBe("Rehab");
    expect(r.nextMilestone.length).toBeGreaterThan(0);
  });

  it("resolved + pain-free reads cleared", () => {
    const r = returnReadiness({ ...injury, phase: "resolved", painToday: 0 });
    expect(r.percent).toBeGreaterThanOrEqual(90);
    expect(r.band).toBe("Cleared");
  });
});
