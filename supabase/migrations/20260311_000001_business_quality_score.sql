create or replace view public.business_quality_score_v1 as
with menu_items_base as (
  select mi.business_id, mi.id
  from public.menu_items mi
  where mi.status = 'published'
),
verified_stats as (
  select
    mb.business_id,
    count(*)::int as total_items,
    count(*) filter (where ps.price_status = 'verified')::int as verified_items
  from menu_items_base mb
  left join public.menu_item_price_status_v1 ps on ps.menu_item_id = mb.id
  group by mb.business_id
),
last_updates as (
  select
    l.business_id,
    max(l.created_at) filter (where l.type = 'menu_update') as last_menu_update_at
  from public.business_activity_log l
  group by l.business_id
),
photos as (
  select bm.business_id, count(*)::int as photos_count
  from public.business_media bm
  group by bm.business_id
),
amenities as (
  select bam.business_id, count(*)::int as amenities_count
  from public.business_amenity_map bam
  group by bam.business_id
),
pricing as (
  select
    b.id as business_id,
    (pr.business_id is not null) as has_pricing_rule,
    (
      bf.business_id is not null
      and (
        bf.has_cover_charge is not null
        or bf.has_service_fee is not null
        or bf.bottled_water_paid is not null
      )
    ) as has_fee_flags
  from public.businesses b
  left join public.business_pricing_rules pr on pr.business_id = b.id
  left join public.business_fee_flags bf on bf.business_id = b.id
),
weekly_votes as (
  select
    mi.business_id,
    count(*) filter (where v.vote = 1 and v.created_at >= now() - interval '7 days')::int as weekly_verified_votes
  from public.menu_item_price_votes v
  join public.menu_items mi on mi.id = v.menu_item_id
  group by mi.business_id
),
scored as (
  select
    b.id as business_id,
    coalesce(vs.total_items, 0) as total_items,
    coalesce(vs.verified_items, 0) as verified_items,
    coalesce(lu.last_menu_update_at, b.created_at) as last_menu_update_at,
    coalesce(p.photos_count, 0) as photos_count,
    coalesce(a.amenities_count, 0) as amenities_count,
    coalesce(pr.has_pricing_rule, false) as has_pricing_rule,
    coalesce(pr.has_fee_flags, false) as has_fee_flags,
    coalesce(wv.weekly_verified_votes, 0) as weekly_verified_votes
  from public.businesses b
  left join verified_stats vs on vs.business_id = b.id
  left join last_updates lu on lu.business_id = b.id
  left join photos p on p.business_id = b.id
  left join amenities a on a.business_id = b.id
  left join pricing pr on pr.business_id = b.id
  left join weekly_votes wv on wv.business_id = b.id
),
points as (
  select
    s.*,
    case
      when s.total_items = 0 then 0
      else least(40, round((s.verified_items::numeric / nullif(s.total_items, 0)::numeric) * 40))::int
    end as verified_points,
    case
      when s.last_menu_update_at >= now() - interval '3 days' then 20
      when s.last_menu_update_at >= now() - interval '7 days' then 16
      when s.last_menu_update_at >= now() - interval '14 days' then 10
      when s.last_menu_update_at >= now() - interval '30 days' then 5
      else 0
    end as recency_points,
    least(15, round((least(s.photos_count, 3)::numeric / 3.0) * 15))::int as photos_points,
    least(10, round((least(s.amenities_count, 4)::numeric / 4.0) * 10))::int as amenities_points,
    ((case when s.has_pricing_rule then 8 else 0 end) + (case when s.has_fee_flags then 7 else 0 end))::int as pricing_points
  from scored s
)
select
  p.business_id,
  greatest(0, least(100, p.verified_points + p.recency_points + p.photos_points + p.amenities_points + p.pricing_points))::int as score,
  p.verified_points,
  p.recency_points,
  p.photos_points,
  p.amenities_points,
  p.pricing_points,
  p.total_items,
  p.verified_items,
  p.last_menu_update_at,
  p.photos_count,
  p.amenities_count,
  p.has_pricing_rule,
  p.has_fee_flags,
  p.weekly_verified_votes
from points p;

create or replace function public.get_business_quality_score_v1(
  p_business_id uuid
)
returns jsonb
language plpgsql
stable
security definer
set search_path to 'public'
as $function$
declare
  v_row public.business_quality_score_v1%rowtype;
  v_tips text[] := array[]::text[];
begin
  if not (public.is_admin() or public.is_owner_of_business(p_business_id)) then
    return jsonb_build_object(
      'score', 0,
      'tips', jsonb_build_array('Bu skor icin isletme sahibi olmalisin.'),
      'breakdown', jsonb_build_object('error', 'not_owner')
    );
  end if;

  select * into v_row
  from public.business_quality_score_v1 q
  where q.business_id = p_business_id;

  if not found then
    return jsonb_build_object(
      'score', 0,
      'tips', jsonb_build_array('Isletme bulunamadi.'),
      'breakdown', jsonb_build_object('error', 'not_found')
    );
  end if;

  if v_row.amenities_count < 2 then
    v_tips := array_append(v_tips, '2 amenities daha ekle');
  end if;
  if v_row.photos_count < 3 then
    v_tips := array_append(v_tips, 'Menuye 3 foto ekle');
  end if;
  if not v_row.has_fee_flags then
    v_tips := array_append(v_tips, 'Kuver/servis bilgisini dogrula');
  end if;
  if v_row.weekly_verified_votes < 1 then
    v_tips := array_append(v_tips, 'Bu hafta 1 fiyat teyidi al');
  end if;
  if v_row.last_menu_update_at < now() - interval '7 days' then
    v_tips := array_append(v_tips, 'Menunu bu hafta guncelle');
  end if;

  return jsonb_build_object(
    'score', v_row.score,
    'tips', to_jsonb(v_tips),
    'breakdown', jsonb_build_object(
      'verified_ratio_points', v_row.verified_points,
      'recency_points', v_row.recency_points,
      'photos_points', v_row.photos_points,
      'amenities_points', v_row.amenities_points,
      'pricing_points', v_row.pricing_points,
      'verified_items', v_row.verified_items,
      'total_items', v_row.total_items,
      'photos_count', v_row.photos_count,
      'amenities_count', v_row.amenities_count,
      'has_pricing_rule', v_row.has_pricing_rule,
      'has_fee_flags', v_row.has_fee_flags,
      'weekly_verified_votes', v_row.weekly_verified_votes,
      'last_menu_update_at', v_row.last_menu_update_at
    )
  );
end;
$function$;
