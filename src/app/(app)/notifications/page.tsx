"use client";

import { SectionTitle } from "@/components/ui/SectionTitle";
import { notifications } from "@/lib/mock/notifications";
import { useForge } from "@/lib/store";
import { toast } from "@/lib/toast";

const TONE: Record<string, { icon: string; color: string; bg: string }> = {
  progress: { icon: "▲", color: "text-forge-green", bg: "bg-forge-green/5 border-forge-green/20" },
  warning: { icon: "⚠", color: "text-forge-amber", bg: "bg-forge-amber/5 border-forge-amber/20" },
  recommendation: { icon: "✦", color: "text-gold-300", bg: "bg-gold-400/5 border-gold-400/20" },
  social: { icon: "❉", color: "text-forge-royal", bg: "bg-forge-royal/5 border-forge-royal/20" },
  streak: { icon: "🔥", color: "text-gold-grad", bg: "bg-gold-400/5 border-gold-400/30" },
  achievement: { icon: "★", color: "text-gold-grad", bg: "bg-gold-400/5 border-gold-400/30" },
};

export default function NotificationsPage() {
  const forge = useForge();

  return (
    <div className="space-y-6">
      <SectionTitle
        eyebrow="Daily"
        title="Notifications"
        subtitle="Forge surfaces real signal: increase weight today, recovery low, protein gap, magnesium intake, sleep debt, injury risk, PT due."
        right={
          <button
            className="btn-ghost text-xs"
            onClick={() => {
              forge.set("notifsRead", true);
              toast("All notifications marked read");
            }}
          >
            Mark all read
          </button>
        }
      />

      <div className="space-y-2">
        {notifications.map((n) => {
          const t = TONE[n.kind];
          const read = forge.notifsRead || n.read;
          return (
            <div
              key={n.id}
              className={`flex items-start gap-3 rounded-lg border p-4 ${t.bg} ${!read ? "ring-1 ring-gold-400/15" : "opacity-80"}`}
            >
              <span className={`grid h-9 w-9 shrink-0 place-items-center rounded-full border border-gold-400/20 bg-obsidian-900/60 text-lg ${t.color}`}>
                {t.icon}
              </span>
              <div className="flex-1">
                <div className="flex items-baseline justify-between gap-3">
                  <div className="text-sm text-cream-50">{n.title}</div>
                  <div className="text-[11px] text-obsidian-200">{n.time}</div>
                </div>
                <div className="mt-0.5 text-[12px] text-cream-200">{n.body}</div>
              </div>
              {!read && <span className="dot dot-gold" />}
            </div>
          );
        })}
      </div>
    </div>
  );
}
