-- get_business_review_counts_batch_v1
-- Returns review_count for a batch of business IDs.
-- Used by mobile discovery cards to show "X yorum" alongside avg_rating.

CREATE OR REPLACE FUNCTION public.get_business_review_counts_batch_v1(p_ids uuid[])
RETURNS TABLE(business_id uuid, review_count integer)
LANGUAGE sql
STABLE SECURITY DEFINER
SET search_path = public
AS $$
  SELECT b.id AS business_id,
         COALESCE(r.reviews_count, 0) AS review_count
  FROM public.businesses b
  LEFT JOIN (
    SELECT business_id,
           COUNT(*) FILTER (WHERE status = 'approved')::integer AS reviews_count
    FROM public.reviews
    GROUP BY business_id
  ) r ON r.business_id = b.id
  WHERE b.id = ANY(p_ids);
$$;

GRANT EXECUTE ON FUNCTION public.get_business_review_counts_batch_v1(uuid[]) TO anon;
GRANT EXECUTE ON FUNCTION public.get_business_review_counts_batch_v1(uuid[]) TO authenticated;
