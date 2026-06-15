-- Kampanyalar tab redesign: discount/category/featured metadata on campaign
-- stories, a saved_campaigns bookmark table, and v2 RPCs that expose them.

alter table public.business_stories
  add column discount_percent smallint,
  add column category text,
  add column is_featured boolean not null default false;

alter table public.business_stories
  add constraint business_stories_discount_percent_check
    check (discount_percent is null or (discount_percent >= 0 and discount_percent <= 100));

alter table public.business_stories
  add constraint business_stories_category_check
    check (category is null or category in ('yemek', 'tatli', 'icecek', 'kahve', 'diger'));

create table if not exists public.saved_campaigns (
  id uuid default gen_random_uuid() not null primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  story_id uuid not null references public.business_stories(id) on delete cascade,
  created_at timestamptz not null default now(),
  unique (user_id, story_id)
);

alter table public.saved_campaigns enable row level security;

create policy saved_campaigns_select_own on public.saved_campaigns
  for select using (auth.uid() = user_id);

create policy saved_campaigns_insert_own on public.saved_campaigns
  for insert with check (auth.uid() = user_id);

create policy saved_campaigns_delete_own on public.saved_campaigns
  for delete using (auth.uid() = user_id);

-- get_nearby_campaign_stories_v2: adds discount_percent/category/is_featured/is_saved
-- and orders featured campaigns first.
create or replace function public.get_nearby_campaign_stories_v2(
  p_lat double precision default null,
  p_lng double precision default null,
  p_radius_km integer default 10,
  p_city text default null,
  p_district text default null,
  p_limit integer default 20
)
returns table (
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
  distance_km double precision,
  discount_percent smallint,
  category text,
  is_featured boolean,
  is_saved boolean
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
      s.discount_percent,
      s.category,
      s.is_featured,
      exists (
        select 1 from public.saved_campaigns sc
        where sc.user_id = auth.uid() and sc.story_id = s.id
      ) as is_saved,
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
    distance_km,
    discount_percent,
    category,
    is_featured,
    is_saved
  from src
  where distance_km is null or distance_km <= greatest(coalesce(p_radius_km, 10), 1)
  order by is_featured desc, distance_km nulls last, created_at desc
  limit greatest(coalesce(p_limit, 20), 1);
$$;

grant execute on function public.get_nearby_campaign_stories_v2(double precision, double precision, integer, text, text, integer) to anon;
grant execute on function public.get_nearby_campaign_stories_v2(double precision, double precision, integer, text, text, integer) to authenticated;
grant execute on function public.get_nearby_campaign_stories_v2(double precision, double precision, integer, text, text, integer) to service_role;

comment on function public.get_nearby_campaign_stories_v1(double precision, double precision, integer, text, text, integer) is 'DEPRECATED 2026-06-13: use get_nearby_campaign_stories_v2';

-- toggle_saved_campaign_v1: bookmark/unbookmark a campaign story for the current user
create or replace function public.toggle_saved_campaign_v1(p_story_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_existing uuid;
  v_saved boolean;
begin
  if auth.uid() is null then
    raise exception 'unauthorized: Oturum açmanız gerekiyor' using errcode = 'P0002';
  end if;

  if not exists (
    select 1 from public.business_stories
    where id = p_story_id and is_deleted = false
  ) then
    raise exception 'not_found: Kampanya bulunamadı' using errcode = 'P0001';
  end if;

  select id into v_existing from public.saved_campaigns
    where user_id = auth.uid() and story_id = p_story_id;

  if v_existing is null then
    insert into public.saved_campaigns (user_id, story_id) values (auth.uid(), p_story_id);
    v_saved := true;
  else
    delete from public.saved_campaigns where id = v_existing;
    v_saved := false;
  end if;

  return jsonb_build_object('saved', v_saved);
end;
$$;

revoke all on function public.toggle_saved_campaign_v1(uuid) from public;
grant execute on function public.toggle_saved_campaign_v1(uuid) to authenticated;
comment on function public.toggle_saved_campaign_v1 is 'Toggles a saved/bookmarked campaign for the current user. Called by: discovery_repository.dart toggleSavedCampaign.';
