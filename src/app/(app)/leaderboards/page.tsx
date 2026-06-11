import { SectionTitle } from "@/components/ui/SectionTitle";
import { leaderboards } from "@/lib/mock/social";

const TABS: { key: keyof typeof leaderboards; label: string; subtitle: string }[] = [
  { key: "steps", label: "Steps · This Week", subtitle: "Total steps logged" },
  { key: "strength", label: "Strength · Wilks", subtitle: "Bodyweight-relative total" },
  { key: "streak", label: "Streak", subtitle: "Consecutive training days" },
  { key: "protein", label: "Protein Consistency", subtitle: "% of days hitting target" },
];

export default function LeaderboardsPage() {
  return (
    <div className="space-y-6">
      <SectionTitle
        eyebrow="Community"
        title="Leaderboards"
        subtitle="Steps, strength, streak, protein. Compare with friends or the global cohort."
      />

      <div className="grid gap-4 lg:grid-cols-2">
        {TABS.map((t) => (
          <div key={t.key} className="card p-5">
            <div className="mb-3 flex items-baseline justify-between">
              <div>
                <div className="text-[10px] uppercase tracking-[0.22em] text-gold-300">{t.label}</div>
                <div className="text-[11px] text-obsidian-200">{t.subtitle}</div>
              </div>
              <span className="chip chip-gold">Global · Top 5</span>
            </div>
            <div className="space-y-1">
              {leaderboards[t.key].map((r) => (
                <div
                  key={r.rank}
                  className={`flex items-center justify-between rounded-md px-3 py-2 ${
                    r.highlight
                      ? "border border-gold-400/40 bg-gold-400/8 text-cream-50"
                      : "bg-obsidian-800/40 text-cream-200"
                  }`}
                >
                  <div className="flex items-center gap-3">
                    <span className={`grid h-7 w-7 place-items-center rounded-full text-[12px] ${r.rank <= 3 ? "bg-gold-gradient text-obsidian-900" : "border border-gold-400/20 text-obsidian-200"}`}>
                      {r.rank}
                    </span>
                    <span className="text-sm">{r.name}</span>
                  </div>
                  <span className={r.highlight ? "stat-num text-gold-grad" : "text-sm"}>{r.value}</span>
                </div>
              ))}
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}
