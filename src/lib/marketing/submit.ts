// @forge/marketing — client → server submission seam.
//
// Forms call submitWaitlist/submitBeta. Those POST to our own API routes, which
// hold the only credentials (service role key stays server-side — never shipped
// to the browser). If no backend is configured the route mock-logs and returns
// { ok, mock: true }, so the whole flow works locally with zero setup.

import type {
  BetaApplication,
  ReferralSource,
  SubmissionResult,
  WaitlistSubmission,
} from "./types";
import { HONEYPOT_FIELD } from "./rate-limit";

/** Capture attribution from the current URL + referrer at submit time. */
export function captureReferral(): ReferralSource {
  if (typeof window === "undefined") return {};
  const params = new URLSearchParams(window.location.search);
  return {
    utm_source: params.get("utm_source"),
    utm_medium: params.get("utm_medium"),
    utm_campaign: params.get("utm_campaign"),
    ref_code: params.get("ref"),
    referrer: document.referrer || null,
    landing_path: window.location.pathname,
  };
}

async function post(
  url: string,
  body: Record<string, unknown>,
): Promise<SubmissionResult> {
  try {
    const res = await fetch(url, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(body),
    });
    const data = (await res.json().catch(() => ({}))) as SubmissionResult;
    if (!res.ok || !data.ok) {
      return { ok: false, error: data.error || "Something went wrong. Please try again." };
    }
    return data;
  } catch {
    return { ok: false, error: "Network error. Check your connection and try again." };
  }
}

/** Wire-only extra field: the honeypot value. Never part of the DB row. */
type Honeypot = { honeypot?: string };

export function submitWaitlist(
  data: Omit<WaitlistSubmission, "referral"> & { referral?: ReferralSource } & Honeypot,
): Promise<SubmissionResult> {
  const { honeypot, ...rest } = data;
  return post("/api/waitlist", {
    ...rest,
    referral: data.referral ?? captureReferral(),
    [HONEYPOT_FIELD]: honeypot ?? "",
  });
}

export function submitBeta(
  data: Omit<BetaApplication, "referral"> & { referral?: ReferralSource } & Honeypot,
): Promise<SubmissionResult> {
  const { honeypot, ...rest } = data;
  return post("/api/beta", {
    ...rest,
    referral: data.referral ?? captureReferral(),
    [HONEYPOT_FIELD]: honeypot ?? "",
  });
}

/** Lightweight email check — real validation is defense-in-depth on the server. */
export function isValidEmail(email: string): boolean {
  return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email.trim());
}

/** The copyable share message shown on the waitlist success state. */
export function referralMessage(shareUrl: string): string {
  return `I just joined the early-access waitlist for Forge — one platform that turns your workouts, wearable data, recovery, and goals into one intelligent training system. Get in early: ${shareUrl}`;
}
