# Forge — Unified Personalization Engine

**Principle:** Forge should never feel like a database — it should feel like a
personal coach that already knows you, and gets smarter every day it's installed.

**Architecture rule:** there is **one** personalization/learning engine, not a
separate recommender per feature. Every Forge domain plugs into the same core and
emits explainable, user-controlled suggestions from the user's own history.

## The shared core (`Core/Personalization/`)
- **`PersonalizationDomain`** — nutrition · training · recovery · sleep · hydration ·
  supplements · checkin · rehab · habits · coaching. One enum tags every signal.
- **`HabitProfile`** — the domain-agnostic learned shape for any subject (a meal, an
  exercise, a supplement, a habit): occurrences, first/last seen, typical hour,
  weekday/weekend bias.
- **`HabitScore`** — the reusable scoring math, extracted from Smart Meal Memory so
  **every domain learns identically**: `profile(times:)` (the when/how-often learner)
  + `frequency` × `recency` × `timeOfDay` × `weekday`. Pure + tested.
- **`PersonalizationSuggestion`** — the unified, explainable output: `title`,
  `reason` (the transparent "why"), `score`, `domain`, `subjectID`. Domains may also
  use richer typed suggestions (e.g. nutrition's `MealSuggestion`) carrying the same
  contract.
- **`PersonalizationSettings`** — per-domain on/off; the user is always in control.

## How a domain plugs in (three steps)
1. **Emit history** — the domain already logs timestamped events (diary entries,
   workouts, supplement logs, check-ins, PT sessions…). No new store needed; the
   engine reads existing per-user, RLS-synced data.
2. **Learn** — reduce that history to `HabitProfile`s per subject via `HabitScore`.
3. **Suggest** — a small domain suggester ranks subjects for the current context
   (time, weekday, what's already done today) into `PersonalizationSuggestion`s.

Nutrition is the first consumer: `MealMemory` (learn recurring meals) + `MealSuggester`
(rank → "Log your usual breakfast?") both now sit on `HabitScore`.

## What it will learn (expanding over time)
Beyond repeated meals: favorite foods / restaurants / grocery stores / brands;
typical portions (already: `FoodQuantityMemory`) and meal timing; training-day vs
rest-day, bulking vs cutting, weekday vs weekend, seasonal, travel/vacation, and
recovery-day eating; pre- and post-workout meals. The same core then powers workout
suggestions, recovery/sleep/hydration/supplement reminders, daily check-in nudges,
injury-rehab exercises, habit reminders, and AI coaching — one engine behind all.

## Non-negotiables (privacy-first, transparent, honest)
- **On-device + per-user.** Learning runs locally over the user's own data; nothing
  new leaves the device beyond the existing owner-scoped RLS sync.
- **Explainable.** Every suggestion carries its `reason`; no black-box nudges.
- **User-controlled.** Any domain can be disabled; suggestions are dismissible.
- **Never fabricated.** Suggestions come only from real logged behavior; with sparse
  history the engine stays quiet rather than guessing.
- **No demo leakage.** Demo mode never learns from or writes real personalization.

## Roadmap fit
- **Now (2.2b-core):** the shared core + nutrition (Smart Meal Memory) refactored onto
  it; behavior-preserving, fully tested.
- **Next:** wire suggestions + one-tap "log the usual" into the app; derive
  recents/favorites/frequently-eaten from the diary.
- **Later:** each additional domain (training, recovery, supplements, rehab, habits,
  coaching) becomes a thin suggester over `HabitScore` — no new engine.
