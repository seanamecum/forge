# ◆ FORGE

**Human Performance, Engineered.**

Forge is an AI-powered human performance operating system. Not a fitness app — a closed-loop
decision engine that turns training, nutrition, sleep, recovery, wearable, injury, and bloodwork
data into one clear directive every morning.

> *"The body is a system. Forge is the operating layer."*

> **Native iOS app:** the complete SwiftUI implementation lives in [`ios/`](ios/README.md) —
> open `ios/Forge/Forge.xcodeproj` in Xcode 16+ and run. Same brand, same thesis, real app.

## Stack

- **Next.js 14** (App Router) + **TypeScript** — static prototype, zero backend required
- **Tailwind CSS** — custom obsidian/gold/cream luxury design system
- **Mock data first** — every module runs on local demo data (`src/lib/mock/`), modeled so the
  whole app tells one coherent story and swaps cleanly for a real API later
- **Zero chart libraries** — rings, sparklines, bars, and sleep-stage charts are hand-rolled SVG

## Run it

```bash
npm install
npm run dev        # http://localhost:3000
```

`npm run build` produces a fully static export-ready build (all 26 routes prerender).

## The demo story

Every number in the app belongs to one athlete: **Marcus Vale**, 29, advanced hybrid
hockey athlete, mid-cut, slightly under-recovered, 47-day streak, rehabbing a right-shoulder
impingement (day 18, phase 3). Every module reflects that same state:

- Forge Score **78** (+3) — driven down by hydration 57 and HRV −8 ms
- Today's workout is **auto-deloaded 12%** and avoids overhead pressing (shoulder rehab)
- The AI Coach explains fatigue via sleep debt + low magnesium — which the Deficiency
  module flags, which the Supplements module shows unlogged, which the Bloodwork module
  corroborates (Vit D 28 ng/mL)
- Injury risk **28%** because volume +38% while HRV dropped — the Digital Twin forecasts
  it falling to 12% in 2 weeks if volume holds flat

That cross-module coherence is the product thesis: **every module feeds the brain, the
brain feeds the day.**

## Map

```
src/
  app/
    page.tsx                 Landing — hero, system grid, coach demo, pricing
    onboarding/              9-step profile flow (identity → body → goals → injuries → wearables)
    (app)/                   App shell: sidebar (desktop) + bottom dock (mobile) + top bar
      dashboard/             Command center — Forge Score ring, AI brief, 4 metric rings,
                             today's workout, macros, score drivers, injury risk, streak/XP
      coach/                 AI Coach chat — context panel, reasoning chains, action cards
      workouts/              History, PRs, volume-by-muscle vs optimal zones, today's session
      workouts/log/          Live logger — sets/reps/weight/RPE, rest timer, add-set
      exercises/             Searchable database — anatomy SVG, mistakes, tips, alternatives
      generate/              AI generator — goal/time/equipment inputs + injury-aware output
      form-analysis/         Squat/bench/deadlift upload sim — form score, mistakes, fixes
      nutrition/             Macros, meals, food search, barcode/photo sim, 34-item micro matrix
      deficiencies/          AI detection — severity, target vs current, recommendations
      supplements/           9-item stack — dose, timing, benefit, streaks
      wearables/             7-device hub — live snapshot, permissions, battery, sync
      recovery/              HRV/RHR/sleep stages/debt/readiness with trend charts
      injury/                FORGE RECOVERY — risk model, injury profile, PT library (16),
                             protocols (4 areas), concussion module + 7-stage RTS, checklist
      body/                  Weight/BF/lean mass, 12 measurements, progress photos
      bloodwork/             15 markers — normal vs optimal ranges, AI interpretation
      forecast/              Digital twin — 6 projections with confidence + scenario planner
      social/                Feed (PRs, progress, shares) + 6 groups
      leaderboards/          Steps, Wilks, streak, protein consistency
      challenges/            6 active challenges with progress + rewards
      achievements/          XP/level, daily missions, 11 badges
      marketplace/           Coaches (6), programs (6), affiliate store (8)
      teams/                 Forge Teams — school/gym/team/business dashboards
      notifications/         Smart notification stream
  components/
    layout/                  Sidebar, TopBar, BottomDock
    ui/                      Ring, Sparkline, Barline, Bar, Stat, SectionTitle, Logo
  lib/
    ai/coach.ts              Rule-based coach engine — archetype matching + live user state
    mock/                    user, exercises, workouts, nutrition, supplements, wearables,
                             injuries, bloodwork, body, social, marketplace, notifications
```

## Design system

| Token | Use |
|---|---|
| `obsidian-*` | Backgrounds — near-black with a navy undertone |
| `gold-*` | The accent. Score rings, CTAs, active states |
| `cream-*` | Typography |
| `forge-green / amber / ruby / royal` | Positive / caution / warning / sleep-blue |

Cormorant Garamond (serif display) for headlines and stat numbers; Inter for UI. Glassy
cards (`.card`), gold-glow buttons (`.btn-gold`), hairline dividers, pulse-gold animation
for the AI presence, `rise` entrance animation on every page.

## Swapping in a real backend

- Replace `src/lib/mock/*` exports with API calls — types are already exported per module
- `src/lib/ai/coach.ts → coachReply()` is the single seam for a real LLM call (pass the
  same context object the mock uses as the prompt context)
- Auth: the `(app)` route group is the protected boundary; wire middleware to your provider
- Wearables: `wearables.ts` device shape includes `permissions`/`metrics` ready for OAuth scopes

## Disclaimers

Forge presents **educational guidance, not medical advice** — that wording ships in the
injury, concussion, bloodwork, deficiency, and forecast modules, with explicit prompts to
see a physician/PT for serious symptoms. Keep it that way.
