import Link from "next/link";
import { StatHero } from "@/components/ui/StatHero";
import { AreaChart } from "@/components/ui/AreaChart";
import { dataSource } from "@/lib/data";

// Minimal dashboard: one hero number, one chart, today's three actions.
// Everything else lives one tap away — whitespace is the feature.
export default async function Dashboard() {
  const { today, forgeScoreTrend, directive } = await dataSource.getDashboard();
  const actions = directive.actions.slice(0, 3);

  return (
    <div className="mx-auto max-w-2xl space-y-8 pb-8">
      {/* Hero — the one number that matters */}
      <section className="card p-8">
        <div className="flex items-end justify-between">
          <StatHero value={today.forgeScore} label="Forge Score" />
          <div className="pb-3 text-right text-[11px] text-obsidian-200">
            {today.forgeScoreDelta >= 0 ? "+" : ""}
            {today.forgeScoreDelta} vs yesterday
          </div>
        </div>
        <div className="mt-6">
          <AreaChart values={forgeScoreTrend} height={96} id="dash" />
        </div>
        <p className="mt-6 text-[13px] leading-relaxed text-cream-300">{directive.headline}</p>
      </section>

      {/* Today — three quiet rows */}
      <section className="card p-6">
        <div className="mb-4 text-[11px] text-obsidian-200">Today</div>
        <ul className="space-y-4">
          {actions.map((a) => (
            <li key={a.kind} className="flex items-center gap-3">
              <span className="text-base">{a.icon}</span>
              <span className="text-sm text-cream-100">{a.value}</span>
            </li>
          ))}
        </ul>
        <div className="mt-5 border-t border-white/[0.06] pt-4">
          <p className="text-[13px] text-gold-400">{directive.priority}</p>
        </div>
      </section>

      {/* One quiet exit to everything else */}
      <Link
        href="/recovery"
        className="card flex items-center justify-between p-5 text-sm text-cream-300"
      >
        <span>Stats, recovery &amp; more</span>
        <span className="text-obsidian-200">→</span>
      </Link>

    </div>
  );
}
