import Foundation
#if canImport(ActivityKit)
import ActivityKit
#endif

/// App-side lifecycle for the workout Live Activity. Fire-and-forget by
/// design: if Live Activities are disabled or unsupported, every call is a
/// silent no-op and the in-app logger is unaffected.
@MainActor
enum WorkoutLiveActivityController {

    #if canImport(ActivityKit)
    private static var current: Activity<WorkoutActivityAttributes>?

    static func start(workoutName: String, startedAt: Date, totalSets: Int) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        end()   // never stack two sessions
        let attributes = WorkoutActivityAttributes(workoutName: workoutName, startedAt: startedAt)
        let state = WorkoutActivityAttributes.ContentState(
            setsDone: 0, totalSets: totalSets, volumeLb: 0, restEndsAt: nil, isPR: false)
        current = try? Activity.request(
            attributes: attributes,
            content: .init(state: state, staleDate: nil))
    }

    static func update(setsDone: Int, totalSets: Int, volumeLb: Double,
                       restEndsAt: Date?, isPR: Bool = false) {
        guard let activity = current else { return }
        let state = WorkoutActivityAttributes.ContentState(
            setsDone: setsDone, totalSets: totalSets, volumeLb: volumeLb,
            restEndsAt: restEndsAt, isPR: isPR)
        Task { await activity.update(.init(state: state, staleDate: nil)) }
    }

    static func end() {
        guard let activity = current else { return }
        current = nil
        Task { await activity.end(nil, dismissalPolicy: .immediate) }
    }
    #else
    static func start(workoutName: String, startedAt: Date, totalSets: Int) {}
    static func update(setsDone: Int, totalSets: Int, volumeLb: Double,
                       restEndsAt: Date?, isPR: Bool = false) {}
    static func end() {}
    #endif
}
