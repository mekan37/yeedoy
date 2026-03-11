create table public.business_amenities (
  id uuid primary key default gen_random_uuid(),
  key text not null unique,
  label text not null,
  icon text not null,
  created_at timestamp with time zone default now()
);
insert into public.business_amenities (key, label, icon)
values
  ('parking', 'Otopark', 'parking'),
  ('kids_area', 'Çocuk Alanı', 'kids_area'),
  ('wifi', 'Wi‑Fi', 'wifi'),
  ('pet_friendly', 'Pet Friendly', 'pet_friendly'),
  ('smoking_area', 'Sigara Alanı', 'smoking_area'),
  ('outdoor_seating', 'Dış Mekan', 'outdoor_seating'),
  ('alcohol', 'Alkol', 'alcohol')
on conflict (key) do nothing;
create table public.business_amenity_map (
  business_id uuid references public.businesses(id) on delete cascade,
  amenity_id uuid references public.business_amenities(id) on delete cascade,
  primary key (business_id, amenity_id)
);
alter table public.business_amenities enable row level security;
alter table public.business_amenity_map enable row level security;
do $$
begin
  if not exists (
    select 1 from pg_policies
    where schemaname = 'public'
      and tablename = 'business_amenities'
      and policyname = 'business_amenities_read_all'
  ) then
    execute 'create policy business_amenities_read_all on public.business_amenities
      for select using (true)';
  end if;

  if not exists (
    select 1 from pg_policies
    where schemaname = 'public'
      and tablename = 'business_amenities'
      and policyname = 'business_amenities_write_owner_admin'
  ) then
    execute 'create policy business_amenities_write_owner_admin on public.business_amenities
      for all
      using (public.is_admin())
      with check (public.is_admin())';
  end if;

  if not exists (
    select 1 from pg_policies
    where schemaname = 'public'
      and tablename = 'business_amenity_map'
      and policyname = 'business_amenity_map_read_all'
  ) then
    execute 'create policy business_amenity_map_read_all on public.business_amenity_map
      for select using (true)';
  end if;

  if not exists (
    select 1 from pg_policies
    where schemaname = 'public'
      and tablename = 'business_amenity_map'
      and policyname = 'business_amenity_map_write_owner_admin'
  ) then
    execute 'create policy business_amenity_map_write_owner_admin on public.business_amenity_map
      for all
      using (public.is_admin() or public.is_owner_of_business(business_id))
      with check (public.is_admin() or public.is_owner_of_business(business_id))';
  end if;
end $$;
create or replace function public.get_business_amenities_v1(
  p_business_id uuid
)
returns table(
  amenity_id uuid,
  key text,
  label text,
  icon text
)
language sql
stable
security definer
set search_path to 'public'
as $function$
  select
    a.id as amenity_id,
    a.key,
    a.label,
    a.icon
  from public.business_amenity_map m
  join public.business_amenities a on a.id = m.amenity_id
  where m.business_id = p_business_id
  order by a.label asc;
$function$;
create or replace function public.owner_update_business_amenities_v1(
  p_business_id uuid,
  p_amenity_keys text[]
)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $function$
begin
  if auth.uid() is null then
    return jsonb_build_object('ok', false, 'code', 'not_authenticated', 'message', 'Auth required');
  end if;

  if not (public.is_admin() or public.is_owner_of_business(p_business_id)) then
    return jsonb_build_object('ok', false, 'code', 'not_owner', 'message', 'Not owner');
  end if;

  delete from public.business_amenity_map
  where business_id = p_business_id;

  if p_amenity_keys is not null and array_length(p_amenity_keys, 1) is not null then
    insert into public.business_amenity_map (business_id, amenity_id)
    select p_business_id, a.id
    from public.business_amenities a
    where a.key = any(p_amenity_keys);
  end if;

  return jsonb_build_object('ok', true, 'business_id', p_business_id);
end;
$function$;
