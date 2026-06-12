"use client";

// App-wide interactive state. Mock data stays the read-model; this layer holds
// every mutation the UI makes (logs, toggles, joins) and persists to localStorage.

import {
  createContext,
  useContext,
  useEffect,
  useState,
  type ReactNode,
} from "react";

export type LoggedMeal = {
  meal: string;
  name: string;
  calories: number;
  protein: number;
  time: string;
};

export type AddedInjury = { id: string; area: string; name: string };

export type FinishedSession = {
  name: string;
  date: string;
  durationMin: number;
  volumeKg: number;
  sets: number;
};

export type UserPost = { body: string; time: string };

type ForgeState = {
  waterMl: number;
  meals: LoggedMeal[];
  supps: Record<string, boolean>;
  likes: Record<string, boolean>;
  joinedChallenges: Record<string, boolean>;
  connected: Record<string, boolean>;
  notifsRead: boolean;
  rts: Record<number, boolean>;
  painToday: number;
  rehabDoneToday: boolean;
  addedInjuries: AddedInjury[];
  sessions: FinishedSession[];
  posts: UserPost[];
  xpBonus: number;
};

const DEFAULTS: ForgeState = {
  waterMl: 2100,
  meals: [],
  supps: {},
  likes: {},
  joinedChallenges: {},
  connected: {},
  notifsRead: false,
  rts: { 0: true, 1: true },
  painToday: 3,
  rehabDoneToday: false,
  addedInjuries: [],
  sessions: [],
  posts: [],
  xpBonus: 0,
};

type Store = ForgeState & {
  set: <K extends keyof ForgeState>(key: K, value: ForgeState[K]) => void;
  addWater: (ml: number) => void;
  addMeal: (m: LoggedMeal) => void;
  toggleSupp: (id: string, base: boolean) => void;
  suppLogged: (id: string, base: boolean) => boolean;
  toggleLike: (id: string) => void;
  toggleChallenge: (id: string) => void;
  toggleConnected: (id: string, base: boolean) => void;
  isConnected: (id: string, base: boolean) => boolean;
  toggleRts: (i: number) => void;
  addInjury: (area: string) => void;
  addSession: (s: FinishedSession) => void;
  addPost: (body: string) => void;
  addXp: (n: number) => void;
};

const Ctx = createContext<Store | null>(null);

export function ForgeProvider({ children }: { children: ReactNode }) {
  const [state, setState] = useState<ForgeState>(DEFAULTS);
  const [loaded, setLoaded] = useState(false);

  useEffect(() => {
    try {
      const raw = localStorage.getItem("forge-state");
      if (raw) setState({ ...DEFAULTS, ...JSON.parse(raw) });
    } catch {}
    setLoaded(true);
  }, []);

  useEffect(() => {
    if (loaded) localStorage.setItem("forge-state", JSON.stringify(state));
  }, [state, loaded]);

  const set: Store["set"] = (key, value) =>
    setState((s) => ({ ...s, [key]: value }));

  const store: Store = {
    ...state,
    set,
    addWater: (ml) => set("waterMl", Math.min(5500, state.waterMl + ml)),
    addMeal: (m) => set("meals", [...state.meals, m]),
    toggleSupp: (id, base) =>
      set("supps", { ...state.supps, [id]: !(state.supps[id] ?? base) }),
    suppLogged: (id, base) => state.supps[id] ?? base,
    toggleLike: (id) => set("likes", { ...state.likes, [id]: !state.likes[id] }),
    toggleChallenge: (id) =>
      set("joinedChallenges", {
        ...state.joinedChallenges,
        [id]: !state.joinedChallenges[id],
      }),
    toggleConnected: (id, base) =>
      set("connected", { ...state.connected, [id]: !(state.connected[id] ?? base) }),
    isConnected: (id, base) => state.connected[id] ?? base,
    toggleRts: (i) => set("rts", { ...state.rts, [i]: !state.rts[i] }),
    addInjury: (area) =>
      set("addedInjuries", [
        ...state.addedInjuries,
        { id: `add-${Date.now()}`, area, name: `${area} — monitoring` },
      ]),
    addSession: (s) => set("sessions", [s, ...state.sessions]),
    addPost: (body) => set("posts", [{ body, time: "now" }, ...state.posts]),
    addXp: (n) => set("xpBonus", state.xpBonus + n),
  };

  return <Ctx.Provider value={store}>{children}</Ctx.Provider>;
}

export function useForge(): Store {
  const ctx = useContext(Ctx);
  if (!ctx) throw new Error("useForge must be used inside <ForgeProvider>");
  return ctx;
}
