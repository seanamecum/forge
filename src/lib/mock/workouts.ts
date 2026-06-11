export type Set = {
  reps: number;
  weightKg?: number;
  rpe?: number;
  rir?: number;
  isPr?: boolean;
};

export type WorkoutExercise = {
  exerciseId: string;
  name: string;
  sets: Set[];
  restSec?: number;
  notes?: string;
};

export type LoggedWorkout = {
  id: string;
  date: string;
  name: string;
  durationMin: number;
  totalVolumeKg: number;
  exercises: WorkoutExercise[];
  rpeAvg: number;
  strain: number;
  feel: "fresh" | "fine" | "tired" | "destroyed";
};

export const workoutHistory: LoggedWorkout[] = [
  {
    id: "w-001",
    date: "2026-06-08",
    name: "Upper — Push Strength",
    durationMin: 72,
    totalVolumeKg: 12340,
    rpeAvg: 8.2,
    strain: 17.2,
    feel: "tired",
    exercises: [
      {
        exerciseId: "bench-press",
        name: "Barbell Bench Press",
        sets: [
          { reps: 5, weightKg: 100, rpe: 7 },
          { reps: 5, weightKg: 110, rpe: 8 },
          { reps: 5, weightKg: 117.5, rpe: 9, isPr: true },
          { reps: 5, weightKg: 117.5, rpe: 9 },
        ],
        restSec: 180,
      },
      {
        exerciseId: "overhead-press",
        name: "Standing Overhead Press",
        sets: [
          { reps: 6, weightKg: 60, rpe: 7 },
          { reps: 6, weightKg: 65, rpe: 8 },
          { reps: 6, weightKg: 65, rpe: 8.5 },
        ],
        restSec: 150,
      },
      {
        exerciseId: "barbell-row",
        name: "Pendlay Row",
        sets: [
          { reps: 8, weightKg: 80, rpe: 7 },
          { reps: 8, weightKg: 90, rpe: 8 },
          { reps: 8, weightKg: 95, rpe: 8.5 },
        ],
        restSec: 150,
      },
      {
        exerciseId: "lateral-raise",
        name: "Lateral Raise — Superset w/ Tricep Pushdown",
        sets: [
          { reps: 15, weightKg: 12, rpe: 8 },
          { reps: 15, weightKg: 12, rpe: 8.5 },
          { reps: 12, weightKg: 14, rpe: 9 },
        ],
        restSec: 60,
      },
    ],
  },
  {
    id: "w-002",
    date: "2026-06-06",
    name: "Lower — Squat Focus",
    durationMin: 68,
    totalVolumeKg: 16800,
    rpeAvg: 8.4,
    strain: 18.6,
    feel: "destroyed",
    exercises: [
      {
        exerciseId: "back-squat",
        name: "Back Squat",
        sets: [
          { reps: 5, weightKg: 140, rpe: 7 },
          { reps: 5, weightKg: 155, rpe: 8 },
          { reps: 5, weightKg: 165, rpe: 9 },
          { reps: 3, weightKg: 175, rpe: 9.5, isPr: true },
        ],
      },
      {
        exerciseId: "deadlift",
        name: "Pause Deadlift",
        sets: [
          { reps: 3, weightKg: 140, rpe: 7 },
          { reps: 3, weightKg: 160, rpe: 8 },
          { reps: 3, weightKg: 170, rpe: 9 },
        ],
      },
      {
        exerciseId: "lunge",
        name: "Walking Lunge",
        sets: [
          { reps: 20, weightKg: 30, rpe: 8 },
          { reps: 20, weightKg: 30, rpe: 8.5 },
          { reps: 20, weightKg: 30, rpe: 9 },
        ],
      },
    ],
  },
  {
    id: "w-003",
    date: "2026-06-04",
    name: "Conditioning + Mobility",
    durationMin: 42,
    totalVolumeKg: 0,
    rpeAvg: 7.5,
    strain: 13.4,
    feel: "fine",
    exercises: [
      {
        exerciseId: "hiit",
        name: "Assault Bike HIIT — 10×30s/30s",
        sets: [
          { reps: 10, rpe: 9 },
        ],
        notes: "Avg power 320W last 5",
      },
    ],
  },
];

// Volume by muscle group, last 7 days (sets)
export const volumeByMuscle = [
  { muscle: "Chest", sets: 14, optimal: [10, 18] },
  { muscle: "Back", sets: 16, optimal: [12, 20] },
  { muscle: "Quads", sets: 12, optimal: [10, 18] },
  { muscle: "Hamstrings", sets: 9, optimal: [8, 14] },
  { muscle: "Glutes", sets: 11, optimal: [8, 16] },
  { muscle: "Shoulders", sets: 13, optimal: [10, 18] },
  { muscle: "Biceps", sets: 7, optimal: [6, 14] },
  { muscle: "Triceps", sets: 10, optimal: [8, 16] },
  { muscle: "Core", sets: 6, optimal: [6, 12] },
];

// Suggested workout for today (built by the generator)
export const todaysWorkout = {
  name: "Lower — Posterior Chain Block",
  reason:
    "Recovery 72 — moderate. We pulled total volume back 12% and capped top sets at RPE 8.5. Avoided heavy back-squat depth given last session's strain (18.6). Hip thrusts moved to first.",
  durationMin: 65,
  exercises: [
    {
      exerciseId: "hip-thrust",
      name: "Barbell Hip Thrust",
      prescription: "4 × 6 @ 170 kg (RPE 8) · 2:30 rest",
      reasoning: "Glute-dominant start while spine fatigue is elevated.",
    },
    {
      exerciseId: "deadlift",
      name: "Romanian Deadlift",
      prescription: "4 × 8 @ 130 kg (RPE 8) · 2:00 rest",
      reasoning: "Hamstring volume target sitting at 9 of 8–14.",
    },
    {
      exerciseId: "lunge",
      name: "Bulgarian Split Squat",
      prescription: "3 × 10/leg @ 24 kg DBs · 1:30 rest",
      reasoning: "Unilateral work for hockey carryover.",
    },
    {
      exerciseId: "leg-press",
      name: "Leg Press (Quads-Focused)",
      prescription: "3 × 12 @ 220 kg (RPE 8) · 2:00 rest",
      reasoning: "Lower-spine-load way to hit quad volume.",
    },
    {
      exerciseId: "plank",
      name: "Copenhagen Plank — Superset Pallof Press",
      prescription: "3 × 20s ea side / 12 reps · 1:00 rest",
      reasoning: "Adductor + anti-rotation. Hockey-specific.",
    },
    {
      exerciseId: "run",
      name: "Cool-down Walk",
      prescription: "10 min Z1",
      reasoning: "Active recovery, lymph drainage.",
    },
  ],
};

// PRs lifetime
export const prHistory = [
  { exercise: "Bench Press", weightKg: 132.5, date: "2026-04-22" },
  { exercise: "Back Squat", weightKg: 175, date: "2026-05-15" },
  { exercise: "Deadlift", weightKg: 210, date: "2026-03-08" },
  { exercise: "Overhead Press", weightKg: 80, date: "2026-02-19" },
  { exercise: "Hip Thrust", weightKg: 190, date: "2026-05-22" },
  { exercise: "Weighted Pull-Up", weightKg: 30, date: "2026-05-01" },
];
