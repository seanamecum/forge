export function ForgeMark({ size = 28 }: { size?: number }) {
  return (
    <svg viewBox="0 0 40 40" width={size} height={size} fill="none" aria-hidden>
      <defs>
        <linearGradient id="forge-mark" x1="0" y1="0" x2="40" y2="40">
          <stop offset="0%" stopColor="#f5dc7a" />
          <stop offset="55%" stopColor="#d4af37" />
          <stop offset="100%" stopColor="#a07f1f" />
        </linearGradient>
      </defs>
      {/* anvil / shield silhouette */}
      <path
        d="M20 3 L34 8 V18 C34 28 28 34 20 37 C12 34 6 28 6 18 V8 Z"
        stroke="url(#forge-mark)"
        strokeWidth="1.5"
        opacity="0.6"
      />
      {/* inner F flame */}
      <path
        d="M16 12 H26 V15 H19 V19 H24 V22 H19 V28 H16 Z"
        fill="url(#forge-mark)"
      />
      <circle cx="20" cy="34" r="1.2" fill="#f5dc7a" />
    </svg>
  );
}

export function ForgeWordmark({ size = 22 }: { size?: number }) {
  return (
    <div className="flex items-center gap-2">
      <ForgeMark size={size} />
      <span
        className="display tracking-[0.35em] uppercase text-cream-50"
        style={{ fontSize: size * 0.6, fontWeight: 600 }}
      >
        Forge
      </span>
    </div>
  );
}
