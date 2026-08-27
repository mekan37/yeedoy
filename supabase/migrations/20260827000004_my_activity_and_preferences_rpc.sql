-- Akıllı Öneri sayfasındaki sahte "Son Aktivitelerin" ve "Senin Zevklerine Göre"
-- bölümlerini gerçek kullanıcı geçmişiyle değiştirmek için: favorites/reviews/visits
-- tablolarındaki gerçek etkileşimleri birleştiren iki "bana özel" RPC.

CREATE OR REPLACE FUNCTION public.get_my_recent_activity_v1(p_limit int DEFAULT 3)
RETURNS TABLE(business_id uuid, activity_type text, created_at timestamptz)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT business_id, 'favorite'::text AS activity_type, created_at
  FROM public.favorites WHERE user_id = auth.uid()
  UNION ALL
  SELECT business_id, 'review'::text, created_at
  FROM public.reviews WHERE user_id = auth.uid()
  UNION ALL
  SELECT business_id, 'visit'::text, created_at
  FROM public.visits WHERE user_id = auth.uid()
  ORDER BY created_at DESC
  LIMIT GREATEST(p_limit, 1);
$$;

REVOKE ALL ON FUNCTION public.get_my_recent_activity_v1(int) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_my_recent_activity_v1(int) TO authenticated;
COMMENT ON FUNCTION public.get_my_recent_activity_v1 IS
  'Kullanıcının favorites/reviews/visits birleşimindeki en son etkileşimleri. Called by: app/(genel)/oneri/page.tsx.';

CREATE OR REPLACE FUNCTION public.get_my_category_preferences_v1(p_limit int DEFAULT 3)
RETURNS TABLE(category text, interaction_count int, pct numeric)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  WITH interactions AS (
    SELECT business_id FROM public.favorites WHERE user_id = auth.uid()
    UNION ALL
    SELECT business_id FROM public.reviews WHERE user_id = auth.uid()
    UNION ALL
    SELECT business_id FROM public.visits WHERE user_id = auth.uid()
  ),
  by_category AS (
    SELECT b.category, count(*)::int AS interaction_count
    FROM interactions i
    JOIN public.businesses b ON b.id = i.business_id
    WHERE b.category IS NOT NULL
    GROUP BY b.category
  ),
  total AS (
    SELECT sum(interaction_count)::numeric AS n FROM by_category
  )
  SELECT
    bc.category,
    bc.interaction_count,
    round(bc.interaction_count / NULLIF((SELECT n FROM total), 0) * 100, 0) AS pct
  FROM by_category bc
  ORDER BY bc.interaction_count DESC
  LIMIT GREATEST(p_limit, 1);
$$;

REVOKE ALL ON FUNCTION public.get_my_category_preferences_v1(int) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_my_category_preferences_v1(int) TO authenticated;
COMMENT ON FUNCTION public.get_my_category_preferences_v1 IS
  'Kullanıcının favorites/reviews/visits birleşiminden gerçek kategori tercih dağılımı (en sık N kategori, yüzde ile). Called by: app/(genel)/oneri/page.tsx.';
