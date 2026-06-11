import Foundation
import Observation

@Observable
final class SocialService {
    var feed: [SocialPost] = MockData.feed
    var groups: [CommunityGroup] = MockData.groups
    var leaderboards: [Leaderboard] = MockData.leaderboards
    var challenges: [Challenge] = MockData.challenges
    var badges: [Badge] = MockData.badges
    var missions: [Mission] = MockData.missions
    var teams: [Team] = MockData.teams

    func toggleLike(_ post: SocialPost) {
        guard let idx = feed.firstIndex(where: { $0.id == post.id }) else { return }
        feed[idx].likedByMe.toggle()
        feed[idx].likes += feed[idx].likedByMe ? 1 : -1
    }

    func toggleJoin(_ group: CommunityGroup) {
        guard let idx = groups.firstIndex(where: { $0.id == group.id }) else { return }
        groups[idx].joined.toggle()
    }

    func toggleJoin(_ challenge: Challenge) {
        guard let idx = challenges.firstIndex(where: { $0.id == challenge.id }) else { return }
        challenges[idx].joined.toggle()
    }

    var earnedBadgeCount: Int { badges.filter(\.earned).count }
}
