# Forge — The Unified User Model (Operating System for Human Performance)

**Principle:** Forge is not a collection of fitness tools. It is **one continuously-
learning model of the user** that every feature contributes to and learns from. No
isolated AI assistants — one shared understanding behind Nutrition, Training, Sleep,
Recovery, Hydration, Supplements, Bodyweight, Injuries, Stress, Biomarkers, Habits,
Calendar, Goals, and every future domain.

**Goal:** no other app understands a user's body and habits as deeply as Forge —
because every logged action makes the model slightly smarter, and every recommendation
improves from months of accumulated cross-domain history.

## The model has three cooperating layers (all one brain)
1. **Signals** — every domain emits timestamped, typed data into shared, per-user,
   RLS-synced stores (the diary, workouts, recovery/sleep snapshots, supplements,
   weigh-ins, check-ins, injuries…). Reduced to the common currency `DayValue`
   (a day → a number) or discrete events for analysis.
2. **Learning** — the unified engines already built:
   - `HabitScore` / `MealMemory` — *what you do and when* (recurring behavior,
     recency-weighted, adaptive).
   - `PerformanceCorrelation` — *how your behaviors relate to your outcomes* across
     domains (weekday patterns, behavior→outcome deltas, paired correlation), with
     honest data-sufficiency gates.
   - `InsightEngine` / `RecommendationBasis` — causal chains + the explainability
     contract.
3. **Interfaces** — the AI Coach, Daily Directive, and every proactive suggestion are
   **queries over this one model**, not separate systems.

## Questions the model is built to answer
- "Why do I always feel tired on Thursdays?" → `PerformanceCorrelation.weekdayPattern`
- "What habit is hurting my recovery the most?" → `behaviorImpact` across candidate
  behaviors (low-carb days, high strain, short sleep…), ranked by impact.
- "What's the highest-ROI change I can make this week?" → the largest meaningful
  negative `behaviorImpact` I can act on.
- "If I eat this meal now, how will it affect tomorrow's workout?" → intake → next-day
  recovery/readiness relationship + today's targets.
- "Why did my performance improve this month?" / "What changed before my sleep
  improved?" → correlation of the improving series vs behavior series over the window.
- "What routine do I follow before my best workouts?" → the habit profile of the days
  preceding top sessions.

## Non-negotiables (inherited across the whole model)
- **Explainable** — every insight/recommendation carries a concrete "why" from the
  real data. No black boxes.
- **Honest** — below data-sufficiency thresholds the model stays silent rather than
  inventing a pattern; correlation is never presented as proven causation.
- **Adaptive** — recent behavior weighs more; the model tracks change, not just
  history.
- **Privacy-first + user-controlled** — on-device learning over the user's own data;
  view / edit / delete / reset / pause / export (see `PERSONALIZATION_ENGINE.md`).
- **No demo leakage.** Demo never contributes to or reads the real model.
- **Pure, tested, mirrored** — the analytical engines are pure Swift, unit-tested, and
  can be mirrored server-side for heavier long-horizon analysis.

## Status & roadmap fit
- **Built:** `HabitScore`/`MealMemory` (behavior), `PerformanceCorrelation` (cross-
  domain relationships), explainability + adaptivity, `InsightEngine` (training/
  recovery chains).
- **Next:** assemble a concrete `UserModel` that pulls each domain's `DayValue` series
  from the existing stores; a ranked "highest-ROI change" + "what's hurting X"
  insight surface; wire the AI Coach to answer the questions above from the model; the
  cross-domain anticipation feed. Every new domain plugs in by emitting signals — no
  new engine.
