-- Fiyat Raporu sayfası yeniden tasarlanırken (min/maks fiyat, rakip işletme
-- listesi, kategori) gerçek veriye dayanması için mevcut RPC genişletildi ve
-- yeni bir RPC eklendi. Sahte "güven skoru" veya "fiyat trendi" eklenmedi —
-- bunlar için hiç veri kaynağı yok (menu_item_price_history şu an boş).

-- ── get_business_price_comparison_v1 (min/maks + kategori eklendi) ─────────
DROP FUNCTION IF EXISTS public.get_business_price_comparison_v1(uuid, integer);

CREATE OR REPLACE FUNCTION public.get_business_price_comparison_v1(
  p_business_id uuid,
  p_limit integer DEFAULT 20
)
RETURNS TABLE(
  menu_item_id uuid,
  item_name text,
  category text,
  business_price_cents integer,
  city_avg_cents integer,
  city_min_cents integer,
  city_max_cents integer,
  district_avg_cents integer,
  city_sample_count integer,
  diff_pct numeric
)
LANGUAGE plpgsql
STABLE SECURITY DEFINER
SET search_path TO 'public', 'extensions'
AS $function$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM public.owner_claims oc
    WHERE oc.business_id = p_business_id
      AND oc.user_id = auth.uid()
      AND oc.status = 'approved'
  ) AND NOT public.is_admin() THEN
    RAISE EXCEPTION 'unauthorized' USING ERRCODE = 'P0002';
  END IF;

  RETURN QUERY
  WITH biz_city AS (
    SELECT city, district FROM public.businesses WHERE id = p_business_id LIMIT 1
  ),
  my_items AS (
    SELECT
      mi.id AS menu_item_id,
      mi.name AS item_name,
      ms.title AS category,
      mi.price_cents AS business_price_cents
    FROM public.menu_items mi
    JOIN public.menu_sections ms ON ms.id = mi.section_id
    JOIN public.menus m ON m.id = ms.menu_id
    WHERE m.business_id = p_business_id
      AND m.status = 'published'
      AND mi.is_available = TRUE
      AND mi.price_cents IS NOT NULL
      AND mi.price_cents > 0
    ORDER BY mi.name
    LIMIT p_limit
  ),
  city_match AS (
    SELECT
      my.menu_item_id,
      ROUND(AVG(x.price_cents))::INT AS avg_cents,
      MIN(x.price_cents)::INT AS min_cents,
      MAX(x.price_cents)::INT AS max_cents,
      COUNT(DISTINCT x.business_id)::INT AS sample_count
    FROM my_items my
    CROSS JOIN biz_city bc
    JOIN LATERAL (
      SELECT mi2.price_cents, b2.id AS business_id
      FROM public.menu_items mi2
      JOIN public.menu_sections ms2 ON ms2.id = mi2.section_id
      JOIN public.menus m2 ON m2.id = ms2.menu_id AND m2.status = 'published'
      JOIN public.businesses b2 ON b2.id = m2.business_id AND b2.is_active = TRUE
      WHERE b2.city = bc.city
        AND b2.id <> p_business_id
        AND mi2.price_cents > 0
        AND mi2.is_available = TRUE
        AND lower(mi2.name) % lower(my.item_name)
        AND similarity(lower(mi2.name), lower(my.item_name)) >= 0.45
    ) x ON TRUE
    GROUP BY my.menu_item_id
  ),
  district_match AS (
    SELECT
      my.menu_item_id,
      ROUND(AVG(x.price_cents))::INT AS avg_cents
    FROM my_items my
    CROSS JOIN biz_city bc
    JOIN LATERAL (
      SELECT mi2.price_cents
      FROM public.menu_items mi2
      JOIN public.menu_sections ms2 ON ms2.id = mi2.section_id
      JOIN public.menus m2 ON m2.id = ms2.menu_id AND m2.status = 'published'
      JOIN public.businesses b2 ON b2.id = m2.business_id AND b2.is_active = TRUE
      WHERE b2.district = bc.district
        AND b2.id <> p_business_id
        AND mi2.price_cents > 0
        AND mi2.is_available = TRUE
        AND lower(mi2.name) % lower(my.item_name)
        AND similarity(lower(mi2.name), lower(my.item_name)) >= 0.45
    ) x ON TRUE
    GROUP BY my.menu_item_id
  )
  SELECT
    my.menu_item_id,
    my.item_name,
    my.category,
    my.business_price_cents,
    COALESCE(ca.avg_cents, 0) AS city_avg_cents,
    COALESCE(ca.min_cents, 0) AS city_min_cents,
    COALESCE(ca.max_cents, 0) AS city_max_cents,
    COALESCE(da.avg_cents, 0) AS district_avg_cents,
    COALESCE(ca.sample_count, 0) AS city_sample_count,
    CASE
      WHEN ca.avg_cents IS NULL OR ca.avg_cents = 0 THEN 0
      ELSE ROUND(((my.business_price_cents - ca.avg_cents)::NUMERIC / ca.avg_cents) * 100, 1)
    END AS diff_pct
  FROM my_items my
  LEFT JOIN city_match ca ON ca.menu_item_id = my.menu_item_id
  LEFT JOIN district_match da ON da.menu_item_id = my.menu_item_id
  WHERE ca.avg_cents IS NOT NULL
  ORDER BY ABS(
    CASE WHEN ca.avg_cents = 0 THEN 0
    ELSE ((my.business_price_cents - ca.avg_cents)::NUMERIC / ca.avg_cents) * 100
    END
  ) DESC;
END;
$function$;

GRANT EXECUTE ON FUNCTION public.get_business_price_comparison_v1(uuid, integer) TO authenticated;
COMMENT ON FUNCTION public.get_business_price_comparison_v1(uuid, integer) IS
  'İşletmenin fiyatlı menü ürünlerini şehirdeki benzer isimli ürünlerle (trigram ≥0.45) karşılaştırır. '
  'min/maks fiyat ve kategori (menu_sections.title) dahildir. Called by: app/sahip/fiyat-raporu/page.tsx.';

-- ── get_business_price_competitors_v1 (yeni) ────────────────────────────────
CREATE OR REPLACE FUNCTION public.get_business_price_competitors_v1(
  p_business_id uuid,
  p_limit int DEFAULT 8
)
RETURNS TABLE(
  business_id uuid,
  city text,
  district text,
  category text,
  matched_items int
)
LANGUAGE plpgsql
STABLE SECURITY DEFINER
SET search_path TO 'public', 'extensions'
AS $function$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM public.owner_claims oc
    WHERE oc.business_id = p_business_id
      AND oc.user_id = auth.uid()
      AND oc.status = 'approved'
  ) AND NOT public.is_admin() THEN
    RAISE EXCEPTION 'unauthorized' USING ERRCODE = 'P0002';
  END IF;

  RETURN QUERY
  WITH biz_city AS (
    SELECT city FROM public.businesses WHERE id = p_business_id LIMIT 1
  ),
  my_items AS (
    SELECT mi.id, mi.name
    FROM public.menu_items mi
    JOIN public.menu_sections ms ON ms.id = mi.section_id
    JOIN public.menus m ON m.id = ms.menu_id
    WHERE m.business_id = p_business_id
      AND m.status = 'published'
      AND mi.is_available = TRUE
      AND mi.price_cents > 0
  )
  SELECT b2.id, b2.city, b2.district, b2.category, count(DISTINCT mi.id)::int AS matched_items
  FROM my_items mi
  CROSS JOIN biz_city bc
  JOIN LATERAL (
    SELECT mi2.id AS item2_id, b3.id AS business_id
    FROM public.menu_items mi2
    JOIN public.menu_sections ms2 ON ms2.id = mi2.section_id
    JOIN public.menus m2 ON m2.id = ms2.menu_id AND m2.status = 'published'
    JOIN public.businesses b3 ON b3.id = m2.business_id AND b3.is_active = TRUE
    WHERE b3.city = bc.city
      AND b3.id <> p_business_id
      AND mi2.price_cents > 0
      AND mi2.is_available = TRUE
      AND lower(mi2.name) % lower(mi.name)
      AND similarity(lower(mi2.name), lower(mi.name)) >= 0.45
  ) x ON TRUE
  JOIN public.businesses b2 ON b2.id = x.business_id
  GROUP BY b2.id, b2.city, b2.district, b2.category
  ORDER BY count(DISTINCT mi.id) DESC
  LIMIT p_limit;
END;
$function$;

REVOKE ALL ON FUNCTION public.get_business_price_competitors_v1(uuid, int) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_business_price_competitors_v1(uuid, int) TO authenticated;
COMMENT ON FUNCTION public.get_business_price_competitors_v1(uuid, int) IS
  'İşletmeyle en çok fiyat karşılaştırması eşleşen rakip işletmeleri (anonim — sadece şehir/ilçe/kategori) döner. '
  'Called by: app/sahip/fiyat-raporu/page.tsx.';
