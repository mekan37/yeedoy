-- ROLLBACK:
-- DROP FUNCTION IF EXISTS public.batch_recompute_price_levels_v1(text, text);
-- DROP FUNCTION IF EXISTS public.compute_business_price_level_v1(uuid);

-- ============================================================
-- compute_business_price_level_v1
-- Tek işletme için city+category p33/p66 percentile hesabı.
-- Döner: 'budget' | 'mid' | 'premium' | NULL
-- NULL koşulları:
--   - İşletme aktif değil veya bulunamadı
--   - Bu işletmenin mevcut menüsünde price_cents > 0 AND is_available = true
--     olan ürün sayısı < 3
--   - Aynı city+category grubunda yeterli ürüne sahip peer işletme sayısı < 3
-- ============================================================

CREATE OR REPLACE FUNCTION public.compute_business_price_level_v1(
  p_business_id uuid
)
RETURNS text
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_city        text;
  v_category    text;
  v_median      numeric;
  v_p33         numeric;
  v_p66         numeric;
  v_item_count  int;
  v_peer_count  int;
BEGIN
  -- İşletme bilgilerini al; aktif olmayanlar hesap dışı
  SELECT city, category
  INTO v_city, v_category
  FROM public.businesses
  WHERE id = p_business_id
    AND is_active = true;

  IF NOT FOUND THEN
    RETURN NULL;
  END IF;

  -- Bu işletmenin medyan menü fiyatını hesapla
  SELECT
    count(*)::int,
    percentile_cont(0.5) WITHIN GROUP (ORDER BY price_cents)
  INTO v_item_count, v_median
  FROM public.menu_items
  WHERE business_id = p_business_id
    AND price_cents  > 0
    AND is_available = true;

  -- Yeterli ürün yok → NULL (veri güvenilmez)
  IF v_item_count < 3 OR v_median IS NULL THEN
    RETURN NULL;
  END IF;

  -- Aynı city+category grubunda yeterli ürüne (>= 3) sahip peer işletme sayısı
  SELECT count(DISTINCT b.id)::int
  INTO v_peer_count
  FROM public.businesses b
  INNER JOIN (
    SELECT business_id
    FROM public.menu_items
    WHERE price_cents  > 0
      AND is_available = true
    GROUP BY business_id
    HAVING count(*) >= 3
  ) qualified ON qualified.business_id = b.id
  WHERE b.city      = v_city
    AND b.category  = v_category
    AND b.is_active = true;

  -- Yeterli peer yok → NULL (kendi kendine karşılaştırma anlamsız)
  IF v_peer_count < 3 THEN
    RETURN NULL;
  END IF;

  -- Peer medyanlarından p33/p66 eşiklerini hesapla
  -- (alt sorgu her çağrıda değerlendirilen CTE — küçük veri setinde kabul edilebilir)
  SELECT
    percentile_cont(0.33) WITHIN GROUP (ORDER BY peer_median),
    percentile_cont(0.66) WITHIN GROUP (ORDER BY peer_median)
  INTO v_p33, v_p66
  FROM (
    SELECT
      percentile_cont(0.5) WITHIN GROUP (ORDER BY mi.price_cents) AS peer_median
    FROM public.businesses b
    JOIN public.menu_items mi ON mi.business_id = b.id
    WHERE b.city      = v_city
      AND b.category  = v_category
      AND b.is_active = true
      AND mi.price_cents  > 0
      AND mi.is_available = true
    GROUP BY b.id
    HAVING count(mi.id) >= 3
  ) peers;

  -- Percentile eşiklerine göre sınıflandır
  IF v_median <= v_p33 THEN
    RETURN 'budget';
  ELSIF v_median <= v_p66 THEN
    RETURN 'mid';
  ELSE
    RETURN 'premium';
  END IF;
END;
$$;

-- authenticated: tek işletme için sonuç okuyabilir (owner panel, mobile)
-- anon erişimi yok — sonuç zaten businesses.price_level sütunundan okunacak
REVOKE ALL ON FUNCTION public.compute_business_price_level_v1(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.compute_business_price_level_v1(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.compute_business_price_level_v1(uuid) TO service_role;

COMMENT ON FUNCTION public.compute_business_price_level_v1(uuid) IS
  'Tek işletme için city+category grubunda medyan fiyatın p33/p66 percentile ile '
  'karşılaştırıldığı fiyat seviyesini hesaplar. '
  'Yeterli veri yoksa NULL döner (< 3 ürün veya < 3 peer). '
  'batch_recompute_price_levels_v1 toplu güncelleme için çağırır. '
  'Callers: batch_recompute_price_levels_v1, owner panel price level preview.';


-- ============================================================
-- batch_recompute_price_levels_v1
-- Tüm aktif işletmelerin price_level sütununu günceller.
-- p_city / p_category: NULL → tüm şehir/kategoriler (tam çalışma)
-- Sadece service_role çalıştırabilir (admin cron / Edge Function).
-- Döner: TABLE(updated int, set_null int)
-- ============================================================

CREATE OR REPLACE FUNCTION public.batch_recompute_price_levels_v1(
  p_city     text DEFAULT NULL,
  p_category text DEFAULT NULL
)
RETURNS TABLE(updated int, set_null int)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_updated int := 0;
  v_null    int := 0;
  v_rec     record;
  v_level   text;
BEGIN
  -- Çağıran service_role değilse ve admin de değilse reddet.
  -- SECURITY DEFINER olduğundan bu guard ekstra savunma katmanıdır.
  IF auth.role() <> 'service_role' AND NOT public.is_admin() THEN
    RAISE EXCEPTION 'unauthorized: sadece service_role veya admin çalıştırabilir'
      USING ERRCODE = 'P0002';
  END IF;

  FOR v_rec IN
    SELECT id
    FROM public.businesses
    WHERE is_active = true
      AND (p_city     IS NULL OR city     = p_city)
      AND (p_category IS NULL OR category = p_category)
    ORDER BY id  -- deterministik sıra, partial çalıştırma kolaylığı
  LOOP
    v_level := public.compute_business_price_level_v1(v_rec.id);

    UPDATE public.businesses
    SET price_level = v_level
    WHERE id = v_rec.id;

    IF v_level IS NULL THEN
      v_null    := v_null + 1;
    ELSE
      v_updated := v_updated + 1;
    END IF;
  END LOOP;

  RETURN QUERY SELECT v_updated, v_null;
END;
$$;

-- Sadece service_role (admin cron, Supabase Edge Function).
-- authenticated erişim yok — is_admin() guard yukarıda yedek olarak var.
REVOKE ALL ON FUNCTION public.batch_recompute_price_levels_v1(text, text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.batch_recompute_price_levels_v1(text, text) TO service_role;

COMMENT ON FUNCTION public.batch_recompute_price_levels_v1(text, text) IS
  'Tüm aktif işletmelerin businesses.price_level sütununu compute_business_price_level_v1 '
  'çağırarak toplu günceller. '
  'p_city veya p_category ile daraltılabilir. '
  'Döner: updated (değer atanan satır), set_null (veri yetersiz → NULL atanan). '
  'Çalıştırma: service_role cron veya admin Edge Function. '
  'Callers: scheduled cron job, admin panel "Fiyat seviyelerini yeniden hesapla" aksiyonu.';
