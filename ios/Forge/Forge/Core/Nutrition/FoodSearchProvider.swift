import Foundation

/// A source of food search results (local cache, USDA, Open Food Facts, restaurant,
/// the server-side Forge Food Index…). One interface so the client fans out over
/// many sources and swaps them without touching the merge/rank pipeline. Live
/// providers arrive in Phase 2.2–2.3; the protocol + pipeline are defined and tested
/// now (2.1).
protocol FoodSearchProvider: Sendable {
    var id: String { get }
    /// Best-effort results for a query (empty on failure — never throws to the caller).
    func search(_ query: String, limit: Int) async -> [CanonicalFood]
    /// A single food by barcode, or nil if this provider doesn't have it.
    func lookup(barcode: String) async -> CanonicalFood?
}

/// The pure result pipeline: dedupe/merge candidates from all sources, then rank so
/// the correct food is usually first. No networking — fully unit-tested and mirrored
/// server-side at scale.
enum FoodSearchPipeline {
    static func process(_ candidates: [CanonicalFood], query: String,
                        personal: PersonalSignals = .none, popularity: [String: Double] = [:],
                        limit: Int = 25, weights: FoodRanker.Weights = .default) -> [CanonicalFood] {
        let merged = FoodDeduplicator.dedupe(candidates)
        let ranked = FoodRanker.rank(merged, query: query, personal: personal,
                                     popularity: popularity, weights: weights)
        return Array(ranked.prefix(limit))
    }
}

/// Fans out a query across providers concurrently, then runs the pure pipeline.
/// Personal signals + popularity bias ranking toward the user's own foods.
struct FoodSearchService: Sendable {
    var providers: [any FoodSearchProvider]
    var personal: PersonalSignals = .none
    var popularity: [String: Double] = [:]

    func search(_ query: String, limit: Int = 25) async -> [CanonicalFood] {
        var all: [CanonicalFood] = []
        await withTaskGroup(of: [CanonicalFood].self) { group in
            for provider in providers {
                group.addTask { await provider.search(query, limit: limit) }
            }
            for await results in group { all += results }
        }
        return FoodSearchPipeline.process(all, query: query, personal: personal,
                                          popularity: popularity, limit: limit)
    }

    /// Barcode lookup: the first provider that has the product wins (providers are
    /// ordered most-authoritative first).
    func lookup(barcode: String) async -> CanonicalFood? {
        for provider in providers {
            if let food = await provider.lookup(barcode: barcode) { return food }
        }
        return nil
    }
}
