import Link from "next/link";
import type { Metadata } from "next";
import { MarketingNav } from "@/components/marketing/MarketingNav";
import { Footer } from "@/components/marketing/Footer";
import { Reveal } from "@/components/marketing/Reveal";
import { WaitlistForm } from "@/components/marketing/WaitlistForm";
import { Faq } from "@/components/marketing/Faq";
import { DashboardMockup, PhoneMockup } from "@/components/marketing/Mockups";
import { ForgeMark } from "@/components/ui/Logo";

export const metadata: Metadata = {
  title: "Forge — Your Training. Recovery. Progress. One Platform.",
  description:
    "Forge connects your workouts, wearable data, recovery, goals, and performance into one intelligent fitness platform built to help you improve faster. Join the early-access waitlist.",
  alternates: { canonical: "/" },
};

export default function Home() {
  return (
    <div className="bg-forge min-h-screen">
      <MarketingNav />
      <Hero />
      <Integrations />
      <Benefits />
      <Features />
      <HowItWorks />
      <UseCases />
      <Marketplace />
      <BetaRecruitment />
      <FaqSection />
      <FinalCta />
      <Footer />
    </div>
  );
}

/* ------------------------------------------------------------------ HERO */
function Hero() {
  return (
    <section className="relative overflow-hidden">
      <div className="absolute inset-0 bg-mesh opacity-30" />
      <div
        className="absolute left-1/2 top-[-120px] -z-0 h-[640px] w-[1100px] -translate-x-1/2 rounded-full"
        style={{ background: "radial-gradient(ellipse at center, rgba(212,175,55,0.16), transparent 62%)" }}
      />
      <div className="relative mx-auto max-w-7xl px-5 pb-20 pt-14 sm:px-6 md:pt-20">
        <div className="mx-auto max-w-3xl text-center">
          <Reveal>
            <div className="mb-6 inline-flex items-center gap-2 rounded-full border border-gold-400/25 bg-gold-400/5 px-4 py-1.5 text-[11px] uppercase tracking-[0.2em] text-gold-200">
              <span className="dot dot-gold animate-pulse-gold" /> Early access now open
            </div>
          </Reveal>
          <Reveal delay={60}>
            <h1 className="display text-4xl leading-[1.06] text-cream-50 sm:text-6xl lg:text-7xl">
              Your Training. Recovery. Progress.
              <br />
              <span className="text-gold-grad display-italic">One platform.</span>
            </h1>
          </Reveal>
          <Reveal delay={120}>
            <p className="mx-auto mt-6 max-w-2xl text-base text-obsidian-100 sm:text-lg">
              Forge connects your workouts, wearable data, recovery, goals, and performance into one
              intelligent fitness platform built to help you improve faster.
            </p>
          </Reveal>
          <Reveal delay={180}>
            <div className="mt-8 flex flex-col items-center justify-center gap-3 sm:flex-row">
              <a href="#waitlist" className="btn-gold w-full sm:w-auto">Join the Waitlist</a>
              <Link href="/beta" className="btn-ghost w-full sm:w-auto">Apply for Beta Access</Link>
            </div>
          </Reveal>
          <Reveal delay={240}>
            <p className="mt-5 text-[11px] uppercase tracking-[0.18em] text-obsidian-200">
              Free to join · Founding-member pricing · No card required
            </p>
          </Reveal>
        </div>

        <Reveal delay={200} className="relative mx-auto mt-14 max-w-5xl">
          <DashboardMockup />
        </Reveal>
      </div>
    </section>
  );
}

/* ---------------------------------------------------------- INTEGRATIONS */
const DEVICES = ["Apple Watch", "WHOOP", "Garmin", "Oura", "Fitbit", "Polar", "Strava", "Withings"];

function Integrations() {
  return (
    <section id="integrations" className="border-t border-gold-400/10 py-16">
      <div className="mx-auto max-w-6xl px-6 text-center">
        <Reveal>
          <div className="text-[11px] uppercase tracking-[0.22em] text-gold-300">Built to work with what you already wear</div>
          <p className="mx-auto mt-3 max-w-2xl text-lg text-obsidian-100">
            At launch, Forge will bring the signals from the devices and apps you already use into one
            place — no switching, no silos.
          </p>
        </Reveal>
        <Reveal delay={80}>
          <div className="mt-8 flex flex-wrap items-center justify-center gap-3">
            {DEVICES.map((d) => (
              <span
                key={d}
                className="rounded-full border border-white/8 bg-obsidian-900/60 px-4 py-2 text-sm text-cream-200"
              >
                {d}
              </span>
            ))}
          </div>
        </Reveal>
      </div>
    </section>
  );
}

/* -------------------------------------------------------------- BENEFITS */
const BENEFITS = [
  {
    title: "One decision every morning",
    desc: "Forge reads your recovery, load, and goals and tells you exactly what to do today — train hard, hold back, or rest — and why.",
    icon: "◆",
  },
  {
    title: "Every signal, one place",
    desc: "Wearables, workouts, sleep, nutrition, and injuries stop living in ten different apps. Forge connects them into one clear picture.",
    icon: "◉",
  },
  {
    title: "A coach that knows your data",
    desc: "AI coaching trained on your training history, recovery, and goals — not generic tips. Ask it anything, any time.",
    icon: "✦",
  },
  {
    title: "Progress you can actually see",
    desc: "Performance analytics that trend strength, endurance, recovery, and body composition — so you know what's working.",
    icon: "▲",
  },
];

function Benefits() {
  return (
    <section className="border-t border-gold-400/10 py-20 sm:py-24">
      <div className="mx-auto max-w-7xl px-6">
        <SectionHeading
          eyebrow="Why Forge"
          title="Built to make you better, faster."
          sub="Not another tracker that just logs the past. A system that decides what you do next."
        />
        <div className="mt-12 grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
          {BENEFITS.map((b, i) => (
            <Reveal key={b.title} delay={i * 70}>
              <div className="card card-hover h-full p-6">
                <div className="mb-3 text-2xl text-gold-300">{b.icon}</div>
                <div className="display text-xl text-cream-50">{b.title}</div>
                <p className="mt-2 text-[14px] leading-relaxed text-obsidian-200">{b.desc}</p>
              </div>
            </Reveal>
          ))}
        </div>
      </div>
    </section>
  );
}

/* -------------------------------------------------------------- FEATURES */
const FEATURES = [
  { icon: "✦", title: "AI Coaching", desc: "A coach that sees your sleep, HRV, last session, and goals — and tells you what to change." },
  { icon: "☾", title: "Recovery & Readiness", desc: "HRV, resting HR, sleep stages, strain, and a daily readiness score — trended and explained." },
  { icon: "◐", title: "Wearable Integrations", desc: "Apple Watch, WHOOP, Garmin, Oura, Fitbit, Polar, Strava — unified into one signal." },
  { icon: "▲", title: "Strength & Training Plans", desc: "Adaptive plans, a full logger, PR and volume analytics, RPE/RIR, and 1RM estimates." },
  { icon: "◈", title: "Running & Endurance", desc: "Pace, zones, weekly load, and race-ready progressions for runners and hybrid athletes." },
  { icon: "◧", title: "Performance Analytics", desc: "Strength, endurance, recovery, and body composition — the trends that actually matter." },
  { icon: "✚", title: "Injury & Rehab", desc: "Injury profiles, rehab protocols, and training that auto-adjusts around what hurts." },
  { icon: "♔", title: "Social & Challenges", desc: "Leaderboards, challenges, and a feed for the athletes who take it seriously." },
];

function Features() {
  return (
    <section id="features" className="border-t border-gold-400/10 py-20 sm:py-24">
      <div className="mx-auto max-w-7xl px-6">
        <SectionHeading
          eyebrow="The platform"
          title="Everything that moves you forward — in one app."
          sub="Strength, running, hybrid, endurance, recovery, nutrition, and coaching, engineered to work together."
        />
        <div className="mt-12 grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
          {FEATURES.map((f, i) => (
            <Reveal key={f.title} delay={(i % 4) * 70}>
              <div className="card card-hover h-full p-5">
                <div className="mb-3 text-2xl text-gold-300">{f.icon}</div>
                <div className="display text-lg text-cream-50">{f.title}</div>
                <p className="mt-1.5 text-[13px] leading-relaxed text-obsidian-200">{f.desc}</p>
              </div>
            </Reveal>
          ))}
        </div>

        {/* Mobile app showcase */}
        <div className="mt-16 grid items-center gap-10 lg:grid-cols-2">
          <Reveal>
            <div>
              <div className="text-[11px] uppercase tracking-[0.22em] text-gold-300">In your pocket</div>
              <h3 className="display mt-2 text-3xl text-cream-50 sm:text-4xl">
                Your whole performance system, on your wrist and in your hand.
              </h3>
              <p className="mt-4 text-obsidian-100">
                Wake up to your Forge Score, today&apos;s session, and a coach that already knows how you slept.
                Log a lift in seconds. See progress the moment it happens.
              </p>
              <ul className="mt-6 space-y-2.5 text-sm text-cream-200">
                {["Morning readiness at a glance", "One-tap workout logging", "Ask your AI coach anything", "Live sync from your wearable"].map((t) => (
                  <li key={t} className="flex items-center gap-2.5">
                    <span className="text-gold-300">✓</span> {t}
                  </li>
                ))}
              </ul>
            </div>
          </Reveal>
          <Reveal delay={120}>
            <PhoneMockup />
          </Reveal>
        </div>
      </div>
    </section>
  );
}

/* ------------------------------------------------------------ HOW IT WORKS */
const STEPS = [
  { n: "01", title: "Connect your world", desc: "Link your wearable and apps. Forge pulls in your sleep, HRV, training, and history automatically." },
  { n: "02", title: "Set your goal", desc: "Tell Forge what you're chasing — strength, a race, fat loss, a comeback. It builds around you." },
  { n: "03", title: "Get your daily call", desc: "Every morning, Forge turns the data into one clear decision: what to do today, how hard, and why." },
  { n: "04", title: "Improve, on repeat", desc: "Log, recover, adapt. Forge learns and adjusts your plan as you progress — or when life gets in the way." },
];

function HowItWorks() {
  return (
    <section id="how" className="border-t border-gold-400/10 py-20 sm:py-24">
      <div className="mx-auto max-w-7xl px-6">
        <SectionHeading eyebrow="How Forge works" title="From scattered data to a daily decision." />
        <div className="mt-12 grid gap-4 md:grid-cols-4">
          {STEPS.map((s, i) => (
            <Reveal key={s.n} delay={i * 80}>
              <div className="card h-full p-6">
                <div className="stat-num text-4xl text-gold-grad">{s.n}</div>
                <div className="display mt-3 text-xl text-cream-50">{s.title}</div>
                <p className="mt-2 text-[14px] leading-relaxed text-obsidian-200">{s.desc}</p>
              </div>
            </Reveal>
          ))}
        </div>
      </div>
    </section>
  );
}

/* ------------------------------------------------------------- USE CASES */
const USE_CASES = [
  { tag: "Lifters", title: "Add weight to the bar without burning out.", desc: "Adaptive strength plans that cap volume on low-recovery days and push when you're primed." },
  { tag: "Runners", title: "Train to your readiness, not just a plan.", desc: "Pace, zones, and weekly load balanced against recovery so you arrive at race day sharp." },
  { tag: "Hybrid athletes", title: "Balance strength and endurance intelligently.", desc: "Forge manages the tug-of-war between lifting and mileage so both keep moving up." },
  { tag: "HS & college athletes", title: "Show up recovered and ready to compete.", desc: "Readiness, load management, and rehab support built for a real season and a real schedule." },
  { tag: "Wearable users", title: "Finally do something with all that data.", desc: "Your WHOOP, Garmin, or Oura numbers become decisions instead of dashboards." },
  { tag: "Coaches & creators", title: "Tools to program, track, and grow.", desc: "Coach and creator tools to manage athletes and build your audience — coming through beta." },
];

function UseCases() {
  return (
    <section className="border-t border-gold-400/10 py-20 sm:py-24">
      <div className="mx-auto max-w-7xl px-6">
        <SectionHeading
          eyebrow="Who it's for"
          title="One platform. Every kind of athlete."
          sub="Forge scales from your first serious training block to competing at the top."
        />
        <div className="mt-12 grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
          {USE_CASES.map((u, i) => (
            <Reveal key={u.tag} delay={(i % 3) * 70}>
              <div className="card card-hover h-full p-6">
                <span className="chip chip-gold">{u.tag}</span>
                <div className="display mt-3 text-xl text-cream-50">{u.title}</div>
                <p className="mt-2 text-[14px] leading-relaxed text-obsidian-200">{u.desc}</p>
              </div>
            </Reveal>
          ))}
        </div>
      </div>
    </section>
  );
}

/* ----------------------------------------------------------- MARKETPLACE */
function Marketplace() {
  return (
    <section id="marketplace" className="border-t border-gold-400/10 py-20 sm:py-24">
      <div className="mx-auto max-w-6xl px-6">
        <div className="card card-gold overflow-hidden">
          <div className="grid items-center gap-8 p-8 sm:p-12 lg:grid-cols-2">
            <Reveal>
              <div>
                <span className="chip chip-gold">Coming soon</span>
                <h3 className="display mt-4 text-3xl text-cream-50 sm:text-4xl">The Forge Marketplace.</h3>
                <p className="mt-4 text-obsidian-100">
                  A marketplace where coaches and creators publish training plans, and athletes find
                  programming built for their sport and their data. Buy a plan, and Forge runs it — adapting
                  to your recovery in real time.
                </p>
                <ul className="mt-6 space-y-2.5 text-sm text-cream-200">
                  {["Plans from real coaches and creators", "Auto-adapts to your readiness", "New revenue for coaches", "Verified results, not hype"].map((t) => (
                    <li key={t} className="flex items-center gap-2.5">
                      <span className="text-gold-300">✦</span> {t}
                    </li>
                  ))}
                </ul>
                <Link href="/beta" className="btn-ghost mt-7">Are you a coach? Apply for beta →</Link>
              </div>
            </Reveal>
            <Reveal delay={120}>
              <div className="grid gap-3">
                {[
                  { t: "12-Week Hybrid Base", a: "by a national-level coach", p: "$49" },
                  { t: "Sub-3 Marathon Build", a: "by an elite runner", p: "$39" },
                  { t: "Raw Strength Peaking", a: "by a powerlifting coach", p: "$59" },
                ].map((p) => (
                  <div key={p.t} className="flex items-center justify-between rounded-xl border border-white/8 bg-obsidian-900/60 p-4">
                    <div>
                      <div className="text-cream-50">{p.t}</div>
                      <div className="text-xs text-obsidian-200">{p.a}</div>
                    </div>
                    <div className="stat-num text-lg text-gold-300">{p.p}</div>
                  </div>
                ))}
                <p className="mt-1 text-center text-[11px] text-obsidian-200">
                  Illustrative examples — the marketplace isn&apos;t live yet.
                </p>
              </div>
            </Reveal>
          </div>
        </div>
      </div>
    </section>
  );
}

/* ------------------------------------------------------- BETA RECRUITMENT */
function BetaRecruitment() {
  return (
    <section className="border-t border-gold-400/10 py-20 sm:py-24">
      <div className="mx-auto max-w-6xl px-6">
        <div className="grid items-center gap-10 lg:grid-cols-2">
          <Reveal>
            <div>
              <div className="text-[11px] uppercase tracking-[0.22em] text-gold-300">Beta program</div>
              <h3 className="display mt-2 text-3xl text-cream-50 sm:text-5xl">
                Help build the platform you&apos;ve always wanted.
              </h3>
              <p className="mt-4 text-obsidian-100">
                We&apos;re inviting a focused group of serious athletes, coaches, and creators to shape Forge
                before launch. You&apos;ll get free early access, a direct line to the team, and real influence
                over the roadmap.
              </p>
              <Link href="/beta" className="btn-gold mt-7">Apply for Beta Access</Link>
            </div>
          </Reveal>
          <Reveal delay={120}>
            <div className="grid gap-3 sm:grid-cols-2">
              {[
                { icon: "◆", t: "Free early access", d: "Use Forge before anyone else — on us." },
                { icon: "✦", t: "Shape the product", d: "Your feedback directly changes what we build." },
                { icon: "♔", t: "Founding-member status", d: "Locked-in perks and pricing at launch." },
                { icon: "▲", t: "Direct line to the team", d: "Talk to the people building it." },
              ].map((b) => (
                <div key={b.t} className="card h-full p-5">
                  <div className="mb-2 text-2xl text-gold-300">{b.icon}</div>
                  <div className="display text-lg text-cream-50">{b.t}</div>
                  <p className="mt-1 text-[13px] text-obsidian-200">{b.d}</p>
                </div>
              ))}
            </div>
          </Reveal>
        </div>
      </div>
    </section>
  );
}

/* -------------------------------------------------------------------- FAQ */
function FaqSection() {
  return (
    <section id="faq" className="border-t border-gold-400/10 py-20 sm:py-24">
      <div className="mx-auto max-w-7xl px-6">
        <SectionHeading eyebrow="Questions" title="Everything you're wondering." />
        <div className="mt-10">
          <Faq />
        </div>
      </div>
    </section>
  );
}

/* -------------------------------------------------------------- FINAL CTA */
function FinalCta() {
  return (
    <section id="waitlist" className="relative overflow-hidden border-t border-gold-400/10 py-20 sm:py-28">
      <div
        className="absolute left-1/2 top-0 -z-0 h-[500px] w-[900px] -translate-x-1/2 rounded-full"
        style={{ background: "radial-gradient(ellipse at center, rgba(212,175,55,0.12), transparent 62%)" }}
      />
      <div className="relative mx-auto max-w-5xl px-6">
        <div className="grid items-center gap-10 lg:grid-cols-2">
          <Reveal>
            <div>
              <ForgeMark size={48} />
              <h2 className="display mt-5 text-4xl text-cream-50 sm:text-5xl">
                Join the early-access
                <br />
                <span className="display-italic text-gold-grad">waitlist.</span>
              </h2>
              <p className="mt-4 max-w-md text-obsidian-100">
                Be first in line when Forge opens. Tell us what you train and what you wear, and we&apos;ll
                tailor your early access. Free to join — founding members get the best pricing.
              </p>
              <div className="mt-6 flex items-center gap-6 text-sm text-obsidian-200">
                <div>
                  <div className="stat-num text-2xl text-gold-300">6</div>
                  <div className="text-[11px] uppercase tracking-wider">wearables at launch</div>
                </div>
                <div className="h-8 w-px bg-white/10" />
                <div>
                  <div className="stat-num text-2xl text-gold-300">1</div>
                  <div className="text-[11px] uppercase tracking-wider">daily decision</div>
                </div>
              </div>
            </div>
          </Reveal>
          <Reveal delay={120}>
            <div className="card card-gold p-6 sm:p-8">
              <WaitlistForm />
            </div>
          </Reveal>
        </div>
      </div>
    </section>
  );
}

/* --------------------------------------------------------------- HELPERS */
function SectionHeading({ eyebrow, title, sub }: { eyebrow: string; title: string; sub?: string }) {
  return (
    <Reveal className="mx-auto max-w-2xl text-center">
      <div className="text-[11px] uppercase tracking-[0.22em] text-gold-300">{eyebrow}</div>
      <h2 className="display mt-2 text-3xl text-cream-50 sm:text-5xl">{title}</h2>
      {sub && <p className="mx-auto mt-3 max-w-xl text-obsidian-100">{sub}</p>}
    </Reveal>
  );
}
