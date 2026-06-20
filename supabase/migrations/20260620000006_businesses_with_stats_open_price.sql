-- businesses_with_stats: is_open_now + recent_price_verified_count kolonları eklendi
--
-- is_open_now  : business_hours tablosundan hesaplanır (Europe/Istanbul).
--                business_hours satırı yoksa NULL döner.
--                Günün open kolonları NULL ise o gün kapalı sayılır (false).
--
-- recent_price_verified_count : son 30 gün içinde onaylanan fiyat önerileri.
--                               FavoritesRepository._businessSelect bu kolonları bekliyor.

create or replace view public.businesses_with_stats
with (security_invoker = true) as
select
  b.id,
  b.name,
  b.category,
  b.description,
  b.phone,
  b.address,
  b.city,
  b.district,
  b.lat,
  b.lng,
  b.is_active,
  b.created_at,
  coalesce(r.reviews_count, 0)                         as reviews_count,
  (coalesce(r.avg_rating, 0::numeric))::numeric(3, 2)  as avg_rating,
  b.is_verified,

  -- is_open_now (Turkey time, Europe/Istanbul = UTC+3)
  case
    when bh.business_id is null then null::boolean
    else case extract(dow from (now() at time zone 'Europe/Istanbul'))::int
      when 0 then bh.sun_open is not null
              and (now() at time zone 'Europe/Istanbul')::time
                  between bh.sun_open and bh.sun_close
      when 1 then bh.mon_open is not null
              and (now() at time zone 'Europe/Istanbul')::time
                  between bh.mon_open and bh.mon_close
      when 2 then bh.tue_open is not null
              and (now() at time zone 'Europe/Istanbul')::time
                  between bh.tue_open and bh.tue_close
      when 3 then bh.wed_open is not null
              and (now() at time zone 'Europe/Istanbul')::time
                  between bh.wed_open and bh.wed_close
      when 4 then bh.thu_open is not null
              and (now() at time zone 'Europe/Istanbul')::time
                  between bh.thu_open and bh.thu_close
      when 5 then bh.fri_open is not null
              and (now() at time zone 'Europe/Istanbul')::time
                  between bh.fri_open and bh.fri_close
      when 6 then bh.sat_open is not null
              and (now() at time zone 'Europe/Istanbul')::time
                  between bh.sat_open and bh.sat_close
      else null::boolean
    end
  end as is_open_now,

  -- recent_price_verified_count: son 30 gün içinde onaylanan fiyat önerileri
  coalesce(p.recent_count, 0)::integer as recent_price_verified_count

from public.businesses b

left join (
  select
    business_id,
    count(*) filter (where status = 'approved') as reviews_count,
    avg(rating)   filter (where status = 'approved') as avg_rating
  from public.reviews
  group by business_id
) r on r.business_id = b.id

left join public.business_hours bh on bh.business_id = b.id

left join (
  select
    business_id,
    count(*) as recent_count
  from public.menu_item_price_suggestions
  where status = 'approved'
    and created_at >= now() - interval '30 days'
  group by business_id
) p on p.business_id = b.id;
