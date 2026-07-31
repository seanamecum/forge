import Foundation

/// Collapses near-identical foods from different sources into **one** canonical,
/// merged result — so the user never sees ten copies of "Chicken Breast". Groups by
/// UPC, else by a normalized signature (name + brand + a per-100 g macro fingerprint),
/// then merges each group field-by-field preferring the most authoritative/complete
/// source, filling missing micros from corroborating sources, unioning portions, and
/// raising confidence for corroboration. Pure + tested; mirrored server-side.
enum FoodDeduplicator {

    /// Merge a candidate list into deduped canonical foods (order preserved by first
    /// appearance of each group).
    static func dedupe(_ foods: [CanonicalFood]) -> [CanonicalFood] {
        var order: [String] = []
        var groups: [String: [CanonicalFood]] = [:]
        for f in foods {
            let key = signature(f)
            if groups[key] == nil { order.append(key) }
            groups[key, default: []].append(f)
        }
        return order.compactMap { groups[$0].map(merge) }
    }

    /// The grouping key: exact UPC when present (the strongest identity), else a
    /// normalized name+brand + rounded macro fingerprint so genuinely different foods
    /// with similar names don't wrongly merge.
    static func signature(_ f: CanonicalFood) -> String {
        if let upc = f.upc, !upc.isEmpty { return "upc:\(upc)" }
        let name = FoodRelevance.norm(f.name)
        let brand = FoodRelevance.norm(f.brand ?? "")
        func r(_ n: Nutrient) -> Int { Int((f.per100g[n] ?? 0).rounded()) }
        // Macro fingerprint (per 100 g, rounded) separates same-named different foods.
        return "sig:\(name)|\(brand)|\(r(.calories)):\(r(.protein)):\(r(.carbs)):\(r(.fat))"
    }

    /// Merge a group into one food. The most authoritative + complete member is the
    /// base; each nutrient/portion missing on the base is filled from the best member
    /// that has it; confidence is recomputed with a corroboration bonus.
    static func merge(_ group: [CanonicalFood]) -> CanonicalFood {
        guard var base = group.max(by: { rank($0) < rank($1) }) else { return group[0] }
        guard group.count > 1 else { return base }
        let others = group.filter { $0.id != base.id }

        // Fill missing nutrients from the highest-precedence member that has each.
        var values = base.per100g.values
        for nutrient in Nutrient.allCases where base.per100g[nutrient] == nil {
            if let donor = group
                .filter({ $0.per100g[nutrient] != nil })
                .max(by: { $0.source.precedence < $1.source.precedence }) {
                values[nutrient.rawValue] = donor.per100g[nutrient]
            }
        }
        base.per100g = NutrientVector(rawValues: values)

        // Union portions (dedup by id), base's first.
        var seen = Set(base.portions.map(\.id))
        for f in others { for p in f.portions where seen.insert(p.id).inserted { base.portions.append(p) } }

        // Prefer a UPC / verified flag / freshest timestamp if the base lacks them.
        if base.upc == nil { base.upc = others.compactMap(\.upc).first }
        base.verified = group.contains { $0.verified }
        base.updatedAt = group.compactMap(\.updatedAt).max() ?? base.updatedAt

        // Recompute confidence with corroboration (each other source agreeing adds trust).
        base.confidence = FoodConfidence.score(
            source: base.source, completeness: base.completeness,
            verified: base.verified, corroboration: distinctSources(group) - 1)
        return base
    }

    /// Merge precedence within a group: authority first, then completeness, then a
    /// present UPC as a tiebreak.
    private static func rank(_ f: CanonicalFood) -> Double {
        Double(f.source.precedence) * 10 + f.completeness * 5 + (f.upc != nil ? 0.5 : 0)
    }

    private static func distinctSources(_ group: [CanonicalFood]) -> Int {
        Set(group.map(\.source)).count
    }
}
