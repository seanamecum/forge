import { SectionTitle } from "@/components/ui/SectionTitle";
import { Bar } from "@/components/ui/Bar";
import { teams } from "@/lib/mock/marketplace";

export default function TeamsPage() {
  return (
    <div className="space-y-6">
      <SectionTitle
        eyebrow="Forge Teams"
        title="Schools · Gyms · Sports Teams · Businesses"
        subtitle="Coach view, athlete recovery, compliance, team challenges. Built for accountability."
        right={<button className="btn-gold text-xs">+ Create team</button>}
      />

      <div className="grid gap-4 lg:grid-cols-2">
        {teams.map((t) => (
          <div key={t.id} className="card p-6">
            <div className="mb-2 flex items-baseline justify-between gap-2">
              <div>
                <div className="display text-xl text-cream-50">{t.name}</div>
                <div className="text-[11px] text-obsidian-200">{t.type} · {t.members} members</div>
              </div>
              <span className="chip chip-gold">Avg Forge {t.avgForge}</span>
            </div>

            <div className="mt-3 grid grid-cols-2 gap-3">
              <div className="rounded-md border border-gold-400/10 bg-obsidian-800/40 p-3">
                <div className="text-[10px] uppercase tracking-wider text-obsidian-200">Average Forge Score</div>
                <div className="mt-1"><Bar value={t.avgForge} max={100} tone="gold" /></div>
                <div className="mt-1 text-[11px] text-cream-100">{t.avgForge} / 100</div>
              </div>
              <div className="rounded-md border border-gold-400/10 bg-obsidian-800/40 p-3">
                <div className="text-[10px] uppercase tracking-wider text-obsidian-200">Compliance · 30d</div>
                <div className="mt-1"><Bar value={t.compliance} max={100} tone="green" /></div>
                <div className="mt-1 text-[11px] text-cream-100">{t.compliance}%</div>
              </div>
            </div>

            <div className="mt-4 grid grid-cols-3 gap-2 text-center text-[11px]">
              <div className="rounded-md border border-gold-400/10 bg-obsidian-800/40 p-2">
                <div className="text-obsidian-200">High risk</div>
                <div className="text-forge-amber">{Math.round(t.members * 0.12)}</div>
              </div>
              <div className="rounded-md border border-gold-400/10 bg-obsidian-800/40 p-2">
                <div className="text-obsidian-200">In rehab</div>
                <div className="text-forge-amber">{Math.round(t.members * 0.08)}</div>
              </div>
              <div className="rounded-md border border-gold-400/10 bg-obsidian-800/40 p-2">
                <div className="text-obsidian-200">PR last 7d</div>
                <div className="text-forge-green">{Math.round(t.members * 0.18)}</div>
              </div>
            </div>

            <div className="mt-4 flex gap-2">
              <button className="btn-gold text-[11px] flex-1">Open coach view</button>
              <button className="btn-ghost text-[11px]">Team challenge</button>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}
