type RingProps = {
  value: number; // 0-100
  size?: number;
  stroke?: number;
  label?: string;
  sublabel?: string;
  tone?: "gold" | "green" | "ruby" | "royal";
  trend?: number; // +/-
  big?: boolean;
};

const TONE: Record<NonNullable<RingProps["tone"]>, { from: string; to: string; text: string }> = {
  gold: { from: "#f5dc7a", to: "#a07f1f", text: "#e9c659" },
  green: { from: "#7ce4b5", to: "#2b6a4d", text: "#5dd39e" },
  ruby: { from: "#c25f74", to: "#5a1822", text: "#c25f74" },
  royal: { from: "#6b8fcc", to: "#1f3866", text: "#6b8fcc" },
};

export function Ring({
  value,
  size = 160,
  stroke = 10,
  label,
  sublabel,
  tone = "gold",
  trend,
  big = false,
}: RingProps) {
  const radius = (size - stroke) / 2;
  const circ = 2 * Math.PI * radius;
  const v = Math.max(0, Math.min(100, value));
  const dash = (v / 100) * circ;
  const id = `g-${tone}-${size}`;
  const colors = TONE[tone];

  return (
    <div className="relative inline-flex items-center justify-center">
      <svg width={size} height={size} className="-rotate-90">
        <defs>
          <linearGradient id={id} x1="0" y1="0" x2="1" y2="1">
            <stop offset="0%" stopColor={colors.from} />
            <stop offset="100%" stopColor={colors.to} />
          </linearGradient>
        </defs>
        <circle
          cx={size / 2}
          cy={size / 2}
          r={radius}
          stroke="rgba(212, 175, 55, 0.08)"
          strokeWidth={stroke}
          fill="none"
        />
        <circle
          cx={size / 2}
          cy={size / 2}
          r={radius}
          stroke={`url(#${id})`}
          strokeWidth={stroke}
          fill="none"
          strokeLinecap="round"
          strokeDasharray={`${dash} ${circ}`}
          style={{ filter: `drop-shadow(0 0 8px ${colors.from}55)` }}
        />
      </svg>
      <div className="absolute inset-0 flex flex-col items-center justify-center">
        <div
          className="stat-num leading-none"
          style={{
            fontSize: big ? size * 0.32 : size * 0.26,
            color: colors.text,
          }}
        >
          {Math.round(v)}
        </div>
        {label && (
          <div
            className="mt-1 text-[10px] uppercase tracking-[0.18em] text-obsidian-200"
            style={{ fontSize: big ? 12 : 10 }}
          >
            {label}
          </div>
        )}
        {sublabel && (
          <div className="mt-0.5 text-[10px] text-obsidian-300">{sublabel}</div>
        )}
        {trend !== undefined && (
          <div
            className={`mt-1 text-[10px] ${trend >= 0 ? "text-forge-green" : "text-forge-ruby"}`}
          >
            {trend >= 0 ? "▲" : "▼"} {Math.abs(trend)}
          </div>
        )}
      </div>
    </div>
  );
}
