import { SectionTitle } from "@/components/ui/SectionTitle";
import { supplements } from "@/lib/mock/supplements";

export default function SupplementsPage() {
  return (
    <div className="space-y-6">
      <SectionTitle
        eyebrow="Fuel · Stack"
        title="Supplements"
        subtitle="Log your stack. Streaks reinforce consistency. Forge connects supplement gaps to fatigue, sleep, and HRV trends."
      />

      <div className="grid gap-3 sm:grid-cols-2 lg:grid-cols-3">
        {supplements.map((s) => (
          <div key={s.id} className="card p-5">
            <div className="mb-2 flex items-start justify-between gap-2">
              <div>
                <div className="display text-lg text-cream-50">{s.name}</div>
                <div className="mt-0.5 text-[12px] text-obsidian-200">{s.dose} · {s.timing}</div>
              </div>
              <span className={`chip ${s.loggedToday ? "chip-green" : "chip-amber"}`}>
                {s.loggedToday ? "Today ✓" : "Pending"}
              </span>
            </div>
            <div className="mt-2 text-[12px] text-cream-200">{s.benefit}</div>
            <div className="mt-3 flex items-center justify-between">
              <div className="text-[11px] text-obsidian-200">
                Streak <span className="text-gold-grad">🔥 {s.streak}</span>
              </div>
              <button className={s.loggedToday ? "btn-quiet" : "btn-gold text-[11px] !py-1.5"}>
                {s.loggedToday ? "Logged" : "Log"}
              </button>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}
