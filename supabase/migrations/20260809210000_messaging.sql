create table if not exists public.conversations (
  id uuid primary key default gen_random_uuid(),
  candidate_id uuid not null references public.profiles(id) on delete cascade,
  recruiter_id uuid not null references public.profiles(id) on delete cascade,
  job_title text,
  company_name text,
  created_at timestamptz not null default now(),
  last_message_at timestamptz not null default now(),
  unique(candidate_id, recruiter_id)
);

create table if not exists public.messages (
  id uuid primary key default gen_random_uuid(),
  conversation_id uuid not null references public.conversations(id) on delete cascade,
  sender_id uuid not null references public.profiles(id) on delete cascade,
  body text not null,
  created_at timestamptz not null default now(),
  read_at timestamptz
);

alter table public.conversations enable row level security;
alter table public.messages enable row level security;

create policy "Participants can view their conversations"
  on public.conversations for select
  using (auth.uid() = candidate_id or auth.uid() = recruiter_id);

create policy "Participants can create conversations"
  on public.conversations for insert
  with check (auth.uid() = candidate_id or auth.uid() = recruiter_id);

create policy "Participants can update their conversations"
  on public.conversations for update
  using (auth.uid() = candidate_id or auth.uid() = recruiter_id);

create policy "Participants can view messages in their conversations"
  on public.messages for select
  using (
    exists (
      select 1 from public.conversations c
      where c.id = messages.conversation_id
        and (c.candidate_id = auth.uid() or c.recruiter_id = auth.uid())
    )
  );

create policy "Participants can send messages in their conversations"
  on public.messages for insert
  with check (
    sender_id = auth.uid()
    and exists (
      select 1 from public.conversations c
      where c.id = messages.conversation_id
        and (c.candidate_id = auth.uid() or c.recruiter_id = auth.uid())
    )
  );

alter publication supabase_realtime add table public.messages;
