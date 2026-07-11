/** The one oversized numeral per screen — huge, bold, quiet label beneath. */
export function StatHero({
  value,
  label,
  accent = false,
}: {
  value: string | number;
  label: string;
  accent?: boolean;
}) {
  return (
    <div>
      <div
        className={`text-7xl font-bold tabular-nums tracking-tight sm:text-8xl ${
          accent ? "text-gold-400" : "text-cream-100"
        }`}
      >
        {value}
      </div>
      <div className="mt-2 text-[11px] font-normal text-obsidian-200">{label}</div>
    </div>
  );
}
