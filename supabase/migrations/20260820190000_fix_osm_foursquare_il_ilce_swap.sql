-- Foursquare/OSM kaynaklı işletmelerde city (il) alanına yanlışlıkla ilçe adı
-- yazılmış (örn. "Deniz Yıldızı" için city='Abana' — Abana aslında Kastamonu'nun
-- bir ilçesi). osm_admin_boundaries'teki gerçek il/ilçe hiyerarşisiyle (admin_level
-- 4=il, 6=ilçe, parent_id ile bağlı) kesin ve tek anlamlı (o ilçe adı Türkiye'de
-- sadece TEK bir ile bağlıysa) olarak çözülüp düzeltiliyor. "Merkez" gibi birden
-- fazla ilde geçen belirsiz ilçe adları BİLEREK atlanıyor (manuel inceleme gerekir).
--
-- district'e sadece o alan zaten BOŞSA eski (yanlış) city değeri yazılıyor —
-- doğru bir district değeri varsa asla üzerine yazılmıyor.

WITH iller AS (
  SELECT id, lower(translate(name, 'İIÖŞÜÇĞıi̇', 'iioşuçğii')) AS il_norm
  FROM public.osm_admin_boundaries WHERE admin_level = 4
),
ilceler AS (
  SELECT ic.id, ic.parent_id, lower(translate(ic.name, 'İIÖŞÜÇĞıi̇', 'iioşuçğii')) AS ilce_norm
  FROM public.osm_admin_boundaries ic WHERE ic.admin_level = 6
),
ilce_il_sayisi AS (
  SELECT ilce_norm, count(DISTINCT parent_id) AS farkli_il_sayisi
  FROM ilceler GROUP BY ilce_norm
),
adaylar AS (
  SELECT
    b.id,
    b.city AS eski_il,
    b.district AS eski_ilce,
    parent_il.name AS yeni_il
  FROM public.businesses b
  JOIN ilceler ic ON ic.ilce_norm = lower(translate(coalesce(b.city,''), 'İIÖŞÜÇĞıi̇', 'iioşuçğii'))
  JOIN ilce_il_sayisi s ON s.ilce_norm = ic.ilce_norm AND s.farkli_il_sayisi = 1
  JOIN public.osm_admin_boundaries parent_il ON parent_il.id = ic.parent_id AND parent_il.admin_level = 4
  LEFT JOIN iller i ON i.il_norm = lower(translate(coalesce(b.city,''), 'İIÖŞÜÇĞıi̇', 'iioşuçğii'))
  WHERE b.source IN ('foursquare', 'osm')
    AND i.il_norm IS NULL
)
UPDATE public.businesses b
SET
  district = CASE WHEN b.district IS NULL OR btrim(b.district) = '' THEN a.eski_il ELSE b.district END,
  city = a.yeni_il
FROM adaylar a
WHERE b.id = a.id;
