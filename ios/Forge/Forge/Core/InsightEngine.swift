import Foundation

/// One factor explaining today's recovery — "Sleep · 7.2h, 1.3h under your 8.5h target".
struct RecoveryDriver: Identifiable {
    let id = UUID()
    let factor: String
    let detail: String
    let positive: Bool   // helping recovery vs hurting it
    let weight: Int      // magnitude, for ordering
}

/// A cross-module causal chain — the heart of "everything connects".
/// "Sleep debt 3.1h → HRV −6% → recovery held at 78", with the fix.
struct ForgeInsight: Identifiable {
    let id = UUID()
    let icon: String
    let chain: String
    let action: String
    let tone: Tone
    let severity: Int    // higher = surface first
}

/// Turns isolated signals into connected explanations. Pure logic, unit-tested,
/// zero UI — the same brain feeds the dashboard, the coach, and (later) widgets.
/// This is what makes Forge an operating system rather than twelve trackers.
enum InsightEngine {

    // MARK: - Recovery attribution ("Recovery is X because…")

    static func recoveryDrivers(
        recovery: Int,
        sleepHours: Double, sleepReference: Double,
        hrv: Int, hrvBaseline: Int,
        strainYesterday: Double, strainAvg: Double,
        restingHR: Int, restingHRBaseline: Int,
        magnesiumPct: Int, magnesiumDaysLow: Int
    ) -> [RecoveryDriver] {
        var out: [RecoveryDriver] = []

        // Sleep vs the athlete's need.
        let sleepDelta = sleepHours - sleepReference
        if sleepDelta <= -0.2 {
            out.append(RecoveryDriver(
                factor: "Sleep",
                detail: String(format: "%.1fh — %.1fh under your %.1fh target", sleepHours, -sleepDelta, sleepReference),
                positive: false, weight: Int(-sleepDelta * 12)))
        } else if sleepDelta >= 0.3 {
            out.append(RecoveryDriver(
                factor: "Sleep",
                detail: String(format: "%.1fh — at your %.1fh target", sleepHours, sleepReference),
                positive: true, weight: 4))
        }

        // HRV vs personal baseline.
        let hrvDelta = hrv - hrvBaseline
        if abs(hrvDelta) >= 2 {
            out.append(RecoveryDriver(
                factor: "HRV",
                detail: "\(hrv)ms — \(signed(hrvDelta))ms vs baseline (\(signed(pct(hrvDelta, hrvBaseline)))%)",
                positive: hrvDelta >= 0, weight: abs(hrvDelta) * 2))
        }

        // Yesterday's training strain.
        let strainDelta = strainYesterday - strainAvg
        if abs(strainDelta) >= 1.0 {
            out.append(RecoveryDriver(
                factor: "Training strain",
                detail: String(format: "%.1f yesterday — %@%% vs your average", strainYesterday, signed(Int((strainDelta / max(1, strainAvg) * 100).rounded()))),
                positive: strainDelta <= 0, weight: Int(abs(strainDelta) * 4)))
        }

        // Resting HR elevation (a stress / under-recovery tell).
        let rhrDelta = restingHR - restingHRBaseline
        if rhrDelta >= 3 {
            out.append(RecoveryDriver(
                factor: "Resting HR",
                detail: "\(restingHR)bpm — \(signed(rhrDelta)) above baseline",
                positive: false, weight: rhrDelta))
        }

        // Chronic magnesium shortfall — upstream of sleep depth + HRV.
        if magnesiumPct < 70 && magnesiumDaysLow >= 3 {
            out.append(RecoveryDriver(
                factor: "Magnesium",
                detail: "\(magnesiumPct)% of target for \(magnesiumDaysLow) days — degrades deep sleep & HRV",
                positive: false, weight: (70 - magnesiumPct) / 4 + magnesiumDaysLow))
        }

        return out.sorted { $0.weight > $1.weight }
    }

    // MARK: - Cross-module chains ("everything connects")

    static func crossModule(
        recovery: Int, sleepDebtHours: Double,
        hrv: Int, hrvBaseline: Int,
        proteinRemaining: Int, hydrationPct: Int,
        injuryName: String?, injuryPhase: String?, injuryPain: Int?,
        injuryRiskPercent: Int, injuryRiskBand: String,
        magnesiumPct: Int, magnesiumDaysLow: Int
    ) -> [ForgeInsight] {
        var out: [ForgeInsight] = []
        let hrvDelta = hrv - hrvBaseline

        // Sleep debt → HRV → recovery → today's training ceiling.
        if sleepDebtHours >= 1.5 {
            out.append(ForgeInsight(
                icon: "moon.zzz.fill",
                chain: "Sleep debt \(hours(sleepDebtHours)) → HRV \(signed(pct(hrvDelta, hrvBaseline)))% → recovery held at \(recovery)",
                action: "Bank 8h tonight and tomorrow's training ceiling rises.",
                tone: .royal, severity: 80 + Int(sleepDebtHours)))
        }

        // Magnesium → sleep depth → HRV (the upstream cause worth fixing first).
        if magnesiumPct < 70 && magnesiumDaysLow >= 3 {
            out.append(ForgeInsight(
                icon: "pills.fill",
                chain: "Magnesium \(magnesiumPct)% × \(magnesiumDaysLow)d → shallower deep sleep → suppressed HRV",
                action: "400mg glycinate before bed — the upstream fix for sleep + recovery.",
                tone: .gold, severity: 68 + magnesiumDaysLow))
        }

        // Training load + active injury → injury risk.
        if let name = injuryName, injuryRiskPercent >= 18 {
            let phase = injuryPhase.map { " (\($0.lowercased()))" } ?? ""
            out.append(ForgeInsight(
                icon: "exclamationmark.triangle.fill",
                chain: "Volume up while the \(name.lowercased()) is mid-rehab\(phase) → injury risk \(injuryRiskPercent)% (\(injuryRiskBand.lowercased()))",
                action: "Hold weekly volume flat and cap RPE 8.5 until it clears.",
                tone: .amber, severity: 55 + injuryRiskPercent))
        }

        // Hydration → recovery + next-session output.
        if hydrationPct < 75 {
            out.append(ForgeInsight(
                icon: "drop.fill",
                chain: "Hydration \(hydrationPct)% → blunted recovery & lower next-session output",
                action: "Add electrolytes to your next two bottles.",
                tone: hydrationPct < 60 ? .amber : .gold, severity: 35 + (75 - hydrationPct)))
        }

        // Protein gap → muscle retention during a bulk.
        if proteinRemaining >= 30 {
            out.append(ForgeInsight(
                icon: "fork.knife",
                chain: "Protein \(proteinRemaining)g short → muscle left on the table this bulk",
                action: "Protein-first dinner plus a casein bowl closes it.",
                tone: .gold, severity: 30 + proteinRemaining / 4))
        }

        return out.sorted { $0.severity > $1.severity }
    }

    // MARK: - Helpers

    private static func signed(_ n: Int) -> String { n >= 0 ? "+\(n)" : "\(n)" }

    private static func pct(_ delta: Int, _ base: Int) -> Int {
        guard base != 0 else { return 0 }
        return Int((Double(delta) / Double(base) * 100).rounded())
    }

    private static func hours(_ h: Double) -> String {
        let whole = Int(h)
        let mins = Int((h - Double(whole)) * 60)
        return mins > 0 ? "\(whole)h \(mins)m" : "\(whole)h"
    }
}
