"use client";

import { SectionTitle } from "@/components/ui/SectionTitle";
import { Bar } from "@/components/ui/Bar";
import { bloodwork } from "@/lib/mock/bloodwork";
import { toast } from "@/lib/toast";

const CATEGORY_LABEL: Record<string, string> = {
  hormones: "Hormones",
  "vitamins-minerals": "Vitamins & Minerals",
  lipids: "Lipids",
  metabolic: "Metabolic",
  inflammation: "Inflammation",
  thyroid: "Thyroid",
};

export default function BloodworkPage() {
  const grouped = bloodwork.reduce<Record<string, typeof bloodwork>>((acc, m) => {
    acc[m.category] = acc[m.category] || [];
    acc[m.category].push(m);
    return acc;
  }, {});

  return (
    <div className="space-y-6">
      <SectionTitle
        eyebrow="Health"
        title="Bloodwork & Health Optimization"
        subtitle="T, free T, D, ferritin, lipids, glucose, A1c, CRP, thyroid, B12 — interpreted in context, not just flagged."
        right={
          <button className="btn-gold text-xs" onClick={() => toast("Panel upload: PDF or lab CSV — markers parse automatically and trends update")}>+ Upload new panel</button>
        }
      />

      <div className="rounded-lg border border-forge-ruby/30 bg-forge-ruby/5 p-4 text-[13px] text-cream-200">
        <span className="text-forge-ruby">⚠ Medical disclaimer:</span> Forge interprets bloodwork
        patterns to surface educational context — not to diagnose, treat, or replace your physician.
        Discuss results and any intervention with a licensed clinician.
      </div>

      <div className="space-y-5">
        {Object.entries(grouped).map(([cat, items]) => (
          <div key={cat}>
            <div className="mb-3 text-[10px] uppercase tracking-[0.22em] text-gold-300">
              {CATEGORY_LABEL[cat]}
            </div>
            <div className="grid gap-3 lg:grid-cols-2">
              {items.map((m) => {
                const min = m.optimalRange[0];
                const max = m.optimalRange[1];
                const inOptimal = m.value >= min && m.value <= max;
                return (
                  <div key={m.name} className="card p-5">
                    <div className="mb-2 flex items-baseline justify-between">
                      <div>
                        <div className="text-sm text-cream-50">{m.name}</div>
                        <div className="text-[11px] text-obsidian-200">{m.takenAt}</div>
                      </div>
                      <div className="text-right">
                        <div className="stat-num text-2xl text-gold-grad">
                          {m.value}<span className="ml-1 text-[10px] text-obsidian-200">{m.unit}</span>
                        </div>
                        {m.delta && (
                          <div className={`text-[11px] ${m.delta.startsWith("+") ? "text-forge-green" : "text-forge-ruby"}`}>
                            {m.delta}
                          </div>
                        )}
                      </div>
                    </div>

                    <div className="mt-1">
                      <div className="mb-1 flex justify-between text-[10px] text-obsidian-200">
                        <span>{m.normalRange[0]}</span>
                        <span className={inOptimal ? "text-forge-green" : "text-forge-amber"}>
                          {inOptimal ? "Optimal" : "Outside optimal"}
                        </span>
                        <span>{m.normalRange[1]}</span>
                      </div>
                      <Bar
                        value={m.value - m.normalRange[0]}
                        max={m.normalRange[1] - m.normalRange[0]}
                        tone={inOptimal ? "green" : "amber"}
                        height={6}
                        zones={[
                          {
                            from: m.optimalRange[0] - m.normalRange[0],
                            to: m.optimalRange[1] - m.normalRange[0],
                            tone: "good",
                          },
                        ]}
                      />
                      <div className="mt-1 text-[10px] text-obsidian-200">
                        Optimal {min}–{max} {m.unit}
                      </div>
                    </div>

                    <div className="mt-3 rounded-md border border-gold-400/12 bg-gold-400/5 p-2.5 text-[12px] text-cream-200">
                      <span className="text-gold-200">✦ </span>{m.aiNote}
                    </div>
                  </div>
                );
              })}
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}
