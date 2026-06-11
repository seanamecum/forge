export type Notification = {
  id: string;
  kind: "progress" | "warning" | "recommendation" | "social" | "streak" | "achievement";
  title: string;
  body: string;
  time: string;
  read: boolean;
};

export const notifications: Notification[] = [
  { id: "n1", kind: "recommendation", title: "Today: increase bench weight to 120 kg", body: "Last session you closed 117.5×5 at RPE 9. Rate of progression is intact.", time: "8m", read: false },
  { id: "n2", kind: "warning", title: "Recovery low: 72 (-5)", body: "HRV dropped 8 ms. Volume cap recommended for today's lower session.", time: "21m", read: false },
  { id: "n3", kind: "progress", title: "Protein gap: 78 g remaining by 9pm", body: "On pace to hit target with one 300-cal high-protein meal.", time: "1h", read: false },
  { id: "n4", kind: "warning", title: "Magnesium intake at 44% of target", body: "Below threshold for 4 days. Consider 400 mg Mg-glycinate tonight.", time: "2h", read: true },
  { id: "n5", kind: "warning", title: "Sleep debt: 4h 20m this week", body: "Cumulative deficit detected. Aim for 8h tonight.", time: "5h", read: true },
  { id: "n6", kind: "warning", title: "Injury risk elevated: 28%", body: "ACR is at 1.38 (volume up 38%) while HRV is down 12%.", time: "5h", read: true },
  { id: "n7", kind: "recommendation", title: "PT session due: Right Shoulder rehab", body: "3 exercises queued. ~12 min.", time: "yesterday", read: true },
  { id: "n8", kind: "streak", title: "🔥 47-day streak active", body: "Don't break it — today's session is ready.", time: "yesterday", read: true },
  { id: "n9", kind: "progress", title: "Step goal complete: 10,824", body: "Crushed it. +2% movement bonus to Forge Score.", time: "2d", read: true },
  { id: "n10", kind: "achievement", title: "PR logged: Back Squat 175 kg", body: "+340 XP. New 1RM estimate: 182 kg.", time: "5d", read: true },
];
