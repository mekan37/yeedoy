-- Sahip Paneli Güvenlik Denetimi P2 performans: get_business_customers_v1,
-- her müşteri satırı için ~10 korele alt-sorgu çalıştırıyordu
-- (review_count, reservation_count, loyalty_progress,
-- loyalty_event_count, is_following, is_email_subscribed, tags, +
-- last/first_interaction_at için 4'er alt-sorgu). Aynı sonucu üreten
-- LEFT JOIN + GROUP BY tabanlı agregasyona taşındı. Çıktı sözleşmesi
-- (jsonb şekli, sıralama) birebir korundu — canlı testte gerçek veriyle
-- byte-byte aynı çıktı doğrulandı. Sayfalama (p_limit/p_offset) bu
-- turda eklenmedi çünkü musteriler/[user_id] detay sayfası şu an tam
-- listeyi çekip client-side .find() yapıyor — sayfalama eklemek o
-- sayfanın da yeniden tasarlanmasını gerektirir, ayrı bir değişiklik
-- olarak bırakıldı.
create or replace function public.get_business_customers_v1(p_business_id uuid)
returns jsonb
language plpgsql
stable security definer
set search_path to 'public'
as $function$
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
      review_agg AS (
        SELECT r.user_id, count(*) AS review_count, max(r.created_at) AS max_at, min(r.created_at) AS min_at
        FROM public.reviews r
        WHERE r.business_id = ANY(v_chain_ids) AND r.status = 'approved'
          AND r.user_id IN (SELECT user_id FROM customer_ids)
        GROUP BY r.user_id
      ),
      reservation_agg AS (
        SELECT rs.user_id, count(*) AS reservation_count, max(rs.created_at) AS max_at, min(rs.created_at) AS min_at
        FROM public.reservations rs
        WHERE rs.business_id = ANY(v_chain_ids)
          AND rs.user_id IN (SELECT user_id FROM customer_ids)
        GROUP BY rs.user_id
      ),
      follow_agg AS (
        SELECT bf.user_id, bool_or(bf.is_subscribed_email) AS is_email_subscribed, max(bf.created_at) AS max_at, min(bf.created_at) AS min_at
        FROM public.business_follows bf
        WHERE bf.business_id = ANY(v_chain_ids)
          AND bf.user_id IN (SELECT user_id FROM customer_ids)
        GROUP BY bf.user_id
      ),
      loyalty_agg AS (
        SELECT lm.user_id, lm.progress AS loyalty_progress, count(le.id) AS loyalty_event_count,
               max(le.created_at) AS max_at, min(le.created_at) AS min_at
        FROM public.loyalty_members lm
        LEFT JOIN public.loyalty_events le ON le.member_id = lm.id
        WHERE v_program_id IS NOT NULL AND lm.program_id = v_program_id
        GROUP BY lm.user_id, lm.progress
      ),
      tags_agg AS (
        SELECT ct.user_id, jsonb_agg(jsonb_build_object('id', ct.id, 'tag', ct.tag) ORDER BY ct.created_at) AS tags
        FROM public.customer_tags ct
        WHERE ct.business_id = ANY(v_chain_ids)
          AND ct.user_id IN (SELECT user_id FROM customer_ids)
        GROUP BY ct.user_id
      ),
      summary AS (
        SELECT
          ci.user_id,
          COALESCE(ra.review_count, 0) AS review_count,
          COALESCE(rsa.reservation_count, 0) AS reservation_count,
          la.loyalty_progress,
          COALESCE(la.loyalty_event_count, 0) AS loyalty_event_count,
          (fa.user_id IS NOT NULL) AS is_following,
          COALESCE(fa.is_email_subscribed, false) AS is_email_subscribed,
          COALESCE(ta.tags, '[]'::jsonb) AS tags,
          GREATEST(
            COALESCE(ra.max_at, 'epoch'::timestamptz),
            COALESCE(rsa.max_at, 'epoch'::timestamptz),
            COALESCE(fa.max_at, 'epoch'::timestamptz),
            COALESCE(la.max_at, 'epoch'::timestamptz)
          ) AS last_interaction_at,
          LEAST(
            COALESCE(ra.min_at, 'infinity'::timestamptz),
            COALESCE(rsa.min_at, 'infinity'::timestamptz),
            COALESCE(fa.min_at, 'infinity'::timestamptz),
            COALESCE(la.min_at, 'infinity'::timestamptz)
          ) AS first_interaction_at
        FROM customer_ids ci
        LEFT JOIN review_agg ra ON ra.user_id = ci.user_id
        LEFT JOIN reservation_agg rsa ON rsa.user_id = ci.user_id
        LEFT JOIN follow_agg fa ON fa.user_id = ci.user_id
        LEFT JOIN loyalty_agg la ON la.user_id = ci.user_id
        LEFT JOIN tags_agg ta ON ta.user_id = ci.user_id
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
