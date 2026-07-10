import Foundation

/// The weekly recap — Forge's reflection ritual. Where the Directive answers
/// "what should I do today?", this answers "how did the week actually go, and
/// what's the ONE thing to fix next week?" Pure logic over the 14-day trend
/// windows so every judgment here is unit-tested.
struct WeeklyReport: Equatable {
    let recoveryAvg: Int
    let recoveryDelta: Int          // vs the prior 7 days
    let hrvDelta: Int               // avg ms vs the prior 7 days
    let sleepAvgHours: Double
    let sleepDebtHours: Double      // sum of nightly shortfalls vs target
    let sleepConsistency: String    // "Steady" or "Erratic"
    let strainAvg: Double
    let wins: [String]
    let watchouts: [String]
    let verdict: String             // one-line headline for the week
    let nextFocus: String           // the single change to make next week
}

enum WeeklyReportEngine {

    /// Arrays are oldest→newest; the last 7 entries are "this week",
    /// the 7 before them are the comparison week.
    static func make(recovery: [Double],
                     sleep: [Double],
                     strain: [Double],
                     hrv: [Double],
                     sleepTarget: Double = 8.0,
                     streakDays: Int,
                     lever: String) -> WeeklyReport {

        let recentRecovery = Array(recovery.suffix(7))
        let priorRecovery = Array(recovery.dropLast(7).suffix(7))
        let recentSleep = Array(sleep.suffix(7))
        let recentStrain = Array(strain.suffix(7))

        let recoveryAvg = avg(recentRecovery)
        let recoveryDelta = priorRecovery.isEmpty ? 0 : recoveryAvg - avg(priorRecovery)
        let hrvDelta: Int = {
            let recent = Array(hrv.suffix(7)), prior = Array(hrv.dropLast(7).suffix(7))
            return prior.isEmpty ? 0 : avg(recent) - avg(prior)
        }()

        let sleepAvg = recentSleep.isEmpty ? 0 : recentSleep.reduce(0, +) / Double(recentSleep.count)
        let sleepDebt = recentSleep.reduce(0) { $0 + max(0, sleepTarget - $1) }
        let sleepSpread = (recentSleep.max() ?? 0) - (recentSleep.min() ?? 0)
        let consistency = sleepSpread <= 1.5 ? "Steady" : "Erratic"
        let strainAvg = recentStrain.isEmpty ? 0 : recentStrain.reduce(0, +) / Double(recentStrain.count)
        let highStrainDays = recentStrain.filter { $0 >= 17 }.count

        // ---- Wins (always at least one — effort deserves acknowledgment) ----
        var wins: [String] = []
        if recoveryDelta >= 2 { wins.append("Recovery up \(recoveryDelta) points vs last week") }
        if hrvDelta >= 1 { wins.append("HRV trending up (+\(hrvDelta) ms on the weekly average)") }
        if streakDays >= 7 { wins.append("\(streakDays)-day logging streak intact") }
        if sleepDebt < 1.5 { wins.append("Sleep debt nearly clear (\(oneDp(sleepDebt))h)") }
        if wins.isEmpty { wins.append("You kept showing up — \(streakDays) straight days logged") }

        // ---- Watchouts (empty is allowed — a clean week reads clean) ----
        var watchouts: [String] = []
        if sleepDebt >= 2 { watchouts.append("\(oneDp(sleepDebt))h of sleep debt accumulated") }
        if recoveryDelta <= -2 { watchouts.append("Recovery slipped \(abs(recoveryDelta)) points vs last week") }
        if highStrainDays >= 2 { watchouts.append("\(highStrainDays) high-strain days (17+) without matching recovery") }
        if consistency == "Erratic" { watchouts.append("Bedtime drifted — sleep ranged \(oneDp(sleepSpread))h night to night") }

        // ---- Verdict ----
        let verdict: String
        switch (recoveryDelta, sleepDebt) {
        case (2..., ..<2):   verdict = "You gained ground this week."
        case (2..., _):      verdict = "Improving — but sleep is the tax you're still paying."
        case ((-1)...1, _):  verdict = "A holding week. Steady, not stalling."
        default:             verdict = "The week took more than it gave back."
        }

        // ---- Next week's ONE focus ----
        let nextFocus: String
        if sleepDebt >= 3 {
            nextFocus = "One change next week: a fixed lights-out. Clearing \(oneDp(sleepDebt))h of debt lifts every other number."
        } else if recoveryDelta <= -3 {
            nextFocus = "One change next week: cap intensity for 3 days and let recovery climb back before pushing again."
        } else {
            nextFocus = "One change next week: \(lever.prefix(1).lowercased() + lever.dropFirst())"
        }

        return WeeklyReport(recoveryAvg: recoveryAvg, recoveryDelta: recoveryDelta,
                            hrvDelta: hrvDelta, sleepAvgHours: sleepAvg,
                            sleepDebtHours: sleepDebt, sleepConsistency: consistency,
                            strainAvg: strainAvg, wins: wins, watchouts: watchouts,
                            verdict: verdict, nextFocus: nextFocus)
    }

    private static func avg(_ xs: [Double]) -> Int {
        xs.isEmpty ? 0 : Int((xs.reduce(0, +) / Double(xs.count)).rounded())
    }
    private static func oneDp(_ x: Double) -> String { String(format: "%.1f", x) }
}
