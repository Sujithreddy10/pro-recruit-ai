-- Restrict Team Management actions (invite/remove) to admin recruiters only.
-- Without this, any recruiter could invite or delete any other recruiter
-- account platform-wide, with no notion of who's actually in charge.
--
-- NOTE: this does NOT add multi-company org scoping. All recruiters are
-- still one flat "team" across the whole platform. If Hylo is meant to
-- serve multiple separate companies, that needs a proper organizations
-- table + org_id foreign keys as a follow-up project.

alter table public.profiles
  add column if not exists is_team_admin boolean not null default false;

-- One-time: make yourself an admin so you're not locked out of the
-- feature you just built. Replace the email with your own recruiter
-- account's email before running.
-- update public.profiles
-- set is_team_admin = true
-- where id = (select id from auth.users where email = 'YOUR_EMAIL_HERE');
