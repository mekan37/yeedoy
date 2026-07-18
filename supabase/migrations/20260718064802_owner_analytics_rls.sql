-- Owner-scoped SELECT access for the owner analytics page.
--
-- The owner analytics page (uygulamalar/web/app/owner/(panel)/analytics/page.tsx)
-- reads public.analytics_events and public.favorites directly from the
-- client-session Supabase client (anon key + user cookies). Neither table had
-- a policy letting a business owner read rows for their own business:
--   - analytics_events only had "analytics_events_admin_all" (admin-only, FOR ALL).
--   - favorites only had "favorites_select_own" (user's own favorites, not a
--     business's aggregate favorite count).
-- These are additive, permissive SELECT policies (OR'd with the existing
-- ones) that do not change the existing admin/own-row access.

DROP POLICY IF EXISTS "analytics_events_owner_select" ON public.analytics_events;

CREATE POLICY "analytics_events_owner_select"
  ON public.analytics_events
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1
      FROM public.owner_claims oc
      WHERE oc.business_id = analytics_events.business_id
        AND oc.user_id = (SELECT auth.uid())
        AND oc.status = 'approved'
    )
  );

COMMENT ON POLICY "analytics_events_owner_select" ON public.analytics_events IS
  'Lets a business owner (approved owner_claims row) read analytics events for their own business; admin access via analytics_events_admin_all is unchanged.';

DROP POLICY IF EXISTS "favorites_owner_select" ON public.favorites;

CREATE POLICY "favorites_owner_select"
  ON public.favorites
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1
      FROM public.owner_claims oc
      WHERE oc.business_id = favorites.business_id
        AND oc.user_id = (SELECT auth.uid())
        AND oc.status = 'approved'
    )
  );

COMMENT ON POLICY "favorites_owner_select" ON public.favorites IS
  'Lets a business owner (approved owner_claims row) read all favorites for their own business (aggregate KPI count); favorites_select_own is unchanged.';
