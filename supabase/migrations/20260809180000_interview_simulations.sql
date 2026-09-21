-- Allow the new 'interview-simulate' feature in the shared usage log
alter table public.ai_usage_log drop constraint if exists ai_usage_log_feature_check;
alter table public.ai_usage_log add constraint ai_usage_log_feature_check
  check (feature in ('intake-chat', 'match-score', 'generate-draft', 'skill-gap', 'interview-simulate'));

-- Stores each AI mock interview session so candidates can review past attempts
create table if not exists public.interview_simulations (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  role_title text not null,
  questions jsonb not null,
  answers jsonb not null,
  feedback text,
  score int,
  created_at timestamptz not null default now()
);

create index if not exists interview_simulations_user_idx
  on public.interview_simulations (user_id, created_at desc);

alter table public.interview_simulations enable row level security;

drop policy if exists "Candidates can view their own interview sessions" on public.interview_simulations;
create policy "Candidates can view their own interview sessions"
  on public.interview_simulations
  for select
  using (auth.uid() = user_id);

-- Inserts happen exclusively via the edge function's service role key.
