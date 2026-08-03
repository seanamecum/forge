import Foundation

/// A curated set of common whole foods with accurate per-100 g nutrition and natural
/// portions — the instant, offline, always-available local layer of federated search
/// (real USDA-grade reference values, not fabricated). Ranked first so logging a
/// staple is immediate even with no network. Expanded/replaced by the server-side
/// Forge Food Index (Phase 2.3); this is the reliable local cache.
enum CommonFoods {
    static let all: [CanonicalFood] = [
        f("chicken-breast", "Chicken breast, cooked", 165, 31, 0, 3.6, portions: [("breast", 120)]),
        f("egg", "Egg, whole", 155, 13, 1.1, 11, portions: [("egg", 50)]),
        f("white-rice", "White rice, cooked", 130, 2.7, 28, 0.3, fiber: 0.4, portions: [("cup", 158)]),
        f("oats", "Rolled oats, dry", 379, 13, 67, 7, fiber: 10, portions: [("cup", 81), ("half cup", 40)]),
        f("banana", "Banana", 89, 1.1, 23, 0.3, fiber: 2.6, sugar: 12, portions: [("medium", 118)]),
        f("whole-milk", "Milk, whole", 61, 3.2, 4.8, 3.3, sugar: 5, portions: [("cup", 244)]),
        f("greek-yogurt", "Greek yogurt, nonfat", 59, 10, 3.6, 0.4, sugar: 3.6, portions: [("cup", 245), ("container", 170)]),
        f("almonds", "Almonds", 579, 21, 22, 50, fiber: 12, portions: [("oz", 28)]),
        f("peanut-butter", "Peanut butter", 588, 25, 20, 50, fiber: 6, portions: [("tbsp", 16)]),
        f("salmon", "Salmon, cooked", 208, 20, 0, 13, portions: [("fillet", 150)]),
        f("ground-beef", "Ground beef 85/15, cooked", 250, 26, 0, 15, portions: [("patty", 113)]),
        f("broccoli", "Broccoli", 34, 2.8, 7, 0.4, fiber: 2.6, portions: [("cup", 91)]),
        f("sweet-potato", "Sweet potato, baked", 90, 2, 21, 0.1, fiber: 3.3, portions: [("medium", 130)]),
        f("avocado", "Avocado", 160, 2, 9, 15, fiber: 7, portions: [("medium", 150)]),
        f("apple", "Apple", 52, 0.3, 14, 0.2, fiber: 2.4, sugar: 10, portions: [("medium", 182)]),
        f("whole-wheat-bread", "Bread, whole wheat", 247, 13, 41, 3.4, fiber: 7, portions: [("slice", 28)]),
        f("cheddar", "Cheddar cheese", 403, 25, 1.3, 33, portions: [("slice", 28), ("oz", 28)]),
        f("pasta", "Pasta, cooked", 131, 5, 25, 1.1, fiber: 1.8, portions: [("cup", 140)]),
        f("olive-oil", "Olive oil", 884, 0, 0, 100, portions: [("tbsp", 14)]),
        f("whey", "Whey protein powder", 400, 80, 8, 6, portions: [("scoop", 30)]),
        f("black-beans", "Black beans, cooked", 132, 8.9, 24, 0.5, fiber: 8.7, portions: [("cup", 172)]),
        f("tuna", "Tuna, canned in water", 116, 26, 0, 0.8, portions: [("can", 142)]),
        f("spinach", "Spinach, raw", 23, 2.9, 3.6, 0.4, fiber: 2.2, portions: [("cup", 30)]),
        f("orange-juice", "Orange juice", 45, 0.7, 10, 0.2, sugar: 8, portions: [("cup", 248)]),
        f("coffee", "Coffee, black", 1, 0.1, 0, 0, portions: [("cup", 240)]),
    ]

    private static func f(_ id: String, _ name: String, _ kcal: Double, _ p: Double, _ c: Double, _ fat: Double,
                          fiber: Double? = nil, sugar: Double? = nil, portions: [(String, Double)] = []) -> CanonicalFood {
        var n: [Nutrient: Double] = [.calories: kcal, .protein: p, .carbs: c, .fat: fat]
        if let fiber { n[.fiber] = fiber }
        if let sugar { n[.sugar] = sugar }
        let ports = portions.map { ServingUnit.portion(id: $0.0, label: $0.0, grams: $0.1, source: .usda) }
        return CanonicalFood(id: "forge-\(id)", name: name, per100g: NutrientVector(n),
                             portions: ports, source: .usda)
    }
}

/// The instant local provider — searches the curated common foods (offline-safe).
struct LocalFoodProvider: FoodSearchProvider {
    let id = "forge-local"
    var foods: [CanonicalFood] = CommonFoods.all

    func search(_ query: String, limit: Int) async -> [CanonicalFood] {
        guard !FoodRelevance.norm(query).isEmpty else { return foods }
        return foods.filter { FoodRelevance.score(query: query, name: $0.name, brand: $0.brand) > 0 }
    }
    func lookup(barcode: String) async -> CanonicalFood? { nil }   // no barcodes locally
}
