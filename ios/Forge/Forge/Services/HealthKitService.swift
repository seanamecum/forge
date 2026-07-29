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

    /// End-date of the most recent real sample per metric — the basis for honest
    /// freshness ("HRV as of 2 days ago") instead of treating every read as current.
    private(set) var sampleDates: [MetricKind: Date] = [:]

    /// The athlete's OWN baselines, computed from HealthKit history (nil until
    /// there's enough real data — the caller then keeps the demo-labeled value).
    private(set) var hrvBaselineLive: Int?
    private(set) var sleepDebtLive: Double?
    /// Recent real history, exposed so the intelligence layer can chart the user's
    /// own trend instead of the demo athlete's (empty until read).
    private(set) var dailyHRVHistory: [Double] = []
    private(set) var nightlySleepHistory: [Double] = []

    var isAvailable: Bool { HKHealthStore.isHealthDataAvailable() }

    /// How old (hours) the latest real sample for a metric is, or nil if none.
    func ageHours(for kind: MetricKind, now: Date = .now) -> Double? {
        guard let date = sampleDates[kind] else { return nil }
        return max(0, now.timeIntervalSince(date) / 3600)
    }

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
        [HKObjectType.workoutType(), HKQuantityType(.bodyMass),
         HKQuantityType(.distanceWalkingRunning), HKQuantityType(.activeEnergyBurned)]
    }

    // MARK: - Authorization

    @MainActor
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

    @MainActor
    func refresh() async {
        guard authState == .authorized else { return }
        isLoading = true
        defer { isLoading = false }
        var gotRealData = false

        if let v = await sumToday(.stepCount, unit: .count()) { steps = Int(v); gotRealData = true }
        if let v = await sumToday(.activeEnergyBurned, unit: .kilocalorie()) { activeEnergy = Int(v); gotRealData = true }
        if let r = await latest(.heartRate, unit: HKUnit.count().unitDivided(by: .minute())) {
            heartRate = Int(r.value); sampleDates[.heartRate] = r.date; gotRealData = true
        }
        if let r = await latest(.restingHeartRate, unit: HKUnit.count().unitDivided(by: .minute())) {
            restingHeartRate = Int(r.value); sampleDates[.restingHR] = r.date; gotRealData = true
        }
        if let r = await latest(.heartRateVariabilitySDNN, unit: .secondUnit(with: .milli)) {
            hrvMs = Int(r.value); sampleDates[.hrv] = r.date; gotRealData = true
        }
        if let r = await latest(.bodyMass, unit: .pound()) { bodyMassLb = r.value; gotRealData = true }
        if let v = await sleepHours() { sleepHoursLastNight = v; gotRealData = true }
        if let v = await workoutCount(days: 7) { workoutsLast7Days = v; gotRealData = true }

        // Personal baselines from real history — the athlete's own HRV baseline and
        // sleep debt, so recovery isn't computed against the demo athlete's numbers.
        await refreshBaselines()

        usingMockData = !gotRealData
        statusMessage = gotRealData
            ? "Connected · live Health data"
            : "Connected — no Health samples yet, showing demo values."
    }

    // MARK: - Writes

    /// Save a strength workout to Apple Health via HKWorkoutBuilder.
    @MainActor
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

    /// Save a GPS run to Apple Health with distance.
    @discardableResult
    func saveRun(start: Date, end: Date, meters: Double, calories: Double) async -> Bool {
        guard authState == .authorized else { return false }
        let config = HKWorkoutConfiguration()
        config.activityType = .running
        config.locationType = .outdoor
        let builder = HKWorkoutBuilder(healthStore: store, configuration: config, device: .local())
        do {
            try await builder.beginCollection(at: start)
            var samples: [HKSample] = []
            if meters > 0 {
                samples.append(HKQuantitySample(
                    type: HKQuantityType(.distanceWalkingRunning),
                    quantity: HKQuantity(unit: .meter(), doubleValue: meters),
                    start: start, end: end))
            }
            if calories > 0 {
                samples.append(HKQuantitySample(
                    type: HKQuantityType(.activeEnergyBurned),
                    quantity: HKQuantity(unit: .kilocalorie(), doubleValue: calories),
                    start: start, end: end))
            }
            if !samples.isEmpty { try await builder.addSamples(samples) }
            try await builder.endCollection(at: end)
            _ = try await builder.finishWorkout()
            return true
        } catch {
            lastError = "Couldn't save run: \(error.localizedDescription)"
            return false
        }
    }

    /// Save a body-mass measurement to Apple Health.
    @MainActor
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

    /// Most-recent sample's value **and** its end-date, so callers can judge
    /// freshness instead of assuming the latest read is current.
    private func latest(_ id: HKQuantityTypeIdentifier, unit: HKUnit) async -> (value: Double, date: Date)? {
        let type = HKQuantityType(id)
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(sampleType: type, predicate: nil,
                                      limit: 1, sortDescriptors: [sort]) { _, samples, _ in
                if let sample = samples?.first as? HKQuantitySample {
                    continuation.resume(returning: (sample.quantity.doubleValue(for: unit), sample.endDate))
                } else {
                    continuation.resume(returning: nil)
                }
            }
            store.execute(query)
        }
    }

    // MARK: - Historical reads → personal baselines

    /// Recompute the athlete's HRV baseline + sleep debt from real history.
    @MainActor
    private func refreshBaselines() async {
        let hrv = await dailyAverages(.heartRateVariabilitySDNN,
                                      unit: .secondUnit(with: .milli), days: 30)
        let nights = await nightlySleepHours(nights: 10)
        dailyHRVHistory = hrv
        nightlySleepHistory = nights
        hrvBaselineLive = HealthBaselineEngine.hrvBaseline(fromDailyHRV: hrv)
        let need = HealthBaselineEngine.sleepNeed(fromNights: nights)
        sleepDebtLive = HealthBaselineEngine.sleepDebt(recentNights: nights, need: need)
    }

    /// Per-day averages of a discrete quantity over the last `days`, oldest→newest,
    /// skipping days with no sample. Used for the HRV baseline.
    private func dailyAverages(_ id: HKQuantityTypeIdentifier, unit: HKUnit, days: Int) async -> [Double] {
        let type = HKQuantityType(id)
        let cal = Calendar.current
        let end = cal.startOfDay(for: .now)
        guard let start = cal.date(byAdding: .day, value: -days, to: end) else { return [] }
        let predicate = HKQuery.predicateForSamples(withStart: start, end: .now)
        var interval = DateComponents(); interval.day = 1
        return await withCheckedContinuation { continuation in
            let query = HKStatisticsCollectionQuery(
                quantityType: type, quantitySamplePredicate: predicate,
                options: .discreteAverage, anchorDate: start, intervalComponents: interval)
            query.initialResultsHandler = { _, results, _ in
                var values: [Double] = []
                results?.enumerateStatistics(from: start, to: .now) { stats, _ in
                    if let avg = stats.averageQuantity()?.doubleValue(for: unit) { values.append(avg) }
                }
                continuation.resume(returning: values)
            }
            store.execute(query)
        }
    }

    /// Asleep hours for each of the last `nights` calendar nights, oldest→newest,
    /// skipping nights with no sleep sample. Feeds the sleep-debt + need baselines.
    private func nightlySleepHours(nights: Int) async -> [Double] {
        var out: [Double] = []
        for offset in stride(from: nights - 1, through: 0, by: -1) {
            if let h = await asleepHours(dayOffset: offset), h > 0 { out.append(h) }
        }
        return out
    }

    /// Sum asleep-stage durations from the last 24 h.
    private func sleepHours() async -> Double? {
        await asleepHours(dayOffset: 0)
    }

    /// Asleep hours for the 24 h window ending at midnight of `dayOffset` days ago
    /// (offset 0 = last night, ending now).
    private func asleepHours(dayOffset: Int) async -> Double? {
        let type = HKCategoryType(.sleepAnalysis)
        // The 24 h window ending `dayOffset` days ago (offset 0 = last night → now).
        let windowEnd = Calendar.current.date(byAdding: .day, value: -dayOffset, to: .now) ?? .now
        let start = Calendar.current.date(byAdding: .hour, value: -24, to: windowEnd) ?? windowEnd
        let predicate = HKQuery.predicateForSamples(withStart: start, end: windowEnd)
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
