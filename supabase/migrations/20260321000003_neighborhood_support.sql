alter table public.businesses
  add column if not exists neighborhood text;

alter table public.user_location_prefs
  add column if not exists neighborhood text;

create or replace function public.upsert_user_location_prefs_v1(
  p_city text,
  p_district text,
  p_neighborhood text default null,
  p_mode text default 'manual'
)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $$
begin
  if auth.uid() is null then
    return jsonb_build_object('ok', false, 'error', 'not_authenticated');
  end if;

  if p_city is null or btrim(p_city) = '' or p_district is null or btrim(p_district) = '' then
    return jsonb_build_object('ok', false, 'error', 'invalid_location');
  end if;

  insert into public.user_location_prefs (user_id, city, district, neighborhood, mode, updated_at)
  values (auth.uid(), p_city, p_district, nullif(trim(p_neighborhood), ''), p_mode, now())
  on conflict (user_id) do update
  set city = excluded.city,
      district = excluded.district,
      neighborhood = excluded.neighborhood,
      mode = excluded.mode,
      updated_at = now();

  return jsonb_build_object('ok', true);
end;
$$;

create or replace function public.get_user_location_prefs_v1()
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  v_row record;
begin
  if auth.uid() is null then
    return jsonb_build_object('ok', false, 'error', 'not_authenticated');
  end if;

  select city, district, neighborhood, mode, updated_at
    into v_row
  from public.user_location_prefs
  where user_id = auth.uid();

  if not found then
    return jsonb_build_object('ok', true, 'data', null);
  end if;

  return jsonb_build_object(
    'ok', true,
    'data', jsonb_build_object(
      'city', v_row.city,
      'district', v_row.district,
      'neighborhood', v_row.neighborhood,
      'mode', v_row.mode,
      'updated_at', v_row.updated_at
    )
  );
end;
$$;

grant all on function public.upsert_user_location_prefs_v1(text, text, text, text) to anon;
grant all on function public.upsert_user_location_prefs_v1(text, text, text, text) to authenticated;
grant all on function public.upsert_user_location_prefs_v1(text, text, text, text) to service_role;

grant all on function public.get_user_location_prefs_v1() to anon;
grant all on function public.get_user_location_prefs_v1() to authenticated;
grant all on function public.get_user_location_prefs_v1() to service_role;
