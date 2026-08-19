-- Müşteriler sayfası yeniden tasarlanırken (yeni/tekrar eden/sadık sınıflandırması,
-- e-posta abonelik oranı) gerçek veriye dayanması için get_business_customers_v1
-- genişletildi. jsonb dönen bir fonksiyon olduğundan yeni alan eklemek imza
-- kırıcı değildir (DROP gerekmez).

CREATE OR REPLACE FUNCTION public.get_business_customers_v1(p_business_id uuid)
RETURNS jsonb
LANGUAGE plpgsql
STABLE SECURITY DEFINER
SET search_path TO 'public'
AS $function$
DECLARE
  v_program_id       uuid;
  v_reward_threshold int;
  v_chain_ids        uuid[];
BEGIN
  IF NOT public.has_business_permission_v1(p_business_id, 'menu_write') THEN
    RAISE EXCEPTION 'unauthorized' USING ERRCODE = 'P0002';
  END IF;

  v_chain_ids := public._resolve_chain_business_ids_v1(p_business_id);
  v_program_id := public._resolve_loyalty_program_v1(p_business_id);

  IF v_program_id IS NOT NULL THEN
    SELECT reward_threshold INTO v_reward_threshold FROM public.loyalty_programs WHERE id = v_program_id;
  END IF;

  RETURN COALESCE(
    (
      WITH customer_ids AS (
        SELECT user_id FROM public.reviews
          WHERE business_id = ANY(v_chain_ids) AND user_id IS NOT NULL AND status = 'approved'
        UNION
        SELECT user_id FROM public.reservations
          WHERE business_id = ANY(v_chain_ids) AND user_id IS NOT NULL
        UNION
        SELECT user_id FROM public.business_follows
          WHERE business_id = ANY(v_chain_ids)
        UNION
        SELECT lm.user_id FROM public.loyalty_members lm
          WHERE v_program_id IS NOT NULL AND lm.program_id = v_program_id
      ),
      summary AS (
        SELECT
          ci.user_id,
          (SELECT count(*) FROM public.reviews r
             WHERE r.business_id = ANY(v_chain_ids) AND r.user_id = ci.user_id AND r.status = 'approved') AS review_count,
          (SELECT count(*) FROM public.reservations rs
             WHERE rs.business_id = ANY(v_chain_ids) AND rs.user_id = ci.user_id) AS reservation_count,
          (SELECT lm.progress FROM public.loyalty_members lm
             WHERE v_program_id IS NOT NULL AND lm.program_id = v_program_id AND lm.user_id = ci.user_id) AS loyalty_progress,
          (SELECT count(*) FROM public.loyalty_events le
             JOIN public.loyalty_members lm2 ON lm2.id = le.member_id
             WHERE v_program_id IS NOT NULL AND lm2.program_id = v_program_id AND lm2.user_id = ci.user_id) AS loyalty_event_count,
          EXISTS(SELECT 1 FROM public.business_follows bf
             WHERE bf.business_id = ANY(v_chain_ids) AND bf.user_id = ci.user_id) AS is_following,
          COALESCE((SELECT bool_or(bf.is_subscribed_email) FROM public.business_follows bf
             WHERE bf.business_id = ANY(v_chain_ids) AND bf.user_id = ci.user_id), false) AS is_email_subscribed,
          (SELECT coalesce(jsonb_agg(jsonb_build_object('id', ct.id, 'tag', ct.tag) ORDER BY ct.created_at), '[]'::jsonb)
             FROM public.customer_tags ct
             WHERE ct.business_id = ANY(v_chain_ids) AND ct.user_id = ci.user_id) AS tags,
          GREATEST(
            COALESCE((SELECT max(r.created_at) FROM public.reviews r
               WHERE r.business_id = ANY(v_chain_ids) AND r.user_id = ci.user_id AND r.status = 'approved'), 'epoch'::timestamptz),
            COALESCE((SELECT max(rs.created_at) FROM public.reservations rs
               WHERE rs.business_id = ANY(v_chain_ids) AND rs.user_id = ci.user_id), 'epoch'::timestamptz),
            COALESCE((SELECT max(bf.created_at) FROM public.business_follows bf
               WHERE bf.business_id = ANY(v_chain_ids) AND bf.user_id = ci.user_id), 'epoch'::timestamptz),
            COALESCE((SELECT max(le.created_at) FROM public.loyalty_events le
               JOIN public.loyalty_members lm2 ON lm2.id = le.member_id
               WHERE v_program_id IS NOT NULL AND lm2.program_id = v_program_id AND lm2.user_id = ci.user_id), 'epoch'::timestamptz)
          ) AS last_interaction_at,
          LEAST(
            COALESCE((SELECT min(r.created_at) FROM public.reviews r
               WHERE r.business_id = ANY(v_chain_ids) AND r.user_id = ci.user_id AND r.status = 'approved'), 'infinity'::timestamptz),
            COALESCE((SELECT min(rs.created_at) FROM public.reservations rs
               WHERE rs.business_id = ANY(v_chain_ids) AND rs.user_id = ci.user_id), 'infinity'::timestamptz),
            COALESCE((SELECT min(bf.created_at) FROM public.business_follows bf
               WHERE bf.business_id = ANY(v_chain_ids) AND bf.user_id = ci.user_id), 'infinity'::timestamptz),
            COALESCE((SELECT min(le.created_at) FROM public.loyalty_events le
               JOIN public.loyalty_members lm2 ON lm2.id = le.member_id
               WHERE v_program_id IS NOT NULL AND lm2.program_id = v_program_id AND lm2.user_id = ci.user_id), 'infinity'::timestamptz)
          ) AS first_interaction_at
        FROM customer_ids ci
      )
      SELECT jsonb_agg(
        jsonb_build_object(
          'user_id', s.user_id,
          'display_name', coalesce(up.display_name, 'Kullanıcı'),
          'avatar_url', up.avatar_url,
          'last_interaction_at', s.last_interaction_at,
          'first_interaction_at', s.first_interaction_at,
          'review_count', s.review_count,
          'reservation_count', s.reservation_count,
          'loyalty_progress', s.loyalty_progress,
          'loyalty_reward_threshold', v_reward_threshold,
          'loyalty_event_count', s.loyalty_event_count,
          'is_following', s.is_following,
          'is_email_subscribed', s.is_email_subscribed,
          'tags', s.tags
        )
        ORDER BY s.last_interaction_at DESC
      )
      FROM summary s
      LEFT JOIN public.user_profiles up ON up.user_id = s.user_id
    ),
    '[]'::jsonb
  );
END;
$function$;

COMMENT ON FUNCTION public.get_business_customers_v1(uuid) IS
  'İşletmeyle etkileşimi olan müşterileri (review/reservation/follow/loyalty birleşimi) döner. '
  'first_interaction_at/loyalty_event_count/is_following/is_email_subscribed alanları '
  'yeni/tekrar eden/sadık sınıflandırması ve e-posta abonelik oranı için eklendi. '
  'Called by: app/sahip/musteriler/page.tsx.';
