-- Extra server-side anti-spam guards for reviews + price suggestions.
-- These run at table insert level, so limits apply even if client flow changes.

create or replace function public.enforce_review_insert_rate_limits_v1()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_recent_same_business int;
  v_recent_daily int;
begin
  if new.created_by is null then
    return new;
  end if;

  select count(*)
    into v_recent_same_business
  from public.reviews r
  where r.user_id = new.user_id
    and r.business_id = new.business_id
    and r.created_at >= now() - interval '12 hours';

  if v_recent_same_business > 0 then
    raise exception 'same_business_cooldown';
  end if;

  select count(*)
    into v_recent_daily
  from public.reviews r
  where r.user_id = new.user_id
    and r.created_at >= now() - interval '24 hours';

  if v_recent_daily >= 15 then
    raise exception 'review_daily_rate_limited';
  end if;

  return new;
end;
$$;

drop trigger if exists trg_reviews_rate_limit_v1 on public.reviews;
create trigger trg_reviews_rate_limit_v1
before insert on public.reviews
for each row execute function public.enforce_review_insert_rate_limits_v1();

create or replace function public.enforce_price_suggestion_insert_rate_limits_v1()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_recent_same_item int;
  v_recent_daily int;
begin
  if new.user_id is null then
    return new;
  end if;

  select count(*)
    into v_recent_same_item
  from public.menu_item_price_suggestions s
  where s.created_by = new.created_by
    and s.menu_item_id = new.menu_item_id
    and s.created_at >= now() - interval '24 hours';

  if v_recent_same_item > 0 then
    raise exception 'price_suggestion_same_item_cooldown';
  end if;

  select count(*)
    into v_recent_daily
  from public.menu_item_price_suggestions s
  where s.created_by = new.created_by
    and s.created_at >= now() - interval '24 hours';

  if v_recent_daily >= 40 then
    raise exception 'price_suggestion_daily_rate_limited';
  end if;

  return new;
end;
$$;

drop trigger if exists trg_menu_item_price_suggestions_rate_limit_v1 on public.menu_item_price_suggestions;
create trigger trg_menu_item_price_suggestions_rate_limit_v1
before insert on public.menu_item_price_suggestions
for each row execute function public.enforce_price_suggestion_insert_rate_limits_v1();

create index if not exists idx_reviews_user_created_at_v1
  on public.reviews(user_id, created_at desc);

create index if not exists idx_reviews_user_business_created_at_v1
  on public.reviews(user_id, business_id, created_at desc);

create index if not exists idx_menu_item_price_suggestions_user_created_at_v1
  on public.menu_item_price_suggestions(created_by, created_at desc);

create index if not exists idx_menu_item_price_suggestions_user_item_created_at_v1
  on public.menu_item_price_suggestions(created_by, menu_item_id, created_at desc);
