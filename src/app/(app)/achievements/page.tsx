import { SectionTitle } from "@/components/ui/SectionTitle";
import { Bar } from "@/components/ui/Bar";
import { badges, missions } from "@/lib/mock/social";
import { user } from "@/lib/mock/user";

export default function AchievementsPage() {
  return (
    <div className="space-y-6">
      <SectionTitle
        eyebrow="Community"
        title="XP · Badges · Missions"
        subtitle="The dopamine layer. Daily missions reward consistency, badges mark milestones."
      />

      {/* Level / XP */}
      <div className="card card-gold p-6">
        <div className="flex flex-wrap items-baseline justify-between gap-3">
          <div>
            <div className="text-[10px] uppercase tracking-[0.22em] text-gold-300">Level</div>
            <div className="display mt-1 text-5xl text-gold-grad">Lv {user.level}</div>
          </div>
          <div className="flex-1 max-w-md">
            <div className="mb-1 flex justify-between text-[11px] text-obsidian-200">
              <span>{user.xp.toLocaleString()} XP</span>
              <span>{user.xpToNext.toLocaleString()} XP · Lv {user.level + 1}</span>
            </div>
            <Bar value={user.xp} max={user.xpToNext} tone="gold" height={10} />
          </div>
          <div className="text-right">
            <div className="text-[10px] uppercase tracking-[0.22em] text-gold-300">Streak</div>
            <div className="display mt-1 text-3xl text-cream-50">🔥 {user.streakDays}</div>
          </div>
        </div>
      </div>

      {/* Daily missions */}
      <div className="card p-6">
        <div className="display mb-3 text-xl text-cream-50">Today's missions</div>
        <div className="space-y-3">
          {missions.map((m, i) => (
            <div
              key={i}
              className={`rounded-md border p-3 ${m.done ? "border-forge-green/30 bg-forge-green/5" : "border-gold-400/10 bg-obsidian-800/40"}`}
            >
              <div className="mb-1 flex items-baseline justify-between">
                <div className="text-sm text-cream-100">{m.name}</div>
                <span className={m.done ? "chip chip-green" : "chip chip-gold"}>+{m.xp} XP</span>
              </div>
              <Bar value={m.progress} max={m.total} tone={m.done ? "green" : "gold"} height={3} />
              <div className="mt-1 text-[11px] text-obsidian-200">{m.progress} / {m.total}</div>
            </div>
          ))}
        </div>
      </div>

      {/* Badges */}
      <div className="card p-6">
        <div className="display mb-3 text-xl text-cream-50">Badges</div>
        <div className="grid gap-3 sm:grid-cols-3 lg:grid-cols-4">
          {badges.map((b) => (
            <div
              key={b.name}
              className={`rounded-lg border p-4 text-center ${b.earned ? "border-gold-400/30 bg-gold-400/5" : "border-gold-400/8 bg-obsidian-800/40 opacity-70"}`}
            >
              <div className={`mx-auto grid h-14 w-14 place-items-center rounded-full text-2xl ${b.earned ? "bg-gold-gradient text-obsidian-900" : "border border-gold-400/15 text-obsidian-300"}`}>
                {b.earned ? "★" : "○"}
              </div>
              <div className={`mt-2 text-sm ${b.earned ? "text-cream-50" : "text-obsidian-200"}`}>{b.name}</div>
              <div className="mt-1 text-[10px] text-obsidian-300">{b.desc}</div>
              {b.earned && b.when && <div className="mt-1 text-[10px] text-gold-300">{b.when}</div>}
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}
