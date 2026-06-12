"use client";

import { SectionTitle } from "@/components/ui/SectionTitle";
import { Sparkline } from "@/components/ui/Sparkline";
import { Stat } from "@/components/ui/Stat";
import { bodyMetrics } from "@/lib/mock/body";
import { weightTrend } from "@/lib/mock/user";
import { toast } from "@/lib/toast";

export default function BodyPage() {
  const m = bodyMetrics.measurements;

  return (
    <div className="space-y-6">
      <SectionTitle
        eyebrow="Body"
        title="Body Tracking"
        subtitle="Weight, composition, 8 measurements, progress photos. Compare any two timestamps."
      />

      <div className="grid gap-4 lg:grid-cols-4">
        <div className="card card-gold p-5">
          <div className="text-[10px] uppercase tracking-[0.22em] text-gold-300">Weight</div>
          <div className="mt-1 stat-num text-4xl text-cream-50">
            {bodyMetrics.weightKg}<span className="ml-1 text-sm text-obsidian-200">kg</span>
          </div>
          <div className="mt-1 text-xs text-forge-green">▼ 2.8 kg / 30d</div>
          <div className="mt-3"><Sparkline data={weightTrend} width={240} height={36} /></div>
        </div>
        <Stat label="Body Fat" value={bodyMetrics.bodyFatPct} unit="%" delta={-1.6} deltaTone="good" hint="30-day Δ" size="lg" />
        <Stat label="Lean Mass" value={bodyMetrics.leanMassKg} unit="kg" delta={-0.9} deltaTone="neutral" hint="protected in deficit" size="lg" />
        <Stat label="BMR" value={bodyMetrics.bmr} unit="kcal" hint="resting energy" size="lg" />
      </div>

      {/* Measurements */}
      <div className="card p-6">
        <div className="mb-4 flex items-baseline justify-between">
          <div className="display text-xl text-cream-50">Measurements</div>
          <button className="btn-ghost text-xs" onClick={() => toast("Measurement logged — 30-day deltas recalculated")}>+ Log measurement</button>
        </div>
        <div className="grid grid-cols-2 gap-4 sm:grid-cols-4 lg:grid-cols-6">
          <Measurement label="Neck" value={`${m.neckCm} cm`} delta="−1.5" />
          <Measurement label="Chest" value={`${m.chestCm} cm`} delta="−2.0" />
          <Measurement label="Waist" value={`${m.waistCm} cm`} delta="−4.5" />
          <Measurement label="Hips" value={`${m.hipsCm} cm`} delta="−1.5" />
          <Measurement label="L Arm" value={`${m.leftArmCm} cm`} delta="+0.5" />
          <Measurement label="R Arm" value={`${m.rightArmCm} cm`} delta="+0.5" />
          <Measurement label="L Forearm" value={`${m.leftForearmCm} cm`} />
          <Measurement label="R Forearm" value={`${m.rightForearmCm} cm`} />
          <Measurement label="L Thigh" value={`${m.leftThighCm} cm`} delta="−1.0" />
          <Measurement label="R Thigh" value={`${m.rightThighCm} cm`} delta="−1.0" />
          <Measurement label="L Calf" value={`${m.leftCalfCm} cm`} />
          <Measurement label="R Calf" value={`${m.rightCalfCm} cm`} />
        </div>
      </div>

      {/* Progress photos */}
      <div className="card p-6">
        <div className="mb-4 flex items-baseline justify-between">
          <div className="display text-xl text-cream-50">Progress photos</div>
          <button className="btn-ghost text-xs" onClick={() => toast("Progress photo added — comparison card updates at the 12-week mark")}>+ Add photo</button>
        </div>
        <div className="grid gap-3 sm:grid-cols-3 lg:grid-cols-4">
          {[
            { date: "Mar 12", weight: "91.2 kg", bf: "16.4%" },
            { date: "Apr 12", weight: "90.1 kg", bf: "15.9%" },
            { date: "May 12", weight: "89.0 kg", bf: "15.3%" },
            { date: "Jun 10", weight: "88.4 kg", bf: "14.8%" },
          ].map((p, i) => (
            <div key={p.date} className="card-hover rounded-lg border border-gold-400/10 bg-obsidian-800/40 p-3">
              <div className="aspect-[3/4] rounded-md bg-obsidian-700/60 grid place-items-center text-3xl text-gold-300/20">
                {i + 1}
              </div>
              <div className="mt-2 text-[12px] text-cream-100">{p.date}</div>
              <div className="text-[11px] text-obsidian-200">{p.weight} · {p.bf}</div>
            </div>
          ))}
        </div>
      </div>

      {/* Trend */}
      <div className="card p-6">
        <div className="mb-3 flex items-baseline justify-between">
          <div className="display text-xl text-cream-50">90-day composition</div>
          <span className="chip chip-green">−2.8 kg fat · LM preserved</span>
        </div>
        <div className="grid gap-4 lg:grid-cols-3">
          {bodyMetrics.history.map((h) => (
            <div key={h.date} className="rounded-md border border-gold-400/10 bg-obsidian-800/40 p-4">
              <div className="text-[10px] uppercase tracking-wider text-obsidian-200">{h.date}</div>
              <div className="mt-1 text-sm text-cream-50">{h.weightKg} kg · {h.bodyFatPct}% bf</div>
              <div className="text-[11px] text-obsidian-200">Lean {h.leanMassKg} kg</div>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}

function Measurement({ label, value, delta }: { label: string; value: string; delta?: string }) {
  return (
    <div>
      <div className="text-[10px] uppercase tracking-wider text-obsidian-200">{label}</div>
      <div className="mt-1 text-sm text-cream-100">{value}</div>
      {delta && (
        <div className={`text-[11px] ${delta.startsWith("−") ? "text-forge-green" : "text-gold-300"}`}>
          {delta} cm / 30d
        </div>
      )}
    </div>
  );
}
