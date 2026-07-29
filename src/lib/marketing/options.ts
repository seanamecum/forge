// @forge/marketing — shared option sets for the waitlist & beta forms.
// Single source of truth so the forms, the analytics dimensions, and the
// Supabase enums (see supabase/migrations/0004_marketing.sql) stay in lockstep.

export const FITNESS_GOALS = [
  "Build muscle",
  "Lose fat",
  "Get stronger",
  "Run faster / further",
  "Hybrid / all-round athleticism",
  "General health & longevity",
  "Recover from an injury",
] as const;

export const TRAINING_TYPES = [
  "Strength / lifting",
  "Running",
  "Hybrid (strength + endurance)",
  "CrossFit / functional",
  "Endurance (cycling, tri, rowing)",
  "Team / field sport",
  "General fitness",
] as const;

export const WEARABLES = [
  "Apple Watch",
  "WHOOP",
  "Garmin",
  "Oura",
  "Fitbit",
  "Polar",
  "Samsung / Google",
  "None yet",
  "Other",
] as const;

export const AGE_RANGES = [
  "Under 18",
  "18–24",
  "25–34",
  "35–44",
  "45–54",
  "55+",
] as const;

export const EXPERIENCE_LEVELS = [
  "Beginner",
  "Intermediate",
  "Advanced",
  "Competitive / elite",
  "Coach / trainer",
] as const;

export const CURRENT_APPS = [
  "Strava",
  "Garmin Connect",
  "WHOOP",
  "Apple Fitness / Health",
  "Hevy / Strong",
  "MyFitnessPal",
  "TrainingPeaks",
  "Nike Run Club",
  "None",
  "Other",
] as const;

export const TRAINING_FREQUENCY = [
  "1–2 days / week",
  "3–4 days / week",
  "5–6 days / week",
  "Every day",
  "Twice a day",
] as const;

// Mirrors the product surface advertised on the homepage.
export const WANTED_FEATURES = [
  "AI coaching",
  "Recovery & readiness",
  "Wearable integrations",
  "Strength / training plans",
  "Running & endurance",
  "Performance analytics",
  "Injury rehab",
  "Nutrition",
  "Social challenges & leaderboards",
  "Coach / creator tools",
] as const;

export type FitnessGoal = (typeof FITNESS_GOALS)[number];
export type TrainingType = (typeof TRAINING_TYPES)[number];
export type Wearable = (typeof WEARABLES)[number];
export type AgeRange = (typeof AGE_RANGES)[number];
export type ExperienceLevel = (typeof EXPERIENCE_LEVELS)[number];
export type TrainingFrequency = (typeof TRAINING_FREQUENCY)[number];
export type WantedFeature = (typeof WANTED_FEATURES)[number];
