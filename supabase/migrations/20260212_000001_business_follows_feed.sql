create table if not exists public.business_follows (
  user_id uuid not null,
  business_id uuid not null references public.businesses(id) on delete cascade,
  created_at timestamptz default now(),
  primary key (user_id, business_id)
);
create table if not exists public.feed_events (
  id uuid primary key default gen_random_uuid(),
  business_id uuid references public.businesses(id) on delete set null,
  type text not null,
  ref_id uuid null,
  meta jsonb default '{}'::jsonb,
  created_at timestamptz default now()
);
do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'feed_events_type_check'
      and conrelid = 'public.feed_events'::regclass
  ) then
    alter table public.feed_events
      add constraint feed_events_type_check
      check (type in ('menu_update','story_posted','price_verified','sponsored'));
  end if;
end $$;
create index if not exists feed_events_business_created_at_idx
  on public.feed_events (business_id, created_at desc);
create or replace function public.follow_business_v1(
  p_business_id uuid
) returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $function$
declare
  v_user_id uuid := auth.uid();
begin
  if v_user_id is null then
    return jsonb_build_object('ok', false, 'code', 'not_authenticated');
  end if;

  insert into public.business_follows (user_id, business_id)
  values (v_user_id, p_business_id)
  on conflict do nothing;

  return jsonb_build_object('ok', true);
end;
$function$;
create or replace function public.unfollow_business_v1(
  p_business_id uuid
) returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $function$
declare
  v_user_id uuid := auth.uid();
begin
  if v_user_id is null then
    return jsonb_build_object('ok', false, 'code', 'not_authenticated');
  end if;

  delete from public.business_follows
  where user_id = v_user_id
    and business_id = p_business_id;

  return jsonb_build_object('ok', true);
end;
$function$;
create or replace function public.get_my_feed_v1(
  p_limit int,
  p_offset int
) returns table(
  event_id uuid,
  business_id uuid,
  type text,
  ref_id uuid,
  meta jsonb,
  created_at timestamptz
)
language plpgsql
security definer
set search_path to 'public'
as $function$
declare
  v_user_id uuid := auth.uid();
begin
  if v_user_id is null then
    return;
  end if;

  return query
  select
    e.id as event_id,
    e.business_id,
    e.type,
    e.ref_id,
    e.meta,
    e.created_at
  from public.feed_events e
  join public.business_follows f
    on f.business_id = e.business_id
   and f.user_id = v_user_id
  where e.created_at >= now() - interval '14 days'
  order by e.created_at desc
  limit greatest(p_limit, 0)
  offset greatest(p_offset, 0);
end;
$function$;
create or replace function public.handle_business_activity_log_feed() returns trigger
language plpgsql
security definer
set search_path to 'public'
as $function$
begin
  if new.type = 'menu_update' then
    insert into public.feed_events (business_id, type, ref_id, meta)
    values (new.business_id, 'menu_update', new.id, coalesce(new.meta, '{}'::jsonb));
  end if;
  return new;
end;
$function$;
drop trigger if exists trg_business_activity_log_feed on public.business_activity_log;
create trigger trg_business_activity_log_feed
after insert on public.business_activity_log
for each row
execute function public.handle_business_activity_log_feed();
