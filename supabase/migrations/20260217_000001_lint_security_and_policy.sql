-- Fix security definer views, enable RLS on public tables without it,
-- set search_path on flagged functions, deduplicate policies,
-- and move extensions out of public schema.

-- Views: make them security invoker
DO $$
BEGIN
  IF to_regclass('public.admin_business_suggestions_queue_v1') IS NOT NULL THEN
    EXECUTE 'ALTER VIEW public.admin_business_suggestions_queue_v1 SET (security_invoker = true)';
  END IF;
  IF to_regclass('public.admin_owner_claims_queue_v1') IS NOT NULL THEN
    EXECUTE 'ALTER VIEW public.admin_owner_claims_queue_v1 SET (security_invoker = true)';
  END IF;
  IF to_regclass('public.admin_reports_queue_v1') IS NOT NULL THEN
    EXECUTE 'ALTER VIEW public.admin_reports_queue_v1 SET (security_invoker = true)';
  END IF;
  IF to_regclass('public.admin_suggestions_v1') IS NOT NULL THEN
    EXECUTE 'ALTER VIEW public.admin_suggestions_v1 SET (security_invoker = true)';
  END IF;
  IF to_regclass('public.business_price_index_v1') IS NOT NULL THEN
    EXECUTE 'ALTER VIEW public.business_price_index_v1 SET (security_invoker = true)';
  END IF;
  IF to_regclass('public.businesses_with_stats') IS NOT NULL THEN
    EXECUTE 'ALTER VIEW public.businesses_with_stats SET (security_invoker = true)';
  END IF;
  IF to_regclass('public.businesses_with_stats_mv') IS NOT NULL THEN
    EXECUTE 'ALTER VIEW public.businesses_with_stats_mv SET (security_invoker = true)';
  END IF;
  IF to_regclass('public.menu_item_price_status_v1') IS NOT NULL THEN
    EXECUTE 'ALTER VIEW public.menu_item_price_status_v1 SET (security_invoker = true)';
  END IF;
  IF to_regclass('public.user_business_signals_v1') IS NOT NULL THEN
    EXECUTE 'ALTER VIEW public.user_business_signals_v1 SET (security_invoker = true)';
  END IF;
  IF to_regclass('public.user_favorites') IS NOT NULL THEN
    EXECUTE 'ALTER VIEW public.user_favorites SET (security_invoker = true)';
  END IF;
END $$;
-- Enable RLS on public tables flagged by linter (spatial_ref_sys excluded due to ownership)
DO $$
BEGIN
  IF to_regclass('public.import_places_stage') IS NOT NULL THEN
    EXECUTE 'ALTER TABLE public.import_places_stage ENABLE ROW LEVEL SECURITY';
  END IF;
  IF to_regclass('public.business_stats') IS NOT NULL THEN
    EXECUTE 'ALTER TABLE public.business_stats ENABLE ROW LEVEL SECURITY';
  END IF;
  IF to_regclass('public.business_media') IS NOT NULL THEN
    EXECUTE 'ALTER TABLE public.business_media ENABLE ROW LEVEL SECURITY';
  END IF;
  IF to_regclass('public.business_follows') IS NOT NULL THEN
    EXECUTE 'ALTER TABLE public.business_follows ENABLE ROW LEVEL SECURITY';
  END IF;
  IF to_regclass('public.feed_events') IS NOT NULL THEN
    EXECUTE 'ALTER TABLE public.feed_events ENABLE ROW LEVEL SECURITY';
  END IF;
  IF to_regclass('public.user_rate_limits') IS NOT NULL THEN
    EXECUTE 'ALTER TABLE public.user_rate_limits ENABLE ROW LEVEL SECURITY';
  END IF;
  IF to_regclass('public.business_presence_events') IS NOT NULL THEN
    EXECUTE 'ALTER TABLE public.business_presence_events ENABLE ROW LEVEL SECURITY';
  END IF;
END $$;
-- RLS policies for newly protected tables
DO $$
BEGIN
  IF to_regclass('public.import_places_stage') IS NOT NULL AND NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE schemaname='public' AND tablename='import_places_stage' AND policyname='import_places_stage_admin_all'
  ) THEN
    EXECUTE 'CREATE POLICY import_places_stage_admin_all ON public.import_places_stage
      USING (public.is_admin()) WITH CHECK (public.is_admin())';
  END IF;

  IF to_regclass('public.business_stats') IS NOT NULL AND NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE schemaname='public' AND tablename='business_stats' AND policyname='business_stats_read_all'
  ) THEN
    EXECUTE 'CREATE POLICY business_stats_read_all ON public.business_stats FOR SELECT USING (true)';
  END IF;

  IF to_regclass('public.business_media') IS NOT NULL AND NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE schemaname='public' AND tablename='business_media' AND policyname='business_media_read_all'
  ) THEN
    EXECUTE 'CREATE POLICY business_media_read_all ON public.business_media FOR SELECT USING (true)';
  END IF;

  IF to_regclass('public.business_follows') IS NOT NULL THEN
    IF NOT EXISTS (
      SELECT 1 FROM pg_policies WHERE schemaname='public' AND tablename='business_follows' AND policyname='business_follows_select_own'
    ) THEN
      EXECUTE 'CREATE POLICY business_follows_select_own ON public.business_follows FOR SELECT TO authenticated
        USING (user_id = (select auth.uid()))';
    END IF;
    IF NOT EXISTS (
      SELECT 1 FROM pg_policies WHERE schemaname='public' AND tablename='business_follows' AND policyname='business_follows_insert_own'
    ) THEN
      EXECUTE 'CREATE POLICY business_follows_insert_own ON public.business_follows FOR INSERT TO authenticated
        WITH CHECK (user_id = (select auth.uid()))';
    END IF;
    IF NOT EXISTS (
      SELECT 1 FROM pg_policies WHERE schemaname='public' AND tablename='business_follows' AND policyname='business_follows_delete_own'
    ) THEN
      EXECUTE 'CREATE POLICY business_follows_delete_own ON public.business_follows FOR DELETE TO authenticated
        USING (user_id = (select auth.uid()))';
    END IF;
  END IF;

  IF to_regclass('public.feed_events') IS NOT NULL AND NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE schemaname='public' AND tablename='feed_events' AND policyname='feed_events_admin_select'
  ) THEN
    EXECUTE 'CREATE POLICY feed_events_admin_select ON public.feed_events FOR SELECT
      USING (public.is_admin())';
  END IF;

  IF to_regclass('public.user_rate_limits') IS NOT NULL AND NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE schemaname='public' AND tablename='user_rate_limits' AND policyname='user_rate_limits_admin_all'
  ) THEN
    EXECUTE 'CREATE POLICY user_rate_limits_admin_all ON public.user_rate_limits
      USING (public.is_admin()) WITH CHECK (public.is_admin())';
  END IF;

  IF to_regclass('public.business_presence_events') IS NOT NULL AND NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE schemaname='public' AND tablename='business_presence_events' AND policyname='business_presence_admin_select'
  ) THEN
    EXECUTE 'CREATE POLICY business_presence_admin_select ON public.business_presence_events FOR SELECT
      USING (public.is_admin())';
  END IF;
END $$;
-- Fix function search_path warnings
ALTER FUNCTION public.recalc_review_helpful_count() SET search_path = public;
ALTER FUNCTION public.normalize_tr_text(text) SET search_path = public;
-- Deduplicate permissive policies
DROP POLICY IF EXISTS admin_users_no_select ON public.admin_users;
DROP POLICY IF EXISTS business_amenities_write_owner_admin ON public.business_amenities;
CREATE POLICY business_amenities_admin_insert ON public.business_amenities
  FOR INSERT TO authenticated
  WITH CHECK (public.is_admin());
CREATE POLICY business_amenities_admin_update ON public.business_amenities
  FOR UPDATE TO authenticated
  USING (public.is_admin()) WITH CHECK (public.is_admin());
CREATE POLICY business_amenities_admin_delete ON public.business_amenities
  FOR DELETE TO authenticated
  USING (public.is_admin());
DROP POLICY IF EXISTS business_amenity_map_write_owner_admin ON public.business_amenity_map;
CREATE POLICY business_amenity_map_owner_insert ON public.business_amenity_map
  FOR INSERT TO authenticated
  WITH CHECK (public.is_admin() OR public.is_owner_of_business(business_id));
CREATE POLICY business_amenity_map_owner_update ON public.business_amenity_map
  FOR UPDATE TO authenticated
  USING (public.is_admin() OR public.is_owner_of_business(business_id))
  WITH CHECK (public.is_admin() OR public.is_owner_of_business(business_id));
CREATE POLICY business_amenity_map_owner_delete ON public.business_amenity_map
  FOR DELETE TO authenticated
  USING (public.is_admin() OR public.is_owner_of_business(business_id));
DROP POLICY IF EXISTS business_hours_owner_read ON public.business_hours;
DROP POLICY IF EXISTS stories_write_owner_admin ON public.business_stories;
CREATE POLICY stories_owner_admin_insert ON public.business_stories
  FOR INSERT TO authenticated
  WITH CHECK (public.is_admin() OR public.is_owner_of_business(business_id));
CREATE POLICY stories_owner_admin_update ON public.business_stories
  FOR UPDATE TO authenticated
  USING (public.is_admin() OR public.is_owner_of_business(business_id))
  WITH CHECK (public.is_admin() OR public.is_owner_of_business(business_id));
CREATE POLICY stories_owner_admin_delete ON public.business_stories
  FOR DELETE TO authenticated
  USING (public.is_admin() OR public.is_owner_of_business(business_id));
DROP POLICY IF EXISTS businesses_select_public ON public.businesses;
DROP POLICY IF EXISTS collection_items_owner_select ON public.collection_items;
DROP POLICY IF EXISTS collection_items_public_select ON public.collection_items;
CREATE POLICY collection_items_select_access ON public.collection_items
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.collections c
      WHERE c.id = collection_items.collection_id
        AND (c.user_id = (select auth.uid()) OR c.is_public = true)
    )
  );
DROP POLICY IF EXISTS collections_owner_select ON public.collections;
DROP POLICY IF EXISTS collections_public_select ON public.collections;
CREATE POLICY collections_select_access ON public.collections
  FOR SELECT
  USING ((user_id = (select auth.uid())) OR (is_public = true));
DROP POLICY IF EXISTS price_hist_admin_write ON public.menu_item_price_history;
CREATE POLICY price_hist_admin_insert ON public.menu_item_price_history
  FOR INSERT TO authenticated
  WITH CHECK (public.is_admin());
CREATE POLICY price_hist_admin_update ON public.menu_item_price_history
  FOR UPDATE TO authenticated
  USING (public.is_admin()) WITH CHECK (public.is_admin());
CREATE POLICY price_hist_admin_delete ON public.menu_item_price_history
  FOR DELETE TO authenticated
  USING (public.is_admin());
DROP POLICY IF EXISTS price_sugg_admin_all ON public.menu_item_price_suggestions;
DROP POLICY IF EXISTS price_sugg_owner_read ON public.menu_item_price_suggestions;
DROP POLICY IF EXISTS price_sugg_read_own ON public.menu_item_price_suggestions;
DROP POLICY IF EXISTS price_sugg_insert_auth ON public.menu_item_price_suggestions;
CREATE POLICY price_sugg_select_access ON public.menu_item_price_suggestions
  FOR SELECT
  USING (
    public.is_admin()
    OR public.is_owner_of_business(business_id)
    OR created_by = (select auth.uid())
  );
CREATE POLICY price_sugg_insert_auth ON public.menu_item_price_suggestions
  FOR INSERT TO authenticated
  WITH CHECK (public.is_admin() OR created_by = (select auth.uid()));
CREATE POLICY price_sugg_update_admin ON public.menu_item_price_suggestions
  FOR UPDATE TO authenticated
  USING (public.is_admin()) WITH CHECK (public.is_admin());
CREATE POLICY price_sugg_delete_admin ON public.menu_item_price_suggestions
  FOR DELETE TO authenticated
  USING (public.is_admin());
DROP POLICY IF EXISTS menu_items_write_owner_admin ON public.menu_items;
CREATE POLICY menu_items_owner_insert ON public.menu_items
  FOR INSERT TO authenticated
  WITH CHECK (public.is_admin() OR public.is_owner_of_business(business_id));
CREATE POLICY menu_items_owner_update ON public.menu_items
  FOR UPDATE TO authenticated
  USING (public.is_admin() OR public.is_owner_of_business(business_id))
  WITH CHECK (public.is_admin() OR public.is_owner_of_business(business_id));
CREATE POLICY menu_items_owner_delete ON public.menu_items
  FOR DELETE TO authenticated
  USING (public.is_admin() OR public.is_owner_of_business(business_id));
DROP POLICY IF EXISTS menu_sections_write ON public.menu_sections;
CREATE POLICY menu_sections_owner_insert ON public.menu_sections
  FOR INSERT TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.menus m
      WHERE m.id = menu_sections.menu_id
        AND (public.is_admin() OR public.is_owner_of_business(m.business_id))
    )
  );
CREATE POLICY menu_sections_owner_update ON public.menu_sections
  FOR UPDATE TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.menus m
      WHERE m.id = menu_sections.menu_id
        AND (public.is_admin() OR public.is_owner_of_business(m.business_id))
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.menus m
      WHERE m.id = menu_sections.menu_id
        AND (public.is_admin() OR public.is_owner_of_business(m.business_id))
    )
  );
CREATE POLICY menu_sections_owner_delete ON public.menu_sections
  FOR DELETE TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.menus m
      WHERE m.id = menu_sections.menu_id
        AND (public.is_admin() OR public.is_owner_of_business(m.business_id))
    )
  );
DROP POLICY IF EXISTS menus_write_owner_admin ON public.menus;
CREATE POLICY menus_owner_insert ON public.menus
  FOR INSERT TO authenticated
  WITH CHECK (public.is_admin() OR public.is_owner_of_business(business_id));
CREATE POLICY menus_owner_update ON public.menus
  FOR UPDATE TO authenticated
  USING (public.is_admin() OR public.is_owner_of_business(business_id))
  WITH CHECK (public.is_admin() OR public.is_owner_of_business(business_id));
CREATE POLICY menus_owner_delete ON public.menus
  FOR DELETE TO authenticated
  USING (public.is_admin() OR public.is_owner_of_business(business_id));
DROP POLICY IF EXISTS reviews_read ON public.reviews;
DROP POLICY IF EXISTS reviews_select_public_approved ON public.reviews;
CREATE POLICY reviews_select_access ON public.reviews
  FOR SELECT
  USING (
    status = 'approved'::text
    OR user_id = (select auth.uid())
    OR public.is_admin()
  );
DROP POLICY IF EXISTS reviews_insert_authenticated ON public.reviews;
DROP POLICY IF EXISTS votes_select_own ON public.review_votes;
DROP POLICY IF EXISTS votes_insert_own ON public.review_votes;
DROP POLICY IF EXISTS votes_delete_own ON public.review_votes;
DROP POLICY IF EXISTS fav_select_own ON public.favorites;
DROP POLICY IF EXISTS fav_insert_own ON public.favorites;
DROP POLICY IF EXISTS fav_delete_own ON public.favorites;
DROP POLICY IF EXISTS owner_claim_select_own ON public.owner_claims;
DROP POLICY IF EXISTS owner_claims_select_admin ON public.owner_claims;
DROP POLICY IF EXISTS owner_claims_select_own ON public.owner_claims;
DROP POLICY IF EXISTS owner_claims_select_owner_or_admin ON public.owner_claims;
DROP POLICY IF EXISTS owner_claim_insert ON public.owner_claims;
DROP POLICY IF EXISTS owner_claims_insert_authenticated ON public.owner_claims;
DROP POLICY IF EXISTS owner_claims_insert_own ON public.owner_claims;
CREATE POLICY owner_claims_select_access ON public.owner_claims
  FOR SELECT TO authenticated
  USING ((user_id = (select auth.uid())) OR public.is_admin());
CREATE POLICY owner_claims_insert_access ON public.owner_claims
  FOR INSERT TO authenticated
  WITH CHECK (user_id = (select auth.uid()));
DROP POLICY IF EXISTS sponsorship_leads_admin_all ON public.sponsorship_leads;
DROP POLICY IF EXISTS sponsorship_leads_owner_read ON public.sponsorship_leads;
DROP POLICY IF EXISTS sponsorship_leads_owner_insert ON public.sponsorship_leads;
CREATE POLICY sponsorship_leads_select_access ON public.sponsorship_leads
  FOR SELECT
  USING (public.is_admin() OR owner_user_id = (select auth.uid()));
CREATE POLICY sponsorship_leads_insert_access ON public.sponsorship_leads
  FOR INSERT TO authenticated
  WITH CHECK (public.is_admin() OR owner_user_id = (select auth.uid()));
CREATE POLICY sponsorship_leads_update_admin ON public.sponsorship_leads
  FOR UPDATE TO authenticated
  USING (public.is_admin()) WITH CHECK (public.is_admin());
CREATE POLICY sponsorship_leads_delete_admin ON public.sponsorship_leads
  FOR DELETE TO authenticated
  USING (public.is_admin());
DROP POLICY IF EXISTS claims_admin_all ON public.suspended_meal_claims;
DROP POLICY IF EXISTS claims_owner_read ON public.suspended_meal_claims;
DROP POLICY IF EXISTS claims_read_own ON public.suspended_meal_claims;
DROP POLICY IF EXISTS claims_owner_update ON public.suspended_meal_claims;
CREATE POLICY claims_select_access ON public.suspended_meal_claims
  FOR SELECT
  USING (
    public.is_admin()
    OR claimant_user_id = (select auth.uid())
    OR public.is_owner_of_business((
      SELECT m.business_id FROM public.suspended_meals m
      WHERE m.id = suspended_meal_claims.suspended_meal_id
    ))
  );
CREATE POLICY claims_update_owner_admin ON public.suspended_meal_claims
  FOR UPDATE TO authenticated
  USING (
    public.is_admin()
    OR public.is_owner_of_business((
      SELECT m.business_id FROM public.suspended_meals m
      WHERE m.id = suspended_meal_claims.suspended_meal_id
    ))
  )
  WITH CHECK (
    public.is_admin()
    OR public.is_owner_of_business((
      SELECT m.business_id FROM public.suspended_meals m
      WHERE m.id = suspended_meal_claims.suspended_meal_id
    ))
  );
DROP POLICY IF EXISTS meals_admin_all ON public.suspended_meals;
DROP POLICY IF EXISTS meals_read_active ON public.suspended_meals;
DROP POLICY IF EXISTS meals_read_own ON public.suspended_meals;
CREATE POLICY meals_select_access ON public.suspended_meals
  FOR SELECT
  USING (
    public.is_admin()
    OR donor_user_id = (select auth.uid())
    OR (status = 'active'::public.suspended_meal_status AND expires_at > now())
  );
CREATE POLICY meals_admin_insert ON public.suspended_meals
  FOR INSERT TO authenticated
  WITH CHECK (public.is_admin());
CREATE POLICY meals_admin_update ON public.suspended_meals
  FOR UPDATE TO authenticated
  USING (public.is_admin()) WITH CHECK (public.is_admin());
CREATE POLICY meals_admin_delete ON public.suspended_meals
  FOR DELETE TO authenticated
  USING (public.is_admin());
DROP POLICY IF EXISTS profiles_write_own ON public.user_profiles;
CREATE POLICY profiles_insert_own ON public.user_profiles
  FOR INSERT TO authenticated
  WITH CHECK (user_id = (select auth.uid()));
CREATE POLICY profiles_update_own ON public.user_profiles
  FOR UPDATE TO authenticated
  USING (user_id = (select auth.uid())) WITH CHECK (user_id = (select auth.uid()));
CREATE POLICY profiles_delete_own ON public.user_profiles
  FOR DELETE TO authenticated
  USING (user_id = (select auth.uid()));
DROP POLICY IF EXISTS suggestions_insert_any ON public.business_suggestions;
DROP POLICY IF EXISTS business_suggestions_insert_authenticated ON public.business_suggestions;
DROP POLICY IF EXISTS business_suggestions_insert_own ON public.business_suggestions;
DROP POLICY IF EXISTS business_suggestions_select_admin ON public.business_suggestions;
DROP POLICY IF EXISTS business_suggestions_select_own ON public.business_suggestions;
DROP POLICY IF EXISTS business_suggestions_select_own_or_admin ON public.business_suggestions;
DROP POLICY IF EXISTS suggestions_select_own ON public.business_suggestions;
CREATE POLICY business_suggestions_select_access ON public.business_suggestions
  FOR SELECT TO authenticated
  USING (public.is_admin() OR user_id = (select auth.uid()));
CREATE POLICY business_suggestions_insert_access ON public.business_suggestions
  FOR INSERT TO authenticated
  WITH CHECK (user_id = (select auth.uid()));
DROP POLICY IF EXISTS reports_insert ON public.reports;
DROP POLICY IF EXISTS reports_insert_authenticated ON public.reports;
DROP POLICY IF EXISTS reports_insert_user ON public.reports;
CREATE POLICY reports_insert_access ON public.reports
  FOR INSERT TO authenticated
  WITH CHECK (
    user_id = (select auth.uid())
    OR reporter_user_id = (select auth.uid())
  );
-- Move extensions out of public schema
CREATE SCHEMA IF NOT EXISTS extensions;
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'pg_trgm') THEN
    EXECUTE 'ALTER EXTENSION pg_trgm SET SCHEMA extensions';
  END IF;
END $$;
ALTER DATABASE postgres SET search_path = public, extensions;
