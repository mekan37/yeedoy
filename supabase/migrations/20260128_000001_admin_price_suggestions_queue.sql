do $$
begin
  if not exists (
    select 1 from pg_type where typname = 'menu_price_suggestion_status'
  ) then
    create type public.menu_price_suggestion_status as enum (
      'pending', 'approved', 'rejected'
    );
  end if;
end $$;

create table if not exists public.menu_item_price_suggestions (
  id uuid primary key default gen_random_uuid(),
  menu_item_id uuid not null references public.menu_items(id) on delete cascade,
  business_id uuid not null references public.businesses(id) on delete cascade,
  suggested_price_cents integer not null,
  currency text not null default 'TRY',
  note text null,
  created_by uuid not null,
  created_at timestamptz default now(),
  status public.menu_price_suggestion_status not null default 'pending',
  handled_by uuid null,
  handled_at timestamptz null,
  approved_by uuid null,
  approved_at timestamptz null
);

create or replace function public.admin_list_menu_price_suggestions_v2(
  p_status text default null,
  p_limit integer default 30,
  p_offset integer default 0,
  p_sla_only boolean default false,
  p_assigned text default null
)
returns table(
  suggestion_id uuid,
  status text,
  created_at timestamp with time zone,
  sla_breached boolean,
  business_id uuid,
  business_name text,
  city text,
  district text,
  menu_item_id uuid,
  item_name text,
  current_price_cents integer,
  suggested_price_cents integer,
  currency text,
  created_by uuid,
  assigned_to uuid,
  assigned_at timestamp with time zone
)
language sql
stable
security definer
set search_path to 'public'
as $function$
  select
    s.id as suggestion_id,
    s.status::text,
    s.created_at,
    (s.status='pending' and s.created_at < now() - interval '48 hours') as sla_breached,

    b.id as business_id,
    b.name as business_name,
    b.city,
    b.district,

    mi.id as menu_item_id,
    mi.name as item_name,
    mi.price_cents as current_price_cents,
    s.suggested_price_cents,
    s.currency,

    s.created_by,
    s.handled_by as assigned_to,
    s.handled_at as assigned_at
  from public.menu_item_price_suggestions s
  join public.menu_items mi on mi.id = s.menu_item_id
  join public.businesses b on b.id = s.business_id
  where public.is_admin()
    and (
      p_status is null
      or p_status = ''
      or s.status::text = p_status
    )
    and (
      p_assigned is null
      or p_assigned = ''
      or (p_assigned = 'me' and s.handled_by = auth.uid())
      or (p_assigned = 'unassigned' and s.handled_by is null)
      or s.handled_by::text = p_assigned
    )
    and (not p_sla_only or (s.status='pending' and s.created_at < now() - interval '48 hours'))
  order by (s.status='pending') desc, s.created_at asc
  limit greatest(p_limit,0) offset greatest(p_offset,0);
$function$;

create or replace function public.admin_export_menu_price_suggestions_csv_v1(
  p_status text default null,
  p_sla_only boolean default false,
  p_assigned text default null
)
returns text
language plpgsql
security definer
set search_path to 'public'
as $function$
declare
  v_csv text;
begin
  if not public.is_admin() then
    raise exception 'not_admin';
  end if;

  select string_agg(line, E'\n') into v_csv
  from (
    select
      'id,created_at,status,business_id,business_name,menu_item_id,item_name,current_price_cents,suggested_price_cents,currency,created_by,handled_by,handled_at,note' as line
    union all
    select
      concat_ws(',',
        s.id::text,
        to_char(s.created_at, 'YYYY-MM-DD"T"HH24:MI:SS"Z"'),
        replace(coalesce(s.status::text,''), ',', ' '),
        coalesce(s.business_id::text,''),
        replace(coalesce(b.name,''), ',', ' '),
        coalesce(s.menu_item_id::text,''),
        replace(coalesce(mi.name,''), ',', ' '),
        coalesce(mi.price_cents::text,''),
        coalesce(s.suggested_price_cents::text,''),
        replace(coalesce(s.currency,''), ',', ' '),
        coalesce(s.created_by::text,''),
        coalesce(s.handled_by::text,''),
        coalesce(to_char(s.handled_at, 'YYYY-MM-DD"T"HH24:MI:SS"Z"'),''),
        replace(coalesce(s.note,''), E'\n', ' ')
      ) as line
    from public.menu_item_price_suggestions s
    join public.menu_items mi on mi.id = s.menu_item_id
    join public.businesses b on b.id = s.business_id
    where (p_status is null or p_status = '' or s.status::text = p_status)
      and (not p_sla_only or (s.status='pending' and s.created_at < now() - interval '48 hours'))
      and (
        p_assigned is null
        or p_assigned = ''
        or (p_assigned = 'me' and s.handled_by = auth.uid())
        or (p_assigned = 'unassigned' and s.handled_by is null)
        or s.handled_by::text = p_assigned
      )
    order by s.created_at desc
  ) t;

  perform public.log_admin_action_v1(
    'price_suggestion.export_csv',
    'menu_item_price_suggestions',
    null,
    jsonb_build_object('status', p_status, 'sla_only', p_sla_only, 'assigned', p_assigned)
  );

  return v_csv;
end;
$function$;
