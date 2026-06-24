// @forge/core — framework-agnostic domain types.
// NO imports from React / Next / Supabase. This is the shared brain the web app
// uses today and a future React Native app will import unchanged.

export type Tone = "neutral" | "gold" | "green" | "amber" | "ruby" | "royal";

export type DirectiveActionKind =
  | "train"
  | "fuel"
  | "protein"
  | "mobility"
  | "supplement"
  | "sleep";

export interface DirectiveAction {
  kind: DirectiveActionKind;
  label: string;
  value: string;
  tone: Tone;
  icon: string;
}

export interface Directive {
  headline: string;
  rationale: string;
  priority: string;
  workoutName: string;
  tone: Tone;
  actions: DirectiveAction[];
}

export interface ScoreComponent {
  label: string;
  value: number; // 0..100
  weight: number; // 0..1, components sum to 1
}

export interface ScoreChange {
  text: string;
  positive: boolean;
}

// --- Targets (fuel) --------------------------------------------------------
export type Goal =
  | "build_muscle"
  | "lose_fat"
  | "strength"
  | "endurance"
  | "athletic"
  | "health"
  | "injury_recovery";

export type ActivityLevel = "sedentary" | "light" | "moderate" | "active" | "very_active";

export interface BodyProfile {
  weightLb: number;
  activity: ActivityLevel;
  goal: Goal;
}

export interface FuelTargets {
  calories: number;
  protein: number;
  carbs: number;
  fat: number;
  waterOz: number;
}

// --- Cross-module intelligence ---------------------------------------------
export interface RecoveryDriver {
  factor: string;
  detail: string;
  positive: boolean;
  weight: number;
}

export interface ForgeInsight {
  icon: string;
  chain: string;
  action: string;
  tone: Tone;
  severity: number;
}

// --- Injury rehab ----------------------------------------------------------
export interface RehabExercise {
  name: string;
  prescription: string;
  note: string;
}

export interface RehabPlan {
  title: string;
  focus: string;
  exercises: RehabExercise[];
  estMinutes: number;
  summary: string;
}

export interface ReturnReadiness {
  percent: number;
  band: string;
  phaseLabel: string;
  nextMilestone: string;
  etaText: string;
}

/** Tailwind text-color class for a tone — keeps rendering consistent app-wide. */
export function toneTextClass(tone: Tone): string {
  switch (tone) {
    case "gold":
      return "text-gold-200";
    case "green":
      return "text-forge-green";
    case "amber":
      return "text-forge-amber";
    case "ruby":
      return "text-forge-ruby";
    case "royal":
      return "text-forge-royal";
    default:
      return "text-cream-200";
  }
}
