begin;
-- Enforce edge guard consumption for review vote writes.
create or replace function public.enforce_review_votes_edge_guard_v1()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if tg_op = 'INSERT' then
    perform public.consume_edge_guard_event_v1(
      'review_vote_set',
      coalesce(new.review_id::text, ''),
      900
    );
    return new;
  elsif tg_op = 'DELETE' then
    perform public.consume_edge_guard_event_v1(
      'review_vote_remove',
      coalesce(old.review_id::text, ''),
      900
    );
    return old;
  end if;
  return null;
end;
$$;
drop trigger if exists trg_review_votes_edge_guard_insert_v1 on public.review_votes;
create trigger trg_review_votes_edge_guard_insert_v1
before insert on public.review_votes
for each row execute function public.enforce_review_votes_edge_guard_v1();
drop trigger if exists trg_review_votes_edge_guard_delete_v1 on public.review_votes;
create trigger trg_review_votes_edge_guard_delete_v1
before delete on public.review_votes
for each row execute function public.enforce_review_votes_edge_guard_v1();
-- Enforce edge guard consumption for visit writes.
create or replace function public.enforce_visits_edge_guard_v1()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if tg_op = 'INSERT' then
    perform public.consume_edge_guard_event_v1(
      'visit_add',
      coalesce(new.business_id::text, ''),
      900
    );
    return new;
  elsif tg_op = 'DELETE' then
    perform public.consume_edge_guard_event_v1(
      'visit_remove',
      coalesce(old.business_id::text, ''),
      900
    );
    return old;
  end if;
  return null;
end;
$$;
drop trigger if exists trg_visits_edge_guard_insert_v1 on public.visits;
create trigger trg_visits_edge_guard_insert_v1
before insert on public.visits
for each row execute function public.enforce_visits_edge_guard_v1();
drop trigger if exists trg_visits_edge_guard_delete_v1 on public.visits;
create trigger trg_visits_edge_guard_delete_v1
before delete on public.visits
for each row execute function public.enforce_visits_edge_guard_v1();
-- Enforce edge guard consumption for menu photo deletes.
create or replace function public.enforce_menu_item_photos_delete_edge_guard_v1()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  perform public.consume_edge_guard_event_v1(
    'menu_photo_delete',
    coalesce(old.id::text, ''),
    900
  );
  return old;
end;
$$;
drop trigger if exists trg_menu_item_photos_delete_edge_guard_v1 on public.menu_item_photos;
create trigger trg_menu_item_photos_delete_edge_guard_v1
before delete on public.menu_item_photos
for each row execute function public.enforce_menu_item_photos_delete_edge_guard_v1();
commit;
