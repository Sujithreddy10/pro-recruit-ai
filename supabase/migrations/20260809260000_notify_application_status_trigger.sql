create or replace function public.notify_application_status_change()
returns trigger as $$
begin
  if new.status is distinct from old.status then
    perform net.http_post(
      url := 'https://zdcaranlkgscrvikoxsc.supabase.co/functions/v1/notify-application-status',
      headers := jsonb_build_object('Content-Type', 'application/json'),
      body := jsonb_build_object('record', row_to_json(new))
    );
  end if;
  return new;
end;
$$ language plpgsql security definer set search_path = public;

drop trigger if exists on_application_status_change on public.applications;
create trigger on_application_status_change
after update on public.applications
for each row execute function public.notify_application_status_change();
