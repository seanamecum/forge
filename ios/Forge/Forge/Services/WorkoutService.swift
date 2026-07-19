import Foundation
import Observation

@Observable
final class WorkoutService {
    var history: [Workout] = MockData.workoutHistory
    var personalRecords: [PersonalRecord] = MockData.personalRecords
    var muscleVolume: [MuscleVolume] = MockData.muscleVolume
    var enrolledProgram = MockData.enrolledProgram
    var exercises: [Exercise] = MockData.exercises

    var weeklyVolumeLb: Double {
        let cutoff = Calendar.current.date(byAdding: .day, value: -7, to: .now) ?? .now
        return history.filter { $0.date >= cutoff }.reduce(0) { $0 + $1.totalVolumeLb }
    }

    /// Lifts that have stopped progressing, with the diagnosis and the fix.
    var plateaus: [PlateauFinding] {
        TrainingAnalyticsEngine.plateaus(history: history)
    }

    /// Muscle groups below their effective-volume floor.
    var weakPoints: [MuscleVolume] {
        TrainingAnalyticsEngine.weakPoints(volume: muscleVolume)
    }

    // MARK: - Hevy-grade logging intelligence

    /// The best completed set from the most recent session containing this
    /// exercise — powers the "last time" ghost values in the logger.
    func lastPerformance(of exerciseName: String) -> WorkoutSet? {
        for workout in history {   // newest-first
            guard let logged = workout.exercises.first(where: { $0.exercise.name == exerciseName })
            else { continue }
            let done = logged.sets.filter { $0.completed && $0.reps > 0 }
            if let best = done.max(by: { $0.estimatedOneRepMax < $1.estimatedOneRepMax }) {
                return best
            }
        }
        return nil
    }

    /// Current estimated-1RM record for an exercise (nil = no record yet).
    func prBaseline(for exerciseName: String) -> Double? {
        personalRecords
            .filter { $0.exerciseName == exerciseName }
            .map { $0.weightLb * (1 + Double($0.reps) / 30) }
            .max()
    }

    /// Does this set beat the athlete's standing record? Drives the live PR
    /// flag, celebration haptic, and record promotion on finish.
    func isPRCandidate(_ set: WorkoutSet, exerciseName: String) -> Bool {
        guard set.weightLb > 0, set.reps > 0 else { return false }
        guard let baseline = prBaseline(for: exerciseName) else { return true }
        return set.estimatedOneRepMax > baseline
    }

    /// Hevy-style repeat: turn the most recent session into a ready-to-log
    /// plan — same exercises, same set counts, loads prefilled from last time.
    func planFromLastSession() -> GeneratedWorkout? {
        guard let last = history.first, !last.exercises.isEmpty else { return nil }
        let items = last.exercises.map { logged -> GeneratedItem in
            let done = logged.sets.filter { $0.completed && $0.reps > 0 }
            let sets = done.isEmpty ? logged.sets : done
            let top = sets.max { $0.estimatedOneRepMax < $1.estimatedOneRepMax }
            let scheme: String
            if let top, top.weightLb > 0 {
                scheme = "\(sets.count) × \(top.reps) @ \(Int(top.weightLb)) lb"
            } else {
                scheme = "\(sets.count) sets · match last time"
            }
            return GeneratedItem(exerciseID: logged.exercise.id,
                                 name: logged.exercise.name,
                                 scheme: scheme,
                                 note: "Beat one rep or 5 lb to progress.")
        }
        let days = Calendar.current.dateComponents([.day], from: last.date, to: .now).day ?? 0
        let when = days <= 0 ? "today" : (days == 1 ? "yesterday" : "\(days) days ago")
        return GeneratedWorkout(
            name: last.name,
            rationale: "Repeat of your session from \(when) — loads prefilled from last time. Add a rep or 5 lb where it moves well.",
            estMinutes: last.durationMin,
            blocks: [GeneratedBlock(label: "Main · Repeat", note: "Progress where you can", items: items)])
    }

    func finish(_ workout: Workout) {
        history.insert(workout, at: 0)
        for logged in workout.exercises {
            for set in logged.sets where set.isPR {
                personalRecords.insert(
                    PersonalRecord(exerciseName: logged.exercise.name,
                                   weightLb: set.weightLb, reps: set.reps, date: "Today"),
                    at: 0
                )
            }
        }
    }

    // MARK: - AI Generator
    // (Today's plan lives on AppState.todaysPlan, generated from the live
    //  profile, recovery, and injuries — this service stays a pure engine.)

    func generate(goal: Goal, minutes: Int, equipment: Equipment,
                  recovery: Int, injuries: [InjuryType], level: FitnessLevel,
                  recentStrain: Double = 0, strainBaseline: Double = 0) -> GeneratedWorkout {

        let lowRecovery = recovery < 60
        let highRecovery = recovery >= 80
        let kneeSafe = injuries.contains(.knee)
        let shoulderSafe = injuries.contains(.shoulder)
        let backSafe = injuries.contains(.back)

        // Volume + intensity scale with recovery, then deload FURTHER when recent
        // training load spiked over the athlete's baseline (acute:chronic ≥ 1.4) or
        // hit a maximal day (≥ 15/21) — so a hard week trims the actual prescribed
        // session, not just the headline. Never drops below the 3-set / RPE-7 floor.
        var mainSets = lowRecovery ? 3 : (highRecovery ? 5 : 4)
        var rpe = lowRecovery ? 7.0 : (highRecovery ? 9.0 : 8.5)
        let highLoad = strainBaseline > 0 ? recentStrain / strainBaseline >= 1.4 : recentStrain >= 15
        let baseSets = mainSets
        if highLoad {
            mainSets = max(3, mainSets - 1)
            rpe = max(7.0, rpe - 0.5)
        }
        let trimmedASet = baseSets > mainSets
        let rpeCap = "RPE " + (rpe == rpe.rounded() ? String(Int(rpe)) : String(format: "%.1f", rpe))

        var rationaleParts: [String] = []
        if highLoad {
            let trimNote = trimmedASet ? "one set trimmed and top sets" : "top sets"
            rationaleParts.append("Recovery \(recovery), but training load ran high (\(Int(recentStrain.rounded()))/21): \(trimNote) capped at \(rpeCap) to absorb the recent block.")
        } else if lowRecovery {
            rationaleParts.append("Recovery \(recovery): volume cut ~25% and intensity capped at \(rpeCap).")
        } else if highRecovery {
            rationaleParts.append("Recovery \(recovery): green light — progression sets included.")
        } else {
            rationaleParts.append("Recovery \(recovery): standard volume, top sets capped at \(rpeCap).")
        }
        if kneeSafe { rationaleParts.append("Knee flag: squats, lunges, and leg press swapped for hip-dominant + tempo work; zero plyometrics.") }
        if shoulderSafe { rationaleParts.append("Shoulder flag: overhead pressing removed — landmine and neutral-grip variants instead.") }
        if backSafe { rationaleParts.append("Back flag: deadlifts, RDLs, and bent-over rows removed — chest-supported pulling only.") }

        // Build blocks
        var main: [GeneratedItem] = []
        var accessory: [GeneratedItem] = []

        switch goal {
        case .buildMuscle, .strength, .athletic:
            if shoulderSafe {
                main.append(GeneratedItem(exerciseID: "bench", name: "Flat DB Press (neutral grip)",
                                          scheme: "\(mainSets) × 8 · \(rpeCap) · rest 2:30",
                                          note: "Neutral grip keeps the shoulder in a safe line."))
            } else {
                main.append(GeneratedItem(exerciseID: "bench", name: "Barbell Bench Press",
                                          scheme: "\(mainSets) × 5 @ 175–185 lb · \(rpeCap) · rest 3:00",
                                          note: "Progression day if bar speed holds."))
            }
            if backSafe {
                main.append(GeneratedItem(exerciseID: "row", name: "Chest-Supported Row",
                                          scheme: "\(mainSets) × 10 · \(rpeCap) · rest 2:00",
                                          note: "Pulls volume without loading the spine."))
            } else {
                main.append(GeneratedItem(exerciseID: "row", name: "Barbell Row",
                                          scheme: "\(mainSets) × 8 @ 155 lb · \(rpeCap) · rest 2:00",
                                          note: "Balance the pressing volume."))
            }
            if kneeSafe {
                accessory.append(GeneratedItem(exerciseID: "hipthrust", name: "Barbell Hip Thrust",
                                               scheme: "3 × 8 @ 225 lb · RPE 8 · rest 2:00",
                                               note: "Hip-dominant lower work — zero patellar stress."))
                accessory.append(GeneratedItem(exerciseID: "legpress", name: "Leg Press · 3-0-3 tempo",
                                               scheme: "3 × 10 @ 60% · pain ≤ 2 rule · rest 2:00",
                                               note: "Heavy-slow-resistance protocol for the tendon."))
            } else {
                accessory.append(GeneratedItem(exerciseID: "squat", name: "Back Squat",
                                               scheme: "\(mainSets) × 5 @ 205–230 lb · \(rpeCap) · rest 3:00",
                                               note: "Drive through the whole foot."))
            }
            accessory.append(GeneratedItem(exerciseID: "latraise", name: "Lateral Raise + Pushdown superset",
                                           scheme: "3 × 12–15 · RPE 9 · rest 1:00",
                                           note: "Arm/delt volume to finish."))
        case .endurance:
            main.append(GeneratedItem(exerciseID: "bike", name: kneeSafe ? "Bike — Zone 2" : "Run — Zone 2",
                                      scheme: "\(max(20, minutes - 20)) min conversational",
                                      note: kneeSafe ? "Bike spares the patellar tendon." : "Nose-breathing pace."))
            accessory.append(GeneratedItem(exerciseID: "plank", name: "Core circuit",
                                           scheme: "3 rounds · plank 45s + dead bug 10",
                                           note: "Posture support for distance work."))
        case .loseFat, .health, .injuryRecovery:
            main.append(GeneratedItem(exerciseID: "hipthrust", name: "Hip Thrust",
                                      scheme: "3 × 10 · RPE 8 · rest 1:30", note: "Big muscle, low joint cost."))
            main.append(GeneratedItem(exerciseID: "latpulldown", name: "Lat Pulldown",
                                      scheme: "3 × 12 · RPE 8 · rest 1:30", note: "Full-body pull volume."))
            accessory.append(GeneratedItem(exerciseID: "hiit", name: kneeSafe ? "Bike intervals" : "HIIT finisher",
                                           scheme: "8 × 30s/30s", note: "Caloric burn without long sessions."))
        }

        let warmup = GeneratedBlock(label: "Warm-up · 8 min", note: "Zone 1–2",
            items: [
                GeneratedItem(exerciseID: "bike", name: "Easy bike", scheme: "5 min", note: "Raise core temp."),
                GeneratedItem(exerciseID: nil, name: kneeSafe ? "Spanish squat isometric" : "Leg swings + hip openers",
                              scheme: kneeSafe ? "3 × 30s" : "1 round",
                              note: kneeSafe ? "Tendon analgesia before loading." : "Open the hips."),
            ])

        return GeneratedWorkout(
            name: goalTitle(goal, kneeSafe: kneeSafe),
            rationale: rationaleParts.joined(separator: " "),
            estMinutes: minutes,
            blocks: [warmup,
                     GeneratedBlock(label: "Main · Strength", note: "Rest fully", items: main),
                     GeneratedBlock(label: "Accessory", note: "Quality over load", items: accessory)]
        )
    }

    /// The session's display name without generating the whole plan — the Directive
    /// needs the name, not the exercises, so it shouldn't pay for a full generate().
    /// Must stay consistent with `generate(...).name`.
    func workoutName(goal: Goal, injuries: [InjuryType]) -> String {
        goalTitle(goal, kneeSafe: injuries.contains(.knee))
    }

    private func goalTitle(_ goal: Goal, kneeSafe: Bool) -> String {
        switch goal {
        case .buildMuscle: return kneeSafe ? "Upper Push + Knee-Safe Lower" : "Hypertrophy Builder"
        case .strength: return "Strength Block"
        case .athletic: return "Athletic Power Session"
        case .endurance: return "Engine Builder"
        case .loseFat: return "Burn Session"
        case .health: return "Foundation Session"
        case .injuryRecovery: return "Rebuild Session"
        }
    }
}
