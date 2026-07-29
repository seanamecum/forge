import { NextResponse } from "next/server";
import { insertRow } from "@/lib/marketing/server";
import { clientIp, isBot, rateLimit } from "@/lib/marketing/rate-limit";
import type { BetaApplication } from "@/lib/marketing/types";

export const runtime = "nodejs";

const emailRe = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
const str = (v: unknown, max = 500) =>
  typeof v === "string" ? v.trim().slice(0, max) : "";
const strArr = (v: unknown, max = 20) =>
  Array.isArray(v) ? v.filter((x) => typeof x === "string").slice(0, max).map((x) => str(x, 120)) : [];

export async function POST(req: Request) {
  // 1. Rate limit per IP (basic abuse protection).
  const rl = rateLimit(`beta:${clientIp(req)}`);
  if (!rl.ok) {
    return NextResponse.json(
      { ok: false, error: "Too many attempts. Please try again in a few minutes." },
      { status: 429, headers: { "Retry-After": String(rl.retryAfter) } },
    );
  }

  let body: Partial<BetaApplication> & Record<string, unknown>;
  try {
    body = await req.json();
  } catch {
    return NextResponse.json({ ok: false, error: "Invalid request." }, { status: 400 });
  }

  // 2. Honeypot — a bot filled the hidden field. Fake success, drop the row.
  if (isBot(body)) return NextResponse.json({ ok: true });

  const name = str(body.name, 120);
  const email = str(body.email, 200).toLowerCase();

  if (name.length < 1) {
    return NextResponse.json({ ok: false, error: "Please enter your name." }, { status: 400 });
  }
  if (!emailRe.test(email)) {
    return NextResponse.json({ ok: false, error: "Please enter a valid email." }, { status: 400 });
  }
  if (body.agrees_to_feedback !== true) {
    return NextResponse.json(
      { ok: false, error: "Beta testers must agree to provide feedback." },
      { status: 400 },
    );
  }

  const result = await insertRow("beta_applications", {
    name,
    email,
    age_range: str(body.age_range),
    primary_sport: str(body.primary_sport),
    experience_level: str(body.experience_level),
    wearable: str(body.wearable),
    current_apps: strArr(body.current_apps),
    training_frequency: str(body.training_frequency),
    wanted_feature: str(body.wanted_feature),
    why: str(body.why, 2000),
    agrees_to_feedback: true,
    marketing_consent: body.marketing_consent === true,
    referral: body.referral ?? {},
  });

  return NextResponse.json(result, { status: result.ok ? 200 : 502 });
}
