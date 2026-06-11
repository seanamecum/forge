export type PTExercise = {
  id: string;
  name: string;
  area: string;
  sets: string;
  notes: string;
  phase: "acute" | "subacute" | "rehab" | "return-to-sport";
};

export const ptExercises: PTExercise[] = [
  { id: "pt1", name: "Rotator Cuff External Rotations", area: "Shoulder", sets: "3 × 15", notes: "Light band, elbow pinned to side. Slow eccentric.", phase: "rehab" },
  { id: "pt2", name: "Wall Slides", area: "Shoulder", sets: "3 × 10", notes: "Forearms against the wall. Focus on scap upward rotation.", phase: "rehab" },
  { id: "pt3", name: "Band Pull-Aparts", area: "Shoulder", sets: "3 × 20", notes: "Daily. Build to 100/day if tolerated.", phase: "rehab" },
  { id: "pt4", name: "Copenhagen Plank", area: "Hip / Adductor", sets: "3 × 20s ea", notes: "Half lever to start.", phase: "rehab" },
  { id: "pt5", name: "Glute Bridges", area: "Hip / Glute", sets: "3 × 12", notes: "Pause 2s at top. Add band for activation.", phase: "rehab" },
  { id: "pt6", name: "Clamshells", area: "Hip / Glute Med", sets: "3 × 15 ea", notes: "Band above the knees. Slow tempo.", phase: "acute" },
  { id: "pt7", name: "Terminal Knee Extensions", area: "Knee", sets: "3 × 15", notes: "Band loop, last 15° of extension.", phase: "rehab" },
  { id: "pt8", name: "Single-Leg Balance (eyes closed)", area: "Ankle / Knee", sets: "3 × 30s ea", notes: "Foam pad to progress.", phase: "return-to-sport" },
  { id: "pt9", name: "Calf Raises", area: "Ankle", sets: "3 × 20", notes: "Full ROM. Slow 3s eccentric.", phase: "rehab" },
  { id: "pt10", name: "Tibialis Raises", area: "Ankle", sets: "3 × 20", notes: "Toes-up against weight or band.", phase: "rehab" },
  { id: "pt11", name: "Dead Bugs", area: "Core / Back", sets: "3 × 10 ea", notes: "Lower back glued to the floor. Exhale fully.", phase: "rehab" },
  { id: "pt12", name: "Bird Dogs", area: "Core / Back", sets: "3 × 10 ea", notes: "Square hips. No lumbar movement.", phase: "rehab" },
  { id: "pt13", name: "McGill Curl-Ups", area: "Core", sets: "3 × 8/6/4 ladder", notes: "One leg straight, one knee bent. Tongue to roof of mouth.", phase: "acute" },
  { id: "pt14", name: "Neck CARs", area: "Neck", sets: "2 × slow circles", notes: "Pain-free range only.", phase: "subacute" },
  { id: "pt15", name: "Ankle Dorsiflexion w/ Band", area: "Ankle Mobility", sets: "2 × 60s", notes: "Joint mobilization, anterior glide.", phase: "rehab" },
  { id: "pt16", name: "Hip 90/90 Rotations", area: "Hip Mobility", sets: "2 × 10 ea", notes: "End-range CARs.", phase: "rehab" },
];

export type InjuryProtocol = {
  area: string;
  symptoms: string[];
  whatToAvoid: string[];
  phases: { phase: string; goal: string; criteria: string }[];
  recommendedPT: string[]; // PTExercise ids
};

export const protocols: InjuryProtocol[] = [
  {
    area: "Shoulder Impingement",
    symptoms: [
      "Pain at end-range overhead",
      "Pinching with internal rotation",
      "Night-pain when sleeping on the side",
    ],
    whatToAvoid: [
      "Behind-the-neck pressing",
      "Heavy upright rows",
      "Dips below 90° elbow flexion",
      "Wide-grip bench at full ROM (paused)",
    ],
    phases: [
      { phase: "Acute (0–7 days)", goal: "Pain control, blood flow", criteria: "Rest from aggravating movements. Daily band pull-aparts." },
      { phase: "Sub-acute (1–3 weeks)", goal: "Restore scapular control", criteria: "Pain ≤ 3/10 in daily life. No night pain." },
      { phase: "Rehab (3–6 weeks)", goal: "Re-load with control", criteria: "Pain-free overhead movement to 90°. Add landmine press." },
      { phase: "Return-to-sport (6+ weeks)", goal: "Full output", criteria: "Pain-free at full ROM. ≥ 80% of healthy-side strength." },
    ],
    recommendedPT: ["pt1", "pt2", "pt3"],
  },
  {
    area: "Knee — Patellar Tendinopathy",
    symptoms: ["Achy below the kneecap", "Worse after jumping or heavy squats", "Stiffness at rest"],
    whatToAvoid: ["Deep ATG squats with high frequency", "Plyometrics in acute phase"],
    phases: [
      { phase: "Acute", goal: "Reduce reactive load", criteria: "Avoid jumping; substitute leg press / hack squat." },
      { phase: "Isometric loading", goal: "Build tendon capacity", criteria: "5×45s wall sit or Spanish squat, daily." },
      { phase: "Heavy slow resistance", goal: "Tendon remodelling", criteria: "Slow tempo squats 3×6 with 3-0-3 tempo, 3×/week." },
      { phase: "Return-to-sport", goal: "Re-introduce plyometrics", criteria: "Pain ≤ 2/10 the morning after loading." },
    ],
    recommendedPT: ["pt7", "pt8", "pt9"],
  },
  {
    area: "Low Back Strain",
    symptoms: ["Localized lumbar pain", "Stiffness in flexion or extension", "Pain with sitting"],
    whatToAvoid: ["Deadlifts", "Heavy bent-over rows", "Loaded carries until stable"],
    phases: [
      { phase: "Acute", goal: "Calm the system", criteria: "Walks, McGill big 3 daily, no axial loading." },
      { phase: "Rebuild bracing", goal: "Re-pattern", criteria: "Pain-free bird dog, dead bug, glute bridge." },
      { phase: "Re-load", goal: "Tolerate hinging", criteria: "Trap bar pulls at 50% of training max." },
      { phase: "Return-to-sport", goal: "Resume full sessions", criteria: "Pain-free workout the following morning." },
    ],
    recommendedPT: ["pt11", "pt12", "pt13"],
  },
  {
    area: "Ankle Sprain (lateral)",
    symptoms: ["Swelling", "Bruising", "Pain with weight-bearing"],
    whatToAvoid: ["Cutting and pivoting sports", "Unstable surfaces too early"],
    phases: [
      { phase: "0–3 days", goal: "PEACE protocol", criteria: "Protect, elevate, avoid anti-inflammatories." },
      { phase: "3–14 days", goal: "ROM + early loading", criteria: "Pain-free single-leg stand 30s." },
      { phase: "2–6 weeks", goal: "Strength + balance", criteria: "Hop tests symmetric within 10%." },
      { phase: "Return-to-sport", goal: "Re-introduce cuts/jumps", criteria: "Sport-specific drills pain-free." },
    ],
    recommendedPT: ["pt8", "pt9", "pt10", "pt15"],
  },
];

// Concussion module — daily symptom tracking
export const concussionSymptoms = [
  { key: "headache", label: "Headache", value: 2 },
  { key: "dizziness", label: "Dizziness", value: 1 },
  { key: "brainFog", label: "Brain fog", value: 3 },
  { key: "light", label: "Light sensitivity", value: 1 },
  { key: "noise", label: "Noise sensitivity", value: 0 },
  { key: "sleep", label: "Sleep quality", value: 2 }, // 0 = best, 6 = worst
  { key: "exercise", label: "Exercise tolerance", value: 4 },
];

export const concussionStages = [
  { id: 1, name: "Rest & symptom control", desc: "No exertion. Sleep, hydrate, avoid screens." },
  { id: 2, name: "Light walking (≤ 5 min)", desc: "Watch for symptom flare. Stop if HR climbs sharply." },
  { id: 3, name: "Light cardio (Z2)", desc: "Bike or jog 20 min. No head impact." },
  { id: 4, name: "Sport-specific movement", desc: "Drills, skating, no contact." },
  { id: 5, name: "Non-contact practice", desc: "Full practice without contact." },
  { id: 6, name: "Full practice (contact)", desc: "Medical clearance required." },
  { id: 7, name: "Competition return", desc: "Game time." },
];

// Injury risk model output
export const injuryRisk = {
  scorePct: 28,
  band: "moderate" as "low" | "moderate" | "elevated" | "high",
  drivers: [
    { driver: "Acute:Chronic Workload Ratio", value: "1.38", note: "Volume up 38% vs 4-wk avg" },
    { driver: "HRV (7d avg)", value: "64 ms", note: "Down 12% from baseline 73" },
    { driver: "Sleep debt (7d)", value: "4h 20m", note: "Below 8h target on 5 nights" },
    { driver: "Existing shoulder", value: "Phase 3 / 4", note: "Not return-to-sport cleared" },
    { driver: "Mobility flags", value: "0", note: "No restrictions logged" },
  ],
  recommendation:
    "Cap top-set RPE at 8.5 for the next 3 sessions. Skip heavy overhead pressing for 7 days. Bring HRV back up with sleep + Mg supplementation. Re-check Sunday.",
};
