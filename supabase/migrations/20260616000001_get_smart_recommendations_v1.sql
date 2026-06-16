CREATE OR REPLACE FUNCTION public.get_smart_recommendations_v1(
  p_city             text,
  p_district         text,
  p_party_size       int  DEFAULT 2,
  p_budget_max_cents int  DEFAULT 60000,
  p_limit            int  DEFAULT 10
)
RETURNS TABLE (
  business_id          uuid,
  business_name        text,
  image_url            text,
  cuisine              text,
  rating               numeric,
  review_count         int,
  distance_km          numeric,
  estimated_minutes    int,
  total_cents          int,
  original_total_cents int,
  discount_pct         int
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF p_party_size < 1 OR p_party_size > 20 THEN
    RAISE EXCEPTION 'validation_error: p_party_size must be between 1 and 20'
      USING ERRCODE = 'P0003';
  END IF;

  RETURN QUERY
  SELECT
    b.id                                                          AS business_id,
    b.name                                                        AS business_name,
    b.image_url,
    b.cuisine,
    b.rating,
    b.review_count,
    b.distance_km,
    NULL::int                                                     AS estimated_minutes,
    LEAST(
      p_budget_max_cents,
      COALESCE(b.median_price_cents, 15000) * p_party_size
    )::int                                                        AS total_cents,
    NULL::int                                                     AS original_total_cents,
    NULL::int                                                     AS discount_pct
  FROM search_nearby_businesses_v3(
    p_city      := p_city,
    p_district  := p_district,
    p_limit     := p_limit * 3
  ) b
  WHERE
    COALESCE(b.median_price_cents, 15000) * p_party_size <= p_budget_max_cents
  ORDER BY b.rating DESC NULLS LAST, random()
  LIMIT p_limit;
END;
$$;

REVOKE ALL ON FUNCTION public.get_smart_recommendations_v1(text, text, int, int, int)
  FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_smart_recommendations_v1(text, text, int, int, int)
  TO anon, authenticated;
COMMENT ON FUNCTION public.get_smart_recommendations_v1 IS
  'Smart budget recommendations filtered by party size × price range. Called by: smart_reco_repository.dart';
