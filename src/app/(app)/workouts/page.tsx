import Link from "next/link";
import { SectionTitle } from "@/components/ui/SectionTitle";
import { Stat } from "@/components/ui/Stat";
import { Bar } from "@/components/ui/Bar";
import { Sparkline, Barline } from "@/components/ui/Sparkline";
import {
  todaysWorkout,
  workoutHistory,
  volumeByMuscle,
  prHistory,
} from "@/lib/mock/workouts";
import { weightTrend } from "@/lib/mock/user";

export default function WorkoutsPage() {
  return (
    <div className="space-y-6">
      <SectionTitle
        eyebrow="Train"
        title="Workouts"
        subtitle="Log, history, volume, PRs, and today's session — tuned by Forge for your current recovery."
        right={
          <Link href="/generate" className="btn-gold shrink-0 whitespace-nowrap">
            ✺ Generate
          </Link>
        }
      />

      {/* Top: Today's workout */}
      <div className="card card-gold p-6">
        <div className="mb-4 flex flex-wrap items-start justify-between gap-3">
          <div>
            <div className="text-[10px] uppercase tracking-[0.22em] text-gold-300">Today's Session</div>
            <h3 className="display mt-1 text-2xl text-cream-50">{todaysWorkout.name}</h3>
            <p className="mt-1 text-sm text-obsidian-200">
              {todaysWorkout.exercises.length} exercises · ~{todaysWorkout.durationMin} min
            </p>
          </div>
          <div className="flex gap-2">
            <span className="chip chip-gold">Auto-deloaded 12%</span>
            <span className="chip chip-amber">Shoulder safe</span>
          </div>
        </div>

        <div className="mb-4 rounded-md border border-gold-400/15 bg-gold-400/5 p-3 text-[13px] text-cream-200">
          <span className="text-gold-200">Forge built this for you:</span> {todaysWorkout.reason}
        </div>

        <div className="space-y-2">
          {todaysWorkout.exercises.map((ex, i) => (
            <div
              key={i}
              className="rounded-md border border-gold-400/10 bg-obsidian-800/50 p-4 transition hover:border-gold-400/30"
            >
              <div className="flex items-start justify-between gap-3">
                <div className="flex items-start gap-3">
                  <span className="grid h-7 w-7 shrink-0 place-items-center rounded-full border border-gold-400/30 bg-obsidian-900 text-xs text-gold-300">
                    {i + 1}
                  </span>
                  <div>
                    <div className="text-sm text-cream-50">{ex.name}</div>
                    <div className="mt-0.5 text-[12px] text-obsidian-200">
                      {ex.prescription}
                    </div>
                    <div className="mt-2 text-[11px] text-gold-200/80">
                      ✦ {ex.reasoning}
                    </div>
                  </div>
                </div>
                <button className="btn-quiet">Start ▶</button>
              </div>
            </div>
          ))}
        </div>

        <div className="mt-5 flex flex-wrap gap-2">
          <Link href="/workouts/log" className="btn-gold">Start logging</Link>
          <button className="btn-ghost">Swap exercises</button>
          <button className="btn-ghost">Add warm-up</button>
        </div>
      </div>

      {/* Weekly stats */}
      <div className="grid gap-4 lg:grid-cols-4">
        <StatCard title="Sessions / wk" value="5" sub="this week · target 5" />
        <StatCard title="Total volume" value="42,180" unit="kg" sub="-3% vs 4-wk avg (deload)" />
        <StatCard title="Avg RPE" value="8.1" sub="last 7 sessions" />
        <StatCard title="Strain" value="18.6" sub="yesterday · high" />
      </div>

      {/* Volume by muscle + PRs + history */}
      <div className="grid gap-4 lg:grid-cols-3">
        <div className="card p-5">
          <div className="mb-3 flex items-center justify-between">
            <div className="text-[10px] uppercase tracking-[0.22em] text-gold-300">Volume by muscle · 7d</div>
            <span className="chip">target zones gold</span>
          </div>
          <div className="space-y-2">
            {volumeByMuscle.map((m) => {
              const inOptimal = m.sets >= m.optimal[0] && m.sets <= m.optimal[1];
              return (
                <div key={m.muscle}>
                  <div className="mb-1 flex items-baseline justify-between text-xs">
                    <span className="text-cream-200">{m.muscle}</span>
                    <span className={inOptimal ? "text-forge-green" : "text-forge-amber"}>
                      {m.sets} · {m.optimal[0]}–{m.optimal[1]}
                    </span>
                  </div>
                  <Bar value={m.sets} max={24} height={4} tone={inOptimal ? "green" : "amber"} />
                </div>
              );
            })}
          </div>
        </div>

        <div className="card p-5">
          <div className="mb-3 text-[10px] uppercase tracking-[0.22em] text-gold-300">Personal records</div>
          <div className="space-y-2">
            {prHistory.map((p) => (
              <div
                key={p.exercise}
                className="flex items-center justify-between rounded-md border border-gold-400/10 bg-obsidian-800/50 px-3 py-2"
              >
                <div>
                  <div className="text-sm text-cream-100">{p.exercise}</div>
                  <div className="text-[11px] text-obsidian-200">{p.date}</div>
                </div>
                <div className="stat-num text-xl text-gold-grad">{p.weightKg}<span className="text-xs ml-1 text-obsidian-200">kg</span></div>
              </div>
            ))}
          </div>
        </div>

        <div className="card p-5">
          <div className="mb-3 flex items-center justify-between">
            <div className="text-[10px] uppercase tracking-[0.22em] text-gold-300">Body weight · 14d</div>
            <span className="chip chip-green">−2.8 kg</span>
          </div>
          <Sparkline data={weightTrend} width={280} height={80} />
          <div className="hairline my-4" />
          <div className="text-[10px] uppercase tracking-[0.18em] text-obsidian-200">Strain · 14d</div>
          <div className="mt-2">
            <Barline data={[13, 14, 17, 9, 16, 19, 18, 12, 14, 17, 19, 13, 15, 17]} width={280} height={48} />
          </div>
        </div>
      </div>

      {/* History */}
      <div className="card p-5">
        <div className="mb-4 flex items-center justify-between">
          <div className="display text-xl text-cream-50">Recent sessions</div>
          <Link href="/workouts/log" className="btn-ghost">+ Log session</Link>
        </div>
        <div className="space-y-3">
          {workoutHistory.map((w) => (
            <div
              key={w.id}
              className="rounded-md border border-gold-400/10 bg-obsidian-800/50 p-4"
            >
              <div className="mb-2 flex flex-wrap items-baseline justify-between gap-2">
                <div>
                  <div className="text-sm text-cream-50">{w.name}</div>
                  <div className="text-[11px] text-obsidian-200">
                    {w.date} · {w.durationMin} min · RPE {w.rpeAvg} · strain {w.strain} · felt {w.feel}
                  </div>
                </div>
                <div className="text-[11px] text-gold-200">
                  Volume {w.totalVolumeKg.toLocaleString()} kg
                </div>
              </div>
              <div className="space-y-1">
                {w.exercises.map((ex, i) => (
                  <div
                    key={i}
                    className="flex items-baseline justify-between text-[12px] text-cream-200"
                  >
                    <span>{ex.name}</span>
                    <span className="text-obsidian-200">
                      {ex.sets
                        .map((s) =>
                          s.weightKg
                            ? `${s.weightKg}×${s.reps}${s.rpe ? `@${s.rpe}` : ""}${s.isPr ? " ★" : ""}`
                            : `${s.reps}r`
                        )
                        .join(" · ")}
                    </span>
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

function StatCard({
  title,
  value,
  unit,
  sub,
}: {
  title: string;
  value: string;
  unit?: string;
  sub?: string;
}) {
  return (
    <div className="card p-5">
      <div className="text-[10px] uppercase tracking-[0.22em] text-gold-300">{title}</div>
      <div className="mt-1 flex items-baseline gap-1.5">
        <span className="stat-num text-3xl text-cream-50">{value}</span>
        {unit && <span className="text-xs text-obsidian-200">{unit}</span>}
      </div>
      {sub && <div className="mt-1 text-[11px] text-obsidian-200">{sub}</div>}
    </div>
  );
}
