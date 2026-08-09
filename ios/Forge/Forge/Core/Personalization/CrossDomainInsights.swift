import Foundation

/// The UserModel "brain" made visible — insights that combine *more than one*
/// domain into a single causal, longitudinal explanation. Where `InsightGenerators`
/// speaks about one signal ("recovery is low"), this speaks about *why*, connecting
/// sleep, training load, and recovery the way the person never has to.
///
/// Honest above all: a cause is named only when it is real in the data. If recovery
/// isn't actually low, or no contributing driver clears its threshold, this returns
/// nil and the simpler single-domain insight (or nothing) takes over. Forge never
/// fabricates a correlation.
enum CrossDomainInsights {

    // MARK: - Pure signal detectors

    /// Length (in nights) of the most recent run of declining sleep, or 0 when there
    /// is no clear decline. Requires a real trailing downward run with meaningful
    /// magnitude — noise alone never counts as "trending down".
    static func sleepDeclineNights(_ hours: [Double]) -> Int {
        guard hours.count >= 3 else { return 0 }
        var run = 1
        var i = hours.count - 1
        // Walk back while each earlier night was not lower than the next (a downward
        // path toward today), tolerating small noise.
        while i > 0 && hours[i] <= hours[i - 1] + 0.1 {
            run += 1
            i -= 1
        }
        let drop = hours[hours.count - run] - hours[hours.count - 1]
        guard run >= 3, drop >= 0.5 else { return 0 }   // real, multi-night, ≥30 min lost
        return run
    }

    /// Percent change in training volume, this week vs the prior week. Nil when the
    /// prior week has no volume (can't express a percentage honestly).
    static func volumeChangePct(thisWeek: Double, priorWeek: Double) -> Int? {
        guard priorWeek > 0 else { return nil }
        return Int(((thisWeek - priorWeek) / priorWeek * 100).rounded())
    }

    // MARK: - Cross-domain synthesis

    /// The flagship "it knows me" insight: recovery is below the person's own usual,
    /// explained by the drivers that are actually true right now — declining sleep
    /// and/or a real jump in training volume. Returns nil unless recovery is
    /// materially low AND at least one driver is genuinely present.
    static func recoveryDriver(recoveryToday: Int, usual: Int, sleepHours: [Double],
                               volumeThisWeek: Double, volumePriorWeek: Double) -> AmbientInsight? {
        guard usual > 0 else { return nil }
        let delta = recoveryToday - usual
        guard delta <= -8 else { return nil }           // below the user's *own* normal

        var causes: [String] = []
        let nights = sleepDeclineNights(sleepHours)
        if nights >= 3 { causes.append("your sleep has trended down \(nights) days") }
        if let pct = volumeChangePct(thisWeek: volumeThisWeek, priorWeek: volumePriorWeek), pct >= 12 {
            causes.append("training volume rose \(pct)%")
        }
        guard !causes.isEmpty else { return nil }       // no real cause → don't claim one

        let because = causes.joined(separator: " while ")
        let confidence = causes.count >= 2 ? 0.85 : 0.72
        return AmbientInsight(
            id: "recovery.driver", domain: .recovery, surface: .home,
            title: "Recovery is lower because \(because).",
            reason: "Today's recovery is \(-delta) below your usual \(usual). An easier session or an earlier night tends to bring it back — Forge connected this for you.",
            impact: 0.82, confidence: confidence)
    }
}
