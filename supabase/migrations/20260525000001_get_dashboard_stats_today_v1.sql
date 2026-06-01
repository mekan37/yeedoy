-- get_dashboard_stats_today_v1: Personel dashboard için günlük istatistikler
-- Dart tarafındaki çoklu sorguları tek RPC'ye toplar
-- Gerçek şema: table_orders (items_json JSONB, processed_by, status: pending/seen/waiting/done)

CREATE OR REPLACE FUNCTION get_dashboard_stats_today_v1(
  p_business_id uuid
)
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_today_start timestamptz := date_trunc('day', NOW() AT TIME ZONE 'Europe/Istanbul') AT TIME ZONE 'Europe/Istanbul';
  v_result json;
BEGIN
  -- İş yeri doğrulama
  IF NOT EXISTS (
    SELECT 1 FROM businesses WHERE id = p_business_id
  ) THEN
    RAISE EXCEPTION 'İş yeri bulunamadı';
  END IF;

  SELECT json_build_object(
    'bugun_bekleyen',       (
      SELECT COUNT(*)
      FROM table_orders
      WHERE business_id = p_business_id
        AND status = 'pending'
        AND created_at >= v_today_start
    ),
    'bugun_hazirlaniyor',   (
      SELECT COUNT(*)
      FROM table_orders
      WHERE business_id = p_business_id
        AND status = 'seen'
        AND created_at >= v_today_start
    ),
    'bugun_tamamlanan',     (
      SELECT COUNT(*)
      FROM table_orders
      WHERE business_id = p_business_id
        AND status = 'done'
        AND created_at >= v_today_start
    ),
    'toplam_bugun',         (
      SELECT COUNT(*)
      FROM table_orders
      WHERE business_id = p_business_id
        AND created_at >= v_today_start
    ),
    'personel_performans',  (
      SELECT COALESCE(json_agg(
        json_build_object(
          'staff_id',    perf.processed_by,
          'siparis_sayisi', perf.siparis_sayisi,
          'tamamlanan',     perf.tamamlanan
        )
        ORDER BY perf.siparis_sayisi DESC
      ), '[]'::json)
      FROM (
        SELECT
          o.processed_by,
          COUNT(*) AS siparis_sayisi,
          COUNT(*) FILTER (WHERE o.status = 'done') AS tamamlanan
        FROM table_orders o
        WHERE o.business_id = p_business_id
          AND o.updated_at >= v_today_start
          AND o.processed_by IS NOT NULL
        GROUP BY o.processed_by
        LIMIT 10
      ) perf
    )
  ) INTO v_result;

  RETURN v_result;
END;
$$;

-- RLS: Sadece authenticated kullanıcılar erişebilir (RLS business_id ile kısıtlar)
REVOKE ALL ON FUNCTION get_dashboard_stats_today_v1(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION get_dashboard_stats_today_v1(uuid) TO authenticated;

COMMENT ON FUNCTION get_dashboard_stats_today_v1 IS
  'Personel dashboard günlük istatistiklerini tek sorguda döner. Dart client N+1 sorgularını önler. MED-009 fix.';
