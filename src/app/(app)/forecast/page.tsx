import { SectionTitle } from "@/components/ui/SectionTitle";
import { Bar } from "@/components/ui/Bar";
import { forecasts } from "@/lib/mock/body";

export default function ForecastPage() {
  return (
    <div className="space-y-6">
      <SectionTitle
        eyebrow="Digital Twin"
        title="Forecast"
        subtitle="The future you, modeled. Forge runs your trajectory forward based on current trends, deficits, training load, recovery, and goals."
      />

      <div className="grid gap-4 lg:grid-cols-2">
        {forecasts.map((f) => (
          <div key={f.metric} className="card p-6">
            <div className="mb-3 flex items-baseline justify-between">
              <div>
                <div className="text-[10px] uppercase tracking-[0.22em] text-gold-300">{f.metric}</div>
                <div className="display mt-1 text-2xl text-cream-50">
                  {f.current} <span className="text-obsidian-200">→</span>{" "}
                  <span className="text-gold-grad">{f.projected}</span>
                </div>
                <div className="mt-1 text-[12px] text-obsidian-200">in {f.eta}</div>
              </div>
              <div className="text-right">
                <div className="text-[10px] uppercase tracking-wider text-obsidian-200">Confidence</div>
                <div className="mt-1 stat-num text-lg text-cream-50">{Math.round(f.confidence * 100)}%</div>
              </div>
            </div>
            <Bar value={f.confidence * 100} max={100} tone="gold" height={4} />
            <div className="mt-3 text-[12px] text-cream-200">{f.rationale}</div>
          </div>
        ))}
      </div>

      <div className="card p-6">
        <div className="display text-xl text-cream-50">Scenario planner</div>
        <p className="mt-1 text-sm text-obsidian-200">
          Adjust your inputs to see how the projections shift. Forge re-runs the model in real time.
        </p>
        <div className="mt-4 grid gap-4 lg:grid-cols-3">
          {[
            { lever: "Deficit", value: "−540 kcal", impact: "Weight at 185.4 lb in 8 wks" },
            { lever: "Sleep", value: "8 h / night", impact: "+6 Forge points in 30 d" },
            { lever: "Volume", value: "Hold flat", impact: "Injury risk → 12% (2 wk)" },
          ].map((s) => (
            <div key={s.lever} className="rounded-md border border-gold-400/12 bg-obsidian-800/40 p-4">
              <div className="text-[10px] uppercase tracking-wider text-gold-300">{s.lever}</div>
              <div className="mt-1 text-sm text-cream-100">{s.value}</div>
              <div className="mt-1 text-[12px] text-gold-200">→ {s.impact}</div>
            </div>
          ))}
        </div>
      </div>

      <div className="rounded-lg border border-gold-400/10 bg-obsidian-800/30 p-4 text-[11px] text-obsidian-200">
        Forecasts are model-based estimates from your current trajectory and are not guarantees. Actual
        outcomes depend on adherence, biology, and life. Treat them as direction, not destination.
      </div>
    </div>
  );
}
