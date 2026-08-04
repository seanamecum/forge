import SwiftUI
import UIKit

/// Forge design tokens — the single source of truth for spacing, radii, elevation,
/// motion, icon sizing, materials, and the haptic language. Every screen composes
/// these; nothing re-introduces magic numbers. Colors and type live in `Theme`.
///
/// The principle: Forge should feel like Apple designed it — calm, content-first,
/// physics-based, restrained. One system so every feature belongs to one product.

// MARK: - Typography scale

/// The named type scale — every screen picks a step by intent instead of a raw
/// point size, so type stays consistent across features. Sizes live once in
/// `Size` (testable, monotonic) and stay Dynamic-Type-aware via `Theme`.
enum Typography {
    /// The raw point sizes behind the scale — the single place type sizes live.
    enum Size {
        static let largeTitle:  CGFloat = 28   // screen titles
        static let title:       CGFloat = 24   // prominent metric values
        static let title3:      CGFloat = 20   // card / empty-state titles
        static let headline:    CGFloat = 16   // emphasis line in a card
        static let body:        CGFloat = 14   // default copy / primary rows
        static let callout:     CGFloat = 13   // supporting copy
        static let subheadline: CGFloat = 12   // secondary labels
        static let footnote:    CGFloat = 11   // captions
        static let caption:     CGFloat = 10   // small captions
        static let eyebrow:     CGFloat = 9    // tracked-out uppercase labels
    }

    static var largeTitle:  Font { Theme.display(Size.largeTitle) }
    static var title:       Font { Theme.display(Size.title) }
    static var title3:      Font { Theme.display(Size.title3) }
    static var headline:    Font { Theme.text(Size.headline, .semibold) }
    static var body:        Font { Theme.text(Size.body) }
    static var callout:     Font { Theme.text(Size.callout) }
    static var subheadline: Font { Theme.text(Size.subheadline) }
    static var footnote:    Font { Theme.text(Size.footnote) }
    static var caption:     Font { Theme.text(Size.caption) }
    static var eyebrow:     Font { Theme.eyebrow(Size.eyebrow) }
}

// MARK: - Spacing scale (8-pt rhythm)

enum Space {
    static let xxs: CGFloat = 2
    static let xs:  CGFloat = 4
    static let sm:  CGFloat = 8
    static let md:  CGFloat = 12
    static let lg:  CGFloat = 16
    static let xl:  CGFloat = 20
    static let xxl: CGFloat = 24
    static let xxxl: CGFloat = 32
    /// Bottom inset that clears the floating tab bar on scroll views.
    static let tabInset: CGFloat = 110
}

// MARK: - Corner radii

enum Radius {
    static let sm:   CGFloat = 10   // notes, banners, inline chips-of-content
    static let md:   CGFloat = 14   // small tiles, capture buttons
    static let lg:   CGFloat = 18   // secondary panels
    static let xl:   CGFloat = 24   // primary cards
    static let pill: CGFloat = 999  // capsules, buttons
}

// MARK: - Icon sizing

enum IconSize {
    static let xs:   CGFloat = 11
    static let sm:   CGFloat = 13
    static let md:   CGFloat = 15
    static let lg:   CGFloat = 17
    static let xl:   CGFloat = 22
    static let hero: CGFloat = 34   // empty-state and feature glyphs
}

// MARK: - Elevation (shadows)

/// Depth is expressed in three steps only — restraint over a soup of shadows.
enum Elevation {
    case flat, card, raised, modal

    var shadow: (color: Color, radius: CGFloat, y: CGFloat) {
        switch self {
        case .flat:   return (.clear, 0, 0)
        case .card:   return (.black.opacity(0.25), 14, 6)
        case .raised: return (.black.opacity(0.35), 22, 12)
        case .modal:  return (.black.opacity(0.45), 30, 18)
        }
    }
}

extension View {
    /// Apply a design-system elevation step.
    func elevation(_ level: Elevation) -> some View {
        let s = level.shadow
        return shadow(color: s.color, radius: s.radius, y: s.y)
    }
}

// MARK: - Motion

/// Named, physics-based animations. Screens reference these by intent, so timing
/// stays consistent and every animation has a purpose.
enum Motion {
    /// Standard interactive spring — button presses, toggles, card taps.
    static let spring  = Animation.spring(response: 0.34, dampingFraction: 0.85)
    /// Quick snappy flip — chips, small state changes, expand/collapse.
    static let snappy  = Animation.snappy(duration: 0.22)
    /// Content reveal — rings filling, numbers counting up, first paint.
    static let reveal  = Animation.easeOut(duration: 0.9)
    /// Calm cross-fade for ambient / secondary changes.
    static let gentle  = Animation.easeInOut(duration: 0.45)
    /// Press feedback inside button styles.
    static let press   = Animation.easeOut(duration: 0.12)

    /// Raw durations for `withAnimation` sites that need explicit control.
    enum Duration {
        static let press:  Double = 0.12
        static let base:   Double = 0.22
        static let gentle: Double = 0.45
        static let reveal: Double = 0.9
    }
}

// MARK: - Blur materials

/// Semantic blur materials — floating bars vs. full overlays.
enum Materials {
    /// Floating bars layered over content (added bar, inline toolbars).
    static let bar: Material = .ultraThinMaterial
    /// Sheets, popovers, and full overlays.
    static let overlay: Material = .regularMaterial
}

// MARK: - Haptic language

/// The semantic haptic vocabulary — call sites express intent, not raw generators,
/// so the whole app speaks one tactile language. (`tap`/`success`/`selection` live
/// on `Haptics` in Extensions.swift; these extend it.)
extension Haptics {
    /// An item was logged / committed — the signature positive confirmation.
    static func logged()  { UINotificationFeedbackGenerator().notificationOccurred(.success) }
    /// A soft cue for reversible changes (undo, dismiss, gentle nudges).
    static func soft()    { UIImpactFeedbackGenerator(style: .soft).impactOccurred() }
    /// A crisp cue for a deliberate discrete action (stepper tick, snap-into-place).
    static func rigid()   { UIImpactFeedbackGenerator(style: .rigid).impactOccurred() }
    /// Something needs attention but isn't an error (over target, low value).
    static func warning() { UINotificationFeedbackGenerator().notificationOccurred(.warning) }
    /// An action failed.
    static func error()   { UINotificationFeedbackGenerator().notificationOccurred(.error) }
}
