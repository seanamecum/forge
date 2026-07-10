import Foundation

// MARK: - Metrics (the normalized vocabulary every device maps into)

/// Every signal Forge can ingest, regardless of which device produced it.
enum MetricKind: String, CaseIterable, Identifiable, Codable {
    case heartRate, restingHR, hrv, sleep, steps, calories, workouts
    case vo2Max, recovery, strain, trainingLoad, respiratoryRate, temperature
    case weight, bodyFat, leanMass

    var id: String { rawValue }

    var label: String {
        switch self {
        case .heartRate: return "Heart Rate"
        case .restingHR: return "Resting HR"
        case .hrv: return "HRV"
        case .sleep: return "Sleep"
        case .steps: return "Steps"
        case .calories: return "Calories"
        case .workouts: return "Workouts"
        case .vo2Max: return "VO₂ Max"
        case .recovery: return "Recovery"
        case .strain: return "Strain"
        case .trainingLoad: return "Training Load"
        case .respiratoryRate: return "Respiratory Rate"
        case .temperature: return "Skin Temp"
        case .weight: return "Weight"
        case .bodyFat: return "Body Fat"
        case .leanMass: return "Lean Mass"
        }
    }

    var icon: String {
        switch self {
        case .heartRate, .restingHR: return "heart.fill"
        case .hrv: return "waveform.path.ecg"
        case .sleep: return "moon.stars.fill"
        case .steps: return "figure.walk"
        case .calories: return "flame.fill"
        case .workouts: return "dumbbell.fill"
        case .vo2Max: return "lungs.fill"
        case .recovery: return "arrow.clockwise.heart.fill"
        case .strain, .trainingLoad: return "gauge.high"
        case .respiratoryRate: return "wind"
        case .temperature: return "thermometer.medium"
        case .weight, .bodyFat, .leanMass: return "scalemass.fill"
        }
    }
}

// MARK: - Data sources

/// Every integration Forge speaks to — plus the future Forge wearable.
/// Forge is source-agnostic by strategy: third-party devices are first-class forever.
enum DataSource: String, CaseIterable, Identifiable, Codable {
    case appleWatch, whoop, oura, garmin, fitbit, polar, smartScale
    case forgeBand   // future hardware — roadmap only, never a dependency

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .appleWatch: return "Apple Watch"
        case .whoop: return "WHOOP"
        case .oura: return "Oura"
        case .garmin: return "Garmin"
        case .fitbit: return "Fitbit"
        case .polar: return "Polar"
        case .smartScale: return "Smart Scale"
        case .forgeBand: return "Forge Band"
        }
    }

    /// What this device actually contributes to the unified stream.
    var capabilities: [MetricKind] {
        switch self {
        case .appleWatch:
            return [.heartRate, .restingHR, .hrv, .sleep, .steps, .calories, .workouts, .vo2Max]
        case .whoop:
            return [.recovery, .hrv, .restingHR, .strain, .sleep, .respiratoryRate, .temperature]
        case .garmin:
            return [.heartRate, .steps, .calories, .workouts, .vo2Max, .trainingLoad, .sleep, .hrv, .recovery]
        case .oura:
            return [.sleep, .hrv, .restingHR, .temperature, .recovery, .respiratoryRate, .steps]
        case .fitbit:
            return [.heartRate, .sleep, .steps, .calories]
        case .polar:
            return [.heartRate, .hrv, .trainingLoad, .workouts]
        case .smartScale:
            return [.weight, .bodyFat, .leanMass]
        case .forgeBand:
            return [.hrv, .sleep, .recovery, .temperature, .restingHR, .strain, .steps]
        }
    }

    /// Why connecting this device makes Forge smarter — shown in the hub.
    var pitch: String {
        switch self {
        case .appleWatch: return "The iOS backbone: heart rate, workouts, sleep, steps, VO₂ max — all live through HealthKit."
        case .whoop: return "Best-in-class recovery and strain. Sharpens your Forge Score and daily training calls."
        case .garmin: return "GPS, running dynamics, and training load — the endurance engine for runners and hybrid athletes."
        case .oura: return "Gold-standard sleep staging plus skin temperature — earlier illness and overtraining warnings."
        case .fitbit: return "Reliable all-day heart rate, sleep, and steps at an accessible price."
        case .polar: return "Chest-strap-grade heart rate and HRV for precise training-intensity control."
        case .smartScale: return "Weight, body fat, and lean mass — the ground truth your forecasts calibrate against."
        case .forgeBand: return "Forge's own sensor — designed around the Forge Score, not retrofitted to it."
        }
    }
}

// MARK: - Readings & quality

/// One normalized reading in the unified stream, with provenance.
struct MetricReading: Equatable {
    let kind: MetricKind
    let value: Double
    let unit: String
    let source: DataSource
    /// Hours since capture — drives the freshness/quality badge.
    let ageHours: Double
}

enum DataQuality: String {
    case excellent = "Excellent"   // < 1 h fresh
    case good = "Good"             // < 24 h
    case stale = "Stale"           // older
    case missing = "Missing"       // no connected source provides it
}
