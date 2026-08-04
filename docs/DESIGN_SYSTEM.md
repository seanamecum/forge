# Forge Design System

Forge should feel like Apple designed it — calm, content-first, physics-based,
restrained. **Every screen composes shared tokens; nothing re-introduces magic
numbers.** The code is the source of truth — this file is the index.

The screen test: *"If someone believed this shipped by Apple tomorrow, would it
feel believable?"*

## Where it lives

| Layer | File |
|---|---|
| Color + typography tokens | `ios/Forge/Forge/DesignSystem/Theme.swift` |
| Spacing / radii / elevation / motion / icons / materials | `DesignSystem/Tokens.swift` |
| Components (Card, buttons, chips, bars, headers, tiles) | `DesignSystem/Components.swift` |
| State views (loading / empty / error / coming-soon / waitlist) | `DesignSystem/StateViews.swift` |
| Rings (calorie + macro hero, `RingMath`) | `DesignSystem/MacroRings.swift` |
| Haptic language | `Haptics` in `Utilities/Extensions.swift` + `Tokens.swift` |

## Tokens

- **Typography** — named scale `Typography.largeTitle/title/title3/headline/body/callout/subheadline/footnote/caption/eyebrow` (sizes in `Typography.Size`, monotonic + testable), Dynamic-Type aware via `Theme.display/.text/.eyebrow`. Color hierarchy: cream/creamDim/muted/faint.
- **Color** — `Theme` obsidian/gold/cream palette; status green/amber/ruby/royal; `Tone` enum for semantic accents.
- **Spacing** — `Space.xxs…xxxl` (8-pt rhythm) + `Space.tabInset`.
- **Corner radii** — `Radius.sm/md/lg/xl/pill` (cards = `xl`, notes/banners = `sm`).
- **Elevation** — `Elevation.flat/card/raised/modal` via `.elevation(_:)`. Three steps only.
- **Blur materials** — `Materials.bar` (floating bars), `Materials.overlay` (sheets).
- **Icon sizing** — `IconSize.xs/sm/md/lg/xl/hero`.
- **Buttons** — `GoldButtonStyle` (one obvious action), `GhostButtonStyle` (secondary). Both use `Motion.press`.
- **Cards** — `Card(gold:)` — radius `xl`, padding `Space.xl`, `.elevation(.card)`.
- **Charts / progress** — `CapsuleBar`, `LabeledBar`, `ScoreRing`, `MetricRing`, `MacroRings`/`MacroDial` (`RingMath` for fill).
- **Empty / loading / error states** — `EmptyStateView`, `LoadingStateView`, `ErrorBanner`. Never a dead end.
- **Success state** — `Haptics.logged()` + snappy count/insert; confirming, not blocking.

## Motion

Named, physics-based, referenced by intent — every animation has a purpose.

| Token | Use |
|---|---|
| `Motion.spring` | button presses, toggles, card taps |
| `Motion.snappy` | chips, expand/collapse, small state flips |
| `Motion.reveal` | rings filling, numbers counting, first paint |
| `Motion.gentle` | ambient / secondary cross-fades |
| `Motion.press` | button-style press feedback |

Reduce Motion is honored: reveals snap instantly.

## Haptic language

Call sites express intent, not raw generators, so the whole app speaks one
tactile language.

| Call | Meaning |
|---|---|
| `Haptics.logged()` | an item was logged / committed (the signature confirm) |
| `Haptics.soft()` | reversible change — undo, dismiss, gentle nudge |
| `Haptics.rigid()` | deliberate discrete action — stepper tick, snap-into-place |
| `Haptics.selection()` | moving between options |
| `Haptics.warning()` | needs attention, not an error (over target) |
| `Haptics.error()` | an action failed |
| `Haptics.tap()` | lightweight generic tap |

## Rules

1. New screens compose existing tokens/primitives. No new magic numbers for
   spacing, radii, springs, durations, or haptics.
2. One obvious action per screen; progressive disclosure for the rest.
3. The AI disappears — the interface is the product, never a chatbot.
4. Never fabricate data or a full ring on absent data (`RingMath` guards this).
