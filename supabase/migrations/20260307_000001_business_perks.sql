create table if not exists public.business_perks (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses(id) on delete cascade,
  title text not null,
  description text null,
  starts_at timestamptz null,
  ends_at timestamptz null,
  requires_checkin boolean not null default true,
  status text not null default 'active',
  created_by uuid null,
  created_at timestamptz not null default now()
);

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'business_perks_status_check'
      and conrelid = 'public.business_perks'::regclass
  ) then
    alter table public.business_perks
      add constraint business_perks_status_check
      check (status in ('active','ended','paused'));
  end if;
end $$;

create index if not exists business_perks_business_status_idx
  on public.business_perks (business_id, status, starts_at, ends_at);

-- expand feed_events type check to include perk
DO $$
begin
  if exists (
    select 1
    from pg_constraint
    where conname = 'feed_events_type_check'
      and conrelid = 'public.feed_events'::regclass
  ) then
    alter table public.feed_events drop constraint feed_events_type_check;
  end if;
  alter table public.feed_events
    add constraint feed_events_type_check
    check (type in ('menu_update','story_posted','price_verified','sponsored','new_item','perk'));
end $$;

create or replace function public.handle_business_perk_feed()
returns trigger
language plpgsql
security definer
set search_path to 'public'
as $function$
begin
  if (tg_op = 'INSERT' or old.status is distinct from new.status)
     and new.status = 'active'
     and (new.starts_at is null or new.starts_at <= now())
     and (new.ends_at is null or new.ends_at >= now()) then
    insert into public.feed_events (business_id, type, ref_id, meta)
    values (
      new.business_id,
      'perk',
      new.id,
      jsonb_build_object(
        'title', new.title,
        'description', new.description,
        'starts_at', new.starts_at,
        'ends_at', new.ends_at,
        'requires_checkin', new.requires_checkin
      )
    );
  end if;
  return new;
end;
$function$;

drop trigger if exists trg_business_perks_feed on public.business_perks;
create trigger trg_business_perks_feed
after insert or update on public.business_perks
for each row
execute function public.handle_business_perk_feed();

create or replace function public.owner_create_perk_v1(
  p_business_id uuid,
  p_title text,
  p_description text default null,
  p_starts_at timestamptz default null,
  p_ends_at timestamptz default null,
  p_requires_checkin boolean default true
) returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $function$
declare
  v_title text;
  v_id uuid;
begin
  if auth.uid() is null then
    return jsonb_build_object('ok', false, 'code', 'not_authenticated');
  end if;

  if not (public.is_admin() or public.is_owner_of_business(p_business_id)) then
    return jsonb_build_object('ok', false, 'code', 'not_owner');
  end if;

  v_title := nullif(trim(p_title), '');
  if v_title is null then
    return jsonb_build_object('ok', false, 'code', 'invalid', 'message', 'Title required');
  end if;

  if p_starts_at is not null and p_ends_at is not null and p_starts_at > p_ends_at then
    return jsonb_build_object('ok', false, 'code', 'invalid', 'message', 'Invalid date range');
  end if;

  insert into public.business_perks(
    business_id,
    title,
    description,
    starts_at,
    ends_at,
    requires_checkin,
    status,
    created_by
  ) values (
    p_business_id,
    v_title,
    nullif(trim(p_description), ''),
    p_starts_at,
    p_ends_at,
    coalesce(p_requires_checkin, true),
    'active',
    auth.uid()
  ) returning id into v_id;

  return jsonb_build_object('ok', true, 'id', v_id);
end;
$function$;

create or replace function public.owner_set_perk_status_v1(
  p_perk_id uuid,
  p_status text
) returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $function$
declare
  v_business_id uuid;
  v_status text;
begin
  if auth.uid() is null then
    return jsonb_build_object('ok', false, 'code', 'not_authenticated');
  end if;

  select business_id into v_business_id
  from public.business_perks
  where id = p_perk_id;

  if v_business_id is null then
    return jsonb_build_object('ok', false, 'code', 'not_found');
  end if;

  if not (public.is_admin() or public.is_owner_of_business(v_business_id)) then
    return jsonb_build_object('ok', false, 'code', 'not_owner');
  end if;

  v_status := nullif(trim(p_status), '');
  if v_status is null or v_status not in ('active','paused','ended') then
    return jsonb_build_object('ok', false, 'code', 'invalid');
  end if;

  update public.business_perks
  set status = v_status
  where id = p_perk_id;

  return jsonb_build_object('ok', true);
end;
$function$;

create or replace function public.get_active_perks_v1(
  p_business_id uuid
) returns table(
  id uuid,
  business_id uuid,
  title text,
  description text,
  starts_at timestamptz,
  ends_at timestamptz,
  requires_checkin boolean,
  status text,
  created_at timestamptz
)
language sql
stable
security definer
set search_path to 'public'
as $$
  select
    p.id,
    p.business_id,
    p.title,
    p.description,
    p.starts_at,
    p.ends_at,
    p.requires_checkin,
    p.status,
    p.created_at
  from public.business_perks p
  where p.business_id = p_business_id
    and p.status = 'active'
    and (p.starts_at is null or p.starts_at <= now())
    and (p.ends_at is null or p.ends_at >= now())
  order by p.created_at desc;
$$;

create or replace function public.owner_list_perks_v1(
  p_business_id uuid
) returns table(
  id uuid,
  business_id uuid,
  title text,
  description text,
  starts_at timestamptz,
  ends_at timestamptz,
  requires_checkin boolean,
  status text,
  created_at timestamptz
)
language sql
stable
security definer
set search_path to 'public'
as $$
  select
    p.id,
    p.business_id,
    p.title,
    p.description,
    p.starts_at,
    p.ends_at,
    p.requires_checkin,
    p.status,
    p.created_at
  from public.business_perks p
  where p.business_id = p_business_id
  order by p.created_at desc;
$$;

create or replace function public.get_perk_feed_v1(
  p_limit int default 30,
  p_offset int default 0,
  p_city text default null,
  p_district text default null,
  p_category text default null
) returns table(
  event_id uuid,
  business_id uuid,
  business_name text,
  title text,
  description text,
  starts_at timestamptz,
  ends_at timestamptz,
  created_at timestamptz
)
language sql
stable
security definer
set search_path to 'public'
as $$
  select
    e.id as event_id,
    e.business_id,
    b.name as business_name,
    (e.meta->>'title')::text as title,
    (e.meta->>'description')::text as description,
    nullif(e.meta->>'starts_at','')::timestamptz as starts_at,
    nullif(e.meta->>'ends_at','')::timestamptz as ends_at,
    e.created_at
  from public.feed_events e
  join public.businesses b on b.id = e.business_id
  where e.type = 'perk'
    and (p_city is null or b.city = p_city)
    and (p_district is null or b.district = p_district)
    and (p_category is null or b.category = p_category)
  order by e.created_at desc
  limit greatest(p_limit, 0)
  offset greatest(p_offset, 0);
$$;
