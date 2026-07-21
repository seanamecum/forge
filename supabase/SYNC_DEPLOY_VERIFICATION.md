# Forge — Cloud Sync (`0003_sync_engine.sql`) deploy + verification

The migration is written idempotently (`create table/index if not exists`,
`create or replace function`, `drop … if exists` before each trigger/policy), so
re-running is safe. It only depends on `auth.users` (from Supabase) and does **not**
touch the `0001` domain tables, so it can go out independently.

> **Auto-mode cannot run `supabase db push`** (the deploy classifier blocks
> production writes). Run the steps below yourself; then tell me "migration
> confirmed" and I'll wire the live end-to-end checks into the audit.

---

## 0. Pre-deploy static review (already done — for the record)
- Columns/keys match the client exactly: PK `(user_id, kind, record_id)`; the app
  upserts with `on_conflict=user_id,kind,record_id` + `Prefer: resolution=merge-duplicates`
  and pulls with `order=synced_at.asc&synced_at=gt.<cursor>`.
- `payload` is `text` (JSON string) — never queried server-side, so no `jsonb` cast.
- Trigger `set_synced_at`: enforces **server-side last-write-wins** (a stale
  `updated_at` returns `OLD`, so it never overwrites a newer row) and stamps
  `synced_at` (the pull cursor) on every accepted write. It never mutates
  `updated_at` (the client's LWW value).
- RLS `own` policy is owner-scoped `auth.uid() = user_id` (USING + WITH CHECK),
  identical to every other user table.

## 1. Deploy
```bash
cd /Users/seanmecum/forge-main
export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"   # if the CLI isn't on PATH
supabase migration list          # see what's pending (0002/0003 — and 0004 if present)
supabase db push --dry-run       # review the plan; expect 0003 (+ any other pending)
supabase db push                 # apply
```
> `db push` applies **all** pending migrations. If `0002_rls_hardening` or an
> unrelated `0004_marketing` are also pending, they go out too — review the
> dry-run output first and confirm that's intended.

## 2. Confirm it applied
```bash
supabase migration list          # 0003 must appear in BOTH Local and Remote
supabase db push --dry-run       # must say the remote is up to date (nothing pending)
```

## 3. Schema + security checks (SQL editor)
```sql
-- table + columns present, RLS on
select relrowsecurity
  from pg_class
 where oid = 'public.sync_records'::regclass;            -- expect: t

select policyname, cmd
  from pg_policies
 where schemaname='public' and tablename='sync_records'; -- expect: "own", ALL

-- pull-cursor index exists
select indexname from pg_indexes
 where schemaname='public' and tablename='sync_records'; -- expect sync_records_pull_idx

-- trigger present
select tgname from pg_trigger
 where tgrelid='public.sync_records'::regclass and not tgisinternal; -- t_sync_synced
```

## 4. Server-side LWW smoke test (SQL editor — proves the trigger)
Run as a role that bypasses RLS (SQL editor does). Use a throwaway user id.
```sql
-- newer write wins; older write is ignored; synced_at advances only on accept
insert into public.sync_records(user_id,kind,record_id,payload,updated_at,deleted)
values ('00000000-0000-0000-0000-000000000000','weight','t1','{"v":1}','2030-01-01', false);

-- stale update (older updated_at) — must be ignored
insert into public.sync_records(user_id,kind,record_id,payload,updated_at,deleted)
values ('00000000-0000-0000-0000-000000000000','weight','t1','{"v":0}','2029-01-01', false)
on conflict (user_id,kind,record_id) do update
  set payload=excluded.payload, updated_at=excluded.updated_at, deleted=excluded.deleted;

select payload, updated_at from public.sync_records
 where record_id='t1';        -- expect payload {"v":1}, updated_at 2030 (stale write lost)

-- newer update — must win
insert into public.sync_records(user_id,kind,record_id,payload,updated_at,deleted)
values ('00000000-0000-0000-0000-000000000000','weight','t1','{"v":2}','2031-01-01', false)
on conflict (user_id,kind,record_id) do update
  set payload=excluded.payload, updated_at=excluded.updated_at, deleted=excluded.deleted;

select payload from public.sync_records where record_id='t1';   -- expect {"v":2}

delete from public.sync_records where record_id='t1';           -- cleanup
```

## 5. RLS checks — anon must be blocked (PostgREST, no dashboard)
```bash
URL="https://vxprqlniecdcxjkevoob.supabase.co"     # from ios/.../SupabaseConfig.swift
ANON="<anon publishable key>"
h=(-H "apikey: $ANON" -H "Authorization: Bearer $ANON")
```
| Check | Command | Expected |
|---|---|---|
| anon read blocked | `curl -s "$URL/rest/v1/sync_records?select=*" "${h[@]}"` | `200 []` (RLS filters all) — never rows |
| anon write blocked | `curl -s -o/dev/null -w "%{http_code}" -X POST "$URL/rest/v1/sync_records" "${h[@]}" -H "Content-Type: application/json" -d '[{"user_id":"00000000-0000-0000-0000-000000000000","kind":"weight","record_id":"x","payload":"{}","updated_at":"2030-01-01","deleted":false}]'` | `401/403` — never `201` |

## 6. Authenticated round-trip (real token)
Sign in in the app (or via GoTrue) and use the returned `access_token` as Bearer:
- [ ] `POST /rest/v1/sync_records` with `user_id = self` → `201`.
- [ ] `POST` with `user_id = <someone else>` → `401/403` (WITH CHECK blocks it).
- [ ] `GET /rest/v1/sync_records?user_id=eq.<other>` → `[]` (cross-user denial).
- [ ] In-app: on a signed-in device, log a weigh-in → the Profile "Cloud Sync" card
      reads **Backed up**; delete + reinstall (or a second device signed into the
      same account) restores it after one sync.

---

### Sign-off
§2–6 all "Expected" ⇒ cloud sync is live and owner-scoped. Record the date + who
verified in `FORGE_AUDIT.md §12a` (migration status) and §12g.
