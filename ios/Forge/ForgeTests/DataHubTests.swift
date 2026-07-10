import XCTest
@testable import Forge

/// The unified data layer: source priority, duplicate handling, preferred
/// sources, missing-data fallback, coverage, and goal-based recommendations.
final class DataHubTests: XCTestCase {

    private func reading(_ kind: MetricKind, _ value: Double,
                         _ source: DataSource, age: Double = 0.5) -> MetricReading {
        MetricReading(kind: kind, value: value, unit: "", source: source, ageHours: age)
    }

    // MARK: - Conflict resolution

    func testSleepPrefersWhoopOverAppleWatchByDefault() {
        let readings = [
            reading(.sleep, 7.9, .appleWatch),
            reading(.sleep, 7.4, .whoop),
        ]
        let winner = DataHub.resolve(.sleep, readings: readings,
                                     connected: [.appleWatch, .whoop])
        XCTAssertEqual(winner?.source, .whoop)
        XCTAssertEqual(winner?.value, 7.4)
    }

    func testUserPreferredSourceOverridesDefaultPriority() {
        let readings = [
            reading(.sleep, 7.9, .appleWatch),
            reading(.sleep, 7.4, .whoop),
        ]
        let winner = DataHub.resolve(.sleep, readings: readings,
                                     connected: [.appleWatch, .whoop],
                                     preferred: .appleWatch)
        XCTAssertEqual(winner?.source, .appleWatch)
    }

    func testPreferredSourceWithoutDataFallsBackToPriority() {
        // User prefers Oura for sleep, but Oura has no reading today.
        let readings = [reading(.sleep, 7.9, .appleWatch)]
        let winner = DataHub.resolve(.sleep, readings: readings,
                                     connected: [.appleWatch, .oura],
                                     preferred: .oura)
        XCTAssertEqual(winner?.source, .appleWatch, "Missing preferred data must fall through, not go blank")
    }

    func testDisconnectedSourceReadingsAreIgnored() {
        let readings = [
            reading(.sleep, 7.4, .whoop),        // device unpaired
            reading(.sleep, 7.9, .appleWatch),
        ]
        let winner = DataHub.resolve(.sleep, readings: readings, connected: [.appleWatch])
        XCTAssertEqual(winner?.source, .appleWatch)
    }

    func testDuplicateReadingsFromOneSourceCollapseToFreshest() {
        let readings = [
            reading(.hrv, 55, .whoop, age: 20),   // yesterday
            reading(.hrv, 58, .whoop, age: 0.2),  // this morning
        ]
        let winner = DataHub.resolve(.hrv, readings: readings, connected: [.whoop])
        XCTAssertEqual(winner?.value, 58)
    }

    func testNoConnectedSourceMeansNoReading() {
        let readings = [reading(.bodyFat, 15.2, .smartScale)]
        XCTAssertNil(DataHub.resolve(.bodyFat, readings: readings, connected: [.appleWatch]))
    }

    // MARK: - Coverage & gaps

    func testCoverageWithoutScaleIsMissingBodyComposition() {
        let (_, missing) = DataHub.coverage(connected: [.appleWatch, .whoop])
        XCTAssertTrue(missing.contains(.bodyFat))
        XCTAssertTrue(missing.contains(.leanMass))
        XCTAssertFalse(missing.contains(.sleep))
        XCTAssertFalse(missing.contains(.recovery), "WHOOP covers recovery")
    }

    func testFillsGapIsHonestAboutOverlap() {
        // With Watch + WHOOP connected, a scale adds body comp…
        let gaps = DataHub.fillsGap(.smartScale, connected: [.appleWatch, .whoop])
        XCTAssertEqual(Set(gaps), Set([.weight, .bodyFat, .leanMass]))
        // …while Fitbit adds nothing new — and the hub must say so.
        XCTAssertTrue(DataHub.fillsGap(.fitbit, connected: [.appleWatch, .whoop]).isEmpty)
    }

    func testFullDemoStackCoversEverythingButTrainingLoadAndVO2ViaGarmin() {
        // Demo stack: Watch + WHOOP + scale — training load is the known gap.
        let (_, missing) = DataHub.coverage(connected: [.appleWatch, .whoop, .smartScale])
        XCTAssertEqual(missing, [.trainingLoad])
        XCTAssertTrue(DataHub.fillsGap(.garmin, connected: [.appleWatch, .whoop, .smartScale])
            .contains(.trainingLoad))
    }

    // MARK: - Quality bands

    func testQualityBands() {
        XCTAssertEqual(DataHub.quality(ageHours: 0.2), .excellent)
        XCTAssertEqual(DataHub.quality(ageHours: 6), .good)
        XCTAssertEqual(DataHub.quality(ageHours: 40), .stale)
        XCTAssertEqual(DataHub.quality(ageHours: nil), .missing)
    }

    // MARK: - Recommended stacks

    func testRecommendedStacksMatchGoals() {
        XCTAssertEqual(DataHub.recommendedStack(for: .endurance).first, .garmin)
        XCTAssertTrue(DataHub.recommendedStack(for: .injuryRecovery).contains(.whoop))
        XCTAssertTrue(DataHub.recommendedStack(for: .loseFat).contains(.smartScale))
        XCTAssertTrue(DataHub.recommendedStack(for: .athletic).contains(.appleWatch))
    }

    // MARK: - Cross-device narrative

    func testNarrativeNamesTheMeasuringDevices() {
        let text = DataHub.narrative(connected: [.appleWatch, .whoop, .garmin],
                                     hrvDeltaPct: -6, sleepHours: 6.8,
                                     loadRatio: 1.3, volumeAdjustPct: -20)
        XCTAssertTrue(text.contains("WHOOP HRV dropped 6%"))
        XCTAssertTrue(text.contains("Garmin training load"))
        XCTAssertTrue(text.contains("sleep was short"))
        XCTAssertTrue(text.contains("reduced 20%"))
    }

    func testNarrativeIsCalmWhenSignalsAreSteady() {
        let text = DataHub.narrative(connected: [.appleWatch],
                                     hrvDeltaPct: 0, sleepHours: 8.2,
                                     loadRatio: 1.0, volumeAdjustPct: 0)
        XCTAssertTrue(text.contains("steady"))
    }

    // MARK: - Service state (preferred sources + contenders)

    func testContendersOnlyIncludeConnectedSources() {
        let recovery = RecoveryService()
        // Demo stack: Watch + WHOOP + scale connected; Oura is not.
        let sleepContenders = recovery.contenders(for: .sleep)
        XCTAssertTrue(sleepContenders.contains(.whoop))
        XCTAssertTrue(sleepContenders.contains(.appleWatch))
        XCTAssertFalse(sleepContenders.contains(.oura))
    }

    func testPreferredSourceRoundTripsAndFallsBackWhenDisconnected() {
        let recovery = RecoveryService()
        recovery.setPreferred(.appleWatch, for: .sleep)
        XCTAssertEqual(recovery.activeSource(for: .sleep), .appleWatch)

        // Preferring a disconnected device must not black-hole the metric.
        recovery.setPreferred(.oura, for: .sleep)
        XCTAssertEqual(recovery.activeSource(for: .sleep), .whoop,
                       "Disconnected preferred source falls back to default priority")

        recovery.setPreferred(nil, for: .sleep)  // cleanup persisted state
        XCTAssertEqual(recovery.activeSource(for: .sleep), .whoop)
    }

    func testCoachContextCarriesEcosystem() {
        let app = AppState()
        let ctx = app.coachContext
        XCTAssertTrue(ctx.dataSources.contains("WHOOP"))
        XCTAssertTrue(ctx.dataSources.contains("Apple Watch"))
        XCTAssertFalse(ctx.deviceNarrative.isEmpty)
        let prompt = AIService.systemPrompt(context: ctx, checkInNote: nil)
        XCTAssertTrue(prompt.contains("DATA SOURCES"))
        XCTAssertTrue(prompt.contains("Cross-device read"))
    }
}
