alter table public.applications add column if not exists recruiter_notes text;
alter table public.applications add column if not exists recruiter_rating smallint check (recruiter_rating between 1 and 5);
