# Forge Marketing Site — Production Deployment Checklist

A step-by-step runbook for taking the Forge waitlist/beta site live on **Vercel** with
**Supabase** as the datastore. Nothing here is committed or deployed automatically.

---

## 1. Supabase (datastore)

- [ ] Create the Supabase project (Settings → strong DB password saved to a password manager).
- [ ] Run `supabase/migrations/0004_marketing.sql` in the SQL Editor.
- [ ] Confirm both tables exist in Table Editor: `waitlist_signups`, `beta_applications`.
- [ ] Confirm RLS is **enabled** on both (Table Editor → table → RLS badge = on).
- [ ] Copy from Settings → API: **Project URL** and **`service_role`** key.
- [ ] (Optional) Restrict the service role to your Vercel egress only if you use Supabase network restrictions.

## 2. Environment variables (set in Vercel → Project → Settings → Environment Variables)

Set for the **Production** (and Preview, if you want live previews) environment:

| Variable | Required | Value | Notes |
|---|---|---|---|
| `SUPABASE_URL` | ✅ | `https://<ref>.supabase.co` | Server-only |
| `SUPABASE_SERVICE_ROLE_KEY` | ✅ | `service_role` key | **Server-only. Never** prefix with `NEXT_PUBLIC_`. |
| `NEXT_PUBLIC_APP_URL` | ✅ | `https://yourdomain.com` | Drives canonical + OG URLs, robots, sitemap |
| `NEXT_PUBLIC_GA_ID` | optional | `G-XXXXXXXXXX` | Enables GA4 when set |
| `NEXT_PUBLIC_META_PIXEL_ID` | optional | Pixel ID | Enables Meta Pixel when set |
| `NEXT_PUBLIC_TIKTOK_PIXEL_ID` | optional | Pixel ID | Enables TikTok Pixel when set |

- [ ] All required vars set for Production.
- [ ] `SUPABASE_SERVICE_ROLE_KEY` is **not** exposed as a `NEXT_PUBLIC_` var (double-check the name).
- [ ] `.env.local` is gitignored (it is) and never committed.

## 3. Vercel project

- [ ] Import the Git repo into Vercel. Framework preset auto-detects **Next.js** — no `vercel.json` needed.
- [ ] Build command `next build`, output handled by Vercel automatically.
- [ ] Node version: repo pins **20+** via `.nvmrc` (`22`) and `engines.node`.
- [ ] Add your custom domain (Settings → Domains) and complete DNS.
- [ ] Verify HTTPS + `Strict-Transport-Security` header is served (set in `next.config.js`).

## 4. Pre-launch verification (run locally against a staging Supabase first)

- [ ] `npm run lint` — clean
- [ ] `npm run typecheck` — clean
- [ ] `npm run build` — succeeds
- [ ] Submit a real waitlist entry → row appears in `waitlist_signups` with correct `submitted_at`, `referral`, `marketing_consent`.
- [ ] Submit a real beta application → row appears in `beta_applications` with `current_apps[]`, `agrees_to_feedback = true`.
- [ ] Duplicate email → still returns success (unique index dedup, no error shown to user).
- [ ] Invalid email / missing name → inline validation error, no network call succeeds.
- [ ] Honeypot filled (bot) → fake success, **no** DB row created.
- [ ] Rapid repeat submits from one IP → `429 Too many attempts` after the limit.
- [ ] `/robots.txt` and `/sitemap.xml` resolve and reference the production domain.
- [ ] OG image renders at `/opengraph-image` (paste your URL into a link-preview debugger).
- [ ] Favicon shows in the browser tab.
- [ ] Lighthouse pass on mobile (perf/SEO/accessibility) — homepage first-load JS is ~102 kB.

## 5. Analytics & attribution (when running ads)

- [ ] GA4 property created, `NEXT_PUBLIC_GA_ID` set, `waitlist_submitted` / `beta_application_submitted` events firing.
- [ ] Meta Pixel + TikTok Pixel set if advertising there; verify `Lead` / `CompleteRegistration` events.
- [ ] Test a `?utm_source=...&utm_campaign=...&ref=CODE` link → values land in the row's `referral` JSON.

## 6. Data & privacy

- [ ] Privacy policy + terms reviewed (routes `/privacy`, `/terms` exist).
- [ ] Marketing-consent checkbox wording matches your email/ESP double-opt-in policy.
- [ ] Decide how you'll read/export signups (Supabase Table Editor, a SQL view, or an admin tool). Reads require the service role — no public read policy exists by design.
- [ ] Plan a confirmation email (e.g. Resend/Postmark) — not included; hook it into the API routes after insert.

## 7. Go-live

- [ ] Merge to the production branch (only after your review — this repo never auto-commits).
- [ ] Confirm the production deployment is green in Vercel.
- [ ] Smoke-test the live domain end-to-end (one waitlist + one beta submit).
- [ ] Announce 🚀

---

### Post-launch hardening (recommended, not blocking)

- Swap the in-memory rate limiter (`src/lib/marketing/rate-limit.ts`) for **Vercel KV / Upstash Redis** for
  globally-consistent limits (serverless memory is per-instance). The `rateLimit()` signature is unchanged —
  replace the `Map` with a Redis `INCR` + `EXPIRE`.
- Add an admin SELECT policy or a Supabase view for reviewing signups.
- Add email confirmation + an ESP sync on successful insert.
