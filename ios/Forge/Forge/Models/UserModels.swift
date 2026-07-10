import Foundation

enum Sex: String, CaseIterable, Codable, Identifiable {
    case male = "Male", female = "Female", other = "Other"
    var id: String { rawValue }
}

enum FitnessLevel: String, CaseIterable, Codable, Identifiable {
    case beginner = "Beginner"
    case intermediate = "Intermediate"
    case advanced = "Advanced"
    case elite = "Elite"
    var id: String { rawValue }

    var blurb: String {
        switch self {
        case .beginner: return "< 1 yr structured training"
        case .intermediate: return "1–3 yrs"
        case .advanced: return "3–8 yrs"
        case .elite: return "8+ yrs or competing"
        }
    }
}

enum ActivityLevel: String, CaseIterable, Codable, Identifiable {
    case sedentary = "Sedentary"
    case light = "Light"
    case moderate = "Moderate"
    case active = "Active"
    case veryActive = "Very Active"
    var id: String { rawValue }
}

enum Goal: String, CaseIterable, Codable, Identifiable {
    case buildMuscle = "Build Muscle"
    case loseFat = "Lose Fat"
    case endurance = "Improve Endurance"
    case strength = "Increase Strength"
    case athletic = "Athletic Performance"
    case health = "General Health"
    case injuryRecovery = "Injury Recovery"
    var id: String { rawValue }

    var icon: String {
        switch self {
        case .buildMuscle: return "figure.strengthtraining.traditional"
        case .loseFat: return "flame.fill"
        case .endurance: return "figure.run"
        case .strength: return "scalemass.fill"
        case .athletic: return "bolt.fill"
        case .health: return "heart.fill"
        case .injuryRecovery: return "cross.case.fill"
        }
    }
}

enum Equipment: String, CaseIterable, Codable, Identifiable {
    case fullGym = "Full Gym"
    case homeGym = "Home Gym"
    case dumbbells = "Dumbbells"
    case barbell = "Barbell"
    case bands = "Bands"
    case kettlebell = "Kettlebell"
    case bodyweight = "Bodyweight"
    var id: String { rawValue }
}

enum DietPreference: String, CaseIterable, Codable, Identifiable {
    case omnivore = "Omnivore"
    case highProtein = "High Protein"
    case vegetarian = "Vegetarian"
    case vegan = "Vegan"
    case pescatarian = "Pescatarian"
    case keto = "Keto"
    case paleo = "Paleo"
    var id: String { rawValue }
}

struct UserProfile: Identifiable, Codable {
    let id = UUID()
    var name: String

    // `id` is identity-per-launch, not persisted — excluding it from Codable
    // also silences the immutable-decode warning.
    private enum CodingKeys: String, CodingKey {
        case name, age, sex, heightInches, weightLb, fitnessLevel, activityLevel
        case goals, experienceYears, equipment, diet, sport, level, xp, xpToNext
        case streakDays, usesImperial
    }
    var age: Int
    var sex: Sex
    var heightInches: Double
    var weightLb: Double
    var fitnessLevel: FitnessLevel
    var activityLevel: ActivityLevel
    var goals: [Goal]
    var experienceYears: Int
    var equipment: [Equipment]
    var diet: DietPreference
    var sport: String
    var level: Int
    var xp: Int
    var xpToNext: Int
    var streakDays: Int
    var usesImperial = true

    var primaryGoal: Goal { goals.first ?? .health }

    var heightLabel: String {
        let ft = Int(heightInches) / 12
        let inch = Int(heightInches) % 12
        return "\(ft)'\(inch)\""
    }

    // Daily fuel targets — derived from this athlete's body, activity, and goal.
    var calorieTarget: Int { TargetEngine.calories(self) }
    var proteinTarget: Int { TargetEngine.protein(self) }
    var carbTarget: Int { TargetEngine.carbs(self) }
    var fatTarget: Int { TargetEngine.fat(self) }
    var waterTargetOz: Int { TargetEngine.water(self) }

    var initials: String {
        name.split(separator: " ").compactMap { $0.first.map(String.init) }.prefix(2).joined()
    }
}

struct CoachMessage: Identifiable {
    let id = UUID()
    let role: Role
    let text: String
    var steps: [String] = []
    var cards: [CoachCard] = []
    var suggestions: [String] = []

    enum Role { case user, coach }
}

struct CoachCard: Identifiable {
    let id = UUID()
    let label: String
    let value: String
    var tone: Tone = .neutral
}

struct ForgeNotification: Identifiable {
    let id = UUID()
    let kind: Kind
    let title: String
    let body: String
    let time: String
    var read: Bool

    enum Kind {
        case recommendation, warning, progress, streak, achievement

        var icon: String {
            switch self {
            case .recommendation: return "sparkles"
            case .warning: return "exclamationmark.triangle.fill"
            case .progress: return "chart.line.uptrend.xyaxis"
            case .streak: return "flame.fill"
            case .achievement: return "star.fill"
            }
        }

        var tone: Tone {
            switch self {
            case .recommendation: return .gold
            case .warning: return .amber
            case .progress: return .green
            case .streak: return .gold
            case .achievement: return .gold
            }
        }
    }
}
