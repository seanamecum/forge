import SwiftUI
import Charts

struct BodyTrackingView: View {
    @Environment(AppState.self) private var app
    @State private var showLogWeight = false

    var body: some View {
        ScreenScaffold {
            SectionHeader(eyebrow: "Health", title: "Body Tracking",
                          subtitle: app.isDemoAccount
                              ? "Lean bulk in progress: +6.5 lb over 90 days, 68% of it lean mass."
                              : "Log your weight and Forge adapts your fuel targets to your real trend.")

            statRow
            weightChart

            // Measurements, progress photos, and body-composition history are demo
            // illustrations (they need a smart scale / camera) — shown in demo mode only.
            if app.isDemoAccount {
                measurementsCard
                photosCard
                comparisonCard
            }
        }
        .navigationTitle("Body")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showLogWeight) { LogWeightSheet() }
    }

    private var statRow: some View {
        Card(gold: true) {
            HStack(spacing: 14) {
                StatTile(label: "Weight",
                         value: app.latestWeight.map { String(format: "%.1f", $0) } ?? "—",
                         unit: "lb", hint: weeklyChangeText ?? "log a weigh-in", tone: .gold)
                if app.isDemoAccount {
                    StatTile(label: "Body Fat", value: "14.1", unit: "%", hint: "+0.2 / 30d")
                    StatTile(label: "Lean Mass", value: "171.8", unit: "lb", hint: "+1.2 / 30d", tone: .green)
                } else {
                    StatTile(label: "Body Fat", value: "—", unit: "%", hint: "smart scale")
                    StatTile(label: "Lean Mass", value: "—", unit: "lb", hint: "smart scale")
                }
            }
        }
    }

    private var weightChart: some View {
        Card {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    EyebrowLabel(text: "Weight")
                    Spacer()
                    Button {
                        Haptics.tap(); showLogWeight = true
                    } label: {
                        Label("Log weight", systemImage: "plus.circle.fill")
                    }
                    .font(.system(size: 12, weight: .medium)).foregroundStyle(Theme.gold)
                }

                let trend = app.weightTrend
                if trend.isEmpty {
                    EmptyStateView(icon: "scalemass",
                                   title: "No weigh-ins yet",
                                   message: "Log your weight and Forge charts your trend and tunes your fuel targets to it.",
                                   actionLabel: "Log your first weigh-in") { showLogWeight = true }
                } else {
                    Sparkline(values: trend, height: 64, accessibilityLabel: "Weight trend, lb")
                    HStack {
                        Text(String(format: "%.1f lb", trend.min() ?? 0))
                            .font(.system(size: 10)).foregroundStyle(Theme.faint)
                        Spacer()
                        if let t = weeklyChangeText {
                            Text(t).font(.system(size: 10)).foregroundStyle(Theme.green)
                            Spacer()
                        }
                        Text(String(format: "%.1f lb", trend.last ?? 0))
                            .font(.system(size: 10)).foregroundStyle(Theme.faint)
                    }
                }
            }
        }
    }

    /// Weekly change from the trend, or nil with fewer than two weigh-ins.
    private var weeklyChangeText: String? {
        let t = app.weightTrend
        guard t.count >= 2, let first = t.first, let last = t.last else { return nil }
        let perWeek = (last - first) / Double(t.count) * 7.0
        return String(format: "trend %+.1f lb/wk", perWeek)
    }

    // MARK: - Demo-only illustrations

    private var measurementsCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 10) {
                EyebrowLabel(text: "Measurements")
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                    ForEach(MockData.measurements) { m in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(m.name.uppercased())
                                .font(.system(size: 8.5, weight: .semibold)).kerning(1)
                                .foregroundStyle(Theme.muted)
                            Text(m.value).font(.system(size: 13, weight: .medium)).foregroundStyle(Theme.cream)
                            if let delta = m.delta30d {
                                Text("\(delta) /30d").font(.system(size: 9.5)).foregroundStyle(Theme.green)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
        }
    }

    private var photosCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    EyebrowLabel(text: "Progress Photos")
                    Spacer()
                    ComingSoonButton("Add", feature: "Progress photos")
                }
                HStack(spacing: 8) {
                    ForEach(MockData.bodyHistory) { snap in
                        VStack(spacing: 5) {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Theme.bgElevated)
                                .frame(height: 110)
                                .overlay(
                                    Image(systemName: "figure.stand")
                                        .font(.system(size: 30))
                                        .foregroundStyle(Theme.gold.opacity(0.25))
                                )
                                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Theme.hairline, lineWidth: 1))
                            Text(snap.date).font(.system(size: 9.5)).foregroundStyle(Theme.muted)
                        }
                    }
                }
            }
        }
    }

    private var comparisonCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 10) {
                EyebrowLabel(text: "90-Day Comparison")
                ForEach(MockData.bodyHistory) { snap in
                    HStack {
                        Text(snap.date).font(.system(size: 12)).foregroundStyle(Theme.muted)
                            .frame(width: 56, alignment: .leading)
                        Text("\(String(format: "%.1f", snap.weightLb)) lb")
                            .font(.system(size: 12.5, weight: .medium)).foregroundStyle(Theme.cream)
                        Spacer()
                        Text("\(String(format: "%.1f", snap.bodyFatPct))% bf")
                            .font(.system(size: 12)).foregroundStyle(Theme.creamDim)
                        Spacer()
                        Text("LM \(String(format: "%.1f", snap.leanMassLb))")
                            .font(.system(size: 12)).foregroundStyle(Theme.green)
                    }
                    .padding(.vertical, 3)
                }
            }
        }
    }
}

/// Compact weigh-in entry — persists, updates the current weight, and re-runs the
/// adaptive fuel plan against the real trend.
private struct LogWeightSheet: View {
    @Environment(AppState.self) private var app
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @State private var text = ""

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bgElevated.ignoresSafeArea()
                VStack(alignment: .leading, spacing: 16) {
                    Text("Today's weight").font(.system(size: 13)).foregroundStyle(Theme.cream)
                    HStack {
                        TextField("0.0", text: $text)
                            .keyboardType(.decimalPad)
                            .font(Theme.display(28))
                            .foregroundStyle(Theme.cream)
                        Text("lb").font(.system(size: 15)).foregroundStyle(Theme.muted)
                    }
                    .padding(14)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Theme.card))

                    Text("Forge charts your trend and tunes your calorie and protein targets to it. Two weeks of weigh-ins unlocks weight-trend coaching.")
                        .font(.system(size: 11.5)).foregroundStyle(Theme.muted)
                        .fixedSize(horizontal: false, vertical: true)

                    Button("Save weigh-in") {
                        if let lb = Double(text.trimmingCharacters(in: .whitespaces)), lb > 0 {
                            app.logWeight(lb, context: context)
                            Haptics.success()
                            dismiss()
                        }
                    }
                    .buttonStyle(GoldButtonStyle())
                    .disabled(Double(text.trimmingCharacters(in: .whitespaces)) ?? 0 <= 0)
                    Spacer()
                }
                .padding(20)
            }
            .navigationTitle("Log Weight")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") { dismiss() }.foregroundStyle(Theme.gold)
                }
            }
        }
        .presentationDetents([.height(300)])
        .preferredColorScheme(.dark)
    }
}
