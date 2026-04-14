begin;
create table if not exists public.edge_ip_denylist (
  id uuid primary key default gen_random_uuid(),
  ip_hash text not null unique,
  reason text not null default 'manual_block',
  is_active boolean not null default true,
  expires_at timestamptz null,
  created_at timestamptz not null default now(),
  created_by uuid null
);
alter table public.edge_ip_denylist enable row level security;
drop policy if exists edge_ip_denylist_admin_all on public.edge_ip_denylist;
create policy edge_ip_denylist_admin_all
  on public.edge_ip_denylist
  for all
  using (public.is_admin())
  with check (public.is_admin());
create index if not exists idx_edge_ip_denylist_active_v1
  on public.edge_ip_denylist(is_active, expires_at);
create or replace function public.is_edge_ip_denied_v1(p_ip_hash text)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists(
    select 1
    from public.edge_ip_denylist d
    where d.ip_hash = p_ip_hash
      and d.is_active = true
      and (d.expires_at is null or d.expires_at > now())
  );
$$;
grant all on function public.is_edge_ip_denied_v1(text) to authenticated;
grant all on function public.is_edge_ip_denied_v1(text) to service_role;
create or replace function public.upsert_user_location_prefs_v1(
  p_city text,
  p_district text,
  p_neighborhood text default null,
  p_mode text default 'auto',
  p_lat double precision default null,
  p_lng double precision default null
) returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid uuid := auth.uid();
  v_lat double precision := null;
  v_lng double precision := null;
begin
  if v_uid is null then
    return jsonb_build_object('ok', false, 'error', 'not_authenticated');
  end if;

  -- PII minimization: keep coarse location only if coordinates are sent.
  if p_lat is not null then
    v_lat := round((p_lat::numeric), 3)::double precision;
  end if;
  if p_lng is not null then
    v_lng := round((p_lng::numeric), 3)::double precision;
  end if;

  insert into public.user_location_prefs (
    user_id, city, district, neighborhood, mode, lat, lng, updated_at
  )
  values (
    v_uid,
    trim(coalesce(p_city, '')),
    trim(coalesce(p_district, '')),
    nullif(trim(coalesce(p_neighborhood, '')), ''),
    coalesce(nullif(trim(coalesce(p_mode, '')), ''), 'auto'),
    v_lat,
    v_lng,
    now()
  )
  on conflict (user_id) do update
    set city = excluded.city,
        district = excluded.district,
        neighborhood = excluded.neighborhood,
        mode = excluded.mode,
        lat = excluded.lat,
        lng = excluded.lng,
        updated_at = now();

  return jsonb_build_object('ok', true);
end;
$$;
grant all on function public.upsert_user_location_prefs_v1(text, text, text, text, double precision, double precision) to authenticated;
grant all on function public.upsert_user_location_prefs_v1(text, text, text, text, double precision, double precision) to service_role;
create or replace function public.upsert_user_location_prefs_v1(
  p_city text,
  p_district text,
  p_neighborhood text default null,
  p_mode text default 'auto'
) returns jsonb
language sql
security definer
set search_path = public
as $$
  select public.upsert_user_location_prefs_v1(
    p_city,
    p_district,
    p_neighborhood,
    p_mode,
    null,
    null
  );
$$;
grant all on function public.upsert_user_location_prefs_v1(text, text, text, text) to authenticated;
grant all on function public.upsert_user_location_prefs_v1(text, text, text, text) to service_role;
commit;
