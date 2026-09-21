create table if not exists public.profile_views (
  id uuid primary key default gen_random_uuid(),
  candidate_id uuid not null references public.profiles(id) on delete cascade,
  recruiter_id uuid not null references public.profiles(id) on delete cascade,
  created_at timestamptz not null default now()
);

alter table public.profile_views enable row level security;

create policy "Candidates can view their own profile views"
  on public.profile_views for select
  using (auth.uid() = candidate_id);

create policy "Recruiters can log their own profile views"
  on public.profile_views for insert
  with check (auth.uid() = recruiter_id);
