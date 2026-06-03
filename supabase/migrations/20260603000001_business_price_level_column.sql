-- ROLLBACK:
-- DROP INDEX IF EXISTS public.idx_businesses_price_level;
-- ALTER TABLE public.businesses DROP COLUMN IF EXISTS price_level;

-- ============================================================
-- businesses.price_level: Computed fiyat seviyesi sütunu
-- Değerler: 'budget' | 'mid' | 'premium' | NULL
-- Hesaplama: compute_business_price_level_v1 RPC
-- Kullanıcı doğrudan yazamaz — tg_protect_price_level trigger
-- ile korunuyor (20260603000003).
-- ============================================================

ALTER TABLE public.businesses
  ADD COLUMN IF NOT EXISTS price_level text
    CHECK (price_level IN ('budget', 'mid', 'premium'));

COMMENT ON COLUMN public.businesses.price_level IS
  'Computed fiyat seviyesi: budget/mid/premium. '
  'city+category içinde medyan fiyatın p33/p66 yüzdesiyle hesaplanır. '
  'compute_business_price_level_v1(business_id) ile tek işletme için hesaplanır. '
  'batch_recompute_price_levels_v1(city, category) ile toplu güncellenir (service_role). '
  'Yetersiz veri (< 3 ürün veya < 3 peer işletme) → NULL. '
  'Web: businesses.price_level dolunca fiyat-seviyesi.ts threshold mantığı yerine kullanılacak.';

-- Partial index: fiyat seviyesi filtrelemesi ve rozet sorgularında kullanılır.
-- NULL ve inactive kayıtlar hariç tutuluyor — küçük, seçici index.
CREATE INDEX IF NOT EXISTS idx_businesses_price_level
  ON public.businesses (price_level)
  WHERE price_level IS NOT NULL AND is_active = true;
