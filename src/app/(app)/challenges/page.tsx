"use client";

import { SectionTitle } from "@/components/ui/SectionTitle";
import { Bar } from "@/components/ui/Bar";
import { challenges } from "@/lib/mock/social";
import { useForge } from "@/lib/store";
import { toast } from "@/lib/toast";

export default function ChallengesPage() {
  const forge = useForge();

  return (
    <div className="space-y-6">
      <SectionTitle
        eyebrow="Community"
        title="Challenges"
        subtitle="Pick a fight with the calendar. Win badges, prove identity, build streaks."
      />

      <div className="grid gap-4 lg:grid-cols-3">
        {challenges.map((c) => {
          const joined = !!forge.joinedChallenges[c.id];
          return (
            <div key={c.id} className="card card-hover p-5">
              <div className="mb-3 flex items-start justify-between gap-2">
                <div>
                  <div className="display text-lg text-cream-50">{c.name}</div>
                  <div className="mt-0.5 text-[11px] text-obsidian-200">
                    {(c.participants + (joined ? 1 : 0)).toLocaleString()} participants
                  </div>
                </div>
                <span className="chip chip-gold">{c.daysLeft}d left</span>
              </div>

              <div className="mt-3">
                <div className="mb-1 flex justify-between text-[10px] text-obsidian-200">
                  <span>Day 8</span>
                  <span>Day 30</span>
                </div>
                <Bar value={8} max={30} tone={joined ? "green" : "gold"} height={4} />
              </div>

              <div className="mt-3 text-[12px] text-cream-200">
                Reward · <span className="text-gold-200">{c.reward}</span>
              </div>

              <div className="mt-4 flex gap-2">
                <button
                  onClick={() => {
                    forge.toggleChallenge(c.id);
                    toast(joined ? `Left ${c.name}` : `Joined ${c.name} — day 1 starts now`);
                  }}
                  className={joined ? "btn-ghost flex-1 text-[11px]" : "btn-gold flex-1 text-[11px]"}
                >
                  {joined ? "Joined ✓ (leave)" : "Join"}
                </button>
                <button className="btn-quiet text-[11px]" onClick={() => toast(`${c.name}: top 10% earn the ${c.reward}. Progress syncs from your logs automatically.`)}>
                  Details
                </button>
              </div>
            </div>
          );
        })}
      </div>
    </div>
  );
}
