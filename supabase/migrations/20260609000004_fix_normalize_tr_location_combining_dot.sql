-- ============================================================
-- 20260609000004_fix_normalize_tr_location_combining_dot.sql
-- ============================================================
-- Amaç: city alias lookup için kullanılan normalize_tr_location_text()
-- helper'ını Unicode combining mark varyantlarına karşı güvenli hale getir.
--
-- Gerekçe:
--   PR #95 alias migration'ları İzmit gibi Türkçe şehir/ilçe alias'larını
--   normalize ederek eşleştirir. Bazı klavye/browser/DB akışlarında "İ"
--   harfi "i" + U+0307 COMBINING DOT ABOVE olarak gelebilir. Bu migration
--   U+0300-U+036F aralığındaki combining mark'ları temizleyerek
--   "i̇zmi̇t" ve "İzmi̇t" değerlerinin "izmit" ile eşleşmesini sağlar.
--
-- Smoke test SQL:
--   select public.normalize_tr_location_text('İzmit');      -- izmit
--   select public.normalize_tr_location_text('izmit');      -- izmit
--   select public.normalize_tr_location_text('IZMIT');      -- izmit
--   select public.normalize_tr_location_text('Izmit');      -- izmit
--   select public.normalize_tr_location_text('i̇zmi̇t');     -- izmit
--   select public.normalize_tr_location_text('İzmi̇t');      -- izmit
--   select public.normalize_tr_location_text('Adapazarı');  -- adapazari
--   select public.normalize_tr_location_text('adapazari');  -- adapazari
--   select public.normalize_tr_location_text('AFYON');      -- afyon
--   select public.normalize_tr_location_text('Antakya');    -- antakya

CREATE OR REPLACE FUNCTION public.normalize_tr_location_text(input text)
RETURNS text
LANGUAGE sql
IMMUTABLE
STRICT
SET search_path = public
AS $$
  WITH prepared AS (
    SELECT lower(
      translate(
        coalesce(input, ''),
        'İIŞĞÜÖÇ',
        'iISGUOC'
      )
    ) AS value
  ),
  without_combining_marks AS (
    SELECT regexp_replace(
      value,
      U&'[\0300-\036F]',
      '',
      'g'
    ) AS value
    FROM prepared
  ),
  without_turkish_letters AS (
    SELECT translate(
      value,
      'çğıöşüı',
      'cgiosui'
    ) AS value
    FROM without_combining_marks
  )
  SELECT trim(regexp_replace(value, '\s+', ' ', 'g'))
  FROM without_turkish_letters
$$;

COMMENT ON FUNCTION public.normalize_tr_location_text(text) IS
  'Konum alias lookup için normalizer: trim, lowercase, combining mark temizliği, Türkçe karakter ASCII indirgemesi. '
  'city_search_aliases.alias sütunu bu fonksiyonun çıktısıyla eşleşmeli. '
  'U+0307 combining dot dahil U+0300-U+036F combining mark aralığını temizler. '
  'Kullanım: search_businesses_v1, search_nearby_businesses_v3.';
