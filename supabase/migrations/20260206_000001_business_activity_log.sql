create table if not exists public.business_activity_log (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses(id) on delete cascade,
  type text not null check (type in ('menu_update')),
  meta jsonb not null default '{}'::jsonb,
  created_at timestamp with time zone not null default now()
);
create index if not exists business_activity_log_business_id_idx
  on public.business_activity_log (business_id, created_at desc);
create or replace function public.log_menu_activity_v1(
  p_business_id uuid,
  p_event text,
  p_meta jsonb default '{}'::jsonb
)
returns void
language plpgsql
security definer
set search_path to 'public'
as $function$
begin
  insert into public.business_activity_log (business_id, type, meta)
  values (p_business_id, 'menu_update', jsonb_build_object('event', p_event) || coalesce(p_meta, '{}'::jsonb));
end;
$function$;
create or replace function public.trg_log_menu_section_activity()
returns trigger
language plpgsql
security definer
set search_path to 'public'
as $function$
declare
  v_business_id uuid;
  v_meta jsonb;
begin
  if tg_op = 'INSERT' then
    select m.business_id into v_business_id from public.menus m where m.id = new.menu_id;
    v_meta := jsonb_build_object('section_id', new.id, 'menu_id', new.menu_id);
    perform public.log_menu_activity_v1(v_business_id, 'section_insert', v_meta);
    return new;
  elsif tg_op = 'UPDATE' then
    select m.business_id into v_business_id from public.menus m where m.id = new.menu_id;
    v_meta := jsonb_build_object('section_id', new.id, 'menu_id', new.menu_id);
    perform public.log_menu_activity_v1(v_business_id, 'section_update', v_meta);
    return new;
  elsif tg_op = 'DELETE' then
    select m.business_id into v_business_id from public.menus m where m.id = old.menu_id;
    v_meta := jsonb_build_object('section_id', old.id, 'menu_id', old.menu_id);
    perform public.log_menu_activity_v1(v_business_id, 'section_delete', v_meta);
    return old;
  end if;
  return null;
end;
$function$;
create or replace function public.trg_log_menu_item_activity()
returns trigger
language plpgsql
security definer
set search_path to 'public'
as $function$
declare
  v_business_id uuid;
  v_meta jsonb;
begin
  if tg_op = 'INSERT' then
    v_business_id := new.business_id;
    v_meta := jsonb_build_object('item_id', new.id, 'section_id', new.section_id, 'menu_id', null);
    perform public.log_menu_activity_v1(v_business_id, 'item_insert', v_meta);
    return new;
  elsif tg_op = 'UPDATE' then
    v_business_id := new.business_id;
    v_meta := jsonb_build_object('item_id', new.id, 'section_id', new.section_id, 'menu_id', null);
    perform public.log_menu_activity_v1(v_business_id, 'item_update', v_meta);
    return new;
  elsif tg_op = 'DELETE' then
    v_business_id := old.business_id;
    v_meta := jsonb_build_object('item_id', old.id, 'section_id', old.section_id, 'menu_id', null);
    perform public.log_menu_activity_v1(v_business_id, 'item_delete', v_meta);
    return old;
  end if;
  return null;
end;
$function$;
do $$
begin
  if not exists (
    select 1 from pg_trigger where tgname = 'menu_sections_activity_log_trg'
  ) then
    create trigger menu_sections_activity_log_trg
      after insert or update or delete on public.menu_sections
      for each row execute function public.trg_log_menu_section_activity();
  end if;

  if not exists (
    select 1 from pg_trigger where tgname = 'menu_items_activity_log_trg'
  ) then
    create trigger menu_items_activity_log_trg
      after insert or update or delete on public.menu_items
      for each row execute function public.trg_log_menu_item_activity();
  end if;
end $$;
create or replace function public.get_business_activity_v1(
  p_business_id uuid,
  p_limit integer default 10
)
returns table(
  activity_id uuid,
  activity_type text,
  meta jsonb,
  created_at timestamp with time zone
)
language sql
stable
security definer
set search_path to 'public'
as $function$
  select
    a.id as activity_id,
    a.type as activity_type,
    a.meta,
    a.created_at
  from public.business_activity_log a
  where a.business_id = p_business_id
  order by a.created_at desc
  limit greatest(p_limit, 0);
$function$;
alter table public.business_activity_log enable row level security;
do $$
begin
  if not exists (
    select 1 from pg_policies
    where schemaname = 'public'
      and tablename = 'business_activity_log'
      and policyname = 'business_activity_read_all'
  ) then
    execute 'create policy business_activity_read_all on public.business_activity_log
      for select using (true)';
  end if;
end $$;
