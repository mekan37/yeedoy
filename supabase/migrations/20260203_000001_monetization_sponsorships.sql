create table public.sponsorship_packages (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  surface text not null
    check (surface in ('discovery','business_page','stories','verified','premium')),
  duration_days integer not null,
  price_display text not null,
  is_active boolean not null default true,
  created_at timestamp with time zone default now()
);

create table public.sponsorships (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses(id) on delete cascade,
  package_id uuid not null references public.sponsorship_packages(id),
  surface text not null
    check (surface in ('discovery','business_page','stories')),
  status text not null
    check (status in ('pending','active','paused','ended')) default 'pending',
  starts_at timestamp with time zone,
  ends_at timestamp with time zone,
  targeting jsonb not null default '{}'::jsonb,
  daily_cap integer,
  total_cap integer,
  source text not null default 'manual',
  created_by uuid references public.admin_users(user_id),
  created_at timestamp with time zone not null default now(),
  updated_at timestamp with time zone not null default now(),
  constraint sponsorships_ends_after_starts
    check (starts_at is null or ends_at is null or ends_at >= starts_at)
);

create index sponsorships_surface_status_dates_idx
  on public.sponsorships (surface, status, starts_at, ends_at);

create index sponsorships_targeting_gin_idx
  on public.sponsorships using gin (targeting);

create table public.sponsorship_impressions_daily (
  id uuid primary key default gen_random_uuid(),
  sponsorship_id uuid not null references public.sponsorships(id) on delete cascade,
  day date not null,
  impressions_count integer not null default 0,
  unique_users_count integer not null default 0,
  created_at timestamp with time zone not null default now(),
  updated_at timestamp with time zone not null default now(),
  unique (sponsorship_id, day)
);

alter table public.businesses
  add column if not exists is_verified boolean not null default false,
  add column if not exists verified_at timestamp with time zone,
  add column if not exists verified_by uuid;

do $$
begin
  if not exists (
    select 1
    from information_schema.table_constraints
    where constraint_schema = 'public'
      and table_name = 'businesses'
      and constraint_name = 'businesses_verified_by_fkey'
  ) then
    alter table public.businesses
      add constraint businesses_verified_by_fkey
      foreign key (verified_by) references public.admin_users(user_id);
  end if;
end $$;

create table public.business_premium (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses(id) on delete cascade,
  tier text not null check (tier in ('verified','premium')),
  status text not null
    check (status in ('active','paused','ended')) default 'active',
  starts_at timestamp with time zone not null default now(),
  ends_at timestamp with time zone,
  source text not null default 'manual',
  created_by uuid references public.admin_users(user_id),
  created_at timestamp with time zone not null default now()
);

create unique index business_premium_active_unique
  on public.business_premium (business_id, tier)
  where status = 'active';

create table public.sponsorship_leads (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses(id) on delete cascade,
  owner_user_id uuid not null,
  phone text,
  message text,
  preferred_surface text not null
    check (preferred_surface in ('discovery','business_page','stories','verified','premium')),
  preferred_targeting jsonb not null default '{}'::jsonb,
  status text not null
    check (status in ('new','contacted','closed')) default 'new',
  created_at timestamp with time zone not null default now()
);

alter table public.sponsorship_packages enable row level security;
alter table public.sponsorships enable row level security;
alter table public.sponsorship_impressions_daily enable row level security;
alter table public.business_premium enable row level security;
alter table public.sponsorship_leads enable row level security;

do $$
begin
  if not exists (
    select 1 from pg_policies
    where schemaname = 'public'
      and tablename = 'sponsorship_packages'
      and policyname = 'sponsorship_packages_admin_all'
  ) then
    execute 'create policy sponsorship_packages_admin_all on public.sponsorship_packages
      for all using (public.is_admin()) with check (public.is_admin())';
  end if;

  if not exists (
    select 1 from pg_policies
    where schemaname = 'public'
      and tablename = 'sponsorships'
      and policyname = 'sponsorships_admin_all'
  ) then
    execute 'create policy sponsorships_admin_all on public.sponsorships
      for all using (public.is_admin()) with check (public.is_admin())';
  end if;

  if not exists (
    select 1 from pg_policies
    where schemaname = 'public'
      and tablename = 'sponsorship_impressions_daily'
      and policyname = 'sponsorship_impressions_admin_all'
  ) then
    execute 'create policy sponsorship_impressions_admin_all on public.sponsorship_impressions_daily
      for all using (public.is_admin()) with check (public.is_admin())';
  end if;

  if not exists (
    select 1 from pg_policies
    where schemaname = 'public'
      and tablename = 'business_premium'
      and policyname = 'business_premium_admin_all'
  ) then
    execute 'create policy business_premium_admin_all on public.business_premium
      for all using (public.is_admin()) with check (public.is_admin())';
  end if;

  if not exists (
    select 1 from pg_policies
    where schemaname = 'public'
      and tablename = 'sponsorship_leads'
      and policyname = 'sponsorship_leads_admin_all'
  ) then
    execute 'create policy sponsorship_leads_admin_all on public.sponsorship_leads
      for all using (public.is_admin()) with check (public.is_admin())';
  end if;

  if not exists (
    select 1 from pg_policies
    where schemaname = 'public'
      and tablename = 'sponsorship_leads'
      and policyname = 'sponsorship_leads_owner_read'
  ) then
    execute 'create policy sponsorship_leads_owner_read on public.sponsorship_leads
      for select using (owner_user_id = auth.uid())';
  end if;

  if not exists (
    select 1 from pg_policies
    where schemaname = 'public'
      and tablename = 'sponsorship_leads'
      and policyname = 'sponsorship_leads_owner_insert'
  ) then
    execute 'create policy sponsorship_leads_owner_insert on public.sponsorship_leads
      for insert with check (owner_user_id = auth.uid())';
  end if;
end $$;

create or replace function public.get_sponsored_businesses_v1(
  p_surface text,
  p_city text default null,
  p_district text default null,
  p_category text default null,
  p_limit integer default 6
)
returns table(
  business_id uuid,
  sponsorship_id uuid,
  priority integer,
  starts_at timestamp with time zone,
  ends_at timestamp with time zone,
  business_name text,
  city text,
  district text,
  category text
)
language sql
stable
security definer
set search_path to 'public'
as $function$
  select
    s.business_id,
    s.id as sponsorship_id,
    0 as priority,
    s.starts_at,
    s.ends_at,
    b.name as business_name,
    b.city,
    b.district,
    b.category
  from public.sponsorships s
  join public.businesses b on b.id = s.business_id
  where s.status = 'active'
    and s.surface = p_surface
    and (s.starts_at is null or s.starts_at <= now())
    and (s.ends_at is null or s.ends_at >= now())
    and (
      not (s.targeting ? 'city')
      or jsonb_typeof(s.targeting->'city') <> 'array'
      or jsonb_array_length(s.targeting->'city') = 0
      or (
        p_city is not null
        and exists (
          select 1 from jsonb_array_elements_text(s.targeting->'city') v
          where v = p_city
        )
      )
    )
    and (
      not (s.targeting ? 'district')
      or jsonb_typeof(s.targeting->'district') <> 'array'
      or jsonb_array_length(s.targeting->'district') = 0
      or (
        p_district is not null
        and exists (
          select 1 from jsonb_array_elements_text(s.targeting->'district') v
          where v = p_district
        )
      )
    )
    and (
      not (s.targeting ? 'category')
      or jsonb_typeof(s.targeting->'category') <> 'array'
      or jsonb_array_length(s.targeting->'category') = 0
      or (
        p_category is not null
        and exists (
          select 1 from jsonb_array_elements_text(s.targeting->'category') v
          where v = p_category
        )
      )
    )
  order by s.created_at desc
  limit greatest(p_limit, 0);
$function$;

create or replace function public.submit_sponsorship_lead_v1(
  p_business_id uuid,
  p_phone text,
  p_message text,
  p_preferred_surface text,
  p_preferred_targeting jsonb default '{}'::jsonb
)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $function$
declare
  v_id uuid;
begin
  if auth.uid() is null then
    return jsonb_build_object('ok', false, 'code', 'not_authenticated', 'message', 'Auth required');
  end if;

  if not public.is_owner_of_business(p_business_id) then
    return jsonb_build_object('ok', false, 'code', 'not_owner', 'message', 'Not owner');
  end if;

  insert into public.sponsorship_leads(
    business_id,
    owner_user_id,
    phone,
    message,
    preferred_surface,
    preferred_targeting
  )
  values (
    p_business_id,
    auth.uid(),
    nullif(trim(p_phone), ''),
    nullif(trim(p_message), ''),
    p_preferred_surface,
    coalesce(p_preferred_targeting, '{}'::jsonb)
  )
  returning id into v_id;

  return jsonb_build_object('ok', true, 'id', v_id, 'message', 'Submitted');
end;
$function$;

create or replace function public.admin_upsert_sponsorship_package_v1(
  p_id uuid default null,
  p_name text default null,
  p_surface text default null,
  p_duration_days integer default null,
  p_price_display text default null,
  p_is_active boolean default true
)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $function$
declare
  v_id uuid;
begin
  if not public.is_admin() then
    return jsonb_build_object('ok', false, 'code', 'not_admin', 'message', 'Not admin');
  end if;

  if p_id is null then
    insert into public.sponsorship_packages(
      name, surface, duration_days, price_display, is_active
    )
    values (
      p_name, p_surface, p_duration_days, p_price_display, p_is_active
    )
    returning id into v_id;
  else
    update public.sponsorship_packages
    set
      name = p_name,
      surface = p_surface,
      duration_days = p_duration_days,
      price_display = p_price_display,
      is_active = p_is_active
    where id = p_id
    returning id into v_id;
  end if;

  return jsonb_build_object('ok', true, 'id', v_id);
end;
$function$;

create or replace function public.admin_create_sponsorship_v1(
  p_business_id uuid,
  p_package_id uuid,
  p_surface text,
  p_starts_at timestamp with time zone default null,
  p_ends_at timestamp with time zone default null,
  p_targeting jsonb default '{}'::jsonb,
  p_daily_cap integer default null,
  p_total_cap integer default null
)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $function$
declare
  v_id uuid;
begin
  if not public.is_admin() then
    return jsonb_build_object('ok', false, 'code', 'not_admin', 'message', 'Not admin');
  end if;

  if p_starts_at is not null and p_ends_at is not null and p_ends_at < p_starts_at then
    return jsonb_build_object('ok', false, 'code', 'invalid', 'message', 'Invalid date range');
  end if;

  insert into public.sponsorships(
    business_id,
    package_id,
    surface,
    starts_at,
    ends_at,
    targeting,
    daily_cap,
    total_cap,
    source,
    created_by
  )
  values (
    p_business_id,
    p_package_id,
    p_surface,
    p_starts_at,
    p_ends_at,
    coalesce(p_targeting, '{}'::jsonb),
    p_daily_cap,
    p_total_cap,
    'manual',
    auth.uid()
  )
  returning id into v_id;

  return jsonb_build_object('ok', true, 'id', v_id);
end;
$function$;

create or replace function public.admin_set_sponsorship_status_v1(
  p_sponsorship_id uuid,
  p_status text
)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $function$
begin
  if not public.is_admin() then
    return jsonb_build_object('ok', false, 'code', 'not_admin', 'message', 'Not admin');
  end if;

  update public.sponsorships
  set status = p_status,
      updated_at = now()
  where id = p_sponsorship_id;

  return jsonb_build_object('ok', true, 'id', p_sponsorship_id);
end;
$function$;

create or replace function public.admin_list_sponsorships_v1(
  p_status text default null,
  p_surface text default null,
  p_limit integer default 50,
  p_offset integer default 0
)
returns table(
  sponsorship_id uuid,
  status text,
  surface text,
  created_at timestamp with time zone,
  business_id uuid,
  business_name text,
  city text,
  district text,
  package_id uuid,
  starts_at timestamp with time zone,
  ends_at timestamp with time zone,
  daily_cap integer,
  total_cap integer,
  source text,
  created_by uuid
)
language sql
stable
security definer
set search_path to 'public'
as $function$
  select
    s.id as sponsorship_id,
    s.status::text,
    s.surface::text,
    s.created_at,
    b.id as business_id,
    b.name as business_name,
    b.city,
    b.district,
    s.package_id,
    s.starts_at,
    s.ends_at,
    s.daily_cap,
    s.total_cap,
    s.source,
    s.created_by
  from public.sponsorships s
  join public.businesses b on b.id = s.business_id
  where public.is_admin()
    and (p_status is null or p_status = '' or s.status::text = p_status)
    and (p_surface is null or p_surface = '' or s.surface::text = p_surface)
  order by s.created_at desc
  limit greatest(p_limit, 0) offset greatest(p_offset, 0);
$function$;

create or replace function public.admin_list_sponsorship_leads_v1(
  p_status text default null,
  p_limit integer default 50,
  p_offset integer default 0
)
returns table(
  lead_id uuid,
  status text,
  created_at timestamp with time zone,
  business_id uuid,
  business_name text,
  city text,
  district text,
  owner_user_id uuid,
  phone text,
  message text,
  preferred_surface text,
  preferred_targeting jsonb
)
language sql
stable
security definer
set search_path to 'public'
as $function$
  select
    l.id as lead_id,
    l.status::text,
    l.created_at,
    b.id as business_id,
    b.name as business_name,
    b.city,
    b.district,
    l.owner_user_id,
    l.phone,
    l.message,
    l.preferred_surface::text,
    l.preferred_targeting
  from public.sponsorship_leads l
  join public.businesses b on b.id = l.business_id
  where public.is_admin()
    and (p_status is null or p_status = '' or l.status::text = p_status)
  order by l.created_at desc
  limit greatest(p_limit, 0) offset greatest(p_offset, 0);
$function$;

create or replace function public.admin_update_sponsorship_lead_status_v1(
  p_id uuid,
  p_status text
)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $function$
begin
  if not public.is_admin() then
    return jsonb_build_object('ok', false, 'code', 'not_admin', 'message', 'Not admin');
  end if;

  update public.sponsorship_leads
  set status = p_status
  where id = p_id;

  return jsonb_build_object('ok', true, 'id', p_id);
end;
$function$;

create or replace function public.admin_set_business_verified_v1(
  p_business_id uuid,
  p_is_verified boolean,
  p_tier text default 'verified',
  p_ends_at timestamp with time zone default null
)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $function$
declare
  v_id uuid;
begin
  if not public.is_admin() then
    return jsonb_build_object('ok', false, 'code', 'not_admin', 'message', 'Not admin');
  end if;

  update public.businesses
  set
    is_verified = p_is_verified,
    verified_at = case when p_is_verified then now() else null end,
    verified_by = case when p_is_verified then auth.uid() else null end
  where id = p_business_id;

  if p_is_verified then
    insert into public.business_premium(
      business_id, tier, status, starts_at, ends_at, source, created_by
    )
    values (
      p_business_id, p_tier, 'active', now(), p_ends_at, 'manual', auth.uid()
    )
    on conflict (business_id, tier) where status = 'active'
    do update set
      ends_at = excluded.ends_at,
      status = 'active';
  else
    update public.business_premium
    set status = 'ended',
        ends_at = coalesce(p_ends_at, now())
    where business_id = p_business_id
      and tier = p_tier
      and status = 'active';
  end if;

  select id into v_id
  from public.business_premium
  where business_id = p_business_id
    and tier = p_tier
  order by created_at desc
  limit 1;

  return jsonb_build_object('ok', true, 'business_id', p_business_id, 'premium_id', v_id);
end;
$function$;
