export type Food = {
  id: string;
  name: string;
  brand?: string;
  serving: string;
  calories: number;
  protein: number;
  carbs: number;
  fat: number;
  fiber?: number;
  sugar?: number;
  saturated?: number;
  cholesterol?: number;
  sodium?: number;
};

export const foodDb: Food[] = [
  { id: "f1", name: "Chicken Breast, grilled", serving: "200 g", calories: 330, protein: 62, carbs: 0, fat: 7.2, saturated: 2.1, sodium: 148 },
  { id: "f2", name: "Sirloin Steak, lean", serving: "180 g", calories: 360, protein: 50, carbs: 0, fat: 17, saturated: 6.4, sodium: 110 },
  { id: "f3", name: "Wild Salmon, baked", serving: "150 g", calories: 280, protein: 38, carbs: 0, fat: 13, saturated: 2.5 },
  { id: "f4", name: "Whole Eggs", serving: "3 large", calories: 215, protein: 19, carbs: 1, fat: 15, cholesterol: 559 },
  { id: "f5", name: "Greek Yogurt, 0%", brand: "Fage", serving: "200 g", calories: 117, protein: 21, carbs: 7, fat: 0 },
  { id: "f6", name: "Whey Isolate", brand: "Ascent", serving: "1 scoop (32g)", calories: 120, protein: 25, carbs: 2, fat: 1 },
  { id: "f7", name: "Cottage Cheese 2%", serving: "1 cup", calories: 180, protein: 24, carbs: 8, fat: 5 },
  { id: "f8", name: "Tuna, canned in water", serving: "1 can (142g)", calories: 130, protein: 30, carbs: 0, fat: 1 },
  { id: "f9", name: "Brown Rice, cooked", serving: "1 cup", calories: 218, protein: 5, carbs: 46, fat: 1.6, fiber: 3.5 },
  { id: "f10", name: "Sweet Potato, baked", serving: "200 g", calories: 180, protein: 4, carbs: 41, fat: 0.3, fiber: 6.6 },
  { id: "f11", name: "Oats, dry", serving: "80 g", calories: 304, protein: 11, carbs: 54, fat: 5.4, fiber: 8 },
  { id: "f12", name: "Banana", serving: "1 medium", calories: 105, protein: 1.3, carbs: 27, fat: 0.4, fiber: 3.1, sugar: 14 },
  { id: "f13", name: "Blueberries", serving: "150 g", calories: 86, protein: 1.1, carbs: 22, fat: 0.5, fiber: 3.6, sugar: 15 },
  { id: "f14", name: "Avocado", serving: "1/2", calories: 160, protein: 2, carbs: 9, fat: 15, fiber: 7 },
  { id: "f15", name: "Olive Oil, extra virgin", serving: "1 tbsp", calories: 120, protein: 0, carbs: 0, fat: 14, saturated: 2 },
  { id: "f16", name: "Almonds", serving: "30 g", calories: 174, protein: 6.4, carbs: 6.1, fat: 15, fiber: 3.7 },
  { id: "f17", name: "Spinach, raw", serving: "100 g", calories: 23, protein: 2.9, carbs: 3.6, fat: 0.4, fiber: 2.2 },
  { id: "f18", name: "Broccoli, steamed", serving: "1 cup", calories: 55, protein: 3.7, carbs: 11, fat: 0.6, fiber: 5.1 },
];

export type MealLog = {
  id: string;
  meal: "breakfast" | "lunch" | "dinner" | "snack" | "pre" | "post";
  time: string;
  items: { foodId: string; servings: number }[];
};

export const todaysMeals: MealLog[] = [
  {
    id: "m1",
    meal: "breakfast",
    time: "06:45",
    items: [
      { foodId: "f4", servings: 1 }, // 3 eggs
      { foodId: "f11", servings: 1 }, // 80g oats
      { foodId: "f12", servings: 1 }, // banana
      { foodId: "f13", servings: 0.5 }, // berries
    ],
  },
  {
    id: "m2",
    meal: "post",
    time: "09:30",
    items: [
      { foodId: "f6", servings: 1.5 }, // 1.5 scoops whey
    ],
  },
  {
    id: "m3",
    meal: "lunch",
    time: "12:50",
    items: [
      { foodId: "f1", servings: 1 }, // 200g chicken
      { foodId: "f9", servings: 1 }, // brown rice
      { foodId: "f18", servings: 1 }, // broccoli
      { foodId: "f15", servings: 1 }, // olive oil
    ],
  },
];

export type DeficiencyAlert = {
  nutrient: string;
  current: number;
  target: number;
  unit: string;
  severity: "low" | "medium" | "high";
  recommendation: string;
};

export const deficiencies: DeficiencyAlert[] = [
  {
    nutrient: "Magnesium",
    current: 184,
    target: 420,
    unit: "mg",
    severity: "medium",
    recommendation:
      "Average intake is 44% of target across the last 7 days. Add a Mg-glycinate supplement at night (300–400 mg) or 100g of pumpkin seeds daily. Low Mg correlates with your elevated resting HR and disrupted sleep.",
  },
  {
    nutrient: "Vitamin D",
    current: 12,
    target: 25,
    unit: "mcg",
    severity: "high",
    recommendation:
      "Sustained low intake — also consistent with your last bloodwork (28 ng/mL). 2000–4000 IU/day with fat. Re-test in 90 days.",
  },
  {
    nutrient: "Omega-3 (EPA+DHA)",
    current: 0.7,
    target: 2.5,
    unit: "g",
    severity: "medium",
    recommendation:
      "You're at 28% of target. Add 2 g EPA+DHA fish oil daily. This supports recovery and may help the shoulder inflammation.",
  },
  {
    nutrient: "Hydration",
    current: 2.1,
    target: 3.7,
    unit: "L",
    severity: "medium",
    recommendation:
      "57% of daily target by 2pm. Pair with electrolytes — your sodium intake is on the low end for your training load.",
  },
  {
    nutrient: "Sodium",
    current: 4280,
    target: 3500,
    unit: "mg",
    severity: "low",
    recommendation:
      "Over by 22%. Mostly fine given your sweat rate, but reduce processed meats this week to balance.",
  },
];

// Micronutrient targets vs intake (7-day rolling avg %)
export const micronutrientMatrix = [
  { group: "Vitamins", items: [
    { name: "Vitamin A", pct: 92 },
    { name: "B1", pct: 110 },
    { name: "B2", pct: 121 },
    { name: "B3", pct: 145 },
    { name: "B5", pct: 88 },
    { name: "B6", pct: 132 },
    { name: "B7", pct: 75 },
    { name: "B9 (Folate)", pct: 82 },
    { name: "B12", pct: 168 },
    { name: "Vitamin C", pct: 154 },
    { name: "Vitamin D", pct: 48 },
    { name: "Vitamin E", pct: 71 },
    { name: "Vitamin K", pct: 124 },
  ] },
  { group: "Minerals", items: [
    { name: "Calcium", pct: 84 },
    { name: "Iron", pct: 121 },
    { name: "Magnesium", pct: 44 },
    { name: "Potassium", pct: 76 },
    { name: "Sodium", pct: 122 },
    { name: "Zinc", pct: 108 },
    { name: "Copper", pct: 95 },
    { name: "Selenium", pct: 138 },
    { name: "Iodine", pct: 67 },
    { name: "Chromium", pct: 89 },
    { name: "Phosphorus", pct: 116 },
    { name: "Chloride", pct: 102 },
    { name: "Molybdenum", pct: 94 },
  ] },
  { group: "Advanced", items: [
    { name: "Omega-3", pct: 28 },
    { name: "Omega-6", pct: 142 },
    { name: "EAAs", pct: 174 },
    { name: "Cholesterol", pct: 88 },
    { name: "Saturated Fat", pct: 91 },
    { name: "Unsaturated Fat", pct: 104 },
    { name: "Caffeine", pct: 60 },
    { name: "Creatine", pct: 100 },
  ] },
];

export const savedMeals = [
  { id: "sm1", name: "Big Breakfast", calories: 720, protein: 52, carbs: 78, fat: 18, ingredients: 4 },
  { id: "sm2", name: "Post-Lift Shake", calories: 380, protein: 50, carbs: 38, fat: 4, ingredients: 3 },
  { id: "sm3", name: "Cut Lunch (Chicken/Rice/Broccoli)", calories: 620, protein: 70, carbs: 60, fat: 11, ingredients: 4 },
  { id: "sm4", name: "Casein Pudding", calories: 240, protein: 38, carbs: 14, fat: 3, ingredients: 3 },
];
