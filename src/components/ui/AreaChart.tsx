/** The one chart style: thin gold line, gradient fill to transparent. Pure SVG. */
export function AreaChart({
  values,
  height = 120,
  id = "area",
}: {
  values: number[];
  height?: number;
  id?: string;
}) {
  if (values.length < 2) return null;
  const w = 100;
  const min = Math.min(...values);
  const max = Math.max(...values);
  const span = max - min || 1;
  const pts = values.map((v, i) => {
    const x = (i / (values.length - 1)) * w;
    const y = 6 + (1 - (v - min) / span) * (height - 12);
    return [x, y] as const;
  });
  const line = pts.map(([x, y], i) => `${i === 0 ? "M" : "L"}${x.toFixed(2)},${y.toFixed(2)}`).join(" ");
  const area = `${line} L${w},${height} L0,${height} Z`;
  return (
    <svg viewBox={`0 0 ${w} ${height}`} preserveAspectRatio="none" className="w-full" style={{ height }}>
      <defs>
        <linearGradient id={id} x1="0" y1="0" x2="0" y2="1">
          <stop offset="0%" stopColor="#d4af37" stopOpacity="0.22" />
          <stop offset="100%" stopColor="#d4af37" stopOpacity="0" />
        </linearGradient>
      </defs>
      <path d={area} fill={`url(#${id})`} />
      <path d={line} fill="none" stroke="#d4af37" strokeWidth="1.5" vectorEffect="non-scaling-stroke" />
    </svg>
  );
}
