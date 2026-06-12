"use client";

import { SectionTitle } from "@/components/ui/SectionTitle";
import { Stat } from "@/components/ui/Stat";
import { wearables, wearableSnapshot } from "@/lib/mock/wearables";
import { useForge } from "@/lib/store";
import { toast } from "@/lib/toast";

export default function WearablesPage() {
  const forge = useForge();

  return (
    <div className="space-y-6">
      <SectionTitle
        eyebrow="Recover · Hardware"
        title="Wearables Hub"
        subtitle="Apple Watch, WHOOP, Oura, Garmin, Fitbit, Polar, smart scales — unified into one signal stream."
      />

      <div className="card card-gold p-6">
        <div className="mb-3 flex items-center justify-between">
          <div className="text-[10px] uppercase tracking-[0.22em] text-gold-300">Live snapshot</div>
          <span className="inline-flex items-center gap-1.5 text-[11px] text-forge-green">
            <span className="dot dot-green animate-pulse-gold" /> Streaming
          </span>
        </div>
        <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
          <Stat label="Heart Rate" value={wearableSnapshot.hr} unit="bpm" />
          <Stat label="HRV" value={wearableSnapshot.hrv} unit="ms" />
          <Stat label="VO₂ Max" value={wearableSnapshot.vo2max} unit="ml/kg/min" />
          <Stat label="Respiratory" value={wearableSnapshot.respiratoryRate} unit="rpm" />
          <Stat label="Body Temp" value={`${wearableSnapshot.bodyTempDelta > 0 ? "+" : ""}${wearableSnapshot.bodyTempDelta}`} unit="°C Δ" />
          <Stat label="SpO₂" value={wearableSnapshot.spo2} unit="%" />
          <Stat label="Strain (today)" value={wearableSnapshot.strainToday} unit={`/ ${wearableSnapshot.strainTarget}`} />
          <Stat
            label="Devices"
            value={wearables.filter((d) => forge.isConnected(d.id, d.connected)).length}
            hint={`connected of ${wearables.length}`}
          />
        </div>
      </div>

      <div className="grid gap-3 sm:grid-cols-2 lg:grid-cols-3">
        {wearables.map((d) => {
          const connected = forge.isConnected(d.id, d.connected);
          return (
            <div key={d.id} className={`card p-5 ${connected ? "card-hover" : "opacity-80"}`}>
              <div className="mb-3 flex items-start justify-between">
                <div className="flex items-center gap-3">
                  <span className="grid h-10 w-10 place-items-center rounded-md border border-gold-400/30 bg-gold-400/5 text-xl text-gold-300">
                    {d.icon}
                  </span>
                  <div>
                    <div className="text-sm text-cream-50">{d.name}</div>
                    <div className="text-[11px] text-obsidian-200">{d.brand}</div>
                  </div>
                </div>
                <span className={`chip ${connected ? "chip-green" : ""}`}>
                  {connected ? "Connected" : "Off"}
                </span>
              </div>

              <div className="text-[11px] text-obsidian-200">
                {connected ? `Last sync · ${forge.connected[d.id] !== undefined ? "just now" : d.lastSync ?? "just now"}` : "Not paired"}
                {d.battery !== undefined && connected && <span className="ml-2">· 🔋 {d.battery}%</span>}
              </div>

              <div className="mt-3">
                <div className="text-[9px] uppercase tracking-wider text-obsidian-300">Permissions</div>
                <div className="mt-1 flex flex-wrap gap-1">
                  {d.permissions.map((p) => (
                    <span key={p} className="chip text-[9px]">{p}</span>
                  ))}
                </div>
              </div>

              <div className="mt-4 flex gap-2">
                <button
                  onClick={() => {
                    if (connected) {
                      toast(`${d.name} synced — data refreshed just now`);
                    } else {
                      forge.toggleConnected(d.id, d.connected);
                      toast(`${d.name} paired · streaming ${d.permissions[0]}`);
                    }
                  }}
                  className={connected ? "btn-ghost flex-1 text-[11px]" : "btn-gold flex-1 text-[11px]"}
                >
                  {connected ? "Sync now" : "Pair device"}
                </button>
                {connected && (
                  <button
                    onClick={() => {
                      forge.toggleConnected(d.id, d.connected);
                      toast(`${d.name} disconnected`);
                    }}
                    className="btn-quiet text-[11px]"
                  >
                    Remove
                  </button>
                )}
              </div>
            </div>
          );
        })}
      </div>
    </div>
  );
}
