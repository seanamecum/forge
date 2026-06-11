import Foundation
import Observation

@Observable
final class InjuryService {
    var active: [InjuryProfile] = [MockData.knee]
    var ptLibrary: [PTExercise] = MockData.ptExercises
    var protocols: [RehabProtocol] = MockData.protocols
    var rtsChecklist: [RTSChecklistItem] = MockData.kneeRTSChecklist
    var concussionSymptoms: [ConcussionSymptom] = MockData.concussionSymptoms
    var rtpStages: [RTPStage] = MockData.rtpStages
    var risk: InjuryRisk = MockData.injuryRisk

    /// Feeds the Forge Score: 100 healthy, scaled down by active injury severity & pain.
    var injuryStatusScore: Int {
        guard let worst = active.max(by: { $0.severity < $1.severity }) else { return 100 }
        return max(40, 100 - worst.severity * 10 - worst.painToday * 3)
    }

    func logPain(_ value: Int, for injury: InjuryProfile) {
        guard let idx = active.firstIndex(where: { $0.id == injury.id }) else { return }
        active[idx].painToday = value
        active[idx].painHistory.append(Double(value))
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
