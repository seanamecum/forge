"use client";

import { useState } from "react";
import Link from "next/link";
import { ForgeMark, ForgeWordmark } from "@/components/ui/Logo";

const STEPS = [
  "Identity",
  "Body",
  "Fitness Level",
  "Goals",
  "Equipment",
  "Diet",
  "Injuries",
  "Wearables",
  "Finalize",
] as const;

export default function OnboardingPage() {
  const [step, setStep] = useState(0);
  const [data, setData] = useState({
    name: "",
    email: "",
    age: 29,
    sex: "male",
    heightCm: 183,
    weightKg: 88,
    fitnessLevel: "advanced",
    activityLevel: "very_active",
    goals: ["athletic_performance"] as string[],
    equipment: ["full_gym"] as string[],
    diet: "high_protein",
    injuries: [] as string[],
    wearables: [] as string[],
  });

  const update = (k: string, v: any) => setData((d) => ({ ...d, [k]: v }));
  const toggle = (k: keyof typeof data, v: string) =>
    setData((d) => {
      const arr = d[k] as string[];
      return { ...d, [k]: arr.includes(v) ? arr.filter((x) => x !== v) : [...arr, v] };
    });

  return (
    <div className="min-h-screen bg-forge">
      <header className="mx-auto flex max-w-5xl items-center justify-between px-6 py-6">
        <Link href="/"><ForgeWordmark size={22} /></Link>
        <div className="text-[11px] uppercase tracking-[0.22em] text-obsidian-200">
          Step {step + 1} / {STEPS.length}
        </div>
      </header>

      <main className="mx-auto max-w-3xl px-6 pb-20">
        {/* Progress */}
        <div className="mb-8 flex gap-1.5">
          {STEPS.map((_, i) => (
            <div
              key={i}
              className={`h-1 flex-1 rounded-full ${i <= step ? "bg-gold-gradient" : "bg-obsidian-700"}`}
            />
          ))}
        </div>

        <div className="card p-8">
          <div className="mb-1 text-[10px] uppercase tracking-[0.22em] text-gold-300">
            {STEPS[step]}
          </div>

          {step === 0 && <Identity data={data} update={update} />}
          {step === 1 && <Body data={data} update={update} />}
          {step === 2 && <Fitness data={data} update={update} />}
          {step === 3 && <Goals data={data} toggle={toggle} />}
          {step === 4 && <Equipment data={data} toggle={toggle} />}
          {step === 5 && <Diet data={data} update={update} />}
          {step === 6 && <Injuries data={data} toggle={toggle} />}
          {step === 7 && <Wearables data={data} toggle={toggle} />}
          {step === 8 && <Finalize data={data} />}
        </div>

        <div className="mt-6 flex items-center justify-between">
          <button
            onClick={() => setStep((s) => Math.max(0, s - 1))}
            className="btn-quiet"
            disabled={step === 0}
          >
            ← Back
          </button>
          {step < STEPS.length - 1 ? (
            <button onClick={() => setStep((s) => Math.min(STEPS.length - 1, s + 1))} className="btn-gold">
              Continue →
            </button>
          ) : (
            <Link href="/dashboard" className="btn-gold">Enter The Forge →</Link>
          )}
        </div>
      </main>
    </div>
  );
}

// ——— Steps

function Heading({ title, sub }: { title: string; sub: string }) {
  return (
    <div className="mb-5">
      <h1 className="display text-3xl text-cream-50">{title}</h1>
      <p className="mt-1 text-sm text-obsidian-200">{sub}</p>
    </div>
  );
}

function Identity({ data, update }: any) {
  return (
    <>
      <Heading title="Who are you?" sub="The basics — used to build your profile." />
      <div className="grid gap-3">
        <Field label="Name">
          <input className="input" value={data.name} onChange={(e) => update("name", e.target.value)} placeholder="Marcus Vale" />
        </Field>
        <Field label="Email">
          <input className="input" value={data.email} onChange={(e) => update("email", e.target.value)} placeholder="you@forge.app" />
        </Field>
        <div className="grid grid-cols-2 gap-3">
          <Field label="Age">
            <input type="number" className="input" value={data.age} onChange={(e) => update("age", +e.target.value)} />
          </Field>
          <Field label="Sex">
            <select className="input" value={data.sex} onChange={(e) => update("sex", e.target.value)}>
              <option value="male">Male</option>
              <option value="female">Female</option>
              <option value="other">Other</option>
            </select>
          </Field>
        </div>
      </div>
    </>
  );
}

function Body({ data, update }: any) {
  return (
    <>
      <Heading title="Body" sub="Height and current weight. We'll let your wearable track changes." />
      <div className="grid grid-cols-2 gap-3">
        <Field label="Height (ft′in″, e.g. 6′3″)">
          <input type="number" className="input" value={data.heightCm} onChange={(e) => update("heightCm", +e.target.value)} />
        </Field>
        <Field label="Weight (lb)">
          <input type="number" className="input" value={data.weightKg} onChange={(e) => update("weightKg", +e.target.value)} />
        </Field>
      </div>
    </>
  );
}

function Fitness({ data, update }: any) {
  const levels = [
    { id: "beginner", name: "Beginner", sub: "< 1 yr structured training" },
    { id: "intermediate", name: "Intermediate", sub: "1–3 yr" },
    { id: "advanced", name: "Advanced", sub: "3–8 yr" },
    { id: "elite", name: "Elite", sub: "8+ yr or competing" },
  ];
  const activity = [
    { id: "sedentary", name: "Sedentary" },
    { id: "light", name: "Light" },
    { id: "moderate", name: "Moderate" },
    { id: "active", name: "Active" },
    { id: "very_active", name: "Very Active" },
  ];
  return (
    <>
      <Heading title="Where are you starting from?" sub="So we don't over- or under-prescribe." />
      <div className="grid gap-3 sm:grid-cols-2">
        {levels.map((l) => (
          <button key={l.id} onClick={() => update("fitnessLevel", l.id)}
            className={`rounded-lg border p-4 text-left ${data.fitnessLevel === l.id ? "border-gold-400/50 bg-gold-400/10" : "border-gold-400/10 bg-obsidian-800/40 hover:border-gold-400/30"}`}>
            <div className="text-sm text-cream-50">{l.name}</div>
            <div className="text-[11px] text-obsidian-200">{l.sub}</div>
          </button>
        ))}
      </div>
      <div className="mt-5 text-[10px] uppercase tracking-[0.22em] text-gold-300">Activity Level</div>
      <div className="mt-2 flex flex-wrap gap-1.5">
        {activity.map((a) => <Toggle key={a.id} on={data.activityLevel === a.id} onClick={() => update("activityLevel", a.id)} label={a.name} />)}
      </div>
    </>
  );
}

function Goals({ data, toggle }: any) {
  const goals = [
    { id: "build_muscle", name: "Build Muscle" },
    { id: "lose_fat", name: "Lose Fat" },
    { id: "get_stronger", name: "Get Stronger" },
    { id: "improve_endurance", name: "Endurance" },
    { id: "athletic_performance", name: "Athletic Performance" },
    { id: "general_health", name: "General Health" },
  ];
  return (
    <>
      <Heading title="What are you forging?" sub="Pick all that apply. We'll rank them with you next." />
      <div className="grid gap-2 sm:grid-cols-2">
        {goals.map((g) => (
          <Toggle key={g.id} on={data.goals.includes(g.id)} onClick={() => toggle("goals", g.id)} label={g.name} big />
        ))}
      </div>
    </>
  );
}

function Equipment({ data, toggle }: any) {
  const eq = ["Full Gym", "Home Gym", "Dumbbells", "Bands", "Bodyweight", "Barbell", "Kettlebell"];
  return (
    <>
      <Heading title="What do you have access to?" sub="We'll build workouts around your reality." />
      <div className="grid gap-2 sm:grid-cols-3">
        {eq.map((e) => (
          <Toggle key={e} on={data.equipment.includes(e.toLowerCase().replace(" ", "_"))} onClick={() => toggle("equipment", e.toLowerCase().replace(" ", "_"))} label={e} big />
        ))}
      </div>
    </>
  );
}

function Diet({ data, update }: any) {
  const opts = ["omnivore", "vegetarian", "vegan", "pescatarian", "keto", "paleo", "high_protein"];
  return (
    <>
      <Heading title="How do you eat?" sub="Filter the food database to what you actually buy." />
      <div className="flex flex-wrap gap-1.5">
        {opts.map((o) => <Toggle key={o} on={data.diet === o} onClick={() => update("diet", o)} label={o.replace("_", " ")} />)}
      </div>
    </>
  );
}

function Injuries({ data, toggle }: any) {
  const areas = ["Shoulder", "Knee", "Ankle", "Hip", "Back", "Neck", "Wrist", "Elbow", "Hamstring", "Groin", "Concussion"];
  return (
    <>
      <Heading title="Anything tweaky?" sub="Forge will automatically block aggravating movements and queue a rehab protocol. Skip if none." />
      <div className="grid gap-2 sm:grid-cols-3">
        {areas.map((a) => <Toggle key={a} on={data.injuries.includes(a)} onClick={() => toggle("injuries", a)} label={a} />)}
      </div>
      <div className="mt-4 rounded-lg border border-gold-400/10 bg-obsidian-800/30 p-3 text-[11px] text-obsidian-200">
        Forge offers educational guidance, not medical care. Serious or persistent symptoms — see a clinician.
      </div>
    </>
  );
}

function Wearables({ data, toggle }: any) {
  const w = ["Apple Watch", "WHOOP", "Oura Ring", "Garmin", "Fitbit", "Polar", "Smart Scale"];
  return (
    <>
      <Heading title="Hook up your hardware" sub="Pick the devices you wear. We'll guide pairing inside the app." />
      <div className="grid gap-2 sm:grid-cols-3">
        {w.map((d) => <Toggle key={d} on={data.wearables.includes(d)} onClick={() => toggle("wearables", d)} label={d} />)}
      </div>
    </>
  );
}

function Finalize({ data }: any) {
  return (
    <div className="text-center">
      <ForgeMark size={56} />
      <h1 className="display mt-4 text-3xl text-cream-50">Welcome to The Forge.</h1>
      <p className="mx-auto mt-2 max-w-md text-sm text-obsidian-200">
        We've drafted your first profile, a starting Forge Score, and your training week. Adjust anything from the dashboard.
      </p>
      <div className="mt-6 grid gap-2 text-left text-[12px] text-cream-200">
        {data.name && <Line k="Name" v={data.name} />}
        <Line k="Age / Sex" v={`${data.age} · ${data.sex}`} />
        <Line k="Body" v={`${Math.floor(data.heightCm / 2.54 / 12)}′${Math.round(data.heightCm / 2.54 % 12)}″ · ${Math.round(data.weightKg * 2.20462)} lb`} />
        <Line k="Level" v={`${data.fitnessLevel} · ${data.activityLevel}`} />
        <Line k="Goals" v={data.goals.join(", ") || "—"} />
        <Line k="Equipment" v={data.equipment.join(", ") || "—"} />
        <Line k="Diet" v={data.diet} />
        <Line k="Injuries" v={data.injuries.length ? data.injuries.join(", ") : "None"} />
        <Line k="Wearables" v={data.wearables.length ? data.wearables.join(", ") : "None yet"} />
      </div>
    </div>
  );
}

function Line({ k, v }: { k: string; v: string }) {
  return (
    <div className="flex justify-between border-b border-gold-400/8 pb-1.5">
      <span className="text-obsidian-200">{k}</span>
      <span className="text-cream-100">{v}</span>
    </div>
  );
}

function Field({ label, children }: { label: string; children: React.ReactNode }) {
  return (
    <div>
      <div className="mb-1 text-[10px] uppercase tracking-[0.18em] text-obsidian-200">{label}</div>
      {children}
    </div>
  );
}

function Toggle({ on, onClick, label, big = false }: { on: boolean; onClick: () => void; label: string; big?: boolean }) {
  return (
    <button
      onClick={onClick}
      className={`rounded-${big ? "lg" : "full"} border ${big ? "p-3 text-left" : "px-3 py-1.5 text-[12px]"} ${
        on ? "border-gold-400/50 bg-gold-400/10 text-gold-200" : "border-gold-400/10 bg-obsidian-800/40 text-cream-200 hover:border-gold-400/30"
      }`}
    >
      <div className={big ? "text-sm capitalize" : "capitalize"}>{label}</div>
    </button>
  );
}
