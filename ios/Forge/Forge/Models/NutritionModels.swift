import Foundation

struct Food: Identifiable, Hashable {
    let id: String
    let name: String
    var brand: String? = nil
    let serving: String
    let calories: Int
    let protein: Double
    let carbs: Double
    let fat: Double
    var fiber: Double = 0
    var sugar: Double = 0
}

enum MealType: String, CaseIterable, Identifiable {
    case breakfast = "Breakfast"
    case lunch = "Lunch"
    case dinner = "Dinner"
    case snack = "Snacks"
    var id: String { rawValue }

    var icon: String {
        switch self {
        case .breakfast: return "sunrise.fill"
        case .lunch: return "sun.max.fill"
        case .dinner: return "moon.fill"
        case .snack: return "leaf.fill"
        }
    }
}

struct FoodEntry: Identifiable {
    let id = UUID()
    let meal: MealType
    let food: Food
    var servings: Double = 1
    var time: String = ""

    var calories: Int { Int(Double(food.calories) * servings) }
    var protein: Double { food.protein * servings }
    var carbs: Double { food.carbs * servings }
    var fat: Double { food.fat * servings }
}

struct SavedMeal: Identifiable {
    let id = UUID()
    let name: String
    let calories: Int
    let protein: Int
    let carbs: Int
    let fat: Int
    let itemCount: Int
}

// MARK: - Micronutrients

struct NutrientStatus: Identifiable {
    let id = UUID()
    let name: String
    /// 7-day rolling average as % of target.
    let percentOfTarget: Int

    var tone: Tone {
        if percentOfTarget < 60 { return .ruby }
        if percentOfTarget < 90 { return .amber }
        if percentOfTarget > 160 { return .gold }
        return .green
    }
}

struct NutrientGroup: Identifiable {
    let id = UUID()
    let name: String
    let items: [NutrientStatus]
}

struct DeficiencyAlert: Identifiable {
    let id = UUID()
    let nutrient: String
    let severity: Severity
    let current: String
    let target: String
    let daysLow: Int
    let recommendation: String

    enum Severity: String {
        case low = "Low", medium = "Medium", high = "High"

        var tone: Tone {
            switch self {
            case .low: return .gold
            case .medium: return .amber
            case .high: return .ruby
            }
        }
    }
}

struct Supplement: Identifiable {
    let id = UUID()
    let name: String
    let dose: String
    let timing: String
    let benefit: String
    var streak: Int
    var loggedToday: Bool
}
