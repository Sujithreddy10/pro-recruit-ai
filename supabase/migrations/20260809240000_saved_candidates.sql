create table if not exists public.saved_candidates (
  id uuid primary key default gen_random_uuid(),
  recruiter_id uuid not null references public.profiles(id) on delete cascade,
  candidate_id uuid not null references public.profiles(id) on delete cascade,
  created_at timestamptz not null default now(),
  unique(recruiter_id, candidate_id)
);

alter table public.saved_candidates enable row level security;

create policy "Recruiters can view own saved candidates"
  on public.saved_candidates for select
  using (auth.uid() = recruiter_id);

create policy "Recruiters can insert own saved candidates"
  on public.saved_candidates for insert
  with check (auth.uid() = recruiter_id);

create policy "Recruiters can delete own saved candidates"
  on public.saved_candidates for delete
  using (auth.uid() = recruiter_id);
