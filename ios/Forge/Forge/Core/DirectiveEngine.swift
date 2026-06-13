import Foundation

/// The single most important instruction for today, synthesized from every signal.
/// This is the heart of Forge's "turn data into decisions" thesis — pure logic,
/// unit-tested, with zero UI so it can be reused anywhere (widget, watch, push).
struct DailyDirective: Equatable {
    let headline: String        // "Train at moderate intensity."
    let rationale: String       // "Recovery is 78%, protein is 72g behind, knee risk is moderate."
    let priorityAction: String  // "Complete knee PT before lifting."
    let workoutName: String
    let tone: Tone

    static func == (lhs: DailyDirective, rhs: DailyDirective) -> Bool {
        lhs.headline == rhs.headline && lhs.rationale == rhs.rationale
            && lhs.priorityAction == rhs.priorityAction
    }
}

enum DirectiveEngine {

    static func make(
        recovery: Int,
        sleepDebtHours: Double,
        proteinRemaining: Int,
        hydrationPct: Int,
        injuryRiskPercent: Int,
        injuryRiskBand: String,
        activeInjuryName: String?,
        activeInjuryPain: Int?,
        workoutName: String,
        soreness: Int? = nil
    ) -> DailyDirective {

        // 1. Training intensity follows recovery — but high morning soreness overrides it.
        var headline: String
        var tone: Tone
        switch recovery {
        case 80...:   headline = "Push hard today.";              tone = .green
        case 60..<80: headline = "Train at moderate intensity.";  tone = .gold
        default:      headline = "Pull back and recover today.";  tone = .ruby
        }
        let verySore = (soreness ?? 0) >= 7
        if verySore {
            headline = "Pull back and recover today."
            tone = .ruby
        }

        // 2. Rationale stitches the live signals into one readable line.
        var parts = ["Recovery is \(recovery)%"]
        if let s = soreness, s >= 5 { parts.append("you logged soreness \(s)/10") }
        if proteinRemaining > 0 { parts.append("protein is \(proteinRemaining)g behind") }
        if hydrationPct < 80 { parts.append("hydration is at \(hydrationPct)%") }
        if injuryRiskPercent >= 20, let name = activeInjuryName {
            parts.append("\(name.lowercased()) risk is \(injuryRiskBand.lowercased())")
        }
        let rationale = sentence(parts)

        // 3. The ONE priority action, most-urgent-first.
        let priorityAction: String
        if verySore {
            priorityAction = "Soreness is \(soreness ?? 0)/10 — swap lifting for mobility and easy Zone 2 today."
        } else if let pain = activeInjuryPain, pain >= 3, let name = activeInjuryName {
            priorityAction = "Complete \(name.lowercased()) PT before lifting."
        } else if recovery < 60 {
            priorityAction = "Skip the top set — today is about recovery, not records."
        } else if sleepDebtHours >= 3 {
            priorityAction = "Lights out by 22:30 — you're carrying \(hours(sleepDebtHours)) of sleep debt."
        } else if proteinRemaining >= 40 {
            priorityAction = "Front-load protein — \(proteinRemaining)g to go, start at lunch."
        } else if hydrationPct < 70 {
            priorityAction = "Hydrate before training — you're at \(hydrationPct)% of target."
        } else {
            priorityAction = "You're cleared to progress — chase the top set."
        }

        return DailyDirective(headline: headline, rationale: rationale,
                              priorityAction: priorityAction, workoutName: workoutName, tone: tone)
    }

    /// Join clauses into one sentence: "a, b, and c."
    private static func sentence(_ parts: [String]) -> String {
        switch parts.count {
        case 0: return ""
        case 1: return parts[0] + "."
        case 2: return parts[0] + " and " + parts[1] + "."
        default:
            let head = parts.dropLast().joined(separator: ", ")
            return head + ", and " + parts.last! + "."
        }
    }

    private static func hours(_ h: Double) -> String {
        let whole = Int(h)
        let mins = Int((h - Double(whole)) * 60)
        return mins > 0 ? "\(whole)h \(mins)m" : "\(whole)h"
    }
}
