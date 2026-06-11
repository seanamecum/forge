import Foundation
import Observation
import HealthKit

/// HealthKit bridge. Real reads when authorized; graceful mock fallback otherwise,
/// so the demo runs identically on Simulator and devices without Health data.
@Observable
final class HealthKitService {
    private let store = HKHealthStore()

    var isAvailable: Bool { HKHealthStore.isHealthDataAvailable() }
    var isAuthorized = false
    var statusMessage = "Not connected"

    // Latest readings (mock-seeded; overwritten by real reads when available).
    var steps: Int = MockData.today.steps
    var heartRate: Int = 61
    var activeEnergy: Int = MockData.today.caloriesOut
    var weightLb: Double = MockData.sean.weightLb
    var sleepHours: Double = MockData.today.sleep.hours

    private var readTypes: Set<HKObjectType> {
        var set = Set<HKObjectType>()
        set.insert(HKQuantityType(.stepCount))
        set.insert(HKQuantityType(.heartRate))
        set.insert(HKQuantityType(.activeEnergyBurned))
        set.insert(HKQuantityType(.bodyMass))
        set.insert(HKCategoryType(.sleepAnalysis))
        return set
    }

    func connect() async {
        guard isAvailable else {
            statusMessage = "Health data unavailable on this device — using demo data."
            return
        }
        do {
            try await store.requestAuthorization(toShare: [], read: readTypes)
            isAuthorized = true
            statusMessage = "Connected to Apple Health"
            await refresh()
        } catch {
            statusMessage = "Health access unavailable — using demo data."
        }
    }

    func refresh() async {
        guard isAuthorized else { return }
        if let todaySteps = await sumToday(.stepCount, unit: .count()) {
            steps = Int(todaySteps)
        }
        if let energy = await sumToday(.activeEnergyBurned, unit: .kilocalorie()) {
            activeEnergy = Int(energy)
        }
        if let bpm = await latestQuantity(.heartRate, unit: HKUnit.count().unitDivided(by: .minute())) {
            heartRate = Int(bpm)
        }
        if let lb = await latestQuantity(.bodyMass, unit: .pound()) {
            weightLb = lb
        }
        // Sleep stays mock in the prototype; category-sample aggregation comes with the backend pass.
    }

    private func sumToday(_ id: HKQuantityTypeIdentifier, unit: HKUnit) async -> Double? {
        let type = HKQuantityType(id)
        let start = Calendar.current.startOfDay(for: .now)
        let predicate = HKQuery.predicateForSamples(withStart: start, end: .now)

        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(quantityType: type,
                                          quantitySamplePredicate: predicate,
                                          options: .cumulativeSum) { _, stats, _ in
                continuation.resume(returning: stats?.sumQuantity()?.doubleValue(for: unit))
            }
            store.execute(query)
        }
    }

    private func latestQuantity(_ id: HKQuantityTypeIdentifier, unit: HKUnit) async -> Double? {
        let type = HKQuantityType(id)
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)

        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(sampleType: type, predicate: nil,
                                      limit: 1, sortDescriptors: [sort]) { _, samples, _ in
                let value = (samples?.first as? HKQuantitySample)?.quantity.doubleValue(for: unit)
                continuation.resume(returning: value)
            }
            store.execute(query)
        }
    }
}
