-- Security advisor (0011_function_search_path_mutable): public.tg_businesses_sync_location_norm
-- was created in 20260831095021_backfill_city_norm_and_dedupe_ensure_profile.sql without
-- SET search_path, unlike every other function in this project. Same class of finding
-- already fixed project-wide once (20260724000007_fix_low_priority_security_findings.sql) —
-- this closes the regression. No logic changes, only the search_path hardening added.
CREATE OR REPLACE FUNCTION public.tg_businesses_sync_location_norm()
RETURNS trigger
LANGUAGE plpgsql
SET search_path TO 'public'
AS $$
BEGIN
  NEW.city_norm := public.normalize_tr_location_text(NEW.city);
  NEW.district_norm := public.normalize_tr_location_text(NEW.district);
  RETURN NEW;
END;
$$;
