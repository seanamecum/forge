import type { Metadata } from "next";
import Link from "next/link";
import { MarketingNav } from "@/components/marketing/MarketingNav";
import { Footer } from "@/components/marketing/Footer";
import { Reveal } from "@/components/marketing/Reveal";
import { WaitlistForm } from "@/components/marketing/WaitlistForm";

export const metadata: Metadata = {
  title: "Join the Waitlist — Forge",
  description:
    "Be first in line when Forge opens. Join the early-access waitlist — free, no card required, founding-member pricing.",
  alternates: { canonical: "/waitlist" },
};

export default function WaitlistPage() {
  return (
    <div className="bg-forge min-h-screen">
      <MarketingNav />

      <section className="relative overflow-hidden">
        <div className="absolute inset-0 bg-mesh opacity-30" />
        <div
          className="absolute left-1/2 top-[-80px] h-[420px] w-[820px] -translate-x-1/2 rounded-full"
          style={{ background: "radial-gradient(ellipse at center, rgba(212,175,55,0.14), transparent 62%)" }}
        />
        <div className="relative mx-auto max-w-2xl px-6 pb-24 pt-16 md:pt-24">
          <Reveal className="text-center">
            <span className="chip chip-gold">Early access</span>
            <h1 className="display mt-4 text-4xl text-cream-50 sm:text-6xl">
              Join the <span className="display-italic text-gold-grad">waitlist.</span>
            </h1>
            <p className="mx-auto mt-5 max-w-lg text-obsidian-100 sm:text-lg">
              Tell us what you train and what you wear, and we&apos;ll tailor your early access. Free to
              join — founding members get the best pricing.
            </p>
          </Reveal>

          <Reveal delay={120} className="mt-10">
            <div className="card card-gold p-6 sm:p-8">
              <WaitlistForm />
            </div>
          </Reveal>

          <Reveal delay={180} className="mt-6 text-center">
            <p className="text-sm text-obsidian-200">
              Want to help build it? {" "}
              <Link href="/beta" className="text-gold-300 hover:text-gold-200">Apply for beta access →</Link>
            </p>
          </Reveal>
        </div>
      </section>

      <Footer />
    </div>
  );
}
