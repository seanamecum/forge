import SwiftUI

struct NotificationsView: View {
    @Environment(AppState.self) private var app

    var body: some View {
        ScreenScaffold {
            HStack {
                SectionHeader(eyebrow: "Daily", title: "Notifications",
                              subtitle: "Only what moves the needle.")
                if app.notifications.items.contains(where: { !$0.read }) {
                    Button("Mark all read") { Haptics.tap(); app.notifications.markAllRead() }
                        .font(Typography.subheadline.weight(.medium))
                        .foregroundStyle(Theme.gold)
                }
            }

            if app.notifications.items.isEmpty {
                EmptyStateView(
                    icon: "bell.badge",
                    title: "You're all caught up",
                    message: "Forge only pings you when something moves the needle — a recovery drop, a protein gap, a streak at risk. New alerts land here.")
            }

            ForEach(app.notifications.items) { item in
                Card {
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: item.kind.icon)
                            .font(.system(size: 15))
                            .foregroundStyle(item.kind.tone.color)
                            .frame(width: 34, height: 34)
                            .background(Circle().fill(item.kind.tone.color.opacity(0.08)))
                            .overlay(Circle().stroke(item.kind.tone.color.opacity(0.3), lineWidth: 1))

                        VStack(alignment: .leading, spacing: 3) {
                            HStack {
                                Text(item.title)
                                    .font(Typography.callout.weight(item.read ? .regular : .semibold))
                                    .foregroundStyle(item.read ? Theme.creamDim : Theme.cream)
                                Spacer()
                                Text(item.time).font(.system(size: 10)).foregroundStyle(Theme.faint)
                            }
                            Text(item.body).font(.system(size: 12)).foregroundStyle(Theme.muted)
                        }

                        if !item.read {
                            Circle().fill(Theme.gold).frame(width: 7, height: 7)
                                .shadow(color: Theme.gold.opacity(0.6), radius: 4)
                        }
                    }
                }
                .opacity(item.read ? 0.78 : 1)
            }
        }
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.inline)
    }
}
