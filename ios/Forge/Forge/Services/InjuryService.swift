import Foundation
import Observation

@Observable
final class InjuryService {
    /// The athlete's currently-active injuries. Editable and persisted; seeded with
    /// the demo knee only until the user manages their own (add / resolve).
    var active: [InjuryProfile] = [MockData.knee]
    var ptLibrary: [PTExercise] = MockData.ptExercises
    var protocols: [RehabProtocol] = MockData.protocols
    var rtsChecklist: [RTSChecklistItem] = MockData.kneeRTSChecklist
    var concussionSymptoms: [ConcussionSymptom] = MockData.concussionSymptoms
    var rtpStages: [RTPStage] = MockData.rtpStages
    var risk: InjuryRisk = MockData.injuryRisk

    private static let storageKey = "forge.injuries.v1"

    init() {
        // A managed set (even empty) wins over the demo seed, so a resolved
        // injury stays gone. Tests stay hermetic on the known demo seed.
        if !PersistenceService.isTestRun, let saved = Self.loadPersisted() {
            active = saved
        }
    }

    /// Feeds the Forge Score: 100 healthy, scaled down by active injury severity & pain.
    var injuryStatusScore: Int {
        guard let worst = active.max(by: { $0.severity < $1.severity }) else { return 100 }
        return max(40, 100 - worst.severity * 10 - worst.painToday * 3)
    }

    // MARK: - Editing (persisted)

    /// Log a new injury. Forge immediately blocks aggravating lifts (via the
    /// workout generator's injury flags) and queues the matching protocol.
    func add(type: InjuryType, phase: InjuryPhase, pain: Int) {
        active.append(Self.makeInjury(type: type, phase: phase, pain: pain))
        persist()
    }

    /// Mark an injury resolved — it stops constraining training immediately.
    func resolve(_ injury: InjuryProfile) {
        active.removeAll { $0.id == injury.id }
        persist()
    }

    func logPain(_ value: Int, for injury: InjuryProfile) {
        guard let idx = active.firstIndex(where: { $0.id == injury.id }) else { return }
        active[idx].painToday = value
        active[idx].painHistory.append(Double(value))
        persist()
    }

    /// Build a sensible new-injury profile from the minimal input the user gives.
    static func makeInjury(type: InjuryType, phase: InjuryPhase, pain: Int) -> InjuryProfile {
        let clampedPain = min(10, max(0, pain))
        let severity = min(5, max(1, (clampedPain + 1) / 2))   // 0–1→1 … 9–10→5
        return InjuryProfile(
            type: type,
            name: "\(type.rawValue) · \(phase.rawValue)",
            painToday: clampedPain, daysOld: 0, phase: phase,
            severity: severity, mobilityPct: 60, strengthPct: 55, stabilityPct: 65,
            notes: "Logged today. Forge blocks aggravating lifts and queues the matching protocol.",
            painHistory: [Double(clampedPain)])
    }

    // MARK: - Persistence

    private func persist() {
        guard !PersistenceService.isTestRun,
              let data = try? JSONEncoder().encode(active) else { return }
        UserDefaults.standard.set(data, forKey: Self.storageKey)
    }

    private static func loadPersisted() -> [InjuryProfile]? {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else { return nil }
        return try? JSONDecoder().decode([InjuryProfile].self, from: data)
    }

    func toggleChecklist(_ item: RTSChecklistItem) {
        guard let idx = rtsChecklist.firstIndex(where: { $0.id == item.id }) else { return }
        rtsChecklist[idx].done.toggle()
    }

    func setSymptom(_ symptom: ConcussionSymptom, value: Int) {
        guard let idx = concussionSymptoms.firstIndex(where: { $0.id == symptom.id }) else { return }
        concussionSymptoms[idx].value = value
    }

    func ptExercises(named names: [String]) -> [PTExercise] {
        names.compactMap { name in ptLibrary.first { $0.name == name } }
    }
}
