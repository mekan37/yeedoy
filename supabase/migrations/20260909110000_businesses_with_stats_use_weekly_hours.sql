-- B38 (mobil production-readiness denetimi): "işletme şu an açık mı" iş
-- kuralı birden fazla yerde farklı sonuç veriyordu. Kök neden tahmin
-- edilenden daha büyük çıktı: public.business_hours tablosu — bu view'ın
-- is_open_now hesaplamasının dayandığı tablo — Google Maps V5 import
-- pipeline'ından (2026-08-19) bu yana TERK EDİLMİŞ, yalnızca 1 satır
-- içeriyor (71.265 işletmenin ~%99.9'u için boş). Gerçek/güncel veri
-- public.business_weekly_hours'ta (415K+ satır, 59K+ işletme) — bu, harita
-- RPC'sinin (nearby_businesses_v2, bkz. 20260825000004 migration'ı) ve
-- get_business_hours_v1'in zaten kullandığı doğru tablo.
--
-- Sonuç: businesses_with_stats'a bağımlı HER YER (favorites_repository.dart
-- "Açık" filtresi, discovery_repository.dart, collab_list_repository.dart)
-- neredeyse tüm işletmeler için is_open_now=NULL/false görüyordu — aynı
-- işletme haritada "Açık", favorilerde "Kapalı/bilinmiyor" görünebiliyordu.
--
-- Fix: is_open_now hesaplaması business_weekly_hours + business_special_hours
-- üzerinden, nearby_businesses_v2/get_business_hours_v1 ile AYNI mantıkla
-- yeniden yazıldı. Kolon listesi/sırası/tipleri değişmedi — CREATE OR
-- REPLACE VIEW yeterli.
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
    COALESCE(p.recent_count, 0::bigint)::integer AS recent_price_verified_count
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
