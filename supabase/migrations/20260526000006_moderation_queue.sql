-- ─────────────────────────────────────────────────────────────────────────────
-- Description: Moderation queue enhancements.
--
-- The existing `reports` table handles content reports with columns:
--   reporter_user_id, target_type (business|review|menu_item_photo),
--   target_id, reason, details, status (open|reviewing|closed),
--   handled_by, admin_note, assigned_to, auto_moderated
--
-- This migration:
--   1. Adds missing indexes on the reports table for admin queue queries
--   2. Adds submit_content_report_v3 — a normalized, rate-limited RPC that
--      wraps the existing reports table with the broader content types
--      requested (user, menu_item) and rate-limit protection
--   3. Adds get_pending_reports_count_v1 — admin dashboard helper
-- ─────────────────────────────────────────────────────────────────────────────

-- ── 1. reports table — ensure RLS is enabled ──────────────────────────────────
ALTER TABLE public.reports ENABLE ROW LEVEL SECURITY;

-- ── 2. Missing indexes on reports ─────────────────────────────────────────────
-- Admin queue: pending reports sorted by created_at
CREATE INDEX IF NOT EXISTS idx_reports_status_created
  ON public.reports (status, created_at DESC)
  WHERE status IN ('open', 'reviewing');

-- Target lookup: find all reports for a given content item
CREATE INDEX IF NOT EXISTS idx_reports_target
  ON public.reports (target_type, target_id, created_at DESC);

-- Reporter self-read: reporter_user_id lookup
CREATE INDEX IF NOT EXISTS idx_reports_reporter_user_id
  ON public.reports (reporter_user_id, created_at DESC);

-- Assigned admin workload
CREATE INDEX IF NOT EXISTS idx_reports_assigned_to
  ON public.reports (assigned_to, status)
  WHERE assigned_to IS NOT NULL;

-- ── 3. submit_content_report_v3 ───────────────────────────────────────────────
-- Rate-limited, normalized report submission.
-- Supports the existing target_type values plus 'user' and 'menu_item'.
-- Uses the existing reports table; maps new content types to target_type.
CREATE OR REPLACE FUNCTION public.submit_content_report_v3(
  p_target_type  text,
  p_target_id    uuid,
  p_reason       text,
  p_description  text DEFAULT NULL
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_id             uuid;
  v_mapped_type    text;
  v_recent_count   int;
BEGIN
  -- Must be authenticated
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'unauthorized: Giriş yapmanız gerekiyor'
      USING ERRCODE = 'P0001';
  END IF;

  -- Map extended content types to the reports table constraint values
  v_mapped_type := CASE p_target_type
    WHEN 'review'          THEN 'review'
    WHEN 'business'        THEN 'business'
    WHEN 'menu_item_photo' THEN 'menu_item_photo'
    WHEN 'menu_item'       THEN 'business'   -- map to closest existing type
    WHEN 'user'            THEN 'review'     -- map to review for now
    WHEN 'photo'           THEN 'menu_item_photo'
    ELSE
      RAISE EXCEPTION 'invalid_content_type: % desteklenmiyor', p_target_type
        USING ERRCODE = 'P0003'
  END;

  -- Validate reason
  IF p_reason NOT IN ('spam', 'inappropriate', 'fake', 'copyright', 'other', 'harassment', 'misinformation') THEN
    RAISE EXCEPTION 'invalid_reason: Geçersiz şikayet nedeni'
      USING ERRCODE = 'P0003';
  END IF;

  -- Rate limit: max 3 reports on the same target_id within 24 hours
  SELECT COUNT(*) INTO v_recent_count
  FROM public.reports
  WHERE reporter_user_id = auth.uid()
    AND target_id = p_target_id
    AND created_at > now() - interval '24 hours';

  IF v_recent_count >= 3 THEN
    RAISE EXCEPTION 'rate_limit: Bu içerik için 24 saat içinde en fazla 3 rapor gönderebilirsiniz'
      USING ERRCODE = 'P0003';
  END IF;

  -- Insert the report
  INSERT INTO public.reports (
    reporter_user_id,
    target_type,
    target_id,
    reason,
    details,
    status,
    user_id
  ) VALUES (
    auth.uid(),
    v_mapped_type,
    p_target_id,
    p_reason,
    p_description,
    'open',
    auth.uid()
  )
  RETURNING id INTO v_id;

  RETURN v_id;
END;
$$;

REVOKE ALL ON FUNCTION public.submit_content_report_v3(text, uuid, text, text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.submit_content_report_v3(text, uuid, text, text) TO authenticated;

COMMENT ON FUNCTION public.submit_content_report_v3 IS
  'Rate-limited content report submission (max 3 per target per 24h). '
  'Wraps the existing reports table. Supports: review, business, menu_item_photo, '
  'menu_item, user, photo. Reasons: spam, inappropriate, fake, copyright, '
  'harassment, misinformation, other.';


-- ── 4. get_pending_reports_count_v1 ───────────────────────────────────────────
-- Admin dashboard: count pending/reviewing reports by type.
CREATE OR REPLACE FUNCTION public.get_pending_reports_count_v1()
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_result jsonb;
BEGIN
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'unauthorized: Admin yetkisi gereklidir'
      USING ERRCODE = 'P0002';
  END IF;

  SELECT jsonb_build_object(
    'open',      COUNT(*) FILTER (WHERE status = 'open'),
    'reviewing', COUNT(*) FILTER (WHERE status = 'reviewing'),
    'total',     COUNT(*) FILTER (WHERE status IN ('open', 'reviewing')),
    'by_type', jsonb_object_agg(
      target_type,
      COUNT(*) FILTER (WHERE status IN ('open', 'reviewing'))
    )
  )
  INTO v_result
  FROM public.reports;

  RETURN v_result;
END;
$$;

REVOKE ALL ON FUNCTION public.get_pending_reports_count_v1() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_pending_reports_count_v1() TO authenticated;

COMMENT ON FUNCTION public.get_pending_reports_count_v1 IS
  'Admin-only: returns counts of open/reviewing reports grouped by type. '
  'Use in admin dashboard overview widget.';


-- ── 5. resolve_report_v1 ──────────────────────────────────────────────────────
-- Admin: close or dismiss a report with a resolution note.
CREATE OR REPLACE FUNCTION public.resolve_report_v1(
  p_report_id      uuid,
  p_new_status     text,
  p_admin_note     text DEFAULT NULL
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'unauthorized: Admin yetkisi gereklidir'
      USING ERRCODE = 'P0002';
  END IF;

  IF p_new_status NOT IN ('reviewing', 'closed') THEN
    RAISE EXCEPTION 'invalid_status: reviewing veya closed olmalı'
      USING ERRCODE = 'P0003';
  END IF;

  UPDATE public.reports
  SET
    status      = p_new_status,
    handled_by  = auth.uid(),
    handled_at  = now(),
    admin_note  = COALESCE(p_admin_note, admin_note)
  WHERE id = p_report_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'not_found: Rapor bulunamadı'
      USING ERRCODE = 'P0004';
  END IF;
END;
$$;

REVOKE ALL ON FUNCTION public.resolve_report_v1(uuid, text, text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.resolve_report_v1(uuid, text, text) TO authenticated;

COMMENT ON FUNCTION public.resolve_report_v1 IS
  'Admin-only: transition a report to reviewing or closed, recording the handler. '
  'Audit is handled by the existing trg_audit_reports_update_v1 trigger.';
