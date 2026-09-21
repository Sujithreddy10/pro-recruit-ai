-- Keep candidate profile forms consistent with the rest of the app's
-- simple text-field-only inputs (no date pickers used anywhere else),
-- so free-form text like "Jan 2023" or "Present" works instead of
-- requiring strict date values.
alter table public.candidate_employment
  alter column start_date type text using start_date::text,
  alter column end_date type text using end_date::text;

alter table public.candidate_accomplishments
  alter column date_achieved type text using date_achieved::text;
