import Foundation

/// Where a food's data came from — drives its trust badge, its baseline confidence,
/// and how duplicates merge (the most authoritative source wins each field).
enum FoodSource: String, Codable, CaseIterable, Sendable {
    case usda            // USDA FoodData Central (authoritative generic + branded)
    case verifiedBrand   // manufacturer / verified branded label
    case restaurant      // restaurant / chain menu
    case openFoodFacts   // crowd-sourced global packaged
    case community       // moderated community submission
    case user            // the user's own custom food

    /// Baseline reliability (0–1) before completeness/verification adjust it.
    var reliability: Double {
        switch self {
        case .usda:          return 0.95
        case .verifiedBrand: return 0.92
        case .restaurant:    return 0.80
        case .openFoodFacts: return 0.65
        case .community:     return 0.55
        case .user:          return 0.70   // trusted for the user's own logging
        }
    }

    /// Short badge label shown next to a result.
    var label: String {
        switch self {
        case .usda:          return "USDA"
        case .verifiedBrand: return "Verified"
        case .restaurant:    return "Restaurant"
        case .openFoodFacts: return "Open Food Facts"
        case .community:     return "Community"
        case .user:          return "Yours"
        }
    }

    /// Precedence when merging duplicates (higher wins a contested field).
    var precedence: Int {
        switch self {
        case .usda:          return 6
        case .verifiedBrand: return 5
        case .restaurant:    return 4
        case .user:          return 3
        case .openFoodFacts: return 2
        case .community:     return 1
        }
    }
}

/// Computes a food's confidence score (0–1) — the single trust number that badges a
/// result and feeds ranking. Purely a function of source reliability, how complete
/// the nutrition data is, whether it's verified, and how many independent sources
/// corroborate it. Never invented — a sparse, unverified, uncorroborated food scores
/// low and is flagged.
enum FoodConfidence {
    /// - Parameters:
    ///   - completeness: 0–1 nutrient completeness (see `CanonicalFood.completeness`).
    ///   - corroboration: number of *additional* sources agreeing (0 = only this one).
    static func score(source: FoodSource, completeness: Double,
                      verified: Bool = false, corroboration: Int = 0) -> Double {
        let base = source.reliability
        // Completeness scales the base down when data is sparse (0.6…1.0 multiplier).
        let completenessFactor = 0.6 + 0.4 * completeness.clampedUnit
        var score = base * completenessFactor
        if verified { score = min(1, score + 0.05) }
        // Each corroborating source adds diminishing trust, capped.
        score = min(1, score + min(0.12, Double(max(0, corroboration)) * 0.04))
        return score.clampedUnit
    }

    /// A food whose confidence falls here should be visibly flagged as low/incomplete.
    static let lowThreshold = 0.5
}

private extension Double {
    var clampedUnit: Double { Swift.min(1, Swift.max(0, self)) }
}
