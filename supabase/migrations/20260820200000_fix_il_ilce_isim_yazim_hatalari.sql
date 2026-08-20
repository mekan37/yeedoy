-- 1) İl/ilçe yazım hataları (Kağizman→Kağızman gibi) + combining-mark/büyük-harf
--    varyasyonları, osm_admin_boundaries'teki gerçek isimlerle trigram
--    benzerliğiyle (pg_trgm) düzeltiliyor. Güvenlik: sadece TEK ADAY en yüksek
--    skora sahipse VE eski değer yeni değerden çok daha uzun değilse (aksi halde
--    "İzmir Tire" gibi il+ilçe birleşik değerler yanlışlıkla sadece ile
--    kısaltılıp ilçe bilgisi kaybolur — o kategori BİLEREK atlanıyor).
-- 2) İsimlerdeki TAMAMEN BÜYÜK HARF yazımlar Türkçe-güvenli title-case'e çevriliyor.

CREATE OR REPLACE FUNCTION private._tr_lower(s text)
RETURNS text LANGUAGE sql IMMUTABLE AS $$
  SELECT lower(replace(replace(s, 'İ', 'i'), 'I', 'ı'));
$$;

CREATE OR REPLACE FUNCTION private._tr_title_case(s text)
RETURNS text LANGUAGE plpgsql IMMUTABLE AS $$
DECLARE
  words text[];
  result text[] := '{}';
  w text;
  first_char text;
BEGIN
  words := regexp_split_to_array(private._tr_lower(btrim(s)), '\s+');
  FOREACH w IN ARRAY words LOOP
    IF w = '' THEN CONTINUE; END IF;
    first_char := CASE substr(w, 1, 1)
      WHEN 'i' THEN 'İ'
      WHEN 'ı' THEN 'I'
      ELSE upper(substr(w, 1, 1))
    END;
    result := array_append(result, first_char || substr(w, 2));
  END LOOP;
  RETURN array_to_string(result, ' ');
END;
$$;

-- ── Fix A: il yazım hataları ────────────────────────────────────────────────
WITH iller AS (
  SELECT id, name FROM public.osm_admin_boundaries WHERE admin_level = 4
),
adaylar AS (
  SELECT b.id, i.name AS yeni,
    row_number() OVER (PARTITION BY b.id ORDER BY similarity(lower(b.city), lower(i.name)) DESC) AS rn,
    similarity(lower(b.city), lower(i.name)) AS skor
  FROM public.businesses b
  CROSS JOIN iller i
  WHERE b.city IS NOT NULL AND btrim(b.city) <> ''
    AND NOT EXISTS (SELECT 1 FROM iller i2 WHERE i2.name = b.city)
)
UPDATE public.businesses b
SET city = a.yeni
FROM adaylar a
WHERE b.id = a.id
  AND a.rn = 1
  AND a.skor >= 0.5
  AND length(b.city) <= length(a.yeni) * 1.35;

-- ── Fix B: ilçe yazım hataları (Fix A sonrası doğru ile göre, parent_id ile
--    kapsamlandırılmış — farklı illerdeki aynı/benzer ilçe adlarıyla yanlış
--    eşleşme riski yok). osm_admin_boundaries'te merkez ilçeler bazı illerde
--    "Merkez", bazılarında (tutarsızca) "{İl} Merkez" olarak kayıtlı — zaten
--    doğru olan sade "Merkez" değerlerinin yanlışlıkla birleşik forma
--    çevrilmesini önlemek için "{İl} Merkez" adaylar hariç tutuluyor.
--    Önce BENZERSİZ (il, ilçe) çiftlerine indirgeniyor (92K satır × tüm
--    ilçeler yerine ~yüzlerce çift × ilçeler) — aksi halde ilk denemede
--    zaman aşımına uğradı.
WITH bad_pairs AS (
  SELECT DISTINCT b.city, b.district
  FROM public.businesses b
  JOIN public.osm_admin_boundaries il ON il.admin_level = 4 AND il.name = b.city
  WHERE b.district IS NOT NULL AND btrim(b.district) <> ''
    AND NOT EXISTS (
      SELECT 1 FROM public.osm_admin_boundaries ic2
      WHERE ic2.admin_level = 6 AND ic2.parent_id = il.id AND ic2.name = b.district
    )
),
adaylar AS (
  SELECT bp.city, bp.district AS eski,
    ic.name AS yeni,
    row_number() OVER (PARTITION BY bp.city, bp.district ORDER BY similarity(lower(bp.district), lower(ic.name)) DESC) AS rn,
    similarity(lower(bp.district), lower(ic.name)) AS skor
  FROM bad_pairs bp
  JOIN public.osm_admin_boundaries il ON il.admin_level = 4 AND il.name = bp.city
  JOIN public.osm_admin_boundaries ic ON ic.admin_level = 6 AND ic.parent_id = il.id
  WHERE ic.name !~* ' Merkez$'
),
secilenler AS (
  SELECT city, eski, yeni FROM adaylar
  WHERE rn = 1 AND skor >= 0.4 AND length(eski) <= length(yeni) * 1.35
)
UPDATE public.businesses b
SET district = s.yeni
FROM secilenler s
WHERE b.city = s.city AND b.district = s.eski;

-- ── Fix C: tamamen büyük harf isimler → Türkçe-güvenli title case ──────────
UPDATE public.businesses
SET name = private._tr_title_case(name)
WHERE name = upper(name) AND name ~ '[A-ZÇĞİÖŞÜ]';
