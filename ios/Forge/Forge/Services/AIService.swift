import Foundation

/// The brain. Rule-based for the prototype — swap `reply(to:)` internals for a
/// Claude API call later; the message/cards/steps shape is already LLM-friendly.
enum AIService {

    static func dailyBrief(forgeScore: Int) -> String {
        let d = MockData.today
        return "Forge Score \(forgeScore). Recovery \(d.recovery) — you're cleared to push upper body. " +
        "Knee stays in rehab loading (no plyo). Close the 72 g protein gap by 9 PM, and get lights-out by 22:30 — sleep is your one lagging input."
    }

    static func reply(to question: String) -> CoachMessage {
        let q = question.lowercased()

        if q.contains("do today") || q.contains("plan my day") {
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
        if q.contains("tired") || q.contains("fatigue") || q.contains("drained") {
            return CoachMessage(role: .coach,
                text: "Stacked, in order of weight: you're carrying 3.1 hours of sleep debt this week, HRV is 6% under baseline (58 vs 62), and magnesium has run at 52% of target for 6 days — low Mg reliably degrades both of the first two. Fix tonight: Mg-glycinate 400 mg, lights out 22:30, and tomorrow will read differently.",
                steps: ["Sleep: 5 of 7 nights under 8 h",
                        "HRV 58 ms vs 62 baseline (−6%)",
                        "Magnesium 52% of target, 6 days running",
                        "Strain yesterday 14.2 — moderate, not the culprit"],
                cards: [CoachCard(label: "Tonight", value: "Mg 400 mg + 22:30", tone: .gold),
                        CoachCard(label: "Tomorrow", value: "Re-check HRV", tone: .green)],
                suggestions: ["What supplement am I missing?", "Should I take a rest day?"])
        }
        if q.contains("train hard") || q.contains("push today") || q.contains("go heavy") {
            return CoachMessage(role: .coach,
                text: "Upper body: yes — recovery 78 and readiness high, so take the bench progression to 185. Lower body: capped. The knee is mid-rehab (phase 2 of 4), so heavy slow resistance only — leg press at 3-0-3 tempo, no jumps, no skating sprints. That's not caution for its own sake; loading the tendon correctly this week is what gets you cleared next week.",
                steps: ["Recovery 78 / readiness High",
                        "HRV −6% — fine for strength, watch volume",
                        "Knee phase 2 → tempo work yes, plyo no",
                        "ACR 1.24 → hold weekly volume flat"],
                cards: [CoachCard(label: "Upper", value: "Full send · RPE ≤ 9", tone: .green),
                        CoachCard(label: "Lower", value: "Tempo only", tone: .amber),
                        CoachCard(label: "Avoid", value: "Jumps · sprints", tone: .ruby)],
                suggestions: ["Generate today's workout", "Why is my bench not increasing?"])
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
                suggestions: ["What supplement am I missing?", "Build me a dinner"])
        }
        if q.contains("bench") {
            return CoachMessage(role: .coach,
                text: "Your bench has stalled at 180 for three weeks, and the data points at recovery, not programming. Top sets have run RPE 9+ four sessions straight, and you average 6.9 h of sleep on bench days. At your training age that combination flatlines progress. The fix: two weeks at RPE 8 cap (175×5), add a paused bench back-off set, sleep 8 h the night before pressing. Then we test 185 — the forecast says 225 lands in November if we protect the slope.",
                steps: ["Top-set RPE trend: 9, 9, 9.5, 9",
                        "Sleep on bench days: 6.9 h avg vs 7.5 overall",
                        "Chest volume 13 sets/wk — already optimal",
                        "Est. 1RM 207 — strength is there, expression isn't"],
                cards: [CoachCard(label: "Next 2 weeks", value: "175×5 @ RPE 8", tone: .gold),
                        CoachCard(label: "Add", value: "Paused bench 3×5", tone: .green),
                        CoachCard(label: "Test day", value: "185×5 · June 24", tone: .green)],
                suggestions: ["Show my PR history", "Should I train hard?"])
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
        return CoachMessage(role: .coach,
            text: "I'm reading your full picture — training, recovery, sleep, fuel, the knee, your goals. Ask me anything about today, fatigue, the bench plateau, your knee, or what's missing in your stack.",
            suggestions: ["What should I do today?", "Why am I tired?", "Should I train hard?",
                          "Why is my bench not increasing?", "How do I recover from knee pain?",
                          "What supplement am I missing?"])
    }
}
