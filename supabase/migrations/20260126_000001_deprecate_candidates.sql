-- Sprint-0 deprecate candidates (idempotent, no DROP)
-- Notes:
-- - All COMMENTs are guarded to avoid errors if objects are missing.
-- - Functions are commented dynamically via pg_proc to cover overloads.
-- - businesses_with_stats_mv is explicitly NOT a drop candidate.

-- VIEWS
DO $$
BEGIN
  IF to_regclass('public.admin_business_suggestions_queue_v1') IS NOT NULL THEN
    EXECUTE 'COMMENT ON VIEW public.admin_business_suggestions_queue_v1 IS ' ||
            quote_literal('DEPRECATED: sprint-0 cleanup candidate; replace with admin_list_business_suggestions_v3');
  END IF;

  IF to_regclass('public.admin_owner_claims_queue_v1') IS NOT NULL THEN
    EXECUTE 'COMMENT ON VIEW public.admin_owner_claims_queue_v1 IS ' ||
            quote_literal('DEPRECATED: sprint-0 cleanup candidate; replace with admin_list_owner_claims_v3');
  END IF;

  IF to_regclass('public.admin_reports_queue_v1') IS NOT NULL THEN
    EXECUTE 'COMMENT ON VIEW public.admin_reports_queue_v1 IS ' ||
            quote_literal('DEPRECATED: sprint-0 cleanup candidate; replace with admin_list_reports_v3');
  END IF;

  IF to_regclass('public.admin_suggestions_v1') IS NOT NULL THEN
    EXECUTE 'COMMENT ON VIEW public.admin_suggestions_v1 IS ' ||
            quote_literal('DEPRECATED: sprint-0 cleanup candidate; replace with admin_list_business_suggestions_v3');
  END IF;

  IF to_regclass('public.businesses_with_stats_mv') IS NOT NULL THEN
    EXECUTE 'COMMENT ON VIEW public.businesses_with_stats_mv IS ' ||
            quote_literal('DEPRECATED: legacy view; NOT a drop candidate; verify external usage');
  END IF;
END $$;
-- TABLES
DO $$
BEGIN
  IF to_regclass('public.user_favorites_legacy') IS NOT NULL THEN
    EXECUTE 'COMMENT ON TABLE public.user_favorites_legacy IS ' ||
            quote_literal('DEPRECATED: sprint-0 cleanup candidate; legacy favorites table');
  END IF;

  IF to_regclass('public.import_places_stage') IS NOT NULL THEN
    EXECUTE 'COMMENT ON TABLE public.import_places_stage IS ' ||
            quote_literal('DEPRECATED: sprint-0 cleanup candidate; staging/import table');
  END IF;
END $$;
-- INDEXES (duplicates only; no drop)
DO $$
DECLARE
  _exists boolean;
BEGIN
  SELECT EXISTS (
    SELECT 1 FROM pg_class c
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname='public' AND c.relname='idx_review_votes_review' AND c.relkind='i'
  ) INTO _exists;
  IF _exists THEN
    EXECUTE 'COMMENT ON INDEX public.idx_review_votes_review IS ' ||
            quote_literal('DEPRECATED: duplicate review_id index; no drop in sprint-0');
  END IF;

  SELECT EXISTS (
    SELECT 1 FROM pg_class c
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname='public' AND c.relname='review_votes_review_idx' AND c.relkind='i'
  ) INTO _exists;
  IF _exists THEN
    EXECUTE 'COMMENT ON INDEX public.review_votes_review_idx IS ' ||
            quote_literal('DEPRECATED: duplicate review_id index; no drop in sprint-0');
  END IF;

  SELECT EXISTS (
    SELECT 1 FROM pg_class c
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname='public' AND c.relname='review_votes_review_id_user_id_key' AND c.relkind='i'
  ) INTO _exists;
  IF _exists THEN
    EXECUTE 'COMMENT ON INDEX public.review_votes_review_id_user_id_key IS ' ||
            quote_literal('DEPRECATED: duplicate unique index; no drop in sprint-0');
  END IF;

  SELECT EXISTS (
    SELECT 1 FROM pg_class c
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname='public' AND c.relname='review_votes_user_review_uniq' AND c.relkind='i'
  ) INTO _exists;
  IF _exists THEN
    EXECUTE 'COMMENT ON INDEX public.review_votes_user_review_uniq IS ' ||
            quote_literal('DEPRECATED: duplicate unique index; no drop in sprint-0');
  END IF;
END $$;
-- FUNCTIONS (dynamic, all overloads)
DO $$
DECLARE
  r record;
  comment_text text;
BEGIN
  FOR r IN
    SELECT n.nspname AS schema_name,
           p.proname AS function_name,
           pg_get_function_identity_arguments(p.oid) AS args
    FROM pg_proc p
    JOIN pg_namespace n ON n.oid = p.pronamespace
    WHERE n.nspname = 'public'
      AND p.proname IN (
        'admin_list_business_suggestions_v1',
        'admin_list_owner_claims_v1',
        'admin_list_reports_v1',
        'admin_list_reports_v2',
        'search_nearby_businesses_v1',
        'search_nearby_businesses_v2',
        'get_menu_items_v1',
        'get_top_businesses',
        'taste_recommendations_from_match_v1',
        'get_taste_matches_v1',
        'approve_business_suggestion',
        'create_owner_claim',
        'approve_owner_claim',
        'reject_owner_claim',
        'refresh_businesses_with_stats_mv'
      )
  LOOP
    comment_text := CASE r.function_name
      WHEN 'admin_list_business_suggestions_v1' THEN 'DEPRECATED: use admin_list_business_suggestions_v3'
      WHEN 'admin_list_owner_claims_v1' THEN 'DEPRECATED: use admin_list_owner_claims_v3'
      WHEN 'admin_list_reports_v1' THEN 'DEPRECATED: use admin_list_reports_v3'
      WHEN 'admin_list_reports_v2' THEN 'DEPRECATED: use admin_list_reports_v3'
      WHEN 'search_nearby_businesses_v1' THEN 'DEPRECATED: use search_nearby_businesses_v3'
      WHEN 'search_nearby_businesses_v2' THEN 'DEPRECATED: use search_nearby_businesses_v3'
      WHEN 'get_menu_items_v1' THEN 'DEPRECATED: use get_menu_items_v2'
      WHEN 'get_top_businesses' THEN 'DEPRECATED: use get_top_businesses_period_v1'
      WHEN 'taste_recommendations_from_match_v1' THEN 'DEPRECATED: use taste_recommendations_from_match_v2'
      WHEN 'get_taste_matches_v1' THEN 'DEPRECATED: use get_taste_matches_hybrid_v1'
      WHEN 'approve_business_suggestion' THEN 'DEPRECATED: use admin_approve_business_suggestion_v1'
      WHEN 'create_owner_claim' THEN 'DEPRECATED: use submit_owner_claim_v1'
      WHEN 'approve_owner_claim' THEN 'DEPRECATED: use admin_decide_owner_claim_v1'
      WHEN 'reject_owner_claim' THEN 'DEPRECATED: use admin_decide_owner_claim_v1'
      WHEN 'refresh_businesses_with_stats_mv' THEN 'DEPRECATED: legacy helper; NOT a drop candidate'
      ELSE 'DEPRECATED'
    END;

    EXECUTE format(
      'COMMENT ON FUNCTION %I.%I(%s) IS %L',
      r.schema_name,
      r.function_name,
      r.args,
      comment_text
    );
  END LOOP;
END $$;
-- ROLLBACK NOTE (manual)
-- Use the following blocks to clear comments (COMMENT ON ... IS NULL).
-- VIEWS
-- DO $$
-- BEGIN
--   IF to_regclass('public.admin_business_suggestions_queue_v1') IS NOT NULL THEN
--     EXECUTE $$COMMENT ON VIEW public.admin_business_suggestions_queue_v1 IS NULL$$;
--   END IF;
--   IF to_regclass('public.admin_owner_claims_queue_v1') IS NOT NULL THEN
--     EXECUTE $$COMMENT ON VIEW public.admin_owner_claims_queue_v1 IS NULL$$;
--   END IF;
--   IF to_regclass('public.admin_reports_queue_v1') IS NOT NULL THEN
--     EXECUTE $$COMMENT ON VIEW public.admin_reports_queue_v1 IS NULL$$;
--   END IF;
--   IF to_regclass('public.admin_suggestions_v1') IS NOT NULL THEN
--     EXECUTE $$COMMENT ON VIEW public.admin_suggestions_v1 IS NULL$$;
--   END IF;
--   IF to_regclass('public.businesses_with_stats_mv') IS NOT NULL THEN
--     EXECUTE $$COMMENT ON VIEW public.businesses_with_stats_mv IS NULL$$;
--   END IF;
-- END $$;

-- TABLES
-- DO $$
-- BEGIN
--   IF to_regclass('public.user_favorites_legacy') IS NOT NULL THEN
--     EXECUTE $$COMMENT ON TABLE public.user_favorites_legacy IS NULL$$;
--   END IF;
--   IF to_regclass('public.import_places_stage') IS NOT NULL THEN
--     EXECUTE $$COMMENT ON TABLE public.import_places_stage IS NULL$$;
--   END IF;
-- END $$;

-- INDEXES
-- DO $$
-- BEGIN
--   IF to_regclass('public.idx_review_votes_review') IS NOT NULL THEN
--     EXECUTE $$COMMENT ON INDEX public.idx_review_votes_review IS NULL$$;
--   END IF;
--   IF to_regclass('public.review_votes_review_idx') IS NOT NULL THEN
--     EXECUTE $$COMMENT ON INDEX public.review_votes_review_idx IS NULL$$;
--   END IF;
--   IF to_regclass('public.review_votes_review_id_user_id_key') IS NOT NULL THEN
--     EXECUTE $$COMMENT ON INDEX public.review_votes_review_id_user_id_key IS NULL$$;
--   END IF;
--   IF to_regclass('public.review_votes_user_review_uniq') IS NOT NULL THEN
--     EXECUTE $$COMMENT ON INDEX public.review_votes_user_review_uniq IS NULL$$;
--   END IF;
-- END $$;

-- FUNCTIONS
-- DO $$
-- DECLARE
--   r record;
-- BEGIN
--   FOR r IN
--     SELECT n.nspname AS schema_name,
--            p.proname AS function_name,
--            pg_get_function_identity_arguments(p.oid) AS args
--     FROM pg_proc p
--     JOIN pg_namespace n ON n.oid = p.pronamespace
--     WHERE n.nspname = 'public'
--       AND p.proname IN (
--         'admin_list_business_suggestions_v1',
--         'admin_list_owner_claims_v1',
--         'admin_list_reports_v1',
--         'admin_list_reports_v2',
--         'search_nearby_businesses_v1',
--         'search_nearby_businesses_v2',
--         'get_menu_items_v1',
--         'get_top_businesses',
--         'taste_recommendations_from_match_v1',
--         'get_taste_matches_v1',
--         'approve_business_suggestion',
--         'create_owner_claim',
--         'approve_owner_claim',
--         'reject_owner_claim',
--         'refresh_businesses_with_stats_mv'
--       )
--   LOOP
--     EXECUTE format(
--       'COMMENT ON FUNCTION %I.%I(%s) IS NULL',
--       r.schema_name,
--       r.function_name,
--       r.args
--     );
--   END LOOP;
-- END $$;;
