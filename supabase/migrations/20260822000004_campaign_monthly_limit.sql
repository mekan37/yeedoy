-- ─────────────────────────────────────────────────────────────────────────────
-- owner_upsert_campaign_v1: yalnızca YENİ kampanya oluşturma (p_id IS NULL)
-- campaign_count_per_month plan limitini tüketir; düzenleme (p_id IS NOT NULL)
-- sayaç tüketmez.
-- ─────────────────────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.owner_upsert_campaign_v1(
  p_business_id uuid, p_title text, p_type text, p_status text DEFAULT 'draft'::text,
  p_description text DEFAULT NULL::text, p_discount_percent smallint DEFAULT NULL::smallint,
  p_starts_at timestamp with time zone DEFAULT NULL::timestamp with time zone,
  p_ends_at timestamp with time zone DEFAULT NULL::timestamp with time zone,
  p_image_url text DEFAULT NULL::text, p_id uuid DEFAULT NULL::uuid
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE v_id UUID;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'unauthorized' USING ERRCODE = 'P0002';
  END IF;
  IF NOT EXISTS (
    SELECT 1 FROM public.owner_claims oc
    WHERE oc.business_id = p_business_id AND oc.user_id = auth.uid() AND oc.status = 'approved'
  ) THEN
    RAISE EXCEPTION 'unauthorized' USING ERRCODE = 'P0002';
  END IF;

  IF p_id IS NULL THEN
    PERFORM public._check_plan_limit_v1(p_business_id, 'campaign_count_per_month');

    INSERT INTO public.campaigns
      (business_id, title, description, type, status,
       discount_percent, starts_at, ends_at, image_url, created_by)
    VALUES
      (p_business_id, p_title, p_description, p_type, p_status,
       p_discount_percent, p_starts_at, p_ends_at, p_image_url, auth.uid())
    RETURNING id INTO v_id;

    PERFORM public._increment_plan_usage_v1(p_business_id, 'campaign_count_per_month');
  ELSE
    UPDATE public.campaigns SET
      title            = p_title,
      description      = p_description,
      type             = p_type,
      status           = p_status,
      discount_percent = p_discount_percent,
      starts_at        = p_starts_at,
      ends_at          = p_ends_at,
      image_url        = p_image_url
    WHERE id = p_id AND business_id = p_business_id
    RETURNING id INTO v_id;
    IF v_id IS NULL THEN
      RAISE EXCEPTION 'not_found' USING ERRCODE = 'P0001';
    END IF;
  END IF;

  RETURN v_id;
END;
$$;
