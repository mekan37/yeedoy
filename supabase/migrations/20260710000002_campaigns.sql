-- ─────────────────────────────────────────────────────────────────────────────
-- Kampanya sistemi (owner panel)
-- Tip: discount | special_offer | loyalty | announcement
-- Durum: draft | planned | active | completed
-- ─────────────────────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS public.campaigns (
  id              UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id     UUID        NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
  title           TEXT        NOT NULL,
  description     TEXT,
  type            TEXT        NOT NULL DEFAULT 'announcement',
  status          TEXT        NOT NULL DEFAULT 'draft',
  discount_percent SMALLINT,
  image_url       TEXT,
  starts_at       TIMESTAMPTZ,
  ends_at         TIMESTAMPTZ,
  view_count      INT         NOT NULL DEFAULT 0,
  click_count     INT         NOT NULL DEFAULT 0,
  created_by      UUID        REFERENCES auth.users(id),
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT now(),

  CONSTRAINT campaigns_title_len    CHECK (char_length(title) BETWEEN 1 AND 120),
  CONSTRAINT campaigns_desc_len     CHECK (description IS NULL OR char_length(description) <= 500),
  CONSTRAINT campaigns_type_valid   CHECK (type IN ('discount','special_offer','loyalty','announcement')),
  CONSTRAINT campaigns_status_valid CHECK (status IN ('draft','planned','active','completed')),
  CONSTRAINT campaigns_discount_rng CHECK (discount_percent IS NULL OR discount_percent BETWEEN 1 AND 100),
  CONSTRAINT campaigns_dates_order  CHECK (ends_at IS NULL OR starts_at IS NULL OR ends_at > starts_at)
);

CREATE INDEX IF NOT EXISTS campaigns_business_id_idx ON public.campaigns(business_id);
CREATE INDEX IF NOT EXISTS campaigns_biz_status_idx  ON public.campaigns(business_id, status);

ALTER TABLE public.campaigns ENABLE ROW LEVEL SECURITY;

-- Owner: kendi işletmesinin kampanyalarını tam yönetebilir
CREATE POLICY "campaigns_owner_all" ON public.campaigns
  FOR ALL TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.owner_claims oc
      WHERE oc.business_id = campaigns.business_id
        AND oc.user_id    = auth.uid()
        AND oc.status     = 'approved'
    )
  );

-- Herkes aktif kampanyaları okuyabilir (mobil/web discovery için)
CREATE POLICY "campaigns_public_read" ON public.campaigns
  FOR SELECT TO anon, authenticated
  USING (status = 'active');

-- updated_at trigger
CREATE OR REPLACE FUNCTION public.tg_campaigns_set_updated_at()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN NEW.updated_at = now(); RETURN NEW; END; $$;

CREATE TRIGGER campaigns_set_updated_at
  BEFORE UPDATE ON public.campaigns
  FOR EACH ROW EXECUTE FUNCTION public.tg_campaigns_set_updated_at();

-- ─────────────────────────────────────────────────────────────────────────────
-- RPC: owner_list_campaigns_v1
-- ─────────────────────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.owner_list_campaigns_v1(
  p_business_id UUID,
  p_status      TEXT    DEFAULT NULL,
  p_type        TEXT    DEFAULT NULL,
  p_page        INT     DEFAULT 1,
  p_page_size   INT     DEFAULT 20
)
RETURNS JSONB
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public
AS $$
DECLARE
  v_total INT;
  v_rows  JSONB;
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

  SELECT count(*)::INT INTO v_total
  FROM public.campaigns c
  WHERE c.business_id = p_business_id
    AND (p_status IS NULL OR c.status = p_status)
    AND (p_type   IS NULL OR c.type   = p_type);

  SELECT coalesce(jsonb_agg(to_jsonb(r) ORDER BY r.created_at DESC), '[]'::jsonb) INTO v_rows
  FROM (
    SELECT id, title, description, type, status, discount_percent,
           image_url, starts_at, ends_at, view_count, click_count,
           created_at, updated_at
    FROM public.campaigns
    WHERE business_id = p_business_id
      AND (p_status IS NULL OR status = p_status)
      AND (p_type   IS NULL OR type   = p_type)
    ORDER BY created_at DESC
    LIMIT  greatest(p_page_size, 1)
    OFFSET (greatest(p_page, 1) - 1) * greatest(p_page_size, 1)
  ) r;

  RETURN jsonb_build_object('total', v_total, 'campaigns', v_rows);
END;
$$;

REVOKE ALL ON FUNCTION public.owner_list_campaigns_v1(UUID,TEXT,TEXT,INT,INT) FROM PUBLIC;
GRANT  EXECUTE ON FUNCTION public.owner_list_campaigns_v1(UUID,TEXT,TEXT,INT,INT) TO authenticated;
COMMENT ON FUNCTION public.owner_list_campaigns_v1 IS
  'Owner: işletme kampanyalarını sayfalı listeler. Called by: owner/marketing/campaigns.';

-- ─────────────────────────────────────────────────────────────────────────────
-- RPC: owner_upsert_campaign_v1
-- ─────────────────────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.owner_upsert_campaign_v1(
  p_business_id     UUID,
  p_title           TEXT,
  p_type            TEXT,
  p_status          TEXT        DEFAULT 'draft',
  p_description     TEXT        DEFAULT NULL,
  p_discount_percent SMALLINT   DEFAULT NULL,
  p_starts_at       TIMESTAMPTZ DEFAULT NULL,
  p_ends_at         TIMESTAMPTZ DEFAULT NULL,
  p_image_url       TEXT        DEFAULT NULL,
  p_id              UUID        DEFAULT NULL
)
RETURNS UUID
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public
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
    INSERT INTO public.campaigns
      (business_id, title, description, type, status,
       discount_percent, starts_at, ends_at, image_url, created_by)
    VALUES
      (p_business_id, p_title, p_description, p_type, p_status,
       p_discount_percent, p_starts_at, p_ends_at, p_image_url, auth.uid())
    RETURNING id INTO v_id;
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

REVOKE ALL ON FUNCTION public.owner_upsert_campaign_v1(UUID,TEXT,TEXT,TEXT,TEXT,SMALLINT,TIMESTAMPTZ,TIMESTAMPTZ,TEXT,UUID) FROM PUBLIC;
GRANT  EXECUTE ON FUNCTION public.owner_upsert_campaign_v1(UUID,TEXT,TEXT,TEXT,TEXT,SMALLINT,TIMESTAMPTZ,TIMESTAMPTZ,TEXT,UUID) TO authenticated;
COMMENT ON FUNCTION public.owner_upsert_campaign_v1 IS
  'Owner: kampanya oluşturur (p_id=NULL) veya günceller. Called by: owner/marketing/campaigns.';

-- ─────────────────────────────────────────────────────────────────────────────
-- RPC: owner_delete_campaign_v1
-- ─────────────────────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.owner_delete_campaign_v1(
  p_id          UUID,
  p_business_id UUID
)
RETURNS VOID
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public
AS $$
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

  DELETE FROM public.campaigns WHERE id = p_id AND business_id = p_business_id;
END;
$$;

REVOKE ALL ON FUNCTION public.owner_delete_campaign_v1(UUID,UUID) FROM PUBLIC;
GRANT  EXECUTE ON FUNCTION public.owner_delete_campaign_v1(UUID,UUID) TO authenticated;
COMMENT ON FUNCTION public.owner_delete_campaign_v1 IS
  'Owner: kampanyayı kalıcı siler. Called by: owner/marketing/campaigns.';

-- ─────────────────────────────────────────────────────────────────────────────
-- RPC: owner_get_campaign_stats_v1
-- ─────────────────────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.owner_get_campaign_stats_v1(
  p_business_id UUID,
  p_period_days INT DEFAULT 7
)
RETURNS JSONB
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public
AS $$
DECLARE v_result JSONB;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'unauthorized' USING ERRCODE = 'P0002';
  END IF;

  SELECT jsonb_build_object(
    'total_campaigns',  count(*),
    'active_campaigns', count(*) FILTER (WHERE status = 'active'),
    'total_views',      coalesce(sum(view_count), 0),
    'total_clicks',     coalesce(sum(click_count), 0),
    'period_views',     coalesce(sum(view_count)  FILTER (WHERE updated_at >= now() - make_interval(days => p_period_days)), 0),
    'period_clicks',    coalesce(sum(click_count) FILTER (WHERE updated_at >= now() - make_interval(days => p_period_days)), 0)
  ) INTO v_result
  FROM public.campaigns
  WHERE business_id = p_business_id;

  RETURN coalesce(v_result, '{}'::jsonb);
END;
$$;

REVOKE ALL ON FUNCTION public.owner_get_campaign_stats_v1(UUID,INT) FROM PUBLIC;
GRANT  EXECUTE ON FUNCTION public.owner_get_campaign_stats_v1(UUID,INT) TO authenticated;
COMMENT ON FUNCTION public.owner_get_campaign_stats_v1 IS
  'Owner: kampanya özet istatistikleri. Called by: owner/marketing/campaigns.';
