export const coaches = [
  { id: "c1", name: "Dr. Maya Hart", specialty: "Strength & Conditioning", credentials: "PhD, CSCS", rating: 4.9, clients: 142, price: "$220/mo", bio: "Former D1 head S&C. Specializes in hybrid athletes and tactical." },
  { id: "c2", name: "Tomás Vega", specialty: "Powerlifting", credentials: "IPF Coach L3", rating: 4.95, clients: 88, price: "$280/mo", bio: "Coached 14 IPF qualifiers. Peaking and meet-day strategy." },
  { id: "c3", name: "Coach Lila Park", specialty: "Nutrition", credentials: "RD, MS", rating: 4.92, clients: 210, price: "$160/mo", bio: "Body recomp, performance fueling, contest prep." },
  { id: "c4", name: "Dr. Ben Hayes", specialty: "Physical Therapist", credentials: "DPT, OCS", rating: 4.97, clients: 64, price: "$320/mo", bio: "Return-to-sport, shoulder + knee specialist." },
  { id: "c5", name: "Felicia Akande", specialty: "Running", credentials: "RRCA, USATF L1", rating: 4.88, clients: 178, price: "$180/mo", bio: "Marathon and ultra. Heart-rate based training." },
  { id: "c6", name: "Coach Antoine Roux", specialty: "Hockey Performance", credentials: "CSCS, NHL S&C alum", rating: 4.93, clients: 56, price: "$340/mo", bio: "Skating power, off-ice strength, in-season maintenance." },
];

export const programs = [
  { id: "p1", name: "Powerlifting Peak — 12 Weeks", coach: "Tomás Vega", level: "Advanced", price: "$89", weeks: 12, dpw: 4, focus: "Squat/Bench/Deadlift peak", buyers: 1820 },
  { id: "p2", name: "Marathon Sub-3:30", coach: "Felicia Akande", level: "Intermediate", price: "$69", weeks: 16, dpw: 5, focus: "Endurance + pace work", buyers: 2410 },
  { id: "p3", name: "Body Recomp 8-Week", coach: "Coach Lila Park", level: "All", price: "$59", weeks: 8, dpw: 4, focus: "Calorie partitioning, hypertrophy + cut", buyers: 5640 },
  { id: "p4", name: "Hockey Off-Season Power", coach: "Coach Antoine Roux", level: "Advanced", price: "$129", weeks: 10, dpw: 5, focus: "Lateral power, top-end speed", buyers: 642 },
  { id: "p5", name: "Daily Mobility Reset", coach: "Dr. Ben Hayes", level: "All", price: "$29", weeks: 6, dpw: 7, focus: "15 min/day full-body", buyers: 8930 },
  { id: "p6", name: "Return-to-Sport After Shoulder", coach: "Dr. Ben Hayes", level: "Rehab", price: "$99", weeks: 8, dpw: 4, focus: "Structured rehab → loading → return", buyers: 412 },
];

export const products = [
  { id: "x1", name: "Whey Isolate — 5lb Tub", brand: "Ascent", price: "$74", rating: 4.8, tag: "Best Value" },
  { id: "x2", name: "Creatine Monohydrate — 1kg", brand: "Bulk Supps", price: "$28", rating: 4.9, tag: "Forge Pick" },
  { id: "x3", name: "Resistance Bands Set", brand: "Forge Gear", price: "$48", rating: 4.7 },
  { id: "x4", name: "Adjustable Dumbbells 5–55 lb", brand: "Bowflex", price: "$429", rating: 4.5 },
  { id: "x5", name: "Electrolyte Sticks — 30ct", brand: "LMNT", price: "$45", rating: 4.85 },
  { id: "x6", name: "Mobility Lacrosse Ball + Roller Kit", brand: "TriggerPoint", price: "$58", rating: 4.7 },
  { id: "x7", name: "Fish Oil EPA/DHA — 90ct", brand: "Nordic Naturals", price: "$38", rating: 4.86 },
  { id: "x8", name: "Magnesium Glycinate — 240ct", brand: "Pure Encaps", price: "$32", rating: 4.85 },
];

export const teams = [
  { id: "t1", name: "Westview High Hockey", type: "School", members: 24, avgForge: 74, compliance: 88 },
  { id: "t2", name: "Iron Forge Powerlifting", type: "Gym", members: 18, avgForge: 81, compliance: 92 },
  { id: "t3", name: "Northstars U-19", type: "Sports Team", members: 22, avgForge: 78, compliance: 90 },
  { id: "t4", name: "Acme Software Inc.", type: "Business", members: 142, avgForge: 67, compliance: 71 },
];
