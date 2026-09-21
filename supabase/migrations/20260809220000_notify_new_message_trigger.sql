create extension if not exists pg_net;

create or replace function public.notify_new_message()
returns trigger as $$
begin
  perform net.http_post(
    url := 'https://zdcaranlkgscrvikoxsc.supabase.co/functions/v1/notify-new-message',
    headers := jsonb_build_object('Content-Type', 'application/json'),
    body := jsonb_build_object('record', row_to_json(new))
  );
  return new;
end;
$$ language plpgsql security definer set search_path = public;

drop trigger if exists on_new_message_notify on public.messages;
create trigger on_new_message_notify
after insert on public.messages
for each row execute function public.notify_new_message();
