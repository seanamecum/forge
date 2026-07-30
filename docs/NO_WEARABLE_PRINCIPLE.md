# Forge Core Principle — Exceptional Without a Wearable

**A wearable enhances Forge's intelligence; it is never required to use it.** Every
major feature has two paths, and the app must feel complete on the manual path alone.
No screen, number, or message may imply the experience is incomplete because the user
doesn't own a wearable.

## The two paths

| Domain | Without a wearable (always works) | With a wearable (enhancement) |
|---|---|---|
| Recovery | **Morning check-in** (sleep quality, soreness, energy, stress) → recovery estimate | Automatic HRV vs baseline, resting HR, sleep → recovery |
| Forge Score | Check-in + logged training, nutrition, weight | + HRV, sleep stages, activity, readiness |
| Daily Directive | Check-in + logs | + continuous biometrics |
| Training | Logged workouts, PRs, RPE | Live/auto workouts, HR, load |
| Nutrition | Full logging, targets, adaptive coach | (no wearable needed) |
| Weight / body comp | Manual weigh-ins, measurements, photos | Smart-scale / HealthKit sync |
| Sleep | Manual sleep logging in the check-in | Sleep stages (Apple Watch / Oura) |
| Bloodwork · goals · habits · deficiencies | Fully manual | — |

Wearable specifics improve **confidence and automation**, not access:
Apple Watch → HealthKit (HRV, sleep, RHR, activity); WHOOP → HRV & recovery;
Oura → sleep & readiness; Garmin → endurance & training load. The AI gracefully
combines whatever is present.

## Rules the code must follow (enforced)

1. **Lead with the check-in, not the wearable.** Any "personalize your data" prompt
   names the **morning check-in first** ("no wearable needed") and frames a wearable
   as an *optional* add-on for automatic HRV/sleep/activity.
2. **Never say "demo data until you connect a wearable."** A real account that has
   logged a check-in (or workouts/nutrition/weight) is running on **real data** — its
   `provenance` is `.partial`, not `.demo`, and messaging reflects that.
3. **"Missing inputs" framing:** the check-in is listed as the primary way to improve
   a number; the wearable line is explicitly marked "(optional)".
4. **Only the truly no-input state is unpersonalized** — and even then the fix offered
   is the check-in, not a purchase.
5. **No dead ends:** every "estimate/unpersonalized" state links to the check-in.

## Where this lives in code
- `AppState.forgeScoreBasis` / `directiveBasis` / `recoveryBasis` — the transparency
  contracts: missing-inputs + `safeFallback` strings now lead with the check-in and
  mark wearables optional (see `RecommendationBasisTests`).
- `RecoveryService.provenance` — `.demo` only when there is **no** live signal **and**
  **no** check-in; a check-in ⇒ `.partial` (real, subjective input).
- Dashboard `connectHealthBanner`, `DashboardCards` wearable row, `RecoverHomeView`
  captions, trend "building" state — all reframed as optional enhancement.
- `MorningCheckInCard` on the dashboard surfaces the primary no-wearable path.

## Tests
`RecommendationBasisTests` locks the principle: in the no-input state the basis
mentions the **check-in** and marks a wearable **optional** (never "required"/"Apple
Health" as the only path); a logged check-in personalizes recovery + Forge Score
without a wearable and removes wearable-gated fallbacks.

## Future wearables
WHOOP / Oura / Garmin land via their cloud APIs at the backend launch; each is
additive to this same two-path model. Adding a source must never move an existing
manual capability behind it.
