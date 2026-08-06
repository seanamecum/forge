import Foundation

/// Lightweight, privacy-respecting product analytics. Events are recorded in a
/// capped local ring (UserDefaults) and are ready to forward to a backend when
/// one ships — no third-party SDK, no PII, nothing leaves the device today.
enum AnalyticsEvent: String {
    case onboardingStarted        = "onboarding_started"
    case onboardingStepViewed     = "onboarding_step_viewed"
    case onboardingStepCompleted  = "onboarding_step_completed"
    case onboardingResumed        = "onboarding_resumed"
    case onboardingWearableSkipped = "onboarding_wearable_skipped"
    case onboardingHealthKitRequested = "onboarding_healthkit_requested"
    case onboardingCompleted      = "onboarding_completed"
}

struct AnalyticsRecord: Codable, Equatable {
    var name: String
    var props: [String: String]
    var at: Date
}

enum Analytics {
    private static let key = "forge.analytics.events.v1"
    private static let cap = 500

    static func log(_ event: AnalyticsEvent, _ props: [String: String] = [:],
                    at: Date = .now, defaults: UserDefaults = .standard) {
        var events = all(defaults: defaults)
        events.append(AnalyticsRecord(name: event.rawValue, props: props, at: at))
        if events.count > cap { events.removeFirst(events.count - cap) }
        if let data = try? JSONEncoder().encode(events) { defaults.set(data, forKey: key) }
    }

    static func all(defaults: UserDefaults = .standard) -> [AnalyticsRecord] {
        guard let data = defaults.data(forKey: key),
              let events = try? JSONDecoder().decode([AnalyticsRecord].self, from: data) else { return [] }
        return events
    }

    static func clear(defaults: UserDefaults = .standard) { defaults.removeObject(forKey: key) }
}
