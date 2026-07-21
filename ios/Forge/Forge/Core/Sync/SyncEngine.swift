import Foundation
import SwiftData

/// The pure orchestration over the registry: gather everything dirty into push
/// rows, apply pulled rows with last-write-wins, and clear dirty flags once the
/// server has acknowledged them. No networking here — that's `SyncTransport` — so
/// this whole file is exercised hermetically in tests.
enum SyncEngine {

    /// All locally-pending changes as rows to push: dirty domain records (from the
    /// registry) plus deletion tombstones. Assigns a stable `syncID` to any record
    /// that doesn't have one yet.
    static func collectPending(context: ModelContext) -> [SyncRow] {
        var rows: [SyncRow] = []
        for handler in SyncRegistry.handlers { rows += handler.collectPending(context) }
        rows += pendingTombstones(context)
        return rows
    }

    /// After a successful push, clear the dirty flags for exactly the rows the
    /// server accepted (records → clear `syncPending`; tombstones → delete them).
    static func markPushed(_ rows: [SyncRow], context: ModelContext) {
        let live = rows.filter { !$0.deleted }
        for (kind, kindRows) in Dictionary(grouping: live, by: \.kind) {
            SyncRegistry.byKind[kind]?.markSynced(context, Set(kindRows.map(\.recordID)))
        }
        let deletedKeys = Set(rows.filter(\.deleted).map { TombstoneKey(kind: $0.kind, recordID: $0.recordID) })
        clearTombstones(deletedKeys, context: context)
    }

    /// Apply a batch pulled from the server. Each row resolves independently via
    /// LWW inside its handler, so order within the batch doesn't affect the result.
    static func applyPulled(_ rows: [SyncRow], context: ModelContext) {
        for row in rows {
            SyncRegistry.byKind[row.kind]?.apply(row, context)
        }
    }

    // MARK: - Tombstones

    private struct TombstoneKey: Hashable { let kind: String; let recordID: String }

    private static func pendingTombstones(_ ctx: ModelContext) -> [SyncRow] {
        let all = (try? ctx.fetch(FetchDescriptor<SyncTombstone>())) ?? []
        return all.filter(\.pending).map {
            SyncRow(userID: nil, kind: $0.kind, recordID: $0.recordID, payload: "{}",
                    updatedAt: $0.updatedAt, deleted: true, syncedAt: nil)
        }
    }

    private static func clearTombstones(_ keys: Set<TombstoneKey>, context ctx: ModelContext) {
        guard !keys.isEmpty else { return }
        let all = (try? ctx.fetch(FetchDescriptor<SyncTombstone>())) ?? []
        var changed = false
        for t in all where keys.contains(TombstoneKey(kind: t.kind, recordID: t.recordID)) {
            ctx.delete(t); changed = true      // acknowledged → no need to keep it
        }
        if changed { try? ctx.save() }
    }

    /// Record a local deletion so it propagates. Call this *before* the domain
    /// record is removed (or right after — only its `syncID` is needed).
    static func recordDeletion(kind: String, syncID: String, context ctx: ModelContext) {
        guard !syncID.isEmpty else { return }   // never-synced record: nothing remote to delete
        ctx.insert(SyncTombstone(kind: kind, recordID: syncID))
        try? ctx.save()
    }
}

/// Mark an existing persisted record as edited locally, so the next sync pushes
/// it. New inserts are already `syncPending` by default — this is only for
/// in-place mutations (adherence streaks, goal progress, a re-scored day).
enum SyncStamp {
    static func touch(_ record: any Syncable) {
        record.syncUpdatedAt = .now
        record.syncPending = true
    }
}
