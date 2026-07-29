import Link from "next/link";
import { ForgeWordmark } from "@/components/ui/Logo";

export function Footer() {
  return (
    <footer className="border-t border-gold-400/10 bg-obsidian-950/60">
      <div className="mx-auto max-w-7xl px-6 py-14">
        <div className="grid gap-10 md:grid-cols-[1.4fr_1fr_1fr_1fr]">
          <div>
            <ForgeWordmark size={22} />
            <p className="mt-4 max-w-xs text-sm text-obsidian-200">
              The performance operating system for athletes. Your training, recovery, and progress —
              engineered into one intelligent platform.
            </p>
          </div>

          <FooterCol
            title="Product"
            links={[
              { href: "/#features", label: "Features" },
              { href: "/#how", label: "How it works" },
              { href: "/#integrations", label: "Integrations" },
              { href: "/#marketplace", label: "Marketplace" },
            ]}
          />
          <FooterCol
            title="Get in"
            links={[
              { href: "/#waitlist", label: "Join the waitlist" },
              { href: "/beta", label: "Beta access" },
              { href: "/dashboard", label: "Live product demo" },
            ]}
          />
          <FooterCol
            title="Company"
            links={[
              { href: "/privacy", label: "Privacy" },
              { href: "/terms", label: "Terms" },
              { href: "/support", label: "Support" },
            ]}
          />
        </div>

        <div className="mt-12 flex flex-col items-center justify-between gap-4 border-t border-white/6 pt-6 text-xs text-obsidian-200 sm:flex-row">
          <div>© {new Date().getFullYear()} Forge Performance Systems. All rights reserved.</div>
          <div>Educational guidance, not medical advice.</div>
        </div>
      </div>
    </footer>
  );
}

function FooterCol({ title, links }: { title: string; links: { href: string; label: string }[] }) {
  return (
    <div>
      <div className="text-[11px] uppercase tracking-[0.2em] text-gold-300">{title}</div>
      <ul className="mt-4 space-y-2.5 text-sm text-obsidian-100">
        {links.map((l) => (
          <li key={l.href}>
            <Link href={l.href} className="transition-colors hover:text-gold-200">
              {l.label}
            </Link>
          </li>
        ))}
      </ul>
    </div>
  );
}
