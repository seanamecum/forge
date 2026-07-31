import XCTest
@testable import Forge

/// Phase 2.1: the pure search spine — per-food source + confidence, relevance +
/// personal ranking (correct food first), and dedup→intelligent merge (never ten
/// near-identical rows). Mirrored server-side at scale.
final class FoodSearchCoreTests: XCTestCase {

    private func food(_ id: String, _ name: String, brand: String? = nil, upc: String? = nil,
                      source: FoodSource, verified: Bool = false,
                      _ n: [Nutrient: Double], portions: [ServingUnit] = []) -> CanonicalFood {
        CanonicalFood(id: id, name: name, brand: brand, per100g: NutrientVector(n),
                      portions: portions, source: source, verified: verified, upc: upc)
    }

    // MARK: - Confidence

    func testConfidenceRewardsSourceCompletenessAndCorroboration() {
        let full: [Nutrient: Double] = [.calories: 100, .protein: 10, .carbs: 5, .fat: 3,
                                        .fiber: 1, .sugar: 2, .sodium: 50, .potassium: 90, .calcium: 20, .iron: 1]
        let usda = FoodConfidence.score(source: .usda, completeness: NutrientVector(full).completenessScore())
        let community = FoodConfidence.score(source: .community, completeness: 0.3)
        XCTAssertGreaterThan(usda, community)
        XCTAssertGreaterThan(usda, 0.9)
        XCTAssertLessThan(community, FoodConfidence.lowThreshold)   // sparse community → flagged

        // Corroboration raises trust.
        let solo = FoodConfidence.score(source: .openFoodFacts, completeness: 0.7, corroboration: 0)
        let backed = FoodConfidence.score(source: .openFoodFacts, completeness: 0.7, corroboration: 3)
        XCTAssertGreaterThan(backed, solo)
    }

    func testCanonicalFoodComputesBaseConfidenceAndLowFlag() {
        let sparse = food("x", "Mystery snack", source: .community, [.calories: 200])
        XCTAssertTrue(sparse.isLowConfidence)
        let rich = food("y", "Egg", source: .usda,
                        [.calories: 155, .protein: 13, .carbs: 1, .fat: 11, .fiber: 0, .sugar: 1, .sodium: 124, .iron: 1.7])
        XCTAssertFalse(rich.isLowConfidence)
        XCTAssertGreaterThan(rich.confidence, sparse.confidence)
    }

    // MARK: - Relevance

    func testRelevanceExactBeatsPrefixBeatsToken() {
        let exact = FoodRelevance.score(query: "chicken breast", name: "Chicken Breast", brand: nil)
        let prefix = FoodRelevance.score(query: "chicken", name: "Chicken Breast", brand: nil)
        let token = FoodRelevance.score(query: "breast chicken", name: "Chicken Breast", brand: nil)
        let none = FoodRelevance.score(query: "salmon", name: "Chicken Breast", brand: nil)
        XCTAssertEqual(exact, 1.0, accuracy: 1e-9)
        XCTAssertGreaterThan(exact, prefix)
        XCTAssertGreaterThan(prefix, token)
        XCTAssertGreaterThan(token, none)
        XCTAssertEqual(none, 0, accuracy: 1e-9)
    }

    func testRelevanceIsTypoTolerantAndDiacriticInsensitive() {
        XCTAssertGreaterThan(FoodRelevance.score(query: "chikken", name: "Chicken", brand: nil), 0)  // typo
        XCTAssertGreaterThan(FoodRelevance.score(query: "creme", name: "Crème", brand: nil), 0)      // accent
    }

    // MARK: - Personal ranking (correct food first)

    func testPersonalHistoryBoostsTheUsersFood() {
        let generic = food("g", "Greek Yogurt", source: .usda, [.calories: 59, .protein: 10, .carbs: 4, .fat: 0])
        let mine = food("m", "Greek Yogurt", brand: "Fage", source: .openFoodFacts, [.calories: 97, .protein: 9, .carbs: 4, .fat: 5])
        var personal = PersonalSignals()
        personal.favoriteFoodIDs = ["m"]
        personal.frequency = ["m": 20]

        let ranked = FoodRanker.rank([generic, mine], query: "greek yogurt", personal: personal)
        XCTAssertEqual(ranked.first?.id, "m", "the user's frequently-eaten favorite ranks first")
    }

    func testHigherConfidenceWinsWhenNoPersonalSignal() {
        let authoritative = food("a", "Oatmeal", source: .usda,
                                 [.calories: 68, .protein: 2.4, .carbs: 12, .fat: 1.4, .fiber: 1.7, .sodium: 4])
        let sketchy = food("b", "Oatmeal", source: .community, [.calories: 70])
        let ranked = FoodRanker.rank([sketchy, authoritative], query: "oatmeal")
        XCTAssertEqual(ranked.first?.id, "a")
    }

    func testZeroRelevanceResultsDroppedWhenQueryed() {
        let match = food("a", "Banana", source: .usda, [.calories: 89, .protein: 1, .carbs: 23, .fat: 0])
        let junk = food("b", "Sardines", source: .usda, [.calories: 208, .protein: 25, .carbs: 0, .fat: 11])
        let ranked = FoodRanker.rank([match, junk], query: "banana")
        XCTAssertEqual(ranked.map(\.id), ["a"])
    }

    // MARK: - Dedup / merge (never ten duplicates)

    func testDedupeByUPCMergesToOne() {
        let off = food("off-1", "Protein Bar", brand: "BrandX", upc: "0123", source: .openFoodFacts,
                       [.calories: 380, .protein: 20, .carbs: 40, .fat: 12])                    // no micros
        let brand = food("b-1", "Protein Bar", brand: "BrandX", upc: "0123", source: .verifiedBrand, verified: true,
                         [.calories: 380, .protein: 20, .carbs: 40, .fat: 12, .fiber: 8, .sodium: 140])
        let merged = FoodDeduplicator.dedupe([off, brand])
        XCTAssertEqual(merged.count, 1, "same UPC → one canonical entry")
        let m = merged[0]
        XCTAssertEqual(m.source, .verifiedBrand)                 // most authoritative base
        XCTAssertTrue(m.verified)
        XCTAssertEqual(m.per100g[.fiber]!, 8, accuracy: 1e-9)    // micro kept from the richer source
        XCTAssertGreaterThan(m.confidence, off.confidence)       // corroboration boost
    }

    func testDedupeBySignatureFillsMissingMicros() {
        let a = food("a", "Chicken Breast", source: .openFoodFacts,
                     [.calories: 165, .protein: 31, .carbs: 0, .fat: 3.6])                       // no sodium
        let b = food("b", "Chicken Breast", source: .usda,
                     [.calories: 165, .protein: 31, .carbs: 0, .fat: 3.6, .sodium: 74, .potassium: 256])
        let merged = FoodDeduplicator.dedupe([a, b])
        XCTAssertEqual(merged.count, 1)
        XCTAssertEqual(merged[0].source, .usda)                  // USDA is base
        XCTAssertEqual(merged[0].per100g[.sodium]!, 74, accuracy: 1e-9)
    }

    func testDifferentFoodsWithSimilarNamesDoNotMerge() {
        let whole = food("a", "Milk", source: .usda, [.calories: 61, .protein: 3.2, .carbs: 4.8, .fat: 3.3])
        let skim  = food("b", "Milk", source: .usda, [.calories: 34, .protein: 3.4, .carbs: 5, .fat: 0.1])
        XCTAssertEqual(FoodDeduplicator.dedupe([whole, skim]).count, 2, "macro fingerprint separates them")
    }

    func testMergeUnionsPortions() {
        let a = food("a", "Egg", source: .usda, [.calories: 155, .protein: 13],
                     portions: [.portion(id: "egg", label: "egg", grams: 50, source: .usda)])
        let b = food("b", "Egg", source: .openFoodFacts, [.calories: 155, .protein: 13],
                     portions: [.portion(id: "large-egg", label: "large egg", grams: 58, source: .off)])
        let m = FoodDeduplicator.dedupe([a, b])[0]
        XCTAssertEqual(Set(m.portions.map(\.id)), ["egg", "large-egg"])
    }

    // MARK: - Full pipeline + provider fan-out

    func testPipelineDedupesThenRanks() {
        let personal = PersonalSignals(favoriteFoodIDs: ["fav"], frequency: ["fav": 12])
        let candidates = [
            food("dup1", "Almonds", upc: "9", source: .openFoodFacts, [.calories: 579, .protein: 21, .carbs: 22, .fat: 50]),
            food("dup2", "Almonds", upc: "9", source: .usda, [.calories: 579, .protein: 21, .carbs: 22, .fat: 50, .fiber: 12]),
            food("fav", "Almond Butter", source: .user, [.calories: 614, .protein: 21, .carbs: 20, .fat: 56]),
        ]
        let out = FoodSearchPipeline.process(candidates, query: "almond", personal: personal)
        // Two UPC-dupes merged to one → 2 results total.
        XCTAssertEqual(out.count, 2)
        XCTAssertEqual(out.first?.id, "fav", "the user's frequently-eaten food ranks first")
    }

    func testServiceFansOutAcrossProviders() async {
        let out = await FoodSearchService(providers: [
            FakeProvider(id: "p1", foods: [food("a", "Rice", source: .usda, [.calories: 130, .protein: 2.7, .carbs: 28, .fat: 0.3])]),
            FakeProvider(id: "p2", foods: [food("b", "Rice", source: .openFoodFacts, [.calories: 130, .protein: 2.7, .carbs: 28, .fat: 0.3])]),
        ]).search("rice")
        // Same name + brand (none) + macro fingerprint → merged to one across providers.
        XCTAssertEqual(out.count, 1)
    }

    func testServiceBarcodeLookupUsesFirstHit() async {
        let svc = FoodSearchService(providers: [
            FakeProvider(id: "p1", foods: [], barcodes: [:]),
            FakeProvider(id: "p2", foods: [], barcodes: ["555": food("z", "Soda", upc: "555", source: .openFoodFacts, [.calories: 42])]),
        ])
        let hit = await svc.lookup(barcode: "555")
        XCTAssertEqual(hit?.id, "z")
        let miss = await svc.lookup(barcode: "000")
        XCTAssertNil(miss)
    }
}

/// An in-memory provider for tests (Sendable — safe in the concurrent fan-out).
private struct FakeProvider: FoodSearchProvider {
    let id: String
    var foods: [CanonicalFood] = []
    var barcodes: [String: CanonicalFood] = [:]
    func search(_ query: String, limit: Int) async -> [CanonicalFood] {
        let q = FoodRelevance.norm(query)
        return foods.filter { FoodRelevance.norm($0.name).contains(q) || q.isEmpty }
    }
    func lookup(barcode: String) async -> CanonicalFood? { barcodes[barcode] }
}
