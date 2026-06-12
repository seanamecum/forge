import Foundation

/// Central demo dataset. Every module reads from one coherent story:
/// Sean — 21, hockey athlete, intermediate, lean-bulking, mild patellar tendinopathy (left knee),
/// recovery 78, sleep 7.2 h, 23-day streak. Bench 180 · Squat 230 · Deadlift 280.
enum MockData {

    // MARK: - User

    static let sean = UserProfile(
        name: "Sean Calloway",
        age: 21,
        sex: .male,
        heightInches: 75,            // 6'3"
        weightLb: 200,
        fitnessLevel: .intermediate,
        activityLevel: .veryActive,
        goals: [.buildMuscle, .athletic],
        experienceYears: 3,
        equipment: [.fullGym, .barbell],
        diet: .highProtein,
        sport: "Ice Hockey",
        level: 12,
        xp: 6840,
        xpToNext: 8000,
        streakDays: 23
    )

    // MARK: - Recovery snapshot

    static let today = RecoveryData(
        recovery: 78,
        hrv: 58,
        hrvBaseline: 62,
        restingHR: 56,
        sleep: SleepData(hours: 7.2, deepHours: 1.1, remHours: 1.5, lightHours: 4.2,
                         awakeHours: 0.4, score: 81, bedtime: "23:10", waketime: "06:25"),
        strainYesterday: 14.2,
        strainToday: 6.8,
        steps: 7840,
        stepGoal: 10000,
        caloriesOut: 2950,
        sleepDebtHours: 3.1,
        readiness: .high
    )

    // MARK: - Trends (14 days)

    static let forgeScoreTrend: [Double] = [68, 70, 72, 69, 74, 76, 73, 75, 71, 74, 77, 75, 73, 76]
    static let recoveryTrend: [Double] = [64, 70, 74, 68, 76, 80, 74, 78, 72, 75, 81, 79, 74, 78]
    static let hrvTrend: [Double] = [54, 57, 60, 56, 61, 63, 59, 62, 58, 60, 64, 62, 59, 58]
    static let sleepTrend: [Double] = [6.8, 7.1, 7.6, 6.9, 7.8, 8.1, 7.2, 7.5, 6.7, 7.3, 7.9, 7.4, 7.0, 7.2]
    static let strainTrend: [Double] = [12, 15, 17, 9, 14, 18, 16, 11, 13, 16, 18, 12, 14, 14.2]
    static let weightTrend: [Double] = [196.8, 197.2, 197.6, 197.4, 198.1, 198.4, 198.2, 198.8, 199.1, 199.0, 199.4, 199.6, 199.8, 200.0]

    // MARK: - Wearables

    static let wearables: [WearableDevice] = [
        WearableDevice(name: "Apple Watch Ultra", brand: "Apple", icon: "applewatch",
                       connected: true, lastSync: "2 min ago",
                       permissions: ["Heart Rate", "Workouts", "Sleep", "Steps", "Energy"], battery: 76),
        WearableDevice(name: "WHOOP 5.0", brand: "WHOOP", icon: "waveform.path.ecg",
                       connected: true, lastSync: "6 min ago",
                       permissions: ["HRV", "RHR", "Sleep Stages", "Strain", "Recovery"], battery: 58),
        WearableDevice(name: "Oura Ring Gen 4", brand: "Oura", icon: "circle.circle",
                       connected: false, lastSync: nil,
                       permissions: ["HRV", "Temperature", "Readiness"]),
        WearableDevice(name: "Garmin Fenix 8", brand: "Garmin", icon: "location.north.circle",
                       connected: false, lastSync: nil,
                       permissions: ["GPS", "Running Power", "VO₂ Max"]),
        WearableDevice(name: "Fitbit Charge 7", brand: "Fitbit", icon: "heart.circle",
                       connected: false, lastSync: nil,
                       permissions: ["Heart Rate", "Sleep", "Steps"]),
        WearableDevice(name: "Polar H10", brand: "Polar", icon: "bolt.heart",
                       connected: false, lastSync: nil,
                       permissions: ["Live HR", "HRV Training"]),
        WearableDevice(name: "Withings Body Scan", brand: "Withings", icon: "scalemass",
                       connected: true, lastSync: "this morning",
                       permissions: ["Weight", "Body Fat", "Lean Mass"], battery: 91),
    ]

    // MARK: - Foods

    static let foods: [Food] = [
        Food(id: "chicken", name: "Chicken Breast, grilled", serving: "8 oz", calories: 374, protein: 70, carbs: 0, fat: 8),
        Food(id: "steak", name: "Sirloin Steak, lean", serving: "6 oz", calories: 340, protein: 46, carbs: 0, fat: 16),
        Food(id: "salmon", name: "Atlantic Salmon", serving: "6 oz", calories: 350, protein: 38, carbs: 0, fat: 21),
        Food(id: "eggs", name: "Whole Eggs", serving: "3 large", calories: 215, protein: 19, carbs: 1, fat: 15),
        Food(id: "greekyogurt", name: "Greek Yogurt 0%", brand: "Fage", serving: "1 cup", calories: 130, protein: 23, carbs: 9, fat: 0),
        Food(id: "whey", name: "Whey Protein", brand: "Ascent", serving: "1 scoop", calories: 120, protein: 25, carbs: 3, fat: 1),
        Food(id: "rice", name: "White Rice, cooked", serving: "1.5 cups", calories: 308, protein: 6, carbs: 67, fat: 0.5),
        Food(id: "oats", name: "Oats, dry", serving: "1 cup", calories: 300, protein: 11, carbs: 54, fat: 5, fiber: 8),
        Food(id: "sweetpotato", name: "Sweet Potato", serving: "1 large", calories: 160, protein: 4, carbs: 37, fat: 0.2, fiber: 6),
        Food(id: "banana", name: "Banana", serving: "1 medium", calories: 105, protein: 1, carbs: 27, fat: 0.4, sugar: 14),
        Food(id: "berries", name: "Mixed Berries", serving: "1 cup", calories: 85, protein: 1, carbs: 21, fat: 0.5, fiber: 4),
        Food(id: "avocado", name: "Avocado", serving: "1/2", calories: 160, protein: 2, carbs: 9, fat: 15, fiber: 7),
        Food(id: "almonds", name: "Almonds", serving: "1 oz", calories: 164, protein: 6, carbs: 6, fat: 14),
        Food(id: "oliveoil", name: "Olive Oil", serving: "1 tbsp", calories: 120, protein: 0, carbs: 0, fat: 14),
        Food(id: "broccoli", name: "Broccoli, steamed", serving: "1 cup", calories: 55, protein: 4, carbs: 11, fat: 0.6, fiber: 5),
        Food(id: "spinach", name: "Spinach", serving: "2 cups", calories: 14, protein: 2, carbs: 2, fat: 0.2),
        Food(id: "pasta", name: "Pasta, cooked", serving: "1.5 cups", calories: 330, protein: 12, carbs: 65, fat: 2),
        Food(id: "milk", name: "Whole Milk", serving: "1 cup", calories: 150, protein: 8, carbs: 12, fat: 8),
    ]

    static func food(_ id: String) -> Food {
        foods.first { $0.id == id } ?? foods[0]
    }

    static let todaysEntries: [FoodEntry] = [
        FoodEntry(meal: .breakfast, food: food("eggs"), servings: 1, time: "7:05 AM"),
        FoodEntry(meal: .breakfast, food: food("oats"), servings: 1, time: "7:05 AM"),
        FoodEntry(meal: .breakfast, food: food("banana"), servings: 1, time: "7:05 AM"),
        FoodEntry(meal: .snack, food: food("whey"), servings: 1.5, time: "10:10 AM"),
        FoodEntry(meal: .lunch, food: food("chicken"), servings: 1, time: "12:40 PM"),
        FoodEntry(meal: .lunch, food: food("rice"), servings: 1, time: "12:40 PM"),
        FoodEntry(meal: .lunch, food: food("broccoli"), servings: 1, time: "12:40 PM"),
        FoodEntry(meal: .snack, food: food("greekyogurt"), servings: 1, time: "3:30 PM"),
        FoodEntry(meal: .snack, food: food("almonds"), servings: 1, time: "3:30 PM"),
    ]

    static let savedMeals: [SavedMeal] = [
        SavedMeal(name: "Hockey Breakfast", calories: 620, protein: 31, carbs: 82, fat: 20, itemCount: 3),
        SavedMeal(name: "Post-Lift Shake", calories: 285, protein: 39, carbs: 30, fat: 2, itemCount: 2),
        SavedMeal(name: "Bulk Lunch", calories: 737, protein: 80, carbs: 78, fat: 9, itemCount: 3),
        SavedMeal(name: "Night Casein Bowl", calories: 310, protein: 35, carbs: 25, fat: 6, itemCount: 3),
    ]

    // MARK: - Micronutrients (7-day avg, % of target)

    static let nutrientGroups: [NutrientGroup] = [
        NutrientGroup(name: "Vitamins", items: [
            NutrientStatus(name: "Vitamin A", percentOfTarget: 94),
            NutrientStatus(name: "B1 Thiamine", percentOfTarget: 112),
            NutrientStatus(name: "B2 Riboflavin", percentOfTarget: 124),
            NutrientStatus(name: "B3 Niacin", percentOfTarget: 148),
            NutrientStatus(name: "B5 Pantothenic", percentOfTarget: 86),
            NutrientStatus(name: "B6", percentOfTarget: 128),
            NutrientStatus(name: "B7 Biotin", percentOfTarget: 74),
            NutrientStatus(name: "B9 Folate", percentOfTarget: 81),
            NutrientStatus(name: "B12", percentOfTarget: 172),
            NutrientStatus(name: "Vitamin C", percentOfTarget: 138),
            NutrientStatus(name: "Vitamin D", percentOfTarget: 41),
            NutrientStatus(name: "Vitamin E", percentOfTarget: 69),
            NutrientStatus(name: "Vitamin K", percentOfTarget: 117),
        ]),
        NutrientGroup(name: "Minerals", items: [
            NutrientStatus(name: "Calcium", percentOfTarget: 96),
            NutrientStatus(name: "Iron", percentOfTarget: 118),
            NutrientStatus(name: "Magnesium", percentOfTarget: 52),
            NutrientStatus(name: "Potassium", percentOfTarget: 78),
            NutrientStatus(name: "Sodium", percentOfTarget: 134),
            NutrientStatus(name: "Zinc", percentOfTarget: 104),
            NutrientStatus(name: "Copper", percentOfTarget: 92),
            NutrientStatus(name: "Selenium", percentOfTarget: 141),
            NutrientStatus(name: "Iodine", percentOfTarget: 66),
            NutrientStatus(name: "Chromium", percentOfTarget: 88),
            NutrientStatus(name: "Phosphorus", percentOfTarget: 121),
            NutrientStatus(name: "Chloride", percentOfTarget: 103),
            NutrientStatus(name: "Molybdenum", percentOfTarget: 95),
        ]),
        NutrientGroup(name: "Advanced", items: [
            NutrientStatus(name: "Omega-3", percentOfTarget: 34),
            NutrientStatus(name: "Omega-6", percentOfTarget: 146),
            NutrientStatus(name: "Essential Aminos", percentOfTarget: 168),
            NutrientStatus(name: "Cholesterol", percentOfTarget: 90),
            NutrientStatus(name: "Saturated Fat", percentOfTarget: 88),
            NutrientStatus(name: "Unsaturated Fat", percentOfTarget: 106),
            NutrientStatus(name: "Electrolytes", percentOfTarget: 82),
            NutrientStatus(name: "Caffeine", percentOfTarget: 55),
            NutrientStatus(name: "Creatine", percentOfTarget: 100),
        ]),
    ]

    static let deficiencies: [DeficiencyAlert] = [
        DeficiencyAlert(nutrient: "Magnesium", severity: .medium, current: "218 mg", target: "420 mg", daysLow: 6,
                        recommendation: "52% of target for 6 straight days. Mg-glycinate 400 mg, 30 min before bed — it's also your fastest path to deeper sleep and better HRV."),
        DeficiencyAlert(nutrient: "Vitamin D", severity: .high, current: "820 IU", target: "2000 IU", daysLow: 14,
                        recommendation: "Low intake plus indoor training season. 2000–4000 IU D3 with a fat-containing meal. Re-check bloodwork in 90 days."),
        DeficiencyAlert(nutrient: "Omega-3", severity: .medium, current: "0.8 g", target: "2.5 g", daysLow: 9,
                        recommendation: "34% of target. 2 g EPA+DHA daily supports joint recovery — relevant to the knee — and post-practice inflammation."),
        DeficiencyAlert(nutrient: "Protein", severity: .low, current: "178 g avg", target: "200 g", daysLow: 3,
                        recommendation: "Close, but you're leaving muscle on the table during a lean bulk. Add one 40 g protein meal — the casein bowl covers it."),
        DeficiencyAlert(nutrient: "Hydration", severity: .medium, current: "74 oz avg", target: "120 oz", daysLow: 5,
                        recommendation: "62% of target. Hockey sweat rates run high — add electrolytes to your first bottle of the day."),
        DeficiencyAlert(nutrient: "Sleep", severity: .medium, current: "7.2 h avg", target: "8.5 h", daysLow: 7,
                        recommendation: "3.1 h cumulative debt this week. As a 21-year-old athlete your ceiling is 8.5–9 h. Lights out 22:30 tonight."),
    ]

    // MARK: - Supplements

    static let supplements: [Supplement] = [
        Supplement(name: "Creatine Monohydrate", dose: "5 g", timing: "Daily, any time", benefit: "Strength, power, recovery between shifts", streak: 23, loggedToday: true),
        Supplement(name: "Whey Protein", dose: "25–50 g", timing: "Post-workout", benefit: "Hit the 200 g protein target", streak: 23, loggedToday: true),
        Supplement(name: "Fish Oil", dose: "2 g EPA+DHA", timing: "With breakfast", benefit: "Joint health, inflammation", streak: 9, loggedToday: false),
        Supplement(name: "Magnesium Glycinate", dose: "400 mg", timing: "30 min before bed", benefit: "Sleep depth, HRV, muscle relaxation", streak: 4, loggedToday: false),
        Supplement(name: "Vitamin D3 + K2", dose: "4000 IU", timing: "With fat-containing meal", benefit: "Hormones, bone density, immunity", streak: 15, loggedToday: true),
        Supplement(name: "Zinc", dose: "15 mg", timing: "With dinner", benefit: "Testosterone, immune support", streak: 11, loggedToday: false),
        Supplement(name: "Electrolytes", dose: "1 packet", timing: "Pre-practice", benefit: "Hydration at hockey sweat rates", streak: 7, loggedToday: true),
        Supplement(name: "Caffeine", dose: "150 mg", timing: "Pre-training, before 2 PM", benefit: "Output and focus", streak: 3, loggedToday: true),
        Supplement(name: "Multivitamin", dose: "1 capsule", timing: "Breakfast", benefit: "Micronutrient insurance", streak: 5, loggedToday: false),
    ]

    // MARK: - Bloodwork

    static let bloodwork: [BloodworkMarker] = [
        BloodworkMarker(name: "Total Testosterone", category: .hormones, value: 645, unit: "ng/dL",
                        normalLow: 264, normalHigh: 916, optimalLow: 600, optimalHigh: 900,
                        takenAt: "May 2026", delta: "+38",
                        aiNote: "Strong for your age and trending up with the lean bulk. Protect it with sleep — that's your weakest input."),
        BloodworkMarker(name: "Free Testosterone", category: .hormones, value: 16.8, unit: "ng/dL",
                        normalLow: 9, normalHigh: 30, optimalLow: 15, optimalHigh: 25,
                        takenAt: "May 2026",
                        aiNote: "Healthy free fraction. No action needed."),
        BloodworkMarker(name: "Vitamin D (25-OH)", category: .vitamins, value: 26, unit: "ng/mL",
                        normalLow: 30, normalHigh: 100, optimalLow: 50, optimalHigh: 70,
                        takenAt: "May 2026",
                        aiNote: "Below range — consistent with your 41% dietary intake. 4000 IU D3 + K2 daily, re-test in 90 days. Indoor ice season makes this worse."),
        BloodworkMarker(name: "Iron, Serum", category: .vitamins, value: 102, unit: "mcg/dL",
                        normalLow: 65, normalHigh: 175, optimalLow: 90, optimalHigh: 150,
                        takenAt: "May 2026", aiNote: "Optimal."),
        BloodworkMarker(name: "Ferritin", category: .vitamins, value: 88, unit: "ng/mL",
                        normalLow: 30, normalHigh: 400, optimalLow: 80, optimalHigh: 200,
                        takenAt: "May 2026", aiNote: "Healthy stores for an endurance-heavy sport."),
        BloodworkMarker(name: "Vitamin B12", category: .vitamins, value: 540, unit: "pg/mL",
                        normalLow: 200, normalHigh: 900, optimalLow: 500, optimalHigh: 800,
                        takenAt: "May 2026", aiNote: "Solid — supports your training volume."),
        BloodworkMarker(name: "Total Cholesterol", category: .lipids, value: 172, unit: "mg/dL",
                        normalLow: 125, normalHigh: 200, optimalLow: 150, optimalHigh: 180,
                        takenAt: "May 2026", aiNote: "Optimal."),
        BloodworkMarker(name: "HDL", category: .lipids, value: 58, unit: "mg/dL",
                        normalLow: 40, normalHigh: 90, optimalLow: 50, optimalHigh: 80,
                        takenAt: "May 2026", delta: "+6", aiNote: "Excellent — conditioning work is paying off."),
        BloodworkMarker(name: "LDL", category: .lipids, value: 94, unit: "mg/dL",
                        normalLow: 0, normalHigh: 130, optimalLow: 60, optimalHigh: 100,
                        takenAt: "May 2026", aiNote: "Within optimal. Watch saturated fat as bulk calories climb."),
        BloodworkMarker(name: "Triglycerides", category: .lipids, value: 72, unit: "mg/dL",
                        normalLow: 0, normalHigh: 150, optimalLow: 40, optimalHigh: 100,
                        takenAt: "May 2026", aiNote: "Excellent insulin sensitivity signal."),
        BloodworkMarker(name: "Fasting Glucose", category: .metabolic, value: 86, unit: "mg/dL",
                        normalLow: 70, normalHigh: 99, optimalLow: 75, optimalHigh: 90,
                        takenAt: "May 2026", aiNote: "Optimal."),
        BloodworkMarker(name: "HbA1c", category: .metabolic, value: 5.1, unit: "%",
                        normalLow: 4, normalHigh: 5.6, optimalLow: 4.6, optimalHigh: 5.3,
                        takenAt: "May 2026", aiNote: "Optimal glycemic control."),
        BloodworkMarker(name: "hs-CRP", category: .inflammation, value: 1.2, unit: "mg/L",
                        normalLow: 0, normalHigh: 3, optimalLow: 0, optimalHigh: 1,
                        takenAt: "May 2026", delta: "+0.3",
                        aiNote: "Slightly above optimal — plausibly the knee plus a heavy training block. Re-check after the rehab phase ends."),
        BloodworkMarker(name: "TSH", category: .thyroid, value: 1.6, unit: "mIU/L",
                        normalLow: 0.4, normalHigh: 4.5, optimalLow: 1.0, optimalHigh: 2.5,
                        takenAt: "May 2026", aiNote: "Optimal thyroid signal."),
    ]

    // MARK: - Body tracking

    static let bodyHistory: [BodySnapshot] = [
        BodySnapshot(date: "Mar 10", weightLb: 193.5, bodyFatPct: 13.2, leanMassLb: 168.0),
        BodySnapshot(date: "Apr 10", weightLb: 196.0, bodyFatPct: 13.6, leanMassLb: 169.3),
        BodySnapshot(date: "May 10", weightLb: 198.2, bodyFatPct: 13.9, leanMassLb: 170.6),
        BodySnapshot(date: "Jun 10", weightLb: 200.0, bodyFatPct: 14.1, leanMassLb: 171.8),
    ]

    static let measurements: [BodyMeasurement] = [
        BodyMeasurement(name: "Neck", value: "15.8 in"),
        BodyMeasurement(name: "Chest", value: "42.5 in", delta30d: "+0.4"),
        BodyMeasurement(name: "Waist", value: "33.0 in", delta30d: "+0.2"),
        BodyMeasurement(name: "Hips", value: "39.5 in"),
        BodyMeasurement(name: "L Arm", value: "15.2 in", delta30d: "+0.2"),
        BodyMeasurement(name: "R Arm", value: "15.4 in", delta30d: "+0.2"),
        BodyMeasurement(name: "L Forearm", value: "12.1 in"),
        BodyMeasurement(name: "R Forearm", value: "12.2 in"),
        BodyMeasurement(name: "L Thigh", value: "24.6 in", delta30d: "+0.3"),
        BodyMeasurement(name: "R Thigh", value: "24.8 in", delta30d: "+0.3"),
        BodyMeasurement(name: "L Calf", value: "15.9 in"),
        BodyMeasurement(name: "R Calf", value: "16.0 in"),
    ]

    // MARK: - Forecasts

    static let forecasts: [Forecast] = [
        Forecast(metric: "Body Weight", current: "200 lb", projected: "207 lb", eta: "12 weeks",
                 confidence: 0.84, rationale: "Current +280 kcal surplus and 0.6 lb/week trend, sustained. Lean-mass fraction holding at 68% of gain."),
        Forecast(metric: "Bench Press", current: "180 lb", projected: "225 lb", eta: "Nov 6",
                 confidence: 0.74, rationale: "Linear-to-diminishing progression at your training age, assuming RPE cap fix below. The plateau is recoverable."),
        Forecast(metric: "Squat", current: "230 lb", projected: "275 lb", eta: "14 weeks",
                 confidence: 0.70, rationale: "Held back ~3 weeks by knee rehab phase. Resumes full slope once return-to-sport criteria clear."),
        Forecast(metric: "Body Fat", current: "14.1%", projected: "15.0%", eta: "12 weeks",
                 confidence: 0.78, rationale: "Acceptable drift for a lean bulk. Flag triggers at 16% — we'd insert a 4-week mini-cut."),
        Forecast(metric: "Recovery (avg)", current: "75", projected: "83", eta: "30 days",
                 confidence: 0.69, rationale: "Driven almost entirely by sleep: 8 h × 6 nights/week plus Mg closes the gap."),
        Forecast(metric: "Overtraining Risk", current: "22%", projected: "9%", eta: "2 weeks",
                 confidence: 0.81, rationale: "ACR normalizes to 1.05 if this week's volume holds flat while the knee finishes rehab."),
    ]

    // MARK: - Community

    static let feed: [SocialPost] = [
        SocialPost(author: "Jake Morrow", handle: "@jmorrow", level: 18, time: "14m", kind: .pr,
                   body: "Two years chasing this. 225 finally moved.", statLabel: "Bench Press", statValue: "225 lb × 1",
                   likes: 67, comments: 12),
        SocialPost(author: "Ava Chen", handle: "@avachen", level: 22, time: "1h", kind: .workout,
                   body: "Track intervals before sunrise. Lungs on fire.", statLabel: "Strain", statValue: "18.7 · 52 min",
                   likes: 41, comments: 5),
        SocialPost(author: "Coach Reyes", handle: "@reyesperf", level: 41, time: "2h", kind: .share,
                   body: "Athletes: your warm-up is rehearsal, not foreplay. Treat the empty bar like it's 405.",
                   likes: 230, comments: 34),
        SocialPost(author: "Sean Calloway", handle: "@scalloway", level: 12, time: "yesterday", kind: .pr,
                   body: "Deadlift moving again after the deload.", statLabel: "Deadlift", statValue: "280 lb × 3",
                   likes: 38, comments: 7),
        SocialPost(author: "Mia Tanaka", handle: "@miatk", level: 26, time: "yesterday", kind: .progress,
                   body: "12-week recomp. Same weight. Completely different athlete.", statLabel: "Body Fat", statValue: "−3.8%",
                   likes: 154, comments: 19),
    ]

    static let groups: [CommunityGroup] = [
        CommunityGroup(name: "Hockey Athletes", tag: "Sport", members: 14820, blurb: "Off-season strength, in-season maintenance.", joined: true),
        CommunityGroup(name: "Powerlifting Club", tag: "Strength", members: 28430, blurb: "Squat, bench, deadlift. Meet prep."),
        CommunityGroup(name: "Running Collective", tag: "Endurance", members: 41200, blurb: "5K to ultra."),
        CommunityGroup(name: "Bodybuilding", tag: "Aesthetic", members: 35610, blurb: "Hypertrophy and contest prep."),
        CommunityGroup(name: "Hybrid Athletes", tag: "Hybrid", members: 18900, blurb: "Strength + engine."),
        CommunityGroup(name: "College Athletes", tag: "Performance", members: 9450, blurb: "NCAA, club, intramural.", joined: true),
    ]

    static let leaderboards: [Leaderboard] = [
        Leaderboard(title: "Steps · This Week", subtitle: "Total steps", entries: [
            LeaderboardEntry(rank: 1, name: "Ava C.", value: "92,410"),
            LeaderboardEntry(rank: 2, name: "Jake M.", value: "88,150"),
            LeaderboardEntry(rank: 3, name: "Sean C.", value: "81,940", isMe: true),
            LeaderboardEntry(rank: 4, name: "Mia T.", value: "78,320"),
            LeaderboardEntry(rank: 5, name: "Leo D.", value: "74,610"),
        ]),
        Leaderboard(title: "Strength · Wilks", subtitle: "BW-relative total", entries: [
            LeaderboardEntry(rank: 1, name: "Coach Reyes", value: "428"),
            LeaderboardEntry(rank: 2, name: "Jake M.", value: "395"),
            LeaderboardEntry(rank: 3, name: "Leo D.", value: "361"),
            LeaderboardEntry(rank: 4, name: "Sean C.", value: "344", isMe: true),
            LeaderboardEntry(rank: 5, name: "Ava C.", value: "338"),
        ]),
        Leaderboard(title: "Workout Streak", subtitle: "Consecutive days", entries: [
            LeaderboardEntry(rank: 1, name: "Coach Reyes", value: "365 d"),
            LeaderboardEntry(rank: 2, name: "Mia T.", value: "112 d"),
            LeaderboardEntry(rank: 3, name: "Ava C.", value: "58 d"),
            LeaderboardEntry(rank: 4, name: "Sean C.", value: "23 d", isMe: true),
            LeaderboardEntry(rank: 5, name: "Jake M.", value: "19 d"),
        ]),
        Leaderboard(title: "Protein Consistency", subtitle: "% days on target", entries: [
            LeaderboardEntry(rank: 1, name: "Mia T.", value: "97%"),
            LeaderboardEntry(rank: 2, name: "Sean C.", value: "91%", isMe: true),
            LeaderboardEntry(rank: 3, name: "Jake M.", value: "88%"),
            LeaderboardEntry(rank: 4, name: "Coach Reyes", value: "86%"),
            LeaderboardEntry(rank: 5, name: "Ava C.", value: "82%"),
        ]),
        Leaderboard(title: "Calories Burned", subtitle: "This week", entries: [
            LeaderboardEntry(rank: 1, name: "Ava C.", value: "21,480"),
            LeaderboardEntry(rank: 2, name: "Sean C.", value: "20,150", isMe: true),
            LeaderboardEntry(rank: 3, name: "Jake M.", value: "18,940"),
            LeaderboardEntry(rank: 4, name: "Leo D.", value: "17,210"),
            LeaderboardEntry(rank: 5, name: "Mia T.", value: "16,830"),
        ]),
        Leaderboard(title: "Running Distance", subtitle: "This month", entries: [
            LeaderboardEntry(rank: 1, name: "Ava C.", value: "84.2 mi"),
            LeaderboardEntry(rank: 2, name: "Leo D.", value: "61.7 mi"),
            LeaderboardEntry(rank: 3, name: "Mia T.", value: "48.9 mi"),
            LeaderboardEntry(rank: 4, name: "Jake M.", value: "32.1 mi"),
            LeaderboardEntry(rank: 5, name: "Sean C.", value: "28.4 mi", isMe: true),
        ]),
    ]

    static let challenges: [Challenge] = [
        Challenge(name: "30-Day Protein Challenge", participants: 4280, daysLeft: 22, progress: 0.27, reward: "Protein King badge", joined: true),
        Challenge(name: "100-Mile Month", participants: 2110, daysLeft: 22, progress: 0.28, reward: "Endurance badge"),
        Challenge(name: "10K Steps Daily", participants: 11800, daysLeft: 22, progress: 0.27, reward: "Movement Streak", joined: true),
        Challenge(name: "Bench Press Challenge — 1.5× BW", participants: 3210, daysLeft: 90, progress: 0.60, reward: "1000-lb Club credit"),
        Challenge(name: "Summer Shred — 6 Weeks", participants: 8430, daysLeft: 41, progress: 0.02, reward: "Shred badge"),
        Challenge(name: "Hockey Off-Season Challenge", participants: 1420, daysLeft: 60, progress: 0.33, reward: "Ice Ready badge", joined: true),
    ]

    static let badges: [Badge] = [
        Badge(name: "First Rep", detail: "Logged your first set", earned: true, earnedDate: "Sep 2024"),
        Badge(name: "7-Day Streak", detail: "Seven straight training days", earned: true, earnedDate: "Oct 2024"),
        Badge(name: "One Plate Bench", detail: "Bench 135 lb", earned: true, earnedDate: "Jan 2025"),
        Badge(name: "Two Plate Bench", detail: "Bench 225 lb — 45 lb to go", earned: false),
        Badge(name: "100 Workouts", detail: "100 sessions logged", earned: true, earnedDate: "Nov 2025"),
        Badge(name: "1000 Pound Club", detail: "S+B+D ≥ 1000 lb · currently 690", earned: false),
        Badge(name: "Marathon", detail: "Complete 26.2 miles", earned: false),
        Badge(name: "Protein King", detail: "30 straight days on protein target", earned: true, earnedDate: "Feb 2026"),
        Badge(name: "Sleep Well", detail: "7+ h sleep, 14 nights in a row", earned: false),
        Badge(name: "Iron Month", detail: "Train every day for a month", earned: false),
        Badge(name: "Before & After", detail: "Log a transformation comparison", earned: true, earnedDate: "Apr 2026"),
    ]

    static let missions: [Mission] = [
        Mission(name: "College Athlete Mission", detail: "Hit protein + 10K steps + train, 5 days this week", progress: 3, total: 5, xp: 400),
        Mission(name: "Strength Builder Mission", detail: "Add 5 lb to any main lift this week", progress: 1, total: 1, xp: 320),
        Mission(name: "Return From Injury Mission", detail: "Complete 6 knee rehab sessions", progress: 4, total: 6, xp: 350),
        Mission(name: "Summer Shred Mission", detail: "Log every meal for 7 days", progress: 5, total: 7, xp: 280),
        Mission(name: "Hybrid Athlete Mission", detail: "2 lifts + 2 conditioning sessions this week", progress: 3, total: 4, xp: 300),
    ]

    static let teams: [Team] = [
        Team(name: "Northgate U Hockey", kind: "School", members: 24, avgForgeScore: 74, compliancePct: 88, atRisk: 3, inRehab: 2, prsThisWeek: 5),
        Team(name: "Iron Works Barbell", kind: "Gym", members: 18, avgForgeScore: 81, compliancePct: 92, atRisk: 1, inRehab: 1, prsThisWeek: 4),
        Team(name: "Riverside Royals U-19", kind: "Sports Team", members: 22, avgForgeScore: 77, compliancePct: 90, atRisk: 2, inRehab: 2, prsThisWeek: 6),
        Team(name: "Vantage Software", kind: "Business", members: 134, avgForgeScore: 66, compliancePct: 71, atRisk: 18, inRehab: 6, prsThisWeek: 9),
    ]

    // MARK: - Marketplace

    static let coaches: [CoachListing] = [
        CoachListing(name: "Dr. Maya Hart", specialty: "Strength & Conditioning", credentials: "PhD, CSCS", rating: 4.9, clients: 142, price: "$220/mo", bio: "Former D1 head S&C. Hybrid and tactical athletes."),
        CoachListing(name: "Tomás Vega", specialty: "Powerlifting", credentials: "IPF Coach L3", rating: 4.95, clients: 88, price: "$280/mo", bio: "14 IPF qualifiers. Peaking and meet-day strategy."),
        CoachListing(name: "Lila Park, RD", specialty: "Nutrition", credentials: "RD, MS", rating: 4.92, clients: 210, price: "$160/mo", bio: "Recomp, performance fueling, contest prep."),
        CoachListing(name: "Dr. Ben Hayes", specialty: "Physical Therapy", credentials: "DPT, OCS", rating: 4.97, clients: 64, price: "$320/mo", bio: "Return-to-sport. Knee and shoulder specialist."),
        CoachListing(name: "Felicia Akande", specialty: "Running", credentials: "RRCA, USATF L1", rating: 4.88, clients: 178, price: "$180/mo", bio: "Marathon and ultra. HR-based training."),
        CoachListing(name: "Antoine Roux", specialty: "Hockey Performance", credentials: "CSCS, NHL S&C alum", rating: 4.93, clients: 56, price: "$340/mo", bio: "Skating power, off-ice strength, in-season management."),
    ]

    static let programs: [ProgramListing] = [
        ProgramListing(name: "Powerlifting Peak", coach: "Tomás Vega", level: "Advanced", price: "$89", weeks: 12, daysPerWeek: 4, focus: "S/B/D peak cycle", buyers: 1820),
        ProgramListing(name: "Marathon Sub-3:30", coach: "Felicia Akande", level: "Intermediate", price: "$69", weeks: 16, daysPerWeek: 5, focus: "Endurance + pace work", buyers: 2410),
        ProgramListing(name: "Body Recomp 8-Week", coach: "Lila Park, RD", level: "All", price: "$59", weeks: 8, daysPerWeek: 4, focus: "Partitioned hypertrophy + cut", buyers: 5640),
        ProgramListing(name: "Hockey Off-Season Power", coach: "Antoine Roux", level: "Advanced", price: "$129", weeks: 10, daysPerWeek: 5, focus: "Lateral power, top speed", buyers: 642),
        ProgramListing(name: "Daily Mobility Reset", coach: "Dr. Ben Hayes", level: "All", price: "$29", weeks: 6, daysPerWeek: 7, focus: "15 min/day full body", buyers: 8930),
        ProgramListing(name: "Return-to-Sport: Knee", coach: "Dr. Ben Hayes", level: "Rehab", price: "$99", weeks: 8, daysPerWeek: 4, focus: "Structured rehab → loading → return", buyers: 412),
    ]

    static let products: [StoreProduct] = [
        StoreProduct(name: "Whey Isolate 5 lb", brand: "Ascent", price: "$74", rating: 4.8, tag: "Best Value", icon: "takeoutbag.and.cup.and.straw.fill"),
        StoreProduct(name: "Creatine Mono 1 kg", brand: "BulkSupps", price: "$28", rating: 4.9, tag: "Forge Pick", icon: "aqi.medium"),
        StoreProduct(name: "Resistance Band Set", brand: "Forge Gear", price: "$48", rating: 4.7, icon: "figure.flexibility"),
        StoreProduct(name: "Adjustable Dumbbells", brand: "Bowflex", price: "$429", rating: 4.5, icon: "dumbbell.fill"),
        StoreProduct(name: "Electrolytes 30 ct", brand: "LMNT", price: "$45", rating: 4.85, icon: "drop.fill"),
        StoreProduct(name: "Mobility Tool Kit", brand: "TriggerPoint", price: "$58", rating: 4.7, icon: "circle.hexagongrid.fill"),
    ]

    // MARK: - Notifications

    static let notifications: [ForgeNotification] = [
        ForgeNotification(kind: .recommendation, title: "Increase bench to 185 today", body: "Last session: 180×5 @ RPE 8.5. Progression intact.", time: "8m", read: false),
        ForgeNotification(kind: .warning, title: "Magnesium low — day 6", body: "52% of target. 400 mg Mg-glycinate tonight.", time: "1h", read: false),
        ForgeNotification(kind: .progress, title: "Protein gap: 72 g by 9 PM", body: "One high-protein dinner closes it.", time: "2h", read: false),
        ForgeNotification(kind: .warning, title: "Sleep debt: 3.1 h this week", body: "Lights out 22:30 tonight for 8 h.", time: "4h", read: true),
        ForgeNotification(kind: .warning, title: "Injury risk: 22%", body: "Volume up 24% while knee is mid-rehab. Cap RPE 8.5.", time: "5h", read: true),
        ForgeNotification(kind: .recommendation, title: "PT session due: Knee rehab", body: "3 exercises · ~12 min. Day 4 of 6 this week.", time: "yesterday", read: true),
        ForgeNotification(kind: .streak, title: "23-day streak active", body: "Today's session is loaded. Don't break it.", time: "yesterday", read: true),
        ForgeNotification(kind: .progress, title: "Step goal complete: 10,420", body: "+2 Forge points for activity.", time: "2d", read: true),
        ForgeNotification(kind: .achievement, title: "PR: Deadlift 280×3", body: "+320 XP · est. 1RM now 308 lb.", time: "3d", read: true),
    ]
}
