-- Resume Vault: candidates can store multiple resume versions instead of
-- just the single resume_path on profiles. Slot limits are enforced
-- client-side based on subscription_tier (free=1, pro=3, enterprise=
-- unlimited), matching the pattern already used for Usage Credits.
--
-- IMPORTANT: profiles.resume_path / resume_uploaded_at stay in sync with
-- whichever row is marked is_primary, via trigger below. This is required
-- because 5 existing recruiter-facing screens (talent_match_screen,
-- candidate_crm_screen, trust_score_screen, recruiter_root.dart x2) read
-- resume_path directly off profiles and were not rewritten to query this
-- new table. Do not remove that sync without updating all 5 call sites.

create table if not exists public.candidate_resumes (
  id uuid primary key default gen_random_uuid(),
  candidate_id uuid not null references auth.users(id) on delete cascade,
  storage_path text not null,
  file_name text not null,
  label text not null default 'Resume',
  is_primary boolean not null default false,
  created_at timestamptz not null default now()
);

create index if not exists candidate_resumes_candidate_id_idx
  on public.candidate_resumes(candidate_id);

alter table public.candidate_resumes enable row level security;

drop policy if exists "Candidates manage own resumes" on public.candidate_resumes;
create policy "Candidates manage own resumes"
  on public.candidate_resumes
  for all
  using (auth.uid() = candidate_id)
  with check (auth.uid() = candidate_id);

-- Recruiters don't browse this table directly (they still go through
-- profiles.resume_path as before), so no recruiter select policy needed.

create or replace function public.sync_primary_resume()
returns trigger as $$
begin
  if new.is_primary then
    update public.candidate_resumes
      set is_primary = false
      where candidate_id = new.candidate_id
        and id <> new.id
        and is_primary = true;

    update public.profiles
      set resume_path = new.storage_path,
          resume_uploaded_at = new.created_at
      where id = new.candidate_id;
  end if;
  return new;
end;
$$ language plpgsql security definer;

drop trigger if exists trg_sync_primary_resume on public.candidate_resumes;
create trigger trg_sync_primary_resume
  after insert or update of is_primary on public.candidate_resumes
  for each row
  when (new.is_primary = true)
  execute function public.sync_primary_resume();

create or replace function public.handle_resume_deletion()
returns trigger as $$
declare
  next_resume record;
begin
  if old.is_primary then
    select * into next_resume
      from public.candidate_resumes
      where candidate_id = old.candidate_id
        and id <> old.id
      order by created_at desc
      limit 1;

    if next_resume.id is not null then
      update public.candidate_resumes
        set is_primary = true
        where id = next_resume.id;
    else
      update public.profiles
        set resume_path = null,
            resume_uploaded_at = null
        where id = old.candidate_id;
    end if;
  end if;
  return old;
end;
$$ language plpgsql security definer;

drop trigger if exists trg_handle_resume_deletion on public.candidate_resumes;
create trigger trg_handle_resume_deletion
  after delete on public.candidate_resumes
  for each row
  execute function public.handle_resume_deletion();

insert into public.candidate_resumes (candidate_id, storage_path, file_name, label, is_primary, created_at)
select
  p.id,
  p.resume_path,
  split_part(p.resume_path, '/', 2),
  'My Resume',
  true,
  coalesce(p.resume_uploaded_at, now())
from public.profiles p
where p.resume_path is not null
  and p.resume_path <> ''
  and not exists (
    select 1 from public.candidate_resumes cr where cr.candidate_id = p.id
  );
