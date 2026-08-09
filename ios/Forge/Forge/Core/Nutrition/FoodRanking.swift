import Foundation

/// The user's own history, which strongly biases ranking so *their* usual foods come
/// first. Populated from the diary (recents/frequency) + favorites; passed into the
/// ranker so "the correct food is usually the first result."
struct PersonalSignals: Sendable {
    var favoriteFoodIDs: Set<String> = []
    /// Most-recent first (by foodID).
    var recentFoodIDs: [String] = []
    /// foodID → number of times logged.
    var frequency: [String: Int] = [:]
    /// Preferred locale (e.g. "US") to break ties toward local products.
    var locale: String? = nil

    static let none = PersonalSignals()

    /// 0–1 personal affinity for a food: favorite dominates, then recency, then how
    /// often it's logged (log-scaled so a daily staple ranks above a one-off).
    func affinity(foodID: String) -> Double {
        var s = 0.0
        if favoriteFoodIDs.contains(foodID) { s = max(s, 1.0) }
        if let idx = recentFoodIDs.firstIndex(of: foodID) {
            s = max(s, 0.8 * (1.0 - Double(idx) / Double(max(1, recentFoodIDs.count))))
        }
        if let f = frequency[foodID], f > 0 {
            s = max(s, min(0.9, log(Double(f) + 1) / log(30)))   // ~1.0 around 29 logs
        }
        return min(1, s)
    }
}

/// Pure query-relevance scoring (0–1): exact > prefix > all-tokens > some-tokens >
/// light fuzzy. Typo/semantic ranking is layered on in Phase 2.4; this already gives
/// forgiving, sensible ordering.
enum FoodRelevance {
    static func score(query: String, name: String, brand: String?) -> Double {
        let q = norm(query)
        guard !q.isEmpty else { return 0.5 }              // no query → neutral (personal wins)
        let hay = norm(name + " " + (brand ?? ""))
        let nm = norm(name)
        if nm == q { return 1.0 }
        if nm.hasPrefix(q) || hay.hasPrefix(q) { return 0.85 }
        let qTokens = q.split(separator: " ").map(String.init)
        let hayTokens = Set(hay.split(separator: " ").map(String.init))
        if !qTokens.isEmpty {
            let matched = qTokens.filter { t in hayTokens.contains(t) || hay.contains(t) }.count
            if matched == qTokens.count { return 0.75 }
            if matched > 0 { return 0.55 * Double(matched) / Double(qTokens.count) + 0.2 }
        }
        if hay.contains(q) { return 0.5 }
        // Light fuzzy: single-token near-match by edit distance.
        if qTokens.count == 1, hayTokens.contains(where: { editClose(q, $0) }) { return 0.45 }
        return 0
    }

    static func norm(_ s: String) -> String {
        s.lowercased().folding(options: .diacriticInsensitive, locale: nil)
            .trimmingCharacters(in: .whitespaces)
    }

    /// True when two short tokens are within a small edit distance (typo tolerance).
    static func editClose(_ a: String, _ b: String) -> Bool {
        let maxD = a.count <= 4 ? 1 : 2
        return levenshtein(a, b) <= maxD
    }

    static func levenshtein(_ a: String, _ b: String) -> Int {
        let x = Array(a), y = Array(b)
        if x.isEmpty { return y.count }; if y.isEmpty { return x.count }
        var prev = Array(0...y.count)
        var cur = [Int](repeating: 0, count: y.count + 1)
        for i in 1...x.count {
            cur[0] = i
            for j in 1...y.count {
                cur[j] = x[i-1] == y[j-1] ? prev[j-1]
                    : 1 + Swift.min(prev[j-1], prev[j], cur[j-1])
            }
            swap(&prev, &cur)
        }
        return prev[y.count]
    }
}

/// Ranks merged candidates so the right food is usually first: a scored blend of
/// query relevance × personal history × confidence × completeness × popularity ×
/// locale. Pure + tested; mirrored server-side at scale.
enum FoodRanker {
    struct Weights {
        var relevance = 0.45, personal = 0.25, confidence = 0.15
        var completeness = 0.05, popularity = 0.05, locale = 0.05
        static let `default` = Weights()
    }

    /// popularity: optional 0–1 global popularity per foodID (from the index).
    static func score(_ food: CanonicalFood, query: String, personal: PersonalSignals,
                      popularity: [String: Double] = [:], weights: Weights = .default) -> Double {
        let rel = FoodRelevance.score(query: query, name: food.name, brand: food.brand)
        let per = personal.affinity(foodID: food.id)
        let pop = popularity[food.id] ?? 0
        let loc = (personal.locale != nil) ? 1.0 : 0.0     // locale hook (index provides region)
        return rel * weights.relevance
            + per * weights.personal
            + food.confidence * weights.confidence
            + food.completeness * weights.completeness
            + pop * weights.popularity
            + loc * weights.locale
    }

    /// Sort candidates best-first. Drops zero-relevance results when a query is
    /// present (so junk never appears), keeps all when browsing (empty query).
    static func rank(_ foods: [CanonicalFood], query: String, personal: PersonalSignals = .none,
                     popularity: [String: Double] = [:], weights: Weights = .default) -> [CanonicalFood] {
        let scored = foods.map { ($0, score($0, query: query, personal: personal, popularity: popularity, weights: weights),
                                  FoodRelevance.score(query: query, name: $0.name, brand: $0.brand)) }
        let filtered = FoodRelevance.norm(query).isEmpty ? scored : scored.filter { $0.2 > 0 || personal.affinity(foodID: $0.0.id) > 0 }
        return filtered.sorted { $0.1 > $1.1 }.map(\.0)
    }
}
