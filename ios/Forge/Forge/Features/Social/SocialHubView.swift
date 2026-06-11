import SwiftUI

struct SocialHubView: View {
    @Environment(AppState.self) private var app
    @State private var tab = 0

    var body: some View {
        ScreenScaffold {
            SectionHeader(eyebrow: "Community", title: "Social",
                          subtitle: "PRs, progress, programming wisdom — for athletes who get it.")

            Picker("", selection: $tab) {
                Text("Feed").tag(0)
                Text("Groups").tag(1)
            }
            .pickerStyle(.segmented)

            if tab == 0 {
                ForEach(app.social.feed) { post in
                    PostCard(post: post)
                }
            } else {
                ForEach(app.social.groups) { group in
                    GroupCard(group: group)
                }
            }
        }
        .navigationTitle("Social")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct PostCard: View {
    @Environment(AppState.self) private var app
    let post: SocialPost

    var body: some View {
        Card {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 10) {
                    ZStack {
                        Circle().fill(Theme.goldGradient)
                        Text(post.author.split(separator: " ").compactMap { $0.first.map(String.init) }.joined())
                            .font(.system(size: 11, weight: .bold)).foregroundStyle(Theme.bg)
                    }
                    .frame(width: 34, height: 34)

                    VStack(alignment: .leading, spacing: 1) {
                        Text(post.author).font(.system(size: 13, weight: .semibold)).foregroundStyle(Theme.cream)
                        Text("Lv \(post.level) · \(post.handle) · \(post.time)")
                            .font(.system(size: 10)).foregroundStyle(Theme.faint)
                    }
                    Spacer()
                    Chip(text: post.kind.rawValue, tone: .gold)
                }

                Text(post.body).font(.system(size: 13.5)).foregroundStyle(Theme.creamDim)

                if let label = post.statLabel, let value = post.statValue {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(label.uppercased())
                                .font(.system(size: 8.5, weight: .semibold)).kerning(1.2)
                                .foregroundStyle(Theme.gold)
                            Text(value).font(Theme.display(18)).foregroundStyle(Theme.goldGradient)
                        }
                        Spacer()
                    }
                    .padding(12)
                    .background(RoundedRectangle(cornerRadius: 10).fill(Theme.gold.opacity(0.05)))
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Theme.gold.opacity(0.2), lineWidth: 1))
                }

                HStack(spacing: 18) {
                    Button {
                        app.social.toggleLike(post)
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: post.likedByMe ? "heart.fill" : "heart")
                                .foregroundStyle(post.likedByMe ? Theme.rubyBright : Theme.muted)
                            Text("\(post.likes)").foregroundStyle(Theme.muted)
                        }
                        .font(.system(size: 12.5))
                    }
                    HStack(spacing: 5) {
                        Image(systemName: "bubble.right")
                        Text("\(post.comments)")
                    }
                    .font(.system(size: 12.5)).foregroundStyle(Theme.muted)
                    Spacer()
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 13)).foregroundStyle(Theme.muted)
                }
            }
        }
    }
}

struct GroupCard: View {
    @Environment(AppState.self) private var app
    let group: CommunityGroup

    var body: some View {
        Card {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 8) {
                        Text(group.name).font(.system(size: 14.5, weight: .semibold)).foregroundStyle(Theme.cream)
                        Chip(text: group.tag)
                    }
                    Text("\(group.members.formatted()) members").font(.system(size: 11)).foregroundStyle(Theme.faint)
                    Text(group.blurb).font(.system(size: 12)).foregroundStyle(Theme.muted)
                }
                Spacer()
                Button(group.joined ? "Joined ✓" : "Join") {
                    app.social.toggleJoin(group)
                }
                .buttonStyle(GhostButtonStyle(compact: true))
            }
        }
    }
}
