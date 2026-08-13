-- CRM v2 — zincir-çapında birleşik görünüm. bkz.
-- docs/superpowers/specs/2026-08-13-crm-v2-zincir-capinda-gorunum-design.md
--
-- _resolve_loyalty_program_v1 (sadakat v1) ile aynı desen: verilen bir
-- business_id'nin ait olduğu zinciri çözümleyip zincir-çapında paylaşılan
-- veriye erişim sağlar. Fark: burada ayrıca çağıranın zincirdeki HER şubede
-- ayrı ayrı yetkili olup olmadığı kontrol ediliyor — business_team_memberships
-- "sadece bu şube" veya "tüm şubeler" (chain_id) kapsamında davet
-- destekliyor (canlı özellik, get_business_role_v1), "sadece bu şube"
-- kapsamlı bir manager'ın kardeş şubelere sızıntısı olmamalı.

-- ── Yardımcı: verilen business_id için zincir-çapında erişilebilir id'leri bul ──
CREATE OR REPLACE FUNCTION public._resolve_chain_business_ids_v1(p_business_id uuid)
RETURNS uuid[]
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_chain_id uuid;
BEGIN
  SELECT chain_id INTO v_chain_id FROM public.businesses WHERE id = p_business_id;

  IF v_chain_id IS NULL THEN
    RETURN ARRAY[p_business_id];
  END IF;

  IF EXISTS (
    SELECT 1 FROM public.businesses sib
    WHERE sib.chain_id = v_chain_id
      AND NOT public.has_business_permission_v1(sib.id, 'menu_write')
  ) THEN
    RETURN ARRAY[p_business_id];
  END IF;

  RETURN (SELECT array_agg(id) FROM public.businesses WHERE chain_id = v_chain_id);
END;
$$;

REVOKE ALL ON FUNCTION public._resolve_chain_business_ids_v1(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public._resolve_chain_business_ids_v1(uuid) TO authenticated;
REVOKE EXECUTE ON FUNCTION public._resolve_chain_business_ids_v1(uuid) FROM authenticated;
COMMENT ON FUNCTION public._resolve_chain_business_ids_v1 IS
  'Internal: p_business_id bir zincirdeyse ve çağıran zincirdeki HER şubede menu_write yetkisine sahipse zincirdeki tüm business id''lerini döner, aksi halde sadece [p_business_id]. Called by: get_business_customers_v1, get_customer_timeline_v1.';

-- ── get_business_customers_v1 (genişletildi: zincir-çapında ANY(chain_ids)) ──
CREATE OR REPLACE FUNCTION public.get_business_customers_v1(p_business_id uuid)
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
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
          ) AS last_interaction_at
        FROM customer_ids ci
      )
      SELECT jsonb_agg(
        jsonb_build_object(
          'user_id', s.user_id,
          'display_name', coalesce(up.display_name, 'Kullanıcı'),
          'avatar_url', up.avatar_url,
          'last_interaction_at', s.last_interaction_at,
          'review_count', s.review_count,
          'reservation_count', s.reservation_count,
          'loyalty_progress', s.loyalty_progress,
          'loyalty_reward_threshold', v_reward_threshold,
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
$$;

-- ── get_customer_timeline_v1 (genişletildi: ANY(chain_ids) + branch_label) ──
CREATE OR REPLACE FUNCTION public.get_customer_timeline_v1(p_business_id uuid, p_user_id uuid)
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_program_id uuid;
  v_chain_ids  uuid[];
BEGIN
  IF NOT public.has_business_permission_v1(p_business_id, 'menu_write') THEN
    RAISE EXCEPTION 'unauthorized' USING ERRCODE = 'P0002';
  END IF;

  v_chain_ids := public._resolve_chain_business_ids_v1(p_business_id);
  v_program_id := public._resolve_loyalty_program_v1(p_business_id);

  RETURN COALESCE(
    (
      SELECT jsonb_agg(evt ORDER BY (evt->>'occurred_at')::timestamptz DESC)
      FROM (
        SELECT jsonb_build_object(
          'event_type', 'review',
          'occurred_at', r.created_at,
          'summary', r.rating || ' yıldız' || CASE WHEN r.title IS NOT NULL AND trim(r.title) <> '' THEN ' — "' || r.title || '"' ELSE '' END,
          'branch_label', (SELECT coalesce(nullif(trim(b.branch_label), ''), b.name) FROM public.businesses b WHERE b.id = r.business_id)
        ) AS evt
        FROM public.reviews r
        WHERE r.business_id = ANY(v_chain_ids) AND r.user_id = p_user_id AND r.status = 'approved'

        UNION ALL

        SELECT jsonb_build_object(
          'event_type', 'reservation',
          'occurred_at', rs.created_at,
          'summary', rs.party_size || ' kişi, ' || to_char(rs.reservation_date, 'DD.MM.YYYY') || ' ' || to_char(rs.reservation_time, 'HH24:MI'),
          'branch_label', (SELECT coalesce(nullif(trim(b.branch_label), ''), b.name) FROM public.businesses b WHERE b.id = rs.business_id)
        )
        FROM public.reservations rs
        WHERE rs.business_id = ANY(v_chain_ids) AND rs.user_id = p_user_id

        UNION ALL

        SELECT jsonb_build_object(
          'event_type', CASE WHEN le.source = 'redeem' THEN 'loyalty_redeem' ELSE 'loyalty_scan' END,
          'occurred_at', le.created_at,
          'summary', CASE WHEN le.source = 'redeem' THEN 'Ödül kullanıldı' ELSE '+' || le.amount || ' ilerleme' END,
          'branch_label', NULL
        )
        FROM public.loyalty_events le
        JOIN public.loyalty_members lm ON lm.id = le.member_id
        WHERE v_program_id IS NOT NULL AND lm.program_id = v_program_id AND lm.user_id = p_user_id

        UNION ALL

        SELECT jsonb_build_object(
          'event_type', 'follow',
          'occurred_at', bf.created_at,
          'summary', 'İşletmeyi takip etmeye başladı',
          'branch_label', (SELECT coalesce(nullif(trim(b.branch_label), ''), b.name) FROM public.businesses b WHERE b.id = bf.business_id)
        )
        FROM public.business_follows bf
        WHERE bf.business_id = ANY(v_chain_ids) AND bf.user_id = p_user_id

        UNION ALL

        SELECT jsonb_build_object(
          'event_type', 'note',
          'occurred_at', cn.created_at,
          'summary', cn.note,
          'branch_label', (SELECT coalesce(nullif(trim(b.branch_label), ''), b.name) FROM public.businesses b WHERE b.id = cn.business_id)
        )
        FROM public.customer_notes cn
        WHERE cn.business_id = ANY(v_chain_ids) AND cn.user_id = p_user_id
      ) sub
    ),
    '[]'::jsonb
  );
END;
$$;
