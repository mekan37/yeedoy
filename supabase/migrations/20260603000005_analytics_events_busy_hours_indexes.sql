-- ============================================================
-- 20260603000005_analytics_events_busy_hours_indexes.sql
--
-- Amaç: Yoğun saat (busy hours) sorguları için analytics_events
-- tablosuna composite ve partial indexler ekle.
--
-- Plan referansı: docs/db-open-hours-price-badge-plan.md — P1
--
-- analytics_events şeması:
--   id uuid, created_at timestamptz, event_name text,
--   business_id uuid, menu_id uuid, source text,
--   client_id text, user_id uuid, meta jsonb
--
-- ROLLBACK:
--   DROP INDEX IF EXISTS public.idx_analytics_events_biz_created;
--   DROP INDEX IF EXISTS public.idx_analytics_events_name_biz_created;
-- ============================================================

-- Index 1: İşletme bazlı en son event'leri bul
-- Kullanım: WHERE business_id = $1 ORDER BY created_at DESC
--   Örn. son 28 günlük saatlik dağılım hesabı
CREATE INDEX IF NOT EXISTS idx_analytics_events_biz_created
  ON public.analytics_events(business_id, created_at DESC);

COMMENT ON INDEX public.idx_analytics_events_biz_created IS
  'Yoğun saat hesabı için business_id + created_at DESC erişim yolu. '
  'get_business_busy_hours_v1 RPC (P3 backlog) tarafından kullanılacak. '
  'Plan: docs/db-open-hours-price-badge-plan.md';

-- Index 2: Event tipi + işletme + zaman filtreleme
-- Partial index — sadece yoğun saat analizinde kullanılan event tipleri
-- Kullanım:
--   WHERE event_name IN ('menu_view','qr_scanned','business_page_view')
--   AND business_id = $1
--   AND created_at >= NOW() - INTERVAL '28 days'
CREATE INDEX IF NOT EXISTS idx_analytics_events_name_biz_created
  ON public.analytics_events(event_name, business_id, created_at DESC)
  WHERE event_name IN ('menu_view', 'qr_scanned', 'business_page_view');

COMMENT ON INDEX public.idx_analytics_events_name_biz_created IS
  'Partial index: menu_view / qr_scanned / business_page_view event tiplerinde '
  'business_id + created_at DESC sorgusu için. '
  'get_business_busy_hours_v1 RPC (P3 backlog) tarafından kullanılacak. '
  'Plan: docs/db-open-hours-price-badge-plan.md';
