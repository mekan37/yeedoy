-- Plan-dahil harita önceliklendirmesi: mevcut sponsorships/sponsorship_packages
-- tablolarına bağlanıyor (paralel bir mekanizma kurulmuyor).

-- Standard/Pro planla gelen, ticari "Yeedoy Vitrin" paketinden ayrı, envanter
-- limiti olmayan dahili bir paket.
INSERT INTO public.sponsorship_packages (name, surface, duration_days, price_display, is_active, price_cents, currency_code, inventory_limit)
VALUES ('Plan Dahili Öncelik', 'discovery', 36500, 'Plana dahil', true, 0, 'TRY', 2147483647)
ON CONFLICT DO NOTHING;

CREATE OR REPLACE FUNCTION public._sync_plan_sponsorship_v1(
  p_business_id uuid,
  p_plan_tier   text,
  p_ends_at     timestamptz
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_package_id uuid;
  v_boost_enabled boolean;
BEGIN
  -- Önce bu işletmenin plan-kaynaklı mevcut discovery sponsorluğunu sonlandır.
  UPDATE public.sponsorships
  SET status = 'ended', updated_at = now()
  WHERE business_id = p_business_id
    AND surface = 'discovery'
    AND source = 'plan_grant'
    AND status = 'active';

  SELECT enabled INTO v_boost_enabled
  FROM public.plan_features
  WHERE plan_tier = p_plan_tier AND feature_key = 'map_boost';

  IF coalesce(v_boost_enabled, false) THEN
    SELECT id INTO v_package_id
    FROM public.sponsorship_packages
    WHERE name = 'Plan Dahili Öncelik' AND surface = 'discovery'
    LIMIT 1;

    INSERT INTO public.sponsorships (
      business_id, package_id, surface, status, starts_at, ends_at, source
    )
    VALUES (
      p_business_id, v_package_id, 'discovery', 'active', now(), p_ends_at, 'plan_grant'
    );
  END IF;
END;
$$;

COMMENT ON FUNCTION public._sync_plan_sponsorship_v1 IS
  'İşletmenin plan kademesi değiştiğinde discovery sponsorluğunu senkronize eder. Called by: admin_set_business_plan_v1.';

REVOKE ALL ON FUNCTION public._sync_plan_sponsorship_v1(uuid, text, timestamptz) FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION public._sync_plan_sponsorship_v1(uuid, text, timestamptz) FROM anon;
REVOKE EXECUTE ON FUNCTION public._sync_plan_sponsorship_v1(uuid, text, timestamptz) FROM authenticated;

-- admin_set_business_plan_v1'i, plan değiştiğinde sponsorluğu senkronize edecek şekilde genişlet.
CREATE OR REPLACE FUNCTION public.admin_set_business_plan_v1(
  p_business_id uuid,
  p_plan_tier   text,
  p_ends_at     timestamptz DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_id uuid;
  v_before_tier text;
  v_before_status text;
BEGIN
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'unauthorized' USING ERRCODE = 'P0002';
  END IF;

  IF p_plan_tier IS NULL OR p_plan_tier NOT IN ('free','starter','standard','pro') THEN
    RAISE EXCEPTION 'validation_error: geçersiz plan_tier' USING ERRCODE = 'P0003';
  END IF;

  IF NOT EXISTS (SELECT 1 FROM public.businesses WHERE id = p_business_id) THEN
    RAISE EXCEPTION 'not_found: işletme bulunamadı' USING ERRCODE = 'P0001';
  END IF;

  SELECT tier, status INTO v_before_tier, v_before_status
  FROM public.business_premium
  WHERE business_id = p_business_id
    AND status = 'active'
    AND tier IN ('starter','standard','pro')
  ORDER BY starts_at DESC
  LIMIT 1;

  -- Var olan aktif plan kademesini sonlandır (starter/standard/pro karşılıklı dışlar)
  UPDATE public.business_premium
  SET status = 'ended', ends_at = now()
  WHERE business_id = p_business_id
    AND status = 'active'
    AND tier IN ('starter','standard','pro');

  IF p_plan_tier <> 'free' THEN
    INSERT INTO public.business_premium (business_id, tier, status, starts_at, ends_at, source, created_by)
    VALUES (p_business_id, p_plan_tier, 'active', now(), p_ends_at, 'manual', auth.uid())
    RETURNING id INTO v_id;
  END IF;

  PERFORM public._sync_plan_sponsorship_v1(p_business_id, p_plan_tier, p_ends_at);

  PERFORM public.insert_audit_log_v1(
    'business.plan_changed',
    'business',
    p_business_id,
    jsonb_build_object('plan_tier', COALESCE(v_before_tier, 'free'), 'status', v_before_status),
    jsonb_build_object('plan_tier', p_plan_tier, 'premium_id', v_id)
  );

  RETURN jsonb_build_object('ok', true, 'business_id', p_business_id, 'plan_tier', p_plan_tier, 'premium_id', v_id);
END;
$$;

-- search_nearby_businesses_v3: sponsorlu (discovery, aktif) işletmeleri öne al.
-- (Önceki tanım: supabase/migrations/20260615000004_search_nearby_price_open.sql)
DROP FUNCTION IF EXISTS public.search_nearby_businesses_v3(
  double precision, double precision, integer, text, text, boolean, integer
);

CREATE OR REPLACE FUNCTION public.search_nearby_businesses_v3(
  p_lat double precision,
  p_lng double precision,
  p_radius_km integer DEFAULT 5,
  p_query text DEFAULT NULL::text,
  p_category text DEFAULT NULL::text,
  p_open_now boolean DEFAULT false,
  p_limit integer DEFAULT 30
)
RETURNS TABLE(
  id uuid,
  name text,
  category text,
  city text,
  district text,
  address text,
  lat double precision,
  lng double precision,
  distance_km double precision,
  quality_score integer,
  median_price_cents integer,
  is_open_now boolean
)
LANGUAGE sql
STABLE SECURITY DEFINER
SET search_path TO 'public'
AS $function$
  WITH base AS (
    SELECT
      b.*,
      (6371.0 * 2.0 * asin(
        sqrt(
          power(sin(radians((b.lat - p_lat) / 2.0)), 2)
          + cos(radians(p_lat)) * cos(radians(b.lat))
          * power(sin(radians((b.lng - p_lng) / 2.0)), 2)
        )
      )) AS distance_km,
      (
        0
        + CASE WHEN b.phone IS NOT NULL AND length(b.phone) >= 7 THEN 1 ELSE 0 END
        + CASE WHEN b.address IS NOT NULL AND length(b.address) >= 6 THEN 1 ELSE 0 END
        + CASE WHEN length(b.name) >= 6 THEN 1 ELSE 0 END
        + CASE WHEN lower(b.name) IN ('restaurant','cafe','bar','pub','mekan','lokanta') THEN -3 ELSE 2 END
      ) AS quality_score,
      (
        SELECT percentile_disc(0.5) WITHIN GROUP (ORDER BY mi.price_cents)
        FROM public.menu_items mi
        WHERE mi.business_id = b.id
          AND mi.price_cents IS NOT NULL
          AND mi.price_cents > 0
      )::int AS median_price_cents,
      CASE
        WHEN h.business_id IS NULL THEN NULL
        ELSE (
          CASE extract(dow FROM now())
            WHEN 1 THEN (h.mon_open IS NOT NULL AND current_time BETWEEN h.mon_open AND h.mon_close)
            WHEN 2 THEN (h.tue_open IS NOT NULL AND current_time BETWEEN h.tue_open AND h.tue_close)
            WHEN 3 THEN (h.wed_open IS NOT NULL AND current_time BETWEEN h.wed_open AND h.wed_close)
            WHEN 4 THEN (h.thu_open IS NOT NULL AND current_time BETWEEN h.thu_open AND h.thu_close)
            WHEN 5 THEN (h.fri_open IS NOT NULL AND current_time BETWEEN h.fri_open AND h.fri_close)
            WHEN 6 THEN (h.sat_open IS NOT NULL AND current_time BETWEEN h.sat_open AND h.sat_close)
            WHEN 0 THEN (h.sun_open IS NOT NULL AND current_time BETWEEN h.sun_open AND h.sun_close)
          END
        )
      END AS is_open_now,
      EXISTS (
        SELECT 1 FROM public.sponsorships s
        WHERE s.business_id = b.id
          AND s.surface = 'discovery'
          AND s.status = 'active'
          AND (s.starts_at IS NULL OR s.starts_at <= now())
          AND (s.ends_at IS NULL OR s.ends_at >= now())
      ) AS is_boosted
    FROM public.businesses b
    LEFT JOIN public.business_hours h ON h.business_id = b.id
    WHERE b.is_active = true
      AND b.lat IS NOT NULL
      AND b.lng IS NOT NULL
      AND (p_category IS NULL OR p_category = '' OR b.category = p_category)
      AND (
        p_query IS NULL
        OR p_query = ''
        OR b.name ILIKE ('%' || p_query || '%')
        OR coalesce(b.address,'') ILIKE ('%' || p_query || '%')
      )
      AND (
        p_open_now = false
        OR (
          h.business_id IS NOT NULL
          AND (
            CASE extract(dow FROM now())
              WHEN 1 THEN (h.mon_open IS NOT NULL AND current_time BETWEEN h.mon_open AND h.mon_close)
              WHEN 2 THEN (h.tue_open IS NOT NULL AND current_time BETWEEN h.tue_open AND h.tue_close)
              WHEN 3 THEN (h.wed_open IS NOT NULL AND current_time BETWEEN h.wed_open AND h.wed_close)
              WHEN 4 THEN (h.thu_open IS NOT NULL AND current_time BETWEEN h.thu_open AND h.thu_close)
              WHEN 5 THEN (h.fri_open IS NOT NULL AND current_time BETWEEN h.fri_open AND h.fri_close)
              WHEN 6 THEN (h.sat_open IS NOT NULL AND current_time BETWEEN h.sat_open AND h.sat_close)
              WHEN 0 THEN (h.sun_open IS NOT NULL AND current_time BETWEEN h.sun_open AND h.sun_close)
            END
          )
        )
      )
  )
  SELECT
    id, name, category, city, district, address, lat, lng,
    distance_km,
    quality_score,
    median_price_cents,
    is_open_now
  FROM base
  WHERE distance_km <= greatest(1, p_radius_km)::double precision
  ORDER BY is_boosted DESC, quality_score DESC, distance_km ASC
  LIMIT p_limit;
$function$;
