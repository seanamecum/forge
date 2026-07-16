import Link from "next/link";
import { ForgeMark, ForgeWordmark } from "@/components/ui/Logo";

export default function Landing() {
  return (
    <div className="bg-forge min-h-screen overflow-hidden">
      {/* Header */}
      <header className="relative z-10 mx-auto flex max-w-7xl items-center justify-between px-6 py-6">
        <ForgeWordmark size={24} />
        <nav className="hidden items-center gap-8 text-sm text-cream-200 md:flex">
          <a href="#system" className="hover:text-gold-200">The System</a>
          <a href="#coach" className="hover:text-gold-200">AI Coach</a>
          <a href="#recovery" className="hover:text-gold-200">Forge Recovery</a>
          <a href="#pricing" className="hover:text-gold-200">Pricing</a>
        </nav>
        <div className="flex items-center gap-3">
          <Link href="/auth" className="btn-ghost text-xs">Sign in</Link>
          <Link href="/onboarding" className="btn-gold text-xs">Begin</Link>
        </div>
      </header>

      {/* Hero */}
      <section className="relative">
        <div className="absolute inset-0 bg-mesh opacity-30" />
        <div className="absolute left-1/2 top-0 -z-10 h-[700px] w-[1200px] -translate-x-1/2 rounded-full"
             style={{ background: "radial-gradient(ellipse at center, rgba(212,175,55,0.15), transparent 60%)" }} />

        <div className="relative mx-auto max-w-7xl px-6 pb-24 pt-10 md:pt-20">
          <div className="text-center">
            <div className="mb-5 inline-flex items-center gap-2 rounded-full border border-gold-400/25 bg-gold-400/5 px-4 py-1.5 text-[11px] uppercase tracking-[0.2em] text-gold-200">
              <span className="dot dot-gold animate-pulse-gold" /> Human Performance, Engineered
            </div>

            <h1 className="display text-5xl leading-[1.05] text-cream-50 sm:text-6xl md:text-7xl lg:text-8xl">
              The body is a system.<br />
              <span className="text-gold-grad display-italic">Forge</span> is the operating layer.
            </h1>

            <p className="mx-auto mt-7 max-w-2xl text-base text-obsidian-100 sm:text-lg">
              Turn the chaos of training, sleep, nutrition, recovery, wearables, and injury data into one
              decision every morning. Forge tells you exactly what to do today — and why.
            </p>

            <div className="mt-9 flex flex-col items-center justify-center gap-3 sm:flex-row">
              <Link href="/onboarding" className="btn-gold">Enter The Forge</Link>
              <Link href="/dashboard" className="btn-ghost">View live demo →</Link>
            </div>

            <div className="mt-10 flex flex-wrap items-center justify-center gap-x-8 gap-y-2 text-[11px] uppercase tracking-[0.18em] text-obsidian-200">
              <span>Apple Watch</span><span className="text-gold-400/40">·</span>
              <span>WHOOP</span><span className="text-gold-400/40">·</span>
              <span>Oura</span><span className="text-gold-400/40">·</span>
              <span>Garmin</span><span className="text-gold-400/40">·</span>
              <span>Withings</span>
            </div>
          </div>

          {/* Visual hero — dashboard preview frame */}
          <div className="relative mx-auto mt-16 max-w-5xl">
            <div className="card card-gold p-6 sm:p-10">
              <div className="grid gap-6 sm:grid-cols-3">
                <div className="text-left">
                  <div className="text-[10px] uppercase tracking-[0.22em] text-gold-300">Forge Score</div>
                  <div className="stat-num mt-2 text-7xl text-gold-grad">78</div>
                  <div className="mt-1 text-xs text-forge-green">▲ 3 vs yesterday</div>
                </div>
                <div className="text-left">
                  <div className="text-[10px] uppercase tracking-[0.22em] text-gold-300">Today's call</div>
                  <div className="display mt-2 text-2xl text-cream-50">Train, cap RPE 8.5.</div>
                  <div className="mt-1 text-sm text-obsidian-100">
                    Lower-body strength block. 12% volume cap given HRV drop. Skip overhead pressing — shoulder rehab continues.
                  </div>
                </div>
                <div className="text-left">
                  <div className="text-[10px] uppercase tracking-[0.22em] text-gold-300">Lowest sub-score</div>
                  <div className="display mt-2 text-2xl text-cream-50">Hydration · 57</div>
                  <div className="mt-1 text-sm text-obsidian-100">
                    1.6 L gap by 2pm. Pair next bottle with electrolytes. Recovery dependent.
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* The System */}
      <section id="system" className="border-t border-gold-400/10 py-24">
        <div className="mx-auto max-w-7xl px-6">
          <div className="mb-12 text-center">
            <div className="mb-2 text-[10px] uppercase tracking-[0.22em] text-gold-300">The System</div>
            <h2 className="display text-4xl text-cream-50 sm:text-5xl">Twenty modules. One decision.</h2>
            <p className="mx-auto mt-3 max-w-2xl text-obsidian-100">
              Forge is not another fitness tracker. It is a closed-loop performance operating system —
              every signal feeds the next, every output is a directive.
            </p>
          </div>

          <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
            {PILLARS.map((p) => (
              <div key={p.title} className="card card-hover p-5">
                <div className="mb-3 text-2xl text-gold-300">{p.icon}</div>
                <div className="display text-lg text-cream-50">{p.title}</div>
                <p className="mt-1 text-[13px] text-obsidian-200">{p.desc}</p>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* AI Coach */}
      <section id="coach" className="border-t border-gold-400/10 py-24">
        <div className="mx-auto max-w-6xl px-6">
          <div className="grid items-center gap-12 lg:grid-cols-2">
            <div>
              <div className="mb-2 text-[10px] uppercase tracking-[0.22em] text-gold-300">AI Coach</div>
              <h2 className="display text-4xl text-cream-50 sm:text-5xl">The brain of the system.</h2>
              <p className="mt-4 text-obsidian-100">
                Trained on your sleep, your last workout, the way your HRV moved this week, the
                deficiency in magnesium, the shoulder you tweaked 18 days ago — and the goal you set six
                weeks ago. Ask it anything.
              </p>
              <ul className="mt-6 space-y-2 text-sm text-cream-200">
                {[
                  "Why am I tired?",
                  "Should I train hard today?",
                  "Why is my bench not increasing?",
                  "How do I recover from this shoulder?",
                  "What should I change this week?",
                ].map((q) => (
                  <li key={q} className="flex items-center gap-2">
                    <span className="text-gold-300">✦</span> "{q}"
                  </li>
                ))}
              </ul>
              <Link href="/coach" className="btn-gold mt-7">Talk to the Coach</Link>
            </div>
            <div className="card p-6">
              <div className="text-[10px] uppercase tracking-[0.18em] text-obsidian-200">User</div>
              <div className="mt-1 text-cream-100">Should I train hard today?</div>
              <div className="hairline my-4" />
              <div className="text-[10px] uppercase tracking-[0.18em] text-gold-300">Forge Coach</div>
              <div className="mt-2 text-cream-100">
                Yes — but cap it. Recovery is 72 and HRV dropped 8 ms from baseline. Lower-body block is
                already auto-deloaded ~12%. Run it as written. <span className="text-gold-200">Top set cap: RPE 8.5.</span>
              </div>
              <div className="mt-4 grid grid-cols-3 gap-2">
                <div className="rounded-md border border-gold-400/15 bg-obsidian-800/60 p-2">
                  <div className="text-[9px] uppercase tracking-wider text-obsidian-200">Session</div>
                  <div className="mt-0.5 text-xs text-cream-100">Lower — Posterior</div>
                </div>
                <div className="rounded-md border border-amber-400/20 bg-amber-400/5 p-2">
                  <div className="text-[9px] uppercase tracking-wider text-obsidian-200">Cap</div>
                  <div className="mt-0.5 text-xs text-forge-amber">RPE 8.5</div>
                </div>
                <div className="rounded-md border border-forge-ruby/30 bg-forge-ruby/5 p-2">
                  <div className="text-[9px] uppercase tracking-wider text-obsidian-200">Skip</div>
                  <div className="mt-0.5 text-xs text-forge-ruby">Overhead press</div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* Forge Recovery */}
      <section id="recovery" className="border-t border-gold-400/10 py-24">
        <div className="mx-auto max-w-6xl px-6">
          <div className="mb-10 text-center">
            <div className="mb-2 text-[10px] uppercase tracking-[0.22em] text-gold-300">Forge Recovery</div>
            <h2 className="display text-4xl text-cream-50 sm:text-5xl">Most apps stop where you start.</h2>
            <p className="mx-auto mt-3 max-w-2xl text-obsidian-100">
              Tweak your shoulder? Most apps go quiet. Forge starts a rehab protocol, throttles your
              training plan, blocks aggravating movements, and walks you back to full output.
            </p>
          </div>

          <div className="grid gap-4 sm:grid-cols-3">
            {RECOVERY_PILLARS.map((r) => (
              <div key={r.title} className="card p-5">
                <div className="mb-2 text-2xl text-gold-300">{r.icon}</div>
                <div className="display text-lg text-cream-50">{r.title}</div>
                <p className="mt-1 text-[13px] text-obsidian-200">{r.desc}</p>
              </div>
            ))}
          </div>

          <div className="mt-6 rounded-lg border border-gold-400/15 bg-obsidian-800/40 p-4 text-[11px] text-obsidian-200">
            Forge provides educational guidance only. It does not replace medical care. For acute or
            severe symptoms — concussion, persistent pain, instability — consult a licensed physician
            or physiotherapist.
          </div>
        </div>
      </section>

      {/* CTA */}
      <section id="pricing" className="border-t border-gold-400/10 py-24">
        <div className="mx-auto max-w-3xl px-6 text-center">
          <ForgeMark size={56} />
          <h2 className="display mt-5 text-4xl text-cream-50 sm:text-5xl">
            Stop guessing.<br />
            <span className="display-italic text-gold-grad">Forge.</span>
          </h2>
          <p className="mx-auto mt-4 max-w-xl text-obsidian-100">
            Stronger, healthier, faster, leaner, more athletic, better recovered.
            One platform. One operating system. One daily decision.
          </p>
          <div className="mt-8 flex flex-col items-center justify-center gap-3 sm:flex-row">
            <Link href="/onboarding" className="btn-gold">Begin — 14 days free</Link>
            <Link href="/dashboard" className="btn-ghost">View the dashboard →</Link>
          </div>
          <div className="mt-12 text-[11px] uppercase tracking-[0.22em] text-obsidian-200">
            Forge Standard $19/mo · Forge Pro $39/mo · Forge Athlete $79/mo
          </div>
        </div>
      </section>

      <footer className="border-t border-gold-400/10 py-10">
        <div className="mx-auto flex max-w-7xl flex-col items-center justify-between gap-4 px-6 text-xs text-obsidian-200 sm:flex-row">
          <ForgeWordmark size={18} />
          <nav className="flex gap-5">
            <Link href="/feedback" className="hover:text-gold-300">Feedback</Link>
            <Link href="/support" className="hover:text-gold-300">Support</Link>
            <Link href="/privacy" className="hover:text-gold-300">Privacy</Link>
          </nav>
          <div>© Forge Performance Systems · Educational guidance, not medical advice.</div>
        </div>
      </footer>
    </div>
  );
}

const PILLARS = [
  { icon: "◆", title: "Forge Score", desc: "0–100 daily, weighted by sleep, HRV, recovery, training load, nutrition, hydration, stress, injury." },
  { icon: "✦", title: "AI Coach", desc: "The brain that watches every signal and tells you what to do today, why, and what to change." },
  { icon: "▲", title: "Training", desc: "Logger, generator, exercise database, PR & volume analytics, RPE/RIR, 1RM estimates, supersets, EMOMs." },
  { icon: "◉", title: "Nutrition", desc: "Macros, micros, 13 vitamins, 13 minerals, omega-3, EAAs. Deficiency detection with corrective actions." },
  { icon: "❖", title: "Supplements", desc: "Track creatine, whey, fish oil, Mg, D3, Zn, electrolytes — streaks, timing, benefit." },
  { icon: "◐", title: "Wearables", desc: "Apple Watch, WHOOP, Oura, Garmin, Fitbit, Polar, smart scales — unified signal." },
  { icon: "☾", title: "Recovery & Sleep", desc: "HRV, RHR, REM, deep, light, sleep debt, strain, readiness — trended and explained." },
  { icon: "✚", title: "Forge Recovery", desc: "Injury profile, pain tracking, PT library, concussion protocols, return-to-sport phases." },
  { icon: "◬", title: "Form Analysis", desc: "Upload your lifts. Get a form score, mistakes, corrections, and coaching notes." },
  { icon: "◧", title: "Body Tracking", desc: "Weight, body fat, lean mass, 8 measurements, progress photos, charts and comparisons." },
  { icon: "❤", title: "Bloodwork", desc: "T, free T, Vit D, ferritin, LDL/HDL, glucose, A1c, CRP, thyroid — with AI interpretation." },
  { icon: "✧", title: "Digital Twin", desc: "Forecast your weight, body fat, 1RM, 5K, recovery, injury risk — in weeks, with confidence." },
  { icon: "❉", title: "Social", desc: "Feed, friends, groups, PR shares, progress posts, comments — for the athletes that get it." },
  { icon: "♔", title: "Leaderboards", desc: "Steps, strength, streaks, calories, miles, protein consistency. Compete. Compare. Rise." },
  { icon: "⚑", title: "Challenges", desc: "30-day protein, 100-mile month, summer shred, hockey off-season, bench challenges." },
  { icon: "★", title: "Gamification", desc: "XP, levels, streaks, badges, achievements, daily missions. Stay in the loop." },
];

const RECOVERY_PILLARS = [
  { icon: "✚", title: "Injury Profile", desc: "Shoulder, knee, ankle, hip, back, neck, wrist, elbow, hamstring, groin, concussion." },
  { icon: "✱", title: "PT Library", desc: "Rotator cuff ER, wall slides, pull-aparts, Copenhagen planks, glute bridges, dead bugs, bird dogs, McGill big 3 — and 50 more." },
  { icon: "◉", title: "Pain & Symptoms", desc: "Daily 0–10 tracking. Trend the trajectory. Adjust the plan." },
  { icon: "☷", title: "Concussion Protocol", desc: "Symptom checklist, 7-stage RTS protocol, sleep & exercise tolerance log." },
  { icon: "◬", title: "Return-to-Sport", desc: "Phase progression with criteria. No guesswork on when to push." },
  { icon: "✦", title: "AI Injury Risk", desc: "ACR, HRV, sleep debt, existing injury — synthesized into a daily risk score with drivers." },
];
