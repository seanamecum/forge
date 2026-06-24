"use client";

import { useState } from "react";
import Link from "next/link";
import { SectionTitle } from "@/components/ui/SectionTitle";
import { Ring } from "@/components/ui/Ring";
import { Bar } from "@/components/ui/Bar";
import {
  ptExercises,
  protocols,
  concussionSymptoms,
  concussionStages,
  injuryRisk,
} from "@/lib/mock/injuries";
import { injuries, user } from "@/lib/mock/user";
import { useForge } from "@/lib/store";
import { toast } from "@/lib/toast";
import { rehabPlan, returnReadiness } from "@/core";

const TABS = ["Profile", "PT Library", "Protocols", "Concussion", "Return-to-Sport"] as const;

export default function InjuryPage() {
  const [tab, setTab] = useState<(typeof TABS)[number]>("Profile");

  return (
    <div className="space-y-6">
      <SectionTitle
        eyebrow="Forge Recovery"
        title="Injury & Physical Therapy"
        subtitle="Most apps stop here. Forge starts a protocol, throttles your plan, blocks aggravating movement, and walks you back to full output."
        right={
          <Link href="/coach" className="btn-ghost text-xs">
            ✦ Ask the Coach
          </Link>
        }
      />

      {/* Tab strip */}
      <div className="flex flex-wrap gap-1.5 border-b border-gold-400/10 pb-3">
        {TABS.map((t) => (
          <button
            key={t}
            onClick={() => setTab(t)}
            className={`rounded-full px-4 py-1.5 text-[12px] uppercase tracking-wider transition ${
              tab === t
                ? "bg-gold-400/15 text-gold-200"
                : "text-cream-200 hover:bg-obsidian-700/50"
            }`}
          >
            {t}
          </button>
        ))}
      </div>

      {tab === "Profile" && <Profile />}
      {tab === "PT Library" && <PTLibrary />}
      {tab === "Protocols" && <Protocols />}
      {tab === "Concussion" && <Concussion />}
      {tab === "Return-to-Sport" && <ReturnToSport />}

      <div className="rounded-lg border border-gold-400/10 bg-obsidian-800/30 p-4 text-[11px] text-obsidian-200">
        Forge Recovery is educational guidance — not a substitute for medical evaluation. For acute pain,
        persistent symptoms, head injury, joint instability, or any concern, consult a licensed
        physician or physical therapist immediately.
      </div>
    </div>
  );
}

function Profile() {
  const forge = useForge();
  const injury = injuries[0];
  // Computed by @forge/core — reacts live to the pain slider below.
  const rehab = injury
    ? rehabPlan(
        { area: injury.area, name: injury.name, phase: injury.phase, painToday: forge.painToday },
        ptExercises,
        protocols
      )
    : null;
  const readiness = injury
    ? returnReadiness({ area: injury.area, name: injury.name, phase: injury.phase, painToday: forge.painToday })
    : null;

  return (
    <div className="space-y-6">
      {/* Risk hero */}
      <div className="card card-gold p-6">
        <div className="grid items-center gap-6 lg:grid-cols-[auto,1fr]">
          <div className="flex flex-col items-center">
            <Ring value={injuryRisk.scorePct} size={180} stroke={12} tone="ruby" label="Injury Risk" big />
            <span className="mt-2 chip chip-amber">{injuryRisk.band}</span>
          </div>
          <div>
            <div className="text-[10px] uppercase tracking-[0.22em] text-gold-300">7-day model</div>
            <h3 className="display mt-1 text-2xl text-cream-50">Why your risk is elevated</h3>
            <div className="mt-3 space-y-1.5">
              {injuryRisk.drivers.map((d, i) => (
                <div key={i} className="flex flex-wrap items-baseline justify-between gap-2 border-b border-gold-400/8 pb-1.5 text-[13px]">
                  <span className="text-cream-200">{d.driver}</span>
                  <span className="text-gold-200">{d.value}</span>
                  <span className="text-[11px] text-obsidian-200">{d.note}</span>
                </div>
              ))}
            </div>
            <div className="mt-3 rounded-md border border-gold-400/15 bg-gold-400/5 p-3 text-[13px] text-cream-200">
              <span className="text-gold-200">Forge plan:</span> {injuryRisk.recommendation}
            </div>
          </div>
        </div>
      </div>

      {/* FORGE REHAB — computed daily PT + return-to-sport readiness */}
      {rehab && readiness && (
        <div className="card p-6">
          <div className="grid items-center gap-6 lg:grid-cols-[auto,1fr]">
            <div className="flex flex-col items-center">
              <Ring value={readiness.percent} size={150} stroke={11} tone="gold" label="RTS Ready" big />
              <span className="mt-2 chip chip-gold">{readiness.band}</span>
            </div>
            <div>
              <div className="text-[10px] uppercase tracking-[0.22em] text-gold-300">{rehab.title}</div>
              <h3 className="display mt-1 text-2xl text-cream-50">{rehab.focus}</h3>
              <div className="mt-1 text-[12px] text-obsidian-200">
                Today&apos;s PT · ~{rehab.estMinutes} min · next: {readiness.nextMilestone} · {readiness.etaText}
              </div>
              <div className="mt-4 space-y-2">
                {rehab.exercises.map((ex) => (
                  <div
                    key={ex.name}
                    className="flex items-baseline justify-between gap-3 rounded-md border border-gold-400/10 bg-obsidian-800/50 px-3 py-2 text-sm"
                  >
                    <div>
                      <div className="text-cream-100">{ex.name}</div>
                      <div className="text-[11px] text-obsidian-200">{ex.note}</div>
                    </div>
                    <span className="shrink-0 text-[12px] text-gold-200">{ex.prescription}</span>
                  </div>
                ))}
              </div>
            </div>
          </div>
        </div>
      )}

      {/* Active injuries */}
      <div className="grid gap-4 lg:grid-cols-2">
        {injuries.map((i) => (
          <div key={i.id} className="card p-6">
            <div className="mb-3 flex items-baseline justify-between">
              <div>
                <div className="text-[10px] uppercase tracking-[0.22em] text-gold-300">Active · {i.area}</div>
                <div className="display mt-1 text-2xl text-cream-50">{i.name}</div>
                <div className="mt-1 text-[12px] text-obsidian-200">Day {i.daysOld} · phase: {i.phase}</div>
              </div>
              <span className="chip chip-amber">Severity {i.severity}/5</span>
            </div>

            <div className="mb-2 flex items-baseline justify-between text-xs">
              <span className="text-cream-200">Pain today — drag to log</span>
              <span className={forge.painToday >= 5 ? "text-forge-ruby" : "text-cream-100"}>{forge.painToday}/10</span>
            </div>
            <Bar value={forge.painToday} max={10} tone={forge.painToday >= 5 ? "ruby" : "amber"} />
            <input
              type="range"
              min={0}
              max={10}
              value={forge.painToday}
              onChange={(e) => forge.set("painToday", Number(e.target.value))}
              onMouseUp={() => toast(`Pain logged: ${forge.painToday}/10${forge.painToday >= 6 ? " — elevated. If this persists or worsens, see a PT." : " — trend updated"}`)}
              onTouchEnd={() => toast(`Pain logged: ${forge.painToday}/10`)}
              className="mt-2 w-full accent-[#d4af37]"
            />

            <div className="mt-4 grid grid-cols-3 gap-2">
              <SubScore label="Mobility" value="78%" tone="good" />
              <SubScore label="Strength" value="62%" tone="warn" />
              <SubScore label="Stability" value="84%" tone="good" />
            </div>

            {i.notes && (
              <div className="mt-4 rounded-md border border-gold-400/10 bg-obsidian-800/40 p-3 text-[12px] text-cream-200">
                {i.notes}
              </div>
            )}

            <div className="mt-4 flex gap-2">
              <button
                className={forge.rehabDoneToday ? "btn-ghost text-xs" : "btn-gold text-xs"}
                onClick={() => {
                  if (forge.rehabDoneToday) {
                    toast("Rehab already completed today — next block tomorrow morning");
                  } else {
                    forge.set("rehabDoneToday", true);
                    forge.addXp(120);
                    toast("Rehab block done: pull-aparts 3×20, wall slides 3×10, ext. rotations 3×15 · +120 XP");
                  }
                }}
              >
                {forge.rehabDoneToday ? "Rehab done today ✓" : "Start today's rehab"}
              </button>
            </div>
          </div>
        ))}

        <div className="card p-6">
          <div className="text-[10px] uppercase tracking-[0.22em] text-gold-300">Add an injury</div>
          <div className="display mt-1 text-2xl text-cream-50">Forge will adapt your plan</div>
          <p className="mt-2 text-sm text-obsidian-200">
            Logging an injury auto-modifies your workout generator, blocks contraindicated lifts, and starts
            a rehab protocol matched to your phase.
          </p>
          <div className="mt-4 flex flex-wrap gap-1.5">
            {["Shoulder", "Knee", "Ankle", "Hip", "Back", "Neck", "Wrist", "Elbow", "Hamstring", "Groin", "Concussion"].map((a) => (
              <button
                key={a}
                className="chip transition hover:border-gold-400/50 hover:text-gold-200"
                onClick={() => {
                  forge.addInjury(a);
                  toast(`${a} injury logged — protocol queued, aggravating lifts blocked in the generator`);
                }}
              >
                + {a}
              </button>
            ))}
          </div>
          {forge.addedInjuries.length > 0 && (
            <div className="mt-4 space-y-2">
              {forge.addedInjuries.map((inj) => (
                <div key={inj.id} className="flex items-center justify-between rounded-md border border-forge-amber/30 bg-forge-amber/5 px-3 py-2">
                  <span className="text-sm text-cream-100">{inj.name}</span>
                  <span className="chip chip-amber">Acute · day 0</span>
                </div>
              ))}
            </div>
          )}
        </div>
      </div>
    </div>
  );
}

function PTLibrary() {
  return (
    <div className="grid gap-3 sm:grid-cols-2 lg:grid-cols-3">
      {ptExercises.map((p) => (
        <div key={p.id} className="card p-4">
          <div className="mb-2 flex items-baseline justify-between gap-2">
            <div>
              <div className="text-[10px] uppercase tracking-wider text-gold-300">{p.area}</div>
              <div className="mt-0.5 text-sm text-cream-100">{p.name}</div>
            </div>
            <span className="chip">{p.phase}</span>
          </div>
          <div className="text-[12px] text-cream-200">{p.sets}</div>
          <div className="mt-1 text-[11px] text-obsidian-200">{p.notes}</div>
        </div>
      ))}
    </div>
  );
}

function Protocols() {
  return (
    <div className="space-y-4">
      {protocols.map((p) => (
        <div key={p.area} className="card p-5">
          <div className="display mb-1 text-xl text-cream-50">{p.area}</div>

          <div className="mt-3 grid gap-4 lg:grid-cols-2">
            <div>
              <div className="text-[10px] uppercase tracking-[0.22em] text-gold-300">Symptoms</div>
              <ul className="mt-2 space-y-1 text-sm text-cream-200">
                {p.symptoms.map((s) => <li key={s} className="flex gap-2"><span className="text-forge-amber">•</span>{s}</li>)}
              </ul>
            </div>
            <div>
              <div className="text-[10px] uppercase tracking-[0.22em] text-forge-ruby">What to avoid</div>
              <ul className="mt-2 space-y-1 text-sm text-cream-200">
                {p.whatToAvoid.map((s) => <li key={s} className="flex gap-2"><span className="text-forge-ruby">×</span>{s}</li>)}
              </ul>
            </div>
          </div>

          <div className="mt-4">
            <div className="text-[10px] uppercase tracking-[0.22em] text-gold-300">Progression phases</div>
            <div className="mt-2 grid gap-2 sm:grid-cols-2 lg:grid-cols-4">
              {p.phases.map((ph, i) => (
                <div key={i} className="rounded-md border border-gold-400/10 bg-obsidian-800/40 p-3">
                  <div className="text-[11px] text-gold-300">{ph.phase}</div>
                  <div className="mt-1 text-sm text-cream-100">{ph.goal}</div>
                  <div className="mt-1 text-[11px] text-obsidian-200">{ph.criteria}</div>
                </div>
              ))}
            </div>
          </div>
        </div>
      ))}
    </div>
  );
}

function Concussion() {
  return (
    <div className="space-y-6">
      <div className="rounded-lg border border-forge-ruby/30 bg-forge-ruby/5 p-4 text-[13px] text-cream-200">
        <span className="text-forge-ruby">⚠ Medical note:</span> Any new head injury with loss of
        consciousness, persistent vomiting, worsening symptoms, or focal neurologic signs (vision changes,
        weakness, slurred speech) is an emergency. Stop and seek care immediately.
      </div>

      <div className="card p-6">
        <div className="display text-xl text-cream-50">Daily symptom tracker</div>
        <p className="mt-1 text-sm text-obsidian-200">Score 0 (none) → 6 (severe). Track twice daily.</p>

        <div className="mt-4 space-y-3">
          {concussionSymptoms.map((s) => (
            <div key={s.key}>
              <div className="mb-1 flex items-baseline justify-between text-xs">
                <span className="text-cream-200">{s.label}</span>
                <span className="text-cream-100">{s.value} / 6</span>
              </div>
              <Bar value={s.value} max={6} tone={s.value >= 4 ? "ruby" : s.value >= 2 ? "amber" : "green"} />
            </div>
          ))}
        </div>
      </div>

      <div className="card p-6">
        <div className="display text-xl text-cream-50">Return-to-play stages</div>
        <p className="mt-1 text-sm text-obsidian-200">Advance only when symptom-free for 24h at the current stage.</p>
        <div className="mt-4 space-y-2">
          {concussionStages.map((s, i) => (
            <div
              key={s.id}
              className={`flex items-start gap-3 rounded-md border p-3 ${
                i < 2 ? "border-forge-green/30 bg-forge-green/5" : "border-gold-400/10 bg-obsidian-800/40"
              }`}
            >
              <span className={`grid h-8 w-8 place-items-center rounded-full border ${i < 2 ? "border-forge-green/40 bg-forge-green/10 text-forge-green" : "border-gold-400/30 bg-gold-400/5 text-gold-300"}`}>
                {i < 2 ? "✓" : s.id}
              </span>
              <div>
                <div className="text-sm text-cream-50">{s.name}</div>
                <div className="text-[11px] text-obsidian-200">{s.desc}</div>
              </div>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}

function ReturnToSport() {
  const forge = useForge();
  return (
    <div className="space-y-4">
      <div className="card p-6">
        <div className="text-[10px] uppercase tracking-[0.22em] text-gold-300">Active: Right Shoulder</div>
        <div className="display mt-1 text-2xl text-cream-50">Return-to-Sport Checklist</div>
        <p className="mt-1 text-sm text-obsidian-200">Hockey shooting + cross-check pressure load.</p>

        <div className="mt-5 space-y-3">
          {RTS_CHECKLIST.map((c, idx) => {
            const done = forge.rts[idx] ?? c.done;
            return (
              <button
                key={c.label}
                onClick={() => {
                  forge.set("rts", { ...forge.rts, [idx]: !done });
                  toast(!done ? `Gate cleared: ${c.label}` : `Gate re-opened: ${c.label}`);
                }}
                className={`flex w-full items-start gap-3 rounded-md border p-3 text-left transition ${
                  done ? "border-forge-green/30 bg-forge-green/5" : "border-gold-400/10 bg-obsidian-800/40 hover:border-gold-400/30"
                }`}
              >
                <span className={`grid h-7 w-7 shrink-0 place-items-center rounded-full text-[11px] ${done ? "bg-forge-green/15 text-forge-green" : "border border-gold-400/25 text-gold-300"}`}>
                  {done ? "✓" : "○"}
                </span>
                <div>
                  <div className={`text-sm ${done ? "text-obsidian-200 line-through" : "text-cream-50"}`}>{c.label}</div>
                  <div className="text-[11px] text-obsidian-200">{c.note}</div>
                </div>
              </button>
            );
          })}
        </div>

        <div className="mt-5 rounded-md border border-gold-400/15 bg-gold-400/5 p-3 text-[13px] text-cream-200">
          <span className="text-gold-200">Forge estimate:</span> ~10–14 days to clear all RTS criteria at current trajectory.
        </div>
      </div>
    </div>
  );
}

function SubScore({ label, value, tone }: { label: string; value: string; tone: "good" | "warn" | "bad" }) {
  const c = tone === "good" ? "text-forge-green" : tone === "warn" ? "text-forge-amber" : "text-forge-ruby";
  return (
    <div className="rounded-md border border-gold-400/10 bg-obsidian-800/40 px-3 py-2 text-center">
      <div className="text-[9px] uppercase tracking-wider text-obsidian-200">{label}</div>
      <div className={`mt-1 text-sm ${c}`}>{value}</div>
    </div>
  );
}

const RTS_CHECKLIST = [
  { label: "Pain ≤ 1/10 at full ROM", note: "All planes, end-range tested", done: true },
  { label: "Internal rotation 90° pain-free", note: "Functional shoulder mobility", done: true },
  { label: "Push-up x 20 pain-free", note: "Closed-chain load tolerance", done: false },
  { label: "Landmine press 30kg x 8", note: "Open-chain in scapular plane", done: false },
  { label: "Plyometric overhead toss x 10", note: "Power return — light medball", done: false },
  { label: "Sport-specific: stick handle 5 min", note: "Hockey-specific load test", done: false },
  { label: "Two consecutive symptom-free sessions", note: "No flare 24h post", done: false },
];
