// @forge/data — the single seam the app reads through.
// MockDataSource backs it today; a SupabaseDataSource implementing the SAME
// interface drops in for M1 (live per-user data) without touching any view.
// "Fetch + compute" lives here, never in components.

import type { Directive, ForgeInsight, RecoveryDriver, ScoreChange } from "@/core";
import type { user, today, injuries, forgeScoreBreakdown } from "@/lib/mock/user";
import type { todaysWorkout, volumeByMuscle } from "@/lib/mock/workouts";
import type { dailyBrief } from "@/lib/ai/coach";

/** Everything the dashboard renders — raw signals plus engine-computed outputs. */
export interface DashboardData {
  user: typeof user;
  today: typeof today;
  injuries: typeof injuries;
  forgeScoreBreakdown: typeof forgeScoreBreakdown;
  forgeScoreTrend: number[];
  recoveryTrend: number[];
  hrvTrend: number[];
  sleepTrend: number[];
  todaysWorkout: typeof todaysWorkout;
  volumeByMuscle: typeof volumeByMuscle;
  brief: ReturnType<typeof dailyBrief>;
  directive: Directive;
  scoreChanges: ScoreChange[];
  scoreLever: string;
  recoveryDrivers: RecoveryDriver[];
  connections: ForgeInsight[];
}

export interface ForgeDataSource {
  getDashboard(): Promise<DashboardData>;
}
