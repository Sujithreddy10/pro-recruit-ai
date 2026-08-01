-- Subscription tier + AI usage tracking
-- Powers the recruiter drawer's "Subscription Plan" and "Usage Credits" screens.

-- 1. Subscription tier lives on profiles (org-level in spirit, tracked per recruiter for now).
alter table public.profiles
  add column if not exists subscription_tier text not null default 'free'
    check (subscription_tier in ('free', 'pro', 'enterprise'));

-- 2. Log every AI feature call so Usage Credits can show real consumption.
create table if not exists public.ai_usage_log (
  id bigint generated always as identity primary key,
  user_id uuid not null references public.profiles(id) on delete cascade,
  feature text not null check (feature in ('intake-chat', 'match-score', 'generate-draft', 'skill-gap')),
  created_at timestamptz not null default now()
);

create index if not exists ai_usage_log_user_month_idx
  on public.ai_usage_log (user_id, created_at desc);

-- 3. RLS: recruiters can only read their own usage rows.
-- Inserts happen exclusively from Edge Functions using the service role key,
-- which bypasses RLS, so no insert policy is needed for client-side access.
alter table public.ai_usage_log enable row level security;

drop policy if exists "Users can view their own usage" on public.ai_usage_log;
create policy "Users can view their own usage"
  on public.ai_usage_log
  for select
  using (auth.uid() = user_id);
