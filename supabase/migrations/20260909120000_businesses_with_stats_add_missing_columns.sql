-- B61 (mobil production-readiness denetimi) araştırılırken bulundu:
-- discovery_repository.dart'ın fetchBusiness() (işletme detay sayfasının
-- TEK veri kaynağı) businesses_with_stats view'ından bare select() ile
-- okuyor, ama Business.fromMap()'in okuduğu logo_url/neighborhood/
-- price_level/accepts_reservations/reservation_* kolonları bu view'da HİÇ
-- YOKTU — halbuki public.businesses tablosunda gerçekten var. Sonuç:
-- işletme detay sayfası logo/mahalle/fiyat seviyesi/rezervasyon bilgisini
-- hep boş gösteriyordu. (image_url/cover_image_url/hero_image_url gibi
-- "işletme fotoğrafı" alanları ise şemada hiçbir yerde yok — bu ayrı,
-- hiç inşa edilmemiş bir özellik gibi duruyor, kapsam dışı bırakıldı.)
--
-- CREATE OR REPLACE VIEW sona kolon eklemeye izin verir — mevcut kolon
-- sırası/tipleri değişmedi.
CREATE OR REPLACE VIEW public.businesses_with_stats AS
 SELECT b.id,
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
    COALESCE(r.reviews_count, 0::bigint)::integer AS reviews_count,
    COALESCE(r.avg_rating, 0::numeric)::numeric(3,2) AS avg_rating,
    b.is_verified,
    (
      SELECT
        CASE
          WHEN EXISTS (
            SELECT 1 FROM public.business_special_hours sh
            WHERE sh.business_id = b.id AND sh.special_date = current_date
          ) THEN (
            SELECT NOT sh.is_closed
              AND sh.open_time IS NOT NULL
              AND (now() AT TIME ZONE 'Europe/Istanbul')::time BETWEEN sh.open_time AND sh.close_time
            FROM public.business_special_hours sh
            WHERE sh.business_id = b.id AND sh.special_date = current_date
          )
          WHEN EXISTS (
            SELECT 1 FROM public.business_weekly_hours bh
            WHERE bh.business_id = b.id
              AND bh.day_of_week = EXTRACT(DOW FROM (now() AT TIME ZONE 'Europe/Istanbul'))::smallint
          ) THEN (
            SELECT NOT bh.is_closed
              AND (now() AT TIME ZONE 'Europe/Istanbul')::time BETWEEN bh.open_time AND bh.close_time
            FROM public.business_weekly_hours bh
            WHERE bh.business_id = b.id
              AND bh.day_of_week = EXTRACT(DOW FROM (now() AT TIME ZONE 'Europe/Istanbul'))::smallint
          )
          ELSE NULL::boolean
        END
    ) AS is_open_now,
    COALESCE(p.recent_count, 0::bigint)::integer AS recent_price_verified_count,
    b.logo_url,
    b.neighborhood,
    b.price_level,
    b.accepts_reservations,
    b.reservation_phone,
    b.reservation_min_party,
    b.reservation_max_party,
    b.reservation_note
   FROM businesses b
     LEFT JOIN ( SELECT reviews.business_id,
            count(*) FILTER (WHERE reviews.status = 'approved'::text) AS reviews_count,
            avg(reviews.rating) FILTER (WHERE reviews.status = 'approved'::text) AS avg_rating
           FROM reviews
          GROUP BY reviews.business_id) r ON r.business_id = b.id
     LEFT JOIN ( SELECT menu_item_price_suggestions.business_id,
            count(*) AS recent_count
           FROM menu_item_price_suggestions
          WHERE menu_item_price_suggestions.status = 'approved'::menu_price_suggestion_status AND menu_item_price_suggestions.created_at >= (now() - '30 days'::interval)
          GROUP BY menu_item_price_suggestions.business_id) p ON p.business_id = b.id;
