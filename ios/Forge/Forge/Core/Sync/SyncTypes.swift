import Foundation
import SwiftData

// MARK: - Wire model

/// One row of the generic document store (`public.sync_records`). This is the
/// exact JSON shape exchanged with PostgREST — the client is authoritative for
/// `updatedAt` (the last-write-wins key) and `deleted`; the server owns
/// `syncedAt` (the pull cursor).
struct SyncRow: Codable, Equatable {
    var userID: String?      // sent on push; echoed on pull
    var kind: String
    var recordID: String
    var payload: String      // JSON text of the record's fields ("{}" for a tombstone)
    var updatedAt: Date
    var deleted: Bool
    var syncedAt: Date?      // server-assigned; nil when we build a row to push

    enum CodingKeys: String, CodingKey {
        case userID = "user_id"
        case kind
        case recordID = "record_id"
        case payload
        case updatedAt = "updated_at"
        case deleted
        case syncedAt = "synced_at"
    }
}

enum SyncCoder {
    /// PostgREST emits/accepts ISO-8601 timestamps; fractional seconds appear on
    /// `timestamptz`, so accept both with and without them.
    static let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .custom { date, enc in
            var c = enc.singleValueContainer()
            try c.encode(iso.string(from: date))
        }
        return e
    }()

    static let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .custom { dec in
            let s = try dec.singleValueContainer().decode(String.self)
            if let date = iso.date(from: s) ?? isoPlain.date(from: s) { return date }
            throw DecodingError.dataCorrupted(.init(codingPath: dec.codingPath,
                debugDescription: "Unrecognized ISO-8601 date: \(s)"))
        }
        return d
    }()

    private static let iso: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()
    private static let isoPlain: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        return f
    }()
}

// MARK: - Status (drives the offline/retry UI)

enum SyncStatus: Equatable {
    case idle            // not signed into a real account → nothing to sync
    case syncing
    case synced(Date)
    case offline         // last attempt couldn't reach the server; will retry
    case error(String)   // a non-network failure worth surfacing

    var isBusy: Bool { self == .syncing }
}

// MARK: - Local tombstone

/// Records a local deletion so the removal propagates to other devices. We keep
/// hard deletes on the domain records (so every loader stays a simple fetch) and
/// track the deletion here; it pushes as a `deleted = true` row and is cleared
/// once acknowledged.
@Model
final class SyncTombstone {
    var kind: String
    var recordID: String
    var updatedAt: Date
    var pending: Bool

    init(kind: String, recordID: String, updatedAt: Date = .now, pending: Bool = true) {
        self.kind = kind
        self.recordID = recordID
        self.updatedAt = updatedAt
        self.pending = pending
    }
}

// MARK: - Auth helpers

enum SyncAuth {
    /// The user's id (the JWT `sub` claim), needed for the `user_id` column and
    /// the RLS `auth.uid() = user_id` check. Decoded locally from the access
    /// token — no network call. Returns nil for a malformed/absent token.
    static func userID(fromJWT token: String) -> String? {
        let parts = token.split(separator: ".")
        guard parts.count == 3 else { return nil }
        guard let data = base64URLDecode(String(parts[1])),
              let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let sub = obj["sub"] as? String, !sub.isEmpty else { return nil }
        return sub
    }

    private static func base64URLDecode(_ s: String) -> Data? {
        var b = s.replacingOccurrences(of: "-", with: "+").replacingOccurrences(of: "_", with: "/")
        while b.count % 4 != 0 { b.append("=") }
        return Data(base64Encoded: b)
    }
}
