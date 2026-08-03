"use client";

import Link from "next/link";
import { useEffect, useRef, useState } from "react";
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
  const toggleRef = useRef<HTMLButtonElement>(null);
  const menuRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    const onScroll = () => setScrolled(window.scrollY > 12);
    onScroll();
    window.addEventListener("scroll", onScroll, { passive: true });
    return () => window.removeEventListener("scroll", onScroll);
  }, []);

  // Close the menu once the viewport crosses into the desktop nav, so the body
  // scroll lock can never persist after a rotate/resize (the hamburger — and thus
  // the only way to close — disappears above 768px).
  useEffect(() => {
    const mq = window.matchMedia("(min-width: 768px)");
    const onChange = (e: MediaQueryListEvent) => {
      if (e.matches) setOpen(false);
    };
    mq.addEventListener("change", onChange);
    return () => mq.removeEventListener("change", onChange);
  }, []);

  // Body scroll lock while the menu is open. The cleanup ALWAYS restores scroll —
  // on close, on unmount (route change), and on breakpoint-close above.
  useEffect(() => {
    if (!open) return;
    document.body.style.overflow = "hidden";
    return () => {
      document.body.style.overflow = "";
    };
  }, [open]);

  // Escape to close; move focus into the menu on open and back to the toggle on
  // close, so keyboard focus is never lost behind the overlay.
  useEffect(() => {
    if (!open) return;
    const toggle = toggleRef.current; // capture now; the same node exists at cleanup
    const onKey = (e: KeyboardEvent) => {
      if (e.key === "Escape") setOpen(false);
    };
    document.addEventListener("keydown", onKey);
    menuRef.current?.querySelector<HTMLElement>("a, button")?.focus();
    return () => {
      document.removeEventListener("keydown", onKey);
      if (toggle && document.contains(toggle)) toggle.focus();
    };
  }, [open]);

  return (
    <>
      <header
        className={`sticky top-0 z-50 pt-[env(safe-area-inset-top)] transition-colors duration-300 ${
          scrolled ? "border-b border-gold-400/10 bg-obsidian-950/80 backdrop-blur-xl" : "bg-transparent"
        }`}
      >
        {/* The header (z-50) is a SIBLING of the menu (z-40), so the logo + close
            button always paint above the overlay and stay tappable. */}
        <div className="mx-auto flex max-w-7xl items-center justify-between px-5 py-4 sm:px-6">
        <Link href="/" aria-label="Forge home" onClick={() => setOpen(false)}>
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
          ref={toggleRef}
          type="button"
          className="btn-quiet md:hidden"
          aria-label={open ? "Close menu" : "Open menu"}
          aria-expanded={open}
          aria-controls="mobile-menu"
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
      </header>

      {/* Mobile menu — a SIBLING of the header (not a descendant), so no ancestor
          backdrop-filter/transform can turn it into a containing block and shrink it.
          Full-screen, scrollable (landscape), clears the notch + home bar. */}
      {open && (
        <div
          id="mobile-menu"
          ref={menuRef}
          role="dialog"
          aria-modal="true"
          aria-label="Menu"
          className="fixed inset-0 z-40 overflow-y-auto overscroll-contain bg-obsidian-950/95 pb-[env(safe-area-inset-bottom)] backdrop-blur-xl md:hidden"
        >
          <nav className="flex flex-col gap-1 px-6 pb-10 pt-[calc(5rem_+_env(safe-area-inset-top))]">
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
    </>
  );
}
