import Foundation

/// Today's recovery snapshot — the signal layer underneath the Forge Score.
struct RecoveryData {
    var recovery: Int            // 0–100
    var hrv: Int                 // ms
    var hrvBaseline: Int
    var restingHR: Int
    var sleep: SleepData
    var strainYesterday: Double  // 0–21
    var strainToday: Double
    var steps: Int
    var stepGoal: Int
    var caloriesOut: Int
    var sleepDebtHours: Double
    var readiness: Readiness

    var sleepScore: Int { sleep.score }
    var hrvDelta: Int { hrv - hrvBaseline }

    var trainingLoadScore: Int {
        // Lower score when yesterday's strain ran hot.
        max(0, min(100, Int(100 - (strainYesterday - 10) * 6)))
    }

    var activityScore: Int {
        min(100, Int(Double(steps) / Double(stepGoal) * 100))
    }

    var stressScore: Int {
        // Proxy: RHR elevation + sleep debt.
        max(0, min(100, 100 - Int(sleepDebtHours * 6) - max(0, restingHR - 52) * 2))
    }

    enum Readiness: String {
        case low = "Low", moderate = "Moderate", high = "High", peak = "Peak"

        var percent: Int {
            switch self {
            case .low: return 30
            case .moderate: return 62
            case .high: return 84
            case .peak: return 96
            }
        }

        var tone: Tone {
            switch self {
            case .low: return .ruby
            case .moderate: return .amber
            case .high, .peak: return .green
            }
        }
    }
}

struct SleepData {
    var hours: Double
    var deepHours: Double
    var remHours: Double
    var lightHours: Double
    var awakeHours: Double
    var score: Int
    var bedtime: String
    var waketime: String

    var stages: [SleepStageSlice] {
        [
            SleepStageSlice(stage: .light, hours: lightHours * 0.4),
            SleepStageSlice(stage: .deep, hours: deepHours * 0.6),
            SleepStageSlice(stage: .rem, hours: remHours * 0.4),
            SleepStageSlice(stage: .light, hours: lightHours * 0.3),
            SleepStageSlice(stage: .deep, hours: deepHours * 0.4),
            SleepStageSlice(stage: .rem, hours: remHours * 0.3),
            SleepStageSlice(stage: .awake, hours: awakeHours * 0.5),
            SleepStageSlice(stage: .light, hours: lightHours * 0.3),
            SleepStageSlice(stage: .rem, hours: remHours * 0.3),
            SleepStageSlice(stage: .awake, hours: awakeHours * 0.5),
        ]
    }
}

struct WearableDevice: Identifiable {
    let id = UUID()
    let name: String
    let brand: String
    let icon: String          // SF Symbol
    var connected: Bool
    var lastSync: String?
    let permissions: [String]
    var battery: Int? = nil
}

struct TrendSeries: Identifiable {
    let id = UUID()
    let name: String
    let unit: String
    let values: [Double]

    var latest: Double { values.last ?? 0 }
}
