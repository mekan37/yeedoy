create table if not exists public.photo_missions (
  id uuid primary key default gen_random_uuid(),
  city text null,
  district text null,
  mission_type text not null,
  business_id uuid not null references public.businesses(id) on delete cascade,
  reward_points int not null default 10,
  expires_at timestamptz null,
  created_at timestamptz not null default now()
);
do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'photo_missions_type_check'
      and conrelid = 'public.photo_missions'::regclass
  ) then
    alter table public.photo_missions
      add constraint photo_missions_type_check
      check (mission_type in ('missing_menu_photo','stale_menu_photo'));
  end if;
end $$;
create index if not exists photo_missions_city_idx
  on public.photo_missions (city, district, created_at desc);
create index if not exists photo_missions_business_idx
  on public.photo_missions (business_id, mission_type, created_at desc);
create table if not exists public.user_mission_claims (
  id uuid primary key default gen_random_uuid(),
  mission_id uuid not null references public.photo_missions(id) on delete cascade,
  user_id uuid not null,
  status text not null default 'claimed',
  photo_id uuid null references public.menu_item_photos(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'user_mission_claims_status_check'
      and conrelid = 'public.user_mission_claims'::regclass
  ) then
    alter table public.user_mission_claims
      add constraint user_mission_claims_status_check
      check (status in ('claimed','submitted','approved','rejected'));
  end if;
end $$;
create unique index if not exists user_mission_claims_unique
  on public.user_mission_claims (mission_id, user_id);
create index if not exists user_mission_claims_user_idx
  on public.user_mission_claims (user_id, status, created_at desc);
create table if not exists public.user_points (
  user_id uuid primary key,
  points int not null default 0,
  updated_at timestamptz not null default now()
);
alter table public.photo_missions enable row level security;
alter table public.user_mission_claims enable row level security;
alter table public.user_points enable row level security;
drop policy if exists photo_missions_read_all on public.photo_missions;
create policy photo_missions_read_all
  on public.photo_missions
  for select
  using (true);
drop policy if exists user_mission_claims_owner_select on public.user_mission_claims;
create policy user_mission_claims_owner_select
  on public.user_mission_claims
  for select
  using (user_id = auth.uid());
drop policy if exists user_mission_claims_owner_write on public.user_mission_claims;
create policy user_mission_claims_owner_write
  on public.user_mission_claims
  for insert
  with check (user_id = auth.uid());
drop policy if exists user_mission_claims_owner_update on public.user_mission_claims;
create policy user_mission_claims_owner_update
  on public.user_mission_claims
  for update
  using (user_id = auth.uid())
  with check (user_id = auth.uid());
drop policy if exists user_mission_claims_admin_all on public.user_mission_claims;
create policy user_mission_claims_admin_all
  on public.user_mission_claims
  for all
  using (public.is_admin());
drop policy if exists user_points_owner_select on public.user_points;
create policy user_points_owner_select
  on public.user_points
  for select
  using (user_id = auth.uid());
drop policy if exists user_points_admin_all on public.user_points;
create policy user_points_admin_all
  on public.user_points
  for all
  using (public.is_admin());
create or replace function public.get_photo_missions_v1(
  p_city text default null,
  p_district text default null,
  p_limit int default 20
) returns table(
  mission_id uuid,
  business_id uuid,
  business_name text,
  city text,
  district text,
  mission_type text,
  reward_points int,
  expires_at timestamptz,
  created_at timestamptz,
  my_status text,
  my_claim_id uuid
)
language sql
stable
security definer
set search_path to 'public'
as $$
  select
    m.id as mission_id,
    m.business_id,
    b.name as business_name,
    coalesce(m.city, b.city) as city,
    coalesce(m.district, b.district) as district,
    m.mission_type,
    m.reward_points,
    m.expires_at,
    m.created_at,
    c.status as my_status,
    c.id as my_claim_id
  from public.photo_missions m
  join public.businesses b on b.id = m.business_id
  left join public.user_mission_claims c
    on c.mission_id = m.id and c.user_id = auth.uid()
  where (m.expires_at is null or m.expires_at >= now())
    and (p_city is null or coalesce(m.city, b.city) = p_city)
    and (p_district is null or coalesce(m.district, b.district) = p_district)
  order by m.created_at desc
  limit greatest(p_limit, 0);
$$;
create or replace function public.claim_mission_v1(
  p_mission_id uuid
) returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $function$
declare
  v_exists uuid;
begin
  if auth.uid() is null then
    return jsonb_build_object('ok', false, 'code', 'not_authenticated');
  end if;

  select id into v_exists
  from public.photo_missions
  where id = p_mission_id
    and (expires_at is null or expires_at >= now());

  if v_exists is null then
    return jsonb_build_object('ok', false, 'code', 'not_found');
  end if;

  insert into public.user_mission_claims(mission_id, user_id, status)
  values (p_mission_id, auth.uid(), 'claimed')
  on conflict (mission_id, user_id) do update
    set updated_at = now()
  returning id into v_exists;

  return jsonb_build_object('ok', true, 'claim_id', v_exists);
end;
$function$;
create or replace function public.submit_mission_proof_v1(
  p_mission_id uuid,
  p_photo_id uuid
) returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $function$
declare
  v_claim_id uuid;
  v_business_id uuid;
  v_photo_business uuid;
begin
  if auth.uid() is null then
    return jsonb_build_object('ok', false, 'code', 'not_authenticated');
  end if;

  select business_id into v_business_id
  from public.photo_missions
  where id = p_mission_id;

  if v_business_id is null then
    return jsonb_build_object('ok', false, 'code', 'not_found');
  end if;

  select business_id into v_photo_business
  from public.menu_item_photos
  where id = p_photo_id;

  if v_photo_business is null or v_photo_business <> v_business_id then
    return jsonb_build_object('ok', false, 'code', 'invalid_photo');
  end if;

  select id into v_claim_id
  from public.user_mission_claims
  where mission_id = p_mission_id and user_id = auth.uid();

  if v_claim_id is null then
    return jsonb_build_object('ok', false, 'code', 'not_claimed');
  end if;

  update public.user_mission_claims
  set status = 'submitted',
      photo_id = p_photo_id,
      updated_at = now()
  where id = v_claim_id;

  return jsonb_build_object('ok', true, 'claim_id', v_claim_id);
end;
$function$;
create or replace function public.admin_list_mission_claims_v1(
  p_status text default 'submitted',
  p_limit int default 50,
  p_offset int default 0
) returns table(
  claim_id uuid,
  status text,
  created_at timestamptz,
  mission_id uuid,
  mission_type text,
  business_id uuid,
  business_name text,
  user_id uuid,
  photo_id uuid,
  reward_points int
)
language sql
stable
security definer
set search_path to 'public'
as $$
  select
    c.id as claim_id,
    c.status,
    c.created_at,
    m.id as mission_id,
    m.mission_type,
    m.business_id,
    b.name as business_name,
    c.user_id,
    c.photo_id,
    m.reward_points
  from public.user_mission_claims c
  join public.photo_missions m on m.id = c.mission_id
  join public.businesses b on b.id = m.business_id
  where (p_status is null or c.status = p_status)
  order by c.created_at desc
  limit greatest(p_limit, 0)
  offset greatest(p_offset, 0);
$$;
create or replace function public.admin_approve_mission_claim_v1(
  p_claim_id uuid
) returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $function$
declare
  v_user_id uuid;
  v_points int;
begin
  if not public.is_admin() then
    return jsonb_build_object('ok', false, 'code', 'not_admin');
  end if;

  select c.user_id, m.reward_points
    into v_user_id, v_points
  from public.user_mission_claims c
  join public.photo_missions m on m.id = c.mission_id
  where c.id = p_claim_id;

  if v_user_id is null then
    return jsonb_build_object('ok', false, 'code', 'not_found');
  end if;

  update public.user_mission_claims
  set status = 'approved',
      updated_at = now()
  where id = p_claim_id;

  insert into public.user_points(user_id, points, updated_at)
  values (v_user_id, coalesce(v_points, 0), now())
  on conflict (user_id) do update
    set points = public.user_points.points + coalesce(excluded.points, 0),
        updated_at = now();

  return jsonb_build_object('ok', true);
end;
$function$;
create or replace function public.admin_reject_mission_claim_v1(
  p_claim_id uuid
) returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $function$
begin
  if not public.is_admin() then
    return jsonb_build_object('ok', false, 'code', 'not_admin');
  end if;

  update public.user_mission_claims
  set status = 'rejected',
      updated_at = now()
  where id = p_claim_id;

  return jsonb_build_object('ok', true);
end;
$function$;
create or replace function public.get_my_points_v1()
returns jsonb
language sql
stable
security definer
set search_path to 'public'
as $$
  select jsonb_build_object(
    'points',
    coalesce((select points from public.user_points where user_id = auth.uid()), 0)
  );
$$;
create or replace function public.generate_photo_missions_v1(
  p_city text default null,
  p_district text default null,
  p_limit int default 200
) returns int
language plpgsql
security definer
set search_path to 'public'
as $function$
declare
  v_count int := 0;
  v_add int := 0;
begin
  insert into public.photo_missions(business_id, city, district, mission_type, reward_points, expires_at)
  select
    b.id,
    b.city,
    b.district,
    'missing_menu_photo',
    10,
    now() + interval '14 days'
  from public.businesses b
  left join public.business_media bm on bm.business_id = b.id
  where bm.id is null
    and (p_city is null or b.city = p_city)
    and (p_district is null or b.district = p_district)
    and not exists (
      select 1
      from public.photo_missions m
      where m.business_id = b.id
        and m.mission_type = 'missing_menu_photo'
        and (m.expires_at is null or m.expires_at >= now())
    )
  limit greatest(p_limit, 0);

  get diagnostics v_count = row_count;

  insert into public.photo_missions(business_id, city, district, mission_type, reward_points, expires_at)
  select
    b.id,
    b.city,
    b.district,
    'stale_menu_photo',
    10,
    now() + interval '14 days'
  from public.businesses b
  join (
    select business_id, max(created_at) as last_photo_at
    from public.business_media
    group by business_id
  ) bm on bm.business_id = b.id
  where bm.last_photo_at < now() - interval '30 days'
    and (p_city is null or b.city = p_city)
    and (p_district is null or b.district = p_district)
    and not exists (
      select 1
      from public.photo_missions m
      where m.business_id = b.id
        and m.mission_type = 'stale_menu_photo'
        and (m.expires_at is null or m.expires_at >= now())
    )
  limit greatest(p_limit, 0);

  get diagnostics v_add = row_count;
  v_count := v_count + v_add;
  return v_count;
end;
$function$;
create or replace function public.add_menu_item_photo_v1(
  p_menu_item_id uuid,
  p_url text,
  p_url_large text default null,
  p_url_thumb text default null,
  p_provider text default 'wp'
) returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $function$
declare
  v_business_id uuid;
  v_photo_id uuid;
begin
  if auth.uid() is null then
    return jsonb_build_object('ok', false, 'error', 'not_authenticated');
  end if;

  select business_id into v_business_id
  from public.menu_items
  where id = p_menu_item_id;

  if v_business_id is null then
    return jsonb_build_object('ok', false, 'error', 'not_found');
  end if;

  insert into public.menu_item_photos(
    menu_item_id,
    business_id,
    url,
    url_large,
    url_thumb,
    provider,
    created_by
  )
  values (
    p_menu_item_id,
    v_business_id,
    p_url,
    p_url_large,
    p_url_thumb,
    p_provider,
    auth.uid()
  )
  returning id into v_photo_id;

  return jsonb_build_object('ok', true, 'photo_id', v_photo_id);
end;
$function$;
