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
        history.reduce(0) { $0 + $1.totalVolumeLb }
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

    /// Today's plan — pre-generated with Sean's live constraints (recovery 78, knee phase 2).
    var todaysPlan: GeneratedWorkout {
        generate(goal: .buildMuscle, minutes: 60, equipment: .fullGym,
                 recovery: MockData.today.recovery,
                 injuries: [.knee], level: .intermediate)
    }

    // MARK: - AI Generator

    func generate(goal: Goal, minutes: Int, equipment: Equipment,
                  recovery: Int, injuries: [InjuryType], level: FitnessLevel) -> GeneratedWorkout {

        let lowRecovery = recovery < 60
        let highRecovery = recovery >= 80
        let kneeSafe = injuries.contains(.knee)
        let shoulderSafe = injuries.contains(.shoulder)
        let backSafe = injuries.contains(.back)

        // Volume scaling by recovery
        let mainSets = lowRecovery ? 3 : (highRecovery ? 5 : 4)
        let rpeCap = lowRecovery ? "RPE 7" : (highRecovery ? "RPE 9" : "RPE 8.5")

        var rationaleParts: [String] = []
        if lowRecovery { rationaleParts.append("Recovery \(recovery): volume cut ~25% and intensity capped at RPE 7.") }
        else if highRecovery { rationaleParts.append("Recovery \(recovery): green light — progression sets included.") }
        else { rationaleParts.append("Recovery \(recovery): standard volume, top sets capped at RPE 8.5.") }
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
