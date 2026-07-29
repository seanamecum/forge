"use client";

import { useState } from "react";

const FAQS: { q: string; a: string }[] = [
  {
    q: "What exactly is Forge?",
    a: "Forge is a unified performance platform. It connects your wearables, training, recovery, nutrition, and goals, then uses an AI coach to turn all of it into one clear decision each day: what to do, how hard, and why. It's built for athletes, not casual step-counting.",
  },
  {
    q: "Which wearables and apps will it work with?",
    a: "We're building integrations for Apple Watch, WHOOP, Garmin, Oura, Fitbit, Polar, and Strava, with more to come. Forge unifies the signals from whatever you already wear — you don't have to switch devices.",
  },
  {
    q: "Is it only for elite athletes?",
    a: "No. Forge scales from serious beginners to competitive athletes. Whether you lift, run, do hybrid training, or play a sport, it meets you at your level and gets more useful the more it learns about you.",
  },
  {
    q: "When does Forge launch?",
    a: "We're rolling out in waves. Waitlist members get early access first; beta testers get in before that and help shape the product. Join the waitlist to hold your place.",
  },
  {
    q: "How much will it cost?",
    a: "Pricing is still being finalized. Waitlist and beta members will get founding-member pricing and lock in early-access perks. Joining the waitlist is completely free.",
  },
  {
    q: "What do beta testers actually do?",
    a: "You train with Forge and tell us what works and what doesn't — through quick surveys, in-app feedback, and the occasional call. In return you get free early access, direct influence on the roadmap, and founding-member status.",
  },
  {
    q: "Is my health data private?",
    a: "Yes. Your data is yours. We never sell personal data, and the AI coach only ever sees your information to help you — never anyone else's. You can export or delete your data at any time.",
  },
];

export function Faq() {
  const [open, setOpen] = useState<number | null>(0);
  return (
    <div className="mx-auto max-w-3xl divide-y divide-white/8">
      {FAQS.map((item, i) => {
        const isOpen = open === i;
        return (
          <div key={item.q}>
            <button
              type="button"
              onClick={() => setOpen(isOpen ? null : i)}
              aria-expanded={isOpen}
              className="flex w-full items-center justify-between gap-4 py-5 text-left"
            >
              <span className="display text-lg text-cream-50 sm:text-xl">{item.q}</span>
              <span
                className={`shrink-0 text-gold-300 transition-transform duration-300 ${isOpen ? "rotate-45" : ""}`}
                aria-hidden
              >
                <svg width="22" height="22" viewBox="0 0 24 24" fill="none">
                  <path d="M12 5v14M5 12h14" stroke="currentColor" strokeWidth="1.6" strokeLinecap="round" />
                </svg>
              </span>
            </button>
            <div
              className="grid transition-all duration-300 ease-out"
              style={{ gridTemplateRows: isOpen ? "1fr" : "0fr" }}
            >
              <div className="overflow-hidden">
                <p className="pb-5 pr-8 text-[15px] leading-relaxed text-obsidian-100">{item.a}</p>
              </div>
            </div>
          </div>
        );
      })}
    </div>
  );
}
