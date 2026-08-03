import SwiftUI

/// Log a searched food at a chosen quantity — the fast, grams-canonical add flow.
/// A thin shell over the tested `QuantityEditorEngine`: unit chips, +/- steps, live
/// macros, and one "Add" tap. Pre-fills the user's remembered serving for this food.
struct LogFoodSheet: View {
    @Environment(AppState.self) private var app
    @Environment(\.dismiss) private var dismiss

    let food: CanonicalFood
    let meal: MealType
    var onLogged: () -> Void = {}

    @State private var engine: QuantityEditorEngine
    @State private var amountText: String

    init(food: CanonicalFood, meal: MealType, onLogged: @escaping () -> Void = {}) {
        self.food = food
        self.meal = meal
        self.onLogged = onLogged
        let remembered = FoodQuantityMemory().last(foodID: food.id)
        let e = QuantityEditorEngine(food: food, remembering: remembered)
        _engine = State(initialValue: e)
        _amountText = State(initialValue: Self.trim(e.amount))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bgElevated.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        header
                        amountField
                        stepperRow
                        unitChips
                        if engine.isEstimatedConversion {
                            Label("Estimated conversion.", systemImage: "exclamationmark.triangle")
                                .font(.system(size: 11.5)).foregroundStyle(Theme.amber)
                        }
                        macroReadout
                        Spacer(minLength: 8)
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Add to \(meal.rawValue)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { Button("Cancel") { dismiss() }.foregroundStyle(Theme.gold) }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Add") { add() }.foregroundStyle(Theme.gold).fontWeight(.semibold)
                        .disabled(!engine.isValid || engine.nutrients == nil)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .preferredColorScheme(.dark)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(food.name).font(Theme.display(20)).foregroundStyle(Theme.cream)
            HStack(spacing: 6) {
                if let brand = food.brand { Text(brand).font(.system(size: 12)).foregroundStyle(Theme.muted) }
                SourceBadge(food: food)
            }
        }
    }

    private var amountField: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            TextField("1", text: $amountText)
                .keyboardType(.numbersAndPunctuation)
                .font(Theme.display(40)).foregroundStyle(Theme.cream).fixedSize()
                .onChange(of: amountText) { _, t in if let v = QuantityParser.parse(t) { engine.setAmount(v) } }
            Text(engine.unit.label).font(.system(size: 17)).foregroundStyle(Theme.gold)
            Spacer()
        }
        .padding(.vertical, 6)
    }

    private var stepperRow: some View {
        HStack(spacing: 10) {
            round("minus") { engine.decrement(); syncText() }
            round("plus") { engine.increment(); syncText() }
            Spacer()
            pill("½×") { engine.scale(by: 0.5); syncText() }
            pill("2×") { engine.scale(by: 2); syncText() }
        }
    }

    private var unitChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(engine.availableUnits) { unit in
                    let selected = unit.id == engine.unitID
                    Button {
                        Haptics.tap(); engine.switchUnit(to: unit.id); syncText()
                    } label: {
                        Text(unit.label).font(.system(size: 13, weight: .medium))
                            .padding(.horizontal, 14).padding(.vertical, 8)
                            .background(RoundedRectangle(cornerRadius: 10).fill(selected ? Theme.gold.opacity(0.2) : Theme.card))
                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(selected ? Theme.gold : .clear, lineWidth: 1))
                            .foregroundStyle(selected ? Theme.gold : Theme.creamDim)
                    }
                }
            }
        }
    }

    private var macroReadout: some View {
        let n = engine.nutrients
        return Card {
            HStack {
                macro("kcal", n?[.calories], accent: true)
                Divider().frame(height: 30).overlay(Theme.faint.opacity(0.3))
                macro("P", n?[.protein]); macro("C", n?[.carbs]); macro("F", n?[.fat])
            }
        }
        .animation(.snappy(duration: 0.18), value: engine.amount)
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

    private func add() {
        app.logFood(food, quantity: engine.quantity, meal: meal)
        Haptics.success(); onLogged(); dismiss()
    }
    private func syncText() { amountText = Self.trim(engine.amount) }

    private func round(_ icon: String, _ a: @escaping () -> Void) -> some View {
        Button(action: a) { Image(systemName: icon).font(.system(size: 16, weight: .bold)).foregroundStyle(Theme.cream)
            .frame(width: 44, height: 44).background(Circle().fill(Theme.card)) }
    }
    private func pill(_ t: String, _ a: @escaping () -> Void) -> some View {
        Button(action: a) { Text(t).font(.system(size: 14, weight: .semibold)).foregroundStyle(Theme.gold)
            .padding(.horizontal, 16).padding(.vertical, 10).background(RoundedRectangle(cornerRadius: 12).fill(Theme.card)) }
    }
    private static func trim(_ v: Double) -> String { v == v.rounded() ? String(Int(v)) : String(format: "%.2f", v) }
}

/// A small source + confidence badge — Verified / USDA / Open Food Facts / Yours.
struct SourceBadge: View {
    let food: CanonicalFood
    var body: some View {
        HStack(spacing: 4) {
            Circle().fill(food.isLowConfidence ? Theme.amber : Theme.green).frame(width: 5, height: 5)
            Text(food.source.label).font(.system(size: 9.5, weight: .medium)).foregroundStyle(Theme.faint)
        }
        .padding(.horizontal, 6).padding(.vertical, 2)
        .background(RoundedRectangle(cornerRadius: 5).fill(Theme.card))
    }
}
