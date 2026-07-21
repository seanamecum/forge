import XCTest
import SwiftData
@testable import Forge

/// The local migration path for cloud sync: the new `sync*` columns default so
/// that (a) every fresh insert is dirty and will upload, and (b) an existing store
/// migrates cleanly with the tombstone model added to the schema.
final class SyncMigrationTests: XCTestCase {

    @MainActor
    func testNewRecordsDefaultToPendingWithNoID() throws {
        let c = try ModelContainer(for: WeightRecord.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let ctx = ModelContext(c)
        let r = WeightRecord(date: .now, weightLb: 180)
        ctx.insert(r); try ctx.save()

        // A record created the ordinary way is automatically queued for upload —
        // this is what makes an *existing* pre-sync store back up on first sign-in.
        XCTAssertTrue(r.syncPending)
        XCTAssertEqual(r.syncID, "")
        XCTAssertEqual(WeightRecord.syncKind, "weight")
    }

    @MainActor
    func testFullSchemaIncludingTombstoneCoexists() throws {
        // Mirrors PersistenceService's schema — proves the added SyncTombstone model
        // and the sync columns don't break container creation or basic writes.
        let c = try ModelContainer(
            for: UserRecord.self, GoalRecord.self, WorkoutRecord.self,
            NutritionEntryRecord.self, RecoveryRecord.self, SleepRecord.self,
            ScoreRecord.self, CheckInRecord.self, WeightRecord.self,
            SupplementRecord.self, BloodworkRecord.self, SyncTombstone.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let ctx = ModelContext(c)

        ctx.insert(SyncTombstone(kind: "weight", recordID: "abc"))
        ctx.insert(BloodworkRecord(name: "Ferritin", category: "vitamins", value: 40, unit: "ng/mL",
                                   normalLow: 30, normalHigh: 400, optimalLow: 50, optimalHigh: 200))
        try ctx.save()

        XCTAssertEqual(try ctx.fetch(FetchDescriptor<SyncTombstone>()).count, 1)
        XCTAssertEqual(try ctx.fetch(FetchDescriptor<BloodworkRecord>()).count, 1)
    }

    @MainActor
    func testEverySyncKindIsRegisteredAndUnique() {
        let kinds = SyncRegistry.handlers.map(\.kind)
        XCTAssertEqual(kinds.count, Set(kinds).count, "sync kinds must be unique")
        // The document store covers the durable, user-generated record types.
        for expected in ["profile", "goal", "workout", "nutrition", "weight", "supplement", "bloodwork", "checkin"] {
            XCTAssertTrue(kinds.contains(expected), "missing sync handler for \(expected)")
        }
        XCTAssertNotNil(SyncRegistry.byKind["weight"])
    }

    @MainActor
    func testPayloadRoundTripsThroughInstantiate() throws {
        let original = SupplementRecord(name: "Magnesium", dose: "400 mg", timing: "Before bed",
                                        benefit: "Sleep", streak: 4)
        let payload = try original.syncPayload()
        let restored = try SupplementRecord.instantiate(payload: payload)
        XCTAssertEqual(restored.name, "Magnesium")
        XCTAssertEqual(restored.dose, "400 mg")
        XCTAssertEqual(restored.streak, 4)
    }
}
