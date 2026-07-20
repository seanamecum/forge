import type { Metadata } from "next";
import Link from "next/link";

export const metadata: Metadata = {
  title: "Terms of Use — Forge",
  description: "The terms that govern your use of the Forge app and website.",
};

// DRAFT — plain-language terms matching the shipped 1.0 (free app, optional
// account, educational guidance). Have counsel review before launch.
export default function TermsPage() {
  return (
    <div className="bg-forge min-h-screen">
      <main className="mx-auto max-w-3xl px-6 py-16">
        <p className="text-xs font-semibold uppercase tracking-[0.2em] text-gold-200">
          Forge · Legal
        </p>
        <h1 className="mt-2 font-display text-4xl text-cream-100">Terms of Use</h1>
        <p className="mt-2 text-sm text-cream-200/70">Effective: at public launch (draft)</p>

        <div className="mt-10 space-y-8 text-[15px] leading-relaxed text-cream-200">
          <section>
            <h2 className="mb-2 font-display text-xl text-cream-100">The short version</h2>
            <p>
              Forge helps you train, eat, and recover with more intelligence. It is
              educational guidance, not medical advice. Use your judgment, stop if
              something hurts, and talk to a professional about injuries and health
              conditions.
            </p>
          </section>

          <section>
            <h2 className="mb-2 font-display text-xl text-cream-100">Not medical advice</h2>
            <p>
              Forge&apos;s scores, directives, coaching replies, rehab content, and
              forecasts are general wellness information. They are not a diagnosis,
              treatment, or substitute for care from a qualified professional.
              Consult a physician before starting a training program, especially if
              you have an injury or medical condition. If something feels wrong
              during exercise, stop.
            </p>
          </section>

          <section>
            <h2 className="mb-2 font-display text-xl text-cream-100">Your account</h2>
            <p>
              An account is optional. If you create one, keep your credentials to
              yourself and tell us about any unauthorized use. You can delete your
              account at any time inside the app (Profile → Account &amp; Data), which
              removes it from our servers.
            </p>
          </section>

          <section>
            <h2 className="mb-2 font-display text-xl text-cream-100">Your data</h2>
            <p>
              Your training and health data stays on your device unless you enable a
              feature that needs it elsewhere. The details live in our{" "}
              <Link href="/privacy" className="text-gold-200 underline underline-offset-4">
                Privacy Policy
              </Link>
              , which is part of these terms.
            </p>
          </section>

          <section>
            <h2 className="mb-2 font-display text-xl text-cream-100">Acceptable use</h2>
            <p>
              Don&apos;t break the law with Forge, probe or disrupt our services,
              scrape or resell them, or misrepresent Forge&apos;s output as
              professional medical guidance to others.
            </p>
          </section>

          <section>
            <h2 className="mb-2 font-display text-xl text-cream-100">The service</h2>
            <p>
              Forge 1.0 is free. Features may change as the product evolves; if we add
              paid tiers, they&apos;ll be clearly marked and governed by additional
              terms at purchase. The app is provided &quot;as is&quot; — we work hard
              to keep it accurate and available, but we can&apos;t guarantee either,
              and to the extent the law allows, our liability is limited to what you
              paid for the service (for 1.0: nothing).
            </p>
          </section>

          <section>
            <h2 className="mb-2 font-display text-xl text-cream-100">Contact</h2>
            <p>
              Questions about these terms:{" "}
              <a
                href="mailto:legal@forge.app"
                className="text-gold-200 underline underline-offset-4"
              >
                legal@forge.app
              </a>
              . See also{" "}
              <Link href="/support" className="text-gold-200 underline underline-offset-4">
                Support
              </Link>
              .
            </p>
          </section>
        </div>

        <p className="mt-12 text-sm text-cream-200/60">
          <Link href="/" className="text-gold-200 underline underline-offset-4">
            ← Back to Forge
          </Link>
        </p>
      </main>
    </div>
  );
}
