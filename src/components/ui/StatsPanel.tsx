"use client";

import { useState } from "react";
import { AreaChart } from "@/components/ui/AreaChart";

const PERIODS = ["D", "W", "M", "Y"] as const;
type Period = (typeof PERIODS)[number];

/** One chart + one toggle + two quiet stats. The whole Stats story. */
export function StatsPanel({
  series,
  todayLabel,
  todayValue,
  secondLabel,
  secondValue,
}: {
  series: number[];
  todayLabel: string;
  todayValue: string;
  secondLabel: string;
  secondValue: string;
}) {
  const [period, setPeriod] = useState<Period>("W");

  // Mock data ships ~2 weeks of points; windows are honest slices of it.
  const windowed =
    period === "D" ? series.slice(-3)
    : period === "W" ? series.slice(-7)
    : series;

  return (
    <section className="card p-6 sm:p-8">
      <div className="mb-6 flex items-center justify-between">
        <div className="text-[11px] text-obsidian-200">Recovery</div>
        <div className="flex gap-1 rounded-full border border-white/[0.06] p-1">
          {PERIODS.map((p) => (
            <button
              key={p}
              onClick={() => setPeriod(p)}
              className={`h-7 w-7 rounded-full text-[11px] transition-colors ${
                period === p ? "bg-gold-400/10 text-gold-400" : "text-obsidian-200"
              }`}
            >
              {p}
            </button>
          ))}
        </div>
      </div>

      <AreaChart values={windowed} height={140} id="stats" />

      <div className="mt-8 grid grid-cols-2 gap-4 border-t border-white/[0.06] pt-6">
        <div>
          <div className="text-2xl font-bold tabular-nums text-cream-100">{todayValue}</div>
          <div className="mt-1 text-[11px] text-obsidian-200">{todayLabel}</div>
        </div>
        <div>
          <div className="text-2xl font-bold tabular-nums text-cream-100">{secondValue}</div>
          <div className="mt-1 text-[11px] text-obsidian-200">{secondLabel}</div>
        </div>
      </div>
    </section>
  );
}
