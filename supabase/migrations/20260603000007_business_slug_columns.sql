-- ============================================================
-- 20260603000007_business_slug_columns.sql
--
-- Amaç: /[sehir]/[slug] route için deterministik slug çözümü.
-- businesses tablosuna city_slug, district_slug, category_slug
-- GENERATED STORED sütunları ekleniyor.
--
-- Plan referansı: docs/web-slug-resolver-deterministic-plan.md
--
-- Migration Maliyeti:
--   - GENERATED STORED sütunlar mevcut tüm satırlarda hesaplanır
--     (INSERT gibi full-table scan, tablo büyüklüğüne göre 1-60 sn)
--   - 5 index oluşturuluyor — kilitlenme riski düşük (CONCURRENTLY YOK)
--   - Supabase local'de test edilmeden production'a uygulanırsa
--     uzun kilitlenme süresi oluşabilir; off-peak saatte çalıştır
--
-- ROLLBACK:
--   DROP INDEX IF EXISTS public.idx_businesses_city_slug;
--   DROP INDEX IF EXISTS public.idx_businesses_district_slug;
--   DROP INDEX IF EXISTS public.idx_businesses_category_slug;
--   DROP INDEX IF EXISTS public.idx_businesses_city_district_slug;
--   DROP INDEX IF EXISTS public.idx_businesses_city_category_slug;
--   ALTER TABLE public.businesses
--     DROP COLUMN IF EXISTS city_slug,
--     DROP COLUMN IF EXISTS district_slug,
--     DROP COLUMN IF EXISTS category_slug;
--   -- slugify_tr sadece bu migration tarafından ekleniyorsa:
--   DROP FUNCTION IF EXISTS public.slugify_tr(text);
-- ============================================================

-- ── slugify_tr ─────────────────────────────────────────────
-- Türkçe karakterleri ASCII eşdeğerlerine çevirir, ardından
-- _normalize_public_slug_v1 ile aynı mantığı uygular.
-- IMMUTABLE: generated stored column için zorunlu.

CREATE OR REPLACE FUNCTION public.slugify_tr(input text)
RETURNS text
LANGUAGE sql
IMMUTABLE
SET search_path = public
AS $$
  SELECT nullif(
    trim(
      both '-' from
      regexp_replace(
        regexp_replace(
          -- Türkçe → ASCII + lowercase
          -- translate: 12 kaynak → 12 hedef (birebir eşleşme)
          -- Ç→C, Ğ→G, İ→I, Ö→O, Ş→S, Ü→U  (büyük, 6 adet)
          -- ç→c, ğ→g, ı→i, ö→o, ş→s, ü→u  (küçük, 6 adet)
          lower(
            translate(
              coalesce(input, ''),
              'ÇĞİÖŞÜçğıöşü',
              'CGIOSUcgiosu'
            )
          ),
          -- Alfanümerik olmayan karakterler → tire
          '[^a-z0-9]+', '-', 'g'
        ),
        -- Ardışık tireler → tek tire
        '-{2,}', '-', 'g'
      )
    ),
    ''
  )
$$;

-- Not: translate() PostgreSQL'de Unicode code point bazlı çalışır.
-- 12 kaynak + 12 hedef — birebir eşleşme zorunlu.
-- ı (U+0131 — noktalı olmayan küçük i) dahil edildi.

COMMENT ON FUNCTION public.slugify_tr(text) IS
  'Türkçe karakter normalizasyonu ile URL slug üretir. '
  'Ç→c, Ğ→g, İ→i, Ö→o, Ş→s, Ü→u, ı→i, küçük eşdeğerleri dahil. '
  'IMMUTABLE — businesses GENERATED STORED sütunlarında kullanılır. '
  'Plan: docs/web-slug-resolver-deterministic-plan.md';


-- ── GENERATED STORED sütunlar ─────────────────────────────

ALTER TABLE public.businesses
  ADD COLUMN IF NOT EXISTS city_slug text
    GENERATED ALWAYS AS (public.slugify_tr(city)) STORED,
  ADD COLUMN IF NOT EXISTS district_slug text
    GENERATED ALWAYS AS (public.slugify_tr(district)) STORED,
  ADD COLUMN IF NOT EXISTS category_slug text
    GENERATED ALWAYS AS (public.slugify_tr(category)) STORED;

COMMENT ON COLUMN public.businesses.city_slug IS
  'URL-safe şehir slug — slugify_tr(city). GENERATED STORED. '
  'Route: /[sehir]/[slug] deterministik çözümü için.';

COMMENT ON COLUMN public.businesses.district_slug IS
  'URL-safe ilçe slug — slugify_tr(district). GENERATED STORED. '
  'Route: /[sehir]/[slug] district modunda eşleştirme için.';

COMMENT ON COLUMN public.businesses.category_slug IS
  'URL-safe kategori slug — slugify_tr(category). GENERATED STORED. '
  'Route: /[sehir]/[slug] category modunda eşleştirme için.';


-- ── Indexler ───────────────────────────────────────────────

-- Tek sütun indexler (aktif işletmeler, null değerler dahil edilmiyor)
CREATE INDEX IF NOT EXISTS idx_businesses_city_slug
  ON public.businesses(city_slug)
  WHERE is_active = true AND city_slug IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_businesses_district_slug
  ON public.businesses(district_slug)
  WHERE is_active = true AND district_slug IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_businesses_category_slug
  ON public.businesses(category_slug)
  WHERE is_active = true AND category_slug IS NOT NULL;

-- Composite indexler — route resolver sorgularını optimize eder
-- /[sehir]/[slug] → district modu: city_slug = $1 AND district_slug = $2
CREATE INDEX IF NOT EXISTS idx_businesses_city_district_slug
  ON public.businesses(city_slug, district_slug)
  WHERE is_active = true
    AND city_slug IS NOT NULL
    AND district_slug IS NOT NULL;

-- /[sehir]/[slug] → category modu: city_slug = $1 AND category_slug = $2
CREATE INDEX IF NOT EXISTS idx_businesses_city_category_slug
  ON public.businesses(city_slug, category_slug)
  WHERE is_active = true
    AND city_slug IS NOT NULL
    AND category_slug IS NOT NULL;

COMMENT ON INDEX public.idx_businesses_city_slug IS
  'Aktif işletmeler şehir slug araması için.';

COMMENT ON INDEX public.idx_businesses_district_slug IS
  'Aktif işletmeler ilçe slug araması için.';

COMMENT ON INDEX public.idx_businesses_category_slug IS
  'Aktif işletmeler kategori slug araması için.';

COMMENT ON INDEX public.idx_businesses_city_district_slug IS
  'Aktif işletmeler şehir+ilçe slug compositi — /[sehir]/[slug] district route için.';

COMMENT ON INDEX public.idx_businesses_city_category_slug IS
  'Aktif işletmeler şehir+kategori slug compositi — /[sehir]/[slug] category route için.';
