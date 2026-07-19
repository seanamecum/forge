# Forge — Supabase RLS Verification

Run this **after** `0002_rls_hardening.sql` is confirmed applied (see "Migration status" below).
The fastest honest test is to probe the live PostgREST API as an anonymous attacker would — no
dashboard needed. Load the **anon** (publishable) key + project URL; never use the service-role key here.

```bash
URL="https://<ref>.supabase.co"      # from ios/.../SupabaseConfig.swift
ANON="<anon publishable key>"        # public by design
h=(-H "apikey: $ANON" -H "Authorization: Bearer $ANON")
```

## Migration status (check first)
```bash
supabase migration list          # 0002 must appear in BOTH Local and Remote columns
supabase db push --dry-run       # must say "Remote database is up to date" (nothing pending)
```

## A. Anonymous (unauthenticated) — must be denied everywhere sensitive
| Check | Command | Expected once secured |
|---|---|---|
| challenge_members not world-readable | `curl -s -o/dev/null -w "%{http_code}" "$URL/rest/v1/challenge_members?select=*" "${h[@]}"` | `200 []` (RLS filters all) — never rows |
| challenge_members not world-writable | `POST …/challenge_members` with a body | `401/403` RLS violation — never `201` |
| subscriptions not readable by anon | `GET …/subscriptions` | `200 []` / denied |
| feedback insert-only: anon cannot read | `GET …/feedback?select=*` | `200 []` (no rows leak; submitter emails private) |
| feedback accepts an insert | `POST …/feedback {"message":"probe"}` | `201` |
| profiles not world-readable | `GET …/profiles` | `200 []` / denied |

## B. Authenticated user (sign in, use the returned access token as Bearer)
Replace `$ANON` Bearer with the user's `access_token`.
- [ ] **Reads own rows:** `GET …/workouts` returns only that user's rows.
- [ ] **Cross-user denial:** `GET …/workouts?user_id=eq.<other-uuid>` returns `[]` (never another user's data).
- [ ] **Insert own:** `POST …/workouts` with `user_id = self` → `201`.
- [ ] **Insert as someone else blocked:** same POST with `user_id = <other>` → `401/403`.
- [ ] **Update/delete own:** allowed; **update/delete another user's row:** `0 rows` / denied.

## C. Privilege-escalation (billing must be server-write-only)
- [ ] Authed user **cannot** self-grant a plan:
      `PATCH …/subscriptions?user_id=eq.<self> {"plan":"elite","status":"active"}` → `0 rows`/denied.
- [ ] Authed user **cannot** change `profiles.plan`:
      `PATCH …/profiles?id=eq.<self> {"plan":"elite"}` → permission denied on column `plan`.

## D. Health & fitness data protection
Every per-user table (`recovery_days, sleep_days, workouts, workout_sets, food_logs, hydration_days,
injuries, pain_logs, bloodwork, body_snapshots, forge_score_history, directives, goals, coach_messages`)
must be owner-scoped:
- [ ] Anonymous `GET` of each → `200 []` (never rows).
- [ ] Authenticated user sees only their own rows; cross-user `user_id` filter returns `[]`.
- [ ] No health table is world-readable/writable; none appears without RLS in
      `select relname, relrowsecurity from pg_class where relnamespace='public'::regnamespace and relkind='r'`
      (run in the SQL editor — every user table `relrowsecurity = true`).

## E. Secrets hygiene (client)
- [ ] `ios/…/SupabaseConfig.swift` contains only the **anon** key + URL (verified: no `service_role`).
- [ ] After the anon key is ever rotated, update the client and re-run §A.

---

### Sign-off
All of §A–D behaving as "Expected" = the P0-1/P0-2/P0-7 authorization holes are closed on the live DB.
Record the date + who verified in `FORGE_AUDIT.md §12`.
