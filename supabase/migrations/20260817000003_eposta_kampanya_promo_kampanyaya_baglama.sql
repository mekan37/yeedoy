-- E-posta kampanyaları artık bağımsız bir özellik değil, promosyon
-- kampanyalarına (public.campaigns) bağlı çalışıyor: sahip panelinde
-- "Kampanyalar" sayfası tek sayfaya indirildi (E-posta Kampanyaları ayrı
-- sayfası kaldırıldı, sekme olarak taşındı). Bir e-posta kampanyası artık
-- var olan bir promosyon kampanyasına referans vermek ZORUNDA
-- (route handler bunu şart koşar) — hiç promosyon kampanyası yoksa e-posta
-- gönderilemez.
--
-- Ayrıca list_email_campaigns_v1'de eksik olan yetki kontrolü eklendi:
-- SECURITY DEFINER olmasına rağmen p_business_id sahipliği hiç
-- doğrulanmıyordu — herhangi bir authenticated kullanıcı başka bir
-- işletmenin e-posta kampanyası listesini (konu satırları, gönderim
-- sayıları) okuyabiliyordu.

ALTER TABLE public.email_campaigns
  ADD COLUMN IF NOT EXISTS campaign_id uuid REFERENCES public.campaigns(id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS email_campaigns_campaign_idx ON public.email_campaigns (campaign_id);

-- ── create_email_campaign_v1 (campaign_id eklendi) ──────────────────────────
DROP FUNCTION IF EXISTS public.create_email_campaign_v1(uuid, text, text, text, timestamptz);

CREATE OR REPLACE FUNCTION public.create_email_campaign_v1(
  p_business_id    uuid,
  p_subject        text,
  p_html_body      text,
  p_target_segment text default 'all_followers',
  p_scheduled_at   timestamptz default null,
  p_campaign_id    uuid default null
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_id uuid;
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM public.business_claims
    WHERE business_id = p_business_id
      AND user_id = auth.uid()
      AND status = 'approved'
  ) THEN
    RAISE EXCEPTION 'not_authorized';
  END IF;

  IF p_campaign_id IS NOT NULL AND NOT EXISTS (
    SELECT 1 FROM public.campaigns WHERE id = p_campaign_id AND business_id = p_business_id
  ) THEN
    RAISE EXCEPTION 'validation_error: kampanya bulunamadı' USING ERRCODE = 'P0003';
  END IF;

  INSERT INTO public.email_campaigns (
    business_id, subject, html_body, target_segment, scheduled_at, campaign_id
  )
  VALUES (p_business_id, p_subject, p_html_body, p_target_segment, p_scheduled_at, p_campaign_id)
  RETURNING id INTO v_id;

  RETURN v_id;
END;
$$;

GRANT EXECUTE ON FUNCTION public.create_email_campaign_v1(uuid, text, text, text, timestamptz, uuid) TO authenticated;
COMMENT ON FUNCTION public.create_email_campaign_v1(uuid, text, text, text, timestamptz, uuid) IS
  'E-posta kampanyası oluşturur. p_campaign_id: bağlı olduğu promosyon kampanyası (public.campaigns) — '
  'verilirse aynı işletmeye ait olduğu doğrulanır. Called by: app/sunucu/sahip/eposta-kampanya/route.ts.';

-- ── list_email_campaigns_v1 (yetki kontrolü + campaign_id/campaign_title) ───
DROP FUNCTION IF EXISTS public.list_email_campaigns_v1(uuid, int, int);

CREATE OR REPLACE FUNCTION public.list_email_campaigns_v1(
  p_business_id uuid,
  p_limit       int  default 20,
  p_offset      int  default 0
)
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM public.business_claims
    WHERE business_id = p_business_id
      AND user_id = auth.uid()
      AND status = 'approved'
  ) THEN
    RAISE EXCEPTION 'unauthorized' USING ERRCODE = 'P0002';
  END IF;

  RETURN (
    SELECT jsonb_build_object(
      'total', count(*) over(),
      'items', coalesce(jsonb_agg(
        jsonb_build_object(
          'id',             sub.id,
          'subject',        sub.subject,
          'target_segment', sub.target_segment,
          'scheduled_at',   sub.scheduled_at,
          'sent_at',        sub.sent_at,
          'sent_count',     sub.sent_count,
          'opened_count',   sub.opened_count,
          'created_at',     sub.created_at,
          'campaign_id',    sub.campaign_id,
          'campaign_title', c.title
        )
        order by sub.created_at desc
      ), '[]'::jsonb)
    )
    FROM (
      SELECT *
      FROM public.email_campaigns
      WHERE business_id = p_business_id
      ORDER BY created_at DESC
      LIMIT p_limit OFFSET p_offset
    ) sub
    LEFT JOIN public.campaigns c ON c.id = sub.campaign_id
  );
END;
$$;

GRANT EXECUTE ON FUNCTION public.list_email_campaigns_v1(uuid, int, int) TO authenticated;
COMMENT ON FUNCTION public.list_email_campaigns_v1(uuid, int, int) IS
  'İşletmenin e-posta kampanyalarını listeler (campaign_id/campaign_title dahil). '
  'Çağıran kullanıcının işletme sahipliği doğrulanır. Called by: app/sahip/pazarlama/kampanyalar/page.tsx.';
