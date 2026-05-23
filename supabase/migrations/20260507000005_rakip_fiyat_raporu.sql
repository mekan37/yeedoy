-- Rakip Fiyat Raporu: işletmenin menü ürünlerini bölge ortalamasıyla karşılaştırır.
-- Yeedoy'un benzersiz avantajı: kalabalık kaynaklı fiyat verisi bu rapora güç verir.
CREATE OR REPLACE FUNCTION get_business_price_comparison_v1(
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
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  WITH biz_city AS (
    SELECT city, district FROM businesses WHERE id = p_business_id LIMIT 1
  ),
  -- İşletmenin kendi ürünleri ve güncel fiyatları
  my_items AS (
    SELECT
      mi.id AS menu_item_id,
      mi.name AS item_name,
      mi.price_cents AS business_price_cents
    FROM menu_items mi
    JOIN menu_sections ms ON ms.id = mi.section_id
    JOIN menus m ON m.id = ms.menu_id
    WHERE m.business_id = p_business_id
      AND m.status = 'published'
      AND mi.is_available = TRUE
      AND mi.price_cents IS NOT NULL
      AND mi.price_cents > 0
    ORDER BY mi.name
    LIMIT p_limit
  ),
  -- Aynı ürün adına sahip diğer işletmelerin ortalama fiyatları (şehir bazlı)
  city_avg AS (
    SELECT
      lower(mi2.name) AS norm_name,
      ROUND(AVG(mi2.price_cents))::INT AS avg_cents,
      COUNT(DISTINCT b2.id)::INT AS sample_count
    FROM menu_items mi2
    JOIN menu_sections ms2 ON ms2.id = mi2.section_id
    JOIN menus m2 ON m2.id = ms2.menu_id AND m2.status = 'published'
    JOIN businesses b2 ON b2.id = m2.business_id AND b2.is_active = TRUE
    JOIN biz_city bc ON b2.city = bc.city
    WHERE mi2.price_cents > 0
      AND mi2.is_available = TRUE
      AND b2.id <> p_business_id
      AND EXISTS (
        SELECT 1 FROM my_items i WHERE lower(i.item_name) = lower(mi2.name)
      )
    GROUP BY lower(mi2.name)
  ),
  -- İlçe bazlı ortalama (daha yerel)
  district_avg AS (
    SELECT
      lower(mi2.name) AS norm_name,
      ROUND(AVG(mi2.price_cents))::INT AS avg_cents
    FROM menu_items mi2
    JOIN menu_sections ms2 ON ms2.id = mi2.section_id
    JOIN menus m2 ON m2.id = ms2.menu_id AND m2.status = 'published'
    JOIN businesses b2 ON b2.id = m2.business_id AND b2.is_active = TRUE
    JOIN biz_city bc ON b2.district = bc.district
    WHERE mi2.price_cents > 0
      AND mi2.is_available = TRUE
      AND b2.id <> p_business_id
      AND EXISTS (
        SELECT 1 FROM my_items i WHERE lower(i.item_name) = lower(mi2.name)
      )
    GROUP BY lower(mi2.name)
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
  LEFT JOIN city_avg ca ON lower(ca.norm_name) = lower(my.item_name)
  LEFT JOIN district_avg da ON lower(da.norm_name) = lower(my.item_name)
  -- Sadece karşılaştırma verisi olan ürünleri göster
  WHERE ca.avg_cents IS NOT NULL
  ORDER BY ABS(
    CASE WHEN ca.avg_cents = 0 THEN 0
    ELSE ((my.business_price_cents - ca.avg_cents)::NUMERIC / ca.avg_cents) * 100
    END
  ) DESC;
$$;
