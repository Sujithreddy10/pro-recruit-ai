create or replace function public.notify_interview_scheduled()
returns trigger as $$
begin
  perform net.http_post(
    url := 'https://zdcaranlkgscrvikoxsc.supabase.co/functions/v1/notify-interview-scheduled',
    headers := jsonb_build_object('Content-Type', 'application/json'),
    body := jsonb_build_object('record', row_to_json(new))
  );
  return new;
end;
$$ language plpgsql security definer set search_path = public;

drop trigger if exists on_interview_scheduled on public.interview_schedules;
create trigger on_interview_scheduled
after insert on public.interview_schedules
for each row execute function public.notify_interview_scheduled();
