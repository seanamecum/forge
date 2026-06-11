// AI Coach response engine — rule-based for the prototype.
// Picks the closest archetype of question, then generates a personalized
// response using current mock user state. Includes reasoning chain.

import { today, user, injuries, forgeScoreBreakdown } from "../mock/user";
import { todaysWorkout, volumeByMuscle } from "../mock/workouts";
import { deficiencies } from "../mock/nutrition";
import { injuryRisk } from "../mock/injuries";

export type CoachMessage = {
  role: "coach" | "user";
  text: string;
  steps?: string[]; // reasoning chain
  cards?: { label: string; value: string; tone?: "good" | "warn" | "bad" }[];
  suggestions?: string[];
};

const ARCHETYPES: { match: RegExp; build: () => CoachMessage }[] = [
  {
    match: /should i train|train today|workout today|train hard/i,
    build: () => ({
      role: "coach",
      text: `Yes — but cap it. Your Recovery is ${today.recovery} and HRV dropped ${Math.abs(
        today.hrvDelta
      )} ms from baseline. That's not "rest day" territory, but I wouldn't push top-set RPE past 8.5. Today's lower block is already auto-deloaded ~12% — run it as written.`,
      steps: [
        `Recovery: ${today.recovery}/100 — moderate band`,
        `HRV: ${today.hrv} ms (Δ ${today.hrvDelta} vs baseline)`,
        `Sleep: ${today.sleepHours} h last night — adequate, not deep`,
        `Strain yesterday: ${today.strainYesterday} — high`,
        `Decision: train, cap intensity, hit prescribed volume`,
      ],
      cards: [
        { label: "Today's session", value: todaysWorkout.name, tone: "good" },
        { label: "Top set cap", value: "RPE 8.5", tone: "warn" },
        { label: "Skip", value: "Heavy overhead pressing", tone: "bad" },
      ],
      suggestions: [
        "Why is recovery low today?",
        "What should I eat before training?",
        "Should I cap conditioning?",
      ],
    }),
  },
  {
    match: /why am i tired|fatigued|drained|low energy/i,
    build: () => ({
      role: "coach",
      text: `Three drivers stacking, in order of weight. (1) Sleep debt — you're 4h 20m short over the last 7 days. (2) HRV at ${today.hrv} is 12% below your baseline — the system is parasympathetic-low. (3) Magnesium intake is at 44% of target for 4 days, which is reliably associated with both of the above.`,
      steps: [
        "Sleep: 5 of 7 nights under 8h target",
        `HRV: ${today.hrv} ms, baseline 73`,
        "Mg intake: 184/420 mg avg (44%)",
        "Training load up 38% vs 4-wk avg",
      ],
      cards: [
        { label: "Fix #1 — Sleep tonight", value: "Target 8h, lights out 21:45", tone: "warn" },
        { label: "Fix #2 — Mg-glycinate", value: "400 mg, 30 min pre-bed", tone: "good" },
        { label: "Fix #3 — Hold volume flat", value: "No new PR attempts this week", tone: "warn" },
      ],
      suggestions: [
        "Should I deload?",
        "What should I eat to recover?",
        "Why is my HRV dropping?",
      ],
    }),
  },
  {
    match: /what should i eat|nutrition|meal|food/i,
    build: () => ({
      role: "coach",
      text: `You have ${today.caloriesRemaining} cal and ${today.proteinRemaining} g protein left to hit your targets. Given today's training (lower-body), front-load carbs in the pre- and post-workout window. After, prioritize protein density — a 250 g chicken + 1.5 cup rice + greens hits 60 g protein and ~620 cal cleanly. Add electrolytes — hydration is at 57%.`,
      steps: [
        `Target: ${user.targets.calories} kcal / ${user.targets.protein} g protein`,
        `Logged so far: ${today.caloriesIn} kcal / ${today.proteinIn} g`,
        "Pre-lift: 30 g whey + banana (~250 cal)",
        "Post-lift: protein + carb-dominant meal (~620 cal)",
        "Cap: keep fat low in the post-lift window for absorption",
      ],
      cards: [
        { label: "Remaining cals", value: `${today.caloriesRemaining}`, tone: "good" },
        { label: "Remaining protein", value: `${today.proteinRemaining} g`, tone: "warn" },
        { label: "Hydration", value: `${today.hydrationPct}%`, tone: "warn" },
      ],
      suggestions: ["Build me a meal", "What about magnesium?", "Should I bulk or cut?"],
    }),
  },
  {
    match: /bench (press )?(not|isn't|isnt|stuck)|bench plateau|bench progress/i,
    build: () => ({
      role: "coach",
      text: `Two likely causes — and your data points at the second. (1) Stimulus: you're benching 1.6×/week with chest volume at 14 sets, which is within optimal. (2) Recovery: your top-set RPE has been 9+ for 4 sessions, and average sleep on bench days is 6.9h vs 7.6h on squat days. Strength gains compress when the system can't supercompensate. Try this: cap top sets at RPE 8 for two weeks and add a pin-press accessory. We'll re-test on June 28.`,
      steps: [
        "Chest volume: 14 sets / wk (10–18 optimal)",
        "Top-set RPE trend: 9.0, 9.0, 9.5, 9.0",
        "Sleep on bench days: avg 6.9 h",
        "Avg session-window protein: 38 g (low)",
        "Recommendation: deload top set + extend rest 30s",
      ],
      cards: [
        { label: "Current 1RM est.", value: "138 kg" },
        { label: "Last PR", value: "132.5 kg · Apr 22" },
        { label: "Recommended next", value: "117.5 × 6 @ RPE 8 cap", tone: "good" },
      ],
      suggestions: ["Show me my bench history", "Pin press setup?", "Is my shoulder limiting me?"],
    }),
  },
  {
    match: /recover from (this )?injury|injury|shoulder|knee|back pain|hurts/i,
    build: () => {
      const inj = injuries[0];
      return {
        role: "coach",
        text: `Right shoulder is in phase 3 (rehab). Pain today: ${inj?.painToday}/10. The trajectory is good — pain at end-range dropped from 6 to 3 over 18 days. Hold the rehab block (band pull-aparts, wall slides, light external rotations) daily this week. Don't reintroduce overhead pressing yet — return when (a) pain ≤ 1 at full ROM and (b) you can hit a 90° internal rotation pain-free. Estimated return: ~10–14 days. If pain spikes above 6 or you feel grinding, see a PT.`,
        steps: [
          `Injury: ${inj?.name}`,
          `Phase: ${inj?.phase}, day ${inj?.daysOld}`,
          "Trajectory: 6 → 3 pain over 18 days",
          "Avoid: overhead pressing, dips, behind-the-neck",
          "Continue: pull-aparts, wall slides, light ER",
        ],
        cards: [
          { label: "Pain today", value: `${inj?.painToday}/10`, tone: "warn" },
          { label: "Phase", value: "Rehab (3/4)", tone: "good" },
          { label: "RTS in", value: "~10–14 days", tone: "good" },
        ],
        suggestions: ["Show me my rehab plan", "Can I bench with a shoulder?", "When should I see a PT?"],
      };
    },
  },
  {
    match: /change this week|adjust|tweak|optimi[sz]e|what's next/i,
    build: () => ({
      role: "coach",
      text: `Three changes, ranked by leverage. (1) Sleep: target 8h × 6 nights. Single biggest gain available — projected +6 Forge points. (2) Mg + Vit D: bridge the deficiencies; HRV typically rebounds 4–6 ms within 10 days. (3) Cap training load: hold volume flat for 7 days while shoulder finishes rehab. Re-test Sunday — we should see Recovery ≥ 80.`,
      steps: [
        "Lever 1 — Sleep (highest leverage)",
        "Lever 2 — Mg-glycinate + D3 (next)",
        "Lever 3 — Volume cap, 7 days (protective)",
        "Re-evaluate: Sunday",
      ],
      cards: [
        { label: "Sleep target", value: "8h × 6 nights", tone: "good" },
        { label: "Mg-glycinate", value: "400 mg / night", tone: "good" },
        { label: "Volume", value: "Hold flat 7d", tone: "warn" },
      ],
      suggestions: ["Show projections", "Build my week", "What's my injury risk?"],
    }),
  },
  {
    match: /what should i do today|plan my day|today/i,
    build: () => ({
      role: "coach",
      text: `Three things, in order. (1) Hit the ${todaysWorkout.name.toLowerCase()} as written — auto-deloaded for your recovery. (2) Close the protein gap with a 60g+ meal post-training. (3) Lights out by 21:45 — biggest single move for tomorrow's Forge Score.`,
      steps: [
        `Forge Score: ${today.forgeScore} · ${today.forgeScoreDelta > 0 ? "+" : ""}${today.forgeScoreDelta}`,
        `Recovery: ${today.recovery} — moderate`,
        `Calories remaining: ${today.caloriesRemaining}`,
        `Protein remaining: ${today.proteinRemaining} g`,
      ],
      cards: [
        { label: "Train", value: todaysWorkout.name, tone: "good" },
        { label: "Eat", value: `+${today.proteinRemaining} g protein`, tone: "warn" },
        { label: "Sleep", value: "Lights out 21:45", tone: "good" },
      ],
      suggestions: ["Should I train hard today?", "What should I eat?", "Why is recovery low?"],
    }),
  },
];

const DEFAULT_REPLY: CoachMessage = {
  role: "coach",
  text: `I can pull from your training, nutrition, recovery, wearables, supplements, injuries, and goals. Try asking about today, why you're tired, what to eat, whether to train hard, or how to fix a plateau.`,
  suggestions: [
    "What should I do today?",
    "Why am I tired?",
    "Should I train hard today?",
    "Why is my bench not progressing?",
    "How do I recover from my shoulder?",
  ],
};

export function coachReply(question: string): CoachMessage {
  for (const a of ARCHETYPES) {
    if (a.match.test(question)) return a.build();
  }
  return DEFAULT_REPLY;
}

// Daily AI summary for the dashboard hero card
export function dailyBrief(): { headline: string; body: string; actions: string[] } {
  const lowestSubscore = [...forgeScoreBreakdown].sort((a, b) => a.value - b.value)[0];
  return {
    headline: `Good morning, ${user.name.split(" ")[0]}. Today is a controlled day.`,
    body: `Forge Score ${today.forgeScore}${
      today.forgeScoreDelta > 0 ? ` (+${today.forgeScoreDelta})` : ""
    }. Recovery ${today.recovery} — moderate. Your lowest sub-score is ${lowestSubscore.label} at ${lowestSubscore.value}. Train as written, close the protein gap by 9pm, sleep by 21:45.`,
    actions: [
      "Open today's workout",
      "Close protein gap",
      "Set lights-out reminder",
    ],
  };
}

export { injuryRisk, volumeByMuscle, deficiencies };
