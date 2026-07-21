import Foundation

/// The network boundary. Everything above this is pure and hermetically tested;
/// this is the one seam a fake replaces in tests.
protocol SyncTransport {
    /// Upsert rows into the document store (idempotent; server sets `synced_at`).
    func push(_ rows: [SyncRow]) async throws
    /// Rows the server received strictly after `cursor` (nil = full history),
    /// ordered oldest→newest so the caller can advance its cursor to the last one.
    func pull(since cursor: Date?) async throws -> [SyncRow]
}

enum SyncError: Error, Equatable {
    case offline          // couldn't reach the server (retryable)
    case unauthorized     // token rejected — re-auth needed
    case server(Int)      // other non-2xx
    case malformed
}

/// Live PostgREST implementation. Owner scoping is enforced by RLS server-side;
/// we still send `user_id` (required by the insert policy's WITH CHECK) and the
/// user's bearer token so `auth.uid()` matches.
struct PostgRESTSyncTransport: SyncTransport {
    let userID: String
    let accessToken: String
    var baseURL: URL = SupabaseConfig.url
    var anonKey: String = SupabaseConfig.anonKey
    var session: URLSession = .shared

    private var endpoint: URL { baseURL.appending(path: "/rest/v1/sync_records") }

    /// Rows are sent without `synced_at` (server-owned) — a dedicated encodable so
    /// we never accidentally ship the server clock back.
    private struct PushRow: Encodable {
        let user_id: String, kind: String, record_id: String
        let payload: String, updated_at: Date, deleted: Bool
    }

    func push(_ rows: [SyncRow]) async throws {
        guard !rows.isEmpty else { return }
        let body = rows.map {
            PushRow(user_id: userID, kind: $0.kind, record_id: $0.recordID,
                    payload: $0.payload, updated_at: $0.updatedAt, deleted: $0.deleted)
        }
        var req = URLRequest(url: endpoint.appending(queryItems: [
            .init(name: "on_conflict", value: "user_id,kind,record_id"),
        ]))
        req.httpMethod = "POST"
        req.timeoutInterval = 20
        req.httpBody = try SyncCoder.encoder.encode(body)
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("resolution=merge-duplicates,return=minimal", forHTTPHeaderField: "Prefer")
        addAuth(&req)
        try await send(req)
    }

    func pull(since cursor: Date?) async throws -> [SyncRow] {
        var items: [URLQueryItem] = [
            .init(name: "user_id", value: "eq.\(userID)"),
            .init(name: "order", value: "synced_at.asc"),
            .init(name: "select", value: "*"),
        ]
        if let cursor { items.append(.init(name: "synced_at", value: "gt.\(SyncCoder.iso(cursor))")) }
        var req = URLRequest(url: endpoint.appending(queryItems: items))
        req.httpMethod = "GET"
        req.timeoutInterval = 20
        addAuth(&req)
        let data = try await send(req)
        guard let rows = try? SyncCoder.decoder.decode([SyncRow].self, from: data) else {
            throw SyncError.malformed
        }
        return rows
    }

    private func addAuth(_ req: inout URLRequest) {
        req.setValue(anonKey, forHTTPHeaderField: "apikey")
        req.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
    }

    @discardableResult
    private func send(_ req: URLRequest) async throws -> Data {
        let data: Data, response: URLResponse
        do { (data, response) = try await session.data(for: req) }
        catch { throw SyncError.offline }               // no connection / timeout / DNS
        guard let http = response as? HTTPURLResponse else { throw SyncError.malformed }
        switch http.statusCode {
        case 200...299: return data
        case 401, 403:  throw SyncError.unauthorized
        default:        throw SyncError.server(http.statusCode)
        }
    }
}

extension SyncCoder {
    /// Cursor formatting for the PostgREST `gt.` filter (URLComponents percent-
    /// encodes the value, so a bare ISO string is fine here).
    static func iso(_ date: Date) -> String {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f.string(from: date)
    }
}
