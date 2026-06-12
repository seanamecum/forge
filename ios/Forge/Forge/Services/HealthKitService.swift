import Foundation
import Observation
import HealthKit

enum HealthAuthState: Equatable {
    case notDetermined
    case authorized
    case denied
    case unavailable
}

/// Full HealthKit bridge: reads steps, heart rate, resting HR, HRV, active energy,
/// workouts, sleep, and body mass; writes workouts and body mass.
/// Every value is mock-seeded so the app behaves identically when Health data is
/// unavailable, denied, or empty — offline-safe by construction.
@Observable
final class HealthKitService {
    private let store = HKHealthStore()

    var authState: HealthAuthState = .notDetermined
    var statusMessage = "Not connected — demo data active"
    var lastError: String?
    var isLoading = false
    var usingMockData = true

    // Latest readings (mock-seeded; overwritten by real reads when available)
    var steps: Int = MockData.today.steps
    var heartRate: Int = 61
    var restingHeartRate: Int = MockData.today.restingHR
    var hrvMs: Int = MockData.today.hrv
    var activeEnergy: Int = MockData.today.caloriesOut
    var bodyMassLb: Double = MockData.sean.weightLb
    var sleepHoursLastNight: Double = MockData.today.sleep.hours
    var workoutsLast7Days: Int = 4

    var isAvailable: Bool { HKHealthStore.isHealthDataAvailable() }

    // MARK: - Types

    private var readTypes: Set<HKObjectType> {
        [
            HKQuantityType(.stepCount),
            HKQuantityType(.heartRate),
            HKQuantityType(.restingHeartRate),
            HKQuantityType(.heartRateVariabilitySDNN),
            HKQuantityType(.activeEnergyBurned),
            HKQuantityType(.bodyMass),
            HKCategoryType(.sleepAnalysis),
            HKObjectType.workoutType(),
        ]
    }

    private var writeTypes: Set<HKSampleType> {
        [HKObjectType.workoutType(), HKQuantityType(.bodyMass)]
    }

    // MARK: - Authorization

    func connect() async {
        guard isAvailable else {
            authState = .unavailable
            statusMessage = "Health data isn't available on this device — demo data active."
            return
        }
        isLoading = true
        defer { isLoading = false }
        do {
            try await store.requestAuthorization(toShare: writeTypes, read: readTypes)
            // Read-permission status is hidden by design; share status is our best signal.
            if store.authorizationStatus(for: HKObjectType.workoutType()) == .sharingDenied {
                authState = .denied
                statusMessage = "Health access denied. Enable Forge in Settings → Privacy & Security → Health."
                return
            }
            authState = .authorized
            statusMessage = "Connected to Apple Health"
            await refresh()
        } catch {
            authState = .denied
            lastError = error.localizedDescription
            statusMessage = "Health authorization failed — demo data active."
        }
    }

    // MARK: - Reads

    func refresh() async {
        guard authState == .authorized else { return }
        isLoading = true
        defer { isLoading = false }
        var gotRealData = false

        if let v = await sumToday(.stepCount, unit: .count()) { steps = Int(v); gotRealData = true }
        if let v = await sumToday(.activeEnergyBurned, unit: .kilocalorie()) { activeEnergy = Int(v); gotRealData = true }
        if let v = await latest(.heartRate, unit: HKUnit.count().unitDivided(by: .minute())) { heartRate = Int(v); gotRealData = true }
        if let v = await latest(.restingHeartRate, unit: HKUnit.count().unitDivided(by: .minute())) { restingHeartRate = Int(v); gotRealData = true }
        if let v = await latest(.heartRateVariabilitySDNN, unit: .secondUnit(with: .milli)) { hrvMs = Int(v); gotRealData = true }
        if let v = await latest(.bodyMass, unit: .pound()) { bodyMassLb = v; gotRealData = true }
        if let v = await sleepHours() { sleepHoursLastNight = v; gotRealData = true }
        if let v = await workoutCount(days: 7) { workoutsLast7Days = v; gotRealData = true }

        usingMockData = !gotRealData
        statusMessage = gotRealData
            ? "Connected · live Health data"
            : "Connected — no Health samples yet, showing demo values."
    }

    // MARK: - Writes

    /// Save a strength workout to Apple Health via HKWorkoutBuilder.
    @discardableResult
    func saveWorkout(start: Date, end: Date, calories: Double) async -> Bool {
        guard authState == .authorized else {
            lastError = "Connect Apple Health before saving workouts."
            return false
        }
        let config = HKWorkoutConfiguration()
        config.activityType = .traditionalStrengthTraining
        let builder = HKWorkoutBuilder(healthStore: store, configuration: config, device: .local())
        do {
            try await builder.beginCollection(at: start)
            if calories > 0 {
                let sample = HKQuantitySample(
                    type: HKQuantityType(.activeEnergyBurned),
                    quantity: HKQuantity(unit: .kilocalorie(), doubleValue: calories),
                    start: start, end: end
                )
                try await builder.addSamples([sample])
            }
            try await builder.endCollection(at: end)
            _ = try await builder.finishWorkout()
            lastError = nil
            return true
        } catch {
            lastError = "Couldn't save workout: \(error.localizedDescription)"
            return false
        }
    }

    /// Save a body-mass measurement to Apple Health.
    @discardableResult
    func saveBodyMass(_ pounds: Double) async -> Bool {
        guard authState == .authorized else {
            lastError = "Connect Apple Health before saving measurements."
            return false
        }
        let sample = HKQuantitySample(
            type: HKQuantityType(.bodyMass),
            quantity: HKQuantity(unit: .pound(), doubleValue: pounds),
            start: .now, end: .now
        )
        do {
            try await store.save(sample)
            bodyMassLb = pounds
            lastError = nil
            return true
        } catch {
            lastError = "Couldn't save weight: \(error.localizedDescription)"
            return false
        }
    }

    // MARK: - Query helpers

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

    private func latest(_ id: HKQuantityTypeIdentifier, unit: HKUnit) async -> Double? {
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

    /// Sum asleep-stage durations from the last 24 h.
    private func sleepHours() async -> Double? {
        let type = HKCategoryType(.sleepAnalysis)
        let start = Calendar.current.date(byAdding: .hour, value: -24, to: .now) ?? .now
        let predicate = HKQuery.predicateForSamples(withStart: start, end: .now)
        let asleepValues: Set<Int> = [
            HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue,
            HKCategoryValueSleepAnalysis.asleepCore.rawValue,
            HKCategoryValueSleepAnalysis.asleepDeep.rawValue,
            HKCategoryValueSleepAnalysis.asleepREM.rawValue,
        ]
        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(sampleType: type, predicate: predicate,
                                      limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, samples, _ in
                guard let samples = samples as? [HKCategorySample], !samples.isEmpty else {
                    continuation.resume(returning: nil)
                    return
                }
                let seconds = samples
                    .filter { asleepValues.contains($0.value) }
                    .reduce(0.0) { $0 + $1.endDate.timeIntervalSince($1.startDate) }
                continuation.resume(returning: seconds > 60 ? seconds / 3600 : nil)
            }
            store.execute(query)
        }
    }

    private func workoutCount(days: Int) async -> Int? {
        let start = Calendar.current.date(byAdding: .day, value: -days, to: .now) ?? .now
        let predicate = HKQuery.predicateForSamples(withStart: start, end: .now)
        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(sampleType: HKObjectType.workoutType(), predicate: predicate,
                                      limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, samples, _ in
                continuation.resume(returning: samples?.count)
            }
            store.execute(query)
        }
    }
}
