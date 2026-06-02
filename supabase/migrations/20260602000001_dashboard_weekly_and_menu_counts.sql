-- 20260602000001_dashboard_weekly_and_menu_counts.sql
-- Implements:
--   get_dashboard_weekly_v1  — replaces N+1 queries in HaftalikVeriBildiricisi
--   get_menu_item_counts_v1  — replaces raw menu_items query in DashboardIstatistikBildiricisi
-- Called by: uygulamalar/personel/lib/features/dashboard/domain/dashboard_istatistik_saglayicisi.dart

-- ── get_dashboard_weekly_v1 ────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION public.get_dashboard_weekly_v1(
  p_business_id uuid,
  p_days        int DEFAULT 7
)
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_tz        text := 'Europe/Istanbul';
  v_start     timestamptz;
  v_today_start timestamptz;
  v_result    json;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'unauthorized' USING ERRCODE = 'P0002';
  END IF;

  v_today_start := date_trunc('day', NOW() AT TIME ZONE v_tz) AT TIME ZONE v_tz;
  v_start       := v_today_start - ((p_days - 1) || ' days')::interval;

  SELECT json_build_object(
    'gunluk',  (
      SELECT COALESCE(json_agg(row_to_json(g) ORDER BY g.gun), '[]'::json)
      FROM (
        SELECT
          to_char(
            date_trunc('day', o.created_at AT TIME ZONE v_tz),
            'YYYY-MM-DD'
          )                              AS gun,
          COUNT(*)::int                  AS siparis_sayisi,
          -- gelir: items_json içindeki her kalem için menu_items.price_cents JOIN
          -- (name eşleşmesi, yaklaşık; uyuşmazlık sıfır sayılır)
          COALESCE(SUM(
            (
              SELECT COALESCE(SUM(
                (item->>'qty')::int * COALESCE(mi.price_cents, 0) / 100.0
              ), 0)
              FROM jsonb_array_elements(o.items_json) AS item
              LEFT JOIN menu_items mi
                ON mi.business_id = o.business_id
               AND mi.name        = (item->>'name')
            )
          ), 0)::float                   AS gelir
        FROM table_orders o
        WHERE o.business_id = p_business_id
          AND o.created_at >= v_start
        GROUP BY date_trunc('day', o.created_at AT TIME ZONE v_tz)
      ) g
    ),
    'saatlik', (
      SELECT COALESCE(json_agg(row_to_json(s) ORDER BY s.saat), '[]'::json)
      FROM (
        SELECT
          EXTRACT(HOUR FROM o.created_at AT TIME ZONE v_tz)::int AS saat,
          COUNT(*)::int AS siparis_sayisi
        FROM table_orders o
        WHERE o.business_id = p_business_id
          AND o.created_at >= v_today_start
        GROUP BY EXTRACT(HOUR FROM o.created_at AT TIME ZONE v_tz)
      ) s
    )
  ) INTO v_result;

  RETURN v_result;
END;
$$;

REVOKE ALL ON FUNCTION public.get_dashboard_weekly_v1(uuid, int) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_dashboard_weekly_v1(uuid, int) TO authenticated;

COMMENT ON FUNCTION public.get_dashboard_weekly_v1 IS
  'Personel dashboard haftalık sipariş + gelir (günlük) ve saatlik sipariş özeti. '
  'Gelir: items_json[].name → menu_items.price_cents isim eşleşmesi (yaklaşık). '
  'Called by: dashboard_istatistik_saglayicisi.dart HaftalikVeriBildiricisi + SaatlikVeriBildiricisi.';


-- ── get_menu_item_counts_v1 ────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION public.get_menu_item_counts_v1(
  p_business_id uuid
)
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_aktif  int;
  v_pasif  int;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'unauthorized' USING ERRCODE = 'P0002';
  END IF;

  SELECT
    COUNT(*) FILTER (WHERE is_available = true),
    COUNT(*) FILTER (WHERE is_available = false)
  INTO v_aktif, v_pasif
  FROM menu_items
  WHERE business_id = p_business_id;

  RETURN json_build_object(
    'aktif',   v_aktif,
    'pasif',   v_pasif,
    'toplam',  v_aktif + v_pasif
  );
END;
$$;

REVOKE ALL ON FUNCTION public.get_menu_item_counts_v1(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_menu_item_counts_v1(uuid) TO authenticated;

COMMENT ON FUNCTION public.get_menu_item_counts_v1 IS
  'Menü kalem aktif/pasif sayısı. '
  'Called by: dashboard_istatistik_saglayicisi.dart DashboardIstatistikBildiricisi.';
