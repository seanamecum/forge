export type WearableDevice = {
  id: string;
  name: string;
  brand: string;
  icon: string; // emoji-ish glyph for the prototype
  connected: boolean;
  lastSync: string | null;
  permissions: string[];
  metrics: string[];
  battery?: number;
};

export const wearables: WearableDevice[] = [
  {
    id: "apple-watch",
    name: "Apple Watch Ultra 3",
    brand: "Apple",
    icon: "◉",
    connected: true,
    lastSync: "2 minutes ago",
    permissions: ["Heart Rate", "ECG", "Workouts", "Sleep", "Steps", "Calories", "VO₂ Max"],
    metrics: ["heart_rate", "steps", "calories", "workouts", "sleep", "vo2max"],
    battery: 78,
  },
  {
    id: "whoop",
    name: "WHOOP 5.0",
    brand: "WHOOP",
    icon: "◐",
    connected: true,
    lastSync: "5 minutes ago",
    permissions: ["HRV", "RHR", "Sleep stages", "Recovery", "Strain", "Respiratory rate"],
    metrics: ["hrv", "rhr", "sleep_stages", "recovery", "strain", "respiratory_rate"],
    battery: 64,
  },
  {
    id: "oura",
    name: "Oura Ring Gen 4",
    brand: "Oura",
    icon: "○",
    connected: false,
    lastSync: null,
    permissions: ["HRV", "Sleep stages", "Temperature", "Readiness"],
    metrics: ["hrv", "sleep_stages", "skin_temp", "readiness"],
  },
  {
    id: "garmin",
    name: "Garmin Fenix 8",
    brand: "Garmin",
    icon: "◎",
    connected: false,
    lastSync: null,
    permissions: ["GPS", "Running power", "VO₂ max", "Recovery time"],
    metrics: ["gps", "running_power", "vo2max", "recovery_time"],
  },
  {
    id: "fitbit",
    name: "Fitbit Charge 7",
    brand: "Fitbit",
    icon: "◑",
    connected: false,
    lastSync: null,
    permissions: ["Heart rate", "Sleep", "Steps"],
    metrics: ["heart_rate", "sleep", "steps"],
  },
  {
    id: "polar",
    name: "Polar H10 Strap",
    brand: "Polar",
    icon: "◓",
    connected: false,
    lastSync: null,
    permissions: ["Live HR", "HRV training"],
    metrics: ["live_hr", "hrv"],
  },
  {
    id: "smart-scale",
    name: "Withings Body Scan",
    brand: "Withings",
    icon: "◧",
    connected: true,
    lastSync: "this morning",
    permissions: ["Weight", "Body composition", "Heart rate"],
    metrics: ["weight", "body_fat", "lean_mass", "visceral_fat", "bone_mass"],
    battery: 92,
  },
];

// Live-ish snapshot
export const wearableSnapshot = {
  hr: 58,
  hrv: 64,
  vo2max: 52,
  respiratoryRate: 14.2,
  bodyTempDelta: -0.1,
  spo2: 98,
  strainToday: 9.4,
  strainTarget: 14.0,
};
