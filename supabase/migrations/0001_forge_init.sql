-- ============================================================================
-- Forge — Human Performance OS · initial schema (Supabase / Postgres)
-- ============================================================================
-- Conventions:
--   * Every user-owned table has `user_id uuid references auth.users` + RLS so a
--     row is only ever visible/writable by its owner. This is the security spine
--     and it's identical whether the client is the web app or React Native.
--   * `updated_at` is maintained by a trigger.
--   * Daily signal tables are keyed (user_id, day) so a day is upsertable and the
--     Forge Score / Directive engines read one row per day.
--   * Enums live in Postgres so web + mobile + edge functions share one contract.
-- Run with:  supabase db push   (or supabase migration up)
-- ============================================================================

create extension if not exists "pgcrypto";

-- ---- shared updated_at trigger --------------------------------------------
create or replace function public.set_updated_at()
returns trigger language plpgsql as $$
begin new.updated_at = now(); return new; end; $$;

-- ---- enums (idempotent — Postgres has no `create type if not exists`) -------
do $$
begin
  if not exists (select 1 from pg_type where typname = 'sex_t') then
    create type sex_t as enum ('male','female','other'); end if;
  if not exists (select 1 from pg_type where typname = 'fitness_level_t') then
    create type fitness_level_t as enum ('beginner','intermediate','advanced','elite'); end if;
  if not exists (select 1 from pg_type where typname = 'activity_level_t') then
    create type activity_level_t as enum ('sedentary','light','moderate','active','very_active'); end if;
  if not exists (select 1 from pg_type where typname = 'goal_t') then
    create type goal_t as enum ('build_muscle','lose_fat','endurance','strength','athletic','health','injury_recovery'); end if;
  if not exists (select 1 from pg_type where typname = 'injury_phase_t') then
    create type injury_phase_t as enum ('acute','subacute','rehab','return_to_sport','resolved'); end if;
  if not exists (select 1 from pg_type where typname = 'plan_t') then
    create type plan_t as enum ('free','pro','elite'); end if;
end $$;

-- ============================================================================
-- IDENTITY
-- ============================================================================
create table if not exists public.profiles (
  id              uuid primary key references auth.users on delete cascade,
  name            text not null default '',
  sex             sex_t,
  birth_date      date,
  height_in       numeric,
  weight_lb       numeric,
  fitness_level   fitness_level_t default 'intermediate',
  activity_level  activity_level_t default 'moderate',
  goals           goal_t[] default '{}',
  sport           text,
  diet            text,
  uses_imperial   boolean default true,
  -- gamification
  level           int default 1,
  xp              int default 0,
  streak_days     int default 0,
  -- monetization
  plan            plan_t default 'free',
  created_at      timestamptz default now(),
  updated_at      timestamptz default now()
);

create table if not exists public.subscriptions (
  user_id              uuid primary key references auth.users on delete cascade,
  plan                 plan_t not null default 'free',
  status               text not null default 'active',     -- active | trialing | past_due | canceled
  stripe_customer_id   text,
  stripe_subscription_id text,
  current_period_end   timestamptz,
  updated_at           timestamptz default now()
);

-- ============================================================================
-- DAILY SIGNALS  (the inputs to Forge Score + Directive + Insight engines)
-- ============================================================================
create table if not exists public.recovery_days (
  id            uuid primary key default gen_random_uuid(),
  user_id       uuid not null references auth.users on delete cascade,
  day           date not null,
  recovery      int,          -- 0..100
  hrv_ms        int,
  hrv_baseline  int,
  resting_hr    int,
  readiness     text,         -- low|moderate|high|peak
  strain        numeric,      -- 0..21
  steps         int,
  calories_out  int,
  source        text default 'manual',  -- manual | healthkit | whoop | oura | garmin
  created_at    timestamptz default now(),
  unique (user_id, day)
);

create table if not exists public.sleep_days (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null references auth.users on delete cascade,
  day         date not null,
  hours       numeric,
  deep_hours  numeric,
  rem_hours   numeric,
  light_hours numeric,
  awake_hours numeric,
  score       int,
  debt_hours  numeric,
  bedtime     text,
  waketime    text,
  unique (user_id, day)
);

-- ============================================================================
-- TRAINING
-- ============================================================================
create table if not exists public.exercises (                 -- shared library (no user_id)
  id          uuid primary key default gen_random_uuid(),
  slug        text unique not null,
  name        text not null,
  muscles     text[] default '{}',
  equipment   text[] default '{}',
  pattern     text,
  is_public   boolean default true
);

create table if not exists public.workouts (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null references auth.users on delete cascade,
  name        text not null,
  day         date not null default current_date,
  est_minutes int,
  notes       text,
  generated   boolean default false,            -- from the AI generator?
  rationale   text,
  created_at  timestamptz default now()
);

create table if not exists public.workout_sets (
  id           uuid primary key default gen_random_uuid(),
  workout_id   uuid not null references public.workouts on delete cascade,
  user_id      uuid not null references auth.users on delete cascade,
  exercise_id  uuid references public.exercises,
  exercise_name text not null,
  set_index    int not null,
  weight_lb    numeric,
  reps         int,
  rpe          numeric,
  is_pr        boolean default false
);

create table if not exists public.personal_records (
  id           uuid primary key default gen_random_uuid(),
  user_id      uuid not null references auth.users on delete cascade,
  exercise_name text not null,
  weight_lb    numeric,
  reps         int,
  est_1rm      numeric,
  achieved_on  date default current_date
);

-- ============================================================================
-- NUTRITION
-- ============================================================================
create table if not exists public.foods (                      -- shared + user-custom
  id        uuid primary key default gen_random_uuid(),
  user_id   uuid references auth.users on delete cascade,   -- null => public food
  name      text not null,
  brand     text,
  serving   text,
  calories  numeric, protein numeric, carbs numeric, fat numeric,
  fiber numeric, sugar numeric
);

create table if not exists public.food_logs (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid not null references auth.users on delete cascade,
  food_id    uuid references public.foods,
  day        date not null default current_date,
  meal       text not null,                       -- breakfast|lunch|dinner|snack
  servings   numeric not null default 1,
  logged_at  timestamptz default now()
);

create table if not exists public.hydration_days (
  user_id   uuid not null references auth.users on delete cascade,
  day       date not null,
  water_oz  numeric not null default 0,
  primary key (user_id, day)
);

create table if not exists public.supplements (
  id           uuid primary key default gen_random_uuid(),
  user_id      uuid not null references auth.users on delete cascade,
  name         text not null,
  dose         text,
  timing       text,
  benefit      text,
  active       boolean default true
);

create table if not exists public.supplement_logs (
  id            uuid primary key default gen_random_uuid(),
  user_id       uuid not null references auth.users on delete cascade,
  supplement_id uuid not null references public.supplements on delete cascade,
  day           date not null default current_date,
  taken         boolean default true,
  unique (user_id, supplement_id, day)
);

-- ============================================================================
-- INJURY / PT  (a Forge differentiator)
-- ============================================================================
create table if not exists public.injuries (
  id           uuid primary key default gen_random_uuid(),
  user_id      uuid not null references auth.users on delete cascade,
  type         text not null,                     -- knee|shoulder|...
  name         text not null,
  phase        injury_phase_t default 'rehab',
  pain_today   int default 0,
  severity     int default 1,
  mobility_pct int, strength_pct int, stability_pct int,
  started_on   date default current_date,
  resolved     boolean default false,
  notes        text
);

create table if not exists public.pain_logs (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid not null references auth.users on delete cascade,
  injury_id  uuid not null references public.injuries on delete cascade,
  day        date not null default current_date,
  pain       int not null,
  unique (injury_id, day)
);

create table if not exists public.rts_checklist (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid not null references auth.users on delete cascade,
  injury_id  uuid not null references public.injuries on delete cascade,
  label      text not null,
  detail     text,
  done       boolean default false
);

-- ============================================================================
-- HEALTH / FORECASTS / SCORE / DIRECTIVE  (engine outputs, cached per day)
-- ============================================================================
create table if not exists public.bloodwork (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null references auth.users on delete cascade,
  name        text not null,
  category    text,
  value       numeric, unit text,
  normal_low numeric, normal_high numeric,
  optimal_low numeric, optimal_high numeric,
  taken_on    date
);

create table if not exists public.body_snapshots (
  id           uuid primary key default gen_random_uuid(),
  user_id      uuid not null references auth.users on delete cascade,
  day          date not null default current_date,
  weight_lb    numeric, body_fat_pct numeric, lean_mass_lb numeric,
  unique (user_id, day)
);

create table if not exists public.forge_score_history (
  user_id   uuid not null references auth.users on delete cascade,
  day       date not null,
  score     int not null,
  breakdown jsonb,                                -- {sleep:.., recovery:.., ...}
  primary key (user_id, day)
);

create table if not exists public.directives (                  -- the cached daily plan + why
  user_id   uuid not null references auth.users on delete cascade,
  day       date not null,
  headline  text, rationale text, priority text,
  actions   jsonb,                                -- [{kind,value,tone}, ...]
  primary key (user_id, day)
);

create table if not exists public.goals (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null references auth.users on delete cascade,
  title       text not null,
  metric      text,
  target      numeric, current numeric, unit text,
  due_on      date,
  achieved    boolean default false
);

-- ============================================================================
-- AI COACH (conversation history; reused by web + mobile)
-- ============================================================================
create table if not exists public.coach_threads (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid not null references auth.users on delete cascade,
  title      text,
  created_at timestamptz default now()
);
create table if not exists public.coach_messages (
  id         uuid primary key default gen_random_uuid(),
  thread_id  uuid not null references public.coach_threads on delete cascade,
  user_id    uuid not null references auth.users on delete cascade,
  role       text not null,                       -- user | coach
  content    text not null,
  meta       jsonb,                               -- steps/cards/suggestions
  created_at timestamptz default now()
);

-- ============================================================================
-- SOCIAL  (opt-in; minimal surface)
-- ============================================================================
create table if not exists public.posts (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid not null references auth.users on delete cascade,
  kind       text,                                -- pr|progress|workout|share
  body       text,
  stat_label text, stat_value text,
  visibility text default 'public',               -- public | followers | private
  created_at timestamptz default now()
);
create table if not exists public.challenges (
  id         uuid primary key default gen_random_uuid(),
  name       text not null, reward text, ends_on date
);
create table if not exists public.challenge_members (
  challenge_id uuid references public.challenges on delete cascade,
  user_id      uuid references auth.users on delete cascade,
  progress     numeric default 0,
  primary key (challenge_id, user_id)
);

-- ============================================================================
-- updated_at triggers
-- ============================================================================
drop trigger if exists t_profiles_updated on public.profiles;
create trigger t_profiles_updated   before update on public.profiles
  for each row execute function public.set_updated_at();
drop trigger if exists t_subs_updated on public.subscriptions;
create trigger t_subs_updated        before update on public.subscriptions
  for each row execute function public.set_updated_at();

-- new auth user => profile + free subscription row
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into public.profiles (id, name) values (new.id, coalesce(new.raw_user_meta_data->>'name',''));
  insert into public.subscriptions (user_id) values (new.id);
  return new;
end; $$;
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created after insert on auth.users
  for each row execute function public.handle_new_user();

-- ============================================================================
-- ROW LEVEL SECURITY  (owner-only for every user table)
-- ============================================================================
do $$
declare t text;
begin
  foreach t in array array[
    'profiles','subscriptions','recovery_days','sleep_days','workouts','workout_sets',
    'personal_records','food_logs','hydration_days','supplements','supplement_logs',
    'injuries','pain_logs','rts_checklist','bloodwork','body_snapshots',
    'forge_score_history','directives','goals','coach_threads','coach_messages',
    'posts','foods'
  ]
  loop
    execute format('alter table public.%I enable row level security;', t);
    execute format('drop policy if exists "own" on public.%I;', t);
    -- profiles keys on id; everything else keys on user_id
    if t = 'profiles' then
      execute format($p$create policy "own" on public.%I
        using (auth.uid() = id) with check (auth.uid() = id);$p$, t);
    else
      execute format($p$create policy "own" on public.%I
        using (auth.uid() = user_id) with check (auth.uid() = user_id);$p$, t);
    end if;
  end loop;
end $$;

-- shared read-only catalogs (exercises, public foods, challenges) are world-readable
alter table public.exercises enable row level security;
drop policy if exists "read_public_exercises" on public.exercises;
create policy "read_public_exercises" on public.exercises for select using (is_public);
alter table public.challenges enable row level security;
drop policy if exists "read_challenges" on public.challenges;
create policy "read_challenges" on public.challenges for select using (true);

-- public posts are readable by anyone; foods: public rows readable by all
drop policy if exists "read_public_posts" on public.posts;
create policy "read_public_posts" on public.posts for select using (visibility = 'public');
drop policy if exists "read_public_foods" on public.foods;
create policy "read_public_foods" on public.foods for select using (user_id is null);
