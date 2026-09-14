-- Sahip Paneli Güvenlik Denetimi P2 performans: owner_get_chain_overview_v1,
-- her şube için ayrı bir korele alt-sorguyla analytics_events/
-- reservations sayıyordu, SONRA total_views/total_reservations için
-- AYNI veriyi TEKRAR tam olarak tarıyordu (branches dizisindeki toplam
-- ile aynı sonucu ikinci kez hesaplıyordu). Tek bir GROUP BY geçişine
-- indirgendi — views/reservations şube başına bir kez hesaplanıyor,
-- toplamlar bu tek geçişten SUM ile türetiliyor. Tarih sınırsız sayım
-- semantiği (kaç görüntülenme/rezervasyon "tüm zamanlar") bilinçli
-- olarak korundu — bunu değiştirmek görüntülenen iş metriğini
-- değiştireceğinden ayrı bir ürün kararı gerektirir.
create or replace function public.owner_get_chain_overview_v1(p_business_id uuid)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $function$
DECLARE
  v_chain_id uuid;
  v_result   jsonb;
BEGIN
  IF NOT public._is_approved_owner_of_business(p_business_id) THEN
    RAISE EXCEPTION 'unauthorized' USING ERRCODE = 'P0002';
  END IF;

  SELECT chain_id INTO v_chain_id FROM public.businesses WHERE id = p_business_id;

  IF v_chain_id IS NULL THEN
    RETURN jsonb_build_object(
      'chain_id', null, 'chain_name', null, 'branches', '[]'::jsonb,
      'total_views', 0, 'total_reservations', 0
    );
  END IF;

  IF EXISTS (
    SELECT 1 FROM public.businesses b
    WHERE b.chain_id = v_chain_id AND NOT public._is_approved_owner_of_business(b.id)
  ) THEN
    RAISE EXCEPTION 'validation_error: zincir birden fazla sahibe ait işletme içeriyor, bu görünüm desteklenmiyor' USING ERRCODE = 'P0003';
  END IF;

  WITH chain_businesses AS (
    SELECT id, name, branch_label, city, district, is_active, logo_url, chain_sort_order
    FROM public.businesses WHERE chain_id = v_chain_id
  ),
  view_counts AS (
    SELECT e.business_id, count(*) AS views
    FROM public.analytics_events e
    WHERE e.business_id IN (SELECT id FROM chain_businesses)
      AND e.event_name IN ('business_page_view', 'menu_view')
    GROUP BY e.business_id
  ),
  reservation_counts AS (
    SELECT r.business_id, count(*) AS reservations
    FROM public.reservations r
    WHERE r.business_id IN (SELECT id FROM chain_businesses)
    GROUP BY r.business_id
  ),
  branch_rows AS (
    SELECT
      cb.*,
      COALESCE(vc.views, 0) AS views,
      COALESCE(rc.reservations, 0) AS reservations
    FROM chain_businesses cb
    LEFT JOIN view_counts vc ON vc.business_id = cb.id
    LEFT JOIN reservation_counts rc ON rc.business_id = cb.id
  )
  SELECT jsonb_build_object(
    'chain_id', c.id,
    'chain_name', c.name,
    'branches', COALESCE((
      SELECT jsonb_agg(jsonb_build_object(
        'business_id', br.id,
        'name', br.name,
        'branch_label', br.branch_label,
        'city', br.city,
        'district', br.district,
        'is_active', br.is_active,
        'logo_url', br.logo_url,
        'chain_sort_order', br.chain_sort_order,
        'is_main_branch', (br.chain_sort_order = 0),
        'views', br.views,
        'reservations', br.reservations
      ) ORDER BY br.chain_sort_order)
      FROM branch_rows br
    ), '[]'::jsonb),
    'total_views', (SELECT COALESCE(sum(views), 0) FROM branch_rows),
    'total_reservations', (SELECT COALESCE(sum(reservations), 0) FROM branch_rows)
  ) INTO v_result
  FROM public.chains c WHERE c.id = v_chain_id;

  RETURN v_result;
END;
$function$;
