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
            directive: directive)
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
        guard ForgeConfig.aiMode != .mock else { return mockReply(to: question) }
        do {
            let text = try await callClaude(question: question, history: history,
                                            context: context, checkInNote: checkInNote)
            return CoachMessage(role: .coach, text: text, suggestions: Array(quickPrompts.prefix(4)))
        } catch {
            return mockReply(to: question)
        }
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
        let knee = MockData.knee
        let defs = MockData.deficiencies.prefix(3).map { "\($0.nutrient) \($0.current)/\($0.target) (\($0.daysLow)d low)" }.joined(separator: ", ")
        let vitD = MockData.bloodwork.first { $0.name.contains("Vitamin D") }
        let benchForecast = MockData.forecasts.first { $0.metric == "Bench Press" }
        let directive = c.directive

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
        - Right now: \(c.proteinRemaining)g protein still to go today; hydration at \(c.hydrationPct)% of target.
        - Deficiencies (7-day): \(defs).\(vitD.map { " Bloodwork Vitamin D \(Int($0.value)) ng/mL (low)." } ?? "")

        INJURY
        - \(knee.name): day \(knee.daysOld), \(knee.phase.rawValue), pain \(knee.painToday)/10. Avoid plyometrics and skating sprints; heavy-slow-resistance and isometrics only.

        FORECAST
        - \(benchForecast.map { "\($0.metric): \($0.current) → \($0.projected) by \($0.eta) if consistent." } ?? "Trending up if recovery holds.")

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
            injuryName: knee.type.rawValue, injuryPhase: knee.phase.rawValue, injuryPain: knee.painToday,
            injuryRiskPercent: MockData.injuryRisk.percent, injuryRiskBand: MockData.injuryRisk.band,
            magnesiumPct: c.magnesiumPct, magnesiumDaysLow: c.magnesiumDaysLow)
        if !insights.isEmpty {
            ctx += "\n\nCROSS-MODULE CONNECTIONS (reason in these chains — this is how Forge thinks)"
            for ins in insights.prefix(3) { ctx += "\n- \(ins.chain) → \(ins.action)" }
        }

        // Rehab — today's PT prescription + return-to-sport readiness.
        let rehab = RehabEngine.plan(for: knee, library: MockData.ptExercises, protocols: MockData.protocols)
        let readiness = RehabEngine.readiness(checklist: MockData.kneeRTSChecklist, injury: knee)
        ctx += "\n\nREHAB (prescribe this exact plan when asked about the injury or rehab)"
        ctx += "\n- \(rehab.title): \(rehab.focus)"
        ctx += "\n- " + rehab.exercises.prefix(4).map { "\($0.name) \($0.prescription)" }.joined(separator: " · ")
        ctx += "\n- Return-to-sport readiness \(readiness.percent)% (\(readiness.band)), \(readiness.etaText)."
        if let next = readiness.nextMilestone { ctx += " Next milestone: \(next)." }

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
                steps: ["Recovery 78 → green light for upper intensity",
                        "Knee phase 2 → isometrics + slow tempo only, no jumps",
                        "Protein pace: 128 g by 4 PM vs 200 g target",
                        "Sleep debt 3.1 h → lights out 22:30"],
                cards: [CoachCard(label: "Train", value: "Upper Push · bench 185", tone: .green),
                        CoachCard(label: "Rehab", value: "Knee block · 12 min", tone: .amber),
                        CoachCard(label: "Fuel", value: "+72 g protein", tone: .gold)],
                suggestions: ["Should I train hard?", "What should I eat?", "How's my knee tracking?"])
        }
        if q.contains("tired") || q.contains("fatigue") || q.contains("drained") || q.contains("recovery low") {
            return CoachMessage(role: .coach,
                text: "Stacked, in order of weight: you're carrying 3.1 hours of sleep debt this week, HRV is 6% under baseline (58 vs 62), and magnesium has run at 52% of target for 6 days — low Mg reliably degrades both of the first two. Fix tonight: Mg-glycinate 400 mg, lights out 22:30, and tomorrow will read differently.",
                steps: ["Sleep: 5 of 7 nights under 8 h",
                        "HRV 58 ms vs 62 baseline (−6%)",
                        "Magnesium 52% of target, 6 days running",
                        "Strain yesterday 14.2 — moderate, not the culprit"],
                cards: [CoachCard(label: "Tonight", value: "Mg 400 mg + 22:30", tone: .gold),
                        CoachCard(label: "Tomorrow", value: "Re-check HRV", tone: .green)],
                suggestions: ["What supplement am I missing?", "Should I deload?"])
        }
        if q.contains("train hard") || q.contains("push today") || q.contains("go heavy") {
            return CoachMessage(role: .coach,
                text: "Upper body: yes — recovery 78 and readiness high, so take the bench progression to 185. Lower body: capped. The knee is mid-rehab (phase 2 of 4), so heavy slow resistance only — leg press at 3-0-3 tempo, no jumps, no skating sprints. That's not caution for its own sake; loading the tendon correctly this week is what puts your PT in a position to clear you sooner.",
                steps: ["Recovery 78 / readiness High",
                        "HRV −6% — fine for strength, watch volume",
                        "Knee phase 2 → tempo work yes, plyo no",
                        "ACR 1.24 → hold weekly volume flat"],
                cards: [CoachCard(label: "Upper", value: "Full send · RPE ≤ 9", tone: .green),
                        CoachCard(label: "Lower", value: "Tempo only", tone: .amber),
                        CoachCard(label: "Avoid", value: "Jumps · sprints", tone: .ruby)],
                suggestions: ["Generate today's workout", "Why is my bench not increasing?"])
        }
        if q.contains("deload") {
            return CoachMessage(role: .coach,
                text: "Not a full deload — your acute:chronic ratio is 1.24, elevated but not red. Hold volume flat this week and cap top sets at RPE 8.5 while the knee finishes phase 2. If HRV is still under baseline next Sunday, then we pull volume 30% for 5 days. Right now: steady, not stop.",
                steps: ["ACR 1.24 — elevated, not critical",
                        "HRV 58 vs 62 baseline",
                        "Knee phase 2/4 — protect, don't detrain",
                        "Re-check Sunday"],
                cards: [CoachCard(label: "This week", value: "Hold volume flat", tone: .gold),
                        CoachCard(label: "Cap", value: "RPE 8.5", tone: .amber)],
                suggestions: ["Why is my recovery low?", "What should I train today?"])
        }
        if q.contains("eat") || q.contains("food") || q.contains("meal") || q.contains("nutrition") {
            return CoachMessage(role: .coach,
                text: "You have 1,050 kcal and 72 g protein left against the lean-bulk targets. Tonight: 8 oz chicken or steak, 1.5 cups rice, vegetables, plus the casein bowl before bed — that's ~1,000 kcal and 75 g protein, done. You're also at 62% hydration; put electrolytes in the next bottle since you skate tomorrow.",
                steps: ["Consumed: 2,150 / 3,200 kcal",
                        "Protein: 128 / 200 g",
                        "Water: 74 / 120 oz",
                        "Surplus target: +280 kcal for 0.6 lb/wk gain"],
                cards: [CoachCard(label: "Remaining", value: "1,050 kcal", tone: .gold),
                        CoachCard(label: "Protein left", value: "72 g", tone: .amber),
                        CoachCard(label: "Hydration", value: "62%", tone: .amber)],
                suggestions: ["What supplements am I missing?", "What is holding me back?"])
        }
        if q.contains("bench") || q.contains("225") {
            return CoachMessage(role: .coach,
                text: "Your bench has stalled at 180 for three weeks, and the data points at recovery, not programming. Top sets have run RPE 9+ four sessions straight, and you average 6.9 h of sleep on bench days. The fix: two weeks at RPE 8 cap (175×5), add a paused bench back-off set, sleep 8 h the night before pressing. Then we test 185 — the forecast says 225 lands by November 6 if we protect the slope.",
                steps: ["Top-set RPE trend: 9, 9, 9.5, 9",
                        "Sleep on bench days: 6.9 h avg vs 7.5 overall",
                        "Chest volume 13 sets/wk — already optimal",
                        "Est. 1RM 207 — strength is there, expression isn't"],
                cards: [CoachCard(label: "Next 2 weeks", value: "175×5 @ RPE 8", tone: .gold),
                        CoachCard(label: "Add", value: "Paused bench 3×5", tone: .green),
                        CoachCard(label: "225 ETA", value: "Nov 6", tone: .green)],
                suggestions: ["Should I train hard?", "What is holding me back?"])
        }
        if q.contains("knee") || q.contains("injury") || q.contains("pain") || q.contains("recover from") {
            return CoachMessage(role: .coach,
                text: "The knee is tracking well — pain is down from 5/10 to 2/10 over 12 days. You're in phase 2 (heavy slow resistance): Spanish squat isometrics daily, leg press at 3-0-3 tempo three times a week, and no jumping or skating sprints yet. Phase 3 unlocks when hops are pain-free with no morning flare — realistically 7–10 days out. If pain spikes above 5 or the knee swells, stop and see a physio; that's not a Forge call to make.",
                steps: ["Patellar tendinopathy · day 12 · phase 2/4",
                        "Pain trend: 5 → 2 over 12 days",
                        "Strength 74% of healthy side — gap closing",
                        "RTS checklist: 3 of 6 cleared"],
                cards: [CoachCard(label: "Daily", value: "Spanish squat 5×45s", tone: .gold),
                        CoachCard(label: "Avoid", value: "Plyo · sprints", tone: .ruby),
                        CoachCard(label: "Phase 3 ETA", value: "7–10 days", tone: .green)],
                suggestions: ["Show my rehab plan", "Can I still squat?"])
        }
        if q.contains("supplement") || q.contains("missing") || q.contains("vitamin") {
            return CoachMessage(role: .coach,
                text: "Two real gaps. Magnesium — 52% of target for 6 straight days, and it lines up with your shallower sleep and HRV dip; 400 mg glycinate before bed. Omega-3 — at 34% of target, and EPA/DHA matters extra right now for the knee tendon. Vitamin D is also low on bloodwork (26 ng/mL), so keep the D3+K2 going through the indoor season. Creatine and protein are dialed — 23-day streak, don't touch them.",
                steps: ["Mg: 218 / 420 mg avg — 6 days low",
                        "Omega-3: 0.8 / 2.5 g — 9 days low",
                        "Vit D bloodwork: 26 ng/mL (optimal 50–70)",
                        "Creatine: 100% — 23-day streak"],
                cards: [CoachCard(label: "Add tonight", value: "Mg-glycinate 400 mg", tone: .gold),
                        CoachCard(label: "Add daily", value: "Fish oil 2 g", tone: .gold),
                        CoachCard(label: "Keep", value: "Creatine · whey · D3", tone: .green)],
                suggestions: ["Why am I tired?", "Show my deficiencies"])
        }
        if q.contains("holding me back") || q.contains("weakness") || q.contains("what should i change") {
            return CoachMessage(role: .coach,
                text: "One thing, clearly: sleep. You're at 6.9 h on training days against a 8.5 h ceiling for a 21-year-old athlete, and it's the common cause behind your dipped HRV, the bench stall, and slower knee recovery. Fix the sleep and three problems improve at once. Everything else — training, nutrition, the rehab — is already dialed.",
                steps: ["Sleep debt 3.1 h — the root cause",
                        "Knock-on: HRV −6%, bench stall, slower rehab",
                        "Training + nutrition adherence already high",
                        "Highest-leverage single change available"],
                cards: [CoachCard(label: "Fix", value: "8 h × 6 nights", tone: .gold),
                        CoachCard(label: "Unlocks", value: "HRV · bench · knee", tone: .green)],
                suggestions: ["Why is my recovery low?", "What supplements am I missing?"])
        }
        if q.contains("12 weeks") || q.contains("look like") || q.contains("forecast") || q.contains("future") {
            return CoachMessage(role: .coach,
                text: "Staying consistent: 207 lb at ~15% body fat, bench 225 by November 6, squat back on its slope once the knee clears, and recovery averaging 83 if you close the sleep gap. The trajectory is good — the only variable that bends the whole curve is sleep. Hold the line for 12 weeks and you're a visibly different athlete.",
                steps: ["Weight 200 → 207 lb (+0.6/wk)",
                        "Bench 180 → 225 by Nov 6",
                        "Body fat ~15% (lean-bulk drift)",
                        "Recovery avg 75 → 83 with sleep fix"],
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
}
