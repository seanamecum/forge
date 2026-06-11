type SparkProps = {
  data: number[];
  width?: number;
  height?: number;
  stroke?: string;
  fill?: string;
  showDot?: boolean;
  className?: string;
};

export function Sparkline({
  data,
  width = 140,
  height = 40,
  stroke = "#d4af37",
  fill = "rgba(212, 175, 55, 0.12)",
  showDot = true,
  className,
}: SparkProps) {
  if (data.length === 0) return null;
  const min = Math.min(...data);
  const max = Math.max(...data);
  const range = max - min || 1;
  const stepX = width / (data.length - 1 || 1);
  const points = data.map((v, i) => {
    const x = i * stepX;
    const y = height - ((v - min) / range) * (height - 4) - 2;
    return [x, y] as const;
  });
  const path = points.map((p, i) => `${i === 0 ? "M" : "L"}${p[0]},${p[1]}`).join(" ");
  const area = `${path} L${width},${height} L0,${height} Z`;
  const last = points[points.length - 1];
  const id = Math.random().toString(36).slice(2, 7);

  return (
    <svg width={width} height={height} className={className}>
      <defs>
        <linearGradient id={`grad-${id}`} x1="0" y1="0" x2="0" y2="1">
          <stop offset="0%" stopColor={stroke} stopOpacity="0.25" />
          <stop offset="100%" stopColor={stroke} stopOpacity="0" />
        </linearGradient>
      </defs>
      <path d={area} fill={`url(#grad-${id})`} />
      <path d={path} fill="none" stroke={stroke} strokeWidth="1.4" strokeLinecap="round" />
      {showDot && (
        <>
          <circle cx={last[0]} cy={last[1]} r="4" fill={stroke} opacity="0.2" />
          <circle cx={last[0]} cy={last[1]} r="2" fill={stroke} />
        </>
      )}
    </svg>
  );
}

export function Barline({
  data,
  width = 240,
  height = 60,
  color = "#d4af37",
}: {
  data: number[];
  width?: number;
  height?: number;
  color?: string;
}) {
  const max = Math.max(...data);
  const barW = (width - 4) / data.length;
  return (
    <svg width={width} height={height}>
      {data.map((v, i) => {
        const h = (v / max) * (height - 6);
        return (
          <rect
            key={i}
            x={i * barW + 1}
            y={height - h - 2}
            width={barW - 2}
            height={h}
            rx={1.5}
            fill={color}
            opacity={0.35 + (i / data.length) * 0.6}
          />
        );
      })}
    </svg>
  );
}
