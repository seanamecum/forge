import SwiftUI

struct AchievementsView: View {
    @Environment(AppState.self) private var app

    var body: some View {
        ScreenScaffold {
            SectionHeader(eyebrow: "Community", title: "Achievements",
                          subtitle: "XP, streaks, badges, missions — the dopamine layer.")

            levelCard
            missionsCard
            badgesGrid
        }
        .navigationTitle("Achievements")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var levelCard: some View {
        let u = app.user
        return Card(gold: true) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        EyebrowLabel(text: "Level")
                        Text("Lv \(u.level)").font(Theme.display(34)).foregroundStyle(Theme.goldGradient)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        EyebrowLabel(text: "Streak")
                        HStack(spacing: 4) {
                            Image(systemName: "flame.fill").foregroundStyle(Theme.gold)
                            Text("\(u.streakDays)").font(Theme.display(34)).foregroundStyle(Theme.cream)
                        }
                    }
                }
                CapsuleBar(value: Double(u.xp), target: Double(u.xpToNext), tone: .gold, height: 9)
                Text("\(u.xp.formatted()) / \(u.xpToNext.formatted()) XP · \((u.xpToNext - u.xp).formatted()) to Lv \(u.level + 1)")
                    .font(.system(size: 11)).foregroundStyle(Theme.muted)
            }
        }
    }

    private var missionsCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 12) {
                EyebrowLabel(text: "Active Missions")
                ForEach(app.social.missions) { mission in
                    VStack(alignment: .leading, spacing: 5) {
                        HStack {
                            Text(mission.name).font(.system(size: 13, weight: .semibold)).foregroundStyle(Theme.cream)
                            Spacer()
                            Chip(text: "+\(mission.xp) XP", tone: mission.done ? .green : .gold)
                        }
                        Text(mission.detail).font(.system(size: 11)).foregroundStyle(Theme.muted)
                        HStack(spacing: 8) {
                            CapsuleBar(value: Double(mission.progress), target: Double(mission.total),
                                       tone: mission.done ? .green : .gold, height: 5)
                            Text("\(mission.progress)/\(mission.total)")
                                .font(.system(size: 10.5)).foregroundStyle(Theme.faint)
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
        }
    }

    private var badgesGrid: some View {
        Card {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    EyebrowLabel(text: "Badges")
                    Spacer()
                    Text("\(app.social.earnedBadgeCount) of \(app.social.badges.count) earned")
                        .font(.system(size: 11)).foregroundStyle(Theme.muted)
                }
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(app.social.badges) { badge in
                        VStack(spacing: 6) {
                            ZStack {
                                Circle()
                                    .fill(badge.earned ? AnyShapeStyle(Theme.goldGradient) : AnyShapeStyle(Theme.card))
                                    .frame(width: 48, height: 48)
                                    .overlay(Circle().stroke(badge.earned ? Theme.gold.opacity(0.5) : Theme.hairline, lineWidth: 1))
                                Image(systemName: badge.earned ? "star.fill" : "lock.fill")
                                    .font(.system(size: 17))
                                    .foregroundStyle(badge.earned ? Theme.bg : Theme.faint)
                            }
                            .shadow(color: badge.earned ? Theme.gold.opacity(0.3) : .clear, radius: 8)
                            Text(badge.name)
                                .font(.system(size: 10.5, weight: .medium))
                                .foregroundStyle(badge.earned ? Theme.cream : Theme.faint)
                                .multilineTextAlignment(.center)
                            Text(badge.earnedDate ?? badge.detail)
                                .font(.system(size: 8.5))
                                .foregroundStyle(Theme.faint)
                                .multilineTextAlignment(.center)
                                .lineLimit(2)
                        }
                    }
                }
            }
        }
    }
}
