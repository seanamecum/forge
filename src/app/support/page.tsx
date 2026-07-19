import type { Metadata } from "next";
import Link from "next/link";

export const metadata: Metadata = {
  title: "Support — Forge",
  description: "Get help with Forge: setup, HealthKit, wearables, coaching, and account questions.",
};

export default function SupportPage() {
  const faqs: Array<{ q: string; a: string }> = [
    {
      q: "How do I try Forge without connecting anything?",
      a: "Tap “Enter demo” on the welcome screen. The full product runs offline with a demo athlete — every feature is explorable without an account, permissions, or a wearable.",
    },
    {
      q: "How do I connect Apple Health?",
      a: "Open the Recover tab → Wearable Hub → Connect Apple Health, then approve the read types you're comfortable sharing. If you previously denied access, enable Forge under iOS Settings → Privacy & Security → Health.",
    },
    {
      q: "Two of my devices report the same metric. Which one does Forge use?",
      a: "The Wearable Hub shows a Preferred Sources card whenever devices overlap (for example, sleep from both WHOOP and Apple Watch). Pick a winner per metric; if it stops syncing, Forge falls back to the next-best source automatically.",
    },
    {
      q: "Why does my dashboard say “demo data”?",
      a: "It means Apple Health isn't connected (or has no samples yet), so Forge is showing clearly-labeled sample values. Connect Health or a wearable and refresh to switch to live data.",
    },
    {
      q: "Is the AI coach medical advice?",
      a: "No. Forge provides educational performance guidance only. For severe pain, swelling, head injury, chest pain, or neurological symptoms, see a physician or physical therapist.",
    },
    {
      q: "How do I delete my data?",
      a: "Forge is local-first: your training and health data lives on your device, and deleting the app deletes it. A Forge account is optional — if you created one, delete it (and its server-side data) anytime in the app under Profile → Account & Data. Health data in Apple Health stays under your control in the Health app.",
    },
  ];

  return (
    <div className="bg-forge min-h-screen">
      <main className="mx-auto max-w-3xl px-6 py-16">
        <p className="text-xs font-semibold uppercase tracking-[0.2em] text-gold-200">
          Forge · Help
        </p>
        <h1 className="mt-2 font-display text-4xl text-cream-100">Support</h1>
        <p className="mt-3 text-[15px] leading-relaxed text-cream-200">
          Stuck, found a bug, or have a feature request? Email{" "}
          <a href="mailto:support@forge.app" className="text-gold-200 hover:underline">
            support@forge.app
          </a>{" "}
          — include your iOS version and what you were doing. We aim to reply within two business days.
        </p>

        <div className="mt-12 space-y-6">
          {faqs.map(({ q, a }) => (
            <section
              key={q}
              className="rounded-2xl border border-gold-200/10 bg-white/[0.02] p-6"
            >
              <h2 className="font-display text-lg text-cream-100">{q}</h2>
              <p className="mt-2 text-[14px] leading-relaxed text-cream-200/90">{a}</p>
            </section>
          ))}
        </div>

        <p className="mt-12 text-sm text-cream-200/70">
          Privacy questions? Read the{" "}
          <Link href="/privacy" className="text-gold-200 hover:underline">
            Privacy Policy
          </Link>
          .
        </p>
      </main>
    </div>
  );
}
