// Mock user state — the protagonist of the Forge demo.
// Numbers are tuned so the dashboard tells a coherent story:
// athlete is mid-cut, slightly under-recovered, training hard, with a tweaky shoulder.

export type Sex = "male" | "female" | "other";
export type FitnessLevel = "beginner" | "intermediate" | "advanced" | "elite";

export type Goal =
  | "build_muscle"
  | "lose_fat"
  | "get_stronger"
  | "improve_endurance"
  | "athletic_performance"
  | "general_health";

export type Equipment =
  | "full_gym"
  | "home_gym"
  | "dumbbells"
  | "bands"
  | "bodyweight"
  | "barbell"
  | "kettlebell";

export type DietPref =
  | "omnivore"
  | "vegetarian"
  | "vegan"
  | "pescatarian"
  | "keto"
  | "paleo"
  | "high_protein";

export type Injury = {
  id: string;
  area:
    | "shoulder"
    | "knee"
    | "ankle"
    | "hip"
    | "back"
    | "neck"
    | "wrist"
    | "elbow"
    | "hamstring"
    | "groin"
    | "concussion";
  name: string;
  severity: 1 | 2 | 3 | 4 | 5; // 1 niggle → 5 acute
  painToday: number; // 0-10
  daysOld: number;
  phase: "acute" | "subacute" | "rehab" | "return-to-sport" | "resolved";
  notes?: string;
};

export const user = {
  name: "Marcus Vale",
  handle: "@mvale",
  age: 29,
  sex: "male" as Sex,
  heightCm: 183,
  weightKg: 88.4,
  bodyFatPct: 14.8,
  leanMassKg: 75.3,
  fitnessLevel: "advanced" as FitnessLevel,
  activityLevel: "very_active" as const,
  goals: ["get_stronger", "lose_fat", "athletic_performance"] as Goal[],
  primaryGoal: "athletic_performance" as Goal,
  equipment: ["full_gym", "barbell", "kettlebell"] as Equipment[],
  dietPreference: "high_protein" as DietPref,
  weeklyTrainingDays: 5,
  sport: "Ice Hockey",
  level: 24,
  xp: 18420,
  xpToNext: 22000,
  streakDays: 47,
  joinedAt: "2024-08-12",
  bio: "Hybrid athlete. Off-season hockey, in-season strength. Sub-9% by Q4.",
  wearables: {
    appleWatch: { connected: true, lastSync: "2 min ago" },
    whoop: { connected: true, lastSync: "5 min ago" },
    oura: { connected: false, lastSync: null },
    garmin: { connected: false, lastSync: null },
    fitbit: { connected: false, lastSync: null },
    polar: { connected: false, lastSync: null },
    smartScale: { connected: true, lastSync: "this morning" },
  },
  targets: {
    calories: 2780,
    protein: 220,
    carbs: 290,
    fat: 80,
    fiber: 38,
    waterMl: 3700,
  },
};

export const injuries: Injury[] = [
  {
    id: "inj-1",
    area: "shoulder",
    name: "Right shoulder impingement",
    severity: 2,
    painToday: 3,
    daysOld: 18,
    phase: "rehab",
    notes:
      "Triggered by heavy overhead pressing. Pain at end-range. Improving with band work.",
  },
];

export const today = {
  date: "Wed, June 10",
  forgeScore: 78,
  forgeScoreDelta: +3,
  recovery: 72,
  recoveryDelta: -5,
  sleep: 84,
  sleepHours: 7.4,
  sleepRem: 1.6,
  sleepDeep: 1.2,
  hrv: 64,
  hrvDelta: -8,
  restingHr: 52,
  trainingReadiness: "moderate" as "low" | "moderate" | "high" | "peak",
  strainYesterday: 17.2,
  caloriesIn: 1840,
  caloriesOut: 3120,
  caloriesRemaining: 940,
  proteinIn: 142,
  proteinRemaining: 78,
  carbsIn: 178,
  fatIn: 62,
  waterMl: 2100,
  hydrationPct: 57,
  steps: 6420,
  injuryRiskPct: 28, // 0-100
  todaysWorkout: {
    name: "Lower Body — Strength Block",
    durationMin: 65,
    exercises: 6,
    estimatedRpe: 8,
    focus: "Posterior chain + unilateral",
  },
};

// Forge Score sub-component contributions (sum-weighted)
export const forgeScoreBreakdown = [
  { label: "Sleep", value: 84, weight: 0.18, contribution: 15.1 },
  { label: "Recovery (HRV)", value: 64, weight: 0.18, contribution: 11.5 },
  { label: "Nutrition", value: 71, weight: 0.14, contribution: 9.9 },
  { label: "Hydration", value: 57, weight: 0.08, contribution: 4.6 },
  { label: "Training Load", value: 82, weight: 0.14, contribution: 11.5 },
  { label: "Activity (Steps)", value: 64, weight: 0.08, contribution: 5.1 },
  { label: "Stress", value: 73, weight: 0.10, contribution: 7.3 },
  { label: "Injury Status", value: 72, weight: 0.10, contribution: 7.2 },
];

// 14-day trend for sparklines (Forge Score)
export const forgeScoreTrend = [
  68, 71, 74, 70, 73, 76, 72, 75, 78, 74, 71, 76, 75, 78,
];

export const recoveryTrend = [
  62, 68, 72, 80, 78, 75, 81, 77, 73, 79, 84, 80, 77, 72,
];

export const hrvTrend = [
  58, 62, 65, 70, 68, 66, 72, 69, 67, 71, 74, 71, 67, 64,
];

export const sleepTrend = [
  7.1, 6.8, 7.4, 8.1, 7.9, 7.2, 8.2, 7.6, 7.3, 7.8, 8.0, 7.5, 7.1, 7.4,
];

export const weightTrend = [
  91.2, 91.0, 90.8, 90.5, 90.2, 89.9, 89.7, 89.4, 89.1, 88.9, 88.8, 88.6, 88.5, 88.4,
];
