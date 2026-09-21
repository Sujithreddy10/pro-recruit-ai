-- The insert/update/delete policies on company-logos were correct, but
-- storage.objects never got a SELECT policy for this bucket. Postgres's
-- RLS requires SELECT visibility on a row for INSERT ... RETURNING to
-- succeed, and the Storage API's upload endpoint uses RETURNING
-- internally -- so uploads were failing purely because there was no way
-- for the uploader to "see" the row it just created, even though the
-- insert itself was always permitted. Bucket is public, so any
-- authenticated user (or even anon, mirroring the public bucket intent)
-- can view.
drop policy if exists "Anyone can view company logos" on storage.objects;
create policy "Anyone can view company logos"
  on storage.objects for select
  using (bucket_id = 'company-logos');
