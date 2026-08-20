-- Gözlemlenebilirlik sayfasındaki uyarı eşikleri şu ana kadar tamamen kozmetikti
-- (AlertKonfigIstemci: sabit DEFAULT_RULES dizisi, save() hiçbir yere yazmıyordu).
-- Bu migration gerçek, kalıcı bir kural tablosu + RPC'ler kurar. Desteklenen metrikler
-- kasıtlı olarak yalnızca gerçekten hesaplanabilenlerle sınırlı (analytics_events /
-- edge_rate_limit_events dışında bir metrik yok — hata oranı/gecikme gibi kavramlar
-- için hiçbir instrumentation olmadığından eklenmedi).

CREATE TABLE public.admin_alert_rules (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name          text NOT NULL CHECK (char_length(btrim(name)) BETWEEN 1 AND 80),
  metric        text NOT NULL CHECK (metric IN ('event_rate_1h', 'rate_limit_events_1h', 'active_users_24h')),
  threshold     integer NOT NULL CHECK (threshold >= 0),
  severity      text NOT NULL DEFAULT 'warning' CHECK (severity IN ('info', 'warning', 'critical')),
  enabled       boolean NOT NULL DEFAULT true,
  notify_email  boolean NOT NULL DEFAULT false,
  notify_slack  boolean NOT NULL DEFAULT false,
  created_at    timestamptz NOT NULL DEFAULT now(),
  updated_at    timestamptz NOT NULL DEFAULT now(),
  updated_by    uuid REFERENCES auth.users(id) ON DELETE SET NULL
);

ALTER TABLE public.admin_alert_rules ENABLE ROW LEVEL SECURITY;

CREATE POLICY "admin_alert_rules_admin_select"
  ON public.admin_alert_rules
  FOR SELECT
  TO authenticated
  USING (public.is_admin());

GRANT SELECT ON public.admin_alert_rules TO authenticated;

CREATE OR REPLACE FUNCTION private.tg_admin_alert_rules_set_updated_at()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = public
AS $$
BEGIN
  NEW.updated_at := now();
  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_admin_alert_rules_set_updated_at
  BEFORE UPDATE ON public.admin_alert_rules
  FOR EACH ROW
  EXECUTE FUNCTION private.tg_admin_alert_rules_set_updated_at();

-- ── RPC'ler ──────────────────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION public.admin_upsert_alert_rule_v1(
  p_id           uuid,
  p_name         text,
  p_metric       text,
  p_threshold    integer,
  p_severity     text,
  p_enabled      boolean,
  p_notify_email boolean,
  p_notify_slack boolean
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_id uuid;
BEGIN
  IF NOT public.has_permission_v1('page:gozlemlenebilirlik') THEN
    RAISE EXCEPTION 'unauthorized: Gözlemlenebilirlik izniniz yok' USING ERRCODE = 'P0002';
  END IF;

  IF btrim(coalesce(p_name, '')) = '' THEN
    RAISE EXCEPTION 'validation_error: Kural adı zorunlu' USING ERRCODE = 'P0003';
  END IF;

  IF p_id IS NULL THEN
    INSERT INTO public.admin_alert_rules (name, metric, threshold, severity, enabled, notify_email, notify_slack, updated_by)
    VALUES (btrim(p_name), p_metric, p_threshold, p_severity, p_enabled, p_notify_email, p_notify_slack, auth.uid())
    RETURNING id INTO v_id;
  ELSE
    UPDATE public.admin_alert_rules
    SET name = btrim(p_name), metric = p_metric, threshold = p_threshold, severity = p_severity,
        enabled = p_enabled, notify_email = p_notify_email, notify_slack = p_notify_slack, updated_by = auth.uid()
    WHERE id = p_id
    RETURNING id INTO v_id;

    IF v_id IS NULL THEN
      RAISE EXCEPTION 'not_found: Kural bulunamadı' USING ERRCODE = 'P0001';
    END IF;
  END IF;

  RETURN v_id;
END;
$$;

REVOKE ALL ON FUNCTION public.admin_upsert_alert_rule_v1(uuid, text, text, integer, text, boolean, boolean, boolean) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.admin_upsert_alert_rule_v1(uuid, text, text, integer, text, boolean, boolean, boolean) TO authenticated;
COMMENT ON FUNCTION public.admin_upsert_alert_rule_v1 IS 'Uyarı kuralı oluşturur/günceller (p_id null ise oluşturur). page:gozlemlenebilirlik izni gerektirir. Called by: app/sunucu/yonetici/gozlemlenebilirlik/route.ts (POST).';


CREATE OR REPLACE FUNCTION public.admin_delete_alert_rule_v1(p_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NOT public.has_permission_v1('page:gozlemlenebilirlik') THEN
    RAISE EXCEPTION 'unauthorized: Gözlemlenebilirlik izniniz yok' USING ERRCODE = 'P0002';
  END IF;

  DELETE FROM public.admin_alert_rules WHERE id = p_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'not_found: Kural bulunamadı' USING ERRCODE = 'P0001';
  END IF;
END;
$$;

REVOKE ALL ON FUNCTION public.admin_delete_alert_rule_v1(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.admin_delete_alert_rule_v1(uuid) TO authenticated;
COMMENT ON FUNCTION public.admin_delete_alert_rule_v1 IS 'Uyarı kuralını siler. page:gozlemlenebilirlik izni gerektirir. Called by: app/sunucu/yonetici/gozlemlenebilirlik/route.ts (DELETE).';
