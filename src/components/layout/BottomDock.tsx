"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";

const ITEMS = [
  { name: "Home", href: "/dashboard", icon: "◆" },
  { name: "Train", href: "/workouts", icon: "▲" },
  { name: "Coach", href: "/coach", icon: "✦" },
  { name: "Fuel", href: "/nutrition", icon: "◉" },
  { name: "Recover", href: "/recovery", icon: "☾" },
];

/** Slim floating pill — icon-only, one gold active state. */
export function BottomDock() {
  const pathname = usePathname();

  return (
    <nav className="fixed inset-x-0 bottom-4 z-40 flex justify-center lg:hidden">
      <ul className="flex items-center gap-1 rounded-full border border-white/[0.06] bg-obsidian-900/90 px-3 py-2 backdrop-blur">
        {ITEMS.map((i) => {
          const active = pathname === i.href;
          return (
            <li key={i.href}>
              <Link
                href={i.href}
                aria-label={i.name}
                className={`flex h-11 w-11 items-center justify-center rounded-full text-lg transition-colors ${
                  active ? "bg-gold-400/10 text-gold-400" : "text-obsidian-200"
                }`}
              >
                {i.icon}
              </Link>
            </li>
          );
        })}
      </ul>
    </nav>
  );
}
