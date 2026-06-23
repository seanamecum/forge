# Forge — Platform Architecture (web-first SaaS)

> The operating system for human performance. Web is the product now; iOS/Android
> reuse the same brain, APIs, schema, and auth. **Build once, reuse everywhere.**

This pivot does **not** start over. It promotes the existing Next.js web app (`src/`,
26 routes, design system, rule-based coach) and the decision engines already proven
on the native side (Directive, Forge Score, cross-module Insight, Rehab, Target) into
a real, multi-tenant SaaS on Supabase.

---

## 1. Architecture (the layer cake)

```
┌──────────────────────────────────────────────────────────────┐
│  CLIENTS        Next.js (web, PWA)  │  React Native (phase 3)  │  ← thin UI only
├──────────────────────────────────────────────────────────────┤
│  @forge/core    pure-TS domain brain (NO React, NO Supabase)   │  ← reused everywhere
│                 score · directive · insight · rehab · targets  │
│                 · forecast · workout-gen · types               │
├──────────────────────────────────────────────────────────────┤
│  @forge/data    typed data access (Supabase client + queries   │  ← swappable transport
│                 + React Query hooks) — one contract, two UIs    │
├──────────────────────────────────────────────────────────────┤
│  SUPABASE       Postgres + RLS · Auth · Storage · Realtime ·    │  ← the backend
│                 Edge Functions (AI coach proxy, score cron)     │
├──────────────────────────────────────────────────────────────┤
│  AI            Claude (claude-opus-4-8) via Edge Function only  │  ← key never on client
└──────────────────────────────────────────────────────────────┘
```

**The rule that makes mobile cheap later:** all decision logic lives in `@forge/core`
as pure functions over plain types. The web app and the RN app are both *thin*: fetch
rows → call `@forge/core` → render. No business logic in components.

---

## 2. Folder structure (pnpm + Turborepo monorepo)

```
forge/
  apps/
    web/                      # Next.js 14 App Router (move today's src/ here)
      app/(marketing)/        # public: landing, pricing, login
      app/(app)/              # authed shell: dashboard, coach, train, fuel, recover…
      components/ ui/ (shadcn) charts/ layout/
      lib/ supabase/ (server+browser clients) providers/ (RQ, theme)
    mobile/                   # Expo / React Native (phase 3) — imports the same packages
  packages/
    core/                     # @forge/core — pure TS brain (port the Swift engines 1:1)
      score.ts directive.ts insight.ts rehab.ts targets.ts forecast.ts
      workout-gen.ts types.ts  __tests__/
    data/                     # @forge/data — Supabase queries + React Query hooks + zod
    ui/                       # @forge/ui — shared primitives (Ring, Sparkline, tokens)
    config/                   # tsconfig, eslint, tailwind preset (dark/gold/cream)
  supabase/
    migrations/0001_forge_init.sql   # ← shipped
    functions/coach/  functions/recompute-score/   # Edge Functions (Deno)
  turbo.json  pnpm-workspace.yaml
```

Today's `src/lib/ai/coach.ts`, `src/lib/mock/*`, and the `ui/` components map directly
into `packages/core`, `packages/data` (mock → Supabase), and `packages/ui`.

---

## 3. Database schema

Shipped in [`supabase/migrations/0001_forge_init.sql`](supabase/migrations/0001_forge_init.sql).
Highlights:
- **Owner-only RLS on every user table** (`auth.uid() = user_id`) — the security spine,
  identical for web and mobile. Shared catalogs (exercises, public foods, challenges,
  public posts) are world-readable.
- **Daily signal tables** (`recovery_days`, `sleep_days`, `hydration_days`,
  `body_snapshots`) keyed `(user_id, day)` so wearable/HealthKit syncs **upsert** a day.
- **Engine outputs cached per day** (`forge_score_history`, `directives`) so the
  dashboard is one fast read and trends/streaks are free.
- `handle_new_user` trigger auto-creates `profiles` + a free `subscriptions` row on signup.
- Enums in Postgres = one contract shared by web, mobile, and edge functions.

---

## 4. Authentication flow

Supabase Auth (email magic-link + Google/Apple OAuth).
1. User signs in → Supabase issues a JWT (access + refresh).
2. `handle_new_user` trigger creates `profiles` + `subscriptions`.
3. Web: `@supabase/ssr` stores the session in cookies; middleware guards `(app)/*` and
   refreshes tokens server-side (RSC-safe).
4. Mobile (phase 3): same Supabase Auth, session in SecureStore — **same users table,
   same RLS, zero backend changes.**
5. The JWT's `auth.uid()` is what every RLS policy checks — auth and authorization are
   one mechanism across all clients.

---

## 5. Dashboard design

One screen that answers "what do I do today?", top to bottom:
`Daily Directive` (hero, the prescribed plan + why) → `Forge Score` ring + drivers →
4 metric rings (Recovery / Sleep / Readiness / Resilience) → Today's Workout →
Fuel status → Injury/Rehab → Forecast peek. Mobile-first single column; on desktop it
becomes a 2–3 col bento grid. Built with shadcn cards + Framer Motion entrance + the
existing hand-rolled SVG charts (`Ring`, `Sparkline`, `Bar`) promoted to `@forge/ui`.

---

## 6. AI system design

- **Never** call Claude from the browser. A Supabase **Edge Function** (`functions/coach`)
  holds the key, builds the system prompt from the user's live rows (recovery, sleep,
  nutrition, injuries, bloodwork, forecasts, **today's directive + score + rehab plan**),
  calls `claude-opus-4-8`, and streams the reply back.
- **Two-tier brain:** `@forge/core` deterministically computes the Directive, Score,
  Insights, and Rehab plan (free, instant, offline-safe). Claude *narrates and adapts*
  on top of that structured context → it can never contradict the on-screen plan.
- Free tier = deterministic engines + limited chat; Pro/Elite = full streaming coach,
  weekly plan generation, deload/rehab/nutrition plan generation.

---

## 7. API structure

Three transports, all behind `@forge/data` so clients never see the difference:
1. **Direct Postgres (PostgREST)** for CRUD — `supabase.from('food_logs')…` wrapped in
   typed query fns + React Query hooks (`useToday()`, `useDirective()`, `useLogFood()`).
2. **Edge Functions** for privileged/compute work: `POST /coach` (AI),
   `POST /recompute-score`, `POST /generate-workout`, `POST /sync/healthkit`,
   `POST /stripe/webhook`.
3. **Realtime** channels for live surfaces (team feed, challenge leaderboards, coach
   typing). Mobile subscribes to the identical channels.

---

## 8. Mobile expansion strategy

- **Phase 1 — Web app** (now): promote `src/` → `apps/web`, wire Supabase, ship.
- **Phase 2 — PWA**: `manifest.ts`, service worker, installable, offline read cache via
  React Query persistence. (90% of "app feel" for ~0 extra code.)
- **Phase 3 — React Native (Expo)**: new `apps/mobile` that imports `@forge/core` +
  `@forge/data` unchanged; only the view layer is rewritten. Auth, schema, RLS, AI,
  business logic = **already done**. HealthKit/Health Connect feed the same
  `recovery_days`/`sleep_days` upserts.
- **Phase 4 — Wearable ecosystem**: WHOOP/Oura/Garmin OAuth → Edge Function ingest →
  same daily-signal tables. One pipeline, every client benefits.

---

## 9. Revenue strategy

| Tier | Price | What unlocks |
|---|---|---|
| **Free** | $0 | Dashboard, logging, deterministic Directive + Forge Score, basic history |
| **Forge Pro** | ~$12/mo | Full AI Coach (streaming + plan generation), Forecasting/Digital Twin, Recovery Intelligence, advanced analytics, unlimited history |
| **Forge Elite** | ~$29/mo | Pro + Coach Marketplace access, premium programs, priority AI, team tools |

Billing via **Stripe** (`subscriptions` table + `stripe/webhook` Edge Function flips
`plan`). Entitlements checked in `@forge/core` (`hasFeature(plan, feature)`) so web and
mobile gate identically. Later revenue: marketplace take-rate, team/coach seats, wearable
partnerships.

---

## 10. Development roadmap

**M0 — Foundation (1–2 wk):** monorepo + Turborepo; move `src/`→`apps/web`; add shadcn,
React Query, Framer Motion; Supabase project + run `0001` migration; `@forge/data` client.
**M1 — Auth + real data (1 wk):** magic-link + OAuth, middleware guard, onboarding writes
`profiles`; swap one module (nutrition) from mock → Supabase end-to-end as the pattern.
**M2 — The Big 3 live (2 wk):** port the engines to `@forge/core` with tests; Dashboard,
Daily Directive, Forge Score reading real rows; `recompute-score` cron.
**M3 — Coach (1 wk):** `functions/coach` streaming Claude with the live system prompt.
**M4 — Breadth (2–3 wk):** training, recovery, injury/PT, forecasting on real data.
**M5 — Monetize (1 wk):** Stripe, tiers, paywall, free-tier limits.
**M6 — PWA + launch (1 wk):** manifest/SW, polish, marketing site, beta.
**Phase 3:** Expo app reusing `@forge/core` + `@forge/data`.

---

### Why this wins
The hard part of a performance app isn't screens — it's the **decision engine** that
turns data into "what do I do today?". That engine already exists and is unit-tested.
This architecture wraps it in a multi-tenant, monetizable, mobile-ready platform without
throwing any of it away.
