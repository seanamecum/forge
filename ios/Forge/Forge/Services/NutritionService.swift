import Foundation
import Observation

@Observable
final class NutritionService {
    var entries: [FoodEntry] = MockData.todaysEntries
    var foods: [Food] = MockData.foods
    var savedMeals: [SavedMeal] = MockData.savedMeals
    var nutrientGroups: [NutrientGroup] = MockData.nutrientGroups
    var deficiencies: [DeficiencyAlert] = MockData.deficiencies
    var supplements: [Supplement] = MockData.supplements
    var waterOz: Double = 74

    let user = MockData.sean

    // MARK: - Totals

    var calories: Int { entries.reduce(0) { $0 + $1.calories } }
    var protein: Int { Int(entries.reduce(0) { $0 + $1.protein }) }
    var carbs: Int { Int(entries.reduce(0) { $0 + $1.carbs }) }
    var fat: Int { Int(entries.reduce(0) { $0 + $1.fat }) }

    var caloriesRemaining: Int { max(0, user.calorieTarget - calories) }
    var proteinRemaining: Int { max(0, user.proteinTarget - protein) }

    var hydrationPct: Int { Int(waterOz / Double(user.waterTargetOz) * 100) }

    // Scores feeding the Forge Score
    var nutritionScore: Int {
        let calPct = min(1, Double(calories) / Double(user.calorieTarget))
        let proPct = min(1, Double(protein) / Double(user.proteinTarget))
        // Pace-adjusted: by evening these approach 100.
        return Int((calPct * 0.4 + proPct * 0.6) * 100 * 1.15).clamped(to: 0...100)
    }

    var hydrationScore: Int { hydrationPct.clamped(to: 0...100) }

    // MARK: - Actions

    func entries(for meal: MealType) -> [FoodEntry] {
        entries.filter { $0.meal == meal }
    }

    func add(food: Food, to meal: MealType, servings: Double = 1) {
        entries.append(FoodEntry(meal: meal, food: food, servings: servings, time: "Now"))
    }

    func remove(_ entry: FoodEntry) {
        entries.removeAll { $0.id == entry.id }
    }

    func addWater(_ oz: Double) {
        waterOz = min(Double(user.waterTargetOz) * 1.5, waterOz + oz)
    }

    func toggleSupplement(_ supplement: Supplement) {
        guard let idx = supplements.firstIndex(where: { $0.id == supplement.id }) else { return }
        supplements[idx].loggedToday.toggle()
        supplements[idx].streak += supplements[idx].loggedToday ? 1 : -1
    }

    func search(_ query: String) -> [Food] {
        guard !query.isEmpty else { return foods }
        return foods.filter { $0.name.localizedCaseInsensitiveContains(query) }
    }
}
