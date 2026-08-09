import Foundation

/// In-progress onboarding, persisted so a backgrounded or killed app resumes
/// exactly where the user left off — no lost answers, no restart.
struct OnboardingProgress: Codable {
    var step: Int
    var profile: UserProfile
    var injuries: [InjuryType]
    var wearables: [String]
}

enum OnboardingStore {
    private static let key = "forge.onboarding.progress.v1"

    static func save(_ p: OnboardingProgress, defaults: UserDefaults = .standard) {
        if let data = try? JSONEncoder().encode(p) { defaults.set(data, forKey: key) }
    }

    static func load(defaults: UserDefaults = .standard) -> OnboardingProgress? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(OnboardingProgress.self, from: data)
    }

    static func clear(defaults: UserDefaults = .standard) { defaults.removeObject(forKey: key) }
}

/// Continue is gated ONLY where a real value is genuinely required — the body
/// fields that feed calorie/macro targets (never fabricated) and the choices that
/// shape the plan. Everything else advances freely, and several steps can be
/// skipped. Pure + fully testable.
enum OnboardingValidation {
    static func nameValid(_ p: UserProfile) -> Bool {
        !p.name.trimmingCharacters(in: .whitespaces).isEmpty
    }
    static func ageValid(_ p: UserProfile) -> Bool { (13...100).contains(p.age) }
    static func heightValid(_ p: UserProfile) -> Bool { p.heightInches >= 36 && p.heightInches <= 96 }
    static func weightValid(_ p: UserProfile) -> Bool { p.weightLb >= 50 && p.weightLb <= 700 }
    static func goalsValid(_ p: UserProfile) -> Bool { !p.goals.isEmpty }
    static func equipmentValid(_ p: UserProfile) -> Bool { !p.equipment.isEmpty }

    /// Everything onboarding must have before it can finish — so targets are never
    /// computed from blank/fabricated defaults.
    static func readyToFinish(_ p: UserProfile) -> Bool {
        nameValid(p) && ageValid(p) && heightValid(p)
            && weightValid(p) && goalsValid(p) && equipmentValid(p)
    }
}
