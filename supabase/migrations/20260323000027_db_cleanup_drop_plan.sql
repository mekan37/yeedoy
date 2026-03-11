do $$
begin
  raise exception 'DROP PLAN - review required';
end $$;
-- DROP PLAN ONLY - DISABLED BY DEFAULT
-- This file is intentionally blocked to prevent accidental execution.
-- Preconditions for each drop candidate:
-- 1) No Flutter reference (rpc/from/storage scan)
-- 2) No DB dependency chain (pg_depend / view/function/trigger/policy references)
-- 3) Object has DEPRECATED comment and at least one release cycle elapsed

-- ============================================================
-- Candidate DROP statements (manual review required)
-- ============================================================

-- Views
-- drop view if exists public.admin_business_suggestions_queue_v1;
-- drop view if exists public.admin_owner_claims_queue_v1;
-- drop view if exists public.admin_reports_queue_v1;
-- drop view if exists public.admin_suggestions_v1;

-- Tables (high risk: data loss, only after archive/export)
-- drop table if exists public.user_favorites_legacy;
-- drop table if exists public.import_places_stage;

-- Functions
-- drop function if exists public.admin_list_business_suggestions_v1(...);
-- drop function if exists public.admin_list_owner_claims_v1(...);
-- drop function if exists public.admin_list_reports_v1(...);
-- drop function if exists public.admin_list_reports_v2(...);
-- drop function if exists public.search_nearby_businesses_v1(...);
-- drop function if exists public.search_nearby_businesses_v2(...);
-- drop function if exists public.taste_recommendations_from_match_v1(...);
-- drop function if exists public.get_taste_matches_v1(...);
-- drop function if exists public.approve_business_suggestion(...);
-- drop function if exists public.create_owner_claim(...);
-- drop function if exists public.approve_owner_claim(...);
-- drop function if exists public.reject_owner_claim(...);

-- ============================================================
-- Dependency check template (run manually before each DROP)
-- ============================================================
-- select
--   c.classid::regclass as dependent_catalog,
--   c.objid,
--   c.refclassid::regclass as referenced_catalog,
--   c.refobjid,
--   c.deptype
-- from pg_depend c
-- where c.refobjid = 'public.admin_business_suggestions_queue_v1'::regclass;;
