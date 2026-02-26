-- Review anti-spam + helpful quality ranking.

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

  insert into public.reviews(
    business_id, user_id, rating, title, content, status
  ) values (
    p_business_id, v_user_id, p_rating, v_title, v_content, 'approved'
  );

  return jsonb_build_object('ok', true);
end;
$$;

create or replace function public.get_business_reviews_v2(
  p_business_id uuid,
  p_sort text default 'newest',
  p_limit integer default 20,
  p_offset integer default 0
) returns table(
  id uuid,
  business_id uuid,
  user_id uuid,
  rating integer,
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
          + (r.rating::numeric * 1.5)
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
        and (durum = 'acik' or status in ('open', 'reviewing'))
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

grant all on function public.submit_review_v1(uuid, integer, text, text) to anon;
grant all on function public.submit_review_v1(uuid, integer, text, text) to authenticated;
grant all on function public.submit_review_v1(uuid, integer, text, text) to service_role;

grant all on function public.get_business_reviews_v2(uuid, text, integer, integer) to anon;
grant all on function public.get_business_reviews_v2(uuid, text, integer, integer) to authenticated;
grant all on function public.get_business_reviews_v2(uuid, text, integer, integer) to service_role;
