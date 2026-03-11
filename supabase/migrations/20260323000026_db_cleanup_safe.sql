-- DB cleanup safe phase (no DROP)
-- Purpose:
-- 1) Mark candidate objects as deprecated via COMMENT
-- 2) Create deprecated schema
-- 3) Create side-copy aliases for candidate views/functions when they exist

create schema if not exists deprecated;
-- Candidate legacy views: add comment + create deprecated side-copy view
do $$
begin
  if to_regclass('public.admin_business_suggestions_queue_v1') is not null then
    execute 'comment on view public.admin_business_suggestions_queue_v1 is ' ||
      quote_literal('DEPRECATED: planned removal after compatibility window');
    execute '
      create or replace view deprecated.admin_business_suggestions_queue_v1_deprecated_202603 as
      select * from public.admin_business_suggestions_queue_v1
    ';
  end if;

  if to_regclass('public.admin_owner_claims_queue_v1') is not null then
    execute 'comment on view public.admin_owner_claims_queue_v1 is ' ||
      quote_literal('DEPRECATED: planned removal after compatibility window');
    execute '
      create or replace view deprecated.admin_owner_claims_queue_v1_deprecated_202603 as
      select * from public.admin_owner_claims_queue_v1
    ';
  end if;

  if to_regclass('public.admin_reports_queue_v1') is not null then
    execute 'comment on view public.admin_reports_queue_v1 is ' ||
      quote_literal('DEPRECATED: planned removal after compatibility window');
    execute '
      create or replace view deprecated.admin_reports_queue_v1_deprecated_202603 as
      select * from public.admin_reports_queue_v1
    ';
  end if;

  if to_regclass('public.admin_suggestions_v1') is not null then
    execute 'comment on view public.admin_suggestions_v1 is ' ||
      quote_literal('DEPRECATED: planned removal after compatibility window');
    execute '
      create or replace view deprecated.admin_suggestions_v1_deprecated_202603 as
      select * from public.admin_suggestions_v1
    ';
  end if;
end $$;
-- Candidate legacy tables: comment only (no rename / no move)
do $$
begin
  if to_regclass('public.user_favorites_legacy') is not null then
    execute 'comment on table public.user_favorites_legacy is ' ||
      quote_literal('DEPRECATED: planned removal after compatibility window');
  end if;

  if to_regclass('public.import_places_stage') is not null then
    execute 'comment on table public.import_places_stage is ' ||
      quote_literal('DEPRECATED: planned removal after compatibility window');
  end if;
end $$;
-- Candidate legacy functions: comment only (safe; no body rewrite/copy)
do $$
declare
  r record;
begin
  for r in
    select p.oid, p.proname, pg_get_function_identity_arguments(p.oid) as args
    from pg_proc p
    join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'public'
      and p.proname in (
        'admin_list_business_suggestions_v1',
        'admin_list_owner_claims_v1',
        'admin_list_reports_v1',
        'admin_list_reports_v2',
        'search_nearby_businesses_v1',
        'search_nearby_businesses_v2',
        'taste_recommendations_from_match_v1',
        'get_taste_matches_v1',
        'approve_business_suggestion',
        'create_owner_claim',
        'approve_owner_claim',
        'reject_owner_claim'
      )
  loop
    execute format(
      'comment on function public.%I(%s) is %L',
      r.proname,
      r.args,
      'DEPRECATED: planned removal after compatibility window'
    );
  end loop;
end $$;
-- Keep these as dangerous/risky (comment only, no copy/drop)
do $$
declare
  r record;
begin
  for r in
    select p.proname, pg_get_function_identity_arguments(p.oid) as args
    from pg_proc p
    join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'public'
      and p.proname in ('get_top_businesses', 'get_menu_items_v1')
  loop
    execute format(
      'comment on function public.%I(%s) is %L',
      r.proname,
      r.args,
      'DANGEROUS_TO_REMOVE: still referenced by app/runtime paths'
    );
  end loop;
end $$;
