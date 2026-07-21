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
    var bloodwork: [BloodworkMarker] = MockData.bloodwork
    var waterOz: Double = 74

    var user = MockData.sean

    /// A real account builds its own stack/labs — the demo athlete's supplement,
    /// micronutrient, deficiency, and bloodwork data belong to demo mode only.
    func clearDemoSeed() {
        supplements = []
        nutrientGroups = []
        deficiencies = []
        bloodwork = []
    }

    func restoreDemoSeed() {
        supplements = MockData.supplements
        nutrientGroups = MockData.nutrientGroups
        deficiencies = MockData.deficiencies
        bloodwork = MockData.bloodwork
    }

    /// Today's coached plan (set by AppState from live cross-module signals).
    /// When present, IT defines the targets; base TargetEngine numbers otherwise.
    var activePlan: FuelPlan?

    var calorieTarget: Int { activePlan?.calories ?? user.calorieTarget }
    var proteinTarget: Int { activePlan?.protein ?? user.proteinTarget }
    var waterTargetOz: Int { activePlan?.waterOz ?? user.waterTargetOz }
    var carbTarget: Int { activePlan?.carbs ?? user.carbTarget }
    var fatTarget: Int { activePlan?.fat ?? user.fatTarget }

    // MARK: - Totals

    var calories: Int { entries.reduce(0) { $0 + $1.calories } }
    var protein: Int { Int(entries.reduce(0) { $0 + $1.protein }) }
    var carbs: Int { Int(entries.reduce(0) { $0 + $1.carbs }) }
    var fat: Int { Int(entries.reduce(0) { $0 + $1.fat }) }

    var caloriesRemaining: Int { max(0, calorieTarget - calories) }
    var proteinRemaining: Int { max(0, proteinTarget - protein) }

    var hydrationPct: Int {
        guard waterTargetOz > 0 else { return 100 }
        return Int(waterOz / Double(waterTargetOz) * 100)
    }

    // Scores feeding the Forge Score
    var nutritionScore: Int {
        let calPct = min(1, Double(calories) / Double(calorieTarget))
        let proPct = min(1, Double(protein) / Double(proteinTarget))
        // Pace-adjusted: by evening these approach 100.
        return Int((calPct * 0.4 + proPct * 0.6) * 100 * 1.15).clamped(to: 0...100)
    }

    var hydrationScore: Int { hydrationPct.clamped(to: 0...100) }

    // MARK: - Actions

    func entries(for meal: MealType) -> [FoodEntry] {
        entries.filter { $0.meal == meal }
    }

    func add(food: Food, to meal: MealType, servings: Double = 1) {
        let entry = FoodEntry(meal: meal, food: food, servings: servings, time: "Now")
        entries.append(entry)
        Task { @MainActor in PersistenceService.saveEntry(entry) }
    }

    func remove(_ entry: FoodEntry) {
        entries.removeAll { $0.id == entry.id }
        Task { @MainActor in PersistenceService.deleteEntry(id: entry.id) }
    }

    func addWater(_ oz: Double) {
        waterOz = min(Double(waterTargetOz) * 1.5, waterOz + oz)
        PersistenceService.saveWater(waterOz)
    }

    func toggleSupplement(_ supplement: Supplement) {
        guard let idx = supplements.firstIndex(where: { $0.id == supplement.id }) else { return }
        supplements[idx].loggedToday.toggle()
        // Streak never goes negative, even if a user un-logs an item that started at 0.
        supplements[idx].streak = max(0, supplements[idx].streak + (supplements[idx].loggedToday ? 1 : -1))
    }

    func search(_ query: String) -> [Food] {
        guard !query.isEmpty else { return foods }
        return foods.filter { $0.name.localizedCaseInsensitiveContains(query) }
    }
}
