import SwiftUI

/// The full nutrition-facts screen for a food at a chosen quantity — Forge's
/// Cronometer-beating detail: every known macro, fat, mineral, and vitamin with
/// %DV, plus honest source + coverage. Read-only; logging stays in LogFoodSheet.
struct FoodDetailView: View {
    @Environment(AppState.self) private var app
    let food: CanonicalFood
    var quantity: FoodQuantity? = nil

    private var q: FoodQuantity { quantity ?? app.defaultQuantity(for: food) }
    private var resolved: (nutrients: NutrientVector?, resolution: GramResolution) { food.nutrients(for: q) }
    private var vector: NutrientVector { resolved.nutrients ?? food.per100g }

    var body: some View {
        ScreenScaffold {
            header
            ForEach(NutritionFacts.sections(vector)) { section in
                Card {
                    VStack(alignment: .leading, spacing: 0) {
                        EyebrowLabel(text: section.title)
                        ForEach(Array(section.rows.enumerated()), id: \.element.id) { i, row in
                            factRow(row)
                            if i < section.rows.count - 1 {
                                Divider().overlay(Theme.hairline).padding(.leading, 0)
                            }
                        }
                    }
                }
            }
            sourceFooter
        }
        .navigationTitle("Nutrition Facts")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var header: some View {
        Card(gold: true) {
            VStack(alignment: .leading, spacing: 8) {
                Text(food.name).font(Typography.title3).foregroundStyle(Theme.cream)
                    .fixedSize(horizontal: false, vertical: true)
                HStack(spacing: 6) {
                    if let brand = food.brand {
                        Text(brand).font(Typography.footnote).foregroundStyle(Theme.muted)
                    }
                    SourceBadge(food: food)
                    if food.verified {
                        Label("Verified", systemImage: "checkmark.seal.fill")
                            .font(Typography.caption).foregroundStyle(Theme.green)
                    }
                }
                Text(servingLine).font(Typography.footnote).foregroundStyle(Theme.creamDim)
            }
        }
    }

    private func factRow(_ row: NutritionFacts.Row) -> some View {
        HStack {
            Text(row.name).font(Typography.body).foregroundStyle(Theme.creamDim)
            Spacer()
            Text(row.amount).font(Typography.body.weight(.medium)).foregroundStyle(Theme.cream)
                .monospacedDigit()
            if let pct = row.percentDV {
                Text("\(pct)%").font(Typography.caption).foregroundStyle(Theme.gold)
                    .monospacedDigit().frame(width: 46, alignment: .trailing)
            } else {
                Spacer().frame(width: 46)
            }
        }
        .padding(.vertical, 9)
    }

    private var sourceFooter: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Source: \(food.source.label) · \(Int((food.confidence * 100).rounded()))% confidence")
                .font(Typography.caption).foregroundStyle(Theme.faint)
            if food.completeness < 0.85 {
                Text("Some nutrients aren't in this food's data yet — they'll fill in as labels improve.")
                    .font(Typography.caption).foregroundStyle(Theme.faint)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.top, 2)
    }

    private var servingLine: String {
        guard let unit = food.unit(id: q.unitID) else { return "Per serving" }
        let amount = q.amount == q.amount.rounded() ? String(Int(q.amount)) : String(format: "%.2f", q.amount)
        if let g = resolved.resolution.grams {
            return "Per \(amount) \(unit.label) · \(Int(g.rounded())) g"
        }
        return "Per \(amount) \(unit.label)"
    }
}
