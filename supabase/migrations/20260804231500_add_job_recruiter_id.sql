alter table public.jobs
  add column if not exists recruiter_id uuid references public.profiles(id) on delete set null;

drop policy if exists "Recruiters can insert jobs" on public.jobs;
create policy "Recruiters can insert own jobs"
  on public.jobs for insert
  with check (is_recruiter() and recruiter_id = auth.uid());

drop policy if exists "Recruiters can update jobs" on public.jobs;
create policy "Recruiters can update own jobs"
  on public.jobs for update
  using (is_recruiter() and recruiter_id = auth.uid())
  with check (is_recruiter() and recruiter_id = auth.uid());

drop policy if exists "Recruiters can delete jobs" on public.jobs;
create policy "Recruiters can delete own jobs"
  on public.jobs for delete
  using (is_recruiter() and recruiter_id = auth.uid());
