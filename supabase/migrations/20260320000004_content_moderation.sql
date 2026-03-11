-- Content moderation, shadow ban, and media rate limits.

alter table public.user_profiles
  add column if not exists shadow_banned boolean not null default false;
alter table public.menu_item_photos
  add column if not exists is_shadow boolean not null default false;
alter table public.menu_item_price_suggestions
  add column if not exists is_shadow boolean not null default false;
alter table public.business_media
  add column if not exists created_by uuid;
alter table public.business_media
  add column if not exists is_shadow boolean not null default false;
create index if not exists idx_menu_item_photos_shadow
  on public.menu_item_photos(is_shadow);
create index if not exists idx_menu_item_price_suggestions_shadow
  on public.menu_item_price_suggestions(is_shadow);
create index if not exists idx_business_media_shadow
  on public.business_media(is_shadow);
create or replace function public.is_shadow_banned_v1()
returns boolean
language sql
security definer
set search_path = public
as $$
  select coalesce(
    (select shadow_banned from public.user_profiles where user_id = auth.uid()),
    false
  );
$$;
create or replace function public.submit_review_v1(
  p_business_id uuid,
  p_rating integer,
  p_title text default null,
  p_content text default null
) returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
  v_content text := coalesce(trim(p_content), '');
  v_title text := nullif(trim(coalesce(p_title, '')), '');
  v_profile_created_at timestamptz;
  v_recent_count int := 0;
  v_same_business_count int := 0;
  v_shadow boolean := false;
  v_rate jsonb;
begin
  if v_user_id is null then
    return jsonb_build_object('ok', false, 'error', 'not_authenticated');
  end if;

  if p_business_id is null then
    return jsonb_build_object('ok', false, 'error', 'business_required');
  end if;

  if p_rating < 1 or p_rating > 5 then
    return jsonb_build_object('ok', false, 'error', 'bad_rating');
  end if;

  if length(v_content) < 8 then
    return jsonb_build_object('ok', false, 'error', 'content_too_short');
  end if;

  -- link / phone / contact filtering
  if v_content ~* '(https?://|www\.|t\.me/|wa\.me/|instagram\.com|@[a-z0-9_]{2,}|(\+?\d[\d\s\-\(\)]{7,}\d))' then
    return jsonb_build_object('ok', false, 'error', 'contains_link_or_phone');
  end if;

  -- emoji / symbol spam (simple heuristic)
  if length(regexp_replace(v_content, '[[:alnum:][:space:]]', '', 'g')) > 12 then
    return jsonb_build_object('ok', false, 'error', 'emoji_spam');
  end if;

  v_rate := public.consume_rate_limit_v1('review', 15);
  if coalesce((v_rate->>'ok')::boolean, false) is false then
    return jsonb_build_object('ok', false, 'error', 'review_daily_rate_limited');
  end if;

  select up.created_at
    into v_profile_created_at
  from public.user_profiles up
  where up.user_id = v_user_id;

  -- New account throttle: first 7 days => max 2 reviews/day
  if v_profile_created_at is not null and v_profile_created_at >= now() - interval '7 days' then
    select count(*)
      into v_recent_count
    from public.reviews r
    where r.user_id = v_user_id
      and r.created_at >= now() - interval '24 hours';

    if v_recent_count >= 2 then
      return jsonb_build_object('ok', false, 'error', 'new_account_rate_limited');
    end if;
  end if;

  -- Same business cooldown: one review per 12 hours.
  select count(*)
    into v_same_business_count
  from public.reviews r
  where r.user_id = v_user_id
    and r.business_id = p_business_id
    and r.created_at >= now() - interval '12 hours';

  if v_same_business_count > 0 then
    return jsonb_build_object('ok', false, 'error', 'same_business_cooldown');
  end if;

  v_shadow := public.is_shadow_banned_v1();

  insert into public.reviews(
    business_id, user_id, rating, title, content, status
  ) values (
    p_business_id, v_user_id, p_rating, v_title, v_content,
    case when v_shadow then 'pending' else 'approved' end
  );

  return jsonb_build_object('ok', true, 'shadowed', v_shadow);
end;
$$;
create or replace function public.submit_menu_item_price_suggestion_v2(
  p_menu_item_id uuid,
  p_suggested_price_cents integer,
  p_currency text default 'TRY',
  p_note text default null,
  p_evidence_url text default null
) returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_business_id uuid;
  v_cnt int;
  v_note text;
  v_evidence_url text;
  v_current_price int;
  v_ok_30d int := 0;
  v_bad_30d int := 0;
  v_total_30d int := 0;
  v_confidence numeric := 0;
  v_auto_approved boolean := false;
  v_pending_count int := 0;
  v_shadow boolean := false;
  v_rate jsonb;
begin
  if auth.uid() is null then
    return jsonb_build_object('ok', false, 'error', 'not_authenticated');
  end if;

  if p_suggested_price_cents < 0 then
    return jsonb_build_object('ok', false, 'error', 'bad_price');
  end if;

  if p_currency is null or length(trim(p_currency)) <> 3 then
    return jsonb_build_object('ok', false, 'error', 'bad_currency');
  end if;

  v_note := nullif(trim(p_note), '');
  v_evidence_url := nullif(trim(p_evidence_url), '');

  if v_note is not null and v_note ~* '(https?://|www\.|t\.me/|wa\.me/|instagram\.com|@[a-z0-9_]{2,}|(\+?\d[\d\s\-\(\)]{7,}\d))' then
    return jsonb_build_object('ok', false, 'error', 'contains_link_or_phone');
  end if;

  if v_note is not null
     and length(regexp_replace(v_note, '[[:alnum:][:space:]]', '', 'g')) > 12 then
    return jsonb_build_object('ok', false, 'error', 'emoji_spam');
  end if;

  if v_evidence_url is not null and left(v_evidence_url, 4) <> 'http' then
    return jsonb_build_object('ok', false, 'error', 'bad_evidence_url');
  end if;

  v_rate := public.consume_rate_limit_v1('price_suggestion', 40);
  if coalesce((v_rate->>'ok')::boolean, false) is false then
    return jsonb_build_object('ok', false, 'error', 'price_suggestion_daily_rate_limited');
  end if;

  select mi.business_id, mi.price_cents
    into v_business_id, v_current_price
  from public.menu_items mi
  where mi.id = p_menu_item_id and mi.status = 'published';

  if v_business_id is null then
    return jsonb_build_object('ok', false, 'error', 'not_found');
  end if;

  -- rate limit: same user, same item, once per 24h
  select count(*) into v_cnt
  from public.menu_item_price_suggestions
  where menu_item_id = p_menu_item_id
    and created_by = auth.uid()
    and created_at >= now() - interval '24 hours';

  if v_cnt > 0 then
    return jsonb_build_object('ok', false, 'error', 'rate_limited_24h');
  end if;

  select
    count(*) filter (where vote = 1 and created_at >= now() - interval '30 days'),
    count(*) filter (where vote = -1 and created_at >= now() - interval '30 days'),
    count(*) filter (where created_at >= now() - interval '30 days')
    into v_ok_30d, v_bad_30d, v_total_30d
  from public.menu_item_price_votes
  where menu_item_id = p_menu_item_id;

  v_confidence :=
    greatest(
      0::numeric,
      least(
        1::numeric,
        (case when v_total_30d <= 0 then 0.2 else (v_ok_30d::numeric / nullif(v_total_30d, 0)) end) * 0.8
        +
        (case
          when v_total_30d >= 12 then 0.2
          when v_total_30d >= 6 then 0.12
          when v_total_30d >= 3 then 0.06
          else 0
        end)
      )
    );

  v_shadow := public.is_shadow_banned_v1();
  if v_shadow then
    v_auto_approved := false;
  end if;

  -- Conservative auto-approval rule:
  -- enough signal + strong positive votes + small price delta (<=5%)
  if v_current_price is not null
     and v_current_price > 0
     and v_total_30d >= 8
     and v_ok_30d >= (v_bad_30d * 3)
     and abs(p_suggested_price_cents - v_current_price)::numeric / v_current_price::numeric <= 0.05
  then
    v_auto_approved := true;
  end if;

  if v_auto_approved then
    update public.menu_items
    set price_cents = p_suggested_price_cents,
        currency = upper(trim(p_currency)),
        updated_at = now()
    where id = p_menu_item_id;

    insert into public.menu_item_price_suggestions(
      menu_item_id, business_id, suggested_price_cents, currency, note, created_by,
      evidence_url, status, handled_at, approved_at, is_shadow
    )
    values (
      p_menu_item_id, v_business_id, p_suggested_price_cents, upper(trim(p_currency)), v_note, auth.uid(),
      v_evidence_url, 'approved', now(), now(), v_shadow
    );

    insert into public.menu_item_price_history(
      menu_item_id, price_cents, currency, source, created_by
    )
    values (
      p_menu_item_id, p_suggested_price_cents, upper(trim(p_currency)), 'auto_rule', auth.uid()
    );

    return jsonb_build_object(
      'ok', true,
      'auto_approved', true,
      'confidence_score', v_confidence,
      'pending_count', 0,
      'shadowed', v_shadow
    );
  end if;

  insert into public.menu_item_price_suggestions(
    menu_item_id, business_id, suggested_price_cents, currency, note, created_by, evidence_url, is_shadow
  )
  values (
    p_menu_item_id, v_business_id, p_suggested_price_cents, upper(trim(p_currency)), v_note, auth.uid(), v_evidence_url, v_shadow
  );

  select count(*) into v_pending_count
  from public.menu_item_price_suggestions
  where menu_item_id = p_menu_item_id
    and status = 'pending';

  return jsonb_build_object(
    'ok', true,
    'auto_approved', false,
    'confidence_score', v_confidence,
    'pending_count', v_pending_count,
    'shadowed', v_shadow
  );
end;
$$;
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
  v_shadow boolean := false;
  v_rate jsonb;
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

  v_rate := public.consume_rate_limit_v1('menu_photo', 20);
  if coalesce((v_rate->>'ok')::boolean, false) is false then
    return jsonb_build_object('ok', false, 'error', 'menu_photo_daily_rate_limited');
  end if;

  v_shadow := public.is_shadow_banned_v1();

  insert into public.menu_item_photos(
    menu_item_id,
    business_id,
    url,
    url_large,
    url_thumb,
    provider,
    created_by,
    is_shadow
  )
  values (
    p_menu_item_id,
    v_business_id,
    p_url,
    p_url_large,
    p_url_thumb,
    p_provider,
    auth.uid(),
    v_shadow
  )
  returning id into v_photo_id;

  return jsonb_build_object('ok', true, 'photo_id', v_photo_id, 'shadowed', v_shadow);
end;
$function$;
create or replace function public.get_menu_item_photos_v1(
  p_menu_item_id uuid,
  p_limit integer default 12
) returns table(
  id uuid,
  url text,
  url_large text,
  url_thumb text,
  provider text,
  created_at timestamp with time zone,
  up_votes integer,
  down_votes integer,
  score integer,
  my_vote smallint
)
language sql
stable
security definer
set search_path to 'public'
as $$
  select
    p.id,
    p.url,
    p.url_large,
    p.url_thumb,
    p.provider,
    p.created_at,
    p.up_votes,
    p.down_votes,
    (p.up_votes - p.down_votes) as score,
    (select v.vote from public.menu_item_photo_votes v
      where v.photo_id = p.id and v.user_id = auth.uid()
      limit 1) as my_vote
  from public.menu_item_photos p
  where p.menu_item_id = p_menu_item_id
    and (p.is_shadow is not true or p.created_by = auth.uid() or public.is_admin())
  order by p.created_at desc
  limit greatest(p_limit, 0);
$$;
create or replace function public.add_business_media_v1(
  p_business_id uuid,
  p_url text,
  p_url_large text default null,
  p_url_thumb text default null,
  p_provider text default 'wp',
  p_kind text default 'venue'
) returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  v_shadow boolean := false;
  v_rate jsonb;
begin
  if auth.uid() is null then
    return jsonb_build_object('ok', false, 'error', 'not_authenticated');
  end if;

  if p_business_id is null then
    return jsonb_build_object('ok', false, 'error', 'missing_business_id');
  end if;

  v_rate := public.consume_rate_limit_v1('business_media', 15);
  if coalesce((v_rate->>'ok')::boolean, false) is false then
    return jsonb_build_object('ok', false, 'error', 'business_media_daily_rate_limited');
  end if;

  v_shadow := public.is_shadow_banned_v1();

  insert into public.business_media(
    business_id, kind, url, url_large, url_thumb, provider, created_by, is_shadow
  ) values (
    p_business_id, coalesce(p_kind, 'venue'), p_url, p_url_large, p_url_thumb, p_provider, auth.uid(), v_shadow
  );

  return jsonb_build_object('ok', true, 'shadowed', v_shadow);
end;
$$;
grant all on function public.add_business_media_v1(uuid, text, text, text, text, text) to anon;
grant all on function public.add_business_media_v1(uuid, text, text, text, text, text) to authenticated;
grant all on function public.add_business_media_v1(uuid, text, text, text, text, text) to service_role;
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
  if new.user_id is null then
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
  if new.created_by is null then
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
create or replace function public.owner_list_menu_price_suggestions_v1(
  p_business_id uuid,
  p_status text default 'pending',
  p_limit integer default 30,
  p_offset integer default 0
) returns table(
  suggestion_id uuid,
  status text,
  created_at timestamp with time zone,
  menu_item_id uuid,
  item_name text,
  current_price_cents integer,
  suggested_price_cents integer,
  currency text,
  created_by uuid
)
language sql
stable
security definer
set search_path to 'public'
as $$
  select
    s.id as suggestion_id,
    s.status::text,
    s.created_at,
    mi.id as menu_item_id,
    mi.name as item_name,
    mi.price_cents as current_price_cents,
    s.suggested_price_cents,
    s.currency,
    s.created_by
  from public.menu_item_price_suggestions s
  join public.menu_items mi on mi.id = s.menu_item_id
  where s.business_id = p_business_id
    and public.is_owner_of_business(p_business_id)
    and (p_status is null or s.status::text = p_status)
    and (s.is_shadow is not true)
  order by (s.status='pending') desc, s.created_at asc
  limit greatest(p_limit,0)
  offset greatest(p_offset,0);
$$;
create or replace function public.admin_list_menu_price_suggestions_v2(
  p_status text default null,
  p_limit integer default 30,
  p_offset integer default 0,
  p_sla_only boolean default false,
  p_assigned text default null
)
returns table(
  suggestion_id uuid,
  status text,
  created_at timestamp with time zone,
  sla_breached boolean,
  business_id uuid,
  business_name text,
  city text,
  district text,
  menu_item_id uuid,
  item_name text,
  current_price_cents integer,
  suggested_price_cents integer,
  currency text,
  created_by uuid,
  assigned_to uuid,
  assigned_at timestamp with time zone
)
language sql
stable
security definer
set search_path to 'public'
as $$
  select
    s.id as suggestion_id,
    s.status::text,
    s.created_at,
    (s.status='pending' and s.created_at < now() - interval '48 hours') as sla_breached,
    b.id as business_id,
    b.name as business_name,
    b.city,
    b.district,
    mi.id as menu_item_id,
    mi.name as item_name,
    mi.price_cents as current_price_cents,
    s.suggested_price_cents,
    s.currency,
    s.created_by,
    s.handled_by as assigned_to,
    s.handled_at as assigned_at
  from public.menu_item_price_suggestions s
  join public.menu_items mi on mi.id = s.menu_item_id
  join public.businesses b on b.id = s.business_id
  where (p_status is null or s.status::text = p_status)
    and (p_assigned is null or p_assigned = '' or (p_assigned = 'assigned' and s.handled_by is not null) or (p_assigned = 'unassigned' and s.handled_by is null))
    and (p_sla_only = false or (s.status='pending' and s.created_at < now() - interval '48 hours'))
    and (s.is_shadow is not true or public.is_admin())
  order by (s.status='pending') desc, s.created_at asc
  limit greatest(p_limit,0)
  offset greatest(p_offset,0);
$$;
