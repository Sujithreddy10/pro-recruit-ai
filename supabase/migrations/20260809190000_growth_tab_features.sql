alter table public.ai_usage_log drop constraint if exists ai_usage_log_feature_check;
alter table public.ai_usage_log add constraint ai_usage_log_feature_check
  check (feature in ('intake-chat', 'match-score', 'generate-draft', 'skill-gap', 'interview-simulate', 'offer-negotiator', 'portfolio-architect'));
