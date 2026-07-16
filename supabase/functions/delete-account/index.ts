// Self-service account deletion (App Store guideline 5.1.1(v)).
// Deployed WITH JWT verification: only a signed-in user's token reaches this
// code, and the account deleted is always the caller's own (from the JWT sub —
// never from the request body). The service-role key exists only server-side.

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });
  if (req.method !== "POST") {
    return new Response(JSON.stringify({ error: "POST only" }), { status: 405, headers: cors });
  }

  const auth = req.headers.get("authorization") ?? "";
  const jwt = auth.replace(/^Bearer\s+/i, "");
  const payloadPart = jwt.split(".")[1];
  if (!payloadPart) {
    return new Response(JSON.stringify({ error: "Missing token" }), { status: 401, headers: cors });
  }

  let sub: string | undefined;
  try {
    const payload = JSON.parse(atob(payloadPart.replace(/-/g, "+").replace(/_/g, "/")));
    sub = typeof payload.sub === "string" ? payload.sub : undefined;
  } catch {
    /* fall through */
  }
  if (!sub) {
    return new Response(JSON.stringify({ error: "Invalid token" }), { status: 401, headers: cors });
  }

  const url = Deno.env.get("SUPABASE_URL")!;
  const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
  const res = await fetch(`${url}/auth/v1/admin/users/${sub}`, {
    method: "DELETE",
    headers: { apikey: serviceKey, Authorization: `Bearer ${serviceKey}` },
  });

  if (!res.ok && res.status !== 404) {
    return new Response(JSON.stringify({ error: "Deletion failed" }), { status: 500, headers: cors });
  }
  return new Response(JSON.stringify({ deleted: true }), {
    status: 200,
    headers: { ...cors, "Content-Type": "application/json" },
  });
});
