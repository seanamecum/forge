import Foundation

/// One prescribed action in today's plan — "Protein: 200 g · 72 g to go".
/// Pure data so it renders identically in the card, a widget, or a push.
struct DirectiveAction: Identifiable {
    enum Kind: String, CaseIterable {
        case train, fuel, protein, mobility, supplement, sleep

        var icon: String {
            switch self {
            case .train:      return "dumbbell.fill"
            case .fuel:       return "flame.fill"
            case .protein:    return "fork.knife"
            case .mobility:   return "figure.cooldown"
            case .supplement: return "pills.fill"
            case .sleep:      return "moon.stars.fill"
            }
        }
        var label: String {
            switch self {
            case .train:      return "Train"
            case .fuel:       return "Fuel"
            case .protein:    return "Protein"
            case .mobility:   return "Mobility"
            case .supplement: return "Supplement"
            case .sleep:      return "Sleep"
            }
        }
    }
    let kind: Kind
    let value: String      // the prescription, e.g. "2,650 kcal" or "8h 15m target"
    let tone: Tone
    var id: String { kind.rawValue }
    var icon: String { kind.icon }
    var label: String { kind.label }
}

/// The single most important instruction for today, synthesized from every signal.
/// This is the heart of Forge's "turn data into decisions" thesis — pure logic,
/// unit-tested, with zero UI so it can be reused anywhere (widget, watch, push).
struct DailyDirective: Equatable {
    let headline: String        // "Train at moderate intensity."
    let rationale: String       // "Recovery is 78%, protein is 72g behind, knee risk is moderate."
    let priorityAction: String  // "Complete knee PT before lifting."
    let workoutName: String
    let tone: Tone
    /// The prescribed plan for today — what to actually do, in order.
    var actions: [DirectiveAction] = []

    /// Stable identity of *this decision* — a dismissal keyed on it persists until
    /// the directive's content actually changes (not merely a view recreation).
    /// Deterministic across launches (unlike `Hashable.hashValue`, which is salted).
    var id: String {
        Data("\(headline)|\(rationale)|\(priorityAction)".utf8).base64EncodedString()
    }

    // Equatable intentionally ignores `actions` (compares the decision, not the render list).
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
        soreness: Int? = nil,
        // Recent training load (0–21 strain) + the athlete's baseline, so a hard
        // day tempers today. Defaulted to 0 → no effect unless supplied.
        trainingLoadYesterday: Double = 0,
        trainingLoadAvg: Double = 0,
        // Prescription inputs — defaulted so the scalar directive (and its tests) are unaffected.
        calorieTarget: Int = 0,
        proteinTarget: Int = 0,
        mobilityMinutes: Int = 0,
        rehabPlanSummary: String? = nil,
        keySupplement: String? = nil,
        sleepTargetHours: Double = 0
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

        // 1b. Acute:chronic workload — a spike over the athlete's own baseline (or
        // a maximal day in absolute terms) tempers a green light. It only ever
        // *lowers* intensity, never raises it, and never overrides a pull-back.
        let loadRatio = trainingLoadAvg > 0 ? trainingLoadYesterday / trainingLoadAvg : 1.0
        let highLoad = trainingLoadYesterday >= 15 || loadRatio >= 1.4
        if highLoad, !verySore, headline == "Push hard today." {
            headline = "Train at moderate intensity."
            tone = .gold
        }
        let loadText = "\(Int(trainingLoadYesterday.rounded()))/21"

        // 2. Rationale stitches the live signals into one readable line.
        var parts = ["Recovery is \(recovery)%"]
        if let s = soreness, s >= 5 { parts.append("you logged soreness \(s)/10") }
        if highLoad { parts.append("training load ran high yesterday (\(loadText))") }
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
        } else if highLoad {
            priorityAction = "You trained hard yesterday (\(loadText)) — keep today controlled and leave 1–2 reps in reserve."
        } else {
            priorityAction = "You're cleared to progress — chase the top set."
        }

        // 4. The prescribed plan — concrete, checkable targets for today.
        let actions = buildActions(
            recovery: recovery, verySore: verySore, workoutName: workoutName,
            calorieTarget: calorieTarget,
            proteinTarget: proteinTarget, proteinRemaining: proteinRemaining,
            mobilityMinutes: mobilityMinutes, activeInjuryName: activeInjuryName,
            rehabPlanSummary: rehabPlanSummary,
            keySupplement: keySupplement, sleepTargetHours: sleepTargetHours)

        return DailyDirective(headline: headline, rationale: rationale,
                              priorityAction: priorityAction, workoutName: workoutName,
                              tone: tone, actions: actions)
    }

    // MARK: - Prescription

    private static func buildActions(
        recovery: Int, verySore: Bool, workoutName: String,
        calorieTarget: Int, proteinTarget: Int, proteinRemaining: Int,
        mobilityMinutes: Int, activeInjuryName: String?,
        rehabPlanSummary: String?,
        keySupplement: String?, sleepTargetHours: Double
    ) -> [DirectiveAction] {
        var actions: [DirectiveAction] = []

        // Train — the day's session, toned by how hard to go.
        let trainTone: Tone = verySore ? .amber : (recovery >= 80 ? .green : (recovery < 60 ? .amber : .gold))
        actions.append(DirectiveAction(kind: .train, value: workoutName, tone: trainTone))

        // Fuel — calorie target.
        if calorieTarget > 0 {
            actions.append(DirectiveAction(kind: .fuel, value: "\(grouped(calorieTarget)) kcal", tone: .gold))
        }

        // Protein — target plus how much is still owed today.
        if proteinTarget > 0 {
            let value = proteinRemaining > 0 ? "\(proteinTarget) g · \(proteinRemaining) g to go" : "\(proteinTarget) g · on track"
            actions.append(DirectiveAction(kind: .protein, value: value,
                                           tone: proteinRemaining >= 40 ? .amber : .green))
        }

        // Mobility / PT — the specific rehab plan when an injury is active.
        if mobilityMinutes > 0 || rehabPlanSummary != nil {
            let value: String
            if let rehab = rehabPlanSummary, !rehab.isEmpty {
                value = rehab
            } else if let name = activeInjuryName {
                value = "\(mobilityMinutes) min \(name.lowercased()) PT"
            } else {
                value = "\(mobilityMinutes) min mobility"
            }
            actions.append(DirectiveAction(kind: .mobility, value: value,
                                           tone: activeInjuryName != nil ? .amber : .royal))
        }

        // Supplement — the single most valuable one not yet taken.
        if let s = keySupplement, !s.isEmpty {
            actions.append(DirectiveAction(kind: .supplement, value: s, tone: .gold))
        }

        // Sleep — tonight's target, debt-adjusted.
        if sleepTargetHours > 0 {
            actions.append(DirectiveAction(kind: .sleep, value: "\(clock(sleepTargetHours)) target", tone: .royal))
        }

        return actions
    }

    // MARK: - Helpers

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

    /// "8h 15m" from 8.25.
    private static func clock(_ h: Double) -> String {
        let whole = Int(h)
        let mins = Int(((h - Double(whole)) * 60).rounded())
        return mins > 0 ? "\(whole)h \(mins)m" : "\(whole)h"
    }

    /// "3,200" with a thousands separator, no locale surprises.
    private static func grouped(_ n: Int) -> String {
        let s = String(n)
        guard s.count > 3 else { return s }
        var out = "", count = 0
        for ch in s.reversed() {
            if count != 0 && count % 3 == 0 { out.append(",") }
            out.append(ch); count += 1
        }
        return String(out.reversed())
    }
}
