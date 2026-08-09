import SwiftUI

/// The production quantity editor — edit a logged food's amount and unit without
/// re-searching, with instant recalculation of calories, macros, and micros. Rich
/// mode (unit switching + grams) when the food has a gram basis; an honest
/// multiplier mode otherwise. Never fabricates a conversion.
struct QuantityEditorSheet: View {
    @Environment(AppState.self) private var app
    @Environment(\.dismiss) private var dismiss

    let entry: FoodEntry

    @State private var engine: QuantityEditorEngine?     // rich mode
    @State private var amountText: String = "1"
    @State private var multiplier: Double = 1            // basis-less fallback
    @State private var dragAnchor: Double = 0

    private var richMode: Bool { engine != nil }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bgElevated.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        header
                        amountField
                        stepperRow
                        if richMode { unitChips } else { multiplierNote }
                        estimatedNote
                        macroReadout
                        Spacer(minLength: 8)
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Edit quantity")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }.foregroundStyle(Theme.gold)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save", action: save).foregroundStyle(Theme.gold).fontWeight(.semibold)
                        .disabled(!canSave)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .preferredColorScheme(.dark)
        .onAppear(perform: load)
    }

    // MARK: Load

    private func load() {
        if let e = app.quantityEditor(for: entry) {
            engine = e
            amountText = trim(e.amount)
        } else {
            engine = nil
            multiplier = 1
            amountText = "1"
        }
    }

    // MARK: Sections

    private var header: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(entry.food.name).font(Theme.display(20)).foregroundStyle(Theme.cream)
            if let brand = entry.food.brand {
                Text(brand).font(.system(size: 12)).foregroundStyle(Theme.muted)
            }
        }
    }

    /// Big, tappable amount with a horizontal drag to scrub — "swipe for quick
    /// quantity changes."
    private var amountField: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            TextField("1", text: $amountText)
                .keyboardType(.numbersAndPunctuation)
                .font(Theme.display(40))
                .foregroundStyle(Theme.cream)
                .fixedSize()
                .onChange(of: amountText) { _, new in commitText(new) }
            Text(unitLabel).font(.system(size: 17)).foregroundStyle(Theme.gold)
            Spacer()
        }
        .padding(.vertical, 6)
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 8)
                .onChanged { g in scrub(by: g.translation.width) }
                .onEnded { _ in dragAnchor = currentAmount }
        )
    }

    private var stepperRow: some View {
        HStack(spacing: 10) {
            roundButton("minus") { adjust(.decrement) }
            roundButton("plus") { adjust(.increment) }
            Spacer()
            pill("½×") { adjust(.scale(0.5)) }
            pill("2×") { adjust(.scale(2)) }
        }
    }

    private var unitChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(engine?.availableUnits ?? []) { unit in
                    let selected = unit.id == engine?.unitID
                    Button {
                        Haptics.tap()
                        engine?.switchUnit(to: unit.id)
                        amountText = trim(engine?.amount ?? 1)
                    } label: {
                        Text(unit.label)
                            .font(.system(size: 13, weight: .medium))
                            .padding(.horizontal, 14).padding(.vertical, 8)
                            .background(RoundedRectangle(cornerRadius: 10)
                                .fill(selected ? Theme.gold.opacity(0.2) : Theme.card))
                            .overlay(RoundedRectangle(cornerRadius: 10)
                                .stroke(selected ? Theme.gold : .clear, lineWidth: 1))
                            .foregroundStyle(selected ? Theme.gold : Theme.creamDim)
                    }
                }
            }
        }
    }

    private var multiplierNote: some View {
        Text("Editing amount as a multiple of the logged serving (\(entry.food.serving)). Unit conversions aren't available for this food yet.")
            .font(Typography.footnote).foregroundStyle(Theme.muted)
            .fixedSize(horizontal: false, vertical: true)
    }

    @ViewBuilder private var estimatedNote: some View {
        if engine?.isEstimatedConversion == true {
            Label("This is an estimated conversion.", systemImage: "exclamationmark.triangle")
                .font(Typography.footnote).foregroundStyle(Theme.amber)
        }
    }

    private var macroReadout: some View {
        let n = liveNutrients
        return Card {
            HStack {
                macro("kcal", n?[.calories], accent: true)
                Divider().frame(height: 30).overlay(Theme.faint.opacity(0.3))
                macro("P", n?[.protein]); macro("C", n?[.carbs]); macro("F", n?[.fat])
            }
        }
        .animation(.snappy(duration: 0.18), value: currentAmount)
    }

    private func macro(_ label: String, _ value: Double?, accent: Bool = false) -> some View {
        VStack(spacing: 2) {
            Text(value.map { String(Int($0.rounded())) } ?? "—")
                .font(.system(size: accent ? 22 : 17, weight: .bold, design: .rounded))
                .foregroundStyle(accent ? Theme.goldGradient : LinearGradient(colors: [Theme.cream], startPoint: .top, endPoint: .bottom))
            Text(label).font(.system(size: 10)).foregroundStyle(Theme.muted)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: Derived

    private var currentAmount: Double { richMode ? (engine?.amount ?? 1) : multiplier }
    private var unitLabel: String { richMode ? (engine?.unit.label ?? "") : "×" }
    private var liveNutrients: NutrientVector? {
        if let e = engine { return e.nutrients }
        // Multiplier preview: scale the row's current consumed by the multiplier.
        return NutrientVector([
            .calories: Double(entry.food.calories), .protein: entry.food.protein,
            .carbs: entry.food.carbs, .fat: entry.food.fat,
        ]).scaled(by: multiplier)
    }
    private var canSave: Bool {
        richMode ? (engine?.isValid == true && engine?.nutrients != nil) : multiplier > 0
    }

    // MARK: Actions

    private enum Adjust { case increment, decrement, scale(Double) }

    private func adjust(_ a: Adjust) {
        Haptics.tap()
        if richMode {
            switch a {
            case .increment: engine?.increment()
            case .decrement: engine?.decrement()
            case .scale(let f): engine?.scale(by: f)
            }
            amountText = trim(engine?.amount ?? 1)
        } else {
            switch a {
            case .increment: multiplier += 1
            case .decrement: multiplier = max(0, multiplier - 1)
            case .scale(let f): multiplier = max(0, multiplier * f)
            }
            amountText = trim(multiplier)
        }
    }

    private func commitText(_ text: String) {
        guard let v = QuantityParser.parse(text) else { return }
        if richMode { engine?.setAmount(v) } else { multiplier = max(0, v) }
    }

    private func scrub(by dx: CGFloat) {
        // ~1 step per 22 pt of drag, from the anchor captured at gesture start.
        let steps = Double((dx / 22).rounded())
        let base = dragAnchor == 0 ? currentAmount : dragAnchor
        let unit = richMode ? QuantityStep.step(for: engine!.unit) : 1
        let v = max(0, base + steps * unit)
        if richMode { engine?.setAmount(v) } else { multiplier = v }
        amountText = trim(v)
    }

    private func save() {
        if richMode, let e = engine {
            app.applyQuantityEdit(entry, engine: e)
        } else {
            app.applyMultiplierEdit(entry, newAmount: multiplier)
        }
        Haptics.success()
        dismiss()
    }

    // MARK: Bits

    private func roundButton(_ icon: String, _ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon).font(.system(size: 16, weight: .bold))
                .foregroundStyle(Theme.cream)
                .frame(width: 44, height: 44)
                .background(Circle().fill(Theme.card))
        }
    }
    private func pill(_ text: String, _ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(text).font(.system(size: 14, weight: .semibold)).foregroundStyle(Theme.gold)
                .padding(.horizontal, 16).padding(.vertical, 10)
                .background(RoundedRectangle(cornerRadius: 12).fill(Theme.card))
        }
    }
    private func trim(_ v: Double) -> String { v == v.rounded() ? String(Int(v)) : String(format: "%.2f", v) }
}
