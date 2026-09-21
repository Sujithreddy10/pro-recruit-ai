-- Fix company-logos storage policies: auth.role() = 'authenticated' was
-- rejecting uploads with a 403, while the proven-working resume upload
-- policy uses auth.uid() instead. Switching to the same reliable check.

drop policy if exists "Authenticated users can upload company logos" on storage.objects;
create policy "Authenticated users can upload company logos"
  on storage.objects for insert
  with check (bucket_id = 'company-logos' and auth.uid() is not null);

drop policy if exists "Authenticated users can update company logos" on storage.objects;
create policy "Authenticated users can update company logos"
  on storage.objects for update
  using (bucket_id = 'company-logos' and auth.uid() is not null);

drop policy if exists "Authenticated users can delete company logos" on storage.objects;
create policy "Authenticated users can delete company logos"
  on storage.objects for delete
  using (bucket_id = 'company-logos' and auth.uid() is not null);
