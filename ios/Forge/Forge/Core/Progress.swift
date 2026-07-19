import Foundation

/// One tested home for every "how far toward a target" calculation in Forge.
///
/// Views used to inline `Int((value / target) * 100)` in several places, which
/// (a) divided by zero when a target was missing, (b) could produce NaN/∞ that
/// then trapped in `Int(...)`, and (c) clamped inconsistently — a ring showed
/// 100 % while VoiceOver read "130 percent". Everything now flows through here so
/// the visual and its accessibility label can never disagree.
enum Progress {

    /// True, unclamped percentage (rounded), safe against a zero/negative target
    /// and against NaN/∞. Use when overachievement is meaningful.
    static func percent(_ value: Double, of target: Double) -> Int {
        guard target > 0, value.isFinite, target.isFinite else { return 0 }
        let raw = (value / target) * 100
        guard raw.isFinite else { return 0 }
        return Int(max(0, raw).rounded())
    }

    static func percent(_ value: Int, of target: Int) -> Int {
        percent(Double(value), of: Double(target))
    }

    /// Display percentage, clamped to 0…100 for rings, bars, and their matching
    /// accessibility labels. Never renders a misleading >100 %.
    static func displayPercent(_ value: Double, of target: Double) -> Int {
        min(100, percent(value, of: target))
    }

    static func displayPercent(_ value: Int, of target: Int) -> Int {
        min(100, percent(value, of: target))
    }

    /// 0…1 fraction for `Shape.trim` / bar widths — clamped and finite-safe.
    static func fraction(_ value: Double, of target: Double) -> Double {
        guard target > 0, value.isFinite, target.isFinite else { return 0 }
        let raw = value / target
        guard raw.isFinite else { return 0 }
        return min(1, max(0, raw))
    }
}

/// Forge Score is presented as an 0–100 index; nothing should ever render a 103
/// or a −4. Score maths funnels through this clamp.
enum ForgeScoreBounds {
    static let range: ClosedRange<Int> = 0...100
    static func clamp(_ raw: Int) -> Int { min(range.upperBound, max(range.lowerBound, raw)) }
    static func clamp(_ raw: Double) -> Int {
        guard raw.isFinite else { return range.lowerBound }
        return clamp(Int(raw.rounded()))
    }
}
