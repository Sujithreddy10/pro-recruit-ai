-- Company logos for job listings. Recruiters upload their own logo when
-- posting a job (more reliable than auto-matching company name to a
-- third-party logo API, which fails for smaller/local companies).

alter table public.jobs
  add column if not exists logo_url text;

-- Public bucket: logos are non-sensitive branding assets meant to be
-- visible to every candidate browsing the job feed, so public read access
-- via the public URL is fine and avoids needing signed URLs everywhere.
insert into storage.buckets (id, name, public)
values ('company-logos', 'company-logos', true)
on conflict (id) do nothing;

-- Jobs currently have no recruiter_id/org scoping (flat team model, same
-- as the rest of the jobs table), so write access here matches that
-- existing posture: any authenticated recruiter can upload/update/delete
-- logos, same as they can already edit any job.
drop policy if exists "Authenticated users can upload company logos" on storage.objects;
create policy "Authenticated users can upload company logos"
  on storage.objects for insert
  with check (bucket_id = 'company-logos' and auth.role() = 'authenticated');

drop policy if exists "Authenticated users can update company logos" on storage.objects;
create policy "Authenticated users can update company logos"
  on storage.objects for update
  using (bucket_id = 'company-logos' and auth.role() = 'authenticated');

drop policy if exists "Authenticated users can delete company logos" on storage.objects;
create policy "Authenticated users can delete company logos"
  on storage.objects for delete
  using (bucket_id = 'company-logos' and auth.role() = 'authenticated');
