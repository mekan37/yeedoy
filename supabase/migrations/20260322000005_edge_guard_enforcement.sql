begin;

create or replace function public.consume_edge_guard_event_v1(
  p_action text,
  p_scope text default null,
  p_max_age_seconds integer default 600
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid uuid := auth.uid();
  v_event_id bigint;
begin
  if public.is_admin() or auth.role() = 'service_role' then
    return;
  end if;

  if v_uid is null then
    raise exception 'edge_guard_required';
  end if;

  with candidate as (
    select e.id
    from public.edge_rate_limit_events e
    where e.action = p_action
      and e.user_id = v_uid
      and e.created_at >= now() - make_interval(secs => greatest(p_max_age_seconds, 1))
      and (
        p_scope is null
        or e.scope = p_scope
      )
    order by e.created_at asc
    limit 1
  ),
  consumed as (
    delete from public.edge_rate_limit_events e
    using candidate c
    where e.id = c.id
    returning e.id
  )
  select id into v_event_id from consumed;

  if v_event_id is null then
    raise exception 'edge_guard_required';
  end if;
end;
$$;

create or replace function public.enforce_reviews_edge_guard_v1()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  perform public.consume_edge_guard_event_v1(
    'review_submit',
    coalesce(new.business_id::text, ''),
    900
  );
  return new;
end;
$$;

drop trigger if exists trg_reviews_edge_guard_v1 on public.reviews;
create trigger trg_reviews_edge_guard_v1
before insert on public.reviews
for each row execute function public.enforce_reviews_edge_guard_v1();

create or replace function public.enforce_price_suggestions_edge_guard_v1()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  perform public.consume_edge_guard_event_v1(
    'price_verify',
    coalesce(new.menu_item_id::text, ''),
    900
  );
  return new;
end;
$$;

drop trigger if exists trg_price_suggestions_edge_guard_v1 on public.menu_item_price_suggestions;
create trigger trg_price_suggestions_edge_guard_v1
before insert on public.menu_item_price_suggestions
for each row execute function public.enforce_price_suggestions_edge_guard_v1();

create or replace function public.enforce_reports_edge_guard_v1()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_scope text;
begin
  v_scope := coalesce(
    new.business_id::text,
    new.review_id::text,
    new.menu_item_photo_id::text,
    new.target_id::text,
    ''
  );
  perform public.consume_edge_guard_event_v1(
    'report_submit',
    v_scope,
    900
  );
  return new;
end;
$$;

drop trigger if exists trg_reports_edge_guard_v1 on public.reports;
create trigger trg_reports_edge_guard_v1
before insert on public.reports
for each row execute function public.enforce_reports_edge_guard_v1();

create or replace function public.enforce_menu_item_photos_edge_guard_v1()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  perform public.consume_edge_guard_event_v1(
    'photo_upload',
    null,
    7200
  );
  return new;
end;
$$;

drop trigger if exists trg_menu_item_photos_edge_guard_v1 on public.menu_item_photos;
create trigger trg_menu_item_photos_edge_guard_v1
before insert on public.menu_item_photos
for each row execute function public.enforce_menu_item_photos_edge_guard_v1();

commit;

