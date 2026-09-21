alter table public.jobs add column if not exists view_count integer not null default 0;

create or replace function public.increment_job_view(job_id_param uuid)
returns void as $$
begin
  update public.jobs set view_count = view_count + 1 where id = job_id_param;
end;
$$ language plpgsql security definer set search_path = public;

grant execute on function public.increment_job_view(uuid) to authenticated;
