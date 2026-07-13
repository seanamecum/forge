import SwiftUI

/// Strava-style share card: a branded image of the finished run, rendered
/// off-screen with ImageRenderer and handed to the system share sheet.
struct RunShareCard: View {
    let distance: String
    let distanceUnit: String
    let time: String
    let pace: String
    let paceUnit: String
    let date: Date

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("FORGE")
                    .font(.system(size: 15, weight: .heavy, design: .rounded))
                    .kerning(4)
                    .foregroundStyle(Theme.gold)
                Spacer()
                Text(date.formatted(date: .abbreviated, time: .shortened))
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.muted)
            }
            Spacer()
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(distance)
                    .font(.system(size: 76, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.cream)
                Text(distanceUnit)
                    .font(.system(size: 22, weight: .semibold, design: .rounded))
                    .foregroundStyle(Theme.gold)
            }
            Text("RUN")
                .font(.system(size: 11, weight: .semibold))
                .kerning(3)
                .foregroundStyle(Theme.muted)
            Spacer()
            HStack(spacing: 28) {
                shareStat(label: "TIME", value: time)
                shareStat(label: "AVG PACE", value: "\(pace) \(paceUnit)")
            }
        }
        .padding(28)
        .frame(width: 400, height: 400, alignment: .leading)
        .background(Theme.bg)
    }

    private func shareStat(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(label)
                .font(.system(size: 10, weight: .semibold)).kerning(1.5)
                .foregroundStyle(Theme.muted)
            Text(value)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(Theme.cream)
        }
    }

    /// Render at 3× for a crisp 1200×1200 share image.
    @MainActor
    func rendered() -> Image? {
        let renderer = ImageRenderer(content: self)
        renderer.scale = 3
        guard let ui = renderer.uiImage else { return nil }
        return Image(uiImage: ui)
    }
}
