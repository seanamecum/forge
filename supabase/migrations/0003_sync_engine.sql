-- ============================================================================
-- Forge — offline-first sync engine (Supabase / Postgres)
-- ============================================================================
-- The mobile client is offline-first: SwiftData is the local source of truth and
-- every user-generated record is mirrored here as one owner-scoped row in a
-- generic document store. This gives cross-device sync + reinstall durability
-- with a single, uniformly-secured surface, independent of the normalized domain
-- schema in 0001 (which remains for a future web client / analytics; a projection
-- job can back-fill it from these rows later).
--
-- Conflict resolution is last-write-wins per (user_id, kind, record_id) using the
-- CLIENT's logical `updated_at`; `deleted` carries tombstones so removals
-- propagate. `synced_at` is the SERVER receipt clock and is the pull cursor, so a
-- device pulls strictly by server order regardless of client clock skew.
-- Run with:  supabase db push
-- ============================================================================

create table if not exists public.sync_records (
  user_id    uuid        not null references auth.users on delete cascade,
  kind       text        not null,          -- 'workout','weight','supplement',…
  record_id  text        not null,          -- client-stable uuid
  payload    text        not null default '{}',  -- JSON text of the record's fields
  updated_at timestamptz not null,          -- CLIENT logical edit time (LWW key)
  deleted    boolean     not null default false,
  synced_at  timestamptz not null default now(),  -- SERVER receipt time (pull cursor)
  primary key (user_id, kind, record_id)
);

-- Pull cursor: "give me everything the server received after X, in order".
create index if not exists sync_records_pull_idx
  on public.sync_records (user_id, synced_at);

-- Server-side last-write-wins + pull-cursor stamping. On an upsert conflict, a
-- STALE write (older client `updated_at`) never overwrites a newer row — it's
-- skipped, so `synced_at` doesn't advance and other devices won't re-pull an
-- unchanged value. This makes LWW correct regardless of which device pushes last.
-- On a genuine (newer or equal) write we stamp `synced_at` with the server clock,
-- which is the pull cursor. `updated_at` itself is always the client's value.
create or replace function public.set_synced_at()
returns trigger language plpgsql as $$
begin
  if TG_OP = 'UPDATE' and NEW.updated_at < OLD.updated_at then
    return OLD;                       -- older edit loses; keep the newer row as-is
  end if;
  new.synced_at = now();
  return new;
end; $$;

drop trigger if exists t_sync_synced on public.sync_records;
create trigger t_sync_synced before insert or update on public.sync_records
  for each row execute function public.set_synced_at();

-- Owner-only, identical to every other user table (the security spine).
alter table public.sync_records enable row level security;
drop policy if exists "own" on public.sync_records;
create policy "own" on public.sync_records
  using (auth.uid() = user_id) with check (auth.uid() = user_id);
