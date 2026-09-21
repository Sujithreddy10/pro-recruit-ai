create table if not exists public.saved_jobs (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  job_id uuid not null references public.jobs(id) on delete cascade,
  created_at timestamptz not null default now(),
  unique(user_id, job_id)
);

alter table public.saved_jobs enable row level security;

create policy "Users can view own saved jobs"
  on public.saved_jobs for select
  using (auth.uid() = user_id);

create policy "Users can insert own saved jobs"
  on public.saved_jobs for insert
  with check (auth.uid() = user_id);

create policy "Users can delete own saved jobs"
  on public.saved_jobs for delete
  using (auth.uid() = user_id);
