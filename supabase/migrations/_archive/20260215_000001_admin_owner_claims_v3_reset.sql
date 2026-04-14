do $$
declare
  r record;
begin
  for r in
    select
      n.nspname as schema_name,
      p.proname as function_name,
      pg_get_function_identity_arguments(p.oid) as args
    from pg_proc p
    join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'public'
      and p.proname = 'admin_list_owner_claims_v3'
  loop
    execute format('drop function if exists %I.%I(%s);', r.schema_name, r.function_name, r.args);
  end loop;
end $$;
create or replace function public.admin_list_owner_claims_v3(
  p_status text default null,
  p_limit integer default 50,
  p_offset integer default 0,
  p_sla_only boolean default false,
  p_assigned text default null,
  p_q text default null
)
returns table(
  claim_id uuid,
  status text,
  created_at timestamptz,
  age_days double precision,
  sla_breached boolean,
  business_id uuid,
  full_name text,
  phone text,
  evidence_url text,
  note text,
  admin_note text,
  assigned_to uuid,
  assigned_at timestamptz,
  auto_moderated boolean
)
language sql
stable
security definer
set search_path to 'public'
as $function$
  select
    c.id as claim_id,
    c.status::text,
    c.created_at,
    extract(epoch from (now() - c.created_at)) / 86400.0 as age_days,
    (c.status = 'pending' and c.created_at < now() - interval '72 hours') as sla_breached,
    c.business_id,
    c.full_name,
    c.phone,
    c.evidence_url,
    c.note,
    c.admin_note,
    c.handled_by as assigned_to,
    c.handled_at as assigned_at,
    coalesce(c.auto_moderated, false) as auto_moderated
  from public.owner_claims c
  where public.is_admin()
    and (
      p_status is null
      or p_status = ''
      or c.status::text = p_status
    )
    and (
      p_assigned is null
      or p_assigned = ''
      or (p_assigned = 'me' and c.handled_by = auth.uid())
      or (p_assigned = 'unassigned' and c.handled_by is null)
      or c.handled_by::text = p_assigned
    )
    and (
      p_q is null
      or p_q = ''
      or c.id::text ilike ('%' || p_q || '%')
      or coalesce(c.full_name, '') ilike ('%' || p_q || '%')
      or coalesce(c.phone, '') ilike ('%' || p_q || '%')
    )
    and (not p_sla_only or (c.status = 'pending' and c.created_at < now() - interval '72 hours'))
  order by (c.status = 'pending') desc, c.created_at asc
  limit greatest(p_limit, 0) offset greatest(p_offset, 0);
$function$;
