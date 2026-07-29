// @forge/marketing — database-ready types for waitlist & beta submissions.
//
// These mirror supabase/migrations/0004_marketing.sql 1:1. The API routes
// (src/app/api/waitlist, src/app/api/beta) validate against these shapes before
// inserting, so the client, the server, and Postgres share one contract.

/** Where a signup came from — used for attribution once ad channels are live. */
export interface ReferralSource {
  /** utm_source / utm_medium / utm_campaign captured from the landing URL. */
  utm_source?: string | null;
  utm_medium?: string | null;
  utm_campaign?: string | null;
  /** document.referrer at submit time. */
  referrer?: string | null;
  /** Optional referral code from a share link (?ref=CODE). */
  ref_code?: string | null;
  /** The path the user submitted from (e.g. "/", "/waitlist"). */
  landing_path?: string | null;
}

/** Fields common to every marketing submission. */
interface BaseSubmission {
  name: string;
  email: string;
  /** Explicit opt-in to product & marketing email. Defaults to false. */
  marketing_consent: boolean;
  referral: ReferralSource;
  /** ISO 8601. Set server-side on insert; optional on the wire. */
  submitted_at?: string;
}

/** Early-access waitlist signup — the lightweight top-of-funnel form. */
export interface WaitlistSubmission extends BaseSubmission {
  fitness_goal: string;
  training_type: string;
  wearable: string;
}

/** Detailed beta-tester application — richer, higher-intent form. */
export interface BetaApplication extends BaseSubmission {
  age_range: string;
  primary_sport: string;
  experience_level: string;
  wearable: string;
  current_apps: string[];
  training_frequency: string;
  wanted_feature: string;
  why: string;
  /** Must be true to submit — agreement to give structured feedback. */
  agrees_to_feedback: boolean;
}

/** Uniform API response for both endpoints. */
export interface SubmissionResult {
  ok: boolean;
  /** true when no backend is configured and the row was only logged. */
  mock?: boolean;
  error?: string;
}
