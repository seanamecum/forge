import XCTest
import SwiftData
@testable import Forge

/// The Nutrition & Health milestone: real users own their supplements, bloodwork,
/// and derived deficiencies; demo mode stays completely separate; and the AI coach
/// only ever sees the current account's own clinical data — never Sean's mock knee,
/// labs, or deficiencies.
final class NutritionHealthTests: XCTestCase {

    // MARK: Helpers

    /// Isolated in-memory store — proves the SupplementRecord/BloodworkRecord model
    /// + schema addition (the migration path) without touching the shared container.
    @MainActor private func freshContext() throws -> ModelContext {
        let container = try ModelContainer(
            for: SupplementRecord.self, BloodworkRecord.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        return ModelContext(container)
    }

    /// The shared container backs `loadHealthData()`; clear it so each integration
    /// test starts from a clean slate regardless of run order.
    @MainActor private func clearSharedHealthStore() {
        try? PersistenceService.context.delete(model: SupplementRecord.self)
        try? PersistenceService.context.delete(model: BloodworkRecord.self)
        try? PersistenceService.context.save()
    }

    private func catalog(_ name: String) -> BloodworkCatalogEntry {
        BloodworkCatalog.markers.first { $0.name == name }!
    }

    // MARK: - DeficiencyEngine (pure)

    func testMarkerBelowNormalIsHighSeverity() {
        let vitD = catalog("Vitamin D (25-OH)").marker(value: 24, takenAt: "Today") // < normalLow 30
        let alerts = DeficiencyEngine.detect(bloodwork: [vitD])
        XCTAssertEqual(alerts.count, 1)
        XCTAssertEqual(alerts.first?.nutrient, "Vitamin D (25-OH)")
        XCTAssertEqual(alerts.first?.severity, .high)
    }

    func testMarkerBelowOptimalButWithinNormalIsMedium() {
        let vitD = catalog("Vitamin D (25-OH)").marker(value: 40, takenAt: "Today") // 30 ≤ 40 < 50
        let alerts = DeficiencyEngine.detect(bloodwork: [vitD])
        XCTAssertEqual(alerts.first?.severity, .medium)
    }

    func testMarkerAtOrAboveOptimalIsNotFlagged() {
        let vitD = catalog("Vitamin D (25-OH)").marker(value: 60, takenAt: "Today") // ≥ optimalLow 50
        XCTAssertTrue(DeficiencyEngine.detect(bloodwork: [vitD]).isEmpty)
    }

    func testLowerIsBetterMarkersAreNeverMislabelledDeficiencies() {
        // LDL and hs-CRP have optimalLow ≈ 0 — a normal value must never be a "deficiency".
        let ldl = catalog("LDL").marker(value: 90, takenAt: "Today")
        let crp = catalog("hs-CRP").marker(value: 2.0, takenAt: "Today")
        XCTAssertTrue(DeficiencyEngine.detect(bloodwork: [ldl, crp]).isEmpty)
    }

    func testNoBloodworkYieldsNoDeficiencies() {
        XCTAssertTrue(DeficiencyEngine.detect(bloodwork: []).isEmpty)
    }

    // MARK: - Persistence / migration round-trip

    @MainActor
    func testSupplementRecordRoundTrips() throws {
        let ctx = try freshContext()
        PersistenceService.insertSupplement(
            SupplementRecord(name: "Creatine", dose: "5 g", timing: "Daily", benefit: "Strength"), context: ctx)
        let fetched = try ctx.fetch(FetchDescriptor<SupplementRecord>())
        XCTAssertEqual(fetched.count, 1)
        XCTAssertEqual(fetched.first?.name, "Creatine")
        XCTAssertEqual(fetched.first?.streak, 0)
    }

    @MainActor
    func testSupplementUpdateAndDelete() throws {
        let ctx = try freshContext()
        PersistenceService.insertSupplement(
            SupplementRecord(name: "Magnesium", dose: "400 mg", timing: "Before bed", benefit: "Sleep"), context: ctx)
        PersistenceService.updateSupplement(named: "Magnesium", streak: 3, lastLogged: .now, context: ctx)
        var fetched = try ctx.fetch(FetchDescriptor<SupplementRecord>())
        XCTAssertEqual(fetched.first?.streak, 3)
        XCTAssertNotNil(fetched.first?.lastLoggedDate)

        PersistenceService.deleteSupplement(named: "Magnesium", context: ctx)
        fetched = try ctx.fetch(FetchDescriptor<SupplementRecord>())
        XCTAssertTrue(fetched.isEmpty)
    }

    @MainActor
    func testBloodworkRecordRoundTrips() throws {
        let ctx = try freshContext()
        let e = catalog("Ferritin")
        PersistenceService.insertBloodwork(
            BloodworkRecord(name: e.name, category: e.category.rawValue, value: 45, unit: e.unit,
                            normalLow: e.normalLow, normalHigh: e.normalHigh,
                            optimalLow: e.optimalLow, optimalHigh: e.optimalHigh), context: ctx)
        let fetched = try ctx.fetch(FetchDescriptor<BloodworkRecord>())
        XCTAssertEqual(fetched.count, 1)
        XCTAssertEqual(fetched.first?.value, 45)
        XCTAssertEqual(fetched.first?.name, "Ferritin")
    }

    // MARK: - Demo vs real never mix

    func testDemoAccountKeepsSeanStackAndLabs() {
        let app = AppState(); app.completeAuth(demo: true)
        XCTAssertEqual(app.nutrition.supplements.count, MockData.supplements.count)
        XCTAssertEqual(app.nutrition.bloodwork.count, MockData.bloodwork.count)
        XCTAssertFalse(app.nutrition.deficiencies.isEmpty)
        XCTAssertFalse(app.injuries.active.isEmpty)                 // demo knee present
        XCTAssertEqual(app.injuries.risk.percent, MockData.injuryRisk.percent)
    }

    func testRealAccountStartsCleanAcrossHealthData() {
        let app = AppState(); app.completeAuth(demo: false)
        XCTAssertTrue(app.nutrition.supplements.isEmpty)
        XCTAssertTrue(app.nutrition.bloodwork.isEmpty)
        XCTAssertTrue(app.nutrition.deficiencies.isEmpty)
        XCTAssertTrue(app.injuries.active.isEmpty)                  // demo knee cleared
        XCTAssertEqual(app.injuries.risk.percent, 0)                // clean risk, not Sean's 22
        XCTAssertEqual(app.injuries.risk.band, "Low")
    }

    // MARK: - AppState management (real account, persisted)

    @MainActor
    func testAddToggleRemoveSupplementForRealAccount() {
        clearSharedHealthStore()
        let app = AppState(); app.completeAuth(demo: false)
        let ctx = PersistenceService.context

        app.addSupplement(name: "Creatine", dose: "5 g", timing: "Daily", benefit: "Strength", context: ctx)
        XCTAssertEqual(app.nutrition.supplements.count, 1)
        XCTAssertEqual(app.nutrition.supplements.first?.name, "Creatine")
        XCTAssertFalse(app.nutrition.supplements.first?.loggedToday ?? true)

        let s = app.nutrition.supplements[0]
        app.toggleSupplement(s, context: ctx)
        XCTAssertTrue(app.nutrition.supplements.first?.loggedToday ?? false)
        XCTAssertEqual(app.nutrition.supplements.first?.streak, 1)
        // Adherence persisted → reload from store reflects the streak.
        XCTAssertEqual(PersistenceService.loadSupplements().first?.streak, 1)

        app.removeSupplement(app.nutrition.supplements[0], context: ctx)
        XCTAssertTrue(app.nutrition.supplements.isEmpty)
        XCTAssertTrue(PersistenceService.loadSupplements().isEmpty)
    }

    @MainActor
    func testAddBloodworkDerivesDeficiencyForRealAccount() {
        clearSharedHealthStore()
        let app = AppState(); app.completeAuth(demo: false)
        app.addBloodwork(catalog("Vitamin D (25-OH)"), value: 24, context: PersistenceService.context)

        XCTAssertEqual(app.nutrition.bloodwork.count, 1)
        XCTAssertEqual(app.nutrition.bloodwork.first?.value, 24)
        // Below normal → a high-severity deficiency is derived from the real lab.
        XCTAssertEqual(app.nutrition.deficiencies.count, 1)
        XCTAssertEqual(app.nutrition.deficiencies.first?.severity, .high)
    }

    @MainActor
    func testNonPositiveBloodworkIsIgnored() {
        clearSharedHealthStore()
        let app = AppState(); app.completeAuth(demo: false)
        app.addBloodwork(catalog("Vitamin D (25-OH)"), value: 0, context: PersistenceService.context)
        XCTAssertTrue(app.nutrition.bloodwork.isEmpty)
    }

    @MainActor
    func testDemoSupplementAddStaysInMemoryAndDoesNotPersist() {
        clearSharedHealthStore()
        let app = AppState(); app.completeAuth(demo: true)
        let base = app.nutrition.supplements.count
        app.addSupplement(name: "Zinc", dose: "15 mg", timing: "Evening", benefit: "Recovery",
                          context: PersistenceService.context)
        XCTAssertEqual(app.nutrition.supplements.count, base + 1)
        XCTAssertEqual(app.nutrition.supplements.last?.name, "Zinc")
        // Demo never writes to the real store.
        XCTAssertTrue(PersistenceService.loadSupplements().isEmpty)
    }

    // MARK: - AI coach only uses the current user's data

    func testRealCoachContextHasNoDemoClinicalData() {
        let app = AppState(); app.completeAuth(demo: false)
        let c = app.coachContext
        XCTAssertFalse(c.isDemo)
        XCTAssertTrue(c.injuryLine.isEmpty)
        XCTAssertTrue(c.deficiencyLine.isEmpty)
        XCTAssertTrue(c.bloodworkLine.isEmpty)
        XCTAssertTrue(c.rehabLine.isEmpty)
        XCTAssertTrue(c.forecastLine.isEmpty)
        XCTAssertEqual(c.injuryName, "")
    }

    func testRealSystemPromptOmitsSeansMockClinicalData() {
        let app = AppState(); app.completeAuth(demo: false)
        let p = AIService.systemPrompt(context: app.coachContext, checkInNote: nil)
        XCTAssertFalse(p.contains("Patellar"))          // Sean's knee
        XCTAssertFalse(p.contains("Bloodwork Vitamin D"))
        XCTAssertFalse(p.contains("REHAB"))             // no active injury → no rehab block
        XCTAssertFalse(p.contains("FORECAST"))          // no forecast engine for real users
        XCTAssertTrue(p.contains("not medical advice")) // safety survives
    }

    func testDemoSystemPromptStillCarriesSeansData() {
        let p = AIService.systemPrompt(context: .demo, checkInNote: nil)
        XCTAssertTrue(p.lowercased().contains("patellar") || p.lowercased().contains("knee"))
        XCTAssertTrue(p.contains("Vitamin D"))
        XCTAssertTrue(p.contains("REHAB"))
    }

    func testOfflineReplyForRealAccountIsHonestNotFabricated() {
        let app = AppState(); app.completeAuth(demo: false)
        let c = app.coachContext

        let knee = AIService.offlineReply(to: "How do I fix my knee pain?", context: c)
        XCTAssertFalse(knee.text.contains("Spanish squat"))     // Sean's demo rehab
        XCTAssertTrue(knee.text.lowercased().contains("no active injury"))

        let supp = AIService.offlineReply(to: "What supplements am I missing?", context: c)
        XCTAssertFalse(supp.text.contains("Omega-3"))           // Sean's fabricated gap
        XCTAssertTrue(supp.text.lowercased().contains("bloodwork"))

        let bench = AIService.offlineReply(to: "How do I hit 225 bench?", context: c)
        XCTAssertFalse(bench.text.contains("Nov 6"))            // Sean's fabricated forecast date
    }

    func testOfflineReplyForDemoKeepsRichCannedScript() {
        let demo = CoachContext.demo
        let knee = AIService.offlineReply(to: "How do I fix my knee pain?", context: demo)
        XCTAssertTrue(knee.text.contains("Spanish squat"))
    }

    func testRealForgeInsightsHaveNoInjuryChainWhenHealthy() {
        // The whole intelligence layer (not just the coach) drops the demo knee.
        let app = AppState(); app.completeAuth(demo: false)
        let mentionsKnee = app.forgeInsights.contains { $0.chain.lowercased().contains("knee") }
        XCTAssertFalse(mentionsKnee)
    }
}
