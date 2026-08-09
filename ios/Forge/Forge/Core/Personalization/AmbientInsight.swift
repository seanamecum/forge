import Foundation

/// Where an insight surfaces — anchoring it to the moment so intelligence feels
/// contextual and almost invisible, never a separate "AI screen".
enum InsightSurface: String, Codable, Sendable {
    case home            // one quiet line on the dashboard
    case diary           // while logging food ("This is your usual breakfast")
    case preWorkout      // before training ("today's estimated performance is +8%")
    case duringWorkout   // predicted next weight / reps / rest
    case postMeal        // "protein is still low — easiest foods to close it"
    case recovery        // recovery/sleep context
    case weekly          // the one or two high-impact insights of the week
}

/// A single ambient insight — the unified presentation unit every domain emits into
/// the interface. Quiet by default (`title`), with a concrete `reason` revealed only
/// when the user chooses to dive deeper. Explainable, dismissible, learned from the
/// user's own behavior. The AI never appears as a chatbot; it appears as this.
struct AmbientInsight: Identifiable, Equatable, Sendable {
    var id: String                 // stable key (drives dismissal memory)
    var domain: PersonalizationDomain
    var surface: InsightSurface
    var title: String              // the calm, inline line
    var reason: String             // the "why", shown on tap-to-deepen
    var impact: Double             // 0–1 how valuable acting on it is
    var confidence: Double         // 0–1 how sure Forge is
    var isDismissible: Bool = true

    /// Ranking priority — value × certainty. Only the best survive curation.
    var priority: Double { impact * confidence }
}

/// Remembers what the user has dismissed, so a brushed-away insight doesn't nag. Pure
/// + testable. This is the anti-spam heart of "never annoying": a cool-down after one
/// dismissal, permanent suppression after repeated ones (Forge learns you don't want it).
struct DismissalMemory: Codable, Equatable, Sendable {
    /// insight id → the times it was dismissed.
    private(set) var dismissals: [String: [Date]] = [:]

    mutating func recordDismissal(_ id: String, at: Date) {
        dismissals[id, default: []].append(at)
    }

    func timesDismissed(_ id: String) -> Int { dismissals[id]?.count ?? 0 }

    func isSuppressed(_ id: String, now: Date, cooldownDays: Double = 3, permanentAfter: Int = 3) -> Bool {
        guard let times = dismissals[id], let last = times.max() else { return false }
        if times.count >= permanentAfter { return true }          // learned: don't show this
        return now.timeIntervalSince(last) < cooldownDays * 86_400 // cool-down after a dismissal
    }
}

/// How restrained a surface is — Apple-calm by default: at most one inline insight, a
/// confidence floor, and dismissal cool-downs. Weekly allows two high-impact insights.
struct CurationPolicy: Sendable {
    var maxInsights: Int = 1
    var minConfidence: Double = 0.5
    var cooldownDays: Double = 3
    var permanentAfter: Int = 3

    static func standard(for surface: InsightSurface) -> CurationPolicy {
        var p = CurationPolicy()
        if surface == .weekly { p.maxInsights = 2 }
        return p
    }
}

/// Turns the full stream of candidate insights (from meal memory, correlations,
/// targets, training, …) into the *few* that actually surface — the mechanism that
/// makes intelligence disappear into the UI. Ranks by priority, gates on confidence,
/// honors dismissals, and caps the count so the user is never overwhelmed. Pure + tested.
enum InsightCurator {
    static func curate(_ candidates: [AmbientInsight], now: Date,
                       dismissed: DismissalMemory = DismissalMemory(),
                       policy: CurationPolicy) -> [AmbientInsight] {
        candidates
            .filter { $0.confidence >= policy.minConfidence }
            .filter { !$0.isDismissible || !dismissed.isSuppressed($0.id, now: now,
                        cooldownDays: policy.cooldownDays, permanentAfter: policy.permanentAfter) }
            .sorted { $0.priority > $1.priority }
            .prefix(policy.maxInsights)
            .map { $0 }
    }
}

// MARK: - Domain adapters (each feature emits AmbientInsights)

extension MealSuggestion {
    /// Surface a "log your usual …" suggestion as a quiet diary insight. Impact scales
    /// with how much of the meal is still unlogged; confidence is the suggestion score.
    func asAmbientInsight() -> AmbientInsight {
        AmbientInsight(id: "meal.\(meal.id)", domain: .nutrition, surface: .diary,
                       title: title, reason: reason,
                       impact: min(1, 0.5 + 0.1 * Double(itemsToLog.count)), confidence: score)
    }
}
