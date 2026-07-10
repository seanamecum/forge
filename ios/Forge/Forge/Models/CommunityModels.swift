import Foundation

struct SocialPost: Identifiable {
    let id = UUID()
    let author: String
    let handle: String
    let level: Int
    let time: String
    let kind: Kind
    let body: String
    var statLabel: String? = nil
    var statValue: String? = nil
    var likes: Int
    var comments: Int
    var likedByMe = false

    enum Kind: String {
        case pr = "PR", workout = "Workout", progress = "Progress", share = "Share", milestone = "Milestone"
    }
}

struct CommunityGroup: Identifiable {
    let id = UUID()
    let name: String
    let tag: String
    let members: Int
    let blurb: String
    var joined = false
}

struct Leaderboard: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let entries: [LeaderboardEntry]
}

struct LeaderboardEntry: Identifiable {
    let id = UUID()
    let rank: Int
    let name: String
    let value: String
    var isMe = false
}

struct Challenge: Identifiable {
    let id = UUID()
    let name: String
    let participants: Int
    let daysLeft: Int
    let progress: Double   // 0–1
    let reward: String
    var joined = false
}

struct Badge: Identifiable {
    let id = UUID()
    let name: String
    let detail: String
    let earned: Bool
    var earnedDate: String? = nil
}

struct Mission: Identifiable {
    let id = UUID()
    let name: String
    let detail: String
    let progress: Int
    let total: Int
    let xp: Int

    var done: Bool { progress >= total }
}

struct Team: Identifiable {
    let id = UUID()
    let name: String
    let kind: String        // School / Gym / Sports Team / Business
    let members: Int
    let avgForgeScore: Int
    let compliancePct: Int
    let atRisk: Int
    let inRehab: Int
    let prsThisWeek: Int
}

// MARK: - Marketplace

struct CoachListing: Identifiable {
    let id = UUID()
    let name: String
    let specialty: String
    let credentials: String
    let rating: Double
    let clients: Int
    let price: String
    let bio: String
}

struct ProgramListing: Identifiable {
    let id = UUID()
    let name: String
    let coach: String
    let level: String
    let price: String
    let weeks: Int
    let daysPerWeek: Int
    let focus: String
    let buyers: Int
}

struct StoreProduct: Identifiable {
    let id = UUID()
    let name: String
    let brand: String
    let price: String
    let rating: Double
    var tag: String? = nil
    let icon: String  // SF Symbol
    /// Curated shelf this product belongs to — Supplements, Recovery, Equipment…
    var category: String = "Gear"
}
