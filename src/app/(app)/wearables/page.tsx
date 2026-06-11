import { SectionTitle } from "@/components/ui/SectionTitle";
import { wearables, wearableSnapshot } from "@/lib/mock/wearables";
import { Stat } from "@/components/ui/Stat";

export default function WearablesPage() {
  return (
    <div className="space-y-6">
      <SectionTitle
        eyebrow="Recover · Hardware"
        title="Wearables Hub"
        subtitle="Apple Watch, WHOOP, Oura, Garmin, Fitbit, Polar, smart scales — unified into one signal stream."
      />

      {/* Live snapshot */}
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
          <Stat label="Devices" value="3" hint="connected of 7" />
        </div>
      </div>

      {/* Devices */}
      <div className="grid gap-3 sm:grid-cols-2 lg:grid-cols-3">
        {wearables.map((d) => (
          <div
            key={d.id}
            className={`card p-5 ${d.connected ? "card-hover" : "opacity-80"}`}
          >
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
              <span className={`chip ${d.connected ? "chip-green" : ""}`}>
                {d.connected ? "Connected" : "Connect"}
              </span>
            </div>

            <div className="text-[11px] text-obsidian-200">
              {d.connected ? `Last sync · ${d.lastSync}` : "Not paired"}
              {d.battery !== undefined && d.connected && (
                <span className="ml-2">· 🔋 {d.battery}%</span>
              )}
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
              <button className={d.connected ? "btn-ghost text-[11px] flex-1" : "btn-gold text-[11px] flex-1"}>
                {d.connected ? "Sync now" : "Pair device"}
              </button>
              {d.connected && <button className="btn-quiet text-[11px]">Settings</button>}
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}
