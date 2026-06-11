export type FeedPost = {
  id: string;
  user: { name: string; handle: string; level: number };
  time: string;
  kind: "pr" | "workout" | "progress" | "milestone" | "share";
  body: string;
  stat?: { label: string; value: string };
  likes: number;
  comments: number;
};

export const feed: FeedPost[] = [
  {
    id: "p1",
    user: { name: "Jordan Reyes", handle: "@jrey", level: 31 },
    time: "12m",
    kind: "pr",
    body: "Five years of grinding. Two plates moves.",
    stat: { label: "Bench Press", value: "102.5 kg × 3" },
    likes: 84,
    comments: 12,
  },
  {
    id: "p2",
    user: { name: "Sasha Lin", handle: "@sashlin", level: 19 },
    time: "37m",
    kind: "workout",
    body: "Hill repeats. Lungs cooked.",
    stat: { label: "Strain", value: "19.4 · 64 min" },
    likes: 41,
    comments: 6,
  },
  {
    id: "p3",
    user: { name: "Coach Will", handle: "@cwill", level: 48 },
    time: "1h",
    kind: "share",
    body:
      "If your training feels random, you don't have a program — you have a hobby. Pick three lifts, beat last week's numbers, sleep. The rest is noise.",
    likes: 312,
    comments: 47,
  },
  {
    id: "p4",
    user: { name: "Mia Tanaka", handle: "@miatk", level: 22 },
    time: "2h",
    kind: "progress",
    body: "8-week recomp progress. Same scale weight — different signal.",
    stat: { label: "Body Fat", value: "−4.1% · LM +1.8 kg" },
    likes: 167,
    comments: 22,
  },
  {
    id: "p5",
    user: { name: "Marcus Vale", handle: "@mvale", level: 24 },
    time: "yesterday",
    kind: "pr",
    body: "Pause squat single. Took the cue — drove the floor away.",
    stat: { label: "Back Squat", value: "175 kg · 1RM est. 182" },
    likes: 58,
    comments: 9,
  },
  {
    id: "p6",
    user: { name: "Devon Park", handle: "@dpark", level: 14 },
    time: "yesterday",
    kind: "milestone",
    body: "47 days. First time I've kept a streak past a month. The dashboard helps.",
    stat: { label: "Forge Streak", value: "🔥 47 days" },
    likes: 92,
    comments: 18,
  },
];

export const groups = [
  { id: "g1", name: "Hockey Athletes", members: 14820, tag: "Sport", description: "Off-season strength, in-season maintenance." },
  { id: "g2", name: "Powerlifting Club", members: 28430, tag: "Strength", description: "Squat, bench, deadlift. Meets and meet prep." },
  { id: "g3", name: "Running Collective", members: 41200, tag: "Endurance", description: "5K to ultra." },
  { id: "g4", name: "Bodybuilding", members: 35610, tag: "Aesthetic", description: "Hypertrophy, contest prep, photo journals." },
  { id: "g5", name: "Hybrid Athletes", members: 18900, tag: "Hybrid", description: "Strength + endurance. Murph crews welcome." },
  { id: "g6", name: "College Athletes", members: 9450, tag: "Performance", description: "NCAA, club, intramural." },
];

export const leaderboards = {
  steps: [
    { rank: 1, name: "Ana K.", value: "+96,420" },
    { rank: 2, name: "Devon P.", value: "+91,810" },
    { rank: 3, name: "Marcus V.", value: "+88,440", highlight: true },
    { rank: 4, name: "Jordan R.", value: "+85,200" },
    { rank: 5, name: "Mia T.", value: "+82,140" },
  ],
  strength: [
    { rank: 1, name: "Jordan R.", value: "Wilks 442" },
    { rank: 2, name: "Coach Will", value: "Wilks 438" },
    { rank: 3, name: "Marcus V.", value: "Wilks 401", highlight: true },
    { rank: 4, name: "Vlad S.", value: "Wilks 388" },
    { rank: 5, name: "Sasha L.", value: "Wilks 372" },
  ],
  streak: [
    { rank: 1, name: "Coach Will", value: "412 d" },
    { rank: 2, name: "Mia T.", value: "188 d" },
    { rank: 3, name: "Jordan R.", value: "97 d" },
    { rank: 4, name: "Marcus V.", value: "47 d", highlight: true },
    { rank: 5, name: "Devon P.", value: "44 d" },
  ],
  protein: [
    { rank: 1, name: "Mia T.", value: "98% hit" },
    { rank: 2, name: "Marcus V.", value: "94% hit", highlight: true },
    { rank: 3, name: "Sasha L.", value: "91% hit" },
    { rank: 4, name: "Jordan R.", value: "89% hit" },
    { rank: 5, name: "Devon P.", value: "84% hit" },
  ],
};

export const challenges = [
  { id: "c1", name: "30-Day Protein Challenge", participants: 4280, daysLeft: 22, status: "active", reward: "Iron Month badge" },
  { id: "c2", name: "100-Mile Month", participants: 2110, daysLeft: 22, status: "active", reward: "Endurance badge" },
  { id: "c3", name: "10K Steps Daily", participants: 11800, daysLeft: 22, status: "active", reward: "Movement Streak" },
  { id: "c4", name: "Bench Press Challenge — 1.5× BW", participants: 3210, daysLeft: 90, status: "active", reward: "1000-lb Club credit" },
  { id: "c5", name: "Summer Shred — 6 weeks", participants: 8430, daysLeft: 41, status: "active", reward: "Cut Badge" },
  { id: "c6", name: "Hockey Off-Season Challenge", participants: 1420, daysLeft: 60, status: "active", reward: "Ice Ready" },
];

export const badges = [
  { name: "First Rep", earned: true, when: "2024-08-12", desc: "Logged your first set." },
  { name: "7-Day Streak", earned: true, when: "2024-08-19", desc: "Seven consecutive training days." },
  { name: "One Plate Bench", earned: true, when: "2024-11-04", desc: "Bench 100 kg or 225 lb for a single." },
  { name: "Two Plate Bench", earned: false, desc: "Bench 140 kg or 315 lb for a single. 6.5 kg to go." },
  { name: "100 Workouts", earned: true, when: "2025-04-22", desc: "100 sessions logged." },
  { name: "1000 lb Club", earned: true, when: "2026-04-22", desc: "Squat + Bench + Deadlift > 1000 lb." },
  { name: "Marathon", earned: false, desc: "Complete a 42.2 km run." },
  { name: "Protein King", earned: true, when: "2025-12-30", desc: "Hit protein target 30 days in a row." },
  { name: "Sleep Well", earned: true, when: "2026-01-12", desc: "7+ hours sleep, 14 nights in a row." },
  { name: "Iron Month", earned: false, desc: "Train every day for a calendar month." },
  { name: "Before & After", earned: true, when: "2025-06-15", desc: "Logged a transformation comparison." },
];

export const missions = [
  { name: "Hit protein 5 days this week", progress: 4, total: 5, xp: 240 },
  { name: "Complete a Z2 cardio session", progress: 0, total: 1, xp: 120 },
  { name: "Bench press above 117.5 kg", progress: 1, total: 1, xp: 320, done: true },
  { name: "Log all supplements daily x7", progress: 5, total: 7, xp: 200 },
  { name: "Mobility session 3×", progress: 1, total: 3, xp: 180 },
];
