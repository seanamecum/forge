import Foundation

extension MockData {

    // MARK: - Active injury

    static let knee = InjuryProfile(
        type: .knee,
        name: "Left Patellar Tendinopathy",
        painToday: 2,
        daysOld: 12,
        phase: .rehab,
        severity: 2,
        mobilityPct: 88,
        strengthPct: 74,
        stabilityPct: 81,
        notes: "Flared after back-to-back skate + heavy squat day. Pain localized below the kneecap, worst on first reps and stairs. Improving with isometrics and load management.",
        painHistory: [5, 5, 4, 4, 4, 3, 3, 3, 2, 3, 2, 2]
    )

    // MARK: - PT exercise library

    static let ptExercises: [PTExercise] = [
        PTExercise(name: "Rotator Cuff External Rotations", area: "Shoulder", prescription: "3 × 15", note: "Light band, elbow pinned. Slow eccentric.", phase: .rehab),
        PTExercise(name: "Wall Slides", area: "Shoulder", prescription: "3 × 10", note: "Forearms on the wall, scap upward rotation.", phase: .rehab),
        PTExercise(name: "Band Pull-Aparts", area: "Shoulder", prescription: "3 × 20", note: "Daily. Build toward 100/day.", phase: .subacute),
        PTExercise(name: "Copenhagen Plank", area: "Groin / Adductor", prescription: "3 × 20s ea", note: "Half-lever first. Hockey essential.", phase: .rehab),
        PTExercise(name: "Glute Bridges", area: "Hip / Glute", prescription: "3 × 12", note: "2s pause at top.", phase: .subacute),
        PTExercise(name: "Clamshells", area: "Hip / Glute Med", prescription: "3 × 15 ea", note: "Band above knees, slow.", phase: .acute),
        PTExercise(name: "Terminal Knee Extensions", area: "Knee", prescription: "3 × 15", note: "Band loop, last 15° of extension.", phase: .rehab),
        PTExercise(name: "Spanish Squat Isometric", area: "Knee", prescription: "5 × 45s", note: "Tendon analgesia + capacity. Your daily anchor.", phase: .rehab),
        PTExercise(name: "Single-Leg Balance", area: "Ankle / Knee", prescription: "3 × 30s ea", note: "Eyes closed to progress; foam pad next.", phase: .returnToSport),
        PTExercise(name: "Calf Raises", area: "Ankle", prescription: "3 × 20", note: "Full range, 3s lowering.", phase: .rehab),
        PTExercise(name: "Tibialis Raises", area: "Ankle / Shin", prescription: "3 × 20", note: "Toes up against the wall or band.", phase: .rehab),
        PTExercise(name: "Dead Bugs", area: "Core / Back", prescription: "3 × 10 ea", note: "Low back glued down. Full exhale.", phase: .rehab),
        PTExercise(name: "Bird Dogs", area: "Core / Back", prescription: "3 × 10 ea", note: "Square hips, zero lumbar motion.", phase: .rehab),
        PTExercise(name: "McGill Curl-Ups", area: "Core", prescription: "8/6/4 ladder", note: "One knee bent. Brace, don't crunch.", phase: .acute),
        PTExercise(name: "Neck CARs", area: "Neck", prescription: "2 × 5 circles", note: "Slow, pain-free range only.", phase: .subacute),
        PTExercise(name: "Ankle Dorsiflexion Mobs", area: "Ankle Mobility", prescription: "2 × 60s", note: "Banded anterior glide.", phase: .rehab),
        PTExercise(name: "Hip 90/90 Rotations", area: "Hip Mobility", prescription: "2 × 10 ea", note: "End-range control.", phase: .rehab),
    ]

    // MARK: - Protocols

    static let protocols: [RehabProtocol] = [
        RehabProtocol(
            title: "Knee — Patellar Tendinopathy",
            injuryType: .knee,
            symptoms: ["Ache just below the kneecap", "Worse after jumping or deep squats", "Stiff after sitting"],
            avoid: ["Plyometrics in the acute phase", "Deep high-frequency squatting", "Skating sprints until phase 3"],
            phases: [
                ProtocolPhase(name: "1 · Calm it down", goal: "Reduce reactive pain", criteria: "Isometrics daily (Spanish squat 5×45s). Pain ≤ 3/10."),
                ProtocolPhase(name: "2 · Heavy slow resistance", goal: "Rebuild tendon capacity", criteria: "Leg press / squat 3-0-3 tempo, 3×/week, pain ≤ 2 next morning."),
                ProtocolPhase(name: "3 · Energy storage", goal: "Reintroduce spring", criteria: "Hops, low jumps, skate drills. No morning flare 24h after."),
                ProtocolPhase(name: "4 · Return-to-sport", goal: "Full practice + games", criteria: "Symmetric hop tests within 10%; full-intensity skate clean."),
            ],
            ptExerciseNames: ["Spanish Squat Isometric", "Terminal Knee Extensions", "Single-Leg Balance", "Calf Raises"]
        ),
        RehabProtocol(
            title: "Shoulder — Impingement",
            injuryType: .shoulder,
            symptoms: ["Pinch at end-range overhead", "Night pain lying on that side", "Painful arc 60–120°"],
            avoid: ["Behind-the-neck pressing", "Upright rows", "Deep dips"],
            phases: [
                ProtocolPhase(name: "1 · Offload", goal: "Stop the irritation", criteria: "Pause overhead work. Daily pull-aparts."),
                ProtocolPhase(name: "2 · Scap control", goal: "Re-pattern mechanics", criteria: "Wall slides clean, no shrug compensation."),
                ProtocolPhase(name: "3 · Reload", goal: "Progressive pressing", criteria: "Landmine → DB neutral → barbell. Pain ≤ 1/10."),
                ProtocolPhase(name: "4 · Return", goal: "Full output", criteria: "80%+ of pre-injury pressing strength, no flare."),
            ],
            ptExerciseNames: ["Rotator Cuff External Rotations", "Wall Slides", "Band Pull-Aparts"]
        ),
        RehabProtocol(
            title: "Low Back — Strain",
            injuryType: .back,
            symptoms: ["Localized lumbar ache", "Stiff flexion in the morning", "Pain with long sitting"],
            avoid: ["Deadlifts and RDLs", "Heavy bent-over rows", "Loaded spinal flexion"],
            phases: [
                ProtocolPhase(name: "1 · Calm", goal: "Settle the system", criteria: "Walks + McGill Big 3 daily, no axial load."),
                ProtocolPhase(name: "2 · Re-pattern", goal: "Bracing under control", criteria: "Pain-free dead bug, bird dog, glute bridge."),
                ProtocolPhase(name: "3 · Re-load", goal: "Tolerate hinging", criteria: "Trap-bar pulls at 50% training max."),
                ProtocolPhase(name: "4 · Return", goal: "Full training", criteria: "Pain-free session and pain-free next morning."),
            ],
            ptExerciseNames: ["McGill Curl-Ups", "Dead Bugs", "Bird Dogs", "Glute Bridges"]
        ),
        RehabProtocol(
            title: "Ankle — Lateral Sprain",
            injuryType: .ankle,
            symptoms: ["Swelling around the lateral malleolus", "Bruising", "Pain on weight-bearing"],
            avoid: ["Cutting sports early", "Unstable surfaces in week 1"],
            phases: [
                ProtocolPhase(name: "1 · Protect (0–3 d)", goal: "PEACE protocol", criteria: "Elevate, compress, gentle motion."),
                ProtocolPhase(name: "2 · Mobilize (3–14 d)", goal: "Restore ROM + early load", criteria: "Single-leg stand 30s pain-free."),
                ProtocolPhase(name: "3 · Strengthen (2–6 wk)", goal: "Capacity + balance", criteria: "Hop test symmetry within 10%."),
                ProtocolPhase(name: "4 · Return", goal: "Cutting + jumping", criteria: "Sport drills full speed, no swelling next day."),
            ],
            ptExerciseNames: ["Calf Raises", "Tibialis Raises", "Single-Leg Balance", "Ankle Dorsiflexion Mobs"]
        ),
    ]

    // MARK: - Return-to-sport checklist (Sean's knee)

    static let kneeRTSChecklist: [RTSChecklistItem] = [
        RTSChecklistItem(label: "Pain ≤ 1/10 on stairs and first reps", detail: "Daily check", done: true),
        RTSChecklistItem(label: "Spanish squat 5×45s pain-free", detail: "Isometric tolerance", done: true),
        RTSChecklistItem(label: "Leg press 3×10 at 80% pain ≤ 2 next morning", detail: "Heavy slow resistance", done: true),
        RTSChecklistItem(label: "Double-leg hops 3×10 no flare", detail: "Energy storage intro", done: false),
        RTSChecklistItem(label: "Single-leg hop symmetry within 10%", detail: "Power symmetry", done: false),
        RTSChecklistItem(label: "Full-intensity skate, clean next morning", detail: "Sport-specific load", done: false),
    ]

    // MARK: - Concussion module

    static let concussionSymptoms: [ConcussionSymptom] = [
        ConcussionSymptom(name: "Headache", value: 0),
        ConcussionSymptom(name: "Dizziness", value: 0),
        ConcussionSymptom(name: "Brain Fog", value: 1),
        ConcussionSymptom(name: "Light Sensitivity", value: 0),
        ConcussionSymptom(name: "Noise Sensitivity", value: 0),
        ConcussionSymptom(name: "Sleep Quality", value: 1),
        ConcussionSymptom(name: "Exercise Tolerance", value: 0),
    ]

    static let rtpStages: [RTPStage] = [
        RTPStage(number: 1, name: "Rest & symptom control", detail: "No exertion. Sleep, hydrate, limit screens.", completed: true),
        RTPStage(number: 2, name: "Light walking", detail: "≤ 15 min. Stop if symptoms rise.", completed: true),
        RTPStage(number: 3, name: "Light cardio", detail: "Zone 2 bike or jog, 20 min, no head impact.", completed: true),
        RTPStage(number: 4, name: "Sport-specific movement", detail: "Skating drills, no contact.", completed: true),
        RTPStage(number: 5, name: "Non-contact practice", detail: "Full practice intensity without contact.", completed: true),
        RTPStage(number: 6, name: "Full practice", detail: "Contact. Requires medical clearance.", completed: true),
        RTPStage(number: 7, name: "Competition return", detail: "Game cleared. Keep monitoring 2 weeks.", completed: true),
    ]

    // MARK: - Injury risk model

    static let injuryRisk = InjuryRisk(
        percent: 22,
        band: "Moderate",
        drivers: [
            RiskDriver(name: "Acute:Chronic Workload", value: "1.24", note: "Volume up 24% vs 4-week average"),
            RiskDriver(name: "HRV (7-day avg)", value: "58 ms", note: "6% below your 62 ms baseline"),
            RiskDriver(name: "Sleep debt", value: "3.1 h", note: "Under 8 h on 5 of 7 nights"),
            RiskDriver(name: "Active injury", value: "Knee · Phase 2/4", note: "Not yet cleared for plyometrics"),
            RiskDriver(name: "Asymmetry flags", value: "1", note: "L/R leg-press strength gap 12%"),
        ],
        recommendation: "Hold weekly volume flat and cap top sets at RPE 8.5 until the knee clears phase 3. Bike replaces skating sprints this week. Sleep is your highest-leverage fix — 8 h × 6 nights drops modeled risk to ~9%."
    )
}
