import SwiftUI

struct MarketplaceView: View {
    @Environment(AppState.self) private var app
    @State private var tab = 0

    var body: some View {
        ScreenScaffold {
            SectionHeader(eyebrow: "Performance Marketplace", title: "Coaches · Programs · Gear",
                          subtitle: "A curated layer, not a store: vetted humans, proven programs, and gear matched to your goal and your device stack.")

            Picker("", selection: $tab) {
                Text("Coaches").tag(0)
                Text("Programs").tag(1)
                Text("Store").tag(2)
            }
            .pickerStyle(.segmented)

            switch tab {
            case 0:
                ForEach(app.marketplace.coaches) { coach in CoachCardView(coach: coach) }
            case 1:
                ForEach(app.marketplace.programs) { program in ProgramCardView(program: program) }
            default:
                storeSection
            }
        }
        .navigationTitle("Marketplace")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Store (curated shelves + partner rail + Forge collection)

    @ViewBuilder
    private var storeSection: some View {
        partnerRail

        let grouped = Dictionary(grouping: app.marketplace.products, by: \.category)
        ForEach(["Supplements", "Recovery", "Equipment", "Apparel"], id: \.self) { category in
            if let items = grouped[category], !items.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    EyebrowLabel(text: category)
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                        ForEach(items) { product in ProductCardView(product: product) }
                    }
                }
            }
        }

        forgeCollectionCard
    }

    /// Featured device partners — matched to the athlete's goal via the DataHub,
    /// with placeholder slots for future sponsored partnerships.
    private var partnerRail: some View {
        let stack = DataHub.recommendedStack(for: app.user.primaryGoal)
            .filter { !app.connectedSources.contains($0) }
        let featured = stack.isEmpty ? [DataSource.whoop, .garmin] : Array(stack.prefix(3))
        return Card(gold: true) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    EyebrowLabel(text: "Featured Partners")
                    Spacer()
                    Chip(text: app.user.primaryGoal.rawValue, tone: .gold)
                }
                Text("Devices that would sharpen YOUR Forge Score — matched to your goal, not to ad spend. Partner offers land here at launch.")
                    .font(.system(size: 11.5)).foregroundStyle(Theme.muted)
                ForEach(featured) { source in
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "sparkle")
                            .font(.system(size: 11)).foregroundStyle(Theme.gold)
                            .padding(.top, 3)
                        VStack(alignment: .leading, spacing: 2) {
                            HStack(spacing: 6) {
                                Text(source.displayName)
                                    .font(.system(size: 13, weight: .semibold)).foregroundStyle(Theme.cream)
                                Chip(text: "Partner slot", tone: .neutral)
                            }
                            Text(source.pitch)
                                .font(.system(size: 11.5)).foregroundStyle(Theme.muted)
                                .fixedSize(horizontal: false, vertical: true)
                            if !DataHub.fillsGap(source, connected: app.connectedSources).isEmpty {
                                Text("Fills your gap: \(DataHub.fillsGap(source, connected: app.connectedSources).map { $0.label.lowercased() }.joined(separator: ", "))")
                                    .font(.system(size: 11, weight: .medium)).foregroundStyle(Theme.gold)
                            }
                        }
                        Spacer()
                        ComingSoonButton("Offer", feature: "Partner device offers")
                    }
                }
            }
        }
    }

    /// The Forge-branded line — phase 3 of the ecosystem roadmap.
    private var forgeCollectionCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Image(systemName: "flame.fill").foregroundStyle(Theme.goldGradient)
                    Text("Forge Collection").font(Theme.display(17)).foregroundStyle(Theme.cream)
                    Spacer()
                    Chip(text: "Coming Soon", tone: .gold)
                }
                Text("Forge-designed training gear, recovery tools, and apparel — and eventually the Forge Band. Built to the same standard as the software; sold only when they earn a place in your stack.")
                    .font(.system(size: 12)).foregroundStyle(Theme.creamDim)
                    .fixedSize(horizontal: false, vertical: true)
                WaitlistButton(feature: "Forge Collection")
            }
        }
    }
}

struct CoachCardView: View {
    let coach: CoachListing

    var body: some View {
        Card {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 11) {
                    ZStack {
                        Circle().fill(Theme.goldGradient)
                        Text(coach.name.split(separator: " ").compactMap { $0.first.map(String.init) }.prefix(2).joined())
                            .font(.system(size: 13, weight: .bold)).foregroundStyle(Theme.bg)
                    }
                    .frame(width: 42, height: 42)
                    VStack(alignment: .leading, spacing: 1) {
                        Text(coach.name).font(.system(size: 14, weight: .semibold)).foregroundStyle(Theme.cream)
                        Text("\(coach.specialty) · \(coach.credentials)")
                            .font(.system(size: 11)).foregroundStyle(Theme.gold)
                    }
                    Spacer()
                    Text(coach.price).font(.system(size: 13, weight: .semibold)).foregroundStyle(Theme.goldBright)
                }
                Text(coach.bio).font(.system(size: 12)).foregroundStyle(Theme.muted)
                HStack {
                    Text("★ \(String(format: "%.2f", coach.rating)) · \(coach.clients) athletes")
                        .font(.system(size: 11)).foregroundStyle(Theme.creamDim)
                    Spacer()
                    ComingSoonButton("Book intro", feature: "Coach booking")
                }
            }
        }
    }
}

struct ProgramCardView: View {
    let program: ProgramListing

    var body: some View {
        Card {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(program.name).font(.system(size: 14.5, weight: .semibold)).foregroundStyle(Theme.cream)
                    Spacer()
                    Text(program.price).font(.system(size: 14, weight: .semibold)).foregroundStyle(Theme.goldBright)
                }
                Text("by \(program.coach) · \(program.level)")
                    .font(.system(size: 11)).foregroundStyle(Theme.gold)
                Text(program.focus).font(.system(size: 12)).foregroundStyle(Theme.muted)
                HStack(spacing: 8) {
                    Chip(text: "\(program.weeks) wks")
                    Chip(text: "\(program.daysPerWeek)x / wk")
                    Chip(text: "\(program.buyers.formatted()) sold", tone: .gold)
                    Spacer()
                    ComingSoonButton("Get", feature: "Program purchase")
                }
            }
        }
    }
}

struct ProductCardView: View {
    let product: StoreProduct

    var body: some View {
        Card {
            VStack(alignment: .leading, spacing: 7) {
                HStack {
                    Image(systemName: product.icon)
                        .font(.system(size: 20)).foregroundStyle(Theme.gold)
                    Spacer()
                    if let tag = product.tag { Chip(text: tag, tone: .gold) }
                }
                Text(product.name).font(.system(size: 12.5, weight: .semibold)).foregroundStyle(Theme.cream)
                Text(product.brand).font(.system(size: 10.5)).foregroundStyle(Theme.muted)
                HStack {
                    Text("★ \(String(format: "%.1f", product.rating))")
                        .font(.system(size: 10.5)).foregroundStyle(Theme.creamDim)
                    Spacer()
                    Text(product.price).font(.system(size: 13, weight: .semibold)).foregroundStyle(Theme.goldBright)
                }
            }
        }
    }
}
