// @forge/data — mock implementation of ForgeDataSource.
// Assembles raw mock signals + @forge/core engine outputs into the shape the
// dashboard renders. The Supabase implementation will mirror this exactly,
// reading rows instead of mock and computing with the same engines.

import {
  user,
  today,
  injuries,
  forgeScoreBreakdown,
  forgeScoreTrend,
  recoveryTrend,
  hrvTrend,
  sleepTrend,
} from "@/lib/mock/user";
import { todaysWorkout, volumeByMuscle } from "@/lib/mock/workouts";
import { dailyBrief } from "@/lib/ai/coach";
import {
  makeDirective,
  scoreChanges,
  scoreLever,
  recoveryDrivers,
  crossModule,
} from "@/core";
import type { DashboardData, ForgeDataSource, RecoveryPageData } from "./source";

export class MockDataSource implements ForgeDataSource {
  async getDashboard(): Promise<DashboardData> {
    const sleepDebtHours = 4.3;
    const hrvBaseline = today.hrv - today.hrvDelta;

    const directive = makeDirective({
      recovery: today.recovery,
      sleepDebtHours,
      calorieTarget: user.targets.calories,
      proteinTarget: user.targets.protein,
      proteinRemaining: today.proteinRemaining,
      hydrationPct: today.hydrationPct,
      injuryName: injuries[0]?.area,
      injuryPain: injuries[0]?.painToday,
      injuryRiskBand: "Moderate",
      injuryRiskPercent: today.injuryRiskPct,
      rehabSummary: injuries[0]
        ? `15 min ${injuries[0].area} PT — band work + scap control`
        : undefined,
      keySupplement: "Magnesium 400 mg",
      sleepTargetHours: 8.0 + Math.min(sleepDebtHours * 0.08, 1.0),
      workoutName: today.todaysWorkout.name,
    });

    const recDrivers = recoveryDrivers({
      recovery: today.recovery,
      sleepHours: today.sleepHours,
      sleepReference: 8.5,
      hrv: today.hrv,
      hrvBaseline,
      strainYesterday: today.strainYesterday,
      strainAvg: 15,
      restingHr: today.restingHr,
      restingHrBaseline: 50,
      magnesiumPct: 52,
      magnesiumDaysLow: 6,
    }).slice(0, 3);

    const connections = crossModule({
      recovery: today.recovery,
      sleepDebtHours,
      hrv: today.hrv,
      hrvBaseline,
      proteinRemaining: today.proteinRemaining,
      hydrationPct: today.hydrationPct,
      injuryName: injuries[0]?.area,
      injuryPhase: injuries[0]?.phase,
      injuryRiskPercent: today.injuryRiskPct,
      injuryRiskBand: "Moderate",
      magnesiumPct: 52,
      magnesiumDaysLow: 6,
    }).slice(0, 3);

    return {
      user,
      today,
      injuries,
      forgeScoreBreakdown,
      forgeScoreTrend,
      recoveryTrend,
      hrvTrend,
      sleepTrend,
      todaysWorkout,
      volumeByMuscle,
      brief: dailyBrief(),
      directive,
      scoreChanges: scoreChanges(forgeScoreBreakdown, { recovery: recoveryTrend, sleep: sleepTrend }),
      scoreLever: scoreLever(forgeScoreBreakdown),
      recoveryDrivers: recDrivers,
      connections,
    };
  }

  async getRecovery(): Promise<RecoveryPageData> {
    return {
      today,
      recoveryTrend,
      hrvTrend,
      sleepTrend,
      recoveryDrivers: recoveryDrivers({
        recovery: today.recovery,
        sleepHours: today.sleepHours,
        sleepReference: 8.5,
        hrv: today.hrv,
        hrvBaseline: today.hrv - today.hrvDelta,
        strainYesterday: today.strainYesterday,
        strainAvg: 15,
        restingHr: today.restingHr,
        restingHrBaseline: 50,
        magnesiumPct: 52,
        magnesiumDaysLow: 6,
      }),
    };
  }
}
