import SwiftUI
import UIKit

/// A built export file, wrapped so `.sheet(item:)` can present it.
private struct ExportFile: Identifiable { let id = UUID(); let url: URL }

/// Minimal system share sheet for a prepared file URL.
private struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_ vc: UIActivityViewController, context: Context) {}
}

struct ProfileView: View {
    @Environment(AppState.self) private var app
    @State private var showDisclaimer = false
    @State private var showFeedback = false
    @State private var confirmDelete = false
    @State private var deleting = false
    @State private var exportFile: ExportFile?
    @State private var exportError: String?

    var body: some View {
        ScreenScaffold {
            profileHeader
            goalsCard
            unitsCard
            devicesCard
            notificationPrefs
            subscriptionCard
            privacyCard
            accountCard

            Button {
                showFeedback = true
            } label: {
                Label("Send Feedback", systemImage: "envelope")
            }
            .buttonStyle(GoldButtonStyle())

            Button {
                showDisclaimer = true
            } label: {
                Label("Medical Disclaimer", systemImage: "cross.case")
            }
            .buttonStyle(GhostButtonStyle())

            Button("Log Out") { app.logout() }
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Theme.rubyBright)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)

            Text("Forge v1.0 · Built for athletes")
                .font(.system(size: 10)).foregroundStyle(Theme.faint)
                .frame(maxWidth: .infinity)
        }
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showDisclaimer) { DisclaimerSheet() }
        .sheet(isPresented: $showFeedback) { FeedbackSheet() }
    }

    /// Account & data ownership: export everything, delete the account
    /// in-app (App Store 5.1.1(v)), or see you're in demo mode.
    private var accountCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 12) {
                EyebrowLabel(text: "Account & Data")
                if let email = app.auth.sessionEmail {
                    Text("Signed in as \(email)")
                        .font(.system(size: 12.5)).foregroundStyle(Theme.creamDim)
                } else {
                    Text("Demo mode — no account, nothing leaves this phone.")
                        .font(.system(size: 12.5)).foregroundStyle(Theme.muted)
                }
                if let error = app.auth.lastError {
                    ErrorBanner(message: error) { app.auth.lastError = nil }
                }
                if let exportError {
                    ErrorBanner(message: exportError) { self.exportError = nil }
                }
                HStack(spacing: 8) {
                    Button {
                        do {
                            exportFile = ExportFile(url: try PersistenceService.exportToTemporaryFile(profile: app.user))
                        } catch {
                            exportError = (error as? LocalizedError)?.errorDescription
                                ?? "Couldn't export your data. Please try again."
                        }
                    } label: {
                        Label("Export my data", systemImage: "square.and.arrow.up")
                    }
                    .buttonStyle(GhostButtonStyle(compact: true))

                    Button(deleting ? "Deleting…" : "Delete data…") { confirmDelete = true }
                        .buttonStyle(GhostButtonStyle(compact: true))
                        .foregroundStyle(Theme.rubyBright)
                        .disabled(deleting)
                }
            }
        }
        .sheet(item: $exportFile) { ShareSheet(items: [$0.url]) }
        .confirmationDialog("Delete Forge data", isPresented: $confirmDelete, titleVisibility: .visible) {
            if app.auth.sessionEmail != nil {
                Button("Delete cloud account only", role: .destructive) { deleteCloudAccount() }
                Button("Delete account + all data on this phone", role: .destructive) { deleteEverything() }
            }
            Button("Delete all data on this phone", role: .destructive) { deleteLocalData() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text(app.auth.sessionEmail != nil
                 ? "Cloud deletion removes your account and sign-in from Forge's servers. Phone deletion erases your workouts, nutrition, check-ins, hydration and scores stored on this device. Neither touches Apple Health — Forge only reads it."
                 : "This erases your workouts, nutrition, check-ins, hydration and scores stored on this device. It does not touch Apple Health — Forge only reads it.")
        }
    }

    /// Cloud account only: server delete, then end the session. Local data stays.
    private func deleteCloudAccount() {
        deleting = true
        Task { @MainActor in
            if await app.auth.deleteAccount() { app.logout() }
            deleting = false
        }
    }

    /// Local only: wipe on-device Forge data; the user stays signed in.
    private func deleteLocalData() {
        PersistenceService.deleteAllLocalData()
    }

    /// Both: delete the cloud account first; only wipe local data if that
    /// succeeds, so a failed server delete can be retried without losing data.
    private func deleteEverything() {
        deleting = true
        Task { @MainActor in
            let ok = await app.auth.deleteAccount()
            if ok {
                PersistenceService.deleteAllLocalData()
                app.logout()
            }
            deleting = false
        }
    }

    private var profileHeader: some View {
        let u = app.user
        return Card(gold: true) {
            HStack(spacing: 14) {
                ZStack {
                    Circle().fill(Theme.goldGradient)
                    Text(u.initials).font(Theme.display(22, .bold)).foregroundStyle(Theme.bg)
                }
                .frame(width: 64, height: 64)
                .shadow(color: Theme.gold.opacity(0.4), radius: 10)

                VStack(alignment: .leading, spacing: 3) {
                    Text(u.name).font(Theme.display(21)).foregroundStyle(Theme.cream)
                    Text("\(u.sport) · \(u.fitnessLevel.rawValue) · \(u.experienceYears) yrs")
                        .font(.system(size: 11.5)).foregroundStyle(Theme.gold)
                    Text("\(u.age) yrs · \(u.heightLabel) · \(Int(u.weightLb)) lb")
                        .font(.system(size: 11)).foregroundStyle(Theme.muted)
                }
                Spacer()
            }
        }
    }

    private var goalsCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 8) {
                EyebrowLabel(text: "Goals")
                FlowChips(options: Goal.allCases.map(\.rawValue),
                          isSelected: { app.user.goals.map(\.rawValue).contains($0) },
                          toggle: { name in
                              guard let goal = Goal(rawValue: name) else { return }
                              if app.user.goals.contains(goal) {
                                  app.user.goals.removeAll { $0 == goal }
                              } else if app.user.goals.count < 3 {
                                  app.user.goals.append(goal)
                              }
                          })
            }
        }
    }

    private var unitsCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 4) {
                EyebrowLabel(text: "Units")
                HStack {
                    Text("Units").font(.system(size: 13.5)).foregroundStyle(Theme.cream)
                    Spacer()
                    Text("Imperial (lb · in · oz)")
                        .font(.system(size: 12.5)).foregroundStyle(Theme.muted)
                }
                .tint(Theme.gold)
            }
        }
    }

    private var devicesCard: some View {
        NavRow(icon: "applewatch.radiowaves.left.and.right",
               title: "Connected Devices",
               subtitle: "\(app.recovery.connectedCount) of \(app.recovery.wearables.count) paired") { WearablesView() }
    }

    private var notificationPrefs: some View {
        Card {
            VStack(alignment: .leading, spacing: 12) {
                EyebrowLabel(text: "Notifications")

                Toggle(isOn: Binding(
                    get: { app.notifications.morningDirectiveOn },
                    set: { on in
                        let dir = app.dailyDirective
                        Task { await app.notifications.setMorningDirective(on, headline: dir.headline, priority: dir.priorityAction) }
                    }
                )) { prefLabel("Morning directive") }
                .tint(Theme.gold)

                if app.notifications.morningDirectiveOn {
                    DatePicker(
                        selection: Binding(
                            get: {
                                var c = DateComponents()
                                c.hour = app.notifications.directiveHour
                                c.minute = app.notifications.directiveMinute
                                return Calendar.current.date(from: c) ?? Date()
                            },
                            set: { newDate in
                                let comps = Calendar.current.dateComponents([.hour, .minute], from: newDate)
                                app.notifications.directiveHour = comps.hour ?? 7
                                app.notifications.directiveMinute = comps.minute ?? 0
                                let dir = app.dailyDirective
                                Task { await app.notifications.rescheduleMorningDirective(headline: dir.headline, priority: dir.priorityAction) }
                            }),
                        displayedComponents: .hourAndMinute
                    ) {
                        prefLabel("Delivery time")
                    }
                    .datePickerStyle(.compact)
                    .tint(Theme.gold)
                }

                Toggle(isOn: Binding(
                    get: { app.notifications.smartNudgesOn },
                    set: { on in
                        Task { await app.notifications.setSmartNudges(on, proteinRemaining: app.nutrition.proteinRemaining) }
                    }
                )) { prefLabel("Smart nudges (protein · PT)") }
                .tint(Theme.gold)

                Button("Send a test notification") {
                    Task { await app.notifications.sendPreview() }
                }
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Theme.gold)
            }
        }
    }

    private func prefLabel(_ text: String) -> some View {
        Text(text).font(.system(size: 13.5)).foregroundStyle(Theme.cream)
    }

    private var subscriptionCard: some View {
        Card(gold: true) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    EyebrowLabel(text: "Membership")
                    Spacer()
                    Chip(text: "Pro trial · 9 days left", tone: .gold)
                }
                tierRow("Free", "Logging · exercise library · basic dashboard", current: false)
                tierRow("Pro · $11.99/mo", "AI Coach · Forge Score · Digital Twin · Form Analysis", current: true)
                tierRow("Elite · $29.99/mo", "1:1 coach marketplace credit · bloodwork reads · team tools", current: false)
                Text("College athlete and team plans available — StoreKit wiring is the production step.")
                    .font(.system(size: 10.5)).foregroundStyle(Theme.faint)
            }
        }
    }

    private func tierRow(_ name: String, _ detail: String, current: Bool) -> some View {
        HStack(spacing: 10) {
            Image(systemName: current ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 16))
                .foregroundStyle(current ? Theme.gold : Theme.faint)
            VStack(alignment: .leading, spacing: 1) {
                Text(name).font(.system(size: 13, weight: current ? .semibold : .regular)).foregroundStyle(Theme.cream)
                Text(detail).font(.system(size: 10.5)).foregroundStyle(Theme.muted)
            }
            Spacer()
        }
        .padding(8)
        .background(RoundedRectangle(cornerRadius: 10).fill(current ? Theme.gold.opacity(0.07) : Theme.bgElevated))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(current ? Theme.gold.opacity(0.35) : Theme.hairline, lineWidth: 1))
    }

    private var privacyCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 8) {
                EyebrowLabel(text: "Privacy")
                Text("Health data stays on device in the prototype. Backend sync will be opt-in, end-to-end encrypted, and never sold. HealthKit data is never used for advertising — App Store rules and ours.")
                    .font(.system(size: 11.5)).foregroundStyle(Theme.muted)
            }
        }
    }
}

struct DisclaimerSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Theme.bgElevated.ignoresSafeArea()
            VStack(alignment: .leading, spacing: 14) {
                Text("Medical Disclaimer").font(Theme.display(26)).foregroundStyle(Theme.cream)
                    .padding(.top, 24)
                Text("""
                Forge provides educational guidance based on the data you share with it. It is not a medical device and does not diagnose, treat, or cure any condition.

                Always seek professional medical care for: concussion or any head injury, chest pain, neurological symptoms, severe pain or swelling, inability to bear weight, or symptoms that worsen or persist.

                Injury, rehab, bloodwork, and supplement content describes general athletic practice — your physician or physical therapist makes the calls for your body.
                """)
                .font(.system(size: 13)).foregroundStyle(Theme.creamDim)
                Spacer()
                Button("Understood") { dismiss() }
                    .buttonStyle(GoldButtonStyle())
                    .padding(.bottom, 20)
            }
            .padding(.horizontal, 24)
        }
        .presentationDetents([.medium])
    }
}
