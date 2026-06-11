export type Supplement = {
  id: string;
  name: string;
  dose: string;
  timing: string;
  benefit: string;
  streak: number;
  loggedToday: boolean;
  category: "performance" | "recovery" | "health" | "sleep";
};

export const supplements: Supplement[] = [
  {
    id: "s1",
    name: "Creatine Monohydrate",
    dose: "5 g",
    timing: "Daily, with food",
    benefit: "Strength, power output, hydration, cognition",
    streak: 47,
    loggedToday: true,
    category: "performance",
  },
  {
    id: "s2",
    name: "Whey Protein Isolate",
    dose: "25–50 g",
    timing: "Post-workout, daily protein gap",
    benefit: "Muscle protein synthesis, recovery",
    streak: 47,
    loggedToday: true,
    category: "performance",
  },
  {
    id: "s3",
    name: "Omega-3 (Fish Oil)",
    dose: "2 g EPA+DHA",
    timing: "With breakfast",
    benefit: "Inflammation, cardiovascular health, joint recovery",
    streak: 23,
    loggedToday: false,
    category: "recovery",
  },
  {
    id: "s4",
    name: "Magnesium Glycinate",
    dose: "400 mg",
    timing: "30 min before bed",
    benefit: "Sleep depth, muscle relaxation, HRV",
    streak: 12,
    loggedToday: false,
    category: "sleep",
  },
  {
    id: "s5",
    name: "Vitamin D3 + K2",
    dose: "4000 IU / 100 mcg",
    timing: "With fat-containing meal",
    benefit: "Testosterone, immunity, bone health, mood",
    streak: 34,
    loggedToday: true,
    category: "health",
  },
  {
    id: "s6",
    name: "Zinc",
    dose: "15 mg",
    timing: "With food, not w/ calcium",
    benefit: "Testosterone, immunity, sleep",
    streak: 21,
    loggedToday: true,
    category: "health",
  },
  {
    id: "s7",
    name: "Electrolytes (LMNT)",
    dose: "1 stick",
    timing: "Pre-training, post-sauna",
    benefit: "Hydration, performance, sleep onset",
    streak: 18,
    loggedToday: false,
    category: "performance",
  },
  {
    id: "s8",
    name: "Caffeine",
    dose: "200 mg",
    timing: "Pre-training",
    benefit: "Output, alertness",
    streak: 5,
    loggedToday: true,
    category: "performance",
  },
  {
    id: "s9",
    name: "Multivitamin",
    dose: "1 capsule",
    timing: "Breakfast",
    benefit: "Micronutrient insurance",
    streak: 8,
    loggedToday: false,
    category: "health",
  },
];
