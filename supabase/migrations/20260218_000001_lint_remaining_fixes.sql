-- Remaining linter fixes: auth_rls_initplan, analytics_events policy, unindexed FKs, table_feedback PK

-- Re-wrap auth/current_setting calls added by recent policy changes
DO $$
declare
  r record;
  new_qual text;
  new_check text;
  stmt text;
begin
  for r in
    select schemaname, tablename, policyname, qual, with_check
    from pg_policies
    where schemaname = 'public'
      and (
        (qual is not null and (qual ~ 'auth\\.' or qual ~ 'current_setting'))
        or (with_check is not null and (with_check ~ 'auth\\.' or with_check ~ 'current_setting'))
      )
  loop
    new_qual := r.qual;
    new_check := r.with_check;

    if new_qual is not null then
      new_qual := regexp_replace(new_qual, 'auth\\.([a-z_]+)\\(\\)', '(select auth.\\1())', 'g');
      new_qual := regexp_replace(new_qual, 'current_setting\\(([^\\)]*)\\)', '(select current_setting(\\1))', 'g');
    end if;

    if new_check is not null then
      new_check := regexp_replace(new_check, 'auth\\.([a-z_]+)\\(\\)', '(select auth.\\1())', 'g');
      new_check := regexp_replace(new_check, 'current_setting\\(([^\\)]*)\\)', '(select current_setting(\\1))', 'g');
    end if;

    stmt := format('alter policy %I on %I.%I', r.policyname, r.schemaname, r.tablename);
    if new_qual is not null then
      stmt := stmt || format(' using (%s)', new_qual);
    end if;
    if new_check is not null then
      stmt := stmt || format(' with check (%s)', new_check);
    end if;

    execute stmt;
  end loop;
end $$;
-- analytics_events: RLS enabled but no policy
DO $$
BEGIN
  IF to_regclass('public.analytics_events') IS NOT NULL THEN
    IF NOT EXISTS (
      SELECT 1 FROM pg_policies WHERE schemaname='public' AND tablename='analytics_events' AND policyname='analytics_events_admin_all'
    ) THEN
      EXECUTE 'CREATE POLICY analytics_events_admin_all ON public.analytics_events
        USING (public.is_admin()) WITH CHECK (public.is_admin())';
    END IF;
  END IF;
END $$;
-- Add missing FK indexes
CREATE INDEX IF NOT EXISTS business_amenity_map_amenity_id_idx ON public.business_amenity_map (amenity_id);
CREATE INDEX IF NOT EXISTS business_follows_business_id_idx ON public.business_follows (business_id);
CREATE INDEX IF NOT EXISTS business_premium_created_by_idx ON public.business_premium (created_by);
CREATE INDEX IF NOT EXISTS businesses_verified_by_idx ON public.businesses (verified_by);
CREATE INDEX IF NOT EXISTS menu_item_photos_business_id_idx ON public.menu_item_photos (business_id);
CREATE INDEX IF NOT EXISTS menu_item_suggestions_menu_item_id_idx ON public.menu_item_suggestions (menu_item_id);
CREATE INDEX IF NOT EXISTS menu_items_catalog_item_id_idx ON public.menu_items (catalog_item_id);
CREATE INDEX IF NOT EXISTS reports_reporter_user_id_idx ON public.reports (reporter_user_id);
CREATE INDEX IF NOT EXISTS sponsorship_leads_business_id_idx ON public.sponsorship_leads (business_id);
CREATE INDEX IF NOT EXISTS sponsorships_business_id_idx ON public.sponsorships (business_id);
CREATE INDEX IF NOT EXISTS sponsorships_created_by_idx ON public.sponsorships (created_by);
CREATE INDEX IF NOT EXISTS sponsorships_package_id_idx ON public.sponsorships (package_id);
-- table_feedback: add primary key
DO $$
BEGIN
  IF to_regclass('public.table_feedback') IS NOT NULL THEN
    IF NOT EXISTS (
      SELECT 1 FROM information_schema.columns
      WHERE table_schema='public' AND table_name='table_feedback' AND column_name='id'
    ) THEN
      EXECUTE 'ALTER TABLE public.table_feedback ADD COLUMN id uuid DEFAULT gen_random_uuid()';
    END IF;
    IF NOT EXISTS (
      SELECT 1 FROM pg_constraint
      WHERE conrelid = 'public.table_feedback'::regclass AND contype = 'p'
    ) THEN
      EXECUTE 'ALTER TABLE public.table_feedback ADD CONSTRAINT table_feedback_pkey PRIMARY KEY (id)';
    END IF;
  END IF;
END $$;
