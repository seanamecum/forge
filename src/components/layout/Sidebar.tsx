"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import { ForgeWordmark } from "../ui/Logo";

const SECTIONS: { label: string; items: { name: string; href: string; icon: string }[] }[] = [
  {
    label: "Daily",
    items: [
      { name: "Dashboard", href: "/dashboard", icon: "◆" },
      { name: "AI Coach", href: "/coach", icon: "✦" },
      { name: "Notifications", href: "/notifications", icon: "◷" },
    ],
  },
  {
    label: "Train",
    items: [
      { name: "Workouts", href: "/workouts", icon: "▲" },
      { name: "Exercises", href: "/exercises", icon: "❒" },
      { name: "Workout Generator", href: "/generate", icon: "✺" },
      { name: "Form Analysis", href: "/form-analysis", icon: "◬" },
    ],
  },
  {
    label: "Fuel",
    items: [
      { name: "Nutrition", href: "/nutrition", icon: "◉" },
      { name: "Deficiencies", href: "/deficiencies", icon: "▼" },
      { name: "Supplements", href: "/supplements", icon: "❖" },
    ],
  },
  {
    label: "Recover",
    items: [
      { name: "Recovery & Sleep", href: "/recovery", icon: "☾" },
      { name: "Wearables", href: "/wearables", icon: "◐" },
      { name: "Forge Recovery (Injury / PT)", href: "/injury", icon: "✚" },
    ],
  },
  {
    label: "Body & Health",
    items: [
      { name: "Body Tracking", href: "/body", icon: "◧" },
      { name: "Bloodwork", href: "/bloodwork", icon: "❤" },
      { name: "Digital Twin / Forecast", href: "/forecast", icon: "✧" },
    ],
  },
  {
    label: "Community",
    items: [
      { name: "Feed", href: "/social", icon: "❉" },
      { name: "Leaderboards", href: "/leaderboards", icon: "♔" },
      { name: "Challenges", href: "/challenges", icon: "⚑" },
      { name: "Achievements", href: "/achievements", icon: "★" },
    ],
  },
  {
    label: "Marketplace",
    items: [
      { name: "Coaches & Programs", href: "/marketplace", icon: "❀" },
      { name: "Forge Teams", href: "/teams", icon: "◈" },
    ],
  },
];

export function Sidebar() {
  const pathname = usePathname();

  return (
    <aside className="sidebar fixed inset-y-0 left-0 z-40 hidden w-64 flex-col lg:flex">
      <div className="px-6 pt-6 pb-4">
        <Link href="/dashboard">
          <ForgeWordmark size={22} />
        </Link>
      </div>

      <div className="hairline mx-6" />

      <nav className="flex-1 overflow-y-auto px-3 py-4 text-sm">
        {SECTIONS.map((s) => (
          <div key={s.label} className="mb-5">
            <div className="px-3 mb-2 text-[10px] uppercase tracking-[0.22em] text-gold-300/70">
              {s.label}
            </div>
            <ul className="space-y-0.5">
              {s.items.map((i) => {
                const active = pathname === i.href || pathname?.startsWith(i.href + "/");
                return (
                  <li key={i.href}>
                    <Link
                      href={i.href}
                      className={`group flex items-center gap-3 rounded-lg px-3 py-2 transition ${
                        active
                          ? "bg-gold-400/8 text-gold-200"
                          : "text-cream-300 hover:bg-obsidian-700/50 hover:text-cream-100"
                      }`}
                    >
                      <span
                        className={`text-base ${
                          active ? "text-gold-300" : "text-obsidian-300 group-hover:text-gold-300/80"
                        }`}
                      >
                        {i.icon}
                      </span>
                      <span className="text-[13px]">{i.name}</span>
                    </Link>
                  </li>
                );
              })}
            </ul>
          </div>
        ))}
      </nav>

      <div className="hairline mx-6" />
      <div className="px-6 py-4">
        <div className="flex items-center gap-3">
          <div className="grid h-9 w-9 place-items-center rounded-full bg-gold-gradient text-[12px] font-semibold text-obsidian-900">
            MV
          </div>
          <div className="min-w-0">
            <div className="truncate text-sm text-cream-100">Marcus Vale</div>
            <div className="truncate text-[11px] text-obsidian-200">
              Level 24 · 🔥 47 day streak
            </div>
          </div>
        </div>
      </div>
    </aside>
  );
}
