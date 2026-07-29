// Product mockups — deterministic, SSR-safe (no Math.random ids), self-contained.
// These stand in for real screenshots until the product ships.

function sparkPath(data: number[], w: number, h: number): { line: string; area: string } {
  const min = Math.min(...data);
  const max = Math.max(...data);
  const range = max - min || 1;
  const stepX = w / (data.length - 1 || 1);
  const pts = data.map((v, i) => {
    const x = i * stepX;
    const y = h - ((v - min) / range) * (h - 4) - 2;
    return [x, y] as const;
  });
  const line = pts.map((p, i) => `${i === 0 ? "M" : "L"}${p[0].toFixed(1)},${p[1].toFixed(1)}`).join(" ");
  const area = `${line} L${w},${h} L0,${h} Z`;
  return { line, area };
}

function Spark({ id, data, w = 120, h = 34, color = "#d4af37" }: { id: string; data: number[]; w?: number; h?: number; color?: string }) {
  const { line, area } = sparkPath(data, w, h);
  return (
    <svg width={w} height={h} aria-hidden className="overflow-visible">
      <defs>
        <linearGradient id={id} x1="0" y1="0" x2="0" y2="1">
          <stop offset="0%" stopColor={color} stopOpacity="0.28" />
          <stop offset="100%" stopColor={color} stopOpacity="0" />
        </linearGradient>
      </defs>
      <path d={area} fill={`url(#${id})`} />
      <path d={line} fill="none" stroke={color} strokeWidth="1.6" strokeLinecap="round" />
    </svg>
  );
}

function ScoreRing({ value = 78 }: { value?: number }) {
  const size = 118;
  const stroke = 9;
  const r = (size - stroke) / 2;
  const circ = 2 * Math.PI * r;
  const dash = (value / 100) * circ;
  return (
    <div className="relative inline-flex items-center justify-center">
      <svg width={size} height={size} className="-rotate-90" aria-hidden>
        <defs>
          <linearGradient id="mk-ring" x1="0" y1="0" x2="1" y2="1">
            <stop offset="0%" stopColor="#f5dc7a" />
            <stop offset="100%" stopColor="#a07f1f" />
          </linearGradient>
        </defs>
        <circle cx={size / 2} cy={size / 2} r={r} stroke="rgba(212,175,55,0.1)" strokeWidth={stroke} fill="none" />
        <circle
          cx={size / 2}
          cy={size / 2}
          r={r}
          stroke="url(#mk-ring)"
          strokeWidth={stroke}
          fill="none"
          strokeLinecap="round"
          strokeDasharray={`${dash} ${circ}`}
          style={{ filter: "drop-shadow(0 0 6px rgba(245,220,122,0.4))" }}
        />
      </svg>
      <div className="absolute inset-0 flex flex-col items-center justify-center">
        <div className="stat-num text-4xl text-gold-grad leading-none">{value}</div>
        <div className="mt-0.5 text-[9px] uppercase tracking-[0.16em] text-obsidian-200">Forge Score</div>
      </div>
    </div>
  );
}

/** Large desktop dashboard mockup for the hero. */
export function DashboardMockup() {
  return (
    <div className="card card-gold overflow-hidden p-0 shadow-gold-strong">
      {/* window chrome */}
      <div className="flex items-center gap-2 border-b border-white/6 px-4 py-3">
        <span className="h-2.5 w-2.5 rounded-full bg-forge-ruby/60" />
        <span className="h-2.5 w-2.5 rounded-full bg-forge-amber/60" />
        <span className="h-2.5 w-2.5 rounded-full bg-forge-green/60" />
        <span className="ml-3 text-[11px] tracking-wide text-obsidian-200">forge.fit / dashboard</span>
      </div>

      <div className="grid gap-4 p-4 sm:grid-cols-3 sm:p-6">
        {/* Score + directive */}
        <div className="rounded-2xl border border-white/6 bg-obsidian-900/50 p-5 text-center sm:text-left">
          <div className="flex justify-center sm:justify-start">
            <ScoreRing value={78} />
          </div>
          <div className="mt-3 text-xs text-forge-green">▲ 3 vs yesterday</div>
        </div>

        {/* Today's call */}
        <div className="rounded-2xl border border-gold-400/20 bg-gold-400/5 p-5 sm:col-span-2">
          <div className="text-[10px] uppercase tracking-[0.2em] text-gold-300">Today&apos;s call</div>
          <div className="display mt-1.5 text-2xl text-cream-50">Train — cap RPE 8.5</div>
          <p className="mt-1.5 text-sm leading-relaxed text-obsidian-100">
            Lower-body strength block. Volume auto-capped 12% on an 8ms HRV drop. Skip overhead pressing —
            shoulder rehab continues.
          </p>
          <div className="mt-3 flex flex-wrap gap-2">
            <span className="chip chip-green">Recovery 72</span>
            <span className="chip chip-amber">Strain moderate</span>
            <span className="chip chip-ruby">Skip: OHP</span>
          </div>
        </div>

        {/* metric tiles */}
        <MetricTile id="mk-hrv" label="HRV" value="64 ms" delta="−8" tone="#e9b949" data={[72, 70, 68, 71, 66, 63, 64]} />
        <MetricTile id="mk-sleep" label="Sleep" value="7h 12m" delta="+41m" tone="#5dd39e" data={[6.1, 6.4, 5.9, 6.8, 7.0, 6.6, 7.2]} />
        <MetricTile id="mk-load" label="Weekly load" value="4,820" delta="+6%" tone="#d4af37" data={[3.9, 4.2, 4.0, 4.5, 4.3, 4.7, 4.8]} />
      </div>
    </div>
  );
}

function MetricTile({ id, label, value, delta, tone, data }: { id: string; label: string; value: string; delta: string; tone: string; data: number[] }) {
  const up = delta.startsWith("+");
  return (
    <div className="rounded-2xl border border-white/6 bg-obsidian-900/50 p-4">
      <div className="flex items-center justify-between">
        <span className="text-[10px] uppercase tracking-[0.16em] text-obsidian-200">{label}</span>
        <span className={up ? "text-[11px] text-forge-green" : "text-[11px] text-forge-amber"}>{delta}</span>
      </div>
      <div className="stat-num mt-1 text-2xl text-cream-50">{value}</div>
      <div className="mt-2">
        <Spark id={id} data={data} color={tone} w={160} h={30} />
      </div>
    </div>
  );
}

/** Phone mockup for the "mobile app" section. */
export function PhoneMockup() {
  return (
    <div className="relative mx-auto w-[264px]">
      <div className="rounded-[2.6rem] border border-gold-400/20 bg-obsidian-900 p-3 shadow-gold-strong">
        <div className="relative overflow-hidden rounded-[2rem] border border-white/6 bg-obsidian-950">
          {/* notch */}
          <div className="absolute left-1/2 top-2 z-10 h-5 w-24 -translate-x-1/2 rounded-full bg-black" />
          <div className="bg-mesh px-4 pb-6 pt-9">
            <div className="flex items-center justify-between">
              <div>
                <div className="text-[10px] uppercase tracking-[0.16em] text-obsidian-200">Good morning</div>
                <div className="display text-lg text-cream-50">Alex</div>
              </div>
              <div className="chip chip-gold">Day 34 · 🔥</div>
            </div>

            <div className="mt-4 flex flex-col items-center rounded-2xl border border-gold-400/20 bg-gold-400/5 py-5">
              <ScoreRing value={78} />
              <div className="mt-2 text-[11px] text-forge-green">Ready to train</div>
            </div>

            <div className="mt-3 rounded-xl border border-white/6 bg-obsidian-900/60 p-3">
              <div className="text-[9px] uppercase tracking-[0.18em] text-gold-300">Today</div>
              <div className="mt-1 text-sm text-cream-100">Lower — Posterior chain</div>
              <div className="mt-0.5 text-[11px] text-obsidian-200">5 exercises · ~52 min · cap RPE 8.5</div>
            </div>

            <div className="mt-3 grid grid-cols-3 gap-2">
              {[
                { l: "Recovery", v: "72" },
                { l: "Sleep", v: "7:12" },
                { l: "Protein", v: "148g" },
              ].map((s) => (
                <div key={s.l} className="rounded-xl border border-white/6 bg-obsidian-900/60 p-2 text-center">
                  <div className="stat-num text-lg text-cream-50">{s.v}</div>
                  <div className="text-[8px] uppercase tracking-wider text-obsidian-200">{s.l}</div>
                </div>
              ))}
            </div>

            <div className="mt-3 flex items-center gap-2 rounded-xl border border-gold-400/15 bg-obsidian-900/60 p-3">
              <span className="text-gold-300">✦</span>
              <span className="text-[11px] text-obsidian-100">&quot;Why is my bench stalling?&quot; — ask your coach</span>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
