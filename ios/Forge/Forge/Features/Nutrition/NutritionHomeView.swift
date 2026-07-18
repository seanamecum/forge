import SwiftUI

struct NutritionHomeView: View {
    @Environment(AppState.self) private var app
    @State private var showFoodSearch = false
    @State private var pickedMeal: MealType = .breakfast
    @State private var showScanner = false
    @State private var showPhoto = false

    var body: some View {
        NavigationStack {
            ScreenScaffold {
                SectionHeader(eyebrow: "Fuel", title: "Nutrition",
                              subtitle: "Targets adapt to your training, weight trend, recovery, and rehab — never silently.")

                coachedTargetsCard
                macroCard
                waterCard
                quickLogRow
                mealsCard
                navLinks
            }
            .navigationBarHidden(true)
            .onAppear { app.refreshFuelPlan() }
            .sheet(isPresented: $showFoodSearch) {
                FoodSearchSheet(meal: pickedMeal)
            }
            .sheet(isPresented: $showScanner) {
                BarcodeScanSheet(meal: pickedMeal)
            }
            .sheet(isPresented: $showPhoto) {
                PhotoFoodScanSheet(meal: pickedMeal)
            }
        }
    }

    /// Adaptive targets — why today's numbers are today's numbers.
    /// Base plan from your body and goal; coached deltas from live signals.
    @ViewBuilder
    private var coachedTargetsCard: some View {
        if let plan = app.nutrition.activePlan {
            Card {
                VStack(alignment: .leading, spacing: 11) {
                    HStack {
                        HStack(spacing: 6) {
                            Image(systemName: "wand.and.stars")
                                .font(.system(size: 11))
                                .foregroundStyle(Theme.gold)
                            EyebrowLabel(text: "Coached Targets · Adaptive")
                        }
                        Spacer()
                        if plan.isAdjusted {
                            Chip(text: "\(plan.adjustments.count) active", tone: .gold)
                        }
                    }
                    Text(plan.headline)
                        .font(Theme.text(13.5, .medium))
                        .foregroundStyle(Theme.cream)
                        .fixedSize(horizontal: false, vertical: true)
                    if plan.isAdjusted {
                        Text("Base \(plan.baseCalories) kcal · \(plan.baseProtein)g → today \(plan.calories) kcal · \(plan.protein)g")
                            .font(.system(size: 11.5))
                            .foregroundStyle(Theme.muted)
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(plan.adjustments) { adj in
                                HStack(alignment: .top, spacing: 9) {
                                    Chip(text: adj.label, tone: .gold)
                                    Text(adj.reason)
                                        .font(Theme.text(12))
                                        .foregroundStyle(Theme.creamDim)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                        }
                    }
                }
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Coached targets. \(plan.headline)")
        }
    }

    private var macroCard: some View {
        let n = app.nutrition
        return Card(gold: true) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .firstTextBaseline) {
                    Text("\(n.calories)")
                        .font(Theme.display(40))
                        .foregroundStyle(Theme.goldGradient)
                    Text("/ \(n.calorieTarget) kcal")
                        .font(.system(size: 13)).foregroundStyle(Theme.muted)
                    Spacer()
                    Chip(text: "\(n.caloriesRemaining) left", tone: .gold)
                }
                LabeledBar(label: "Protein", valueText: "\(n.protein) / \(n.proteinTarget) g",
                           value: Double(n.protein), target: Double(n.proteinTarget), tone: .green)
                LabeledBar(label: "Carbs", valueText: "\(n.carbs) / \(n.carbTarget) g",
                           value: Double(n.carbs), target: Double(n.carbTarget), tone: .gold)
                LabeledBar(label: "Fat", valueText: "\(n.fat) / \(n.fatTarget) g",
                           value: Double(n.fat), target: Double(n.fatTarget), tone: .amber)
            }
        }
    }

    private var waterCard: some View {
        let n = app.nutrition
        return Card {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    EyebrowLabel(text: "Hydration", tone: .royal)
                    Spacer()
                    Text("\(n.hydrationPct)%")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(n.hydrationPct < 70 ? Theme.amber : Theme.green)
                }
                CapsuleBar(value: n.waterOz, target: Double(n.waterTargetOz), tone: .royal, height: 9)
                HStack(spacing: 8) {
                    ForEach([8, 16, 24], id: \.self) { oz in
                        Button("+\(oz) oz") { app.nutrition.addWater(Double(oz)) }
                            .buttonStyle(GhostButtonStyle(compact: true))
                    }
                    Spacer()
                    Text("\(Int(n.waterOz)) / \(n.waterTargetOz) oz")
                        .font(.system(size: 11)).foregroundStyle(Theme.muted)
                }
            }
        }
    }

    private var quickLogRow: some View {
        HStack(spacing: 10) {
            CaptureButton(icon: "magnifyingglass", label: "Search") {
                pickedMeal = .snack; showFoodSearch = true
            }
            CaptureButton(icon: "barcode.viewfinder", label: "Scan") {
                pickedMeal = .snack; showScanner = true
            }
            CaptureButton(icon: "camera.fill", label: "Photo AI") {
                pickedMeal = .snack; showPhoto = true
            }
        }
    }

    private var mealsCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            EyebrowLabel(text: "Today's Meals")
            ForEach(MealType.allCases) { meal in
                MealSection(meal: meal) {
                    pickedMeal = meal
                    showFoodSearch = true
                }
            }
        }
    }

    private var navLinks: some View {
        VStack(spacing: 10) {
            NavRow(icon: "pills.fill", title: "Supplements",
                   subtitle: "\(app.nutrition.supplements.filter(\.loggedToday).count)/\(app.nutrition.supplements.count) logged today") { SupplementsView() }
            NavRow(icon: "exclamationmark.shield.fill", title: "Deficiency Detection",
                   subtitle: "\(app.nutrition.deficiencies.count) flags · Mg + D + Omega-3") { DeficienciesView() }
            NavRow(icon: "chart.bar.doc.horizontal.fill", title: "Micronutrients",
                   subtitle: "35 tracked · 7-day averages") { MicronutrientsView() }
        }
    }
}

// MARK: - Pieces

struct CaptureButton: View {
    let icon: String
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon).font(.system(size: 17)).foregroundStyle(Theme.gold)
                Text(label).font(.system(size: 11, weight: .medium)).foregroundStyle(Theme.creamDim)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 13)
            .background(RoundedRectangle(cornerRadius: 13).fill(Theme.cardGradient))
            .overlay(RoundedRectangle(cornerRadius: 13).stroke(Theme.hairline, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}

struct MealSection: View {
    @Environment(AppState.self) private var app
    let meal: MealType
    let onAdd: () -> Void

    var body: some View {
        let entries = app.nutrition.entries(for: meal)
        let kcal = entries.reduce(0) { $0 + $1.calories }
        return Card {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: meal.icon).font(.system(size: 12)).foregroundStyle(Theme.gold)
                    Text(meal.rawValue).font(.system(size: 13, weight: .semibold)).foregroundStyle(Theme.cream)
                    Spacer()
                    if kcal > 0 {
                        Text("\(kcal) kcal").font(.system(size: 11.5)).foregroundStyle(Theme.muted)
                    }
                    Button(action: onAdd) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 18)).foregroundStyle(Theme.gold)
                    }
                    .accessibilityLabel("Add food to \(meal.rawValue)")
                }
                if entries.isEmpty {
                    Text("Nothing logged").font(.system(size: 11.5)).foregroundStyle(Theme.faint)
                } else {
                    ForEach(entries) { entry in
                        HStack {
                            Text(entry.food.name).font(.system(size: 12.5)).foregroundStyle(Theme.creamDim)
                            if entry.servings != 1 {
                                Text("×\(String(format: "%g", entry.servings))")
                                    .font(.system(size: 10.5)).foregroundStyle(Theme.faint)
                            }
                            Spacer()
                            Text("\(entry.calories) · \(Int(entry.protein))P")
                                .font(.system(size: 11)).foregroundStyle(Theme.muted)
                        }
                    }
                }
            }
        }
    }
}

struct NavRow<Destination: View>: View {
    let icon: String
    let title: String
    let subtitle: String
    @ViewBuilder var destination: () -> Destination

    var body: some View {
        NavigationLink(destination: destination) {
            Card {
                HStack(spacing: 12) {
                    Image(systemName: icon).font(.system(size: 17)).foregroundStyle(Theme.gold)
                        .frame(width: 30)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(title).font(.system(size: 14, weight: .semibold)).foregroundStyle(Theme.cream)
                        Text(subtitle).font(.system(size: 11)).foregroundStyle(Theme.muted)
                    }
                    Spacer()
                    Image(systemName: "chevron.right").font(.system(size: 11)).foregroundStyle(Theme.faint)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Sheets

struct FoodSearchSheet: View {
    @Environment(AppState.self) private var app
    @Environment(\.dismiss) private var dismiss
    let meal: MealType
    @State private var query = ""

    var body: some View {
        NavigationStack {
            List(app.nutrition.search(query)) { food in
                Button {
                    app.nutrition.add(food: food, to: meal)
                    dismiss()
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(food.name).font(.system(size: 14, weight: .medium)).foregroundStyle(Theme.cream)
                            Text("\(food.brand.map { "\($0) · " } ?? "")\(food.serving)")
                                .font(.system(size: 11)).foregroundStyle(Theme.muted)
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("\(food.calories)").font(.system(size: 14, weight: .semibold)).foregroundStyle(Theme.gold)
                            Text("\(Int(food.protein))P \(Int(food.carbs))C \(Int(food.fat))F")
                                .font(.system(size: 10)).foregroundStyle(Theme.faint)
                        }
                    }
                }
                .listRowBackground(Theme.card)
            }
            .scrollContentBackground(.hidden)
            .background(Theme.bg)
            .searchable(text: $query, prompt: "Search foods")
            .overlay {
                if !query.isEmpty && app.nutrition.search(query).isEmpty {
                    EmptyStateView(
                        icon: "magnifyingglass",
                        title: "No foods match \"\(query)\"",
                        message: "Try the barcode scanner — it knows about 3 million products.")
                }
            }
            .navigationTitle("Add to \(meal.rawValue)")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

