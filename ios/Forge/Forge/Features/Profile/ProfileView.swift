import SwiftUI

struct ProfileView: View {
    @Environment(AppState.self) private var app
    @State private var showDisclaimer = false

    var body: some View {
        ScreenScaffold {
            profileHeader
            goalsCard
            unitsCard
            devicesCard
            notificationPrefs
            subscriptionCard
            privacyCard

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
                Toggle(isOn: Binding(
                    get: { app.user.usesImperial },
                    set: { app.user.usesImperial = $0 }
                )) {
                    Text(app.user.usesImperial ? "Imperial (lb · in · oz)" : "Metric (kg · cm · mL)")
                        .font(.system(size: 13.5)).foregroundStyle(Theme.cream)
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
