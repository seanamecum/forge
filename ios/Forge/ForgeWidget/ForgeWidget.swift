import WidgetKit
import SwiftUI

// The Forge home-screen widget: today's Directive at a glance — score,
// the call, and the plan. Reads the snapshot the app publishes; renders a
// built-in placeholder until the app has run once.

@main
struct ForgeWidgetBundle: WidgetBundle {
    var body: some Widget {
        ForgeDirectiveWidget()
        ForgeWorkoutLiveActivity()
    }
}

struct ForgeDirectiveWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "ForgeDirectiveWidget", provider: DirectiveProvider()) { entry in
            DirectiveWidgetView(snapshot: entry.snapshot)
                .containerBackground(for: .widget) { WidgetTheme.bg }
        }
        .configurationDisplayName("Today's Directive")
        .description("Your Forge Score and today's plan — what to do, at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Timeline

struct DirectiveEntry: TimelineEntry {
    let date: Date
    let snapshot: WidgetSnapshot
}

struct DirectiveProvider: TimelineProvider {
    func placeholder(in context: Context) -> DirectiveEntry {
        DirectiveEntry(date: .now, snapshot: .placeholder)
    }

    func getSnapshot(in context: Context, completion: @escaping (DirectiveEntry) -> Void) {
        completion(DirectiveEntry(date: .now, snapshot: WidgetBridge.load() ?? .placeholder))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<DirectiveEntry>) -> Void) {
        let entry = DirectiveEntry(date: .now, snapshot: WidgetBridge.load() ?? .placeholder)
        // The app pushes reloads on every dashboard refresh; refresh hourly as a floor.
        let next = Calendar.current.date(byAdding: .hour, value: 1, to: .now) ?? .now
        completion(Timeline(entries: [entry], policy: .after(next)))
    }
}

// MARK: - Theme (self-contained — the widget carries its own brand tokens)

enum WidgetTheme {
    static let bg = Color(red: 0.020, green: 0.024, blue: 0.031)
    static let cream = Color(red: 0.957, green: 0.925, blue: 0.847)
    static let creamDim = Color(red: 0.812, green: 0.769, blue: 0.659)
    static let muted = Color(red: 0.545, green: 0.576, blue: 0.659)
    static let gold = Color(red: 0.831, green: 0.686, blue: 0.216)
    static let goldBright = Color(red: 0.961, green: 0.863, blue: 0.478)
}

// MARK: - Views

struct DirectiveWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let snapshot: WidgetSnapshot

    var body: some View {
        switch family {
        case .systemMedium: medium
        default: small
        }
    }

    private var scoreBlock: some View {
        VStack(spacing: 1) {
            Text("\(snapshot.forgeScore)")
                .font(.system(size: 30, weight: .bold, design: .serif))
                .foregroundStyle(WidgetTheme.goldBright)
            Text("FORGE")
                .font(.system(size: 7, weight: .semibold))
                .kerning(1.4)
                .foregroundStyle(WidgetTheme.muted)
        }
    }

    private var small: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                scoreBlock
                Spacer()
                Image(systemName: "sparkles")
                    .font(.system(size: 11))
                    .foregroundStyle(WidgetTheme.gold)
            }
            Spacer(minLength: 0)
            Text(snapshot.headline)
                .font(.system(size: 13, weight: .semibold, design: .serif))
                .foregroundStyle(WidgetTheme.cream)
                .lineLimit(3)
                .minimumScaleFactor(0.8)
        }
    }

    private var medium: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                scoreBlock
                Spacer(minLength: 0)
                Text(snapshot.headline)
                    .font(.system(size: 13.5, weight: .semibold, design: .serif))
                    .foregroundStyle(WidgetTheme.cream)
                    .lineLimit(3)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            VStack(alignment: .leading, spacing: 6) {
                ForEach(snapshot.rows.prefix(3), id: \.label) { row in
                    HStack(spacing: 6) {
                        Image(systemName: row.icon)
                            .font(.system(size: 9))
                            .foregroundStyle(WidgetTheme.gold)
                            .frame(width: 12)
                        VStack(alignment: .leading, spacing: 0) {
                            Text(row.label.uppercased())
                                .font(.system(size: 7, weight: .semibold))
                                .kerning(0.8)
                                .foregroundStyle(WidgetTheme.muted)
                            Text(row.value)
                                .font(.system(size: 10.5, weight: .medium))
                                .foregroundStyle(WidgetTheme.creamDim)
                                .lineLimit(1)
                                .minimumScaleFactor(0.75)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
