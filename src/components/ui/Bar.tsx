type Props = {
  value: number;
  max: number;
  tone?: "gold" | "green" | "ruby" | "amber" | "royal";
  height?: number;
  label?: string;
  rightLabel?: string;
  zones?: { from: number; to: number; tone: "good" | "warn" }[];
};

const TONE = {
  gold: "linear-gradient(90deg, #f5dc7a, #d4af37 60%, #a07f1f)",
  green: "linear-gradient(90deg, #7ce4b5, #5dd39e 60%, #2b6a4d)",
  ruby: "linear-gradient(90deg, #c25f74, #9b2a3f 60%, #5a1822)",
  amber: "linear-gradient(90deg, #f7d97a, #e9b949 60%, #a07f1f)",
  royal: "linear-gradient(90deg, #6b8fcc, #3a5a8c 60%, #1f3866)",
};

export function Bar({
  value,
  max,
  tone = "gold",
  height = 8,
  label,
  rightLabel,
  zones,
}: Props) {
  const pct = Math.max(0, Math.min(100, (value / max) * 100));
  return (
    <div>
      {(label || rightLabel) && (
        <div className="mb-1 flex items-baseline justify-between text-xs">
          {label && <span className="text-obsidian-200">{label}</span>}
          {rightLabel && <span className="text-cream-200">{rightLabel}</span>}
        </div>
      )}
      <div
        className="relative w-full overflow-hidden rounded-full"
        style={{
          height,
          background: "rgba(212, 175, 55, 0.06)",
          border: "1px solid rgba(212, 175, 55, 0.06)",
        }}
      >
        {zones?.map((z, i) => (
          <div
            key={i}
            className="absolute inset-y-0"
            style={{
              left: `${(z.from / max) * 100}%`,
              width: `${((z.to - z.from) / max) * 100}%`,
              background: z.tone === "good" ? "rgba(93, 211, 158, 0.08)" : "rgba(233, 185, 73, 0.08)",
            }}
          />
        ))}
        <div
          className="absolute inset-y-0 left-0 transition-all"
          style={{
            width: `${pct}%`,
            background: TONE[tone],
            boxShadow: `0 0 10px ${tone === "gold" ? "rgba(212,175,55,0.4)" : "rgba(93,211,158,0.25)"}`,
          }}
        />
      </div>
    </div>
  );
}
