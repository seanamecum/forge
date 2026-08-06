import SwiftUI

// MARK: - Modules grid

/// "Explore Forge" — the secondary destinations, every one backed by real data.
/// (The former dashboard card zoo — ForgeScoreHero, IntelligenceCard, FuelCard,
/// etc. — was dead code and has been removed; Home composes its own cards now.)
struct ModulesGrid: View {
    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        VStack(alignment: .leading, spacing: Space.sm) {
            EyebrowLabel(text: "Explore Forge")
            LazyVGrid(columns: columns, spacing: Space.sm) {
                ModuleTile(icon: "target", title: "Goals", subtitle: "Targets · deadlines · progress") { GoalsView() }
                ModuleTile(icon: "figure.run", title: "Running", subtitle: "GPS runs · paces · splits") { RunningView() }
                ModuleTile(icon: "figure.arms.open", title: "Body", subtitle: "Weight · measurements") { BodyTrackingView() }
                ModuleTile(icon: "wand.and.stars", title: "Digital Twin", subtitle: "Your 12-week forecast") { ForecastView() }
                ModuleTile(icon: "pills.fill", title: "Supplements", subtitle: "Your stack · adherence") { SupplementsView() }
                ModuleTile(icon: "heart.fill", title: "Apple Health", subtitle: "Your data source") { WearablesView() }
            }
        }
    }
}

struct ModuleTile<Destination: View>: View {
    let icon: String
    let title: String
    let subtitle: String
    @ViewBuilder var destination: () -> Destination

    var body: some View {
        NavigationLink(destination: destination) {
            VStack(alignment: .leading, spacing: Space.sm) {
                Image(systemName: icon)
                    .font(.system(size: 19))
                    .foregroundStyle(Theme.gold)
                Text(title)
                    .font(Typography.body.weight(.semibold))
                    .foregroundStyle(Theme.cream)
                Text(subtitle)
                    .font(Typography.caption)
                    .foregroundStyle(Theme.faint)
            }
            .padding(Space.md)
            .frame(maxWidth: .infinity, minHeight: 96, alignment: .topLeading)
            .background(RoundedRectangle(cornerRadius: Radius.md).fill(Theme.cardGradient))
            .overlay(RoundedRectangle(cornerRadius: Radius.md).stroke(Theme.hairline, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}
