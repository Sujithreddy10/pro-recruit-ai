-- Jobs never had a location field at all, which is why the candidate-side
-- Locations filter had nothing real to filter against. Adding it so
-- recruiters can specify where a job is when posting.
alter table public.jobs
  add column if not exists location text;
