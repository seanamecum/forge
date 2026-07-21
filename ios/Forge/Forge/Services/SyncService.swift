import Foundation
import Observation
import SwiftData

struct SyncCredentials: Sendable { let userID: String; let token: String }

/// Where the pull cursor lives (last server timestamp we've seen), keyed per user
/// so switching accounts on a device never crosses streams.
protocol SyncCursorStore {
    func cursor(for userID: String) -> Date?
    func setCursor(_ date: Date?, for userID: String)
}

struct UserDefaultsCursorStore: SyncCursorStore {
    private func key(_ userID: String) -> String { "forge.sync.cursor.\(userID)" }
    func cursor(for userID: String) -> Date? {
        let t = UserDefaults.standard.double(forKey: key(userID))
        return t > 0 ? Date(timeIntervalSince1970: t) : nil
    }
    func setCursor(_ date: Date?, for userID: String) {
        UserDefaults.standard.set(date?.timeIntervalSince1970 ?? 0, forKey: key(userID))
    }
}

/// Offline-first cloud sync: SwiftData is the source of truth; this pushes local
/// changes and pulls remote ones on a best-effort basis. Never blocks the UI, and
/// a lost connection just parks the work (dirty flags persist) and retries with
/// backoff. Conflict resolution is last-write-wins inside `SyncEngine`.
///
/// Main-actor isolated (its `status` drives the UI), but the triggers are
/// `nonisolated` so the non-isolated parts of AppState can fire them freely.
@MainActor
@Observable
final class SyncService {
    var status: SyncStatus = .idle
    var lastSyncedAt: Date?

    /// Live account credentials, or nil when signed out / in demo mode / under test.
    /// Reads the session statically so it captures nothing (Sendable-safe).
    var credentials: @Sendable () -> SyncCredentials? = {
        guard !PersistenceService.isTestRun,
              let token = AuthService.currentToken(),
              let uid = SyncAuth.userID(fromJWT: token) else { return nil }
        return SyncCredentials(userID: uid, token: token)
    }
    /// Profile/settings singleton: AppState supplies the current snapshot JSON
    /// (nil in demo / signed out) and applies a pulled one. Dirty is detected by
    /// content diff, so no per-field mutation hooks are needed.
    var profileSnapshot: () -> String? = { nil }
    var applyProfileSnapshot: (String) -> Void = { _ in }

    /// Test seams.
    var transportOverride: SyncTransport?
    var contextOverride: ModelContext?
    var cursorStore: SyncCursorStore = UserDefaultsCursorStore()
    var profileStore: ProfileSyncStore = UserDefaultsProfileSyncStore()

    private static let profileKind = "profile"
    private static let profileRecordID = "singleton"

    nonisolated init() {}

    private var context: ModelContext { contextOverride ?? PersistenceService.context }

    private var isSyncing = false
    private var coalesceAnother = false
    private var debounceTask: Task<Void, Never>?
    private var retryTask: Task<Void, Never>?
    private var retryStep = 0
    private let retryLadder: [Double] = [5, 15, 45, 120, 300]   // seconds

    // MARK: - Triggers (callable from anywhere)

    /// Coalesce rapid local edits into a single sync a moment later.
    nonisolated func requestSync() {
        Task { @MainActor in self.scheduleDebounced() }
    }

    /// Sync immediately (sign-in, foreground, or a manual "Sync now").
    nonisolated func syncNow() {
        Task { @MainActor in await self.sync() }
    }

    /// Drop retry/queue state (called on sign-out).
    nonisolated func reset() {
        Task { @MainActor in
            self.debounceTask?.cancel(); self.retryTask?.cancel()
            self.retryStep = 0
            self.status = .idle
            self.lastSyncedAt = nil
        }
    }

    private func scheduleDebounced() {
        guard credentials() != nil else { return }
        debounceTask?.cancel()
        debounceTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(1.2))
            guard !Task.isCancelled else { return }
            await self?.sync()
        }
    }

    // MARK: - Core cycle

    /// Full push-then-pull cycle. Overlapping calls coalesce into one trailing run.
    func sync() async {
        guard let creds = credentials() else { status = .idle; return }
        if isSyncing { coalesceAnother = true; return }
        isSyncing = true
        defer { isSyncing = false }

        retryTask?.cancel()
        let transport = transportOverride
            ?? PostgRESTSyncTransport(userID: creds.userID, accessToken: creds.token)
        let ctx = context
        status = .syncing

        do {
            // Pull first, then push — so a device incorporates the account's current
            // state (esp. the profile singleton) before deciding what's still dirty.
            // This makes a fresh device adopt the account's profile instead of
            // clobbering it with an unchanged local baseline.
            let cursor = cursorStore.cursor(for: creds.userID)
            let pulled = try await transport.pull(since: cursor)
            SyncEngine.applyPulled(pulled.filter { $0.kind != Self.profileKind }, context: ctx)
            for row in pulled where row.kind == Self.profileKind {
                applyPulledProfile(row, for: creds.userID)
            }
            if let newest = pulled.compactMap(\.syncedAt).max() {
                cursorStore.setCursor(newest, for: creds.userID)
            }

            // Push everything still dirty (records + a genuinely-changed profile).
            var pending = SyncEngine.collectPending(context: ctx)
            let profileRow = pendingProfileRow(for: creds.userID)
            if let profileRow { pending.append(profileRow) }
            try await transport.push(pending)
            SyncEngine.markPushed(pending, context: ctx)
            if let profileRow {
                profileStore.setSnapshot(profileRow.payload, updatedAt: profileRow.updatedAt, for: creds.userID)
            }

            retryStep = 0
            lastSyncedAt = .now
            status = .synced(.now)
        } catch SyncError.offline {
            status = .offline
            scheduleRetry()
        } catch SyncError.unauthorized {
            // Token expired/invalid — a refresh + re-sign-in resolves it. Leave the
            // dirty flags in place so nothing is lost.
            status = .error("Sign in again to keep syncing.")
        } catch {
            status = .error("Sync will retry shortly.")
            scheduleRetry()
        }

        if coalesceAnother {
            coalesceAnother = false
            await sync()
        }
    }

    // MARK: - Profile / settings singleton

    /// A push row iff the current profile snapshot differs from what we last synced.
    private func pendingProfileRow(for userID: String) -> SyncRow? {
        guard let current = profileSnapshot() else { return nil }
        let last = profileStore.snapshot(for: userID)
        guard last?.json != current else { return nil }
        return SyncRow(userID: nil, kind: Self.profileKind, recordID: Self.profileRecordID,
                       payload: current, updatedAt: .now, deleted: false, syncedAt: nil)
    }

    /// Apply a pulled profile if it's newer than what we've reconciled (LWW). After
    /// applying, cache the *canonical* local snapshot so we don't immediately re-push.
    private func applyPulledProfile(_ row: SyncRow, for userID: String) {
        let local = profileStore.snapshot(for: userID)
        guard local == nil || row.updatedAt > local!.updatedAt else { return }
        applyProfileSnapshot(row.payload)
        let canonical = profileSnapshot() ?? row.payload
        profileStore.setSnapshot(canonical, updatedAt: row.updatedAt, for: userID)
    }

    // MARK: - Retry

    private func scheduleRetry() {
        retryTask?.cancel()
        let delay = retryLadder[min(retryStep, retryLadder.count - 1)]
        retryStep = min(retryStep + 1, retryLadder.count - 1)
        retryTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(delay))
            guard !Task.isCancelled else { return }
            await self?.sync()
        }
    }
}
