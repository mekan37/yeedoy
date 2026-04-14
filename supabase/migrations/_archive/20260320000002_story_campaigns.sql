create or replace function public.create_business_story_v1(
  p_business_id uuid,
  p_type text,
  p_caption text,
  p_media_url text,
  p_media_thumb_url text default null,
  p_duration_sec integer default null,
  p_expire_mode text default '24h'
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_today date := (now() at time zone 'utc')::date;
  v_count int;
  v_caption text := nullif(lower(trim(coalesce(p_caption, ''))), '');
  v_media_url text := nullif(trim(coalesce(p_media_url, '')), '');
  v_media_thumb_url text := nullif(trim(coalesce(p_media_thumb_url, '')), '');
  v_expires_at timestamptz;
  v_contains_gambling boolean := false;
  v_contains_copyright boolean := false;
begin
  if auth.uid() is null then
    return jsonb_build_object('ok', false, 'error', 'not_authenticated');
  end if;

  if not (public.is_admin() or public.is_owner_of_business(p_business_id)) then
    return jsonb_build_object('ok', false, 'error', 'not_owner');
  end if;

  if p_type not in ('menu', 'crowd', 'promo', 'update') then
    return jsonb_build_object('ok', false, 'error', 'bad_type');
  end if;

  if v_media_url is null or length(v_media_url) < 10 then
    return jsonb_build_object('ok', false, 'error', 'media_required');
  end if;

  if coalesce(p_expire_mode, '24h') = '7d' then
    v_expires_at := now() + interval '7 days';
  else
    v_expires_at := now() + interval '24 hours';
  end if;

  if v_caption is not null then
    v_contains_gambling := v_caption ~* '(iddaa|bahis|casino|rulet|slot|kumar|bet)';
    v_contains_copyright := v_caption ~* '(copyright|telif|dmca|izinsiz|pirate|illegal stream)';
  end if;

  if v_contains_gambling then
    return jsonb_build_object('ok', false, 'error', 'blocked_gambling');
  end if;

  if v_contains_copyright then
    return jsonb_build_object('ok', false, 'error', 'blocked_copyright');
  end if;

  select count(*)
  into v_count
  from public.business_stories
  where business_id = p_business_id
    and created_by = auth.uid()
    and created_at >= (v_today::timestamptz)
    and is_deleted = false;

  if v_count >= 5 then
    return jsonb_build_object('ok', false, 'error', 'rate_limited_daily');
  end if;

  if exists (
    select 1
    from public.business_stories s
    where s.business_id = p_business_id
      and s.is_deleted = false
      and s.created_at >= now() - interval '30 days'
      and (
        s.media_url = v_media_url
        or (v_media_thumb_url is not null and s.media_thumb_url = v_media_thumb_url)
      )
  ) then
    return jsonb_build_object('ok', false, 'error', 'duplicate_media');
  end if;

  if v_caption is not null and exists (
    select 1
    from public.business_stories s
    where s.business_id = p_business_id
      and s.created_by = auth.uid()
      and s.is_deleted = false
      and s.type = p_type::public.story_type
      and lower(trim(coalesce(s.caption, ''))) = v_caption
      and s.created_at >= now() - interval '24 hours'
  ) then
    return jsonb_build_object('ok', false, 'error', 'spam_suspected');
  end if;

  if exists (
    select 1
    from public.business_stories s
    where s.business_id = p_business_id
      and s.created_by = auth.uid()
      and s.is_deleted = false
      and s.type = p_type::public.story_type
      and s.created_at >= now() - interval '2 minutes'
  ) then
    return jsonb_build_object('ok', false, 'error', 'spam_suspected');
  end if;

  insert into public.business_stories(
    business_id,
    type,
    caption,
    media_url,
    media_thumb_url,
    media_type,
    duration_sec,
    created_by,
    expires_at
  )
  values (
    p_business_id,
    p_type::public.story_type,
    p_caption,
    v_media_url,
    v_media_thumb_url,
    case when p_duration_sec is null then 'image' else 'video' end,
    p_duration_sec,
    auth.uid(),
    v_expires_at
  );

  return jsonb_build_object('ok', true);
end;
$$;
grant all on function public.create_business_story_v1(
  uuid,
  text,
  text,
  text,
  text,
  integer,
  text
) to anon;
grant all on function public.create_business_story_v1(
  uuid,
  text,
  text,
  text,
  text,
  integer,
  text
) to authenticated;
grant all on function public.create_business_story_v1(
  uuid,
  text,
  text,
  text,
  text,
  integer,
  text
) to service_role;
create or replace function public.get_nearby_campaign_stories_v1(
  p_lat double precision default null,
  p_lng double precision default null,
  p_radius_km integer default 10,
  p_city text default null,
  p_district text default null,
  p_limit integer default 20
)
returns table(
  story_id uuid,
  business_id uuid,
  business_name text,
  city text,
  district text,
  caption text,
  media_url text,
  media_thumb_url text,
  created_at timestamptz,
  expires_at timestamptz,
  distance_km double precision
)
language sql
security definer
set search_path = public
as $$
  with src as (
    select
      s.id as story_id,
      s.business_id,
      b.name as business_name,
      b.city,
      b.district,
      s.caption,
      s.media_url,
      coalesce(s.media_thumb_url, s.media_url) as media_thumb_url,
      s.created_at,
      s.expires_at,
      case
        when p_lat is null or p_lng is null or b.lat is null or b.lng is null then null
        else (
          6371.0 * acos(
            least(
              1.0,
              greatest(
                -1.0,
                cos(radians(p_lat)) * cos(radians(b.lat)) * cos(radians(b.lng) - radians(p_lng))
                + sin(radians(p_lat)) * sin(radians(b.lat))
              )
            )
          )
        )
      end as distance_km
    from public.business_stories s
    join public.businesses b on b.id = s.business_id
    where s.is_deleted = false
      and s.type = 'promo'::public.story_type
      and s.expires_at > now()
      and (
        p_lat is not null and p_lng is not null
        or (
          (p_city is null or trim(p_city) = '' or lower(b.city) = lower(trim(p_city)))
          and (p_district is null or trim(p_district) = '' or lower(b.district) = lower(trim(p_district)))
        )
      )
  )
  select
    story_id,
    business_id,
    business_name,
    city,
    district,
    caption,
    media_url,
    media_thumb_url,
    created_at,
    expires_at,
    distance_km
  from src
  where distance_km is null or distance_km <= greatest(coalesce(p_radius_km, 10), 1)
  order by distance_km nulls last, created_at desc
  limit greatest(coalesce(p_limit, 20), 1);
$$;
grant all on function public.get_nearby_campaign_stories_v1(
  double precision,
  double precision,
  integer,
  text,
  text,
  integer
) to anon;
grant all on function public.get_nearby_campaign_stories_v1(
  double precision,
  double precision,
  integer,
  text,
  text,
  integer
) to authenticated;
grant all on function public.get_nearby_campaign_stories_v1(
  double precision,
  double precision,
  integer,
  text,
  text,
  integer
) to service_role;
