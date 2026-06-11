import { SectionTitle } from "@/components/ui/SectionTitle";
import { feed, groups } from "@/lib/mock/social";

export default function SocialPage() {
  return (
    <div className="space-y-6">
      <SectionTitle
        eyebrow="Community"
        title="Feed"
        subtitle="For the athletes that get it. PRs, progress, programming wisdom — no calorie shaming."
        right={<button className="btn-gold text-xs">+ Post</button>}
      />

      <div className="grid gap-6 lg:grid-cols-[1fr,300px]">
        <div className="space-y-4">
          {feed.map((p) => (
            <div key={p.id} className="card p-5">
              <div className="mb-3 flex items-center gap-3">
                <div className="grid h-10 w-10 place-items-center rounded-full bg-gold-gradient text-[12px] font-semibold text-obsidian-900">
                  {initials(p.user.name)}
                </div>
                <div>
                  <div className="text-sm text-cream-50">{p.user.name}</div>
                  <div className="text-[11px] text-obsidian-200">
                    Lv {p.user.level} · {p.user.handle} · {p.time}
                  </div>
                </div>
                <span className="ml-auto chip chip-gold">{p.kind.toUpperCase()}</span>
              </div>

              <div className="text-[14px] leading-relaxed text-cream-100">{p.body}</div>

              {p.stat && (
                <div className="mt-3 rounded-md border border-gold-400/15 bg-gold-400/5 p-3">
                  <div className="text-[10px] uppercase tracking-wider text-gold-300">{p.stat.label}</div>
                  <div className="mt-0.5 stat-num text-xl text-gold-grad">{p.stat.value}</div>
                </div>
              )}

              <div className="mt-4 flex items-center gap-5 text-[12px] text-obsidian-200">
                <button className="hover:text-gold-200">♡ {p.likes}</button>
                <button className="hover:text-gold-200">💬 {p.comments}</button>
                <button className="hover:text-gold-200 ml-auto">↗ share</button>
              </div>
            </div>
          ))}
        </div>

        <aside className="space-y-4">
          <div className="card p-5">
            <div className="text-[10px] uppercase tracking-[0.22em] text-gold-300">Groups</div>
            <div className="mt-3 space-y-2">
              {groups.map((g) => (
                <div key={g.id} className="rounded-md border border-gold-400/8 bg-obsidian-800/40 p-3">
                  <div className="flex items-baseline justify-between">
                    <div className="text-sm text-cream-100">{g.name}</div>
                    <span className="chip">{g.tag}</span>
                  </div>
                  <div className="mt-1 text-[11px] text-obsidian-200">{g.members.toLocaleString()} members</div>
                  <div className="mt-1 text-[11px] text-cream-200">{g.description}</div>
                </div>
              ))}
            </div>
          </div>
        </aside>
      </div>
    </div>
  );
}

function initials(n: string) {
  return n.split(" ").map((p) => p[0]).join("").slice(0, 2).toUpperCase();
}
