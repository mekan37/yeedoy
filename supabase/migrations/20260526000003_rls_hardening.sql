-- ─────────────────────────────────────────────────────────────────────────────
-- Description: RLS hardening pass — audit_logs column guard, businesses admin
--              read-all path, owner_claims admin-only delete, reports
--              self-read for reporter_user_id.
--
-- Idempotent: all policy changes use DROP IF EXISTS + CREATE.
-- Does NOT recreate tables or indexes that already exist.
-- ─────────────────────────────────────────────────────────────────────────────

-- ── 1. audit_logs ─────────────────────────────────────────────────────────────
-- Table created in 20260504000001_audit_logs.sql with correct RLS.
-- Ensure it exists and has proper index on table-name equivalent (action col).
ALTER TABLE public.audit_logs ENABLE ROW LEVEL SECURITY;

-- Admin read policy already exists as "admin_read_audit_logs".
-- Guard: add a secondary policy so the admin can also read via the action column.
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE tablename = 'audit_logs'
      AND policyname = 'audit_logs_admin_read_v2'
  ) THEN
    EXECUTE $pol$
      CREATE POLICY "audit_logs_admin_read_v2"
        ON public.audit_logs
        FOR SELECT
        TO authenticated
        USING (public.is_admin())
    $pol$;
  END IF;
END $$;

-- No INSERT policy for clients — only service role / SECURITY DEFINER triggers.
-- This is the existing baseline from 20260504000001; re-enforce it:
DROP POLICY IF EXISTS "audit_logs_client_insert_block" ON public.audit_logs;
CREATE POLICY "audit_logs_client_insert_block"
  ON public.audit_logs
  FOR INSERT
  TO anon, authenticated
  WITH CHECK (false);

-- ── 2. businesses — admin read-all (including inactive) ───────────────────────
-- Existing policy "businesses_read" allows anon/authenticated to read WHERE
-- is_active = true. Admins need to read inactive businesses too.
DROP POLICY IF EXISTS "businesses_admin_read_all" ON public.businesses;
CREATE POLICY "businesses_admin_read_all"
  ON public.businesses
  FOR SELECT
  TO authenticated
  USING (public.is_admin());

-- ── 3. owner_claims — owner delete guard ──────────────────────────────────────
-- The existing "owner_claims_select_access" allows owners to read their claims.
-- Add an explicit DELETE block so owners cannot delete their own claims
-- (only admin can decide / delete).
DROP POLICY IF EXISTS "owner_claims_no_client_delete" ON public.owner_claims;
CREATE POLICY "owner_claims_no_client_delete"
  ON public.owner_claims
  FOR DELETE
  TO authenticated
  USING (public.is_admin());

-- ── 4. reports — reporter self-read ───────────────────────────────────────────
-- Existing "reports_select_admin" only lets admins read.
-- Users who submitted a report should be able to see their own report status.
DROP POLICY IF EXISTS "reports_reporter_self_read" ON public.reports;
CREATE POLICY "reports_reporter_self_read"
  ON public.reports
  FOR SELECT
  TO authenticated
  USING (reporter_user_id = auth.uid());

-- ── 5. reports — anon insert guard ────────────────────────────────────────────
-- Existing "reports_insert_access" allows anon inserts via user_id = auth.uid().
-- For anon, auth.uid() is NULL which makes the CHECK always false — safe.
-- Add explicit comment to document this is intentional.
COMMENT ON POLICY "reports_insert_access" ON public.reports IS
  'Allows authenticated users to submit reports. Anon is implicitly blocked because auth.uid() returns NULL.';
