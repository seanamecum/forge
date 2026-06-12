"use client";

import { useState } from "react";
import { SectionTitle } from "@/components/ui/SectionTitle";
import { feed, groups } from "@/lib/mock/social";
import { useForge } from "@/lib/store";
import { toast } from "@/lib/toast";

export default function SocialPage() {
  const forge = useForge();
  const [composer, setComposer] = useState(false);
  const [draft, setDraft] = useState("");
  const [joinedGroups, setJoinedGroups] = useState<Record<string, boolean>>({ g1: true });

  function publish() {
    const body = draft.trim();
    if (!body) return;
    forge.addPost(body);
    setDraft("");
    setComposer(false);
    toast("Posted to the feed · +40 XP");
  }

  return (
    <div className="space-y-6">
      <SectionTitle
        eyebrow="Community"
        title="Feed"
        subtitle="For the athletes that get it. PRs, progress, programming wisdom — no calorie shaming."
        right={
          <button className="btn-gold text-xs" onClick={() => setComposer((c) => !c)}>
            + Post
          </button>
        }
      />

      <div className="grid gap-6 lg:grid-cols-[1fr,300px]">
        <div className="space-y-4">
          {composer && (
            <div className="card card-gold p-5">
              <div className="mb-2 text-[10px] uppercase tracking-[0.22em] text-gold-300">New post</div>
              <textarea
                value={draft}
                onChange={(e) => setDraft(e.target.value)}
                placeholder="Share a PR, a session, or something the group needs to hear…"
                className="input min-h-[80px] resize-none"
              />
              <div className="mt-3 flex justify-end gap-2">
                <button className="btn-quiet text-xs" onClick={() => setComposer(false)}>Cancel</button>
                <button className="btn-gold text-xs" onClick={publish}>Publish</button>
              </div>
            </div>
          )}

          {forge.posts.map((p, i) => (
            <div key={`mine-${i}`} className="card p-5">
              <div className="mb-3 flex items-center gap-3">
                <div className="grid h-10 w-10 place-items-center rounded-full bg-gold-gradient text-[12px] font-semibold text-obsidian-900">MV</div>
                <div>
                  <div className="text-sm text-cream-50">Marcus Vale</div>
                  <div className="text-[11px] text-obsidian-200">Lv 24 · @mvale · {p.time}</div>
                </div>
                <span className="ml-auto chip chip-gold">SHARE</span>
              </div>
              <div className="text-[14px] leading-relaxed text-cream-100">{p.body}</div>
              <div className="mt-4 flex items-center gap-5 text-[12px] text-obsidian-200">
                <span>♡ 0</span><span>💬 0</span>
                <span className="ml-auto text-gold-300">just posted</span>
              </div>
            </div>
          ))}

          {feed.map((p) => {
            const liked = !!forge.likes[p.id];
            return (
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
                  <button
                    onClick={() => forge.toggleLike(p.id)}
                    className={liked ? "text-forge-ruby" : "hover:text-gold-200"}
                  >
                    {liked ? "♥" : "♡"} {p.likes + (liked ? 1 : 0)}
                  </button>
                  <button className="hover:text-gold-200" onClick={() => toast("Comments open in the full thread view")}>
                    💬 {p.comments}
                  </button>
                  <button className="ml-auto hover:text-gold-200" onClick={() => toast("Share link copied")}>
                    ↗ share
                  </button>
                </div>
              </div>
            );
          })}
        </div>

        <aside className="space-y-4">
          <div className="card p-5">
            <div className="text-[10px] uppercase tracking-[0.22em] text-gold-300">Groups</div>
            <div className="mt-3 space-y-2">
              {groups.map((g) => {
                const joined = !!joinedGroups[g.id];
                return (
                  <div key={g.id} className="rounded-md border border-gold-400/8 bg-obsidian-800/40 p-3">
                    <div className="flex items-baseline justify-between">
                      <div className="text-sm text-cream-100">{g.name}</div>
                      <span className="chip">{g.tag}</span>
                    </div>
                    <div className="mt-1 text-[11px] text-obsidian-200">
                      {(g.members + (joined ? 1 : 0)).toLocaleString()} members
                    </div>
                    <div className="mt-1 text-[11px] text-cream-200">{g.description}</div>
                    <button
                      onClick={() => {
                        setJoinedGroups((j) => ({ ...j, [g.id]: !joined }));
                        toast(joined ? `Left ${g.name}` : `Joined ${g.name}`);
                      }}
                      className={`mt-2 w-full ${joined ? "btn-quiet" : "btn-ghost"} !py-1.5 text-[11px]`}
                    >
                      {joined ? "Joined ✓" : "Join group"}
                    </button>
                  </div>
                );
              })}
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
