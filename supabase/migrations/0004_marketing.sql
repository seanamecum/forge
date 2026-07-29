-- ============================================================================
-- Forge — marketing funnel: waitlist signups + beta applications
-- ============================================================================
-- These tables are NOT user-owned (submitted by anonymous visitors pre-launch),
-- so the security model differs from the app tables in 0001:
--   * RLS is ON. Anonymous visitors may INSERT but never SELECT/UPDATE/DELETE.
--   * Reads happen only via the service role (server API routes / admin), which
--     bypasses RLS. So the list is never publicly readable.
--   * `email` is unique per table — a duplicate signup is a no-op (see API 23505).
-- Run with:  supabase db push   (or supabase migration up)
-- ============================================================================

create extension if not exists "pgcrypto";

-- ---- waitlist -------------------------------------------------------------
create table if not exists public.waitlist_signups (
  id                uuid primary key default gen_random_uuid(),
  name              text not null default '',
  email             text not null,
  fitness_goal      text,
  training_type     text,
  wearable          text,
  marketing_consent boolean not null default false,
  referral          jsonb not null default '{}'::jsonb,
  submitted_at      timestamptz not null default now(),
  created_at        timestamptz not null default now()
);

create unique index if not exists waitlist_signups_email_key
  on public.waitlist_signups (lower(email));

-- ---- beta applications ----------------------------------------------------
create table if not exists public.beta_applications (
  id                  uuid primary key default gen_random_uuid(),
  name                text not null default '',
  email               text not null,
  age_range           text,
  primary_sport       text,
  experience_level    text,
  wearable            text,
  current_apps        text[] not null default '{}',
  training_frequency  text,
  wanted_feature      text,
  why                 text,
  agrees_to_feedback  boolean not null default false,
  marketing_consent   boolean not null default false,
  referral            jsonb not null default '{}'::jsonb,
  submitted_at        timestamptz not null default now(),
  created_at          timestamptz not null default now()
);

create unique index if not exists beta_applications_email_key
  on public.beta_applications (lower(email));

-- ---- RLS: anonymous INSERT only, no public read ---------------------------
alter table public.waitlist_signups  enable row level security;
alter table public.beta_applications enable row level security;

do $$
begin
  if not exists (select 1 from pg_policies where tablename = 'waitlist_signups' and policyname = 'waitlist_public_insert') then
    create policy waitlist_public_insert on public.waitlist_signups
      for insert to anon, authenticated with check (true);
  end if;
  if not exists (select 1 from pg_policies where tablename = 'beta_applications' and policyname = 'beta_public_insert') then
    create policy beta_public_insert on public.beta_applications
      for insert to anon, authenticated with check (true);
  end if;
end $$;

-- No SELECT/UPDATE/DELETE policies are defined on purpose: only the service role
-- (which bypasses RLS) can read these lists. Add an admin SELECT policy here once
-- an internal admin role/claim exists.
