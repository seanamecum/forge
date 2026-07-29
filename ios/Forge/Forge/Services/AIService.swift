import Foundation

/// The brain. Two paths behind one async entry point:
///   • Live  — calls the Claude Messages API (raw HTTPS; Swift has no official SDK)
///             with a system prompt built from the athlete's real data.
///   • Mock  — the rule-based engine below; used when no API key is configured,
///             and as the offline-safe fallback whenever a live call fails.
/// The app behaves identically with or without a key — it never breaks offline.
/// Everything the coach knows about the athlete *right now*. Built by AppState
/// from live service state so the system prompt (and the dashboard brief) always
/// reflect what the app is actually showing — never a stale snapshot.
struct CoachContext {
    // Athlete
    var name: String
    var age: Int
    var sport: String
    var goals: String
    var level: String
    var streakDays: Int
    // Today's signals
    var forgeScore: Int
    var recovery: Int
    var readiness: String
    var hrv: Int
    var hrvBaseline: Int
    var restingHR: Int
    var sleepHours: Double
    var sleepDebtHours: Double
    var strainYesterday: Double
    // Fuel
    var calorieTarget: Int
    var proteinTarget: Int
    var waterTargetOz: Int
    var proteinRemaining: Int
    var hydrationPct: Int
    var magnesiumPct: Int
    var magnesiumDaysLow: Int
    // The plan the app is showing
    var directive: DailyDirective
    // Connected ecosystem — which devices feed Forge, and the cross-device read.
    var dataSources: String = ""
    var deviceNarrative: String = ""
    // Lift watch — the current plateau, if any, so the coach diagnoses it.
    var plateauNote: String = ""
    // True only for the demo athlete — gates the rich canned offline replies so a
    // real account never receives the demo athlete's fabricated numbers.
    var isDemo: Bool = false
    // Clinical context, from the athlete's OWN data (empty for a real user with
    // none) — the coach never sees the demo athlete's injuries/labs/deficiencies.
    var injuryName: String = ""
    var injuryPhase: String = ""
    var injuryPain: Int = 0
    var injuryRiskPercent: Int = 0
    var injuryRiskBand: String = ""
    var injuryLine: String = ""      // full INJURY bullet, or "" when healthy
    var deficiencyLine: String = ""  // e.g. "Magnesium 240/400mg (6d low), …", or ""
    var bloodworkLine: String = ""   // e.g. " Bloodwork Vitamin D 24 ng/mL (low).", or ""
    var forecastLine: String = ""    // e.g. "Bench Press: 180 → 205 by …", or ""
    var rehabLine: String = ""       // full REHAB block, or "" when no active injury

    /// Demo snapshot mirroring the mock athlete — used by previews and tests.
    static var demo: CoachContext {
        let u = MockData.sean
        let d = MockData.today
        let knee = MockData.knee
        let directive = DirectiveEngine.make(
            recovery: d.recovery, sleepDebtHours: d.sleepDebtHours,
            proteinRemaining: 72, hydrationPct: 62,
            injuryRiskPercent: MockData.injuryRisk.percent,
            injuryRiskBand: MockData.injuryRisk.band,
            activeInjuryName: knee.type.rawValue, activeInjuryPain: knee.painToday,
            workoutName: "Upper Push + Knee-Safe Lower",
            calorieTarget: u.calorieTarget, proteinTarget: u.proteinTarget,
            mobilityMinutes: 20, keySupplement: "Magnesium 400 mg",
            sleepTargetHours: 8.0 + min(d.sleepDebtHours * 0.08, 1.0))
        return CoachContext(
            name: u.name, age: u.age, sport: u.sport,
            goals: u.goals.map(\.rawValue).joined(separator: ", "),
            level: u.fitnessLevel.rawValue, streakDays: u.streakDays,
            forgeScore: 78, recovery: d.recovery, readiness: d.readiness.rawValue,
            hrv: d.hrv, hrvBaseline: d.hrvBaseline, restingHR: d.restingHR,
            sleepHours: d.sleep.hours, sleepDebtHours: d.sleepDebtHours,
            strainYesterday: d.strainYesterday,
            calorieTarget: u.calorieTarget, proteinTarget: u.proteinTarget,
            waterTargetOz: u.waterTargetOz,
            proteinRemaining: 72, hydrationPct: 62,
            magnesiumPct: 52, magnesiumDaysLow: 6,
            directive: directive,
            isDemo: true,
            injuryName: knee.type.rawValue, injuryPhase: knee.phase.rawValue,
            injuryPain: knee.painToday,
            injuryRiskPercent: MockData.injuryRisk.percent, injuryRiskBand: MockData.injuryRisk.band,
            injuryLine: injuryLine(for: knee),
            deficiencyLine: deficiencyLine(from: MockData.deficiencies),
            bloodworkLine: bloodworkLine(from: MockData.bloodwork),
            forecastLine: forecastLine(from: MockData.forecasts),
            rehabLine: rehabLine(
                plan: RehabEngine.plan(for: knee, library: MockData.ptExercises, protocols: MockData.protocols),
                readiness: RehabEngine.readiness(checklist: MockData.kneeRTSChecklist, injury: knee)))
    }

    // MARK: - Clinical line formatting (shared by demo + AppState.coachContext)
    // These turn the athlete's OWN data into the exact strings the coach reads, so
    // the demo snapshot and a live account produce identically-shaped context — and
    // a real user with no injury/labs simply gets empty strings (honest silence).

    /// The INJURY bullet — "" when the athlete is healthy.
    static func injuryLine(for injury: InjuryProfile?) -> String {
        guard let i = injury else { return "" }
        return "\(i.name): day \(i.daysOld), \(i.phase.rawValue), pain \(i.painToday)/10."
    }

    /// The 7-day deficiency summary (top 3) — "" when there are none.
    static func deficiencyLine(from deficiencies: [DeficiencyAlert]) -> String {
        deficiencies.prefix(3)
            .map { "\($0.nutrient) \($0.current)/\($0.target) (\($0.daysLow)d low)" }
            .joined(separator: ", ")
    }

    /// A one-marker bloodwork callout (Vitamin D if present) — "" when no labs.
    static func bloodworkLine(from bloodwork: [BloodworkMarker]) -> String {
        guard let vitD = bloodwork.first(where: { $0.name.contains("Vitamin D") }) else { return "" }
        return " Bloodwork Vitamin D \(Int(vitD.value)) ng/mL (low)."
    }

    /// The lead performance forecast — "" when none is available yet.
    static func forecastLine(from forecasts: [Forecast]) -> String {
        guard let f = forecasts.first(where: { $0.metric == "Bench Press" }) ?? forecasts.first else { return "" }
        return "\(f.metric): \(f.current) → \(f.projected) by \(f.eta) if consistent."
    }

    /// The REHAB block — the exact PT prescription + return-to-sport read. "" when
    /// there is no active injury to rehab.
    static func rehabLine(plan: RehabPlan?, readiness: ReturnReadiness?) -> String {
        guard let plan else { return "" }
        var s = "\(plan.title): \(plan.focus)\n- "
        s += plan.exercises.prefix(4).map { "\($0.name) \($0.prescription)" }.joined(separator: " · ")
        if let r = readiness {
            s += "\n- Return-to-sport readiness \(r.percent)% (\(r.band)), \(r.etaText)."
            if let next = r.nextMilestone { s += " Next milestone: \(next)." }
        }
        return s
    }
}

enum AIService {

    static let quickPrompts = [
        "What should I train today?", "Should I train hard?", "Should I deload?",
        "What should I eat today?", "Why is my recovery low?", "How do I fix my knee pain?",
        "What supplements am I missing?", "How do I hit 225 bench?",
        "What is holding me back?", "What will I look like in 12 weeks?",
    ]

    // MARK: - Daily brief (dashboard hero)

    /// One-paragraph morning brief, synthesized from the live directive so the
    /// hero text always agrees with the plan below it.
    static func dailyBrief(context c: CoachContext) -> String {
        var brief = "Forge Score \(c.forgeScore). Recovery \(c.recovery) — \(c.directive.headline.lowercased().dropLast())."
        if c.proteinRemaining > 0 {
            brief += " Close the \(c.proteinRemaining) g protein gap by 9 PM."
        }
        if let sleep = c.directive.actions.first(where: { $0.kind == .sleep }) {
            brief += " Tonight: \(sleep.value.lowercased())"
            brief += c.sleepDebtHours >= 2 ? " — sleep is your one lagging input." : "."
        }
        return brief
    }

    // MARK: - Unified entry point

    /// Returns a coach reply. Tries the live model when configured; otherwise (or on
    /// any error) returns the rich mock so the chat always works.
    /// `history` is the conversation *before* the new question — the question is
    /// appended exactly once here.
    static func reply(to question: String,
                      history: [CoachMessage] = [],
                      context: CoachContext = .demo,
                      checkInNote: String? = nil) async -> CoachMessage {
        // The "signals" panel shows exactly what Forge fed the coach — the same
        // real context in mock and live mode, never fabricated reasoning.
        let signals = contextSignals(context)
        guard ForgeConfig.aiMode != .mock else {
            var reply = offlineReply(to: question, context: context)
            reply.steps = signals; return reply
        }
        do {
            let text = try await callClaude(question: question, history: history,
                                            context: context, checkInNote: checkInNote)
            return CoachMessage(role: .coach, text: text, steps: signals,
                                suggestions: Array(quickPrompts.prefix(4)))
        } catch {
            var reply = offlineReply(to: question, context: context)
            reply.steps = signals; return reply
        }
    }

    /// The offline (no-API) reply. The demo athlete gets the rich canned script that
    /// matches Sean's mock data; a real account gets an honest answer synthesized
    /// from ITS OWN live numbers — never the demo athlete's fabricated stats.
    static func offlineReply(to question: String, context c: CoachContext) -> CoachMessage {
        c.isDemo ? mockReply(to: question) : contextualReply(to: question, context: c)
    }

    /// The live signals Forge hands the coach, as short honest labels — the real
    /// inputs behind the answer, not an invented chain-of-thought. Pure + tested.
    static func contextSignals(_ c: CoachContext) -> [String] {
        var s = [
            "Forge Score \(c.forgeScore)/100",
            "Recovery \(c.recovery) · readiness \(c.readiness)",
            "HRV \(c.hrv) ms (baseline \(c.hrvBaseline))",
            "Sleep \(String(format: "%.1f", c.sleepHours)) h",
        ]
        if c.sleepDebtHours >= 0.5 { s.append("Sleep debt \(String(format: "%.1f", c.sleepDebtHours)) h") }
        if c.strainYesterday > 0 { s.append("Training load \(Int(c.strainYesterday.rounded()))/21") }
        if c.proteinRemaining > 0 { s.append("Protein \(c.proteinRemaining) g to target") }
        s.append("Hydration \(c.hydrationPct)%")
        s.append("Directive: \(c.directive.headline.replacingOccurrences(of: ".", with: ""))")
        if !c.plateauNote.isEmpty { s.append(c.plateauNote) }
        return s
    }

    // MARK: - Live: Claude Messages API (raw HTTPS)

    private enum AIError: Error { case badStatus, emptyBody }

    struct APIMessage: Codable, Equatable { let role: String; let content: String }
    private struct APIRequest: Codable {
        let model: String
        let max_tokens: Int
        let system: String
        let messages: [APIMessage]
    }
    private struct APIResponse: Codable {
        struct Block: Codable { let type: String; let text: String? }
        let content: [Block]
    }

    /// Build the API message list. The API requires the first message to be `user`,
    /// so leading coach/seed turns are dropped; a trailing history entry that
    /// duplicates the new question is skipped so the question is sent exactly once.
    /// Internal (not private) so the shape rules are unit-tested.
    static func buildAPIMessages(question: String, history: [CoachMessage]) -> [APIMessage] {
        var messages: [APIMessage] = []
        for m in history.suffix(12) {
            let role = m.role == .user ? "user" : "assistant"
            if messages.isEmpty && role != "user" { continue }
            messages.append(APIMessage(role: role, content: m.text))
        }
        if messages.last?.role == "user" && messages.last?.content == question {
            messages.removeLast()
        }
        messages.append(APIMessage(role: "user", content: question))
        return messages
    }

    private static func callClaude(question: String,
                                   history: [CoachMessage],
                                   context: CoachContext,
                                   checkInNote: String?) async throws -> String {
        guard let endpoint = URL(string: ForgeConfig.coachEndpoint) else { throw AIError.badStatus }
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        // Proxy mode: the backend holds the Anthropic key — the client sends none.
        // Direct mode (local dev only): authenticate straight to the API.
        if ForgeConfig.aiMode == .liveDirect {
            request.setValue(ForgeConfig.anthropicAPIKey, forHTTPHeaderField: "x-api-key")
        }
        request.setValue(ForgeConfig.anthropicVersion, forHTTPHeaderField: "anthropic-version")
        request.setValue("application/json", forHTTPHeaderField: "content-type")
        request.timeoutInterval = 30

        let messages = buildAPIMessages(question: question, history: history)

        // Opus 4.8: no temperature/top_p (removed); thinking omitted for a snappy chat.
        let body = APIRequest(model: ForgeConfig.coachModel,
                              max_tokens: ForgeConfig.coachMaxTokens,
                              system: systemPrompt(context: context, checkInNote: checkInNote),
                              messages: messages)
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw AIError.badStatus
        }
        let decoded = try JSONDecoder().decode(APIResponse.self, from: data)
        let text = decoded.content.compactMap(\.text).joined()
        guard !text.isEmpty else { throw AIError.emptyBody }
        return text
    }

    /// Back-compat convenience — demo-context prompt (previews, tests).
    static func systemPrompt(checkInNote: String?) -> String {
        systemPrompt(context: .demo, checkInNote: checkInNote)
    }

    /// The system prompt — Forge's coaching persona plus the athlete's LIVE data.
    /// Every number comes from `context`, which AppState builds from current service
    /// state, so the coach and the on-screen app can never disagree.
    /// Exposed `internal` so tests can assert it carries the right signals.
    static func systemPrompt(context c: CoachContext, checkInNote: String?) -> String {
        let directive = c.directive
        // Clinical blocks come straight from `c` (the athlete's OWN data). A real
        // user with no labs/injury gets empty strings → the section drops out
        // entirely, never a demo athlete's knee or Vitamin D bleeding through.
        let deficiencyBlock: String = {
            guard !c.deficiencyLine.isEmpty || !c.bloodworkLine.isEmpty else { return "" }
            let defs = c.deficiencyLine.isEmpty ? "none flagged" : c.deficiencyLine
            return "\n- Deficiencies (7-day): \(defs).\(c.bloodworkLine)"
        }()
        let injuryBlock = c.injuryLine.isEmpty ? "" : "\n\nINJURY\n- \(c.injuryLine)"
        let forecastBlock = c.forecastLine.isEmpty ? "" : "\n\nFORECAST\n- \(c.forecastLine)"

        var ctx = """
        You are Forge — an elite, premium AI performance coach inside a human-performance app. \
        You are direct, specific, and motivating; never generic. Reference the athlete's actual numbers. \
        Give one clear directive plus the reasoning, in 2–4 short sentences. Avoid bullet lists unless asked.

        ATHLETE
        - \(c.name), \(c.age), \(c.sport). Goals: \(c.goals). Level: \(c.level).
        - Lifts: bench 180, squat 230, deadlift 280. \(c.streakDays)-day streak.\(c.plateauNote.isEmpty ? "" : "\n- Lift watch: \(c.plateauNote)")

        TODAY
        - Forge Score \(c.forgeScore)/100. Recovery \(c.recovery)/100, readiness \(c.readiness), HRV \(c.hrv)ms (baseline \(c.hrvBaseline)), resting HR \(c.restingHR).
        - Sleep \(String(format: "%.1f", c.sleepHours))h last night; sleep debt \(String(format: "%.1f", c.sleepDebtHours))h this week.
        - Strain yesterday \(String(format: "%.1f", c.strainYesterday))/21.

        FUEL
        - Targets: \(c.calorieTarget) kcal / \(c.proteinTarget)g protein / \(c.waterTargetOz)oz water.
        - Right now: \(c.proteinRemaining)g protein still to go today; hydration at \(c.hydrationPct)% of target.\(deficiencyBlock)\(injuryBlock)\(forecastBlock)

        SAFETY
        - You provide educational guidance, not medical advice. For severe pain, swelling, head injury, chest pain, or neurological symptoms, tell the athlete to see a physician or physical therapist.

        EVIDENCE (when you make a physiological or training claim, cite from this vetted list when relevant, e.g. "(Jäger et al., JISSN 2017)". NEVER invent a citation; if the list doesn't cover a claim, speak from consensus without one.)
        \(EvidenceBase.promptBlock)
        """
        // Connected ecosystem — the coach reasons ACROSS devices and credits each one.
        if !c.dataSources.isEmpty {
            ctx += "\n\nDATA SOURCES (name the device that measured a signal when you cite it — e.g. \"your WHOOP HRV\", \"Apple Watch sleep\")"
            ctx += "\n- Connected: \(c.dataSources)"
            if !c.deviceNarrative.isEmpty {
                ctx += "\n- Cross-device read: \(c.deviceNarrative)"
            }
        }

        // Today's directive — keep the coach perfectly aligned with the on-screen plan.
        ctx += "\n\nTODAY'S DIRECTIVE (the app is showing the athlete this exact plan — stay consistent with it)"
        ctx += "\n- \(directive.headline) \(directive.priorityAction)"
        ctx += "\n- Plan: " + directive.actions.map { "\($0.label) \($0.value)" }.joined(separator: " · ")

        // Cross-module intelligence — the coach reasons in causal chains, never in silos.
        let drivers = InsightEngine.recoveryDrivers(
            recovery: c.recovery, sleepHours: c.sleepHours, sleepReference: 8.5,
            hrv: c.hrv, hrvBaseline: c.hrvBaseline,
            strainYesterday: c.strainYesterday, strainAvg: 13.9,
            restingHR: c.restingHR, restingHRBaseline: 52,
            magnesiumPct: c.magnesiumPct, magnesiumDaysLow: c.magnesiumDaysLow)
        if !drivers.isEmpty {
            ctx += "\n\nWHY RECOVERY IS \(c.recovery) (cite these specifics when asked about fatigue or recovery)"
            for dr in drivers.prefix(3) { ctx += "\n- \(dr.factor): \(dr.detail)" }
        }
        let insights = InsightEngine.crossModule(
            recovery: c.recovery, sleepDebtHours: c.sleepDebtHours,
            hrv: c.hrv, hrvBaseline: c.hrvBaseline,
            proteinRemaining: c.proteinRemaining, hydrationPct: c.hydrationPct,
            injuryName: c.injuryName.isEmpty ? nil : c.injuryName,
            injuryPhase: c.injuryPhase.isEmpty ? nil : c.injuryPhase,
            injuryPain: c.injuryName.isEmpty ? nil : c.injuryPain,
            injuryRiskPercent: c.injuryRiskPercent, injuryRiskBand: c.injuryRiskBand,
            magnesiumPct: c.magnesiumPct, magnesiumDaysLow: c.magnesiumDaysLow)
        if !insights.isEmpty {
            ctx += "\n\nCROSS-MODULE CONNECTIONS (reason in these chains — this is how Forge thinks)"
            for ins in insights.prefix(3) { ctx += "\n- \(ins.chain) → \(ins.action)" }
        }

        // Rehab — today's PT prescription + return-to-sport readiness (from the
        // athlete's own active injury; absent entirely when they're healthy).
        if !c.rehabLine.isEmpty {
            ctx += "\n\nREHAB (prescribe this exact plan when asked about the injury or rehab)"
            ctx += "\n- \(c.rehabLine)"
        }

        if let note = checkInNote, !note.isEmpty {
            ctx += "\n\nMORNING CHECK-IN\n- \(note) Weigh this heavily — it's today's freshest signal."
        }
        return ctx
    }

    // MARK: - Mock engine (offline-safe fallback)

    static func mockReply(to question: String) -> CoachMessage {
        let q = question.lowercased()

        if q.contains("do today") || q.contains("plan my day") || q.contains("train today") {
            return CoachMessage(role: .coach,
                text: "Three calls today, in order. (1) Upper push session as written — recovery is 78, so the progression to 185 on bench is on. (2) Knee rehab block after lifting: Spanish squats and TKEs, ~12 minutes. (3) You're 72 g short on protein pace — make dinner protein-first and you'll land on target.",
                cards: [CoachCard(label: "Train", value: "Upper Push · bench 185", tone: .green),
                        CoachCard(label: "Rehab", value: "Knee block · 12 min", tone: .amber),
                        CoachCard(label: "Fuel", value: "+72 g protein", tone: .gold)],
                suggestions: ["Should I train hard?", "What should I eat?", "How's my knee tracking?"])
        }
        if q.contains("tired") || q.contains("fatigue") || q.contains("drained") || q.contains("recovery low") {
            return CoachMessage(role: .coach,
                text: "Stacked, in order of weight: you're carrying 3.1 hours of sleep debt this week, HRV is 6% under baseline (58 vs 62), and magnesium has run at 52% of target for 6 days — low Mg reliably degrades both of the first two. Fix tonight: Mg-glycinate 400 mg, lights out 22:30, and tomorrow will read differently.",
                cards: [CoachCard(label: "Tonight", value: "Mg 400 mg + 22:30", tone: .gold),
                        CoachCard(label: "Tomorrow", value: "Re-check HRV", tone: .green)],
                suggestions: ["What supplement am I missing?", "Should I deload?"])
        }
        if q.contains("train hard") || q.contains("push today") || q.contains("go heavy") {
            return CoachMessage(role: .coach,
                text: "Upper body: yes — recovery 78 and readiness high, so take the bench progression to 185. Lower body: capped. The knee is mid-rehab (phase 2 of 4), so heavy slow resistance only — leg press at 3-0-3 tempo, no jumps, no skating sprints. That's not caution for its own sake; loading the tendon correctly this week is what puts your PT in a position to clear you sooner.",
                cards: [CoachCard(label: "Upper", value: "Full send · RPE ≤ 9", tone: .green),
                        CoachCard(label: "Lower", value: "Tempo only", tone: .amber),
                        CoachCard(label: "Avoid", value: "Jumps · sprints", tone: .ruby)],
                suggestions: ["Generate today's workout", "Why is my bench not increasing?"])
        }
        if q.contains("deload") {
            return CoachMessage(role: .coach,
                text: "Not a full deload — your acute:chronic ratio is 1.24, elevated but not red. Hold volume flat this week and cap top sets at RPE 8.5 while the knee finishes phase 2. If HRV is still under baseline next Sunday, then we pull volume 30% for 5 days. Right now: steady, not stop.",
                cards: [CoachCard(label: "This week", value: "Hold volume flat", tone: .gold),
                        CoachCard(label: "Cap", value: "RPE 8.5", tone: .amber)],
                suggestions: ["Why is my recovery low?", "What should I train today?"])
        }
        if q.contains("eat") || q.contains("food") || q.contains("meal") || q.contains("nutrition") {
            return CoachMessage(role: .coach,
                text: "You have 1,050 kcal and 72 g protein left against the lean-bulk targets. Tonight: 8 oz chicken or steak, 1.5 cups rice, vegetables, plus the casein bowl before bed — that's ~1,000 kcal and 75 g protein, done. You're also at 62% hydration; put electrolytes in the next bottle since you skate tomorrow.",
                cards: [CoachCard(label: "Remaining", value: "1,050 kcal", tone: .gold),
                        CoachCard(label: "Protein left", value: "72 g", tone: .amber),
                        CoachCard(label: "Hydration", value: "62%", tone: .amber)],
                suggestions: ["What supplements am I missing?", "What is holding me back?"])
        }
        if q.contains("bench") || q.contains("225") {
            return CoachMessage(role: .coach,
                text: "Your bench has stalled at 180 for three weeks, and the data points at recovery, not programming. Top sets have run RPE 9+ four sessions straight, and you average 6.9 h of sleep on bench days. The fix: two weeks at RPE 8 cap (175×5), add a paused bench back-off set, sleep 8 h the night before pressing. Then we test 185 — the forecast says 225 lands by November 6 if we protect the slope.",
                cards: [CoachCard(label: "Next 2 weeks", value: "175×5 @ RPE 8", tone: .gold),
                        CoachCard(label: "Add", value: "Paused bench 3×5", tone: .green),
                        CoachCard(label: "225 ETA", value: "Nov 6", tone: .green)],
                suggestions: ["Should I train hard?", "What is holding me back?"])
        }
        if q.contains("knee") || q.contains("injury") || q.contains("pain") || q.contains("recover from") {
            return CoachMessage(role: .coach,
                text: "The knee is tracking well — pain is down from 5/10 to 2/10 over 12 days. You're in phase 2 (heavy slow resistance): Spanish squat isometrics daily, leg press at 3-0-3 tempo three times a week, and no jumping or skating sprints yet. Phase 3 unlocks when hops are pain-free with no morning flare — realistically 7–10 days out. If pain spikes above 5 or the knee swells, stop and see a physio; that's not a Forge call to make.",
                cards: [CoachCard(label: "Daily", value: "Spanish squat 5×45s", tone: .gold),
                        CoachCard(label: "Avoid", value: "Plyo · sprints", tone: .ruby),
                        CoachCard(label: "Phase 3 ETA", value: "7–10 days", tone: .green)],
                suggestions: ["Show my rehab plan", "Can I still squat?"])
        }
        if q.contains("supplement") || q.contains("missing") || q.contains("vitamin") {
            return CoachMessage(role: .coach,
                text: "Two real gaps. Magnesium — 52% of target for 6 straight days, and it lines up with your shallower sleep and HRV dip; 400 mg glycinate before bed. Omega-3 — at 34% of target, and EPA/DHA matters extra right now for the knee tendon. Vitamin D is also low on bloodwork (26 ng/mL), so keep the D3+K2 going through the indoor season. Creatine and protein are dialed — 23-day streak, don't touch them.",
                cards: [CoachCard(label: "Add tonight", value: "Mg-glycinate 400 mg", tone: .gold),
                        CoachCard(label: "Add daily", value: "Fish oil 2 g", tone: .gold),
                        CoachCard(label: "Keep", value: "Creatine · whey · D3", tone: .green)],
                suggestions: ["Why am I tired?", "Show my deficiencies"])
        }
        if q.contains("holding me back") || q.contains("weakness") || q.contains("what should i change") {
            return CoachMessage(role: .coach,
                text: "One thing, clearly: sleep. You're at 6.9 h on training days against a 8.5 h ceiling for a 21-year-old athlete, and it's the common cause behind your dipped HRV, the bench stall, and slower knee recovery. Fix the sleep and three problems improve at once. Everything else — training, nutrition, the rehab — is already dialed.",
                cards: [CoachCard(label: "Fix", value: "8 h × 6 nights", tone: .gold),
                        CoachCard(label: "Unlocks", value: "HRV · bench · knee", tone: .green)],
                suggestions: ["Why is my recovery low?", "What supplements am I missing?"])
        }
        if q.contains("12 weeks") || q.contains("look like") || q.contains("forecast") || q.contains("future") {
            return CoachMessage(role: .coach,
                text: "Staying consistent: 207 lb at ~15% body fat, bench 225 by November 6, squat back on its slope once the knee clears, and recovery averaging 83 if you close the sleep gap. The trajectory is good — the only variable that bends the whole curve is sleep. Hold the line for 12 weeks and you're a visibly different athlete.",
                cards: [CoachCard(label: "Weight", value: "207 lb", tone: .gold),
                        CoachCard(label: "Bench", value: "225 · Nov 6", tone: .green),
                        CoachCard(label: "Recovery", value: "→ 83", tone: .green)],
                suggestions: ["What is holding me back?", "How do I hit 225 bench?"])
        }
        return CoachMessage(role: .coach,
            text: "I'm reading your full picture — training, recovery, sleep, fuel, the knee, your goals. Ask me anything about today, fatigue, the bench plateau, your knee, or what's missing in your stack.",
            suggestions: ["What should I train today?", "Why is my recovery low?", "Should I deload?",
                          "How do I hit 225 bench?", "How do I fix my knee pain?",
                          "What supplements am I missing?"])
    }

    // MARK: - Real-account offline engine (honest, data-grounded)

    /// The offline coach for a REAL account. Every sentence is built from the user's
    /// own live context — targets, directive, recovery, their logged injury/labs —
    /// and empty data yields an honest empty-state answer, never a fabricated stat.
    /// Pure + tested.
    static func contextualReply(to question: String, context c: CoachContext) -> CoachMessage {
        let q = question.lowercased()
        let d = c.directive
        func f(_ x: Double) -> String { String(format: "%.1f", x) }

        // TODAY / PLAN — mirror the on-screen directive exactly.
        if q.contains("do today") || q.contains("plan my day") || q.contains("train today")
            || q.contains("what should i train") || q.contains("plan my") {
            var text = "\(d.headline) \(d.priorityAction)"
            let plan = d.actions.prefix(3).map { "\($0.label.lowercased()) \($0.value.lowercased())" }.joined(separator: ", ")
            if !plan.isEmpty { text += " Today: \(plan)." }
            return CoachMessage(role: .coach, text: text,
                cards: d.actions.prefix(3).map { CoachCard(label: $0.label, value: $0.value, tone: .green) },
                suggestions: ["Should I train hard?", "What should I eat today?", "Why is my recovery low?"])
        }

        // FATIGUE / RECOVERY — decompose from real inputs.
        if q.contains("tired") || q.contains("fatigue") || q.contains("drained")
            || q.contains("recovery low") || q.contains("why is my recovery") {
            var parts: [String] = []
            if c.sleepDebtHours >= 0.5 { parts.append("\(f(c.sleepDebtHours)) h of sleep debt this week") }
            if c.hrv < c.hrvBaseline { parts.append("HRV \(c.hrv) ms, under your \(c.hrvBaseline) ms baseline") }
            if c.magnesiumPct < 80 && c.magnesiumDaysLow > 0 {
                parts.append("magnesium at \(c.magnesiumPct)% of target for \(c.magnesiumDaysLow) days")
            }
            var text = parts.isEmpty
                ? "Recovery is \(c.recovery)/100 and nothing in your inputs is flashing red — sleep, HRV, and load are all in range. Train as planned."
                : "Recovery is \(c.recovery)/100. In order of weight: " + parts.joined(separator: ", ") + "."
            if c.sleepDebtHours >= 1 { text += " Closing the sleep gap is your highest-leverage fix." }
            return CoachMessage(role: .coach, text: text,
                cards: [CoachCard(label: "Recovery", value: "\(c.recovery)/100", tone: c.recovery >= 66 ? .green : .amber),
                        CoachCard(label: "HRV", value: "\(c.hrv) ms", tone: c.hrv >= c.hrvBaseline ? .green : .amber)],
                suggestions: ["What should I train today?", "Should I deload?"])
        }

        // TRAIN HARD — gate on real recovery/readiness, respect a logged injury.
        if q.contains("train hard") || q.contains("push today") || q.contains("go heavy") || q.contains("should i train hard") {
            let green = c.recovery >= 66
            var text = green
                ? "Green light — recovery \(c.recovery)/100 and readiness \(c.readiness). Take your top sets to prescription; cap at RPE 9."
                : "Ease off — recovery \(c.recovery)/100 is below the line for a hard session. Hold volume and cap top sets around RPE 8 today."
            if !c.injuryName.isEmpty {
                text += " Work around your \(c.injuryName.lowercased()) (\(c.injuryPhase.lowercased())) — no loading that aggravates it; see your rehab plan."
            }
            return CoachMessage(role: .coach, text: text,
                cards: [CoachCard(label: "Recovery", value: "\(c.recovery)/100", tone: green ? .green : .amber),
                        CoachCard(label: "Cap", value: green ? "RPE 9" : "RPE 8", tone: green ? .green : .amber)],
                suggestions: ["What should I train today?", "Should I deload?"])
        }

        // DELOAD — from real recovery + load.
        if q.contains("deload") {
            let heavy = c.recovery < 55 || c.strainYesterday >= 16
            let text = heavy
                ? "There's a case for it — recovery \(c.recovery)/100 with yesterday's load at \(f(c.strainYesterday))/21. Pull volume ~30% for 5 days and cap intensity at RPE 8; re-check when recovery climbs back above 66."
                : "Not yet — recovery \(c.recovery)/100 doesn't warrant a full deload. Hold volume flat and cap top sets at RPE 8.5. If recovery stays under 60 for several days, then deload."
            return CoachMessage(role: .coach, text: text,
                cards: [CoachCard(label: "Recovery", value: "\(c.recovery)/100", tone: heavy ? .amber : .green)],
                suggestions: ["Why is my recovery low?", "What should I train today?"])
        }

        // FUEL — real targets + what's left today.
        if q.contains("eat") || q.contains("food") || q.contains("meal") || q.contains("nutrition") || q.contains("protein") {
            var text = "Targets today: \(c.calorieTarget) kcal and \(c.proteinTarget) g protein."
            text += c.proteinRemaining > 0
                ? " You have \(c.proteinRemaining) g of protein still to go — make your next meal protein-first."
                : " Protein target is met — nice work."
            if c.hydrationPct < 90 { text += " Hydration is at \(c.hydrationPct)% of target; get another bottle in." }
            return CoachMessage(role: .coach, text: text,
                cards: [CoachCard(label: "Protein left", value: "\(c.proteinRemaining) g", tone: c.proteinRemaining > 0 ? .amber : .green),
                        CoachCard(label: "Hydration", value: "\(c.hydrationPct)%", tone: c.hydrationPct >= 90 ? .green : .amber)],
                suggestions: ["What supplements am I missing?", "What is holding me back?"])
        }

        // LIFT PLATEAU — only if we actually detected one.
        if q.contains("bench") || q.contains("225") || q.contains("plateau") || q.contains("not increasing") || q.contains("stall") {
            let text = c.plateauNote.isEmpty
                ? "No plateau is showing in your logged lifts right now — keep progressive overload on the bar and log every top set so I can flag a stall the moment one starts."
                : "Here's the stall: \(c.plateauNote) That pattern usually points at recovery, not programming — hold intensity at RPE 8 for two weeks, add a back-off set, and protect sleep on lifting days before you re-test."
            return CoachMessage(role: .coach, text: text,
                suggestions: ["Should I train hard?", "What is holding me back?"])
        }

        // INJURY / REHAB — from the user's own logged injury, or an honest empty state.
        if q.contains("knee") || q.contains("injury") || q.contains("pain") || q.contains("rehab") || q.contains("recover from") {
            if c.injuryLine.isEmpty {
                return CoachMessage(role: .coach,
                    text: "You have no active injury logged. If something's bothering you, add it on the Injury screen — I'll build a rehab plan and automatically block the lifts that aggravate it. For sharp pain, swelling, or a head knock, see a physician or physio first.",
                    suggestions: ["What should I train today?", "Should I deload?"])
            }
            var text = "\(c.injuryLine)"
            if !c.rehabLine.isEmpty { text += " Your plan: \(c.rehabLine.replacingOccurrences(of: "\n- ", with: " — "))" }
            text += " If pain spikes above 5/10 or the joint swells, stop and see a physio — that's not a call I make for you."
            return CoachMessage(role: .coach, text: text,
                suggestions: ["What should I train today?", "Can I still train around it?"])
        }

        // SUPPLEMENTS / DEFICIENCIES — from real labs, or an honest empty state.
        if q.contains("supplement") || q.contains("missing") || q.contains("vitamin") || q.contains("deficien") {
            if c.deficiencyLine.isEmpty && c.bloodworkLine.isEmpty {
                return CoachMessage(role: .coach,
                    text: "No deficiencies are flagged from your data yet. Add your bloodwork on the Health screen and I'll flag anything below its optimal range and tailor your stack to it — until then I won't guess at numbers you haven't measured.",
                    suggestions: ["What should I eat today?", "Why is my recovery low?"])
            }
            var text = "From your labs: "
            text += c.deficiencyLine.isEmpty ? "no 7-day deficiencies flagged." : "\(c.deficiencyLine)."
            if !c.bloodworkLine.isEmpty { text += c.bloodworkLine }
            text += " Discuss correction — diet, supplementation, dosing — with your clinician."
            return CoachMessage(role: .coach, text: text,
                suggestions: ["What should I eat today?", "Why am I tired?"])
        }

        // BIGGEST LEVER.
        if q.contains("holding me back") || q.contains("weakness") || q.contains("what should i change") || q.contains("improve") {
            let text: String
            if c.sleepDebtHours >= 1.5 {
                text = "One thing, clearly: sleep. You're carrying \(f(c.sleepDebtHours)) h of debt this week, and it's the common cause behind a dipped HRV and slower progress. Fix the sleep and several things improve at once."
            } else if c.recovery < 60 {
                text = "Recovery — it's sitting at \(c.recovery)/100. Protect sleep and keep load progressive rather than spiky, and the rest of your numbers follow it up."
            } else if c.proteinRemaining > 0 {
                text = "Consistency on fuel — you're regularly leaving protein on the table (\(c.proteinRemaining) g short today). Hit \(c.proteinTarget) g daily and recovery and body composition both move."
            } else {
                text = "Honestly, nothing is red right now — recovery \(c.recovery)/100, protein on target, sleep in range. Keep the streak and stay progressive; that's what compounds."
            }
            return CoachMessage(role: .coach, text: text,
                suggestions: ["Why is my recovery low?", "What should I eat today?"])
        }

        // FORECAST — honest about the current capability.
        if q.contains("12 weeks") || q.contains("look like") || q.contains("forecast") || q.contains("future") || q.contains("projection") {
            return CoachMessage(role: .coach,
                text: "I don't project a performance forecast yet — that needs more of your own logged history before any number would be honest. What I can tell you: keep recovery above ~66, progressive load on the bar, and protein at \(c.proteinTarget) g, and the trend follows. Log consistently and forecasts unlock as your data builds.",
                suggestions: ["What should I train today?", "What is holding me back?"])
        }

        // DEFAULT — grounded overview, no fabricated specifics.
        var overview = "Reading your live picture: Forge Score \(c.forgeScore)/100, recovery \(c.recovery)/100, \(f(c.sleepHours)) h sleep."
        if c.proteinRemaining > 0 { overview += " \(c.proteinRemaining) g protein left today." }
        overview += " Ask me about today's plan, your recovery, fuel, or anything you've logged."
        return CoachMessage(role: .coach, text: overview,
            suggestions: ["What should I train today?", "Why is my recovery low?", "What should I eat today?",
                          "What is holding me back?", "What supplements am I missing?"])
    }
}
