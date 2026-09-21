-- Real identity verification via Sandbox's Aadhaar/DigiLocker API, replacing
-- any decorative "HYLO VERIFIED" state with an actual verified status.
-- Only server-side Edge Functions (using the service role key) may write to
-- this table -- candidates and recruiters both get read-only access, so a
-- user can never self-certify as verified from the client.
create table if not exists public.identity_verifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  verification_type text not null default 'aadhaar_digilocker',
  status text not null default 'pending' check (status in ('pending','verified','failed')),
  masked_id text,
  full_name text,
  provider_session_id text,
  provider_reference_id text,
  verified_at timestamptz,
  created_at timestamptz not null default now()
);

alter table public.identity_verifications enable row level security;

create policy "Candidates can view their own verification"
  on public.identity_verifications for select
  using (auth.uid() = user_id);

create policy "Recruiters can view all verifications"
  on public.identity_verifications for select
  using (is_recruiter());
