"use client";

import { useState } from "react";
import { SectionTitle } from "@/components/ui/SectionTitle";
import { exercises, Exercise } from "@/lib/mock/exercises";

export default function ExercisesPage() {
  const [q, setQ] = useState("");
  const [selected, setSelected] = useState<Exercise | null>(exercises[0]);
  const [filter, setFilter] = useState<string>("all");

  const filtered = exercises.filter(
    (e) =>
      (filter === "all" || e.category === filter) &&
      (q === "" ||
        e.name.toLowerCase().includes(q.toLowerCase()) ||
        e.primaryMuscles.some((m) => m.toLowerCase().includes(q.toLowerCase())))
  );

  return (
    <div className="space-y-6">
      <SectionTitle
        eyebrow="Train · Library"
        title="Exercise Database"
        subtitle="Full anatomy, common mistakes, coaching tips, alternatives, and your 1RM history per movement."
      />

      <div className="grid gap-6 lg:grid-cols-[380px,1fr]">
        <div>
          <input
            value={q}
            onChange={(e) => setQ(e.target.value)}
            placeholder="Search exercise or muscle…"
            className="input"
          />
          <div className="mt-3 flex flex-wrap gap-1.5">
            {["all", "compound", "isolation", "cardio", "core", "mobility"].map((f) => (
              <button
                key={f}
                onClick={() => setFilter(f)}
                className={`rounded-full border px-3 py-1 text-[11px] uppercase tracking-wider ${
                  filter === f
                    ? "border-gold-400/50 bg-gold-400/10 text-gold-200"
                    : "border-gold-400/10 text-obsidian-200 hover:text-cream-100"
                }`}
              >
                {f}
              </button>
            ))}
          </div>
          <div className="mt-3 max-h-[640px] space-y-1 overflow-y-auto pr-1">
            {filtered.map((e) => (
              <button
                key={e.id}
                onClick={() => setSelected(e)}
                className={`w-full rounded-md border px-3 py-2 text-left ${
                  selected?.id === e.id
                    ? "border-gold-400/40 bg-gold-400/8"
                    : "border-gold-400/8 bg-obsidian-800/50 hover:border-gold-400/20"
                }`}
              >
                <div className="text-sm text-cream-100">{e.name}</div>
                <div className="mt-0.5 text-[11px] text-obsidian-200">
                  {e.primaryMuscles.join(" · ")}
                </div>
                <div className="mt-1 flex flex-wrap gap-1">
                  <span className="chip">{e.category}</span>
                  <span className="chip">{e.difficulty}</span>
                  {e.e1rmKg && <span className="chip chip-gold">1RM {e.e1rmKg}kg</span>}
                </div>
              </button>
            ))}
          </div>
        </div>

        {selected && <ExerciseDetail ex={selected} />}
      </div>
    </div>
  );
}

function ExerciseDetail({ ex }: { ex: Exercise }) {
  return (
    <div className="space-y-4">
      <div className="card p-6">
        <div className="mb-2 flex flex-wrap items-baseline justify-between gap-2">
          <div>
            <div className="text-[10px] uppercase tracking-[0.22em] text-gold-300">
              {ex.category} · {ex.difficulty}
            </div>
            <h2 className="display mt-1 text-3xl text-cream-50">{ex.name}</h2>
          </div>
          {ex.contraindicated && ex.contraindicated.length > 0 && (
            <span className="chip chip-ruby">⚠ Avoid w/ {ex.contraindicated.join(", ")}</span>
          )}
        </div>

        <div className="mt-4 grid gap-4 sm:grid-cols-2">
          <Field label="Primary muscles" value={ex.primaryMuscles.join(", ")} />
          <Field label="Secondary" value={ex.secondaryMuscles.join(", ") || "—"} />
          <Field label="Equipment" value={ex.equipment.join(", ")} />
          {ex.e1rmKg && <Field label="Your 1RM (est)" value={`${ex.e1rmKg} kg`} />}
        </div>
      </div>

      <div className="grid gap-4 sm:grid-cols-2">
        <div className="card p-5">
          <div className="mb-3 text-[10px] uppercase tracking-[0.22em] text-gold-300">Instructions</div>
          <ol className="space-y-1.5 text-sm text-cream-200">
            {ex.instructions.map((s, i) => (
              <li key={i} className="flex gap-2">
                <span className="text-gold-300/70">{i + 1}.</span>
                <span>{s}</span>
              </li>
            ))}
          </ol>
        </div>

        <div className="card p-5">
          <div className="mb-3 text-[10px] uppercase tracking-[0.22em] text-gold-300">Coaching tips</div>
          <ul className="space-y-1.5 text-sm text-cream-200">
            {ex.coachingTips.map((s, i) => (
              <li key={i} className="flex gap-2">
                <span className="text-gold-300">✦</span>
                <span>{s}</span>
              </li>
            ))}
          </ul>
        </div>
      </div>

      <div className="grid gap-4 sm:grid-cols-2">
        <div className="card p-5">
          <div className="mb-3 text-[10px] uppercase tracking-[0.22em] text-gold-300">Common mistakes</div>
          <ul className="space-y-1.5 text-sm text-cream-200">
            {ex.commonMistakes.map((s, i) => (
              <li key={i} className="flex gap-2">
                <span className="text-forge-ruby">×</span>
                <span>{s}</span>
              </li>
            ))}
          </ul>
        </div>

        <div className="card p-5">
          <div className="mb-3 text-[10px] uppercase tracking-[0.22em] text-gold-300">Alternatives</div>
          <div className="flex flex-wrap gap-1.5">
            {ex.alternatives.map((id) => (
              <span key={id} className="chip">{id.replace(/-/g, " ")}</span>
            ))}
          </div>
        </div>
      </div>

      {/* Anatomy / placeholder svg */}
      <div className="card p-5">
        <div className="mb-3 text-[10px] uppercase tracking-[0.22em] text-gold-300">Muscle anatomy</div>
        <AnatomySvg highlight={ex.primaryMuscles} />
      </div>
    </div>
  );
}

function Field({ label, value }: { label: string; value: string }) {
  return (
    <div>
      <div className="text-[10px] uppercase tracking-[0.16em] text-obsidian-200">{label}</div>
      <div className="mt-1 text-sm text-cream-100">{value}</div>
    </div>
  );
}

function AnatomySvg({ highlight }: { highlight: string[] }) {
  const isOn = (m: string) =>
    highlight.some((h) => h.toLowerCase().includes(m.toLowerCase()));

  const on = "#d4af37";
  const off = "rgba(212,175,55,0.1)";

  return (
    <svg viewBox="0 0 200 320" className="mx-auto h-72">
      {/* Body silhouette */}
      <path
        d="M100 20 c14 0 24 12 24 26 c0 14 -10 24 -24 24 c-14 0 -24 -10 -24 -24 c0 -14 10 -26 24 -26 z"
        fill="rgba(212,175,55,0.06)"
        stroke="rgba(212,175,55,0.2)"
      />
      {/* Chest */}
      <rect x="68" y="70" width="64" height="40" rx="14"
        fill={isOn("Chest") ? on : off} stroke="rgba(212,175,55,0.2)" opacity={isOn("Chest") ? 0.8 : 0.5} />
      {/* Shoulders / Delts */}
      <circle cx="62" cy="80" r="14" fill={isOn("Delt") || isOn("Shoulder") ? on : off} opacity="0.8" />
      <circle cx="138" cy="80" r="14" fill={isOn("Delt") || isOn("Shoulder") ? on : off} opacity="0.8" />
      {/* Back markers (visible through transparency) */}
      <rect x="74" y="74" width="52" height="36" rx="12"
        fill={isOn("Back") || isOn("Lat") ? on : off} opacity={isOn("Back") || isOn("Lat") ? 0.5 : 0.3} />
      {/* Biceps */}
      <ellipse cx="48" cy="118" rx="10" ry="22" fill={isOn("Biceps") ? on : off} opacity="0.8" />
      <ellipse cx="152" cy="118" rx="10" ry="22" fill={isOn("Biceps") ? on : off} opacity="0.8" />
      {/* Triceps overlay */}
      <ellipse cx="46" cy="116" rx="6" ry="20" fill={isOn("Triceps") ? on : off} opacity="0.7" />
      <ellipse cx="154" cy="116" rx="6" ry="20" fill={isOn("Triceps") ? on : off} opacity="0.7" />
      {/* Core */}
      <rect x="80" y="110" width="40" height="50" rx="6"
        fill={isOn("Core") || isOn("Erector") ? on : off} opacity="0.8" />
      {/* Glutes */}
      <ellipse cx="100" cy="170" rx="32" ry="14"
        fill={isOn("Glutes") ? on : off} opacity="0.8" />
      {/* Quads */}
      <rect x="74" y="184" width="22" height="64" rx="10"
        fill={isOn("Quads") ? on : off} opacity="0.8" />
      <rect x="104" y="184" width="22" height="64" rx="10"
        fill={isOn("Quads") ? on : off} opacity="0.8" />
      {/* Hamstrings overlay */}
      <rect x="74" y="192" width="22" height="56" rx="10"
        fill={isOn("Hamstring") ? on : off} opacity="0.6" />
      <rect x="104" y="192" width="22" height="56" rx="10"
        fill={isOn("Hamstring") ? on : off} opacity="0.6" />
      {/* Calves */}
      <rect x="78" y="254" width="16" height="42" rx="6"
        fill={isOn("Calves") || isOn("Calf") ? on : off} opacity="0.8" />
      <rect x="106" y="254" width="16" height="42" rx="6"
        fill={isOn("Calves") || isOn("Calf") ? on : off} opacity="0.8" />
    </svg>
  );
}
