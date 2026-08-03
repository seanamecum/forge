# Forge — Ambient Intelligence (the AI disappears into the experience)

**Locked principle (permanent):** *The intelligence is not the product. The user
experience is the product.* Forge must never feel like an AI chatbot inside a fitness
app. The AI disappears into the interface — users **discover** insights while using the
app; they don't have to ask.

**Benchmark: Apple.** Apple doesn't make users think — the software simply feels like
it understands them. Forge should have that feeling: the default experience is
**beautiful, calm, fast, and effortless**; the AI surfaces only when it's genuinely
helpful, and only expands into detail when the user chooses to dive deeper.

## How intelligence appears (and how it doesn't)
- **Ambient, not conversational.** Every intelligent output is an `AmbientInsight`
  rendered *in context*, not a chat message:
  - while logging → *"This is your usual breakfast."*
  - before a workout → *"Based on your sleep and recovery, today's estimated
    performance is +8%."*
  - during a workout → previous lifts, predicted next weight, rest timer, expected reps.
  - after dinner → *"Protein is still low — here are the easiest foods to close it."*
  - weekly → **one or two** high-impact insights, never an analytics wall.
- **Quiet by default, deep on demand.** An insight shows a single calm line (`title`);
  the concrete "why" (`reason`) and any drill-down appear only when the user taps to
  go deeper. The full chat Coach exists, but it's opt-in — the *default* surface is
  ambient.

## The mechanism (built, tested)
`Core/Personalization/AmbientInsight` makes "the AI disappears" concrete:
- **`AmbientInsight`** — the unified presentation unit every domain emits (id, surface,
  quiet `title`, explainable `reason`, `impact`, `confidence`, dismissible).
- **`InsightCurator`** — turns the *stream* of candidate insights into the *few* that
  surface: ranks by `impact × confidence`, gates on a confidence floor, and **caps the
  count per surface** (1 inline, 2 weekly). This is the engineering embodiment of
  "surface one or two high-impact insights instead of overwhelming."
- **`DismissalMemory`** — never annoying: a dismissed insight goes quiet for a
  cool-down, and repeated dismissals suppress it permanently (Forge learns you don't
  want it). Non-dismissible (critical/safety) insights bypass this.
- **Domain adapters** — each feature (nutrition's `MealSuggestion` today; training,
  recovery, hydration, supplements next) maps its output to an `AmbientInsight`, so
  every domain flows through the *same* calm curation. No feature invents its own UI
  for intelligence.

## Non-negotiables
- **Calm-first.** Restraint is the default; more surfaces stay silent than speak.
- **Contextual + proactive + almost invisible.** Anchored to the moment (`InsightSurface`).
- **Explainable, dismissible, learned from the user's own behavior** (inherits the
  personalization/user-model contracts).
- **Chat is opt-in.** AI-as-conversation appears only when the user explicitly wants to
  dive deeper — never the default experience.

## Roadmap fit
- **Built:** the `AmbientInsight` unit + `InsightCurator` restraint + `DismissalMemory`
  anti-nag + nutrition adapter — all pure and tested.
- **Next:** render ambient insights inline on each surface (diary "usual breakfast"
  chip, pre-workout readiness line, post-meal protein nudge, the weekly one-or-two),
  wire the dismissal store, and route other domains through the curator — with the
  chat Coach kept as the explicit deep-dive.
