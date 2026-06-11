import { SectionTitle } from "@/components/ui/SectionTitle";
import { Bar } from "@/components/ui/Bar";
import { deficiencies } from "@/lib/mock/nutrition";

export default function DeficienciesPage() {
  return (
    <div className="space-y-6">
      <SectionTitle
        eyebrow="Fuel · AI Detection"
        title="Deficiency Detection"
        subtitle="Forge cross-references your 7-day intake against research-based targets, training load, and your bloodwork to surface real signal — not just numbers."
      />

      <div className="space-y-3">
        {deficiencies.map((d) => {
          const pct = Math.min(150, Math.round((d.current / d.target) * 100));
          const tone =
            d.severity === "high" ? "ruby" : d.severity === "medium" ? "amber" : "gold";
          const chip =
            d.severity === "high"
              ? "chip-ruby"
              : d.severity === "medium"
              ? "chip-amber"
              : "chip-gold";
          return (
            <div key={d.nutrient} className="card p-5">
              <div className="flex flex-wrap items-baseline justify-between gap-3">
                <div>
                  <div className="display text-xl text-cream-50">{d.nutrient}</div>
                  <div className="mt-0.5 text-[12px] text-obsidian-200">
                    {d.current} {d.unit} · target {d.target} {d.unit} · {pct}%
                  </div>
                </div>
                <span className={`chip ${chip}`}>{d.severity.toUpperCase()}</span>
              </div>

              <div className="mt-3">
                <Bar value={d.current} max={d.target * 1.5} tone={tone as any} height={6} />
              </div>

              <div className="mt-3 rounded-md border border-gold-400/12 bg-gold-400/5 p-3 text-[13px] text-cream-200">
                <span className="text-gold-200">Coach:</span> {d.recommendation}
              </div>
            </div>
          );
        })}
      </div>

      <div className="rounded-lg border border-gold-400/10 bg-obsidian-800/30 p-4 text-[11px] text-obsidian-200">
        Educational guidance only. For supplement decisions tied to medication or a known condition,
        check with a registered dietitian or physician.
      </div>
    </div>
  );
}
