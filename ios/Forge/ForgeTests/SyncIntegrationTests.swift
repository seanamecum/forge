import XCTest
import SwiftData
@testable import Forge

/// A fake Supabase for the document store. Faithfully models the server's
/// last-write-wins semantics (an older `updatedAt` never overwrites a newer row)
/// and hands out a monotonic `syncedAt` as the pull cursor, so device↔device
/// behaviour here matches production.
@MainActor
final class FakeSyncServer {
    private(set) var rows: [String: SyncRow] = [:]
    private var clock: Double = 0
    var online = true
    var pushCount = 0

    private func key(_ r: SyncRow) -> String { "\(r.kind)|\(r.recordID)" }

    func push(_ pushed: [SyncRow]) throws {
        guard online else { throw SyncError.offline }
        pushCount += 1
        for var r in pushed {
            if let existing = rows[key(r)], r.updatedAt < existing.updatedAt {
                continue                         // stale write loses (server-side LWW)
            }
            clock += 1
            r.userID = "u"
            r.syncedAt = Date(timeIntervalSince1970: clock)
            rows[key(r)] = r
        }
    }

    func pull(since cursor: Date?) throws -> [SyncRow] {
        guard online else { throw SyncError.offline }
        let sorted = rows.values.sorted { ($0.syncedAt ?? .distantPast) < ($1.syncedAt ?? .distantPast) }
        guard let cursor else { return sorted }
        return sorted.filter { ($0.syncedAt ?? .distantPast) > cursor }
    }
}

struct FakeTransport: SyncTransport {
    let server: FakeSyncServer
    func push(_ rows: [SyncRow]) async throws { try await server.push(rows) }
    func pull(since cursor: Date?) async throws -> [SyncRow] { try await server.pull(since: cursor) }
}

final class InMemoryCursorStore: SyncCursorStore {
    private var store: [String: Date] = [:]
    func cursor(for userID: String) -> Date? { store[userID] }
    func setCursor(_ date: Date?, for userID: String) { store[userID] = date }
}

/// Two devices, one fake cloud — the real-world scenarios the milestone promises:
/// cross-device sync, reinstall restore, conflict resolution, and offline queueing.
final class SyncIntegrationTests: XCTestCase {

    @MainActor private func newDevice(_ server: FakeSyncServer) throws -> (ModelContext, SyncService) {
        let container = try ModelContainer(
            for: WeightRecord.self, SupplementRecord.self, GoalRecord.self,
            NutritionEntryRecord.self, CheckInRecord.self, SyncTombstone.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let ctx = ModelContext(container)
        let svc = SyncService()
        svc.contextOverride = ctx
        svc.transportOverride = FakeTransport(server: server)
        svc.cursorStore = InMemoryCursorStore()
        svc.credentials = { SyncCredentials(userID: "u", token: "t") }
        return (ctx, svc)
    }

    @MainActor private func weights(_ ctx: ModelContext) -> [WeightRecord] {
        (try? ctx.fetch(FetchDescriptor<WeightRecord>())) ?? []
    }

    // MARK: cross-device

    @MainActor
    func testChangeOnOneDeviceReachesTheOther() async throws {
        let server = FakeSyncServer()
        let (ctxA, a) = try newDevice(server)
        let (ctxB, b) = try newDevice(server)

        ctxA.insert(WeightRecord(date: .now, weightLb: 182)); try ctxA.save()
        await a.sync()

        XCTAssertTrue(weights(ctxB).isEmpty)   // B hasn't synced yet
        await b.sync()

        XCTAssertEqual(weights(ctxB).count, 1)
        XCTAssertEqual(weights(ctxB).first?.weightLb, 182)
        if case .synced = b.status {} else { XCTFail("B should report synced, got \(b.status)") }
    }

    // MARK: reinstall

    @MainActor
    func testReinstallRestoresFullHistory() async throws {
        let server = FakeSyncServer()
        let (ctxA, a) = try newDevice(server)
        for lb in [180.0, 181, 179] { ctxA.insert(WeightRecord(date: .now, weightLb: lb)) }
        ctxA.insert(SupplementRecord(name: "Creatine", dose: "5 g", timing: "Daily", benefit: "Strength"))
        try ctxA.save()
        await a.sync()

        // A fresh install: brand-new empty store, fresh cursor, same account.
        let (ctxC, c) = try newDevice(server)
        XCTAssertTrue(weights(ctxC).isEmpty)
        await c.sync()

        XCTAssertEqual(weights(ctxC).count, 3)
        XCTAssertEqual((try ctxC.fetch(FetchDescriptor<SupplementRecord>())).first?.name, "Creatine")
    }

    // MARK: conflict — last write wins, regardless of push order

    @MainActor
    func testConflictResolvesToLatestEditEvenIfPushedFirst() async throws {
        let server = FakeSyncServer()
        let (ctxA, a) = try newDevice(server)
        let (ctxB, b) = try newDevice(server)

        // Seed one record on both devices.
        ctxA.insert(WeightRecord(date: .now, weightLb: 180)); try ctxA.save()
        await a.sync(); await b.sync()
        XCTAssertEqual(weights(ctxB).first?.weightLb, 180)

        // A makes the NEWER edit; B makes an older one. (Both must be newer than the
        // seed's own timestamp, or the server rightly rejects them as stale.)
        let recA = weights(ctxA).first!
        recA.weightLb = 205
        recA.syncUpdatedAt = .now.addingTimeInterval(100)
        recA.syncPending = true
        try ctxA.save()

        let recB = weights(ctxB).first!
        recB.weightLb = 190
        recB.syncUpdatedAt = .now.addingTimeInterval(50)          // older than A's edit
        recB.syncPending = true
        try ctxB.save()

        // A syncs first, then B pushes its stale edit and pulls.
        await a.sync()
        await b.sync()
        // And a final A pull to converge.
        await a.sync()

        XCTAssertEqual(weights(ctxA).first?.weightLb, 205)
        XCTAssertEqual(weights(ctxB).first?.weightLb, 205, "the newer edit wins on both devices")
    }

    // MARK: delete propagation

    @MainActor
    func testDeletePropagates() async throws {
        let server = FakeSyncServer()
        let (ctxA, a) = try newDevice(server)
        let (ctxB, b) = try newDevice(server)

        ctxA.insert(WeightRecord(date: .now, weightLb: 200)); try ctxA.save()
        await a.sync(); await b.sync()
        XCTAssertEqual(weights(ctxB).count, 1)

        // Delete on A: tombstone + hard delete, then sync.
        let rec = weights(ctxA).first!
        SyncEngine.recordDeletion(kind: "weight", syncID: rec.syncID, context: ctxA)
        ctxA.delete(rec); try ctxA.save()
        await a.sync()

        await b.sync()
        XCTAssertTrue(weights(ctxB).isEmpty, "the deletion reached device B")
    }

    // MARK: offline-first

    @MainActor
    func testOfflineQueuesThenSyncsWhenBackOnline() async throws {
        let server = FakeSyncServer()
        server.online = false
        let (ctxA, a) = try newDevice(server)

        ctxA.insert(WeightRecord(date: .now, weightLb: 178)); try ctxA.save()
        await a.sync()

        XCTAssertEqual(a.status, .offline)
        // The change is still queued locally (dirty), nothing lost.
        XCTAssertTrue(weights(ctxA).first?.syncPending ?? false)
        XCTAssertEqual(server.rows.count, 0)

        // Back online → it flushes.
        server.online = true
        await a.sync()
        XCTAssertFalse(weights(ctxA).first?.syncPending ?? true)
        XCTAssertEqual(server.rows.count, 1)
        if case .synced = a.status {} else { XCTFail("expected synced, got \(a.status)") }
    }

    @MainActor
    func testDemoOrSignedOutDoesNotSync() async throws {
        let server = FakeSyncServer()
        let (ctxA, a) = try newDevice(server)
        a.credentials = { nil }                 // demo / signed out
        ctxA.insert(WeightRecord(date: .now, weightLb: 180)); try ctxA.save()
        await a.sync()
        XCTAssertEqual(a.status, .idle)
        XCTAssertEqual(server.rows.count, 0)    // nothing left the device
    }
}
