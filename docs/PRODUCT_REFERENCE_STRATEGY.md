# Forge — Official Product-Reference Strategy

Forge's quality bar is set by two best-in-class references. This is policy: every
Train decision is measured against **Hevy**; every other surface against **Bevel**.

## Per-domain benchmarks (locked)
Each Forge domain is measured against the category leader — reference **standards, not
templates to copy**. Study what makes each exceptional (navigation, information
architecture, interactions, animations, onboarding, visual hierarchy, typography,
speed, trust, delight), then build Forge's own design language that **reaches or
exceeds** it.

| Domain | Benchmark |
|---|---|
| Recovery / Health / Dashboard | **Bevel** |
| Workout tracking | **Hevy** |
| Nutrition & Coaching | **MacroFactor** |
| Food database | beat **MyFitnessPal** — via **USDA + Open Food Facts + verified brands + restaurants** |
| Apple ecosystem integration | **Apple Health** |
| Overall polish | **Apple** |

**Non-negotiable:** if we build a feature, it must **compete with the category
leader**. Recovery competes with Bevel; workout logging with Hevy; nutrition with
MacroFactor; food search beats MyFitnessPal; overall polish feels Apple-quality.

### Forge's real advantage — one continuously-learning UserModel
Forge's edge is **not any single feature**; it's that **every domain feeds one
continuously-learning UserModel** (see `UNIFIED_USER_MODEL.md`). Recovery influences
nutrition; nutrition influences training; training influences sleep; sleep influences
recovery — everything contributes to one intelligence. **No competing app should
understand the user more deeply than Forge.** This philosophy drives every design
decision: features reach category-leader quality *and* compound because they share one
model.

## Hard rules (originality)
- **Do NOT copy** either product's branding, code, text/wording, exact layouts,
  icons, assets, or proprietary implementation.
- **DO study and reproduce the underlying product principles**, then improve them
  through Forge's unique ecosystem.
- One product: **one design system** (`DesignSystem/*`), **one intelligence layer**
  (Forge Score · Directive · InsightEngine · Coach), **one identity**. New work
  extends the existing architecture where it's sound; it never forks the look or the
  data model.

## The no-wearable principle (already policy — see `NO_WEARABLE_PRINCIPLE.md`)
Both benchmarks must hold **without any wearable**. Manual paths (morning check-in,
sleep logging, energy/stress/soreness, workouts, nutrition, weight, habits, injury
data, goals) drive a complete experience; a wearable only adds automation and
confidence. Nothing is ever gated behind hardware, and messaging leads with the
check-in, not the device.

## Differentiation — Forge is NOT "Hevy + Bevel"
Forge combines their strongest principles and goes beyond both, as **one unified
app**, through the ecosystem no single-purpose app has:
- **Daily Directive** — one prioritized action synthesized from every signal.
- **Transparent Forge Score** — every number explained (`RecommendationBasis`).
- **AI Coach** — contextual, proactive, grounded only in the user's real data.
- **Adaptive nutrition** + **injury rehabilitation** + **complete workout logging**.
- **Wearable aggregation** (Apple Health / WHOOP / Oura / Garmin) **and** full
  no-wearable support.
- **Forecasting** and **long-term performance intelligence**.

Every workout connects to Forge Score, Directive, Recovery, Nutrition, Sleep, Injury
status, the Coach, and Forecasting — the thing a dedicated tracker can't do.

## How this drives work
- The Train experience is audited against the **Hevy requirement set**; every other
  screen against the **Bevel requirement set** (see the audit + roadmap deliverable).
- Findings are bucketed: complete · partial · missing · weak-UX · technical blocker.
- Work is split **launch-critical vs post-launch**, then shipped **one verified
  milestone at a time** (tests → Debug+Release builds → UI review → commit/push;
  never merged to main without approval), preserving architecture where sound.

## Non-negotiables carried into every milestone
Never fabricate data or capability; honest empty/incomplete/offline states; strict
demo/real isolation; per-user RLS + offline-first sync; accessibility; Debug+Release
green with 0 warnings; comprehensive tests.
