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
    /// Test seams.
    var transportOverride: SyncTransport?
    var contextOverride: ModelContext?
    var cursorStore: SyncCursorStore = UserDefaultsCursorStore()

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
            // Push everything dirty, then mark it clean once accepted.
            let pending = SyncEngine.collectPending(context: ctx)
            try await transport.push(pending)
            SyncEngine.markPushed(pending, context: ctx)

            // Pull everything new since our cursor and merge (LWW).
            let cursor = cursorStore.cursor(for: creds.userID)
            let pulled = try await transport.pull(since: cursor)
            SyncEngine.applyPulled(pulled, context: ctx)
            if let newest = pulled.compactMap(\.syncedAt).max() {
                cursorStore.setCursor(newest, for: creds.userID)
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
