import { describe, it, expect } from "vitest";
import { recoveryDrivers, crossModule } from "../insight";

describe("insight engine", () => {
  it("recovery drivers decompose the score, ordered by magnitude", () => {
    const d = recoveryDrivers({
      recovery: 72,
      sleepHours: 7.4,
      sleepReference: 8.5,
      hrv: 64,
      hrvBaseline: 72,
      strainYesterday: 17.2,
      strainAvg: 15,
      restingHr: 52,
      restingHrBaseline: 52,
      magnesiumPct: 52,
      magnesiumDaysLow: 6,
    });
    const factors = d.map((x) => x.factor);
    expect(factors).toEqual(expect.arrayContaining(["Sleep", "HRV", "Magnesium"]));
    // sorted descending by weight
    expect(d[0].weight).toBeGreaterThanOrEqual(d[d.length - 1].weight);
    expect(d.find((x) => x.factor === "Sleep")?.positive).toBe(false);
  });

  it("cross-module chains connect the modules, severity-first", () => {
    const chains = crossModule({
      recovery: 72,
      sleepDebtHours: 4.3,
      hrv: 64,
      hrvBaseline: 72,
      proteinRemaining: 78,
      hydrationPct: 57,
      injuryName: "Shoulder",
      injuryPhase: "Rehab",
      injuryRiskPercent: 28,
      injuryRiskBand: "Moderate",
      magnesiumPct: 52,
      magnesiumDaysLow: 6,
    });
    expect(chains.length).toBeGreaterThan(0);
    expect(chains[0].chain).toContain("Sleep debt");
    expect(chains.some((c) => c.chain.toLowerCase().includes("injury risk"))).toBe(true);
    expect(chains.every((c) => c.action.length > 0)).toBe(true);
  });

  it("a fully recovered athlete is not nagged with chains", () => {
    const chains = crossModule({
      recovery: 92,
      sleepDebtHours: 0,
      hrv: 66,
      hrvBaseline: 62,
      proteinRemaining: 0,
      hydrationPct: 100,
      injuryRiskPercent: 8,
      injuryRiskBand: "Low",
      magnesiumPct: 100,
      magnesiumDaysLow: 0,
    });
    expect(chains.length).toBe(0);
  });
});
