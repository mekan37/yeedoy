-- ============================================================
-- normalize_businesses_location.sql
-- City ve district kolonlarını Türkiye il/ilçe standartlarına normalize eder.
-- Dry-run tarihi : 2026-06-09
-- Tahmini etkilenen kayıt : ~6.692 otomatik UPDATE + ~3.170 review queue
-- PRODUCTION ÇALIŞTIRMADAN ÖNCE : supabase/migrations/README içindeki
--   rollback prosedürünü oku.
-- Bu dosya idempotent'tir: ikinci kez çalıştırılabilir (ON CONFLICT / WHERE guard).
-- ============================================================

BEGIN;

-- ============================================================
-- ADIM 0: Backup snapshot
-- İdempotency: tablo varsa ve dolu ise TRUNCATE + yeniden doldur,
-- yoksa CREATE AS SELECT ile oluştur.
-- ============================================================
CREATE TABLE IF NOT EXISTS public.businesses_city_district_backup_20260609 AS
  SELECT id, city, district FROM public.businesses WHERE FALSE;

-- Her çalışmada güncel snapshot'ı yaz
TRUNCATE public.businesses_city_district_backup_20260609;
INSERT INTO public.businesses_city_district_backup_20260609
  SELECT id, city, district FROM public.businesses;

-- ============================================================
-- KURAL 1: Dotted-I (U+0307 combining dot above) temizliği
-- ~4.259 kayıt: "Balikesi̇r" → "Balıkesir", "İzmi̇r" → "İzmir" vb.
-- Strateji: i + U+0307 → sade i; I + U+0307 → sade I.
-- Kural 2 (ASCII→Türkçe) bu kuraldan sonra çalışır ve nihai forma getirir.
-- ============================================================
UPDATE public.businesses
SET city = regexp_replace(
              regexp_replace(city, 'i̇', 'i', 'g'),
              'İ', 'I', 'g')
WHERE (city ~ 'i̇' OR city ~ 'İ')
  AND city IS NOT NULL;

UPDATE public.businesses
SET district = regexp_replace(
                  regexp_replace(district, 'i̇', 'i', 'g'),
                  'İ', 'I', 'g')
WHERE (district ~ 'i̇' OR district ~ 'İ')
  AND district IS NOT NULL;

-- ============================================================
-- KURAL 2: ASCII→Türkçe ve büyük/küçük harf normalizasyonu (city)
-- Sadece kesin, tek anlamlı eşleşmeler.
-- ~665 kayıt
-- ============================================================
UPDATE public.businesses SET city = 'Adana'          WHERE lower(city) = 'adana'                             AND city <> 'Adana';
UPDATE public.businesses SET city = 'Adıyaman'       WHERE lower(city) IN ('adiyaman','adiyaman')            AND city <> 'Adıyaman';
UPDATE public.businesses SET city = 'Afyonkarahisar' WHERE lower(city) = 'afyonkarahisar'                    AND city <> 'Afyonkarahisar';
UPDATE public.businesses SET city = 'Ağrı'           WHERE lower(city) IN ('agri','agri')                    AND city <> 'Ağrı';
UPDATE public.businesses SET city = 'Aksaray'        WHERE lower(city) = 'aksaray'                           AND city <> 'Aksaray';
UPDATE public.businesses SET city = 'Amasya'         WHERE lower(city) = 'amasya'                            AND city <> 'Amasya';
UPDATE public.businesses SET city = 'Ankara'         WHERE lower(city) = 'ankara'                            AND city <> 'Ankara';
UPDATE public.businesses SET city = 'Antalya'        WHERE lower(city) = 'antalya'                           AND city <> 'Antalya';
UPDATE public.businesses SET city = 'Ardahan'        WHERE lower(city) = 'ardahan'                           AND city <> 'Ardahan';
UPDATE public.businesses SET city = 'Artvin'         WHERE lower(city) = 'artvin'                            AND city <> 'Artvin';
UPDATE public.businesses SET city = 'Aydın'          WHERE lower(city) IN ('aydin','aydin')                  AND city <> 'Aydın';
UPDATE public.businesses SET city = 'Balıkesir'      WHERE lower(city) IN ('balikesir','balikesir')          AND city <> 'Balıkesir';
UPDATE public.businesses SET city = 'Bartın'         WHERE lower(city) IN ('bartin','bartin')                AND city <> 'Bartın';
UPDATE public.businesses SET city = 'Batman'         WHERE lower(city) = 'batman'                            AND city <> 'Batman';
UPDATE public.businesses SET city = 'Bayburt'        WHERE lower(city) = 'bayburt'                           AND city <> 'Bayburt';
UPDATE public.businesses SET city = 'Bilecik'        WHERE lower(city) = 'bilecik'                           AND city <> 'Bilecik';
UPDATE public.businesses SET city = 'Bingöl'         WHERE lower(city) IN ('bingol','bingol')                AND city <> 'Bingöl';
UPDATE public.businesses SET city = 'Bitlis'         WHERE lower(city) = 'bitlis'                            AND city <> 'Bitlis';
UPDATE public.businesses SET city = 'Bolu'           WHERE lower(city) = 'bolu'                              AND city <> 'Bolu';
UPDATE public.businesses SET city = 'Burdur'         WHERE lower(city) = 'burdur'                            AND city <> 'Burdur';
UPDATE public.businesses SET city = 'Bursa'          WHERE lower(city) = 'bursa'                             AND city <> 'Bursa';
UPDATE public.businesses SET city = 'Çanakkale'      WHERE lower(city) IN ('canakkale','canakkale')          AND city <> 'Çanakkale';
UPDATE public.businesses SET city = 'Çankırı'        WHERE lower(city) IN ('cankiri','cankiri')              AND city <> 'Çankırı';
UPDATE public.businesses SET city = 'Çorum'          WHERE lower(city) IN ('corum','corum')                  AND city <> 'Çorum';
UPDATE public.businesses SET city = 'Denizli'        WHERE lower(city) = 'denizli'                           AND city <> 'Denizli';
UPDATE public.businesses SET city = 'Diyarbakır'     WHERE lower(city) IN ('diyarbakir','diyarbakir')        AND city <> 'Diyarbakır';
UPDATE public.businesses SET city = 'Düzce'          WHERE lower(city) IN ('duzce','duzce')                  AND city <> 'Düzce';
UPDATE public.businesses SET city = 'Edirne'         WHERE lower(city) = 'edirne'                            AND city <> 'Edirne';
UPDATE public.businesses SET city = 'Elazığ'         WHERE lower(city) IN ('elazig','elazig','elazıg')       AND city <> 'Elazığ';
UPDATE public.businesses SET city = 'Erzincan'       WHERE lower(city) = 'erzincan'                          AND city <> 'Erzincan';
UPDATE public.businesses SET city = 'Erzurum'        WHERE lower(city) = 'erzurum'                           AND city <> 'Erzurum';
UPDATE public.businesses SET city = 'Eskişehir'      WHERE lower(city) IN ('eskisehir','eskisehir')          AND city <> 'Eskişehir';
UPDATE public.businesses SET city = 'Gaziantep'      WHERE lower(city) = 'gaziantep'                         AND city <> 'Gaziantep';
UPDATE public.businesses SET city = 'Giresun'        WHERE lower(city) = 'giresun'                           AND city <> 'Giresun';
UPDATE public.businesses SET city = 'Gümüşhane'      WHERE lower(city) IN ('gumushane','gumushane')          AND city <> 'Gümüşhane';
UPDATE public.businesses SET city = 'Hakkari'        WHERE lower(city) = 'hakkari'                           AND city <> 'Hakkari';
UPDATE public.businesses SET city = 'Hatay'          WHERE lower(city) = 'hatay'                             AND city <> 'Hatay';
UPDATE public.businesses SET city = 'Iğdır'          WHERE lower(city) IN ('igdir','igdir')                  AND city <> 'Iğdır';
UPDATE public.businesses SET city = 'Isparta'        WHERE lower(city) = 'isparta'                           AND city <> 'Isparta';
UPDATE public.businesses SET city = 'İstanbul'       WHERE lower(city) IN ('istanbul','istanbul')            AND city <> 'İstanbul';
UPDATE public.businesses SET city = 'İzmir'          WHERE lower(city) IN ('izmir','izmir')                  AND city <> 'İzmir';
UPDATE public.businesses SET city = 'Kahramanmaraş'  WHERE lower(city) IN ('kahramanmaras','kahramanmaras')  AND city <> 'Kahramanmaraş';
UPDATE public.businesses SET city = 'Karabük'        WHERE lower(city) IN ('karabuk','karabuk')              AND city <> 'Karabük';
UPDATE public.businesses SET city = 'Karaman'        WHERE lower(city) = 'karaman'                           AND city <> 'Karaman';
UPDATE public.businesses SET city = 'Kars'           WHERE lower(city) = 'kars'                              AND city <> 'Kars';
UPDATE public.businesses SET city = 'Kastamonu'      WHERE lower(city) = 'kastamonu'                         AND city <> 'Kastamonu';
UPDATE public.businesses SET city = 'Kayseri'        WHERE lower(city) = 'kayseri'                           AND city <> 'Kayseri';
UPDATE public.businesses SET city = 'Kilis'          WHERE lower(city) = 'kilis'                             AND city <> 'Kilis';
UPDATE public.businesses SET city = 'Kırıkkale'      WHERE lower(city) IN ('kirikkale','kirikkale')          AND city <> 'Kırıkkale';
UPDATE public.businesses SET city = 'Kırklareli'     WHERE lower(city) IN ('kirklareli','kirklareli')        AND city <> 'Kırklareli';
UPDATE public.businesses SET city = 'Kırşehir'       WHERE lower(city) IN ('kirsehir','kirsehir')            AND city <> 'Kırşehir';
UPDATE public.businesses SET city = 'Kocaeli'        WHERE lower(city) = 'kocaeli'                           AND city <> 'Kocaeli';
UPDATE public.businesses SET city = 'Konya'          WHERE lower(city) = 'konya'                             AND city <> 'Konya';
UPDATE public.businesses SET city = 'Kütahya'        WHERE lower(city) IN ('kutahya','kutahya')              AND city <> 'Kütahya';
UPDATE public.businesses SET city = 'Malatya'        WHERE lower(city) = 'malatya'                           AND city <> 'Malatya';
UPDATE public.businesses SET city = 'Manisa'         WHERE lower(city) = 'manisa'                            AND city <> 'Manisa';
UPDATE public.businesses SET city = 'Mardin'         WHERE lower(city) = 'mardin'                            AND city <> 'Mardin';
UPDATE public.businesses SET city = 'Mersin'         WHERE lower(city) = 'mersin'                            AND city <> 'Mersin';
UPDATE public.businesses SET city = 'Muğla'          WHERE lower(city) IN ('mugla','mugla')                  AND city <> 'Muğla';
UPDATE public.businesses SET city = 'Muş'            WHERE lower(city) IN ('mus','mus')                      AND city <> 'Muş';
UPDATE public.businesses SET city = 'Nevşehir'       WHERE lower(city) IN ('nevsehir','nevsehir')            AND city <> 'Nevşehir';
UPDATE public.businesses SET city = 'Niğde'          WHERE lower(city) IN ('nigde','nigde')                  AND city <> 'Niğde';
UPDATE public.businesses SET city = 'Ordu'           WHERE lower(city) = 'ordu'                              AND city <> 'Ordu';
UPDATE public.businesses SET city = 'Osmaniye'       WHERE lower(city) = 'osmaniye'                          AND city <> 'Osmaniye';
UPDATE public.businesses SET city = 'Rize'           WHERE lower(city) = 'rize'                              AND city <> 'Rize';
UPDATE public.businesses SET city = 'Sakarya'        WHERE lower(city) = 'sakarya'                           AND city <> 'Sakarya';
UPDATE public.businesses SET city = 'Samsun'         WHERE lower(city) = 'samsun'                            AND city <> 'Samsun';
UPDATE public.businesses SET city = 'Siirt'          WHERE lower(city) = 'siirt'                             AND city <> 'Siirt';
UPDATE public.businesses SET city = 'Sinop'          WHERE lower(city) = 'sinop'                             AND city <> 'Sinop';
UPDATE public.businesses SET city = 'Sivas'          WHERE lower(city) = 'sivas'                             AND city <> 'Sivas';
UPDATE public.businesses SET city = 'Şanlıurfa'      WHERE lower(city) IN ('sanliurfa','sanliurfa')          AND city <> 'Şanlıurfa';
UPDATE public.businesses SET city = 'Şırnak'         WHERE lower(city) IN ('sirnak','sirnak')                AND city <> 'Şırnak';
UPDATE public.businesses SET city = 'Tekirdağ'       WHERE lower(city) IN ('tekirdag','tekirdag')            AND city <> 'Tekirdağ';
UPDATE public.businesses SET city = 'Tokat'          WHERE lower(city) = 'tokat'                             AND city <> 'Tokat';
UPDATE public.businesses SET city = 'Trabzon'        WHERE lower(city) = 'trabzon'                           AND city <> 'Trabzon';
UPDATE public.businesses SET city = 'Tunceli'        WHERE lower(city) = 'tunceli'                           AND city <> 'Tunceli';
UPDATE public.businesses SET city = 'Uşak'           WHERE lower(city) IN ('usak','usak')                    AND city <> 'Uşak';
UPDATE public.businesses SET city = 'Van'            WHERE lower(city) = 'van'                               AND city <> 'Van';
UPDATE public.businesses SET city = 'Yalova'         WHERE lower(city) = 'yalova'                            AND city <> 'Yalova';
UPDATE public.businesses SET city = 'Yozgat'         WHERE lower(city) = 'yozgat'                            AND city <> 'Yozgat';
UPDATE public.businesses SET city = 'Zonguldak'      WHERE lower(city) = 'zonguldak'                         AND city <> 'Zonguldak';

-- ============================================================
-- KURAL 3: Kısaltma / alias → canonical il adı (city)
-- ~204 kayıt
-- ============================================================
-- İzmit → Kocaeli (~86)
UPDATE public.businesses SET city = 'Kocaeli'
WHERE lower(city) IN ('izmit', 'i̇zmit')
  AND city <> 'Kocaeli';

-- Antakya → Hatay (~57) ; Antakya ilçe olarak Hatay'da kalır
UPDATE public.businesses SET city = 'Hatay'
WHERE lower(city) IN ('antakya')
  AND city <> 'Hatay';

-- Karşıyaka → İzmir (~27) ; Karşıyaka ilçe olarak zaten İzmir'in district'i
UPDATE public.businesses SET city = 'İzmir'
WHERE lower(city) IN ('karşıyaka', 'karsiyaka')
  AND city <> 'İzmir';

-- Çankaya → Ankara (~26) ; Çankaya ilçe, il değil
UPDATE public.businesses SET city = 'Ankara'
WHERE lower(city) IN ('çankaya', 'cankaya')
  AND city <> 'Ankara';

-- Adapazarı → Sakarya (~25)
UPDATE public.businesses SET city = 'Sakarya'
WHERE lower(city) IN ('adapazarı', 'adapazari')
  AND city <> 'Sakarya';

-- Afyon → Afyonkarahisar (~5)
UPDATE public.businesses SET city = 'Afyonkarahisar'
WHERE lower(city) IN ('afyon')
  AND city <> 'Afyonkarahisar';

-- k.Maraş, kahraman maraş vb → Kahramanmaraş
UPDATE public.businesses SET city = 'Kahramanmaraş'
WHERE lower(regexp_replace(city, '[.\s]', '', 'g')) IN
      ('kmaraş', 'kmaras', 'kahramanmaraş', 'kahramanmaras', 'k.maraş', 'k.maras')
  AND city <> 'Kahramanmaraş';

-- ş.urfa, şanlıurfa varyantları → Şanlıurfa
UPDATE public.businesses SET city = 'Şanlıurfa'
WHERE lower(regexp_replace(city, '[.\s]', '', 'g')) IN
      ('şurfa', 'surfa', 'ş.urfa', 's.urfa', 'şanlıurfa', 'sanliurfa')
  AND city <> 'Şanlıurfa';

-- ============================================================
-- KURAL 4: District prefix fazlalığı temizliği
-- YALNIZCA: district = city || ' Merkez' pattern'i
-- ~1.500 kayıt
-- Güvenlik şartı: sadece bire bir eşleşme, başka pattern'e dokunma.
-- district = 'Merkez' sade değerine dokunma.
-- ============================================================
UPDATE public.businesses
SET district = 'Merkez'
WHERE district IS NOT NULL
  AND city IS NOT NULL
  AND district = city || ' Merkez'
  AND district <> 'Merkez';

-- ============================================================
-- KURAL 5: "19 Mayis" → "Ondokuzmayıs" (district, Samsun)
-- ~23 kayıt
-- ============================================================
UPDATE public.businesses
SET district = 'Ondokuzmayıs'
WHERE lower(regexp_replace(district, '\s+', '', 'g')) IN ('19mayis', '19mayıs', '19mayo', 'ondokuzmayis')
  AND district <> 'Ondokuzmayıs';

-- ============================================================
-- KURAL 6: "% District" / "% Province" İngilizce suffix temizliği
-- ~8 kayıt
-- ============================================================

-- district suffix kaldır: "Yahyali District" → "Yahyalı"
-- Önce suffix'i kaldır, sonra Turkey canonical referans tablosuna bak
UPDATE public.businesses
SET district = initcap(
    regexp_replace(
      regexp_replace(district, '\s+[Dd]istrict\s*$', ''),
      '\s+[Pp]rovince\s*$', ''
    )
  )
WHERE (district ilike '% District' OR district ilike '% Province')
  AND district IS NOT NULL;

-- Sonra "Province" suffix'li city değerleri için aynı işlemi city üstüne uygula
UPDATE public.businesses
SET city = initcap(
    regexp_replace(
      regexp_replace(city, '\s+[Pp]rovince\s*$', ''),
      '\s+[Ii]l\s*$', ''
    )
  )
WHERE (city ilike '% Province' OR city ilike '% İl' OR city ilike '% Il')
  AND city IS NOT NULL;

-- Suffix temizlendikten sonra ASCII→Türkçe gerekirse Kural 2'nin tekrar
-- tetiklenmesi beklenmez (miktar ~8 kayıt). Gerekirse Kural 2'yi sonra el ile çalıştır.

-- ============================================================
-- KURAL 7: Ters yerleşim (city ↔ district swap)
-- ~17 kayıt — YALNIZCA şu koşulların üçü de sağlanırsa swap:
--   a) city değeri turkey_districts_reference.district_name olarak var
--   b) district değeri 81 geçerli il arasında var (turkey_districts_reference.province_name)
--   c) o district_name'in province_name'i mevcut district değeriyle eşleşiyor
--   d) Birden fazla province eşleşmesi → review queue'ya gönder (swap yapma)
-- ============================================================
DO $$
DECLARE
  r RECORD;
  v_match_count INT;
  v_canonical_province TEXT;
BEGIN
  FOR r IN
    SELECT b.id, b.city AS old_city, b.district AS old_district
    FROM public.businesses b
    WHERE b.city IS NOT NULL
      AND b.district IS NOT NULL
      -- city değeri bir ilçe adı olarak kayıtlı
      AND EXISTS (
        SELECT 1 FROM public.turkey_districts_reference tdr
        WHERE lower(tdr.district_name) = lower(b.city)
      )
      -- district değeri bir il adı olarak kayıtlı
      AND EXISTS (
        SELECT 1 FROM public.turkey_districts_reference tdr
        WHERE lower(tdr.province_name) = lower(b.district)
        LIMIT 1
      )
  LOOP
    -- Kaç farklı ilde bu ilçe adı var?
    SELECT COUNT(DISTINCT tdr.province_name)
    INTO v_match_count
    FROM public.turkey_districts_reference tdr
    WHERE lower(tdr.district_name) = lower(r.old_city);

    IF v_match_count = 1 THEN
      -- Tek eşleşme: o ilçenin ili mevcut district değeriyle uyuşuyor mu?
      SELECT tdr.province_name INTO v_canonical_province
      FROM public.turkey_districts_reference tdr
      WHERE lower(tdr.district_name) = lower(r.old_city)
      LIMIT 1;

      IF lower(v_canonical_province) = lower(r.old_district) THEN
        -- Güvenli swap
        UPDATE public.businesses
        SET city     = r.old_district,
            district = r.old_city
        WHERE id = r.id
          AND city = r.old_city
          AND district = r.old_district;
      ELSE
        -- Province uyuşmuyor → review queue
        INSERT INTO public.business_location_review_queue
          (business_id, old_city, old_district, reason, suggested_city, suggested_district,
           confidence, source)
        VALUES (
          r.id, r.old_city, r.old_district,
          'swap_province_mismatch',
          r.old_district, r.old_city,
          0.60,
          'location_normalization_20260609'
        )
        ON CONFLICT (business_id, source, reason) DO NOTHING;
      END IF;
    ELSE
      -- Birden fazla il eşleşmesi → review queue
      INSERT INTO public.business_location_review_queue
        (business_id, old_city, old_district, reason, suggested_city, suggested_district,
         confidence, source)
      VALUES (
        r.id, r.old_city, r.old_district,
        'swap_ambiguous_district',
        r.old_district, r.old_city,
        0.40,
        'location_normalization_20260609'
      )
      ON CONFLICT (business_id, source, reason) DO NOTHING;
    END IF;
  END LOOP;
END $$;

-- ============================================================
-- KURAL 8: Birleşik city (tire ayırıcı, il tespiti yapılabilenler)
-- ~16 kayıt: "İstanbul - Silivri" → city="İstanbul", district="Silivri"
-- Sadece " - " ayırıcısı, sol taraf geçerli 81 il, sağ taraf district_name'de var
-- ============================================================
DO $$
DECLARE
  r RECORD;
  v_left  TEXT;
  v_right TEXT;
  v_province_match INT;
BEGIN
  FOR r IN
    SELECT id, city, district
    FROM public.businesses
    WHERE city ~ '.+ - .+'
      AND city IS NOT NULL
  LOOP
    v_left  := trim(split_part(r.city, ' - ', 1));
    v_right := trim(split_part(r.city, ' - ', 2));

    -- Sol taraf geçerli il mi?
    SELECT COUNT(*) INTO v_province_match
    FROM public.turkey_districts_reference tdr
    WHERE lower(tdr.province_name) = lower(v_left)
    LIMIT 1;

    IF v_province_match >= 1 THEN
      -- Sağ taraf bu ilin ilçesi mi?
      IF EXISTS (
        SELECT 1 FROM public.turkey_districts_reference tdr
        WHERE lower(tdr.province_name) = lower(v_left)
          AND lower(tdr.district_name) = lower(v_right)
      ) THEN
        -- Net eşleşme: split et, district doluysa review queue'ya at
        IF r.district IS NOT NULL AND r.district <> '' THEN
          -- Eski district değeri kaybolabilir → queue'ya ekle
          INSERT INTO public.business_location_review_queue
            (business_id, old_city, old_district, reason, suggested_city, suggested_district,
             confidence, source)
          VALUES (
            r.id, r.city, r.district,
            'combined_city_split_existing_district',
            v_left, v_right,
            0.85,
            'location_normalization_20260609'
          )
          ON CONFLICT (business_id, source, reason) DO NOTHING;
        ELSE
          -- district boştu: doğrudan split
          UPDATE public.businesses
          SET city = v_left, district = v_right
          WHERE id = r.id AND city = r.city;
        END IF;
      ELSE
        -- Sağ taraf bu ilin ilçesi değil → review queue
        INSERT INTO public.business_location_review_queue
          (business_id, old_city, old_district, reason, suggested_city, suggested_district,
           confidence, source)
        VALUES (
          r.id, r.city, r.district,
          'combined_city_unknown_district',
          v_left, v_right,
          0.60,
          'location_normalization_20260609'
        )
        ON CONFLICT (business_id, source, reason) DO NOTHING;
      END IF;
    ELSE
      -- Sol taraf il değil → review queue
      INSERT INTO public.business_location_review_queue
        (business_id, old_city, old_district, reason, suggested_city, suggested_district,
         confidence, source)
      VALUES (
        r.id, r.city, r.district,
        'combined_city_ambiguous',
        NULL, NULL,
        0.30,
        'location_normalization_20260609'
      )
      ON CONFLICT (business_id, source, reason) DO NOTHING;
    END IF;
  END LOOP;
END $$;

-- ============================================================
-- REVIEW QUEUE: Statik ekleme (tespit edilen kategoriler)
-- Ana veri DEĞİŞTİRİLMEZ, yalnızca review kaydı açılır.
-- ============================================================

-- ── Yabancı alfabe (Yunanca, Arapça, Ermenice vb.) ──────────
-- ~46 kayıt
INSERT INTO public.business_location_review_queue
  (business_id, old_city, old_district, reason, confidence, source)
SELECT
  b.id,
  b.city,
  b.district,
  'foreign_alphabet',
  0.00,
  'location_normalization_20260609'
FROM public.businesses b
WHERE (
    -- Unicode bloklar: Yunanca U+0370-03FF, Arapça U+0600-06FF, Ermenice U+0530-058F,
    -- Kiril U+0400-04FF, Gürcüce U+10A0-10FF, vb.
    b.city    ~ '[^ -ɏ̀-ͯ\s\-\.,\(\)''"]'
    OR b.district ~ '[^ -ɏ̀-ͯ\s\-\.,\(\)''"]'
  )
  AND (b.city IS NOT NULL OR b.district IS NOT NULL)
ON CONFLICT (business_id, source, reason) DO NOTHING;

-- ── Anlamsız / özel karakter ─────────────────────────────────
-- ~2 kayıt
INSERT INTO public.business_location_review_queue
  (business_id, old_city, old_district, reason, confidence, source)
SELECT
  b.id,
  b.city,
  b.district,
  'garbage_value',
  0.00,
  'location_normalization_20260609'
FROM public.businesses b
WHERE (
    (b.city IS NOT NULL    AND b.city    ~ '^[^a-zA-ZğüşıöçĞÜŞİÖÇ\s]+$')
    OR (b.district IS NOT NULL AND b.district ~ '^[^a-zA-ZğüşıöçĞÜŞİÖÇ\s]+$')
  )
ON CONFLICT (business_id, source, reason) DO NOTHING;

-- ── City=ilçe, il tespiti yapılabilir ama district dolu (~3.117) ─
-- Ana veri değiştirilmez; öneri ile queue'ya gönderilir.
INSERT INTO public.business_location_review_queue
  (business_id, old_city, old_district, reason, suggested_city, suggested_district,
   confidence, source)
SELECT
  b.id,
  b.city,
  b.district,
  'city_is_district_of_known_province',
  tdr.province_name,
  b.city,
  0.75,
  'location_normalization_20260609'
FROM public.businesses b
JOIN public.turkey_districts_reference tdr
  ON lower(tdr.district_name) = lower(b.city)
WHERE b.city IS NOT NULL
  AND b.district IS NOT NULL
  AND b.district <> ''
  -- city artık geçerli 81 il değil (zaten düzelttik yukarıda)
  AND NOT EXISTS (
    SELECT 1 FROM public.turkey_districts_reference tdr2
    WHERE lower(tdr2.province_name) = lower(b.city)
    LIMIT 1
  )
  -- Birden fazla il eşleşmesinde ilk ili alıyoruz; confidence 0.75 → gözden geçirilsin
ON CONFLICT (business_id, source, reason) DO NOTHING;

-- ============================================================
-- ADIM SON: city_norm / district_norm güncelleme
-- businesses tablosunda city_norm ve district_norm kolonları var (base_schema).
-- Bunları da güncelle: lower(trim(city)) standart formunu yaz.
-- ============================================================
UPDATE public.businesses
SET
  city_norm     = lower(trim(city)),
  district_norm = lower(trim(district))
WHERE city IS NOT NULL OR district IS NOT NULL;

COMMIT;

-- ============================================================
-- ROLLBACK prosedürü (transaction dışında çalıştır):
-- BEGIN;
-- UPDATE public.businesses b
-- SET city = bk.city, district = bk.district
-- FROM public.businesses_city_district_backup_20260609 bk
-- WHERE b.id = bk.id;
-- TRUNCATE public.business_location_review_queue;
-- COMMIT;
-- DROP TABLE IF EXISTS public.businesses_city_district_backup_20260609;
-- ============================================================
