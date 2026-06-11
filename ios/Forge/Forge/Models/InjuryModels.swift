import Foundation

enum InjuryType: String, CaseIterable, Codable, Identifiable {
    case shoulder = "Shoulder"
    case knee = "Knee"
    case ankle = "Ankle"
    case hip = "Hip"
    case back = "Back"
    case neck = "Neck"
    case wrist = "Wrist"
    case elbow = "Elbow"
    case hamstring = "Hamstring"
    case groin = "Groin"
    case concussion = "Concussion"
    var id: String { rawValue }
}

enum InjuryPhase: String, CaseIterable {
    case acute = "Acute"
    case subacute = "Sub-acute"
    case rehab = "Rehab"
    case returnToSport = "Return-to-Sport"
    case resolved = "Resolved"
}

struct InjuryProfile: Identifiable {
    let id = UUID()
    let type: InjuryType
    let name: String
    var painToday: Int          // 0–10
    var daysOld: Int
    var phase: InjuryPhase
    var severity: Int           // 1–5
    var mobilityPct: Int
    var strengthPct: Int
    var stabilityPct: Int
    var notes: String
    var painHistory: [Double]   // recent trend
}

struct PTExercise: Identifiable {
    let id = UUID()
    let name: String
    let area: String
    let prescription: String
    let note: String
    let phase: InjuryPhase
}

struct RehabProtocol: Identifiable {
    let id = UUID()
    let title: String
    let injuryType: InjuryType
    let symptoms: [String]
    let avoid: [String]
    let phases: [ProtocolPhase]
    let ptExerciseNames: [String]
}

struct ProtocolPhase: Identifiable {
    let id = UUID()
    let name: String
    let goal: String
    let criteria: String
}

struct RTSChecklistItem: Identifiable {
    let id = UUID()
    let label: String
    let detail: String
    var done: Bool
}

// MARK: - Concussion

struct ConcussionSymptom: Identifiable {
    let id = UUID()
    let name: String
    var value: Int  // 0 none – 6 severe
}

struct RTPStage: Identifiable {
    let id = UUID()
    let number: Int
    let name: String
    let detail: String
    var completed: Bool
}

// MARK: - Risk model

struct InjuryRisk {
    let percent: Int
    let band: String
    let drivers: [RiskDriver]
    let recommendation: String
}

struct RiskDriver: Identifiable {
    let id = UUID()
    let name: String
    let value: String
    let note: String
}
