-- ============================================================
-- 20260609000002_normalize_tr_location.sql
--
-- Amaç: city_search_aliases tablosu için konum normalizer helper.
--
-- Mevcut normalize_tr_text(text) fonksiyonu (base_schema.sql satır 13239)
-- genel amaçlı olup alfanumerik olmayan karakterleri boşlukla değiştirir.
-- Bu, konum aramasında istemediğimiz bir davranış — örneğin "Afyon karahisar"
-- tek kelime olarak "afyonkarahisar" şeklinde eşleşmeli.
-- Bu yüzden konum lookup'a özel ayrı bir helper tanımlanıyor.
--
-- Dönüşüm kuralları:
--   1. trim() + lower()
--   2. Türkçe büyük harf İ → i (combining dot üzerinde özel case)
--   3. Türkçe karakterleri ASCII'ye indir: ç→c, ğ→g, ı→i/i, ö→o, ş→s, ü→u
--   4. Çoklu boşlukları tek boşluğa indir
--   NOT: Alfanumerik olmayan karakterleri silmiyoruz — "Afyonkarahisar"
--        ile "afyon karahisar" farklı eşleşmeli olduğu için boşluk
--        normalize edilmiş halde korunuyor.
--
-- Kullanım:
--   normalize_tr_location_text('İzmit')     → 'izmit'
--   normalize_tr_location_text('ADAPAZARI') → 'adapazari'
--   normalize_tr_location_text('Çankaya')   → 'cankaya'
--   normalize_tr_location_text(' Kocaeli ') → 'kocaeli'
--
-- ROLLBACK:
--   DROP FUNCTION IF EXISTS public.normalize_tr_location_text(text);
-- ============================================================

CREATE OR REPLACE FUNCTION public.normalize_tr_location_text(input text)
RETURNS text
LANGUAGE sql
IMMUTABLE
STRICT
SET search_path = public
AS $$
  SELECT trim(
    regexp_replace(
      translate(
        lower(coalesce(input, '')),
        -- Türkçe küçük + büyük harfler → ASCII karşılıkları
        -- Sıra: ç,ğ,ı,ö,ş,ü,İ,Ç,Ğ,Ö,Ş,Ü
        'çğıöşüiçğöşü',
        'cgiosuicgiosu'
      ),
      '\s+', ' ', 'g'
    )
  )
$$;

COMMENT ON FUNCTION public.normalize_tr_location_text(text) IS
  'Konum alias lookup için normalizer: trim, lowercase, Türkçe karakter ASCII indirgemesi. '
  'city_search_aliases.alias sütunu bu fonksiyonun çıktısıyla eşleşmeli. '
  'Alfanumerik olmayan karakterleri silmez (boşluk temizleme dışında). '
  'Kullanım: search_businesses_v1, search_nearby_businesses_v3. '
  'İlgili: normalize_tr_text(text) genel amaçlıdır, bu fonksiyon konum-spesifik.';
