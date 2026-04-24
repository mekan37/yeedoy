-- get_category_price_benchmark_v1
-- Returns city-wide price benchmark for a menu item name.
-- Used on mobile menu item detail to show "City avg: 220₺, here it's 195₺ (below avg)".
-- Requires at least 3 data points to return a result.

CREATE OR REPLACE FUNCTION public.get_category_price_benchmark_v1(
  p_item_name  text,
  p_city       text,
  p_exclude_business_id uuid DEFAULT NULL
)
RETURNS TABLE(
  avg_price_cents  integer,
  min_price_cents  integer,
  max_price_cents  integer,
  sample_count     integer
)
LANGUAGE sql
STABLE SECURITY DEFINER
SET search_path = public
AS $$
  SELECT
    round(avg(mi.price_cents))::integer  AS avg_price_cents,
    min(mi.price_cents)::integer         AS min_price_cents,
    max(mi.price_cents)::integer         AS max_price_cents,
    count(*)::integer                    AS sample_count
  FROM public.menu_items mi
  JOIN public.businesses b ON b.id = mi.business_id
  WHERE lower(trim(mi.name)) = lower(trim(p_item_name))
    AND b.city                  = p_city
    AND mi.is_available         = true
    AND mi.price_cents          > 0
    AND (p_exclude_business_id IS NULL OR b.id != p_exclude_business_id)
  HAVING count(*) >= 3;
$$;

GRANT EXECUTE ON FUNCTION public.get_category_price_benchmark_v1(text, text, uuid) TO anon;
GRANT EXECUTE ON FUNCTION public.get_category_price_benchmark_v1(text, text, uuid) TO authenticated;
