-- Geliştirici Araçları sayfası için: gerçek DB sağlık metriği (aktif bağlantı
-- sayısı + DB boyutu). pg_stat_activity system catalog'una authenticated
-- rolünden doğrudan erişim garanti değil (bazı kolonlar superuser/pg_monitor
-- dışında maskelenir) — SECURITY DEFINER ile sarmalanıyor, mevcut RPC
-- konvansiyonuyla tutarlı.

CREATE OR REPLACE FUNCTION public.admin_db_health_v1()
RETURNS TABLE(active_connections integer, db_size_bytes bigint)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'unauthorized' USING ERRCODE = 'P0002';
  END IF;

  RETURN QUERY
  SELECT
    (SELECT count(*)::integer FROM pg_stat_activity WHERE datname = current_database()),
    pg_database_size(current_database());
END;
$$;

REVOKE ALL ON FUNCTION public.admin_db_health_v1() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.admin_db_health_v1() TO authenticated;
REVOKE EXECUTE ON FUNCTION public.admin_db_health_v1() FROM anon;
COMMENT ON FUNCTION public.admin_db_health_v1 IS 'Gerçek DB sağlık metrikleri: aktif bağlantı sayısı ve veritabanı boyutu. Called by: app/yonetici/gelistirme-araclari/page.tsx.';
