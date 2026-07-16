// Feedback → Supabase `feedback` table (insert-only for clients via RLS;
// readable only from the dashboard). Mirrors the iOS FeedbackClient.

const SUPABASE_URL = "https://vxprqlniecdcxjkevoob.supabase.co";
const ANON_KEY = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY ?? "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZ4cHJxbG5pZWNkY3hqa2V2b29iIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODM3MzY4NjEsImV4cCI6MjA5OTMxMjg2MX0.YAa5hW56xq3zZm8_LrBOFexkwXPVl2k-kA_jtxRRSwI";

/** Pure request builder — unit-tested. */
export function buildFeedbackRequest(message: string, email: string | null) {
  return {
    url: `${SUPABASE_URL}/rest/v1/feedback`,
    init: {
      method: "POST" as const,
      headers: {
        apikey: ANON_KEY,
        Authorization: `Bearer ${ANON_KEY}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        source: "web",
        email: email || null,
        message,
        context: { page: typeof window !== "undefined" ? window.location.pathname : "ssr" },
      }),
    },
  };
}

export async function submitFeedback(message: string, email: string | null): Promise<boolean> {
  const { url, init } = buildFeedbackRequest(message, email);
  try {
    const res = await fetch(url, init);
    return res.ok;
  } catch {
    return false;
  }
}
