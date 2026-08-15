-- CRM v2 — etiket bazlı toplu e-posta kampanyası. bkz.
-- docs/superpowers/specs/2026-08-14-crm-v2-eposta-kampanya-design.md
--
-- email_campaigns tablosu ve create_email_campaign_v1/list_email_campaigns_v1/
-- estimate_email_segment_v1 RPC'leri zaten var (20260424000009_email_campaigns.sql).
-- Bu migration: (1) yeni bir alıcı-çözümleme RPC'si ekler — hem mevcut 3
-- takipçi-segmentini hem yeni tag:<etiket> segmentini destekler, her ikisinde
-- de user_profiles.marketing_email_opt_in taban filtresi zorunlu (eski
-- implementasyonda hiç yoktu — gerçek bir uyumluluk boşluğuydu); (2)
-- estimate_email_segment_v1'i aynı tag: önekini ve aynı çift-filtreyi
-- tanıyacak şekilde genişletir; (3) etiket dropdown'ı için list_customer_tags_v1.

-- ── get_email_campaign_recipients_v1 ────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.get_email_campaign_recipients_v1(
  p_business_id uuid,
  p_target_segment text
)
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_tag text;
BEGIN
  IF NOT public.has_business_permission_v1(p_business_id, 'menu_write') THEN
    RAISE EXCEPTION 'unauthorized' USING ERRCODE = 'P0002';
  END IF;

  IF p_target_segment LIKE 'tag:%' THEN
    v_tag := substring(p_target_segment FROM 5);

    RETURN COALESCE(
      (
        SELECT jsonb_agg(
          jsonb_build_object(
            'user_id', u.id,
            'email', u.email,
            'display_name', coalesce(up.display_name, 'Değerli Müşteri')
          )
        )
        FROM public.customer_tags ct
        JOIN auth.users u ON u.id = ct.user_id
        JOIN public.user_profiles up ON up.user_id = u.id
        WHERE ct.business_id = p_business_id
          AND ct.tag = v_tag
          AND up.marketing_email_opt_in = true
          AND u.email IS NOT NULL
      ),
      '[]'::jsonb
    );
  END IF;

  RETURN COALESCE(
    (
      SELECT jsonb_agg(
        jsonb_build_object(
          'user_id', u.id,
          'email', u.email,
          'display_name', coalesce(up.display_name, 'Değerli Müşteri')
        )
      )
      FROM public.business_follows bf
      JOIN auth.users u ON u.id = bf.user_id
      JOIN public.user_profiles up ON up.user_id = u.id
      WHERE bf.business_id = p_business_id
        AND bf.is_subscribed_email = true
        AND up.marketing_email_opt_in = true
        AND u.email IS NOT NULL
        AND (
          p_target_segment = 'all_followers'
          OR (p_target_segment = 'new_30d' AND bf.created_at >= now() - interval '30 days')
          OR (p_target_segment = 'inactive_30d' AND bf.created_at < now() - interval '30 days')
        )
    ),
    '[]'::jsonb
  );
END;
$$;

-- ── estimate_email_segment_v1 (genişletildi: tag: önekini tanır) ───────────
CREATE OR REPLACE FUNCTION public.estimate_email_segment_v1(
  p_business_id uuid,
  p_segment     text DEFAULT 'all_followers'
)
RETURNS int
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_tag text;
  v_count int;
BEGIN
  IF NOT public.has_business_permission_v1(p_business_id, 'menu_write') THEN
    RAISE EXCEPTION 'unauthorized' USING ERRCODE = 'P0002';
  END IF;

  IF p_segment LIKE 'tag:%' THEN
    v_tag := substring(p_segment FROM 5);
    SELECT count(*)::int INTO v_count
    FROM public.customer_tags ct
    JOIN auth.users u ON u.id = ct.user_id
    JOIN public.user_profiles up ON up.user_id = u.id
    WHERE ct.business_id = p_business_id
      AND ct.tag = v_tag
      AND up.marketing_email_opt_in = true
      AND u.email IS NOT NULL;
    RETURN v_count;
  END IF;

  SELECT count(*)::int INTO v_count
  FROM public.business_follows bf
  JOIN auth.users u ON u.id = bf.user_id
  JOIN public.user_profiles up ON up.user_id = u.id
  WHERE bf.business_id = p_business_id
    AND bf.is_subscribed_email = true
    AND up.marketing_email_opt_in = true
    AND u.email IS NOT NULL
    AND (
      p_segment = 'all_followers'
      OR (p_segment = 'new_30d'     AND bf.created_at >= now() - interval '30 days')
      OR (p_segment = 'inactive_30d' AND bf.created_at < now() - interval '30 days')
    );
  RETURN v_count;
END;
$$;

-- ── list_customer_tags_v1 (etiket dropdown veri kaynağı) ────────────────────
CREATE OR REPLACE FUNCTION public.list_customer_tags_v1(p_business_id uuid)
RETURNS text[]
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NOT public.has_business_permission_v1(p_business_id, 'menu_write') THEN
    RAISE EXCEPTION 'unauthorized' USING ERRCODE = 'P0002';
  END IF;

  RETURN COALESCE(
    (SELECT array_agg(DISTINCT tag ORDER BY tag) FROM public.customer_tags WHERE business_id = p_business_id),
    ARRAY[]::text[]
  );
END;
$$;

REVOKE ALL ON FUNCTION public.get_email_campaign_recipients_v1(uuid, text) FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION public.get_email_campaign_recipients_v1(uuid, text) FROM anon;
GRANT EXECUTE ON FUNCTION public.get_email_campaign_recipients_v1(uuid, text) TO authenticated;
COMMENT ON FUNCTION public.get_email_campaign_recipients_v1 IS
  'CRM v2 e-posta kampanyası: hedef segmentteki (takipçi ya da tag:) alıcıları, marketing_email_opt_in filtresiyle döner. Called by: app/sunucu/sahip/eposta-kampanya/route.ts.';

REVOKE ALL ON FUNCTION public.list_customer_tags_v1(uuid) FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION public.list_customer_tags_v1(uuid) FROM anon;
GRANT EXECUTE ON FUNCTION public.list_customer_tags_v1(uuid) TO authenticated;
COMMENT ON FUNCTION public.list_customer_tags_v1 IS
  'CRM v2 e-posta kampanyası: etiket dropdown''ı için distinct customer_tags.tag listesi. Called by: app/sahip/pazarlama/eposta-kampanyalari/page.tsx.';

-- estimate_email_segment_v1 zaten authenticated'a GRANT'lıydı (20260424000009);
-- CREATE OR REPLACE imzayı değiştirmediği için GRANT'ı korur, yeniden yazmaya gerek yok.
