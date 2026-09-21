-- Recruiters currently cannot view any candidate's resume: the only SELECT
-- policy on the resumes bucket restricts access to the owning candidate
-- via folder-name matching. This mirrors the existing pattern already used
-- for candidate_certificates ("Recruiters can view all certificates"),
-- reusing the same is_recruiter() helper function.
drop policy if exists "Recruiters can view all resumes" on storage.objects;
create policy "Recruiters can view all resumes"
  on storage.objects for select
  using (bucket_id = 'resumes' and is_recruiter());
