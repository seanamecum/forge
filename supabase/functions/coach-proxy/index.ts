// Forge Coach Proxy — Supabase Edge Function (Deno).
//
// The production path for live AI coaching: clients (iOS + web) POST the same
// body they would send to the Claude Messages API; this function attaches the
// server-side ANTHROPIC_API_KEY and forwards it. The key never ships in an app
// binary or reaches a browser.
//
// Deploy:
//   supabase secrets set ANTHROPIC_API_KEY=sk-ant-...
//   supabase functions deploy coach-proxy
// iOS: set FORGE_COACH_PROXY_URL (scheme env) or CoachProxyURL (Secrets.plist)
//   to https://<project-ref>.functions.supabase.co/coach-proxy
//
// Hardening beyond this baseline (when accounts ship): verify the Supabase
// auth JWT, per-user rate limits, and per-user usage metering.

const ANTHROPIC_URL = "https://api.anthropic.com/v1/messages";
const ANTHROPIC_VERSION = "2023-06-01";

// Guardrails: the proxy only relays what the Forge coach actually needs.
const ALLOWED_MODELS = new Set([
  "claude-opus-4-8",
  "claude-sonnet-4-6",
  "claude-haiku-4-5",
]);
const MAX_TOKENS_CAP = 2048;
const MAX_BODY_BYTES = 64_000; // system prompt + 12-turn window fits comfortably

const CORS_HEADERS: Record<string, string> = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Access-Control-Allow-Headers": "content-type, anthropic-version, authorization, apikey",
};

function json(status: number, body: unknown): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "content-type": "application/json", ...CORS_HEADERS },
  });
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { status: 204, headers: CORS_HEADERS });
  }
  if (req.method !== "POST") {
    return json(405, { error: "POST only" });
  }

  const apiKey = Deno.env.get("ANTHROPIC_API_KEY");
  if (!apiKey) {
    return json(503, { error: "Coach proxy is not configured (missing ANTHROPIC_API_KEY secret)" });
  }

  const raw = await req.text();
  if (raw.length > MAX_BODY_BYTES) {
    return json(413, { error: "Request too large" });
  }

  let body: {
    model?: string;
    max_tokens?: number;
    system?: string;
    messages?: Array<{ role: string; content: string }>;
  };
  try {
    body = JSON.parse(raw);
  } catch {
    return json(400, { error: "Invalid JSON" });
  }

  if (!Array.isArray(body.messages) || body.messages.length === 0) {
    return json(400, { error: "messages[] is required" });
  }
  const model = body.model && ALLOWED_MODELS.has(body.model) ? body.model : "claude-opus-4-8";
  const maxTokens = Math.min(Math.max(1, body.max_tokens ?? 1024), MAX_TOKENS_CAP);

  const upstream = await fetch(ANTHROPIC_URL, {
    method: "POST",
    headers: {
      "x-api-key": apiKey,
      "anthropic-version": req.headers.get("anthropic-version") ?? ANTHROPIC_VERSION,
      "content-type": "application/json",
    },
    body: JSON.stringify({
      model,
      max_tokens: maxTokens,
      system: body.system ?? "",
      messages: body.messages,
    }),
  });

  // Relay the Anthropic response (success or error) verbatim — the iOS client
  // already treats any non-200 as "fall back to the offline mock".
  const text = await upstream.text();
  return new Response(text, {
    status: upstream.status,
    headers: { "content-type": "application/json", ...CORS_HEADERS },
  });
});
