type Props = {
  eyebrow?: string;
  title: string;
  subtitle?: string;
  right?: React.ReactNode;
};

export function SectionTitle({ eyebrow, title, subtitle, right }: Props) {
  return (
    <div className="mb-4 flex items-end justify-between gap-4">
      <div>
        {eyebrow && (
          <div className="mb-1 text-[10px] uppercase tracking-[0.22em] text-gold-300">
            {eyebrow}
          </div>
        )}
        <h2 className="display text-2xl text-cream-50 sm:text-3xl">{title}</h2>
        {subtitle && (
          <p className="mt-1 max-w-2xl text-sm text-obsidian-200">{subtitle}</p>
        )}
      </div>
      {right}
    </div>
  );
}
