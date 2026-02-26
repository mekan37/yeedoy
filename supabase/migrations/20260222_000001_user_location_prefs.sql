create table if not exists public.user_location_prefs (
  user_id uuid primary key references auth.users(id) on delete cascade,
  city text null,
  district text null,
  mode text not null default 'auto' check (mode in ('auto','manual')),
  updated_at timestamptz not null default now()
);

alter table public.user_location_prefs enable row level security;

drop policy if exists user_location_prefs_select_own on public.user_location_prefs;
create policy user_location_prefs_select_own on public.user_location_prefs
  for select using (user_id = auth.uid());

drop policy if exists user_location_prefs_insert_own on public.user_location_prefs;
create policy user_location_prefs_insert_own on public.user_location_prefs
  for insert with check (user_id = auth.uid());

drop policy if exists user_location_prefs_update_own on public.user_location_prefs;
create policy user_location_prefs_update_own on public.user_location_prefs
  for update using (user_id = auth.uid()) with check (user_id = auth.uid());

drop policy if exists user_location_prefs_delete_own on public.user_location_prefs;
create policy user_location_prefs_delete_own on public.user_location_prefs
  for delete using (user_id = auth.uid());

create or replace function public.upsert_user_location_prefs_v1(
  p_city text,
  p_district text,
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

  insert into public.user_location_prefs (user_id, city, district, mode, updated_at)
  values (auth.uid(), p_city, p_district, p_mode, now())
  on conflict (user_id) do update
  set city = excluded.city,
      district = excluded.district,
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

  select city, district, mode, updated_at
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
      'mode', v_row.mode,
      'updated_at', v_row.updated_at
    )
  );
end;
$$;
