-- Kod incelemesinde bulundu: 20260803000008_plan_sponsorship_boost.sql sponsor boost'unu
-- sadece search_nearby_businesses_v3'ün 7 parametreli overload'ına ekledi. Ancak gerçek
-- harita yüzeyleri bu overload'ı hiç kullanmıyor:
--   - Mobil (discovery_search_notifier -> SearchRepository.searchNearby -> _searchNearbyBase,
--     hem liste hem tam ekran harita) search_nearby_businesses_v3'ün 8 parametreli
--     overload'ını çağırıyor (p_user_lat, p_user_lng, p_radius_km double precision, p_limit,
--     p_offset, p_city, p_district, p_query).
--   - Web'in gerçek harita sayfası (app/(genel)/kesif/harita + /api/harita-isletmeler,
--     ikisi de src/lib/veri/harita-okuma.ts::getMapBusinesses üzerinden) tamamen ayrı,
--     zaten deprecated olan nearby_businesses_v2'yi çağırıyor.
-- Bu migration aynı is_boosted mantığını gerçekte kullanılan bu iki fonksiyona uygular.
-- Her iki fonksiyonun da RETURNS TABLE şekli (kolon adı/sırası/tipi) değişmiyor —
-- mobil Dart parsing (BusinessCardModel.fromMap) ve web TS mapping'i buna bağımlı.
-- is_boosted sadece ORDER BY için kullanılan, dışa açılmayan bir CTE kolonu.
-- Grantlar (anon dahil, her iki fonksiyon da public/anon aramada kullanılıyor) dokunulmadan
-- korunuyor; genuine bir anon-leak bulunmadı.

-- search_nearby_businesses_v3 (8 parametreli overload — mobil discovery/harita canlı çağrısı)
-- Önceki tanım: supabase/migrations/20260615000004_search_nearby_price_open.sql civarı
-- (bkz. \sf çıktısı, aşağıdaki gövde canlı tanımın birebir aynısıdır, sadece is_boosted
-- eklendi).
CREATE OR REPLACE FUNCTION public.search_nearby_businesses_v3(
  p_user_lat double precision,
  p_user_lng double precision,
  p_radius_km double precision DEFAULT 5,
  p_limit integer DEFAULT 50,
  p_offset integer DEFAULT 0,
  p_city text DEFAULT NULL::text,
  p_district text DEFAULT NULL::text,
  p_query text DEFAULT NULL::text
)
RETURNS TABLE(
  id uuid,
  name text,
  category text,
  address text,
  city text,
  district text,
  lat double precision,
  lng double precision,
  distance_km double precision,
  is_open_now boolean,
  median_price_cents integer,
  price_level text
)
LANGUAGE sql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
  WITH
  -- Alias resolution: p_city bir alias'a karşılık geliyorsa canonical değeri döndür
  -- p_city NULL ise LEFT JOIN eşleşmez, COALESCE p_city=NULL döndürür
  resolved_city AS (
    SELECT
      COALESCE(csa.canonical_city, p_city)  AS city_val,
      csa.canonical_district                 AS district_hint
    FROM (SELECT 1) _dummy
    LEFT JOIN public.city_search_aliases csa
      ON public.normalize_tr_location_text(csa.alias)
         = public.normalize_tr_location_text(p_city)
    WHERE p_city IS NOT NULL
    LIMIT 1
  ),
  params AS (
    SELECT
      st_setsrid(st_makepoint(p_user_lng, p_user_lat), 4326)::geography AS user_geog,
      greatest(p_radius_km, 0.1) * 1000.0 AS radius_m,
      nullif(trim(coalesce(p_query, '')), '') AS q
  ),
  rows AS (
    SELECT
      b.id,
      b.name,
      b.category,
      b.address,
      b.city,
      b.district,
      b.lat,
      b.lng,
      (st_distance(b.geog, (SELECT user_geog FROM params)) / 1000.0)::double precision AS distance_km,
      -- is_open_now: Bu overload'da business_hours join'i ve p_open_now parametresi
      -- mevcut değil. Hesaplanamaz, NULL döndürülüyor. Mobil fromMap null-safe.
      NULL::boolean AS is_open_now,
      -- median_price_cents: business_price_index_v1 view'ından lateral lookup.
      pi.median_price_cents,
      -- price_level: businesses.price_level (migration 20260603000001).
      b.price_level,
      -- Plan/ticari sponsorluk: aktif discovery sponsorluğu olan işletmeler öne alınır.
      EXISTS (
        SELECT 1 FROM public.sponsorships s
        WHERE s.business_id = b.id
          AND s.surface = 'discovery'
          AND s.status = 'active'
          AND (s.starts_at IS NULL OR s.starts_at <= now())
          AND (s.ends_at IS NULL OR s.ends_at >= now())
      ) AS is_boosted
    FROM public.businesses b
    CROSS JOIN params
    LEFT JOIN LATERAL (
      SELECT bpi.median_price_cents
      FROM public.business_price_index_v1 bpi
      WHERE bpi.business_id = b.id
      LIMIT 1
    ) pi ON true
    WHERE b.geog IS NOT NULL
      AND st_dwithin(b.geog, params.user_geog, params.radius_m)
      -- Şehir filtresi: doğrudan eşleşme VEYA alias lookup
      AND (
        p_city IS NULL
        OR b.city = p_city
        OR EXISTS (
          SELECT 1
          FROM resolved_city rc
          WHERE rc.city_val = b.city
            AND (rc.district_hint IS NULL OR b.district = rc.district_hint)
        )
      )
      -- İlçe filtresi: doğrudan parametre
      AND (p_district IS NULL OR b.district = p_district)
      -- Metin filtresi
      AND (
        params.q IS NULL
        OR b.search_tsv @@ websearch_to_tsquery('turkish', params.q)
        OR b.name    ILIKE '%' || params.q || '%'
        OR b.address ILIKE '%' || params.q || '%'
      )
  )
  SELECT
    id, name, category, address, city, district, lat, lng,
    distance_km, is_open_now, median_price_cents, price_level
  FROM rows
  ORDER BY is_boosted DESC, distance_km ASC
  LIMIT  greatest(p_limit, 0)
  OFFSET greatest(p_offset, 0);
$function$;

-- nearby_businesses_v2 (web'in gerçek harita sayfasının çağırdığı, deprecated ama hâlâ
-- canlı fonksiyon — getMapBusinesses() üzerinden). Önceki tanım migration'lar arasında
-- dağınık; gövde canlı \sf çıktısının birebir aynısı, sadece is_boosted eklendi.
CREATE OR REPLACE FUNCTION public.nearby_businesses_v2(
  p_lat double precision,
  p_lng double precision,
  p_radius_m integer DEFAULT 2000,
  p_category text DEFAULT NULL::text,
  p_limit integer DEFAULT 50,
  p_offset integer DEFAULT 0
)
RETURNS TABLE(
  id uuid,
  name text,
  slug text,
  public_slug text,
  category text,
  address text,
  city text,
  district text,
  neighborhood text,
  lat double precision,
  lng double precision,
  distance_m integer,
  avg_rating double precision,
  review_count integer,
  is_active boolean,
  is_verified boolean,
  logo_url text,
  cover_url text
)
LANGUAGE sql
STABLE SECURITY DEFINER
SET search_path TO 'public', 'extensions'
AS $function$
  WITH ref AS (
    SELECT ST_SetSRID(ST_MakePoint(p_lng, p_lat), 4326)::public.geography AS pt
  ),
  rows AS (
    SELECT
      b.id,
      b.name,
      b.slug,
      b.public_slug,
      b.category,
      b.address,
      b.city,
      b.district,
      b.neighborhood,
      b.lat,
      b.lng,
      ST_Distance(b.geog, ref.pt)::INT        AS distance_m,
      COALESCE(bws.avg_rating,    0)::FLOAT8  AS avg_rating,
      COALESCE(bws.reviews_count, 0)::INT     AS review_count,
      b.is_active,
      b.is_verified,
      b.logo_url,
      b.cover_url,
      -- Plan/ticari sponsorluk: aktif discovery sponsorluğu olan işletmeler öne alınır.
      EXISTS (
        SELECT 1 FROM public.sponsorships s
        WHERE s.business_id = b.id
          AND s.surface = 'discovery'
          AND s.status = 'active'
          AND (s.starts_at IS NULL OR s.starts_at <= now())
          AND (s.ends_at IS NULL OR s.ends_at >= now())
      ) AS is_boosted
    FROM public.businesses b
    CROSS JOIN ref
    LEFT JOIN public.businesses_with_stats bws ON bws.id = b.id
    WHERE
      b.is_active = TRUE
      AND b.geog IS NOT NULL
      AND ST_DWithin(b.geog, ref.pt, p_radius_m)
      AND (p_category IS NULL OR b.category = p_category)
  )
  SELECT
    id, name, slug, public_slug, category, address, city, district, neighborhood,
    lat, lng, distance_m, avg_rating, review_count, is_active, is_verified,
    logo_url, cover_url
  FROM rows
  ORDER BY is_boosted DESC, distance_m ASC
  LIMIT  p_limit
  OFFSET p_offset;
$function$;
