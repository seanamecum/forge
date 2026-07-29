import { NextResponse } from "next/server";
import { insertRow } from "@/lib/marketing/server";
import { clientIp, isBot, rateLimit } from "@/lib/marketing/rate-limit";
import type { WaitlistSubmission } from "@/lib/marketing/types";

export const runtime = "nodejs";

const emailRe = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
const str = (v: unknown, max = 200) =>
  typeof v === "string" ? v.trim().slice(0, max) : "";

export async function POST(req: Request) {
  // 1. Rate limit per IP (basic abuse protection).
  const rl = rateLimit(`waitlist:${clientIp(req)}`);
  if (!rl.ok) {
    return NextResponse.json(
      { ok: false, error: "Too many attempts. Please try again in a few minutes." },
      { status: 429, headers: { "Retry-After": String(rl.retryAfter) } },
    );
  }

  let body: Partial<WaitlistSubmission> & Record<string, unknown>;
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

  const result = await insertRow("waitlist_signups", {
    name,
    email,
    fitness_goal: str(body.fitness_goal),
    training_type: str(body.training_type),
    wearable: str(body.wearable),
    marketing_consent: body.marketing_consent === true,
    referral: body.referral ?? {},
  });

  return NextResponse.json(result, { status: result.ok ? 200 : 502 });
}
