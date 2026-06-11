"use client";

import Link from "next/link";
import { today, user } from "@/lib/mock/user";

export function TopBar() {
  return (
    <header className="sticky top-0 z-30 border-b border-gold-400/10 bg-obsidian-950/70 backdrop-blur">
      <div className="flex items-center justify-between px-4 py-3 sm:px-6 lg:px-8">
        <div className="flex items-center gap-4">
          <div className="hidden sm:block">
            <div className="text-[10px] uppercase tracking-[0.18em] text-obsidian-200">
              {today.date}
            </div>
            <div className="display text-cream-50 text-base">
              Good morning, <span className="text-gold-grad">{user.name.split(" ")[0]}</span>
            </div>
          </div>
        </div>

        <div className="flex items-center gap-3">
          <div className="hidden md:flex items-center gap-1 rounded-full border border-gold-400/15 bg-obsidian-800/60 px-3 py-1.5 text-xs text-cream-200">
            <span className="dot dot-green" /> All wearables synced
          </div>

          <Link
            href="/coach"
            className="hidden sm:inline-flex items-center gap-2 rounded-full border border-gold-400/30 bg-gold-400/5 px-3 py-1.5 text-xs text-gold-200 hover:bg-gold-400/10"
          >
            <span className="animate-pulse-gold">✦</span> Ask the Coach
          </Link>

          <Link
            href="/notifications"
            className="relative grid h-8 w-8 place-items-center rounded-full border border-gold-400/15 text-cream-200 hover:border-gold-400/40"
            aria-label="Notifications"
          >
            ◷
            <span className="absolute -right-0.5 -top-0.5 grid h-4 w-4 place-items-center rounded-full bg-forge-ruby text-[9px] text-cream-50">
              3
            </span>
          </Link>
        </div>
      </div>
    </header>
  );
}
