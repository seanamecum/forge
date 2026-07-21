import XCTest
import SwiftData
@testable import Forge

/// The pure sync core: collect-pending, mark-pushed, and LWW apply — all exercised
/// against isolated in-memory stores, no networking.
final class SyncEngineTests: XCTestCase {

    @MainActor private func store() throws -> ModelContext {
        let c = try ModelContainer(
            for: WeightRecord.self, SupplementRecord.self, GoalRecord.self,
            NutritionEntryRecord.self, SyncTombstone.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        return ModelContext(c)
    }

    // MARK: collect / mark

    @MainActor
    func testCollectPendingAssignsIDsAndSkipsClean() throws {
        let ctx = try store()
        ctx.insert(WeightRecord(date: .now, weightLb: 180))   // pending by default
        try ctx.save()

        let rows = SyncEngine.collectPending(context: ctx)
        XCTAssertEqual(rows.count, 1)
        XCTAssertEqual(rows.first?.kind, "weight")
        XCTAssertFalse(rows.first?.recordID.isEmpty ?? true)   // a syncID was assigned
        XCTAssertFalse(rows.first?.deleted ?? true)

        // The record now carries the assigned id; still pending until acknowledged.
        let rec = try ctx.fetch(FetchDescriptor<WeightRecord>()).first
        XCTAssertEqual(rec?.syncID, rows.first?.recordID)
        XCTAssertTrue(rec?.syncPending ?? false)

        // After marking pushed it's no longer collected.
        SyncEngine.markPushed(rows, context: ctx)
        XCTAssertFalse(try ctx.fetch(FetchDescriptor<WeightRecord>()).first?.syncPending ?? true)
        XCTAssertTrue(SyncEngine.collectPending(context: ctx).isEmpty)
    }

    // MARK: apply — create / LWW / ignore-older

    @MainActor
    func testApplyCreatesThenLWWUpdatesAndIgnoresOlder() throws {
        let ctx = try store()
        let id = "w-1"
        let t1 = Date(timeIntervalSince1970: 1_000)
        let t2 = Date(timeIntervalSince1970: 2_000)

        func row(_ lb: Double, _ at: Date) -> SyncRow {
            SyncRow(userID: "u", kind: "weight", recordID: id,
                    payload: #"{"date":"1970-01-01T00:00:00Z","weightLb":\#(lb)}"#,
                    updatedAt: at, deleted: false, syncedAt: at)
        }

        // Create.
        SyncEngine.applyPulled([row(180, t1)], context: ctx)
        var all = try ctx.fetch(FetchDescriptor<WeightRecord>())
        XCTAssertEqual(all.count, 1)
        XCTAssertEqual(all.first?.weightLb, 180)
        XCTAssertFalse(all.first?.syncPending ?? true)   // pulled rows aren't dirty

        // Newer wins.
        SyncEngine.applyPulled([row(200, t2)], context: ctx)
        all = try ctx.fetch(FetchDescriptor<WeightRecord>())
        XCTAssertEqual(all.count, 1)                      // updated in place, not duplicated
        XCTAssertEqual(all.first?.weightLb, 200)

        // Older is ignored (keep the newer local).
        SyncEngine.applyPulled([row(150, t1)], context: ctx)
        XCTAssertEqual(try ctx.fetch(FetchDescriptor<WeightRecord>()).first?.weightLb, 200)
    }

    @MainActor
    func testTombstoneDeletesUnlessLocalIsNewer() throws {
        let ctx = try store()
        let id = "w-9"
        let t1 = Date(timeIntervalSince1970: 1_000)
        let t2 = Date(timeIntervalSince1970: 2_000)
        let payload = #"{"date":"1970-01-01T00:00:00Z","weightLb":180}"#

        SyncEngine.applyPulled([SyncRow(userID: "u", kind: "weight", recordID: id,
            payload: payload, updatedAt: t2, deleted: false, syncedAt: t2)], context: ctx)
        XCTAssertEqual(try ctx.fetch(FetchDescriptor<WeightRecord>()).count, 1)

        // An OLDER tombstone must not delete a newer local edit.
        SyncEngine.applyPulled([SyncRow(userID: "u", kind: "weight", recordID: id,
            payload: "{}", updatedAt: t1, deleted: true, syncedAt: t1)], context: ctx)
        XCTAssertEqual(try ctx.fetch(FetchDescriptor<WeightRecord>()).count, 1, "stale delete ignored")

        // A newer tombstone deletes.
        let t3 = Date(timeIntervalSince1970: 3_000)
        SyncEngine.applyPulled([SyncRow(userID: "u", kind: "weight", recordID: id,
            payload: "{}", updatedAt: t3, deleted: true, syncedAt: t3)], context: ctx)
        XCTAssertTrue(try ctx.fetch(FetchDescriptor<WeightRecord>()).isEmpty)
    }

    @MainActor
    func testLocalDeletionProducesPushableTombstone() throws {
        let ctx = try store()
        let r = WeightRecord(date: .now, weightLb: 175)
        r.syncID = "w-tomb"; r.syncPending = false
        ctx.insert(r); try ctx.save()

        SyncEngine.recordDeletion(kind: "weight", syncID: "w-tomb", context: ctx)
        ctx.delete(r); try ctx.save()

        let rows = SyncEngine.collectPending(context: ctx)
        XCTAssertEqual(rows.count, 1)
        XCTAssertTrue(rows.first?.deleted ?? false)
        XCTAssertEqual(rows.first?.recordID, "w-tomb")

        // Acknowledged → tombstone cleared, nothing left to push.
        SyncEngine.markPushed(rows, context: ctx)
        XCTAssertTrue(SyncEngine.collectPending(context: ctx).isEmpty)
        XCTAssertTrue(try ctx.fetch(FetchDescriptor<SyncTombstone>()).isEmpty)
    }

    @MainActor
    func testNeverSyncedDeletionSkipsTombstone() throws {
        let ctx = try store()
        // Empty syncID → never reached the server → nothing to tombstone.
        SyncEngine.recordDeletion(kind: "weight", syncID: "", context: ctx)
        XCTAssertTrue(try ctx.fetch(FetchDescriptor<SyncTombstone>()).isEmpty)
    }

    // MARK: helpers

    func testJWTUserIDDecode() {
        // header.{"sub":"user-123"}.sig  (payload is base64url of the JSON)
        let payload = Data(#"{"sub":"user-123","role":"authenticated"}"#.utf8)
            .base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
        XCTAssertEqual(SyncAuth.userID(fromJWT: "h.\(payload).s"), "user-123")
        XCTAssertNil(SyncAuth.userID(fromJWT: "not-a-jwt"))
        XCTAssertNil(SyncAuth.userID(fromJWT: ""))
    }

    func testDateCoderRoundTrip() throws {
        let row = SyncRow(userID: "u", kind: "weight", recordID: "1", payload: "{}",
                          updatedAt: Date(timeIntervalSince1970: 1_700_000_000.5),
                          deleted: false, syncedAt: nil)
        let data = try SyncCoder.encoder.encode(row)
        let back = try SyncCoder.decoder.decode(SyncRow.self, from: data)
        XCTAssertEqual(back.updatedAt.timeIntervalSince1970, 1_700_000_000.5, accuracy: 0.01)
    }
}
