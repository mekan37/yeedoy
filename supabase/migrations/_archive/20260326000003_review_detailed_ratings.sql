begin;

alter table public.reviews
  add column if not exists overall_rating smallint,
  add column if not exists taste_rating smallint,
  add column if not exists service_speed_rating smallint,
  add column if not exists price_performance_rating smallint,
  add column if not exists cleanliness_rating smallint,
  add column if not exists atmosphere_rating smallint;

update public.reviews
set overall_rating = rating::smallint
where overall_rating is null;

alter table public.reviews
  drop constraint if exists reviews_overall_rating_range,
  drop constraint if exists reviews_taste_rating_range,
  drop constraint if exists reviews_service_speed_rating_range,
  drop constraint if exists reviews_price_performance_rating_range,
  drop constraint if exists reviews_cleanliness_rating_range,
  drop constraint if exists reviews_atmosphere_rating_range;

alter table public.reviews
  add constraint reviews_overall_rating_range
    check (overall_rating is null or overall_rating between 1 and 5),
  add constraint reviews_taste_rating_range
    check (taste_rating is null or taste_rating between 1 and 5),
  add constraint reviews_service_speed_rating_range
    check (service_speed_rating is null or service_speed_rating between 1 and 5),
  add constraint reviews_price_performance_rating_range
    check (price_performance_rating is null or price_performance_rating between 1 and 5),
  add constraint reviews_cleanliness_rating_range
    check (cleanliness_rating is null or cleanliness_rating between 1 and 5),
  add constraint reviews_atmosphere_rating_range
    check (atmosphere_rating is null or atmosphere_rating between 1 and 5);

create index if not exists idx_reviews_business_status_created_at_v2
  on public.reviews (business_id, status, created_at desc);

create index if not exists idx_reviews_business_status_helpful_count_v1
  on public.reviews (business_id, status, helpful_count desc, created_at desc);

create or replace function public.sync_review_overall_rating_v1()
returns trigger
language plpgsql
as $$
begin
  new.overall_rating := coalesce(new.overall_rating, new.rating::smallint);
  new.rating := coalesce(new.overall_rating, new.rating::smallint)::integer;
  return new;
end;
$$;

drop trigger if exists trg_reviews_sync_overall_rating_v1 on public.reviews;
create trigger trg_reviews_sync_overall_rating_v1
before insert or update on public.reviews
for each row execute function public.sync_review_overall_rating_v1();

create or replace view public.business_rating_summary as
select
  r.business_id,
  count(*)::integer as rating_count,
  round(avg(coalesce(r.overall_rating, r.rating::smallint)::numeric), 2) as avg_overall_rating,
  round(avg(r.taste_rating::numeric), 2) as avg_taste_rating,
  round(avg(r.service_speed_rating::numeric), 2) as avg_service_speed_rating,
  round(avg(r.price_performance_rating::numeric), 2) as avg_price_performance_rating,
  round(avg(r.cleanliness_rating::numeric), 2) as avg_cleanliness_rating,
  round(avg(r.atmosphere_rating::numeric), 2) as avg_atmosphere_rating
from public.reviews r
where r.status = 'approved'
group by r.business_id;

grant select on public.business_rating_summary to anon, authenticated, service_role;

create or replace function public.get_business_rating_summary_v1(
  p_business_id uuid
)
returns table(
  business_id uuid,
  rating_count integer,
  avg_overall_rating numeric,
  avg_taste_rating numeric,
  avg_service_speed_rating numeric,
  avg_price_performance_rating numeric,
  avg_cleanliness_rating numeric,
  avg_atmosphere_rating numeric
)
language sql
stable
security definer
set search_path = public
as $$
  with summary as (
    select *
    from public.business_rating_summary
    where business_id = p_business_id
  )
  select
    coalesce((select s.business_id from summary s), p_business_id) as business_id,
    coalesce((select s.rating_count from summary s), 0) as rating_count,
    (select s.avg_overall_rating from summary s) as avg_overall_rating,
    (select s.avg_taste_rating from summary s) as avg_taste_rating,
    (select s.avg_service_speed_rating from summary s) as avg_service_speed_rating,
    (select s.avg_price_performance_rating from summary s) as avg_price_performance_rating,
    (select s.avg_cleanliness_rating from summary s) as avg_cleanliness_rating,
    (select s.avg_atmosphere_rating from summary s) as avg_atmosphere_rating;
$$;

grant all on function public.get_business_rating_summary_v1(uuid) to anon;
grant all on function public.get_business_rating_summary_v1(uuid) to authenticated;
grant all on function public.get_business_rating_summary_v1(uuid) to service_role;

create or replace function public.get_business_reviews_v3(
  p_business_id uuid,
  p_sort text default 'newest',
  p_limit integer default 20,
  p_offset integer default 0
) returns table(
  id uuid,
  business_id uuid,
  user_id uuid,
  rating integer,
  overall_rating integer,
  taste_rating integer,
  service_speed_rating integer,
  price_performance_rating integer,
  cleanliness_rating integer,
  atmosphere_rating integer,
  title text,
  content text,
  helpful_count integer,
  created_at timestamptz,
  status text,
  quality_score numeric
)
language sql
stable
security definer
set search_path = public
as $$
  with base as (
    select
      r.id,
      r.business_id,
      r.user_id,
      r.rating,
      coalesce(r.overall_rating, r.rating::smallint)::integer as overall_rating,
      r.taste_rating::integer as taste_rating,
      r.service_speed_rating::integer as service_speed_rating,
      r.price_performance_rating::integer as price_performance_rating,
      r.cleanliness_rating::integer as cleanliness_rating,
      r.atmosphere_rating::integer as atmosphere_rating,
      r.title,
      r.content,
      r.helpful_count,
      r.created_at,
      r.status,
      coalesce(rep.open_reports, 0) as open_reports,
      greatest(
        0::numeric,
        least(
          100::numeric,
          (coalesce(r.helpful_count, 0)::numeric * 2.2)
          + (least(length(coalesce(r.content, '')), 400)::numeric / 20)
          + (coalesce(r.overall_rating, r.rating::smallint)::numeric * 1.5)
          - (coalesce(rep.open_reports, 0)::numeric * 3.0)
        )
      ) as quality_score
    from public.reviews r
    left join (
      select
        review_id,
        count(*)::int as open_reports
      from public.reports
      where review_id is not null
        and coalesce(status, '') in ('open', 'reviewing', 'acik')
      group by review_id
    ) rep on rep.review_id = r.id
    where r.business_id = p_business_id
      and r.status = 'approved'
  )
  select
    b.id,
    b.business_id,
    b.user_id,
    b.rating,
    b.overall_rating,
    b.taste_rating,
    b.service_speed_rating,
    b.price_performance_rating,
    b.cleanliness_rating,
    b.atmosphere_rating,
    b.title,
    b.content,
    b.helpful_count,
    b.created_at,
    b.status,
    b.quality_score
  from base b
  order by
    case when lower(coalesce(p_sort, 'newest')) = 'helpful' then b.quality_score else null end desc,
    case when lower(coalesce(p_sort, 'newest')) = 'helpful' then b.helpful_count else null end desc,
    b.created_at desc
  limit greatest(p_limit, 1)
  offset greatest(p_offset, 0);
$$;

grant all on function public.get_business_reviews_v3(uuid, text, integer, integer) to anon;
grant all on function public.get_business_reviews_v3(uuid, text, integer, integer) to authenticated;
grant all on function public.get_business_reviews_v3(uuid, text, integer, integer) to service_role;

create or replace function public.submit_review_v3(
  p_business_id uuid,
  p_overall_rating integer,
  p_title text default null,
  p_content text default null,
  p_taste_rating integer default null,
  p_service_speed_rating integer default null,
  p_price_performance_rating integer default null,
  p_cleanliness_rating integer default null,
  p_atmosphere_rating integer default null,
  p_idempotency_key text default null
) returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
  v_content text := public.sanitize_plain_text_v1(p_content);
  v_title text := nullif(public.sanitize_plain_text_v1(p_title), '');
  v_profile_created_at timestamptz;
  v_recent_count int := 0;
  v_same_business_count int := 0;
  v_shadow boolean := false;
  v_rate jsonb;
  v_has_contact boolean := false;
  v_has_profanity boolean := false;
  v_status text := 'approved';
  v_idempotency_key text := nullif(trim(coalesce(p_idempotency_key, '')), '');
  v_cached_response jsonb;
  v_response jsonb;
  v_review_id uuid;
begin
  if v_user_id is null then
    return jsonb_build_object('ok', false, 'error', 'not_authenticated');
  end if;

  if v_idempotency_key is not null then
    perform pg_advisory_xact_lock(
      hashtext('submit_review_v3'),
      hashtext(v_user_id::text || ':' || v_idempotency_key)
    );

    select k.response
      into v_cached_response
    from public.client_mutation_idempotency_keys k
    where k.user_id = v_user_id
      and k.action = 'submit_review_v3'
      and k.idempotency_key = v_idempotency_key
    limit 1;

    if v_cached_response is not null then
      return v_cached_response;
    end if;
  end if;

  if p_business_id is null then
    return jsonb_build_object('ok', false, 'error', 'business_required');
  end if;

  if p_overall_rating < 1 or p_overall_rating > 5 then
    return jsonb_build_object('ok', false, 'error', 'bad_rating');
  end if;

  if p_taste_rating is not null and (p_taste_rating < 1 or p_taste_rating > 5) then
    return jsonb_build_object('ok', false, 'error', 'bad_taste_rating');
  end if;

  if p_service_speed_rating is not null and (p_service_speed_rating < 1 or p_service_speed_rating > 5) then
    return jsonb_build_object('ok', false, 'error', 'bad_service_speed_rating');
  end if;

  if p_price_performance_rating is not null and (p_price_performance_rating < 1 or p_price_performance_rating > 5) then
    return jsonb_build_object('ok', false, 'error', 'bad_price_performance_rating');
  end if;

  if p_cleanliness_rating is not null and (p_cleanliness_rating < 1 or p_cleanliness_rating > 5) then
    return jsonb_build_object('ok', false, 'error', 'bad_cleanliness_rating');
  end if;

  if p_atmosphere_rating is not null and (p_atmosphere_rating < 1 or p_atmosphere_rating > 5) then
    return jsonb_build_object('ok', false, 'error', 'bad_atmosphere_rating');
  end if;

  if length(v_content) < 8 then
    return jsonb_build_object('ok', false, 'error', 'content_too_short');
  end if;

  if length(regexp_replace(v_content, '[[:alnum:][:space:]]', '', 'g')) > 12 then
    return jsonb_build_object('ok', false, 'error', 'emoji_spam');
  end if;

  v_has_contact := public.contains_contact_or_url_v1(coalesce(p_content, ''))
    or public.contains_contact_or_url_v1(v_content);

  v_has_profanity := public.contains_obfuscated_profanity_v1(v_content)
    or public.contains_obfuscated_profanity_v1(coalesce(v_title, ''));

  if v_has_contact then
    v_content := public.mask_contact_tokens_v1(v_content);
    v_title := nullif(public.mask_contact_tokens_v1(coalesce(v_title, '')), '');
  end if;

  v_rate := public.consume_rate_limit_v1('review', 15);
  if coalesce((v_rate->>'ok')::boolean, false) is false then
    return jsonb_build_object('ok', false, 'error', 'review_daily_rate_limited');
  end if;

  select up.created_at
    into v_profile_created_at
  from public.user_profiles up
  where up.user_id = v_user_id;

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
  v_status := case
    when v_shadow or v_has_contact or v_has_profanity then 'pending'
    else 'approved'
  end;

  insert into public.reviews(
    business_id,
    user_id,
    rating,
    overall_rating,
    taste_rating,
    service_speed_rating,
    price_performance_rating,
    cleanliness_rating,
    atmosphere_rating,
    title,
    content,
    status
  ) values (
    p_business_id,
    v_user_id,
    p_overall_rating,
    p_overall_rating,
    p_taste_rating,
    p_service_speed_rating,
    p_price_performance_rating,
    p_cleanliness_rating,
    p_atmosphere_rating,
    v_title,
    v_content,
    v_status
  )
  returning id into v_review_id;

  v_response := jsonb_build_object(
    'ok', true,
    'review_id', v_review_id,
    'shadowed', v_shadow,
    'pending', v_status = 'pending',
    'contains_contact', v_has_contact,
    'contains_profanity', v_has_profanity,
    'has_detailed_ratings',
      (p_taste_rating is not null
        or p_service_speed_rating is not null
        or p_price_performance_rating is not null
        or p_cleanliness_rating is not null
        or p_atmosphere_rating is not null)
  );

  if v_idempotency_key is not null then
    insert into public.client_mutation_idempotency_keys(
      user_id,
      action,
      idempotency_key,
      response,
      resource_type,
      resource_id
    )
    values (
      v_user_id,
      'submit_review_v3',
      v_idempotency_key,
      v_response,
      'review',
      v_review_id
    )
    on conflict (user_id, action, idempotency_key) do update
    set response = excluded.response,
        resource_type = excluded.resource_type,
        resource_id = excluded.resource_id;
  end if;

  return v_response;
end;
$$;

grant all on function public.submit_review_v3(
  uuid,
  integer,
  text,
  text,
  integer,
  integer,
  integer,
  integer,
  integer,
  text
) to anon;
grant all on function public.submit_review_v3(
  uuid,
  integer,
  text,
  text,
  integer,
  integer,
  integer,
  integer,
  integer,
  text
) to authenticated;
grant all on function public.submit_review_v3(
  uuid,
  integer,
  text,
  text,
  integer,
  integer,
  integer,
  integer,
  integer,
  text
) to service_role;

commit;
