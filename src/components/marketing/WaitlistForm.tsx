"use client";

import { useEffect, useState } from "react";
import { SelectField, TextField, Checkbox, Honeypot } from "./Field";
import { FITNESS_GOALS, TRAINING_TYPES, WEARABLES } from "@/lib/marketing/options";
import { isValidEmail, referralMessage, submitWaitlist } from "@/lib/marketing/submit";
import { AnalyticsEvent, track } from "@/lib/analytics";

type Errors = Partial<Record<"name" | "email" | "goal" | "training" | "wearable", string>>;

export function WaitlistForm({ compact = false }: { compact?: boolean }) {
  const [name, setName] = useState("");
  const [email, setEmail] = useState("");
  const [goal, setGoal] = useState("");
  const [training, setTraining] = useState("");
  const [wearable, setWearable] = useState("");
  const [consent, setConsent] = useState(true);
  const [honeypot, setHoneypot] = useState("");
  const [errors, setErrors] = useState<Errors>({});
  const [status, setStatus] = useState<"idle" | "loading" | "error" | "done">("idle");
  const [serverError, setServerError] = useState("");
  const [started, setStarted] = useState(false);

  function onFirstInteraction() {
    if (!started) {
      setStarted(true);
      track(AnalyticsEvent.WaitlistStarted);
    }
  }

  function validate(): boolean {
    const next: Errors = {};
    if (!name.trim()) next.name = "Please enter your name.";
    if (!isValidEmail(email)) next.email = "Enter a valid email.";
    if (!goal) next.goal = "Pick a goal.";
    if (!training) next.training = "Pick a training type.";
    if (!wearable) next.wearable = "Pick a device.";
    setErrors(next);
    return Object.keys(next).length === 0;
  }

  async function onSubmit(e: React.FormEvent) {
    e.preventDefault();
    setServerError("");
    if (!validate()) return;
    setStatus("loading");
    const res = await submitWaitlist({
      name: name.trim(),
      email: email.trim(),
      fitness_goal: goal,
      training_type: training,
      wearable,
      marketing_consent: consent,
      honeypot,
    });
    if (res.ok) {
      track(AnalyticsEvent.WaitlistSubmitted, { goal, training, wearable });
      setStatus("done");
    } else {
      setStatus("error");
      setServerError(res.error || "Something went wrong.");
    }
  }

  if (status === "done") {
    return <WaitlistSuccess name={name.trim()} />;
  }

  return (
    <form onSubmit={onSubmit} onChange={onFirstInteraction} noValidate className="space-y-4">
      <Honeypot value={honeypot} onChange={setHoneypot} />
      <div className={compact ? "space-y-4" : "grid gap-4 sm:grid-cols-2"}>
        <TextField label="Name" value={name} onChange={setName} error={errors.name} required autoComplete="name" placeholder="Alex Rivera" />
        <TextField label="Email" type="email" value={email} onChange={setEmail} error={errors.email} required autoComplete="email" placeholder="you@email.com" />
      </div>
      <SelectField label="Primary fitness goal" value={goal} onChange={setGoal} options={FITNESS_GOALS} error={errors.goal} required />
      <div className={compact ? "space-y-4" : "grid gap-4 sm:grid-cols-2"}>
        <SelectField label="Training type" value={training} onChange={setTraining} options={TRAINING_TYPES} error={errors.training} required />
        <SelectField label="Wearable device" value={wearable} onChange={setWearable} options={WEARABLES} error={errors.wearable} required />
      </div>

      <Checkbox checked={consent} onChange={setConsent}>
        Email me early-access updates and beta invites. No spam — unsubscribe anytime.
      </Checkbox>

      {status === "error" && (
        <p className="text-sm text-forge-ruby" role="alert">{serverError}</p>
      )}

      <button type="submit" className="btn-gold w-full" disabled={status === "loading"}>
        {status === "loading" ? (
          <><Spinner /> Securing your spot…</>
        ) : (
          "Join the Waitlist"
        )}
      </button>
      <p className="text-center text-[11px] text-obsidian-200">
        Free to join · No card required · We never sell your data
      </p>
    </form>
  );
}

function WaitlistSuccess({ name }: { name: string }) {
  const [copied, setCopied] = useState(false);
  const [shareUrl, setShareUrl] = useState("https://forge.fit");

  useEffect(() => {
    if (typeof window !== "undefined") setShareUrl(window.location.origin);
  }, []);

  const message = referralMessage(shareUrl);

  async function copy() {
    try {
      await navigator.clipboard.writeText(message);
      setCopied(true);
      track(AnalyticsEvent.ReferralCopied);
      setTimeout(() => setCopied(false), 2200);
    } catch {
      setCopied(false);
    }
  }

  return (
    <div className="fade-in text-center">
      <div className="mx-auto flex h-16 w-16 items-center justify-center rounded-full border border-gold-400/40 bg-gold-400/10">
        <svg width="30" height="30" viewBox="0 0 24 24" fill="none" aria-hidden>
          <path d="M5 13l4 4L19 7" stroke="#e9c659" strokeWidth="2.2" strokeLinecap="round" strokeLinejoin="round" />
        </svg>
      </div>
      <h3 className="display mt-5 text-3xl text-cream-50">You&apos;re on the list{name ? `, ${name.split(" ")[0]}` : ""}.</h3>
      <p className="mx-auto mt-3 max-w-md text-sm text-obsidian-100">
        You&apos;ll be among the first invited when Forge opens. We&apos;ll email your invite and a short
        onboarding — keep an eye on your inbox (and check spam just in case).
      </p>

      <div className="hairline my-7" />

      <div className="text-left">
        <div className="text-[11px] uppercase tracking-[0.18em] text-gold-300">Move up the list</div>
        <p className="mt-1 text-sm text-obsidian-100">
          Every friend who joins with your link moves you closer to the front. Share this:
        </p>
        <div className="mt-3 rounded-xl border border-gold-400/15 bg-obsidian-900/60 p-4 text-sm text-cream-200">
          {message}
        </div>
        <button type="button" onClick={copy} className="btn-gold mt-3 w-full">
          {copied ? "Copied to clipboard ✓" : "Copy share message"}
        </button>
      </div>
    </div>
  );
}

function Spinner() {
  return (
    <svg className="h-4 w-4 animate-spin" viewBox="0 0 24 24" fill="none" aria-hidden>
      <circle cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="3" opacity="0.25" />
      <path d="M22 12a10 10 0 0 1-10 10" stroke="currentColor" strokeWidth="3" strokeLinecap="round" />
    </svg>
  );
}
