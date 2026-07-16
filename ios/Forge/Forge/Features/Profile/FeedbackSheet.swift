import SwiftUI

/// Founder-loop feedback: two fields, one tap, straight into the Supabase
/// `feedback` table (insert-only for clients; readable only from the dashboard).
enum FeedbackClient {
    struct Payload: Encodable {
        let source: String
        let email: String?
        let message: String
        let context: [String: String]
    }

    @MainActor
    static func submit(message: String, email: String?) async -> Bool {
        let payload = Payload(
            source: "ios",
            email: email?.isEmpty == true ? nil : email,
            message: message,
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
        guard let body = try? JSONEncoder().encode(payload) else { return false }
        request.httpBody = body
        guard let (_, response) = try? await URLSession.shared.data(for: request),
              let http = response as? HTTPURLResponse else { return false }
        return (200...299).contains(http.statusCode)
    }
}

struct FeedbackSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var message = ""
    @State private var email = ""
    @State private var sending = false
    @State private var sent = false
    @State private var failed = false
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

            if failed {
                ErrorBanner(message: "Couldn't send — check your connection and try again.") { failed = false }
            }

            Button(sending ? "Sending…" : "Send feedback") {
                sending = true; failed = false
                Task {
                    let ok = await FeedbackClient.submit(message: message, email: email)
                    sending = false
                    if ok { Haptics.success(); sent = true } else { failed = true }
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
