-- get_business_price_comparison_v1: exact case-insensitive name match ('lower(mi.name) = lower(mi2.name)')
-- almost never finds a comparison at real-world scale (menu names vary too much between businesses,
-- e.g. "Adana Kebap" vs "Acılı Adana Kebap" vs "Kebap - Adana"), so the owner-panel "Fiyat Raporu"
-- page renders its empty state for virtually every business. This replaces the exact match with
-- pg_trgm fuzzy matching via the '%' operator, which can use the existing idx_menu_items_name_trgm
-- GIN index (defined on lower(menu_items.name) in 00000000000000_base_schema.sql).
--
-- Threshold: the final cutoff is similarity >= 0.45 (pg_trgm's own default threshold is 0.3). We do NOT
-- set the pg_trgm.similarity_threshold GUC (setting it via CREATE FUNCTION's SET clause hit "permission
-- denied to set parameter" for the local migration role) — instead each comparison uses the standard
-- two-predicate idiom: 'lower(a) % lower(b)' first, which is index-accelerated by idx_menu_items_name_trgm
-- via the default (0.3) threshold and cheaply narrows candidates, followed by an explicit
-- 'similarity(lower(a), lower(b)) >= 0.45' to apply our tighter, precise cutoff on that candidate set.
-- Hand-tested locally with representative Turkish menu-item name pairs:
--   true matches kept        >= 0.45: "Adana Kebap"/"Acılı Adana Kebap" 0.706, "Kebap - Adana" 1.0,
--                                     "Ayran"/"Ayran (Büyük)" 0.5, "Kofte"/"Kofte Ekmek" 0.5,
--                                     "Latte"/"Cafe Latte" 0.545, "Salata"/"Çoban Salata" 0.538
--   false positives rejected < 0.45: "Balık Ekmek"/"Köfte Ekmek" 0.333, "Tavuk Sote"/"Tavuk Sarma" 0.4375,
--                                     "Mercimek Çorbası"/"Ezogelin Çorbası" 0.308,
--                                     "İzgara Tavuk"/"İzgara Kofte" 0.368, "Cheeseburger"/"Chicken Burger" 0.333
-- The default 0.3 threshold let several of those false positives through (distinct dishes that only
-- share a common word), so 0.45 was chosen to favor precision: a wrong/misleading price comparison is
-- worse than the page's existing "not enough data" empty state for a given item.
--
-- Because fuzzy matching means each owner item can match a different set of similarly-named items at
-- other businesses (unlike the old exact match's clean GROUP BY normalized name), matching is done with
-- a LATERAL subquery per owner item.
--
-- Also adds an ownership check: the function previously had no REVOKE/GRANT statements at all, which
-- under this project's default privileges (ALTER DEFAULT PRIVILEGES ... GRANT EXECUTE ON FUNCTIONS TO
-- anon, authenticated in 00000000000000_base_schema.sql) meant ANY caller, including anon, could pass an
-- arbitrary p_business_id and read that business's price data. The calling page
-- (uygulamalar/web/app/sahip/fiyat-raporu/page.tsx) only ever calls this with business ids the signed-in
-- owner already holds an approved owner_claims row for (via getOwnerBusinesses), so adding that same
-- ownership check here (plus is_admin() bypass, matching the _check_plan_limit_v1 pattern) does not change
-- the page's behavior for legitimate calls.
CREATE OR REPLACE FUNCTION public.get_business_price_comparison_v1(
  p_business_id UUID,
  p_limit       INT DEFAULT 20
)
RETURNS TABLE (
  menu_item_id       UUID,
  item_name          TEXT,
  business_price_cents INT,
  city_avg_cents     INT,
  district_avg_cents INT,
  city_sample_count  INT,
  diff_pct           NUMERIC -- pozitif = pahalı, negatif = ucuz
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public, extensions
AS $$
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
  -- İşletmenin kendi ürünleri ve güncel fiyatları
  my_items AS (
    SELECT
      mi.id AS menu_item_id,
      mi.name AS item_name,
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
  -- Benzer isimli ürünlerin ortalama fiyatları (şehir bazlı, trigram benzerliğiyle)
  city_match AS (
    SELECT
      my.menu_item_id,
      ROUND(AVG(x.price_cents))::INT AS avg_cents,
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
  -- İlçe bazlı ortalama (daha yerel), aynı trigram eşleştirmesiyle
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
    my.business_price_cents,
    COALESCE(ca.avg_cents, 0)        AS city_avg_cents,
    COALESCE(da.avg_cents, 0)        AS district_avg_cents,
    COALESCE(ca.sample_count, 0)     AS city_sample_count,
    CASE
      WHEN ca.avg_cents IS NULL OR ca.avg_cents = 0 THEN 0
      ELSE ROUND(((my.business_price_cents - ca.avg_cents)::NUMERIC / ca.avg_cents) * 100, 1)
    END AS diff_pct
  FROM my_items my
  LEFT JOIN city_match ca ON ca.menu_item_id = my.menu_item_id
  LEFT JOIN district_match da ON da.menu_item_id = my.menu_item_id
  -- Sadece karşılaştırma verisi olan ürünleri göster
  WHERE ca.avg_cents IS NOT NULL
  ORDER BY ABS(
    CASE WHEN ca.avg_cents = 0 THEN 0
    ELSE ((my.business_price_cents - ca.avg_cents)::NUMERIC / ca.avg_cents) * 100
    END
  ) DESC;
END;
$$;

REVOKE ALL ON FUNCTION public.get_business_price_comparison_v1(UUID, INT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_business_price_comparison_v1(UUID, INT) TO authenticated;
REVOKE EXECUTE ON FUNCTION public.get_business_price_comparison_v1(UUID, INT) FROM anon;
COMMENT ON FUNCTION public.get_business_price_comparison_v1 IS
  'İşletmenin menü ürünlerini pg_trgm bulanık eşleştirmeyle şehir/ilçe ortalamasıyla karşılaştırır (threshold 0.45). Sadece işletme sahibi (owner_claims approved) veya admin çağırabilir. Called by: fiyat-raporu/page.tsx.';
