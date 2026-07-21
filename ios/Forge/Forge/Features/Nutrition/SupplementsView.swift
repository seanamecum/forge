import SwiftUI

struct SupplementsView: View {
    @Environment(AppState.self) private var app
    @Environment(\.modelContext) private var context
    @State private var showAdd = false

    var body: some View {
        ScreenScaffold {
            SectionHeader(eyebrow: "Fuel · Stack", title: "Supplements",
                          subtitle: "Streaks build the habit. Forge ties gaps here to your sleep, HRV, and fatigue.")

            if app.nutrition.supplements.isEmpty {
                EmptyStateView(
                    icon: "pills",
                    title: "Build your stack",
                    message: "Add the supplements you actually take. Forge tracks your daily streak and connects any gaps to your recovery, sleep, and labs.",
                    actionLabel: "Add supplement",
                    action: { showAdd = true })
            } else {
                ForEach(app.nutrition.supplements) { s in
                    Card {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(s.name).font(.system(size: 14.5, weight: .semibold)).foregroundStyle(Theme.cream)
                                    Text("\(s.dose) · \(s.timing)").font(.system(size: 11)).foregroundStyle(Theme.muted)
                                }
                                Spacer()
                                Button {
                                    Haptics.tap()
                                    app.toggleSupplement(s, context: context)
                                } label: {
                                    Image(systemName: s.loggedToday ? "checkmark.circle.fill" : "circle")
                                        .font(.system(size: 26))
                                        .foregroundStyle(s.loggedToday ? Theme.green : Theme.faint.opacity(0.5))
                                }
                                .accessibilityLabel(s.loggedToday ? "Logged today" : "Mark \(s.name) taken")
                            }
                            if !s.benefit.isEmpty {
                                Text(s.benefit).font(.system(size: 12)).foregroundStyle(Theme.creamDim)
                            }
                            HStack {
                                Image(systemName: "flame.fill").font(.system(size: 10)).foregroundStyle(Theme.gold)
                                Text("\(s.streak)-day streak")
                                    .font(.system(size: 11, weight: .medium)).foregroundStyle(Theme.gold)
                                Spacer()
                                if !s.loggedToday {
                                    Text("Pending today").font(.system(size: 10.5)).foregroundStyle(Theme.amber)
                                }
                            }
                        }
                    }
                    .contextMenu {
                        Button(role: .destructive) {
                            app.removeSupplement(s, context: context)
                        } label: { Label("Remove", systemImage: "trash") }
                    }
                }

                Button {
                    showAdd = true
                } label: {
                    Label("Add supplement", systemImage: "plus")
                }
                .buttonStyle(GhostButtonStyle(compact: true))
                .padding(.top, 2)
            }
        }
        .navigationTitle("Supplements")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { showAdd = true } label: { Image(systemName: "plus") }
                    .foregroundStyle(Theme.gold)
                    .accessibilityLabel("Add supplement")
            }
        }
        .sheet(isPresented: $showAdd) { AddSupplementSheet() }
    }
}

/// Logs a supplement into the user's real stack (persisted for real accounts,
/// in-memory for the demo athlete). Deliberately minimal — name is all that's
/// required; dose/timing/benefit refine the coaching.
private struct AddSupplementSheet: View {
    @Environment(AppState.self) private var app
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var dose = ""
    @State private var timing = "Daily"
    @State private var benefit = ""

    private let timings = ["Morning", "With food", "Pre-workout", "Evening", "Before bed", "Daily"]

    private var canSave: Bool { !name.trimmingCharacters(in: .whitespaces).isEmpty }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bgElevated.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        field("Name", text: $name, placeholder: "Magnesium glycinate")
                        field("Dose", text: $dose, placeholder: "400 mg")

                        Text("Timing").font(.system(size: 12)).foregroundStyle(Theme.muted)
                        Picker("Timing", selection: $timing) {
                            ForEach(timings, id: \.self) { Text($0).tag($0) }
                        }
                        .pickerStyle(.menu)
                        .tint(Theme.gold)

                        field("Why you take it", text: $benefit, placeholder: "Sleep & recovery")

                        Button("Add to stack") {
                            app.addSupplement(name: name, dose: dose, timing: timing, benefit: benefit, context: context)
                            Haptics.success()
                            dismiss()
                        }
                        .buttonStyle(GoldButtonStyle())
                        .disabled(!canSave)
                        .padding(.top, 4)
                        Spacer()
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Add Supplement")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") { dismiss() }.foregroundStyle(Theme.gold)
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private func field(_ label: String, text: Binding<String>, placeholder: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label).font(.system(size: 12)).foregroundStyle(Theme.muted)
            TextField(placeholder, text: text)
                .font(.system(size: 15)).foregroundStyle(Theme.cream)
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 11).fill(Theme.card))
        }
    }
}
