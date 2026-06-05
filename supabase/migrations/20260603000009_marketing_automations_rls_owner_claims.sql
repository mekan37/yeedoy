-- Migration: fix marketing automations RLS ownership
--
-- Problem: 20260518000001_business_automations.sql created a policy
-- "owner_manage_automations" that references public.business_owners, a table
-- that does not exist in production. The policy is therefore permanently broken
-- (evaluated as always-false or causes a runtime error depending on PG version).
--
-- Fix: drop the broken policy and replace it with the canonical
-- is_admin() OR is_owner_of_business() pattern used across loyalty_programs,
-- owner_claims, and other owner-scoped tables in this schema.
--
-- Note: 20260424000010_loyalty_automations.sql already created the table with
-- a business_claims-based policy "owner_manage_automations". Because the later
-- migration (20260518000001) used CREATE TABLE IF NOT EXISTS the table itself
-- was unchanged, but it added a second duplicate-named policy via CREATE POLICY
-- (no IF NOT EXISTS guard) which will fail on a fresh db reset if the earlier
-- policy already exists. This migration uses DROP POLICY IF EXISTS to safely
-- remove whichever variant is present, then installs the correct policy once.

-- Step 1: Remove broken / legacy policy regardless of which migration created it
DROP POLICY IF EXISTS "owner_manage_automations" ON public.business_automations;

-- Step 2: Ensure RLS is enabled (idempotent — already set in original migration)
ALTER TABLE public.business_automations ENABLE ROW LEVEL SECURITY;

-- Step 3: Install correct owner + admin policy
--   is_owner_of_business() — SECURITY DEFINER, delegates to
--     has_business_permission_v1(business_id, 'menu_write'); handles approved
--     claims internally. Same pattern as loyalty_programs, business_menus, etc.
--   is_admin() — superadmin / community-mod bypass for support operations.
CREATE POLICY "automations_owner_or_admin_v1"
  ON public.business_automations
  FOR ALL
  TO authenticated
  USING  (public.is_admin() OR public.is_owner_of_business(business_id))
  WITH CHECK (public.is_admin() OR public.is_owner_of_business(business_id));
