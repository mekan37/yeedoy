-- ============================================================
-- 20260526000002_planned_rpc_stubs.sql
-- Planlanmış RPC Taslakları — API Kontrat Denetimi 2026-05-26
--
-- Bu dosya tespit edilen N+1 sorgu örüntüleri ve eksik RPC'ler için
-- placeholder tanımları içerir.  Her fonksiyon şu an yalnızca
-- 'not_implemented' hatası fırlatır; gerçek implementasyon ayrı
-- migration dosyasında yapılmalıdır.
--
-- Güvenlik notu: Tüm stub'lar idempotent (CREATE OR REPLACE) ve
-- SECURITY DEFINER + sabit search_path ile tanımlanmıştır.
-- ============================================================

-- ── 1. get_dashboard_weekly_v1 ────────────────────────────────────────────────
-- Mevcut durum: Dart DashboardIstatistikBildiricisi içinde
--   supabase.from('table_orders').select() + supabase.from('table_order_items').select()
--   şeklinde 2 ayrı sorgu yapılmakta (haftalikVeriProvider).
-- Hedef: Bu iki sorguyu tek RPC'ye topla ve saatlik/günlük veriyi sunucu tarafında hesapla.
-- Referans dosya: uygulamalar/personel/lib/features/dashboard/domain/dashboard_istatistik_saglayicisi.dart
CREATE OR REPLACE FUNCTION public.get_dashboard_weekly_v1(
  p_business_id uuid,
  p_days        int DEFAULT 7
)
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- TODO: implement — haftalık sipariş + gelir verisini tek sorguda döndür
  -- Beklenen çıktı:
  -- {
  --   "gunluk": [{ "gun": "2026-05-20", "siparis_sayisi": 12, "gelir": 1500.0 }, ...],
  --   "saatlik": [{ "saat": 12, "siparis_sayisi": 3 }, ...]
  -- }
  RAISE EXCEPTION 'not_implemented: get_dashboard_weekly_v1 henüz implement edilmedi'
    USING ERRCODE = 'P0004';
END;
$$;

REVOKE ALL ON FUNCTION public.get_dashboard_weekly_v1(uuid, int) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_dashboard_weekly_v1(uuid, int) TO authenticated;

COMMENT ON FUNCTION public.get_dashboard_weekly_v1 IS
  'STUB — Personel dashboard haftalık sipariş + gelir özeti. '
  'N+1 fix: table_orders + table_order_items birleştir. '
  'dashboard_istatistik_saglayicisi.dart içindeki çift sorguyu kaldırır.';


-- ── 2. get_staff_performance_today_v1 ────────────────────────────────────────
-- 2026-07-23 fix: bu stub kaldırıldı. get_staff_performance_today_v1 aslında
-- 20260522000003_table_orders_processed_by.sql'de GERÇEK, çalışan bir
-- implementasyona sahip (RETURNS TABLE(staff_id, siparis_sayisi, tamamlanan)).
-- Bu stub onu "not_implemented" fırlatan bir json-dönen sürümle EZİYORDU —
-- CREATE OR REPLACE dönüş tipi değiştiremediği için fresh reset'te patlıyordu,
-- ama patlamasaydı bile gerçek özelliği kırardı. Bu dosyanın kendi yorumu da
-- ("Bu stub gerekli OLMADIĞINDA buradan kaldırılabilir") bu belirsizliği
-- zaten işaret ediyordu.


-- ── 3. get_menu_items_with_counts_v1 ─────────────────────────────────────────
-- Mevcut durum: DashboardIstatistikBildiricisi içinde
--   supabase.from('menu_items').select('is_available').eq('business_id', ...)
--   şeklinde ayrı bir sorgu yapılıyor (get_dashboard_stats_today_v1 bunu kapsamıyor).
-- Hedef: Menü kalem sayısını (aktif/pasif) tek RPC'ye dahil et.
CREATE OR REPLACE FUNCTION public.get_menu_item_counts_v1(
  p_business_id uuid
)
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- TODO: implement
  -- Beklenen çıktı: { "aktif": 42, "pasif": 8, "toplam": 50 }
  RAISE EXCEPTION 'not_implemented: get_menu_item_counts_v1 henüz implement edilmedi'
    USING ERRCODE = 'P0004';
END;
$$;

REVOKE ALL ON FUNCTION public.get_menu_item_counts_v1(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_menu_item_counts_v1(uuid) TO authenticated;

COMMENT ON FUNCTION public.get_menu_item_counts_v1 IS
  'STUB — Menü kalem aktif/pasif sayısı. '
  'Alternatif: get_dashboard_stats_today_v1 genişletilerek menu_item_counts alanı eklenebilir.';


-- ── 4. admin_get_overview_stats_v1 ───────────────────────────────────────────
-- Mevcut durum: Admin panel birden fazla tablodan ayrı ayrı COUNT sorgusu çekiyor.
-- Hedef: claims + reports + suggestions sayılarını tek admin RPC'de topla.
CREATE OR REPLACE FUNCTION public.admin_get_overview_stats_v1()
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- TODO: implement
  -- Beklenen çıktı:
  -- {
  --   "pending_claims": 5,
  --   "pending_reports": 12,
  --   "pending_suggestions": 3,
  --   "suspended_claims_sla_breach": 2
  -- }
  RAISE EXCEPTION 'not_implemented: admin_get_overview_stats_v1 henüz implement edilmedi'
    USING ERRCODE = 'P0004';
END;
$$;

REVOKE ALL ON FUNCTION public.admin_get_overview_stats_v1() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.admin_get_overview_stats_v1() TO authenticated;

COMMENT ON FUNCTION public.admin_get_overview_stats_v1 IS
  'STUB — Admin genel bakış istatistikleri. '
  'N+1 fix: admin_get_queues_counts_v1 ile birleştirilebilir.';


-- ── 5. get_business_full_profile_v1 ──────────────────────────────────────────
-- Mevcut durum: Web public-menu-client.tsx get_business_detail_v1 + get_business_hours_v1
-- şeklinde ardışık 2 RPC çağrısı yapıyor.
-- Hedef: İşletme profili + çalışma saatleri + menü özeti tek RPC'de.
CREATE OR REPLACE FUNCTION public.get_business_full_profile_v1(
  p_business_id       uuid,
  p_latest_reviews    int DEFAULT 5,
  p_include_hours     boolean DEFAULT true
)
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- TODO: implement — get_business_detail_v1 + get_business_hours_v1 birleştir
  RAISE EXCEPTION 'not_implemented: get_business_full_profile_v1 henüz implement edilmedi'
    USING ERRCODE = 'P0004';
END;
$$;

REVOKE ALL ON FUNCTION public.get_business_full_profile_v1(uuid, int, boolean) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_business_full_profile_v1(uuid, int, boolean)
  TO anon, authenticated;

COMMENT ON FUNCTION public.get_business_full_profile_v1 IS
  'STUB — İşletme tam profil (detay + saatler + menü özeti). '
  'Mevcut get_business_detail_v1 + get_business_hours_v1 çağrılarını birleştirir.';
