import { StatHero } from "@/components/ui/StatHero";
import { StatsPanel } from "@/components/ui/StatsPanel";
import { dataSource } from "@/lib/data";

// Minimal stats: hero number, one chart with a period toggle, two quiet stats.
export default async function RecoveryPage() {
  const { today, recoveryTrend } = await dataSource.getRecovery();

  return (
    <div className="mx-auto max-w-2xl space-y-8 pb-8">
      <section className="card p-8">
        <StatHero value={today.recovery} label="Recovery today" accent />
      </section>

      <StatsPanel
        series={recoveryTrend}
        todayLabel="HRV"
        todayValue={`${today.hrv} ms`}
        secondLabel="Sleep"
        secondValue={`${today.sleepHours} h`}
      />
    </div>
  );
}
