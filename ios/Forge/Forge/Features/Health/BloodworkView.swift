import SwiftUI

struct BloodworkView: View {
    @Environment(AppState.self) private var app
    @State private var showAdd = false

    private var markers: [BloodworkMarker] { app.nutrition.bloodwork }

    private var grouped: [(BloodworkMarker.Category, [BloodworkMarker])] {
        BloodworkMarker.Category.allCases.compactMap { category in
            let items = markers.filter { $0.category == category }
            return items.isEmpty ? nil : (category, items)
        }
    }

    private var subtitle: String {
        markers.isEmpty
            ? "Add your lab results and Forge reads each marker against your training, sleep, and intake."
            : "\(markers.count) marker\(markers.count == 1 ? "" : "s"), interpreted in the context of your training, sleep, and intake — not just flagged."
    }

    var body: some View {
        ScreenScaffold {
            SectionHeader(eyebrow: "Health", title: "Bloodwork", subtitle: subtitle)

            DisclaimerNote(text: "Bloodwork interpretation is educational context, not diagnosis or treatment. Review results and any intervention with your physician.")

            if markers.isEmpty {
                EmptyStateView(
                    icon: "drop.fill",
                    title: "Add your bloodwork",
                    message: "Enter your lab values and Forge flags anything below its optimal range, then folds it into your fuel and recovery coaching.",
                    actionLabel: "Add a marker",
                    action: { showAdd = true })
            } else {
                ForEach(grouped, id: \.0) { category, markers in
                    VStack(alignment: .leading, spacing: 10) {
                        EyebrowLabel(text: category.rawValue)
                        ForEach(markers) { marker in
                            MarkerCard(marker: marker)
                        }
                    }
                }

                Button { showAdd = true } label: {
                    Label("Add a marker", systemImage: "plus")
                }
                .buttonStyle(GhostButtonStyle(compact: false))
            }
        }
        .navigationTitle("Bloodwork")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { showAdd = true } label: { Image(systemName: "plus") }
                    .foregroundStyle(Theme.gold)
                    .accessibilityLabel("Add bloodwork marker")
            }
        }
        .sheet(isPresented: $showAdd) { AddBloodworkSheet() }
    }
}

/// Enter one lab result from the reference catalog. The user picks a marker
/// (which carries its own normal/optimal ranges) and types their measured value;
/// Forge derives status and deficiency flags from it.
private struct AddBloodworkSheet: View {
    @Environment(AppState.self) private var app
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var selected: BloodworkCatalogEntry = BloodworkCatalog.markers[0]
    @State private var valueText = ""

    private var value: Double { Double(valueText.trimmingCharacters(in: .whitespaces)) ?? 0 }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bgElevated.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Marker").font(.system(size: 12)).foregroundStyle(Theme.muted)
                        Picker("Marker", selection: $selected) {
                            ForEach(BloodworkCatalog.markers) { m in Text(m.name).tag(m) }
                        }
                        .pickerStyle(.menu)
                        .tint(Theme.gold)

                        Text("Your value").font(.system(size: 12)).foregroundStyle(Theme.muted)
                        HStack {
                            TextField("0", text: $valueText)
                                .keyboardType(.decimalPad)
                                .font(Theme.display(26)).foregroundStyle(Theme.cream)
                            Text(selected.unit).font(.system(size: 14)).foregroundStyle(Theme.muted)
                        }
                        .padding(12)
                        .background(RoundedRectangle(cornerRadius: 11).fill(Theme.card))

                        Text("Normal \(g(selected.normalLow))–\(g(selected.normalHigh)) · optimal \(g(selected.optimalLow))–\(g(selected.optimalHigh)) \(selected.unit)")
                            .font(.system(size: 11)).foregroundStyle(Theme.faint)

                        Button("Save marker") {
                            app.addBloodwork(selected, value: value, context: context)
                            Haptics.success()
                            dismiss()
                        }
                        .buttonStyle(GoldButtonStyle())
                        .disabled(value <= 0)
                        .padding(.top, 4)
                        Spacer()
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Add Marker")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") { dismiss() }.foregroundStyle(Theme.gold)
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private func g(_ v: Double) -> String { String(format: "%g", v) }
}

struct MarkerCard: View {
    let marker: BloodworkMarker

    var body: some View {
        Card {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    VStack(alignment: .leading, spacing: 1) {
                        Text(marker.name).font(.system(size: 14, weight: .semibold)).foregroundStyle(Theme.cream)
                        Text(marker.takenAt).font(.system(size: 10.5)).foregroundStyle(Theme.faint)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 1) {
                        HStack(alignment: .firstTextBaseline, spacing: 3) {
                            Text(String(format: "%g", marker.value))
                                .font(Theme.display(20)).foregroundStyle(Theme.goldGradient)
                            Text(marker.unit).font(.system(size: 9.5)).foregroundStyle(Theme.muted)
                        }
                        if let delta = marker.delta {
                            Text(delta).font(.system(size: 10.5)).foregroundStyle(Theme.green)
                        }
                    }
                }

                RangeBar(marker: marker)

                HStack {
                    Chip(text: marker.status, tone: marker.statusTone)
                    Spacer()
                    Text("Optimal \(String(format: "%g", marker.optimalLow))–\(String(format: "%g", marker.optimalHigh)) \(marker.unit)")
                        .font(.system(size: 10)).foregroundStyle(Theme.faint)
                }

                if !marker.aiNote.isEmpty {
                    CoachNote(text: marker.aiNote)
                }
            }
        }
    }
}

/// Normal range track with the optimal band highlighted and a value marker.
struct RangeBar: View {
    let marker: BloodworkMarker

    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let span = max(0.001, marker.normalHigh - marker.normalLow)
            let optStart = (marker.optimalLow - marker.normalLow) / span
            let optWidth = (marker.optimalHigh - marker.optimalLow) / span
            let pos = ((marker.value - marker.normalLow) / span).clamped01

            ZStack(alignment: .leading) {
                Capsule().fill(Theme.gold.opacity(0.07)).frame(height: 8)
                Capsule()
                    .fill(Theme.green.opacity(0.22))
                    .frame(width: max(0, width * optWidth), height: 8)
                    .offset(x: width * optStart.clamped01)
                Circle()
                    .fill(marker.statusTone.color)
                    .frame(width: 13, height: 13)
                    .overlay(Circle().stroke(Theme.bg, lineWidth: 2))
                    .offset(x: width * pos - 6.5)
                    .shadow(color: marker.statusTone.color.opacity(0.6), radius: 4)
            }
        }
        .frame(height: 14)
    }
}

private extension Double {
    var clamped01: Double { Swift.min(1, Swift.max(0, self)) }
}
