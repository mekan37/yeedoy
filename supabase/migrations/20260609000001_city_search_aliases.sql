-- ============================================================
-- 20260609000001_city_search_aliases.sql
--
-- Amaç: Kullanıcının girdiği eski/yaygın şehir adlarını (alias)
-- canonical il/ilçe değerlerine eşleyen lookup tablosu.
--
-- Gerekçe: PR #94 (chore/normalize-business-location-data) aşağıdaki
-- dönüşümleri yapacak:
--   İzmit → Kocaeli, Adapazarı → Sakarya,
--   Afyon → Afyonkarahisar, Antakya → Hatay
-- Bu dönüşümler sonrası "İzmit" araması boş sonuç dönerdi.
-- Alias tablosu, eski adları canonical değerlere yönlendirerek
-- bu geçişi şeffaf hale getirir.
--
-- Bağımlılık (uygulama sırası):
--   1. Bu migration (20260609000001) → önce uygulanır
--   2. 20260609000002 (normalize helper)
--   3. 20260609000003 (search RPC güncellemeleri)
--   4. PR #94 (chore/normalize-business-location-data) → veri dönüşümü
--
-- ROLLBACK:
--   DROP TABLE IF EXISTS public.city_search_aliases CASCADE;
-- ============================================================

CREATE TABLE IF NOT EXISTS public.city_search_aliases (
  -- Normalize edilmiş arama terimi: lowercase, trim, Türkçe karakter indirgemesi
  -- normalize_tr_location_text() çıktısıyla eşleşmeli
  alias                text        PRIMARY KEY,
  -- Canonical il adı — businesses.city alanındaki normalized değer
  canonical_city       text        NOT NULL,
  -- Canonical ilçe adı — doluysa hem city hem district filtrelenir
  -- NULL ise sadece city eşleşmesi yeterlidir
  canonical_district   text        NULL,
  created_at           timestamptz NOT NULL DEFAULT now()
);

COMMENT ON TABLE public.city_search_aliases IS
  'Kullanıcı girişi → canonical city/district eşleme tablosu. '
  'alias sütunu normalize_tr_location_text() uygulanmış haldedir. '
  'search_businesses_v1 ve search_nearby_businesses_v3 bu tabloyu kullanır. '
  'PR #94 (location normalization) bu tabloya bağımlıdır: '
  '1. Bu migration → 2. search RPC güncellemeleri → 3. PR #94 veri dönüşümü.';

COMMENT ON COLUMN public.city_search_aliases.alias IS
  'Arama terimi — normalize_tr_location_text() ile işlenmiş (lowercase, trim, Türkçe ASCII). Örn: ''izmit'', ''adapazari''';
COMMENT ON COLUMN public.city_search_aliases.canonical_city IS
  'PR #94 sonrası businesses.city sütunundaki canonical değer. Örn: ''Kocaeli'', ''Sakarya''';
COMMENT ON COLUMN public.city_search_aliases.canonical_district IS
  'Opsiyonel canonical district. Dolu ise city + district birlikte filtrelenir. NULL ise sadece city yeterli.';

-- ============================================================
-- Seed: 9 alias (PR #94 dönüşümleri + önemli ilçe alias'ları)
-- ============================================================
INSERT INTO public.city_search_aliases (alias, canonical_city, canonical_district) VALUES
  -- PR #94 zorunlu dönüşümler: eski il adı → canonical il
  ('izmit',      'Kocaeli',        'İzmit'),
  ('adapazari',  'Sakarya',        'Adapazarı'),
  ('adapazarı',  'Sakarya',        'Adapazarı'),  -- Türkçe ı harfi içeren form
  ('afyon',      'Afyonkarahisar', NULL),          -- district hint yok; il adı tamamen değişiyor
  ('antakya',    'Hatay',          'Antakya'),
  -- Yaygın ilçe alias'ları (ASCII form — normalize_tr_location_text eşleşmesi garantisi)
  ('karsiyaka',  'İzmir',          'Karşıyaka'),
  ('cankaya',    'Ankara',         'Çankaya'),
  -- Türkçe karakter içeren formlar
  ('karşıyaka',  'İzmir',          'Karşıyaka'),
  ('çankaya',    'Ankara',         'Çankaya')
ON CONFLICT (alias) DO NOTHING;

-- ============================================================
-- RLS: anon SELECT (arama sırasında anonim kullanıcı erişebilmeli)
--       yazma sadece admin
-- ============================================================
ALTER TABLE public.city_search_aliases ENABLE ROW LEVEL SECURITY;

-- Herkes (anon dahil) okuyabilir — bu tablo gizli veri içermez
CREATE POLICY city_search_aliases_select_all
  ON public.city_search_aliases
  FOR SELECT
  TO anon, authenticated
  USING (true);

-- Sadece admin yazabilir
CREATE POLICY city_search_aliases_write_admin
  ON public.city_search_aliases
  FOR ALL
  TO authenticated
  USING (public.is_admin())
  WITH CHECK (public.is_admin());

-- ============================================================
-- GRANTs
-- ============================================================
GRANT SELECT ON public.city_search_aliases TO anon;
GRANT SELECT ON public.city_search_aliases TO authenticated;
GRANT ALL    ON public.city_search_aliases TO service_role;
