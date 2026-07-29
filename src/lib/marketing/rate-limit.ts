// @forge/marketing — spam protection + basic rate limiting for the API routes.
//
// Two cheap, dependency-free defenses:
//   1. Honeypot — a hidden form field real users never see. If it's filled, the
//      request is a bot; we pretend success and drop it.
//   2. Rate limit — an in-memory sliding window per client IP.
//
// SCOPE NOTE: the rate-limit store is in-process, so on a serverless platform
// (Vercel) it is per-instance and resets on cold starts — good enough to blunt
// casual abuse, which is what "basic rate limiting" means here. For strict,
// globally-consistent limits, back this with Vercel KV / Upstash Redis: keep the
// same rateLimit() signature and swap the Map for a Redis INCR + EXPIRE.

/** Hidden field name shared by the forms and the routes. */
export const HONEYPOT_FIELD = "company_website";

interface Bucket {
  count: number;
  resetAt: number;
}

const buckets = new Map<string, Bucket>();

// Defaults: 5 submissions per IP per 10 minutes.
const DEFAULT_MAX = 5;
const DEFAULT_WINDOW_MS = 10 * 60 * 1000;

export interface RateLimitResult {
  ok: boolean;
  /** Seconds until the window resets (only meaningful when ok === false). */
  retryAfter: number;
}

/**
 * Fixed-window rate limiter. Returns { ok:false, retryAfter } when the caller
 * has exceeded `max` requests within `windowMs`.
 */
export function rateLimit(
  key: string,
  max = DEFAULT_MAX,
  windowMs = DEFAULT_WINDOW_MS,
): RateLimitResult {
  const now = Date.now();

  // Opportunistic prune so the Map can't grow unbounded on a long-lived instance.
  if (buckets.size > 5000) {
    for (const [k, b] of buckets) if (b.resetAt <= now) buckets.delete(k);
  }

  const bucket = buckets.get(key);
  if (!bucket || bucket.resetAt <= now) {
    buckets.set(key, { count: 1, resetAt: now + windowMs });
    return { ok: true, retryAfter: 0 };
  }
  if (bucket.count >= max) {
    return { ok: false, retryAfter: Math.max(1, Math.ceil((bucket.resetAt - now) / 1000)) };
  }
  bucket.count += 1;
  return { ok: true, retryAfter: 0 };
}

/** Best-effort client IP from proxy headers (Vercel sets x-forwarded-for). */
export function clientIp(req: Request): string {
  const xff = req.headers.get("x-forwarded-for");
  if (xff) return xff.split(",")[0]!.trim();
  return req.headers.get("x-real-ip")?.trim() || "unknown";
}

/** True when the honeypot field was filled — i.e. the submitter is a bot. */
export function isBot(body: Record<string, unknown>): boolean {
  const v = body[HONEYPOT_FIELD];
  return typeof v === "string" && v.trim().length > 0;
}
