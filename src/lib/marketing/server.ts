// @forge/marketing — SERVER ONLY. Never import from a client component.
//
// Inserts a marketing submission into Supabase via PostgREST using a server-side
// secret key. When the env isn't configured, it degrades to a mock: the row is
// logged and { ok, mock:true } is returned so local dev needs no backend.
//
// To go live, set:
//   SUPABASE_URL         (or NEXT_PUBLIC_SUPABASE_URL)
//   SUPABASE_SECRET_KEY  — the new Supabase Secret key (sb_secret_…), preferred.
//                          Falls back to the legacy SUPABASE_SERVICE_ROLE_KEY.
// then run supabase/migrations/0004_marketing.sql.
//
// Both key formats are full-access, RLS-bypassing SERVER keys and are used
// identically by PostgREST (apikey + Bearer). This module is imported only by
// route handlers (src/app/api/**), which always execute on the server — so the
// secret key is never bundled to the client. Neither var is NEXT_PUBLIC_*.

import type { SubmissionResult } from "./types";

const SUPABASE_URL =
  process.env.SUPABASE_URL || process.env.NEXT_PUBLIC_SUPABASE_URL || "";
// Prefer the new Secret key; fall back to the legacy service_role key.
const SECRET_KEY =
  process.env.SUPABASE_SECRET_KEY || process.env.SUPABASE_SERVICE_ROLE_KEY || "";

export const backendConfigured = !!SUPABASE_URL && !!SECRET_KEY;

/**
 * Insert one row into a marketing table. `row` must already be validated and
 * shaped to the table's columns.
 */
export async function insertRow(
  table: "waitlist_signups" | "beta_applications",
  row: Record<string, unknown>,
): Promise<SubmissionResult> {
  const payload = { ...row, submitted_at: new Date().toISOString() };

  if (!backendConfigured) {
    // Mock mode — surface the row so it's verifiable without a database.
    // eslint-disable-next-line no-console
    console.info(`[marketing:mock] would insert into ${table}:`, payload);
    return { ok: true, mock: true };
  }

  try {
    const res = await fetch(`${SUPABASE_URL}/rest/v1/${table}`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        apikey: SECRET_KEY,
        Authorization: `Bearer ${SECRET_KEY}`,
        Prefer: "return=minimal",
      },
      body: JSON.stringify(payload),
    });

    if (!res.ok) {
      const detail = await res.text().catch(() => "");
      // eslint-disable-next-line no-console
      console.error(`[marketing] insert into ${table} failed (${res.status}):`, detail);
      // 23505 = unique_violation → the email is already on the list. Treat as success.
      if (res.status === 409 || detail.includes("23505")) return { ok: true };
      return { ok: false, error: "We couldn't save your submission. Please try again." };
    }
    return { ok: true };
  } catch (err) {
    // eslint-disable-next-line no-console
    console.error(`[marketing] insert into ${table} threw:`, err);
    return { ok: false, error: "We couldn't reach the server. Please try again." };
  }
}
