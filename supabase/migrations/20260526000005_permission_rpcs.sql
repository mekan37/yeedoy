-- ─────────────────────────────────────────────────────────────────────────────
-- Description: Owner and admin permission helper RPCs.
--   1. check_owner_permission_v1 — check if caller owns a business
--   2. log_admin_bulk_operation_v1 — write bulk-operation audit entry
--
-- Both use SECURITY DEFINER + fixed search_path.
-- is_admin() uses admin_users table (existing pattern in this codebase).
-- is_owner_of_business() delegates to has_business_permission_v1 (existing).
-- ─────────────────────────────────────────────────────────────────────────────

-- ── 1. check_owner_permission_v1 ─────────────────────────────────────────────
-- Returns true if the caller has owner/admin access to p_business_id.
-- p_required_action is informational; the underlying permission model
-- uses has_business_permission_v1 which maps 'menu_write' to owner-level.
CREATE OR REPLACE FUNCTION public.check_owner_permission_v1(
  p_business_id    uuid,
  p_required_action text DEFAULT 'read'
)
RETURNS boolean
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- Admins always have access
  IF public.is_admin() THEN
    RETURN true;
  END IF;

  -- For write-level actions, require menu_write permission (owner or manager)
  IF p_required_action IN ('write', 'update', 'delete', 'manage') THEN
    RETURN public.has_business_permission_v1(p_business_id, 'menu_write');
  END IF;

  -- For read-level actions, allow any team member
  RETURN public.has_business_permission_v1(p_business_id, 'business_read');
END;
$$;

REVOKE ALL ON FUNCTION public.check_owner_permission_v1(uuid, text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.check_owner_permission_v1(uuid, text) TO authenticated;

COMMENT ON FUNCTION public.check_owner_permission_v1 IS
  'Returns true if the caller has owner/admin access to the given business. '
  'Delegates to has_business_permission_v1 (existing RBAC system). '
  'p_required_action: read (default) | write | update | delete | manage.';


-- ── 2. log_admin_bulk_operation_v1 ───────────────────────────────────────────
-- Writes a bulk operation record to audit_logs. Admin-only.
-- Uses the existing audit_logs schema (action, resource_type, new_data, user_id).
CREATE OR REPLACE FUNCTION public.log_admin_bulk_operation_v1(
  p_operation_type text,
  p_affected_ids   uuid[],
  p_metadata       jsonb DEFAULT '{}'
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- Admin-only guard
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'unauthorized: Admin yetkisi gereklidir'
      USING ERRCODE = 'P0002';
  END IF;

  INSERT INTO public.audit_logs (
    action,
    resource_type,
    new_data,
    user_id
  ) VALUES (
    'admin.bulk_operation.' || p_operation_type,
    'bulk_operation',
    jsonb_build_object(
      'operation_type',  p_operation_type,
      'affected_count',  COALESCE(array_length(p_affected_ids, 1), 0),
      'affected_ids',    to_jsonb(p_affected_ids),
      'metadata',        p_metadata
    ),
    auth.uid()
  );
END;
$$;

REVOKE ALL ON FUNCTION public.log_admin_bulk_operation_v1(text, uuid[], jsonb) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.log_admin_bulk_operation_v1(text, uuid[], jsonb) TO authenticated;

COMMENT ON FUNCTION public.log_admin_bulk_operation_v1 IS
  'Writes a bulk admin operation record to audit_logs. '
  'Admin-only: raises P0002 if caller is not in admin_users. '
  'Use from admin panel after bulk claim decisions, mass status changes, etc.';
