-- Onboarding Pro: one-time guided flow for new candidates right after
-- signup (welcome -> upload resume -> AI skill snapshot -> real job
-- matches preview). Tracked via profiles.onboarding_completed so it only
-- shows once per candidate.

alter table public.profiles
  add column if not exists onboarding_completed boolean not null default false;

-- Don't retroactively force existing candidates (including test accounts
-- like harsha) through onboarding they never had. Only NEW candidate
-- signups from this point forward will see the flow.
update public.profiles
set onboarding_completed = true
where user_role = 'candidate'
  and onboarding_completed = false;
