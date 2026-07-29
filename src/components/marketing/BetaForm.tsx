"use client";

import { useState } from "react";
import { ChipGroup, Checkbox, SelectField, TextArea, TextField, Honeypot } from "./Field";
import {
  AGE_RANGES,
  CURRENT_APPS,
  EXPERIENCE_LEVELS,
  TRAINING_FREQUENCY,
  TRAINING_TYPES,
  WANTED_FEATURES,
  WEARABLES,
} from "@/lib/marketing/options";
import { isValidEmail, submitBeta } from "@/lib/marketing/submit";
import { AnalyticsEvent, track } from "@/lib/analytics";
import Link from "next/link";

type Key =
  | "name" | "email" | "age" | "sport" | "experience" | "wearable"
  | "frequency" | "feature" | "why" | "agree";
type Errors = Partial<Record<Key, string>>;

export function BetaForm() {
  const [name, setName] = useState("");
  const [email, setEmail] = useState("");
  const [age, setAge] = useState("");
  const [sport, setSport] = useState("");
  const [experience, setExperience] = useState("");
  const [wearable, setWearable] = useState("");
  const [apps, setApps] = useState<string[]>([]);
  const [frequency, setFrequency] = useState("");
  const [feature, setFeature] = useState("");
  const [why, setWhy] = useState("");
  const [agree, setAgree] = useState(false);
  const [consent, setConsent] = useState(true);
  const [honeypot, setHoneypot] = useState("");
  const [errors, setErrors] = useState<Errors>({});
  const [status, setStatus] = useState<"idle" | "loading" | "error" | "done">("idle");
  const [serverError, setServerError] = useState("");
  const [started, setStarted] = useState(false);

  function onFirstInteraction() {
    if (!started) {
      setStarted(true);
      track(AnalyticsEvent.BetaStarted);
    }
  }

  function toggleApp(app: string) {
    setApps((prev) => (prev.includes(app) ? prev.filter((a) => a !== app) : [...prev, app]));
  }

  function validate(): boolean {
    const next: Errors = {};
    if (!name.trim()) next.name = "Please enter your name.";
    if (!isValidEmail(email)) next.email = "Enter a valid email.";
    if (!age) next.age = "Select an age range.";
    if (!sport) next.sport = "Select your primary training style.";
    if (!experience) next.experience = "Select your experience level.";
    if (!wearable) next.wearable = "Select a device.";
    if (!frequency) next.frequency = "Select your training frequency.";
    if (!feature) next.feature = "Pick the feature you want most.";
    if (why.trim().length < 10) next.why = "Tell us a little more (10+ characters).";
    if (!agree) next.agree = "You must agree to provide feedback to beta test.";
    setErrors(next);
    if (Object.keys(next).length) {
      const first = document.querySelector('[aria-invalid="true"]');
      first?.scrollIntoView({ behavior: "smooth", block: "center" });
    }
    return Object.keys(next).length === 0;
  }

  async function onSubmit(e: React.FormEvent) {
    e.preventDefault();
    setServerError("");
    if (!validate()) return;
    setStatus("loading");
    const res = await submitBeta({
      name: name.trim(),
      email: email.trim(),
      age_range: age,
      primary_sport: sport,
      experience_level: experience,
      wearable,
      current_apps: apps,
      training_frequency: frequency,
      wanted_feature: feature,
      why: why.trim(),
      agrees_to_feedback: agree,
      marketing_consent: consent,
      honeypot,
    });
    if (res.ok) {
      track(AnalyticsEvent.BetaApplicationSubmitted, { sport, experience, feature });
      setStatus("done");
      window.scrollTo({ top: 0, behavior: "smooth" });
    } else {
      setStatus("error");
      setServerError(res.error || "Something went wrong.");
    }
  }

  if (status === "done") return <BetaSuccess name={name.trim()} />;

  return (
    <form onSubmit={onSubmit} onChange={onFirstInteraction} noValidate className="space-y-5">
      <Honeypot value={honeypot} onChange={setHoneypot} />
      <div className="grid gap-4 sm:grid-cols-2">
        <TextField label="Name" value={name} onChange={setName} error={errors.name} required autoComplete="name" placeholder="Alex Rivera" />
        <TextField label="Email" type="email" value={email} onChange={setEmail} error={errors.email} required autoComplete="email" placeholder="you@email.com" />
      </div>

      <div className="grid gap-4 sm:grid-cols-2">
        <SelectField label="Age range" value={age} onChange={setAge} options={AGE_RANGES} error={errors.age} required />
        <SelectField label="Primary sport / training style" value={sport} onChange={setSport} options={TRAINING_TYPES} error={errors.sport} required />
      </div>

      <div className="grid gap-4 sm:grid-cols-2">
        <SelectField label="Experience level" value={experience} onChange={setExperience} options={EXPERIENCE_LEVELS} error={errors.experience} required />
        <SelectField label="Primary wearable device" value={wearable} onChange={setWearable} options={WEARABLES} error={errors.wearable} required />
      </div>

      <ChipGroup label="Fitness apps you use today" options={CURRENT_APPS} selected={apps} onToggle={toggleApp} />

      <div className="grid gap-4 sm:grid-cols-2">
        <SelectField label="Training frequency" value={frequency} onChange={setFrequency} options={TRAINING_FREQUENCY} error={errors.frequency} required />
        <SelectField label="Most-wanted Forge feature" value={feature} onChange={setFeature} options={WANTED_FEATURES} error={errors.feature} required />
      </div>

      <TextArea
        label="Why do you want to beta test Forge?"
        value={why}
        onChange={setWhy}
        error={errors.why}
        required
        rows={4}
        maxLength={2000}
        placeholder="What are you training for, and what would make Forge genuinely useful to you?"
      />

      <div className="hairline" />

      <Checkbox checked={agree} onChange={setAgree} error={errors.agree}>
        I agree to actively use Forge and share honest feedback (surveys, bug reports, the occasional call) during the beta.
      </Checkbox>
      <Checkbox checked={consent} onChange={setConsent}>
        Email me beta updates and early-access news.
      </Checkbox>

      {status === "error" && <p className="text-sm text-forge-ruby" role="alert">{serverError}</p>}

      <button type="submit" className="btn-gold w-full" disabled={status === "loading"}>
        {status === "loading" ? "Submitting application…" : "Apply for Beta Access"}
      </button>
    </form>
  );
}

function BetaSuccess({ name }: { name: string }) {
  return (
    <div className="fade-in text-center">
      <div className="mx-auto flex h-16 w-16 items-center justify-center rounded-full border border-gold-400/40 bg-gold-400/10">
        <svg width="30" height="30" viewBox="0 0 24 24" fill="none" aria-hidden>
          <path d="M5 13l4 4L19 7" stroke="#e9c659" strokeWidth="2.2" strokeLinecap="round" strokeLinejoin="round" />
        </svg>
      </div>
      <h3 className="display mt-5 text-3xl text-cream-50">
        Application received{name ? `, ${name.split(" ")[0]}` : ""}.
      </h3>
      <p className="mx-auto mt-3 max-w-md text-sm text-obsidian-100">
        Thanks for stepping up. We review applications in waves and invite testers whose sport and
        devices fit each build. If you&apos;re a match, you&apos;ll get a personal invite with access
        details and a short onboarding.
      </p>
      <div className="mx-auto mt-6 max-w-md rounded-xl border border-gold-400/15 bg-obsidian-900/60 p-4 text-left text-sm text-obsidian-100">
        <div className="text-[11px] uppercase tracking-[0.18em] text-gold-300">What happens next</div>
        <ol className="mt-2 list-decimal space-y-1 pl-5">
          <li>We match your profile to an upcoming beta build.</li>
          <li>You get an email invite with install + onboarding steps.</li>
          <li>You train with Forge and tell us what to sharpen.</li>
        </ol>
      </div>
      <Link href="/" className="btn-ghost mt-7">Back to home</Link>
    </div>
  );
}
