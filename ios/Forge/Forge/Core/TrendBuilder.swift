import Foundation

/// Builds the athlete's OWN trend series from their persisted daily snapshots, so a
/// real user's recovery/HRV/sleep/strain/Forge-Score charts show THEIR history —
/// never the demo athlete's seeded trend. Pure + tested. Empty history yields empty
/// series (an honest "no data yet"), never a fabricated line.
enum TrendBuilder {
    /// Minimum real data points before a trend chart is worth showing; below this a
    /// real account shows a "building" state rather than one or two lonely dots.
    static let minPointsToShow = 3

    struct Series {
        var recovery: [Double]
        var hrv: [Double]
        var sleep: [Double]
        var strain: [Double]
        var forgeScore: [Double]

        var hasEnoughToShow: Bool {
            [recovery, hrv, sleep, strain, forgeScore].contains { $0.count >= minPointsToShow }
        }
    }

    /// Assemble the series from raw daily values (already oldest→newest). Kept
    /// value-typed so it's trivially unit-testable without SwiftData.
    static func make(recovery: [Int], hrv: [Int], sleepHours: [Double],
                     strain: [Double], scores: [Int]) -> Series {
        Series(recovery: recovery.map(Double.init),
               hrv: hrv.map(Double.init),
               sleep: sleepHours,
               strain: strain,
               forgeScore: scores.map(Double.init))
    }
}
