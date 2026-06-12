"use client";

import { SectionTitle } from "@/components/ui/SectionTitle";
import { supplements } from "@/lib/mock/supplements";
import { useForge } from "@/lib/store";
import { toast } from "@/lib/toast";

export default function SupplementsPage() {
  const forge = useForge();

  return (
    <div className="space-y-6">
      <SectionTitle
        eyebrow="Fuel · Stack"
        title="Supplements"
        subtitle="Log your stack. Streaks reinforce consistency. Forge connects supplement gaps to fatigue, sleep, and HRV trends."
      />

      <div className="grid gap-3 sm:grid-cols-2 lg:grid-cols-3">
        {supplements.map((s) => {
          const logged = forge.suppLogged(s.id, s.loggedToday);
          const streak = s.streak + (logged !== s.loggedToday ? (logged ? 1 : -1) : 0);
          return (
            <div key={s.id} className="card p-5">
              <div className="mb-2 flex items-start justify-between gap-2">
                <div>
                  <div className="display text-lg text-cream-50">{s.name}</div>
                  <div className="mt-0.5 text-[12px] text-obsidian-200">{s.dose} · {s.timing}</div>
                </div>
                <span className={`chip ${logged ? "chip-green" : "chip-amber"}`}>
                  {logged ? "Today ✓" : "Pending"}
                </span>
              </div>
              <div className="mt-2 text-[12px] text-cream-200">{s.benefit}</div>
              <div className="mt-3 flex items-center justify-between">
                <div className="text-[11px] text-obsidian-200">
                  Streak <span className="text-gold-grad">🔥 {streak}</span>
                </div>
                <button
                  onClick={() => {
                    forge.toggleSupp(s.id, s.loggedToday);
                    toast(logged ? `${s.name} unlogged` : `${s.name} logged · 🔥 streak ${streak + 1}`);
                  }}
                  className={logged ? "btn-quiet" : "btn-gold text-[11px] !py-1.5"}
                >
                  {logged ? "Unlog" : "Log"}
                </button>
              </div>
            </div>
          );
        })}
      </div>
    </div>
  );
}
