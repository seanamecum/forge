"use client";

import Link from "next/link";
import { useEffect, useState } from "react";
import { ForgeWordmark } from "@/components/ui/Logo";
import { AnalyticsEvent, track } from "@/lib/analytics";

const LINKS = [
  { href: "/#features", label: "Features" },
  { href: "/#how", label: "How it works" },
  { href: "/#integrations", label: "Integrations" },
  { href: "/#faq", label: "FAQ" },
];

export function MarketingNav() {
  const [open, setOpen] = useState(false);
  const [scrolled, setScrolled] = useState(false);

  useEffect(() => {
    const onScroll = () => setScrolled(window.scrollY > 12);
    onScroll();
    window.addEventListener("scroll", onScroll, { passive: true });
    return () => window.removeEventListener("scroll", onScroll);
  }, []);

  // Lock body scroll when the mobile menu is open.
  useEffect(() => {
    document.body.style.overflow = open ? "hidden" : "";
    return () => {
      document.body.style.overflow = "";
    };
  }, [open]);

  return (
    <header
      className={`sticky top-0 z-50 transition-colors duration-300 ${
        scrolled ? "border-b border-gold-400/10 bg-obsidian-950/80 backdrop-blur-xl" : "bg-transparent"
      }`}
    >
      <div className="mx-auto flex max-w-7xl items-center justify-between px-5 py-4 sm:px-6">
        <Link href="/" aria-label="Forge home">
          <ForgeWordmark size={24} />
        </Link>

        <nav className="hidden items-center gap-8 text-sm text-cream-200 md:flex">
          {LINKS.map((l) => (
            <a key={l.href} href={l.href} className="transition-colors hover:text-gold-200">
              {l.label}
            </a>
          ))}
        </nav>

        <div className="hidden items-center gap-3 md:flex">
          <Link href="/beta" className="btn-ghost text-xs" onClick={() => track(AnalyticsEvent.CtaClicked, { cta: "nav_beta" })}>
            Beta Access
          </Link>
          <a href="/#waitlist" className="btn-gold text-xs" onClick={() => track(AnalyticsEvent.CtaClicked, { cta: "nav_waitlist" })}>
            Join Waitlist
          </a>
        </div>

        <button
          type="button"
          className="btn-quiet md:hidden"
          aria-label={open ? "Close menu" : "Open menu"}
          aria-expanded={open}
          onClick={() => setOpen((v) => !v)}
        >
          <svg width="24" height="24" viewBox="0 0 24 24" fill="none" aria-hidden>
            {open ? (
              <path d="M6 6l12 12M18 6L6 18" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" />
            ) : (
              <path d="M4 7h16M4 12h16M4 17h16" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" />
            )}
          </svg>
        </button>
      </div>

      {/* Mobile menu */}
      {open && (
        <div className="fixed inset-0 top-[64px] z-40 bg-obsidian-950/98 backdrop-blur-xl md:hidden">
          <nav className="flex flex-col gap-1 px-6 py-6">
            {LINKS.map((l) => (
              <a
                key={l.href}
                href={l.href}
                onClick={() => setOpen(false)}
                className="border-b border-white/6 py-4 text-lg text-cream-100"
              >
                {l.label}
              </a>
            ))}
            <div className="mt-6 flex flex-col gap-3">
              <Link href="/beta" className="btn-ghost" onClick={() => setOpen(false)}>
                Apply for Beta Access
              </Link>
              <a href="/#waitlist" className="btn-gold" onClick={() => setOpen(false)}>
                Join the Waitlist
              </a>
            </div>
          </nav>
        </div>
      )}
    </header>
  );
}
