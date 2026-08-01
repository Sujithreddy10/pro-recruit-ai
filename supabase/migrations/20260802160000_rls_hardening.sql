-- RLS hardening pass, based on a full audit of pg_tables / pg_policies.
--
-- Fixes three real issues found:
-- 1. applications had 4 leftover dev/test policies allowing ANONYMOUS
--    inserts with no restriction. Anyone with the public anon key could
--    spam fake applications into production.
-- 2. candidate_profiles (name, phone, hourly rate, location) had RLS
--    disabled entirely - fully exposed to any client with the anon key.
-- 3. profiles' "Users can update own profile" policy allowed changing
--    ANY column on your own row, including user_role and is_team_admin -
--    meaning a user could self-promote to recruiter or team admin by
--    calling .update() directly, bypassing the team-invite Edge Function.

-- 1. Remove the dangerous anonymous-insert dev/test policies on applications.
-- The legitimate "Users can insert their own applications" policy stays,
-- so real authenticated users are unaffected.
drop policy if exists "Allow anon insert for dev" on public.applications;
drop policy if exists "Allow anon insert for local test" on public.applications;
drop policy if exists "Allow anon inserts for testing" on public.applications;
drop policy if exists "Dev Allow Anon Insert" on public.applications;

-- 2. Enable RLS on candidate_profiles and add owner + recruiter-read policies,
-- matching the pattern already used on candidate_skills / candidate_projects.
alter table public.candidate_profiles enable row level security;

drop policy if exists "Users manage own candidate profile" on public.candidate_profiles;
create policy "Users manage own candidate profile"
  on public.candidate_profiles
  for all
  using (auth.uid() = id)
  with check (auth.uid() = id);

drop policy if exists "Recruiters view all candidate profiles" on public.candidate_profiles;
create policy "Recruiters view all candidate profiles"
  on public.candidate_profiles
  for select
  using (is_recruiter());

-- 3. Prevent privilege escalation: block client-side changes to user_role
-- and is_team_admin on profiles unless the request comes from the service
-- role (i.e. through an Edge Function using the service role key, like
-- team-invite). Regular authenticated users can still update every other
-- column on their own row (full_name, resume_path, subscription_tier, etc).
--
-- user_role is only guarded once it already has a real value, so this does
-- not interfere with however your existing signup flow first sets it.
create or replace function public.prevent_privilege_escalation()
returns trigger as $$
begin
  if current_user <> 'service_role' then
    if old.user_role is not null and new.user_role is distinct from old.user_role then
      new.user_role := old.user_role;
    end if;
    if new.is_team_admin is distinct from old.is_team_admin then
      new.is_team_admin := old.is_team_admin;
    end if;
  end if;
  return new;
end;
$$ language plpgsql security definer;

drop trigger if exists trg_prevent_privilege_escalation on public.profiles;
create trigger trg_prevent_privilege_escalation
  before update on public.profiles
  for each row
  execute function public.prevent_privilege_escalation();
