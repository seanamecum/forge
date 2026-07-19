import Foundation

/// One prescribed PT movement for today.
struct RehabExercise: Identifiable {
    let id = UUID()
    let name: String
    let prescription: String
    let note: String
}

/// Today's auto-generated rehab session for an active injury.
struct RehabPlan {
    let title: String          // "Knee Rehab · Rehab"
    let focus: String          // "Heavy slow resistance — rebuild capacity"
    let exercises: [RehabExercise]
    let estMinutes: Int
    let summary: String        // one-liner for the Daily Directive
}

/// Return-to-sport readiness, blended from objective markers.
struct ReturnReadiness {
    let percent: Int
    let band: String
    let clearedCount: Int
    let totalCount: Int
    let nextMilestone: String?
    let etaText: String
}

/// Turns an injury profile into a concrete daily rehab plan and a return-to-sport
/// readiness score. Pure logic, unit-tested — feeds the Daily Directive and the
/// coach so injury work is prescribed, not just tracked.
enum RehabEngine {

    /// Today's PT — pulled from the matching protocol, falling back to the library by area.
    static func plan(for injury: InjuryProfile,
                     library: [PTExercise],
                     protocols: [RehabProtocol]) -> RehabPlan {
        let names: [String]
        if let proto = protocols.first(where: { $0.injuryType == injury.type }) {
            names = proto.ptExerciseNames
        } else {
            names = library
                .filter { $0.area.lowercased().contains(injury.type.rawValue.lowercased()) }
                .map(\.name)
        }
        var exercises = names.compactMap { name -> RehabExercise? in
            guard let ex = library.first(where: { $0.name == name }) else { return nil }
            return RehabExercise(name: ex.name, prescription: ex.prescription, note: ex.note)
        }
        if exercises.isEmpty {   // a plan must always exist
            exercises = library.prefix(3).map { RehabExercise(name: $0.name, prescription: $0.prescription, note: $0.note) }
        }

        let minutes = max(10, roundTo5(exercises.count * 4 + 5))
        let area = injury.type.rawValue.lowercased()
        let anchor = exercises.first?.name ?? "mobility"
        let extra = exercises.count - 1
        let summary = extra > 0
            ? "\(minutes) min \(area) PT — \(anchor) +\(extra) more"
            : "\(minutes) min \(area) PT — \(anchor)"

        return RehabPlan(title: "\(injury.type.rawValue) Rehab · \(injury.phase.rawValue)",
                         focus: focusText(injury.phase),
                         exercises: exercises, estMinutes: minutes, summary: summary)
    }

    /// Blends checklist progress (50%), rebuilt strength (30%), and current pain
    /// (20%) into one return-to-sport readiness score.
    static func readiness(checklist: [RTSChecklistItem], injury: InjuryProfile) -> ReturnReadiness {
        let total = checklist.count
        let cleared = checklist.filter(\.done).count
        let checklistPct = total > 0 ? Double(cleared) / Double(total) * 100 : 0
        let painScore = Double(max(0, 10 - injury.painToday)) * 10
        let raw = 0.5 * checklistPct + 0.3 * Double(injury.strengthPct) + 0.2 * painScore
        let percent = Int(raw.rounded()).clamped(to: 0...100)

        // Forge tracks self-reported progress; it never issues medical clearance.
        // The top band means the athlete has met the self-check criteria — the
        // return-to-sport decision still belongs to a clinician.
        let band: String
        switch percent {
        case 90...:    band = "Criteria met"
        case 70..<90:  band = "Nearly there"
        case 45..<70:  band = "On track"
        default:       band = "Early"
        }

        let remaining = total - cleared
        let etaText: String
        switch remaining {
        case 0:    etaText = "Final gate: clinician sign-off"
        case 1:    etaText = "~1 week out"
        case 2...3: etaText = "~2–3 weeks out"
        default:   etaText = "4+ weeks out"
        }

        return ReturnReadiness(percent: percent, band: band,
                               clearedCount: cleared, totalCount: total,
                               nextMilestone: checklist.first(where: { !$0.done })?.label,
                               etaText: etaText)
    }

    // MARK: - Helpers

    private static func focusText(_ phase: InjuryPhase) -> String {
        switch phase {
        case .acute:         return "Calm it down — reduce reactive pain"
        case .subacute:      return "Restore motion and gentle load"
        case .rehab:         return "Heavy slow resistance — rebuild capacity"
        case .returnToSport: return "Energy storage + sport drills"
        case .resolved:      return "Maintain — keep the area resilient"
        }
    }

    private static func roundTo5(_ n: Int) -> Int { Int((Double(n) / 5).rounded()) * 5 }
}
