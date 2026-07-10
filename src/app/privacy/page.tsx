import type { Metadata } from "next";
import Link from "next/link";

export const metadata: Metadata = {
  title: "Privacy Policy — Forge",
  description:
    "How Forge handles your health, fitness, and coaching data. Local-first, no tracking, no ads.",
};

// DRAFT — accurate to the shipped app's behavior (matches the iOS
// PrivacyInfo.xcprivacy and App Store privacy answers). Have counsel review
// before launch and update the effective date when published.
export default function PrivacyPage() {
  return (
    <div className="bg-forge min-h-screen">
      <main className="mx-auto max-w-3xl px-6 py-16">
        <p className="text-xs font-semibold uppercase tracking-[0.2em] text-gold-200">
          Forge · Legal
        </p>
        <h1 className="mt-2 font-display text-4xl text-cream-100">Privacy Policy</h1>
        <p className="mt-2 text-sm text-cream-200/70">Effective: at public launch (draft)</p>

        <div className="mt-10 space-y-8 text-[15px] leading-relaxed text-cream-200">
          <section>
            <h2 className="mb-2 font-display text-xl text-cream-100">The short version</h2>
            <p>
              Forge is local-first. Your health and training data lives on your device.
              We don&apos;t run ads, we don&apos;t sell data, and we don&apos;t track you
              across apps or websites. The only data that ever leaves your device is what&apos;s
              needed to answer your questions when live AI coaching is enabled.
            </p>
          </section>

          <section>
            <h2 className="mb-2 font-display text-xl text-cream-100">Data stored on your device</h2>
            <ul className="list-disc space-y-1 pl-5">
              <li>Your profile, goals, and preferences (including preferred data sources per metric)</li>
              <li>Workouts, nutrition, hydration, supplements, check-ins, pain logs, and Forge Score history</li>
              <li>
                Apple Health data (steps, heart rate, HRV, sleep, workouts, energy, weight) — read only
                with your permission, processed on-device, and never uploaded by Forge
              </li>
              <li>Waitlist interest flags (e.g. Forge Band)</li>
            </ul>
            <p className="mt-2">
              Deleting the app deletes this data. Forge has no account system in the current release,
              so there is nothing server-side to erase.
            </p>
          </section>

          <section>
            <h2 className="mb-2 font-display text-xl text-cream-100">Data sent off-device (live AI coaching only)</h2>
            <p>
              When live coaching is enabled, your chat messages and a summary of your current
              signals (for example: recovery percentage, sleep hours, protein remaining, injury
              status) are sent to Forge&apos;s backend, which relays them to our AI provider
              (Anthropic) to generate a reply. This data is used only to answer you, is not linked
              to your identity, and is not used for advertising or tracking. In the offline demo
              mode, nothing leaves your device at all.
            </p>
          </section>

          <section>
            <h2 className="mb-2 font-display text-xl text-cream-100">Apple Health</h2>
            <p>
              HealthKit access is optional and controlled by you in iOS Settings. Forge reads the
              types you approve to compute your Forge Score and recommendations, and writes only the
              workouts and body measurements you explicitly log. Forge never uses HealthKit data for
              marketing and never discloses it to third parties, consistent with Apple&apos;s
              HealthKit guidelines.
            </p>
          </section>

          <section>
            <h2 className="mb-2 font-display text-xl text-cream-100">What we don&apos;t do</h2>
            <ul className="list-disc space-y-1 pl-5">
              <li>No third-party advertising or ad SDKs</li>
              <li>No cross-app or cross-site tracking; no tracking domains</li>
              <li>No sale or sharing of personal or health data</li>
              <li>No third-party analytics in the current release</li>
            </ul>
          </section>

          <section>
            <h2 className="mb-2 font-display text-xl text-cream-100">Not medical advice</h2>
            <p>
              Forge provides educational performance guidance, not medical advice, diagnosis, or
              treatment. For injuries, severe pain, or medical concerns, consult a physician or
              physical therapist.
            </p>
          </section>

          <section>
            <h2 className="mb-2 font-display text-xl text-cream-100">Changes & contact</h2>
            <p>
              We&apos;ll update this policy as Forge gains accounts and sync, and material changes
              will be called out in the app. Questions:{" "}
              <a href="mailto:privacy@forge.app" className="text-gold-200 hover:underline">
                privacy@forge.app
              </a>
              . See also <Link href="/support" className="text-gold-200 hover:underline">Support</Link>.
            </p>
          </section>
        </div>
      </main>
    </div>
  );
}
