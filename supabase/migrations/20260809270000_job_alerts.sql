create table if not exists public.job_alert_preferences (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade unique,
  locations text[] not null default '{}',
  work_modes text[] not null default '{}',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.job_alert_preferences enable row level security;

create policy "Candidates manage own alert preferences"
  on public.job_alert_preferences for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create or replace function public.notify_job_alert()
returns trigger as $$
begin
  perform net.http_post(
    url := 'https://zdcaranlkgscrvikoxsc.supabase.co/functions/v1/notify-job-alert',
    headers := jsonb_build_object('Content-Type', 'application/json'),
    body := jsonb_build_object('record', row_to_json(new))
  );
  return new;
end;
$$ language plpgsql security definer set search_path = public;

drop trigger if exists on_new_job_alert on public.jobs;
create trigger on_new_job_alert
after insert on public.jobs
for each row execute function public.notify_job_alert();
