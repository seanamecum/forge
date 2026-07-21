import Foundation
import SwiftData

/// A local record that mirrors to the cloud document store. Conformers expose a
/// stable id + LWW timestamp + dirty flag (the stored `sync*` fields) and know how
/// to (de)serialize just their domain fields. All merge/transport logic is generic
/// over this protocol, so adding a new synced type is one small extension.
protocol Syncable: PersistentModel {
    static var syncKind: String { get }
    var syncID: String { get set }
    var syncUpdatedAt: Date { get set }
    var syncPending: Bool { get set }

    /// JSON of the domain fields only (never the sync metadata).
    func syncPayload() throws -> Data
    /// Build a fresh record from a pulled payload.
    static func instantiate(payload: Data) throws -> Self
    /// Overwrite this record's domain fields from a newer pulled payload.
    func applyPayload(_ payload: Data) throws
}

// MARK: - Type-erased handler + registry

/// The generic operations the engine needs, closed over a concrete `Syncable`.
struct AnySyncHandler {
    let kind: String
    /// Dirty records as push rows; assigns a `syncID` to any that lack one.
    let collectPending: (ModelContext) -> [SyncRow]
    /// Clear the dirty flag for record ids the server acknowledged.
    let markSynced: (ModelContext, Set<String>) -> Void
    /// Apply one pulled row (LWW upsert, or tombstone delete).
    let apply: (SyncRow, ModelContext) -> Void
}

enum SyncRegistry {
    /// Every syncable type, in a deterministic order (parents before children is
    /// irrelevant here — the store is flat — but a stable order keeps tests stable).
    static let handlers: [AnySyncHandler] = [
        make(UserRecord.self), make(GoalRecord.self), make(WorkoutRecord.self),
        make(NutritionEntryRecord.self), make(RecoveryRecord.self), make(SleepRecord.self),
        make(ScoreRecord.self), make(CheckInRecord.self), make(WeightRecord.self),
        make(SupplementRecord.self), make(BloodworkRecord.self),
    ]

    static let byKind: [String: AnySyncHandler] =
        Dictionary(uniqueKeysWithValues: handlers.map { ($0.kind, $0) })

    private static func make<T: Syncable>(_ type: T.Type) -> AnySyncHandler {
        AnySyncHandler(
            kind: T.syncKind,
            collectPending: { ctx in
                let all = (try? ctx.fetch(FetchDescriptor<T>())) ?? []
                var rows: [SyncRow] = []
                var changed = false
                for r in all where r.syncPending {
                    if r.syncID.isEmpty { r.syncID = UUID().uuidString; changed = true }
                    let payload = (try? r.syncPayload())
                        .flatMap { String(data: $0, encoding: .utf8) } ?? "{}"
                    rows.append(SyncRow(userID: nil, kind: T.syncKind, recordID: r.syncID,
                                        payload: payload, updatedAt: r.syncUpdatedAt,
                                        deleted: false, syncedAt: nil))
                }
                if changed { try? ctx.save() }
                return rows
            },
            markSynced: { ctx, ids in
                guard !ids.isEmpty else { return }
                let all = (try? ctx.fetch(FetchDescriptor<T>())) ?? []
                var changed = false
                for r in all where r.syncPending && ids.contains(r.syncID) {
                    r.syncPending = false; changed = true
                }
                if changed { try? ctx.save() }
            },
            apply: { row, ctx in
                let all = (try? ctx.fetch(FetchDescriptor<T>())) ?? []
                let local = all.first { $0.syncID == row.recordID }
                if row.deleted {
                    // Tombstone wins only if it's at least as new as the local edit.
                    if let local, local.syncUpdatedAt <= row.updatedAt {
                        ctx.delete(local); try? ctx.save()
                    }
                    return
                }
                guard let data = row.payload.data(using: .utf8) else { return }
                if let local {
                    // Last-write-wins: keep the strictly-newer side; a tie keeps local
                    // (which, for our own echoed rows, avoids a redundant write).
                    guard row.updatedAt > local.syncUpdatedAt else { return }
                    try? local.applyPayload(data)
                    local.syncUpdatedAt = row.updatedAt
                    local.syncPending = false
                    try? ctx.save()
                } else {
                    guard let obj = try? T.instantiate(payload: data) else { return }
                    obj.syncID = row.recordID
                    obj.syncUpdatedAt = row.updatedAt
                    obj.syncPending = false
                    ctx.insert(obj)
                    try? ctx.save()
                }
            })
    }
}

// MARK: - Per-model conformances (domain fields only in each Payload)

extension UserRecord: Syncable {
    static var syncKind: String { "profile" }
    private struct Payload: Codable { var name: String; var weightLb: Double; var heightInches: Double; var primaryGoal: String; var updatedAt: Date }
    func syncPayload() throws -> Data {
        try SyncCoder.encoder.encode(Payload(name: name, weightLb: weightLb, heightInches: heightInches, primaryGoal: primaryGoal, updatedAt: updatedAt))
    }
    static func instantiate(payload: Data) throws -> UserRecord {
        let p = try SyncCoder.decoder.decode(Payload.self, from: payload)
        let r = UserRecord(name: p.name, weightLb: p.weightLb, heightInches: p.heightInches, primaryGoal: p.primaryGoal)
        r.updatedAt = p.updatedAt; return r
    }
    func applyPayload(_ payload: Data) throws {
        let p = try SyncCoder.decoder.decode(Payload.self, from: payload)
        name = p.name; weightLb = p.weightLb; heightInches = p.heightInches; primaryGoal = p.primaryGoal; updatedAt = p.updatedAt
    }
}

extension GoalRecord: Syncable {
    static var syncKind: String { "goal" }
    private struct Payload: Codable { var title: String; var unit: String; var targetValue: Double; var currentValue: Double; var deadline: Date?; var done: Bool; var createdAt: Date }
    func syncPayload() throws -> Data {
        try SyncCoder.encoder.encode(Payload(title: title, unit: unit, targetValue: targetValue, currentValue: currentValue, deadline: deadline, done: done, createdAt: createdAt))
    }
    static func instantiate(payload: Data) throws -> GoalRecord {
        let p = try SyncCoder.decoder.decode(Payload.self, from: payload)
        let r = GoalRecord(title: p.title, unit: p.unit, targetValue: p.targetValue, currentValue: p.currentValue, deadline: p.deadline)
        r.done = p.done; r.createdAt = p.createdAt; return r
    }
    func applyPayload(_ payload: Data) throws {
        let p = try SyncCoder.decoder.decode(Payload.self, from: payload)
        title = p.title; unit = p.unit; targetValue = p.targetValue; currentValue = p.currentValue; deadline = p.deadline; done = p.done; createdAt = p.createdAt
    }
}

extension WorkoutRecord: Syncable {
    static var syncKind: String { "workout" }
    private struct Payload: Codable { var name: String; var date: Date; var durationMin: Int; var totalVolumeLb: Double; var setCount: Int; var avgRPE: Double; var exerciseSummary: String; var savedToHealthKit: Bool; var exercisesJSON: String }
    func syncPayload() throws -> Data {
        try SyncCoder.encoder.encode(Payload(name: name, date: date, durationMin: durationMin, totalVolumeLb: totalVolumeLb, setCount: setCount, avgRPE: avgRPE, exerciseSummary: exerciseSummary, savedToHealthKit: savedToHealthKit, exercisesJSON: exercisesJSON))
    }
    static func instantiate(payload: Data) throws -> WorkoutRecord {
        let p = try SyncCoder.decoder.decode(Payload.self, from: payload)
        return WorkoutRecord(name: p.name, date: p.date, durationMin: p.durationMin, totalVolumeLb: p.totalVolumeLb, setCount: p.setCount, avgRPE: p.avgRPE, exerciseSummary: p.exerciseSummary, savedToHealthKit: p.savedToHealthKit, exercisesJSON: p.exercisesJSON)
    }
    func applyPayload(_ payload: Data) throws {
        let p = try SyncCoder.decoder.decode(Payload.self, from: payload)
        name = p.name; date = p.date; durationMin = p.durationMin; totalVolumeLb = p.totalVolumeLb; setCount = p.setCount; avgRPE = p.avgRPE; exerciseSummary = p.exerciseSummary; savedToHealthKit = p.savedToHealthKit; exercisesJSON = p.exercisesJSON
    }
}

extension NutritionEntryRecord: Syncable {
    static var syncKind: String { "nutrition" }
    private struct Payload: Codable { var entryID: String; var date: Date; var meal: String; var name: String; var calories: Int; var protein: Double; var carbs: Double; var fat: Double; var servings: Double }
    func syncPayload() throws -> Data {
        try SyncCoder.encoder.encode(Payload(entryID: entryID, date: date, meal: meal, name: name, calories: calories, protein: protein, carbs: carbs, fat: fat, servings: servings))
    }
    static func instantiate(payload: Data) throws -> NutritionEntryRecord {
        let p = try SyncCoder.decoder.decode(Payload.self, from: payload)
        return NutritionEntryRecord(entryID: p.entryID, date: p.date, meal: p.meal, name: p.name, calories: p.calories, protein: p.protein, carbs: p.carbs, fat: p.fat, servings: p.servings)
    }
    func applyPayload(_ payload: Data) throws {
        let p = try SyncCoder.decoder.decode(Payload.self, from: payload)
        entryID = p.entryID; date = p.date; meal = p.meal; name = p.name; calories = p.calories; protein = p.protein; carbs = p.carbs; fat = p.fat; servings = p.servings
    }
}

extension RecoveryRecord: Syncable {
    static var syncKind: String { "recovery" }
    private struct Payload: Codable { var date: Date; var recovery: Int; var hrv: Int; var restingHR: Int; var strain: Double }
    func syncPayload() throws -> Data {
        try SyncCoder.encoder.encode(Payload(date: date, recovery: recovery, hrv: hrv, restingHR: restingHR, strain: strain))
    }
    static func instantiate(payload: Data) throws -> RecoveryRecord {
        let p = try SyncCoder.decoder.decode(Payload.self, from: payload)
        return RecoveryRecord(date: p.date, recovery: p.recovery, hrv: p.hrv, restingHR: p.restingHR, strain: p.strain)
    }
    func applyPayload(_ payload: Data) throws {
        let p = try SyncCoder.decoder.decode(Payload.self, from: payload)
        date = p.date; recovery = p.recovery; hrv = p.hrv; restingHR = p.restingHR; strain = p.strain
    }
}

extension SleepRecord: Syncable {
    static var syncKind: String { "sleep" }
    private struct Payload: Codable { var date: Date; var hours: Double; var deepHours: Double; var remHours: Double; var score: Int }
    func syncPayload() throws -> Data {
        try SyncCoder.encoder.encode(Payload(date: date, hours: hours, deepHours: deepHours, remHours: remHours, score: score))
    }
    static func instantiate(payload: Data) throws -> SleepRecord {
        let p = try SyncCoder.decoder.decode(Payload.self, from: payload)
        return SleepRecord(date: p.date, hours: p.hours, deepHours: p.deepHours, remHours: p.remHours, score: p.score)
    }
    func applyPayload(_ payload: Data) throws {
        let p = try SyncCoder.decoder.decode(Payload.self, from: payload)
        date = p.date; hours = p.hours; deepHours = p.deepHours; remHours = p.remHours; score = p.score
    }
}

extension ScoreRecord: Syncable {
    static var syncKind: String { "score" }
    private struct Payload: Codable { var date: Date; var score: Int }
    func syncPayload() throws -> Data { try SyncCoder.encoder.encode(Payload(date: date, score: score)) }
    static func instantiate(payload: Data) throws -> ScoreRecord {
        let p = try SyncCoder.decoder.decode(Payload.self, from: payload)
        return ScoreRecord(date: p.date, score: p.score)
    }
    func applyPayload(_ payload: Data) throws {
        let p = try SyncCoder.decoder.decode(Payload.self, from: payload)
        date = p.date; score = p.score
    }
}

extension CheckInRecord: Syncable {
    static var syncKind: String { "checkin" }
    private struct Payload: Codable { var date: Date; var sleepQuality: Int; var soreness: Int; var energy: Int; var stress: Int }
    func syncPayload() throws -> Data {
        try SyncCoder.encoder.encode(Payload(date: date, sleepQuality: sleepQuality, soreness: soreness, energy: energy, stress: stress))
    }
    static func instantiate(payload: Data) throws -> CheckInRecord {
        let p = try SyncCoder.decoder.decode(Payload.self, from: payload)
        return CheckInRecord(date: p.date, sleepQuality: p.sleepQuality, soreness: p.soreness, energy: p.energy, stress: p.stress)
    }
    func applyPayload(_ payload: Data) throws {
        let p = try SyncCoder.decoder.decode(Payload.self, from: payload)
        date = p.date; sleepQuality = p.sleepQuality; soreness = p.soreness; energy = p.energy; stress = p.stress
    }
}

extension WeightRecord: Syncable {
    static var syncKind: String { "weight" }
    private struct Payload: Codable { var date: Date; var weightLb: Double }
    func syncPayload() throws -> Data { try SyncCoder.encoder.encode(Payload(date: date, weightLb: weightLb)) }
    static func instantiate(payload: Data) throws -> WeightRecord {
        let p = try SyncCoder.decoder.decode(Payload.self, from: payload)
        return WeightRecord(date: p.date, weightLb: p.weightLb)
    }
    func applyPayload(_ payload: Data) throws {
        let p = try SyncCoder.decoder.decode(Payload.self, from: payload)
        date = p.date; weightLb = p.weightLb
    }
}

extension SupplementRecord: Syncable {
    static var syncKind: String { "supplement" }
    private struct Payload: Codable { var name: String; var dose: String; var timing: String; var benefit: String; var streak: Int; var lastLoggedDate: Date?; var createdAt: Date }
    func syncPayload() throws -> Data {
        try SyncCoder.encoder.encode(Payload(name: name, dose: dose, timing: timing, benefit: benefit, streak: streak, lastLoggedDate: lastLoggedDate, createdAt: createdAt))
    }
    static func instantiate(payload: Data) throws -> SupplementRecord {
        let p = try SyncCoder.decoder.decode(Payload.self, from: payload)
        return SupplementRecord(name: p.name, dose: p.dose, timing: p.timing, benefit: p.benefit, streak: p.streak, lastLoggedDate: p.lastLoggedDate, createdAt: p.createdAt)
    }
    func applyPayload(_ payload: Data) throws {
        let p = try SyncCoder.decoder.decode(Payload.self, from: payload)
        name = p.name; dose = p.dose; timing = p.timing; benefit = p.benefit; streak = p.streak; lastLoggedDate = p.lastLoggedDate; createdAt = p.createdAt
    }
}

extension BloodworkRecord: Syncable {
    static var syncKind: String { "bloodwork" }
    private struct Payload: Codable { var name: String; var category: String; var value: Double; var unit: String; var normalLow: Double; var normalHigh: Double; var optimalLow: Double; var optimalHigh: Double; var date: Date }
    func syncPayload() throws -> Data {
        try SyncCoder.encoder.encode(Payload(name: name, category: category, value: value, unit: unit, normalLow: normalLow, normalHigh: normalHigh, optimalLow: optimalLow, optimalHigh: optimalHigh, date: date))
    }
    static func instantiate(payload: Data) throws -> BloodworkRecord {
        let p = try SyncCoder.decoder.decode(Payload.self, from: payload)
        return BloodworkRecord(name: p.name, category: p.category, value: p.value, unit: p.unit, normalLow: p.normalLow, normalHigh: p.normalHigh, optimalLow: p.optimalLow, optimalHigh: p.optimalHigh, date: p.date)
    }
    func applyPayload(_ payload: Data) throws {
        let p = try SyncCoder.decoder.decode(Payload.self, from: payload)
        name = p.name; category = p.category; value = p.value; unit = p.unit; normalLow = p.normalLow; normalHigh = p.normalHigh; optimalLow = p.optimalLow; optimalHigh = p.optimalHigh; date = p.date
    }
}
