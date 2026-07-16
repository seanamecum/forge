// Real authentication against Forge's Supabase backend (GoTrue REST).
// The anon key is public by design — row-level security is the protection.
// Mirrors the iOS AuthService so both clients share one account system.

const SUPABASE_URL = "https://vxprqlniecdcxjkevoob.supabase.co";
const ANON_KEY = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY ?? "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZ4cHJxbG5pZWNkY3hqa2V2b29iIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODM3MzY4NjEsImV4cCI6MjA5OTMxMjg2MX0.YAa5hW56xq3zZm8_LrBOFexkwXPVl2k-kA_jtxRRSwI";

const SESSION_KEY = "forge.web.session.v1";

export interface Session {
  accessToken: string;
  refreshToken: string;
  email: string;
  expiresAt: number; // unix seconds
}

/** Pure request builder — unit-tested. */
export function buildAuthRequest(path: string, body: Record<string, unknown>) {
  return {
    url: `${SUPABASE_URL}/auth/v1/${path}`,
    init: {
      method: "POST" as const,
      headers: {
        apikey: ANON_KEY,
        "Content-Type": "application/json",
      },
      body: JSON.stringify(body),
    },
  };
}

/** Map a GoTrue token payload to our session shape (null if no session). */
export function sessionFromPayload(
  payload: Record<string, unknown> | null | undefined,
  fallbackEmail: string,
): Session | null {
  if (!payload || typeof payload.access_token !== "string") return null;
  const user = payload.user as { email?: string } | undefined;
  return {
    accessToken: payload.access_token,
    refreshToken: typeof payload.refresh_token === "string" ? payload.refresh_token : "",
    email: user?.email ?? fallbackEmail,
    expiresAt:
      typeof payload.expires_at === "number"
        ? payload.expires_at
        : Math.floor(Date.now() / 1000) + 3600,
  };
}

async function post(path: string, body: Record<string, unknown>) {
  const { url, init } = buildAuthRequest(path, body);
  const res = await fetch(url, init);
  const json = (await res.json().catch(() => ({}))) as Record<string, unknown>;
  return { ok: res.ok, json };
}

export type AuthResult =
  | { ok: true; session: Session }
  | { ok: true; notice: string }
  | { ok: false; error: string };

function errorMessage(json: Record<string, unknown>, fallback: string): string {
  const msg = json.msg ?? json.message ?? json.error_description ?? json.error;
  return typeof msg === "string" ? msg : fallback;
}

export async function signUp(email: string, password: string, name: string): Promise<AuthResult> {
  const { ok, json } = await post("signup", {
    email,
    password,
    data: { name },
  });
  if (!ok) return { ok: false, error: errorMessage(json, "Could not create the account.") };
  const session = sessionFromPayload(json, email);
  if (session) {
    saveSession(session);
    return { ok: true, session };
  }
  // Email confirmation is on — a user record exists but no session yet.
  return { ok: true, notice: "Account created — check your email to confirm, then sign in." };
}

export async function signIn(email: string, password: string): Promise<AuthResult> {
  const { ok, json } = await post("token?grant_type=password", { email, password });
  if (!ok) return { ok: false, error: errorMessage(json, "Check your email and password.") };
  const session = sessionFromPayload(json, email);
  if (!session) return { ok: false, error: "Unexpected response — try again." };
  saveSession(session);
  return { ok: true, session };
}

export async function sendReset(email: string): Promise<AuthResult> {
  const { ok, json } = await post("recover", { email });
  if (!ok) return { ok: false, error: errorMessage(json, "Could not send the reset email.") };
  return { ok: true, notice: "Reset link sent — check your inbox." };
}

// MARK: session storage (browser only)

export function saveSession(session: Session) {
  if (typeof window !== "undefined") {
    window.localStorage.setItem(SESSION_KEY, JSON.stringify(session));
  }
}

export function loadSession(): Session | null {
  if (typeof window === "undefined") return null;
  try {
    const raw = window.localStorage.getItem(SESSION_KEY);
    if (!raw) return null;
    const s = JSON.parse(raw) as Session;
    return s.expiresAt > Date.now() / 1000 ? s : null;
  } catch {
    return null;
  }
}

export function signOut() {
  if (typeof window !== "undefined") {
    window.localStorage.removeItem(SESSION_KEY);
  }
}
