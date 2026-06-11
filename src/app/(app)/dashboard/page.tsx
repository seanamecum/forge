import Link from "next/link";
import { Ring } from "@/components/ui/Ring";
import { Sparkline, Barline } from "@/components/ui/Sparkline";
import { Stat } from "@/components/ui/Stat";
import { Bar } from "@/components/ui/Bar";
import {
  today,
  user,
  injuries,
  forgeScoreTrend,
  recoveryTrend,
  hrvTrend,
  sleepTrend,
  forgeScoreBreakdown,
} from "@/lib/mock/user";
import { todaysWorkout, volumeByMuscle } from "@/lib/mock/workouts";
import { dailyBrief } from "@/lib/ai/coach";

export default function Dashboard() {
  const brief = dailyBrief();
  const lowest = [...forgeScoreBreakdown].sort((a, b) => a.value - b.value)[0];

  return (
    <div className="space-y-6">
      {/* HERO — Forge Score + AI brief */}
      <section className="card card-gold overflow-hidden p-6 sm:p-8">
        <div className="grid items-center gap-8 lg:grid-cols-[auto,1fr,auto]">
          {/* Score ring */}
          <div className="flex flex-col items-center">
            <Ring value={today.forgeScore} size={220} stroke={14} label="Forge Score" big trend={today.forgeScoreDelta} />
            <div className="mt-3 chip chip-gold">Moderate Day</div>
          </div>

          {/* Brief */}
          <div>
            <div className="text-[10px] uppercase tracking-[0.22em] text-gold-300">Forge Coach · Daily Brief</div>
            <h1 className="display mt-1 text-2xl text-cream-50 sm:text-3xl">
              {brief.headline}
            </h1>
            <p className="mt-3 max-w-2xl text-cream-200">{brief.body}</p>

            <div className="mt-5 flex flex-wrap gap-2">
              <Link href="/workouts" className="btn-gold">Open today's workout</Link>
              <Link href="/nutrition" className="btn-ghost">Close protein gap</Link>
              <Link href="/coach" className="btn-quiet">
                ✦ Ask the Coach
              </Link>
            </div>
          </div>

          {/* Sparkline */}
          <div className="hidden lg:block">
            <div className="text-[10px] uppercase tracking-[0.18em] text-obsidian-200">
              Forge Score · 14d
            </div>
            <Sparkline data={forgeScoreTrend} width={220} height={70} />
            <div className="mt-1 flex items-baseline justify-between text-[11px] text-obsidian-200">
              <span>68</span>
              <span className="text-gold-200">avg 74</span>
              <span>78</span>
            </div>
          </div>
        </div>
      </section>

      {/* PRIMARY METRICS — 4 rings */}
      <section className="grid grid-cols-2 gap-4 lg:grid-cols-4">
        <MetricRing
          value={today.recovery}
          label="Recovery"
          sub="HRV-weighted"
          tone="green"
          trend={today.recoveryDelta}
          spark={recoveryTrend}
        />
        <MetricRing
          value={today.sleep}
          label="Sleep"
          sub={`${today.sleepHours} h · ${today.sleepDeep} h deep`}
          tone="royal"
          spark={sleepTrend.map((s) => s * 10)}
        />
        <MetricRing
          value={Math.round((today.hrv / 80) * 100)}
          label="HRV"
          sub={`${today.hrv} ms · RHR ${today.restingHr}`}
          tone="gold"
          trend={today.hrvDelta}
          spark={hrvTrend}
        />
        <MetricRing
          value={readinessToPct(today.trainingReadiness)}
          label="Readiness"
          sub={today.trainingReadiness.toUpperCase()}
          tone={
            today.trainingReadiness === "low"
              ? "ruby"
              : today.trainingReadiness === "moderate"
              ? "gold"
              : "green"
          }
        />
      </section>

      {/* GRID — Workout + Nutrition + Recovery + AI */}
      <section className="grid gap-4 lg:grid-cols-3">
        {/* Today's workout */}
        <Link href="/workouts" className="card card-hover lg:col-span-2 p-6">
          <div className="mb-3 flex items-center justify-between">
            <div>
              <div className="text-[10px] uppercase tracking-[0.22em] text-gold-300">Today's Session</div>
              <div className="display mt-1 text-xl text-cream-50">{todaysWorkout.name}</div>
              <div className="mt-1 text-xs text-obsidian-200">
                {todaysWorkout.exercises.length} exercises · ~{todaysWorkout.durationMin} min · est. RPE 8
              </div>
            </div>
            <span className="chip chip-gold">Auto-tuned for recovery</span>
          </div>

          <div className="mb-4 rounded-md border border-gold-400/15 bg-gold-400/5 p-3 text-[12px] text-cream-200">
            <span className="text-gold-200">Why this session?</span> {todaysWorkout.reason}
          </div>

          <div className="space-y-2">
            {todaysWorkout.exercises.slice(0, 4).map((ex, i) => (
              <div
                key={i}
                className="flex items-center justify-between rounded-md border border-gold-400/8 bg-obsidian-800/50 px-3 py-2 text-sm"
              >
                <div className="flex items-center gap-3">
                  <span className="grid h-6 w-6 place-items-center rounded-full border border-gold-400/30 bg-obsidian-900 text-[10px] text-gold-300">
                    {i + 1}
                  </span>
                  <div>
                    <div className="text-cream-100">{ex.name}</div>
                    <div className="text-[11px] text-obsidian-200">{ex.prescription}</div>
                  </div>
                </div>
                <span className="text-[11px] text-obsidian-300">→</span>
              </div>
            ))}
            <div className="pt-1 text-center text-[11px] text-obsidian-300">
              + {todaysWorkout.exercises.length - 4} more
            </div>
          </div>
        </Link>

        {/* Macros + hydration */}
        <Link href="/nutrition" className="card card-hover p-6">
          <div className="text-[10px] uppercase tracking-[0.22em] text-gold-300">Fuel · Today</div>
          <div className="display mt-1 text-xl text-cream-50">
            {today.caloriesIn} <span className="text-sm text-obsidian-200">/ {user.targets.calories} kcal</span>
          </div>
          <div className="mt-3 space-y-3">
            <Bar
              label="Protein"
              rightLabel={`${today.proteinIn} / ${user.targets.protein} g`}
              value={today.proteinIn}
              max={user.targets.protein}
              tone="gold"
            />
            <Bar
              label="Carbs"
              rightLabel={`${today.carbsIn} / ${user.targets.carbs} g`}
              value={today.carbsIn}
              max={user.targets.carbs}
              tone="green"
            />
            <Bar
              label="Fat"
              rightLabel={`${today.fatIn} / ${user.targets.fat} g`}
              value={today.fatIn}
              max={user.targets.fat}
              tone="amber"
            />
            <Bar
              label="Water"
              rightLabel={`${today.waterMl} / ${user.targets.waterMl} mL`}
              value={today.waterMl}
              max={user.targets.waterMl}
              tone="royal"
            />
          </div>
          <div className="mt-4 flex items-center justify-between text-xs">
            <span className="chip chip-amber">{today.proteinRemaining} g protein left</span>
            <span className="text-obsidian-200">9pm cut-off</span>
          </div>
        </Link>
      </section>

      {/* SECONDARY GRID */}
      <section className="grid gap-4 lg:grid-cols-3">
        {/* Forge Score breakdown */}
        <div className="card p-6">
          <div className="mb-3 flex items-center justify-between">
            <div>
              <div className="text-[10px] uppercase tracking-[0.22em] text-gold-300">Forge Score · Drivers</div>
              <div className="display mt-1 text-base text-cream-50">8 inputs · live weighted</div>
            </div>
            <span className="chip">Lowest: {lowest.label}</span>
          </div>
          <div className="space-y-2.5">
            {forgeScoreBreakdown.map((b) => (
              <div key={b.label}>
                <div className="mb-1 flex items-baseline justify-between text-xs">
                  <span className="text-cream-200">{b.label}</span>
                  <span className="text-obsidian-200">
                    <span className="text-cream-100">{b.value}</span>
                    <span className="ml-2 text-[10px]">w {Math.round(b.weight * 100)}%</span>
                  </span>
                </div>
                <Bar
                  value={b.value}
                  max={100}
                  height={4}
                  tone={b.value < 60 ? "ruby" : b.value < 75 ? "amber" : "gold"}
                />
              </div>
            ))}
          </div>
        </div>

        {/* Injury risk + active rehab */}
        <Link href="/injury" className="card card-hover p-6">
          <div className="mb-3 flex items-center justify-between">
            <div className="text-[10px] uppercase tracking-[0.22em] text-gold-300">Injury Risk</div>
            <span className="chip chip-amber">Moderate</span>
          </div>
          <div className="flex items-center gap-4">
            <Ring value={today.injuryRiskPct} size={92} tone="ruby" label="" />
            <div className="flex-1">
              <div className="text-xs text-obsidian-200">7-day modeled risk</div>
              <div className="mt-2 space-y-1 text-[11px] text-cream-200">
                <div>ACR <span className="text-forge-amber">1.38</span> · vol +38%</div>
                <div>HRV ↓12% vs baseline</div>
                <div>Sleep debt 4h 20m</div>
              </div>
            </div>
          </div>
          <div className="hairline my-4" />
          <div className="text-[10px] uppercase tracking-[0.22em] text-gold-300">Active rehab</div>
          {injuries.map((i) => (
            <div key={i.id} className="mt-2 rounded-md border border-gold-400/12 bg-obsidian-800/50 p-3">
              <div className="flex items-center justify-between">
                <div className="text-sm text-cream-100">{i.name}</div>
                <span className="chip chip-amber">Phase {i.phase}</span>
              </div>
              <div className="mt-2 text-[11px] text-obsidian-200">
                Pain today {i.painToday}/10 · day {i.daysOld}
              </div>
            </div>
          ))}
        </Link>

        {/* AI Coach quick chat preview */}
        <Link href="/coach" className="card card-hover p-6">
          <div className="mb-3 flex items-center gap-2">
            <span className="text-gold-300 animate-pulse-gold">✦</span>
            <div className="text-[10px] uppercase tracking-[0.22em] text-gold-300">AI Coach · Ready</div>
          </div>
          <div className="display text-xl text-cream-50">What do you want to know?</div>
          <div className="mt-3 space-y-2">
            {[
              "What should I do today?",
              "Why am I tired?",
              "Why is my bench not progressing?",
              "How do I recover from this shoulder?",
            ].map((q) => (
              <div
                key={q}
                className="flex items-center justify-between rounded-md border border-gold-400/10 bg-obsidian-800/50 px-3 py-2 text-sm text-cream-200 hover:border-gold-400/30"
              >
                "{q}" <span className="text-gold-300/60">↗</span>
              </div>
            ))}
          </div>
        </Link>
      </section>

      {/* TERTIARY — volume + activity + recovery trends */}
      <section className="grid gap-4 lg:grid-cols-3">
        <div className="card p-6">
          <div className="mb-3 flex items-center justify-between">
            <div className="text-[10px] uppercase tracking-[0.22em] text-gold-300">Volume · 7 days</div>
            <Link href="/workouts" className="text-[11px] text-obsidian-200 hover:text-gold-200">View →</Link>
          </div>
          <div className="space-y-2">
            {volumeByMuscle.slice(0, 6).map((m) => {
              const pct = (m.sets / m.optimal[1]) * 100;
              const inOptimal = m.sets >= m.optimal[0] && m.sets <= m.optimal[1];
              return (
                <div key={m.muscle}>
                  <div className="mb-1 flex items-baseline justify-between text-xs">
                    <span className="text-cream-200">{m.muscle}</span>
                    <span className={inOptimal ? "text-forge-green" : "text-forge-amber"}>
                      {m.sets} sets · target {m.optimal[0]}–{m.optimal[1]}
                    </span>
                  </div>
                  <Bar value={pct} max={120} height={4} tone={inOptimal ? "green" : "amber"} />
                </div>
              );
            })}
          </div>
        </div>

        <div className="card p-6">
          <div className="mb-3 text-[10px] uppercase tracking-[0.22em] text-gold-300">Activity</div>
          <div className="grid grid-cols-3 gap-3">
            <Stat label="Steps" value={today.steps.toLocaleString()} hint="target 10K" />
            <Stat label="Out" value={today.caloriesOut.toLocaleString()} unit="kcal" />
            <Stat label="Strain" value={today.strainYesterday} unit="/ 21" />
          </div>
          <div className="hairline my-4" />
          <div className="mb-2 text-[10px] uppercase tracking-[0.18em] text-obsidian-200">
            14-day strain
          </div>
          <Barline
            data={[13, 14, 17, 9, 16, 19, 18, 12, 14, 17, 19, 13, 15, 17]}
            width={280}
            height={48}
          />
        </div>

        <div className="card p-6">
          <div className="mb-3 text-[10px] uppercase tracking-[0.22em] text-gold-300">Streak · XP</div>
          <div className="flex items-center gap-6">
            <div>
              <div className="stat-num text-5xl text-gold-grad">🔥 {user.streakDays}</div>
              <div className="mt-1 text-[11px] text-obsidian-200">consecutive training days</div>
            </div>
            <div className="flex-1">
              <div className="text-xs text-cream-200">
                Lv {user.level} · {user.xp.toLocaleString()} / {user.xpToNext.toLocaleString()} XP
              </div>
              <Bar value={user.xp} max={user.xpToNext} tone="gold" height={6} />
              <div className="mt-2 text-[11px] text-obsidian-200">
                {(user.xpToNext - user.xp).toLocaleString()} XP to Lv {user.level + 1}
              </div>
            </div>
          </div>
          <div className="hairline my-4" />
          <Link href="/achievements" className="text-[11px] text-gold-300 hover:text-gold-200">
            View achievements →
          </Link>
        </div>
      </section>

      {/* MICRO disclaimer */}
      <div className="rounded-lg border border-gold-400/10 bg-obsidian-800/30 p-4 text-[11px] text-obsidian-200">
        Forge provides educational guidance based on the signals you share with it. It is not medical
        advice. For pain that persists, severe symptoms, head injury, or concerning bloodwork — consult
        a licensed clinician.
      </div>
    </div>
  );
}

function MetricRing({
  value,
  label,
  sub,
  tone,
  trend,
  spark,
}: {
  value: number;
  label: string;
  sub: string;
  tone: "gold" | "green" | "ruby" | "royal";
  trend?: number;
  spark?: number[];
}) {
  return (
    <div className="card card-hover p-5">
      <div className="flex items-center gap-4">
        <Ring value={value} size={84} stroke={6} tone={tone} />
        <div className="min-w-0 flex-1">
          <div className="text-[10px] uppercase tracking-[0.18em] text-obsidian-200">{label}</div>
          <div className="mt-0.5 truncate text-xs text-cream-200">{sub}</div>
          {trend !== undefined && (
            <div className={`mt-1 text-[11px] ${trend >= 0 ? "text-forge-green" : "text-forge-ruby"}`}>
              {trend >= 0 ? "▲" : "▼"} {Math.abs(trend)} vs 7d
            </div>
          )}
        </div>
      </div>
      {spark && (
        <div className="mt-3">
          <Sparkline data={spark} width={240} height={28} />
        </div>
      )}
    </div>
  );
}

function readinessToPct(r: "low" | "moderate" | "high" | "peak") {
  return { low: 30, moderate: 65, high: 85, peak: 96 }[r];
}
