import SwiftUI

/// Why a feedback submission failed — distinct cases so the user gets an
/// appropriate, non-technical message instead of one catch-all string, and so
/// we can tell an offline error apart from an RLS rejection. Mapping is pure and
/// unit-tested (see FeedbackErrorTests).
enum FeedbackError: Error, Equatable {
    case offline
    case timeout
    case invalidRequest
    case unauthorized
    case rateLimited
    case serverError
    case validation(String)
    case unknown

    /// Nontechnical, user-facing copy. Never exposes backend detail.
    var userMessage: String {
        switch self {
        case .offline:        return "You're offline. Check your connection and try again."
        case .timeout:        return "That took too long. Please try again."
        case .invalidRequest: return "That couldn't be sent as written. Please adjust and retry."
        case .unauthorized:   return "Feedback isn't accepting submissions right now. Please try again later."
        case .rateLimited:    return "That's a lot of feedback at once — give it a moment, then try again."
        case .serverError:    return "Our end had a problem. Please try again shortly."
        case .validation(let m): return m
        case .unknown:        return "Couldn't send your feedback. Please try again."
        }
    }

    /// HTTP status → error (nil for 2xx success).
    static func fromHTTP(_ status: Int) -> FeedbackError? {
        switch status {
        case 200...299: return nil
        case 400, 422:  return .invalidRequest
        case 401, 403:  return .unauthorized
        case 429:       return .rateLimited
        case 500...599: return .serverError
        default:        return .unknown
        }
    }

    /// Transport failure → error.
    static func fromURLError(_ error: URLError) -> FeedbackError {
        switch error.code {
        case .notConnectedToInternet, .dataNotAllowed, .networkConnectionLost:
            return .offline
        case .timedOut:
            return .timeout
        default:
            return .unknown
        }
    }

    /// Client-side validation before we ever hit the network.
    static func validate(message: String, email: String?) -> FeedbackError? {
        let count = message.count
        guard (1...4000).contains(count) else {
            return .validation(count == 0
                ? "Add a little detail before sending."
                : "That message is too long — 4000 characters max.")
        }
        if let email, !email.isEmpty {
            let looksValid = email.contains("@") && email.contains(".") && email.count <= 320
            if !looksValid { return .validation("That email doesn't look right — fix it or leave it blank.") }
        }
        return nil
    }
}

/// Founder-loop feedback: two fields, one tap, straight into the Supabase
/// `feedback` table (insert-only for clients; readable only from the dashboard).
enum FeedbackClient {
    struct Payload: Encodable {
        let source: String
        let email: String?
        let message: String
        let context: [String: String]
    }

    /// Returns nil on success, or a typed `FeedbackError` the UI can explain.
    @MainActor
    static func submit(message: String, email: String?) async -> FeedbackError? {
        let trimmed = message.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanEmail = (email?.isEmpty == true) ? nil : email
        if let invalid = FeedbackError.validate(message: trimmed, email: cleanEmail) { return invalid }

        let payload = Payload(
            source: "ios",
            email: cleanEmail,
            message: trimmed,
            context: [
                "build": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "dev",
                "os": UIDevice.current.systemVersion,
                "device": UIDevice.current.model,
            ])
        var request = URLRequest(url: SupabaseConfig.url.appending(path: "/rest/v1/feedback"))
        request.httpMethod = "POST"
        request.timeoutInterval = 15
        request.setValue(SupabaseConfig.anonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(SupabaseConfig.anonKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        guard let body = try? JSONEncoder().encode(payload) else { return .invalidRequest }
        request.httpBody = body
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse else { return .unknown }
            return FeedbackError.fromHTTP(http.statusCode)
        } catch let urlError as URLError {
            return FeedbackError.fromURLError(urlError)
        } catch {
            return .unknown
        }
    }
}

struct FeedbackSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var message = ""
    @State private var email = ""
    @State private var sending = false
    @State private var sent = false
    @State private var errorMessage: String?
    @FocusState private var messageFocused: Bool

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bgElevated.ignoresSafeArea()
                if sent { thanks } else { form }
            }
            .navigationTitle("Send Feedback")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { dismiss() }.foregroundStyle(Theme.gold)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .preferredColorScheme(.dark)
    }

    private var form: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("What's broken, confusing, or missing? Raw and unfiltered helps most — it goes straight to the founder.")
                .font(.system(size: 12.5)).foregroundStyle(Theme.muted)
                .fixedSize(horizontal: false, vertical: true)

            TextEditor(text: $message)
                .focused($messageFocused)
                .frame(minHeight: 120)
                .padding(10)
                .scrollContentBackground(.hidden)
                .background(RoundedRectangle(cornerRadius: 12).fill(Theme.card))
                .font(.system(size: 14)).foregroundStyle(Theme.cream)

            TextField("Email (optional — for a reply)", text: $email)
                .keyboardType(.emailAddress)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 12).fill(Theme.card))
                .font(.system(size: 13)).foregroundStyle(Theme.cream)

            if let errorMessage {
                ErrorBanner(message: errorMessage) { self.errorMessage = nil }
            }

            Button(sending ? "Sending…" : "Send feedback") {
                sending = true; errorMessage = nil
                Task {
                    let error = await FeedbackClient.submit(message: message, email: email)
                    sending = false
                    if let error {
                        errorMessage = error.userMessage
                    } else {
                        Haptics.success(); sent = true
                    }
                }
            }
            .buttonStyle(GoldButtonStyle())
            .disabled(sending || message.trimmingCharacters(in: .whitespacesAndNewlines).count < 3)
            Spacer()
        }
        .padding(18)
        .onAppear { messageFocused = true }
    }

    private var thanks: some View {
        VStack(spacing: 14) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 44)).foregroundStyle(Theme.green)
            Text("Received").font(Theme.display(24)).foregroundStyle(Theme.cream)
            Text("Every note gets read. Thank you for making Forge better.")
                .font(.system(size: 13)).foregroundStyle(Theme.muted)
            Button("Done") { dismiss() }.buttonStyle(GoldButtonStyle(compact: true))
        }
        .padding(24)
    }
}
