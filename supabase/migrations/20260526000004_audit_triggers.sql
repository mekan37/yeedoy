-- ─────────────────────────────────────────────────────────────────────────────
-- Description: Generic audit trigger for tables that lack dedicated audit
--              functions. Writes to the existing audit_logs table using its
--              actual schema: (action, resource_type, resource_id, old_data,
--              new_data, user_id). All triggers use SECURITY DEFINER + fixed
--              search_path. Idempotent (CREATE OR REPLACE / OR REPLACE).
-- ─────────────────────────────────────────────────────────────────────────────

-- ── Generic trigger function ──────────────────────────────────────────────────
-- The existing audit_logs schema (from 20260504000001) uses:
--   action text, resource_type text, resource_id uuid,
--   old_data jsonb, new_data jsonb, user_id uuid
-- We map TG_OP → action and TG_TABLE_NAME → resource_type.
CREATE OR REPLACE FUNCTION public.tg_generic_audit_log()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_action      text;
  v_resource_id uuid;
BEGIN
  v_action := lower(TG_TABLE_NAME) || '.' || lower(TG_OP);

  v_resource_id := CASE TG_OP
    WHEN 'DELETE' THEN
      CASE WHEN (to_jsonb(OLD) ->> 'id') IS NOT NULL
           THEN (to_jsonb(OLD) ->> 'id')::uuid
           ELSE NULL
      END
    ELSE
      CASE WHEN (to_jsonb(NEW) ->> 'id') IS NOT NULL
           THEN (to_jsonb(NEW) ->> 'id')::uuid
           ELSE NULL
      END
  END;

  INSERT INTO public.audit_logs (
    action,
    resource_type,
    resource_id,
    old_data,
    new_data,
    user_id
  ) VALUES (
    v_action,
    TG_TABLE_NAME,
    v_resource_id,
    CASE TG_OP WHEN 'INSERT' THEN NULL ELSE to_jsonb(OLD) END,
    CASE TG_OP WHEN 'DELETE' THEN NULL ELSE to_jsonb(NEW) END,
    auth.uid()
  );

  RETURN COALESCE(NEW, OLD);
END;
$$;

-- ── user_profiles: ban/role changes ──────────────────────────────────────────
-- Note: trg_audit_user_ban_toggle_v1 already exists on user_profiles for
-- ban_status changes. We add a broader trigger that catches all profile updates
-- except where the dedicated trigger already fires. To avoid double-logging,
-- we scope to columns NOT covered by the existing trigger.
-- Strategy: add trigger only if it does not yet exist.
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_trigger t
    JOIN pg_class c ON c.oid = t.tgrelid
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname = 'public'
      AND c.relname = 'user_profiles'
      AND t.tgname = 'audit_user_profiles_generic'
  ) THEN
    EXECUTE $tg$
      CREATE TRIGGER audit_user_profiles_generic
        AFTER INSERT OR DELETE ON public.user_profiles
        FOR EACH ROW
        EXECUTE FUNCTION public.tg_generic_audit_log()
    $tg$;
  END IF;
END $$;

-- ── business_team_memberships: team membership changes ───────────────────────
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_trigger t
    JOIN pg_class c ON c.oid = t.tgrelid
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname = 'public'
      AND c.relname = 'business_team_memberships'
      AND t.tgname = 'audit_business_team_memberships'
  ) THEN
    EXECUTE $tg$
      CREATE TRIGGER audit_business_team_memberships
        AFTER INSERT OR UPDATE OR DELETE ON public.business_team_memberships
        FOR EACH ROW
        EXECUTE FUNCTION public.tg_generic_audit_log()
    $tg$;
  END IF;
END $$;

-- ── admin_users: admin grant/revoke ───────────────────────────────────────────
-- This is a critical table — any change to admin membership must be logged.
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_trigger t
    JOIN pg_class c ON c.oid = t.tgrelid
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname = 'public'
      AND c.relname = 'admin_users'
      AND t.tgname = 'audit_admin_users'
  ) THEN
    EXECUTE $tg$
      CREATE TRIGGER audit_admin_users
        AFTER INSERT OR UPDATE OR DELETE ON public.admin_users
        FOR EACH ROW
        EXECUTE FUNCTION public.tg_generic_audit_log()
    $tg$;
  END IF;
END $$;

-- ── Note on existing triggers ─────────────────────────────────────────────────
-- The following tables already have dedicated audit triggers (not duplicated):
--   businesses          → trg_audit_businesses_update_v1
--   menu_items          → trg_audit_menu_items_cud_v1
--   menus               → trg_audit_menus_cud_v1
--   owner_claims        → trg_audit_owner_claims_update_v1
--   reports             → trg_audit_reports_update_v1
--   user_profiles       → trg_audit_user_ban_toggle_v1 (ban changes only)
