import Foundation

/// Turns the user's real, current state into candidate `AmbientInsight`s — the quiet
/// lines Forge surfaces at the right moment ("You're 35 g short of protein",
/// "Recovery is lower than normal today"). Each is pure, honest (nil when there's no
/// real signal), explainable, and dismissible. The `InsightCurator` then decides which
/// one or two actually appear. Never spam.
enum InsightGenerators {

    /// Protein still to go today — only when materially short.
    static func proteinShort(remaining: Int, target: Int) -> AmbientInsight? {
        guard target > 0, remaining >= 25 else { return nil }
        return AmbientInsight(
            id: "nutrition.protein-short", domain: .nutrition, surface: .home,
            title: "You're \(remaining) g short of protein.",
            reason: "You've hit \(target - remaining) of \(target) g today — a protein-forward next meal closes it.",
            impact: min(1, Double(remaining) / 50), confidence: 0.8)
    }

    /// Recovery notably below the user's own usual level.
    static func recoveryVsNormal(today: Int, usual: Int) -> AmbientInsight? {
        guard usual > 0 else { return nil }
        let delta = today - usual
        guard delta <= -8 else { return nil }
        return AmbientInsight(
            id: "recovery.low-today", domain: .recovery, surface: .home,
            title: "Recovery is lower than normal today.",
            reason: "Recovery is \(today), vs your usual \(usual) — consider trimming volume and prioritizing sleep.",
            impact: min(1, Double(-delta) / 25), confidence: 0.78)
    }

    /// Hydration under target for several recent days.
    static func hydrationLow(daysBelowTarget: Int) -> AmbientInsight? {
        guard daysBelowTarget >= 3 else { return nil }
        return AmbientInsight(
            id: "hydration.low-streak", domain: .hydration, surface: .home,
            title: "Hydration has been below average for \(daysBelowTarget) days.",
            reason: "Your water intake trailed your target on \(daysBelowTarget) recent days.",
            impact: min(1, Double(daysBelowTarget) / 7), confidence: 0.7)
    }

    /// This week is the highest weekly training load in the tracked window.
    static func trainingLoadPeak(weeksTracked: Int, isHighest: Bool) -> AmbientInsight? {
        guard isHighest, weeksTracked >= 4 else { return nil }
        return AmbientInsight(
            id: "training.load-peak", domain: .training, surface: .home,
            title: "This week is your highest training load in \(weeksTracked) weeks.",
            reason: "Weekly volume is peaking — protect recovery, sleep, and protein to absorb it.",
            impact: 0.6, confidence: 0.7)
    }

    /// Sleep declining over recent nights (slope in hours/day).
    static func sleepTrendingDown(slopePerDay: Double) -> AmbientInsight? {
        guard slopePerDay <= -0.15 else { return nil }
        return AmbientInsight(
            id: "sleep.trending-down", domain: .sleep, surface: .home,
            title: "Your sleep is trending down.",
            reason: "Nightly sleep has been declining recently — it's the highest-leverage fix for recovery.",
            impact: 0.6, confidence: 0.66)
    }

    /// On pace to reach the goal ahead of schedule.
    static func goalPace(daysEarly: Int) -> AmbientInsight? {
        guard daysEarly >= 2 else { return nil }
        return AmbientInsight(
            id: "goal.ahead-of-pace", domain: .habits, surface: .home,
            title: "You're on pace to hit your goal \(daysEarly) days early.",
            reason: "Your recent trend is ahead of schedule — keep it steady.",
            impact: 0.5, confidence: 0.6)
    }
}
