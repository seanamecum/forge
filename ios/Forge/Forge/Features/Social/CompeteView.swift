import SwiftUI

struct CompeteView: View {
    @Environment(AppState.self) private var app
    @State private var tab = 0

    var body: some View {
        ScreenScaffold {
            SectionHeader(eyebrow: "Community", title: "Compete",
                          subtitle: "Leaderboards and challenges. Pick a fight with the calendar.")

            Picker("", selection: $tab) {
                Text("Leaderboards").tag(0)
                Text("Challenges").tag(1)
            }
            .pickerStyle(.segmented)

            if tab == 0 {
                ForEach(app.social.leaderboards) { board in
                    LeaderboardCard(board: board)
                }
            } else {
                ForEach(app.social.challenges) { challenge in
                    ChallengeCard(challenge: challenge)
                }
            }
        }
        .navigationTitle("Compete")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct LeaderboardCard: View {
    let board: Leaderboard

    var body: some View {
        Card {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    VStack(alignment: .leading, spacing: 1) {
                        Text(board.title).font(.system(size: 14, weight: .semibold)).foregroundStyle(Theme.cream)
                        Text(board.subtitle).font(.system(size: 10.5)).foregroundStyle(Theme.faint)
                    }
                    Spacer()
                    Chip(text: "Friends", tone: .gold)
                }
                ForEach(board.entries) { entry in
                    HStack(spacing: 10) {
                        ZStack {
                            Circle()
                                .fill(entry.rank <= 3 ? AnyShapeStyle(Theme.goldGradient) : AnyShapeStyle(Theme.card))
                            Text("\(entry.rank)")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(entry.rank <= 3 ? Theme.bg : Theme.muted)
                        }
                        .frame(width: 24, height: 24)

                        Text(entry.name)
                            .font(.system(size: 13, weight: entry.isMe ? .semibold : .regular))
                            .foregroundStyle(entry.isMe ? Theme.goldBright : Theme.creamDim)
                        if entry.isMe { Chip(text: "You", tone: .gold) }
                        Spacer()
                        Text(entry.value)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(entry.isMe ? Theme.goldBright : Theme.cream)
                    }
                    .padding(.vertical, 3)
                    .padding(.horizontal, entry.isMe ? 8 : 0)
                    .background(
                        entry.isMe
                        ? AnyView(RoundedRectangle(cornerRadius: 8).fill(Theme.gold.opacity(0.07)))
                        : AnyView(EmptyView())
                    )
                }
            }
        }
    }
}

struct ChallengeCard: View {
    @Environment(AppState.self) private var app
    let challenge: Challenge

    var body: some View {
        Card {
            VStack(alignment: .leading, spacing: 9) {
                HStack {
                    Text(challenge.name).font(.system(size: 14, weight: .semibold)).foregroundStyle(Theme.cream)
                    Spacer()
                    Chip(text: "\(challenge.daysLeft)d left", tone: .gold)
                }
                Text("\(challenge.participants.formatted()) athletes · reward: \(challenge.reward)")
                    .font(.system(size: 11)).foregroundStyle(Theme.muted)
                CapsuleBar(value: challenge.progress, target: 1, tone: challenge.joined ? .green : .gold, height: 6)
                HStack {
                    Text("\(Int(challenge.progress * 100))% complete")
                        .font(.system(size: 10.5)).foregroundStyle(Theme.faint)
                    Spacer()
                    Button(challenge.joined ? "Joined ✓" : "Join Challenge") {
                        app.social.toggleJoin(challenge)
                    }
                    .buttonStyle(GhostButtonStyle(compact: true))
                }
            }
        }
    }
}
