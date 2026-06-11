type Props = {
  label: string;
  value: string | number;
  unit?: string;
  delta?: string | number;
  deltaTone?: "good" | "bad" | "neutral";
  hint?: string;
  size?: "sm" | "md" | "lg";
};

export function Stat({
  label,
  value,
  unit,
  delta,
  deltaTone = "neutral",
  hint,
  size = "md",
}: Props) {
  const valueSize = size === "lg" ? "text-4xl" : size === "sm" ? "text-xl" : "text-2xl";
  return (
    <div>
      <div className="text-[10px] uppercase tracking-[0.16em] text-obsidian-200">{label}</div>
      <div className="mt-1 flex items-baseline gap-1.5">
        <span className={`stat-num text-cream-50 ${valueSize}`}>{value}</span>
        {unit && <span className="text-xs text-obsidian-200">{unit}</span>}
        {delta !== undefined && delta !== "" && (
          <span
            className={`text-xs ${
              deltaTone === "good"
                ? "text-forge-green"
                : deltaTone === "bad"
                ? "text-forge-ruby"
                : "text-obsidian-200"
            }`}
          >
            {typeof delta === "number"
              ? `${delta > 0 ? "+" : ""}${delta}`
              : delta}
          </span>
        )}
      </div>
      {hint && <div className="mt-0.5 text-[11px] text-obsidian-300">{hint}</div>}
    </div>
  );
}
