-- ============================================================
-- 20260603000006_business_busy_hours_rpc.sql
--
-- Amaç: Belirli bir işletme için yoğun saat dağılımını döndür.
-- Son N günlük (varsayılan 28) veride saat bazlı ağırlıklı
-- event sayısı hesaplanır. Tüm 24 saat döner; veri yoksa 0.
--
-- Hesaplama ağırlıkları:
--   analytics_events (menu_view, qr_scanned, business_page_view) → 1x
--   table_orders (gerçek sipariş sinyali, daha güçlü)            → 3x
-- Ağırlıklı toplam / gün sayısı → avg_event_count
-- peak_rank: en yoğun saat 1, en az yoğun saat 24.
--
-- Auth: anon + authenticated GRANT (sadece aggregate, bireysel
-- kullanıcı/event verisi yok). Public işletme sayfasında
-- "Yoğun Saatler" widget için kullanılabilir.
-- PR'da Risk: MEDIUM (yeni public RPC).
--
-- Plan referansı: docs/db-open-hours-price-badge-plan.md — P3
--
-- ROLLBACK:
--   DROP FUNCTION IF EXISTS public.get_business_busy_hours_v1(uuid, integer);
-- ============================================================

CREATE OR REPLACE FUNCTION public.get_business_busy_hours_v1(
  p_business_id uuid,
  p_days_back   integer DEFAULT 28
)
RETURNS TABLE(
  hour_of_day      smallint,
  event_count      bigint,
  avg_event_count  numeric,
  peak_rank        smallint
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
WITH
-- Zaman sınırını hesapla (Europe/Istanbul'da günün başı)
params AS (
  SELECT
    -- p_days_back sınırı: min 1, max 90
    GREATEST(1, LEAST(COALESCE(p_days_back, 28), 90)) AS days_back
),

-- analytics_events sinyali (ağırlık: 1)
analytics_signal AS (
  SELECT
    EXTRACT(HOUR FROM ae.created_at AT TIME ZONE 'Europe/Istanbul')::smallint AS h,
    COUNT(*)                                                                   AS cnt
  FROM analytics_events ae, params p
  WHERE ae.business_id = p_business_id
    AND ae.event_name IN ('menu_view', 'qr_scanned', 'business_page_view')
    AND ae.created_at >= NOW() - (p.days_back || ' days')::interval
  GROUP BY 1
),

-- table_orders sinyali (gerçek sipariş — daha güçlü, ağırlık: 3)
order_signal AS (
  SELECT
    EXTRACT(HOUR FROM tor.created_at AT TIME ZONE 'Europe/Istanbul')::smallint AS h,
    COUNT(*) * 3                                                                AS cnt
  FROM table_orders tor, params p
  WHERE tor.business_id = p_business_id
    AND tor.created_at >= NOW() - (p.days_back || ' days')::interval
  GROUP BY 1
),

-- Tüm 24 saati üret; eksik saatler 0 ile dolar
all_hours AS (
  SELECT generate_series(0, 23)::smallint AS h
),

-- Sinyalleri birleştir
combined AS (
  SELECT
    ah.h,
    COALESCE(a.cnt, 0) + COALESCE(o.cnt, 0) AS weighted_count
  FROM all_hours ah
  LEFT JOIN analytics_signal a ON a.h = ah.h
  LEFT JOIN order_signal     o ON o.h = ah.h
)

-- Son hesaplama: avg (gün sayısına böl) + peak_rank
SELECT
  c.h                                                        AS hour_of_day,
  c.weighted_count                                           AS event_count,
  ROUND(
    c.weighted_count::numeric / GREATEST((SELECT days_back FROM params), 1),
    2
  )                                                          AS avg_event_count,
  RANK() OVER (ORDER BY c.weighted_count DESC)::smallint    AS peak_rank
FROM combined c
ORDER BY c.h;
$$;

-- Bireysel veri dönmüyor (sadece aggregate) → anon + authenticated
REVOKE ALL ON FUNCTION public.get_business_busy_hours_v1(uuid, integer) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_business_busy_hours_v1(uuid, integer) TO anon;
GRANT EXECUTE ON FUNCTION public.get_business_busy_hours_v1(uuid, integer) TO authenticated;

COMMENT ON FUNCTION public.get_business_busy_hours_v1 IS
  'İşletme için yoğun saat dağılımı (son 28 gün varsayılan). '
  'analytics_events (1x) + table_orders (3x ağırlık). '
  'Tüm 24 saat döner; veri yoksa event_count = 0. '
  'peak_rank: en yoğun = 1. '
  'Sadece aggregate veri — bireysel event/kullanıcı bilgisi yok. '
  'Caller: owner panel "Yoğun Saatler" widget, public işletme sayfası. '
  'Plan: docs/db-open-hours-price-badge-plan.md P3.';
