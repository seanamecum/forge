import type { Metadata } from "next";
import Link from "next/link";
import { MarketingNav } from "@/components/marketing/MarketingNav";
import { Footer } from "@/components/marketing/Footer";
import { Reveal } from "@/components/marketing/Reveal";
import { BetaForm } from "@/components/marketing/BetaForm";

export const metadata: Metadata = {
  title: "Apply for Beta Access — Forge",
  description:
    "Help shape Forge before launch. Beta testers get free early access, founding-member status, and a direct line to the team. Apply in two minutes.",
  alternates: { canonical: "/beta" },
};

export default function BetaPage() {
  return (
    <div className="bg-forge min-h-screen">
      <MarketingNav />

      <section className="relative overflow-hidden">
        <div className="absolute inset-0 bg-mesh opacity-30" />
        <div className="relative mx-auto max-w-5xl px-6 pb-8 pt-14 text-center md:pt-20">
          <Reveal>
            <span className="chip chip-gold">Beta program</span>
            <h1 className="display mt-4 text-4xl text-cream-50 sm:text-6xl">
              Become a <span className="display-italic text-gold-grad">Forge</span> beta tester.
            </h1>
            <p className="mx-auto mt-5 max-w-2xl text-obsidian-100 sm:text-lg">
              We&apos;re inviting a focused group of serious athletes, coaches, and creators to test Forge
              before launch. Tell us about your training and we&apos;ll match you to an upcoming build.
            </p>
          </Reveal>
        </div>
      </section>

      <section className="pb-24">
        <div className="mx-auto max-w-5xl px-6">
          <div className="grid gap-8 lg:grid-cols-[1fr_1.4fr]">
            {/* Perks rail */}
            <Reveal>
              <aside className="lg:sticky lg:top-24">
                <div className="card p-6">
                  <div className="text-[11px] uppercase tracking-[0.2em] text-gold-300">What you get</div>
                  <ul className="mt-4 space-y-4">
                    {[
                      { t: "Free early access", d: "Use the full product before launch — no cost." },
                      { t: "Founding-member status", d: "Locked-in pricing and perks when we go live." },
                      { t: "Real influence", d: "Your feedback directly shapes the roadmap." },
                      { t: "Direct line to the team", d: "Talk to the people building Forge." },
                    ].map((p) => (
                      <li key={p.t} className="flex gap-3">
                        <span className="mt-0.5 text-gold-300">✦</span>
                        <div>
                          <div className="text-cream-50">{p.t}</div>
                          <div className="text-[13px] text-obsidian-200">{p.d}</div>
                        </div>
                      </li>
                    ))}
                  </ul>
                  <div className="hairline my-5" />
                  <p className="text-[13px] text-obsidian-200">
                    Not ready to commit? {" "}
                    <Link href="/#waitlist" className="text-gold-300 hover:text-gold-200">
                      Join the waitlist instead →
                    </Link>
                  </p>
                </div>
              </aside>
            </Reveal>

            {/* Application */}
            <Reveal delay={100}>
              <div className="card card-gold p-6 sm:p-8">
                <h2 className="display text-2xl text-cream-50">Application</h2>
                <p className="mb-6 mt-1 text-sm text-obsidian-200">Takes about two minutes. Fields marked * are required.</p>
                <BetaForm />
              </div>
            </Reveal>
          </div>
        </div>
      </section>

      <Footer />
    </div>
  );
}
