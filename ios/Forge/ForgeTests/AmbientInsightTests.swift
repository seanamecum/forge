import XCTest
@testable import Forge

/// "The intelligence is not the product — the experience is." The curation layer that
/// makes intelligence disappear into the UI: surface only the few highest-impact
/// insights, honor dismissals (never nag), and stay calm by default.
final class AmbientInsightTests: XCTestCase {

    private var now: Date { Date(timeIntervalSince1970: 1_700_000_000) }

    private func insight(_ id: String, impact: Double, confidence: Double,
                         surface: InsightSurface = .home, dismissible: Bool = true) -> AmbientInsight {
        AmbientInsight(id: id, domain: .nutrition, surface: surface, title: id, reason: "because",
                       impact: impact, confidence: confidence, isDismissible: dismissible)
    }

    // MARK: - Restraint (surface the few, not the many)

    func testCurationSurfacesOnlyTheTopByDefault() {
        let candidates = [
            insight("a", impact: 0.9, confidence: 0.9),   // priority 0.81
            insight("b", impact: 0.5, confidence: 0.9),   // 0.45
            insight("c", impact: 0.8, confidence: 0.6),   // 0.48
        ]
        let out = InsightCurator.curate(candidates, now: now, policy: .standard(for: .home))
        XCTAssertEqual(out.map(\.id), ["a"])              // one calm, highest-impact line
    }

    func testWeeklyAllowsTwoHighImpactInsights() {
        let candidates = [
            insight("a", impact: 0.9, confidence: 0.9, surface: .weekly),
            insight("b", impact: 0.8, confidence: 0.8, surface: .weekly),
            insight("c", impact: 0.4, confidence: 0.9, surface: .weekly),
        ]
        let out = InsightCurator.curate(candidates, now: now, policy: .standard(for: .weekly))
        XCTAssertEqual(out.map(\.id), ["a", "b"])         // one or two, never a wall
    }

    func testLowConfidenceIsSuppressed() {
        let out = InsightCurator.curate([insight("weak", impact: 1.0, confidence: 0.3)],
                                        now: now, policy: .standard(for: .home))
        XCTAssertTrue(out.isEmpty)                         // unsure → stay silent
    }

    // MARK: - Never annoying (dismissal memory)

    func testDismissedInsightGoesQuietForACooldown() {
        var mem = DismissalMemory()
        mem.recordDismissal("a", at: now)
        // Same day → suppressed.
        var out = InsightCurator.curate([insight("a", impact: 0.9, confidence: 0.9)],
                                        now: now, dismissed: mem, policy: .standard(for: .home))
        XCTAssertTrue(out.isEmpty)
        // After the cool-down → it can return.
        let later = now.addingTimeInterval(4 * 86_400)
        out = InsightCurator.curate([insight("a", impact: 0.9, confidence: 0.9)],
                                    now: later, dismissed: mem, policy: .standard(for: .home))
        XCTAssertEqual(out.map(\.id), ["a"])
    }

    func testRepeatedDismissalSuppressesPermanently() {
        var mem = DismissalMemory()
        for i in 0..<3 { mem.recordDismissal("a", at: now.addingTimeInterval(Double(i) * 5 * 86_400)) }
        let wayLater = now.addingTimeInterval(60 * 86_400)
        let out = InsightCurator.curate([insight("a", impact: 1, confidence: 1)],
                                        now: wayLater, dismissed: mem, policy: .standard(for: .home))
        XCTAssertTrue(out.isEmpty, "Forge learned the user doesn't want this")
        XCTAssertTrue(mem.isSuppressed("a", now: wayLater))
    }

    func testNonDismissibleInsightIgnoresDismissalMemory() {
        var mem = DismissalMemory()
        for i in 0..<5 { mem.recordDismissal("x", at: now.addingTimeInterval(Double(i))) }
        let out = InsightCurator.curate([insight("x", impact: 1, confidence: 1, dismissible: false)],
                                        now: now, dismissed: mem, policy: .standard(for: .home))
        XCTAssertEqual(out.map(\.id), ["x"])              // critical, non-dismissible items still show
    }

    // MARK: - Domain adapter (nutrition feeds the same curator)

    func testMealSuggestionBecomesAnAmbientDiaryInsight() {
        let meal = RememberedMeal(id: "sig", meal: "Breakfast",
                                  items: [MealItem(foodID: "egg", foodName: "Eggs", amount: 3, unitID: "egg", unitLabel: "egg")],
                                  occurrences: 18, firstSeen: now.addingTimeInterval(-20 * 86_400), lastSeen: now,
                                  weekdayBias: .weekday, typicalHour: 8, recencyWeight: 15)
        let suggestion = MealSuggestion(meal: meal, score: 0.8, missingItems: meal.items, reason: "you usually eat this")
        let ambient = suggestion.asAmbientInsight()
        XCTAssertEqual(ambient.surface, .diary)
        XCTAssertEqual(ambient.domain, .nutrition)
        XCTAssertEqual(ambient.confidence, 0.8)
        XCTAssertFalse(ambient.reason.isEmpty)            // explainable
        // Flows through the same curation as every other domain.
        XCTAssertEqual(InsightCurator.curate([ambient], now: now, policy: .standard(for: .diary)).count, 1)
    }
}
