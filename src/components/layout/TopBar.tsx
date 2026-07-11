"use client";

import Link from "next/link";
import { user } from "@/lib/mock/user";

/** Slim top bar — wordmark and avatar. Everything else earned its removal. */
export function TopBar() {
  return (
    <header className="sticky top-0 z-30 bg-obsidian-950/80 backdrop-blur">
      <div className="flex items-center justify-between px-5 py-4 lg:px-8">
        <Link href="/dashboard" className="text-sm font-bold tracking-[0.25em] text-cream-100">
          FORGE
        </Link>
        <Link
          href="/notifications"
          className="flex h-9 w-9 items-center justify-center rounded-full border border-white/[0.06] text-[11px] font-bold text-gold-400"
        >
          {user.name.split(" ").map((p) => p[0]).join("").slice(0, 2)}
        </Link>
      </div>
    </header>
  );
}
