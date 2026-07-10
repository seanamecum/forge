import SwiftUI
import UIKit

/// Forge design tokens — obsidian / gold / cream luxury athletic palette.
enum Theme {
    // Backgrounds
    static let bg = Color(red: 0.020, green: 0.024, blue: 0.031)          // #050608
    static let bgElevated = Color(red: 0.051, green: 0.063, blue: 0.082)  // #0D1015
    static let card = Color(red: 0.075, green: 0.090, blue: 0.118)        // #131722
    static let cardHigh = Color(red: 0.106, green: 0.125, blue: 0.161)    // #1B2029

    // Gold accent
    static let gold = Color(red: 0.831, green: 0.686, blue: 0.216)        // #D4AF37
    static let goldBright = Color(red: 0.961, green: 0.863, blue: 0.478)  // #F5DC7A
    static let goldDeep = Color(red: 0.627, green: 0.498, blue: 0.122)    // #A07F1F

    // Typography
    static let cream = Color(red: 0.957, green: 0.925, blue: 0.847)       // #F4ECD8
    static let creamDim = Color(red: 0.812, green: 0.769, blue: 0.659)    // #CFC4A8
    static let muted = Color(red: 0.545, green: 0.576, blue: 0.659)       // #8B93A8
    static let faint = Color(red: 0.353, green: 0.384, blue: 0.459)       // #5A6275

    // Status
    static let green = Color(red: 0.365, green: 0.827, blue: 0.620)       // #5DD39E
    static let ruby = Color(red: 0.608, green: 0.165, blue: 0.247)        // #9B2A3F
    static let rubyBright = Color(red: 0.761, green: 0.373, blue: 0.455)  // #C25F74
    static let amber = Color(red: 0.914, green: 0.725, blue: 0.286)       // #E9B949
    static let royal = Color(red: 0.420, green: 0.561, blue: 0.800)       // #6B8FCC

    static let hairline = gold.opacity(0.12)

    static let goldGradient = LinearGradient(
        colors: [goldBright, gold, goldDeep],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let cardGradient = LinearGradient(
        colors: [cardHigh.opacity(0.85), card.opacity(0.7)],
        startPoint: .top,
        endPoint: .bottom
    )

    /// Luxury serif display font (New York).
    static func display(_ size: CGFloat, _ weight: Font.Weight = .medium) -> Font {
        .system(size: scaled(size, .title2), weight: weight, design: .serif)
    }

    /// Tiny tracked-out uppercase eyebrow label font.
    static func eyebrow(_ size: CGFloat = 10) -> Font {
        .system(size: scaled(size, .caption2), weight: .semibold)
    }

    /// Dynamic-Type-aware body text. New code should prefer this over raw
    /// `.system(size:)`; existing call sites migrate screen by screen.
    static func text(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        .system(size: scaled(size, .body), weight: weight)
    }

    /// Scale a design-point size with the user's content size category.
    /// Views re-evaluate `body` when Dynamic Type changes, so fonts built
    /// through these factories track the setting automatically.
    private static func scaled(_ size: CGFloat, _ style: UIFont.TextStyle) -> CGFloat {
        UIFontMetrics(forTextStyle: style).scaledValue(for: size)
    }
}

extension View {
    /// Score-tone color helper: green high, amber mid, ruby low.
    func toneColor(for value: Int) -> Color {
        if value >= 75 { return Theme.green }
        if value >= 55 { return Theme.amber }
        return Theme.rubyBright
    }
}

enum Tone {
    case neutral, gold, green, ruby, amber, royal

    var color: Color {
        switch self {
        case .neutral: return Theme.creamDim
        case .gold: return Theme.gold
        case .green: return Theme.green
        case .ruby: return Theme.rubyBright
        case .amber: return Theme.amber
        case .royal: return Theme.royal
        }
    }
}
