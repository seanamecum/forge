import Foundation

/// Turns the morning check-in (subjective) into recovery + sleep scores. For an
/// athlete without a wearable, this IS their recovery signal — so the daily
/// 15-second check-in actually moves the Forge Score and the Directive instead of
/// just filling a form. Objective live HRV wins when it's available. Pure + tested.
enum CheckInEngine {

    /// Subjective recovery 0–100 from energy (30%), sleep quality (30%), soreness
    /// (25%, inverted), and stress (15%, inverted).
    static func recovery(_ c: CheckInSnapshot) -> Int {
        let energy = frac(c.energy, 1, 5)
        let sleep  = frac(c.sleepQuality, 1, 5)
        let soreOK = 1 - frac(c.soreness, 0, 10)
        let calm   = 1 - frac(c.stress, 1, 5)
        let blend = 0.30 * energy + 0.30 * sleep + 0.25 * soreOK + 0.15 * calm
        return Int((blend * 100).rounded()).clamped(to: 0...100)
    }

    /// Sleep-component score from the 1–5 quality rating (1 → 40, 5 → 95).
    static func sleepScore(_ quality: Int) -> Int {
        let q = min(5, max(1, quality))
        return Int((40 + Double(q - 1) / 4 * 55).rounded()).clamped(to: 0...100)
    }

    /// Readiness band for a recovery value — keeps the readiness ring in step.
    static func readiness(for recovery: Int) -> RecoveryData.Readiness {
        switch recovery {
        case 90...:   return .peak
        case 75..<90: return .high
        case 55..<75: return .moderate
        default:      return .low
        }
    }

    private static func frac(_ v: Int, _ lo: Int, _ hi: Int) -> Double {
        Double(min(hi, max(lo, v)) - lo) / Double(hi - lo)
    }
}
