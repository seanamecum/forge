import Foundation
#if canImport(ActivityKit)
import ActivityKit
#endif

/// The live-workout contract between the app and the Live Activity UI.
/// Compiled into BOTH targets — keep it dependency-free.
/// Timers render natively via `Text(timerInterval:)`, so the activity only
/// needs updates when sets complete or rest starts — not every second.
#if canImport(ActivityKit)
struct WorkoutActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var setsDone: Int
        var totalSets: Int
        var volumeLb: Double
        /// When set, the lock screen shows a counting-down rest timer.
        var restEndsAt: Date?
        /// Flash the PR treatment on the latest completed set.
        var isPR: Bool

        var setsLabel: String { "\(setsDone)/\(totalSets)" }
        var progress: Double {
            guard totalSets > 0 else { return 0 }
            return Double(setsDone) / Double(totalSets)
        }
        var volumeLabel: String { "\(Int(volumeLb).formatted()) lb" }
    }

    var workoutName: String
    var startedAt: Date
}
#endif
