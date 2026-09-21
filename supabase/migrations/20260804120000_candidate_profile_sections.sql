-- Basic Details, Professional Summary, Personal Details, Career Preferences,
-- and Diversity & Inclusion are single-value per candidate, so they live
-- directly on profiles. Employment, Education, Accomplishments, and
-- Languages each get their own table since a candidate can have multiple
-- entries of each -- same pattern as the existing candidate_skills and
-- candidate_projects tables.

alter table public.profiles
  add column if not exists phone text,
  add column if not exists city text,
  add column if not exists work_status text,
  add column if not exists availability text,
  add column if not exists professional_summary text,
  add column if not exists dob date,
  add column if not exists gender text,
  add column if not exists address text,
  add column if not exists gender_preference text,
  add column if not exists specially_abled_status text,
  add column if not exists preferred_work_mode text,
  add column if not exists preferred_location text,
  add column if not exists expected_salary text;

create table if not exists public.candidate_employment (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  company_name text not null,
  designation text not null,
  start_date date,
  end_date date,
  is_current boolean default false,
  description text,
  created_at timestamptz default now()
);
alter table public.candidate_employment enable row level security;
drop policy if exists "Candidates manage own employment" on public.candidate_employment;
create policy "Candidates manage own employment" on public.candidate_employment
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

create table if not exists public.candidate_education (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  degree text not null,
  institution text,
  year_of_passing text,
  grade text,
  created_at timestamptz default now()
);
alter table public.candidate_education enable row level security;
drop policy if exists "Candidates manage own education" on public.candidate_education;
create policy "Candidates manage own education" on public.candidate_education
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

create table if not exists public.candidate_accomplishments (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  title text not null,
  type text,
  description text,
  date_achieved date,
  created_at timestamptz default now()
);
alter table public.candidate_accomplishments enable row level security;
drop policy if exists "Candidates manage own accomplishments" on public.candidate_accomplishments;
create policy "Candidates manage own accomplishments" on public.candidate_accomplishments
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

create table if not exists public.candidate_languages (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  language_name text not null,
  proficiency text,
  created_at timestamptz default now()
);
alter table public.candidate_languages enable row level security;
drop policy if exists "Candidates manage own languages" on public.candidate_languages;
create policy "Candidates manage own languages" on public.candidate_languages
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
