"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";

const ITEMS = [
  { name: "Home", href: "/dashboard", icon: "◆" },
  { name: "Train", href: "/workouts", icon: "▲" },
  { name: "Coach", href: "/coach", icon: "✦", gold: true },
  { name: "Fuel", href: "/nutrition", icon: "◉" },
  { name: "Recover", href: "/recovery", icon: "☾" },
];

export function BottomDock() {
  const pathname = usePathname();

  return (
    <nav className="dock fixed inset-x-0 bottom-0 z-40 lg:hidden">
      <ul className="grid grid-cols-5 px-2 py-2">
        {ITEMS.map((i) => {
          const active = pathname === i.href;
          return (
            <li key={i.href}>
              <Link
                href={i.href}
                className={`flex flex-col items-center justify-center gap-0.5 rounded-lg px-2 py-1.5 ${
                  active ? "text-gold-200" : i.gold ? "text-gold-300" : "text-cream-300"
                }`}
              >
                <span
                  className={`text-lg ${i.gold ? "animate-pulse-gold" : ""}`}
                  style={{
                    filter: i.gold
                      ? "drop-shadow(0 0 8px rgba(212,175,55,0.6))"
                      : undefined,
                  }}
                >
                  {i.icon}
                </span>
                <span className="text-[10px] uppercase tracking-wide">{i.name}</span>
              </Link>
            </li>
          );
        })}
      </ul>
    </nav>
  );
}
