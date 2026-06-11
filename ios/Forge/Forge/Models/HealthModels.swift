import Foundation

struct BloodworkMarker: Identifiable {
    let id = UUID()
    let name: String
    let category: Category
    let value: Double
    let unit: String
    let normalLow: Double
    let normalHigh: Double
    let optimalLow: Double
    let optimalHigh: Double
    let takenAt: String
    var delta: String? = nil
    let aiNote: String

    enum Category: String, CaseIterable {
        case hormones = "Hormones"
        case vitamins = "Vitamins & Minerals"
        case lipids = "Lipids"
        case metabolic = "Metabolic"
        case inflammation = "Inflammation"
        case thyroid = "Thyroid"
    }

    var inOptimal: Bool { value >= optimalLow && value <= optimalHigh }
    var inNormal: Bool { value >= normalLow && value <= normalHigh }

    var status: String {
        if inOptimal { return "Optimal" }
        if inNormal { return "Normal" }
        return "Out of range"
    }

    var statusTone: Tone {
        if inOptimal { return .green }
        if inNormal { return .amber }
        return .ruby
    }
}

// MARK: - Body tracking

struct BodySnapshot: Identifiable {
    let id = UUID()
    let date: String
    let weightLb: Double
    let bodyFatPct: Double
    let leanMassLb: Double
}

struct BodyMeasurement: Identifiable {
    let id = UUID()
    let name: String
    let value: String
    var delta30d: String? = nil
}

// MARK: - Digital twin

struct Forecast: Identifiable {
    let id = UUID()
    let metric: String
    let current: String
    let projected: String
    let eta: String
    let confidence: Double  // 0–1
    let rationale: String
}
