"use client";

import { useEffect, useState } from "react";
import Link from "next/link";
import { SectionTitle } from "@/components/ui/SectionTitle";
import { Bar } from "@/components/ui/Bar";
import { foodDb, todaysMeals, savedMeals, micronutrientMatrix, Food } from "@/lib/mock/nutrition";
import { today, user } from "@/lib/mock/user";
import { useForge } from "@/lib/store";
import { toast } from "@/lib/toast";

type Modal = null | "search" | "barcode" | "photo";

export default function NutritionPage() {
  const forge = useForge();
  const [q, setQ] = useState("");
  const [modal, setModal] = useState<Modal>(null);
  const [pickedMeal, setPickedMeal] = useState("snack");

  const extraCal = forge.meals.reduce((s, m) => s + m.calories, 0);
  const extraPro = forge.meals.reduce((s, m) => s + m.protein, 0);
  const calIn = today.caloriesIn + extraCal;
  const proIn = today.proteinIn + Math.round(extraPro);

  const filtered = foodDb.filter(
    (f) =>
      f.name.toLowerCase().includes(q.toLowerCase()) ||
      (f.brand?.toLowerCase().includes(q.toLowerCase()) ?? false)
  );

  function logFood(f: Food, meal = pickedMeal) {
    forge.addMeal({ meal, name: f.name, calories: f.calories, protein: f.protein, time: "now" });
    toast(`${f.name} logged · +${f.calories} kcal · +${Math.round(f.protein)} g protein`);
    setModal(null);
  }

  return (
    <div className="space-y-6">
      <SectionTitle
        eyebrow="Fuel"
        title="Nutrition"
        subtitle="Macros, micros, hydration. 13 vitamins, 13 minerals, omega-3, EAAs — tracked, scored, and actionable."
        right={
          <div className="flex gap-2">
            <Link href="/deficiencies" className="btn-ghost text-xs">▼ Deficiencies</Link>
            <button className="btn-gold text-xs" onClick={() => { setPickedMeal("dinner"); setModal("search"); }}>
              + Log meal
            </button>
          </div>
        }
      />

      <div className="grid gap-4 lg:grid-cols-4">
        <div className="card card-gold col-span-1 p-5 lg:col-span-2">
          <div className="text-[10px] uppercase tracking-[0.22em] text-gold-300">Today · {today.date}</div>
          <div className="mt-2 flex items-baseline gap-3">
            <span className="stat-num text-5xl text-cream-50">{calIn}</span>
            <span className="text-sm text-obsidian-200">/ {user.targets.calories} kcal</span>
            <span className="ml-auto chip chip-gold">{Math.max(0, user.targets.calories - calIn)} left</span>
          </div>
          <div className="mt-4 space-y-3">
            <Bar label="Protein" rightLabel={`${proIn} / ${user.targets.protein} g`} value={proIn} max={user.targets.protein} tone="gold" />
            <Bar label="Carbs" rightLabel={`${today.carbsIn} / ${user.targets.carbs} g`} value={today.carbsIn} max={user.targets.carbs} tone="green" />
            <Bar label="Fat" rightLabel={`${today.fatIn} / ${user.targets.fat} g`} value={today.fatIn} max={user.targets.fat} tone="amber" />
            <Bar label="Water" rightLabel={`${forge.waterMl} / ${user.targets.waterMl} mL`} value={forge.waterMl} max={user.targets.waterMl} tone="royal" />
          </div>
          <div className="mt-4 flex flex-wrap items-center gap-2">
            {[250, 500, 750].map((ml) => (
              <button
                key={ml}
                className="btn-ghost !py-1.5 text-[11px]"
                onClick={() => { forge.addWater(ml); toast(`+${ml} mL water · ${Math.round(((forge.waterMl + ml) / user.targets.waterMl) * 100)}% of target`); }}
              >
                +{ml} mL
              </button>
            ))}
            <span className="ml-auto text-[11px] text-obsidian-200">
              hydration {Math.round((forge.waterMl / user.targets.waterMl) * 100)}%
            </span>
          </div>
        </div>

        <div className="card p-5">
          <div className="text-[10px] uppercase tracking-[0.22em] text-gold-300">Quick log</div>
          <QuickTool icon="▢" title="Scan barcode" sub="Point at the label" onClick={() => setModal("barcode")} />
          <QuickTool icon="◉" title="Photo recognition" sub="AI estimates the plate" onClick={() => setModal("photo")} />
          <QuickTool icon="❉" title="Search the database" sub={`${foodDb.length} foods`} onClick={() => { setPickedMeal("snack"); setModal("search"); }} />
        </div>

        <div className="card p-5">
          <div className="text-[10px] uppercase tracking-[0.22em] text-gold-300">Saved meals</div>
          <div className="mt-3 space-y-1.5">
            {savedMeals.map((m) => (
              <button
                key={m.id}
                onClick={() => {
                  forge.addMeal({ meal: "snack", name: m.name, calories: m.calories, protein: m.protein, time: "now" });
                  toast(`${m.name} logged · +${m.calories} kcal · +${m.protein} g protein`);
                }}
                className="flex w-full items-baseline justify-between rounded-md bg-obsidian-800/30 px-3 py-1.5 text-left hover:bg-gold-400/8"
              >
                <div>
                  <div className="text-[13px] text-cream-100">{m.name}</div>
                  <div className="text-[11px] text-obsidian-200">{m.protein}p · {m.carbs}c · {m.fat}f</div>
                </div>
                <div className="text-sm text-gold-grad">{m.calories}</div>
              </button>
            ))}
          </div>
        </div>
      </div>

      {/* Today's meals */}
      <div className="card p-6">
        <div className="mb-4 flex items-center justify-between">
          <div className="display text-xl text-cream-50">Today's meals</div>
          <button className="btn-ghost text-xs" onClick={() => { setPickedMeal("dinner"); setModal("search"); }}>+ Add meal</button>
        </div>
        <div className="space-y-3">
          {todaysMeals.map((m) => {
            const items = m.items.map((i) => ({ ...foodDb.find((f) => f.id === i.foodId)!, servings: i.servings }));
            const cal = items.reduce((s, i) => s + i.calories * i.servings, 0);
            const prot = items.reduce((s, i) => s + i.protein * i.servings, 0);
            return (
              <MealRow key={m.id} title={`${m.meal} · ${m.time}`} desc={items.map((i) => i.name).join(" · ")} cal={Math.round(cal)} prot={Math.round(prot)} />
            );
          })}
          {forge.meals.map((m, i) => (
            <MealRow key={`x-${i}`} title={`${m.meal} · ${m.time}`} desc={m.name} cal={m.calories} prot={Math.round(m.protein)} fresh />
          ))}
        </div>
      </div>

      {/* Food search inline */}
      <div className="card p-6">
        <div className="mb-3 flex items-center justify-between">
          <div className="display text-xl text-cream-50">Food database</div>
          <input value={q} onChange={(e) => setQ(e.target.value)} placeholder="Search foods…" className="input max-w-xs" />
        </div>
        <div className="grid gap-2 sm:grid-cols-2 lg:grid-cols-3">
          {filtered.slice(0, 12).map((f) => (
            <button key={f.id} onClick={() => logFood(f, "snack")} className="rounded-md border border-gold-400/8 bg-obsidian-800/40 p-3 text-left transition hover:border-gold-400/40">
              <div className="flex items-baseline justify-between">
                <div>
                  <div className="text-sm text-cream-100">{f.name}</div>
                  <div className="text-[11px] text-obsidian-200">{f.brand && `${f.brand} · `}{f.serving}</div>
                </div>
                <div className="text-sm text-gold-grad">{f.calories}</div>
              </div>
              <div className="mt-2 flex items-center justify-between text-[11px] text-obsidian-200">
                <span>P {f.protein} · C {f.carbs} · F {f.fat}</span>
                <span className="text-gold-300">+ log</span>
              </div>
            </button>
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
                    <Bar value={Math.min(i.pct, 150)} max={150} height={3}
                         tone={i.pct < 60 ? "ruby" : i.pct < 90 ? "amber" : i.pct > 150 ? "gold" : "green"} />
                  </div>
                ))}
              </div>
            </div>
          ))}
        </div>
      </div>

      {modal === "search" && (
        <Overlay onClose={() => setModal(null)} title="Log a meal">
          <div className="mb-3 flex flex-wrap gap-1.5">
            {["breakfast", "lunch", "dinner", "snack", "pre", "post"].map((m) => (
              <button key={m} onClick={() => setPickedMeal(m)}
                className={`rounded-full border px-3 py-1 text-[11px] capitalize ${pickedMeal === m ? "border-gold-400/50 bg-gold-400/10 text-gold-200" : "border-gold-400/10 text-cream-200"}`}>
                {m}
              </button>
            ))}
          </div>
          <div className="max-h-[50vh] space-y-1.5 overflow-y-auto pr-1">
            {foodDb.map((f) => (
              <button key={f.id} onClick={() => logFood(f)} className="flex w-full items-baseline justify-between rounded-md border border-gold-400/8 bg-obsidian-800/50 px-3 py-2 text-left hover:border-gold-400/40">
                <span className="text-sm text-cream-100">{f.name} <span className="text-[10px] text-obsidian-300">{f.serving}</span></span>
                <span className="text-sm text-gold-grad">{f.calories}</span>
              </button>
            ))}
          </div>
        </Overlay>
      )}

      {modal === "barcode" && (
        <SimSheet
          onClose={() => setModal(null)}
          icon="▢"
          title="Barcode Scanner"
          found="Whey Isolate — Ascent · 1 scoop"
          detail="120 kcal · 25 P · 2 C · 1 F"
          onAdd={() => logFood(foodDb.find((f) => f.id === "f6")!, "snack")}
        />
      )}
      {modal === "photo" && (
        <SimSheet
          onClose={() => setModal(null)}
          icon="◉"
          title="Photo Recognition"
          found="Detected: chicken breast, brown rice, broccoli"
          detail="~620 kcal · 70 P · 60 C · 11 F · confidence 92%"
          onAdd={() => {
            forge.addMeal({ meal: "dinner", name: "Photo: chicken, rice, broccoli", calories: 620, protein: 70, time: "now" });
            toast("Plate logged from photo · +620 kcal · +70 g protein");
            setModal(null);
          }}
        />
      )}
    </div>
  );
}

function QuickTool({ icon, title, sub, onClick }: { icon: string; title: string; sub: string; onClick: () => void }) {
  return (
    <button onClick={onClick} className="mt-2 flex w-full items-center gap-3 rounded-md border border-gold-400/12 bg-obsidian-800/50 p-3 text-left hover:border-gold-400/40">
      <span className="grid h-10 w-10 place-items-center rounded-md border border-gold-400/30 bg-gold-400/5 text-gold-300">{icon}</span>
      <div>
        <div className="text-sm text-cream-50">{title}</div>
        <div className="text-[11px] text-obsidian-200">{sub}</div>
      </div>
    </button>
  );
}

function MealRow({ title, desc, cal, prot, fresh = false }: { title: string; desc: string; cal: number; prot: number; fresh?: boolean }) {
  return (
    <div className={`rounded-md border p-4 ${fresh ? "border-gold-400/30 bg-gold-400/5" : "border-gold-400/10 bg-obsidian-800/40"}`}>
      <div className="flex flex-wrap items-baseline justify-between gap-2">
        <div>
          <div className="text-[10px] uppercase tracking-wider text-gold-300">{title}{fresh && " · just logged"}</div>
          <div className="mt-0.5 text-sm text-cream-100">{desc}</div>
        </div>
        <div className="text-[11px] text-obsidian-200">
          <span className="text-cream-100">{cal}</span> kcal · {prot} g protein
        </div>
      </div>
    </div>
  );
}

function Overlay({ children, onClose, title }: { children: React.ReactNode; onClose: () => void; title: string }) {
  return (
    <div className="fixed inset-0 z-[80] grid place-items-center bg-black/70 p-4 backdrop-blur-sm" onClick={onClose}>
      <div className="card card-gold w-full max-w-md p-5" onClick={(e) => e.stopPropagation()}>
        <div className="mb-3 flex items-center justify-between">
          <div className="display text-xl text-cream-50">{title}</div>
          <button onClick={onClose} className="btn-quiet text-xs">✕ Close</button>
        </div>
        {children}
      </div>
    </div>
  );
}

function SimSheet({ onClose, icon, title, found, detail, onAdd }: {
  onClose: () => void; icon: string; title: string; found: string; detail: string; onAdd: () => void;
}) {
  const [ready, setReady] = useState(false);
  useEffect(() => {
    const t = setTimeout(() => setReady(true), 1200);
    return () => clearTimeout(t);
  }, []);
  return (
    <Overlay onClose={onClose} title={title}>
      <div className="py-4 text-center">
        <div className={`text-4xl ${ready ? "text-forge-green" : "animate-pulse-gold text-gold-300"}`}>{icon}</div>
        {ready ? (
          <>
            <div className="mt-3 text-sm text-cream-100">{found}</div>
            <div className="mt-1 text-[12px] text-obsidian-200">{detail}</div>
            <button className="btn-gold mt-4 w-full" onClick={onAdd}>Add to log</button>
          </>
        ) : (
          <div className="mt-3 text-[11px] uppercase tracking-[0.2em] text-gold-300">Scanning…</div>
        )}
      </div>
    </Overlay>
  );
}
