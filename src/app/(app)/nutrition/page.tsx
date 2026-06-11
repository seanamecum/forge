"use client";

import { useState } from "react";
import Link from "next/link";
import { SectionTitle } from "@/components/ui/SectionTitle";
import { Bar } from "@/components/ui/Bar";
import { foodDb, todaysMeals, savedMeals, micronutrientMatrix } from "@/lib/mock/nutrition";
import { today, user } from "@/lib/mock/user";

export default function NutritionPage() {
  const [q, setQ] = useState("");

  const filtered = foodDb.filter(
    (f) =>
      f.name.toLowerCase().includes(q.toLowerCase()) ||
      (f.brand?.toLowerCase().includes(q.toLowerCase()) ?? false)
  );

  return (
    <div className="space-y-6">
      <SectionTitle
        eyebrow="Fuel"
        title="Nutrition"
        subtitle="Macros, micros, hydration. 13 vitamins, 13 minerals, omega-3, EAAs — tracked, scored, and actionable."
        right={
          <div className="flex gap-2">
            <Link href="/deficiencies" className="btn-ghost text-xs">
              ▼ Deficiencies
            </Link>
            <button className="btn-gold text-xs">+ Log meal</button>
          </div>
        }
      />

      {/* Today's totals */}
      <div className="grid gap-4 lg:grid-cols-4">
        <div className="card card-gold col-span-1 p-5 lg:col-span-2">
          <div className="text-[10px] uppercase tracking-[0.22em] text-gold-300">Today · {today.date}</div>
          <div className="mt-2 flex items-baseline gap-3">
            <span className="stat-num text-5xl text-cream-50">{today.caloriesIn}</span>
            <span className="text-sm text-obsidian-200">/ {user.targets.calories} kcal</span>
            <span className="ml-auto chip chip-gold">{today.caloriesRemaining} left</span>
          </div>
          <div className="mt-4 space-y-3">
            <Bar label="Protein" rightLabel={`${today.proteinIn} / ${user.targets.protein} g`} value={today.proteinIn} max={user.targets.protein} tone="gold" />
            <Bar label="Carbs" rightLabel={`${today.carbsIn} / ${user.targets.carbs} g`} value={today.carbsIn} max={user.targets.carbs} tone="green" />
            <Bar label="Fat" rightLabel={`${today.fatIn} / ${user.targets.fat} g`} value={today.fatIn} max={user.targets.fat} tone="amber" />
            <Bar label="Water" rightLabel={`${today.waterMl} / ${user.targets.waterMl} mL`} value={today.waterMl} max={user.targets.waterMl} tone="royal" />
          </div>
        </div>

        {/* Quick-log tools */}
        <div className="card p-5">
          <div className="text-[10px] uppercase tracking-[0.22em] text-gold-300">Quick log</div>
          <button className="mt-2 flex w-full items-center gap-3 rounded-md border border-gold-400/12 bg-obsidian-800/50 p-3 text-left hover:border-gold-400/40">
            <span className="grid h-10 w-10 place-items-center rounded-md border border-gold-400/30 bg-gold-400/5 text-gold-300">▢</span>
            <div>
              <div className="text-sm text-cream-50">Scan barcode</div>
              <div className="text-[11px] text-obsidian-200">Point at the label</div>
            </div>
          </button>
          <button className="mt-2 flex w-full items-center gap-3 rounded-md border border-gold-400/12 bg-obsidian-800/50 p-3 text-left hover:border-gold-400/40">
            <span className="grid h-10 w-10 place-items-center rounded-md border border-gold-400/30 bg-gold-400/5 text-gold-300">◉</span>
            <div>
              <div className="text-sm text-cream-50">Photo recognition</div>
              <div className="text-[11px] text-obsidian-200">AI estimates the plate</div>
            </div>
          </button>
          <button className="mt-2 flex w-full items-center gap-3 rounded-md border border-gold-400/12 bg-obsidian-800/50 p-3 text-left hover:border-gold-400/40">
            <span className="grid h-10 w-10 place-items-center rounded-md border border-gold-400/30 bg-gold-400/5 text-gold-300">❉</span>
            <div>
              <div className="text-sm text-cream-50">From saved meal</div>
              <div className="text-[11px] text-obsidian-200">{savedMeals.length} meals saved</div>
            </div>
          </button>
        </div>

        <div className="card p-5">
          <div className="text-[10px] uppercase tracking-[0.22em] text-gold-300">Saved meals</div>
          <div className="mt-3 space-y-1.5">
            {savedMeals.map((m) => (
              <div key={m.id} className="flex items-baseline justify-between rounded-md bg-obsidian-800/30 px-3 py-1.5">
                <div>
                  <div className="text-[13px] text-cream-100">{m.name}</div>
                  <div className="text-[11px] text-obsidian-200">{m.protein}p · {m.carbs}c · {m.fat}f</div>
                </div>
                <div className="text-sm text-gold-grad">{m.calories}</div>
              </div>
            ))}
          </div>
        </div>
      </div>

      {/* Today's meals */}
      <div className="card p-6">
        <div className="mb-4 flex items-center justify-between">
          <div className="display text-xl text-cream-50">Today's meals</div>
          <button className="btn-ghost text-xs">+ Add meal</button>
        </div>
        <div className="space-y-3">
          {todaysMeals.map((m) => {
            const items = m.items.map((i) => ({ ...foodDb.find((f) => f.id === i.foodId)!, servings: i.servings }));
            const cal = items.reduce((s, i) => s + i.calories * i.servings, 0);
            const prot = items.reduce((s, i) => s + i.protein * i.servings, 0);
            return (
              <div key={m.id} className="rounded-md border border-gold-400/10 bg-obsidian-800/40 p-4">
                <div className="mb-2 flex flex-wrap items-baseline justify-between gap-2">
                  <div>
                    <div className="text-[10px] uppercase tracking-wider text-gold-300">
                      {m.meal} · {m.time}
                    </div>
                    <div className="mt-0.5 text-sm text-cream-100">{items.map((i) => i.name).join(" · ")}</div>
                  </div>
                  <div className="text-[11px] text-obsidian-200">
                    <span className="text-cream-100">{Math.round(cal)}</span> kcal · {Math.round(prot)} g protein
                  </div>
                </div>
              </div>
            );
          })}
        </div>
      </div>

      {/* Food search */}
      <div className="card p-6">
        <div className="mb-3 flex items-center justify-between">
          <div className="display text-xl text-cream-50">Food database</div>
          <input
            value={q}
            onChange={(e) => setQ(e.target.value)}
            placeholder="Search foods…"
            className="input max-w-xs"
          />
        </div>
        <div className="grid gap-2 sm:grid-cols-2 lg:grid-cols-3">
          {filtered.slice(0, 12).map((f) => (
            <div key={f.id} className="rounded-md border border-gold-400/8 bg-obsidian-800/40 p-3">
              <div className="flex items-baseline justify-between">
                <div>
                  <div className="text-sm text-cream-100">{f.name}</div>
                  <div className="text-[11px] text-obsidian-200">
                    {f.brand && `${f.brand} · `}{f.serving}
                  </div>
                </div>
                <div className="text-sm text-gold-grad">{f.calories}</div>
              </div>
              <div className="mt-2 grid grid-cols-3 gap-2 text-[11px] text-obsidian-200">
                <span>P {f.protein}</span>
                <span>C {f.carbs}</span>
                <span>F {f.fat}</span>
              </div>
            </div>
          ))}
        </div>
      </div>

      {/* Micros */}
      <div className="card p-6">
        <div className="mb-4 flex items-baseline justify-between">
          <div className="display text-xl text-cream-50">Micronutrients · 7-day avg</div>
          <Link href="/deficiencies" className="btn-ghost text-xs">View deficiencies →</Link>
        </div>
        <div className="grid gap-6 lg:grid-cols-3">
          {micronutrientMatrix.map((g) => (
            <div key={g.group}>
              <div className="mb-2 text-[10px] uppercase tracking-[0.22em] text-gold-300">{g.group}</div>
              <div className="space-y-1.5">
                {g.items.map((i) => (
                  <div key={i.name}>
                    <div className="mb-0.5 flex items-baseline justify-between text-xs">
                      <span className="text-cream-200">{i.name}</span>
                      <span className={i.pct < 60 ? "text-forge-ruby" : i.pct < 90 ? "text-forge-amber" : i.pct > 150 ? "text-gold-300" : "text-forge-green"}>
                        {i.pct}%
                      </span>
                    </div>
                    <Bar
                      value={Math.min(i.pct, 150)}
                      max={150}
                      height={3}
                      tone={i.pct < 60 ? "ruby" : i.pct < 90 ? "amber" : i.pct > 150 ? "gold" : "green"}
                    />
                  </div>
                ))}
              </div>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}
