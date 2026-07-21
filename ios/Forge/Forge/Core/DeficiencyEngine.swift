import Foundation

/// Derives deficiency flags from the athlete's **real** bloodwork — markers below
/// their optimal range. No bloodwork → no flags (honest empty state, never demo).
/// Pure + tested. "Lower is better" markers (LDL, hs-CRP) have optimalLow ≈ 0, so
/// they're never mislabelled a deficiency.
enum DeficiencyEngine {
    static func detect(bloodwork: [BloodworkMarker]) -> [DeficiencyAlert] {
        bloodwork
            .filter { $0.value < $0.optimalLow }
            .map { m in
                let belowNormal = m.value < m.normalLow
                return DeficiencyAlert(
                    nutrient: m.name,
                    severity: belowNormal ? .high : .medium,
                    current: "\(trim(m.value)) \(m.unit)",
                    target: "\(trim(m.optimalLow))+ \(m.unit)",
                    daysLow: 0,
                    recommendation: belowNormal
                        ? "Below the normal range on your labs — discuss correction with your physician."
                        : "Below optimal on your labs — raise it with diet or supplementation, and confirm with your clinician.")
            }
    }

    private static func trim(_ v: Double) -> String {
        v == v.rounded() ? String(Int(v)) : String(format: "%.1f", v)
    }
}
