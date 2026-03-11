begin;

create or replace function public.admin_list_offline_mutation_outcomes_v1(
  p_hours integer default 24,
  p_limit integer default 100
)
returns table(
  created_at timestamptz,
  source text,
  kind text,
  disposition text,
  retry_category text,
  retry_count integer,
  detail text,
  user_id uuid,
  client_id text
)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_hours integer := greatest(coalesce(p_hours, 24), 1);
  v_limit integer := least(greatest(coalesce(p_limit, 100), 1), 500);
begin
  if not public.is_admin() then
    raise exception 'not_authorized';
  end if;

  return query
  select
    e.created_at,
    coalesce(e.source, '') as source,
    coalesce(e.meta ->> 'kind', 'unknown') as kind,
    coalesce(e.meta ->> 'disposition', 'unknown') as disposition,
    nullif(e.meta ->> 'retry_category', '') as retry_category,
    case
      when nullif(e.meta ->> 'retry_count', '') is null then null
      else (e.meta ->> 'retry_count')::integer
    end as retry_count,
    nullif(e.meta ->> 'detail', '') as detail,
    e.user_id,
    e.client_id
  from public.analytics_events e
  where e.event_name = 'offline_mutation_outcome'
    and e.created_at >= now() - make_interval(hours => v_hours)
  order by e.created_at desc
  limit v_limit;
end;
$$;

grant all on function public.admin_list_offline_mutation_outcomes_v1(
  integer,
  integer
) to authenticated;

grant all on function public.admin_list_offline_mutation_outcomes_v1(
  integer,
  integer
) to service_role;

commit;
