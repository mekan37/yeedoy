-- Remove IP/user-agent tracking from business_audit_log (user decision 2026-07-18).
-- The table was already deployed via 20260717135736_business_audit_log.sql with
-- ip_address/user_agent columns; this migration removes them and updates both
-- RPCs to stop capturing/returning them. Table currently has 0 rows (Faz 2 —
-- wiring real mutation call sites — has not started), so this is a safe,
-- lossless schema change.

ALTER TABLE public.business_audit_log DROP COLUMN IF EXISTS ip_address;
ALTER TABLE public.business_audit_log DROP COLUMN IF EXISTS user_agent;

CREATE OR REPLACE FUNCTION public.log_business_action_v1(
  p_business_id  UUID,
  p_action       TEXT,
  p_description  TEXT,
  p_target_table TEXT DEFAULT NULL,
  p_target_id    UUID DEFAULT NULL,
  p_target_label TEXT DEFAULT NULL,
  p_meta         JSONB DEFAULT '{}'::jsonb
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_actor_role TEXT;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'unauthorized: Oturum açmanız gerekiyor' USING ERRCODE = 'P0002';
  END IF;

  IF EXISTS (
    SELECT 1 FROM public.owner_claims
     WHERE business_id = p_business_id
       AND user_id     = auth.uid()
       AND status      = 'approved'
  ) THEN
    v_actor_role := 'owner';
  ELSE
    SELECT role INTO v_actor_role
      FROM public.business_team_memberships
     WHERE business_id  = p_business_id
       AND user_id      = auth.uid()
       AND accepted_at IS NOT NULL
       AND revoked_at  IS NULL
     LIMIT 1;
  END IF;

  IF v_actor_role IS NULL THEN
    RAISE EXCEPTION 'unauthorized: Bu işletme için yetkiniz yok' USING ERRCODE = 'P0002';
  END IF;

  IF nullif(trim(coalesce(p_action, '')), '') IS NULL THEN
    RAISE EXCEPTION 'validation_error: action boş olamaz' USING ERRCODE = 'P0003';
  END IF;

  IF nullif(trim(coalesce(p_description, '')), '') IS NULL THEN
    RAISE EXCEPTION 'validation_error: description boş olamaz' USING ERRCODE = 'P0003';
  END IF;

  INSERT INTO public.business_audit_log (
    business_id, actor_id, actor_role, action, description,
    target_table, target_id, target_label, meta
  ) VALUES (
    p_business_id, auth.uid(), v_actor_role, p_action, p_description,
    p_target_table, p_target_id, p_target_label,
    coalesce(p_meta, '{}'::jsonb)
  );
END;
$$;

COMMENT ON FUNCTION public.log_business_action_v1(
  UUID, TEXT, TEXT, TEXT, UUID, TEXT, JSONB
) IS 'Writes one immutable audit row for a business owner/team-member action. Captures actor role snapshot. Does not capture IP/user-agent (user decision 2026-07-18). Called by: owner panel mutation server actions (Faz 2 — not yet wired up in Faz 1).';


CREATE OR REPLACE FUNCTION public.get_business_audit_log_v1(
  p_business_ids UUID[],
  p_actor_id     UUID DEFAULT NULL,
  p_action       TEXT DEFAULT NULL,
  p_date_from    DATE DEFAULT NULL,
  p_date_to      DATE DEFAULT NULL,
  p_limit        INT  DEFAULT 10,
  p_offset       INT  DEFAULT 0
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_allowed_ids UUID[];
  v_limit       INT;
  v_total       INT;
  v_rows        JSONB;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'unauthorized: Oturum açmanız gerekiyor' USING ERRCODE = 'P0002';
  END IF;

  SELECT ARRAY(
    SELECT business_id FROM public.owner_claims
     WHERE user_id = auth.uid() AND status = 'approved'
    UNION
    SELECT business_id FROM public.business_team_memberships
     WHERE user_id = auth.uid() AND accepted_at IS NOT NULL AND revoked_at IS NULL
  ) INTO v_allowed_ids;

  v_limit := LEAST(GREATEST(p_limit, 1), 200);

  SELECT COUNT(*)
    INTO v_total
    FROM public.business_audit_log l
   WHERE l.business_id = ANY (p_business_ids)
     AND l.business_id = ANY (v_allowed_ids)
     AND (p_actor_id  IS NULL OR l.actor_id  = p_actor_id)
     AND (p_action    IS NULL OR l.action    = p_action)
     AND (p_date_from IS NULL OR l.created_at >= p_date_from)
     AND (p_date_to   IS NULL OR l.created_at <  (p_date_to + INTERVAL '1 day'));

  SELECT COALESCE(jsonb_agg(row_data), '[]'::jsonb)
    INTO v_rows
    FROM (
      SELECT jsonb_build_object(
        'id',               l.id,
        'created_at',       l.created_at,
        'actor_id',         l.actor_id,
        'actor_name',       COALESCE(up.display_name, 'Kullanıcı'),
        'actor_avatar_url', up.avatar_url,
        'actor_role',       l.actor_role,
        'action',           l.action,
        'description',      l.description,
        'target_table',     l.target_table,
        'target_id',        l.target_id,
        'target_label',     l.target_label,
        'business_id',      l.business_id,
        'business_name',    b.name
      ) AS row_data
      FROM public.business_audit_log l
      LEFT JOIN public.user_profiles up ON up.user_id = l.actor_id
      LEFT JOIN public.businesses    b  ON b.id        = l.business_id
     WHERE l.business_id = ANY (p_business_ids)
       AND l.business_id = ANY (v_allowed_ids)
       AND (p_actor_id  IS NULL OR l.actor_id  = p_actor_id)
       AND (p_action    IS NULL OR l.action    = p_action)
       AND (p_date_from IS NULL OR l.created_at >= p_date_from)
       AND (p_date_to   IS NULL OR l.created_at <  (p_date_to + INTERVAL '1 day'))
     ORDER BY l.created_at DESC
     LIMIT v_limit OFFSET p_offset
    ) sub;

  RETURN jsonb_build_object('rows', v_rows, 'total', v_total);
END;
$$;

COMMENT ON FUNCTION public.get_business_audit_log_v1(
  UUID[], UUID, TEXT, DATE, DATE, INT, INT
) IS 'Returns paginated, filtered audit log rows across one or more owner-managed businesses. Filters: actor, action, date range. Returns {rows, total}. Does not return IP/user-agent (user decision 2026-07-18). Called by: owner panel Denetim Kaydı page.';
