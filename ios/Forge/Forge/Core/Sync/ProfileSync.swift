import Foundation

/// The account's profile + app settings, synced as a single per-user row
/// (`kind = "profile"`, `record_id = "singleton"`). Unlike the append-only
/// records, this is one converging document, so it's handled specially by
/// `SyncService` rather than the generic registry.
struct ProfileSnapshot: Codable {
    var profile: UserProfile
    var morningDirectiveOn: Bool
    var smartNudgesOn: Bool
    var directiveHour: Int
    var directiveMinute: Int
}

enum ProfileSnapshotCoder {
    /// Deterministic (sorted-keys) so content-diff dirty detection is stable.
    static let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.outputFormatting = [.sortedKeys]
        return e
    }()
    static func encode(_ s: ProfileSnapshot) -> String? {
        (try? encoder.encode(s)).flatMap { String(data: $0, encoding: .utf8) }
    }
    static func decode(_ json: String) -> ProfileSnapshot? {
        json.data(using: .utf8).flatMap { try? JSONDecoder().decode(ProfileSnapshot.self, from: $0) }
    }
}

/// Remembers the last profile snapshot we reconciled with the server (its JSON +
/// logical timestamp), per user, so we can tell "changed since last sync" by
/// content and resolve pulls with last-write-wins.
protocol ProfileSyncStore {
    func snapshot(for userID: String) -> (json: String, updatedAt: Date)?
    func setSnapshot(_ json: String, updatedAt: Date, for userID: String)
    func clear(for userID: String)
}

struct UserDefaultsProfileSyncStore: ProfileSyncStore {
    private func jsonKey(_ u: String) -> String { "forge.sync.profile.json.\(u)" }
    private func atKey(_ u: String) -> String { "forge.sync.profile.at.\(u)" }

    func snapshot(for userID: String) -> (json: String, updatedAt: Date)? {
        let d = UserDefaults.standard
        guard let json = d.string(forKey: jsonKey(userID)) else { return nil }
        return (json, Date(timeIntervalSince1970: d.double(forKey: atKey(userID))))
    }
    func setSnapshot(_ json: String, updatedAt: Date, for userID: String) {
        let d = UserDefaults.standard
        d.set(json, forKey: jsonKey(userID))
        d.set(updatedAt.timeIntervalSince1970, forKey: atKey(userID))
    }
    func clear(for userID: String) {
        let d = UserDefaults.standard
        d.removeObject(forKey: jsonKey(userID))
        d.removeObject(forKey: atKey(userID))
    }
}
