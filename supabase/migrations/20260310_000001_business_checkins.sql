create table if not exists public.business_checkins (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses(id) on delete cascade,
  menu_id uuid null references public.menus(id) on delete set null,
  table_no text null,
  client_id text not null,
  user_id uuid null,
  created_at timestamptz not null default now()
);

create index if not exists business_checkins_business_created_idx
  on public.business_checkins (business_id, created_at desc);

create index if not exists business_checkins_client_created_idx
  on public.business_checkins (client_id, created_at desc);

alter table public.business_checkins enable row level security;

drop policy if exists business_checkins_admin_all on public.business_checkins;
create policy business_checkins_admin_all
  on public.business_checkins
  for all
  using (public.is_admin())
  with check (public.is_admin());

create or replace function public.log_checkin_v1(
  p_business_id uuid,
  p_menu_id uuid default null,
  p_table_no text default null,
  p_client_id text default null
) returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $function$
declare
  v_client_id text := nullif(trim(coalesce(p_client_id, '')), '');
  v_table_no text := nullif(trim(coalesce(p_table_no, '')), '');
  v_exists uuid;
begin
  if p_business_id is null then
    return jsonb_build_object('ok', false, 'code', 'invalid_business');
  end if;

  if v_client_id is null then
    return jsonb_build_object('ok', false, 'code', 'client_required');
  end if;

  if not exists (
    select 1 from public.businesses b where b.id = p_business_id
  ) then
    return jsonb_build_object('ok', false, 'code', 'business_not_found');
  end if;

  if p_menu_id is not null and not exists (
    select 1 from public.menus m where m.id = p_menu_id and m.business_id = p_business_id
  ) then
    return jsonb_build_object('ok', false, 'code', 'menu_mismatch');
  end if;

  select c.id into v_exists
  from public.business_checkins c
  where c.business_id = p_business_id
    and c.client_id = v_client_id
    and coalesce(c.table_no, '') = coalesce(v_table_no, '')
    and c.created_at >= now() - interval '10 minutes'
  limit 1;

  if v_exists is not null then
    return jsonb_build_object('ok', true, 'deduped', true, 'id', v_exists);
  end if;

  insert into public.business_checkins(
    business_id,
    menu_id,
    table_no,
    client_id,
    user_id
  )
  values (
    p_business_id,
    p_menu_id,
    v_table_no,
    v_client_id,
    auth.uid()
  )
  returning id into v_exists;

  return jsonb_build_object('ok', true, 'id', v_exists);
end;
$function$;

create or replace function public.get_business_recent_checkins_v1(
  p_business_id uuid,
  p_hours int default 2
) returns jsonb
language sql
stable
security definer
set search_path to 'public'
as $$
  select jsonb_build_object(
    'count',
    coalesce((
      select count(*)::int
      from public.business_checkins c
      where c.business_id = p_business_id
        and c.created_at >= now() - make_interval(hours => greatest(p_hours, 1))
    ), 0)
  );
$$;

create or replace function public.has_recent_checkin_v1(
  p_business_id uuid,
  p_client_id text,
  p_window_minutes int default 120
) returns boolean
language sql
stable
security definer
set search_path to 'public'
as $$
  select exists(
    select 1
    from public.business_checkins c
    where c.business_id = p_business_id
      and c.client_id = nullif(trim(coalesce(p_client_id, '')), '')
      and c.created_at >= now() - make_interval(mins => greatest(p_window_minutes, 1))
  );
$$;
