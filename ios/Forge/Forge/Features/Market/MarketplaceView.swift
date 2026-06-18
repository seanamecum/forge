import SwiftUI

struct MarketplaceView: View {
    @Environment(AppState.self) private var app
    @State private var tab = 0

    var body: some View {
        ScreenScaffold {
            SectionHeader(eyebrow: "Marketplace", title: "Coaches · Programs · Gear",
                          subtitle: "Vetted humans, real programs, gear we actually use.")

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
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    ForEach(app.marketplace.products) { product in ProductCardView(product: product) }
                }
            }
        }
        .navigationTitle("Marketplace")
        .navigationBarTitleDisplayMode(.inline)
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
