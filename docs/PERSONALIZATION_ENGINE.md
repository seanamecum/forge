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
- **Explainable — always a "Why?".** Every suggestion carries a required, concrete
  `reason` built from the real signals; there is **no unexplained recommendation**.
  (See "Explainability" below.)
- **Adaptive, not sticky.** Recent behavior outweighs old; habits fade and new
  patterns are learned; long-term routines still register. (See "Adaptivity" below.)
- **User-controlled.** View what Forge has learned; edit/delete learned habits; reset
  a domain; pause personalization; export the data. Any domain can be disabled;
  suggestions are dismissible. (See "User control" below.)
- **Never fabricated.** Suggestions come only from real logged behavior; with sparse
  history the engine stays quiet rather than guessing.
- **No demo leakage.** Demo mode never learns from or writes real personalization.

## Explainability (implemented for nutrition)
Every `MealSuggestion` (and the generic `PersonalizationSuggestion`) carries a
non-optional `reason` generated from the learned habit — e.g. *"You've logged this
18× in the last 21 days, usually on weekday mornings."* Domain callers append their
own factors when they have them: *"You're 42 g short of today's protein target,"*
*"suggested because you usually eat this after leg day,"* *"your HRV has been lower
this week, so recovery nutrition was prioritized."* The type requires a reason, so an
unexplained suggestion cannot be constructed.

## Adaptivity (recency-weighted)
`HabitScore` weights recent occurrences more than old ones (exponential decay with a
~2-week half-life), so a changed routine is learned quickly and stale habits fade,
while a long-standing routine still carries real weight. Raw occurrence counts remain
available for display; ranking uses the recency-weighted signal.

## User control (roadmap: next milestone)
`PersonalizationSettings` (pause + per-domain disable) exists; the full control surface
— view learned habits, edit/delete a habit (persisted "forget"), reset a domain, and
export personalization data — lands next, all on-device and reversible.

## Anticipatory, not reactive (a defining feature)
Opening Forge should feel like *"I was just about to do that."* After weeks of use the
engine proactively surfaces the few things you're about to do — across domains:
- *"Ready to log your usual breakfast?"* · *"Looks like today is your Push workout."*
- *"You normally eat another 35 g of protein around this time."*
- *"You usually go to bed in about an hour."* · *"You haven't logged water yet today."*
- *"Recovery is lower than normal today — consider reducing volume."*
- *"Your creatine is usually taken after this meal."*

**Architecture:** an `AnticipationEngine` orchestrates `PersonalizationSuggestion`s from
every domain's suggester (nutrition today; training, sleep, hydration, supplements,
recovery, rehab next) into a single ranked "what's next" feed for the current moment.
Each suggestion is explainable, dismissible, learned from the user's own behavior, and
privacy-first.

**Never annoying (hard anti-spam guarantees, built into the orchestrator):**
- **Confidence gate** — only surface high-confidence, timely suggestions; stay silent
  when unsure.
- **Dismissal memory** — a dismissed suggestion doesn't reappear for a cool-down; a
  repeatedly-dismissed one is suppressed (the engine learns you don't want it).
- **Rate limit** — a small cap on proactive prompts per surface/period; never a wall
  of nudges.
- **Relevance/timing** — anchored to the moment (meal section, time-of-day, what's
  already done today) so a prompt only appears when it's actually about to happen.

The goal: consistently helpful, trustworthy, and smarter every week — Forge's biggest
competitive advantage precisely because it's transparent, not mysterious.

## Roadmap fit
- **Now (2.2b-core):** the shared core + nutrition (Smart Meal Memory) refactored onto
  it; behavior-preserving, fully tested.
- **Next:** wire suggestions + one-tap "log the usual" into the app; derive
  recents/favorites/frequently-eaten from the diary.
- **Later:** each additional domain (training, recovery, supplements, rehab, habits,
  coaching) becomes a thin suggester over `HabitScore` — no new engine.
