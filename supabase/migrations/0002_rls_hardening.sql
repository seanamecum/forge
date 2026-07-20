-- ============================================================================
-- 0002_rls_hardening.sql
-- Closes the P0 authorization gaps found in the launch audit (see FORGE_AUDIT.md
-- §4 P0-1, P0-2, P0-7). Safe to run once against the project created by
-- 0001_forge_init.sql. Idempotent guards are used where practical.
--
-- ⚠︎ NOT APPLIED/TESTED by the audit tooling — no Supabase CLI in that environment.
-- Apply via the Supabase SQL editor or `supabase db push`, then verify with the
-- checks at the bottom of this file. Rotate the anon key afterwards.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- P0-1 · challenge_members had NO row-level security → world read/write via anon.
-- Enable RLS and scope every row to its owner (auth.uid() = user_id).
-- ----------------------------------------------------------------------------
alter table public.challenge_members enable row level security;

drop policy if exists "own" on public.challenge_members;
create policy "own_challenge_membership"
  on public.challenge_members
  for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- ----------------------------------------------------------------------------
-- P0-2 · subscriptions was writable by the row's owner (the loop policy was
-- FOR ALL), letting a user self-grant plan='elite'/status='active'. Billing is
-- server truth: clients may READ their own row, only the service role may write.
-- (RLS does not apply to the service role, so server code keeps full access.)
-- ----------------------------------------------------------------------------
drop policy if exists "own" on public.subscriptions;

create policy "read_own_subscription"
  on public.subscriptions
  for select
  using (auth.uid() = user_id);
-- no insert/update/delete policy ⇒ denied for anon & authenticated.

-- Defense in depth at the column-privilege layer (independent of RLS):
revoke insert, update, delete on public.subscriptions from anon, authenticated;

-- ----------------------------------------------------------------------------
-- P0-2 (cont.) · profiles keeps its owner FOR ALL policy (users legitimately
-- edit name/goals/units), but the monetization column must not be self-set.
-- Revoke UPDATE on just profiles.plan from client roles; service role retains it.
-- ----------------------------------------------------------------------------
revoke update (plan) on public.profiles from anon, authenticated;

-- ----------------------------------------------------------------------------
-- P0-7 · The feedback table that iOS + web POST to was never in a migration, so
-- its "insert-only" protection was unverifiable. Define it here as insert-only
-- for public clients (no select/update/delete policy), with length bounds so the
-- endpoint can't be used as an unbounded storage/abuse sink.
--   create if not exists so this is safe whether or not a dashboard-made table
--   already exists; the policies/constraints below are the authoritative state.
-- ----------------------------------------------------------------------------
create table if not exists public.feedback (
  id          uuid primary key default gen_random_uuid(),
  created_at  timestamptz not null default now(),
  message     text not null,
  email       text,
  source      text,                       -- 'ios' | 'web' | …
  app_version text,
  user_id     uuid references auth.users on delete set null,
  constraint feedback_message_len check (char_length(message) between 1 and 4000),
  constraint feedback_email_len   check (email is null or char_length(email) <= 320),
  constraint feedback_source_len  check (source is null or char_length(source) <= 32),
  constraint feedback_appver_len  check (app_version is null or char_length(app_version) <= 32)
);

alter table public.feedback enable row level security;

drop policy if exists "insert_feedback" on public.feedback;
create policy "insert_feedback"
  on public.feedback
  for insert
  to anon, authenticated
  with check (
    char_length(message) between 1 and 4000
    and (email is null or char_length(email) <= 320)
  );
-- Intentionally NO select/update/delete policy: public clients can write feedback
-- but can never read, edit, or delete any row (submitter emails stay private).
-- Read it from the dashboard or a service-role job only.

-- ----------------------------------------------------------------------------
-- Verification (run manually after apply; each should behave as noted):
--   -- 1) challenge_members no longer world-readable by anon:
--   --    set role anon; select * from public.challenge_members;  -> 0 rows / denied
--   -- 2) a signed-in user cannot escalate plan:
--   --    update public.subscriptions set plan='elite' where user_id=auth.uid();  -> 0 rows
--   --    update public.profiles set plan='elite' where id=auth.uid();            -> permission denied on column "plan"
--   -- 3) feedback insert works but select is denied for anon:
--   --    insert into public.feedback(message) values ('hi');  -> ok
--   --    select * from public.feedback;                        -> denied (no policy)
--   -- 4) confirm every user table has RLS enabled:
--   --    select relname, relrowsecurity from pg_class
--   --    where relnamespace='public'::regnamespace and relkind='r' order by relname;
-- ----------------------------------------------------------------------------
