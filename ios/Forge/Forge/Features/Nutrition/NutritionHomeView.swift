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
                   subtitle: supplementsSubtitle) { SupplementsView() }
            NavRow(icon: "exclamationmark.shield.fill", title: "Deficiency Detection",
                   subtitle: deficiencySubtitle) { DeficienciesView() }
            NavRow(icon: "chart.bar.doc.horizontal.fill", title: "Micronutrients",
                   subtitle: micronutrientSubtitle) { MicronutrientsView() }
        }
    }

    private var supplementsSubtitle: String {
        let stack = app.nutrition.supplements
        guard !stack.isEmpty else { return "Build your stack" }
        return "\(stack.filter(\.loggedToday).count)/\(stack.count) logged today"
    }

    private var deficiencySubtitle: String {
        let defs = app.nutrition.deficiencies
        if defs.isEmpty {
            return app.nutrition.bloodwork.isEmpty ? "Add bloodwork to detect" : "No flags — all optimal"
        }
        let names = defs.prefix(3).map(\.nutrient).joined(separator: " · ")
        return "\(defs.count) flag\(defs.count == 1 ? "" : "s") · \(names)"
    }

    private var micronutrientSubtitle: String {
        let groups = app.nutrition.nutrientGroups
        guard !groups.isEmpty else { return "Log intake to track" }
        let count = groups.reduce(0) { $0 + $1.items.count }
        return "\(count) tracked · 7-day averages"
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
    @State private var editing: FoodEntry?

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
                        Button { editing = entry } label: {
                            HStack {
                                Text(entry.food.name).font(.system(size: 12.5)).foregroundStyle(Theme.creamDim)
                                if entry.food.serving != "serving" && !entry.food.serving.isEmpty {
                                    Text(entry.food.serving)
                                        .font(.system(size: 10.5)).foregroundStyle(Theme.faint)
                                }
                                Spacer()
                                Text("\(entry.calories) · \(Int(entry.protein))P")
                                    .font(.system(size: 11)).foregroundStyle(Theme.muted)
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .contextMenu {
                            Button { editing = entry } label: { Label("Edit quantity", systemImage: "slider.horizontal.3") }
                            Button { app.duplicateDiaryEntry(entry) } label: { Label("Duplicate", systemImage: "plus.square.on.square") }
                            Menu {
                                ForEach(MealType.allCases.filter { $0 != meal }) { m in
                                    Button(m.rawValue) { app.moveDiaryEntry(entry, toMeal: m) }
                                }
                            } label: { Label("Move to", systemImage: "arrow.right.arrow.left") }
                            Button(role: .destructive) { app.nutrition.remove(entry) } label: { Label("Delete", systemImage: "trash") }
                        }
                    }
                }
            }
        }
        .sheet(item: $editing) { QuantityEditorSheet(entry: $0) }
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

/// The unified, real food search — local-first instant results + Open Food Facts,
/// merged/deduped/ranked with the user's own history, with source badges and a
/// quantity picker. When idle it shows the proactive "usual meal" + recents.
struct FoodSearchSheet: View {
    @Environment(AppState.self) private var app
    @Environment(\.dismiss) private var dismiss
    let meal: MealType

    @State private var query = ""
    @State private var results: [CanonicalFood] = []
    @State private var searching = false
    @State private var searchTask: Task<Void, Never>?
    @State private var picking: CanonicalFood?

    private var isIdle: Bool { query.trimmingCharacters(in: .whitespaces).isEmpty }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                if isIdle { idleSuggestions } else { resultsList }
            }
            .searchable(text: $query, prompt: "Search foods")
            .onChange(of: query) { _, q in runSearch(q) }
            .navigationTitle("Add to \(meal.rawValue)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Done") { dismiss() }.foregroundStyle(Theme.gold) } }
            .sheet(item: $picking) { food in
                LogFoodSheet(food: food, meal: meal, onLogged: { dismiss() })
            }
        }
    }

    // MARK: Idle — proactive suggestions + recents

    private var idleSuggestions: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                ForEach(app.mealSuggestions(for: meal)) { s in usualMealCard(s) }

                let recents = app.recentLoggedFoods()
                if !recents.isEmpty {
                    EyebrowLabel(text: "Recents").padding(.top, 4)
                    ForEach(recents, id: \.foodID) { r in
                        oneTapRow(name: r.foodName) { app.logRecentFood(foodID: r.foodID, into: meal); dismiss() }
                    }
                }

                EyebrowLabel(text: "Common foods").padding(.top, 4)
                ForEach(CommonFoods.all.prefix(12)) { food in resultRow(food) }
            }
            .padding(16)
        }
    }

    private func usualMealCard(_ s: MealSuggestion) -> some View {
        Card(gold: true) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    Image(systemName: "sparkles").font(.system(size: 12)).foregroundStyle(Theme.gold)
                    Text(s.title).font(.system(size: 14, weight: .semibold)).foregroundStyle(Theme.cream)
                }
                Text(s.reason).font(.system(size: 11.5)).foregroundStyle(Theme.muted)
                    .fixedSize(horizontal: false, vertical: true)
                Button {
                    app.logRememberedMeal(s, into: meal); Haptics.success(); dismiss()
                } label: { Label("Log it", systemImage: "plus.circle.fill") }
                    .buttonStyle(GoldButtonStyle(compact: true))
            }
        }
    }

    // MARK: Results

    private var resultsList: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                ForEach(results) { food in resultRow(food) }
                if searching {
                    HStack(spacing: 8) { ProgressView().controlSize(.small).tint(Theme.gold)
                        Text("Searching…").font(.system(size: 11.5)).foregroundStyle(Theme.muted) }
                        .padding(.top, 6)
                } else if results.isEmpty {
                    EmptyStateView(icon: "magnifyingglass", title: "No matches for \"\(query)\"",
                                   message: "Scan a barcode, or create the food in a few seconds.")
                        .padding(.top, 24)
                }
            }
            .padding(16)
        }
    }

    private func resultRow(_ food: CanonicalFood) -> some View {
        Button { picking = food } label: {
            Card {
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(food.name).font(.system(size: 14, weight: .medium)).foregroundStyle(Theme.cream)
                            .lineLimit(1)
                        HStack(spacing: 6) {
                            if let b = food.brand { Text(b).font(.system(size: 10.5)).foregroundStyle(Theme.muted).lineLimit(1) }
                            SourceBadge(food: food)
                        }
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 1) {
                        Text("\(Int((food.per100g[.calories] ?? 0).rounded()))")
                            .font(.system(size: 14, weight: .semibold)).foregroundStyle(Theme.gold)
                        Text("kcal/100g").font(.system(size: 8.5)).foregroundStyle(Theme.faint)
                    }
                }
            }
        }
        .buttonStyle(.plain)
    }

    private func oneTapRow(name: String, _ action: @escaping () -> Void) -> some View {
        Button(action: { Haptics.tap(); action() }) {
            Card {
                HStack {
                    Text(name).font(.system(size: 13.5)).foregroundStyle(Theme.creamDim)
                    Spacer()
                    Image(systemName: "arrow.uturn.left.circle").font(.system(size: 15)).foregroundStyle(Theme.gold)
                }
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: Search

    private func runSearch(_ q: String) {
        searchTask?.cancel()
        guard !q.trimmingCharacters(in: .whitespaces).isEmpty else { results = []; searching = false; return }
        results = app.localFoodResults(q)          // instant local-first
        searching = true
        searchTask = Task {
            try? await Task.sleep(for: .milliseconds(250))   // debounce network
            guard !Task.isCancelled else { return }
            let full = await app.searchFoods(q)
            guard !Task.isCancelled else { return }
            results = full
            searching = false
        }
    }
}

