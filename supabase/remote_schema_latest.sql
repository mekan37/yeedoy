-- Yeedoy schema snapshot (migration-derived)
-- Generated at: 2026-02-27 16:11:25
-- Source: supabase/migrations/*.sql
-- Note: This is derived from repository migrations and may differ from linked remote state.


-- ===== BEGIN MIGRATION: 20260126_000001_deprecate_candidates.sql =====
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
-- END $$;

-- ===== END MIGRATION: 20260126_000001_deprecate_candidates.sql =====

-- ===== BEGIN MIGRATION: 20260128_000001_admin_price_suggestions_queue.sql =====
do $$
begin
  if not exists (
    select 1 from pg_type where typname = 'menu_price_suggestion_status'
  ) then
    create type public.menu_price_suggestion_status as enum (
      'pending', 'approved', 'rejected'
    );
  end if;
end $$;

create table if not exists public.menu_item_price_suggestions (
  id uuid primary key default gen_random_uuid(),
  menu_item_id uuid not null references public.menu_items(id) on delete cascade,
  business_id uuid not null references public.businesses(id) on delete cascade,
  suggested_price_cents integer not null,
  currency text not null default 'TRY',
  note text null,
  created_by uuid not null,
  created_at timestamptz default now(),
  status public.menu_price_suggestion_status not null default 'pending',
  handled_by uuid null,
  handled_at timestamptz null,
  approved_by uuid null,
  approved_at timestamptz null
);

create or replace function public.admin_list_menu_price_suggestions_v2(
  p_status text default null,
  p_limit integer default 30,
  p_offset integer default 0,
  p_sla_only boolean default false,
  p_assigned text default null
)
returns table(
  suggestion_id uuid,
  status text,
  created_at timestamp with time zone,
  sla_breached boolean,
  business_id uuid,
  business_name text,
  city text,
  district text,
  menu_item_id uuid,
  item_name text,
  current_price_cents integer,
  suggested_price_cents integer,
  currency text,
  created_by uuid,
  assigned_to uuid,
  assigned_at timestamp with time zone
)
language sql
stable
security definer
set search_path to 'public'
as $function$
  select
    s.id as suggestion_id,
    s.status::text,
    s.created_at,
    (s.status='pending' and s.created_at < now() - interval '48 hours') as sla_breached,

    b.id as business_id,
    b.name as business_name,
    b.city,
    b.district,

    mi.id as menu_item_id,
    mi.name as item_name,
    mi.price_cents as current_price_cents,
    s.suggested_price_cents,
    s.currency,

    s.created_by,
    s.handled_by as assigned_to,
    s.handled_at as assigned_at
  from public.menu_item_price_suggestions s
  join public.menu_items mi on mi.id = s.menu_item_id
  join public.businesses b on b.id = s.business_id
  where public.is_admin()
    and (
      p_status is null
      or p_status = ''
      or s.status::text = p_status
    )
    and (
      p_assigned is null
      or p_assigned = ''
      or (p_assigned = 'me' and s.handled_by = auth.uid())
      or (p_assigned = 'unassigned' and s.handled_by is null)
      or s.handled_by::text = p_assigned
    )
    and (not p_sla_only or (s.status='pending' and s.created_at < now() - interval '48 hours'))
  order by (s.status='pending') desc, s.created_at asc
  limit greatest(p_limit,0) offset greatest(p_offset,0);
$function$;

create or replace function public.admin_export_menu_price_suggestions_csv_v1(
  p_status text default null,
  p_sla_only boolean default false,
  p_assigned text default null
)
returns text
language plpgsql
security definer
set search_path to 'public'
as $function$
declare
  v_csv text;
begin
  if not public.is_admin() then
    raise exception 'not_admin';
  end if;

  select string_agg(line, E'\n') into v_csv
  from (
    select
      'id,created_at,status,business_id,business_name,menu_item_id,item_name,current_price_cents,suggested_price_cents,currency,created_by,handled_by,handled_at,note' as line
    union all
    select
      concat_ws(',',
        s.id::text,
        to_char(s.created_at, 'YYYY-MM-DD"T"HH24:MI:SS"Z"'),
        replace(coalesce(s.status::text,''), ',', ' '),
        coalesce(s.business_id::text,''),
        replace(coalesce(b.name,''), ',', ' '),
        coalesce(s.menu_item_id::text,''),
        replace(coalesce(mi.name,''), ',', ' '),
        coalesce(mi.price_cents::text,''),
        coalesce(s.suggested_price_cents::text,''),
        replace(coalesce(s.currency,''), ',', ' '),
        coalesce(s.created_by::text,''),
        coalesce(s.handled_by::text,''),
        coalesce(to_char(s.handled_at, 'YYYY-MM-DD"T"HH24:MI:SS"Z"'),''),
        replace(coalesce(s.note,''), E'\n', ' ')
      ) as line
    from public.menu_item_price_suggestions s
    join public.menu_items mi on mi.id = s.menu_item_id
    join public.businesses b on b.id = s.business_id
    where (p_status is null or p_status = '' or s.status::text = p_status)
      and (not p_sla_only or (s.status='pending' and s.created_at < now() - interval '48 hours'))
      and (
        p_assigned is null
        or p_assigned = ''
        or (p_assigned = 'me' and s.handled_by = auth.uid())
        or (p_assigned = 'unassigned' and s.handled_by is null)
        or s.handled_by::text = p_assigned
      )
    order by s.created_at desc
  ) t;

  perform public.log_admin_action_v1(
    'price_suggestion.export_csv',
    'menu_item_price_suggestions',
    null,
    jsonb_build_object('status', p_status, 'sla_only', p_sla_only, 'assigned', p_assigned)
  );

  return v_csv;
end;
$function$;

-- ===== END MIGRATION: 20260128_000001_admin_price_suggestions_queue.sql =====

-- ===== BEGIN MIGRATION: 20260129_000001_owner_price_suggestions.sql =====
alter table public.menu_item_price_suggestions
  add column if not exists approved_by uuid,
  add column if not exists approved_at timestamp with time zone;

create or replace function public.owner_approve_price_suggestion_v1(p_suggestion_id uuid)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $function$
begin
  return public.owner_approve_menu_price_suggestion_v1(p_suggestion_id);
end;
$function$;

create or replace function public.owner_reject_price_suggestion_v1(
  p_suggestion_id uuid,
  p_reason text default null
)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $function$
begin
  return public.owner_reject_menu_price_suggestion_v1(p_suggestion_id, p_reason);
end;
$function$;

create or replace function public.get_owner_price_suggestions_v1(
  p_business_id uuid default null,
  p_status text default 'pending',
  p_limit integer default 30,
  p_offset integer default 0
)
returns table(
  suggestion_id uuid,
  status text,
  created_at timestamp with time zone,
  business_id uuid,
  business_name text,
  menu_item_id uuid,
  item_name text,
  current_price_cents integer,
  suggested_price_cents integer,
  currency text,
  created_by uuid
)
language sql
stable
security definer
set search_path to 'public'
as $function$
  with owner_businesses as (
    select c.business_id
    from public.owner_claims c
    where c.user_id = auth.uid()
      and c.status = 'approved'
  ),
  target_businesses as (
    select business_id
    from owner_businesses
    where p_business_id is null
    union all
    select p_business_id
    where p_business_id is not null
  )
  select
    s.id as suggestion_id,
    s.status::text,
    s.created_at,
    s.business_id,
    b.name as business_name,
    mi.id as menu_item_id,
    mi.name as item_name,
    mi.price_cents as current_price_cents,
    s.suggested_price_cents,
    s.currency,
    s.created_by
  from public.menu_item_price_suggestions s
  join target_businesses tb on tb.business_id = s.business_id
  join public.menu_items mi on mi.id = s.menu_item_id
  join public.businesses b on b.id = s.business_id
  where (p_status is null or s.status::text = p_status)
  order by (s.status='pending') desc, s.created_at asc
  limit greatest(p_limit,0) offset greatest(p_offset,0);
$function$;

do $$
begin
  if not exists (
    select 1
    from pg_policies
    where schemaname = 'public'
      and tablename = 'menu_item_price_suggestions'
      and policyname = 'price_sugg_owner_read'
  ) then
    execute 'create policy price_sugg_owner_read on public.menu_item_price_suggestions
      for select
      using (public.is_owner_of_business(business_id))';
  end if;
end $$;

-- ===== END MIGRATION: 20260129_000001_owner_price_suggestions.sql =====

-- ===== BEGIN MIGRATION: 20260130_000001_price_note_normalization.sql =====
create or replace function public.submit_menu_item_price_suggestion_v1(
  p_menu_item_id uuid,
  p_suggested_price_cents integer,
  p_currency text default 'TRY',
  p_note text default null
)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $function$
declare
  v_business_id uuid;
  v_cnt int;
  v_note text;
begin
  if auth.uid() is null then
    return jsonb_build_object('ok', false, 'error', 'not_authenticated');
  end if;

  if p_suggested_price_cents < 0 then
    return jsonb_build_object('ok', false, 'error', 'bad_price');
  end if;

  v_note := nullif(trim(p_note), '');

  select business_id into v_business_id
  from public.menu_items
  where id = p_menu_item_id and status='published';

  if v_business_id is null then
    return jsonb_build_object('ok', false, 'error', 'not_found');
  end if;

  -- rate limit: aynı kullanıcı aynı itemâ€™e 24 saatte 1
  select count(*) into v_cnt
  from public.menu_item_price_suggestions
  where menu_item_id = p_menu_item_id
    and created_by = auth.uid()
    and created_at >= now() - interval '24 hours';

  if v_cnt > 0 then
    return jsonb_build_object('ok', false, 'error', 'rate_limited_24h');
  end if;

  insert into public.menu_item_price_suggestions(
    menu_item_id, business_id, suggested_price_cents, currency, note, created_by
  )
  values (
    p_menu_item_id, v_business_id, p_suggested_price_cents, p_currency, v_note, auth.uid()
  );

  return jsonb_build_object('ok', true);
end;
$function$;

create or replace function public.owner_reject_menu_price_suggestion_v1(
  p_suggestion_id uuid,
  p_note text default null
)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $function$
declare
  v_business_id uuid;
  v_note text;
begin
  if auth.uid() is null then
    return jsonb_build_object('ok', false, 'error', 'not_authenticated');
  end if;

  v_note := nullif(trim(p_note), '');

  select business_id into v_business_id
  from public.menu_item_price_suggestions
  where id = p_suggestion_id and status='pending';

  if v_business_id is null then
    return jsonb_build_object('ok', false, 'error', 'not_found_or_not_pending');
  end if;

  if not public.is_owner_of_business(v_business_id) and not public.is_admin() then
    return jsonb_build_object('ok', false, 'error', 'not_owner');
  end if;

  update public.menu_item_price_suggestions
  set status='rejected',
      note = coalesce(note, v_note),
      handled_by=auth.uid(),
      handled_at=now()
  where id = p_suggestion_id
    and status='pending';

  return jsonb_build_object('ok', true);
end;
$function$;

create or replace function public.admin_reject_menu_price_suggestion_v1(
  p_suggestion_id uuid,
  p_note text default null
)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $function$
declare
  v_note text;
begin
  if not public.is_admin() then
    return jsonb_build_object('ok', false, 'error', 'not_admin');
  end if;

  v_note := nullif(trim(p_note), '');

  update public.menu_item_price_suggestions
  set status='rejected',
      note = coalesce(note, v_note),
      handled_by=auth.uid(),
      handled_at=now()
  where id = p_suggestion_id
    and status='pending';

  if not found then
    return jsonb_build_object('ok', false, 'error', 'not_found_or_not_pending');
  end if;

  return jsonb_build_object('ok', true);
end;
$function$;

create or replace function public.admin_reject_suspended_claim_v1(
  p_claim_id uuid,
  p_note text default null
)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $function$
declare
  v_note text;
begin
  if not public.is_admin() then
    return jsonb_build_object('ok', false, 'error', 'not_admin');
  end if;

  v_note := nullif(trim(p_note), '');

  update public.suspended_meal_claims
  set status='rejected',
      note = coalesce(note, v_note),
      handled_by=auth.uid(),
      handled_at=now()
  where id = p_claim_id
    and status='pending';

  if not found then
    return jsonb_build_object('ok', false, 'error', 'not_found_or_not_pending');
  end if;

  return jsonb_build_object('ok', true);
end;
$function$;

create or replace function public.admin_decide_owner_claim_v1(
  p_claim_id uuid,
  p_decision text,
  p_note text default null
)
returns void
language plpgsql
security definer
set search_path to 'public'
as $function$
declare
  v_note text;
begin
  if not public.is_admin() then
    raise exception 'not_admin';
  end if;

  v_note := nullif(trim(p_note), '');

  update public.owner_claims
  set
    status = p_decision,
    handled_by = auth.uid(),
    handled_at = now(),
    admin_note = v_note
  where id = p_claim_id;

  perform public.log_admin_action_v1(
    case
      when p_decision = 'approved' then 'claim.approve'
      else 'claim.reject'
    end,
    'owner_claims',
    p_claim_id,
    jsonb_build_object(
      'decision', p_decision,
      'admin_note', v_note
    )
  );
end;
$function$;

create or replace function public.admin_bulk_decide_owner_claims_v1(
  p_claim_ids uuid[],
  p_decision text,
  p_note text default null
)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $function$
declare
  v_count int;
  v_note text;
begin
  if not public.is_admin() then
    raise exception 'not_admin';
  end if;

  v_note := nullif(trim(p_note), '');

  update public.owner_claims
  set
    status = p_decision,
    handled_by = auth.uid(),
    handled_at = now(),
    admin_note = v_note
  where id = any(p_claim_ids);

  get diagnostics v_count = row_count;

  perform public.log_admin_action_v1(
    'claim.bulk_decide',
    'owner_claims',
    null,
    jsonb_build_object('decision', p_decision, 'count', v_count)
  );

  return jsonb_build_object('ok', true, 'updated', v_count);
end;
$function$;

create or replace function public.submit_owner_claim_v1(
  p_business_id uuid,
  p_full_name text,
  p_phone text,
  p_evidence_url text default null,
  p_note text default null
)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $function$
declare
  v_uid uuid := auth.uid();
  v_recent_exists boolean;
  v_claim_id uuid;
  v_note text;
begin
  if v_uid is null then
    return jsonb_build_object('ok', false, 'error', 'not_authenticated');
  end if;

  if p_business_id is null then
    return jsonb_build_object('ok', false, 'error', 'missing_business_id');
  end if;

  v_note := nullif(trim(p_note), '');

  -- 7 gün rate limit (aynı business için)
  select exists(
    select 1
    from public.owner_claims
    where user_id = v_uid
      and business_id = p_business_id
      and created_at >= now() - interval '7 days'
  ) into v_recent_exists;

  if v_recent_exists then
    return jsonb_build_object('ok', false, 'error', 'rate_limited_7d');
  end if;

  insert into public.owner_claims(
    user_id, business_id, full_name, phone, evidence_url, note, status
  ) values (
    v_uid, p_business_id,
    nullif(trim(p_full_name),''),
    nullif(trim(p_phone),''),
    nullif(trim(p_evidence_url),''),
    v_note,
    'pending'
  )
  returning id into v_claim_id;

  return jsonb_build_object('ok', true, 'claim_id', v_claim_id);
exception
  when unique_violation then
    return jsonb_build_object('ok', false, 'error', 'already_submitted');
end;
$function$;



-- ===== END MIGRATION: 20260130_000001_price_note_normalization.sql =====

-- ===== BEGIN MIGRATION: 20260131_000001_price_note_normalization_v2.sql =====
create or replace function public.approve_menu_item_suggestion_v1(
  p_suggestion_id uuid,
  p_note text default null
)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $function$
declare
  s record;
  v_item_id uuid;
  v_note text;
begin
  if not public.is_admin() then
    raise exception 'not_admin';
  end if;

  v_note := nullif(trim(p_note), '');

  select * into s
  from public.menu_item_suggestions
  where id = p_suggestion_id and status = 'pending';

  if s is null then
    return jsonb_build_object('ok', false, 'error', 'not_found_or_not_pending');
  end if;

  if s.action = 'create' then
    insert into public.menu_items(
      section_id, business_id, name, description, price_cents, currency, calories,
      is_vegan, is_vegetarian, is_gluten_free, is_lactose_free, is_halal,
      status, created_by,
      catalog_item_id
    )
    values (
      (s.payload->>'section_id')::uuid,
      s.business_id,
      coalesce(s.payload->>'name',''),
      s.payload->>'description',
      nullif(s.payload->>'price_cents','')::int,
      coalesce(s.payload->>'currency','TRY'),
      nullif(s.payload->>'calories','')::int,
      coalesce((s.payload->>'is_vegan')::boolean,false),
      coalesce((s.payload->>'is_vegetarian')::boolean,false),
      coalesce((s.payload->>'is_gluten_free')::boolean,false),
      coalesce((s.payload->>'is_lactose_free')::boolean,false),
      coalesce((s.payload->>'is_halal')::boolean,false),
      'published',
      s.created_by,
      nullif(s.payload->>'catalog_item_id','')::bigint
    )
    returning id into v_item_id;

  elsif s.action = 'price_update' then
    update public.menu_items
    set price_cents = nullif(s.payload->>'price_cents','')::int,
        currency = coalesce(s.payload->>'currency','TRY'),
        updated_at = now()
    where id = s.menu_item_id;

    v_item_id := s.menu_item_id;

  elsif s.action = 'update' then
    update public.menu_items
    set
      name = coalesce(s.payload->>'name', name),
      description = coalesce(s.payload->>'description', description),
      price_cents = coalesce(nullif(s.payload->>'price_cents','')::int, price_cents),
      calories = coalesce(nullif(s.payload->>'calories','')::int, calories),
      is_vegan = coalesce((s.payload->>'is_vegan')::boolean, is_vegan),
      is_vegetarian = coalesce((s.payload->>'is_vegetarian')::boolean, is_vegetarian),
      is_gluten_free = coalesce((s.payload->>'is_gluten_free')::boolean, is_gluten_free),
      is_lactose_free = coalesce((s.payload->>'is_lactose_free')::boolean, is_lactose_free),
      is_halal = coalesce((s.payload->>'is_halal')::boolean, is_halal),
      catalog_item_id = coalesce(nullif(s.payload->>'catalog_item_id','')::bigint, catalog_item_id),
      updated_at = now()
    where id = s.menu_item_id;

    v_item_id := s.menu_item_id;

  elsif s.action = 'delete' then
    update public.menu_items set status = 'archived', updated_at = now()
    where id = s.menu_item_id;

    v_item_id := s.menu_item_id;
  end if;

  update public.menu_item_suggestions
  set status = 'approved',
      handled_by = auth.uid(),
      handled_at = now(),
      admin_note = v_note
  where id = p_suggestion_id;

  return jsonb_build_object('ok', true, 'menu_item_id', v_item_id);
end;
$function$;

create or replace function public.reject_owner_claim(
  p_claim_id uuid,
  p_note text default null
)
returns void
language plpgsql
security definer
set search_path to 'public'
as $function$
declare
  v_is_admin boolean;
  v_note text;
begin
  select exists(select 1 from public.admin_users where user_id = auth.uid())
  into v_is_admin;

  if not v_is_admin then
    raise exception 'not_authorized';
  end if;

  v_note := nullif(trim(p_note), '');

  update public.owner_claims
  set status = 'rejected',
      admin_note = v_note,
      reviewed_at = now()
  where id = p_claim_id;
end;
$function$;

create or replace function public.submit_suspended_meal_claim_v1(
  p_suspended_meal_id uuid,
  p_note text default null
)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $function$
declare
  v_status public.suspended_meal_status;
  v_note text;
begin
  if auth.uid() is null then
    return jsonb_build_object('ok', false, 'error', 'not_authenticated');
  end if;

  v_note := nullif(trim(p_note), '');

  select status into v_status
  from public.suspended_meals
  where id = p_suspended_meal_id;

  if v_status is null then
    return jsonb_build_object('ok', false, 'error', 'not_found');
  end if;

  if v_status <> 'active' then
    return jsonb_build_object('ok', false, 'error', 'not_active');
  end if;

  -- aynı kullanıcı aynı mealâ€™e tekrar claim atamasın
  if exists (
    select 1 from public.suspended_meal_claims
    where suspended_meal_id = p_suspended_meal_id
      and claimant_user_id = auth.uid()
  ) then
    return jsonb_build_object('ok', false, 'error', 'already_claimed');
  end if;

  insert into public.suspended_meal_claims(suspended_meal_id, claimant_user_id, note)
  values (p_suspended_meal_id, auth.uid(), v_note);

  return jsonb_build_object('ok', true);
end;
$function$;

create or replace function public.submit_business_suggestion(
  p_name text,
  p_category text,
  p_address text,
  p_city text,
  p_district text,
  p_note text default null
)
returns bigint
language plpgsql
security definer
set search_path to 'public'
as $function$
declare
  v_uid uuid := auth.uid();
  v_id bigint;
  v_note text;
begin
  if v_uid is null then
    raise exception 'not_authenticated';
  end if;

  v_note := nullif(trim(p_note), '');

  insert into public.business_suggestions(
    user_id, name, category, address, city, district, note
  ) values (
    v_uid, p_name, p_category, p_address, p_city, p_district, v_note
  )
  returning id into v_id;

  return v_id;
end;
$function$;



-- ===== END MIGRATION: 20260131_000001_price_note_normalization_v2.sql =====

-- ===== BEGIN MIGRATION: 20260201_000001_owner_menu_crud.sql =====
create function public.owner_create_menu_v1(
  p_business_id uuid,
  p_title text,
  p_kind text default null,
  p_active_from timestamptz default null,
  p_active_to timestamptz default null
)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $function$
declare
  v_title text;
  v_kind text;
  v_menu_id uuid;
begin
  if auth.uid() is null then
    return jsonb_build_object('ok', false, 'code', 'not_authenticated', 'message', 'Auth required');
  end if;

  if not (public.is_admin() or public.is_owner_of_business(p_business_id)) then
    return jsonb_build_object('ok', false, 'code', 'not_owner', 'message', 'Not owner');
  end if;

  v_title := nullif(trim(p_title), '');
  if v_title is null then
    return jsonb_build_object('ok', false, 'code', 'invalid', 'message', 'Title required');
  end if;

  if p_active_from is not null and p_active_to is not null and p_active_from > p_active_to then
    return jsonb_build_object('ok', false, 'code', 'invalid', 'message', 'Invalid active range');
  end if;

  v_kind := nullif(trim(p_kind), '');

  insert into public.menus(
    business_id, title, kind, status, created_by, active_from, active_to
  )
  values (
    p_business_id, v_title, v_kind, 'draft', auth.uid(), p_active_from, p_active_to
  )
  returning id into v_menu_id;

  if public.is_admin() then
    insert into public.admin_audit_log(action, target_table, target_id, meta)
    values ('menu.create', 'menus', v_menu_id, jsonb_build_object('business_id', p_business_id));
  end if;

  return jsonb_build_object('ok', true, 'id', v_menu_id, 'message', 'Created');
end;
$function$;

create function public.owner_update_menu_v1(
  p_menu_id uuid,
  p_title text default null,
  p_kind text default null,
  p_active_from timestamptz default null,
  p_active_to timestamptz default null
)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $function$
declare
  v_title text;
  v_kind text;
  v_business_id uuid;
begin
  if auth.uid() is null then
    return jsonb_build_object('ok', false, 'code', 'not_authenticated', 'message', 'Auth required');
  end if;

  select business_id into v_business_id
  from public.menus
  where id = p_menu_id;

  if v_business_id is null then
    return jsonb_build_object('ok', false, 'code', 'not_found', 'message', 'Menu not found');
  end if;

  if not (public.is_admin() or public.is_owner_of_business(v_business_id)) then
    return jsonb_build_object('ok', false, 'code', 'not_owner', 'message', 'Not owner');
  end if;

  if p_active_from is not null and p_active_to is not null and p_active_from > p_active_to then
    return jsonb_build_object('ok', false, 'code', 'invalid', 'message', 'Invalid active range');
  end if;

  v_title := nullif(trim(p_title), '');
  v_kind := nullif(trim(p_kind), '');

  update public.menus
  set
    title = coalesce(v_title, title),
    kind = coalesce(v_kind, kind),
    active_from = coalesce(p_active_from, active_from),
    active_to = coalesce(p_active_to, active_to),
    updated_at = now()
  where id = p_menu_id;

  if public.is_admin() then
    insert into public.admin_audit_log(action, target_table, target_id, meta)
    values ('menu.update', 'menus', p_menu_id, jsonb_build_object('business_id', v_business_id));
  end if;

  return jsonb_build_object('ok', true, 'id', p_menu_id, 'message', 'Updated');
end;
$function$;

create function public.owner_archive_menu_v1(
  p_menu_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $function$
declare
  v_business_id uuid;
begin
  if auth.uid() is null then
    return jsonb_build_object('ok', false, 'code', 'not_authenticated', 'message', 'Auth required');
  end if;

  select business_id into v_business_id
  from public.menus
  where id = p_menu_id;

  if v_business_id is null then
    return jsonb_build_object('ok', false, 'code', 'not_found', 'message', 'Menu not found');
  end if;

  if not (public.is_admin() or public.is_owner_of_business(v_business_id)) then
    return jsonb_build_object('ok', false, 'code', 'not_owner', 'message', 'Not owner');
  end if;

  update public.menus
  set status = 'archived',
      updated_at = now()
  where id = p_menu_id;

  if public.is_admin() then
    insert into public.admin_audit_log(action, target_table, target_id, meta)
    values ('menu.archive', 'menus', p_menu_id, jsonb_build_object('business_id', v_business_id));
  end if;

  return jsonb_build_object('ok', true, 'id', p_menu_id, 'message', 'Archived');
end;
$function$;

create function public.owner_publish_menu_v1(
  p_menu_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $function$
declare
  v_business_id uuid;
begin
  if auth.uid() is null then
    return jsonb_build_object('ok', false, 'code', 'not_authenticated', 'message', 'Auth required');
  end if;

  select business_id into v_business_id
  from public.menus
  where id = p_menu_id;

  if v_business_id is null then
    return jsonb_build_object('ok', false, 'code', 'not_found', 'message', 'Menu not found');
  end if;

  if not (public.is_admin() or public.is_owner_of_business(v_business_id)) then
    return jsonb_build_object('ok', false, 'code', 'not_owner', 'message', 'Not owner');
  end if;

  update public.menus
  set status = 'published',
      updated_at = now()
  where id = p_menu_id;

  if public.is_admin() then
    insert into public.admin_audit_log(action, target_table, target_id, meta)
    values ('menu.publish', 'menus', p_menu_id, jsonb_build_object('business_id', v_business_id));
  end if;

  return jsonb_build_object('ok', true, 'id', p_menu_id, 'message', 'Published');
end;
$function$;

create function public.owner_create_menu_section_v1(
  p_menu_id uuid,
  p_title text,
  p_sort_order integer default null
)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $function$
declare
  v_title text;
  v_sort integer;
  v_section_id uuid;
  v_business_id uuid;
begin
  if auth.uid() is null then
    return jsonb_build_object('ok', false, 'code', 'not_authenticated', 'message', 'Auth required');
  end if;

  select business_id into v_business_id
  from public.menus
  where id = p_menu_id;

  if v_business_id is null then
    return jsonb_build_object('ok', false, 'code', 'not_found', 'message', 'Menu not found');
  end if;

  if not (public.is_admin() or public.is_owner_of_business(v_business_id)) then
    return jsonb_build_object('ok', false, 'code', 'not_owner', 'message', 'Not owner');
  end if;

  v_title := nullif(trim(p_title), '');
  if v_title is null then
    return jsonb_build_object('ok', false, 'code', 'invalid', 'message', 'Title required');
  end if;

  if p_sort_order is null then
    select coalesce(max(sort_order), 0) + 1 into v_sort
    from public.menu_sections
    where menu_id = p_menu_id;
  else
    v_sort := p_sort_order;
  end if;

  insert into public.menu_sections(menu_id, title, sort_order, created_by)
  values (p_menu_id, v_title, v_sort, auth.uid())
  returning id into v_section_id;

  if public.is_admin() then
    insert into public.admin_audit_log(action, target_table, target_id, meta)
    values ('menu_section.create', 'menu_sections', v_section_id, jsonb_build_object('menu_id', p_menu_id));
  end if;

  return jsonb_build_object('ok', true, 'id', v_section_id, 'message', 'Created');
end;
$function$;

create function public.owner_update_menu_section_v1(
  p_section_id uuid,
  p_title text
)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $function$
declare
  v_title text;
  v_business_id uuid;
  v_menu_id uuid;
begin
  if auth.uid() is null then
    return jsonb_build_object('ok', false, 'code', 'not_authenticated', 'message', 'Auth required');
  end if;

  select m.business_id, s.menu_id into v_business_id, v_menu_id
  from public.menu_sections s
  join public.menus m on m.id = s.menu_id
  where s.id = p_section_id;

  if v_business_id is null then
    return jsonb_build_object('ok', false, 'code', 'not_found', 'message', 'Section not found');
  end if;

  if not (public.is_admin() or public.is_owner_of_business(v_business_id)) then
    return jsonb_build_object('ok', false, 'code', 'not_owner', 'message', 'Not owner');
  end if;

  v_title := nullif(trim(p_title), '');
  if v_title is null then
    return jsonb_build_object('ok', false, 'code', 'invalid', 'message', 'Title required');
  end if;

  update public.menu_sections
  set title = v_title,
      updated_at = now()
  where id = p_section_id;

  if public.is_admin() then
    insert into public.admin_audit_log(action, target_table, target_id, meta)
    values ('menu_section.update', 'menu_sections', p_section_id, jsonb_build_object('menu_id', v_menu_id));
  end if;

  return jsonb_build_object('ok', true, 'id', p_section_id, 'message', 'Updated');
end;
$function$;

create function public.owner_delete_menu_section_v1(
  p_section_id uuid,
  p_delete_items boolean default true
)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $function$
declare
  v_business_id uuid;
  v_menu_id uuid;
  v_has_items boolean;
begin
  if auth.uid() is null then
    return jsonb_build_object('ok', false, 'code', 'not_authenticated', 'message', 'Auth required');
  end if;

  select m.business_id, s.menu_id into v_business_id, v_menu_id
  from public.menu_sections s
  join public.menus m on m.id = s.menu_id
  where s.id = p_section_id;

  if v_business_id is null then
    return jsonb_build_object('ok', false, 'code', 'not_found', 'message', 'Section not found');
  end if;

  if not (public.is_admin() or public.is_owner_of_business(v_business_id)) then
    return jsonb_build_object('ok', false, 'code', 'not_owner', 'message', 'Not owner');
  end if;

  select exists(
    select 1 from public.menu_items where section_id = p_section_id
  ) into v_has_items;

  if v_has_items and not p_delete_items then
    return jsonb_build_object('ok', false, 'code', 'has_items', 'message', 'Section has items');
  end if;

  if p_delete_items then
    update public.menu_items
    set status = 'archived',
        updated_at = now()
    where section_id = p_section_id;
  end if;

  delete from public.menu_sections where id = p_section_id;

  if public.is_admin() then
    insert into public.admin_audit_log(action, target_table, target_id, meta)
    values ('menu_section.delete', 'menu_sections', p_section_id, jsonb_build_object('menu_id', v_menu_id));
  end if;

  return jsonb_build_object('ok', true, 'id', p_section_id, 'message', 'Deleted');
end;
$function$;

create function public.owner_reorder_menu_sections_v1(
  p_menu_id uuid,
  p_section_ids uuid[]
)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $function$
declare
  v_business_id uuid;
  v_count int;
begin
  if auth.uid() is null then
    return jsonb_build_object('ok', false, 'code', 'not_authenticated', 'message', 'Auth required');
  end if;

  select business_id into v_business_id
  from public.menus
  where id = p_menu_id;

  if v_business_id is null then
    return jsonb_build_object('ok', false, 'code', 'not_found', 'message', 'Menu not found');
  end if;

  if not (public.is_admin() or public.is_owner_of_business(v_business_id)) then
    return jsonb_build_object('ok', false, 'code', 'not_owner', 'message', 'Not owner');
  end if;

  if p_section_ids is null or array_length(p_section_ids, 1) is null then
    return jsonb_build_object('ok', false, 'code', 'invalid', 'message', 'Empty section list');
  end if;

  select count(*) into v_count
  from public.menu_sections
  where menu_id = p_menu_id
    and id = any(p_section_ids);

  if v_count <> array_length(p_section_ids, 1) then
    return jsonb_build_object('ok', false, 'code', 'invalid', 'message', 'Section list mismatch');
  end if;

  update public.menu_sections s
  set sort_order = r.ord
  from (
    select unnest(p_section_ids) as id, row_number() over () as ord
  ) r
  where s.id = r.id;

  if public.is_admin() then
    insert into public.admin_audit_log(action, target_table, target_id, meta)
    values ('menu_section.reorder', 'menu_sections', null, jsonb_build_object('menu_id', p_menu_id));
  end if;

  return jsonb_build_object('ok', true, 'id', p_menu_id, 'message', 'Reordered');
end;
$function$;

create function public.owner_create_menu_item_v1(
  p_section_id uuid,
  p_name text,
  p_description text default null,
  p_price_cents integer default null,
  p_currency text default 'TRY',
  p_catalog_item_id bigint default null
)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $function$
declare
  v_name text;
  v_desc text;
  v_currency text;
  v_item_id uuid;
  v_business_id uuid;
  v_menu_id uuid;
begin
  if auth.uid() is null then
    return jsonb_build_object('ok', false, 'code', 'not_authenticated', 'message', 'Auth required');
  end if;

  select m.business_id, m.id into v_business_id, v_menu_id
  from public.menu_sections s
  join public.menus m on m.id = s.menu_id
  where s.id = p_section_id;

  if v_business_id is null then
    return jsonb_build_object('ok', false, 'code', 'not_found', 'message', 'Section not found');
  end if;

  if not (public.is_admin() or public.is_owner_of_business(v_business_id)) then
    return jsonb_build_object('ok', false, 'code', 'not_owner', 'message', 'Not owner');
  end if;

  v_name := nullif(trim(p_name), '');
  if v_name is null then
    return jsonb_build_object('ok', false, 'code', 'invalid', 'message', 'Name required');
  end if;

  if p_price_cents is not null and p_price_cents < 0 then
    return jsonb_build_object('ok', false, 'code', 'invalid', 'message', 'Invalid price');
  end if;

  v_desc := nullif(trim(p_description), '');
  v_currency := nullif(trim(p_currency), '');
  if v_currency is null then
    return jsonb_build_object('ok', false, 'code', 'invalid', 'message', 'Currency required');
  end if;

  insert into public.menu_items(
    section_id,
    business_id,
    name,
    description,
    price_cents,
    currency,
    catalog_item_id,
    status,
    created_by
  )
  values (
    p_section_id,
    v_business_id,
    v_name,
    v_desc,
    p_price_cents,
    v_currency,
    p_catalog_item_id,
    'draft',
    auth.uid()
  )
  returning id into v_item_id;

  if public.is_admin() then
    insert into public.admin_audit_log(action, target_table, target_id, meta)
    values (
      'menu_item.create',
      'menu_items',
      v_item_id,
      jsonb_build_object('menu_id', v_menu_id, 'section_id', p_section_id)
    );
  end if;

  return jsonb_build_object('ok', true, 'id', v_item_id, 'message', 'Created');
end;
$function$;

create function public.owner_update_menu_item_v1(
  p_item_id uuid,
  p_name text default null,
  p_description text default null,
  p_price_cents integer default null,
  p_currency text default null,
  p_catalog_item_id bigint default null
)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $function$
declare
  v_name text;
  v_desc text;
  v_currency text;
  v_business_id uuid;
  v_section_id uuid;
begin
  if auth.uid() is null then
    return jsonb_build_object('ok', false, 'code', 'not_authenticated', 'message', 'Auth required');
  end if;

  select business_id, section_id into v_business_id, v_section_id
  from public.menu_items
  where id = p_item_id;

  if v_business_id is null then
    return jsonb_build_object('ok', false, 'code', 'not_found', 'message', 'Item not found');
  end if;

  if not (public.is_admin() or public.is_owner_of_business(v_business_id)) then
    return jsonb_build_object('ok', false, 'code', 'not_owner', 'message', 'Not owner');
  end if;

  if p_price_cents is not null and p_price_cents < 0 then
    return jsonb_build_object('ok', false, 'code', 'invalid', 'message', 'Invalid price');
  end if;

  v_name := nullif(trim(p_name), '');
  v_desc := nullif(trim(p_description), '');
  v_currency := nullif(trim(p_currency), '');

  update public.menu_items
  set
    name = coalesce(v_name, name),
    description = coalesce(v_desc, description),
    price_cents = coalesce(p_price_cents, price_cents),
    currency = coalesce(v_currency, currency),
    catalog_item_id = coalesce(p_catalog_item_id, catalog_item_id),
    updated_at = now()
  where id = p_item_id;

  if public.is_admin() then
    insert into public.admin_audit_log(action, target_table, target_id, meta)
    values (
      'menu_item.update',
      'menu_items',
      p_item_id,
      jsonb_build_object('section_id', v_section_id)
    );
  end if;

  return jsonb_build_object('ok', true, 'id', p_item_id, 'message', 'Updated');
end;
$function$;

create function public.owner_archive_menu_item_v1(
  p_item_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $function$
declare
  v_business_id uuid;
  v_section_id uuid;
begin
  if auth.uid() is null then
    return jsonb_build_object('ok', false, 'code', 'not_authenticated', 'message', 'Auth required');
  end if;

  select business_id, section_id into v_business_id, v_section_id
  from public.menu_items
  where id = p_item_id;

  if v_business_id is null then
    return jsonb_build_object('ok', false, 'code', 'not_found', 'message', 'Item not found');
  end if;

  if not (public.is_admin() or public.is_owner_of_business(v_business_id)) then
    return jsonb_build_object('ok', false, 'code', 'not_owner', 'message', 'Not owner');
  end if;

  update public.menu_items
  set status = 'archived',
      updated_at = now()
  where id = p_item_id;

  if public.is_admin() then
    insert into public.admin_audit_log(action, target_table, target_id, meta)
    values (
      'menu_item.archive',
      'menu_items',
      p_item_id,
      jsonb_build_object('section_id', v_section_id)
    );
  end if;

  return jsonb_build_object('ok', true, 'id', p_item_id, 'message', 'Archived');
end;
$function$;

create function public.owner_publish_menu_item_v1(
  p_item_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $function$
declare
  v_business_id uuid;
  v_section_id uuid;
begin
  if auth.uid() is null then
    return jsonb_build_object('ok', false, 'code', 'not_authenticated', 'message', 'Auth required');
  end if;

  select business_id, section_id into v_business_id, v_section_id
  from public.menu_items
  where id = p_item_id;

  if v_business_id is null then
    return jsonb_build_object('ok', false, 'code', 'not_found', 'message', 'Item not found');
  end if;

  if not (public.is_admin() or public.is_owner_of_business(v_business_id)) then
    return jsonb_build_object('ok', false, 'code', 'not_owner', 'message', 'Not owner');
  end if;

  update public.menu_items
  set status = 'published',
      updated_at = now()
  where id = p_item_id;

  if public.is_admin() then
    insert into public.admin_audit_log(action, target_table, target_id, meta)
    values (
      'menu_item.publish',
      'menu_items',
      p_item_id,
      jsonb_build_object('section_id', v_section_id)
    );
  end if;

  return jsonb_build_object('ok', true, 'id', p_item_id, 'message', 'Published');
end;
$function$;

-- NOTE: menu_items tablosunda sort_order bulunmadığı için
-- owner_reorder_menu_items_v1 oluşturulmadı. Gerekirse schema'ya sort_order eklenmeli.

-- Smoke tests (örnek çağrılar)
-- select public.owner_create_menu_v1('00000000-0000-0000-0000-000000000000'::uuid, 'Öğle', null, null, null);
-- select public.owner_update_menu_v1('00000000-0000-0000-0000-000000000000'::uuid, 'Güncel', null, null, null);
-- select public.owner_archive_menu_v1('00000000-0000-0000-0000-000000000000'::uuid);
-- select public.owner_publish_menu_v1('00000000-0000-0000-0000-000000000000'::uuid);
-- select public.owner_create_menu_section_v1('00000000-0000-0000-0000-000000000000'::uuid, 'Ana yemekler', null);
-- select public.owner_update_menu_section_v1('00000000-0000-0000-0000-000000000000'::uuid, 'Başlangıçlar');
-- select public.owner_delete_menu_section_v1('00000000-0000-0000-0000-000000000000'::uuid, false);
-- select public.owner_reorder_menu_sections_v1('00000000-0000-0000-0000-000000000000'::uuid, array['00000000-0000-0000-0000-000000000000'::uuid]);
-- select public.owner_create_menu_item_v1('00000000-0000-0000-0000-000000000000'::uuid, 'Köfte', 'Not', 25000, 'TRY', null);
-- select public.owner_update_menu_item_v1('00000000-0000-0000-0000-000000000000'::uuid, 'Köfte', 'Not', 26000, 'TRY', null);
-- select public.owner_archive_menu_item_v1('00000000-0000-0000-0000-000000000000'::uuid);
-- select public.owner_publish_menu_item_v1('00000000-0000-0000-0000-000000000000'::uuid);





-- ===== END MIGRATION: 20260201_000001_owner_menu_crud.sql =====

-- ===== BEGIN MIGRATION: 20260202_000001_canonical_price_suggestion_rpcs.sql =====
create function public.admin_approve_price_suggestion_v1(
  p_suggestion_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $function$
begin
  return public.admin_approve_menu_price_suggestion_v1(p_suggestion_id);
end;
$function$;

create function public.admin_reject_price_suggestion_v1(
  p_suggestion_id uuid,
  p_reason text default null
)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $function$
declare
  v_reason text;
begin
  v_reason := nullif(trim(p_reason), '');

  return public.admin_reject_menu_price_suggestion_v1(p_suggestion_id, v_reason);
end;
$function$;

create function public.owner_list_price_suggestions_v1(
  p_business_id uuid,
  p_status text,
  p_limit integer,
  p_offset integer
)
returns table(
  suggestion_id uuid,
  status text,
  created_at timestamp with time zone,
  business_id uuid,
  business_name text,
  menu_item_id uuid,
  item_name text,
  current_price_cents integer,
  suggested_price_cents integer,
  currency text,
  created_by uuid
)
language plpgsql
security definer
set search_path to 'public'
as $function$
begin
  if to_regprocedure('public.get_owner_price_suggestions_v1(uuid,text,integer,integer)') is not null then
    return query
    select *
    from public.get_owner_price_suggestions_v1(
      p_business_id,
      p_status,
      p_limit,
      p_offset
    );
  else
    return query
    select
      l.suggestion_id,
      l.status,
      l.created_at,
      s.business_id,
      b.name as business_name,
      l.menu_item_id,
      l.item_name,
      l.current_price_cents,
      l.suggested_price_cents,
      l.currency,
      l.created_by
    from public.owner_list_menu_price_suggestions_v1(
      p_business_id,
      p_status,
      p_limit,
      p_offset
    ) l
    join public.menu_item_price_suggestions s on s.id = l.suggestion_id
    join public.businesses b on b.id = s.business_id;
  end if;
end;
$function$;

-- Mini doğrulama (örnek çağrılar)
-- select public.admin_approve_price_suggestion_v1('00000000-0000-0000-0000-000000000000'::uuid);
-- select public.admin_reject_price_suggestion_v1('00000000-0000-0000-0000-000000000000'::uuid, 'test');
-- select * from public.owner_list_price_suggestions_v1(null, 'pending', 10, 0);



-- ===== END MIGRATION: 20260202_000001_canonical_price_suggestion_rpcs.sql =====

-- ===== BEGIN MIGRATION: 20260203_000001_monetization_sponsorships.sql =====
create table public.sponsorship_packages (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  surface text not null
    check (surface in ('discovery','business_page','stories','verified','premium')),
  duration_days integer not null,
  price_display text not null,
  is_active boolean not null default true,
  created_at timestamp with time zone default now()
);

create table public.sponsorships (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses(id) on delete cascade,
  package_id uuid not null references public.sponsorship_packages(id),
  surface text not null
    check (surface in ('discovery','business_page','stories')),
  status text not null
    check (status in ('pending','active','paused','ended')) default 'pending',
  starts_at timestamp with time zone,
  ends_at timestamp with time zone,
  targeting jsonb not null default '{}'::jsonb,
  daily_cap integer,
  total_cap integer,
  source text not null default 'manual',
  created_by uuid references public.admin_users(user_id),
  created_at timestamp with time zone not null default now(),
  updated_at timestamp with time zone not null default now(),
  constraint sponsorships_ends_after_starts
    check (starts_at is null or ends_at is null or ends_at >= starts_at)
);

create index sponsorships_surface_status_dates_idx
  on public.sponsorships (surface, status, starts_at, ends_at);

create index sponsorships_targeting_gin_idx
  on public.sponsorships using gin (targeting);

create table public.sponsorship_impressions_daily (
  id uuid primary key default gen_random_uuid(),
  sponsorship_id uuid not null references public.sponsorships(id) on delete cascade,
  day date not null,
  impressions_count integer not null default 0,
  unique_users_count integer not null default 0,
  created_at timestamp with time zone not null default now(),
  updated_at timestamp with time zone not null default now(),
  unique (sponsorship_id, day)
);

alter table public.businesses
  add column if not exists is_verified boolean not null default false,
  add column if not exists verified_at timestamp with time zone,
  add column if not exists verified_by uuid;

do $$
begin
  if not exists (
    select 1
    from information_schema.table_constraints
    where constraint_schema = 'public'
      and table_name = 'businesses'
      and constraint_name = 'businesses_verified_by_fkey'
  ) then
    alter table public.businesses
      add constraint businesses_verified_by_fkey
      foreign key (verified_by) references public.admin_users(user_id);
  end if;
end $$;

create table public.business_premium (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses(id) on delete cascade,
  tier text not null check (tier in ('verified','premium')),
  status text not null
    check (status in ('active','paused','ended')) default 'active',
  starts_at timestamp with time zone not null default now(),
  ends_at timestamp with time zone,
  source text not null default 'manual',
  created_by uuid references public.admin_users(user_id),
  created_at timestamp with time zone not null default now()
);

create unique index business_premium_active_unique
  on public.business_premium (business_id, tier)
  where status = 'active';

create table public.sponsorship_leads (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses(id) on delete cascade,
  owner_user_id uuid not null,
  phone text,
  message text,
  preferred_surface text not null
    check (preferred_surface in ('discovery','business_page','stories','verified','premium')),
  preferred_targeting jsonb not null default '{}'::jsonb,
  status text not null
    check (status in ('new','contacted','closed')) default 'new',
  created_at timestamp with time zone not null default now()
);

alter table public.sponsorship_packages enable row level security;
alter table public.sponsorships enable row level security;
alter table public.sponsorship_impressions_daily enable row level security;
alter table public.business_premium enable row level security;
alter table public.sponsorship_leads enable row level security;

do $$
begin
  if not exists (
    select 1 from pg_policies
    where schemaname = 'public'
      and tablename = 'sponsorship_packages'
      and policyname = 'sponsorship_packages_admin_all'
  ) then
    execute 'create policy sponsorship_packages_admin_all on public.sponsorship_packages
      for all using (public.is_admin()) with check (public.is_admin())';
  end if;

  if not exists (
    select 1 from pg_policies
    where schemaname = 'public'
      and tablename = 'sponsorships'
      and policyname = 'sponsorships_admin_all'
  ) then
    execute 'create policy sponsorships_admin_all on public.sponsorships
      for all using (public.is_admin()) with check (public.is_admin())';
  end if;

  if not exists (
    select 1 from pg_policies
    where schemaname = 'public'
      and tablename = 'sponsorship_impressions_daily'
      and policyname = 'sponsorship_impressions_admin_all'
  ) then
    execute 'create policy sponsorship_impressions_admin_all on public.sponsorship_impressions_daily
      for all using (public.is_admin()) with check (public.is_admin())';
  end if;

  if not exists (
    select 1 from pg_policies
    where schemaname = 'public'
      and tablename = 'business_premium'
      and policyname = 'business_premium_admin_all'
  ) then
    execute 'create policy business_premium_admin_all on public.business_premium
      for all using (public.is_admin()) with check (public.is_admin())';
  end if;

  if not exists (
    select 1 from pg_policies
    where schemaname = 'public'
      and tablename = 'sponsorship_leads'
      and policyname = 'sponsorship_leads_admin_all'
  ) then
    execute 'create policy sponsorship_leads_admin_all on public.sponsorship_leads
      for all using (public.is_admin()) with check (public.is_admin())';
  end if;

  if not exists (
    select 1 from pg_policies
    where schemaname = 'public'
      and tablename = 'sponsorship_leads'
      and policyname = 'sponsorship_leads_owner_read'
  ) then
    execute 'create policy sponsorship_leads_owner_read on public.sponsorship_leads
      for select using (owner_user_id = auth.uid())';
  end if;

  if not exists (
    select 1 from pg_policies
    where schemaname = 'public'
      and tablename = 'sponsorship_leads'
      and policyname = 'sponsorship_leads_owner_insert'
  ) then
    execute 'create policy sponsorship_leads_owner_insert on public.sponsorship_leads
      for insert with check (owner_user_id = auth.uid())';
  end if;
end $$;

create or replace function public.get_sponsored_businesses_v1(
  p_surface text,
  p_city text default null,
  p_district text default null,
  p_category text default null,
  p_limit integer default 6
)
returns table(
  business_id uuid,
  sponsorship_id uuid,
  priority integer,
  starts_at timestamp with time zone,
  ends_at timestamp with time zone,
  business_name text,
  city text,
  district text,
  category text
)
language sql
stable
security definer
set search_path to 'public'
as $function$
  select
    s.business_id,
    s.id as sponsorship_id,
    0 as priority,
    s.starts_at,
    s.ends_at,
    b.name as business_name,
    b.city,
    b.district,
    b.category
  from public.sponsorships s
  join public.businesses b on b.id = s.business_id
  where s.status = 'active'
    and s.surface = p_surface
    and (s.starts_at is null or s.starts_at <= now())
    and (s.ends_at is null or s.ends_at >= now())
    and (
      not (s.targeting ? 'city')
      or jsonb_typeof(s.targeting->'city') <> 'array'
      or jsonb_array_length(s.targeting->'city') = 0
      or (
        p_city is not null
        and exists (
          select 1 from jsonb_array_elements_text(s.targeting->'city') v
          where v = p_city
        )
      )
    )
    and (
      not (s.targeting ? 'district')
      or jsonb_typeof(s.targeting->'district') <> 'array'
      or jsonb_array_length(s.targeting->'district') = 0
      or (
        p_district is not null
        and exists (
          select 1 from jsonb_array_elements_text(s.targeting->'district') v
          where v = p_district
        )
      )
    )
    and (
      not (s.targeting ? 'category')
      or jsonb_typeof(s.targeting->'category') <> 'array'
      or jsonb_array_length(s.targeting->'category') = 0
      or (
        p_category is not null
        and exists (
          select 1 from jsonb_array_elements_text(s.targeting->'category') v
          where v = p_category
        )
      )
    )
  order by s.created_at desc
  limit greatest(p_limit, 0);
$function$;

create or replace function public.submit_sponsorship_lead_v1(
  p_business_id uuid,
  p_phone text,
  p_message text,
  p_preferred_surface text,
  p_preferred_targeting jsonb default '{}'::jsonb
)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $function$
declare
  v_id uuid;
begin
  if auth.uid() is null then
    return jsonb_build_object('ok', false, 'code', 'not_authenticated', 'message', 'Auth required');
  end if;

  if not public.is_owner_of_business(p_business_id) then
    return jsonb_build_object('ok', false, 'code', 'not_owner', 'message', 'Not owner');
  end if;

  insert into public.sponsorship_leads(
    business_id,
    owner_user_id,
    phone,
    message,
    preferred_surface,
    preferred_targeting
  )
  values (
    p_business_id,
    auth.uid(),
    nullif(trim(p_phone), ''),
    nullif(trim(p_message), ''),
    p_preferred_surface,
    coalesce(p_preferred_targeting, '{}'::jsonb)
  )
  returning id into v_id;

  return jsonb_build_object('ok', true, 'id', v_id, 'message', 'Submitted');
end;
$function$;

create or replace function public.admin_upsert_sponsorship_package_v1(
  p_id uuid default null,
  p_name text default null,
  p_surface text default null,
  p_duration_days integer default null,
  p_price_display text default null,
  p_is_active boolean default true
)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $function$
declare
  v_id uuid;
begin
  if not public.is_admin() then
    return jsonb_build_object('ok', false, 'code', 'not_admin', 'message', 'Not admin');
  end if;

  if p_id is null then
    insert into public.sponsorship_packages(
      name, surface, duration_days, price_display, is_active
    )
    values (
      p_name, p_surface, p_duration_days, p_price_display, p_is_active
    )
    returning id into v_id;
  else
    update public.sponsorship_packages
    set
      name = p_name,
      surface = p_surface,
      duration_days = p_duration_days,
      price_display = p_price_display,
      is_active = p_is_active
    where id = p_id
    returning id into v_id;
  end if;

  return jsonb_build_object('ok', true, 'id', v_id);
end;
$function$;

create or replace function public.admin_create_sponsorship_v1(
  p_business_id uuid,
  p_package_id uuid,
  p_surface text,
  p_starts_at timestamp with time zone default null,
  p_ends_at timestamp with time zone default null,
  p_targeting jsonb default '{}'::jsonb,
  p_daily_cap integer default null,
  p_total_cap integer default null
)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $function$
declare
  v_id uuid;
begin
  if not public.is_admin() then
    return jsonb_build_object('ok', false, 'code', 'not_admin', 'message', 'Not admin');
  end if;

  if p_starts_at is not null and p_ends_at is not null and p_ends_at < p_starts_at then
    return jsonb_build_object('ok', false, 'code', 'invalid', 'message', 'Invalid date range');
  end if;

  insert into public.sponsorships(
    business_id,
    package_id,
    surface,
    starts_at,
    ends_at,
    targeting,
    daily_cap,
    total_cap,
    source,
    created_by
  )
  values (
    p_business_id,
    p_package_id,
    p_surface,
    p_starts_at,
    p_ends_at,
    coalesce(p_targeting, '{}'::jsonb),
    p_daily_cap,
    p_total_cap,
    'manual',
    auth.uid()
  )
  returning id into v_id;

  return jsonb_build_object('ok', true, 'id', v_id);
end;
$function$;

create or replace function public.admin_set_sponsorship_status_v1(
  p_sponsorship_id uuid,
  p_status text
)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $function$
begin
  if not public.is_admin() then
    return jsonb_build_object('ok', false, 'code', 'not_admin', 'message', 'Not admin');
  end if;

  update public.sponsorships
  set status = p_status,
      updated_at = now()
  where id = p_sponsorship_id;

  return jsonb_build_object('ok', true, 'id', p_sponsorship_id);
end;
$function$;

create or replace function public.admin_list_sponsorships_v1(
  p_status text default null,
  p_surface text default null,
  p_limit integer default 50,
  p_offset integer default 0
)
returns table(
  sponsorship_id uuid,
  status text,
  surface text,
  created_at timestamp with time zone,
  business_id uuid,
  business_name text,
  city text,
  district text,
  package_id uuid,
  starts_at timestamp with time zone,
  ends_at timestamp with time zone,
  daily_cap integer,
  total_cap integer,
  source text,
  created_by uuid
)
language sql
stable
security definer
set search_path to 'public'
as $function$
  select
    s.id as sponsorship_id,
    s.status::text,
    s.surface::text,
    s.created_at,
    b.id as business_id,
    b.name as business_name,
    b.city,
    b.district,
    s.package_id,
    s.starts_at,
    s.ends_at,
    s.daily_cap,
    s.total_cap,
    s.source,
    s.created_by
  from public.sponsorships s
  join public.businesses b on b.id = s.business_id
  where public.is_admin()
    and (p_status is null or p_status = '' or s.status::text = p_status)
    and (p_surface is null or p_surface = '' or s.surface::text = p_surface)
  order by s.created_at desc
  limit greatest(p_limit, 0) offset greatest(p_offset, 0);
$function$;

create or replace function public.admin_list_sponsorship_leads_v1(
  p_status text default null,
  p_limit integer default 50,
  p_offset integer default 0
)
returns table(
  lead_id uuid,
  status text,
  created_at timestamp with time zone,
  business_id uuid,
  business_name text,
  city text,
  district text,
  owner_user_id uuid,
  phone text,
  message text,
  preferred_surface text,
  preferred_targeting jsonb
)
language sql
stable
security definer
set search_path to 'public'
as $function$
  select
    l.id as lead_id,
    l.status::text,
    l.created_at,
    b.id as business_id,
    b.name as business_name,
    b.city,
    b.district,
    l.owner_user_id,
    l.phone,
    l.message,
    l.preferred_surface::text,
    l.preferred_targeting
  from public.sponsorship_leads l
  join public.businesses b on b.id = l.business_id
  where public.is_admin()
    and (p_status is null or p_status = '' or l.status::text = p_status)
  order by l.created_at desc
  limit greatest(p_limit, 0) offset greatest(p_offset, 0);
$function$;

create or replace function public.admin_update_sponsorship_lead_status_v1(
  p_id uuid,
  p_status text
)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $function$
begin
  if not public.is_admin() then
    return jsonb_build_object('ok', false, 'code', 'not_admin', 'message', 'Not admin');
  end if;

  update public.sponsorship_leads
  set status = p_status
  where id = p_id;

  return jsonb_build_object('ok', true, 'id', p_id);
end;
$function$;

create or replace function public.admin_set_business_verified_v1(
  p_business_id uuid,
  p_is_verified boolean,
  p_tier text default 'verified',
  p_ends_at timestamp with time zone default null
)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $function$
declare
  v_id uuid;
begin
  if not public.is_admin() then
    return jsonb_build_object('ok', false, 'code', 'not_admin', 'message', 'Not admin');
  end if;

  update public.businesses
  set
    is_verified = p_is_verified,
    verified_at = case when p_is_verified then now() else null end,
    verified_by = case when p_is_verified then auth.uid() else null end
  where id = p_business_id;

  if p_is_verified then
    insert into public.business_premium(
      business_id, tier, status, starts_at, ends_at, source, created_by
    )
    values (
      p_business_id, p_tier, 'active', now(), p_ends_at, 'manual', auth.uid()
    )
    on conflict (business_id, tier) where status = 'active'
    do update set
      ends_at = excluded.ends_at,
      status = 'active';
  else
    update public.business_premium
    set status = 'ended',
        ends_at = coalesce(p_ends_at, now())
    where business_id = p_business_id
      and tier = p_tier
      and status = 'active';
  end if;

  select id into v_id
  from public.business_premium
  where business_id = p_business_id
    and tier = p_tier
  order by created_at desc
  limit 1;

  return jsonb_build_object('ok', true, 'business_id', p_business_id, 'premium_id', v_id);
end;
$function$;

-- ===== END MIGRATION: 20260203_000001_monetization_sponsorships.sql =====

-- ===== BEGIN MIGRATION: 20260204_000001_business_amenities.sql =====
create table public.business_amenities (
  id uuid primary key default gen_random_uuid(),
  key text not null unique,
  label text not null,
  icon text not null,
  created_at timestamp with time zone default now()
);

insert into public.business_amenities (key, label, icon)
values
  ('parking', 'Otopark', 'parking'),
  ('kids_area', 'Çocuk Alanı', 'kids_area'),
  ('wifi', 'Wi‑Fi', 'wifi'),
  ('pet_friendly', 'Pet Friendly', 'pet_friendly'),
  ('smoking_area', 'Sigara Alanı', 'smoking_area'),
  ('outdoor_seating', 'Dış Mekan', 'outdoor_seating'),
  ('alcohol', 'Alkol', 'alcohol')
on conflict (key) do nothing;

create table public.business_amenity_map (
  business_id uuid references public.businesses(id) on delete cascade,
  amenity_id uuid references public.business_amenities(id) on delete cascade,
  primary key (business_id, amenity_id)
);

alter table public.business_amenities enable row level security;
alter table public.business_amenity_map enable row level security;

do $$
begin
  if not exists (
    select 1 from pg_policies
    where schemaname = 'public'
      and tablename = 'business_amenities'
      and policyname = 'business_amenities_read_all'
  ) then
    execute 'create policy business_amenities_read_all on public.business_amenities
      for select using (true)';
  end if;

  if not exists (
    select 1 from pg_policies
    where schemaname = 'public'
      and tablename = 'business_amenities'
      and policyname = 'business_amenities_write_owner_admin'
  ) then
    execute 'create policy business_amenities_write_owner_admin on public.business_amenities
      for all
      using (public.is_admin())
      with check (public.is_admin())';
  end if;

  if not exists (
    select 1 from pg_policies
    where schemaname = 'public'
      and tablename = 'business_amenity_map'
      and policyname = 'business_amenity_map_read_all'
  ) then
    execute 'create policy business_amenity_map_read_all on public.business_amenity_map
      for select using (true)';
  end if;

  if not exists (
    select 1 from pg_policies
    where schemaname = 'public'
      and tablename = 'business_amenity_map'
      and policyname = 'business_amenity_map_write_owner_admin'
  ) then
    execute 'create policy business_amenity_map_write_owner_admin on public.business_amenity_map
      for all
      using (public.is_admin() or public.is_owner_of_business(business_id))
      with check (public.is_admin() or public.is_owner_of_business(business_id))';
  end if;
end $$;

create or replace function public.get_business_amenities_v1(
  p_business_id uuid
)
returns table(
  amenity_id uuid,
  key text,
  label text,
  icon text
)
language sql
stable
security definer
set search_path to 'public'
as $function$
  select
    a.id as amenity_id,
    a.key,
    a.label,
    a.icon
  from public.business_amenity_map m
  join public.business_amenities a on a.id = m.amenity_id
  where m.business_id = p_business_id
  order by a.label asc;
$function$;

create or replace function public.owner_update_business_amenities_v1(
  p_business_id uuid,
  p_amenity_keys text[]
)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $function$
begin
  if auth.uid() is null then
    return jsonb_build_object('ok', false, 'code', 'not_authenticated', 'message', 'Auth required');
  end if;

  if not (public.is_admin() or public.is_owner_of_business(p_business_id)) then
    return jsonb_build_object('ok', false, 'code', 'not_owner', 'message', 'Not owner');
  end if;

  delete from public.business_amenity_map
  where business_id = p_business_id;

  if p_amenity_keys is not null and array_length(p_amenity_keys, 1) is not null then
    insert into public.business_amenity_map (business_id, amenity_id)
    select p_business_id, a.id
    from public.business_amenities a
    where a.key = any(p_amenity_keys);
  end if;

  return jsonb_build_object('ok', true, 'business_id', p_business_id);
end;
$function$;

-- ===== END MIGRATION: 20260204_000001_business_amenities.sql =====

-- ===== BEGIN MIGRATION: 20260205_000001_menu_share_and_aliases.sql =====
create or replace function public.owner_delete_menu_v1(
  p_menu_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $function$
begin
  return public.owner_archive_menu_v1(p_menu_id);
end;
$function$;

create or replace function public.owner_delete_menu_item_v1(
  p_item_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $function$
begin
  return public.owner_archive_menu_item_v1(p_item_id);
end;
$function$;

create or replace function public.public_menu_share_view_v1(
  p_menu_id uuid
)
returns jsonb
language sql
stable
security definer
set search_path to 'public'
as $function$
  with menu_base as (
    select
      m.id,
      m.business_id,
      m.title,
      m.kind,
      m.status,
      m.active_from,
      m.active_to,
      m.created_at,
      m.updated_at
    from public.menus m
    where m.id = p_menu_id
      and m.status = 'published'
  ),
  sections as (
    select
      s.id,
      s.menu_id,
      s.title,
      s.sort_order
    from public.menu_sections s
    join menu_base m on m.id = s.menu_id
    order by s.sort_order asc, s.created_at asc
  ),
  items as (
    select
      i.id,
      i.section_id,
      i.business_id,
      i.name,
      i.description,
      i.price_cents,
      i.currency,
      i.calories,
      i.is_vegan,
      i.is_vegetarian,
      i.is_gluten_free,
      i.is_lactose_free,
      i.is_halal,
      i.status,
      i.catalog_item_id
    from public.menu_items i
    join sections s on s.id = i.section_id
    where i.status = 'published'
    order by i.created_at asc
  )
  select jsonb_build_object(
    'menu', (select to_jsonb(m) from menu_base m),
    'sections', coalesce((
      select jsonb_agg(
        jsonb_build_object(
          'id', s.id,
          'title', s.title,
          'sort_order', s.sort_order,
          'items', coalesce((
            select jsonb_agg(to_jsonb(i))
            from items i
            where i.section_id = s.id
          ), '[]'::jsonb)
        )
      )
      from sections s
    ), '[]'::jsonb)
  );
$function$;

-- ===== END MIGRATION: 20260205_000001_menu_share_and_aliases.sql =====

-- ===== BEGIN MIGRATION: 20260206_000001_business_activity_log.sql =====
create table if not exists public.business_activity_log (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses(id) on delete cascade,
  type text not null check (type in ('menu_update')),
  meta jsonb not null default '{}'::jsonb,
  created_at timestamp with time zone not null default now()
);

create index if not exists business_activity_log_business_id_idx
  on public.business_activity_log (business_id, created_at desc);

create or replace function public.log_menu_activity_v1(
  p_business_id uuid,
  p_event text,
  p_meta jsonb default '{}'::jsonb
)
returns void
language plpgsql
security definer
set search_path to 'public'
as $function$
begin
  insert into public.business_activity_log (business_id, type, meta)
  values (p_business_id, 'menu_update', jsonb_build_object('event', p_event) || coalesce(p_meta, '{}'::jsonb));
end;
$function$;

create or replace function public.trg_log_menu_section_activity()
returns trigger
language plpgsql
security definer
set search_path to 'public'
as $function$
declare
  v_business_id uuid;
  v_meta jsonb;
begin
  if tg_op = 'INSERT' then
    select m.business_id into v_business_id from public.menus m where m.id = new.menu_id;
    v_meta := jsonb_build_object('section_id', new.id, 'menu_id', new.menu_id);
    perform public.log_menu_activity_v1(v_business_id, 'section_insert', v_meta);
    return new;
  elsif tg_op = 'UPDATE' then
    select m.business_id into v_business_id from public.menus m where m.id = new.menu_id;
    v_meta := jsonb_build_object('section_id', new.id, 'menu_id', new.menu_id);
    perform public.log_menu_activity_v1(v_business_id, 'section_update', v_meta);
    return new;
  elsif tg_op = 'DELETE' then
    select m.business_id into v_business_id from public.menus m where m.id = old.menu_id;
    v_meta := jsonb_build_object('section_id', old.id, 'menu_id', old.menu_id);
    perform public.log_menu_activity_v1(v_business_id, 'section_delete', v_meta);
    return old;
  end if;
  return null;
end;
$function$;

create or replace function public.trg_log_menu_item_activity()
returns trigger
language plpgsql
security definer
set search_path to 'public'
as $function$
declare
  v_business_id uuid;
  v_meta jsonb;
begin
  if tg_op = 'INSERT' then
    v_business_id := new.business_id;
    v_meta := jsonb_build_object('item_id', new.id, 'section_id', new.section_id, 'menu_id', null);
    perform public.log_menu_activity_v1(v_business_id, 'item_insert', v_meta);
    return new;
  elsif tg_op = 'UPDATE' then
    v_business_id := new.business_id;
    v_meta := jsonb_build_object('item_id', new.id, 'section_id', new.section_id, 'menu_id', null);
    perform public.log_menu_activity_v1(v_business_id, 'item_update', v_meta);
    return new;
  elsif tg_op = 'DELETE' then
    v_business_id := old.business_id;
    v_meta := jsonb_build_object('item_id', old.id, 'section_id', old.section_id, 'menu_id', null);
    perform public.log_menu_activity_v1(v_business_id, 'item_delete', v_meta);
    return old;
  end if;
  return null;
end;
$function$;

do $$
begin
  if not exists (
    select 1 from pg_trigger where tgname = 'menu_sections_activity_log_trg'
  ) then
    create trigger menu_sections_activity_log_trg
      after insert or update or delete on public.menu_sections
      for each row execute function public.trg_log_menu_section_activity();
  end if;

  if not exists (
    select 1 from pg_trigger where tgname = 'menu_items_activity_log_trg'
  ) then
    create trigger menu_items_activity_log_trg
      after insert or update or delete on public.menu_items
      for each row execute function public.trg_log_menu_item_activity();
  end if;
end $$;

create or replace function public.get_business_activity_v1(
  p_business_id uuid,
  p_limit integer default 10
)
returns table(
  activity_id uuid,
  activity_type text,
  meta jsonb,
  created_at timestamp with time zone
)
language sql
stable
security definer
set search_path to 'public'
as $function$
  select
    a.id as activity_id,
    a.type as activity_type,
    a.meta,
    a.created_at
  from public.business_activity_log a
  where a.business_id = p_business_id
  order by a.created_at desc
  limit greatest(p_limit, 0);
$function$;

alter table public.business_activity_log enable row level security;

do $$
begin
  if not exists (
    select 1 from pg_policies
    where schemaname = 'public'
      and tablename = 'business_activity_log'
      and policyname = 'business_activity_read_all'
  ) then
    execute 'create policy business_activity_read_all on public.business_activity_log
      for select using (true)';
  end if;
end $$;

-- ===== END MIGRATION: 20260206_000001_business_activity_log.sql =====

-- ===== BEGIN MIGRATION: 20260207_000001_amenities_mvp_update.sql =====
insert into public.business_amenities (key, label, icon)
values
  ('delivery', 'Paket Servis', 'delivery'),
  ('takeaway', 'Gel Al', 'takeaway')
on conflict (key) do nothing;

drop function if exists public.get_business_amenities_v1(uuid);

create or replace function public.get_business_amenities_v1(
  p_business_id uuid
)
returns table(
  key text,
  label text,
  icon text
)
language sql
stable
security definer
set search_path to 'public'
as $function$
  select
    a.key,
    a.label,
    a.icon
  from public.business_amenity_map m
  join public.business_amenities a on a.id = m.amenity_id
  where m.business_id = p_business_id
  order by a.label asc;
$function$;

-- ===== END MIGRATION: 20260207_000001_amenities_mvp_update.sql =====

-- ===== BEGIN MIGRATION: 20260208_000001_public_menu_share_view.sql =====
create or replace function public.public_menu_share_view_v1(
  p_menu_id uuid
)
returns jsonb
language plpgsql
stable
security definer
set search_path to 'public'
as $function$
declare
  v_status text;
  v_menu jsonb;
  v_business jsonb;
  v_sections jsonb;
begin
  select m.status
    into v_status
  from public.menus m
  where m.id = p_menu_id;

  if v_status is null then
    return jsonb_build_object('ok', false);
  end if;

  if v_status = 'archived' then
    return jsonb_build_object('ok', false);
  end if;

  if v_status <> 'published' then
    return jsonb_build_object('ok', false);
  end if;

  select to_jsonb(m)
    into v_menu
  from (
    select
      m.id,
      m.business_id,
      m.title,
      m.kind,
      m.status,
      m.active_from,
      m.active_to,
      m.created_at,
      m.updated_at
    from public.menus m
    where m.id = p_menu_id
  ) m;

  select to_jsonb(b)
    into v_business
  from (
    select
      b.id,
      b.name,
      b.logo_url
    from public.businesses b
    join public.menus m on m.business_id = b.id
    where m.id = p_menu_id
  ) b;

  with sections as (
    select
      s.id,
      s.menu_id,
      s.title,
      s.sort_order
    from public.menu_sections s
    where s.menu_id = p_menu_id
    order by s.sort_order asc, s.created_at asc
  ),
  items as (
    select
      i.id,
      i.section_id,
      i.business_id,
      i.name,
      i.description,
      i.price_cents,
      i.currency,
      i.calories,
      i.is_vegan,
      i.is_vegetarian,
      i.is_gluten_free,
      i.is_lactose_free,
      i.is_halal,
      i.status,
      i.catalog_item_id
    from public.menu_items i
    join sections s on s.id = i.section_id
    where i.status = 'published'
    order by i.created_at asc
  )
  select coalesce(
    jsonb_agg(
      jsonb_build_object(
        'id', s.id,
        'title', s.title,
        'sort_order', s.sort_order,
        'items', coalesce((
          select jsonb_agg(to_jsonb(i))
          from items i
          where i.section_id = s.id
        ), '[]'::jsonb)
      )
    ),
    '[]'::jsonb
  )
  into v_sections
  from sections s;

  return jsonb_build_object(
    'ok', true,
    'menu', v_menu,
    'business', v_business,
    'sections', v_sections
  );
end;
$function$;

-- ===== END MIGRATION: 20260208_000001_public_menu_share_view.sql =====

-- ===== BEGIN MIGRATION: 20260209_000001_owner_onboarding_progress.sql =====
create table if not exists public.owner_onboarding_progress (
  business_id uuid primary key references public.businesses(id) on delete cascade,
  step_completed int not null default 0,
  updated_at timestamptz not null default now(),
  check (step_completed >= 0 and step_completed <= 5)
);

alter table public.owner_onboarding_progress enable row level security;

-- Ensure owners/admins can read/write onboarding progress
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'owner_onboarding_progress'
      AND policyname = 'owner_onboarding_progress_owner_read'
  ) THEN
    EXECUTE 'CREATE POLICY owner_onboarding_progress_owner_read ON public.owner_onboarding_progress
      FOR SELECT USING (public.is_admin() OR public.is_owner_of_business(business_id))';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'owner_onboarding_progress'
      AND policyname = 'owner_onboarding_progress_owner_write'
  ) THEN
    EXECUTE 'CREATE POLICY owner_onboarding_progress_owner_write ON public.owner_onboarding_progress
      FOR INSERT WITH CHECK (public.is_admin() OR public.is_owner_of_business(business_id))';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'owner_onboarding_progress'
      AND policyname = 'owner_onboarding_progress_owner_update'
  ) THEN
    EXECUTE 'CREATE POLICY owner_onboarding_progress_owner_update ON public.owner_onboarding_progress
      FOR UPDATE USING (public.is_admin() OR public.is_owner_of_business(business_id))
      WITH CHECK (public.is_admin() OR public.is_owner_of_business(business_id))';
  END IF;
END $$;

-- Business hours RLS for owners/admins (if missing)
ALTER TABLE public.business_hours ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'business_hours'
      AND policyname = 'business_hours_owner_read'
  ) THEN
    EXECUTE 'CREATE POLICY business_hours_owner_read ON public.business_hours
      FOR SELECT USING (public.is_admin() OR public.is_owner_of_business(business_id))';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'business_hours'
      AND policyname = 'business_hours_owner_write'
  ) THEN
    EXECUTE 'CREATE POLICY business_hours_owner_write ON public.business_hours
      FOR INSERT WITH CHECK (public.is_admin() OR public.is_owner_of_business(business_id))';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'business_hours'
      AND policyname = 'business_hours_owner_update'
  ) THEN
    EXECUTE 'CREATE POLICY business_hours_owner_update ON public.business_hours
      FOR UPDATE USING (public.is_admin() OR public.is_owner_of_business(business_id))
      WITH CHECK (public.is_admin() OR public.is_owner_of_business(business_id))';
  END IF;
END $$;

create or replace function public.get_owner_onboarding_progress_v1(
  p_business_id uuid
)
returns table(step_completed int, updated_at timestamptz)
language sql
stable
security definer
set search_path to 'public'
as $function$
  select p.step_completed, p.updated_at
  from public.owner_onboarding_progress p
  where p.business_id = p_business_id
    and (public.is_admin() or public.is_owner_of_business(p_business_id));
$function$;

create or replace function public.owner_set_onboarding_progress_v1(
  p_business_id uuid,
  p_step_completed int
)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $function$
declare
  v_step int;
begin
  if not (public.is_admin() or public.is_owner_of_business(p_business_id)) then
    return jsonb_build_object('ok', false, 'code', 'not_owner', 'message', 'Not owner');
  end if;

  v_step := least(greatest(coalesce(p_step_completed, 0), 0), 5);

  insert into public.owner_onboarding_progress(business_id, step_completed, updated_at)
  values (p_business_id, v_step, now())
  on conflict (business_id) do update
    set step_completed = greatest(owner_onboarding_progress.step_completed, excluded.step_completed),
        updated_at = now();

  return jsonb_build_object('ok', true, 'step_completed', v_step);
end;
$function$;

create or replace function public.owner_update_business_profile_v1(
  p_business_id uuid,
  p_logo_url text default null,
  p_cover_url text default null
)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $function$
begin
  if not (public.is_admin() or public.is_owner_of_business(p_business_id)) then
    return jsonb_build_object('ok', false, 'code', 'not_owner', 'message', 'Not owner');
  end if;

  update public.businesses
  set
    logo_url = nullif(trim(p_logo_url), ''),
    cover_url = nullif(trim(p_cover_url), '')
  where id = p_business_id;

  return jsonb_build_object('ok', true);
end;
$function$;

create or replace function public.owner_upsert_business_hours_v1(
  p_business_id uuid,
  p_open time,
  p_close time
)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $function$
begin
  if not (public.is_admin() or public.is_owner_of_business(p_business_id)) then
    return jsonb_build_object('ok', false, 'code', 'not_owner', 'message', 'Not owner');
  end if;

  if p_open is null or p_close is null then
    return jsonb_build_object('ok', false, 'code', 'invalid', 'message', 'Hours required');
  end if;

  insert into public.business_hours(
    business_id,
    mon_open, mon_close,
    tue_open, tue_close,
    wed_open, wed_close,
    thu_open, thu_close,
    fri_open, fri_close,
    sat_open, sat_close,
    sun_open, sun_close,
    updated_at
  )
  values (
    p_business_id,
    p_open, p_close,
    p_open, p_close,
    p_open, p_close,
    p_open, p_close,
    p_open, p_close,
    p_open, p_close,
    p_open, p_close,
    now()
  )
  on conflict (business_id) do update
    set
      mon_open = excluded.mon_open,
      mon_close = excluded.mon_close,
      tue_open = excluded.tue_open,
      tue_close = excluded.tue_close,
      wed_open = excluded.wed_open,
      wed_close = excluded.wed_close,
      thu_open = excluded.thu_open,
      thu_close = excluded.thu_close,
      fri_open = excluded.fri_open,
      fri_close = excluded.fri_close,
      sat_open = excluded.sat_open,
      sat_close = excluded.sat_close,
      sun_open = excluded.sun_open,
      sun_close = excluded.sun_close,
      updated_at = now();

  return jsonb_build_object('ok', true);
end;
$function$;

-- ===== END MIGRATION: 20260209_000001_owner_onboarding_progress.sql =====

-- ===== BEGIN MIGRATION: 20260210_000001_business_profile_score.sql =====
create or replace function public.get_business_profile_score_v1(
  p_business_id uuid
)
returns jsonb
language plpgsql
stable
security definer
set search_path to 'public'
as $function$
declare
  v_menu_exists boolean;
  v_amenities_count int;
  v_media_count int;
  v_recent_update boolean;
  v_score int := 0;
  v_breakdown jsonb;
begin
  if not (public.is_admin() or public.is_owner_of_business(p_business_id)) then
    return jsonb_build_object(
      'score', 0,
      'breakdown', jsonb_build_object('error', 'not_owner')
    );
  end if;

  select exists(
    select 1 from public.menus m
    where m.business_id = p_business_id
  ) into v_menu_exists;

  select count(*)
    into v_amenities_count
  from public.business_amenity_map bam
  where bam.business_id = p_business_id;

  select count(*)
    into v_media_count
  from public.business_media bm
  where bm.business_id = p_business_id;

  select exists(
    select 1
    from public.business_activity_log l
    where l.business_id = p_business_id
      and l.type = 'menu_update'
      and l.created_at >= now() - interval '7 days'
  ) into v_recent_update;

  if v_menu_exists then v_score := v_score + 40; end if;
  if v_amenities_count >= 2 then v_score := v_score + 20; end if;
  if v_media_count >= 3 then v_score := v_score + 20; end if;
  if v_recent_update then v_score := v_score + 20; end if;

  v_breakdown := jsonb_build_object(
    'menu', v_menu_exists,
    'amenities', v_amenities_count,
    'photos', v_media_count,
    'recent_update', v_recent_update
  );

  return jsonb_build_object(
    'score', v_score,
    'breakdown', v_breakdown
  );
end;
$function$;

-- ===== END MIGRATION: 20260210_000001_business_profile_score.sql =====

-- ===== BEGIN MIGRATION: 20260211_000001_analytics_events.sql =====
create table if not exists public.analytics_events (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz default now(),
  event_name text not null,
  business_id uuid null references public.businesses(id) on delete set null,
  menu_id uuid null references public.menus(id) on delete set null,
  source text null,
  client_id text null,
  user_id uuid null,
  meta jsonb not null default '{}'::jsonb
);

alter table public.analytics_events
  add constraint analytics_events_event_name_check
  check (event_name in ('menu_shared','qr_scanned','menu_link_opened','app_install_from_menu'));

create index if not exists analytics_events_event_name_created_at_idx
  on public.analytics_events (event_name, created_at desc);
create index if not exists analytics_events_business_created_at_idx
  on public.analytics_events (business_id, created_at desc);
create index if not exists analytics_events_menu_created_at_idx
  on public.analytics_events (menu_id, created_at desc);
create index if not exists analytics_events_client_created_at_idx
  on public.analytics_events (client_id, created_at desc);

alter table public.analytics_events enable row level security;

create or replace function public.log_event_v1(
  p_event_name text,
  p_business_id uuid default null,
  p_menu_id uuid default null,
  p_source text default null,
  p_client_id text default null,
  p_meta jsonb default '{}'::jsonb
) returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $function$
declare
  v_event_name text := coalesce(trim(p_event_name), '');
  v_client text := nullif(trim(p_client_id), '');
  v_key text;
  v_today date := current_date;
  v_current_count int;
  v_user_id uuid := coalesce(auth.uid(), '00000000-0000-0000-0000-000000000000'::uuid);
begin
  if v_event_name not in (
    'menu_shared',
    'qr_scanned',
    'menu_link_opened',
    'app_install_from_menu'
  ) then
    return jsonb_build_object('ok', false, 'code', 'invalid_event');
  end if;

  if v_event_name = 'menu_link_opened' and v_client is null then
    return jsonb_build_object('ok', false, 'code', 'client_required');
  end if;

  if v_event_name = 'menu_link_opened' then
    v_key := format('menu_link_opened:%s:%s', v_client, v_today::text);
    select count into v_current_count
    from public.user_rate_limits
    where key = v_key;

    if coalesce(v_current_count, 0) >= 200 then
      return jsonb_build_object('ok', false, 'code', 'rate_limited');
    end if;

    insert into public.user_rate_limits (key, user_id, action, day, count, updated_at)
    values (v_key, v_user_id, 'menu_link_opened', v_today, 1, now())
    on conflict (key) do update
      set count = public.user_rate_limits.count + 1,
          updated_at = now();
  end if;

  insert into public.analytics_events (
    event_name,
    business_id,
    menu_id,
    source,
    client_id,
    user_id,
    meta
  ) values (
    v_event_name,
    p_business_id,
    p_menu_id,
    p_source,
    v_client,
    auth.uid(),
    coalesce(p_meta, '{}'::jsonb)
  );

  return jsonb_build_object('ok', true);
end;
$function$;

create or replace function public.analytics_growth_v1(
  p_days int default 30,
  p_business_id uuid default null
) returns table(
  day date,
  menu_link_opened int,
  qr_scanned int,
  menu_shared int,
  app_install_from_menu int
)
language plpgsql
security definer
set search_path to 'public'
as $function$
begin
  if not public.is_admin() then
    raise exception 'not authorized';
  end if;

  return query
  select
    d.day::date,
    sum(case when e.event_name = 'menu_link_opened' then 1 else 0 end)::int as menu_link_opened,
    sum(case when e.event_name = 'qr_scanned' then 1 else 0 end)::int as qr_scanned,
    sum(case when e.event_name = 'menu_shared' then 1 else 0 end)::int as menu_shared,
    sum(case when e.event_name = 'app_install_from_menu' then 1 else 0 end)::int as app_install_from_menu
  from generate_series(
    (current_date - greatest(p_days, 1) + 1)::date,
    current_date::date,
    interval '1 day'
  ) as d(day)
  left join public.analytics_events e
    on date_trunc('day', e.created_at) = d.day
   and (p_business_id is null or e.business_id = p_business_id)
  group by d.day
  order by d.day;
end;
$function$;

-- ===== END MIGRATION: 20260211_000001_analytics_events.sql =====

-- ===== BEGIN MIGRATION: 20260212_000001_business_follows_feed.sql =====
create table if not exists public.business_follows (
  user_id uuid not null,
  business_id uuid not null references public.businesses(id) on delete cascade,
  created_at timestamptz default now(),
  primary key (user_id, business_id)
);

create table if not exists public.feed_events (
  id uuid primary key default gen_random_uuid(),
  business_id uuid references public.businesses(id) on delete set null,
  type text not null,
  ref_id uuid null,
  meta jsonb default '{}'::jsonb,
  created_at timestamptz default now()
);

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'feed_events_type_check'
      and conrelid = 'public.feed_events'::regclass
  ) then
    alter table public.feed_events
      add constraint feed_events_type_check
      check (type in ('menu_update','story_posted','price_verified','sponsored'));
  end if;
end $$;

create index if not exists feed_events_business_created_at_idx
  on public.feed_events (business_id, created_at desc);

create or replace function public.follow_business_v1(
  p_business_id uuid
) returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $function$
declare
  v_user_id uuid := auth.uid();
begin
  if v_user_id is null then
    return jsonb_build_object('ok', false, 'code', 'not_authenticated');
  end if;

  insert into public.business_follows (user_id, business_id)
  values (v_user_id, p_business_id)
  on conflict do nothing;

  return jsonb_build_object('ok', true);
end;
$function$;

create or replace function public.unfollow_business_v1(
  p_business_id uuid
) returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $function$
declare
  v_user_id uuid := auth.uid();
begin
  if v_user_id is null then
    return jsonb_build_object('ok', false, 'code', 'not_authenticated');
  end if;

  delete from public.business_follows
  where user_id = v_user_id
    and business_id = p_business_id;

  return jsonb_build_object('ok', true);
end;
$function$;

create or replace function public.get_my_feed_v1(
  p_limit int,
  p_offset int
) returns table(
  event_id uuid,
  business_id uuid,
  type text,
  ref_id uuid,
  meta jsonb,
  created_at timestamptz
)
language plpgsql
security definer
set search_path to 'public'
as $function$
declare
  v_user_id uuid := auth.uid();
begin
  if v_user_id is null then
    return;
  end if;

  return query
  select
    e.id as event_id,
    e.business_id,
    e.type,
    e.ref_id,
    e.meta,
    e.created_at
  from public.feed_events e
  join public.business_follows f
    on f.business_id = e.business_id
   and f.user_id = v_user_id
  where e.created_at >= now() - interval '14 days'
  order by e.created_at desc
  limit greatest(p_limit, 0)
  offset greatest(p_offset, 0);
end;
$function$;

create or replace function public.handle_business_activity_log_feed() returns trigger
language plpgsql
security definer
set search_path to 'public'
as $function$
begin
  if new.type = 'menu_update' then
    insert into public.feed_events (business_id, type, ref_id, meta)
    values (new.business_id, 'menu_update', new.id, coalesce(new.meta, '{}'::jsonb));
  end if;
  return new;
end;
$function$;

drop trigger if exists trg_business_activity_log_feed on public.business_activity_log;
create trigger trg_business_activity_log_feed
after insert on public.business_activity_log
for each row
execute function public.handle_business_activity_log_feed();

-- ===== END MIGRATION: 20260212_000001_business_follows_feed.sql =====

-- ===== BEGIN MIGRATION: 20260213_000001_admin_owner_claims_v3.sql =====
create or replace function public.admin_list_owner_claims_v3(
  p_status text default null,
  p_limit integer default 50,
  p_offset integer default 0,
  p_sla_only boolean default false,
  p_assigned text default null,
  p_q text default null
)
returns table(
  claim_id uuid,
  status text,
  created_at timestamptz,
  age_days double precision,
  sla_breached boolean,
  business_id uuid,
  full_name text,
  phone text,
  evidence_url text,
  note text,
  admin_note text,
  assigned_to uuid,
  assigned_at timestamptz,
  auto_moderated boolean
)
language sql
stable
security definer
set search_path to 'public'
as $function$
  select
    c.id as claim_id,
    c.status::text,
    c.created_at,
    extract(epoch from (now() - c.created_at)) / 86400.0 as age_days,
    (c.status = 'pending' and c.created_at < now() - interval '72 hours') as sla_breached,
    c.business_id,
    c.full_name,
    c.phone,
    c.evidence_url,
    c.note,
    c.admin_note,
    c.handled_by as assigned_to,
    c.handled_at as assigned_at,
    coalesce(c.auto_moderated, false) as auto_moderated
  from public.owner_claims c
  where public.is_admin()
    and (
      p_status is null
      or p_status = ''
      or c.status::text = p_status
    )
    and (
      p_assigned is null
      or p_assigned = ''
      or (p_assigned = 'me' and c.handled_by = auth.uid())
      or (p_assigned = 'unassigned' and c.handled_by is null)
      or c.handled_by::text = p_assigned
    )
    and (
      p_q is null
      or p_q = ''
      or c.id::text ilike ('%' || p_q || '%')
      or coalesce(c.full_name, '') ilike ('%' || p_q || '%')
      or coalesce(c.phone, '') ilike ('%' || p_q || '%')
    )
    and (not p_sla_only or (c.status = 'pending' and c.created_at < now() - interval '72 hours'))
  order by (c.status = 'pending') desc, c.created_at asc
  limit greatest(p_limit, 0) offset greatest(p_offset, 0);
$function$;

-- ===== END MIGRATION: 20260213_000001_admin_owner_claims_v3.sql =====

-- ===== BEGIN MIGRATION: 20260214_000001_admin_owner_claims_v3_dedup.sql =====
drop function if exists public.admin_list_owner_claims_v3(
  p_status text,
  p_limit integer,
  p_offset integer,
  p_q text,
  p_assigned text,
  p_sla_only boolean
);

drop function if exists public.admin_list_owner_claims_v3(
  p_status text,
  p_limit integer,
  p_offset integer,
  p_sla_only boolean,
  p_assigned text,
  p_q text
);

create or replace function public.admin_list_owner_claims_v3(
  p_status text default null,
  p_limit integer default 50,
  p_offset integer default 0,
  p_sla_only boolean default false,
  p_assigned text default null,
  p_q text default null
)
returns table(
  claim_id uuid,
  status text,
  created_at timestamptz,
  age_days double precision,
  sla_breached boolean,
  business_id uuid,
  full_name text,
  phone text,
  evidence_url text,
  note text,
  admin_note text,
  assigned_to uuid,
  assigned_at timestamptz,
  auto_moderated boolean
)
language sql
stable
security definer
set search_path to 'public'
as $function$
  select
    c.id as claim_id,
    c.status::text,
    c.created_at,
    extract(epoch from (now() - c.created_at)) / 86400.0 as age_days,
    (c.status = 'pending' and c.created_at < now() - interval '72 hours') as sla_breached,
    c.business_id,
    c.full_name,
    c.phone,
    c.evidence_url,
    c.note,
    c.admin_note,
    c.handled_by as assigned_to,
    c.handled_at as assigned_at,
    coalesce(c.auto_moderated, false) as auto_moderated
  from public.owner_claims c
  where public.is_admin()
    and (
      p_status is null
      or p_status = ''
      or c.status::text = p_status
    )
    and (
      p_assigned is null
      or p_assigned = ''
      or (p_assigned = 'me' and c.handled_by = auth.uid())
      or (p_assigned = 'unassigned' and c.handled_by is null)
      or c.handled_by::text = p_assigned
    )
    and (
      p_q is null
      or p_q = ''
      or c.id::text ilike ('%' || p_q || '%')
      or coalesce(c.full_name, '') ilike ('%' || p_q || '%')
      or coalesce(c.phone, '') ilike ('%' || p_q || '%')
    )
    and (not p_sla_only or (c.status = 'pending' and c.created_at < now() - interval '72 hours'))
  order by (c.status = 'pending') desc, c.created_at asc
  limit greatest(p_limit, 0) offset greatest(p_offset, 0);
$function$;

-- ===== END MIGRATION: 20260214_000001_admin_owner_claims_v3_dedup.sql =====

-- ===== BEGIN MIGRATION: 20260215_000001_admin_owner_claims_v3_reset.sql =====
do $$
declare
  r record;
begin
  for r in
    select
      n.nspname as schema_name,
      p.proname as function_name,
      pg_get_function_identity_arguments(p.oid) as args
    from pg_proc p
    join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'public'
      and p.proname = 'admin_list_owner_claims_v3'
  loop
    execute format('drop function if exists %I.%I(%s);', r.schema_name, r.function_name, r.args);
  end loop;
end $$;

create or replace function public.admin_list_owner_claims_v3(
  p_status text default null,
  p_limit integer default 50,
  p_offset integer default 0,
  p_sla_only boolean default false,
  p_assigned text default null,
  p_q text default null
)
returns table(
  claim_id uuid,
  status text,
  created_at timestamptz,
  age_days double precision,
  sla_breached boolean,
  business_id uuid,
  full_name text,
  phone text,
  evidence_url text,
  note text,
  admin_note text,
  assigned_to uuid,
  assigned_at timestamptz,
  auto_moderated boolean
)
language sql
stable
security definer
set search_path to 'public'
as $function$
  select
    c.id as claim_id,
    c.status::text,
    c.created_at,
    extract(epoch from (now() - c.created_at)) / 86400.0 as age_days,
    (c.status = 'pending' and c.created_at < now() - interval '72 hours') as sla_breached,
    c.business_id,
    c.full_name,
    c.phone,
    c.evidence_url,
    c.note,
    c.admin_note,
    c.handled_by as assigned_to,
    c.handled_at as assigned_at,
    coalesce(c.auto_moderated, false) as auto_moderated
  from public.owner_claims c
  where public.is_admin()
    and (
      p_status is null
      or p_status = ''
      or c.status::text = p_status
    )
    and (
      p_assigned is null
      or p_assigned = ''
      or (p_assigned = 'me' and c.handled_by = auth.uid())
      or (p_assigned = 'unassigned' and c.handled_by is null)
      or c.handled_by::text = p_assigned
    )
    and (
      p_q is null
      or p_q = ''
      or c.id::text ilike ('%' || p_q || '%')
      or coalesce(c.full_name, '') ilike ('%' || p_q || '%')
      or coalesce(c.phone, '') ilike ('%' || p_q || '%')
    )
    and (not p_sla_only or (c.status = 'pending' and c.created_at < now() - interval '72 hours'))
  order by (c.status = 'pending') desc, c.created_at asc
  limit greatest(p_limit, 0) offset greatest(p_offset, 0);
$function$;

-- ===== END MIGRATION: 20260215_000001_admin_owner_claims_v3_reset.sql =====

-- ===== BEGIN MIGRATION: 20260216_000001_lint_perf_auth_rls_and_indexes.sql =====
-- Fix auth_rsl_initplan warnings by wrapping auth/current_setting calls
-- and drop duplicate indexes reported by linter.

do $$
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

-- Drop duplicate indexes reported by linter (safe if missing)
drop index if exists public.idx_businesses_city_district;
drop index if exists public.businesses_address_trgm_idx;
drop index if exists public.idx_businesses_name_trgm;
drop index if exists public.businesses_name_trgm_idx;
drop index if exists public.idx_price_history_item;
drop index if exists public.review_votes_review_idx;

-- ===== END MIGRATION: 20260216_000001_lint_perf_auth_rls_and_indexes.sql =====

-- ===== BEGIN MIGRATION: 20260217_000001_lint_security_and_policy.sql =====
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

-- ===== END MIGRATION: 20260217_000001_lint_security_and_policy.sql =====

-- ===== BEGIN MIGRATION: 20260218_000001_lint_remaining_fixes.sql =====
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

-- ===== END MIGRATION: 20260218_000001_lint_remaining_fixes.sql =====

-- ===== BEGIN MIGRATION: 20260219_000001_price_alerts.sql =====
-- Price alerts + alert events + trigger

create table if not exists public.price_alerts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null,
  city text null,
  district text null,
  query text not null,
  max_price_cents int not null,
  currency text not null default 'TRY',
  category text null,
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);

create index if not exists price_alerts_user_active_idx
  on public.price_alerts (user_id, is_active);

create table if not exists public.alert_events (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null,
  alert_id uuid not null references public.price_alerts(id) on delete cascade,
  business_id uuid not null references public.businesses(id),
  menu_item_id uuid null,
  matched_price_cents int not null,
  created_at timestamptz not null default now(),
  created_day date not null default (now()::date)
);

alter table public.alert_events
  add column if not exists created_day date;

update public.alert_events
  set created_day = created_at::date
  where created_day is null;

alter table public.alert_events
  alter column created_day set default (now()::date),
  alter column created_day set not null;

create unique index if not exists alert_events_dedupe_idx
  on public.alert_events (
    user_id,
    alert_id,
    business_id,
    menu_item_id,
    created_day
  );

-- RLS
alter table public.price_alerts enable row level security;
alter table public.alert_events enable row level security;

drop policy if exists price_alerts_owner_select on public.price_alerts;
create policy price_alerts_owner_select on public.price_alerts
  for select using (user_id = auth.uid());

drop policy if exists price_alerts_owner_insert on public.price_alerts;
create policy price_alerts_owner_insert on public.price_alerts
  for insert with check (user_id = auth.uid());

drop policy if exists price_alerts_owner_update on public.price_alerts;
create policy price_alerts_owner_update on public.price_alerts
  for update using (user_id = auth.uid()) with check (user_id = auth.uid());

drop policy if exists price_alerts_owner_delete on public.price_alerts;
create policy price_alerts_owner_delete on public.price_alerts
  for delete using (user_id = auth.uid());

drop policy if exists alert_events_owner_select on public.alert_events;
create policy alert_events_owner_select on public.alert_events
  for select using (user_id = auth.uid());

drop policy if exists alert_events_owner_insert on public.alert_events;
create policy alert_events_owner_insert on public.alert_events
  for insert with check (user_id = auth.uid());

-- alert matching function
create or replace function public.check_price_alerts_for_item_v1(
  p_menu_item_id uuid,
  p_business_id uuid,
  p_item_name text,
  p_price_cents int,
  p_city text,
  p_district text,
  p_category text
)
returns void
language plpgsql
security definer
set search_path to 'public'
as $$
begin
  insert into public.alert_events (
    user_id,
    alert_id,
    business_id,
    menu_item_id,
    matched_price_cents
  )
  select
    a.user_id,
    a.id,
    p_business_id,
    p_menu_item_id,
    p_price_cents
  from public.price_alerts a
  where a.is_active = true
    and (a.query is null or a.query = '' or p_item_name ilike '%' || a.query || '%')
    and (a.max_price_cents is null or p_price_cents <= a.max_price_cents)
    and (a.city is null or a.city = '' or a.city = p_city)
    and (a.district is null or a.district = '' or a.district = p_district)
    and (a.category is null or a.category = '' or a.category = p_category)
  on conflict do nothing;
end;
$$;

-- trigger: call alerts on verified price changes (history insert)
create or replace function public.handle_price_alerts_for_history_v1()
returns trigger
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  v_item_name text;
  v_business_id uuid;
  v_city text;
  v_district text;
  v_category text;
  v_price int;
begin
  if coalesce(new.source, '') not in ('suggestion', 'owner', 'admin', 'verified') then
    return new;
  end if;

  select mi.name, mi.business_id, b.city, b.district, b.category
    into v_item_name, v_business_id, v_city, v_district, v_category
  from public.menu_items mi
  join public.businesses b on b.id = mi.business_id
  where mi.id = new.menu_item_id;

  v_price := coalesce(new.new_price_cents, new.price_cents);
  if v_item_name is null or v_business_id is null or v_price is null then
    return new;
  end if;

  perform public.check_price_alerts_for_item_v1(
    new.menu_item_id,
    v_business_id,
    v_item_name,
    v_price,
    v_city,
    v_district,
    v_category
  );

  return new;
end;
$$;

drop trigger if exists trg_price_alerts_history on public.menu_item_price_history;
create trigger trg_price_alerts_history
  after insert on public.menu_item_price_history
  for each row execute function public.handle_price_alerts_for_history_v1();

-- RPCs
create or replace function public.create_price_alert_v1(
  p_query text,
  p_max_price_cents int,
  p_city text default null,
  p_district text default null,
  p_currency text default 'TRY',
  p_category text default null
)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  v_id uuid;
begin
  if auth.uid() is null then
    return jsonb_build_object('ok', false, 'error', 'not_authenticated');
  end if;

  insert into public.price_alerts(
    user_id, city, district, query, max_price_cents, currency, category, is_active
  )
  values (
    auth.uid(), p_city, p_district, p_query, p_max_price_cents, p_currency, p_category, true
  )
  returning id into v_id;

  return jsonb_build_object('ok', true, 'id', v_id);
end;
$$;

create or replace function public.list_my_alerts_v1(
  p_limit int default 20,
  p_offset int default 0
)
returns table(
  id uuid,
  city text,
  district text,
  query text,
  max_price_cents int,
  currency text,
  category text,
  is_active boolean,
  created_at timestamptz
)
language sql
security definer
set search_path to 'public'
as $$
  select
    a.id,
    a.city,
    a.district,
    a.query,
    a.max_price_cents,
    a.currency,
    a.category,
    a.is_active,
    a.created_at
  from public.price_alerts a
  where a.user_id = auth.uid()
  order by a.created_at desc
  limit p_limit offset p_offset;
$$;

create or replace function public.list_my_alert_events_v1(
  p_limit int default 20,
  p_offset int default 0
)
returns table(
  id uuid,
  alert_id uuid,
  business_id uuid,
  menu_item_id uuid,
  matched_price_cents int,
  created_at timestamptz
)
language sql
security definer
set search_path to 'public'
as $$
  select
    e.id,
    e.alert_id,
    e.business_id,
    e.menu_item_id,
    e.matched_price_cents,
    e.created_at
  from public.alert_events e
  where e.user_id = auth.uid()
  order by e.created_at desc
  limit p_limit offset p_offset;
$$;

-- ===== END MIGRATION: 20260219_000001_price_alerts.sql =====

-- ===== BEGIN MIGRATION: 20260220000001_business_pricing_rules.sql =====
-- business pricing rules + bill estimate rpc

create table if not exists public.business_pricing_rules (
  business_id uuid primary key references public.businesses(id) on delete cascade,
  service_fee_pct int null,
  cover_charge_cents int null,
  vat_included boolean not null default true,
  default_tip_pct int null
);

alter table if exists public.business_pricing_rules enable row level security;

create or replace function public.get_bill_estimate_v1(
  p_business_id uuid,
  p_items jsonb,
  p_tip_pct int default null
)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  v_subtotal int := 0;
  v_cover int := 0;
  v_service int := 0;
  v_tip int := 0;
  v_total int := 0;
  v_service_pct int := 0;
  v_tip_pct int := 0;
  v_vat_included boolean := true;
  v_has_rules boolean := false;
begin
  if p_items is null or jsonb_typeof(p_items) <> 'array' then
    return jsonb_build_object(
      'ok', false,
      'error', 'invalid_items'
    );
  end if;

  select
    coalesce(r.service_fee_pct, 0),
    coalesce(r.cover_charge_cents, 0),
    coalesce(r.vat_included, true),
    r.default_tip_pct
  into v_service_pct, v_cover, v_vat_included, v_tip_pct
  from public.business_pricing_rules r
  where r.business_id = p_business_id;

  if found then
    v_has_rules := true;
  end if;

  v_tip_pct := coalesce(p_tip_pct, v_tip_pct, 0);

  select
    coalesce(sum(mi.price_cents * req.qty), 0)
  into v_subtotal
  from (
    select
      (i->>'menu_item_id')::uuid as menu_item_id,
      greatest(coalesce((i->>'qty')::int, 1), 1) as qty
    from jsonb_array_elements(p_items) as i
  ) req
  join public.menu_items mi on mi.id = req.menu_item_id;

  v_service := (v_subtotal * v_service_pct / 100.0)::int;
  v_tip := (v_subtotal * v_tip_pct / 100.0)::int;
  v_total := v_subtotal + v_cover + v_service + v_tip;

  return jsonb_build_object(
    'ok', true,
    'has_rules', v_has_rules,
    'subtotal_cents', v_subtotal,
    'cover_cents', v_cover,
    'service_fee_cents', v_service,
    'service_fee_pct', v_service_pct,
    'tip_cents', v_tip,
    'tip_pct', v_tip_pct,
    'total_cents', v_total,
    'vat_included', v_vat_included
  );
end;
$$;

-- ===== END MIGRATION: 20260220000001_business_pricing_rules.sql =====

-- ===== BEGIN MIGRATION: 20260220000002_unify_menu_item_fields.sql =====
-- Canonical menu item schema alignment (phase 1 / non-breaking).
-- Target canonical fields:
-- id, business_id, name, description, price_cents, currency, tags, image_url,
-- is_available, sort_order, created_at, updated_at

begin;

alter table public.menu_items
  add column if not exists sort_order integer;

update public.menu_items
set sort_order = coalesce(sort_order, 0)
where sort_order is null;

alter table public.menu_items
  alter column sort_order set default 0,
  alter column sort_order set not null;

update public.menu_items
set price_cents = 0
where price_cents is null or price_cents < 0;

alter table public.menu_items
  alter column price_cents set default 0,
  alter column price_cents set not null;

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'menu_items_price_cents_nonnegative_ck'
  ) then
    alter table public.menu_items
      add constraint menu_items_price_cents_nonnegative_ck
      check (price_cents >= 0);
  end if;
end $$;

update public.menu_items
set currency = 'TRY'
where currency is null or btrim(currency) = '';

alter table public.menu_items
  alter column currency set default 'TRY',
  alter column currency set not null;

update public.menu_items
set is_available = true
where is_available is null;

alter table public.menu_items
  alter column is_available set default true,
  alter column is_available set not null;

update public.menu_items
set tags = '[]'::jsonb
where tags is null or jsonb_typeof(tags) <> 'array';

alter table public.menu_items
  alter column tags set default '[]'::jsonb,
  alter column tags set not null;

insert into public.menu_categories (business_id, sort_order, is_active)
select distinct i.business_id, 0, true
from public.menu_items i
where i.category_id is null
  and not exists (
    select 1
    from public.menu_categories c
    where c.business_id = i.business_id
  );

insert into public.menu_translations (entity_type, entity_id, locale, name, description)
select
  'category'::public.translation_entity_type,
  c.id,
  'tr',
  'Genel',
  null
from public.menu_categories c
where not exists (
  select 1
  from public.menu_translations t
  where t.entity_type = 'category'
    and t.entity_id = c.id
    and t.locale = 'tr'
);

update public.menu_items i
set category_id = (
  select c2.id
  from public.menu_categories c2
  where c2.business_id = i.business_id
  order by c2.sort_order asc, c2.created_at asc
  limit 1
)
where i.category_id is null;

create index if not exists idx_menu_items_business_category_sort_order
  on public.menu_items (business_id, category_id, sort_order);

commit;

-- ===== END MIGRATION: 20260220000002_unify_menu_item_fields.sql =====

-- ===== BEGIN MIGRATION: 20260220000003_menu_items_auto_section_assignment.sql =====
begin;

create or replace function public.ensure_default_section_for_business_v1(
  p_business_id uuid
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_menu_id uuid;
  v_section_id uuid;
begin
  select id
    into v_menu_id
  from public.menus
  where business_id = p_business_id
  order by created_at asc
  limit 1;

  if v_menu_id is null then
    insert into public.menus (business_id, title, status, created_by)
    values (p_business_id, 'Menü', 'published', auth.uid())
    returning id into v_menu_id;
  end if;

  select id
    into v_section_id
  from public.menu_sections
  where menu_id = v_menu_id
  order by sort_order asc, created_at asc
  limit 1;

  if v_section_id is null then
    insert into public.menu_sections (menu_id, title, sort_order, created_by)
    values (v_menu_id, 'Genel', 0, auth.uid())
    returning id into v_section_id;
  end if;

  return v_section_id;
end;
$$;

create or replace function public.menu_items_assign_section_v1()
returns trigger
language plpgsql
set search_path = public
as $$
declare
  v_section_business_id uuid;
begin
  if new.section_id is null then
    new.section_id := public.ensure_default_section_for_business_v1(new.business_id);
  end if;

  select m.business_id
    into v_section_business_id
  from public.menu_sections s
  join public.menus m on m.id = s.menu_id
  where s.id = new.section_id
  limit 1;

  if v_section_business_id is null then
    raise exception 'invalid_section_id';
  end if;

  if v_section_business_id <> new.business_id then
    raise exception 'section_business_mismatch';
  end if;

  return new;
end;
$$;

drop trigger if exists trg_menu_items_assign_section on public.menu_items;
create trigger trg_menu_items_assign_section
before insert or update of section_id, business_id
on public.menu_items
for each row
execute function public.menu_items_assign_section_v1();

commit;

-- ===== END MIGRATION: 20260220000003_menu_items_auto_section_assignment.sql =====

-- ===== BEGIN MIGRATION: 20260220122649_db_global_field_unification_phase1.sql =====
begin;

-- 1) Canonicalize reports to a single status column.
update public.reports
set status = case
  when status in ('open','reviewing','closed') then status
  when durum in ('acik','open') then 'open'
  when durum in ('inceleniyor','reviewing') then 'reviewing'
  when durum in ('kapandi','closed','reddedildi','rejected') then 'closed'
  else coalesce(status, 'open')
end;

alter table public.reports
  alter column status set default 'open',
  alter column status set not null;

-- 2) Keep RPC compatibility while removing duplicated table column.
create or replace view public.admin_reports_queue_v1 as
select
  id,
  created_at,
  status as durum,
  reason,
  details,
  user_id,
  business_id,
  review_id,
  handled_by,
  handled_at,
  admin_note
from public.reports r;

create or replace function public.admin_bulk_update_reports_status_v1(
  p_report_ids uuid[],
  p_durum text,
  p_admin_note text default null
)
returns jsonb
language plpgsql
security definer
set search_path = public
as 
declare
  v_count int;
  v_status text;
begin
  if not public.is_admin() then
    raise exception 'not_admin';
  end if;

  v_status := case
    when p_durum in ('acik','open') then 'open'
    when p_durum in ('inceleniyor','reviewing') then 'reviewing'
    when p_durum in ('kapandi','closed','reddedildi','rejected') then 'closed'
    else 'open'
  end;

  update public.reports
  set
    status = v_status,
    handled_by = auth.uid(),
    handled_at = now(),
    admin_note = coalesce(p_admin_note, admin_note)
  where id = any(p_report_ids);

  get diagnostics v_count = row_count;

  perform public.log_admin_action_v1(
    'report.bulk_update',
    'reports',
    null,
    jsonb_build_object('status', v_status, 'count', v_count)
  );

  return jsonb_build_object('ok', true, 'updated', v_count);
end;
;

create or replace function public.admin_export_reports_csv_v1(
  p_status text default null,
  p_q text default null
)
returns text
language plpgsql
security definer
set search_path = public
as 
declare
  v_csv text;
  v_status text;
begin
  if not public.is_admin() then
    raise exception 'not_admin';
  end if;

  v_status := case
    when p_status in ('acik','open') then 'open'
    when p_status in ('inceleniyor','reviewing') then 'reviewing'
    when p_status in ('kapandi','closed','reddedildi','rejected') then 'closed'
    else null
  end;

  select string_agg(line, E'\n') into v_csv
  from (
    select 'id,created_at,status,reason,details,user_id,business_id,review_id,handled_by,handled_at,admin_note' as line
    union all
    select
      concat_ws(',',
        r.id::text,
        to_char(r.created_at, 'YYYY-MM-DD THH24:MI:SSZ'),
        replace(coalesce(r.status,''), ',', ' '),
        replace(coalesce(r.reason,''), ',', ' '),
        replace(coalesce(r.details,''), E'\n', ' '),
        coalesce(r.user_id::text,''),
        coalesce(r.business_id::text,''),
        coalesce(r.review_id::text,''),
        coalesce(r.handled_by::text,''),
        coalesce(to_char(r.handled_at, 'YYYY-MM-DDTHH24:MI:SSZ'),''),
        replace(coalesce(r.admin_note,''), E'\n', ' ')
      ) as line
    from public.reports r
    where (v_status is null or r.status = v_status)
      and (
        p_q is null
        or r.reason ilike ('%'||p_q||'%')
        or r.details ilike ('%'||p_q||'%')
        or r.admin_note ilike ('%'||p_q||'%')
      )
    order by r.created_at desc
  ) t;

  perform public.log_admin_action_v1(
    'report.export_csv',
    'reports',
    null,
    jsonb_build_object('status', v_status, 'q', p_q)
  );

  return v_csv;
end;
;

create or replace function public.admin_get_queues_counts_v1()
returns jsonb
language plpgsql
security definer
set search_path = public
as 
declare
  v_reports_open int;
  v_claims_pending int;
  v_suggestions_pending int;
begin
  if not public.is_admin() then
    raise exception 'not_admin';
  end if;

  select count(*) into v_reports_open
  from public.reports
  where status in ('open','reviewing');

  select count(*) into v_claims_pending
  from public.owner_claims
  where status = 'pending';

  select count(*) into v_suggestions_pending
  from public.business_suggestions
  where status = 'pending';

  return jsonb_build_object(
    'reports_open', v_reports_open,
    'claims_pending', v_claims_pending,
    'suggestions_pending', v_suggestions_pending
  );
end;
;

create or replace function public.admin_list_reports_v1(
  p_status text default null,
  p_limit integer default 50,
  p_offset integer default 0,
  p_q text default null
)
returns table(
  id uuid,
  created_at timestamptz,
  durum text,
  reason text,
  details text,
  user_id uuid,
  business_id uuid,
  review_id uuid,
  handled_by uuid,
  handled_at timestamptz,
  admin_note text
)
language sql
security definer
set search_path = public
as 
  with params as (
    select case
      when p_status in ('acik','open') then 'open'
      when p_status in ('inceleniyor','reviewing') then 'reviewing'
      when p_status in ('kapandi','closed','reddedildi','rejected') then 'closed'
      else null
    end as status_filter
  )
  select
    r.id, r.created_at, r.status as durum, r.reason, r.details, r.user_id,
    r.business_id, r.review_id, r.handled_by, r.handled_at, r.admin_note
  from public.reports r
  cross join params p
  where public.is_admin()
    and (p.status_filter is null or r.status = p.status_filter)
    and (
      p_q is null
      or r.reason ilike ('%'||p_q||'%')
      or r.details ilike ('%'||p_q||'%')
      or r.admin_note ilike ('%'||p_q||'%')
    )
  order by r.created_at desc
  limit greatest(p_limit,0)
  offset greatest(p_offset,0);
;

create or replace function public.admin_list_reports_v2(
  p_status text default null,
  p_limit integer default 50,
  p_offset integer default 0,
  p_q text default null,
  p_assigned text default null
)
returns table(
  id uuid,
  created_at timestamptz,
  durum text,
  reason text,
  details text,
  user_id uuid,
  business_id uuid,
  review_id uuid,
  assigned_to uuid,
  assigned_at timestamptz,
  handled_by uuid,
  handled_at timestamptz,
  admin_note text
)
language sql
security definer
set search_path = public
as 
  with params as (
    select case
      when p_status in ('acik','open') then 'open'
      when p_status in ('inceleniyor','reviewing') then 'reviewing'
      when p_status in ('kapandi','closed','reddedildi','rejected') then 'closed'
      else null
    end as status_filter
  )
  select
    r.id, r.created_at, r.status as durum, r.reason, r.details, r.user_id,
    r.business_id, r.review_id,
    r.assigned_to, r.assigned_at,
    r.handled_by, r.handled_at, r.admin_note
  from public.reports r
  cross join params p
  where public.is_admin()
    and (p.status_filter is null or r.status = p.status_filter)
    and (
      p_assigned is null
      or (p_assigned='me' and r.assigned_to = auth.uid())
      or (p_assigned='unassigned' and r.assigned_to is null)
    )
    and (
      p_q is null
      or r.reason ilike ('%'||p_q||'%')
      or r.details ilike ('%'||p_q||'%')
      or r.admin_note ilike ('%'||p_q||'%')
    )
  order by r.created_at desc
  limit greatest(p_limit,0)
  offset greatest(p_offset,0);
;

create or replace function public.admin_list_reports_v3(
  p_status text default null,
  p_limit integer default 50,
  p_offset integer default 0,
  p_q text default null,
  p_assigned text default null,
  p_sla_only boolean default false
)
returns table(
  id uuid,
  created_at timestamptz,
  durum text,
  reason text,
  details text,
  user_id uuid,
  business_id uuid,
  review_id uuid,
  assigned_to uuid,
  assigned_at timestamptz,
  handled_by uuid,
  handled_at timestamptz,
  admin_note text,
  age_hours float,
  sla_breached boolean
)
language sql
security definer
set search_path = public
as 
  with params as (
    select case
      when p_status in ('acik','open') then 'open'
      when p_status in ('inceleniyor','reviewing') then 'reviewing'
      when p_status in ('kapandi','closed','reddedildi','rejected') then 'closed'
      else null
    end as status_filter
  ),
  base as (
    select
      r.*,
      (extract(epoch from (now() - r.created_at))/3600.0)::float as age_hours,
      (
        r.handled_at is null
        and r.status in ('open','reviewing')
        and r.created_at < now() - interval '24 hours'
      ) as sla_breached
    from public.reports r
    cross join params p
    where public.is_admin()
      and (p.status_filter is null or r.status = p.status_filter)
      and (
        p_assigned is null
        or (p_assigned='me' and r.assigned_to = auth.uid())
        or (p_assigned='unassigned' and r.assigned_to is null)
      )
      and (
        p_q is null
        or r.reason ilike ('%'||p_q||'%')
        or r.details ilike ('%'||p_q||'%')
        or r.admin_note ilike ('%'||p_q||'%')
      )
  )
  select
    id, created_at, status as durum, reason, details, user_id, business_id, review_id,
    assigned_to, assigned_at, handled_by, handled_at, admin_note,
    age_hours, sla_breached
  from base
  where (not p_sla_only) or sla_breached
  order by sla_breached desc, created_at desc
  limit greatest(p_limit,0)
  offset greatest(p_offset,0);
;

create or replace function public.admin_list_reports_v4(
  p_status text default null,
  p_limit integer default 50,
  p_offset integer default 0,
  p_q text default null,
  p_assigned text default null,
  p_sla_only boolean default false
)
returns table(
  id uuid,
  created_at timestamptz,
  durum text,
  reason text,
  details text,
  user_id uuid,
  business_id uuid,
  review_id uuid,
  menu_item_photo_id uuid,
  target_type text,
  target_id uuid,
  assigned_to uuid,
  assigned_at timestamptz,
  handled_by uuid,
  handled_at timestamptz,
  admin_note text,
  age_hours float,
  sla_breached boolean
)
language sql
security definer
set search_path = public
as 
  with params as (
    select case
      when p_status in ('acik','open') then 'open'
      when p_status in ('inceleniyor','reviewing') then 'reviewing'
      when p_status in ('kapandi','closed','reddedildi','rejected') then 'closed'
      else null
    end as status_filter
  ),
  base as (
    select
      r.*,
      (extract(epoch from (now() - r.created_at))/3600.0)::float as age_hours,
      (
        r.handled_at is null
        and r.status in ('open','reviewing')
        and r.created_at < now() - interval '24 hours'
      ) as sla_breached
    from public.reports r
    cross join params p
    where public.is_admin_or_community_mod_v1()
      and (p.status_filter is null or r.status = p.status_filter)
      and (
        p_assigned is null
        or (p_assigned='me' and r.assigned_to = auth.uid())
        or (p_assigned='unassigned' and r.assigned_to is null)
      )
      and (
        p_q is null
        or r.reason ilike ('%'||p_q||'%')
        or r.details ilike ('%'||p_q||'%')
        or r.admin_note ilike ('%'||p_q||'%')
      )
  )
  select
    id, created_at, status as durum, reason, details, user_id, business_id, review_id,
    menu_item_photo_id, target_type, target_id,
    assigned_to, assigned_at, handled_by, handled_at, admin_note,
    age_hours, sla_breached
  from base
  where (not p_sla_only) or sla_breached
  order by sla_breached desc, created_at desc
  limit greatest(p_limit, 1)
  offset greatest(p_offset, 0);
;

create or replace function public.admin_update_report_v1(
  p_report_id uuid,
  p_durum text,
  p_admin_note text default null
)
returns void
language plpgsql
security definer
set search_path = public
as 
declare
  v_status text;
begin
  if not public.is_admin() then
    raise exception 'not_admin';
  end if;

  v_status := case
    when p_durum in ('acik','open') then 'open'
    when p_durum in ('inceleniyor','reviewing') then 'reviewing'
    when p_durum in ('kapandi','closed','reddedildi','rejected') then 'closed'
    else 'open'
  end;

  update public.reports
  set
    status = v_status,
    handled_by = auth.uid(),
    handled_at = now(),
    admin_note = p_admin_note
  where id = p_report_id;

  perform public.log_admin_action_v1(
    'report.update',
    'reports',
    p_report_id,
    jsonb_build_object('status', v_status, 'admin_note', p_admin_note)
  );
end;
;

create or replace function public.auto_close_duplicate_report_v1(p_report_id uuid)
returns boolean
language plpgsql
security definer
set search_path = public
as 
declare
  v_r public.reports%rowtype;
  v_exists boolean;
begin
  select * into v_r from public.reports where id = p_report_id;

  if v_r.id is null then return false; end if;

  select exists(
    select 1
    from public.reports
    where user_id = v_r.user_id
      and target_type = v_r.target_type
      and target_id = v_r.target_id
      and id <> v_r.id
      and created_at >= now() - interval '24 hours'
  ) into v_exists;

  if v_exists then
    update public.reports
    set
      status = 'closed',
      admin_note = 'Otomatik: 24 saat i�inde m�kerrer bildirim',
      handled_at = now(),
      auto_moderated = true
    where id = p_report_id;

    perform public.log_admin_action_v1(
      'report.auto_close_duplicate',
      'reports',
      p_report_id,
      jsonb_build_object()
    );

    return true;
  end if;

  return false;
end;
;

create or replace function public.auto_queue_grey_report_v1(p_report_id uuid)
returns boolean
language plpgsql
security definer
set search_path = public
as 
declare
  v_r public.reports%rowtype;
  v_len int;
begin
  select * into v_r from public.reports where id = p_report_id;
  v_len := length(coalesce(v_r.details, ''));

  if v_r.id is null then return false; end if;

  if v_r.status = 'closed' then
    return false;
  end if;

  if v_len >= 15 and v_len <= 200 and v_r.reason not in ('spam','duplicate') then
    update public.reports
    set
      status = 'reviewing',
      admin_note = 'Otomatik: gri alan, kuyru�a al�nd�',
      handled_at = now(),
      auto_moderated = true
    where id = p_report_id;

    perform public.log_admin_action_v1(
      'report.auto_queue_grey',
      'reports',
      p_report_id,
      jsonb_build_object('length', v_len, 'reason', v_r.reason)
    );

    return true;
  end if;

  return false;
end;
;

create or replace function public.auto_reject_low_quality_report_v1(p_report_id uuid)
returns boolean
language plpgsql
security definer
set search_path = public
as 
declare
  v_len int;
  v_uid uuid;
begin
  select length(coalesce(details,'')), user_id into v_len, v_uid
  from public.reports
  where id = p_report_id;

  if v_len < 15 then
    update public.reports
    set
      status = 'closed',
      admin_note = 'Otomatik: �ok k�sa / d���k kaliteli bildirim',
      handled_at = now(),
      auto_moderated = true
    where id = p_report_id;

    perform public.log_admin_action_v1(
      'report.auto_reject_low_quality',
      'reports',
      p_report_id,
      jsonb_build_object('length', v_len)
    );

    perform public.add_moderation_strike_v1(
      v_uid,
      'low_quality_report',
      'report'
    );

    return true;
  end if;

  return false;
end;
;

create or replace function public.get_business_reviews_v2(
  p_business_id uuid,
  p_sort text default 'newest',
  p_limit integer default 20,
  p_offset integer default 0
)
returns table(
  id uuid,
  business_id uuid,
  user_id uuid,
  rating integer,
  title text,
  content text,
  helpful_count integer,
  created_at timestamptz,
  status text,
  quality_score numeric
)
language sql
stable
security definer
set search_path = public
as 
  with base as (
    select
      r.id,
      r.business_id,
      r.user_id,
      r.rating,
      r.title,
      r.content,
      r.helpful_count,
      r.created_at,
      r.status,
      coalesce(rep.open_reports, 0) as open_reports,
      greatest(
        0::numeric,
        least(
          100::numeric,
          (coalesce(r.helpful_count, 0)::numeric * 2.2)
          + (least(length(coalesce(r.content, '')), 400)::numeric / 20)
          + (r.rating::numeric * 1.5)
          - (coalesce(rep.open_reports, 0)::numeric * 3.0)
        )
      ) as quality_score
    from public.reviews r
    left join (
      select
        review_id,
        count(*)::int as open_reports
      from public.reports
      where review_id is not null
        and status in ('open', 'reviewing')
      group by review_id
    ) rep on rep.review_id = r.id
    where r.business_id = p_business_id
      and r.status = 'approved'
  )
  select
    b.id,
    b.business_id,
    b.user_id,
    b.rating,
    b.title,
    b.content,
    b.helpful_count,
    b.created_at,
    b.status,
    b.quality_score
  from base b
  order by
    case when lower(coalesce(p_sort, 'newest')) = 'helpful' then b.quality_score else null end desc,
    case when lower(coalesce(p_sort, 'newest')) = 'helpful' then b.helpful_count else null end desc,
    b.created_at desc
  limit greatest(p_limit, 1)
  offset greatest(p_offset, 0);
;

-- 3) Remove deprecated favorites table usage from merge function and drop legacy table.
create or replace function public.admin_merge_businesses_v1(
  p_primary_business_id uuid,
  p_duplicate_business_id uuid,
  p_admin_note text default null,
  p_dry_run boolean default false
)
returns jsonb
language plpgsql
security definer
set search_path = public
as 
declare
  v_primary_exists boolean := false;
  v_duplicate_exists boolean := false;
  v_now timestamptz := now();
  v_summary jsonb;
begin
  if not public.is_admin() then
    raise exception 'not_admin';
  end if;

  if p_primary_business_id is null or p_duplicate_business_id is null then
    return jsonb_build_object('ok', false, 'error', 'missing_business_id');
  end if;
  if p_primary_business_id = p_duplicate_business_id then
    return jsonb_build_object('ok', false, 'error', 'same_business');
  end if;

  select exists(select 1 from public.businesses b where b.id = p_primary_business_id)
    into v_primary_exists;
  select exists(select 1 from public.businesses b where b.id = p_duplicate_business_id)
    into v_duplicate_exists;

  if not v_primary_exists or not v_duplicate_exists then
    return jsonb_build_object('ok', false, 'error', 'business_not_found');
  end if;

  v_summary := jsonb_build_object(
    'menus', (select count(*) from public.menus where business_id = p_duplicate_business_id),
    'menu_items', (select count(*) from public.menu_items where business_id = p_duplicate_business_id),
    'reviews', (select count(*) from public.reviews where business_id = p_duplicate_business_id),
    'media', (select count(*) from public.business_media where business_id = p_duplicate_business_id),
    'stories', (select count(*) from public.business_stories where business_id = p_duplicate_business_id),
    'favorites', (select count(*) from public.favorites where business_id = p_duplicate_business_id),
    'follows', (select count(*) from public.business_follows where business_id = p_duplicate_business_id)
  );

  if p_dry_run then
    return jsonb_build_object(
      'ok', true,
      'dry_run', true,
      'summary', v_summary
    );
  end if;

  insert into public.business_follows(user_id, business_id, created_at)
  select bf.user_id, p_primary_business_id, bf.created_at
  from public.business_follows bf
  where bf.business_id = p_duplicate_business_id
    and not exists (
      select 1
      from public.business_follows x
      where x.user_id = bf.user_id
        and x.business_id = p_primary_business_id
    );
  delete from public.business_follows where business_id = p_duplicate_business_id;

  insert into public.favorites(user_id, business_id, created_at)
  select f.user_id, p_primary_business_id, f.created_at
  from public.favorites f
  where f.business_id = p_duplicate_business_id
    and not exists (
      select 1
      from public.favorites x
      where x.user_id = f.user_id
        and x.business_id = p_primary_business_id
    );
  delete from public.favorites where business_id = p_duplicate_business_id;

  insert into public.collection_items(collection_id, business_id, note, created_at)
  select c.collection_id, p_primary_business_id, c.note, c.created_at
  from public.collection_items c
  where c.business_id = p_duplicate_business_id
    and not exists (
      select 1
      from public.collection_items x
      where x.collection_id = c.collection_id
        and x.business_id = p_primary_business_id
    );
  delete from public.collection_items where business_id = p_duplicate_business_id;

  insert into public.business_amenity_map(business_id, amenity_id)
  select p_primary_business_id, m.amenity_id
  from public.business_amenity_map m
  where m.business_id = p_duplicate_business_id
    and not exists (
      select 1
      from public.business_amenity_map x
      where x.business_id = p_primary_business_id
        and x.amenity_id = m.amenity_id
    );
  delete from public.business_amenity_map where business_id = p_duplicate_business_id;

  update public.owner_claims oc
  set business_id = p_primary_business_id
  where oc.business_id = p_duplicate_business_id
    and not exists (
      select 1
      from public.owner_claims x
      where x.user_id = oc.user_id
        and x.business_id = p_primary_business_id
    );
  delete from public.owner_claims where business_id = p_duplicate_business_id;

  if exists(select 1 from public.business_hours where business_id = p_primary_business_id) then
    delete from public.business_hours where business_id = p_duplicate_business_id;
  else
    update public.business_hours
      set business_id = p_primary_business_id
      where business_id = p_duplicate_business_id;
  end if;

  if exists(select 1 from public.owner_onboarding_progress where business_id = p_primary_business_id) then
    delete from public.owner_onboarding_progress where business_id = p_duplicate_business_id;
  else
    update public.owner_onboarding_progress
      set business_id = p_primary_business_id
      where business_id = p_duplicate_business_id;
  end if;

  if exists(select 1 from public.business_stats where business_id = p_primary_business_id) then
    delete from public.business_stats where business_id = p_duplicate_business_id;
  else
    update public.business_stats
      set business_id = p_primary_business_id
      where business_id = p_duplicate_business_id;
  end if;

  update public.analytics_events set business_id = p_primary_business_id where business_id = p_duplicate_business_id;
  update public.business_activity_log set business_id = p_primary_business_id where business_id = p_duplicate_business_id;
  update public.business_media set business_id = p_primary_business_id where business_id = p_duplicate_business_id;
  update public.business_premium set business_id = p_primary_business_id where business_id = p_duplicate_business_id;
  update public.business_presence_events set business_id = p_primary_business_id where business_id = p_duplicate_business_id;
  update public.business_stories set business_id = p_primary_business_id where business_id = p_duplicate_business_id;
  update public.feed_events set business_id = p_primary_business_id where business_id = p_duplicate_business_id;
  update public.menu_item_photos set business_id = p_primary_business_id where business_id = p_duplicate_business_id;
  update public.menu_item_price_suggestions set business_id = p_primary_business_id where business_id = p_duplicate_business_id;
  update public.menu_item_suggestions set business_id = p_primary_business_id where business_id = p_duplicate_business_id;
  update public.menu_items set business_id = p_primary_business_id where business_id = p_duplicate_business_id;
  update public.menus set business_id = p_primary_business_id where business_id = p_duplicate_business_id;
  update public.reviews set business_id = p_primary_business_id where business_id = p_duplicate_business_id;
  update public.sponsorship_leads set business_id = p_primary_business_id where business_id = p_duplicate_business_id;
  update public.sponsorships set business_id = p_primary_business_id where business_id = p_duplicate_business_id;
  update public.suspended_meals set business_id = p_primary_business_id where business_id = p_duplicate_business_id;
  update public.table_feedback set business_id = p_primary_business_id where business_id = p_duplicate_business_id;
  update public.visits set business_id = p_primary_business_id where business_id = p_duplicate_business_id;

  insert into public.business_merge_log(
    duplicate_business_id,
    primary_business_id,
    merged_by,
    merged_at,
    note
  ) values (
    p_duplicate_business_id,
    p_primary_business_id,
    auth.uid(),
    v_now,
    nullif(trim(coalesce(p_admin_note, '')), '')
  )
  on conflict (duplicate_business_id)
  do update set
    primary_business_id = excluded.primary_business_id,
    merged_by = excluded.merged_by,
    merged_at = excluded.merged_at,
    note = excluded.note;

  update public.businesses
  set
    is_active = false,
    source = 'merged',
    source_id = p_primary_business_id::text
  where id = p_duplicate_business_id;

  perform public.log_admin_action_v1(
    'business.merge',
    'businesses',
    p_duplicate_business_id,
    jsonb_build_object(
      'primary_business_id', p_primary_business_id,
      'duplicate_business_id', p_duplicate_business_id,
      'note', p_admin_note,
      'summary', v_summary
    )
  );

  return jsonb_build_object(
    'ok', true,
    'dry_run', false,
    'summary', v_summary
  );
end;
;

drop table if exists public.user_favorites_legacy;

-- 4) Finally drop duplicated reports column.
alter table public.reports
  drop column if exists durum;

commit;

-- ===== END MIGRATION: 20260220122649_db_global_field_unification_phase1.sql =====

-- ===== BEGIN MIGRATION: 20260220123136_menu_categories_sort_order_unification.sql =====
begin;

alter table public.menu_categories
  add column if not exists sort_order integer;

update public.menu_categories
set sort_order = coalesce(sort_order, sort, 0)
where sort_order is null;

alter table public.menu_categories
  alter column sort_order set default 0,
  alter column sort_order set not null;

create or replace function public.menu_categories_sync_sort_columns_v1()
returns trigger
language plpgsql
as 
begin
  if tg_op = 'INSERT' then
    if new.sort_order is null and new.sort is not null then
      new.sort_order := new.sort;
    end if;
    if new.sort is null and new.sort_order is not null then
      new.sort := new.sort_order;
    end if;
    return new;
  end if;

  if new.sort_order is distinct from old.sort_order then
    new.sort := new.sort_order;
  elsif new.sort is distinct from old.sort then
    new.sort_order := new.sort;
  end if;

  return new;
end;
;

drop trigger if exists trg_menu_categories_sync_sort_columns on public.menu_categories;
create trigger trg_menu_categories_sync_sort_columns
before insert or update of sort, sort_order on public.menu_categories
for each row execute function public.menu_categories_sync_sort_columns_v1();

create index if not exists idx_menu_categories_business_id_sort_order
  on public.menu_categories (business_id, sort_order);

comment on column public.menu_categories.sort is 'DEPRECATED: replaced by sort_order';

commit;

-- ===== END MIGRATION: 20260220123136_menu_categories_sort_order_unification.sql =====

-- ===== BEGIN MIGRATION: 20260220173000_canonical_alignment_preflight.sql =====
-- Canonical alignment preflight (non-breaking, no destructive DDL)
-- Date: 2026-02-20
-- Purpose: Guard checks before legacy cleanup.

begin;

do $$
declare
  missing_count int;
  sort_mismatch int;
begin
  -- 1) Canonical menu_items columns must exist.
  perform 1
  from information_schema.columns
  where table_schema='public' and table_name='menu_items' and column_name in
    ('id','business_id','name','description','price_cents','currency','tags','image_url','is_available','sort_order','created_at','updated_at')
  group by table_name
  having count(*) = 12;

  if not found then
    raise exception 'menu_items canonical column set is incomplete';
  end if;

  -- 2) reports must use status (durum should not be a table column).
  if exists (
    select 1 from information_schema.columns
    where table_schema='public' and table_name='reports' and column_name='durum'
  ) then
    raise exception 'reports.durum still exists; expected canonical status';
  end if;

  if not exists (
    select 1 from information_schema.columns
    where table_schema='public' and table_name='reports' and column_name='status'
  ) then
    raise exception 'reports.status missing';
  end if;

  -- 3) Detect temporary dual-column drift in menu_categories.
  select count(*) into sort_mismatch
  from public.menu_categories
  where coalesce(sort, -1) <> coalesce(sort_order, -1);

  raise notice 'menu_categories sort mismatch rows: %', sort_mismatch;

  -- 4) Track code-referenced missing DB objects (for refactor backlog).
  with expected(name) as (
    values
      ('menu_settings'),
      ('profiles'),
      ('qr_assets'),
      ('qr_links'),
      ('review_replies'),
      ('user_feed_preferences')
  )
  select count(*) into missing_count
  from expected e
  left join information_schema.tables t
    on t.table_schema='public' and t.table_name=e.name
  left join information_schema.views v
    on v.table_schema='public' and v.table_name=e.name
  where t.table_name is null and v.table_name is null;

  raise notice 'code-referenced missing objects: %', missing_count;
end $$;

commit;

-- ===== END MIGRATION: 20260220173000_canonical_alignment_preflight.sql =====

-- ===== BEGIN MIGRATION: 20260221_000001_reverse_auction.sql =====
-- Reverse auction: group requests & offers

create table if not exists public.group_requests (
  id uuid primary key default gen_random_uuid(),
  created_by uuid not null,
  city text not null,
  districts text[] null,
  category text null,
  date_time timestamptz not null,
  party_size int not null,
  budget_total_cents int not null,
  currency text not null default 'TRY',
  notes text null,
  status text not null default 'open',
  created_at timestamptz not null default now(),
  constraint group_requests_party_size_check
    check (party_size between 2 and 200),
  constraint group_requests_status_check
    check (status in ('open','closed','awarded','cancelled'))
);

create index if not exists group_requests_city_date_idx
  on public.group_requests (city, date_time);
create index if not exists group_requests_status_created_idx
  on public.group_requests (status, created_at desc);

create table if not exists public.group_offers (
  id uuid primary key default gen_random_uuid(),
  request_id uuid not null references public.group_requests(id) on delete cascade,
  business_id uuid not null references public.businesses(id) on delete cascade,
  offered_total_cents int not null,
  includes jsonb not null default '{}'::jsonb,
  message text null,
  status text not null default 'submitted',
  created_by uuid not null,
  created_at timestamptz not null default now(),
  constraint group_offers_status_check
    check (status in ('submitted','withdrawn','accepted','rejected'))
);

create unique index if not exists group_offers_unique_active
  on public.group_offers (request_id, business_id)
  where status in ('submitted','accepted');

create index if not exists group_offers_request_created_idx
  on public.group_offers (request_id, created_at desc);
create index if not exists group_offers_business_created_idx
  on public.group_offers (business_id, created_at desc);

create table if not exists public.offer_messages (
  id uuid primary key default gen_random_uuid(),
  request_id uuid not null references public.group_requests(id) on delete cascade,
  offer_id uuid null references public.group_offers(id) on delete set null,
  sender_type text not null,
  sender_user_id uuid null,
  business_id uuid null references public.businesses(id) on delete set null,
  body text not null,
  created_at timestamptz not null default now(),
  constraint offer_messages_sender_type_check
    check (sender_type in ('user','business','admin'))
);

create index if not exists offer_messages_request_created_idx
  on public.offer_messages (request_id, created_at desc);

-- RLS
alter table public.group_requests enable row level security;
alter table public.group_offers enable row level security;
alter table public.offer_messages enable row level security;

-- group_requests
drop policy if exists group_requests_owner_select on public.group_requests;
create policy group_requests_owner_select on public.group_requests
  for select using (created_by = auth.uid() or public.is_admin());

drop policy if exists group_requests_owner_insert on public.group_requests;
create policy group_requests_owner_insert on public.group_requests
  for insert with check (created_by = auth.uid() or public.is_admin());

drop policy if exists group_requests_owner_update on public.group_requests;
create policy group_requests_owner_update on public.group_requests
  for update using (created_by = auth.uid() or public.is_admin())
  with check (created_by = auth.uid() or public.is_admin());

-- group_offers
drop policy if exists group_offers_business_select on public.group_offers;
create policy group_offers_business_select on public.group_offers
  for select using (
    public.is_admin()
    or public.is_owner_of_business(business_id)
    or exists (
      select 1 from public.group_requests r
      where r.id = request_id and r.created_by = auth.uid()
    )
  );

drop policy if exists group_offers_business_insert on public.group_offers;
create policy group_offers_business_insert on public.group_offers
  for insert with check (public.is_admin() or public.is_owner_of_business(business_id));

drop policy if exists group_offers_business_update on public.group_offers;
create policy group_offers_business_update on public.group_offers
  for update using (public.is_admin() or public.is_owner_of_business(business_id))
  with check (public.is_admin() or public.is_owner_of_business(business_id));

-- offer_messages
drop policy if exists offer_messages_read on public.offer_messages;
create policy offer_messages_read on public.offer_messages
  for select using (
    public.is_admin()
    or exists (
      select 1 from public.group_requests r
      where r.id = request_id and r.created_by = auth.uid()
    )
    or (business_id is not null and public.is_owner_of_business(business_id))
  );

drop policy if exists offer_messages_insert on public.offer_messages;
create policy offer_messages_insert on public.offer_messages
  for insert with check (
    public.is_admin()
    or exists (
      select 1 from public.group_requests r
      where r.id = request_id and r.created_by = auth.uid()
    )
    or (business_id is not null and public.is_owner_of_business(business_id))
  );

-- RPCs
create or replace function public.create_group_request_v1(
  p_city text,
  p_districts text[] default null,
  p_category text default null,
  p_date_time timestamptz default null,
  p_party_size int default null,
  p_budget_total_cents int default null,
  p_notes text default null
) returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  v_id uuid;
  v_key text;
  v_today date := current_date;
  v_count int;
begin
  if auth.uid() is null then
    return jsonb_build_object('ok', false, 'code', 'not_authenticated');
  end if;

  if p_date_time is null or p_party_size is null or p_budget_total_cents is null then
    return jsonb_build_object('ok', false, 'code', 'invalid_input');
  end if;

  v_key := format('group_request:%s:%s', auth.uid()::text, v_today::text);
  select count into v_count from public.user_rate_limits where key = v_key;
  if coalesce(v_count, 0) >= 3 then
    return jsonb_build_object('ok', false, 'code', 'rate_limited');
  end if;

  insert into public.user_rate_limits (key, user_id, action, day, count, updated_at)
  values (v_key, auth.uid(), 'group_request', v_today, 1, now())
  on conflict (key) do update
    set count = public.user_rate_limits.count + 1,
        updated_at = now();

  insert into public.group_requests(
    created_by, city, districts, category, date_time, party_size,
    budget_total_cents, currency, notes, status
  )
  values (
    auth.uid(),
    trim(p_city),
    p_districts,
    nullif(trim(p_category), ''),
    p_date_time,
    p_party_size,
    p_budget_total_cents,
    'TRY',
    nullif(trim(p_notes), ''),
    'open'
  )
  returning id into v_id;

  return jsonb_build_object('ok', true, 'id', v_id);
end;
$$;

create or replace function public.list_group_requests_v1(
  p_status text default null,
  p_city text default null,
  p_limit int default 30,
  p_offset int default 0,
  p_include_open boolean default false
) returns table(
  id uuid,
  created_by uuid,
  city text,
  districts text[],
  category text,
  date_time timestamptz,
  party_size int,
  budget_total_cents int,
  currency text,
  notes text,
  status text,
  created_at timestamptz
)
language sql
security definer
set search_path to 'public'
as $$
  select
    r.id,
    r.created_by,
    r.city,
    r.districts,
    r.category,
    r.date_time,
    r.party_size,
    r.budget_total_cents,
    r.currency,
    r.notes,
    r.status,
    r.created_at
  from public.group_requests r
  where
    (public.is_admin()
      or r.created_by = auth.uid()
      or (p_include_open and r.status = 'open'))
    and (p_status is null or r.status = p_status)
    and (p_city is null or r.city = p_city)
  order by r.created_at desc
  limit p_limit offset p_offset;
$$;

create or replace function public.list_open_requests_for_business_v1(
  p_city text,
  p_categories text[] default null,
  p_limit int default 30,
  p_offset int default 0,
  p_business_id uuid default null
) returns table(
  id uuid,
  city text,
  districts text[],
  category text,
  date_time timestamptz,
  party_size int,
  budget_total_cents int,
  currency text,
  notes text,
  status text,
  created_at timestamptz
)
language sql
security definer
set search_path to 'public'
as $$
  select
    r.id,
    r.city,
    r.districts,
    r.category,
    r.date_time,
    r.party_size,
    r.budget_total_cents,
    r.currency,
    r.notes,
    r.status,
    r.created_at
  from public.group_requests r
  where (public.is_admin() or (p_business_id is not null and public.is_owner_of_business(p_business_id)))
    and r.status = 'open'
    and r.date_time >= now()
    and r.city = p_city
    and (p_categories is null or r.category = any(p_categories))
  order by r.date_time asc
  limit p_limit offset p_offset;
$$;

create or replace function public.submit_group_offer_v1(
  p_request_id uuid,
  p_business_id uuid,
  p_offered_total_cents int,
  p_includes jsonb default '{}'::jsonb,
  p_message text default null
) returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  v_req_status text;
  v_key text;
  v_today date := current_date;
  v_count int;
begin
  if auth.uid() is null then
    return jsonb_build_object('ok', false, 'code', 'not_authenticated');
  end if;
  if not (public.is_admin() or public.is_owner_of_business(p_business_id)) then
    return jsonb_build_object('ok', false, 'code', 'not_owner');
  end if;

  select status into v_req_status
  from public.group_requests
  where id = p_request_id;

  if v_req_status is distinct from 'open' then
    return jsonb_build_object('ok', false, 'code', 'request_closed');
  end if;

  v_key := format('group_offer:%s:%s', p_business_id::text, v_today::text);
  select count into v_count from public.user_rate_limits where key = v_key;
  if coalesce(v_count, 0) >= 20 then
    return jsonb_build_object('ok', false, 'code', 'rate_limited');
  end if;

  insert into public.user_rate_limits (key, user_id, action, day, count, updated_at)
  values (v_key, auth.uid(), 'group_offer', v_today, 1, now())
  on conflict (key) do update
    set count = public.user_rate_limits.count + 1,
        updated_at = now();

  insert into public.group_offers(
    request_id, business_id, offered_total_cents, includes, message, status, created_by
  )
  values (
    p_request_id, p_business_id, p_offered_total_cents,
    coalesce(p_includes, '{}'::jsonb),
    nullif(trim(p_message), ''),
    'submitted',
    auth.uid()
  )
  on conflict do nothing;

  return jsonb_build_object('ok', true);
end;
$$;

create or replace function public.accept_group_offer_v1(
  p_offer_id uuid
) returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  v_request_id uuid;
  v_request_owner uuid;
begin
  select o.request_id, r.created_by
  into v_request_id, v_request_owner
  from public.group_offers o
  join public.group_requests r on r.id = o.request_id
  where o.id = p_offer_id;

  if v_request_id is null then
    return jsonb_build_object('ok', false, 'code', 'not_found');
  end if;
  if v_request_owner <> auth.uid() and not public.is_admin() then
    return jsonb_build_object('ok', false, 'code', 'not_owner');
  end if;

  update public.group_requests
    set status = 'awarded'
    where id = v_request_id;

  update public.group_offers
    set status = case when id = p_offer_id then 'accepted' else 'rejected' end
    where request_id = v_request_id
      and status in ('submitted','accepted');

  return jsonb_build_object('ok', true);
end;
$$;

create or replace function public.close_group_request_v1(
  p_request_id uuid
) returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  v_owner uuid;
begin
  select created_by into v_owner from public.group_requests where id = p_request_id;
  if v_owner is null then
    return jsonb_build_object('ok', false, 'code', 'not_found');
  end if;
  if v_owner <> auth.uid() and not public.is_admin() then
    return jsonb_build_object('ok', false, 'code', 'not_owner');
  end if;

  update public.group_requests
    set status = 'closed'
    where id = p_request_id;

  return jsonb_build_object('ok', true);
end;
$$;

-- ===== END MIGRATION: 20260221_000001_reverse_auction.sql =====

-- ===== BEGIN MIGRATION: 20260222_000001_user_location_prefs.sql =====
create table if not exists public.user_location_prefs (
  user_id uuid primary key references auth.users(id) on delete cascade,
  city text null,
  district text null,
  mode text not null default 'auto' check (mode in ('auto','manual')),
  updated_at timestamptz not null default now()
);

alter table public.user_location_prefs enable row level security;

drop policy if exists user_location_prefs_select_own on public.user_location_prefs;
create policy user_location_prefs_select_own on public.user_location_prefs
  for select using (user_id = auth.uid());

drop policy if exists user_location_prefs_insert_own on public.user_location_prefs;
create policy user_location_prefs_insert_own on public.user_location_prefs
  for insert with check (user_id = auth.uid());

drop policy if exists user_location_prefs_update_own on public.user_location_prefs;
create policy user_location_prefs_update_own on public.user_location_prefs
  for update using (user_id = auth.uid()) with check (user_id = auth.uid());

drop policy if exists user_location_prefs_delete_own on public.user_location_prefs;
create policy user_location_prefs_delete_own on public.user_location_prefs
  for delete using (user_id = auth.uid());

create or replace function public.upsert_user_location_prefs_v1(
  p_city text,
  p_district text,
  p_mode text default 'manual'
)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $$
begin
  if auth.uid() is null then
    return jsonb_build_object('ok', false, 'error', 'not_authenticated');
  end if;

  if p_city is null or btrim(p_city) = '' or p_district is null or btrim(p_district) = '' then
    return jsonb_build_object('ok', false, 'error', 'invalid_location');
  end if;

  insert into public.user_location_prefs (user_id, city, district, mode, updated_at)
  values (auth.uid(), p_city, p_district, p_mode, now())
  on conflict (user_id) do update
  set city = excluded.city,
      district = excluded.district,
      mode = excluded.mode,
      updated_at = now();

  return jsonb_build_object('ok', true);
end;
$$;

create or replace function public.get_user_location_prefs_v1()
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  v_row record;
begin
  if auth.uid() is null then
    return jsonb_build_object('ok', false, 'error', 'not_authenticated');
  end if;

  select city, district, mode, updated_at
    into v_row
  from public.user_location_prefs
  where user_id = auth.uid();

  if not found then
    return jsonb_build_object('ok', true, 'data', null);
  end if;

  return jsonb_build_object(
    'ok', true,
    'data', jsonb_build_object(
      'city', v_row.city,
      'district', v_row.district,
      'mode', v_row.mode,
      'updated_at', v_row.updated_at
    )
  );
end;
$$;

-- ===== END MIGRATION: 20260222_000001_user_location_prefs.sql =====

-- ===== BEGIN MIGRATION: 20260223_000001_business_submissions.sql =====
create table if not exists public.business_submissions (
  id uuid primary key default gen_random_uuid(),
  submitted_by uuid not null,
  name text not null,
  city text not null,
  district text not null,
  category text not null,
  address text not null,
  phone text null,
  website text null,
  status text not null default 'new' check (status in ('new','approved','rejected')),
  admin_note text null,
  created_at timestamptz not null default now()
);

create index if not exists business_submissions_status_created_idx
  on public.business_submissions (status, created_at desc);

alter table public.business_submissions enable row level security;

drop policy if exists business_submissions_owner_select on public.business_submissions;
create policy business_submissions_owner_select on public.business_submissions
  for select using (submitted_by = auth.uid());

drop policy if exists business_submissions_owner_insert on public.business_submissions;
create policy business_submissions_owner_insert on public.business_submissions
  for insert with check (submitted_by = auth.uid());

drop policy if exists business_submissions_admin_all on public.business_submissions;
create policy business_submissions_admin_all on public.business_submissions
  for all using (public.is_admin()) with check (public.is_admin());

create or replace function public.owner_list_my_businesses_v1(
  p_status text default 'approved',
  p_limit int default 50,
  p_offset int default 0
)
returns table(
  business_id uuid,
  business_name text,
  city text,
  district text,
  claim_status text,
  claimed_at timestamptz
)
language sql
security definer
set search_path to 'public'
as $$
  select
    b.id as business_id,
    b.name as business_name,
    b.city,
    b.district,
    c.status::text as claim_status,
    c.created_at as claimed_at
  from public.owner_claims c
  join public.businesses b on b.id = c.business_id
  where c.user_id = auth.uid()
    and (
      p_status is null
      or p_status = ''
      or c.status::text = p_status
    )
  order by c.created_at desc
  limit greatest(p_limit, 0) offset greatest(p_offset, 0);
$$;

create or replace function public.owner_list_my_business_submissions_v1(
  p_status text default null,
  p_limit int default 50,
  p_offset int default 0
)
returns table(
  id uuid,
  name text,
  city text,
  district text,
  category text,
  address text,
  phone text,
  website text,
  status text,
  admin_note text,
  created_at timestamptz
)
language sql
security definer
set search_path to 'public'
as $$
  select
    s.id,
    s.name,
    s.city,
    s.district,
    s.category,
    s.address,
    s.phone,
    s.website,
    s.status::text,
    s.admin_note,
    s.created_at
  from public.business_submissions s
  where s.submitted_by = auth.uid()
    and (
      p_status is null
      or p_status = ''
      or s.status::text = p_status
    )
  order by s.created_at desc
  limit greatest(p_limit, 0) offset greatest(p_offset, 0);
$$;

create or replace function public.owner_submit_new_business_v1(
  p_name text,
  p_city text,
  p_district text,
  p_category text,
  p_address text,
  p_phone text default null,
  p_website text default null
)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  v_id uuid;
begin
  if auth.uid() is null then
    return jsonb_build_object('ok', false, 'error', 'not_authenticated');
  end if;

  insert into public.business_submissions(
    submitted_by, name, city, district, category, address, phone, website
  )
  values (
    auth.uid(), p_name, p_city, p_district, p_category, p_address, p_phone, p_website
  )
  returning id into v_id;

  return jsonb_build_object('ok', true, 'request_id', v_id);
end;
$$;

create or replace function public.admin_list_business_submissions_v1(
  p_status text default null,
  p_limit int default 50,
  p_offset int default 0
)
returns table(
  id uuid,
  submitted_by uuid,
  name text,
  city text,
  district text,
  category text,
  address text,
  phone text,
  website text,
  status text,
  admin_note text,
  created_at timestamptz
)
language sql
security definer
set search_path to 'public'
as $$
  select
    s.id,
    s.submitted_by,
    s.name,
    s.city,
    s.district,
    s.category,
    s.address,
    s.phone,
    s.website,
    s.status::text,
    s.admin_note,
    s.created_at
  from public.business_submissions s
  where public.is_admin()
    and (
      p_status is null
      or p_status = ''
      or s.status::text = p_status
    )
  order by s.created_at desc
  limit greatest(p_limit, 0) offset greatest(p_offset, 0);
$$;

create or replace function public.admin_approve_business_submission_v1(
  p_submission_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  v_sub record;
  v_business_id uuid;
begin
  if not public.is_admin() then
    return jsonb_build_object('ok', false, 'error', 'not_admin');
  end if;

  select *
    into v_sub
  from public.business_submissions
  where id = p_submission_id;

  if not found then
    return jsonb_build_object('ok', false, 'error', 'not_found');
  end if;

  if v_sub.status <> 'new' then
    return jsonb_build_object('ok', false, 'error', 'invalid_status');
  end if;

  insert into public.businesses(
    name, category, address, city, district, phone, source, source_id
  )
  values (
    v_sub.name, v_sub.category, v_sub.address, v_sub.city, v_sub.district, v_sub.phone,
    'submission', v_sub.id::text
  )
  returning id into v_business_id;

  insert into public.owner_claims(
    business_id, user_id, status, created_at
  )
  values (
    v_business_id, v_sub.submitted_by, 'approved', now()
  )
  on conflict do nothing;

  update public.business_submissions
  set status = 'approved'
  where id = v_sub.id;

  return jsonb_build_object('ok', true, 'business_id', v_business_id);
end;
$$;

create or replace function public.admin_reject_business_submission_v1(
  p_submission_id uuid,
  p_note text default null
)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $$
begin
  if not public.is_admin() then
    return jsonb_build_object('ok', false, 'error', 'not_admin');
  end if;

  update public.business_submissions
  set status = 'rejected',
      admin_note = p_note
  where id = p_submission_id;

  if not found then
    return jsonb_build_object('ok', false, 'error', 'not_found');
  end if;

  return jsonb_build_object('ok', true);
end;
$$;

-- ===== END MIGRATION: 20260223_000001_business_submissions.sql =====

-- ===== BEGIN MIGRATION: 20260226_000001_placeholder.sql =====
-- placeholder to keep local migration history aligned with remote

-- ===== END MIGRATION: 20260226_000001_placeholder.sql =====

-- ===== BEGIN MIGRATION: 20260227_000001_placeholder.sql =====
-- placeholder to keep local migration history aligned with remote

-- ===== END MIGRATION: 20260227_000001_placeholder.sql =====

-- ===== BEGIN MIGRATION: 20260228_000001_placeholder.sql =====
-- placeholder to keep local migration history aligned with remote

-- ===== END MIGRATION: 20260228_000001_placeholder.sql =====

-- ===== BEGIN MIGRATION: 20260229_000001_placeholder.sql =====
-- placeholder to keep local migration history aligned with remote

-- ===== END MIGRATION: 20260229_000001_placeholder.sql =====

-- ===== BEGIN MIGRATION: 20260301_000001_placeholder.sql =====
-- placeholder to keep local migration history aligned with remote

-- ===== END MIGRATION: 20260301_000001_placeholder.sql =====

-- ===== BEGIN MIGRATION: 20260302_000001_placeholder.sql =====
-- placeholder to keep local migration history aligned with remote

-- ===== END MIGRATION: 20260302_000001_placeholder.sql =====

-- ===== BEGIN MIGRATION: 20260303_000001_placeholder.sql =====
-- placeholder to keep local migration history aligned with remote

-- ===== END MIGRATION: 20260303_000001_placeholder.sql =====

-- ===== BEGIN MIGRATION: 20260304_000001_item_trends_and_value_score.sql =====
-- Business item trends (last 7 days)
create or replace view public.business_item_trends_v1 as
with price_votes as (
  select
    v.menu_item_id,
    count(*) filter (
      where v.vote = 1
        and v.created_at >= now() - interval '7 days'
    ) as price_votes_7d
  from public.menu_item_price_votes v
  group by v.menu_item_id
),
photo_votes as (
  select
    p.menu_item_id,
    count(*) filter (
      where v.vote = 1
        and v.created_at >= now() - interval '7 days'
    ) as photo_votes_7d
  from public.menu_item_photo_votes v
  join public.menu_item_photos p on p.id = v.photo_id
  group by p.menu_item_id
),
price_changes as (
  select
    h.menu_item_id,
    count(*) filter (
      where h.created_at >= now() - interval '7 days'
    ) as price_changes_7d
  from public.menu_item_price_history h
  group by h.menu_item_id
)
select
  mi.id as menu_item_id,
  mi.business_id,
  coalesce(pv.price_votes_7d, 0) as price_votes_7d,
  coalesce(phv.photo_votes_7d, 0) as photo_votes_7d,
  0::int as menu_item_views_7d,
  coalesce(pc.price_changes_7d, 0) as price_changes_7d,
  (
    coalesce(pv.price_votes_7d, 0) * 3
    + coalesce(phv.photo_votes_7d, 0) * 2
    + coalesce(pc.price_changes_7d, 0)
  )::int as score
from public.menu_items mi
left join price_votes pv on pv.menu_item_id = mi.id
left join photo_votes phv on phv.menu_item_id = mi.id
left join price_changes pc on pc.menu_item_id = mi.id;

create or replace function public.get_business_trending_items_v1(
  p_business_id uuid,
  p_limit int default 6
)
returns table(
  menu_item_id uuid,
  item_name text,
  price_cents int,
  currency text,
  score int
)
language sql
stable
security definer
set search_path to 'public'
as $$
  select
    mi.id as menu_item_id,
    mi.name as item_name,
    mi.price_cents,
    mi.currency,
    t.score
  from public.business_item_trends_v1 t
  join public.menu_items mi on mi.id = t.menu_item_id
  where t.business_id = p_business_id
  order by t.score desc, mi.updated_at desc nulls last, mi.created_at desc
  limit p_limit;
$$;

-- Menu item value score (F/P)
create or replace view public.menu_item_value_score_v1 as
with votes_all as (
  select
    v.menu_item_id,
    count(*) filter (where v.vote = 1) as pos_votes,
    count(*) as total_votes
  from public.menu_item_price_votes v
  group by v.menu_item_id
),
votes_30d as (
  select
    v.menu_item_id,
    count(*) filter (
      where v.vote = 1
        and v.created_at >= now() - interval '30 days'
    ) as pos_votes_30d,
    count(*) filter (
      where v.created_at >= now() - interval '30 days'
    ) as total_votes_30d
  from public.menu_item_price_votes v
  group by v.menu_item_id
),
price_changes_30d as (
  select
    h.menu_item_id,
    count(*) filter (
      where h.created_at >= now() - interval '30 days'
    ) as changes_30d
  from public.menu_item_price_history h
  group by h.menu_item_id
)
select
  mi.id as menu_item_id,
  coalesce(va.pos_votes::float / nullif(va.total_votes, 0), 0) as verified_ratio,
  coalesce(v30.pos_votes_30d::float / nullif(v30.total_votes_30d, 0), 0) as recent_positive_ratio,
  (1 - least(coalesce(pc.changes_30d, 0) / 5.0, 1.0))::float as price_stability,
  coalesce(pc.changes_30d, 0) as price_changes_30d,
  (
    coalesce(va.pos_votes::float / nullif(va.total_votes, 0), 0) * 0.4
    + coalesce(v30.pos_votes_30d::float / nullif(v30.total_votes_30d, 0), 0) * 0.3
    + (1 - least(coalesce(pc.changes_30d, 0) / 5.0, 1.0)) * 0.3
  )::float as value_score
from public.menu_items mi
left join votes_all va on va.menu_item_id = mi.id
left join votes_30d v30 on v30.menu_item_id = mi.id
left join price_changes_30d pc on pc.menu_item_id = mi.id;

create or replace function public.get_menu_item_value_score_v1(
  p_menu_item_id uuid
)
returns jsonb
language sql
stable
security definer
set search_path to 'public'
as $$
  select jsonb_build_object(
    'score', coalesce(v.value_score, 0),
    'breakdown', jsonb_build_object(
      'verified_ratio', coalesce(v.verified_ratio, 0),
      'recent_positive_ratio', coalesce(v.recent_positive_ratio, 0),
      'price_stability', coalesce(v.price_stability, 0),
      'price_changes_30d', coalesce(v.price_changes_30d, 0)
    )
  )
  from public.menu_item_value_score_v1 v
  where v.menu_item_id = p_menu_item_id;
$$;

-- ===== END MIGRATION: 20260304_000001_item_trends_and_value_score.sql =====

-- ===== BEGIN MIGRATION: 20260305_000001_budget_combos.sql =====
create or replace function public.get_budget_combos_v1(
  p_city text,
  p_district text,
  p_party_size int,
  p_budget_total_cents int,
  p_category text default null,
  p_limit int default 30
)
returns table(
  business_id uuid,
  business_name text,
  combo jsonb,
  total_cents int
)
language sql
stable
security definer
set search_path to 'public'
as $$
  with base_businesses as (
    select b.id, b.name
    from public.businesses b
    where b.city = p_city
      and (p_district is null or b.district = p_district)
      and (p_category is null or b.category = p_category)
  ),
  main_items as (
    select
      b.id as business_id,
      mi.id as menu_item_id,
      mi.name,
      mi.price_cents,
      mi.currency,
      row_number() over (
        partition by b.id
        order by coalesce(v.verified_ratio, 0) desc,
                 mi.price_cents asc nulls last,
                 mi.created_at desc
      ) as rn
    from base_businesses b
    join public.menu_items mi on mi.business_id = b.id
    left join public.menu_item_value_score_v1 v on v.menu_item_id = mi.id
    left join public.menu_sections s on s.id = mi.section_id
    where mi.status = 'published'
      and mi.price_cents is not null
      and not (
        (s.title is not null and lower(s.title) like any(
          array['%icecek%','%icki%','%drink%','%beverage%']
        ))
        or (lower(mi.name) like any(
          array[
            '%cola%','%soda%','%gazoz%','%su%','%ayran%','%limonata%','%cay%','%kahve%','%juice%','%smoothie%','%bira%','%wine%','%sarap%'
          ]
        ))
      )
  ),
  mains as (
    select * from main_items where rn <= 3
  ),
  drink_items as (
    select
      b.id as business_id,
      mi.id as menu_item_id,
      mi.name,
      mi.price_cents,
      mi.currency,
      row_number() over (
        partition by b.id
        order by mi.price_cents asc nulls last, mi.created_at desc
      ) as rn
    from base_businesses b
    join public.menu_items mi on mi.business_id = b.id
    left join public.menu_sections s on s.id = mi.section_id
    where mi.status = 'published'
      and mi.price_cents is not null
      and (
        (s.title is not null and lower(s.title) like any(
          array['%icecek%','%icki%','%drink%','%beverage%']
        ))
        or (lower(mi.name) like any(
          array[
            '%cola%','%soda%','%gazoz%','%su%','%ayran%','%limonata%','%cay%','%kahve%','%juice%','%smoothie%','%bira%','%wine%','%sarap%'
          ]
        ))
      )
  ),
  drinks as (
    select * from drink_items where rn <= 2
  ),
  combos_main_only as (
    select
      b.id as business_id,
      b.name as business_name,
      jsonb_build_object(
        'main', jsonb_build_object(
          'id', m.menu_item_id,
          'name', m.name,
          'price_cents', m.price_cents,
          'currency', m.currency
        ),
        'drink', null
      ) as combo,
      (m.price_cents * p_party_size)::int as total_cents
    from base_businesses b
    join mains m on m.business_id = b.id
  ),
  combos_with_drink as (
    select
      b.id as business_id,
      b.name as business_name,
      jsonb_build_object(
        'main', jsonb_build_object(
          'id', m.menu_item_id,
          'name', m.name,
          'price_cents', m.price_cents,
          'currency', m.currency
        ),
        'drink', jsonb_build_object(
          'id', d.menu_item_id,
          'name', d.name,
          'price_cents', d.price_cents,
          'currency', d.currency
        )
      ) as combo,
      ((m.price_cents + d.price_cents) * p_party_size)::int as total_cents
    from base_businesses b
    join mains m on m.business_id = b.id
    join drinks d on d.business_id = b.id
  ),
  all_combos as (
    select * from combos_main_only
    union all
    select * from combos_with_drink
  )
  select business_id, business_name, combo, total_cents
  from all_combos
  where total_cents <= p_budget_total_cents
  order by total_cents asc
  limit p_limit;
$$;


-- ===== END MIGRATION: 20260305_000001_budget_combos.sql =====

-- ===== BEGIN MIGRATION: 20260306_000001_new_items_feed.sql =====
-- add new_item to feed_events type check
DO $$
begin
  if exists (
    select 1
    from pg_constraint
    where conname = 'feed_events_type_check'
      and conrelid = 'public.feed_events'::regclass
  ) then
    alter table public.feed_events drop constraint feed_events_type_check;
  end if;
  alter table public.feed_events
    add constraint feed_events_type_check
    check (type in ('menu_update','story_posted','price_verified','sponsored','new_item'));
end $$;

create or replace function public.handle_menu_item_new_feed()
returns trigger
language plpgsql
security definer
set search_path to 'public'
as $function$
begin
  if new.status = 'published' then
    insert into public.feed_events (business_id, type, ref_id, meta)
    values (
      new.business_id,
      'new_item',
      new.id,
      jsonb_build_object(
        'title', 'Yeni urun eklendi',
        'item_name', new.name,
        'price_cents', new.price_cents,
        'currency', new.currency
      )
    );
  end if;
  return new;
end;
$function$;

drop trigger if exists trg_menu_items_new_feed on public.menu_items;
create trigger trg_menu_items_new_feed
after insert on public.menu_items
for each row
execute function public.handle_menu_item_new_feed();

create or replace function public.get_business_new_items_v1(
  p_business_id uuid,
  p_limit int default 6
)
returns table(
  menu_item_id uuid,
  item_name text,
  price_cents int,
  currency text,
  created_at timestamptz
)
language sql
stable
security definer
set search_path to 'public'
as $$
  select
    mi.id as menu_item_id,
    mi.name as item_name,
    mi.price_cents,
    mi.currency,
    mi.created_at
  from public.menu_items mi
  where mi.business_id = p_business_id
    and mi.status = 'published'
    and mi.created_at >= now() - interval '7 days'
  order by mi.created_at desc
  limit p_limit;
$$;

-- ===== END MIGRATION: 20260306_000001_new_items_feed.sql =====

-- ===== BEGIN MIGRATION: 20260307_000001_business_perks.sql =====
create table if not exists public.business_perks (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses(id) on delete cascade,
  title text not null,
  description text null,
  starts_at timestamptz null,
  ends_at timestamptz null,
  requires_checkin boolean not null default true,
  status text not null default 'active',
  created_by uuid null,
  created_at timestamptz not null default now()
);

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'business_perks_status_check'
      and conrelid = 'public.business_perks'::regclass
  ) then
    alter table public.business_perks
      add constraint business_perks_status_check
      check (status in ('active','ended','paused'));
  end if;
end $$;

create index if not exists business_perks_business_status_idx
  on public.business_perks (business_id, status, starts_at, ends_at);

-- expand feed_events type check to include perk
DO $$
begin
  if exists (
    select 1
    from pg_constraint
    where conname = 'feed_events_type_check'
      and conrelid = 'public.feed_events'::regclass
  ) then
    alter table public.feed_events drop constraint feed_events_type_check;
  end if;
  alter table public.feed_events
    add constraint feed_events_type_check
    check (type in ('menu_update','story_posted','price_verified','sponsored','new_item','perk'));
end $$;

create or replace function public.handle_business_perk_feed()
returns trigger
language plpgsql
security definer
set search_path to 'public'
as $function$
begin
  if (tg_op = 'INSERT' or old.status is distinct from new.status)
     and new.status = 'active'
     and (new.starts_at is null or new.starts_at <= now())
     and (new.ends_at is null or new.ends_at >= now()) then
    insert into public.feed_events (business_id, type, ref_id, meta)
    values (
      new.business_id,
      'perk',
      new.id,
      jsonb_build_object(
        'title', new.title,
        'description', new.description,
        'starts_at', new.starts_at,
        'ends_at', new.ends_at,
        'requires_checkin', new.requires_checkin
      )
    );
  end if;
  return new;
end;
$function$;

drop trigger if exists trg_business_perks_feed on public.business_perks;
create trigger trg_business_perks_feed
after insert or update on public.business_perks
for each row
execute function public.handle_business_perk_feed();

create or replace function public.owner_create_perk_v1(
  p_business_id uuid,
  p_title text,
  p_description text default null,
  p_starts_at timestamptz default null,
  p_ends_at timestamptz default null,
  p_requires_checkin boolean default true
) returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $function$
declare
  v_title text;
  v_id uuid;
begin
  if auth.uid() is null then
    return jsonb_build_object('ok', false, 'code', 'not_authenticated');
  end if;

  if not (public.is_admin() or public.is_owner_of_business(p_business_id)) then
    return jsonb_build_object('ok', false, 'code', 'not_owner');
  end if;

  v_title := nullif(trim(p_title), '');
  if v_title is null then
    return jsonb_build_object('ok', false, 'code', 'invalid', 'message', 'Title required');
  end if;

  if p_starts_at is not null and p_ends_at is not null and p_starts_at > p_ends_at then
    return jsonb_build_object('ok', false, 'code', 'invalid', 'message', 'Invalid date range');
  end if;

  insert into public.business_perks(
    business_id,
    title,
    description,
    starts_at,
    ends_at,
    requires_checkin,
    status,
    created_by
  ) values (
    p_business_id,
    v_title,
    nullif(trim(p_description), ''),
    p_starts_at,
    p_ends_at,
    coalesce(p_requires_checkin, true),
    'active',
    auth.uid()
  ) returning id into v_id;

  return jsonb_build_object('ok', true, 'id', v_id);
end;
$function$;

create or replace function public.owner_set_perk_status_v1(
  p_perk_id uuid,
  p_status text
) returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $function$
declare
  v_business_id uuid;
  v_status text;
begin
  if auth.uid() is null then
    return jsonb_build_object('ok', false, 'code', 'not_authenticated');
  end if;

  select business_id into v_business_id
  from public.business_perks
  where id = p_perk_id;

  if v_business_id is null then
    return jsonb_build_object('ok', false, 'code', 'not_found');
  end if;

  if not (public.is_admin() or public.is_owner_of_business(v_business_id)) then
    return jsonb_build_object('ok', false, 'code', 'not_owner');
  end if;

  v_status := nullif(trim(p_status), '');
  if v_status is null or v_status not in ('active','paused','ended') then
    return jsonb_build_object('ok', false, 'code', 'invalid');
  end if;

  update public.business_perks
  set status = v_status
  where id = p_perk_id;

  return jsonb_build_object('ok', true);
end;
$function$;

create or replace function public.get_active_perks_v1(
  p_business_id uuid
) returns table(
  id uuid,
  business_id uuid,
  title text,
  description text,
  starts_at timestamptz,
  ends_at timestamptz,
  requires_checkin boolean,
  status text,
  created_at timestamptz
)
language sql
stable
security definer
set search_path to 'public'
as $$
  select
    p.id,
    p.business_id,
    p.title,
    p.description,
    p.starts_at,
    p.ends_at,
    p.requires_checkin,
    p.status,
    p.created_at
  from public.business_perks p
  where p.business_id = p_business_id
    and p.status = 'active'
    and (p.starts_at is null or p.starts_at <= now())
    and (p.ends_at is null or p.ends_at >= now())
  order by p.created_at desc;
$$;

create or replace function public.owner_list_perks_v1(
  p_business_id uuid
) returns table(
  id uuid,
  business_id uuid,
  title text,
  description text,
  starts_at timestamptz,
  ends_at timestamptz,
  requires_checkin boolean,
  status text,
  created_at timestamptz
)
language sql
stable
security definer
set search_path to 'public'
as $$
  select
    p.id,
    p.business_id,
    p.title,
    p.description,
    p.starts_at,
    p.ends_at,
    p.requires_checkin,
    p.status,
    p.created_at
  from public.business_perks p
  where p.business_id = p_business_id
  order by p.created_at desc;
$$;

create or replace function public.get_perk_feed_v1(
  p_limit int default 30,
  p_offset int default 0,
  p_city text default null,
  p_district text default null,
  p_category text default null
) returns table(
  event_id uuid,
  business_id uuid,
  business_name text,
  title text,
  description text,
  starts_at timestamptz,
  ends_at timestamptz,
  created_at timestamptz
)
language sql
stable
security definer
set search_path to 'public'
as $$
  select
    e.id as event_id,
    e.business_id,
    b.name as business_name,
    (e.meta->>'title')::text as title,
    (e.meta->>'description')::text as description,
    nullif(e.meta->>'starts_at','')::timestamptz as starts_at,
    nullif(e.meta->>'ends_at','')::timestamptz as ends_at,
    e.created_at
  from public.feed_events e
  join public.businesses b on b.id = e.business_id
  where e.type = 'perk'
    and (p_city is null or b.city = p_city)
    and (p_district is null or b.district = p_district)
    and (p_category is null or b.category = p_category)
  order by e.created_at desc
  limit greatest(p_limit, 0)
  offset greatest(p_offset, 0);
$$;

-- ===== END MIGRATION: 20260307_000001_business_perks.sql =====

-- ===== BEGIN MIGRATION: 20260308_000001_photo_missions.sql =====
create table if not exists public.photo_missions (
  id uuid primary key default gen_random_uuid(),
  city text null,
  district text null,
  mission_type text not null,
  business_id uuid not null references public.businesses(id) on delete cascade,
  reward_points int not null default 10,
  expires_at timestamptz null,
  created_at timestamptz not null default now()
);

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'photo_missions_type_check'
      and conrelid = 'public.photo_missions'::regclass
  ) then
    alter table public.photo_missions
      add constraint photo_missions_type_check
      check (mission_type in ('missing_menu_photo','stale_menu_photo'));
  end if;
end $$;

create index if not exists photo_missions_city_idx
  on public.photo_missions (city, district, created_at desc);

create index if not exists photo_missions_business_idx
  on public.photo_missions (business_id, mission_type, created_at desc);

create table if not exists public.user_mission_claims (
  id uuid primary key default gen_random_uuid(),
  mission_id uuid not null references public.photo_missions(id) on delete cascade,
  user_id uuid not null,
  status text not null default 'claimed',
  photo_id uuid null references public.menu_item_photos(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'user_mission_claims_status_check'
      and conrelid = 'public.user_mission_claims'::regclass
  ) then
    alter table public.user_mission_claims
      add constraint user_mission_claims_status_check
      check (status in ('claimed','submitted','approved','rejected'));
  end if;
end $$;

create unique index if not exists user_mission_claims_unique
  on public.user_mission_claims (mission_id, user_id);

create index if not exists user_mission_claims_user_idx
  on public.user_mission_claims (user_id, status, created_at desc);

create table if not exists public.user_points (
  user_id uuid primary key,
  points int not null default 0,
  updated_at timestamptz not null default now()
);

alter table public.photo_missions enable row level security;
alter table public.user_mission_claims enable row level security;
alter table public.user_points enable row level security;

drop policy if exists photo_missions_read_all on public.photo_missions;
create policy photo_missions_read_all
  on public.photo_missions
  for select
  using (true);

drop policy if exists user_mission_claims_owner_select on public.user_mission_claims;
create policy user_mission_claims_owner_select
  on public.user_mission_claims
  for select
  using (user_id = auth.uid());

drop policy if exists user_mission_claims_owner_write on public.user_mission_claims;
create policy user_mission_claims_owner_write
  on public.user_mission_claims
  for insert
  with check (user_id = auth.uid());

drop policy if exists user_mission_claims_owner_update on public.user_mission_claims;
create policy user_mission_claims_owner_update
  on public.user_mission_claims
  for update
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

drop policy if exists user_mission_claims_admin_all on public.user_mission_claims;
create policy user_mission_claims_admin_all
  on public.user_mission_claims
  for all
  using (public.is_admin());

drop policy if exists user_points_owner_select on public.user_points;
create policy user_points_owner_select
  on public.user_points
  for select
  using (user_id = auth.uid());

drop policy if exists user_points_admin_all on public.user_points;
create policy user_points_admin_all
  on public.user_points
  for all
  using (public.is_admin());

create or replace function public.get_photo_missions_v1(
  p_city text default null,
  p_district text default null,
  p_limit int default 20
) returns table(
  mission_id uuid,
  business_id uuid,
  business_name text,
  city text,
  district text,
  mission_type text,
  reward_points int,
  expires_at timestamptz,
  created_at timestamptz,
  my_status text,
  my_claim_id uuid
)
language sql
stable
security definer
set search_path to 'public'
as $$
  select
    m.id as mission_id,
    m.business_id,
    b.name as business_name,
    coalesce(m.city, b.city) as city,
    coalesce(m.district, b.district) as district,
    m.mission_type,
    m.reward_points,
    m.expires_at,
    m.created_at,
    c.status as my_status,
    c.id as my_claim_id
  from public.photo_missions m
  join public.businesses b on b.id = m.business_id
  left join public.user_mission_claims c
    on c.mission_id = m.id and c.user_id = auth.uid()
  where (m.expires_at is null or m.expires_at >= now())
    and (p_city is null or coalesce(m.city, b.city) = p_city)
    and (p_district is null or coalesce(m.district, b.district) = p_district)
  order by m.created_at desc
  limit greatest(p_limit, 0);
$$;

create or replace function public.claim_mission_v1(
  p_mission_id uuid
) returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $function$
declare
  v_exists uuid;
begin
  if auth.uid() is null then
    return jsonb_build_object('ok', false, 'code', 'not_authenticated');
  end if;

  select id into v_exists
  from public.photo_missions
  where id = p_mission_id
    and (expires_at is null or expires_at >= now());

  if v_exists is null then
    return jsonb_build_object('ok', false, 'code', 'not_found');
  end if;

  insert into public.user_mission_claims(mission_id, user_id, status)
  values (p_mission_id, auth.uid(), 'claimed')
  on conflict (mission_id, user_id) do update
    set updated_at = now()
  returning id into v_exists;

  return jsonb_build_object('ok', true, 'claim_id', v_exists);
end;
$function$;

create or replace function public.submit_mission_proof_v1(
  p_mission_id uuid,
  p_photo_id uuid
) returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $function$
declare
  v_claim_id uuid;
  v_business_id uuid;
  v_photo_business uuid;
begin
  if auth.uid() is null then
    return jsonb_build_object('ok', false, 'code', 'not_authenticated');
  end if;

  select business_id into v_business_id
  from public.photo_missions
  where id = p_mission_id;

  if v_business_id is null then
    return jsonb_build_object('ok', false, 'code', 'not_found');
  end if;

  select business_id into v_photo_business
  from public.menu_item_photos
  where id = p_photo_id;

  if v_photo_business is null or v_photo_business <> v_business_id then
    return jsonb_build_object('ok', false, 'code', 'invalid_photo');
  end if;

  select id into v_claim_id
  from public.user_mission_claims
  where mission_id = p_mission_id and user_id = auth.uid();

  if v_claim_id is null then
    return jsonb_build_object('ok', false, 'code', 'not_claimed');
  end if;

  update public.user_mission_claims
  set status = 'submitted',
      photo_id = p_photo_id,
      updated_at = now()
  where id = v_claim_id;

  return jsonb_build_object('ok', true, 'claim_id', v_claim_id);
end;
$function$;

create or replace function public.admin_list_mission_claims_v1(
  p_status text default 'submitted',
  p_limit int default 50,
  p_offset int default 0
) returns table(
  claim_id uuid,
  status text,
  created_at timestamptz,
  mission_id uuid,
  mission_type text,
  business_id uuid,
  business_name text,
  user_id uuid,
  photo_id uuid,
  reward_points int
)
language sql
stable
security definer
set search_path to 'public'
as $$
  select
    c.id as claim_id,
    c.status,
    c.created_at,
    m.id as mission_id,
    m.mission_type,
    m.business_id,
    b.name as business_name,
    c.user_id,
    c.photo_id,
    m.reward_points
  from public.user_mission_claims c
  join public.photo_missions m on m.id = c.mission_id
  join public.businesses b on b.id = m.business_id
  where (p_status is null or c.status = p_status)
  order by c.created_at desc
  limit greatest(p_limit, 0)
  offset greatest(p_offset, 0);
$$;

create or replace function public.admin_approve_mission_claim_v1(
  p_claim_id uuid
) returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $function$
declare
  v_user_id uuid;
  v_points int;
begin
  if not public.is_admin() then
    return jsonb_build_object('ok', false, 'code', 'not_admin');
  end if;

  select c.user_id, m.reward_points
    into v_user_id, v_points
  from public.user_mission_claims c
  join public.photo_missions m on m.id = c.mission_id
  where c.id = p_claim_id;

  if v_user_id is null then
    return jsonb_build_object('ok', false, 'code', 'not_found');
  end if;

  update public.user_mission_claims
  set status = 'approved',
      updated_at = now()
  where id = p_claim_id;

  insert into public.user_points(user_id, points, updated_at)
  values (v_user_id, coalesce(v_points, 0), now())
  on conflict (user_id) do update
    set points = public.user_points.points + coalesce(excluded.points, 0),
        updated_at = now();

  return jsonb_build_object('ok', true);
end;
$function$;

create or replace function public.admin_reject_mission_claim_v1(
  p_claim_id uuid
) returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $function$
begin
  if not public.is_admin() then
    return jsonb_build_object('ok', false, 'code', 'not_admin');
  end if;

  update public.user_mission_claims
  set status = 'rejected',
      updated_at = now()
  where id = p_claim_id;

  return jsonb_build_object('ok', true);
end;
$function$;

create or replace function public.get_my_points_v1()
returns jsonb
language sql
stable
security definer
set search_path to 'public'
as $$
  select jsonb_build_object(
    'points',
    coalesce((select points from public.user_points where user_id = auth.uid()), 0)
  );
$$;

create or replace function public.generate_photo_missions_v1(
  p_city text default null,
  p_district text default null,
  p_limit int default 200
) returns int
language plpgsql
security definer
set search_path to 'public'
as $function$
declare
  v_count int := 0;
  v_add int := 0;
begin
  insert into public.photo_missions(business_id, city, district, mission_type, reward_points, expires_at)
  select
    b.id,
    b.city,
    b.district,
    'missing_menu_photo',
    10,
    now() + interval '14 days'
  from public.businesses b
  left join public.business_media bm on bm.business_id = b.id
  where bm.id is null
    and (p_city is null or b.city = p_city)
    and (p_district is null or b.district = p_district)
    and not exists (
      select 1
      from public.photo_missions m
      where m.business_id = b.id
        and m.mission_type = 'missing_menu_photo'
        and (m.expires_at is null or m.expires_at >= now())
    )
  limit greatest(p_limit, 0);

  get diagnostics v_count = row_count;

  insert into public.photo_missions(business_id, city, district, mission_type, reward_points, expires_at)
  select
    b.id,
    b.city,
    b.district,
    'stale_menu_photo',
    10,
    now() + interval '14 days'
  from public.businesses b
  join (
    select business_id, max(created_at) as last_photo_at
    from public.business_media
    group by business_id
  ) bm on bm.business_id = b.id
  where bm.last_photo_at < now() - interval '30 days'
    and (p_city is null or b.city = p_city)
    and (p_district is null or b.district = p_district)
    and not exists (
      select 1
      from public.photo_missions m
      where m.business_id = b.id
        and m.mission_type = 'stale_menu_photo'
        and (m.expires_at is null or m.expires_at >= now())
    )
  limit greatest(p_limit, 0);

  get diagnostics v_add = row_count;
  v_count := v_count + v_add;
  return v_count;
end;
$function$;

create or replace function public.add_menu_item_photo_v1(
  p_menu_item_id uuid,
  p_url text,
  p_url_large text default null,
  p_url_thumb text default null,
  p_provider text default 'wp'
) returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $function$
declare
  v_business_id uuid;
  v_photo_id uuid;
begin
  if auth.uid() is null then
    return jsonb_build_object('ok', false, 'error', 'not_authenticated');
  end if;

  select business_id into v_business_id
  from public.menu_items
  where id = p_menu_item_id;

  if v_business_id is null then
    return jsonb_build_object('ok', false, 'error', 'not_found');
  end if;

  insert into public.menu_item_photos(
    menu_item_id,
    business_id,
    url,
    url_large,
    url_thumb,
    provider,
    created_by
  )
  values (
    p_menu_item_id,
    v_business_id,
    p_url,
    p_url_large,
    p_url_thumb,
    p_provider,
    auth.uid()
  )
  returning id into v_photo_id;

  return jsonb_build_object('ok', true, 'photo_id', v_photo_id);
end;
$function$;

-- ===== END MIGRATION: 20260308_000001_photo_missions.sql =====

-- ===== BEGIN MIGRATION: 20260309_000001_receipt_ocr.sql =====
create table if not exists public.receipt_submissions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null,
  business_id uuid not null references public.businesses(id) on delete cascade,
  image_url text not null,
  created_at timestamptz not null default now()
);

create table if not exists public.receipt_matches (
  receipt_id uuid not null references public.receipt_submissions(id) on delete cascade,
  menu_item_id uuid not null references public.menu_items(id) on delete cascade,
  detected_price_cents int not null,
  primary key (receipt_id, menu_item_id)
);

create index if not exists receipt_submissions_user_idx
  on public.receipt_submissions (user_id, created_at desc);

create index if not exists receipt_submissions_business_idx
  on public.receipt_submissions (business_id, created_at desc);

create index if not exists receipt_matches_receipt_idx
  on public.receipt_matches (receipt_id);

alter table public.receipt_submissions enable row level security;
alter table public.receipt_matches enable row level security;

drop policy if exists receipt_submissions_owner_select on public.receipt_submissions;
create policy receipt_submissions_owner_select
  on public.receipt_submissions
  for select
  using (user_id = auth.uid());

drop policy if exists receipt_submissions_owner_insert on public.receipt_submissions;
create policy receipt_submissions_owner_insert
  on public.receipt_submissions
  for insert
  with check (user_id = auth.uid());

drop policy if exists receipt_submissions_admin_all on public.receipt_submissions;
create policy receipt_submissions_admin_all
  on public.receipt_submissions
  for all
  using (public.is_admin());

drop policy if exists receipt_matches_owner_select on public.receipt_matches;
create policy receipt_matches_owner_select
  on public.receipt_matches
  for select
  using (
    exists (
      select 1
      from public.receipt_submissions s
      where s.id = receipt_id
        and s.user_id = auth.uid()
    )
  );

drop policy if exists receipt_matches_owner_insert on public.receipt_matches;
create policy receipt_matches_owner_insert
  on public.receipt_matches
  for insert
  with check (
    exists (
      select 1
      from public.receipt_submissions s
      where s.id = receipt_id
        and s.user_id = auth.uid()
    )
  );

drop policy if exists receipt_matches_admin_all on public.receipt_matches;
create policy receipt_matches_admin_all
  on public.receipt_matches
  for all
  using (public.is_admin());

create or replace function public.submit_receipt_submission_v1(
  p_business_id uuid,
  p_image_url text,
  p_matches jsonb default '[]'::jsonb
) returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $function$
declare
  v_id uuid;
begin
  if auth.uid() is null then
    return jsonb_build_object('ok', false, 'code', 'not_authenticated');
  end if;

  if p_image_url is null or length(trim(p_image_url)) = 0 then
    return jsonb_build_object('ok', false, 'code', 'invalid_image');
  end if;

  insert into public.receipt_submissions(user_id, business_id, image_url)
  values (auth.uid(), p_business_id, trim(p_image_url))
  returning id into v_id;

  insert into public.receipt_matches(receipt_id, menu_item_id, detected_price_cents)
  select
    v_id,
    (m->>'menu_item_id')::uuid,
    greatest(((m->>'detected_price_cents')::int), 0)
  from jsonb_array_elements(coalesce(p_matches, '[]'::jsonb)) as m
  join public.menu_items mi on mi.id = (m->>'menu_item_id')::uuid
  where mi.business_id = p_business_id
    and (m->>'detected_price_cents') is not null;

  return jsonb_build_object('ok', true, 'id', v_id);
end;
$function$;

create or replace function public.admin_list_receipt_submissions_v1(
  p_limit int default 50,
  p_offset int default 0
) returns table(
  receipt_id uuid,
  created_at timestamptz,
  user_id uuid,
  business_id uuid,
  business_name text,
  image_url text,
  matches_count int
)
language sql
stable
security definer
set search_path to 'public'
as $$
  select
    s.id as receipt_id,
    s.created_at,
    s.user_id,
    s.business_id,
    b.name as business_name,
    s.image_url,
    coalesce(m.cnt, 0) as matches_count
  from public.receipt_submissions s
  join public.businesses b on b.id = s.business_id
  left join (
    select receipt_id, count(*)::int as cnt
    from public.receipt_matches
    group by receipt_id
  ) m on m.receipt_id = s.id
  where public.is_admin()
  order by s.created_at desc
  limit greatest(p_limit, 0)
  offset greatest(p_offset, 0);
$$;

-- ===== END MIGRATION: 20260309_000001_receipt_ocr.sql =====

-- ===== BEGIN MIGRATION: 20260310_000001_business_checkins.sql =====
create table if not exists public.business_checkins (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses(id) on delete cascade,
  menu_id uuid null references public.menus(id) on delete set null,
  table_no text null,
  client_id text not null,
  user_id uuid null,
  created_at timestamptz not null default now()
);

create index if not exists business_checkins_business_created_idx
  on public.business_checkins (business_id, created_at desc);

create index if not exists business_checkins_client_created_idx
  on public.business_checkins (client_id, created_at desc);

alter table public.business_checkins enable row level security;

drop policy if exists business_checkins_admin_all on public.business_checkins;
create policy business_checkins_admin_all
  on public.business_checkins
  for all
  using (public.is_admin())
  with check (public.is_admin());

create or replace function public.log_checkin_v1(
  p_business_id uuid,
  p_menu_id uuid default null,
  p_table_no text default null,
  p_client_id text default null
) returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $function$
declare
  v_client_id text := nullif(trim(coalesce(p_client_id, '')), '');
  v_table_no text := nullif(trim(coalesce(p_table_no, '')), '');
  v_exists uuid;
begin
  if p_business_id is null then
    return jsonb_build_object('ok', false, 'code', 'invalid_business');
  end if;

  if v_client_id is null then
    return jsonb_build_object('ok', false, 'code', 'client_required');
  end if;

  if not exists (
    select 1 from public.businesses b where b.id = p_business_id
  ) then
    return jsonb_build_object('ok', false, 'code', 'business_not_found');
  end if;

  if p_menu_id is not null and not exists (
    select 1 from public.menus m where m.id = p_menu_id and m.business_id = p_business_id
  ) then
    return jsonb_build_object('ok', false, 'code', 'menu_mismatch');
  end if;

  select c.id into v_exists
  from public.business_checkins c
  where c.business_id = p_business_id
    and c.client_id = v_client_id
    and coalesce(c.table_no, '') = coalesce(v_table_no, '')
    and c.created_at >= now() - interval '10 minutes'
  limit 1;

  if v_exists is not null then
    return jsonb_build_object('ok', true, 'deduped', true, 'id', v_exists);
  end if;

  insert into public.business_checkins(
    business_id,
    menu_id,
    table_no,
    client_id,
    user_id
  )
  values (
    p_business_id,
    p_menu_id,
    v_table_no,
    v_client_id,
    auth.uid()
  )
  returning id into v_exists;

  return jsonb_build_object('ok', true, 'id', v_exists);
end;
$function$;

create or replace function public.get_business_recent_checkins_v1(
  p_business_id uuid,
  p_hours int default 2
) returns jsonb
language sql
stable
security definer
set search_path to 'public'
as $$
  select jsonb_build_object(
    'count',
    coalesce((
      select count(*)::int
      from public.business_checkins c
      where c.business_id = p_business_id
        and c.created_at >= now() - make_interval(hours => greatest(p_hours, 1))
    ), 0)
  );
$$;

create or replace function public.has_recent_checkin_v1(
  p_business_id uuid,
  p_client_id text,
  p_window_minutes int default 120
) returns boolean
language sql
stable
security definer
set search_path to 'public'
as $$
  select exists(
    select 1
    from public.business_checkins c
    where c.business_id = p_business_id
      and c.client_id = nullif(trim(coalesce(p_client_id, '')), '')
      and c.created_at >= now() - make_interval(mins => greatest(p_window_minutes, 1))
  );
$$;

-- ===== END MIGRATION: 20260310_000001_business_checkins.sql =====

-- ===== BEGIN MIGRATION: 20260311_000001_business_quality_score.sql =====
create or replace view public.business_quality_score_v1 as
with menu_items_base as (
  select mi.business_id, mi.id
  from public.menu_items mi
  where mi.status = 'published'
),
verified_stats as (
  select
    mb.business_id,
    count(*)::int as total_items,
    count(*) filter (where ps.price_status = 'verified')::int as verified_items
  from menu_items_base mb
  left join public.menu_item_price_status_v1 ps on ps.menu_item_id = mb.id
  group by mb.business_id
),
last_updates as (
  select
    l.business_id,
    max(l.created_at) filter (where l.type = 'menu_update') as last_menu_update_at
  from public.business_activity_log l
  group by l.business_id
),
photos as (
  select bm.business_id, count(*)::int as photos_count
  from public.business_media bm
  group by bm.business_id
),
amenities as (
  select bam.business_id, count(*)::int as amenities_count
  from public.business_amenity_map bam
  group by bam.business_id
),
pricing as (
  select
    b.id as business_id,
    (pr.business_id is not null) as has_pricing_rule,
    (
      bf.business_id is not null
      and (
        bf.has_cover_charge is not null
        or bf.has_service_fee is not null
        or bf.bottled_water_paid is not null
      )
    ) as has_fee_flags
  from public.businesses b
  left join public.business_pricing_rules pr on pr.business_id = b.id
  left join public.business_fee_flags bf on bf.business_id = b.id
),
weekly_votes as (
  select
    mi.business_id,
    count(*) filter (where v.vote = 1 and v.created_at >= now() - interval '7 days')::int as weekly_verified_votes
  from public.menu_item_price_votes v
  join public.menu_items mi on mi.id = v.menu_item_id
  group by mi.business_id
),
scored as (
  select
    b.id as business_id,
    coalesce(vs.total_items, 0) as total_items,
    coalesce(vs.verified_items, 0) as verified_items,
    coalesce(lu.last_menu_update_at, b.created_at) as last_menu_update_at,
    coalesce(p.photos_count, 0) as photos_count,
    coalesce(a.amenities_count, 0) as amenities_count,
    coalesce(pr.has_pricing_rule, false) as has_pricing_rule,
    coalesce(pr.has_fee_flags, false) as has_fee_flags,
    coalesce(wv.weekly_verified_votes, 0) as weekly_verified_votes
  from public.businesses b
  left join verified_stats vs on vs.business_id = b.id
  left join last_updates lu on lu.business_id = b.id
  left join photos p on p.business_id = b.id
  left join amenities a on a.business_id = b.id
  left join pricing pr on pr.business_id = b.id
  left join weekly_votes wv on wv.business_id = b.id
),
points as (
  select
    s.*,
    case
      when s.total_items = 0 then 0
      else least(40, round((s.verified_items::numeric / nullif(s.total_items, 0)::numeric) * 40))::int
    end as verified_points,
    case
      when s.last_menu_update_at >= now() - interval '3 days' then 20
      when s.last_menu_update_at >= now() - interval '7 days' then 16
      when s.last_menu_update_at >= now() - interval '14 days' then 10
      when s.last_menu_update_at >= now() - interval '30 days' then 5
      else 0
    end as recency_points,
    least(15, round((least(s.photos_count, 3)::numeric / 3.0) * 15))::int as photos_points,
    least(10, round((least(s.amenities_count, 4)::numeric / 4.0) * 10))::int as amenities_points,
    ((case when s.has_pricing_rule then 8 else 0 end) + (case when s.has_fee_flags then 7 else 0 end))::int as pricing_points
  from scored s
)
select
  p.business_id,
  greatest(0, least(100, p.verified_points + p.recency_points + p.photos_points + p.amenities_points + p.pricing_points))::int as score,
  p.verified_points,
  p.recency_points,
  p.photos_points,
  p.amenities_points,
  p.pricing_points,
  p.total_items,
  p.verified_items,
  p.last_menu_update_at,
  p.photos_count,
  p.amenities_count,
  p.has_pricing_rule,
  p.has_fee_flags,
  p.weekly_verified_votes
from points p;

create or replace function public.get_business_quality_score_v1(
  p_business_id uuid
)
returns jsonb
language plpgsql
stable
security definer
set search_path to 'public'
as $function$
declare
  v_row public.business_quality_score_v1%rowtype;
  v_tips text[] := array[]::text[];
begin
  if not (public.is_admin() or public.is_owner_of_business(p_business_id)) then
    return jsonb_build_object(
      'score', 0,
      'tips', jsonb_build_array('Bu skor icin isletme sahibi olmalisin.'),
      'breakdown', jsonb_build_object('error', 'not_owner')
    );
  end if;

  select * into v_row
  from public.business_quality_score_v1 q
  where q.business_id = p_business_id;

  if not found then
    return jsonb_build_object(
      'score', 0,
      'tips', jsonb_build_array('Isletme bulunamadi.'),
      'breakdown', jsonb_build_object('error', 'not_found')
    );
  end if;

  if v_row.amenities_count < 2 then
    v_tips := array_append(v_tips, '2 amenities daha ekle');
  end if;
  if v_row.photos_count < 3 then
    v_tips := array_append(v_tips, 'Menuye 3 foto ekle');
  end if;
  if not v_row.has_fee_flags then
    v_tips := array_append(v_tips, 'Kuver/servis bilgisini dogrula');
  end if;
  if v_row.weekly_verified_votes < 1 then
    v_tips := array_append(v_tips, 'Bu hafta 1 fiyat teyidi al');
  end if;
  if v_row.last_menu_update_at < now() - interval '7 days' then
    v_tips := array_append(v_tips, 'Menunu bu hafta guncelle');
  end if;

  return jsonb_build_object(
    'score', v_row.score,
    'tips', to_jsonb(v_tips),
    'breakdown', jsonb_build_object(
      'verified_ratio_points', v_row.verified_points,
      'recency_points', v_row.recency_points,
      'photos_points', v_row.photos_points,
      'amenities_points', v_row.amenities_points,
      'pricing_points', v_row.pricing_points,
      'verified_items', v_row.verified_items,
      'total_items', v_row.total_items,
      'photos_count', v_row.photos_count,
      'amenities_count', v_row.amenities_count,
      'has_pricing_rule', v_row.has_pricing_rule,
      'has_fee_flags', v_row.has_fee_flags,
      'weekly_verified_votes', v_row.weekly_verified_votes,
      'last_menu_update_at', v_row.last_menu_update_at
    )
  );
end;
$function$;

-- ===== END MIGRATION: 20260311_000001_business_quality_score.sql =====

-- ===== BEGIN MIGRATION: 20260312_000001_story_moderation_guards.sql =====
-- Server-side moderation guards for business stories.
-- Adds duplicate and spam checks without changing client-facing contracts.

CREATE OR REPLACE FUNCTION public.create_business_story_v1(
  p_business_id uuid,
  p_type text,
  p_caption text,
  p_media_url text,
  p_media_thumb_url text DEFAULT NULL,
  p_duration_sec integer DEFAULT NULL
) RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_today date := (now() at time zone 'utc')::date;
  v_count int;
  v_caption text := nullif(lower(trim(coalesce(p_caption, ''))), '');
  v_media_url text := nullif(trim(coalesce(p_media_url, '')), '');
  v_media_thumb_url text := nullif(trim(coalesce(p_media_thumb_url, '')), '');
BEGIN
  IF auth.uid() IS NULL THEN
    RETURN jsonb_build_object('ok', false, 'error', 'not_authenticated');
  END IF;

  IF NOT (public.is_admin() OR public.is_owner_of_business(p_business_id)) THEN
    RETURN jsonb_build_object('ok', false, 'error', 'not_owner');
  END IF;

  IF p_type NOT IN ('menu', 'crowd', 'promo', 'update') THEN
    RETURN jsonb_build_object('ok', false, 'error', 'bad_type');
  END IF;

  IF v_media_url IS NULL OR length(v_media_url) < 10 THEN
    RETURN jsonb_build_object('ok', false, 'error', 'media_required');
  END IF;

  SELECT count(*)
  INTO v_count
  FROM public.business_stories
  WHERE business_id = p_business_id
    AND created_by = auth.uid()
    AND created_at >= (v_today::timestamptz)
    AND is_deleted = false;

  IF v_count >= 5 THEN
    RETURN jsonb_build_object('ok', false, 'error', 'rate_limited_daily');
  END IF;

  IF EXISTS (
    SELECT 1
    FROM public.business_stories s
    WHERE s.business_id = p_business_id
      AND s.is_deleted = false
      AND s.created_at >= now() - interval '30 days'
      AND (
        s.media_url = v_media_url
        OR (v_media_thumb_url IS NOT NULL AND s.media_thumb_url = v_media_thumb_url)
      )
  ) THEN
    RETURN jsonb_build_object('ok', false, 'error', 'duplicate_media');
  END IF;

  IF v_caption IS NOT NULL AND EXISTS (
    SELECT 1
    FROM public.business_stories s
    WHERE s.business_id = p_business_id
      AND s.created_by = auth.uid()
      AND s.is_deleted = false
      AND s.type = p_type::public.story_type
      AND lower(trim(coalesce(s.caption, ''))) = v_caption
      AND s.created_at >= now() - interval '24 hours'
  ) THEN
    RETURN jsonb_build_object('ok', false, 'error', 'spam_suspected');
  END IF;

  IF EXISTS (
    SELECT 1
    FROM public.business_stories s
    WHERE s.business_id = p_business_id
      AND s.created_by = auth.uid()
      AND s.is_deleted = false
      AND s.type = p_type::public.story_type
      AND s.created_at >= now() - interval '2 minutes'
  ) THEN
    RETURN jsonb_build_object('ok', false, 'error', 'spam_suspected');
  END IF;

  INSERT INTO public.business_stories(
    business_id,
    type,
    caption,
    media_url,
    media_thumb_url,
    media_type,
    duration_sec,
    created_by
  )
  VALUES (
    p_business_id,
    p_type::public.story_type,
    p_caption,
    v_media_url,
    v_media_thumb_url,
    CASE WHEN p_duration_sec IS NULL THEN 'image' ELSE 'video' END,
    p_duration_sec,
    auth.uid()
  );

  RETURN jsonb_build_object('ok', true);
END;
$$;

-- ===== END MIGRATION: 20260312_000001_story_moderation_guards.sql =====

-- ===== BEGIN MIGRATION: 20260313_000001_menu_price_confidence.sql =====
-- Menu & price trust hardening:
-- 1) Optional evidence URL for price suggestions
-- 2) New submit RPC with confidence score + conservative auto-approval
-- 3) Enriched price status payload (price, last verification, confidence)

alter table if exists public.menu_item_price_suggestions
  add column if not exists evidence_url text;

create or replace function public.get_menu_item_price_status_v1(p_menu_item_id uuid)
returns jsonb
language sql
stable
security definer
set search_path = public
as $$
  with votes as (
    select
      count(*) filter (where created_at >= now() - interval '30 days') as total_30d,
      count(*) filter (where vote = 1 and created_at >= now() - interval '30 days') as ok_30d,
      count(*) filter (where vote = -1 and created_at >= now() - interval '30 days') as bad_30d,
      (
        select vote
        from public.menu_item_price_votes
        where menu_item_id = p_menu_item_id and user_id = auth.uid()
        limit 1
      ) as my_vote
    from public.menu_item_price_votes
    where menu_item_id = p_menu_item_id
  ),
  latest as (
    select
      mi.price_cents,
      (
        select max(h.created_at)
        from public.menu_item_price_history h
        where h.menu_item_id = p_menu_item_id
      ) as last_verified_at
    from public.menu_items mi
    where mi.id = p_menu_item_id
    limit 1
  )
  select jsonb_build_object(
    'total_30d', votes.total_30d,
    'ok_30d', votes.ok_30d,
    'bad_30d', votes.bad_30d,
    'my_vote', votes.my_vote,
    'price_cents', latest.price_cents,
    'last_verified_at', latest.last_verified_at,
    'confidence_score',
      greatest(
        0::numeric,
        least(
          1::numeric,
          (
            case
              when votes.total_30d <= 0 then 0.2
              else (votes.ok_30d::numeric / nullif(votes.total_30d, 0))
            end
          ) * 0.8
          +
          (
            case
              when votes.total_30d >= 12 then 0.2
              when votes.total_30d >= 6 then 0.12
              when votes.total_30d >= 3 then 0.06
              else 0
            end
          )
        )
      ),
    'status',
      case
        when votes.total_30d = 0 then 'unknown'
        when votes.ok_30d >= 3 and votes.ok_30d >= votes.bad_30d * 2 then 'verified'
        when votes.bad_30d >= 3 and votes.bad_30d > votes.ok_30d then 'outdated'
        else 'mixed'
      end
  )
  from votes
  left join latest on true;
$$;

create or replace function public.submit_menu_item_price_suggestion_v2(
  p_menu_item_id uuid,
  p_suggested_price_cents integer,
  p_currency text default 'TRY',
  p_note text default null,
  p_evidence_url text default null
) returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_business_id uuid;
  v_cnt int;
  v_note text;
  v_evidence_url text;
  v_current_price int;
  v_ok_30d int := 0;
  v_bad_30d int := 0;
  v_total_30d int := 0;
  v_confidence numeric := 0;
  v_auto_approved boolean := false;
  v_pending_count int := 0;
begin
  if auth.uid() is null then
    return jsonb_build_object('ok', false, 'error', 'not_authenticated');
  end if;

  if p_suggested_price_cents < 0 then
    return jsonb_build_object('ok', false, 'error', 'bad_price');
  end if;

  if p_currency is null or length(trim(p_currency)) <> 3 then
    return jsonb_build_object('ok', false, 'error', 'bad_currency');
  end if;

  v_note := nullif(trim(p_note), '');
  v_evidence_url := nullif(trim(p_evidence_url), '');

  if v_evidence_url is not null and left(v_evidence_url, 4) <> 'http' then
    return jsonb_build_object('ok', false, 'error', 'bad_evidence_url');
  end if;

  select mi.business_id, mi.price_cents
    into v_business_id, v_current_price
  from public.menu_items mi
  where mi.id = p_menu_item_id and mi.status = 'published';

  if v_business_id is null then
    return jsonb_build_object('ok', false, 'error', 'not_found');
  end if;

  -- rate limit: same user, same item, once per 24h
  select count(*) into v_cnt
  from public.menu_item_price_suggestions
  where menu_item_id = p_menu_item_id
    and created_by = auth.uid()
    and created_at >= now() - interval '24 hours';

  if v_cnt > 0 then
    return jsonb_build_object('ok', false, 'error', 'rate_limited_24h');
  end if;

  select
    count(*) filter (where vote = 1 and created_at >= now() - interval '30 days'),
    count(*) filter (where vote = -1 and created_at >= now() - interval '30 days'),
    count(*) filter (where created_at >= now() - interval '30 days')
    into v_ok_30d, v_bad_30d, v_total_30d
  from public.menu_item_price_votes
  where menu_item_id = p_menu_item_id;

  v_confidence :=
    greatest(
      0::numeric,
      least(
        1::numeric,
        (case when v_total_30d <= 0 then 0.2 else (v_ok_30d::numeric / nullif(v_total_30d, 0)) end) * 0.8
        +
        (case
          when v_total_30d >= 12 then 0.2
          when v_total_30d >= 6 then 0.12
          when v_total_30d >= 3 then 0.06
          else 0
        end)
      )
    );

  -- Conservative auto-approval rule:
  -- enough signal + strong positive votes + small price delta (<=5%)
  if v_current_price is not null
     and v_current_price > 0
     and v_total_30d >= 8
     and v_ok_30d >= (v_bad_30d * 3)
     and abs(p_suggested_price_cents - v_current_price)::numeric / v_current_price::numeric <= 0.05
  then
    v_auto_approved := true;
  end if;

  if v_auto_approved then
    update public.menu_items
    set price_cents = p_suggested_price_cents,
        currency = upper(trim(p_currency)),
        updated_at = now()
    where id = p_menu_item_id;

    insert into public.menu_item_price_suggestions(
      menu_item_id, business_id, suggested_price_cents, currency, note, created_by,
      evidence_url, status, handled_at, approved_at
    )
    values (
      p_menu_item_id, v_business_id, p_suggested_price_cents, upper(trim(p_currency)), v_note, auth.uid(),
      v_evidence_url, 'approved', now(), now()
    );

    insert into public.menu_item_price_history(
      menu_item_id, price_cents, currency, source, created_by
    )
    values (
      p_menu_item_id, p_suggested_price_cents, upper(trim(p_currency)), 'auto_rule', auth.uid()
    );

    return jsonb_build_object(
      'ok', true,
      'auto_approved', true,
      'confidence_score', v_confidence,
      'pending_count', 0
    );
  end if;

  insert into public.menu_item_price_suggestions(
    menu_item_id, business_id, suggested_price_cents, currency, note, created_by, evidence_url
  )
  values (
    p_menu_item_id, v_business_id, p_suggested_price_cents, upper(trim(p_currency)), v_note, auth.uid(), v_evidence_url
  );

  select count(*) into v_pending_count
  from public.menu_item_price_suggestions
  where menu_item_id = p_menu_item_id
    and status = 'pending';

  return jsonb_build_object(
    'ok', true,
    'auto_approved', false,
    'confidence_score', v_confidence,
    'pending_count', v_pending_count
  );
end;
$$;

grant all on function public.submit_menu_item_price_suggestion_v2(uuid, integer, text, text, text) to anon;
grant all on function public.submit_menu_item_price_suggestion_v2(uuid, integer, text, text, text) to authenticated;
grant all on function public.submit_menu_item_price_suggestion_v2(uuid, integer, text, text, text) to service_role;

-- ===== END MIGRATION: 20260313_000001_menu_price_confidence.sql =====

-- ===== BEGIN MIGRATION: 20260314_000001_reviews_quality_and_antispam.sql =====
-- Review anti-spam + helpful quality ranking.

create or replace function public.submit_review_v1(
  p_business_id uuid,
  p_rating integer,
  p_title text default null,
  p_content text default null
) returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
  v_content text := coalesce(trim(p_content), '');
  v_title text := nullif(trim(coalesce(p_title, '')), '');
  v_profile_created_at timestamptz;
  v_recent_count int := 0;
  v_same_business_count int := 0;
begin
  if v_user_id is null then
    return jsonb_build_object('ok', false, 'error', 'not_authenticated');
  end if;

  if p_business_id is null then
    return jsonb_build_object('ok', false, 'error', 'business_required');
  end if;

  if p_rating < 1 or p_rating > 5 then
    return jsonb_build_object('ok', false, 'error', 'bad_rating');
  end if;

  if length(v_content) < 8 then
    return jsonb_build_object('ok', false, 'error', 'content_too_short');
  end if;

  -- link / phone / contact filtering
  if v_content ~* '(https?://|www\.|t\.me/|wa\.me/|instagram\.com|@[a-z0-9_]{2,}|(\+?\d[\d\s\-\(\)]{7,}\d))' then
    return jsonb_build_object('ok', false, 'error', 'contains_link_or_phone');
  end if;

  select up.created_at
    into v_profile_created_at
  from public.user_profiles up
  where up.user_id = v_user_id;

  -- New account throttle: first 7 days => max 2 reviews/day
  if v_profile_created_at is not null and v_profile_created_at >= now() - interval '7 days' then
    select count(*)
      into v_recent_count
    from public.reviews r
    where r.user_id = v_user_id
      and r.created_at >= now() - interval '24 hours';

    if v_recent_count >= 2 then
      return jsonb_build_object('ok', false, 'error', 'new_account_rate_limited');
    end if;
  end if;

  -- Same business cooldown: one review per 12 hours.
  select count(*)
    into v_same_business_count
  from public.reviews r
  where r.user_id = v_user_id
    and r.business_id = p_business_id
    and r.created_at >= now() - interval '12 hours';

  if v_same_business_count > 0 then
    return jsonb_build_object('ok', false, 'error', 'same_business_cooldown');
  end if;

  insert into public.reviews(
    business_id, user_id, rating, title, content, status
  ) values (
    p_business_id, v_user_id, p_rating, v_title, v_content, 'approved'
  );

  return jsonb_build_object('ok', true);
end;
$$;

create or replace function public.get_business_reviews_v2(
  p_business_id uuid,
  p_sort text default 'newest',
  p_limit integer default 20,
  p_offset integer default 0
) returns table(
  id uuid,
  business_id uuid,
  user_id uuid,
  rating integer,
  title text,
  content text,
  helpful_count integer,
  created_at timestamptz,
  status text,
  quality_score numeric
)
language sql
stable
security definer
set search_path = public
as $$
  with base as (
    select
      r.id,
      r.business_id,
      r.user_id,
      r.rating,
      r.title,
      r.content,
      r.helpful_count,
      r.created_at,
      r.status,
      coalesce(rep.open_reports, 0) as open_reports,
      greatest(
        0::numeric,
        least(
          100::numeric,
          (coalesce(r.helpful_count, 0)::numeric * 2.2)
          + (least(length(coalesce(r.content, '')), 400)::numeric / 20)
          + (r.rating::numeric * 1.5)
          - (coalesce(rep.open_reports, 0)::numeric * 3.0)
        )
      ) as quality_score
    from public.reviews r
    left join (
      select
        review_id,
        count(*)::int as open_reports
      from public.reports
      where review_id is not null
        and (durum = 'acik' or status in ('open', 'reviewing'))
      group by review_id
    ) rep on rep.review_id = r.id
    where r.business_id = p_business_id
      and r.status = 'approved'
  )
  select
    b.id,
    b.business_id,
    b.user_id,
    b.rating,
    b.title,
    b.content,
    b.helpful_count,
    b.created_at,
    b.status,
    b.quality_score
  from base b
  order by
    case when lower(coalesce(p_sort, 'newest')) = 'helpful' then b.quality_score else null end desc,
    case when lower(coalesce(p_sort, 'newest')) = 'helpful' then b.helpful_count else null end desc,
    b.created_at desc
  limit greatest(p_limit, 1)
  offset greatest(p_offset, 0);
$$;

grant all on function public.submit_review_v1(uuid, integer, text, text) to anon;
grant all on function public.submit_review_v1(uuid, integer, text, text) to authenticated;
grant all on function public.submit_review_v1(uuid, integer, text, text) to service_role;

grant all on function public.get_business_reviews_v2(uuid, text, integer, integer) to anon;
grant all on function public.get_business_reviews_v2(uuid, text, integer, integer) to authenticated;
grant all on function public.get_business_reviews_v2(uuid, text, integer, integer) to service_role;

-- ===== END MIGRATION: 20260314_000001_reviews_quality_and_antispam.sql =====

-- ===== BEGIN MIGRATION: 20260315_000001_server_side_spam_rate_limits.sql =====
-- Extra server-side anti-spam guards for reviews + price suggestions.
-- These run at table insert level, so limits apply even if client flow changes.

create or replace function public.enforce_review_insert_rate_limits_v1()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_recent_same_business int;
  v_recent_daily int;
begin
  if new.created_by is null then
    return new;
  end if;

  select count(*)
    into v_recent_same_business
  from public.reviews r
  where r.user_id = new.user_id
    and r.business_id = new.business_id
    and r.created_at >= now() - interval '12 hours';

  if v_recent_same_business > 0 then
    raise exception 'same_business_cooldown';
  end if;

  select count(*)
    into v_recent_daily
  from public.reviews r
  where r.user_id = new.user_id
    and r.created_at >= now() - interval '24 hours';

  if v_recent_daily >= 15 then
    raise exception 'review_daily_rate_limited';
  end if;

  return new;
end;
$$;

drop trigger if exists trg_reviews_rate_limit_v1 on public.reviews;
create trigger trg_reviews_rate_limit_v1
before insert on public.reviews
for each row execute function public.enforce_review_insert_rate_limits_v1();

create or replace function public.enforce_price_suggestion_insert_rate_limits_v1()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_recent_same_item int;
  v_recent_daily int;
begin
  if new.user_id is null then
    return new;
  end if;

  select count(*)
    into v_recent_same_item
  from public.menu_item_price_suggestions s
  where s.created_by = new.created_by
    and s.menu_item_id = new.menu_item_id
    and s.created_at >= now() - interval '24 hours';

  if v_recent_same_item > 0 then
    raise exception 'price_suggestion_same_item_cooldown';
  end if;

  select count(*)
    into v_recent_daily
  from public.menu_item_price_suggestions s
  where s.created_by = new.created_by
    and s.created_at >= now() - interval '24 hours';

  if v_recent_daily >= 40 then
    raise exception 'price_suggestion_daily_rate_limited';
  end if;

  return new;
end;
$$;

drop trigger if exists trg_menu_item_price_suggestions_rate_limit_v1 on public.menu_item_price_suggestions;
create trigger trg_menu_item_price_suggestions_rate_limit_v1
before insert on public.menu_item_price_suggestions
for each row execute function public.enforce_price_suggestion_insert_rate_limits_v1();

create index if not exists idx_reviews_user_created_at_v1
  on public.reviews(user_id, created_at desc);

create index if not exists idx_reviews_user_business_created_at_v1
  on public.reviews(user_id, business_id, created_at desc);

create index if not exists idx_menu_item_price_suggestions_user_created_at_v1
  on public.menu_item_price_suggestions(created_by, created_at desc);

create index if not exists idx_menu_item_price_suggestions_user_item_created_at_v1
  on public.menu_item_price_suggestions(created_by, menu_item_id, created_at desc);

-- ===== END MIGRATION: 20260315_000001_server_side_spam_rate_limits.sql =====

-- ===== BEGIN MIGRATION: 20260316_000001_admin_business_merge.sql =====
-- Admin merge flow for duplicate business records.

create table if not exists public.business_merge_log (
  duplicate_business_id uuid primary key references public.businesses(id) on delete cascade,
  primary_business_id uuid not null references public.businesses(id) on delete cascade,
  merged_by uuid null,
  merged_at timestamptz not null default now(),
  note text null
);

create or replace function public.admin_merge_businesses_v1(
  p_primary_business_id uuid,
  p_duplicate_business_id uuid,
  p_admin_note text default null,
  p_dry_run boolean default false
) returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_primary_exists boolean := false;
  v_duplicate_exists boolean := false;
  v_now timestamptz := now();
  v_summary jsonb;
begin
  if not public.is_admin() then
    raise exception 'not_admin';
  end if;

  if p_primary_business_id is null or p_duplicate_business_id is null then
    return jsonb_build_object('ok', false, 'error', 'missing_business_id');
  end if;
  if p_primary_business_id = p_duplicate_business_id then
    return jsonb_build_object('ok', false, 'error', 'same_business');
  end if;

  select exists(select 1 from public.businesses b where b.id = p_primary_business_id)
    into v_primary_exists;
  select exists(select 1 from public.businesses b where b.id = p_duplicate_business_id)
    into v_duplicate_exists;

  if not v_primary_exists or not v_duplicate_exists then
    return jsonb_build_object('ok', false, 'error', 'business_not_found');
  end if;

  v_summary := jsonb_build_object(
    'menus', (select count(*) from public.menus where business_id = p_duplicate_business_id),
    'menu_items', (select count(*) from public.menu_items where business_id = p_duplicate_business_id),
    'reviews', (select count(*) from public.reviews where business_id = p_duplicate_business_id),
    'media', (select count(*) from public.business_media where business_id = p_duplicate_business_id),
    'stories', (select count(*) from public.business_stories where business_id = p_duplicate_business_id),
    'favorites', (select count(*) from public.favorites where business_id = p_duplicate_business_id),
    'follows', (select count(*) from public.business_follows where business_id = p_duplicate_business_id)
  );

  if p_dry_run then
    return jsonb_build_object(
      'ok', true,
      'dry_run', true,
      'summary', v_summary
    );
  end if;

  -- conflict-safe merge on tables with unique constraints.
  insert into public.business_follows(user_id, business_id, created_at)
  select bf.user_id, p_primary_business_id, bf.created_at
  from public.business_follows bf
  where bf.business_id = p_duplicate_business_id
    and not exists (
      select 1
      from public.business_follows x
      where x.user_id = bf.user_id
        and x.business_id = p_primary_business_id
    );
  delete from public.business_follows where business_id = p_duplicate_business_id;

  insert into public.favorites(user_id, business_id, created_at)
  select f.user_id, p_primary_business_id, f.created_at
  from public.favorites f
  where f.business_id = p_duplicate_business_id
    and not exists (
      select 1
      from public.favorites x
      where x.user_id = f.user_id
        and x.business_id = p_primary_business_id
    );
  delete from public.favorites where business_id = p_duplicate_business_id;

  insert into public.user_favorites_legacy(user_id, business_id, created_at)
  select f.user_id, p_primary_business_id, f.created_at
  from public.user_favorites_legacy f
  where f.business_id = p_duplicate_business_id
    and not exists (
      select 1
      from public.user_favorites_legacy x
      where x.user_id = f.user_id
        and x.business_id = p_primary_business_id
    );
  delete from public.user_favorites_legacy where business_id = p_duplicate_business_id;

  insert into public.collection_items(collection_id, business_id, note, created_at)
  select c.collection_id, p_primary_business_id, c.note, c.created_at
  from public.collection_items c
  where c.business_id = p_duplicate_business_id
    and not exists (
      select 1
      from public.collection_items x
      where x.collection_id = c.collection_id
        and x.business_id = p_primary_business_id
    );
  delete from public.collection_items where business_id = p_duplicate_business_id;

  insert into public.business_amenity_map(business_id, amenity_id)
  select p_primary_business_id, m.amenity_id
  from public.business_amenity_map m
  where m.business_id = p_duplicate_business_id
    and not exists (
      select 1
      from public.business_amenity_map x
      where x.business_id = p_primary_business_id
        and x.amenity_id = m.amenity_id
    );
  delete from public.business_amenity_map where business_id = p_duplicate_business_id;

  update public.owner_claims oc
  set business_id = p_primary_business_id
  where oc.business_id = p_duplicate_business_id
    and not exists (
      select 1
      from public.owner_claims x
      where x.user_id = oc.user_id
        and x.business_id = p_primary_business_id
    );
  delete from public.owner_claims where business_id = p_duplicate_business_id;

  -- one-row-per-business tables
  if exists(select 1 from public.business_hours where business_id = p_primary_business_id) then
    delete from public.business_hours where business_id = p_duplicate_business_id;
  else
    update public.business_hours
      set business_id = p_primary_business_id
      where business_id = p_duplicate_business_id;
  end if;

  if exists(select 1 from public.owner_onboarding_progress where business_id = p_primary_business_id) then
    delete from public.owner_onboarding_progress where business_id = p_duplicate_business_id;
  else
    update public.owner_onboarding_progress
      set business_id = p_primary_business_id
      where business_id = p_duplicate_business_id;
  end if;

  if exists(select 1 from public.business_stats where business_id = p_primary_business_id) then
    delete from public.business_stats where business_id = p_duplicate_business_id;
  else
    update public.business_stats
      set business_id = p_primary_business_id
      where business_id = p_duplicate_business_id;
  end if;

  -- direct updates
  update public.analytics_events set business_id = p_primary_business_id where business_id = p_duplicate_business_id;
  update public.business_activity_log set business_id = p_primary_business_id where business_id = p_duplicate_business_id;
  update public.business_media set business_id = p_primary_business_id where business_id = p_duplicate_business_id;
  update public.business_premium set business_id = p_primary_business_id where business_id = p_duplicate_business_id;
  update public.business_presence_events set business_id = p_primary_business_id where business_id = p_duplicate_business_id;
  update public.business_stories set business_id = p_primary_business_id where business_id = p_duplicate_business_id;
  update public.feed_events set business_id = p_primary_business_id where business_id = p_duplicate_business_id;
  update public.menu_item_photos set business_id = p_primary_business_id where business_id = p_duplicate_business_id;
  update public.menu_item_price_suggestions set business_id = p_primary_business_id where business_id = p_duplicate_business_id;
  update public.menu_item_suggestions set business_id = p_primary_business_id where business_id = p_duplicate_business_id;
  update public.menu_items set business_id = p_primary_business_id where business_id = p_duplicate_business_id;
  update public.menus set business_id = p_primary_business_id where business_id = p_duplicate_business_id;
  update public.reviews set business_id = p_primary_business_id where business_id = p_duplicate_business_id;
  update public.sponsorship_leads set business_id = p_primary_business_id where business_id = p_duplicate_business_id;
  update public.sponsorships set business_id = p_primary_business_id where business_id = p_duplicate_business_id;
  update public.suspended_meals set business_id = p_primary_business_id where business_id = p_duplicate_business_id;
  update public.table_feedback set business_id = p_primary_business_id where business_id = p_duplicate_business_id;
  update public.visits set business_id = p_primary_business_id where business_id = p_duplicate_business_id;

  insert into public.business_merge_log(
    duplicate_business_id,
    primary_business_id,
    merged_by,
    merged_at,
    note
  ) values (
    p_duplicate_business_id,
    p_primary_business_id,
    auth.uid(),
    v_now,
    nullif(trim(coalesce(p_admin_note, '')), '')
  )
  on conflict (duplicate_business_id)
  do update set
    primary_business_id = excluded.primary_business_id,
    merged_by = excluded.merged_by,
    merged_at = excluded.merged_at,
    note = excluded.note;

  update public.businesses
  set
    is_active = false,
    source = 'merged',
    source_id = p_primary_business_id::text
  where id = p_duplicate_business_id;

  perform public.log_admin_action_v1(
    'business.merge',
    'businesses',
    p_duplicate_business_id,
    jsonb_build_object(
      'primary_business_id', p_primary_business_id,
      'duplicate_business_id', p_duplicate_business_id,
      'note', p_admin_note,
      'summary', v_summary
    )
  );

  return jsonb_build_object(
    'ok', true,
    'dry_run', false,
    'summary', v_summary
  );
end;
$$;

grant all on function public.admin_merge_businesses_v1(uuid, uuid, text, boolean) to anon;
grant all on function public.admin_merge_businesses_v1(uuid, uuid, text, boolean) to authenticated;
grant all on function public.admin_merge_businesses_v1(uuid, uuid, text, boolean) to service_role;

-- ===== END MIGRATION: 20260316_000001_admin_business_merge.sql =====

-- ===== BEGIN MIGRATION: 20260317_000001_chain_branches.sql =====
-- Chain / branch model

create table if not exists public.chains (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  slug text null,
  description text null,
  created_at timestamptz not null default now()
);

create unique index if not exists idx_chains_name_unique
  on public.chains(lower(name));

alter table public.businesses
  add column if not exists chain_id uuid references public.chains(id) on delete set null;

alter table public.businesses
  add column if not exists branch_label text;

create table if not exists public.chain_memberships (
  chain_id uuid not null references public.chains(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  role text not null default 'manager' check (role in ('owner', 'manager')),
  created_at timestamptz not null default now(),
  primary key (chain_id, user_id)
);

alter table public.chains enable row level security;
alter table public.chain_memberships enable row level security;

drop policy if exists chains_read_all on public.chains;
create policy chains_read_all on public.chains
for select to authenticated using (true);

drop policy if exists chain_memberships_owner_read on public.chain_memberships;
create policy chain_memberships_owner_read on public.chain_memberships
for select to authenticated using (user_id = auth.uid() or public.is_admin());

drop policy if exists chain_memberships_admin_all on public.chain_memberships;
create policy chain_memberships_admin_all on public.chain_memberships
for all to authenticated using (public.is_admin()) with check (public.is_admin());

create or replace function public.owner_list_my_businesses_v2(
  p_status text default 'approved',
  p_limit integer default 50,
  p_offset integer default 0
) returns table(
  business_id uuid,
  business_name text,
  city text,
  district text,
  claim_status text,
  claimed_at timestamptz,
  chain_id uuid,
  chain_name text,
  branch_label text,
  owner_role text
)
language sql
stable
security definer
set search_path = public
as $$
  select
    b.id as business_id,
    b.name as business_name,
    coalesce(b.city, '') as city,
    coalesce(b.district, '') as district,
    c.status as claim_status,
    c.created_at as claimed_at,
    b.chain_id,
    ch.name as chain_name,
    coalesce(b.branch_label, '') as branch_label,
    coalesce(cm.role, 'owner') as owner_role
  from public.owner_claims c
  join public.businesses b on b.id = c.business_id
  left join public.chains ch on ch.id = b.chain_id
  left join public.chain_memberships cm on cm.chain_id = b.chain_id and cm.user_id = auth.uid()
  where c.user_id = auth.uid()
    and (p_status is null or c.status = p_status)
  order by c.created_at desc
  limit greatest(p_limit, 1)
  offset greatest(p_offset, 0);
$$;

create or replace function public.get_chain_overview_v1(
  p_chain_id uuid,
  p_lat double precision default null,
  p_lng double precision default null,
  p_limit integer default 20
) returns table(
  chain_id uuid,
  chain_name text,
  chain_description text,
  business_id uuid,
  business_name text,
  branch_label text,
  city text,
  district text,
  address text,
  is_open_now boolean,
  distance_km double precision
)
language sql
stable
security definer
set search_path = public
as $$
  select
    ch.id as chain_id,
    ch.name as chain_name,
    ch.description as chain_description,
    b.id as business_id,
    b.name as business_name,
    coalesce(b.branch_label, '') as branch_label,
    b.city,
    b.district,
    b.address,
    null::boolean as is_open_now,
    case
      when p_lat is null or p_lng is null or b.lat is null or b.lng is null then null
      else round((st_distance(
        st_setsrid(st_makepoint(p_lng, p_lat), 4326)::geography,
        st_setsrid(st_makepoint(b.lng, b.lat), 4326)::geography
      ) / 1000.0)::numeric, 2)::double precision
    end as distance_km
  from public.businesses b
  join public.chains ch on ch.id = b.chain_id
  where b.chain_id = p_chain_id
    and b.is_active = true
  order by
    case when p_lat is null or p_lng is null then null else
      st_distance(
        st_setsrid(st_makepoint(p_lng, p_lat), 4326)::geography,
        st_setsrid(st_makepoint(b.lng, b.lat), 4326)::geography
      )
    end asc nulls last,
    b.name asc
  limit greatest(p_limit, 1);
$$;

grant all on function public.owner_list_my_businesses_v2(text, integer, integer) to anon;
grant all on function public.owner_list_my_businesses_v2(text, integer, integer) to authenticated;
grant all on function public.owner_list_my_businesses_v2(text, integer, integer) to service_role;

grant all on function public.get_chain_overview_v1(uuid, double precision, double precision, integer) to anon;
grant all on function public.get_chain_overview_v1(uuid, double precision, double precision, integer) to authenticated;
grant all on function public.get_chain_overview_v1(uuid, double precision, double precision, integer) to service_role;

-- ===== END MIGRATION: 20260317_000001_chain_branches.sql =====

-- ===== BEGIN MIGRATION: 20260318_000001_business_commerce_links.sql =====
alter table public.businesses
  add column if not exists reservation_url text,
  add column if not exists order_yemeksepeti_url text,
  add column if not exists order_trendyolgo_url text,
  add column if not exists order_getir_url text;

alter table public.analytics_events
  drop constraint if exists analytics_events_event_name_check;

alter table public.analytics_events
  add constraint analytics_events_event_name_check
  check (
    event_name = any (
      array[
        'menu_shared'::text,
        'qr_scanned'::text,
        'menu_link_opened'::text,
        'app_install_from_menu'::text,
        'business_reservation_click'::text,
        'business_order_click'::text,
        'business_whatsapp_click'::text,
        'business_phone_click'::text
      ]
    )
  );

create or replace function public.log_event_v1(
  p_event_name text,
  p_business_id uuid default null,
  p_menu_id uuid default null,
  p_source text default null,
  p_client_id text default null,
  p_meta jsonb default '{}'::jsonb
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_event_name text := coalesce(trim(p_event_name), '');
  v_client text := nullif(trim(p_client_id), '');
  v_key text;
  v_today date := current_date;
  v_current_count int;
  v_user_id uuid := coalesce(auth.uid(), '00000000-0000-0000-0000-000000000000'::uuid);
begin
  if v_event_name not in (
    'menu_shared',
    'qr_scanned',
    'menu_link_opened',
    'app_install_from_menu',
    'business_reservation_click',
    'business_order_click',
    'business_whatsapp_click',
    'business_phone_click'
  ) then
    return jsonb_build_object('ok', false, 'code', 'invalid_event');
  end if;

  if v_event_name = 'menu_link_opened' and v_client is null then
    return jsonb_build_object('ok', false, 'code', 'client_required');
  end if;

  if v_event_name = 'menu_link_opened' then
    v_key := format('menu_link_opened:%s:%s', v_client, v_today::text);
    select count into v_current_count
    from public.user_rate_limits
    where key = v_key;

    if coalesce(v_current_count, 0) >= 200 then
      return jsonb_build_object('ok', false, 'code', 'rate_limited');
    end if;

    insert into public.user_rate_limits (key, user_id, action, day, count, updated_at)
    values (v_key, v_user_id, 'menu_link_opened', v_today, 1, now())
    on conflict (key) do update
      set count = public.user_rate_limits.count + 1,
          updated_at = now();
  end if;

  insert into public.analytics_events (
    event_name,
    business_id,
    menu_id,
    source,
    client_id,
    user_id,
    meta
  ) values (
    v_event_name,
    p_business_id,
    p_menu_id,
    p_source,
    v_client,
    auth.uid(),
    coalesce(p_meta, '{}'::jsonb)
  );

  return jsonb_build_object('ok', true);
end;
$$;

create or replace function public.analytics_growth_v2(
  p_days integer default 30,
  p_business_id uuid default null
)
returns table(
  day date,
  menu_link_opened integer,
  qr_scanned integer,
  menu_shared integer,
  app_install_from_menu integer,
  business_reservation_click integer,
  business_order_click integer,
  business_whatsapp_click integer,
  business_phone_click integer
)
language plpgsql
security definer
set search_path = public
as $$
begin
  if not public.is_admin() then
    raise exception 'not authorized';
  end if;

  return query
  select
    d.day::date,
    sum(case when e.event_name = 'menu_link_opened' then 1 else 0 end)::int as menu_link_opened,
    sum(case when e.event_name = 'qr_scanned' then 1 else 0 end)::int as qr_scanned,
    sum(case when e.event_name = 'menu_shared' then 1 else 0 end)::int as menu_shared,
    sum(case when e.event_name = 'app_install_from_menu' then 1 else 0 end)::int as app_install_from_menu,
    sum(case when e.event_name = 'business_reservation_click' then 1 else 0 end)::int as business_reservation_click,
    sum(case when e.event_name = 'business_order_click' then 1 else 0 end)::int as business_order_click,
    sum(case when e.event_name = 'business_whatsapp_click' then 1 else 0 end)::int as business_whatsapp_click,
    sum(case when e.event_name = 'business_phone_click' then 1 else 0 end)::int as business_phone_click
  from generate_series(
    (current_date - greatest(p_days, 1) + 1)::date,
    current_date::date,
    interval '1 day'
  ) as d(day)
  left join public.analytics_events e
    on date_trunc('day', e.created_at) = d.day
   and (p_business_id is null or e.business_id = p_business_id)
  group by d.day
  order by d.day;
end;
$$;

grant all on function public.analytics_growth_v2(integer, uuid) to anon;
grant all on function public.analytics_growth_v2(integer, uuid) to authenticated;
grant all on function public.analytics_growth_v2(integer, uuid) to service_role;

create or replace function public.owner_update_business_commerce_links_v1(
  p_business_id uuid,
  p_reservation_url text default null,
  p_order_yemeksepeti_url text default null,
  p_order_trendyolgo_url text default null,
  p_order_getir_url text default null
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
begin
  if not (public.is_admin() or public.is_owner_of_business(p_business_id)) then
    return jsonb_build_object('ok', false, 'code', 'not_authorized');
  end if;

  update public.businesses
  set
    reservation_url = nullif(trim(coalesce(p_reservation_url, '')), ''),
    order_yemeksepeti_url = nullif(trim(coalesce(p_order_yemeksepeti_url, '')), ''),
    order_trendyolgo_url = nullif(trim(coalesce(p_order_trendyolgo_url, '')), ''),
    order_getir_url = nullif(trim(coalesce(p_order_getir_url, '')), ''),
    updated_at = now()
  where id = p_business_id;

  return jsonb_build_object('ok', true);
end;
$$;

grant all on function public.owner_update_business_commerce_links_v1(
  uuid,
  text,
  text,
  text,
  text
) to anon;
grant all on function public.owner_update_business_commerce_links_v1(
  uuid,
  text,
  text,
  text,
  text
) to authenticated;
grant all on function public.owner_update_business_commerce_links_v1(
  uuid,
  text,
  text,
  text,
  text
) to service_role;

-- ===== END MIGRATION: 20260318_000001_business_commerce_links.sql =====

-- ===== BEGIN MIGRATION: 20260319_000001_group_offer_votes.sql =====
-- Group offer votes (one vote per user per offer)
create table if not exists public.group_offer_votes (
  offer_id uuid not null references public.group_offers(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  vote smallint not null default 1 check (vote in (1)),
  created_at timestamptz not null default now(),
  primary key (offer_id, user_id)
);

alter table public.group_offer_votes enable row level security;

create policy "group_offer_votes_select_own"
  on public.group_offer_votes
  for select
  using (auth.uid() = user_id);

create policy "group_offer_votes_insert_own"
  on public.group_offer_votes
  for insert
  with check (auth.uid() = user_id);

create policy "group_offer_votes_delete_own"
  on public.group_offer_votes
  for delete
  using (auth.uid() = user_id);

-- Returns offers with vote counts + my_vote
create or replace function public.get_group_offers_v1(p_request_id uuid)
returns table(
  id uuid,
  request_id uuid,
  business_id uuid,
  offered_total_cents integer,
  includes jsonb,
  message text,
  status text,
  created_by uuid,
  created_at timestamptz,
  votes_count integer,
  my_vote smallint
) language sql stable as $$
  select
    o.id,
    o.request_id,
    o.business_id,
    o.offered_total_cents,
    o.includes,
    o.message,
    o.status,
    o.created_by,
    o.created_at,
    coalesce(v.count, 0) as votes_count,
    mv.vote as my_vote
  from public.group_offers o
  left join (
    select offer_id, count(*)::int as count
    from public.group_offer_votes
    group by offer_id
  ) v on v.offer_id = o.id
  left join public.group_offer_votes mv
    on mv.offer_id = o.id and mv.user_id = auth.uid()
  where o.request_id = p_request_id
  order by v.count desc, o.created_at desc;
$$;

-- Toggle vote for an offer (1 = voted, 0 = removed)
create or replace function public.vote_group_offer_v1(p_offer_id uuid)
returns jsonb
language plpgsql
as $$
declare
  v_prev smallint;
begin
  if auth.uid() is null then
    return jsonb_build_object('ok', false, 'error', 'unauthorized');
  end if;

  select vote into v_prev
  from public.group_offer_votes
  where offer_id = p_offer_id and user_id = auth.uid();

  if v_prev is null then
    insert into public.group_offer_votes(offer_id, user_id, vote)
    values (p_offer_id, auth.uid(), 1);
    return jsonb_build_object('ok', true, 'mode', 'insert', 'vote', 1);
  else
    delete from public.group_offer_votes
    where offer_id = p_offer_id and user_id = auth.uid();
    return jsonb_build_object('ok', true, 'mode', 'remove', 'vote', 0);
  end if;
end;
$$;

grant all on table public.group_offer_votes to anon, authenticated, service_role;
grant all on function public.get_group_offers_v1(uuid) to anon, authenticated, service_role;
grant all on function public.vote_group_offer_v1(uuid) to anon, authenticated, service_role;

-- ===== END MIGRATION: 20260319_000001_group_offer_votes.sql =====

-- ===== BEGIN MIGRATION: 20260320000001_owner_growth_access.sql =====
create or replace function public.analytics_growth_v2(
  p_days integer default 30,
  p_business_id uuid default null
)
returns table(
  day date,
  menu_link_opened integer,
  qr_scanned integer,
  menu_shared integer,
  app_install_from_menu integer,
  business_reservation_click integer,
  business_order_click integer,
  business_whatsapp_click integer,
  business_phone_click integer
)
language plpgsql
security definer
set search_path = public
as $$
begin
  if not public.is_admin() then
    if p_business_id is null or not public.is_owner_of_business(p_business_id) then
      raise exception 'not authorized';
    end if;
  end if;

  return query
  select
    d.day::date,
    sum(case when e.event_name = 'menu_link_opened' then 1 else 0 end)::int as menu_link_opened,
    sum(case when e.event_name = 'qr_scanned' then 1 else 0 end)::int as qr_scanned,
    sum(case when e.event_name = 'menu_shared' then 1 else 0 end)::int as menu_shared,
    sum(case when e.event_name = 'app_install_from_menu' then 1 else 0 end)::int as app_install_from_menu,
    sum(case when e.event_name = 'business_reservation_click' then 1 else 0 end)::int as business_reservation_click,
    sum(case when e.event_name = 'business_order_click' then 1 else 0 end)::int as business_order_click,
    sum(case when e.event_name = 'business_whatsapp_click' then 1 else 0 end)::int as business_whatsapp_click,
    sum(case when e.event_name = 'business_phone_click' then 1 else 0 end)::int as business_phone_click
  from generate_series(
    (current_date - greatest(p_days, 1) + 1)::date,
    current_date::date,
    interval '1 day'
  ) as d(day)
  left join public.analytics_events e
    on date_trunc('day', e.created_at) = d.day
   and (p_business_id is null or e.business_id = p_business_id)
  group by d.day
  order by d.day;
end;
$$;

grant all on function public.analytics_growth_v2(integer, uuid) to anon;
grant all on function public.analytics_growth_v2(integer, uuid) to authenticated;
grant all on function public.analytics_growth_v2(integer, uuid) to service_role;

-- ===== END MIGRATION: 20260320000001_owner_growth_access.sql =====

-- ===== BEGIN MIGRATION: 20260320000002_story_campaigns.sql =====
create or replace function public.create_business_story_v1(
  p_business_id uuid,
  p_type text,
  p_caption text,
  p_media_url text,
  p_media_thumb_url text default null,
  p_duration_sec integer default null,
  p_expire_mode text default '24h'
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_today date := (now() at time zone 'utc')::date;
  v_count int;
  v_caption text := nullif(lower(trim(coalesce(p_caption, ''))), '');
  v_media_url text := nullif(trim(coalesce(p_media_url, '')), '');
  v_media_thumb_url text := nullif(trim(coalesce(p_media_thumb_url, '')), '');
  v_expires_at timestamptz;
  v_contains_gambling boolean := false;
  v_contains_copyright boolean := false;
begin
  if auth.uid() is null then
    return jsonb_build_object('ok', false, 'error', 'not_authenticated');
  end if;

  if not (public.is_admin() or public.is_owner_of_business(p_business_id)) then
    return jsonb_build_object('ok', false, 'error', 'not_owner');
  end if;

  if p_type not in ('menu', 'crowd', 'promo', 'update') then
    return jsonb_build_object('ok', false, 'error', 'bad_type');
  end if;

  if v_media_url is null or length(v_media_url) < 10 then
    return jsonb_build_object('ok', false, 'error', 'media_required');
  end if;

  if coalesce(p_expire_mode, '24h') = '7d' then
    v_expires_at := now() + interval '7 days';
  else
    v_expires_at := now() + interval '24 hours';
  end if;

  if v_caption is not null then
    v_contains_gambling := v_caption ~* '(iddaa|bahis|casino|rulet|slot|kumar|bet)';
    v_contains_copyright := v_caption ~* '(copyright|telif|dmca|izinsiz|pirate|illegal stream)';
  end if;

  if v_contains_gambling then
    return jsonb_build_object('ok', false, 'error', 'blocked_gambling');
  end if;

  if v_contains_copyright then
    return jsonb_build_object('ok', false, 'error', 'blocked_copyright');
  end if;

  select count(*)
  into v_count
  from public.business_stories
  where business_id = p_business_id
    and created_by = auth.uid()
    and created_at >= (v_today::timestamptz)
    and is_deleted = false;

  if v_count >= 5 then
    return jsonb_build_object('ok', false, 'error', 'rate_limited_daily');
  end if;

  if exists (
    select 1
    from public.business_stories s
    where s.business_id = p_business_id
      and s.is_deleted = false
      and s.created_at >= now() - interval '30 days'
      and (
        s.media_url = v_media_url
        or (v_media_thumb_url is not null and s.media_thumb_url = v_media_thumb_url)
      )
  ) then
    return jsonb_build_object('ok', false, 'error', 'duplicate_media');
  end if;

  if v_caption is not null and exists (
    select 1
    from public.business_stories s
    where s.business_id = p_business_id
      and s.created_by = auth.uid()
      and s.is_deleted = false
      and s.type = p_type::public.story_type
      and lower(trim(coalesce(s.caption, ''))) = v_caption
      and s.created_at >= now() - interval '24 hours'
  ) then
    return jsonb_build_object('ok', false, 'error', 'spam_suspected');
  end if;

  if exists (
    select 1
    from public.business_stories s
    where s.business_id = p_business_id
      and s.created_by = auth.uid()
      and s.is_deleted = false
      and s.type = p_type::public.story_type
      and s.created_at >= now() - interval '2 minutes'
  ) then
    return jsonb_build_object('ok', false, 'error', 'spam_suspected');
  end if;

  insert into public.business_stories(
    business_id,
    type,
    caption,
    media_url,
    media_thumb_url,
    media_type,
    duration_sec,
    created_by,
    expires_at
  )
  values (
    p_business_id,
    p_type::public.story_type,
    p_caption,
    v_media_url,
    v_media_thumb_url,
    case when p_duration_sec is null then 'image' else 'video' end,
    p_duration_sec,
    auth.uid(),
    v_expires_at
  );

  return jsonb_build_object('ok', true);
end;
$$;

grant all on function public.create_business_story_v1(
  uuid,
  text,
  text,
  text,
  text,
  integer,
  text
) to anon;
grant all on function public.create_business_story_v1(
  uuid,
  text,
  text,
  text,
  text,
  integer,
  text
) to authenticated;
grant all on function public.create_business_story_v1(
  uuid,
  text,
  text,
  text,
  text,
  integer,
  text
) to service_role;

create or replace function public.get_nearby_campaign_stories_v1(
  p_lat double precision default null,
  p_lng double precision default null,
  p_radius_km integer default 10,
  p_city text default null,
  p_district text default null,
  p_limit integer default 20
)
returns table(
  story_id uuid,
  business_id uuid,
  business_name text,
  city text,
  district text,
  caption text,
  media_url text,
  media_thumb_url text,
  created_at timestamptz,
  expires_at timestamptz,
  distance_km double precision
)
language sql
security definer
set search_path = public
as $$
  with src as (
    select
      s.id as story_id,
      s.business_id,
      b.name as business_name,
      b.city,
      b.district,
      s.caption,
      s.media_url,
      coalesce(s.media_thumb_url, s.media_url) as media_thumb_url,
      s.created_at,
      s.expires_at,
      case
        when p_lat is null or p_lng is null or b.lat is null or b.lng is null then null
        else (
          6371.0 * acos(
            least(
              1.0,
              greatest(
                -1.0,
                cos(radians(p_lat)) * cos(radians(b.lat)) * cos(radians(b.lng) - radians(p_lng))
                + sin(radians(p_lat)) * sin(radians(b.lat))
              )
            )
          )
        )
      end as distance_km
    from public.business_stories s
    join public.businesses b on b.id = s.business_id
    where s.is_deleted = false
      and s.type = 'promo'::public.story_type
      and s.expires_at > now()
      and (
        p_lat is not null and p_lng is not null
        or (
          (p_city is null or trim(p_city) = '' or lower(b.city) = lower(trim(p_city)))
          and (p_district is null or trim(p_district) = '' or lower(b.district) = lower(trim(p_district)))
        )
      )
  )
  select
    story_id,
    business_id,
    business_name,
    city,
    district,
    caption,
    media_url,
    media_thumb_url,
    created_at,
    expires_at,
    distance_km
  from src
  where distance_km is null or distance_km <= greatest(coalesce(p_radius_km, 10), 1)
  order by distance_km nulls last, created_at desc
  limit greatest(coalesce(p_limit, 20), 1);
$$;

grant all on function public.get_nearby_campaign_stories_v1(
  double precision,
  double precision,
  integer,
  text,
  text,
  integer
) to anon;
grant all on function public.get_nearby_campaign_stories_v1(
  double precision,
  double precision,
  integer,
  text,
  text,
  integer
) to authenticated;
grant all on function public.get_nearby_campaign_stories_v1(
  double precision,
  double precision,
  integer,
  text,
  text,
  integer
) to service_role;

-- ===== END MIGRATION: 20260320000002_story_campaigns.sql =====

-- ===== BEGIN MIGRATION: 20260320000003_reports_menu_photos.sql =====
alter table public.reports
  add column if not exists menu_item_photo_id uuid;

alter table public.reports
  drop constraint if exists reports_target_type_check;

alter table public.reports
  add constraint reports_target_type_check
  check (
    target_type = any (
      array['business'::text, 'review'::text, 'menu_item_photo'::text]
    )
  );

create or replace function public.submit_report_v1(
  p_business_id uuid default null,
  p_review_id uuid default null,
  p_menu_item_photo_id uuid default null,
  p_reason text default 'other',
  p_details text default null
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid uuid := auth.uid();
  v_recent_exists boolean;
  v_report_id uuid;
  v_target_type text;
  v_target_id uuid;
  v_business_id uuid;
  v_review_id uuid;
  v_photo_id uuid;
begin
  if v_uid is null then
    return jsonb_build_object('ok', false, 'error', 'not_authenticated');
  end if;

  if p_business_id is null and p_review_id is null and p_menu_item_photo_id is null then
    return jsonb_build_object('ok', false, 'error', 'missing_target');
  end if;

  if p_menu_item_photo_id is not null then
    v_target_type := 'menu_item_photo';
    v_target_id := p_menu_item_photo_id;
    v_photo_id := p_menu_item_photo_id;
    select business_id into v_business_id
    from public.menu_item_photos
    where id = p_menu_item_photo_id;
    if v_business_id is null then
      return jsonb_build_object('ok', false, 'error', 'photo_not_found');
    end if;
  elsif p_review_id is not null then
    v_target_type := 'review';
    v_target_id := p_review_id;
    v_review_id := p_review_id;
  else
    v_target_type := 'business';
    v_target_id := p_business_id;
    v_business_id := p_business_id;
  end if;

  if v_target_type = 'business' then
    select exists(
      select 1
      from public.reports
      where user_id = v_uid
        and business_id = v_business_id
        and created_at >= now() - interval '24 hours'
    ) into v_recent_exists;
  elsif v_target_type = 'review' then
    select exists(
      select 1
      from public.reports
      where user_id = v_uid
        and review_id = v_review_id
        and created_at >= now() - interval '24 hours'
    ) into v_recent_exists;
  else
    select exists(
      select 1
      from public.reports
      where user_id = v_uid
        and menu_item_photo_id = v_photo_id
        and created_at >= now() - interval '24 hours'
    ) into v_recent_exists;
  end if;

  if v_recent_exists then
    return jsonb_build_object('ok', false, 'error', 'rate_limited_24h');
  end if;

  insert into public.reports(
    user_id,
    business_id,
    review_id,
    menu_item_photo_id,
    target_type,
    target_id,
    reason,
    details
  )
  values (
    v_uid,
    v_business_id,
    v_review_id,
    v_photo_id,
    v_target_type,
    v_target_id,
    coalesce(nullif(trim(p_reason), ''), 'other'),
    nullif(trim(p_details), '')
  )
  returning id into v_report_id;

  return jsonb_build_object('ok', true, 'report_id', v_report_id);
end;
$$;

grant all on function public.submit_report_v1(
  uuid,
  uuid,
  uuid,
  text,
  text
) to anon;
grant all on function public.submit_report_v1(
  uuid,
  uuid,
  uuid,
  text,
  text
) to authenticated;
grant all on function public.submit_report_v1(
  uuid,
  uuid,
  uuid,
  text,
  text
) to service_role;

create or replace function public.admin_list_reports_v4(
  p_status text default null,
  p_limit integer default 50,
  p_offset integer default 0,
  p_q text default null,
  p_assigned text default null,
  p_sla_only boolean default false
)
returns table(
  id uuid,
  created_at timestamptz,
  durum text,
  reason text,
  details text,
  user_id uuid,
  business_id uuid,
  review_id uuid,
  menu_item_photo_id uuid,
  target_type text,
  target_id uuid,
  assigned_to uuid,
  assigned_at timestamptz,
  handled_by uuid,
  handled_at timestamptz,
  admin_note text,
  age_hours double precision,
  sla_breached boolean
)
language sql
security definer
set search_path = public
as $$
  with base as (
    select
      r.*,
      (extract(epoch from (now() - r.created_at))/3600.0)::float as age_hours,
      (
        r.handled_at is null
        and r.durum in ('acik','inceleniyor')
        and r.created_at < now() - interval '24 hours'
      ) as sla_breached
    from public.reports r
    where public.is_admin()
      and (p_status is null or r.durum = p_status)
      and (
        p_assigned is null
        or (p_assigned='me' and r.assigned_to = auth.uid())
        or (p_assigned='unassigned' and r.assigned_to is null)
      )
      and (
        p_q is null
        or r.reason ilike ('%'||p_q||'%')
        or r.details ilike ('%'||p_q||'%')
        or r.admin_note ilike ('%'||p_q||'%')
      )
  )
  select
    id, created_at, durum, reason, details, user_id, business_id, review_id,
    menu_item_photo_id, target_type, target_id,
    assigned_to, assigned_at, handled_by, handled_at, admin_note,
    age_hours, sla_breached
  from base
  where (not p_sla_only) or sla_breached
  order by
    sla_breached desc,
    created_at desc
  limit greatest(p_limit, 1)
  offset greatest(p_offset, 0);
$$;

grant all on function public.admin_list_reports_v4(
  text,
  integer,
  integer,
  text,
  text,
  boolean
) to anon;
grant all on function public.admin_list_reports_v4(
  text,
  integer,
  integer,
  text,
  text,
  boolean
) to authenticated;
grant all on function public.admin_list_reports_v4(
  text,
  integer,
  integer,
  text,
  text,
  boolean
) to service_role;

-- ===== END MIGRATION: 20260320000003_reports_menu_photos.sql =====

-- ===== BEGIN MIGRATION: 20260320000004_content_moderation.sql =====
-- Content moderation, shadow ban, and media rate limits.

alter table public.user_profiles
  add column if not exists shadow_banned boolean not null default false;

alter table public.menu_item_photos
  add column if not exists is_shadow boolean not null default false;

alter table public.menu_item_price_suggestions
  add column if not exists is_shadow boolean not null default false;

alter table public.business_media
  add column if not exists created_by uuid;

alter table public.business_media
  add column if not exists is_shadow boolean not null default false;

create index if not exists idx_menu_item_photos_shadow
  on public.menu_item_photos(is_shadow);

create index if not exists idx_menu_item_price_suggestions_shadow
  on public.menu_item_price_suggestions(is_shadow);

create index if not exists idx_business_media_shadow
  on public.business_media(is_shadow);

create or replace function public.is_shadow_banned_v1()
returns boolean
language sql
security definer
set search_path = public
as $$
  select coalesce(
    (select shadow_banned from public.user_profiles where user_id = auth.uid()),
    false
  );
$$;

create or replace function public.submit_review_v1(
  p_business_id uuid,
  p_rating integer,
  p_title text default null,
  p_content text default null
) returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
  v_content text := coalesce(trim(p_content), '');
  v_title text := nullif(trim(coalesce(p_title, '')), '');
  v_profile_created_at timestamptz;
  v_recent_count int := 0;
  v_same_business_count int := 0;
  v_shadow boolean := false;
  v_rate jsonb;
begin
  if v_user_id is null then
    return jsonb_build_object('ok', false, 'error', 'not_authenticated');
  end if;

  if p_business_id is null then
    return jsonb_build_object('ok', false, 'error', 'business_required');
  end if;

  if p_rating < 1 or p_rating > 5 then
    return jsonb_build_object('ok', false, 'error', 'bad_rating');
  end if;

  if length(v_content) < 8 then
    return jsonb_build_object('ok', false, 'error', 'content_too_short');
  end if;

  -- link / phone / contact filtering
  if v_content ~* '(https?://|www\.|t\.me/|wa\.me/|instagram\.com|@[a-z0-9_]{2,}|(\+?\d[\d\s\-\(\)]{7,}\d))' then
    return jsonb_build_object('ok', false, 'error', 'contains_link_or_phone');
  end if;

  -- emoji / symbol spam (simple heuristic)
  if length(regexp_replace(v_content, '[[:alnum:][:space:]]', '', 'g')) > 12 then
    return jsonb_build_object('ok', false, 'error', 'emoji_spam');
  end if;

  v_rate := public.consume_rate_limit_v1('review', 15);
  if coalesce((v_rate->>'ok')::boolean, false) is false then
    return jsonb_build_object('ok', false, 'error', 'review_daily_rate_limited');
  end if;

  select up.created_at
    into v_profile_created_at
  from public.user_profiles up
  where up.user_id = v_user_id;

  -- New account throttle: first 7 days => max 2 reviews/day
  if v_profile_created_at is not null and v_profile_created_at >= now() - interval '7 days' then
    select count(*)
      into v_recent_count
    from public.reviews r
    where r.user_id = v_user_id
      and r.created_at >= now() - interval '24 hours';

    if v_recent_count >= 2 then
      return jsonb_build_object('ok', false, 'error', 'new_account_rate_limited');
    end if;
  end if;

  -- Same business cooldown: one review per 12 hours.
  select count(*)
    into v_same_business_count
  from public.reviews r
  where r.user_id = v_user_id
    and r.business_id = p_business_id
    and r.created_at >= now() - interval '12 hours';

  if v_same_business_count > 0 then
    return jsonb_build_object('ok', false, 'error', 'same_business_cooldown');
  end if;

  v_shadow := public.is_shadow_banned_v1();

  insert into public.reviews(
    business_id, user_id, rating, title, content, status
  ) values (
    p_business_id, v_user_id, p_rating, v_title, v_content,
    case when v_shadow then 'pending' else 'approved' end
  );

  return jsonb_build_object('ok', true, 'shadowed', v_shadow);
end;
$$;

create or replace function public.submit_menu_item_price_suggestion_v2(
  p_menu_item_id uuid,
  p_suggested_price_cents integer,
  p_currency text default 'TRY',
  p_note text default null,
  p_evidence_url text default null
) returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_business_id uuid;
  v_cnt int;
  v_note text;
  v_evidence_url text;
  v_current_price int;
  v_ok_30d int := 0;
  v_bad_30d int := 0;
  v_total_30d int := 0;
  v_confidence numeric := 0;
  v_auto_approved boolean := false;
  v_pending_count int := 0;
  v_shadow boolean := false;
  v_rate jsonb;
begin
  if auth.uid() is null then
    return jsonb_build_object('ok', false, 'error', 'not_authenticated');
  end if;

  if p_suggested_price_cents < 0 then
    return jsonb_build_object('ok', false, 'error', 'bad_price');
  end if;

  if p_currency is null or length(trim(p_currency)) <> 3 then
    return jsonb_build_object('ok', false, 'error', 'bad_currency');
  end if;

  v_note := nullif(trim(p_note), '');
  v_evidence_url := nullif(trim(p_evidence_url), '');

  if v_note is not null and v_note ~* '(https?://|www\.|t\.me/|wa\.me/|instagram\.com|@[a-z0-9_]{2,}|(\+?\d[\d\s\-\(\)]{7,}\d))' then
    return jsonb_build_object('ok', false, 'error', 'contains_link_or_phone');
  end if;

  if v_note is not null
     and length(regexp_replace(v_note, '[[:alnum:][:space:]]', '', 'g')) > 12 then
    return jsonb_build_object('ok', false, 'error', 'emoji_spam');
  end if;

  if v_evidence_url is not null and left(v_evidence_url, 4) <> 'http' then
    return jsonb_build_object('ok', false, 'error', 'bad_evidence_url');
  end if;

  v_rate := public.consume_rate_limit_v1('price_suggestion', 40);
  if coalesce((v_rate->>'ok')::boolean, false) is false then
    return jsonb_build_object('ok', false, 'error', 'price_suggestion_daily_rate_limited');
  end if;

  select mi.business_id, mi.price_cents
    into v_business_id, v_current_price
  from public.menu_items mi
  where mi.id = p_menu_item_id and mi.status = 'published';

  if v_business_id is null then
    return jsonb_build_object('ok', false, 'error', 'not_found');
  end if;

  -- rate limit: same user, same item, once per 24h
  select count(*) into v_cnt
  from public.menu_item_price_suggestions
  where menu_item_id = p_menu_item_id
    and created_by = auth.uid()
    and created_at >= now() - interval '24 hours';

  if v_cnt > 0 then
    return jsonb_build_object('ok', false, 'error', 'rate_limited_24h');
  end if;

  select
    count(*) filter (where vote = 1 and created_at >= now() - interval '30 days'),
    count(*) filter (where vote = -1 and created_at >= now() - interval '30 days'),
    count(*) filter (where created_at >= now() - interval '30 days')
    into v_ok_30d, v_bad_30d, v_total_30d
  from public.menu_item_price_votes
  where menu_item_id = p_menu_item_id;

  v_confidence :=
    greatest(
      0::numeric,
      least(
        1::numeric,
        (case when v_total_30d <= 0 then 0.2 else (v_ok_30d::numeric / nullif(v_total_30d, 0)) end) * 0.8
        +
        (case
          when v_total_30d >= 12 then 0.2
          when v_total_30d >= 6 then 0.12
          when v_total_30d >= 3 then 0.06
          else 0
        end)
      )
    );

  v_shadow := public.is_shadow_banned_v1();
  if v_shadow then
    v_auto_approved := false;
  end if;

  -- Conservative auto-approval rule:
  -- enough signal + strong positive votes + small price delta (<=5%)
  if v_current_price is not null
     and v_current_price > 0
     and v_total_30d >= 8
     and v_ok_30d >= (v_bad_30d * 3)
     and abs(p_suggested_price_cents - v_current_price)::numeric / v_current_price::numeric <= 0.05
  then
    v_auto_approved := true;
  end if;

  if v_auto_approved then
    update public.menu_items
    set price_cents = p_suggested_price_cents,
        currency = upper(trim(p_currency)),
        updated_at = now()
    where id = p_menu_item_id;

    insert into public.menu_item_price_suggestions(
      menu_item_id, business_id, suggested_price_cents, currency, note, created_by,
      evidence_url, status, handled_at, approved_at, is_shadow
    )
    values (
      p_menu_item_id, v_business_id, p_suggested_price_cents, upper(trim(p_currency)), v_note, auth.uid(),
      v_evidence_url, 'approved', now(), now(), v_shadow
    );

    insert into public.menu_item_price_history(
      menu_item_id, price_cents, currency, source, created_by
    )
    values (
      p_menu_item_id, p_suggested_price_cents, upper(trim(p_currency)), 'auto_rule', auth.uid()
    );

    return jsonb_build_object(
      'ok', true,
      'auto_approved', true,
      'confidence_score', v_confidence,
      'pending_count', 0,
      'shadowed', v_shadow
    );
  end if;

  insert into public.menu_item_price_suggestions(
    menu_item_id, business_id, suggested_price_cents, currency, note, created_by, evidence_url, is_shadow
  )
  values (
    p_menu_item_id, v_business_id, p_suggested_price_cents, upper(trim(p_currency)), v_note, auth.uid(), v_evidence_url, v_shadow
  );

  select count(*) into v_pending_count
  from public.menu_item_price_suggestions
  where menu_item_id = p_menu_item_id
    and status = 'pending';

  return jsonb_build_object(
    'ok', true,
    'auto_approved', false,
    'confidence_score', v_confidence,
    'pending_count', v_pending_count,
    'shadowed', v_shadow
  );
end;
$$;

create or replace function public.add_menu_item_photo_v1(
  p_menu_item_id uuid,
  p_url text,
  p_url_large text default null,
  p_url_thumb text default null,
  p_provider text default 'wp'
) returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $function$
declare
  v_business_id uuid;
  v_photo_id uuid;
  v_shadow boolean := false;
  v_rate jsonb;
begin
  if auth.uid() is null then
    return jsonb_build_object('ok', false, 'error', 'not_authenticated');
  end if;

  select business_id into v_business_id
  from public.menu_items
  where id = p_menu_item_id;

  if v_business_id is null then
    return jsonb_build_object('ok', false, 'error', 'not_found');
  end if;

  v_rate := public.consume_rate_limit_v1('menu_photo', 20);
  if coalesce((v_rate->>'ok')::boolean, false) is false then
    return jsonb_build_object('ok', false, 'error', 'menu_photo_daily_rate_limited');
  end if;

  v_shadow := public.is_shadow_banned_v1();

  insert into public.menu_item_photos(
    menu_item_id,
    business_id,
    url,
    url_large,
    url_thumb,
    provider,
    created_by,
    is_shadow
  )
  values (
    p_menu_item_id,
    v_business_id,
    p_url,
    p_url_large,
    p_url_thumb,
    p_provider,
    auth.uid(),
    v_shadow
  )
  returning id into v_photo_id;

  return jsonb_build_object('ok', true, 'photo_id', v_photo_id, 'shadowed', v_shadow);
end;
$function$;

create or replace function public.get_menu_item_photos_v1(
  p_menu_item_id uuid,
  p_limit integer default 12
) returns table(
  id uuid,
  url text,
  url_large text,
  url_thumb text,
  provider text,
  created_at timestamp with time zone,
  up_votes integer,
  down_votes integer,
  score integer,
  my_vote smallint
)
language sql
stable
security definer
set search_path to 'public'
as $$
  select
    p.id,
    p.url,
    p.url_large,
    p.url_thumb,
    p.provider,
    p.created_at,
    p.up_votes,
    p.down_votes,
    (p.up_votes - p.down_votes) as score,
    (select v.vote from public.menu_item_photo_votes v
      where v.photo_id = p.id and v.user_id = auth.uid()
      limit 1) as my_vote
  from public.menu_item_photos p
  where p.menu_item_id = p_menu_item_id
    and (p.is_shadow is not true or p.created_by = auth.uid() or public.is_admin())
  order by p.created_at desc
  limit greatest(p_limit, 0);
$$;

create or replace function public.add_business_media_v1(
  p_business_id uuid,
  p_url text,
  p_url_large text default null,
  p_url_thumb text default null,
  p_provider text default 'wp',
  p_kind text default 'venue'
) returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  v_shadow boolean := false;
  v_rate jsonb;
begin
  if auth.uid() is null then
    return jsonb_build_object('ok', false, 'error', 'not_authenticated');
  end if;

  if p_business_id is null then
    return jsonb_build_object('ok', false, 'error', 'missing_business_id');
  end if;

  v_rate := public.consume_rate_limit_v1('business_media', 15);
  if coalesce((v_rate->>'ok')::boolean, false) is false then
    return jsonb_build_object('ok', false, 'error', 'business_media_daily_rate_limited');
  end if;

  v_shadow := public.is_shadow_banned_v1();

  insert into public.business_media(
    business_id, kind, url, url_large, url_thumb, provider, created_by, is_shadow
  ) values (
    p_business_id, coalesce(p_kind, 'venue'), p_url, p_url_large, p_url_thumb, p_provider, auth.uid(), v_shadow
  );

  return jsonb_build_object('ok', true, 'shadowed', v_shadow);
end;
$$;

grant all on function public.add_business_media_v1(uuid, text, text, text, text, text) to anon;
grant all on function public.add_business_media_v1(uuid, text, text, text, text, text) to authenticated;
grant all on function public.add_business_media_v1(uuid, text, text, text, text, text) to service_role;

create or replace function public.enforce_review_insert_rate_limits_v1()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_recent_same_business int;
  v_recent_daily int;
begin
  if new.user_id is null then
    return new;
  end if;

  select count(*)
    into v_recent_same_business
  from public.reviews r
  where r.user_id = new.user_id
    and r.business_id = new.business_id
    and r.created_at >= now() - interval '12 hours';

  if v_recent_same_business > 0 then
    raise exception 'same_business_cooldown';
  end if;

  select count(*)
    into v_recent_daily
  from public.reviews r
  where r.user_id = new.user_id
    and r.created_at >= now() - interval '24 hours';

  if v_recent_daily >= 15 then
    raise exception 'review_daily_rate_limited';
  end if;

  return new;
end;
$$;

create or replace function public.enforce_price_suggestion_insert_rate_limits_v1()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_recent_same_item int;
  v_recent_daily int;
begin
  if new.created_by is null then
    return new;
  end if;

  select count(*)
    into v_recent_same_item
  from public.menu_item_price_suggestions s
  where s.created_by = new.created_by
    and s.menu_item_id = new.menu_item_id
    and s.created_at >= now() - interval '24 hours';

  if v_recent_same_item > 0 then
    raise exception 'price_suggestion_same_item_cooldown';
  end if;

  select count(*)
    into v_recent_daily
  from public.menu_item_price_suggestions s
  where s.created_by = new.created_by
    and s.created_at >= now() - interval '24 hours';

  if v_recent_daily >= 40 then
    raise exception 'price_suggestion_daily_rate_limited';
  end if;

  return new;
end;
$$;

create or replace function public.owner_list_menu_price_suggestions_v1(
  p_business_id uuid,
  p_status text default 'pending',
  p_limit integer default 30,
  p_offset integer default 0
) returns table(
  suggestion_id uuid,
  status text,
  created_at timestamp with time zone,
  menu_item_id uuid,
  item_name text,
  current_price_cents integer,
  suggested_price_cents integer,
  currency text,
  created_by uuid
)
language sql
stable
security definer
set search_path to 'public'
as $$
  select
    s.id as suggestion_id,
    s.status::text,
    s.created_at,
    mi.id as menu_item_id,
    mi.name as item_name,
    mi.price_cents as current_price_cents,
    s.suggested_price_cents,
    s.currency,
    s.created_by
  from public.menu_item_price_suggestions s
  join public.menu_items mi on mi.id = s.menu_item_id
  where s.business_id = p_business_id
    and public.is_owner_of_business(p_business_id)
    and (p_status is null or s.status::text = p_status)
    and (s.is_shadow is not true)
  order by (s.status='pending') desc, s.created_at asc
  limit greatest(p_limit,0)
  offset greatest(p_offset,0);
$$;

create or replace function public.admin_list_menu_price_suggestions_v2(
  p_status text default null,
  p_limit integer default 30,
  p_offset integer default 0,
  p_sla_only boolean default false,
  p_assigned text default null
)
returns table(
  suggestion_id uuid,
  status text,
  created_at timestamp with time zone,
  sla_breached boolean,
  business_id uuid,
  business_name text,
  city text,
  district text,
  menu_item_id uuid,
  item_name text,
  current_price_cents integer,
  suggested_price_cents integer,
  currency text,
  created_by uuid,
  assigned_to uuid,
  assigned_at timestamp with time zone
)
language sql
stable
security definer
set search_path to 'public'
as $$
  select
    s.id as suggestion_id,
    s.status::text,
    s.created_at,
    (s.status='pending' and s.created_at < now() - interval '48 hours') as sla_breached,
    b.id as business_id,
    b.name as business_name,
    b.city,
    b.district,
    mi.id as menu_item_id,
    mi.name as item_name,
    mi.price_cents as current_price_cents,
    s.suggested_price_cents,
    s.currency,
    s.created_by,
    s.handled_by as assigned_to,
    s.handled_at as assigned_at
  from public.menu_item_price_suggestions s
  join public.menu_items mi on mi.id = s.menu_item_id
  join public.businesses b on b.id = s.business_id
  where (p_status is null or s.status::text = p_status)
    and (p_assigned is null or p_assigned = '' or (p_assigned = 'assigned' and s.handled_by is not null) or (p_assigned = 'unassigned' and s.handled_by is null))
    and (p_sla_only = false or (s.status='pending' and s.created_at < now() - interval '48 hours'))
    and (s.is_shadow is not true or public.is_admin())
  order by (s.status='pending') desc, s.created_at asc
  limit greatest(p_limit,0)
  offset greatest(p_offset,0);
$$;

-- ===== END MIGRATION: 20260320000004_content_moderation.sql =====

-- ===== BEGIN MIGRATION: 20260320000005_auto_moderation_rules.sql =====
-- Auto moderation rules: low-risk auto decisions, queueing, and repeat offender strikes.

create table if not exists public.user_moderation_strikes (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null,
  reason text,
  source text,
  created_at timestamptz not null default now()
);

create index if not exists idx_user_moderation_strikes_user
  on public.user_moderation_strikes(user_id, created_at desc);

create or replace function public.add_moderation_strike_v1(
  p_user_id uuid,
  p_reason text default null,
  p_source text default null
) returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_recent int := 0;
  v_shadow boolean := false;
begin
  if p_user_id is null then
    return jsonb_build_object('ok', false, 'error', 'missing_user');
  end if;

  insert into public.user_moderation_strikes(user_id, reason, source)
  values (p_user_id, nullif(trim(p_reason), ''), nullif(trim(p_source), ''));

  select count(*) into v_recent
  from public.user_moderation_strikes s
  where s.user_id = p_user_id
    and s.created_at >= now() - interval '30 days';

  if v_recent >= 3 then
    update public.user_profiles
    set shadow_banned = true
    where user_id = p_user_id;
    v_shadow := true;
  end if;

  return jsonb_build_object(
    'ok', true,
    'recent_strikes_30d', v_recent,
    'shadow_banned', v_shadow
  );
end;
$$;

create or replace function public.auto_close_duplicate_report_v1(p_report_id uuid)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare
  v_r public.reports%rowtype;
  v_exists boolean;
begin
  select * into v_r
  from public.reports
  where id = p_report_id;

  if v_r.id is null then return false; end if;

  select exists(
    select 1
    from public.reports
    where user_id = v_r.user_id
      and target_type = v_r.target_type
      and target_id = v_r.target_id
      and id <> v_r.id
      and created_at >= now() - interval '24 hours'
  ) into v_exists;

  if v_exists then
    update public.reports
    set
      durum = 'kapandi',
      admin_note = 'Otomatik: 24 saat içinde mükerrer bildirim',
      handled_at = now(),
      auto_moderated = true
    where id = p_report_id;

    perform public.log_admin_action_v1(
      'report.auto_close_duplicate',
      'reports',
      p_report_id,
      jsonb_build_object()
    );

    return true;
  end if;

  return false;
end;
$$;

create or replace function public.auto_reject_low_quality_report_v1(p_report_id uuid)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare
  v_len int;
  v_uid uuid;
begin
  select length(coalesce(details,'')), user_id into v_len, v_uid
  from public.reports
  where id = p_report_id;

  if v_len < 15 then
    update public.reports
    set
      durum = 'reddedildi',
      admin_note = 'Otomatik: çok kısa / düşük kaliteli bildirim',
      handled_at = now(),
      auto_moderated = true
    where id = p_report_id;

    perform public.log_admin_action_v1(
      'report.auto_reject_low_quality',
      'reports',
      p_report_id,
      jsonb_build_object('length', v_len)
    );

    perform public.add_moderation_strike_v1(
      v_uid,
      'low_quality_report',
      'report'
    );

    return true;
  end if;

  return false;
end;
$$;

create or replace function public.auto_queue_grey_report_v1(p_report_id uuid)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare
  v_r public.reports%rowtype;
  v_len int;
begin
  select * into v_r
  from public.reports
  where id = p_report_id;
  v_len := length(coalesce(v_r.details, ''));

  if v_r.id is null then return false; end if;

  if v_r.durum in ('kapandi','reddedildi') then
    return false;
  end if;

  if v_len >= 15 and v_len <= 200 and v_r.reason not in ('spam','duplicate') then
    update public.reports
    set
      durum = 'inceleniyor',
      admin_note = 'Otomatik: gri alan, kuyruğa alındı',
      handled_at = now(),
      auto_moderated = true
    where id = p_report_id;

    perform public.log_admin_action_v1(
      'report.auto_queue_grey',
      'reports',
      p_report_id,
      jsonb_build_object('length', v_len, 'reason', v_r.reason)
    );

    return true;
  end if;

  return false;
end;
$$;

create or replace function public.apply_auto_moderation_rules_v1(p_target text, p_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_applied boolean := false;
begin
  if not public.is_admin() then
    raise exception 'not_admin';
  end if;

  if p_target = 'report' then
    v_applied := public.auto_close_duplicate_report_v1(p_id)
                 or public.auto_reject_low_quality_report_v1(p_id)
                 or public.auto_queue_grey_report_v1(p_id);
  elsif p_target = 'claim' then
    v_applied := public.auto_approve_trusted_owner_claim_v1(p_id);
  end if;

  return jsonb_build_object('ok', true, 'applied', v_applied);
end;
$$;

create or replace function public.trg_auto_moderate_report_v1()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  perform public.auto_close_duplicate_report_v1(new.id);
  perform public.auto_reject_low_quality_report_v1(new.id);
  perform public.auto_queue_grey_report_v1(new.id);
  return new;
end;
$$;

drop trigger if exists trg_auto_moderate_report on public.reports;
create trigger trg_auto_moderate_report
after insert on public.reports
for each row
execute function public.trg_auto_moderate_report_v1();

-- ===== END MIGRATION: 20260320000005_auto_moderation_rules.sql =====

-- ===== BEGIN MIGRATION: 20260320000006_smart_feed_context.sql =====
create or replace function public.get_smart_feed_v2(
  p_limit integer,
  p_offset integer,
  p_city text default null,
  p_districts text[] default null,
  p_categories text[] default null,
  p_bundles text[] default null,
  p_price_max_cents integer default null,
  p_weather_hint text default null,
  p_time_label text default null,
  p_day_label text default null
)
returns table (
  event_id uuid,
  event_type text,
  business_id uuid,
  business_name text,
  created_at timestamptz,
  ref_type text,
  ref_id uuid,
  payload jsonb
)
language plpgsql
security definer
as $$
begin
  if to_regprocedure(
       'public.get_smart_feed_v1(integer,integer,text,text[],text[],text[],integer)'
     ) is not null then
    return query execute
      'select
         event_id,
         event_type,
         business_id,
         business_name,
         created_at,
         ref_type,
         ref_id,
         coalesce(payload, ''{}''::jsonb)
           || jsonb_strip_nulls(
                jsonb_build_object(
                  ''weather_hint'', $8,
                  ''time_label'', $9,
                  ''day_label'', $10
                )
              ) as payload
       from public.get_smart_feed_v1($1,$2,$3,$4,$5,$6,$7)'
      using
        p_limit,
        p_offset,
        p_city,
        p_districts,
        p_categories,
        p_bundles,
        p_price_max_cents,
        p_weather_hint,
        p_time_label,
        p_day_label;
  else
    return query
      select
        null::uuid,
        null::text,
        null::uuid,
        null::text,
        null::timestamptz,
        null::text,
        null::uuid,
        '{}'::jsonb
      where false;
  end if;
end;
$$;

-- ===== END MIGRATION: 20260320000006_smart_feed_context.sql =====

-- ===== BEGIN MIGRATION: 20260320000007_business_activity_social_proof.sql =====
create or replace function public.get_business_activity_v1(
  p_business_id uuid,
  p_limit integer default 10
)
returns table(
  activity_id uuid,
  activity_type text,
  meta jsonb,
  created_at timestamp with time zone
)
language sql
stable
security definer
set search_path to 'public'
as $function$
  with base as (
    select
      a.id as activity_id,
      a.type as activity_type,
      a.meta,
      a.created_at
    from public.business_activity_log a
    where a.business_id = p_business_id
  ),
  menu_views as (
    select count(*)::int as count_today
    from public.analytics_events e
    where e.business_id = p_business_id
      and e.event_name = 'menu_view'
      and e.created_at >= date_trunc('day', now())
  ),
  ranked as (
    select
      b.id,
      b.district,
      coalesce(q.score, 0) as score,
      rank() over (
        partition by b.district
        order by coalesce(q.score, 0) desc, b.id
      ) as rank
    from public.businesses b
    left join public.business_quality_score_v1 q
      on q.business_id = b.id
    where b.district is not null
      and b.is_active = true
  ),
  district_rank as (
    select r.rank, r.district
    from ranked r
    where r.id = p_business_id
  ),
  synthetic as (
    select
      '00000000-0000-0000-0000-000000000000'::uuid as activity_id,
      'menu_views' as activity_type,
      jsonb_build_object('count_today', mv.count_today) as meta,
      now() as created_at
    from menu_views mv
    where mv.count_today > 0

    union all

    select
      '00000000-0000-0000-0000-000000000000'::uuid as activity_id,
      'district_rank' as activity_type,
      jsonb_build_object('rank', dr.rank, 'district', dr.district) as meta,
      now() as created_at
    from district_rank dr
    where dr.rank is not null
  )
  select *
  from (
    select * from base
    union all
    select * from synthetic
  ) s
  order by created_at desc
  limit greatest(p_limit, 0);
$function$;

-- ===== END MIGRATION: 20260320000007_business_activity_social_proof.sql =====

-- ===== BEGIN MIGRATION: 20260321000000_remote_placeholder.sql =====
-- placeholder for remote version alignment

-- ===== END MIGRATION: 20260321000000_remote_placeholder.sql =====

-- ===== BEGIN MIGRATION: 20260321000001_kpi_analytics.sql =====
alter table public.analytics_events
  drop constraint if exists analytics_events_event_name_check;

alter table public.analytics_events
  add constraint analytics_events_event_name_check check (
    event_name = any (
      array[
        'menu_shared',
        'qr_scanned',
        'menu_link_opened',
        'app_install_from_menu',
        'business_reservation_click',
        'business_phone_click',
        'business_whatsapp_click',
        'business_order_click',
        'business_directions_click',
        'business_page_view',
        'menu_view',
        'discovery_impression',
        'discovery_business_click',
        'business_impression',
        'price_suggestion_submitted'
      ]
    )
  );

create or replace function public.log_event_v1(
  p_event_name text,
  p_business_id uuid default null,
  p_menu_id uuid default null,
  p_source text default null,
  p_client_id text default null,
  p_meta jsonb default '{}'::jsonb
)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  v_event_name text := coalesce(trim(p_event_name), '');
  v_client text := nullif(trim(p_client_id), '');
  v_key text;
  v_today date := current_date;
  v_current_count int;
  v_user_id uuid := coalesce(auth.uid(), '00000000-0000-0000-0000-000000000000'::uuid);
begin
  if v_event_name not in (
    'menu_shared',
    'qr_scanned',
    'menu_link_opened',
    'app_install_from_menu',
    'business_reservation_click',
    'business_phone_click',
    'business_whatsapp_click',
    'business_order_click',
    'business_directions_click',
    'business_page_view',
    'menu_view',
    'discovery_impression',
    'discovery_business_click',
    'business_impression',
    'price_suggestion_submitted'
  ) then
    return jsonb_build_object('ok', false, 'code', 'invalid_event');
  end if;

  if v_event_name = 'menu_link_opened' and v_client is null then
    return jsonb_build_object('ok', false, 'code', 'client_required');
  end if;

  if v_event_name = 'menu_link_opened' then
    v_key := format('menu_link_opened:%s:%s', v_client, v_today::text);
    select count into v_current_count
    from public.user_rate_limits
    where key = v_key;

    if coalesce(v_current_count, 0) >= 200 then
      return jsonb_build_object('ok', false, 'code', 'rate_limited');
    end if;

    insert into public.user_rate_limits (key, user_id, action, day, count, updated_at)
    values (v_key, v_user_id, 'menu_link_opened', v_today, 1, now())
    on conflict (key) do update
      set count = public.user_rate_limits.count + 1,
          updated_at = now();
  end if;

  insert into public.analytics_events (
    event_name,
    business_id,
    menu_id,
    source,
    client_id,
    user_id,
    meta
  )
  values (
    v_event_name,
    p_business_id,
    p_menu_id,
    nullif(trim(p_source), ''),
    v_client,
    v_user_id,
    coalesce(p_meta, '{}'::jsonb)
  );

  return jsonb_build_object('ok', true);
end;
$$;

create or replace function public.admin_kpi_summary_v1(p_days integer default 30)
returns table(
  dau integer,
  dau_prev integer,
  wau integer,
  wau_prev integer,
  discovery_impressions integer,
  discovery_impressions_prev integer,
  discovery_clicks integer,
  discovery_clicks_prev integer,
  discovery_ctr double precision,
  discovery_ctr_prev double precision,
  business_views integer,
  business_views_prev integer,
  menu_views integer,
  menu_views_prev integer,
  menu_view_rate double precision,
  menu_view_rate_prev double precision,
  price_suggestions integer,
  price_suggestions_prev integer,
  price_verification_rate double precision,
  price_verification_rate_prev double precision,
  reports_avg_resolution_minutes double precision,
  reports_avg_resolution_minutes_prev double precision
)
language sql
as $$
with
  events as (
    select *
    from public.analytics_events
    where created_at >= now() - (p_days::text || ' days')::interval
  ),
  discovery_impressions_cte as (
    select
      coalesce(sum(nullif((meta->>'count'), '')::int), count(*))::int as impressions
    from events
    where event_name = 'discovery_impression'
  ),
  prev_events as (
    select *
    from public.analytics_events
    where created_at >= now() - ((p_days * 2)::text || ' days')::interval
      and created_at < now() - (p_days::text || ' days')::interval
  ),
  discovery_impressions_prev_cte as (
    select
      coalesce(sum(nullif((meta->>'count'), '')::int), count(*))::int as impressions
    from prev_events
    where event_name = 'discovery_impression'
  ),
  discovery_clicks_cte as (
    select count(*)::int as clicks
    from events
    where event_name = 'discovery_business_click'
  ),
  discovery_clicks_prev_cte as (
    select count(*)::int as clicks
    from prev_events
    where event_name = 'discovery_business_click'
  ),
  business_views_cte as (
    select count(*)::int as views
    from events
    where event_name = 'business_page_view'
  ),
  business_views_prev_cte as (
    select count(*)::int as views
    from prev_events
    where event_name = 'business_page_view'
  ),
  menu_views_cte as (
    select count(*)::int as views
    from events
    where event_name = 'menu_view'
  ),
  menu_views_prev_cte as (
    select count(*)::int as views
    from prev_events
    where event_name = 'menu_view'
  ),
  price_suggestions_cte as (
    select count(*)::int as cnt
    from events
    where event_name = 'price_suggestion_submitted'
  ),
  price_suggestions_prev_cte as (
    select count(*)::int as cnt
    from prev_events
    where event_name = 'price_suggestion_submitted'
  )
select
  (
    select count(distinct client_id)::int
    from public.analytics_events
    where created_at >= now() - interval '1 day'
      and client_id is not null
      and client_id <> ''
  ) as dau,
  (
    select count(distinct client_id)::int
    from public.analytics_events
    where created_at >= now() - interval '2 days'
      and created_at < now() - interval '1 day'
      and client_id is not null
      and client_id <> ''
  ) as dau_prev,
  (
    select count(distinct client_id)::int
    from public.analytics_events
    where created_at >= now() - interval '7 days'
      and client_id is not null
      and client_id <> ''
  ) as wau,
  (
    select count(distinct client_id)::int
    from public.analytics_events
    where created_at >= now() - interval '14 days'
      and created_at < now() - interval '7 days'
      and client_id is not null
      and client_id <> ''
  ) as wau_prev,
  d.impressions as discovery_impressions,
  dp.impressions as discovery_impressions_prev,
  c.clicks as discovery_clicks,
  cp.clicks as discovery_clicks_prev,
  case when d.impressions > 0 then c.clicks::double precision / d.impressions else 0 end as discovery_ctr,
  case when dp.impressions > 0 then cp.clicks::double precision / dp.impressions else 0 end as discovery_ctr_prev,
  bv.views as business_views,
  bvp.views as business_views_prev,
  mv.views as menu_views,
  mvp.views as menu_views_prev,
  case when bv.views > 0 then mv.views::double precision / bv.views else 0 end as menu_view_rate,
  case when bvp.views > 0 then mvp.views::double precision / bvp.views else 0 end as menu_view_rate_prev,
  ps.cnt as price_suggestions,
  psp.cnt as price_suggestions_prev,
  case when mv.views > 0 then ps.cnt::double precision / mv.views else 0 end as price_verification_rate,
  case when mvp.views > 0 then psp.cnt::double precision / mvp.views else 0 end as price_verification_rate_prev,
  (
    select coalesce(avg(extract(epoch from (handled_at - created_at)) / 60.0), 0)
    from public.reports
    where handled_at is not null
      and created_at >= now() - (p_days::text || ' days')::interval
  ) as reports_avg_resolution_minutes,
  (
    select coalesce(avg(extract(epoch from (handled_at - created_at)) / 60.0), 0)
    from public.reports
    where handled_at is not null
      and created_at >= now() - ((p_days * 2)::text || ' days')::interval
      and created_at < now() - (p_days::text || ' days')::interval
  ) as reports_avg_resolution_minutes_prev
from discovery_impressions_cte d
cross join discovery_impressions_prev_cte dp
cross join discovery_clicks_cte c
cross join discovery_clicks_prev_cte cp
cross join business_views_cte bv
cross join business_views_prev_cte bvp
cross join menu_views_cte mv
cross join menu_views_prev_cte mvp
cross join price_suggestions_cte ps
cross join price_suggestions_prev_cte psp;
$$;

create or replace function public.owner_kpi_summary_v1(
  p_business_id uuid,
  p_days integer default 30
)
returns table(
  business_views integer,
  outbound_clicks integer,
  directions_clicks integer,
  search_impressions integer
)
language sql
as $$
with events as (
  select *
  from public.analytics_events
  where business_id = p_business_id
    and created_at >= now() - (p_days::text || ' days')::interval
)
select
  (select count(*) from events where event_name = 'business_page_view')::int as business_views,
  (select count(*) from events where event_name in (
      'business_reservation_click',
      'business_phone_click',
      'business_whatsapp_click',
      'business_order_click'
    ))::int as outbound_clicks,
  (select count(*) from events where event_name = 'business_directions_click')::int as directions_clicks,
  (select count(*) from events where event_name = 'business_impression')::int as search_impressions;
$$;

grant all on function public.admin_kpi_summary_v1(p_days integer) to anon, authenticated, service_role;
grant all on function public.owner_kpi_summary_v1(p_business_id uuid, p_days integer) to anon, authenticated, service_role;

-- ===== END MIGRATION: 20260321000001_kpi_analytics.sql =====

-- ===== BEGIN MIGRATION: 20260321000002_micro_trends.sql =====
create or replace function public.get_district_top_views_v1(
  p_city text,
  p_district text,
  p_neighborhood text default null,
  p_limit int default 10
)
returns table(
  id uuid,
  name text,
  category text,
  city text,
  district text,
  address text,
  lat double precision,
  lng double precision,
  distance_km double precision,
  quality_score double precision,
  avg_rating double precision,
  median_price_cents int,
  is_open_now boolean,
  recent_price_verified_count int,
  views_count int
)
language sql
stable
security definer
set search_path to 'public'
as $$
  with params as (
    select
      nullif(trim(p_city), '') as city,
      nullif(trim(p_district), '') as district,
      nullif(trim(p_neighborhood), '') as neighborhood
  ),
  views as (
    select
      business_id,
      count(*) filter (
        where created_at >= now() - interval '7 days'
      ) as views_7d
    from public.analytics_events
    where event_name = 'menu_view'
    group by business_id
  )
  select
    bws.id,
    bws.name,
    bws.category,
    bws.city,
    bws.district,
    bws.address,
    bws.lat,
    bws.lng,
    null::double precision as distance_km,
    bws.quality_score,
    bws.avg_rating,
    bws.median_price_cents,
    null::boolean as is_open_now,
    bws.recent_price_verified_count,
    coalesce(v.views_7d, 0)::int as views_count
  from params p
  join public.businesses_with_stats bws
    on bws.city = p.city and bws.district = p.district
  join public.businesses b on b.id = bws.id
  left join views v on v.business_id = bws.id
  where p.city is not null
    and p.district is not null
    and (p.neighborhood is null or b.neighborhood = p.neighborhood)
  order by v.views_7d desc nulls last, bws.quality_score desc nulls last
  limit p_limit;
$$;

grant all on function public.get_district_top_views_v1(text, text, text, int) to anon;
grant all on function public.get_district_top_views_v1(text, text, text, int) to authenticated;
grant all on function public.get_district_top_views_v1(text, text, text, int) to service_role;

create or replace function public.get_district_price_changes_v1(
  p_city text,
  p_district text,
  p_neighborhood text default null,
  p_limit int default 10
)
returns table(
  id uuid,
  name text,
  category text,
  city text,
  district text,
  address text,
  lat double precision,
  lng double precision,
  distance_km double precision,
  quality_score double precision,
  avg_rating double precision,
  median_price_cents int,
  is_open_now boolean,
  recent_price_verified_count int,
  price_changes_count int
)
language sql
stable
security definer
set search_path to 'public'
as $$
  with params as (
    select
      nullif(trim(p_city), '') as city,
      nullif(trim(p_district), '') as district,
      nullif(trim(p_neighborhood), '') as neighborhood
  ),
  changes as (
    select
      mi.business_id,
      count(*) filter (
        where h.created_at >= now() - interval '7 days'
      ) as changes_7d
    from public.menu_item_price_history h
    join public.menu_items mi on mi.id = h.menu_item_id
    group by mi.business_id
  )
  select
    bws.id,
    bws.name,
    bws.category,
    bws.city,
    bws.district,
    bws.address,
    bws.lat,
    bws.lng,
    null::double precision as distance_km,
    bws.quality_score,
    bws.avg_rating,
    bws.median_price_cents,
    null::boolean as is_open_now,
    bws.recent_price_verified_count,
    coalesce(c.changes_7d, 0)::int as price_changes_count
  from params p
  join public.businesses_with_stats bws
    on bws.city = p.city and bws.district = p.district
  join public.businesses b on b.id = bws.id
  left join changes c on c.business_id = bws.id
  where p.city is not null
    and p.district is not null
    and (p.neighborhood is null or b.neighborhood = p.neighborhood)
  order by c.changes_7d desc nulls last, bws.quality_score desc nulls last
  limit p_limit;
$$;

grant all on function public.get_district_price_changes_v1(text, text, text, int) to anon;
grant all on function public.get_district_price_changes_v1(text, text, text, int) to authenticated;
grant all on function public.get_district_price_changes_v1(text, text, text, int) to service_role;

create or replace function public.get_district_night_favorites_v1(
  p_city text,
  p_district text,
  p_neighborhood text default null,
  p_limit int default 10
)
returns table(
  id uuid,
  name text,
  category text,
  city text,
  district text,
  address text,
  lat double precision,
  lng double precision,
  distance_km double precision,
  quality_score double precision,
  avg_rating double precision,
  median_price_cents int,
  is_open_now boolean,
  recent_price_verified_count int,
  favorites_count int
)
language sql
stable
security definer
set search_path to 'public'
as $$
  with params as (
    select
      nullif(trim(p_city), '') as city,
      nullif(trim(p_district), '') as district,
      nullif(trim(p_neighborhood), '') as neighborhood
  ),
  favorites as (
    select business_id, count(*) as favorites_count
    from public.business_follows
    group by business_id
  ),
  night_open as (
    select bh.business_id
    from public.business_hours bh
    where (
      bh.mon_open is not null and bh.mon_close is not null and
      (bh.mon_close >= time '23:00' or bh.mon_close < bh.mon_open)
    ) or (
      bh.tue_open is not null and bh.tue_close is not null and
      (bh.tue_close >= time '23:00' or bh.tue_close < bh.tue_open)
    ) or (
      bh.wed_open is not null and bh.wed_close is not null and
      (bh.wed_close >= time '23:00' or bh.wed_close < bh.wed_open)
    ) or (
      bh.thu_open is not null and bh.thu_close is not null and
      (bh.thu_close >= time '23:00' or bh.thu_close < bh.thu_open)
    ) or (
      bh.fri_open is not null and bh.fri_close is not null and
      (bh.fri_close >= time '23:00' or bh.fri_close < bh.fri_open)
    ) or (
      bh.sat_open is not null and bh.sat_close is not null and
      (bh.sat_close >= time '23:00' or bh.sat_close < bh.sat_open)
    ) or (
      bh.sun_open is not null and bh.sun_close is not null and
      (bh.sun_close >= time '23:00' or bh.sun_close < bh.sun_open)
    )
  )
  select
    bws.id,
    bws.name,
    bws.category,
    bws.city,
    bws.district,
    bws.address,
    bws.lat,
    bws.lng,
    null::double precision as distance_km,
    bws.quality_score,
    bws.avg_rating,
    bws.median_price_cents,
    null::boolean as is_open_now,
    bws.recent_price_verified_count,
    coalesce(f.favorites_count, 0)::int as favorites_count
  from params p
  join public.businesses_with_stats bws
    on bws.city = p.city and bws.district = p.district
  join public.businesses b on b.id = bws.id
  join night_open n on n.business_id = bws.id
  left join favorites f on f.business_id = bws.id
  where p.city is not null
    and p.district is not null
    and (p.neighborhood is null or b.neighborhood = p.neighborhood)
  order by f.favorites_count desc nulls last, bws.quality_score desc nulls last
  limit p_limit;
$$;

grant all on function public.get_district_night_favorites_v1(text, text, text, int) to anon;
grant all on function public.get_district_night_favorites_v1(text, text, text, int) to authenticated;
grant all on function public.get_district_night_favorites_v1(text, text, text, int) to service_role;

-- ===== END MIGRATION: 20260321000002_micro_trends.sql =====

-- ===== BEGIN MIGRATION: 20260321000003_neighborhood_support.sql =====
alter table public.businesses
  add column if not exists neighborhood text;

alter table public.user_location_prefs
  add column if not exists neighborhood text;

create or replace function public.upsert_user_location_prefs_v1(
  p_city text,
  p_district text,
  p_neighborhood text default null,
  p_mode text default 'manual'
)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $$
begin
  if auth.uid() is null then
    return jsonb_build_object('ok', false, 'error', 'not_authenticated');
  end if;

  if p_city is null or btrim(p_city) = '' or p_district is null or btrim(p_district) = '' then
    return jsonb_build_object('ok', false, 'error', 'invalid_location');
  end if;

  insert into public.user_location_prefs (user_id, city, district, neighborhood, mode, updated_at)
  values (auth.uid(), p_city, p_district, nullif(trim(p_neighborhood), ''), p_mode, now())
  on conflict (user_id) do update
  set city = excluded.city,
      district = excluded.district,
      neighborhood = excluded.neighborhood,
      mode = excluded.mode,
      updated_at = now();

  return jsonb_build_object('ok', true);
end;
$$;

create or replace function public.get_user_location_prefs_v1()
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  v_row record;
begin
  if auth.uid() is null then
    return jsonb_build_object('ok', false, 'error', 'not_authenticated');
  end if;

  select city, district, neighborhood, mode, updated_at
    into v_row
  from public.user_location_prefs
  where user_id = auth.uid();

  if not found then
    return jsonb_build_object('ok', true, 'data', null);
  end if;

  return jsonb_build_object(
    'ok', true,
    'data', jsonb_build_object(
      'city', v_row.city,
      'district', v_row.district,
      'neighborhood', v_row.neighborhood,
      'mode', v_row.mode,
      'updated_at', v_row.updated_at
    )
  );
end;
$$;

grant all on function public.upsert_user_location_prefs_v1(text, text, text, text) to anon;
grant all on function public.upsert_user_location_prefs_v1(text, text, text, text) to authenticated;
grant all on function public.upsert_user_location_prefs_v1(text, text, text, text) to service_role;

grant all on function public.get_user_location_prefs_v1() to anon;
grant all on function public.get_user_location_prefs_v1() to authenticated;
grant all on function public.get_user_location_prefs_v1() to service_role;

-- ===== END MIGRATION: 20260321000003_neighborhood_support.sql =====

-- ===== BEGIN MIGRATION: 20260321000004_micro_trends_fix.sql =====
create or replace function public.get_district_top_views_v1(
  p_city text,
  p_district text,
  p_neighborhood text default null,
  p_limit int default 10
)
returns table(
  id uuid,
  name text,
  category text,
  city text,
  district text,
  address text,
  lat double precision,
  lng double precision,
  distance_km double precision,
  quality_score double precision,
  avg_rating double precision,
  median_price_cents int,
  is_open_now boolean,
  recent_price_verified_count int,
  views_count int
)
language sql
stable
security definer
set search_path to 'public'
as $$
  with params as (
    select
      nullif(trim(p_city), '') as city,
      nullif(trim(p_district), '') as district,
      nullif(trim(p_neighborhood), '') as neighborhood
  ),
  views as (
    select
      business_id,
      count(*) filter (
        where created_at >= now() - interval '7 days'
      ) as views_7d
    from public.analytics_events
    where event_name = 'menu_view'
    group by business_id
  )
  select
    bws.id,
    bws.name,
    bws.category,
    bws.city,
    bws.district,
    bws.address,
    bws.lat,
    bws.lng,
    null::double precision as distance_km,
    coalesce(qs.score, 0)::double precision as quality_score,
    bws.avg_rating,
    null::int as median_price_cents,
    null::boolean as is_open_now,
    null::int as recent_price_verified_count,
    coalesce(v.views_7d, 0)::int as views_count
  from params p
  join public.businesses_with_stats bws
    on bws.city = p.city and bws.district = p.district
  join public.businesses b on b.id = bws.id
  left join public.business_quality_score_v1 qs on qs.business_id = bws.id
  left join views v on v.business_id = bws.id
  where p.city is not null
    and p.district is not null
    and (p.neighborhood is null or b.neighborhood = p.neighborhood)
  order by v.views_7d desc nulls last, coalesce(qs.score, 0) desc nulls last
  limit p_limit;
$$;

grant all on function public.get_district_top_views_v1(text, text, text, int) to anon;
grant all on function public.get_district_top_views_v1(text, text, text, int) to authenticated;
grant all on function public.get_district_top_views_v1(text, text, text, int) to service_role;

create or replace function public.get_district_price_changes_v1(
  p_city text,
  p_district text,
  p_neighborhood text default null,
  p_limit int default 10
)
returns table(
  id uuid,
  name text,
  category text,
  city text,
  district text,
  address text,
  lat double precision,
  lng double precision,
  distance_km double precision,
  quality_score double precision,
  avg_rating double precision,
  median_price_cents int,
  is_open_now boolean,
  recent_price_verified_count int,
  price_changes_count int
)
language sql
stable
security definer
set search_path to 'public'
as $$
  with params as (
    select
      nullif(trim(p_city), '') as city,
      nullif(trim(p_district), '') as district,
      nullif(trim(p_neighborhood), '') as neighborhood
  ),
  changes as (
    select
      mi.business_id,
      count(*) filter (
        where h.created_at >= now() - interval '7 days'
      ) as changes_7d
    from public.menu_item_price_history h
    join public.menu_items mi on mi.id = h.menu_item_id
    group by mi.business_id
  )
  select
    bws.id,
    bws.name,
    bws.category,
    bws.city,
    bws.district,
    bws.address,
    bws.lat,
    bws.lng,
    null::double precision as distance_km,
    coalesce(qs.score, 0)::double precision as quality_score,
    bws.avg_rating,
    null::int as median_price_cents,
    null::boolean as is_open_now,
    null::int as recent_price_verified_count,
    coalesce(c.changes_7d, 0)::int as price_changes_count
  from params p
  join public.businesses_with_stats bws
    on bws.city = p.city and bws.district = p.district
  join public.businesses b on b.id = bws.id
  left join public.business_quality_score_v1 qs on qs.business_id = bws.id
  left join changes c on c.business_id = bws.id
  where p.city is not null
    and p.district is not null
    and (p.neighborhood is null or b.neighborhood = p.neighborhood)
  order by c.changes_7d desc nulls last, coalesce(qs.score, 0) desc nulls last
  limit p_limit;
$$;

grant all on function public.get_district_price_changes_v1(text, text, text, int) to anon;
grant all on function public.get_district_price_changes_v1(text, text, text, int) to authenticated;
grant all on function public.get_district_price_changes_v1(text, text, text, int) to service_role;

create or replace function public.get_district_night_favorites_v1(
  p_city text,
  p_district text,
  p_neighborhood text default null,
  p_limit int default 10
)
returns table(
  id uuid,
  name text,
  category text,
  city text,
  district text,
  address text,
  lat double precision,
  lng double precision,
  distance_km double precision,
  quality_score double precision,
  avg_rating double precision,
  median_price_cents int,
  is_open_now boolean,
  recent_price_verified_count int,
  favorites_count int
)
language sql
stable
security definer
set search_path to 'public'
as $$
  with params as (
    select
      nullif(trim(p_city), '') as city,
      nullif(trim(p_district), '') as district,
      nullif(trim(p_neighborhood), '') as neighborhood
  ),
  favorites as (
    select business_id, count(*) as favorites_count
    from public.business_follows
    group by business_id
  ),
  night_open as (
    select bh.business_id
    from public.business_hours bh
    where (
      bh.mon_open is not null and bh.mon_close is not null and
      (bh.mon_close >= time '23:00' or bh.mon_close < bh.mon_open)
    ) or (
      bh.tue_open is not null and bh.tue_close is not null and
      (bh.tue_close >= time '23:00' or bh.tue_close < bh.tue_open)
    ) or (
      bh.wed_open is not null and bh.wed_close is not null and
      (bh.wed_close >= time '23:00' or bh.wed_close < bh.wed_open)
    ) or (
      bh.thu_open is not null and bh.thu_close is not null and
      (bh.thu_close >= time '23:00' or bh.thu_close < bh.thu_open)
    ) or (
      bh.fri_open is not null and bh.fri_close is not null and
      (bh.fri_close >= time '23:00' or bh.fri_close < bh.fri_open)
    ) or (
      bh.sat_open is not null and bh.sat_close is not null and
      (bh.sat_close >= time '23:00' or bh.sat_close < bh.sat_open)
    ) or (
      bh.sun_open is not null and bh.sun_close is not null and
      (bh.sun_close >= time '23:00' or bh.sun_close < bh.sun_open)
    )
  )
  select
    bws.id,
    bws.name,
    bws.category,
    bws.city,
    bws.district,
    bws.address,
    bws.lat,
    bws.lng,
    null::double precision as distance_km,
    coalesce(qs.score, 0)::double precision as quality_score,
    bws.avg_rating,
    null::int as median_price_cents,
    null::boolean as is_open_now,
    null::int as recent_price_verified_count,
    coalesce(f.favorites_count, 0)::int as favorites_count
  from params p
  join public.businesses_with_stats bws
    on bws.city = p.city and bws.district = p.district
  join public.businesses b on b.id = bws.id
  left join public.business_quality_score_v1 qs on qs.business_id = bws.id
  join night_open n on n.business_id = bws.id
  left join favorites f on f.business_id = bws.id
  where p.city is not null
    and p.district is not null
    and (p.neighborhood is null or b.neighborhood = p.neighborhood)
  order by f.favorites_count desc nulls last, coalesce(qs.score, 0) desc nulls last
  limit p_limit;
$$;

grant all on function public.get_district_night_favorites_v1(text, text, text, int) to anon;
grant all on function public.get_district_night_favorites_v1(text, text, text, int) to authenticated;
grant all on function public.get_district_night_favorites_v1(text, text, text, int) to service_role;


-- ===== END MIGRATION: 20260321000004_micro_trends_fix.sql =====

-- ===== BEGIN MIGRATION: 20260321000005_price_alert_smart_events.sql =====
-- Extend price alert events with previous price + district average context.

alter table public.alert_events
  add column if not exists previous_price_cents int,
  add column if not exists district_avg_price_cents int;

create or replace function public.check_price_alerts_for_item_v1(
  p_menu_item_id uuid,
  p_business_id uuid,
  p_item_name text,
  p_price_cents int,
  p_city text,
  p_district text,
  p_category text,
  p_previous_price_cents int default null,
  p_district_avg_price_cents int default null
)
returns void
language plpgsql
security definer
set search_path to 'public'
as $$
begin
  insert into public.alert_events (
    user_id,
    alert_id,
    business_id,
    menu_item_id,
    matched_price_cents,
    previous_price_cents,
    district_avg_price_cents
  )
  select
    a.user_id,
    a.id,
    p_business_id,
    p_menu_item_id,
    p_price_cents,
    p_previous_price_cents,
    p_district_avg_price_cents
  from public.price_alerts a
  where a.is_active = true
    and (a.query is null or a.query = '' or p_item_name ilike '%' || a.query || '%')
    and (a.max_price_cents is null or p_price_cents <= a.max_price_cents)
    and (a.city is null or a.city = '' or a.city = p_city)
    and (a.district is null or a.district = '' or a.district = p_district)
    and (a.category is null or a.category = '' or a.category = p_category)
  on conflict do nothing;
end;
$$;

create or replace function public.handle_price_alerts_for_history_v1()
returns trigger
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  v_item_name text;
  v_business_id uuid;
  v_city text;
  v_district text;
  v_category text;
  v_price int;
  v_prev_price int;
  v_district_avg int;
begin
  if coalesce(new.source, '') not in ('suggestion', 'owner', 'admin', 'verified') then
    return new;
  end if;

  select mi.name, mi.business_id, b.city, b.district, b.category
    into v_item_name, v_business_id, v_city, v_district, v_category
  from public.menu_items mi
  join public.businesses b on b.id = mi.business_id
  where mi.id = new.menu_item_id;

  v_price := coalesce(new.new_price_cents, new.price_cents);
  if v_item_name is null or v_business_id is null or v_price is null then
    return new;
  end if;

  select h.price_cents
    into v_prev_price
  from public.menu_item_price_history h
  where h.menu_item_id = new.menu_item_id
    and h.created_at < new.created_at
  order by h.created_at desc
  limit 1;

  if coalesce(v_district, '') <> '' then
    select avg(h.price_cents)::int
      into v_district_avg
    from public.menu_item_price_history h
    join public.menu_items mi on mi.id = h.menu_item_id
    join public.businesses b on b.id = mi.business_id
    where lower(mi.name) = lower(v_item_name)
      and b.district = v_district
      and h.created_at >= now() - interval '30 days'
      and h.price_cents is not null;
  end if;

  perform public.check_price_alerts_for_item_v1(
    new.menu_item_id,
    v_business_id,
    v_item_name,
    v_price,
    v_city,
    v_district,
    v_category,
    v_prev_price,
    v_district_avg
  );

  return new;
end;
$$;

drop function if exists public.list_my_alert_events_v1(int, int);

create function public.list_my_alert_events_v1(
  p_limit int default 20,
  p_offset int default 0
)
returns table(
  id uuid,
  alert_id uuid,
  business_id uuid,
  menu_item_id uuid,
  matched_price_cents int,
  previous_price_cents int,
  district_avg_price_cents int,
  created_at timestamptz
)
language sql
security definer
set search_path to 'public'
as $$
  select
    e.id,
    e.alert_id,
    e.business_id,
    e.menu_item_id,
    e.matched_price_cents,
    e.previous_price_cents,
    e.district_avg_price_cents,
    e.created_at
  from public.alert_events e
  where e.user_id = auth.uid()
  order by e.created_at desc
  limit p_limit offset p_offset;
$$;

-- ===== END MIGRATION: 20260321000005_price_alert_smart_events.sql =====

-- ===== BEGIN MIGRATION: 20260321000006_user_reputation_score.sql =====
-- Community reputation score (behavior-based, no direct user voting).

create or replace function public.get_my_reputation_score_v1()
returns int
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  v_user uuid := auth.uid();
  v_score int := 50;
  v_approved int := 0;
  v_rejected int := 0;
begin
  if v_user is null then
    return 0;
  end if;

  if to_regclass('public.menu_item_price_suggestions') is not null then
    execute
      'select count(*) from public.menu_item_price_suggestions
       where created_by = $1 and status = any($2)'
      into v_approved using v_user, array['approved','accepted','handled','verified'];
    execute
      'select count(*) from public.menu_item_price_suggestions
       where created_by = $1 and status = any($2)'
      into v_rejected using v_user, array['rejected'];
    v_score := v_score + (v_approved * 3) - (v_rejected * 5);
  end if;

  if to_regclass('public.menu_item_suggestions') is not null then
    execute
      'select count(*) from public.menu_item_suggestions
       where created_by = $1 and status = any($2)'
      into v_approved using v_user, array['approved','accepted'];
    execute
      'select count(*) from public.menu_item_suggestions
       where created_by = $1 and status = any($2)'
      into v_rejected using v_user, array['rejected'];
    v_score := v_score + (v_approved * 2) - (v_rejected * 4);
  end if;

  if to_regclass('public.business_suggestions') is not null then
    execute
      'select count(*) from public.business_suggestions
       where user_id = $1 and status = any($2)'
      into v_approved using v_user, array['approved','accepted'];
    execute
      'select count(*) from public.business_suggestions
       where user_id = $1 and status = any($2)'
      into v_rejected using v_user, array['rejected'];
    v_score := v_score + (v_approved * 4) - (v_rejected * 6);
  end if;

  if to_regclass('public.reviews') is not null then
    execute
      'select count(*) from public.reviews
       where user_id = $1 and status = any($2)'
      into v_approved using v_user, array['approved','published'];
    execute
      'select count(*) from public.reviews
       where user_id = $1 and status = any($2)'
      into v_rejected using v_user, array['rejected'];
    v_score := v_score + (v_approved * 1) - (v_rejected * 3);
  end if;

  if v_score < 0 then
    v_score := 0;
  end if;
  if v_score > 100 then
    v_score := 100;
  end if;

  return v_score;
end;
$$;

-- ===== END MIGRATION: 20260321000006_user_reputation_score.sql =====

-- ===== BEGIN MIGRATION: 20260321000007_collection_social.sql =====
create table if not exists public.collection_social_stats (
  collection_key text primary key,
  followers_count integer not null default 0,
  engagement_count integer not null default 0,
  updated_at timestamptz not null default now()
);

create table if not exists public.user_collection_follows (
  user_id uuid not null references auth.users(id) on delete cascade,
  collection_key text not null,
  created_at timestamptz not null default now(),
  primary key (user_id, collection_key)
);

alter table public.collection_social_stats enable row level security;
alter table public.user_collection_follows enable row level security;

drop policy if exists "collection_social_stats_read"
on public.collection_social_stats;

create policy "collection_social_stats_read"
on public.collection_social_stats
for select
using (true);

drop policy if exists "user_collection_follows_select_own"
on public.user_collection_follows;

create policy "user_collection_follows_select_own"
on public.user_collection_follows
for select
using (auth.uid() = user_id);

drop policy if exists "user_collection_follows_insert_own"
on public.user_collection_follows;

create policy "user_collection_follows_insert_own"
on public.user_collection_follows
for insert
with check (auth.uid() = user_id);

drop policy if exists "user_collection_follows_delete_own"
on public.user_collection_follows;

create policy "user_collection_follows_delete_own"
on public.user_collection_follows
for delete
using (auth.uid() = user_id);

create or replace function public.get_collection_social_batch_v1(
  p_keys text[]
)
returns table (
  collection_key text,
  followers_count integer,
  engagement_count integer,
  is_following boolean
)
language sql
security definer
as $$
  select
    k.key as collection_key,
    coalesce(s.followers_count, 0) as followers_count,
    coalesce(s.engagement_count, 0) as engagement_count,
    (f.user_id is not null) as is_following
  from unnest(p_keys) as k(key)
  left join public.collection_social_stats s
    on s.collection_key = k.key
  left join public.user_collection_follows f
    on f.collection_key = k.key
   and f.user_id = auth.uid();
$$;

create or replace function public.toggle_collection_follow_v1(
  p_collection_key text
)
returns table (
  is_following boolean,
  followers_count integer
)
language plpgsql
security definer
as $$
declare
  v_exists boolean;
begin
  select exists(
    select 1
    from public.user_collection_follows
    where user_id = auth.uid()
      and collection_key = p_collection_key
  ) into v_exists;

  if v_exists then
    delete from public.user_collection_follows
    where user_id = auth.uid()
      and collection_key = p_collection_key;

    insert into public.collection_social_stats(collection_key)
    values (p_collection_key)
    on conflict (collection_key) do nothing;

    update public.collection_social_stats
      set followers_count = greatest(followers_count - 1, 0),
          updated_at = now()
    where collection_key = p_collection_key;

    return query
      select false, followers_count
      from public.collection_social_stats
      where collection_key = p_collection_key;
  else
    insert into public.user_collection_follows(user_id, collection_key)
    values (auth.uid(), p_collection_key)
    on conflict do nothing;

    insert into public.collection_social_stats(collection_key)
    values (p_collection_key)
    on conflict (collection_key) do nothing;

    update public.collection_social_stats
      set followers_count = followers_count + 1,
          updated_at = now()
    where collection_key = p_collection_key;

    return query
      select true, followers_count
      from public.collection_social_stats
      where collection_key = p_collection_key;
  end if;
end;
$$;

create or replace function public.bump_collection_engagement_v1(
  p_collection_key text,
  p_delta integer default 1
)
returns table (
  engagement_count integer
)
language plpgsql
security definer
as $$
begin
  insert into public.collection_social_stats(collection_key)
  values (p_collection_key)
  on conflict (collection_key) do nothing;

  update public.collection_social_stats
    set engagement_count = greatest(engagement_count + p_delta, 0),
        updated_at = now()
  where collection_key = p_collection_key;

  return query
    select engagement_count
    from public.collection_social_stats
    where collection_key = p_collection_key;
end;
$$;

-- ===== END MIGRATION: 20260321000007_collection_social.sql =====

-- ===== BEGIN MIGRATION: 20260321000008_collection_shares.sql =====
create extension if not exists pgcrypto;

create table if not exists public.collection_shares (
  slug text primary key,
  collection_key text not null,
  name text not null,
  business_ids text[] not null,
  created_by uuid references auth.users(id) on delete cascade,
  created_at timestamptz not null default now()
);

create unique index if not exists collection_shares_unique_key
  on public.collection_shares (collection_key, created_by);

alter table public.collection_shares enable row level security;

create policy "collection_shares_read"
on public.collection_shares
for select
using (true);

create policy "collection_shares_insert_own"
on public.collection_shares
for insert
with check (auth.uid() = created_by);

create or replace function public.upsert_collection_share_v1(
  p_collection_key text,
  p_name text,
  p_business_ids text[]
)
returns table (slug text)
language plpgsql
security definer
as $$
declare
  v_slug text;
begin
  select cs.slug
    into v_slug
  from public.collection_shares cs
  where cs.collection_key = p_collection_key
    and cs.created_by = auth.uid()
  limit 1;

  if v_slug is not null then
    return query select v_slug;
  end if;

  v_slug := substr(encode(gen_random_uuid(), 'hex'), 1, 10);

  insert into public.collection_shares(
    slug,
    collection_key,
    name,
    business_ids,
    created_by
  ) values (
    v_slug,
    p_collection_key,
    p_name,
    p_business_ids,
    auth.uid()
  );

  return query select v_slug;
end;
$$;

create or replace function public.get_collection_share_by_slug_v1(
  p_slug text
)
returns table (
  slug text,
  collection_key text,
  name text,
  business_ids text[]
)
language sql
security definer
as $$
  select
    cs.slug,
    cs.collection_key,
    cs.name,
    cs.business_ids
  from public.collection_shares cs
  where cs.slug = p_slug
  limit 1;
$$;

-- ===== END MIGRATION: 20260321000008_collection_shares.sql =====

-- ===== BEGIN MIGRATION: 20260321000009_b2b_exports.sql =====
create or replace function public.admin_export_anonymous_trends_csv_v1(
  p_days int default 30
)
returns text
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  v_csv text;
begin
  if not public.is_admin() then
    raise exception 'not authorized';
  end if;

  with rows as (
    select
      to_char(date_trunc('day', e.created_at), 'YYYY-MM-DD') as day,
      coalesce(b.city, '-') as city,
      coalesce(b.district, '-') as district,
      e.event_name,
      count(*)::int as event_count
    from public.analytics_events e
    left join public.businesses b on b.id = e.business_id
    where e.created_at >= now() - make_interval(days => greatest(p_days, 1))
    group by 1, 2, 3, 4
    order by 1 desc, 2, 3, 4
  )
  select
    'day,city,district,event_name,event_count' || E'\n' ||
    coalesce(
      string_agg(
        format(
          '%s,%s,%s,%s,%s',
          r.day,
          replace(r.city, ',', ' '),
          replace(r.district, ',', ' '),
          replace(r.event_name, ',', ' '),
          r.event_count::text
        ),
        E'\n'
      ),
      ''
    )
  into v_csv
  from rows r;

  return v_csv;
end;
$$;

create or replace function public.admin_export_regional_price_index_csv_v1(
  p_days int default 30
)
returns text
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  v_csv text;
begin
  if not public.is_admin() then
    raise exception 'not authorized';
  end if;

  with current_window as (
    select
      b.city,
      b.district,
      avg(mi.price_cents)::numeric as avg_price_cents,
      percentile_cont(0.5) within group (order by mi.price_cents)::numeric as median_price_cents,
      count(*)::int as item_count
    from public.menu_items mi
    join public.businesses b on b.id = mi.business_id
    where mi.price_cents is not null
      and mi.price_cents > 0
      and mi.updated_at >= now() - make_interval(days => greatest(p_days, 1))
    group by b.city, b.district
  ),
  previous_window as (
    select
      b.city,
      b.district,
      avg(mi.price_cents)::numeric as prev_avg_price_cents
    from public.menu_items mi
    join public.businesses b on b.id = mi.business_id
    where mi.price_cents is not null
      and mi.price_cents > 0
      and mi.updated_at >= now() - make_interval(days => greatest(p_days * 2, 2))
      and mi.updated_at < now() - make_interval(days => greatest(p_days, 1))
    group by b.city, b.district
  ),
  rows as (
    select
      coalesce(c.city, '-') as city,
      coalesce(c.district, '-') as district,
      round(c.avg_price_cents)::int as avg_price_cents,
      round(c.median_price_cents)::int as median_price_cents,
      c.item_count,
      case
        when p.prev_avg_price_cents is null or p.prev_avg_price_cents = 0 then null
        else round(((c.avg_price_cents - p.prev_avg_price_cents) / p.prev_avg_price_cents) * 100.0, 2)
      end as change_pct
    from current_window c
    left join previous_window p
      on p.city = c.city and p.district = c.district
    order by c.avg_price_cents desc nulls last
  )
  select
    'city,district,avg_price_cents,median_price_cents,item_count,change_pct' || E'\n' ||
    coalesce(
      string_agg(
        format(
          '%s,%s,%s,%s,%s,%s',
          replace(r.city, ',', ' '),
          replace(r.district, ',', ' '),
          r.avg_price_cents::text,
          r.median_price_cents::text,
          r.item_count::text,
          coalesce(r.change_pct::text, '')
        ),
        E'\n'
      ),
      ''
    )
  into v_csv
  from rows r;

  return v_csv;
end;
$$;

create or replace function public.admin_export_menu_inflation_csv_v1(
  p_days int default 30
)
returns text
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  v_csv text;
begin
  if not public.is_admin() then
    raise exception 'not authorized';
  end if;

  with hist as (
    select
      h.menu_item_id,
      mi.name as menu_item_name,
      b.city,
      b.district,
      h.price_cents,
      h.created_at,
      row_number() over (
        partition by h.menu_item_id
        order by h.created_at asc
      ) as rn_first,
      row_number() over (
        partition by h.menu_item_id
        order by h.created_at desc
      ) as rn_last
    from public.menu_item_price_history h
    join public.menu_items mi on mi.id = h.menu_item_id
    join public.businesses b on b.id = mi.business_id
    where h.price_cents is not null
      and h.price_cents > 0
      and h.created_at >= now() - make_interval(days => greatest(p_days, 1))
  ),
  first_last as (
    select
      h1.menu_item_id,
      h1.menu_item_name,
      h1.city,
      h1.district,
      max(case when h1.rn_first = 1 then h1.price_cents end) as first_price_cents,
      max(case when h1.rn_last = 1 then h1.price_cents end) as last_price_cents
    from hist h1
    group by h1.menu_item_id, h1.menu_item_name, h1.city, h1.district
  ),
  rows as (
    select
      coalesce(fl.city, '-') as city,
      coalesce(fl.district, '-') as district,
      replace(fl.menu_item_name, ',', ' ') as menu_item_name,
      fl.first_price_cents::int as first_price_cents,
      fl.last_price_cents::int as last_price_cents,
      case
        when fl.first_price_cents is null or fl.first_price_cents = 0 then null
        else round(((fl.last_price_cents - fl.first_price_cents)::numeric / fl.first_price_cents::numeric) * 100.0, 2)
      end as inflation_pct
    from first_last fl
    where fl.first_price_cents is not null
      and fl.last_price_cents is not null
    order by inflation_pct desc nulls last
    limit 5000
  )
  select
    'city,district,menu_item_name,first_price_cents,last_price_cents,inflation_pct' || E'\n' ||
    coalesce(
      string_agg(
        format(
          '%s,%s,%s,%s,%s,%s',
          r.city,
          r.district,
          r.menu_item_name,
          r.first_price_cents::text,
          r.last_price_cents::text,
          coalesce(r.inflation_pct::text, '')
        ),
        E'\n'
      ),
      ''
    )
  into v_csv
  from rows r;

  return v_csv;
end;
$$;

-- ===== END MIGRATION: 20260321000009_b2b_exports.sql =====

-- ===== BEGIN MIGRATION: 20260321000010_incident_response_center.sql =====
create table if not exists public.incident_updates (
  id uuid primary key default gen_random_uuid(),
  incident_key text not null,
  title text not null,
  summary text not null,
  action_taken text not null,
  status text not null default 'open' check (status in ('open', 'mitigated', 'resolved')),
  visibility text not null default 'public' check (visibility in ('public', 'internal')),
  created_by uuid null references auth.users(id) on delete set null,
  created_at timestamptz not null default now()
);

create index if not exists incident_updates_incident_key_created_at_idx
  on public.incident_updates (incident_key, created_at desc);

create index if not exists incident_updates_visibility_created_at_idx
  on public.incident_updates (visibility, created_at desc);

alter table public.incident_updates enable row level security;

drop policy if exists "incident_updates_public_read" on public.incident_updates;
create policy "incident_updates_public_read"
on public.incident_updates
for select
using (visibility = 'public');

drop policy if exists "incident_updates_admin_insert" on public.incident_updates;
create policy "incident_updates_admin_insert"
on public.incident_updates
for insert
with check (public.is_admin());

drop policy if exists "incident_updates_admin_update" on public.incident_updates;
create policy "incident_updates_admin_update"
on public.incident_updates
for update
using (public.is_admin())
with check (public.is_admin());

drop policy if exists "incident_updates_admin_delete" on public.incident_updates;
create policy "incident_updates_admin_delete"
on public.incident_updates
for delete
using (public.is_admin());

create or replace function public.admin_list_incident_updates_v1(
  p_limit int default 100
)
returns table(
  id uuid,
  incident_key text,
  title text,
  summary text,
  action_taken text,
  status text,
  visibility text,
  created_by uuid,
  created_at timestamptz
)
language sql
security definer
set search_path to 'public'
as $$
  select
    iu.id,
    iu.incident_key,
    iu.title,
    iu.summary,
    iu.action_taken,
    iu.status,
    iu.visibility,
    iu.created_by,
    iu.created_at
  from public.incident_updates iu
  where public.is_admin()
  order by iu.created_at desc
  limit greatest(p_limit, 1);
$$;

create or replace function public.public_list_incident_updates_v1(
  p_limit int default 100
)
returns table(
  id uuid,
  incident_key text,
  title text,
  summary text,
  action_taken text,
  status text,
  created_at timestamptz
)
language sql
security definer
set search_path to 'public'
as $$
  select
    iu.id,
    iu.incident_key,
    iu.title,
    iu.summary,
    iu.action_taken,
    iu.status,
    iu.created_at
  from public.incident_updates iu
  where iu.visibility = 'public'
  order by iu.created_at desc
  limit greatest(p_limit, 1);
$$;

create or replace function public.admin_create_incident_update_v1(
  p_incident_key text,
  p_title text,
  p_summary text,
  p_action_taken text,
  p_status text default 'open',
  p_visibility text default 'public'
)
returns uuid
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  v_id uuid;
begin
  if not public.is_admin() then
    raise exception 'not authorized';
  end if;

  insert into public.incident_updates(
    incident_key,
    title,
    summary,
    action_taken,
    status,
    visibility,
    created_by
  ) values (
    nullif(trim(p_incident_key), ''),
    trim(p_title),
    trim(p_summary),
    trim(p_action_taken),
    coalesce(nullif(trim(p_status), ''), 'open'),
    coalesce(nullif(trim(p_visibility), ''), 'public'),
    auth.uid()
  )
  returning id into v_id;

  return v_id;
end;
$$;

-- ===== END MIGRATION: 20260321000010_incident_response_center.sql =====

-- ===== BEGIN MIGRATION: 20260321000011_push_notifications_and_realtime.sql =====
create table if not exists public.notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  type text not null,
  title text not null,
  body text not null,
  data jsonb not null default '{}'::jsonb,
  is_read boolean not null default false,
  created_at timestamptz not null default now()
);

create table if not exists public.user_devices (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  fcm_token text not null,
  platform text not null,
  app_version text,
  last_seen_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  unique (user_id, fcm_token)
);

create index if not exists notifications_user_created_idx
  on public.notifications(user_id, created_at desc);
create index if not exists notifications_user_unread_idx
  on public.notifications(user_id, is_read, created_at desc);
create index if not exists user_devices_user_last_seen_idx
  on public.user_devices(user_id, last_seen_at desc);

alter table public.notifications enable row level security;
alter table public.user_devices enable row level security;

drop policy if exists notifications_select_own on public.notifications;
create policy notifications_select_own
on public.notifications
for select
to authenticated
using (user_id = auth.uid());

drop policy if exists notifications_update_own on public.notifications;
create policy notifications_update_own
on public.notifications
for update
to authenticated
using (user_id = auth.uid())
with check (user_id = auth.uid());

drop policy if exists user_devices_select_own on public.user_devices;
create policy user_devices_select_own
on public.user_devices
for select
to authenticated
using (user_id = auth.uid());

drop policy if exists user_devices_insert_own on public.user_devices;
create policy user_devices_insert_own
on public.user_devices
for insert
to authenticated
with check (user_id = auth.uid());

drop policy if exists user_devices_update_own on public.user_devices;
create policy user_devices_update_own
on public.user_devices
for update
to authenticated
using (user_id = auth.uid())
with check (user_id = auth.uid());

create or replace function public.notify_user_v1(
  p_user_id uuid,
  p_type text,
  p_title text,
  p_body text,
  p_data jsonb default '{}'::jsonb
)
returns uuid
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  v_id uuid;
begin
  if p_user_id is null then
    return null;
  end if;

  insert into public.notifications(user_id, type, title, body, data)
  values (
    p_user_id,
    coalesce(nullif(trim(p_type), ''), 'system'),
    coalesce(nullif(trim(p_title), ''), 'Bildirim'),
    coalesce(nullif(trim(p_body), ''), ''),
    coalesce(p_data, '{}'::jsonb)
  )
  returning id into v_id;

  return v_id;
end;
$$;

create or replace function public.register_user_device_v1(
  p_fcm_token text,
  p_platform text,
  p_app_version text default null
)
returns uuid
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  v_user_id uuid := auth.uid();
  v_id uuid;
begin
  if v_user_id is null then
    raise exception 'not_authenticated';
  end if;
  if coalesce(trim(p_fcm_token), '') = '' then
    raise exception 'invalid_token';
  end if;
  if coalesce(trim(p_platform), '') = '' then
    raise exception 'invalid_platform';
  end if;

  insert into public.user_devices(user_id, fcm_token, platform, app_version, last_seen_at)
  values (v_user_id, trim(p_fcm_token), lower(trim(p_platform)), nullif(trim(coalesce(p_app_version, '')), ''), now())
  on conflict (user_id, fcm_token)
  do update set
    platform = excluded.platform,
    app_version = excluded.app_version,
    last_seen_at = now()
  returning id into v_id;

  return v_id;
end;
$$;

create or replace function public.mark_notification_read_v1(
  p_notification_id uuid
)
returns boolean
language plpgsql
security definer
set search_path to 'public'
as $$
begin
  if auth.uid() is null then
    raise exception 'not_authenticated';
  end if;

  update public.notifications
  set is_read = true
  where id = p_notification_id
    and user_id = auth.uid();

  return found;
end;
$$;

create or replace function public.mark_all_notifications_read_v1()
returns int
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  v_count int := 0;
begin
  if auth.uid() is null then
    raise exception 'not_authenticated';
  end if;

  update public.notifications
  set is_read = true
  where user_id = auth.uid()
    and is_read = false;

  get diagnostics v_count = row_count;
  return v_count;
end;
$$;

create or replace function public.trg_notify_price_suggestion_result_v1()
returns trigger
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  v_business_name text;
  v_status text;
begin
  if tg_op <> 'UPDATE' then
    return new;
  end if;

  if coalesce(old.status, '') = coalesce(new.status, '') then
    return new;
  end if;

  if coalesce(new.status, '') not in ('approved', 'rejected') then
    return new;
  end if;

  select b.name into v_business_name
  from public.businesses b
  where b.id = new.business_id;

  v_status := case when new.status = 'approved' then 'onaylandi' else 'reddedildi' end;

  perform public.notify_user_v1(
    new.created_by,
    'price_verification_result',
    case when new.status = 'approved' then 'Fiyat dogrulama onaylandi' else 'Fiyat dogrulama reddedildi' end,
    coalesce(v_business_name, 'Isletme') || ' icin fiyat dogrulaman ' || v_status || '.',
    jsonb_build_object(
      'business_id', new.business_id,
      'menu_item_id', new.menu_item_id,
      'suggestion_id', new.id,
      'status', new.status
    )
  );

  return new;
end;
$$;

drop trigger if exists trg_notify_price_suggestion_result_v1
on public.menu_item_price_suggestions;
create trigger trg_notify_price_suggestion_result_v1
after update on public.menu_item_price_suggestions
for each row
execute function public.trg_notify_price_suggestion_result_v1();

create or replace function public.trg_notify_owner_new_price_suggestion_v1()
returns trigger
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  v_owner_id uuid;
  v_business_name text;
begin
  if tg_op <> 'INSERT' then
    return new;
  end if;

  select b.name into v_business_name
  from public.businesses b
  where b.id = new.business_id;

  for v_owner_id in
    select distinct oc.user_id
    from public.owner_claims oc
    where oc.business_id = new.business_id
      and oc.status = 'approved'
      and oc.user_id is not null
      and oc.user_id <> new.created_by
  loop
    perform public.notify_user_v1(
      v_owner_id,
      'owner_new_price_suggestion',
      'Yeni fiyat onerisi geldi',
      coalesce(v_business_name, 'Isletme') || ' icin yeni bir fiyat onerisi var.',
      jsonb_build_object(
        'business_id', new.business_id,
        'menu_item_id', new.menu_item_id,
        'suggestion_id', new.id
      )
    );
  end loop;

  return new;
end;
$$;

drop trigger if exists trg_notify_owner_new_price_suggestion_v1
on public.menu_item_price_suggestions;
create trigger trg_notify_owner_new_price_suggestion_v1
after insert on public.menu_item_price_suggestions
for each row
execute function public.trg_notify_owner_new_price_suggestion_v1();

create or replace function public.trg_notify_owner_new_review_v1()
returns trigger
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  v_owner_id uuid;
  v_business_name text;
begin
  if tg_op <> 'INSERT' then
    return new;
  end if;

  select b.name into v_business_name
  from public.businesses b
  where b.id = new.business_id;

  for v_owner_id in
    select distinct oc.user_id
    from public.owner_claims oc
    where oc.business_id = new.business_id
      and oc.status = 'approved'
      and oc.user_id is not null
      and oc.user_id <> new.user_id
  loop
    perform public.notify_user_v1(
      v_owner_id,
      'owner_new_review',
      'Yeni yorum geldi',
      coalesce(v_business_name, 'Isletme') || ' icin yeni yorum aldin.',
      jsonb_build_object(
        'business_id', new.business_id,
        'review_id', new.id
      )
    );
  end loop;

  return new;
end;
$$;

drop trigger if exists trg_notify_owner_new_review_v1
on public.reviews;
create trigger trg_notify_owner_new_review_v1
after insert on public.reviews
for each row
execute function public.trg_notify_owner_new_review_v1();

create or replace function public.trg_notify_owner_reported_v1()
returns trigger
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  v_owner_id uuid;
  v_business_name text;
begin
  if tg_op <> 'INSERT' then
    return new;
  end if;

  if new.business_id is null then
    return new;
  end if;

  select b.name into v_business_name
  from public.businesses b
  where b.id = new.business_id;

  for v_owner_id in
    select distinct oc.user_id
    from public.owner_claims oc
    where oc.business_id = new.business_id
      and oc.status = 'approved'
      and oc.user_id is not null
      and oc.user_id <> new.user_id
  loop
    perform public.notify_user_v1(
      v_owner_id,
      'owner_business_reported',
      'Isletmen raporlandi',
      coalesce(v_business_name, 'Isletme') || ' icin yeni bir rapor acildi.',
      jsonb_build_object(
        'business_id', new.business_id,
        'report_id', new.id,
        'reason', new.reason
      )
    );
  end loop;

  return new;
end;
$$;

drop trigger if exists trg_notify_owner_reported_v1
on public.reports;
create trigger trg_notify_owner_reported_v1
after insert on public.reports
for each row
execute function public.trg_notify_owner_reported_v1();

create or replace function public.trg_notify_review_reply_v1()
returns trigger
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  v_business_name text;
begin
  if tg_op <> 'INSERT' then
    return new;
  end if;

  select b.name into v_business_name
  from public.businesses b
  where b.id = new.business_id;

  perform public.notify_user_v1(
    new.review_author_id,
    'review_reply',
    'Yorumuna cevap geldi',
    coalesce(v_business_name, 'Isletme') || ' yorumuna cevap verdi.',
    jsonb_build_object(
      'business_id', new.business_id,
      'review_id', new.review_id,
      'reply_id', new.id
    )
  );

  return new;
end;
$$;

do $$
begin
  if to_regclass('public.review_replies') is not null then
    execute 'drop trigger if exists trg_notify_review_reply_v1 on public.review_replies';
    execute 'create trigger trg_notify_review_reply_v1
      after insert on public.review_replies
      for each row
      execute function public.trg_notify_review_reply_v1()';
  end if;
end;
$$;

create or replace function public.trg_notify_price_alert_event_v1()
returns trigger
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  v_business_name text;
  v_item_name text;
begin
  if tg_op <> 'INSERT' then
    return new;
  end if;

  select b.name into v_business_name
  from public.businesses b
  where b.id = new.business_id;

  select mi.name into v_item_name
  from public.menu_items mi
  where mi.id = new.menu_item_id;

  perform public.notify_user_v1(
    new.user_id,
    'favorite_price_changed',
    'Favori urunun fiyati degisti',
    coalesce(v_business_name, 'Isletme') || ' / ' || coalesce(v_item_name, 'Urun') || ' icin yeni fiyat var.',
    jsonb_build_object(
      'business_id', new.business_id,
      'menu_item_id', new.menu_item_id,
      'alert_event_id', new.id,
      'matched_price_cents', new.matched_price_cents,
      'previous_price_cents', new.previous_price_cents,
      'district_avg_price_cents', new.district_avg_price_cents
    )
  );

  return new;
end;
$$;

do $$
begin
  if to_regclass('public.alert_events') is not null then
    execute 'drop trigger if exists trg_notify_price_alert_event_v1 on public.alert_events';
    execute 'create trigger trg_notify_price_alert_event_v1
      after insert on public.alert_events
      for each row
      execute function public.trg_notify_price_alert_event_v1()';
  end if;
end;
$$;

grant execute on function public.register_user_device_v1(text, text, text) to authenticated;
grant execute on function public.mark_notification_read_v1(uuid) to authenticated;
grant execute on function public.mark_all_notifications_read_v1() to authenticated;

-- ===== END MIGRATION: 20260321000011_push_notifications_and_realtime.sql =====

-- ===== BEGIN MIGRATION: 20260321000012_notification_dispatch_queue.sql =====
create table if not exists public.notification_dispatch_jobs (
  id uuid primary key default gen_random_uuid(),
  notification_id uuid not null references public.notifications(id) on delete cascade,
  status text not null default 'pending',
  attempts int not null default 0,
  last_error text,
  locked_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (notification_id)
);

create index if not exists notification_dispatch_jobs_status_idx
  on public.notification_dispatch_jobs(status, created_at asc);

create or replace function public.touch_updated_at_v1()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists trg_notification_dispatch_jobs_touch_v1
on public.notification_dispatch_jobs;
create trigger trg_notification_dispatch_jobs_touch_v1
before update on public.notification_dispatch_jobs
for each row
execute function public.touch_updated_at_v1();

create or replace function public.enqueue_notification_dispatch_v1()
returns trigger
language plpgsql
security definer
set search_path to 'public'
as $$
begin
  insert into public.notification_dispatch_jobs(notification_id, status)
  values (new.id, 'pending')
  on conflict (notification_id) do nothing;
  return new;
end;
$$;

drop trigger if exists trg_enqueue_notification_dispatch_v1
on public.notifications;
create trigger trg_enqueue_notification_dispatch_v1
after insert on public.notifications
for each row
execute function public.enqueue_notification_dispatch_v1();

create or replace function public.dequeue_notification_dispatch_jobs_v1(
  p_limit int default 20
)
returns table(
  job_id uuid,
  notification_id uuid,
  user_id uuid,
  type text,
  title text,
  body text,
  data jsonb
)
language plpgsql
security definer
set search_path to 'public'
as $$
begin
  if p_limit <= 0 then
    p_limit := 20;
  end if;

  return query
  with picked as (
    select j.id
    from public.notification_dispatch_jobs j
    where j.status in ('pending', 'retry')
      and coalesce(j.attempts, 0) < 8
      and (j.locked_at is null or j.locked_at < now() - interval '5 minutes')
    order by j.created_at asc
    limit p_limit
    for update skip locked
  ),
  locked as (
    update public.notification_dispatch_jobs j
    set
      status = 'processing',
      locked_at = now(),
      attempts = coalesce(j.attempts, 0) + 1
    where j.id in (select id from picked)
    returning j.id, j.notification_id
  )
  select
    l.id as job_id,
    n.id as notification_id,
    n.user_id,
    n.type,
    n.title,
    n.body,
    n.data
  from locked l
  join public.notifications n on n.id = l.notification_id;
end;
$$;

create or replace function public.complete_notification_dispatch_job_v1(
  p_job_id uuid,
  p_success boolean,
  p_error text default null
)
returns boolean
language plpgsql
security definer
set search_path to 'public'
as $$
begin
  update public.notification_dispatch_jobs
  set
    status = case when p_success then 'sent' else 'retry' end,
    locked_at = null,
    last_error = case when p_success then null else left(coalesce(p_error, 'dispatch_failed'), 800) end
  where id = p_job_id;

  return found;
end;
$$;

-- ===== END MIGRATION: 20260321000012_notification_dispatch_queue.sql =====

-- ===== BEGIN MIGRATION: 20260321000013_achievements_v2.sql =====
create table if not exists public.achievements (
  id text primary key,
  title text not null,
  description text not null,
  icon text not null default 'trophy',
  color text not null default '#9CA3AF',
  condition jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create table if not exists public.user_achievements (
  user_id uuid not null references auth.users(id) on delete cascade,
  achievement_id text not null references public.achievements(id) on delete cascade,
  unlocked_at timestamptz not null default now(),
  meta jsonb not null default '{}'::jsonb,
  primary key (user_id, achievement_id)
);

create index if not exists user_achievements_user_idx
  on public.user_achievements(user_id, unlocked_at desc);

alter table public.achievements enable row level security;
alter table public.user_achievements enable row level security;

drop policy if exists achievements_public_read on public.achievements;
create policy achievements_public_read
on public.achievements
for select
to authenticated
using (true);

drop policy if exists user_achievements_read_own on public.user_achievements;
create policy user_achievements_read_own
on public.user_achievements
for select
to authenticated
using (user_id = auth.uid());

insert into public.achievements(id, title, description, icon, color, condition)
values
  ('first_review', 'Ilk Yorum', 'Ilk yorumunu yaz', 'comment', '#4CAF50', '{"type":"review_count","value":1}'),
  ('first_rating', 'Ilk Puan', 'Ilk mekan puanini ver', 'star', '#3B82F6', '{"type":"rating_count","value":1}'),
  ('first_discovery', 'Ilk Kesif', 'Ilk isletme goruntulemesini yap', 'place', '#F59E0B', '{"type":"business_view_count","value":1}'),
  ('traveler_10', 'Gezgin', '10 farkli mekani puanla', 'travel', '#06B6D4', '{"type":"unique_rated_business_count","value":10}'),
  ('price_hunter_5', 'Fiyat Avcisi', '5 fiyat dogrulama katkisi yap', 'price', '#10B981', '{"type":"price_verified_count","value":5}'),
  ('observer_3', 'Gozlemci', '3 menu fotografi ekle', 'photo', '#A855F7', '{"type":"menu_photo_count","value":3}'),
  ('district_gourmet_top10', 'Ilce Gurmesi', 'Ilcede ilk %10 katkiciya gir', 'crown', '#7C3AED', '{"type":"district_top_percent","value":10}'),
  ('detective_10', 'Dedektif', '10 yanlis bilgi bildirimi yap', 'detective', '#EF4444', '{"type":"wrong_info_reports_count","value":10}'),
  ('trusted_contributor', 'Guvenilir Katkici', 'Guven skoru 80 ve ustu', 'shield', '#059669', '{"type":"reputation_score","value":80}')
on conflict (id) do update set
  title = excluded.title,
  description = excluded.description,
  icon = excluded.icon,
  color = excluded.color,
  condition = excluded.condition;

create or replace function public.award_achievement_v1(
  p_user_id uuid,
  p_achievement_id text,
  p_meta jsonb default '{}'::jsonb
)
returns boolean
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  v_inserted boolean := false;
  v_title text;
begin
  if p_user_id is null or coalesce(trim(p_achievement_id), '') = '' then
    return false;
  end if;

  insert into public.user_achievements(user_id, achievement_id, meta)
  values (p_user_id, trim(p_achievement_id), coalesce(p_meta, '{}'::jsonb))
  on conflict do nothing;

  get diagnostics v_inserted = row_count;
  if not v_inserted then
    return false;
  end if;

  select a.title into v_title
  from public.achievements a
  where a.id = trim(p_achievement_id);

  if to_regclass('public.notifications') is not null then
    perform public.notify_user_v1(
      p_user_id,
      'achievement_unlocked',
      'Basari acildi',
      'Tebrikler! "' || coalesce(v_title, trim(p_achievement_id)) || '" basarisini kazandin.',
      jsonb_build_object('achievement_id', trim(p_achievement_id))
    );
  end if;

  return true;
end;
$$;

create or replace function public.get_user_reputation_score_v2(
  p_user_id uuid
)
returns int
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  v_score int := 50;
  v_approved int := 0;
  v_rejected int := 0;
begin
  if p_user_id is null then
    return 0;
  end if;

  if to_regclass('public.menu_item_price_suggestions') is not null then
    execute
      'select count(*) from public.menu_item_price_suggestions
       where created_by = $1 and status = any($2)'
      into v_approved using p_user_id, array['approved','accepted','handled','verified'];
    execute
      'select count(*) from public.menu_item_price_suggestions
       where created_by = $1 and status = any($2)'
      into v_rejected using p_user_id, array['rejected'];
    v_score := v_score + (v_approved * 3) - (v_rejected * 5);
  end if;

  if to_regclass('public.business_suggestions') is not null then
    execute
      'select count(*) from public.business_suggestions
       where user_id = $1 and status = any($2)'
      into v_approved using p_user_id, array['approved','accepted'];
    execute
      'select count(*) from public.business_suggestions
       where user_id = $1 and status = any($2)'
      into v_rejected using p_user_id, array['rejected'];
    v_score := v_score + (v_approved * 4) - (v_rejected * 6);
  end if;

  if to_regclass('public.reviews') is not null then
    execute
      'select count(*) from public.reviews
       where user_id = $1 and status = any($2)'
      into v_approved using p_user_id, array['approved','published'];
    execute
      'select count(*) from public.reviews
       where user_id = $1 and status = any($2)'
      into v_rejected using p_user_id, array['rejected'];
    v_score := v_score + (v_approved * 1) - (v_rejected * 3);
  end if;

  if v_score < 0 then v_score := 0; end if;
  if v_score > 100 then v_score := 100; end if;
  return v_score;
end;
$$;

create or replace function public.recompute_user_achievements_v1(
  p_user_id uuid
)
returns void
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  v_review_count int := 0;
  v_rating_count int := 0;
  v_business_view_count int := 0;
  v_unique_rated_count int := 0;
  v_price_verified_count int := 0;
  v_menu_photo_count int := 0;
  v_wrong_info_reports_count int := 0;
  v_reputation int := 0;
  v_top10 boolean := false;
begin
  if p_user_id is null then
    return;
  end if;

  if to_regclass('public.reviews') is not null then
    execute
      'select count(*) from public.reviews where user_id = $1'
      into v_review_count using p_user_id;
    execute
      'select count(*) from public.reviews where user_id = $1 and rating is not null'
      into v_rating_count using p_user_id;
    execute
      'select count(distinct business_id) from public.reviews where user_id = $1 and rating is not null and business_id is not null'
      into v_unique_rated_count using p_user_id;
  end if;

  if to_regclass('public.analytics_events') is not null then
    execute
      'select count(*) from public.analytics_events
       where user_id = $1 and event_name = any($2)'
      into v_business_view_count using p_user_id, array['discovery_business_click', 'business_view'];
  end if;

  if to_regclass('public.menu_item_price_suggestions') is not null then
    execute
      'select count(*) from public.menu_item_price_suggestions
       where created_by = $1 and status = any($2)'
      into v_price_verified_count using p_user_id, array['approved','accepted','handled','verified'];
  end if;

  if to_regclass('public.menu_item_photos') is not null then
    execute
      'select count(*) from public.menu_item_photos where created_by = $1'
      into v_menu_photo_count using p_user_id;
  end if;

  if to_regclass('public.reports') is not null then
    execute
      'select count(*) from public.reports
       where coalesce(user_id, reporter_user_id) = $1'
      into v_wrong_info_reports_count using p_user_id;
  end if;

  v_reputation := public.get_user_reputation_score_v2(p_user_id);

  if to_regclass('public.reviews') is not null then
    execute $sql$
      with user_counts as (
        select
          b.district,
          r.user_id,
          count(*)::int as c
        from public.reviews r
        join public.businesses b on b.id = r.business_id
        where b.district is not null
        group by b.district, r.user_id
      ),
      ranked as (
        select
          district,
          user_id,
          c,
          rank() over(partition by district order by c desc, user_id) as rnk,
          count(*) over(partition by district) as user_total
        from user_counts
      )
      select exists(
        select 1
        from ranked
        where user_id = $1
          and user_total >= 10
          and rnk <= greatest(1, ceil(user_total::numeric * 0.10)::int)
      )
    $sql$
    into v_top10 using p_user_id;
  end if;

  if v_review_count >= 1 then
    perform public.award_achievement_v1(p_user_id, 'first_review');
  end if;
  if v_rating_count >= 1 then
    perform public.award_achievement_v1(p_user_id, 'first_rating');
  end if;
  if v_business_view_count >= 1 then
    perform public.award_achievement_v1(p_user_id, 'first_discovery');
  end if;
  if v_unique_rated_count >= 10 then
    perform public.award_achievement_v1(p_user_id, 'traveler_10');
  end if;
  if v_price_verified_count >= 5 then
    perform public.award_achievement_v1(p_user_id, 'price_hunter_5');
  end if;
  if v_menu_photo_count >= 3 then
    perform public.award_achievement_v1(p_user_id, 'observer_3');
  end if;
  if v_wrong_info_reports_count >= 10 then
    perform public.award_achievement_v1(p_user_id, 'detective_10');
  end if;
  if v_reputation >= 80 then
    perform public.award_achievement_v1(p_user_id, 'trusted_contributor');
  end if;
  if v_top10 then
    perform public.award_achievement_v1(p_user_id, 'district_gourmet_top10');
  end if;
end;
$$;

create or replace function public.get_my_achievements_v1()
returns table(
  id text,
  title text,
  description text,
  icon text,
  color text,
  condition jsonb,
  unlocked boolean,
  unlocked_at timestamptz
)
language sql
security definer
set search_path to 'public'
as $$
  select
    a.id,
    a.title,
    a.description,
    a.icon,
    a.color,
    a.condition,
    (ua.user_id is not null) as unlocked,
    ua.unlocked_at
  from public.achievements a
  left join public.user_achievements ua
    on ua.achievement_id = a.id
   and ua.user_id = auth.uid()
  order by
    case when ua.user_id is not null then 0 else 1 end,
    coalesce(ua.unlocked_at, 'epoch'::timestamptz) desc,
    a.title asc;
$$;

create or replace function public.trg_recompute_achievements_reviews_v1()
returns trigger
language plpgsql
security definer
set search_path to 'public'
as $$
begin
  perform public.recompute_user_achievements_v1(new.user_id);
  return new;
end;
$$;

drop trigger if exists trg_recompute_achievements_reviews_v1 on public.reviews;
create trigger trg_recompute_achievements_reviews_v1
after insert on public.reviews
for each row
execute function public.trg_recompute_achievements_reviews_v1();

create or replace function public.trg_recompute_achievements_price_suggestions_v1()
returns trigger
language plpgsql
security definer
set search_path to 'public'
as $$
begin
  perform public.recompute_user_achievements_v1(new.created_by);
  return new;
end;
$$;

drop trigger if exists trg_recompute_achievements_price_suggestions_v1 on public.menu_item_price_suggestions;
create trigger trg_recompute_achievements_price_suggestions_v1
after insert or update of status on public.menu_item_price_suggestions
for each row
execute function public.trg_recompute_achievements_price_suggestions_v1();

do $$
begin
  if to_regclass('public.menu_item_photos') is not null then
    execute 'create or replace function public.trg_recompute_achievements_menu_photos_v1()
      returns trigger
      language plpgsql
      security definer
      set search_path to ''public''
      as $fn$
      begin
        perform public.recompute_user_achievements_v1(new.created_by);
        return new;
      end;
      $fn$';
    execute 'drop trigger if exists trg_recompute_achievements_menu_photos_v1 on public.menu_item_photos';
    execute 'create trigger trg_recompute_achievements_menu_photos_v1
      after insert on public.menu_item_photos
      for each row
      execute function public.trg_recompute_achievements_menu_photos_v1()';
  end if;
end;
$$;

do $$
begin
  if to_regclass('public.analytics_events') is not null then
    execute 'create or replace function public.trg_recompute_achievements_analytics_v1()
      returns trigger
      language plpgsql
      security definer
      set search_path to ''public''
      as $fn$
      begin
        if new.user_id is not null then
          perform public.recompute_user_achievements_v1(new.user_id);
        end if;
        return new;
      end;
      $fn$';
    execute 'drop trigger if exists trg_recompute_achievements_analytics_v1 on public.analytics_events';
    execute 'create trigger trg_recompute_achievements_analytics_v1
      after insert on public.analytics_events
      for each row
      execute function public.trg_recompute_achievements_analytics_v1()';
  end if;
end;
$$;

do $$
begin
  if to_regclass('public.reports') is not null then
    execute 'create or replace function public.trg_recompute_achievements_reports_v1()
      returns trigger
      language plpgsql
      security definer
      set search_path to ''public''
      as $fn$
      begin
        perform public.recompute_user_achievements_v1(coalesce(new.user_id, new.reporter_user_id));
        return new;
      end;
      $fn$';
    execute 'drop trigger if exists trg_recompute_achievements_reports_v1 on public.reports';
    execute 'create trigger trg_recompute_achievements_reports_v1
      after insert on public.reports
      for each row
      execute function public.trg_recompute_achievements_reports_v1()';
  end if;
end;
$$;

grant execute on function public.get_my_achievements_v1() to authenticated;

-- ===== END MIGRATION: 20260321000013_achievements_v2.sql =====

-- ===== BEGIN MIGRATION: 20260321000014_achievement_xp_v2.sql =====
alter table public.achievements
  add column if not exists xp int not null default 20;

update public.achievements
set xp = case id
  when 'first_review' then 20
  when 'first_rating' then 20
  when 'first_discovery' then 20
  when 'traveler_10' then 40
  when 'price_hunter_5' then 40
  when 'observer_3' then 40
  when 'district_gourmet_top10' then 80
  when 'detective_10' then 80
  when 'trusted_contributor' then 80
  else xp
end;

create or replace function public.award_achievement_v1(
  p_user_id uuid,
  p_achievement_id text,
  p_meta jsonb default '{}'::jsonb
)
returns boolean
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  v_inserted int := 0;
  v_title text;
  v_xp int := 20;
begin
  if p_user_id is null or coalesce(trim(p_achievement_id), '') = '' then
    return false;
  end if;

  insert into public.user_achievements(user_id, achievement_id, meta)
  values (p_user_id, trim(p_achievement_id), coalesce(p_meta, '{}'::jsonb))
  on conflict do nothing;

  get diagnostics v_inserted = row_count;
  if v_inserted = 0 then
    return false;
  end if;

  select a.title, coalesce(a.xp, 20)
    into v_title, v_xp
  from public.achievements a
  where a.id = trim(p_achievement_id);

  if to_regclass('public.notifications') is not null then
    perform public.notify_user_v1(
      p_user_id,
      'achievement_unlocked',
      'Basari acildi',
      'Tebrikler! "' || coalesce(v_title, trim(p_achievement_id)) || '" basarisini kazandin. +' || v_xp::text || ' XP',
      jsonb_build_object(
        'achievement_id', trim(p_achievement_id),
        'xp', v_xp
      )
    );
  end if;

  return true;
end;
$$;

create or replace function public.get_my_achievements_v2()
returns table(
  id text,
  title text,
  description text,
  icon text,
  color text,
  xp int,
  condition jsonb,
  unlocked boolean,
  unlocked_at timestamptz
)
language sql
security definer
set search_path to 'public'
as $$
  select
    a.id,
    a.title,
    a.description,
    a.icon,
    a.color,
    coalesce(a.xp, 20) as xp,
    a.condition,
    (ua.user_id is not null) as unlocked,
    ua.unlocked_at
  from public.achievements a
  left join public.user_achievements ua
    on ua.achievement_id = a.id
   and ua.user_id = auth.uid()
  order by
    case when ua.user_id is not null then 0 else 1 end,
    coalesce(ua.unlocked_at, 'epoch'::timestamptz) desc,
    a.title asc;
$$;

-- ===== END MIGRATION: 20260321000014_achievement_xp_v2.sql =====

-- ===== BEGIN MIGRATION: 20260321000015_profile_progress_v1.sql =====
create table if not exists public.user_profile_progress (
  user_id uuid primary key references auth.users(id) on delete cascade,
  total_xp int not null default 0 check (total_xp >= 0),
  level int not null default 1 check (level >= 1),
  unlocked_count int not null default 0 check (unlocked_count >= 0),
  updated_at timestamptz not null default now()
);

alter table public.user_profile_progress enable row level security;

drop policy if exists user_profile_progress_read_own on public.user_profile_progress;
create policy user_profile_progress_read_own
on public.user_profile_progress
for select
to authenticated
using (user_id = auth.uid());

create or replace function public.profile_level_from_xp_v1(p_total_xp int)
returns int
language sql
immutable
as $$
  select greatest(1, (greatest(coalesce(p_total_xp, 0), 0) / 100) + 1)::int;
$$;

create or replace function public.apply_profile_xp_v1(
  p_user_id uuid,
  p_xp int
)
returns table(
  total_xp int,
  level int,
  unlocked_count int,
  leveled_up boolean
)
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  v_prev_level int;
begin
  if p_user_id is null then
    return;
  end if;

  insert into public.user_profile_progress(user_id)
  values (p_user_id)
  on conflict (user_id) do nothing;

  select upp.level
    into v_prev_level
  from public.user_profile_progress upp
  where upp.user_id = p_user_id
  for update;

  update public.user_profile_progress upp
  set
    total_xp = greatest(0, upp.total_xp + greatest(coalesce(p_xp, 0), 0)),
    unlocked_count = (
      select count(*)
      from public.user_achievements ua
      where ua.user_id = p_user_id
    ),
    updated_at = now()
  where upp.user_id = p_user_id;

  update public.user_profile_progress upp
  set level = public.profile_level_from_xp_v1(upp.total_xp)
  where upp.user_id = p_user_id;

  return query
  select
    upp.total_xp,
    upp.level,
    upp.unlocked_count,
    (upp.level > coalesce(v_prev_level, 1)) as leveled_up
  from public.user_profile_progress upp
  where upp.user_id = p_user_id;
end;
$$;

create or replace function public.recompute_profile_progress_v1(
  p_user_id uuid
)
returns void
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  v_total_xp int := 0;
  v_unlocked_count int := 0;
begin
  if p_user_id is null then
    return;
  end if;

  select
    coalesce(sum(coalesce(a.xp, 20)), 0)::int,
    count(*)::int
  into v_total_xp, v_unlocked_count
  from public.user_achievements ua
  join public.achievements a on a.id = ua.achievement_id
  where ua.user_id = p_user_id;

  insert into public.user_profile_progress(user_id, total_xp, level, unlocked_count, updated_at)
  values (
    p_user_id,
    v_total_xp,
    public.profile_level_from_xp_v1(v_total_xp),
    v_unlocked_count,
    now()
  )
  on conflict (user_id) do update
  set
    total_xp = excluded.total_xp,
    level = excluded.level,
    unlocked_count = excluded.unlocked_count,
    updated_at = excluded.updated_at;
end;
$$;

create or replace function public.get_my_profile_progress_v1()
returns table(
  total_xp int,
  level int,
  xp_in_level int,
  next_level_xp int,
  unlocked_count int
)
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  v_uid uuid := auth.uid();
  v_total_xp int := 0;
  v_level int := 1;
  v_unlocked_count int := 0;
begin
  if v_uid is null then
    return;
  end if;

  perform public.recompute_profile_progress_v1(v_uid);

  select
    upp.total_xp,
    upp.level,
    upp.unlocked_count
  into v_total_xp, v_level, v_unlocked_count
  from public.user_profile_progress upp
  where upp.user_id = v_uid;

  return query
  select
    coalesce(v_total_xp, 0),
    coalesce(v_level, 1),
    (coalesce(v_total_xp, 0) % 100),
    100,
    coalesce(v_unlocked_count, 0);
end;
$$;

create or replace function public.award_achievement_v1(
  p_user_id uuid,
  p_achievement_id text,
  p_meta jsonb default '{}'::jsonb
)
returns boolean
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  v_inserted int := 0;
  v_title text;
  v_xp int := 20;
  v_progress record;
begin
  if p_user_id is null or coalesce(trim(p_achievement_id), '') = '' then
    return false;
  end if;

  insert into public.user_achievements(user_id, achievement_id, meta)
  values (p_user_id, trim(p_achievement_id), coalesce(p_meta, '{}'::jsonb))
  on conflict do nothing;

  get diagnostics v_inserted = row_count;
  if v_inserted = 0 then
    return false;
  end if;

  select a.title, coalesce(a.xp, 20)
    into v_title, v_xp
  from public.achievements a
  where a.id = trim(p_achievement_id);

  select *
    into v_progress
  from public.apply_profile_xp_v1(p_user_id, v_xp);

  if to_regclass('public.notifications') is not null then
    perform public.notify_user_v1(
      p_user_id,
      'achievement_unlocked',
      'Basari acildi',
      'Tebrikler! "' || coalesce(v_title, trim(p_achievement_id)) || '" basarisini kazandin. +' || v_xp::text || ' XP',
      jsonb_build_object(
        'achievement_id', trim(p_achievement_id),
        'xp', v_xp,
        'level', coalesce(v_progress.level, 1),
        'total_xp', coalesce(v_progress.total_xp, v_xp),
        'leveled_up', coalesce(v_progress.leveled_up, false)
      )
    );
  end if;

  return true;
end;
$$;

grant execute on function public.get_my_profile_progress_v1() to authenticated;

do $$
begin
  if exists (select 1 from auth.users limit 1) then
    update public.user_profile_progress upp
    set
      total_xp = sub.total_xp,
      level = public.profile_level_from_xp_v1(sub.total_xp),
      unlocked_count = sub.unlocked_count,
      updated_at = now()
    from (
      select
        ua.user_id,
        coalesce(sum(coalesce(a.xp, 20)), 0)::int as total_xp,
        count(*)::int as unlocked_count
      from public.user_achievements ua
      join public.achievements a on a.id = ua.achievement_id
      group by ua.user_id
    ) sub
    where upp.user_id = sub.user_id;

    insert into public.user_profile_progress(user_id, total_xp, level, unlocked_count, updated_at)
    select
      sub.user_id,
      sub.total_xp,
      public.profile_level_from_xp_v1(sub.total_xp),
      sub.unlocked_count,
      now()
    from (
      select
        ua.user_id,
        coalesce(sum(coalesce(a.xp, 20)), 0)::int as total_xp,
        count(*)::int as unlocked_count
      from public.user_achievements ua
      join public.achievements a on a.id = ua.achievement_id
      group by ua.user_id
    ) sub
    on conflict (user_id) do nothing;
  end if;
end
$$;

-- ===== END MIGRATION: 20260321000015_profile_progress_v1.sql =====

-- ===== BEGIN MIGRATION: 20260321000016_achievement_antispam_quality.sql =====
create table if not exists public.user_achievement_awards (
  user_id uuid not null references auth.users(id) on delete cascade,
  achievement_id text not null references public.achievements(id) on delete cascade,
  award_date date not null default (now() at time zone 'utc')::date,
  awarded_at timestamptz not null default now(),
  meta jsonb not null default '{}'::jsonb,
  primary key (user_id, achievement_id, award_date)
);

alter table public.user_achievement_awards enable row level security;

drop policy if exists user_achievement_awards_read_own on public.user_achievement_awards;
create policy user_achievement_awards_read_own
on public.user_achievement_awards
for select
to authenticated
using (user_id = auth.uid());

create index if not exists user_achievement_awards_user_idx
  on public.user_achievement_awards(user_id, awarded_at desc);

create or replace function public.award_achievement_v1(
  p_user_id uuid,
  p_achievement_id text,
  p_meta jsonb default '{}'::jsonb
)
returns boolean
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  v_inserted int := 0;
  v_title text;
  v_xp int := 20;
  v_progress record;
  v_today date := (now() at time zone 'utc')::date;
begin
  if p_user_id is null or coalesce(trim(p_achievement_id), '') = '' then
    return false;
  end if;

  -- Anti-spam: same achievement can never be awarded twice in the same UTC day.
  if exists (
    select 1
    from public.user_achievement_awards a
    where a.user_id = p_user_id
      and a.achievement_id = trim(p_achievement_id)
      and a.award_date = v_today
  ) then
    return false;
  end if;

  insert into public.user_achievements(user_id, achievement_id, meta)
  values (p_user_id, trim(p_achievement_id), coalesce(p_meta, '{}'::jsonb))
  on conflict do nothing;

  get diagnostics v_inserted = row_count;
  if v_inserted = 0 then
    return false;
  end if;

  insert into public.user_achievement_awards(user_id, achievement_id, award_date, meta)
  values (p_user_id, trim(p_achievement_id), v_today, coalesce(p_meta, '{}'::jsonb))
  on conflict do nothing;

  select a.title, coalesce(a.xp, 20)
    into v_title, v_xp
  from public.achievements a
  where a.id = trim(p_achievement_id);

  select *
    into v_progress
  from public.apply_profile_xp_v1(p_user_id, v_xp);

  if to_regclass('public.notifications') is not null then
    perform public.notify_user_v1(
      p_user_id,
      'achievement_unlocked',
      'Basari acildi',
      'Tebrikler! "' || coalesce(v_title, trim(p_achievement_id)) || '" basarisini kazandin. +' || v_xp::text || ' XP',
      jsonb_build_object(
        'achievement_id', trim(p_achievement_id),
        'xp', v_xp,
        'level', coalesce(v_progress.level, 1),
        'total_xp', coalesce(v_progress.total_xp, v_xp),
        'leveled_up', coalesce(v_progress.leveled_up, false)
      )
    );
  end if;

  return true;
end;
$$;

create or replace function public.recompute_user_achievements_v1(
  p_user_id uuid
)
returns void
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  v_review_count int := 0;
  v_rating_count int := 0;
  v_business_view_count int := 0;
  v_unique_rated_count int := 0;
  v_price_verified_count int := 0;
  v_menu_photo_count int := 0;
  v_wrong_info_reports_count int := 0;
  v_reputation int := 0;
  v_top10 boolean := false;
begin
  if p_user_id is null then
    return;
  end if;

  -- Only approved/published non-shadow reviews are quality signals.
  if to_regclass('public.reviews') is not null then
    execute
      'select count(*) from public.reviews
       where user_id = $1
         and status = any($2)
         and coalesce(is_shadow, false) = false'
      into v_review_count using p_user_id, array['approved','published'];

    execute
      'select count(*) from public.reviews
       where user_id = $1
         and rating is not null
         and status = any($2)
         and coalesce(is_shadow, false) = false'
      into v_rating_count using p_user_id, array['approved','published'];

    execute
      'select count(distinct business_id) from public.reviews
       where user_id = $1
         and rating is not null
         and business_id is not null
         and status = any($2)
         and coalesce(is_shadow, false) = false'
      into v_unique_rated_count using p_user_id, array['approved','published'];
  end if;

  if to_regclass('public.analytics_events') is not null then
    execute
      'select count(*) from public.analytics_events
       where user_id = $1 and event_name = any($2)'
      into v_business_view_count using p_user_id, array['discovery_business_click', 'business_view'];
  end if;

  -- Rejected or shadowed suggestions must not contribute.
  if to_regclass('public.menu_item_price_suggestions') is not null then
    execute
      'select count(*) from public.menu_item_price_suggestions
       where created_by = $1
         and status = any($2)
         and coalesce(is_shadow, false) = false'
      into v_price_verified_count using p_user_id, array['approved','accepted','handled','verified'];
  end if;

  if to_regclass('public.menu_item_photos') is not null then
    execute
      'select count(*) from public.menu_item_photos
       where created_by = $1
         and coalesce(is_shadow, false) = false'
      into v_menu_photo_count using p_user_id;
  end if;

  -- Only validly closed reports count; open/noise reports do not.
  if to_regclass('public.reports') is not null then
    execute
      'select count(*) from public.reports
       where coalesce(user_id, reporter_user_id) = $1
         and coalesce(status, '''') = any($2)
         and coalesce(is_shadow, false) = false'
      into v_wrong_info_reports_count using p_user_id, array['kapandi', 'resolved', 'closed'];
  end if;

  v_reputation := public.get_user_reputation_score_v2(p_user_id);

  if to_regclass('public.reviews') is not null then
    execute $sql$
      with user_counts as (
        select
          b.district,
          r.user_id,
          count(*)::int as c
        from public.reviews r
        join public.businesses b on b.id = r.business_id
        where b.district is not null
          and r.status = any($2)
          and coalesce(r.is_shadow, false) = false
        group by b.district, r.user_id
      ),
      ranked as (
        select
          district,
          user_id,
          c,
          rank() over(partition by district order by c desc, user_id) as rnk,
          count(*) over(partition by district) as user_total
        from user_counts
      )
      select exists(
        select 1
        from ranked
        where user_id = $1
          and user_total >= 10
          and rnk <= greatest(1, ceil(user_total::numeric * 0.10)::int)
      )
    $sql$
    into v_top10 using p_user_id, array['approved','published'];
  end if;

  if v_review_count >= 1 then
    perform public.award_achievement_v1(p_user_id, 'first_review');
  end if;
  if v_rating_count >= 1 then
    perform public.award_achievement_v1(p_user_id, 'first_rating');
  end if;
  if v_business_view_count >= 1 then
    perform public.award_achievement_v1(p_user_id, 'first_discovery');
  end if;
  if v_unique_rated_count >= 10 then
    perform public.award_achievement_v1(p_user_id, 'traveler_10');
  end if;
  if v_price_verified_count >= 5 then
    perform public.award_achievement_v1(p_user_id, 'price_hunter_5');
  end if;
  if v_menu_photo_count >= 3 then
    perform public.award_achievement_v1(p_user_id, 'observer_3');
  end if;
  if v_wrong_info_reports_count >= 10 then
    perform public.award_achievement_v1(p_user_id, 'detective_10');
  end if;
  if v_reputation >= 80 then
    perform public.award_achievement_v1(p_user_id, 'trusted_contributor');
  end if;
  if v_top10 then
    perform public.award_achievement_v1(p_user_id, 'district_gourmet_top10');
  end if;
end;
$$;

create or replace function public.admin_reset_user_achievement_v1(
  p_user_id uuid,
  p_achievement_id text,
  p_reason text default null
)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  v_deleted int := 0;
  v_reason text := nullif(trim(p_reason), '');
  v_target_id text := coalesce(p_user_id::text, '') || ':' || coalesce(trim(p_achievement_id), '');
begin
  if not public.is_admin() then
    return jsonb_build_object('ok', false, 'error', 'not_admin');
  end if;

  if p_user_id is null or coalesce(trim(p_achievement_id), '') = '' then
    return jsonb_build_object('ok', false, 'error', 'bad_request');
  end if;

  delete from public.user_achievements ua
  where ua.user_id = p_user_id
    and ua.achievement_id = trim(p_achievement_id);

  get diagnostics v_deleted = row_count;

  perform public.recompute_profile_progress_v1(p_user_id);

  insert into public.admin_audit_log(action, target_table, target_id, meta)
  values (
    'achievement.reset',
    'user_achievements',
    v_target_id,
    jsonb_build_object(
      'user_id', p_user_id,
      'achievement_id', trim(p_achievement_id),
      'deleted', v_deleted > 0,
      'reason', v_reason
    )
  );

  return jsonb_build_object('ok', true, 'deleted', v_deleted > 0);
end;
$$;

grant execute on function public.admin_reset_user_achievement_v1(uuid, text, text) to authenticated;

-- ===== END MIGRATION: 20260321000016_achievement_antispam_quality.sql =====

-- ===== BEGIN MIGRATION: 20260321000017_hidden_achievements_v1.sql =====
alter table public.achievements
  add column if not exists is_hidden boolean not null default false;

update public.achievements
set is_hidden = coalesce(is_hidden, false)
where true;

insert into public.achievements(
  id, title, description, icon, color, xp, is_hidden, condition
)
values
  (
    'silent_follower_20',
    'Sessiz Takipci',
    '20 isletmeye bak, hic yorum yazma',
    'visibility',
    '#64748B',
    35,
    true,
    '{"type":"silent_follower","views":20,"reviews":0}'
  ),
  (
    'night_gourmet_5',
    'Gece Gurmesi',
    '00:00-04:00 arasi 5 mekan incele',
    'bedtime',
    '#1D4ED8',
    45,
    true,
    '{"type":"night_views","value":5}'
  ),
  (
    'menu_archivist_1',
    'Menu Arsivcisi',
    '1 yil eski menude fiyat dogrulama katkisi yap',
    'history_edu',
    '#7C3AED',
    60,
    true,
    '{"type":"stale_menu_update","days":365,"value":1}'
  ),
  (
    'chance_hunter_10',
    'Tesaduf Avcisi',
    'Arama yapmadan kesfetten 10 mekan ac',
    'explore',
    '#F59E0B',
    45,
    true,
    '{"type":"serendipity_click","value":10}'
  ),
  (
    'weekend_wanderer_8',
    'Hafta Sonu Kesfedicisi',
    'Hafta sonu 8 mekan incele',
    'event',
    '#06B6D4',
    35,
    true,
    '{"type":"weekend_business_view","value":8}'
  ),
  (
    'deep_menu_diver_30',
    'Derin Menu Avcisi',
    '30 farkli menu urunu goruntule',
    'restaurant_menu',
    '#10B981',
    40,
    true,
    '{"type":"unique_menu_item_view","value":30}'
  )
on conflict (id) do update set
  title = excluded.title,
  description = excluded.description,
  icon = excluded.icon,
  color = excluded.color,
  xp = excluded.xp,
  is_hidden = excluded.is_hidden,
  condition = excluded.condition;

create or replace function public.get_my_achievements_v2()
returns table(
  id text,
  title text,
  description text,
  icon text,
  color text,
  xp int,
  condition jsonb,
  unlocked boolean,
  unlocked_at timestamptz
)
language sql
security definer
set search_path to 'public'
as $$
  select
    a.id,
    a.title,
    a.description,
    a.icon,
    a.color,
    coalesce(a.xp, 20) as xp,
    a.condition,
    (ua.user_id is not null) as unlocked,
    ua.unlocked_at
  from public.achievements a
  left join public.user_achievements ua
    on ua.achievement_id = a.id
   and ua.user_id = auth.uid()
  where not coalesce(a.is_hidden, false)
     or ua.user_id is not null
  order by
    case when ua.user_id is not null then 0 else 1 end,
    coalesce(ua.unlocked_at, 'epoch'::timestamptz) desc,
    a.title asc;
$$;

create or replace function public.recompute_user_achievements_v1(
  p_user_id uuid
)
returns void
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  v_review_count int := 0;
  v_rating_count int := 0;
  v_business_view_count int := 0;
  v_unique_rated_count int := 0;
  v_price_verified_count int := 0;
  v_menu_photo_count int := 0;
  v_wrong_info_reports_count int := 0;
  v_reputation int := 0;
  v_top10 boolean := false;
  v_silent_views int := 0;
  v_night_views int := 0;
  v_serendipity_clicks int := 0;
  v_weekend_views int := 0;
  v_stale_updates int := 0;
  v_unique_menu_item_views int := 0;
begin
  if p_user_id is null then
    return;
  end if;

  if to_regclass('public.reviews') is not null then
    execute
      'select count(*) from public.reviews
       where user_id = $1
         and status = any($2)
         and coalesce(is_shadow, false) = false'
      into v_review_count using p_user_id, array['approved','published'];

    execute
      'select count(*) from public.reviews
       where user_id = $1
         and rating is not null
         and status = any($2)
         and coalesce(is_shadow, false) = false'
      into v_rating_count using p_user_id, array['approved','published'];

    execute
      'select count(distinct business_id) from public.reviews
       where user_id = $1
         and rating is not null
         and business_id is not null
         and status = any($2)
         and coalesce(is_shadow, false) = false'
      into v_unique_rated_count using p_user_id, array['approved','published'];
  end if;

  if to_regclass('public.analytics_events') is not null then
    execute
      'select count(*) from public.analytics_events
       where user_id = $1 and event_name = any($2)'
      into v_business_view_count using p_user_id, array['discovery_business_click', 'business_view', 'business_page_view'];

    execute
      'select count(*) from public.analytics_events
       where user_id = $1
         and event_name = any($2)'
      into v_silent_views using p_user_id, array['discovery_business_click', 'business_page_view'];

    execute
      'select count(*) from public.analytics_events
       where user_id = $1
         and event_name = any($2)
         and extract(hour from (created_at at time zone ''Europe/Istanbul'')) between 0 and 3'
      into v_night_views using p_user_id, array['discovery_business_click', 'business_page_view'];

    execute
      'select count(*) from public.analytics_events
       where user_id = $1
         and event_name = ''discovery_business_click''
         and coalesce(source, '''') = any($2)'
      into v_serendipity_clicks using p_user_id, array['discover', 'serendipity', 'discover_list'];

    execute
      'select count(*) from public.analytics_events
       where user_id = $1
         and event_name = any($2)
         and extract(isodow from (created_at at time zone ''Europe/Istanbul'')) in (6,7)'
      into v_weekend_views using p_user_id, array['discovery_business_click', 'business_page_view'];

    execute
      'select count(distinct coalesce((meta->>''menu_item_id''), ''''))
       from public.analytics_events
       where user_id = $1
         and event_name = ''menu_view''
         and coalesce((meta->>''menu_item_id''), '''') <> '''''
      into v_unique_menu_item_views using p_user_id;
  end if;

  if to_regclass('public.menu_item_price_suggestions') is not null then
    execute
      'select count(*) from public.menu_item_price_suggestions
       where created_by = $1
         and status = any($2)
         and coalesce(is_shadow, false) = false'
      into v_price_verified_count using p_user_id, array['approved','accepted','handled','verified'];

    if to_regclass('public.menu_items') is not null then
      execute
        'select count(*) from public.menu_item_price_suggestions s
         join public.menu_items mi on mi.id = s.menu_item_id
         where s.created_by = $1
           and s.status = any($2)
           and coalesce(s.is_shadow, false) = false
           and mi.updated_at <= now() - interval ''365 days'''
        into v_stale_updates using p_user_id, array['approved','accepted','handled','verified'];
    end if;
  end if;

  if to_regclass('public.menu_item_photos') is not null then
    execute
      'select count(*) from public.menu_item_photos
       where created_by = $1
         and coalesce(is_shadow, false) = false'
      into v_menu_photo_count using p_user_id;
  end if;

  if to_regclass('public.reports') is not null then
    execute
      'select count(*) from public.reports
       where coalesce(user_id, reporter_user_id) = $1
         and coalesce(status, '''') = any($2)
         and coalesce(is_shadow, false) = false'
      into v_wrong_info_reports_count using p_user_id, array['kapandi', 'resolved', 'closed'];
  end if;

  v_reputation := public.get_user_reputation_score_v2(p_user_id);

  if to_regclass('public.reviews') is not null then
    execute $sql$
      with user_counts as (
        select
          b.district,
          r.user_id,
          count(*)::int as c
        from public.reviews r
        join public.businesses b on b.id = r.business_id
        where b.district is not null
          and r.status = any($2)
          and coalesce(r.is_shadow, false) = false
        group by b.district, r.user_id
      ),
      ranked as (
        select
          district,
          user_id,
          c,
          rank() over(partition by district order by c desc, user_id) as rnk,
          count(*) over(partition by district) as user_total
        from user_counts
      )
      select exists(
        select 1
        from ranked
        where user_id = $1
          and user_total >= 10
          and rnk <= greatest(1, ceil(user_total::numeric * 0.10)::int)
      )
    $sql$
    into v_top10 using p_user_id, array['approved','published'];
  end if;

  if v_review_count >= 1 then
    perform public.award_achievement_v1(p_user_id, 'first_review');
  end if;
  if v_rating_count >= 1 then
    perform public.award_achievement_v1(p_user_id, 'first_rating');
  end if;
  if v_business_view_count >= 1 then
    perform public.award_achievement_v1(p_user_id, 'first_discovery');
  end if;
  if v_unique_rated_count >= 10 then
    perform public.award_achievement_v1(p_user_id, 'traveler_10');
  end if;
  if v_price_verified_count >= 5 then
    perform public.award_achievement_v1(p_user_id, 'price_hunter_5');
  end if;
  if v_menu_photo_count >= 3 then
    perform public.award_achievement_v1(p_user_id, 'observer_3');
  end if;
  if v_wrong_info_reports_count >= 10 then
    perform public.award_achievement_v1(p_user_id, 'detective_10');
  end if;
  if v_reputation >= 80 then
    perform public.award_achievement_v1(p_user_id, 'trusted_contributor');
  end if;
  if v_top10 then
    perform public.award_achievement_v1(p_user_id, 'district_gourmet_top10');
  end if;

  -- Hidden achievements.
  if v_silent_views >= 20 and v_review_count = 0 then
    perform public.award_achievement_v1(p_user_id, 'silent_follower_20');
  end if;
  if v_night_views >= 5 then
    perform public.award_achievement_v1(p_user_id, 'night_gourmet_5');
  end if;
  if v_stale_updates >= 1 then
    perform public.award_achievement_v1(p_user_id, 'menu_archivist_1');
  end if;
  if v_serendipity_clicks >= 10 then
    perform public.award_achievement_v1(p_user_id, 'chance_hunter_10');
  end if;
  if v_weekend_views >= 8 then
    perform public.award_achievement_v1(p_user_id, 'weekend_wanderer_8');
  end if;
  if v_unique_menu_item_views >= 30 then
    perform public.award_achievement_v1(p_user_id, 'deep_menu_diver_30');
  end if;
end;
$$;

create or replace function public.admin_reset_user_achievement_v1(
  p_user_id uuid,
  p_achievement_id text,
  p_reason text default null
)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  v_deleted int := 0;
  v_award_deleted int := 0;
  v_reason text := nullif(trim(p_reason), '');
  v_target_id text := coalesce(p_user_id::text, '') || ':' || coalesce(trim(p_achievement_id), '');
begin
  if not public.is_admin() then
    return jsonb_build_object('ok', false, 'error', 'not_admin');
  end if;

  if p_user_id is null or coalesce(trim(p_achievement_id), '') = '' then
    return jsonb_build_object('ok', false, 'error', 'bad_request');
  end if;

  delete from public.user_achievements ua
  where ua.user_id = p_user_id
    and ua.achievement_id = trim(p_achievement_id);
  get diagnostics v_deleted = row_count;

  delete from public.user_achievement_awards a
  where a.user_id = p_user_id
    and a.achievement_id = trim(p_achievement_id);
  get diagnostics v_award_deleted = row_count;

  perform public.recompute_profile_progress_v1(p_user_id);

  insert into public.admin_audit_log(action, target_table, target_id, meta)
  values (
    'achievement.reset',
    'user_achievements',
    v_target_id,
    jsonb_build_object(
      'user_id', p_user_id,
      'achievement_id', trim(p_achievement_id),
      'deleted', v_deleted > 0,
      'award_rows_deleted', v_award_deleted,
      'reason', v_reason
    )
  );

  return jsonb_build_object(
    'ok', true,
    'deleted', v_deleted > 0,
    'award_rows_deleted', v_award_deleted
  );
end;
$$;

-- ===== END MIGRATION: 20260321000017_hidden_achievements_v1.sql =====

-- ===== BEGIN MIGRATION: 20260321000018_progressive_pizza_achievement.sql =====
insert into public.achievements (
  id,
  title,
  description,
  icon,
  color,
  xp,
  is_hidden,
  condition
)
values (
  'pizza_master_10',
  'Pizza Ustasi',
  '10 farkli pizza mekanini puanla',
  'local_pizza',
  '#F97316',
  55,
  false,
  '{"type":"category_unique_rated_business_count","category":"pizza","value":10}'::jsonb
)
on conflict (id) do update set
  title = excluded.title,
  description = excluded.description,
  icon = excluded.icon,
  color = excluded.color,
  xp = excluded.xp,
  is_hidden = excluded.is_hidden,
  condition = excluded.condition;

drop function if exists public.get_my_achievements_v2();

create function public.get_my_achievements_v2()
returns table(
  id text,
  title text,
  description text,
  icon text,
  color text,
  xp int,
  condition jsonb,
  unlocked boolean,
  unlocked_at timestamptz,
  current_value int,
  target_value int
)
language sql
security definer
set search_path to 'public'
as $$
  with me as (
    select auth.uid() as uid
  ),
  metrics as (
    select
      (select count(*)::int
       from public.reviews r, me
       where r.user_id = me.uid
         and r.status = any(array['approved','published'])) as review_count,
      (select count(*)::int
       from public.analytics_events e, me
       where e.user_id = me.uid
         and e.event_name = any(array['discovery_business_click', 'business_view', 'business_page_view'])) as business_view_count,
      (select count(*)::int
       from public.menu_item_price_suggestions s, me
       where s.created_by = me.uid
         and s.status::text = any(array['approved','accepted','handled','verified'])) as price_verified_count,
      coalesce(public.get_my_reputation_score_v1(), 0)::int as reputation_score
  )
  select
    a.id,
    a.title,
    a.description,
    a.icon,
    a.color,
    coalesce(a.xp, 20) as xp,
    a.condition,
    (ua.user_id is not null) as unlocked,
    ua.unlocked_at,
    coalesce(
      case (a.condition->>'type')
        when 'review_count' then m.review_count
        when 'business_view_count' then m.business_view_count
        when 'price_verified_count' then m.price_verified_count
        when 'reputation_score' then m.reputation_score
        when 'unique_rated_business_count' then (
          select count(distinct r.business_id)::int
          from public.reviews r, me
          where r.user_id = me.uid
            and r.rating is not null
            and r.business_id is not null
            and r.status = any(array['approved','published'])
        )
        when 'category_unique_rated_business_count' then (
          select count(distinct r.business_id)::int
          from public.reviews r
          join public.businesses b on b.id = r.business_id
          join me on true
          where r.user_id = me.uid
            and r.rating is not null
            and r.business_id is not null
            and r.status = any(array['approved','published'])
            and lower(coalesce(b.category, '')) like '%' || lower(coalesce(a.condition->>'category', '')) || '%'
        )
        else null
      end,
      case when ua.user_id is not null then coalesce((a.condition->>'value')::int, 0) else 0 end
    ) as current_value,
    coalesce((a.condition->>'value')::int, 0) as target_value
  from public.achievements a
  left join public.user_achievements ua
    on ua.achievement_id = a.id
   and ua.user_id = auth.uid()
  cross join metrics m
  where not coalesce(a.is_hidden, false)
     or ua.user_id is not null
  order by
    case when ua.user_id is not null then 0 else 1 end,
    coalesce(ua.unlocked_at, 'epoch'::timestamptz) desc,
    a.title asc;
$$;

create or replace function public.get_my_daily_micro_task_v1()
returns table(
  task_key text,
  title text,
  description text,
  current_value int,
  target_value int,
  completed boolean
)
language sql
security definer
set search_path to 'public'
as $$
  with me as (
    select auth.uid() as uid
  ),
  d as (
    select (extract(doy from now() at time zone 'Europe/Istanbul')::int % 3) as idx
  ),
  metrics as (
    select
      (select count(*)::int
       from public.menu_item_price_suggestions s, me
       where s.created_by = me.uid
        and s.created_at >= date_trunc('day', now() at time zone 'Europe/Istanbul')
        and s.status::text = any(array['approved','accepted','handled','verified'])) as price_verified_today,
      (select count(*)::int
       from public.analytics_events e, me
       where e.user_id = me.uid
         and e.created_at >= date_trunc('day', now() at time zone 'Europe/Istanbul')
         and e.event_name = any(array['discovery_business_click', 'business_page_view', 'business_view'])) as discovered_today,
      (select count(*)::int
       from public.review_votes v, me
       where v.user_id = me.uid
         and v.created_at >= date_trunc('day', now() at time zone 'Europe/Istanbul')) as helpful_today
  )
  select
    case d.idx
      when 0 then 'verify_price_once'
      when 1 then 'discover_business_once'
      else 'helpful_vote_once'
    end as task_key,
    case d.idx
      when 0 then 'Bugün 1 fiyat doğrula'
      when 1 then 'Bugün yeni bir mekan keşfet'
      else 'Bugün bir yorumu faydalı bul'
    end as title,
    case d.idx
      when 0 then '10 saniye sürer, veri kalitesini artırır.'
      when 1 then 'Kısa bir keşif, öneri kalitesine katkı sağlar.'
      else 'Kaliteli yorumu öne çıkar, topluluğa destek ol.'
    end as description,
    case d.idx
      when 0 then least(m.price_verified_today, 1)
      when 1 then least(m.discovered_today, 1)
      else least(m.helpful_today, 1)
    end as current_value,
    1 as target_value,
    case d.idx
      when 0 then m.price_verified_today >= 1
      when 1 then m.discovered_today >= 1
      else m.helpful_today >= 1
    end as completed
  from d
  cross join metrics m;
$$;

grant execute on function public.get_my_daily_micro_task_v1() to authenticated;

create or replace function public.recompute_user_achievements_v1(
  p_user_id uuid
)
returns void
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  v_review_count int := 0;
  v_rating_count int := 0;
  v_business_view_count int := 0;
  v_unique_rated_count int := 0;
  v_price_verified_count int := 0;
  v_menu_photo_count int := 0;
  v_wrong_info_reports_count int := 0;
  v_reputation int := 0;
  v_top10 boolean := false;
  v_silent_views int := 0;
  v_night_views int := 0;
  v_serendipity_clicks int := 0;
  v_weekend_views int := 0;
  v_stale_updates int := 0;
  v_unique_menu_item_views int := 0;
  v_pizza_unique_rated_count int := 0;
begin
  if p_user_id is null then
    return;
  end if;

  if to_regclass('public.reviews') is not null then
    execute
      'select count(*) from public.reviews
       where user_id = $1
         and status = any($2)
         and coalesce(is_shadow, false) = false'
      into v_review_count using p_user_id, array['approved','published'];

    execute
      'select count(*) from public.reviews
       where user_id = $1
         and rating is not null
         and status = any($2)
         and coalesce(is_shadow, false) = false'
      into v_rating_count using p_user_id, array['approved','published'];

    execute
      'select count(distinct business_id) from public.reviews
       where user_id = $1
         and rating is not null
         and business_id is not null
         and status = any($2)
         and coalesce(is_shadow, false) = false'
      into v_unique_rated_count using p_user_id, array['approved','published'];

    if to_regclass('public.businesses') is not null then
      execute
        'select count(distinct r.business_id)
         from public.reviews r
         join public.businesses b on b.id = r.business_id
         where r.user_id = $1
           and r.rating is not null
           and r.business_id is not null
           and r.status = any($2)
           and coalesce(r.is_shadow, false) = false
           and lower(coalesce(b.category, '''')) like ''%pizza%'''
        into v_pizza_unique_rated_count using p_user_id, array['approved','published'];
    end if;
  end if;

  if to_regclass('public.analytics_events') is not null then
    execute
      'select count(*) from public.analytics_events
       where user_id = $1 and event_name = any($2)'
      into v_business_view_count using p_user_id, array['discovery_business_click', 'business_view', 'business_page_view'];

    execute
      'select count(*) from public.analytics_events
       where user_id = $1
         and event_name = any($2)'
      into v_silent_views using p_user_id, array['discovery_business_click', 'business_page_view'];

    execute
      'select count(*) from public.analytics_events
       where user_id = $1
         and event_name = any($2)
         and extract(hour from (created_at at time zone ''Europe/Istanbul'')) between 0 and 3'
      into v_night_views using p_user_id, array['discovery_business_click', 'business_page_view'];

    execute
      'select count(*) from public.analytics_events
       where user_id = $1
         and event_name = ''discovery_business_click''
         and coalesce(source, '''') = any($2)'
      into v_serendipity_clicks using p_user_id, array['discover', 'serendipity', 'discover_list'];

    execute
      'select count(*) from public.analytics_events
       where user_id = $1
         and event_name = any($2)
         and extract(isodow from (created_at at time zone ''Europe/Istanbul'')) in (6,7)'
      into v_weekend_views using p_user_id, array['discovery_business_click', 'business_page_view'];

    execute
      'select count(distinct coalesce((meta->>''menu_item_id''), ''''))
       from public.analytics_events
       where user_id = $1
         and event_name = ''menu_view''
         and coalesce((meta->>''menu_item_id''), '''') <> '''''
      into v_unique_menu_item_views using p_user_id;
  end if;

  if to_regclass('public.menu_item_price_suggestions') is not null then
    execute
      'select count(*) from public.menu_item_price_suggestions
       where created_by = $1
         and status = any($2)
         and coalesce(is_shadow, false) = false'
      into v_price_verified_count using p_user_id, array['approved','accepted','handled','verified'];

    if to_regclass('public.menu_items') is not null then
      execute
        'select count(*) from public.menu_item_price_suggestions s
         join public.menu_items mi on mi.id = s.menu_item_id
         where s.created_by = $1
           and s.status = any($2)
           and coalesce(s.is_shadow, false) = false
           and mi.updated_at <= now() - interval ''365 days'''
        into v_stale_updates using p_user_id, array['approved','accepted','handled','verified'];
    end if;
  end if;

  if to_regclass('public.menu_item_photos') is not null then
    execute
      'select count(*) from public.menu_item_photos
       where created_by = $1
         and coalesce(is_shadow, false) = false'
      into v_menu_photo_count using p_user_id;
  end if;

  if to_regclass('public.reports') is not null then
    execute
      'select count(*) from public.reports
       where coalesce(user_id, reporter_user_id) = $1
         and coalesce(status, '''') = any($2)
         and coalesce(is_shadow, false) = false'
      into v_wrong_info_reports_count using p_user_id, array['kapandi', 'resolved', 'closed'];
  end if;

  v_reputation := public.get_user_reputation_score_v2(p_user_id);

  if to_regclass('public.reviews') is not null then
    execute $sql$
      with user_counts as (
        select
          b.district,
          r.user_id,
          count(*)::int as c
        from public.reviews r
        join public.businesses b on b.id = r.business_id
        where b.district is not null
          and r.status = any($2)
          and coalesce(r.is_shadow, false) = false
        group by b.district, r.user_id
      ),
      ranked as (
        select
          district,
          user_id,
          c,
          rank() over(partition by district order by c desc, user_id) as rnk,
          count(*) over(partition by district) as user_total
        from user_counts
      )
      select exists(
        select 1
        from ranked
        where user_id = $1
          and user_total >= 10
          and rnk <= greatest(1, ceil(user_total::numeric * 0.10)::int)
      )
    $sql$
    into v_top10 using p_user_id, array['approved','published'];
  end if;

  if v_review_count >= 1 then
    perform public.award_achievement_v1(p_user_id, 'first_review');
  end if;
  if v_rating_count >= 1 then
    perform public.award_achievement_v1(p_user_id, 'first_rating');
  end if;
  if v_business_view_count >= 1 then
    perform public.award_achievement_v1(p_user_id, 'first_discovery');
  end if;
  if v_unique_rated_count >= 10 then
    perform public.award_achievement_v1(p_user_id, 'traveler_10');
  end if;
  if v_price_verified_count >= 5 then
    perform public.award_achievement_v1(p_user_id, 'price_hunter_5');
  end if;
  if v_menu_photo_count >= 3 then
    perform public.award_achievement_v1(p_user_id, 'observer_3');
  end if;
  if v_wrong_info_reports_count >= 10 then
    perform public.award_achievement_v1(p_user_id, 'detective_10');
  end if;
  if v_reputation >= 80 then
    perform public.award_achievement_v1(p_user_id, 'trusted_contributor');
  end if;
  if v_top10 then
    perform public.award_achievement_v1(p_user_id, 'district_gourmet_top10');
  end if;
  if v_pizza_unique_rated_count >= 10 then
    perform public.award_achievement_v1(p_user_id, 'pizza_master_10');
  end if;

  -- Hidden achievements.
  if v_silent_views >= 20 and v_review_count = 0 then
    perform public.award_achievement_v1(p_user_id, 'silent_follower_20');
  end if;
  if v_night_views >= 5 then
    perform public.award_achievement_v1(p_user_id, 'night_gourmet_5');
  end if;
  if v_stale_updates >= 1 then
    perform public.award_achievement_v1(p_user_id, 'menu_archivist_1');
  end if;
  if v_serendipity_clicks >= 10 then
    perform public.award_achievement_v1(p_user_id, 'chance_hunter_10');
  end if;
  if v_weekend_views >= 8 then
    perform public.award_achievement_v1(p_user_id, 'weekend_wanderer_8');
  end if;
  if v_unique_menu_item_views >= 30 then
    perform public.award_achievement_v1(p_user_id, 'deep_menu_diver_30');
  end if;
end;
$$;

-- ===== END MIGRATION: 20260321000018_progressive_pizza_achievement.sql =====

-- ===== BEGIN MIGRATION: 20260321000019_combo_achievements.sql =====
insert into public.achievements (
  id,
  title,
  description,
  icon,
  color,
  xp,
  is_hidden,
  condition
)
values
  (
    'combo_price_streak_3',
    'Seri Avci',
    '3 gun ust uste fiyat dogrula',
    'whatshot',
    '#EF4444',
    80,
    false,
    '{"type":"price_verified_streak_days","value":3}'::jsonb
  ),
  (
    'combo_district_master_5',
    'Mahalle Hakimi',
    'Ayni ilcede 5 farkli mekani puanla',
    'location_city',
    '#2563EB',
    70,
    false,
    '{"type":"district_unique_rated_business_count","value":5}'::jsonb
  ),
  (
    'combo_full_contributor',
    'Tam Katki',
    'Yorum + fiyat + menu fotosu katkisini tamamla',
    'auto_awesome',
    '#7C3AED',
    90,
    false,
    '{"type":"combo_review_price_photo","value":3}'::jsonb
  )
on conflict (id) do update set
  title = excluded.title,
  description = excluded.description,
  icon = excluded.icon,
  color = excluded.color,
  xp = excluded.xp,
  is_hidden = excluded.is_hidden,
  condition = excluded.condition;

drop function if exists public.get_my_achievements_v2();

create function public.get_my_achievements_v2()
returns table(
  id text,
  title text,
  description text,
  icon text,
  color text,
  xp int,
  condition jsonb,
  unlocked boolean,
  unlocked_at timestamptz,
  current_value int,
  target_value int
)
language sql
security definer
set search_path to 'public'
as $$
  with me as (
    select auth.uid() as uid
  ),
  metrics as (
    select
      (select count(*)::int
       from public.reviews r, me
       where r.user_id = me.uid
         and r.status = any(array['approved','published'])
         and coalesce((to_jsonb(r)->>'is_shadow')::boolean, false) = false) as review_count,
      (select count(*)::int
       from public.analytics_events e, me
       where e.user_id = me.uid
         and e.event_name = any(array['discovery_business_click', 'business_view', 'business_page_view'])) as business_view_count,
      (select count(*)::int
       from public.menu_item_price_suggestions s, me
       where s.created_by = me.uid
         and s.status::text = any(array['approved','accepted','handled','verified'])
         and coalesce((to_jsonb(s)->>'is_shadow')::boolean, false) = false) as price_verified_count,
      coalesce(public.get_my_reputation_score_v1(), 0)::int as reputation_score,
      (
        with verified_days as (
          select distinct (s.created_at at time zone 'Europe/Istanbul')::date as d
          from public.menu_item_price_suggestions s, me
          where s.created_by = me.uid
            and s.status::text = any(array['approved','accepted','handled','verified'])
            and coalesce((to_jsonb(s)->>'is_shadow')::boolean, false) = false
        ),
        grouped as (
          select
            d,
            d - (row_number() over(order by d))::int as grp
          from verified_days
        )
        select coalesce(max(streak_len), 0)::int
        from (
          select count(*)::int as streak_len
          from grouped
          group by grp
        ) s
      ) as price_verified_streak_days,
      (
        select coalesce(max(c.cnt), 0)::int
        from (
          select count(distinct r.business_id)::int as cnt
          from public.reviews r
          join public.businesses b on b.id = r.business_id
          join me on true
          where r.user_id = me.uid
            and r.rating is not null
            and r.business_id is not null
            and r.status = any(array['approved','published'])
            and coalesce((to_jsonb(r)->>'is_shadow')::boolean, false) = false
            and nullif(trim(b.district), '') is not null
          group by b.district
        ) c
      ) as district_unique_rated_business_count,
      (
        (case when (
          select count(*)::int
          from public.reviews r, me
          where r.user_id = me.uid
            and r.status = any(array['approved','published'])
            and coalesce((to_jsonb(r)->>'is_shadow')::boolean, false) = false
        ) > 0 then 1 else 0 end) +
        (case when (
          select count(*)::int
          from public.menu_item_price_suggestions s, me
          where s.created_by = me.uid
            and s.status::text = any(array['approved','accepted','handled','verified'])
            and coalesce((to_jsonb(s)->>'is_shadow')::boolean, false) = false
        ) > 0 then 1 else 0 end) +
        (case when (
          select count(*)::int
          from public.menu_item_photos p, me
          where p.created_by = me.uid
            and coalesce((to_jsonb(p)->>'is_shadow')::boolean, false) = false
        ) > 0 then 1 else 0 end)
      )::int as combo_review_price_photo
  )
  select
    a.id,
    a.title,
    a.description,
    a.icon,
    a.color,
    coalesce(a.xp, 20) as xp,
    a.condition,
    (ua.user_id is not null) as unlocked,
    ua.unlocked_at,
    coalesce(
      case (a.condition->>'type')
        when 'review_count' then m.review_count
        when 'business_view_count' then m.business_view_count
        when 'price_verified_count' then m.price_verified_count
        when 'reputation_score' then m.reputation_score
        when 'price_verified_streak_days' then m.price_verified_streak_days
        when 'district_unique_rated_business_count' then m.district_unique_rated_business_count
        when 'combo_review_price_photo' then m.combo_review_price_photo
        when 'unique_rated_business_count' then (
          select count(distinct r.business_id)::int
          from public.reviews r, me
          where r.user_id = me.uid
            and r.rating is not null
            and r.business_id is not null
            and r.status = any(array['approved','published'])
            and coalesce((to_jsonb(r)->>'is_shadow')::boolean, false) = false
        )
        when 'category_unique_rated_business_count' then (
          select count(distinct r.business_id)::int
          from public.reviews r
          join public.businesses b on b.id = r.business_id
          join me on true
          where r.user_id = me.uid
            and r.rating is not null
            and r.business_id is not null
            and r.status = any(array['approved','published'])
            and coalesce((to_jsonb(r)->>'is_shadow')::boolean, false) = false
            and lower(coalesce(b.category, '')) like '%' || lower(coalesce(a.condition->>'category', '')) || '%'
        )
        else null
      end,
      case when ua.user_id is not null then coalesce((a.condition->>'value')::int, 0) else 0 end
    ) as current_value,
    coalesce((a.condition->>'value')::int, 0) as target_value
  from public.achievements a
  left join public.user_achievements ua
    on ua.achievement_id = a.id
   and ua.user_id = auth.uid()
  cross join metrics m
  where not coalesce(a.is_hidden, false)
     or ua.user_id is not null
  order by
    case when ua.user_id is not null then 0 else 1 end,
    coalesce(ua.unlocked_at, 'epoch'::timestamptz) desc,
    a.title asc;
$$;

create or replace function public.recompute_user_achievements_v1(
  p_user_id uuid
)
returns void
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  v_review_count int := 0;
  v_rating_count int := 0;
  v_business_view_count int := 0;
  v_unique_rated_count int := 0;
  v_price_verified_count int := 0;
  v_menu_photo_count int := 0;
  v_wrong_info_reports_count int := 0;
  v_reputation int := 0;
  v_top10 boolean := false;
  v_silent_views int := 0;
  v_night_views int := 0;
  v_serendipity_clicks int := 0;
  v_weekend_views int := 0;
  v_stale_updates int := 0;
  v_unique_menu_item_views int := 0;
  v_pizza_unique_rated_count int := 0;
  v_price_verified_streak_days int := 0;
  v_district_unique_rated_count int := 0;
  v_combo_review_price_photo int := 0;
begin
  if p_user_id is null then
    return;
  end if;

  if to_regclass('public.reviews') is not null then
    execute
      'select count(*) from public.reviews
       where user_id = $1
         and status = any($2)
         and coalesce((to_jsonb(reviews)->>''is_shadow'')::boolean, false) = false'
      into v_review_count using p_user_id, array['approved','published'];

    execute
      'select count(*) from public.reviews
       where user_id = $1
         and rating is not null
         and status = any($2)
         and coalesce((to_jsonb(reviews)->>''is_shadow'')::boolean, false) = false'
      into v_rating_count using p_user_id, array['approved','published'];

    execute
      'select count(distinct business_id) from public.reviews
       where user_id = $1
         and rating is not null
         and business_id is not null
         and status = any($2)
         and coalesce((to_jsonb(reviews)->>''is_shadow'')::boolean, false) = false'
      into v_unique_rated_count using p_user_id, array['approved','published'];

    if to_regclass('public.businesses') is not null then
      execute
        'select count(distinct r.business_id)
         from public.reviews r
         join public.businesses b on b.id = r.business_id
         where r.user_id = $1
           and r.rating is not null
           and r.business_id is not null
           and r.status = any($2)
           and coalesce((to_jsonb(r)->>''is_shadow'')::boolean, false) = false
           and lower(coalesce(b.category, '''')) like ''%pizza%'''
        into v_pizza_unique_rated_count using p_user_id, array['approved','published'];

      execute
        'select coalesce(max(cnt), 0)::int
         from (
           select count(distinct r.business_id)::int as cnt
           from public.reviews r
           join public.businesses b on b.id = r.business_id
           where r.user_id = $1
             and r.rating is not null
             and r.business_id is not null
             and r.status = any($2)
             and coalesce((to_jsonb(r)->>''is_shadow'')::boolean, false) = false
             and nullif(trim(b.district), '''') is not null
           group by b.district
         ) x'
        into v_district_unique_rated_count using p_user_id, array['approved','published'];
    end if;
  end if;

  if to_regclass('public.analytics_events') is not null then
    execute
      'select count(*) from public.analytics_events
       where user_id = $1 and event_name = any($2)'
      into v_business_view_count using p_user_id, array['discovery_business_click', 'business_view', 'business_page_view'];

    execute
      'select count(*) from public.analytics_events
       where user_id = $1
         and event_name = any($2)'
      into v_silent_views using p_user_id, array['discovery_business_click', 'business_page_view'];

    execute
      'select count(*) from public.analytics_events
       where user_id = $1
         and event_name = any($2)
         and extract(hour from (created_at at time zone ''Europe/Istanbul'')) between 0 and 3'
      into v_night_views using p_user_id, array['discovery_business_click', 'business_page_view'];

    execute
      'select count(*) from public.analytics_events
       where user_id = $1
         and event_name = ''discovery_business_click''
         and coalesce(source, '''') = any($2)'
      into v_serendipity_clicks using p_user_id, array['discover', 'serendipity', 'discover_list'];

    execute
      'select count(*) from public.analytics_events
       where user_id = $1
         and event_name = any($2)
         and extract(isodow from (created_at at time zone ''Europe/Istanbul'')) in (6,7)'
      into v_weekend_views using p_user_id, array['discovery_business_click', 'business_page_view'];

    execute
      'select count(distinct coalesce((meta->>''menu_item_id''), ''''))
       from public.analytics_events
       where user_id = $1
         and event_name = ''menu_view''
         and coalesce((meta->>''menu_item_id''), '''') <> '''''
      into v_unique_menu_item_views using p_user_id;
  end if;

  if to_regclass('public.menu_item_price_suggestions') is not null then
    execute
      'select count(*) from public.menu_item_price_suggestions s
       where s.created_by = $1
         and s.status = any($2)
         and coalesce((to_jsonb(s)->>''is_shadow'')::boolean, false) = false'
      into v_price_verified_count using p_user_id, array['approved','accepted','handled','verified'];

    execute
      'with verified_days as (
         select distinct (created_at at time zone ''Europe/Istanbul'')::date as d
         from public.menu_item_price_suggestions s
         where s.created_by = $1
           and s.status = any($2)
           and coalesce((to_jsonb(s)->>''is_shadow'')::boolean, false) = false
       ),
       grouped as (
         select d, d - (row_number() over(order by d))::int as grp
         from verified_days
       )
       select coalesce(max(streak_len), 0)::int
       from (
         select count(*)::int as streak_len
         from grouped
         group by grp
       ) s'
      into v_price_verified_streak_days using p_user_id, array['approved','accepted','handled','verified'];

    if to_regclass('public.menu_items') is not null then
      execute
        'select count(*) from public.menu_item_price_suggestions s
         join public.menu_items mi on mi.id = s.menu_item_id
         where s.created_by = $1
           and s.status = any($2)
           and coalesce((to_jsonb(s)->>''is_shadow'')::boolean, false) = false
           and mi.updated_at <= now() - interval ''365 days'''
        into v_stale_updates using p_user_id, array['approved','accepted','handled','verified'];
    end if;
  end if;

  if to_regclass('public.menu_item_photos') is not null then
    execute
      'select count(*) from public.menu_item_photos p
       where p.created_by = $1
         and coalesce((to_jsonb(p)->>''is_shadow'')::boolean, false) = false'
      into v_menu_photo_count using p_user_id;
  end if;

  if to_regclass('public.reports') is not null then
    execute
      'select count(*) from public.reports r
       where coalesce(r.user_id, r.reporter_user_id) = $1
         and coalesce(r.status, '''') = any($2)
         and coalesce((to_jsonb(r)->>''is_shadow'')::boolean, false) = false'
      into v_wrong_info_reports_count using p_user_id, array['kapandi', 'resolved', 'closed'];
  end if;

  v_combo_review_price_photo :=
    (case when v_review_count > 0 then 1 else 0 end) +
    (case when v_price_verified_count > 0 then 1 else 0 end) +
    (case when v_menu_photo_count > 0 then 1 else 0 end);

  v_reputation := public.get_user_reputation_score_v2(p_user_id);

  if to_regclass('public.reviews') is not null then
    execute $sql$
      with user_counts as (
        select
          b.district,
          r.user_id,
          count(*)::int as c
        from public.reviews r
        join public.businesses b on b.id = r.business_id
        where b.district is not null
          and r.status = any($2)
          and coalesce((to_jsonb(r)->>''is_shadow'')::boolean, false) = false
        group by b.district, r.user_id
      ),
      ranked as (
        select
          district,
          user_id,
          c,
          rank() over(partition by district order by c desc, user_id) as rnk,
          count(*) over(partition by district) as user_total
        from user_counts
      )
      select exists(
        select 1
        from ranked
        where user_id = $1
          and user_total >= 10
          and rnk <= greatest(1, ceil(user_total::numeric * 0.10)::int)
      )
    $sql$
    into v_top10 using p_user_id, array['approved','published'];
  end if;

  if v_review_count >= 1 then
    perform public.award_achievement_v1(p_user_id, 'first_review');
  end if;
  if v_rating_count >= 1 then
    perform public.award_achievement_v1(p_user_id, 'first_rating');
  end if;
  if v_business_view_count >= 1 then
    perform public.award_achievement_v1(p_user_id, 'first_discovery');
  end if;
  if v_unique_rated_count >= 10 then
    perform public.award_achievement_v1(p_user_id, 'traveler_10');
  end if;
  if v_price_verified_count >= 5 then
    perform public.award_achievement_v1(p_user_id, 'price_hunter_5');
  end if;
  if v_menu_photo_count >= 3 then
    perform public.award_achievement_v1(p_user_id, 'observer_3');
  end if;
  if v_wrong_info_reports_count >= 10 then
    perform public.award_achievement_v1(p_user_id, 'detective_10');
  end if;
  if v_reputation >= 80 then
    perform public.award_achievement_v1(p_user_id, 'trusted_contributor');
  end if;
  if v_top10 then
    perform public.award_achievement_v1(p_user_id, 'district_gourmet_top10');
  end if;
  if v_pizza_unique_rated_count >= 10 then
    perform public.award_achievement_v1(p_user_id, 'pizza_master_10');
  end if;
  if v_price_verified_streak_days >= 3 then
    perform public.award_achievement_v1(p_user_id, 'combo_price_streak_3');
  end if;
  if v_district_unique_rated_count >= 5 then
    perform public.award_achievement_v1(p_user_id, 'combo_district_master_5');
  end if;
  if v_combo_review_price_photo >= 3 then
    perform public.award_achievement_v1(p_user_id, 'combo_full_contributor');
  end if;

  -- Hidden achievements.
  if v_silent_views >= 20 and v_review_count = 0 then
    perform public.award_achievement_v1(p_user_id, 'silent_follower_20');
  end if;
  if v_night_views >= 5 then
    perform public.award_achievement_v1(p_user_id, 'night_gourmet_5');
  end if;
  if v_stale_updates >= 1 then
    perform public.award_achievement_v1(p_user_id, 'menu_archivist_1');
  end if;
  if v_serendipity_clicks >= 10 then
    perform public.award_achievement_v1(p_user_id, 'chance_hunter_10');
  end if;
  if v_weekend_views >= 8 then
    perform public.award_achievement_v1(p_user_id, 'weekend_wanderer_8');
  end if;
  if v_unique_menu_item_views >= 30 then
    perform public.award_achievement_v1(p_user_id, 'deep_menu_diver_30');
  end if;
end;
$$;



-- ===== END MIGRATION: 20260321000019_combo_achievements.sql =====

-- ===== BEGIN MIGRATION: 20260321000020_real_world_confidence.sql =====
alter table if exists public.menu_item_price_suggestions
  add column if not exists client_id text,
  add column if not exists captured_at timestamptz,
  add column if not exists onsite_verified boolean not null default false,
  add column if not exists onsite_signal text;

create index if not exists menu_item_price_suggestions_onsite_idx
  on public.menu_item_price_suggestions(menu_item_id, onsite_verified, created_at desc);

create or replace function public.submit_menu_item_price_suggestion_v3(
  p_menu_item_id uuid,
  p_suggested_price_cents integer,
  p_currency text default 'TRY',
  p_note text default null,
  p_evidence_url text default null,
  p_client_id text default null,
  p_captured_at timestamptz default now()
) returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_business_id uuid;
  v_result jsonb;
  v_client_id text := nullif(trim(coalesce(p_client_id, '')), '');
  v_captured_at timestamptz := coalesce(p_captured_at, now());
  v_recent_checkin boolean := false;
  v_onsite boolean := false;
  v_signal text := 'none';
begin
  select mi.business_id
    into v_business_id
  from public.menu_items mi
  where mi.id = p_menu_item_id
  limit 1;

  v_result := public.submit_menu_item_price_suggestion_v2(
    p_menu_item_id,
    p_suggested_price_cents,
    p_currency,
    p_note,
    p_evidence_url
  );

  if coalesce((v_result->>'ok')::boolean, false) is false then
    return v_result;
  end if;

  if v_business_id is not null and v_client_id is not null then
    v_recent_checkin := public.has_recent_checkin_v1(v_business_id, v_client_id, 180);
  end if;

  v_onsite := v_recent_checkin and v_captured_at >= (now() - interval '6 hours');
  v_signal := case
    when v_onsite then 'checkin_recent'
    when v_client_id is null then 'no_client_id'
    when not v_recent_checkin then 'checkin_missing'
    else 'stale_capture'
  end;

  update public.menu_item_price_suggestions s
  set client_id = coalesce(v_client_id, s.client_id),
      captured_at = v_captured_at,
      onsite_verified = v_onsite,
      onsite_signal = v_signal
  where s.id = (
    select x.id
    from public.menu_item_price_suggestions x
    where x.menu_item_id = p_menu_item_id
      and x.created_by = auth.uid()
    order by x.created_at desc
    limit 1
  );

  return v_result || jsonb_build_object(
    'onsite_verified', v_onsite,
    'onsite_signal', v_signal,
    'xp_multiplier', case when v_onsite then 1.25 else 1.0 end,
    'queue_priority', case when v_onsite then 'high' else 'normal' end
  );
end;
$$;

grant all on function public.submit_menu_item_price_suggestion_v3(uuid, integer, text, text, text, text, timestamptz) to anon;
grant all on function public.submit_menu_item_price_suggestion_v3(uuid, integer, text, text, text, text, timestamptz) to authenticated;
grant all on function public.submit_menu_item_price_suggestion_v3(uuid, integer, text, text, text, text, timestamptz) to service_role;

create or replace function public.get_menu_item_price_status_v1(p_menu_item_id uuid)
returns jsonb
language sql
stable
security definer
set search_path = public
as $$
  with votes as (
    select
      count(*) filter (where created_at >= now() - interval '30 days') as total_30d,
      count(*) filter (where vote = 1 and created_at >= now() - interval '30 days') as ok_30d,
      count(*) filter (where vote = -1 and created_at >= now() - interval '30 days') as bad_30d,
      (
        select vote
        from public.menu_item_price_votes
        where menu_item_id = p_menu_item_id and user_id = auth.uid()
        limit 1
      ) as my_vote
    from public.menu_item_price_votes
    where menu_item_id = p_menu_item_id
  ),
  latest as (
    select
      mi.price_cents,
      (
        select max(h.created_at)
        from public.menu_item_price_history h
        where h.menu_item_id = p_menu_item_id
      ) as last_verified_at
    from public.menu_items mi
    where mi.id = p_menu_item_id
    limit 1
  ),
  consensus as (
    select
      (count(distinct s.created_by) filter (
        where s.created_at >= now() - interval '48 hours'
          and s.status::text = any (array['approved', 'accepted', 'handled', 'verified'])
      ))::int as verified_sources_48h
    from public.menu_item_price_suggestions s
    where s.menu_item_id = p_menu_item_id
  )
  select jsonb_build_object(
    'total_30d', votes.total_30d,
    'ok_30d', votes.ok_30d,
    'bad_30d', votes.bad_30d,
    'my_vote', votes.my_vote,
    'price_cents', latest.price_cents,
    'last_verified_at', latest.last_verified_at,
    'verified_sources_48h', coalesce(consensus.verified_sources_48h, 0),
    'safe_to_trust',
      (
        coalesce(consensus.verified_sources_48h, 0) >= 3
        and coalesce(votes.ok_30d, 0) >= greatest(3, coalesce(votes.bad_30d, 0) * 2)
      ),
    'consensus_status',
      case
        when coalesce(consensus.verified_sources_48h, 0) >= 3
             and coalesce(votes.ok_30d, 0) >= greatest(3, coalesce(votes.bad_30d, 0) * 2)
          then 'strong'
        when coalesce(consensus.verified_sources_48h, 0) >= 2
             and coalesce(votes.ok_30d, 0) > coalesce(votes.bad_30d, 0)
          then 'moderate'
        when coalesce(votes.bad_30d, 0) >= 3
             and coalesce(votes.bad_30d, 0) >= coalesce(votes.ok_30d, 0)
          then 'conflicted'
        else 'weak'
      end,
    'confidence_score',
      greatest(
        0::numeric,
        least(
          1::numeric,
          (
            case
              when votes.total_30d <= 0 then 0.2
              else (votes.ok_30d::numeric / nullif(votes.total_30d, 0))
            end
          ) * 0.8
          +
          (
            case
              when votes.total_30d >= 12 then 0.2
              when votes.total_30d >= 6 then 0.12
              when votes.total_30d >= 3 then 0.06
              else 0
            end
          )
        )
      ),
    'status',
      case
        when votes.total_30d = 0 then 'unknown'
        when votes.ok_30d >= 3 and votes.ok_30d >= votes.bad_30d * 2 then 'verified'
        when votes.bad_30d >= 3 and votes.bad_30d > votes.ok_30d then 'outdated'
        else 'mixed'
      end
  )
  from votes
  left join latest on true
  left join consensus on true;
$$;

create or replace function public.get_business_reality_score_v1(
  p_business_id uuid
) returns jsonb
language sql
stable
security definer
set search_path = public
as $$
  with recent as (
    select
      (select count(*)::int
       from public.menu_item_price_history h
       join public.menu_items mi on mi.id = h.menu_item_id
       where mi.business_id = p_business_id
         and h.created_at >= now() - interval '30 days') as menu_updates_30d,
      (select count(*)::int
       from public.menu_item_price_suggestions s
       where s.business_id = p_business_id
         and s.status::text = any(array['approved', 'accepted', 'handled', 'verified'])
         and s.created_at >= now() - interval '30 days') as verified_prices_30d,
      (select count(*)::int
       from public.business_checkins c
       where c.business_id = p_business_id
         and c.created_at >= now() - interval '30 days') as checkins_30d,
      (select count(*)::int
       from public.business_media bm
       where bm.business_id = p_business_id
         and bm.created_at >= now() - interval '30 days') as fresh_media_30d,
      (select count(*)::int
       from public.owner_claims oc
       where oc.business_id = p_business_id
         and oc.status::text in ('approved', 'accepted')) as active_owner_claims
  ),
  points as (
    select
      least(30, recent.menu_updates_30d * 6) as p_menu,
      least(25, recent.verified_prices_30d * 5) as p_price,
      least(20, recent.checkins_30d * 2) as p_presence,
      least(15, recent.fresh_media_30d * 3) as p_media,
      case when recent.active_owner_claims > 0 then 10 else 0 end as p_owner,
      recent.*
    from recent
  )
  select jsonb_build_object(
    'score', greatest(0, least(100, points.p_menu + points.p_price + points.p_presence + points.p_media + points.p_owner)),
    'menu_updates_30d', points.menu_updates_30d,
    'verified_prices_30d', points.verified_prices_30d,
    'checkins_30d', points.checkins_30d,
    'fresh_media_30d', points.fresh_media_30d,
    'owner_active', (points.active_owner_claims > 0),
    'warning', case
      when (points.p_menu + points.p_price + points.p_presence + points.p_media + points.p_owner) < 40
        then 'Bilgi eski olabilir; son katkıları kontrol et.'
      else null
    end
  )
  from points;
$$;

grant all on function public.get_business_reality_score_v1(uuid) to anon;
grant all on function public.get_business_reality_score_v1(uuid) to authenticated;
grant all on function public.get_business_reality_score_v1(uuid) to service_role;

-- ===== END MIGRATION: 20260321000020_real_world_confidence.sql =====

-- ===== BEGIN MIGRATION: 20260321000021_real_alert_triggers.sql =====
-- Real alert trigger hardening: favorites only, meaningful delta, verified changes.

create or replace function public.check_price_alerts_for_item_v1(
  p_menu_item_id uuid,
  p_business_id uuid,
  p_item_name text,
  p_price_cents int,
  p_city text,
  p_district text,
  p_category text,
  p_previous_price_cents int default null,
  p_district_avg_price_cents int default null,
  p_is_verified_change boolean default true
)
returns void
language plpgsql
security definer
set search_path to 'public'
as $$
begin
  if coalesce(p_is_verified_change, false) is false then
    return;
  end if;

  -- Ignore noisy updates unless there is at least 10% delta.
  if p_previous_price_cents is not null
     and p_previous_price_cents > 0
     and p_price_cents > 0
     and abs(p_price_cents - p_previous_price_cents)::numeric / p_previous_price_cents::numeric < 0.10
  then
    return;
  end if;

  insert into public.alert_events (
    user_id,
    alert_id,
    business_id,
    menu_item_id,
    matched_price_cents,
    previous_price_cents,
    district_avg_price_cents
  )
  select
    a.user_id,
    a.id,
    p_business_id,
    p_menu_item_id,
    p_price_cents,
    p_previous_price_cents,
    p_district_avg_price_cents
  from public.price_alerts a
  where a.is_active = true
    and exists (
      select 1
      from public.favorites f
      where f.user_id = a.user_id
        and f.business_id = p_business_id
    )
    and (a.query is null or a.query = '' or p_item_name ilike '%' || a.query || '%')
    and (a.max_price_cents is null or p_price_cents <= a.max_price_cents)
    and (a.city is null or a.city = '' or a.city = p_city)
    and (a.district is null or a.district = '' or a.district = p_district)
    and (a.category is null or a.category = '' or a.category = p_category)
  on conflict do nothing;
end;
$$;

create or replace function public.handle_price_alerts_for_history_v1()
returns trigger
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  v_item_name text;
  v_business_id uuid;
  v_city text;
  v_district text;
  v_category text;
  v_price int;
  v_prev_price int;
  v_district_avg int;
  v_is_verified_change boolean := false;
begin
  if coalesce(new.source, '') not in ('suggestion', 'owner', 'admin', 'verified') then
    return new;
  end if;

  select mi.name, mi.business_id, b.city, b.district, b.category
    into v_item_name, v_business_id, v_city, v_district, v_category
  from public.menu_items mi
  join public.businesses b on b.id = mi.business_id
  where mi.id = new.menu_item_id;

  v_price := coalesce(new.new_price_cents, new.price_cents);
  if v_item_name is null or v_business_id is null or v_price is null then
    return new;
  end if;

  select h.price_cents
    into v_prev_price
  from public.menu_item_price_history h
  where h.menu_item_id = new.menu_item_id
    and h.created_at < new.created_at
  order by h.created_at desc
  limit 1;

  -- Verified change rule: trusted source OR an approved suggestion close to this update.
  v_is_verified_change := coalesce(new.source, '') in ('verified', 'admin', 'owner')
    or exists (
      select 1
      from public.menu_item_price_suggestions s
      where s.menu_item_id = new.menu_item_id
        and s.suggested_price_cents = v_price
        and s.status::text = any(array['approved', 'accepted', 'handled', 'verified'])
        and s.created_at >= new.created_at - interval '24 hours'
    );

  if v_is_verified_change is false then
    return new;
  end if;

  if v_prev_price is not null
     and v_prev_price > 0
     and abs(v_price - v_prev_price)::numeric / v_prev_price::numeric < 0.10
  then
    return new;
  end if;

  if coalesce(v_district, '') <> '' then
    select avg(h.price_cents)::int
      into v_district_avg
    from public.menu_item_price_history h
    join public.menu_items mi on mi.id = h.menu_item_id
    join public.businesses b on b.id = mi.business_id
    where lower(mi.name) = lower(v_item_name)
      and b.district = v_district
      and h.created_at >= now() - interval '30 days'
      and h.price_cents is not null;
  end if;

  perform public.check_price_alerts_for_item_v1(
    new.menu_item_id,
    v_business_id,
    v_item_name,
    v_price,
    v_city,
    v_district,
    v_category,
    v_prev_price,
    v_district_avg,
    v_is_verified_change
  );

  return new;
end;
$$;

create or replace function public.trg_notify_price_alert_event_v1()
returns trigger
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  v_business_name text;
  v_item_name text;
begin
  if tg_op <> 'INSERT' then
    return new;
  end if;

  select b.name into v_business_name
  from public.businesses b
  where b.id = new.business_id;

  select mi.name into v_item_name
  from public.menu_items mi
  where mi.id = new.menu_item_id;

  perform public.notify_user_v1(
    new.user_id,
    'favorite_price_changed',
    '⚠️ Fiyat değişimi',
    coalesce(v_business_name, 'İşletme') || ' mekanında ' || coalesce(v_item_name, 'ürün') || ' fiyatı değişti.',
    jsonb_build_object(
      'business_id', new.business_id,
      'menu_item_id', new.menu_item_id,
      'alert_event_id', new.id,
      'matched_price_cents', new.matched_price_cents,
      'previous_price_cents', new.previous_price_cents,
      'district_avg_price_cents', new.district_avg_price_cents,
      'meaningful_change', true,
      'verified_change', true
    )
  );

  return new;
end;
$$;

-- ===== END MIGRATION: 20260321000021_real_alert_triggers.sql =====

-- ===== BEGIN MIGRATION: 20260321000022_owner_pressure_features.sql =====
create or replace function public.get_chain_overview_v2(
  p_chain_id uuid,
  p_lat double precision default null,
  p_lng double precision default null,
  p_limit integer default 20
) returns table(
  chain_id uuid,
  chain_name text,
  chain_description text,
  business_id uuid,
  business_name text,
  branch_label text,
  city text,
  district text,
  address text,
  is_open_now boolean,
  distance_km double precision,
  avg_price_cents integer,
  chain_avg_price_cents integer,
  price_delta_pct numeric
)
language sql
stable
security definer
set search_path = public
as $$
  with branch_prices as (
    select
      b.id as business_id,
      percentile_disc(0.5) within group (order by mi.price_cents)::int as avg_price_cents
    from public.businesses b
    left join public.menu_items mi
      on mi.business_id = b.id
     and mi.price_cents is not null
     and mi.price_cents > 0
    where b.chain_id = p_chain_id
      and b.is_active = true
    group by b.id
  ),
  chain_price as (
    select
      percentile_disc(0.5) within group (order by bp.avg_price_cents)::int as chain_avg_price_cents
    from branch_prices bp
    where bp.avg_price_cents is not null
  )
  select
    ch.id as chain_id,
    ch.name as chain_name,
    ch.description as chain_description,
    b.id as business_id,
    b.name as business_name,
    coalesce(b.branch_label, '') as branch_label,
    b.city,
    b.district,
    b.address,
    null::boolean as is_open_now,
    case
      when p_lat is null or p_lng is null or b.lat is null or b.lng is null then null
      else round((st_distance(
        st_setsrid(st_makepoint(p_lng, p_lat), 4326)::geography,
        st_setsrid(st_makepoint(b.lng, b.lat), 4326)::geography
      ) / 1000.0)::numeric, 2)::double precision
    end as distance_km,
    bp.avg_price_cents,
    cp.chain_avg_price_cents,
    case
      when cp.chain_avg_price_cents is null or cp.chain_avg_price_cents <= 0 or bp.avg_price_cents is null
        then null
      else round((((bp.avg_price_cents - cp.chain_avg_price_cents)::numeric / cp.chain_avg_price_cents::numeric) * 100), 1)
    end as price_delta_pct
  from public.businesses b
  join public.chains ch on ch.id = b.chain_id
  left join branch_prices bp on bp.business_id = b.id
  left join chain_price cp on true
  where b.chain_id = p_chain_id
    and b.is_active = true
  order by
    case when p_lat is null or p_lng is null then null else
      st_distance(
        st_setsrid(st_makepoint(p_lng, p_lat), 4326)::geography,
        st_setsrid(st_makepoint(b.lng, b.lat), 4326)::geography
      )
    end asc nulls last,
    b.name asc
  limit greatest(p_limit, 1);
$$;

grant all on function public.get_chain_overview_v2(uuid, double precision, double precision, integer) to anon;
grant all on function public.get_chain_overview_v2(uuid, double precision, double precision, integer) to authenticated;
grant all on function public.get_chain_overview_v2(uuid, double precision, double precision, integer) to service_role;

create or replace function public.analytics_growth_v3(
  p_days integer default 30,
  p_business_id uuid default null
) returns table(
  day date,
  menu_link_opened integer,
  qr_scanned integer,
  menu_shared integer,
  app_install_from_menu integer,
  business_reservation_click integer,
  business_order_click integer,
  business_whatsapp_click integer,
  business_phone_click integer,
  price_dropoff_estimate integer,
  district_price_gap_pct numeric,
  district_price_position text
)
language plpgsql
security definer
set search_path = public
as $$
begin
  if not public.is_admin() then
    if p_business_id is null or not public.is_owner_of_business(p_business_id) then
      raise exception 'not authorized';
    end if;
  end if;

  return query
  with events as (
    select
      d.day::date as day,
      sum(case when e.event_name = 'menu_link_opened' then 1 else 0 end)::int as menu_link_opened,
      sum(case when e.event_name = 'qr_scanned' then 1 else 0 end)::int as qr_scanned,
      sum(case when e.event_name = 'menu_shared' then 1 else 0 end)::int as menu_shared,
      sum(case when e.event_name = 'app_install_from_menu' then 1 else 0 end)::int as app_install_from_menu,
      sum(case when e.event_name = 'business_reservation_click' then 1 else 0 end)::int as business_reservation_click,
      sum(case when e.event_name = 'business_order_click' then 1 else 0 end)::int as business_order_click,
      sum(case when e.event_name = 'business_whatsapp_click' then 1 else 0 end)::int as business_whatsapp_click,
      sum(case when e.event_name = 'business_phone_click' then 1 else 0 end)::int as business_phone_click
    from generate_series(
      (current_date - greatest(p_days, 1) + 1)::date,
      current_date::date,
      interval '1 day'
    ) as d(day)
    left join public.analytics_events e
      on date_trunc('day', e.created_at) = d.day
     and (p_business_id is null or e.business_id = p_business_id)
    group by d.day
  ),
  business_ctx as (
    select
      b.id,
      b.city,
      b.district
    from public.businesses b
    where b.id = p_business_id
    limit 1
  ),
  business_price as (
    select percentile_disc(0.5) within group (order by mi.price_cents)::numeric as median_price_cents
    from public.menu_items mi
    where mi.business_id = p_business_id
      and mi.price_cents is not null
      and mi.price_cents > 0
  ),
  district_price as (
    select percentile_disc(0.5) within group (order by mi.price_cents)::numeric as median_price_cents
    from business_ctx bc
    join public.businesses b on b.city = bc.city and b.district = bc.district and b.is_active = true
    join public.menu_items mi on mi.business_id = b.id
    where mi.price_cents is not null
      and mi.price_cents > 0
  ),
  gap as (
    select
      case
        when bp.median_price_cents is null or dp.median_price_cents is null or dp.median_price_cents <= 0
          then null
        else round((((bp.median_price_cents - dp.median_price_cents) / dp.median_price_cents) * 100)::numeric, 1)
      end as district_price_gap_pct
    from business_price bp
    cross join district_price dp
  )
  select
    e.day,
    e.menu_link_opened,
    e.qr_scanned,
    e.menu_shared,
    e.app_install_from_menu,
    e.business_reservation_click,
    e.business_order_click,
    e.business_whatsapp_click,
    e.business_phone_click,
    greatest(
      0,
      round(
        greatest(
          0,
          e.menu_link_opened - (
            e.business_reservation_click +
            e.business_order_click +
            e.business_whatsapp_click +
            e.business_phone_click
          )
        ) * case
          when gap.district_price_gap_pct is null then 0.10
          when gap.district_price_gap_pct <= 0 then 0.08
          else least(0.65, gap.district_price_gap_pct / 100.0)
        end
      )::int
    ) as price_dropoff_estimate,
    gap.district_price_gap_pct,
    case
      when gap.district_price_gap_pct is null then 'unknown'
      when gap.district_price_gap_pct >= 8 then 'higher'
      when gap.district_price_gap_pct <= -8 then 'lower'
      else 'similar'
    end as district_price_position
  from events e
  left join gap on true
  order by e.day;
end;
$$;

grant all on function public.analytics_growth_v3(integer, uuid) to anon;
grant all on function public.analytics_growth_v3(integer, uuid) to authenticated;
grant all on function public.analytics_growth_v3(integer, uuid) to service_role;

-- ===== END MIGRATION: 20260321000022_owner_pressure_features.sql =====

-- ===== BEGIN MIGRATION: 20260321000023_data_moat_analytics.sql =====
create or replace function public.get_business_price_history_v1(
  p_business_id uuid,
  p_days integer default 60,
  p_limit integer default 120
) returns table(
  business_id uuid,
  menu_item_id uuid,
  menu_item_name text,
  price_cents integer,
  changed_at timestamptz
)
language sql
stable
security definer
set search_path = public
as $$
  select
    mi.business_id,
    h.menu_item_id,
    mi.name as menu_item_name,
    h.price_cents,
    h.created_at as changed_at
  from public.menu_item_price_history h
  join public.menu_items mi on mi.id = h.menu_item_id
  where mi.business_id = p_business_id
    and h.price_cents is not null
    and h.price_cents > 0
    and h.created_at >= now() - make_interval(days => greatest(p_days, 1))
  order by h.created_at desc
  limit greatest(p_limit, 1);
$$;

grant all on function public.get_business_price_history_v1(uuid, integer, integer) to anon;
grant all on function public.get_business_price_history_v1(uuid, integer, integer) to authenticated;
grant all on function public.get_business_price_history_v1(uuid, integer, integer) to service_role;

create or replace function public.get_regional_price_index_v2(
  p_city text default null,
  p_district text default null,
  p_limit integer default 12
) returns table(
  category text,
  median_price_cents integer,
  avg_price_cents integer,
  sample_count integer,
  updated_in_30d integer
)
language sql
stable
security definer
set search_path = public
as $$
  with base as (
    select
      b.category,
      mi.price_cents,
      mi.updated_at
    from public.menu_items mi
    join public.businesses b on b.id = mi.business_id
    where b.is_active = true
      and mi.price_cents is not null
      and mi.price_cents > 0
      and (p_city is null or b.city = p_city)
      and (p_district is null or b.district = p_district)
  )
  select
    coalesce(category, 'Genel') as category,
    percentile_disc(0.5) within group (order by price_cents)::int as median_price_cents,
    round(avg(price_cents))::int as avg_price_cents,
    count(*)::int as sample_count,
    count(*) filter (where updated_at >= now() - interval '30 days')::int as updated_in_30d
  from base
  group by category
  order by median_price_cents desc nulls last
  limit greatest(p_limit, 1);
$$;

grant all on function public.get_regional_price_index_v2(text, text, integer) to anon;
grant all on function public.get_regional_price_index_v2(text, text, integer) to authenticated;
grant all on function public.get_regional_price_index_v2(text, text, integer) to service_role;

create or replace function public.get_menu_price_anomalies_v1(
  p_city text default null,
  p_district text default null,
  p_days integer default 30,
  p_min_change_pct numeric default 40,
  p_limit integer default 20
) returns table(
  business_id uuid,
  business_name text,
  menu_item_id uuid,
  menu_item_name text,
  city text,
  district text,
  first_price_cents integer,
  last_price_cents integer,
  change_pct numeric,
  last_changed_at timestamptz
)
language sql
stable
security definer
set search_path = public
as $$
  with hist as (
    select
      b.id as business_id,
      b.name as business_name,
      b.city,
      b.district,
      h.menu_item_id,
      mi.name as menu_item_name,
      h.price_cents,
      h.created_at,
      row_number() over (partition by h.menu_item_id order by h.created_at asc) as rn_first,
      row_number() over (partition by h.menu_item_id order by h.created_at desc) as rn_last
    from public.menu_item_price_history h
    join public.menu_items mi on mi.id = h.menu_item_id
    join public.businesses b on b.id = mi.business_id
    where h.created_at >= now() - make_interval(days => greatest(p_days, 1))
      and h.price_cents is not null
      and h.price_cents > 0
      and b.is_active = true
      and (p_city is null or b.city = p_city)
      and (p_district is null or b.district = p_district)
  ),
  first_last as (
    select
      business_id,
      business_name,
      city,
      district,
      menu_item_id,
      menu_item_name,
      max(case when rn_first = 1 then price_cents end)::int as first_price_cents,
      max(case when rn_last = 1 then price_cents end)::int as last_price_cents,
      max(case when rn_last = 1 then created_at end) as last_changed_at
    from hist
    group by business_id, business_name, city, district, menu_item_id, menu_item_name
  )
  select
    fl.business_id,
    fl.business_name,
    fl.menu_item_id,
    fl.menu_item_name,
    fl.city,
    fl.district,
    fl.first_price_cents,
    fl.last_price_cents,
    round((((fl.last_price_cents - fl.first_price_cents)::numeric / nullif(fl.first_price_cents, 0)::numeric) * 100), 1) as change_pct,
    fl.last_changed_at
  from first_last fl
  where fl.first_price_cents is not null
    and fl.last_price_cents is not null
    and fl.first_price_cents > 0
    and abs(((fl.last_price_cents - fl.first_price_cents)::numeric / fl.first_price_cents::numeric) * 100) >= greatest(p_min_change_pct, 1)
  order by abs(((fl.last_price_cents - fl.first_price_cents)::numeric / fl.first_price_cents::numeric) * 100) desc
  limit greatest(p_limit, 1);
$$;

grant all on function public.get_menu_price_anomalies_v1(text, text, integer, numeric, integer) to anon;
grant all on function public.get_menu_price_anomalies_v1(text, text, integer, numeric, integer) to authenticated;
grant all on function public.get_menu_price_anomalies_v1(text, text, integer, numeric, integer) to service_role;

create or replace function public.admin_export_price_anomalies_csv_v1(
  p_days int default 30,
  p_threshold_pct numeric default 40
) returns text
language plpgsql
security definer
set search_path = public
as $$
declare
  v_csv text;
begin
  if not public.is_admin() then
    raise exception 'not authorized';
  end if;

  with rows as (
    select *
    from public.get_menu_price_anomalies_v1(
      p_city => null,
      p_district => null,
      p_days => p_days,
      p_min_change_pct => p_threshold_pct,
      p_limit => 5000
    )
  )
  select
    'business_name,city,district,menu_item_name,first_price_cents,last_price_cents,change_pct,last_changed_at' || E'\n' ||
    coalesce(
      string_agg(
        format(
          '%s,%s,%s,%s,%s,%s,%s,%s',
          replace(coalesce(r.business_name, ''), ',', ' '),
          replace(coalesce(r.city, ''), ',', ' '),
          replace(coalesce(r.district, ''), ',', ' '),
          replace(coalesce(r.menu_item_name, ''), ',', ' '),
          coalesce(r.first_price_cents::text, ''),
          coalesce(r.last_price_cents::text, ''),
          coalesce(r.change_pct::text, ''),
          coalesce(to_char(r.last_changed_at, 'YYYY-MM-DD HH24:MI:SS'), '')
        ),
        E'\n'
      ),
      ''
    )
  into v_csv
  from rows r;

  return v_csv;
end;
$$;

grant all on function public.admin_export_price_anomalies_csv_v1(integer, numeric) to anon;
grant all on function public.admin_export_price_anomalies_csv_v1(integer, numeric) to authenticated;
grant all on function public.admin_export_price_anomalies_csv_v1(integer, numeric) to service_role;

-- ===== END MIGRATION: 20260321000023_data_moat_analytics.sql =====

-- ===== BEGIN MIGRATION: 20260321000024_moat_trust_graph.sql =====
-- Moat signals: trust graph, behavior segment, and silent quality score.

create or replace function public.get_my_trust_graph_v1()
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user uuid := auth.uid();
  v_price_approved int := 0;
  v_price_rejected int := 0;
  v_review_published int := 0;
  v_review_rejected int := 0;
  v_report_resolved int := 0;
  v_report_rejected int := 0;
  v_spam_signals int := 0;
  v_accuracy numeric := 0;
  v_trust int := 0;
begin
  if v_user is null then
    return jsonb_build_object(
      'trusted_actions', 0,
      'rejected_actions', 0,
      'spam_signals', 0,
      'accuracy_score', 0,
      'trust_score', 0
    );
  end if;

  if to_regclass('public.menu_item_price_suggestions') is not null then
    select
      count(*) filter (where status = any(array['approved','accepted','handled','verified'])),
      count(*) filter (where status = 'rejected')
    into v_price_approved, v_price_rejected
    from public.menu_item_price_suggestions
    where created_by = v_user;
  end if;

  if to_regclass('public.reviews') is not null then
    select
      count(*) filter (where status = any(array['approved','published'])),
      count(*) filter (where status = 'rejected')
    into v_review_published, v_review_rejected
    from public.reviews
    where user_id = v_user;
  end if;

  if to_regclass('public.reports') is not null then
    select
      count(*) filter (where status = any(array['resolved','handled','accepted'])),
      count(*) filter (where status = 'rejected')
    into v_report_resolved, v_report_rejected
    from public.reports
    where created_by = v_user;
  end if;

  if to_regclass('public.user_rate_limits') is not null then
    select count(*)
      into v_spam_signals
    from public.user_rate_limits
    where user_id = v_user
      and day >= current_date - 30
      and action in (
        'review_submit',
        'price_suggestion_submit',
        'business_media_upload',
        'menu_photo_upload'
      )
      and count >= 10;
  end if;

  v_accuracy :=
    (
      (v_price_approved + v_review_published + v_report_resolved)::numeric /
      nullif(
        (v_price_approved + v_review_published + v_report_resolved + v_price_rejected + v_review_rejected + v_report_rejected),
        0
      )::numeric
    );
  if v_accuracy is null then
    v_accuracy := 0;
  end if;

  v_trust := round(
    least(
      100::numeric,
      greatest(
        0::numeric,
        (v_accuracy * 70) +
        least(20, (v_price_approved + v_review_published + v_report_resolved)) -
        least(30, v_spam_signals * 6)
      )
    )
  )::int;

  return jsonb_build_object(
    'trusted_actions', (v_price_approved + v_review_published + v_report_resolved),
    'rejected_actions', (v_price_rejected + v_review_rejected + v_report_rejected),
    'spam_signals', v_spam_signals,
    'accuracy_score', round(v_accuracy * 100),
    'trust_score', v_trust
  );
end;
$$;

grant all on function public.get_my_trust_graph_v1() to anon;
grant all on function public.get_my_trust_graph_v1() to authenticated;
grant all on function public.get_my_trust_graph_v1() to service_role;

create or replace function public.get_my_behavior_segment_v1()
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user uuid := auth.uid();
  v_price_actions int := 0;
  v_discovery_actions int := 0;
  v_photo_actions int := 0;
  v_total int := 0;
  v_primary text := 'balanced';
begin
  if v_user is null then
    return jsonb_build_object(
      'primary_segment', 'balanced',
      'price_actions', 0,
      'discovery_actions', 0,
      'photo_actions', 0
    );
  end if;

  if to_regclass('public.menu_item_price_votes') is not null then
    select count(*) into v_price_actions
    from public.menu_item_price_votes
    where user_id = v_user
      and created_at >= now() - interval '90 days';
  end if;

  if to_regclass('public.analytics_events') is not null then
    select count(*) into v_discovery_actions
    from public.analytics_events
    where user_id = v_user
      and created_at >= now() - interval '90 days'
      and event_name in ('discovery_business_click', 'business_page_view', 'menu_link_opened');
  end if;

  if to_regclass('public.business_media') is not null then
    select count(*) into v_photo_actions
    from public.business_media
    where created_by = v_user
      and created_at >= now() - interval '90 days';
  end if;

  v_total := v_price_actions + v_discovery_actions + v_photo_actions;
  if v_total = 0 then
    v_primary := 'balanced';
  elsif v_price_actions >= v_discovery_actions and v_price_actions >= v_photo_actions then
    v_primary := 'price_hunter';
  elsif v_photo_actions >= v_discovery_actions and v_photo_actions >= v_price_actions then
    v_primary := 'photo_proof';
  else
    v_primary := 'explorer';
  end if;

  return jsonb_build_object(
    'primary_segment', v_primary,
    'price_actions', v_price_actions,
    'discovery_actions', v_discovery_actions,
    'photo_actions', v_photo_actions
  );
end;
$$;

grant all on function public.get_my_behavior_segment_v1() to anon;
grant all on function public.get_my_behavior_segment_v1() to authenticated;
grant all on function public.get_my_behavior_segment_v1() to service_role;

create or replace function public.get_my_silent_quality_score_v1()
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user uuid := auth.uid();
  v_contribution_count int := 0;
  v_approved_count int := 0;
  v_review_count int := 0;
  v_score int := 0;
begin
  if v_user is null then
    return jsonb_build_object(
      'silent_quality_score', 0,
      'is_silent_quality', false,
      'approved_count', 0,
      'contribution_count', 0
    );
  end if;

  if to_regclass('public.menu_item_price_suggestions') is not null then
    select
      count(*),
      count(*) filter (where status = any(array['approved','accepted','handled','verified']))
    into v_contribution_count, v_approved_count
    from public.menu_item_price_suggestions
    where created_by = v_user
      and created_at >= now() - interval '180 days';
  end if;

  if to_regclass('public.reviews') is not null then
    select count(*)
      into v_review_count
    from public.reviews
    where user_id = v_user
      and created_at >= now() - interval '180 days';
  end if;

  v_score := round(
    least(
      100::numeric,
      greatest(
        0::numeric,
        (
          (coalesce(v_approved_count, 0)::numeric / nullif(v_contribution_count, 0)::numeric) * 80
        ) + least(20, v_approved_count)
      )
    )
  )::int;
  if v_contribution_count = 0 then
    v_score := 0;
  end if;

  return jsonb_build_object(
    'silent_quality_score', v_score,
    'is_silent_quality', (v_review_count <= 2 and v_approved_count >= 5 and v_score >= 70),
    'approved_count', v_approved_count,
    'contribution_count', v_contribution_count
  );
end;
$$;

grant all on function public.get_my_silent_quality_score_v1() to anon;
grant all on function public.get_my_silent_quality_score_v1() to authenticated;
grant all on function public.get_my_silent_quality_score_v1() to service_role;

-- ===== END MIGRATION: 20260321000024_moat_trust_graph.sql =====

-- ===== BEGIN MIGRATION: 20260321000200_canonical_reports_rpc_v2.sql =====
-- Canonical report RPC surface.
-- Adds status-based wrappers without breaking existing p_durum/v3-v4 callers.

create or replace function public.admin_update_report_v2(
  p_report_id uuid,
  p_status text,
  p_admin_note text default null
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  perform public.admin_update_report_v1(
    p_report_id => p_report_id,
    p_durum => p_status,
    p_admin_note => p_admin_note
  );
end;
$$;

create or replace function public.admin_bulk_update_reports_status_v2(
  p_report_ids uuid[],
  p_status text,
  p_admin_note text default null
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
begin
  return public.admin_bulk_update_reports_status_v1(
    p_report_ids => p_report_ids,
    p_durum => p_status,
    p_admin_note => p_admin_note
  );
end;
$$;

create or replace function public.admin_list_reports_v5(
  p_status text default null,
  p_limit integer default 50,
  p_offset integer default 0,
  p_q text default null,
  p_assigned text default null,
  p_sla_only boolean default false
)
returns table(
  id uuid,
  created_at timestamptz,
  status text,
  reason text,
  details text,
  user_id uuid,
  business_id uuid,
  review_id uuid,
  menu_item_photo_id uuid,
  target_type text,
  target_id uuid,
  assigned_to uuid,
  assigned_at timestamptz,
  handled_by uuid,
  handled_at timestamptz,
  admin_note text,
  age_hours double precision,
  sla_breached boolean
)
language sql
security definer
set search_path = public
as $$
  select
    r.id,
    r.created_at,
    r.durum as status,
    r.reason,
    r.details,
    r.user_id,
    r.business_id,
    r.review_id,
    r.menu_item_photo_id,
    r.target_type,
    r.target_id,
    r.assigned_to,
    r.assigned_at,
    r.handled_by,
    r.handled_at,
    r.admin_note,
    r.age_hours,
    r.sla_breached
  from public.admin_list_reports_v4(
    p_status => p_status,
    p_limit => p_limit,
    p_offset => p_offset,
    p_q => p_q,
    p_assigned => p_assigned,
    p_sla_only => p_sla_only
  ) as r;
$$;

-- ===== END MIGRATION: 20260321000200_canonical_reports_rpc_v2.sql =====

-- ===== BEGIN MIGRATION: 20260321000300_drop_menu_categories_sort_legacy.sql =====
-- Drop legacy menu_categories.sort after full canonical migration to sort_order.
-- Safe order: trigger -> sync function -> legacy index -> legacy column.

do $$
begin
  if exists (
    select 1
    from pg_trigger t
    join pg_class c on c.oid = t.tgrelid
    join pg_namespace n on n.oid = c.relnamespace
    where n.nspname = 'public'
      and c.relname = 'menu_categories'
      and t.tgname = 'trg_menu_categories_sync_sort_columns'
      and not t.tgisinternal
  ) then
    execute 'drop trigger trg_menu_categories_sync_sort_columns on public.menu_categories';
  end if;
end $$;

drop function if exists public.menu_categories_sync_sort_columns_v1();

drop index if exists public.idx_menu_categories_business_id;

alter table if exists public.menu_categories
  drop column if exists sort;

-- ===== END MIGRATION: 20260321000300_drop_menu_categories_sort_legacy.sql =====

-- ===== BEGIN MIGRATION: 20260321000400_canonical_reports_drop_legacy.sql =====
-- Canonicalize reports RPC surface and remove legacy function versions.
-- Keep only:
--   - admin_list_reports_v5
--   - admin_update_report_v2
--   - admin_bulk_update_reports_status_v2

create or replace function public.admin_update_report_v2(
  p_report_id uuid,
  p_status text,
  p_admin_note text default null
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_status text;
begin
  if not public.is_admin() then
    raise exception 'not_admin';
  end if;

  v_status := case
    when p_status in ('acik','open') then 'open'
    when p_status in ('inceleniyor','reviewing') then 'reviewing'
    when p_status in ('kapandi','closed','reddedildi','rejected') then 'closed'
    else 'open'
  end;

  update public.reports
  set
    status = v_status,
    handled_by = auth.uid(),
    handled_at = now(),
    admin_note = p_admin_note
  where id = p_report_id;

  perform public.log_admin_action_v1(
    'report.update',
    'reports',
    p_report_id,
    jsonb_build_object('status', v_status, 'admin_note', p_admin_note)
  );
end;
$$;

create or replace function public.admin_bulk_update_reports_status_v2(
  p_report_ids uuid[],
  p_status text,
  p_admin_note text default null
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_count int;
  v_status text;
begin
  if not public.is_admin() then
    raise exception 'not_admin';
  end if;

  v_status := case
    when p_status in ('acik','open') then 'open'
    when p_status in ('inceleniyor','reviewing') then 'reviewing'
    when p_status in ('kapandi','closed','reddedildi','rejected') then 'closed'
    else 'open'
  end;

  update public.reports
  set
    status = v_status,
    handled_by = auth.uid(),
    handled_at = now(),
    admin_note = coalesce(p_admin_note, admin_note)
  where id = any(p_report_ids);

  get diagnostics v_count = row_count;

  perform public.log_admin_action_v1(
    'report.bulk_update',
    'reports',
    null,
    jsonb_build_object('status', v_status, 'count', v_count)
  );

  return jsonb_build_object('ok', true, 'updated', v_count);
end;
$$;

create or replace function public.admin_list_reports_v5(
  p_status text default null,
  p_limit integer default 50,
  p_offset integer default 0,
  p_q text default null,
  p_assigned text default null,
  p_sla_only boolean default false
)
returns table(
  id uuid,
  created_at timestamptz,
  status text,
  reason text,
  details text,
  user_id uuid,
  business_id uuid,
  review_id uuid,
  menu_item_photo_id uuid,
  target_type text,
  target_id uuid,
  assigned_to uuid,
  assigned_at timestamptz,
  handled_by uuid,
  handled_at timestamptz,
  admin_note text,
  age_hours double precision,
  sla_breached boolean
)
language sql
security definer
set search_path = public
as $$
  with params as (
    select case
      when p_status in ('acik','open') then 'open'
      when p_status in ('inceleniyor','reviewing') then 'reviewing'
      when p_status in ('kapandi','closed','reddedildi','rejected') then 'closed'
      else null
    end as status_filter
  ),
  base as (
    select
      r.*,
      (extract(epoch from (now() - r.created_at))/3600.0)::float as age_hours,
      (
        r.handled_at is null
        and r.status in ('open','reviewing')
        and r.created_at < now() - interval '24 hours'
      ) as sla_breached
    from public.reports r
    cross join params p
    where public.is_admin_or_community_mod_v1()
      and (p.status_filter is null or r.status = p.status_filter)
      and (
        p_assigned is null
        or (p_assigned='me' and r.assigned_to = auth.uid())
        or (p_assigned='unassigned' and r.assigned_to is null)
      )
      and (
        p_q is null
        or r.reason ilike ('%'||p_q||'%')
        or r.details ilike ('%'||p_q||'%')
        or r.admin_note ilike ('%'||p_q||'%')
      )
  )
  select
    id, created_at, status, reason, details, user_id, business_id, review_id,
    menu_item_photo_id, target_type, target_id,
    assigned_to, assigned_at, handled_by, handled_at, admin_note,
    age_hours, sla_breached
  from base
  where (not p_sla_only) or sla_breached
  order by sla_breached desc, created_at desc
  limit greatest(p_limit, 1)
  offset greatest(p_offset, 0);
$$;

drop function if exists public.admin_list_reports_v4(text, integer, integer, text, text, boolean);
drop function if exists public.admin_list_reports_v3(text, integer, integer, text, text, boolean);
drop function if exists public.admin_list_reports_v2(text, integer, integer, text, text);
drop function if exists public.admin_list_reports_v1(text, integer, integer, text);
drop function if exists public.admin_update_report_v1(uuid, text, text);
drop function if exists public.admin_bulk_update_reports_status_v1(uuid[], text, text);

-- ===== END MIGRATION: 20260321000400_canonical_reports_drop_legacy.sql =====

-- ===== BEGIN MIGRATION: 20260321000500_drop_user_favorites_view.sql =====
-- Remove legacy compatibility view. Canonical source is public.favorites table.
drop view if exists public.user_favorites;

-- ===== END MIGRATION: 20260321000500_drop_user_favorites_view.sql =====

-- ===== BEGIN MIGRATION: 20260322000001_auth_session_device_security.sql =====
create or replace function public.register_user_device_v1(
  p_fcm_token text,
  p_platform text,
  p_app_version text default null
)
returns uuid
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  v_user_id uuid := auth.uid();
  v_id uuid;
begin
  if v_user_id is null then
    raise exception 'not_authenticated';
  end if;
  if coalesce(trim(p_fcm_token), '') = '' then
    raise exception 'invalid_token';
  end if;
  if coalesce(trim(p_platform), '') = '' then
    raise exception 'invalid_platform';
  end if;

  insert into public.user_devices(user_id, fcm_token, platform, app_version, last_seen_at)
  values (
    v_user_id,
    trim(p_fcm_token),
    lower(trim(p_platform)),
    nullif(trim(coalesce(p_app_version, '')), ''),
    now()
  )
  on conflict (user_id, fcm_token)
  do update set
    platform = excluded.platform,
    app_version = excluded.app_version,
    last_seen_at = now()
  returning id into v_id;

  delete from public.user_devices d
  where d.user_id = v_user_id
    and (
      d.last_seen_at < now() - interval '120 days'
      or d.id in (
        select stale.id
        from public.user_devices stale
        where stale.user_id = v_user_id
        order by stale.last_seen_at desc
        offset 10
      )
    );

  return v_id;
end;
$$;

create or replace function public.unregister_user_device_v1(
  p_fcm_token text default null
)
returns int
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  v_user_id uuid := auth.uid();
  v_count int := 0;
begin
  if v_user_id is null then
    raise exception 'not_authenticated';
  end if;

  if coalesce(trim(coalesce(p_fcm_token, '')), '') = '' then
    update public.user_devices
    set last_seen_at = now() - interval '365 days'
    where user_id = v_user_id;
    get diagnostics v_count = row_count;
    return v_count;
  end if;

  delete from public.user_devices
  where user_id = v_user_id
    and fcm_token = trim(p_fcm_token);
  get diagnostics v_count = row_count;
  return v_count;
end;
$$;

grant execute on function public.unregister_user_device_v1(text) to authenticated;

create or replace function public.trg_require_verified_contact_v1()
returns trigger
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  v_user_id uuid;
  v_role text := current_setting('request.jwt.claim.role', true);
  v_is_verified boolean := false;
begin
  if v_role = 'service_role' then
    return new;
  end if;

  if auth.uid() is null then
    return new;
  end if;

  v_user_id := coalesce(new.user_id, new.created_by, auth.uid());
  if v_user_id is null then
    raise exception 'contact_verification_required';
  end if;

  select
    (u.email_confirmed_at is not null or u.phone_confirmed_at is not null)
  into v_is_verified
  from auth.users u
  where u.id = v_user_id;

  if coalesce(v_is_verified, false) = false then
    raise exception 'contact_verification_required';
  end if;

  return new;
end;
$$;

drop trigger if exists trg_reviews_require_verified_contact_v1 on public.reviews;
create trigger trg_reviews_require_verified_contact_v1
before insert on public.reviews
for each row
execute function public.trg_require_verified_contact_v1();

drop trigger if exists trg_price_suggestions_require_verified_contact_v1 on public.menu_item_price_suggestions;
create trigger trg_price_suggestions_require_verified_contact_v1
before insert on public.menu_item_price_suggestions
for each row
execute function public.trg_require_verified_contact_v1();

drop trigger if exists trg_menu_item_photos_require_verified_contact_v1 on public.menu_item_photos;
create trigger trg_menu_item_photos_require_verified_contact_v1
before insert on public.menu_item_photos
for each row
execute function public.trg_require_verified_contact_v1();

drop trigger if exists trg_business_media_require_verified_contact_v1 on public.business_media;
create trigger trg_business_media_require_verified_contact_v1
before insert on public.business_media
for each row
execute function public.trg_require_verified_contact_v1();

-- ===== END MIGRATION: 20260322000001_auth_session_device_security.sql =====

-- ===== BEGIN MIGRATION: 20260322000002_role_permission_hardening.sql =====
-- Role and permission hardening:
-- - canonical app role RPC
-- - business manage permission RPC
-- - explicit businesses write policies

create or replace function public.current_user_role_v1()
returns text
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_uid uuid := auth.uid();
begin
  if v_uid is null then
    return 'user';
  end if;

  if public.is_admin() then
    return 'admin';
  end if;

  if exists (
    select 1
    from public.owner_claims oc
    where oc.user_id = v_uid
      and oc.status = 'approved'
  ) then
    return 'owner';
  end if;

  return 'user';
end;
$$;

revoke all on function public.current_user_role_v1() from public;
grant execute on function public.current_user_role_v1() to authenticated;

create or replace function public.can_manage_business_v1(p_business_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select
    case
      when auth.uid() is null then false
      else (public.is_admin() or public.is_owner_of_business(p_business_id))
    end;
$$;

revoke all on function public.can_manage_business_v1(uuid) from public;
grant execute on function public.can_manage_business_v1(uuid) to authenticated;

alter table if exists public.businesses enable row level security;

drop policy if exists businesses_insert_admin on public.businesses;
create policy businesses_insert_admin
on public.businesses
for insert
to authenticated
with check (public.is_admin());

drop policy if exists businesses_update_owner_admin on public.businesses;
create policy businesses_update_owner_admin
on public.businesses
for update
to authenticated
using (public.is_admin() or public.is_owner_of_business(id))
with check (public.is_admin() or public.is_owner_of_business(id));

drop policy if exists businesses_delete_admin on public.businesses;
create policy businesses_delete_admin
on public.businesses
for delete
to authenticated
using (public.is_admin());

-- ===== END MIGRATION: 20260322000002_role_permission_hardening.sql =====

-- ===== BEGIN MIGRATION: 20260322000003_rls_user_content_owner_admin_matrix.sql =====
begin;

-- Reviews: keep public approved read, add admin override for update/delete.
drop policy if exists reviews_update_admin on public.reviews;
create policy reviews_update_admin
  on public.reviews
  for update
  to authenticated
  using (public.is_admin())
  with check (public.is_admin());

drop policy if exists reviews_delete_admin on public.reviews;
create policy reviews_delete_admin
  on public.reviews
  for delete
  to authenticated
  using (public.is_admin());

-- Review votes: owner scope + admin override.
drop policy if exists review_votes_admin_all on public.review_votes;
create policy review_votes_admin_all
  on public.review_votes
  for all
  to authenticated
  using (public.is_admin())
  with check (public.is_admin());

-- Business suggestions:
-- approved visible to everyone; pending/non-approved visible only to owner/admin.
drop policy if exists business_suggestions_select_access on public.business_suggestions;
drop policy if exists business_suggestions_select_public_or_owner_admin on public.business_suggestions;
create policy business_suggestions_select_public_or_owner_admin
  on public.business_suggestions
  for select
  to public
  using (
    status = 'approved'
    or user_id = auth.uid()
    or public.is_admin()
  );

-- allow user to update/delete only own pending suggestion; admin keeps full control.
drop policy if exists business_suggestions_update_own_pending on public.business_suggestions;
create policy business_suggestions_update_own_pending
  on public.business_suggestions
  for update
  to authenticated
  using (
    user_id = auth.uid()
    and status = 'pending'
  )
  with check (
    user_id = auth.uid()
    and status = 'pending'
  );

drop policy if exists business_suggestions_delete_own_pending on public.business_suggestions;
create policy business_suggestions_delete_own_pending
  on public.business_suggestions
  for delete
  to authenticated
  using (
    user_id = auth.uid()
    and status = 'pending'
  );

-- Menu item price suggestions:
-- approved public; pending visible to creator/owner/admin.
drop policy if exists price_sugg_select_access on public.menu_item_price_suggestions;
drop policy if exists price_sugg_select_public_or_actor on public.menu_item_price_suggestions;
create policy price_sugg_select_public_or_actor
  on public.menu_item_price_suggestions
  for select
  to public
  using (
    status::text = 'approved'
    or created_by = auth.uid()
    or public.is_admin()
    or public.is_owner_of_business(business_id)
  );

-- creator can update/delete only own pending rows; admin remains all-powerful.
drop policy if exists price_sugg_update_own_pending on public.menu_item_price_suggestions;
create policy price_sugg_update_own_pending
  on public.menu_item_price_suggestions
  for update
  to authenticated
  using (
    created_by = auth.uid()
    and status = 'pending'::public.menu_price_suggestion_status
  )
  with check (
    created_by = auth.uid()
    and status = 'pending'::public.menu_price_suggestion_status
  );

drop policy if exists price_sugg_delete_own_pending on public.menu_item_price_suggestions;
create policy price_sugg_delete_own_pending
  on public.menu_item_price_suggestions
  for delete
  to authenticated
  using (
    created_by = auth.uid()
    and status = 'pending'::public.menu_price_suggestion_status
  );

-- Price/photo/business-fee votes: ensure admin override exists consistently.
drop policy if exists menu_item_price_votes_admin_all on public.menu_item_price_votes;
create policy menu_item_price_votes_admin_all
  on public.menu_item_price_votes
  for all
  to authenticated
  using (public.is_admin())
  with check (public.is_admin());

drop policy if exists menu_item_photo_votes_admin_all on public.menu_item_photo_votes;
create policy menu_item_photo_votes_admin_all
  on public.menu_item_photo_votes
  for all
  to authenticated
  using (public.is_admin())
  with check (public.is_admin());

-- owner_claims already enforces own/admin access, keep as is.
-- admin_audit_log already admin-only, keep as is.

commit;

-- ===== END MIGRATION: 20260322000003_rls_user_content_owner_admin_matrix.sql =====

-- ===== BEGIN MIGRATION: 20260322000004_edge_rate_limit_events.sql =====
begin;

create table if not exists public.edge_rate_limit_events (
  id bigserial primary key,
  action text not null,
  user_id uuid null,
  ip_hash text not null,
  scope text null,
  created_at timestamptz not null default now()
);

create index if not exists idx_edge_rate_limit_events_action_user_created
  on public.edge_rate_limit_events (action, user_id, created_at desc);

create index if not exists idx_edge_rate_limit_events_action_ip_created
  on public.edge_rate_limit_events (action, ip_hash, created_at desc);

create index if not exists idx_edge_rate_limit_events_action_user_scope_created
  on public.edge_rate_limit_events (action, user_id, scope, created_at desc)
  where scope is not null;

alter table public.edge_rate_limit_events enable row level security;

drop policy if exists edge_rate_limit_events_admin_all on public.edge_rate_limit_events;
create policy edge_rate_limit_events_admin_all
  on public.edge_rate_limit_events
  for all
  to authenticated
  using (public.is_admin())
  with check (public.is_admin());

commit;

-- ===== END MIGRATION: 20260322000004_edge_rate_limit_events.sql =====

-- ===== BEGIN MIGRATION: 20260322000005_edge_guard_enforcement.sql =====
begin;

create or replace function public.consume_edge_guard_event_v1(
  p_action text,
  p_scope text default null,
  p_max_age_seconds integer default 600
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid uuid := auth.uid();
  v_event_id bigint;
begin
  if public.is_admin() or auth.role() = 'service_role' then
    return;
  end if;

  if v_uid is null then
    raise exception 'edge_guard_required';
  end if;

  with candidate as (
    select e.id
    from public.edge_rate_limit_events e
    where e.action = p_action
      and e.user_id = v_uid
      and e.created_at >= now() - make_interval(secs => greatest(p_max_age_seconds, 1))
      and (
        p_scope is null
        or e.scope = p_scope
      )
    order by e.created_at asc
    limit 1
  ),
  consumed as (
    delete from public.edge_rate_limit_events e
    using candidate c
    where e.id = c.id
    returning e.id
  )
  select id into v_event_id from consumed;

  if v_event_id is null then
    raise exception 'edge_guard_required';
  end if;
end;
$$;

create or replace function public.enforce_reviews_edge_guard_v1()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  perform public.consume_edge_guard_event_v1(
    'review_submit',
    coalesce(new.business_id::text, ''),
    900
  );
  return new;
end;
$$;

drop trigger if exists trg_reviews_edge_guard_v1 on public.reviews;
create trigger trg_reviews_edge_guard_v1
before insert on public.reviews
for each row execute function public.enforce_reviews_edge_guard_v1();

create or replace function public.enforce_price_suggestions_edge_guard_v1()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  perform public.consume_edge_guard_event_v1(
    'price_verify',
    coalesce(new.menu_item_id::text, ''),
    900
  );
  return new;
end;
$$;

drop trigger if exists trg_price_suggestions_edge_guard_v1 on public.menu_item_price_suggestions;
create trigger trg_price_suggestions_edge_guard_v1
before insert on public.menu_item_price_suggestions
for each row execute function public.enforce_price_suggestions_edge_guard_v1();

create or replace function public.enforce_reports_edge_guard_v1()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_scope text;
begin
  v_scope := coalesce(
    new.business_id::text,
    new.review_id::text,
    new.menu_item_photo_id::text,
    new.target_id::text,
    ''
  );
  perform public.consume_edge_guard_event_v1(
    'report_submit',
    v_scope,
    900
  );
  return new;
end;
$$;

drop trigger if exists trg_reports_edge_guard_v1 on public.reports;
create trigger trg_reports_edge_guard_v1
before insert on public.reports
for each row execute function public.enforce_reports_edge_guard_v1();

create or replace function public.enforce_menu_item_photos_edge_guard_v1()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  perform public.consume_edge_guard_event_v1(
    'photo_upload',
    null,
    7200
  );
  return new;
end;
$$;

drop trigger if exists trg_menu_item_photos_edge_guard_v1 on public.menu_item_photos;
create trigger trg_menu_item_photos_edge_guard_v1
before insert on public.menu_item_photos
for each row execute function public.enforce_menu_item_photos_edge_guard_v1();

commit;


-- ===== END MIGRATION: 20260322000005_edge_guard_enforcement.sql =====

-- ===== BEGIN MIGRATION: 20260322000006_input_hygiene_and_moderation.sql =====
begin;

create or replace function public.sanitize_plain_text_v1(p_text text)
returns text
language sql
immutable
as $$
  select trim(
    regexp_replace(
      regexp_replace(
        regexp_replace(coalesce(p_text, ''), '<[^>]*>', ' ', 'gi'),
        '&[a-zA-Z0-9#]+;',
        ' ',
        'g'
      ),
      '[[:cntrl:]]+',
      ' ',
      'g'
    )
  );
$$;

create or replace function public.mask_contact_tokens_v1(p_text text)
returns text
language sql
immutable
as $$
  select trim(
    regexp_replace(
      regexp_replace(
        regexp_replace(
          coalesce(p_text, ''),
          '(https?://[^\s]+|www\.[^\s]+|t\.me/[^\s]+|wa\.me/[^\s]+|instagram\.com/[^\s]*)',
          '[gizlendi]',
          'gi'
        ),
        '([A-Z0-9._%+\-]+@[A-Z0-9.\-]+\.[A-Z]{2,})',
        '[gizlendi]',
        'gi'
      ),
      '(\+?\d[\d\s\-\(\)]{7,}\d)',
      '[gizlendi]',
      'g'
    )
  );
$$;

create or replace function public.contains_contact_or_url_v1(p_text text)
returns boolean
language sql
immutable
as $$
  select coalesce(p_text, '') ~* '(https?://|www\.|t\.me/|wa\.me/|instagram\.com/|[A-Z0-9._%+\-]+@[A-Z0-9.\-]+\.[A-Z]{2,}|(\+?\d[\d\s\-\(\)]{7,}\d))';
$$;

create or replace function public.normalize_for_moderation_v1(p_text text)
returns text
language sql
immutable
as $$
  select regexp_replace(
    replace(
      replace(
        replace(
          replace(
            replace(
              replace(
                replace(
                  replace(
                    replace(
                      replace(
                        translate(lower(coalesce(p_text, '')), 'çğıöşü', 'cgiosu'),
                        '@',
                        'a'
                      ),
                      '4',
                      'a'
                    ),
                    '0',
                    'o'
                  ),
                  '1',
                  'i'
                ),
                '!',
                'i'
              ),
              '$',
              's'
            ),
            '5',
            's'
          ),
          '3',
          'e'
        ),
        '.',
        ''
      ),
      '_',
      ''
    ),
    '[^a-z0-9]+',
    ' ',
    'g'
  );
$$;

create or replace function public.contains_obfuscated_profanity_v1(p_text text)
returns boolean
language plpgsql
immutable
as $$
declare
  v_norm text := public.normalize_for_moderation_v1(p_text);
  v_compact text := regexp_replace(v_norm, '\s+', '', 'g');
begin
  if v_norm ~* '(^| )a\s*m\s*k( |$)' then
    return true;
  end if;

  if v_compact ~* '(amk|amq|aq|siktir|sikik|sikicem|orospu|orosbu|pic|yarrak|gavat|ibne|gotveren)' then
    return true;
  end if;

  return false;
end;
$$;

create or replace function public.submit_review_v1(
  p_business_id uuid,
  p_rating integer,
  p_title text default null,
  p_content text default null
) returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
  v_content text := public.sanitize_plain_text_v1(p_content);
  v_title text := nullif(public.sanitize_plain_text_v1(p_title), '');
  v_profile_created_at timestamptz;
  v_recent_count int := 0;
  v_same_business_count int := 0;
  v_shadow boolean := false;
  v_rate jsonb;
  v_has_contact boolean := false;
  v_has_profanity boolean := false;
  v_status text := 'approved';
begin
  if v_user_id is null then
    return jsonb_build_object('ok', false, 'error', 'not_authenticated');
  end if;

  if p_business_id is null then
    return jsonb_build_object('ok', false, 'error', 'business_required');
  end if;

  if p_rating < 1 or p_rating > 5 then
    return jsonb_build_object('ok', false, 'error', 'bad_rating');
  end if;

  if length(v_content) < 8 then
    return jsonb_build_object('ok', false, 'error', 'content_too_short');
  end if;

  if length(regexp_replace(v_content, '[[:alnum:][:space:]]', '', 'g')) > 12 then
    return jsonb_build_object('ok', false, 'error', 'emoji_spam');
  end if;

  v_has_contact := public.contains_contact_or_url_v1(coalesce(p_content, ''))
    or public.contains_contact_or_url_v1(v_content);

  v_has_profanity := public.contains_obfuscated_profanity_v1(v_content)
    or public.contains_obfuscated_profanity_v1(coalesce(v_title, ''));

  if v_has_contact then
    v_content := public.mask_contact_tokens_v1(v_content);
    v_title := nullif(public.mask_contact_tokens_v1(coalesce(v_title, '')), '');
  end if;

  v_rate := public.consume_rate_limit_v1('review', 15);
  if coalesce((v_rate->>'ok')::boolean, false) is false then
    return jsonb_build_object('ok', false, 'error', 'review_daily_rate_limited');
  end if;

  select up.created_at
    into v_profile_created_at
  from public.user_profiles up
  where up.user_id = v_user_id;

  if v_profile_created_at is not null and v_profile_created_at >= now() - interval '7 days' then
    select count(*)
      into v_recent_count
    from public.reviews r
    where r.user_id = v_user_id
      and r.created_at >= now() - interval '24 hours';

    if v_recent_count >= 2 then
      return jsonb_build_object('ok', false, 'error', 'new_account_rate_limited');
    end if;
  end if;

  select count(*)
    into v_same_business_count
  from public.reviews r
  where r.user_id = v_user_id
    and r.business_id = p_business_id
    and r.created_at >= now() - interval '12 hours';

  if v_same_business_count > 0 then
    return jsonb_build_object('ok', false, 'error', 'same_business_cooldown');
  end if;

  v_shadow := public.is_shadow_banned_v1();
  v_status := case
    when v_shadow or v_has_contact or v_has_profanity then 'pending'
    else 'approved'
  end;

  insert into public.reviews(
    business_id, user_id, rating, title, content, status
  ) values (
    p_business_id, v_user_id, p_rating, v_title, v_content, v_status
  );

  return jsonb_build_object(
    'ok', true,
    'shadowed', v_shadow,
    'pending', v_status = 'pending',
    'contains_contact', v_has_contact,
    'contains_profanity', v_has_profanity
  );
end;
$$;

create or replace function public.submit_menu_item_price_suggestion_v2(
  p_menu_item_id uuid,
  p_suggested_price_cents integer,
  p_currency text default 'TRY',
  p_note text default null,
  p_evidence_url text default null
) returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_business_id uuid;
  v_cnt int;
  v_note text;
  v_evidence_url text;
  v_current_price int;
  v_ok_30d int := 0;
  v_bad_30d int := 0;
  v_total_30d int := 0;
  v_confidence numeric := 0;
  v_auto_approved boolean := false;
  v_pending_count int := 0;
  v_shadow boolean := false;
  v_rate jsonb;
begin
  if auth.uid() is null then
    return jsonb_build_object('ok', false, 'error', 'not_authenticated');
  end if;

  if p_suggested_price_cents < 0 then
    return jsonb_build_object('ok', false, 'error', 'bad_price');
  end if;

  if p_currency is null or length(trim(p_currency)) <> 3 then
    return jsonb_build_object('ok', false, 'error', 'bad_currency');
  end if;

  v_note := nullif(public.sanitize_plain_text_v1(p_note), '');
  v_evidence_url := nullif(trim(p_evidence_url), '');

  if v_note is not null and public.contains_contact_or_url_v1(v_note) then
    return jsonb_build_object('ok', false, 'error', 'contains_link_or_phone');
  end if;

  if v_note is not null and public.contains_obfuscated_profanity_v1(v_note) then
    return jsonb_build_object('ok', false, 'error', 'contains_profanity');
  end if;

  if v_note is not null
     and length(regexp_replace(v_note, '[[:alnum:][:space:]]', '', 'g')) > 12 then
    return jsonb_build_object('ok', false, 'error', 'emoji_spam');
  end if;

  if v_evidence_url is not null and left(v_evidence_url, 4) <> 'http' then
    return jsonb_build_object('ok', false, 'error', 'bad_evidence_url');
  end if;

  v_rate := public.consume_rate_limit_v1('price_suggestion', 40);
  if coalesce((v_rate->>'ok')::boolean, false) is false then
    return jsonb_build_object('ok', false, 'error', 'price_suggestion_daily_rate_limited');
  end if;

  select mi.business_id, mi.price_cents
    into v_business_id, v_current_price
  from public.menu_items mi
  where mi.id = p_menu_item_id and mi.status = 'published';

  if v_business_id is null then
    return jsonb_build_object('ok', false, 'error', 'not_found');
  end if;

  select count(*) into v_cnt
  from public.menu_item_price_suggestions
  where menu_item_id = p_menu_item_id
    and created_by = auth.uid()
    and created_at >= now() - interval '24 hours';

  if v_cnt > 0 then
    return jsonb_build_object('ok', false, 'error', 'rate_limited_24h');
  end if;

  select
    count(*) filter (where vote = 1 and created_at >= now() - interval '30 days'),
    count(*) filter (where vote = -1 and created_at >= now() - interval '30 days'),
    count(*) filter (where created_at >= now() - interval '30 days')
    into v_ok_30d, v_bad_30d, v_total_30d
  from public.menu_item_price_votes
  where menu_item_id = p_menu_item_id;

  v_confidence :=
    greatest(
      0::numeric,
      least(
        1::numeric,
        (case when v_total_30d <= 0 then 0.2 else (v_ok_30d::numeric / nullif(v_total_30d, 0)) end) * 0.8
        +
        (case
          when v_total_30d >= 12 then 0.2
          when v_total_30d >= 6 then 0.12
          when v_total_30d >= 3 then 0.06
          else 0
        end)
      )
    );

  v_shadow := public.is_shadow_banned_v1();
  if v_shadow then
    v_auto_approved := false;
  end if;

  if v_current_price is not null
     and v_current_price > 0
     and v_total_30d >= 8
     and v_ok_30d >= (v_bad_30d * 3)
     and abs(p_suggested_price_cents - v_current_price)::numeric / v_current_price::numeric <= 0.05
  then
    v_auto_approved := true;
  end if;

  if v_auto_approved then
    update public.menu_items
    set price_cents = p_suggested_price_cents,
        currency = upper(trim(p_currency)),
        updated_at = now()
    where id = p_menu_item_id;

    insert into public.menu_item_price_suggestions(
      menu_item_id, business_id, suggested_price_cents, currency, note, created_by,
      evidence_url, status, handled_at, approved_at, is_shadow
    )
    values (
      p_menu_item_id, v_business_id, p_suggested_price_cents, upper(trim(p_currency)), v_note, auth.uid(),
      v_evidence_url, 'approved', now(), now(), v_shadow
    );

    insert into public.menu_item_price_history(
      menu_item_id, price_cents, currency, source, created_by
    )
    values (
      p_menu_item_id, p_suggested_price_cents, upper(trim(p_currency)), 'auto_rule', auth.uid()
    );

    return jsonb_build_object(
      'ok', true,
      'auto_approved', true,
      'confidence_score', v_confidence,
      'pending_count', 0,
      'shadowed', v_shadow
    );
  end if;

  insert into public.menu_item_price_suggestions(
    menu_item_id, business_id, suggested_price_cents, currency, note, created_by, evidence_url, is_shadow
  )
  values (
    p_menu_item_id, v_business_id, p_suggested_price_cents, upper(trim(p_currency)), v_note, auth.uid(), v_evidence_url, v_shadow
  );

  select count(*) into v_pending_count
  from public.menu_item_price_suggestions
  where menu_item_id = p_menu_item_id
    and status = 'pending';

  return jsonb_build_object(
    'ok', true,
    'auto_approved', false,
    'confidence_score', v_confidence,
    'pending_count', v_pending_count,
    'shadowed', v_shadow
  );
end;
$$;

create or replace function public.submit_report_v1(
  p_business_id uuid default null,
  p_review_id uuid default null,
  p_menu_item_photo_id uuid default null,
  p_reason text default 'other',
  p_details text default null
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid uuid := auth.uid();
  v_recent_exists boolean;
  v_report_id uuid;
  v_target_type text;
  v_target_id uuid;
  v_business_id uuid;
  v_review_id uuid;
  v_photo_id uuid;
  v_reason text := coalesce(nullif(public.sanitize_plain_text_v1(p_reason), ''), 'other');
  v_details text := nullif(public.sanitize_plain_text_v1(p_details), '');
begin
  if v_uid is null then
    return jsonb_build_object('ok', false, 'error', 'not_authenticated');
  end if;

  if p_business_id is null and p_review_id is null and p_menu_item_photo_id is null then
    return jsonb_build_object('ok', false, 'error', 'missing_target');
  end if;

  if p_menu_item_photo_id is not null then
    v_target_type := 'menu_item_photo';
    v_target_id := p_menu_item_photo_id;
    v_photo_id := p_menu_item_photo_id;
    select business_id into v_business_id
    from public.menu_item_photos
    where id = p_menu_item_photo_id;
    if v_business_id is null then
      return jsonb_build_object('ok', false, 'error', 'photo_not_found');
    end if;
  elsif p_review_id is not null then
    v_target_type := 'review';
    v_target_id := p_review_id;
    v_review_id := p_review_id;
  else
    v_target_type := 'business';
    v_target_id := p_business_id;
    v_business_id := p_business_id;
  end if;

  if v_target_type = 'business' then
    select exists(
      select 1
      from public.reports
      where user_id = v_uid
        and business_id = v_business_id
        and created_at >= now() - interval '24 hours'
    ) into v_recent_exists;
  elsif v_target_type = 'review' then
    select exists(
      select 1
      from public.reports
      where user_id = v_uid
        and review_id = v_review_id
        and created_at >= now() - interval '24 hours'
    ) into v_recent_exists;
  else
    select exists(
      select 1
      from public.reports
      where user_id = v_uid
        and menu_item_photo_id = v_photo_id
        and created_at >= now() - interval '24 hours'
    ) into v_recent_exists;
  end if;

  if v_recent_exists then
    return jsonb_build_object('ok', false, 'error', 'rate_limited_24h');
  end if;

  insert into public.reports(
    user_id,
    business_id,
    review_id,
    menu_item_photo_id,
    target_type,
    target_id,
    reason,
    details
  )
  values (
    v_uid,
    v_business_id,
    v_review_id,
    v_photo_id,
    v_target_type,
    v_target_id,
    v_reason,
    v_details
  )
  returning id into v_report_id;

  return jsonb_build_object('ok', true, 'report_id', v_report_id);
end;
$$;

commit;


-- ===== END MIGRATION: 20260322000006_input_hygiene_and_moderation.sql =====

-- ===== BEGIN MIGRATION: 20260322000007_storage_photo_security.sql =====
begin;

-- Secure bucket for user photos.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'menu-media',
  'menu-media',
  true,
  5242880,
  array['image/jpeg', 'image/png', 'image/webp']
)
on conflict (id) do update
set public = excluded.public,
    file_size_limit = excluded.file_size_limit,
    allowed_mime_types = excluded.allowed_mime_types;

-- Storage object policies (for direct SDK usage if any).
drop policy if exists menu_media_read_all on storage.objects;
create policy menu_media_read_all
  on storage.objects
  for select
  to public
  using (bucket_id = 'menu-media');

drop policy if exists menu_media_insert_auth on storage.objects;
create policy menu_media_insert_auth
  on storage.objects
  for insert
  to authenticated
  with check (
    bucket_id = 'menu-media'
    and owner = auth.uid()
    and name like 'business/%'
    and (
      lower(name) like '%.jpg'
      or lower(name) like '%.jpeg'
      or lower(name) like '%.png'
      or lower(name) like '%.webp'
    )
  );

drop policy if exists menu_media_update_own_or_admin on storage.objects;
create policy menu_media_update_own_or_admin
  on storage.objects
  for update
  to authenticated
  using (
    bucket_id = 'menu-media'
    and (owner = auth.uid() or public.is_admin())
  )
  with check (
    bucket_id = 'menu-media'
    and (owner = auth.uid() or public.is_admin())
  );

drop policy if exists menu_media_delete_own_or_admin on storage.objects;
create policy menu_media_delete_own_or_admin
  on storage.objects
  for delete
  to authenticated
  using (
    bucket_id = 'menu-media'
    and (owner = auth.uid() or public.is_admin())
  );

-- Moderation fields.
alter table public.menu_item_photos
  add column if not exists status text not null default 'pending'
    check (status in ('pending', 'approved', 'rejected')),
  add column if not exists is_hidden boolean not null default false,
  add column if not exists moderation_note text;

alter table public.business_media
  add column if not exists status text not null default 'pending'
    check (status in ('pending', 'approved', 'rejected')),
  add column if not exists is_hidden boolean not null default false,
  add column if not exists moderation_note text;

create index if not exists idx_menu_item_photos_status_hidden
  on public.menu_item_photos(status, is_hidden, created_at desc);

create index if not exists idx_business_media_status_hidden
  on public.business_media(status, is_hidden, created_at desc);

create or replace function public.add_menu_item_photo_v1(
  p_menu_item_id uuid,
  p_url text,
  p_url_large text default null,
  p_url_thumb text default null,
  p_provider text default 'supabase_storage'
) returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $function$
declare
  v_business_id uuid;
  v_photo_id uuid;
  v_shadow boolean := false;
  v_rate jsonb;
begin
  if auth.uid() is null then
    return jsonb_build_object('ok', false, 'error', 'not_authenticated');
  end if;

  select business_id into v_business_id
  from public.menu_items
  where id = p_menu_item_id;

  if v_business_id is null then
    return jsonb_build_object('ok', false, 'error', 'not_found');
  end if;

  v_rate := public.consume_rate_limit_v1('menu_photo', 20);
  if coalesce((v_rate->>'ok')::boolean, false) is false then
    return jsonb_build_object('ok', false, 'error', 'menu_photo_daily_rate_limited');
  end if;

  v_shadow := public.is_shadow_banned_v1();

  insert into public.menu_item_photos(
    menu_item_id,
    business_id,
    url,
    url_large,
    url_thumb,
    provider,
    created_by,
    is_shadow,
    status,
    is_hidden
  )
  values (
    p_menu_item_id,
    v_business_id,
    p_url,
    p_url_large,
    p_url_thumb,
    p_provider,
    auth.uid(),
    v_shadow,
    'pending',
    false
  )
  returning id into v_photo_id;

  return jsonb_build_object('ok', true, 'photo_id', v_photo_id, 'shadowed', v_shadow, 'pending', true);
end;
$function$;

create or replace function public.get_menu_item_photos_v1(
  p_menu_item_id uuid,
  p_limit integer default 12
) returns table(
  id uuid,
  url text,
  url_large text,
  url_thumb text,
  provider text,
  created_at timestamp with time zone,
  up_votes integer,
  down_votes integer,
  score integer,
  my_vote smallint
)
language sql
stable
security definer
set search_path to 'public'
as $$
  select
    p.id,
    p.url,
    p.url_large,
    p.url_thumb,
    p.provider,
    p.created_at,
    p.up_votes,
    p.down_votes,
    (p.up_votes - p.down_votes) as score,
    (select v.vote from public.menu_item_photo_votes v
      where v.photo_id = p.id and v.user_id = auth.uid()
      limit 1) as my_vote
  from public.menu_item_photos p
  where p.menu_item_id = p_menu_item_id
    and (
      (p.status = 'approved' and p.is_hidden is not true and p.is_shadow is not true)
      or p.created_by = auth.uid()
      or public.is_admin()
    )
  order by p.created_at desc
  limit greatest(p_limit, 0);
$$;

-- Reported photo => hidden + pending.
create or replace function public.trg_hide_reported_menu_photo_v1()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if new.target_type = 'menu_item_photo' and new.menu_item_photo_id is not null then
    update public.menu_item_photos
    set is_hidden = true,
        status = 'pending',
        moderation_note = coalesce(moderation_note, 'auto_hidden_by_report')
    where id = new.menu_item_photo_id;
  end if;
  return new;
end;
$$;

drop trigger if exists trg_hide_reported_menu_photo_v1 on public.reports;
create trigger trg_hide_reported_menu_photo_v1
after insert on public.reports
for each row execute function public.trg_hide_reported_menu_photo_v1();

-- Admin moderation endpoint.
create or replace function public.admin_set_menu_item_photo_moderation_v1(
  p_photo_id uuid,
  p_status text,
  p_is_hidden boolean default false,
  p_note text default null
) returns jsonb
language plpgsql
security definer
set search_path = public
as $$
begin
  if not public.is_admin() then
    return jsonb_build_object('ok', false, 'error', 'not_admin');
  end if;

  if p_status not in ('pending', 'approved', 'rejected') then
    return jsonb_build_object('ok', false, 'error', 'invalid_status');
  end if;

  update public.menu_item_photos
  set status = p_status,
      is_hidden = coalesce(p_is_hidden, false),
      moderation_note = nullif(trim(coalesce(p_note, '')), '')
  where id = p_photo_id;

  if not found then
    return jsonb_build_object('ok', false, 'error', 'not_found');
  end if;

  return jsonb_build_object('ok', true);
end;
$$;

grant all on function public.admin_set_menu_item_photo_moderation_v1(uuid, text, boolean, text) to authenticated;
grant all on function public.admin_set_menu_item_photo_moderation_v1(uuid, text, boolean, text) to service_role;

commit;

-- ===== END MIGRATION: 20260322000007_storage_photo_security.sql =====

-- ===== BEGIN MIGRATION: 20260322000008_write_path_server_controlled.sql =====
begin;

-- Enforce edge guard consumption for review vote writes.
create or replace function public.enforce_review_votes_edge_guard_v1()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if tg_op = 'INSERT' then
    perform public.consume_edge_guard_event_v1(
      'review_vote_set',
      coalesce(new.review_id::text, ''),
      900
    );
    return new;
  elsif tg_op = 'DELETE' then
    perform public.consume_edge_guard_event_v1(
      'review_vote_remove',
      coalesce(old.review_id::text, ''),
      900
    );
    return old;
  end if;
  return null;
end;
$$;

drop trigger if exists trg_review_votes_edge_guard_insert_v1 on public.review_votes;
create trigger trg_review_votes_edge_guard_insert_v1
before insert on public.review_votes
for each row execute function public.enforce_review_votes_edge_guard_v1();

drop trigger if exists trg_review_votes_edge_guard_delete_v1 on public.review_votes;
create trigger trg_review_votes_edge_guard_delete_v1
before delete on public.review_votes
for each row execute function public.enforce_review_votes_edge_guard_v1();

-- Enforce edge guard consumption for visit writes.
create or replace function public.enforce_visits_edge_guard_v1()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if tg_op = 'INSERT' then
    perform public.consume_edge_guard_event_v1(
      'visit_add',
      coalesce(new.business_id::text, ''),
      900
    );
    return new;
  elsif tg_op = 'DELETE' then
    perform public.consume_edge_guard_event_v1(
      'visit_remove',
      coalesce(old.business_id::text, ''),
      900
    );
    return old;
  end if;
  return null;
end;
$$;

drop trigger if exists trg_visits_edge_guard_insert_v1 on public.visits;
create trigger trg_visits_edge_guard_insert_v1
before insert on public.visits
for each row execute function public.enforce_visits_edge_guard_v1();

drop trigger if exists trg_visits_edge_guard_delete_v1 on public.visits;
create trigger trg_visits_edge_guard_delete_v1
before delete on public.visits
for each row execute function public.enforce_visits_edge_guard_v1();

-- Enforce edge guard consumption for menu photo deletes.
create or replace function public.enforce_menu_item_photos_delete_edge_guard_v1()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  perform public.consume_edge_guard_event_v1(
    'menu_photo_delete',
    coalesce(old.id::text, ''),
    900
  );
  return old;
end;
$$;

drop trigger if exists trg_menu_item_photos_delete_edge_guard_v1 on public.menu_item_photos;
create trigger trg_menu_item_photos_delete_edge_guard_v1
before delete on public.menu_item_photos
for each row execute function public.enforce_menu_item_photos_delete_edge_guard_v1();

commit;


-- ===== END MIGRATION: 20260322000008_write_path_server_controlled.sql =====

-- ===== BEGIN MIGRATION: 20260322000009_abuse_fraud_modular_system.sql =====
begin;

create table if not exists public.user_risk_signals (
  id bigserial primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  signal_key text not null,
  signal_weight integer not null default 0,
  ip_hash text null,
  signal_meta jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create index if not exists idx_user_risk_signals_user_created
  on public.user_risk_signals (user_id, created_at desc);

create index if not exists idx_user_risk_signals_signal_created
  on public.user_risk_signals (signal_key, created_at desc);

create table if not exists public.user_safety_actions (
  user_id uuid primary key references auth.users(id) on delete cascade,
  risk_score integer not null default 0,
  soft_limited_until timestamptz null,
  auto_pending_until timestamptz null,
  shadow_banned_until timestamptz null,
  last_signal_at timestamptz null,
  updated_at timestamptz not null default now()
);

create table if not exists public.user_device_fingerprints (
  user_id uuid not null references auth.users(id) on delete cascade,
  fingerprint text not null,
  created_at timestamptz not null default now(),
  last_seen_at timestamptz not null default now(),
  seen_count integer not null default 1,
  primary key (user_id, fingerprint)
);

create index if not exists idx_user_device_fingerprints_user_seen
  on public.user_device_fingerprints (user_id, last_seen_at desc);

alter table public.user_risk_signals enable row level security;
alter table public.user_safety_actions enable row level security;
alter table public.user_device_fingerprints enable row level security;

drop policy if exists user_risk_signals_admin_all on public.user_risk_signals;
create policy user_risk_signals_admin_all
  on public.user_risk_signals
  for all
  to authenticated
  using (public.is_admin())
  with check (public.is_admin());

drop policy if exists user_safety_actions_admin_all on public.user_safety_actions;
create policy user_safety_actions_admin_all
  on public.user_safety_actions
  for all
  to authenticated
  using (public.is_admin())
  with check (public.is_admin());

drop policy if exists user_device_fingerprints_admin_all on public.user_device_fingerprints;
create policy user_device_fingerprints_admin_all
  on public.user_device_fingerprints
  for all
  to authenticated
  using (public.is_admin())
  with check (public.is_admin());

create or replace function public.is_user_shadowed_v1(p_user_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select
    coalesce((select up.shadow_banned from public.user_profiles up where up.user_id = p_user_id), false)
    or coalesce((select usa.shadow_banned_until > now() from public.user_safety_actions usa where usa.user_id = p_user_id), false);
$$;

create or replace function public.is_user_auto_pending_v1(p_user_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select coalesce(
    (select usa.auto_pending_until > now() from public.user_safety_actions usa where usa.user_id = p_user_id),
    false
  );
$$;

create or replace function public.is_user_soft_limited_v1(p_user_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select coalesce(
    (select usa.soft_limited_until > now() from public.user_safety_actions usa where usa.user_id = p_user_id),
    false
  );
$$;

create or replace function public.is_shadow_banned_v1()
returns boolean
language sql
security definer
set search_path = public
as $$
  select public.is_user_shadowed_v1(auth.uid());
$$;

create or replace function public.record_user_risk_signal_v1(
  p_user_id uuid,
  p_signal_key text,
  p_signal_weight integer default 5,
  p_ip_hash text default null,
  p_signal_meta jsonb default '{}'::jsonb
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_actor uuid := auth.uid();
  v_inserted boolean := false;
  v_score integer := 0;
  v_now timestamptz := now();
begin
  if p_user_id is null then
    return jsonb_build_object('ok', false, 'error', 'missing_user_id');
  end if;

  if coalesce(trim(p_signal_key), '') = '' then
    return jsonb_build_object('ok', false, 'error', 'missing_signal_key');
  end if;

  if auth.role() <> 'service_role' and not public.is_admin() and v_actor is distinct from p_user_id then
    return jsonb_build_object('ok', false, 'error', 'forbidden');
  end if;

  if exists (
    select 1
    from public.user_risk_signals rs
    where rs.user_id = p_user_id
      and rs.signal_key = p_signal_key
      and rs.created_at >= case
        when p_signal_key in ('new_account', 'device_change') then v_now - interval '24 hours'
        when p_signal_key = 'same_ip_burst' then v_now - interval '30 minutes'
        when p_signal_key = 'duplicate_text' then v_now - interval '12 hours'
        else v_now - interval '10 minutes'
      end
  ) then
    v_inserted := false;
  else
    insert into public.user_risk_signals(
      user_id,
      signal_key,
      signal_weight,
      ip_hash,
      signal_meta
    ) values (
      p_user_id,
      p_signal_key,
      greatest(0, p_signal_weight),
      nullif(trim(coalesce(p_ip_hash, '')), ''),
      coalesce(p_signal_meta, '{}'::jsonb)
    );
    v_inserted := true;
  end if;

  select coalesce(sum(rs.signal_weight), 0)::integer
    into v_score
  from public.user_risk_signals rs
  where rs.user_id = p_user_id
    and rs.created_at >= v_now - interval '14 days';

  insert into public.user_safety_actions(
    user_id,
    risk_score,
    last_signal_at,
    updated_at
  ) values (
    p_user_id,
    v_score,
    case when v_inserted then v_now else null end,
    v_now
  )
  on conflict (user_id) do update
    set risk_score = excluded.risk_score,
        last_signal_at = coalesce(excluded.last_signal_at, public.user_safety_actions.last_signal_at),
        updated_at = v_now;

  if v_score >= 80 then
    update public.user_safety_actions
      set shadow_banned_until = greatest(coalesce(shadow_banned_until, v_now), v_now + interval '72 hours'),
          auto_pending_until = greatest(coalesce(auto_pending_until, v_now), v_now + interval '72 hours'),
          updated_at = v_now
    where user_id = p_user_id;
  elsif v_score >= 50 then
    update public.user_safety_actions
      set auto_pending_until = greatest(coalesce(auto_pending_until, v_now), v_now + interval '24 hours'),
          updated_at = v_now
    where user_id = p_user_id;
  elsif v_score >= 30 then
    update public.user_safety_actions
      set soft_limited_until = greatest(coalesce(soft_limited_until, v_now), v_now + interval '30 minutes'),
          updated_at = v_now
    where user_id = p_user_id;
  end if;

  return jsonb_build_object(
    'ok', true,
    'inserted', v_inserted,
    'risk_score', v_score
  );
end;
$$;

create or replace function public.record_user_device_fingerprint_v1(
  p_user_id uuid,
  p_fingerprint text
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_fingerprint text := trim(coalesce(p_fingerprint, ''));
  v_exists boolean := false;
  v_device_count integer := 0;
begin
  if p_user_id is null then
    return jsonb_build_object('ok', false, 'error', 'missing_user_id');
  end if;

  if v_fingerprint = '' then
    return jsonb_build_object('ok', false, 'error', 'missing_fingerprint');
  end if;

  select exists(
    select 1
    from public.user_device_fingerprints d
    where d.user_id = p_user_id
      and d.fingerprint = v_fingerprint
  ) into v_exists;

  if v_exists then
    update public.user_device_fingerprints
      set last_seen_at = now(),
          seen_count = seen_count + 1
    where user_id = p_user_id
      and fingerprint = v_fingerprint;
  else
    insert into public.user_device_fingerprints(
      user_id,
      fingerprint
    ) values (
      p_user_id,
      v_fingerprint
    );
  end if;

  select count(*)
    into v_device_count
  from public.user_device_fingerprints d
  where d.user_id = p_user_id
    and d.last_seen_at >= now() - interval '30 days';

  if not v_exists and v_device_count > 1 then
    perform public.record_user_risk_signal_v1(
      p_user_id,
      'device_change',
      12,
      null,
      jsonb_build_object('device_count', v_device_count)
    );
  end if;

  return jsonb_build_object(
    'ok', true,
    'is_new_device', not v_exists,
    'device_count', v_device_count
  );
end;
$$;

create or replace function public.admin_list_risky_users_v1(
  p_limit integer default 50,
  p_offset integer default 0,
  p_min_score integer default 20
)
returns table(
  user_id uuid,
  risk_score integer,
  signal_count integer,
  last_signal_at timestamptz,
  new_account_hits integer,
  device_change_hits integer,
  same_ip_hits integer,
  duplicate_text_hits integer,
  soft_limited_until timestamptz,
  auto_pending_until timestamptz,
  shadow_banned_until timestamptz,
  recommended_action text
)
language plpgsql
security definer
set search_path = public
as $$
begin
  if not public.is_admin() then
    return;
  end if;

  return query
  with recent as (
    select
      rs.user_id,
      coalesce(sum(rs.signal_weight), 0)::integer as score_14d,
      count(*)::integer as cnt,
      max(rs.created_at) as last_at,
      count(*) filter (where rs.signal_key = 'new_account')::integer as new_account_hits,
      count(*) filter (where rs.signal_key = 'device_change')::integer as device_change_hits,
      count(*) filter (where rs.signal_key = 'same_ip_burst')::integer as same_ip_hits,
      count(*) filter (where rs.signal_key = 'duplicate_text')::integer as duplicate_text_hits
    from public.user_risk_signals rs
    where rs.created_at >= now() - interval '14 days'
    group by rs.user_id
  )
  select
    r.user_id,
    greatest(r.score_14d, coalesce(usa.risk_score, 0)) as risk_score,
    r.cnt as signal_count,
    coalesce(usa.last_signal_at, r.last_at) as last_signal_at,
    r.new_account_hits,
    r.device_change_hits,
    r.same_ip_hits,
    r.duplicate_text_hits,
    usa.soft_limited_until,
    usa.auto_pending_until,
    usa.shadow_banned_until,
    case
      when coalesce(usa.shadow_banned_until > now(), false) then 'shadow_ban'
      when coalesce(usa.auto_pending_until > now(), false) then 'auto_pending'
      when coalesce(usa.soft_limited_until > now(), false) then 'soft_limit'
      when greatest(r.score_14d, coalesce(usa.risk_score, 0)) >= 80 then 'shadow_ban'
      when greatest(r.score_14d, coalesce(usa.risk_score, 0)) >= 50 then 'auto_pending'
      else 'soft_limit'
    end as recommended_action
  from recent r
  left join public.user_safety_actions usa on usa.user_id = r.user_id
  where greatest(r.score_14d, coalesce(usa.risk_score, 0)) >= greatest(p_min_score, 1)
  order by greatest(r.score_14d, coalesce(usa.risk_score, 0)) desc, coalesce(usa.last_signal_at, r.last_at) desc
  limit greatest(p_limit, 1)
  offset greatest(p_offset, 0);
end;
$$;

create or replace function public.admin_apply_user_safety_action_v1(
  p_user_id uuid,
  p_action text,
  p_minutes integer default 60,
  p_reason text default null
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_action text := lower(trim(coalesce(p_action, '')));
  v_until timestamptz := now() + make_interval(mins => greatest(p_minutes, 1));
begin
  if not public.is_admin() then
    return jsonb_build_object('ok', false, 'error', 'forbidden');
  end if;

  if p_user_id is null then
    return jsonb_build_object('ok', false, 'error', 'missing_user_id');
  end if;

  insert into public.user_safety_actions(user_id, updated_at)
  values (p_user_id, now())
  on conflict (user_id) do nothing;

  if v_action = 'soft_limit' then
    update public.user_safety_actions
      set soft_limited_until = greatest(coalesce(soft_limited_until, now()), v_until),
          updated_at = now()
    where user_id = p_user_id;
  elsif v_action = 'auto_pending' then
    update public.user_safety_actions
      set auto_pending_until = greatest(coalesce(auto_pending_until, now()), v_until),
          updated_at = now()
    where user_id = p_user_id;
  elsif v_action = 'shadow_ban' then
    update public.user_safety_actions
      set shadow_banned_until = greatest(coalesce(shadow_banned_until, now()), v_until),
          auto_pending_until = greatest(coalesce(auto_pending_until, now()), v_until),
          updated_at = now()
    where user_id = p_user_id;
    update public.user_profiles
      set shadow_banned = true
    where user_id = p_user_id;
  elsif v_action = 'clear' then
    update public.user_safety_actions
      set soft_limited_until = null,
          auto_pending_until = null,
          shadow_banned_until = null,
          updated_at = now()
    where user_id = p_user_id;
    update public.user_profiles
      set shadow_banned = false
    where user_id = p_user_id;
  else
    return jsonb_build_object('ok', false, 'error', 'bad_action');
  end if;

  insert into public.admin_audit_log(action, target_table, target_id, meta)
  values (
    'user.safety_action',
    'user_profiles',
    p_user_id::text,
    jsonb_build_object(
      'actor_id', auth.uid(),
      'action', v_action,
      'minutes', greatest(p_minutes, 1),
      'reason', nullif(trim(coalesce(p_reason, '')), '')
    )
  );

  return jsonb_build_object('ok', true);
end;
$$;

create or replace function public.enforce_abuse_controls_on_reviews_v1()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_count integer := 0;
begin
  if new.user_id is null then
    return new;
  end if;

  if public.is_user_soft_limited_v1(new.user_id) then
    select count(*)
      into v_count
    from public.reviews r
    where r.user_id = new.user_id
      and r.created_at >= now() - interval '24 hours';
    if v_count >= 3 then
      raise exception 'soft_rate_limited';
    end if;
  end if;

  if public.is_user_shadowed_v1(new.user_id) or public.is_user_auto_pending_v1(new.user_id) then
    new.status := 'pending';
  end if;

  return new;
end;
$$;

drop trigger if exists trg_reviews_abuse_controls_v1 on public.reviews;
create trigger trg_reviews_abuse_controls_v1
before insert on public.reviews
for each row execute function public.enforce_abuse_controls_on_reviews_v1();

create or replace function public.enforce_abuse_controls_on_price_suggestions_v1()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid uuid := coalesce(new.created_by, auth.uid());
  v_count integer := 0;
begin
  if v_uid is null then
    return new;
  end if;

  if public.is_user_soft_limited_v1(v_uid) then
    select count(*)
      into v_count
    from public.menu_item_price_suggestions s
    where s.created_by = v_uid
      and s.created_at >= now() - interval '24 hours';
    if v_count >= 6 then
      raise exception 'soft_rate_limited';
    end if;
  end if;

  if public.is_user_shadowed_v1(v_uid) or public.is_user_auto_pending_v1(v_uid) then
    new.status := 'pending'::public.menu_price_suggestion_status;
  end if;

  return new;
end;
$$;

drop trigger if exists trg_price_suggestions_abuse_controls_v1 on public.menu_item_price_suggestions;
create trigger trg_price_suggestions_abuse_controls_v1
before insert on public.menu_item_price_suggestions
for each row execute function public.enforce_abuse_controls_on_price_suggestions_v1();

create or replace function public.enforce_abuse_controls_on_menu_photos_v1()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid uuid := coalesce(new.created_by, auth.uid());
begin
  if v_uid is null then
    return new;
  end if;

  if public.is_user_shadowed_v1(v_uid) or public.is_user_auto_pending_v1(v_uid) then
    new.status := 'pending';
  end if;

  return new;
end;
$$;

drop trigger if exists trg_menu_item_photos_abuse_controls_v1 on public.menu_item_photos;
create trigger trg_menu_item_photos_abuse_controls_v1
before insert on public.menu_item_photos
for each row execute function public.enforce_abuse_controls_on_menu_photos_v1();

create or replace function public.collect_risk_signals_on_reviews_v1()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_created_at timestamptz;
  v_norm text := '';
  v_dup integer := 0;
begin
  if new.user_id is null then
    return new;
  end if;

  select up.created_at
    into v_created_at
  from public.user_profiles up
  where up.user_id = new.user_id;

  if v_created_at is not null and v_created_at >= now() - interval '3 days' then
    perform public.record_user_risk_signal_v1(
      new.user_id,
      'new_account',
      8,
      null,
      jsonb_build_object('source', 'reviews')
    );
  end if;

  v_norm := trim(public.normalize_for_moderation_v1(coalesce(new.content, '')));
  if length(v_norm) >= 8 then
    select count(*)
      into v_dup
    from public.reviews r
    where r.user_id <> new.user_id
      and r.created_at >= now() - interval '24 hours'
      and trim(public.normalize_for_moderation_v1(coalesce(r.content, ''))) = v_norm;

    if v_dup >= 2 then
      perform public.record_user_risk_signal_v1(
        new.user_id,
        'duplicate_text',
        18,
        null,
        jsonb_build_object('source', 'reviews', 'duplicate_count', v_dup)
      );
    end if;
  end if;

  return new;
end;
$$;

drop trigger if exists trg_reviews_collect_risk_signals_v1 on public.reviews;
create trigger trg_reviews_collect_risk_signals_v1
before insert on public.reviews
for each row execute function public.collect_risk_signals_on_reviews_v1();

create or replace function public.collect_risk_signals_on_price_suggestions_v1()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid uuid := coalesce(new.created_by, auth.uid());
  v_created_at timestamptz;
  v_norm text := '';
  v_dup integer := 0;
begin
  if v_uid is null then
    return new;
  end if;

  select up.created_at
    into v_created_at
  from public.user_profiles up
  where up.user_id = v_uid;

  if v_created_at is not null and v_created_at >= now() - interval '3 days' then
    perform public.record_user_risk_signal_v1(
      v_uid,
      'new_account',
      8,
      null,
      jsonb_build_object('source', 'price_suggestion')
    );
  end if;

  v_norm := trim(public.normalize_for_moderation_v1(coalesce(new.note, '')));
  if length(v_norm) >= 6 then
    select count(*)
      into v_dup
    from public.menu_item_price_suggestions s
    where s.created_by <> v_uid
      and s.created_at >= now() - interval '24 hours'
      and trim(public.normalize_for_moderation_v1(coalesce(s.note, ''))) = v_norm;

    if v_dup >= 2 then
      perform public.record_user_risk_signal_v1(
        v_uid,
        'duplicate_text',
        14,
        null,
        jsonb_build_object('source', 'price_suggestion', 'duplicate_count', v_dup)
      );
    end if;
  end if;

  return new;
end;
$$;

drop trigger if exists trg_price_suggestions_collect_risk_signals_v1 on public.menu_item_price_suggestions;
create trigger trg_price_suggestions_collect_risk_signals_v1
before insert on public.menu_item_price_suggestions
for each row execute function public.collect_risk_signals_on_price_suggestions_v1();

grant all on function public.record_user_risk_signal_v1(uuid, text, integer, text, jsonb) to authenticated;
grant all on function public.record_user_risk_signal_v1(uuid, text, integer, text, jsonb) to service_role;
grant all on function public.record_user_device_fingerprint_v1(uuid, text) to authenticated;
grant all on function public.record_user_device_fingerprint_v1(uuid, text) to service_role;
grant all on function public.admin_list_risky_users_v1(integer, integer, integer) to authenticated;
grant all on function public.admin_apply_user_safety_action_v1(uuid, text, integer, text) to authenticated;

commit;


-- ===== END MIGRATION: 20260322000009_abuse_fraud_modular_system.sql =====

-- ===== BEGIN MIGRATION: 20260322000010_permissions_rbac_and_admin_api.sql =====
begin;

create or replace function public.get_app_role_v1()
returns text
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_claim jsonb := auth.jwt();
  v_role text;
begin
  v_role := lower(coalesce(
    v_claim -> 'app_metadata' ->> 'role',
    v_claim -> 'user_metadata' ->> 'role',
    'user'
  ));
  if v_role not in ('user', 'owner', 'admin') then
    v_role := 'user';
  end if;
  return v_role;
end;
$$;

create or replace function public.can_access_business_v1(p_business_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select
    p_business_id is not null
    and (
      public.is_admin()
      or public.is_owner_of_business(p_business_id)
    );
$$;

create or replace function public.assert_owner_scope_v1(p_business_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if p_business_id is null then
    raise exception 'missing_business_id';
  end if;

  if not public.can_access_business_v1(p_business_id) then
    raise exception 'forbidden_scope';
  end if;
end;
$$;

create or replace function public.admin_apply_user_safety_action_v1(
  p_user_id uuid,
  p_action text,
  p_minutes integer default 60,
  p_reason text default null
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_action text := lower(trim(coalesce(p_action, '')));
  v_until timestamptz := now() + make_interval(mins => greatest(p_minutes, 1));
  v_reason text := nullif(trim(coalesce(p_reason, '')), '');
begin
  if not public.is_admin() then
    return jsonb_build_object('ok', false, 'error', 'forbidden');
  end if;

  if p_user_id is null then
    return jsonb_build_object('ok', false, 'error', 'missing_user_id');
  end if;

  if v_reason is null then
    return jsonb_build_object('ok', false, 'error', 'reason_required');
  end if;

  insert into public.user_safety_actions(user_id, updated_at)
  values (p_user_id, now())
  on conflict (user_id) do nothing;

  if v_action = 'soft_limit' then
    update public.user_safety_actions
      set soft_limited_until = greatest(coalesce(soft_limited_until, now()), v_until),
          updated_at = now()
    where user_id = p_user_id;
  elsif v_action = 'auto_pending' then
    update public.user_safety_actions
      set auto_pending_until = greatest(coalesce(auto_pending_until, now()), v_until),
          updated_at = now()
    where user_id = p_user_id;
  elsif v_action = 'shadow_ban' then
    update public.user_safety_actions
      set shadow_banned_until = greatest(coalesce(shadow_banned_until, now()), v_until),
          auto_pending_until = greatest(coalesce(auto_pending_until, now()), v_until),
          updated_at = now()
    where user_id = p_user_id;
    update public.user_profiles
      set shadow_banned = true
    where user_id = p_user_id;
  elsif v_action = 'clear' then
    update public.user_safety_actions
      set soft_limited_until = null,
          auto_pending_until = null,
          shadow_banned_until = null,
          updated_at = now()
    where user_id = p_user_id;
    update public.user_profiles
      set shadow_banned = false
    where user_id = p_user_id;
  else
    return jsonb_build_object('ok', false, 'error', 'bad_action');
  end if;

  insert into public.admin_audit_log(action, target_table, target_id, meta)
  values (
    'user.safety_action',
    'user_profiles',
    p_user_id::text,
    jsonb_build_object(
      'actor_id', auth.uid(),
      'action', v_action,
      'minutes', greatest(p_minutes, 1),
      'reason', v_reason
    )
  );

  return jsonb_build_object('ok', true);
end;
$$;

grant all on function public.get_app_role_v1() to authenticated;
grant all on function public.can_access_business_v1(uuid) to authenticated;
grant all on function public.assert_owner_scope_v1(uuid) to authenticated;
grant all on function public.admin_apply_user_safety_action_v1(uuid, text, integer, text) to authenticated;

commit;

-- ===== END MIGRATION: 20260322000010_permissions_rbac_and_admin_api.sql =====

-- ===== BEGIN MIGRATION: 20260322000011_storage_security_hardening.sql =====
begin;

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'menu-media-private',
  'menu-media-private',
  false,
  5242880,
  array['image/jpeg', 'image/png', 'image/webp']
)
on conflict (id) do update
set public = excluded.public,
    file_size_limit = excluded.file_size_limit,
    allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists menu_media_private_insert_auth on storage.objects;
create policy menu_media_private_insert_auth
  on storage.objects
  for insert
  to authenticated
  with check (
    bucket_id = 'menu-media-private'
    and owner = auth.uid()
    and name like 'critical/business/%'
    and (
      lower(name) like '%.jpg'
      or lower(name) like '%.jpeg'
      or lower(name) like '%.png'
      or lower(name) like '%.webp'
    )
  );

drop policy if exists menu_media_private_read_owner_admin on storage.objects;
create policy menu_media_private_read_owner_admin
  on storage.objects
  for select
  to authenticated
  using (
    bucket_id = 'menu-media-private'
    and (owner = auth.uid() or public.is_admin())
  );

drop policy if exists menu_media_private_update_owner_admin on storage.objects;
create policy menu_media_private_update_owner_admin
  on storage.objects
  for update
  to authenticated
  using (
    bucket_id = 'menu-media-private'
    and (owner = auth.uid() or public.is_admin())
  )
  with check (
    bucket_id = 'menu-media-private'
    and (owner = auth.uid() or public.is_admin())
  );

drop policy if exists menu_media_private_delete_owner_admin on storage.objects;
create policy menu_media_private_delete_owner_admin
  on storage.objects
  for delete
  to authenticated
  using (
    bucket_id = 'menu-media-private'
    and (owner = auth.uid() or public.is_admin())
  );

create or replace function public.trg_hide_reported_business_media_v1()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if new.target_type = 'business_media' and new.target_id is not null then
    update public.business_media
       set is_hidden = true,
           status = 'pending',
           moderation_note = coalesce(moderation_note, 'auto_hidden_by_report')
     where id::text = new.target_id;
  end if;
  return new;
end;
$$;

drop trigger if exists trg_hide_reported_business_media_v1 on public.reports;
create trigger trg_hide_reported_business_media_v1
after insert on public.reports
for each row execute function public.trg_hide_reported_business_media_v1();

commit;


-- ===== END MIGRATION: 20260322000011_storage_security_hardening.sql =====

-- ===== BEGIN MIGRATION: 20260322000012_data_quality_engine.sql =====
begin;

alter table if exists public.menu_item_price_suggestions
  add column if not exists quality_confidence numeric not null default 0,
  add column if not exists quality_user_weight numeric not null default 1,
  add column if not exists quality_evidence_weight numeric not null default 1,
  add column if not exists quality_time_weight numeric not null default 1,
  add column if not exists anomaly_flags jsonb not null default '[]'::jsonb,
  add column if not exists anomaly_score numeric not null default 0,
  add column if not exists conflict_state text not null default 'none',
  add column if not exists conflict_variants_24h integer not null default 0;

create index if not exists idx_menu_price_suggestion_quality_conflict_v1
  on public.menu_item_price_suggestions(menu_item_id, conflict_state, created_at desc);

create index if not exists idx_menu_price_suggestion_quality_anomaly_v1
  on public.menu_item_price_suggestions(menu_item_id, anomaly_score desc, created_at desc);

create or replace function public.compute_price_suggestion_quality_v1(
  p_menu_item_id uuid,
  p_suggested_price_cents integer,
  p_evidence_url text default null,
  p_captured_at timestamptz default now()
) returns jsonb
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_uid uuid := auth.uid();
  v_current_price integer := null;
  v_user_reputation integer := 0;
  v_user_weight numeric := 1.0;
  v_evidence_weight numeric := 1.0;
  v_time_weight numeric := 1.0;
  v_base_confidence numeric := 0.6;
  v_quality_confidence numeric := 0.6;
  v_anomaly_score numeric := 0;
  v_delta_ratio numeric := 0;
  v_recent_distinct integer := 0;
  v_conflict_state text := 'none';
  v_flags text[] := array[]::text[];
  v_flags_json jsonb := '[]'::jsonb;
begin
  if v_uid is not null and to_regprocedure('public.get_user_reputation_score_v2(uuid)') is not null then
    begin
      execute 'select coalesce(public.get_user_reputation_score_v2($1), 0)::int'
      into v_user_reputation
      using v_uid;
    exception
      when others then
        v_user_reputation := 0;
    end;
  end if;

  v_user_weight := greatest(0.35, least(1.5, 0.6 + (v_user_reputation::numeric / 120.0)));
  v_evidence_weight := case when nullif(trim(coalesce(p_evidence_url, '')), '') is null then 1.0 else 1.18 end;
  v_time_weight := case
    when p_captured_at >= now() - interval '2 hours' then 1.25
    when p_captured_at >= now() - interval '24 hours' then 1.05
    when p_captured_at >= now() - interval '72 hours' then 0.9
    else 0.75
  end;

  select mi.price_cents
    into v_current_price
  from public.menu_items mi
  where mi.id = p_menu_item_id
  limit 1;

  if v_current_price is not null and v_current_price > 0 then
    v_delta_ratio := abs(p_suggested_price_cents - v_current_price)::numeric / v_current_price::numeric;
    if p_suggested_price_cents >= ceil(v_current_price * 1.40) then
      v_flags := array_append(v_flags, 'high_increase');
      v_anomaly_score := v_anomaly_score + 0.55;
    end if;
    if p_suggested_price_cents <= floor(v_current_price * 0.55) then
      v_flags := array_append(v_flags, 'extreme_drop');
      v_anomaly_score := v_anomaly_score + 0.55;
    end if;
    if v_delta_ratio >= 0.75 then
      v_flags := array_append(v_flags, 'suspicious_jump');
      v_anomaly_score := v_anomaly_score + 0.35;
    end if;
  end if;

  select count(distinct s.suggested_price_cents)
    into v_recent_distinct
  from public.menu_item_price_suggestions s
  where s.menu_item_id = p_menu_item_id
    and s.created_at >= now() - interval '24 hours'
    and s.status::text = any(array['pending', 'approved', 'accepted', 'handled', 'verified']);

  if v_recent_distinct >= 2 then
    v_conflict_state := 'queued';
    v_flags := array_append(v_flags, 'price_conflict');
  end if;

  if coalesce(array_length(v_flags, 1), 0) > 0 then
    v_flags_json := to_jsonb(v_flags);
  end if;

  v_quality_confidence :=
    greatest(
      0::numeric,
      least(
        1::numeric,
        (v_base_confidence * v_user_weight * v_evidence_weight * v_time_weight)
        - least(0.65::numeric, v_anomaly_score * 0.45)
      )
    );

  return jsonb_build_object(
    'user_weight', v_user_weight,
    'evidence_weight', v_evidence_weight,
    'time_weight', v_time_weight,
    'quality_confidence', v_quality_confidence,
    'anomaly_score', v_anomaly_score,
    'anomaly_flags', v_flags_json,
    'conflict_state', v_conflict_state,
    'conflict_variants_24h', v_recent_distinct
  );
end;
$$;

create or replace function public.submit_menu_item_price_suggestion_v4(
  p_menu_item_id uuid,
  p_suggested_price_cents integer,
  p_currency text default 'TRY',
  p_note text default null,
  p_evidence_url text default null,
  p_client_id text default null,
  p_captured_at timestamptz default now()
) returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_result jsonb;
  v_suggestion_id uuid;
  v_quality jsonb := '{}'::jsonb;
  v_force_pending boolean := false;
  v_prev_price integer := null;
  v_conflict_state text := 'none';
  v_anomaly_score numeric := 0;
  v_quality_confidence numeric := 0;
  v_pending_count integer := 0;
begin
  select mi.price_cents
    into v_prev_price
  from public.menu_items mi
  where mi.id = p_menu_item_id
  limit 1;

  v_result := public.submit_menu_item_price_suggestion_v2(
    p_menu_item_id,
    p_suggested_price_cents,
    p_currency,
    p_note,
    p_evidence_url,
    p_client_id,
    p_captured_at
  );

  if coalesce((v_result->>'ok')::boolean, false) is false then
    return v_result;
  end if;

  select s.id
    into v_suggestion_id
  from public.menu_item_price_suggestions s
  where s.menu_item_id = p_menu_item_id
    and s.created_by = auth.uid()
  order by s.created_at desc
  limit 1;

  if v_suggestion_id is null then
    return v_result;
  end if;

  v_quality := public.compute_price_suggestion_quality_v1(
    p_menu_item_id,
    p_suggested_price_cents,
    p_evidence_url,
    coalesce(p_captured_at, now())
  );
  v_conflict_state := coalesce(v_quality->>'conflict_state', 'none');
  v_anomaly_score := coalesce((v_quality->>'anomaly_score')::numeric, 0);
  v_quality_confidence := coalesce((v_quality->>'quality_confidence')::numeric, 0);
  v_force_pending := (v_conflict_state = 'queued') or (v_anomaly_score >= 0.50);

  update public.menu_item_price_suggestions s
  set quality_user_weight = coalesce((v_quality->>'user_weight')::numeric, 1),
      quality_evidence_weight = coalesce((v_quality->>'evidence_weight')::numeric, 1),
      quality_time_weight = coalesce((v_quality->>'time_weight')::numeric, 1),
      quality_confidence = v_quality_confidence,
      anomaly_score = v_anomaly_score,
      anomaly_flags = coalesce(v_quality->'anomaly_flags', '[]'::jsonb),
      conflict_state = v_conflict_state,
      conflict_variants_24h = coalesce((v_quality->>'conflict_variants_24h')::int, 0),
      status = case
        when v_force_pending then 'pending'::public.menu_price_suggestion_status
        else s.status
      end,
      handled_by = case when v_force_pending then null else s.handled_by end,
      handled_at = case when v_force_pending then null else s.handled_at end,
      approved_by = case when v_force_pending then null else s.approved_by end,
      approved_at = case when v_force_pending then null else s.approved_at end,
      onsite_signal = case
        when v_force_pending and v_conflict_state = 'queued' then 'conflict_queue'
        when v_force_pending and v_anomaly_score >= 0.50 then 'anomaly_queue'
        else s.onsite_signal
      end
  where s.id = v_suggestion_id;

  if v_force_pending and coalesce((v_result->>'auto_approved')::boolean, false) then
    if v_prev_price is not null then
      update public.menu_items mi
      set price_cents = v_prev_price,
          updated_at = now()
      where mi.id = p_menu_item_id;
    end if;
  end if;

  select count(*)
    into v_pending_count
  from public.menu_item_price_suggestions s
  where s.menu_item_id = p_menu_item_id
    and s.status = 'pending'::public.menu_price_suggestion_status;

  return v_result
    || jsonb_build_object(
      'suggestion_id', v_suggestion_id,
      'auto_approved', case when v_force_pending then false else coalesce((v_result->>'auto_approved')::boolean, false) end,
      'pending_count', v_pending_count,
      'quality_confidence', v_quality_confidence,
      'anomaly_score', v_anomaly_score,
      'anomaly_flags', coalesce(v_quality->'anomaly_flags', '[]'::jsonb),
      'conflict_state', v_conflict_state,
      'conflict_variants_24h', coalesce((v_quality->>'conflict_variants_24h')::int, 0),
      'queued_for_review', v_force_pending
    );
end;
$$;

create or replace function public.submit_menu_item_price_suggestion_v3(
  p_menu_item_id uuid,
  p_suggested_price_cents integer,
  p_currency text default 'TRY',
  p_note text default null,
  p_evidence_url text default null,
  p_client_id text default null,
  p_captured_at timestamptz default now()
) returns jsonb
language sql
security definer
set search_path = public
as $$
  select public.submit_menu_item_price_suggestion_v4(
    p_menu_item_id,
    p_suggested_price_cents,
    p_currency,
    p_note,
    p_evidence_url,
    p_client_id,
    p_captured_at
  );
$$;

create or replace function public.owner_override_price_suggestion_v1(
  p_suggestion_id uuid,
  p_reason text,
  p_force_price_cents integer default null
) returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid uuid := auth.uid();
  v_reason text := nullif(trim(coalesce(p_reason, '')), '');
  v_s public.menu_item_price_suggestions%rowtype;
  v_price integer;
begin
  if v_uid is null then
    return jsonb_build_object('ok', false, 'error', 'not_authenticated');
  end if;
  if v_reason is null or length(v_reason) < 3 then
    return jsonb_build_object('ok', false, 'error', 'reason_required');
  end if;

  select *
    into v_s
  from public.menu_item_price_suggestions s
  where s.id = p_suggestion_id
  for update;

  if v_s.id is null then
    return jsonb_build_object('ok', false, 'error', 'not_found');
  end if;
  if not public.is_admin() and not public.is_owner_of_business(v_s.business_id) then
    return jsonb_build_object('ok', false, 'error', 'forbidden');
  end if;

  v_price := coalesce(p_force_price_cents, v_s.suggested_price_cents);
  if v_price is null or v_price < 0 then
    return jsonb_build_object('ok', false, 'error', 'bad_price');
  end if;

  update public.menu_items mi
  set price_cents = v_price,
      currency = coalesce(nullif(trim(v_s.currency), ''), mi.currency),
      updated_at = now()
  where mi.id = v_s.menu_item_id;

  insert into public.menu_item_price_history(
    menu_item_id, price_cents, currency, source, created_by
  )
  values (
    v_s.menu_item_id,
    v_price,
    coalesce(nullif(trim(v_s.currency), ''), 'TRY'),
    'owner_override',
    v_uid
  );

  update public.menu_item_price_suggestions s
  set status = 'approved'::public.menu_price_suggestion_status,
      handled_by = v_uid,
      handled_at = now(),
      approved_by = v_uid,
      approved_at = now(),
      quality_confidence = greatest(s.quality_confidence, 0.90),
      conflict_state = case
        when s.conflict_state = 'queued' then 'owner_overridden'
        else s.conflict_state
      end,
      note = coalesce(nullif(s.note, ''), '') || E'\n[owner_override] ' || v_reason
  where s.id = v_s.id;

  insert into public.admin_audit_log(action, target_table, target_id, meta)
  values (
    'owner.price_suggestion.override',
    'menu_item_price_suggestions',
    v_s.id,
    jsonb_build_object(
      'actor_id', v_uid,
      'business_id', v_s.business_id,
      'menu_item_id', v_s.menu_item_id,
      'suggested_price_cents', v_s.suggested_price_cents,
      'applied_price_cents', v_price,
      'reason', v_reason,
      'conflict_state_before', v_s.conflict_state,
      'anomaly_score_before', v_s.anomaly_score
    )
  );

  return jsonb_build_object(
    'ok', true,
    'suggestion_id', v_s.id,
    'applied_price_cents', v_price
  );
end;
$$;

create or replace function public.owner_approve_price_suggestion_v1(p_suggestion_id uuid)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $function$
begin
  return public.owner_override_price_suggestion_v1(
    p_suggestion_id,
    'owner_override_approved',
    null
  );
end;
$function$;

drop function if exists public.owner_list_price_suggestions_v1(uuid, text, integer, integer);
create or replace function public.owner_list_price_suggestions_v1(
  p_business_id uuid,
  p_status text,
  p_limit integer,
  p_offset integer
)
returns table(
  suggestion_id uuid,
  status text,
  created_at timestamp with time zone,
  business_id uuid,
  business_name text,
  menu_item_id uuid,
  item_name text,
  current_price_cents integer,
  suggested_price_cents integer,
  currency text,
  created_by uuid,
  quality_confidence numeric,
  anomaly_score numeric,
  anomaly_flags jsonb,
  conflict_state text,
  conflict_variants_24h integer
)
language sql
security definer
set search_path to 'public'
as $function$
  with owner_businesses as (
    select c.business_id
    from public.owner_claims c
    where c.user_id = auth.uid()
      and c.status = 'approved'
  ),
  target_businesses as (
    select business_id
    from owner_businesses
    where p_business_id is null
    union all
    select p_business_id
    where p_business_id is not null
  )
  select
    s.id as suggestion_id,
    s.status::text,
    s.created_at,
    s.business_id,
    b.name as business_name,
    mi.id as menu_item_id,
    mi.name as item_name,
    mi.price_cents as current_price_cents,
    s.suggested_price_cents,
    s.currency,
    s.created_by,
    s.quality_confidence,
    s.anomaly_score,
    s.anomaly_flags,
    s.conflict_state,
    s.conflict_variants_24h
  from public.menu_item_price_suggestions s
  join target_businesses tb on tb.business_id = s.business_id
  join public.menu_items mi on mi.id = s.menu_item_id
  join public.businesses b on b.id = s.business_id
  where (p_status is null or p_status = '' or s.status::text = p_status)
  order by
    (s.conflict_state = 'queued') desc,
    (coalesce(s.anomaly_score, 0) >= 0.5) desc,
    (s.status = 'pending') desc,
    s.created_at asc
  limit greatest(p_limit, 0) offset greatest(p_offset, 0);
$function$;

drop function if exists public.admin_list_menu_price_suggestions_v2(text, integer, integer, boolean, text);
create or replace function public.admin_list_menu_price_suggestions_v2(
  p_status text default null,
  p_limit integer default 30,
  p_offset integer default 0,
  p_sla_only boolean default false,
  p_assigned text default null
)
returns table(
  suggestion_id uuid,
  status text,
  created_at timestamp with time zone,
  sla_breached boolean,
  business_id uuid,
  business_name text,
  city text,
  district text,
  menu_item_id uuid,
  item_name text,
  current_price_cents integer,
  suggested_price_cents integer,
  currency text,
  created_by uuid,
  assigned_to uuid,
  assigned_at timestamp with time zone,
  quality_confidence numeric,
  anomaly_score numeric,
  anomaly_flags jsonb,
  conflict_state text,
  conflict_variants_24h integer
)
language sql
stable
security definer
set search_path to 'public'
as $function$
  select
    s.id as suggestion_id,
    s.status::text,
    s.created_at,
    (s.status = 'pending' and s.created_at < now() - interval '48 hours') as sla_breached,
    b.id as business_id,
    b.name as business_name,
    b.city,
    b.district,
    mi.id as menu_item_id,
    mi.name as item_name,
    mi.price_cents as current_price_cents,
    s.suggested_price_cents,
    s.currency,
    s.created_by,
    s.handled_by as assigned_to,
    s.handled_at as assigned_at,
    s.quality_confidence,
    s.anomaly_score,
    s.anomaly_flags,
    s.conflict_state,
    s.conflict_variants_24h
  from public.menu_item_price_suggestions s
  join public.menu_items mi on mi.id = s.menu_item_id
  join public.businesses b on b.id = s.business_id
  where public.is_admin()
    and (
      p_status is null
      or p_status = ''
      or s.status::text = p_status
    )
    and (
      p_assigned is null
      or p_assigned = ''
      or (p_assigned = 'me' and s.handled_by = auth.uid())
      or (p_assigned = 'unassigned' and s.handled_by is null)
      or s.handled_by::text = p_assigned
    )
    and (not p_sla_only or (s.status = 'pending' and s.created_at < now() - interval '48 hours'))
  order by
    (s.conflict_state = 'queued') desc,
    (coalesce(s.anomaly_score, 0) >= 0.5) desc,
    (s.status = 'pending') desc,
    s.created_at asc
  limit greatest(p_limit, 0) offset greatest(p_offset, 0);
$function$;

grant all on function public.compute_price_suggestion_quality_v1(uuid, integer, text, timestamptz) to authenticated;
grant all on function public.compute_price_suggestion_quality_v1(uuid, integer, text, timestamptz) to service_role;
grant all on function public.submit_menu_item_price_suggestion_v4(uuid, integer, text, text, text, text, timestamptz) to anon;
grant all on function public.submit_menu_item_price_suggestion_v4(uuid, integer, text, text, text, text, timestamptz) to authenticated;
grant all on function public.submit_menu_item_price_suggestion_v4(uuid, integer, text, text, text, text, timestamptz) to service_role;
grant all on function public.owner_override_price_suggestion_v1(uuid, text, integer) to authenticated;
grant all on function public.owner_override_price_suggestion_v1(uuid, text, integer) to service_role;

commit;

-- ===== END MIGRATION: 20260322000012_data_quality_engine.sql =====

-- ===== BEGIN MIGRATION: 20260322000013_edge_zero_trust_waf.sql =====
begin;

create table if not exists public.edge_ip_denylist (
  id uuid primary key default gen_random_uuid(),
  ip_hash text not null unique,
  reason text not null default 'manual_block',
  is_active boolean not null default true,
  expires_at timestamptz null,
  created_at timestamptz not null default now(),
  created_by uuid null
);

alter table public.edge_ip_denylist enable row level security;

drop policy if exists edge_ip_denylist_admin_all on public.edge_ip_denylist;
create policy edge_ip_denylist_admin_all
  on public.edge_ip_denylist
  for all
  using (public.is_admin())
  with check (public.is_admin());

create index if not exists idx_edge_ip_denylist_active_v1
  on public.edge_ip_denylist(is_active, expires_at);

create or replace function public.is_edge_ip_denied_v1(p_ip_hash text)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists(
    select 1
    from public.edge_ip_denylist d
    where d.ip_hash = p_ip_hash
      and d.is_active = true
      and (d.expires_at is null or d.expires_at > now())
  );
$$;

grant all on function public.is_edge_ip_denied_v1(text) to authenticated;
grant all on function public.is_edge_ip_denied_v1(text) to service_role;

create or replace function public.upsert_user_location_prefs_v1(
  p_city text,
  p_district text,
  p_neighborhood text default null,
  p_mode text default 'auto',
  p_lat double precision default null,
  p_lng double precision default null
) returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid uuid := auth.uid();
  v_lat double precision := null;
  v_lng double precision := null;
begin
  if v_uid is null then
    return jsonb_build_object('ok', false, 'error', 'not_authenticated');
  end if;

  -- PII minimization: keep coarse location only if coordinates are sent.
  if p_lat is not null then
    v_lat := round((p_lat::numeric), 3)::double precision;
  end if;
  if p_lng is not null then
    v_lng := round((p_lng::numeric), 3)::double precision;
  end if;

  insert into public.user_location_prefs (
    user_id, city, district, neighborhood, mode, lat, lng, updated_at
  )
  values (
    v_uid,
    trim(coalesce(p_city, '')),
    trim(coalesce(p_district, '')),
    nullif(trim(coalesce(p_neighborhood, '')), ''),
    coalesce(nullif(trim(coalesce(p_mode, '')), ''), 'auto'),
    v_lat,
    v_lng,
    now()
  )
  on conflict (user_id) do update
    set city = excluded.city,
        district = excluded.district,
        neighborhood = excluded.neighborhood,
        mode = excluded.mode,
        lat = excluded.lat,
        lng = excluded.lng,
        updated_at = now();

  return jsonb_build_object('ok', true);
end;
$$;

grant all on function public.upsert_user_location_prefs_v1(text, text, text, text, double precision, double precision) to authenticated;
grant all on function public.upsert_user_location_prefs_v1(text, text, text, text, double precision, double precision) to service_role;

create or replace function public.upsert_user_location_prefs_v1(
  p_city text,
  p_district text,
  p_neighborhood text default null,
  p_mode text default 'auto'
) returns jsonb
language sql
security definer
set search_path = public
as $$
  select public.upsert_user_location_prefs_v1(
    p_city,
    p_district,
    p_neighborhood,
    p_mode,
    null,
    null
  );
$$;

grant all on function public.upsert_user_location_prefs_v1(text, text, text, text) to authenticated;
grant all on function public.upsert_user_location_prefs_v1(text, text, text, text) to service_role;

commit;

-- ===== END MIGRATION: 20260322000013_edge_zero_trust_waf.sql =====

-- ===== BEGIN MIGRATION: 20260322000014_release_ops_runtime_flags.sql =====
begin;

create table if not exists public.runtime_release_controls (
  id boolean primary key default true check (id = true),
  global_kill_switch boolean not null default false,
  updated_by uuid null,
  updated_at timestamptz not null default now()
);

insert into public.runtime_release_controls (id, global_kill_switch)
values (true, false)
on conflict (id) do nothing;

create table if not exists public.runtime_feature_flags (
  key text primary key,
  enabled boolean not null default false,
  rollout_percent int not null default 100 check (rollout_percent between 0 and 100),
  allowed_regions text[] not null default '{}',
  blocked_regions text[] not null default '{}',
  metadata jsonb not null default '{}'::jsonb,
  updated_by uuid null,
  updated_at timestamptz not null default now()
);

alter table public.runtime_release_controls enable row level security;
alter table public.runtime_feature_flags enable row level security;

drop policy if exists runtime_release_controls_select_all on public.runtime_release_controls;
create policy runtime_release_controls_select_all
on public.runtime_release_controls
for select
to authenticated, anon
using (true);

drop policy if exists runtime_release_controls_admin_write on public.runtime_release_controls;
create policy runtime_release_controls_admin_write
on public.runtime_release_controls
for all
to authenticated
using (coalesce(public.is_admin(), false))
with check (coalesce(public.is_admin(), false));

drop policy if exists runtime_feature_flags_select_all on public.runtime_feature_flags;
create policy runtime_feature_flags_select_all
on public.runtime_feature_flags
for select
to authenticated, anon
using (true);

drop policy if exists runtime_feature_flags_admin_write on public.runtime_feature_flags;
create policy runtime_feature_flags_admin_write
on public.runtime_feature_flags
for all
to authenticated
using (coalesce(public.is_admin(), false))
with check (coalesce(public.is_admin(), false));

create or replace function public.get_runtime_feature_flags_v1(
  p_user_id uuid default auth.uid()
)
returns jsonb
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_global_kill boolean := false;
  v_flags jsonb := '{}'::jsonb;
begin
  select coalesce(rc.global_kill_switch, false)
    into v_global_kill
  from public.runtime_release_controls rc
  where rc.id = true
  limit 1;

  select coalesce(
    jsonb_object_agg(
      rf.key,
      jsonb_build_object(
        'enabled', rf.enabled,
        'rollout_percent', rf.rollout_percent,
        'allowed_regions', rf.allowed_regions,
        'blocked_regions', rf.blocked_regions
      )
    ),
    '{}'::jsonb
  )
  into v_flags
  from public.runtime_feature_flags rf;

  return jsonb_build_object(
    'global_kill_switch', v_global_kill,
    'flags', v_flags
  );
end;
$$;

grant execute on function public.get_runtime_feature_flags_v1(uuid) to anon, authenticated;

commit;

-- ===== END MIGRATION: 20260322000014_release_ops_runtime_flags.sql =====

-- ===== BEGIN MIGRATION: 20260322000015_growth_experiments.sql =====
begin;

create table if not exists public.runtime_experiments (
  key text primary key,
  enabled boolean not null default false,
  variants jsonb not null default '{}'::jsonb,
  allowed_regions text[] not null default '{}',
  blocked_regions text[] not null default '{}',
  updated_by uuid null,
  updated_at timestamptz not null default now()
);

alter table public.runtime_experiments enable row level security;

drop policy if exists runtime_experiments_select_all on public.runtime_experiments;
create policy runtime_experiments_select_all
on public.runtime_experiments
for select
to authenticated, anon
using (true);

drop policy if exists runtime_experiments_admin_write on public.runtime_experiments;
create policy runtime_experiments_admin_write
on public.runtime_experiments
for all
to authenticated
using (coalesce(public.is_admin(), false))
with check (coalesce(public.is_admin(), false));

insert into public.runtime_experiments (key, enabled, variants)
values
  ('home_category_layout', true, '{"horizontal":50,"grid2x4":50}'::jsonb),
  ('verify_price_cta_placement', true, '{"bottom":50,"top":50}'::jsonb)
on conflict (key) do nothing;

create or replace function public.get_runtime_experiments_v1(
  p_user_id uuid default auth.uid()
)
returns jsonb
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_payload jsonb := '{}'::jsonb;
begin
  select coalesce(
    jsonb_object_agg(
      e.key,
      jsonb_build_object(
        'enabled', e.enabled,
        'variants', e.variants,
        'allowed_regions', e.allowed_regions,
        'blocked_regions', e.blocked_regions
      )
    ),
    '{}'::jsonb
  )
  into v_payload
  from public.runtime_experiments e;
  return v_payload;
end;
$$;

grant execute on function public.get_runtime_experiments_v1(uuid) to anon, authenticated;

commit;

-- ===== END MIGRATION: 20260322000015_growth_experiments.sql =====

-- ===== BEGIN MIGRATION: 20260322000016_moderation_ops_sla_roles_appeals.sql =====
-- Operations and moderation scaling:
-- - role expansion: community_mod
-- - queue SLA alignment: reports 24h, owner claims 48h
-- - decision templates
-- - moderation appeal flow

create or replace function public.get_app_role_v1()
returns text
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_claim jsonb := auth.jwt();
  v_role text;
begin
  v_role := lower(
    coalesce(
      v_claim -> 'app_metadata' ->> 'role',
      v_claim -> 'user_metadata' ->> 'role',
      'user'
    )
  );

  if v_role not in ('user', 'owner', 'community_mod', 'admin') then
    v_role := 'user';
  end if;
  return v_role;
end;
$$;

create or replace function public.current_user_role_v1()
returns text
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_uid uuid := auth.uid();
  v_claim jsonb := auth.jwt();
  v_role text := lower(
    coalesce(
      v_claim -> 'app_metadata' ->> 'role',
      v_claim -> 'user_metadata' ->> 'role',
      ''
    )
  );
  v_has_owner boolean := false;
begin
  if v_uid is null then
    return 'user';
  end if;

  if v_role in ('admin', 'community_mod') then
    return v_role;
  end if;

  select exists(
    select 1
    from public.owner_claims oc
    where oc.user_id = v_uid
      and oc.status::text in ('approved', 'accepted')
  )
  into v_has_owner;

  if v_has_owner then
    return 'owner';
  end if;

  return 'user';
end;
$$;

create or replace function public.is_admin_or_community_mod_v1()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select public.is_admin()
    or lower(coalesce(public.get_app_role_v1(), 'user')) = 'community_mod';
$$;

create table if not exists public.moderation_decision_templates (
  id uuid primary key default gen_random_uuid(),
  scope text not null check (scope in ('report', 'claim', 'appeal')),
  decision text not null check (decision in ('approved', 'rejected', 'needs_info')),
  title text not null,
  body text not null,
  locale text not null default 'tr-TR',
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (scope, decision, title, locale)
);

insert into public.moderation_decision_templates(scope, decision, title, body, locale)
values
  ('report', 'approved', 'Ihlal Teyit', 'Raporunuz incelendi. İhlal teyit edildi ve gerekli işlem uygulandı.', 'tr-TR'),
  ('report', 'rejected', 'Kanıt Yetersiz', 'Raporunuz incelendi. Mevcut kanıt nedeniyle işlem uygulanamadı.', 'tr-TR'),
  ('claim', 'approved', 'Sahiplik Onayı', 'Talebiniz incelendi ve işletme sahipliği onaylandı.', 'tr-TR'),
  ('claim', 'rejected', 'Sahiplik Reddi', 'Talebiniz incelendi ancak doğrulama kriterleri sağlanamadı.', 'tr-TR'),
  ('appeal', 'approved', 'İtiraz Kabul', 'İtirazınız yeniden incelendi ve kararınız güncellendi.', 'tr-TR'),
  ('appeal', 'rejected', 'İtiraz Sonucu', 'İtirazınız incelendi. İlk karar geçerliliğini koruyor.', 'tr-TR')
on conflict (scope, decision, title, locale) do nothing;

alter table public.moderation_decision_templates enable row level security;

do $$
begin
  if not exists (
    select 1
    from pg_policies
    where schemaname = 'public'
      and tablename = 'moderation_decision_templates'
      and policyname = 'moderation_templates_read_v1'
  ) then
    create policy moderation_templates_read_v1
      on public.moderation_decision_templates
      for select
      to authenticated
      using (is_active = true and locale = 'tr-TR');
  end if;
end $$;

create table if not exists public.moderation_appeals (
  id uuid primary key default gen_random_uuid(),
  source_type text not null check (source_type in ('report', 'claim')),
  source_id uuid not null,
  appellant_user_id uuid not null,
  reason text not null,
  details text,
  status text not null default 'pending' check (status in ('pending', 'approved', 'rejected')),
  decision_note text,
  decided_by uuid,
  decided_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_moderation_appeals_status_created_at
  on public.moderation_appeals(status, created_at desc);
create index if not exists idx_moderation_appeals_source
  on public.moderation_appeals(source_type, source_id);
create index if not exists idx_moderation_appeals_appellant
  on public.moderation_appeals(appellant_user_id, created_at desc);

alter table public.moderation_appeals enable row level security;

do $$
begin
  if not exists (
    select 1 from pg_policies
    where schemaname = 'public'
      and tablename = 'moderation_appeals'
      and policyname = 'appeals_insert_own_v1'
  ) then
    create policy appeals_insert_own_v1
      on public.moderation_appeals
      for insert
      to authenticated
      with check (auth.uid() = appellant_user_id);
  end if;

  if not exists (
    select 1 from pg_policies
    where schemaname = 'public'
      and tablename = 'moderation_appeals'
      and policyname = 'appeals_select_owner_or_mod_v1'
  ) then
    create policy appeals_select_owner_or_mod_v1
      on public.moderation_appeals
      for select
      to authenticated
      using (
        auth.uid() = appellant_user_id
        or public.is_admin_or_community_mod_v1()
      );
  end if;

  if not exists (
    select 1 from pg_policies
    where schemaname = 'public'
      and tablename = 'moderation_appeals'
      and policyname = 'appeals_update_mod_only_v1'
  ) then
    create policy appeals_update_mod_only_v1
      on public.moderation_appeals
      for update
      to authenticated
      using (public.is_admin_or_community_mod_v1())
      with check (public.is_admin_or_community_mod_v1());
  end if;
end $$;

create or replace function public.get_moderation_templates_v1(
  p_scope text default null
)
returns table(
  id uuid,
  scope text,
  decision text,
  title text,
  body text,
  locale text
)
language sql
stable
security definer
set search_path = public
as $$
  select
    t.id,
    t.scope,
    t.decision,
    t.title,
    t.body,
    t.locale
  from public.moderation_decision_templates t
  where t.is_active = true
    and (p_scope is null or p_scope = '' or t.scope = p_scope)
  order by t.scope, t.decision, t.title;
$$;

create or replace function public.submit_moderation_appeal_v1(
  p_source_type text,
  p_source_id uuid,
  p_reason text,
  p_details text default null
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid uuid := auth.uid();
  v_appeal_id uuid;
begin
  if v_uid is null then
    return jsonb_build_object('ok', false, 'error', 'not_authenticated');
  end if;

  if coalesce(trim(p_source_type), '') not in ('report', 'claim') then
    return jsonb_build_object('ok', false, 'error', 'invalid_source_type');
  end if;
  if p_source_id is null then
    return jsonb_build_object('ok', false, 'error', 'missing_source_id');
  end if;
  if coalesce(trim(p_reason), '') = '' then
    return jsonb_build_object('ok', false, 'error', 'reason_required');
  end if;

  if exists (
    select 1
    from public.moderation_appeals a
    where a.source_type = p_source_type
      and a.source_id = p_source_id
      and a.appellant_user_id = v_uid
      and a.status = 'pending'
  ) then
    return jsonb_build_object('ok', false, 'error', 'appeal_already_pending');
  end if;

  insert into public.moderation_appeals(
    source_type,
    source_id,
    appellant_user_id,
    reason,
    details
  )
  values (
    trim(p_source_type),
    p_source_id,
    v_uid,
    left(trim(p_reason), 120),
    nullif(trim(coalesce(p_details, '')), '')
  )
  returning id into v_appeal_id;

  return jsonb_build_object('ok', true, 'appeal_id', v_appeal_id);
end;
$$;

create or replace function public.admin_list_moderation_appeals_v1(
  p_status text default null,
  p_limit integer default 50,
  p_offset integer default 0
)
returns table(
  appeal_id uuid,
  source_type text,
  source_id uuid,
  appellant_user_id uuid,
  reason text,
  details text,
  status text,
  decision_note text,
  decided_by uuid,
  decided_at timestamptz,
  created_at timestamptz
)
language sql
stable
security definer
set search_path = public
as $$
  select
    a.id as appeal_id,
    a.source_type,
    a.source_id,
    a.appellant_user_id,
    a.reason,
    a.details,
    a.status,
    a.decision_note,
    a.decided_by,
    a.decided_at,
    a.created_at
  from public.moderation_appeals a
  where public.is_admin_or_community_mod_v1()
    and (p_status is null or p_status = '' or a.status = p_status)
  order by
    (a.status = 'pending') desc,
    a.created_at asc
  limit greatest(p_limit, 1)
  offset greatest(p_offset, 0);
$$;

create or replace function public.admin_decide_moderation_appeal_v1(
  p_appeal_id uuid,
  p_decision text,
  p_note text default null
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid uuid := auth.uid();
begin
  if v_uid is null then
    return jsonb_build_object('ok', false, 'error', 'not_authenticated');
  end if;
  if not public.is_admin_or_community_mod_v1() then
    return jsonb_build_object('ok', false, 'error', 'forbidden');
  end if;
  if p_appeal_id is null then
    return jsonb_build_object('ok', false, 'error', 'missing_appeal_id');
  end if;
  if p_decision not in ('approved', 'rejected') then
    return jsonb_build_object('ok', false, 'error', 'invalid_decision');
  end if;

  update public.moderation_appeals
  set
    status = p_decision,
    decision_note = nullif(trim(coalesce(p_note, '')), ''),
    decided_by = v_uid,
    decided_at = now(),
    updated_at = now()
  where id = p_appeal_id;

  if not found then
    return jsonb_build_object('ok', false, 'error', 'appeal_not_found');
  end if;

  return jsonb_build_object('ok', true);
end;
$$;

create or replace function public.admin_list_reports_v4(
  p_status text default null,
  p_limit integer default 50,
  p_offset integer default 0,
  p_q text default null,
  p_assigned text default null,
  p_sla_only boolean default false
)
returns table(
  id uuid,
  created_at timestamptz,
  durum text,
  reason text,
  details text,
  user_id uuid,
  business_id uuid,
  review_id uuid,
  menu_item_photo_id uuid,
  target_type text,
  target_id uuid,
  assigned_to uuid,
  assigned_at timestamptz,
  handled_by uuid,
  handled_at timestamptz,
  admin_note text,
  age_hours double precision,
  sla_breached boolean
)
language sql
security definer
set search_path = public
as $$
  with base as (
    select
      r.*,
      (extract(epoch from (now() - r.created_at))/3600.0)::float as age_hours,
      (
        r.handled_at is null
        and r.durum in ('acik','inceleniyor')
        and r.created_at < now() - interval '24 hours'
      ) as sla_breached
    from public.reports r
    where public.is_admin_or_community_mod_v1()
      and (p_status is null or r.durum = p_status)
      and (
        p_assigned is null
        or (p_assigned='me' and r.assigned_to = auth.uid())
        or (p_assigned='unassigned' and r.assigned_to is null)
      )
      and (
        p_q is null
        or r.reason ilike ('%'||p_q||'%')
        or r.details ilike ('%'||p_q||'%')
        or r.admin_note ilike ('%'||p_q||'%')
      )
  )
  select
    id, created_at, durum, reason, details, user_id, business_id, review_id,
    menu_item_photo_id, target_type, target_id,
    assigned_to, assigned_at, handled_by, handled_at, admin_note,
    age_hours, sla_breached
  from base
  where (not p_sla_only) or sla_breached
  order by
    sla_breached desc,
    created_at desc
  limit greatest(p_limit, 1)
  offset greatest(p_offset, 0);
$$;

create or replace function public.admin_list_owner_claims_v3(
  p_status text default null,
  p_limit integer default 50,
  p_offset integer default 0,
  p_sla_only boolean default false,
  p_assigned text default null,
  p_q text default null
)
returns table(
  claim_id uuid,
  status text,
  created_at timestamptz,
  age_days double precision,
  sla_breached boolean,
  business_id uuid,
  full_name text,
  phone text,
  evidence_url text,
  note text,
  admin_note text,
  assigned_to uuid,
  assigned_at timestamptz,
  auto_moderated boolean
)
language sql
stable
security definer
set search_path to 'public'
as $function$
  select
    c.id as claim_id,
    c.status::text,
    c.created_at,
    extract(epoch from (now() - c.created_at)) / 86400.0 as age_days,
    (c.status = 'pending' and c.created_at < now() - interval '48 hours') as sla_breached,
    c.business_id,
    c.full_name,
    c.phone,
    c.evidence_url,
    c.note,
    c.admin_note,
    c.handled_by as assigned_to,
    c.handled_at as assigned_at,
    coalesce(c.auto_moderated, false) as auto_moderated
  from public.owner_claims c
  where public.is_admin()
    and (
      p_status is null
      or p_status = ''
      or c.status::text = p_status
    )
    and (
      p_assigned is null
      or p_assigned = ''
      or (p_assigned = 'me' and c.handled_by = auth.uid())
      or (p_assigned = 'unassigned' and c.handled_by is null)
      or c.handled_by::text = p_assigned
    )
    and (
      p_q is null
      or p_q = ''
      or c.id::text ilike ('%' || p_q || '%')
      or coalesce(c.full_name, '') ilike ('%' || p_q || '%')
      or coalesce(c.phone, '') ilike ('%' || p_q || '%')
    )
    and (not p_sla_only or (c.status = 'pending' and c.created_at < now() - interval '48 hours'))
  order by (c.status = 'pending') desc, c.created_at asc
  limit greatest(p_limit, 0) offset greatest(p_offset, 0);
$function$;

grant all on function public.get_app_role_v1() to authenticated;
grant all on function public.current_user_role_v1() to authenticated;
grant all on function public.is_admin_or_community_mod_v1() to authenticated, service_role;
grant all on function public.get_moderation_templates_v1(text) to authenticated, service_role;
grant all on function public.submit_moderation_appeal_v1(text, uuid, text, text) to authenticated, service_role;
grant all on function public.admin_list_moderation_appeals_v1(text, integer, integer) to authenticated, service_role;
grant all on function public.admin_decide_moderation_appeal_v1(uuid, text, text) to authenticated, service_role;

-- ===== END MIGRATION: 20260322000016_moderation_ops_sla_roles_appeals.sql =====

-- ===== BEGIN MIGRATION: 20260322000017_temp_uploads_ttl_helper.sql =====
-- TTL helper view + mark function for temp uploads

create or replace view public.expired_temp_uploads_v1 as
select
  t.*
from public.temp_uploads t
where t.status in ('pending', 'rejected')
  and t.expires_at < now();

create or replace function public.mark_expired_temp_uploads_v1(
  p_limit int default 500
)
returns int
language plpgsql
security definer
set search_path = public
as $$
declare
  v_count int := 0;
begin
  with target as (
    select t.id
    from public.temp_uploads t
    where t.status in ('pending', 'rejected')
      and t.expires_at < now()
    order by t.expires_at asc
    limit greatest(coalesce(p_limit, 500), 1)
  )
  update public.temp_uploads t
  set
    status = 'expired',
    reviewed_at = coalesce(t.reviewed_at, now())
  where t.id in (select id from target);

  get diagnostics v_count = row_count;
  return v_count;
end;
$$;

grant select on public.expired_temp_uploads_v1 to authenticated, service_role;
grant execute on function public.mark_expired_temp_uploads_v1(int) to service_role;


-- ===== END MIGRATION: 20260322000017_temp_uploads_ttl_helper.sql =====

-- ===== BEGIN MIGRATION: 20260322000018_storage_deletion_queue_and_temp_upload_cleanup.sql =====
-- Storage deletion queue + temp upload cleanup wiring

create table if not exists public.storage_deletion_queue (
  id uuid primary key default gen_random_uuid(),
  bucket text not null,
  path text not null,
  reason text not null,
  scheduled_at timestamptz not null default now(),
  processed_at timestamptz null,
  attempts int not null default 0,
  last_error text null
);

create index if not exists storage_deletion_queue_pending_idx
  on public.storage_deletion_queue (processed_at, scheduled_at)
  where processed_at is null;

create index if not exists storage_deletion_queue_reason_idx
  on public.storage_deletion_queue (reason, scheduled_at desc);

create unique index if not exists storage_deletion_queue_dedupe_idx
  on public.storage_deletion_queue (bucket, path, reason)
  where processed_at is null;

alter table public.storage_deletion_queue enable row level security;

drop policy if exists storage_deletion_queue_admin_select on public.storage_deletion_queue;
create policy storage_deletion_queue_admin_select
on public.storage_deletion_queue
for select
to authenticated
using (coalesce(public.is_admin(), false));

drop policy if exists storage_deletion_queue_admin_write on public.storage_deletion_queue;
create policy storage_deletion_queue_admin_write
on public.storage_deletion_queue
for all
to authenticated
using (coalesce(public.is_admin(), false))
with check (coalesce(public.is_admin(), false));

grant all on public.storage_deletion_queue to service_role;

create or replace function public.promote_temp_upload_to_menu_asset_v1(
  p_temp_upload_id uuid,
  p_asset_type text,
  p_menu_version int
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_actor uuid := auth.uid();
  v_temp public.temp_uploads%rowtype;
  v_menu_asset_id uuid;
  v_asset_type text;
begin
  if v_actor is null then
    raise exception 'auth_required';
  end if;

  select *
    into v_temp
  from public.temp_uploads t
  where t.id = p_temp_upload_id
  for update;

  if not found then
    return jsonb_build_object('ok', false, 'error', 'temp_upload_not_found');
  end if;

  if not (
    coalesce(public.is_admin(), false)
    or coalesce(public.is_owner_of_business(v_temp.business_id), false)
  ) then
    raise exception 'not_authorized';
  end if;

  if v_temp.status <> 'pending' then
    return jsonb_build_object('ok', false, 'error', 'temp_upload_not_pending');
  end if;

  v_asset_type := lower(trim(coalesce(p_asset_type, 'menu_page')));
  if v_asset_type not in ('menu_page', 'menu_pdf', 'thumbnail') then
    return jsonb_build_object('ok', false, 'error', 'invalid_asset_type');
  end if;

  insert into public.menu_assets (
    business_id,
    menu_version,
    asset_type,
    storage_bucket,
    storage_path,
    source,
    created_by
  )
  values (
    v_temp.business_id,
    greatest(coalesce(p_menu_version, 1), 1),
    v_asset_type,
    v_temp.storage_bucket,
    v_temp.storage_path,
    'user_promoted',
    v_actor
  )
  returning id into v_menu_asset_id;

  update public.temp_uploads t
  set
    status = 'promoted',
    reviewed_by = v_actor,
    reviewed_at = now()
  where t.id = v_temp.id;

  if coalesce(v_temp.storage_path, '') <> '' then
    insert into public.storage_deletion_queue (bucket, path, reason)
    values (
      coalesce(nullif(v_temp.storage_bucket, ''), 'temp'),
      v_temp.storage_path,
      'promoted_cleanup'
    )
    on conflict do nothing;
  end if;

  return jsonb_build_object(
    'ok', true,
    'menu_asset_id', v_menu_asset_id,
    'temp_upload_id', v_temp.id
  );
end;
$$;

grant execute on function public.promote_temp_upload_to_menu_asset_v1(uuid, text, int)
  to authenticated, service_role;

create or replace function public.mark_expired_temp_uploads_v1(
  p_limit int default 500
)
returns int
language plpgsql
security definer
set search_path = public
as $$
declare
  v_count int := 0;
begin
  with target as (
    select
      t.id,
      t.storage_bucket,
      t.storage_path
    from public.temp_uploads t
    where t.status in ('pending', 'rejected')
      and t.expires_at < now()
    order by t.expires_at asc
    limit greatest(coalesce(p_limit, 500), 1)
  ),
  updated as (
    update public.temp_uploads t
    set
      status = 'expired',
      reviewed_at = coalesce(t.reviewed_at, now())
    where t.id in (select id from target)
    returning t.id
  ),
  queued as (
    insert into public.storage_deletion_queue (bucket, path, reason)
    select
      coalesce(nullif(target.storage_bucket, ''), 'temp'),
      target.storage_path,
      'ttl_cleanup'
    from target
    join updated on updated.id = target.id
    where coalesce(target.storage_path, '') <> ''
    on conflict do nothing
    returning id
  )
  select count(*) into v_count
  from updated;

  return v_count;
end;
$$;

grant execute on function public.mark_expired_temp_uploads_v1(int) to service_role;

-- ===== END MIGRATION: 20260322000018_storage_deletion_queue_and_temp_upload_cleanup.sql =====

-- ===== BEGIN MIGRATION: 20260322000019_menu_versioning_metadata.sql =====
begin;

alter table if exists public.menus
  add column if not exists version int not null default 1,
  add column if not exists source text not null default 'owner',
  add column if not exists confidence_score numeric not null default 0,
  add column if not exists updated_at timestamptz not null default now();

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'menus_source_check_v1'
  ) then
    alter table public.menus
      add constraint menus_source_check_v1
      check (source in ('owner', 'admin', 'user_promoted'));
  end if;
end $$;

create or replace function public.bump_menu_version_v1()
returns trigger
language plpgsql
as $$
begin
  new.updated_at := now();

  if tg_op = 'INSERT' then
    new.version := coalesce(new.version, 1);
    new.source := coalesce(nullif(trim(coalesce(new.source, '')), ''), 'owner');
    new.confidence_score := greatest(0, least(1, coalesce(new.confidence_score, 0)));
    return new;
  end if;

  if (
    new.title is distinct from old.title
    or new.kind is distinct from old.kind
    or new.active_from is distinct from old.active_from
    or new.active_to is distinct from old.active_to
    or new.status is distinct from old.status
  ) then
    new.version := greatest(coalesce(old.version, 1) + 1, 1);
  else
    new.version := coalesce(old.version, 1);
  end if;

  new.source := coalesce(nullif(trim(coalesce(new.source, '')), ''), old.source, 'owner');
  new.confidence_score := greatest(0, least(1, coalesce(new.confidence_score, old.confidence_score, 0)));
  return new;
end;
$$;

drop trigger if exists trg_menus_versioning_v1 on public.menus;
create trigger trg_menus_versioning_v1
before insert or update on public.menus
for each row execute function public.bump_menu_version_v1();

commit;

-- ===== END MIGRATION: 20260322000019_menu_versioning_metadata.sql =====

-- ===== BEGIN MIGRATION: 20260323000025_embeds_links.sql =====
-- URL-only embeds storage for users/businesses
create table if not exists public.embeds (
  id uuid primary key default gen_random_uuid(),
  owner_type text not null check (owner_type in ('user', 'business')),
  owner_id uuid not null,
  provider text not null check (provider in ('youtube', 'instagram', 'facebook', 'unknown')),
  url_raw text not null,
  url_normalized text not null,
  title text null,
  thumbnail_url text null,
  created_at timestamptz not null default now(),
  created_by uuid null references auth.users(id) on delete set null
);

create index if not exists embeds_owner_created_idx
  on public.embeds (owner_type, owner_id, created_at desc);

create index if not exists embeds_provider_created_idx
  on public.embeds (provider, created_at desc);

create unique index if not exists embeds_owner_url_normalized_uniq
  on public.embeds (owner_type, owner_id, url_normalized);

alter table public.embeds enable row level security;

drop policy if exists embeds_select_public on public.embeds;
create policy embeds_select_public
  on public.embeds
  for select
  using (true);

drop policy if exists embeds_insert_user_self on public.embeds;
create policy embeds_insert_user_self
  on public.embeds
  for insert
  with check (
    auth.uid() is not null
    and owner_type = 'user'
    and owner_id = auth.uid()
    and created_by = auth.uid()
  );

drop policy if exists embeds_insert_business_owner_admin on public.embeds;
create policy embeds_insert_business_owner_admin
  on public.embeds
  for insert
  with check (
    auth.uid() is not null
    and owner_type = 'business'
    and created_by = auth.uid()
    and (public.is_admin() or public.is_owner_of_business(owner_id))
  );

drop policy if exists embeds_update_owner_admin on public.embeds;
create policy embeds_update_owner_admin
  on public.embeds
  for update
  using (
    public.is_admin()
    or (
      owner_type = 'user'
      and owner_id = auth.uid()
      and created_by = auth.uid()
    )
    or (
      owner_type = 'business'
      and public.is_owner_of_business(owner_id)
    )
  )
  with check (
    public.is_admin()
    or (
      owner_type = 'user'
      and owner_id = auth.uid()
      and created_by = auth.uid()
    )
    or (
      owner_type = 'business'
      and public.is_owner_of_business(owner_id)
    )
  );

drop policy if exists embeds_delete_owner_admin on public.embeds;
create policy embeds_delete_owner_admin
  on public.embeds
  for delete
  using (
    public.is_admin()
    or (
      owner_type = 'user'
      and owner_id = auth.uid()
      and created_by = auth.uid()
    )
    or (
      owner_type = 'business'
      and public.is_owner_of_business(owner_id)
    )
  );

grant select on public.embeds to anon, authenticated;
grant insert, update, delete on public.embeds to authenticated;
grant all on public.embeds to service_role;

-- ===== END MIGRATION: 20260323000025_embeds_links.sql =====

-- ===== BEGIN MIGRATION: 20260323000026_db_cleanup_safe.sql =====
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

-- ===== END MIGRATION: 20260323000026_db_cleanup_safe.sql =====

-- ===== BEGIN MIGRATION: 20260323000027_db_cleanup_drop_plan.sql =====
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
-- where c.refobjid = 'public.admin_business_suggestions_queue_v1'::regclass;

-- ===== END MIGRATION: 20260323000027_db_cleanup_drop_plan.sql =====

-- ===== BEGIN MIGRATION: 20260323000028_qr_menu_schema_sync.sql =====
-- Sync QR menu schema with existing production DB
-- Safe/idempotent migration for mixed legacy schema

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_type t
    JOIN pg_namespace n ON n.oid = t.typnamespace
    WHERE n.nspname = 'public' AND t.typname = 'translation_entity_type'
  ) THEN
    CREATE TYPE public.translation_entity_type AS ENUM ('business', 'category', 'item');
  END IF;
END
$$;

CREATE TABLE IF NOT EXISTS public.menu_categories (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
  sort int NOT NULL DEFAULT 0,
  is_active boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.menu_translations (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  entity_type public.translation_entity_type NOT NULL,
  entity_id uuid NOT NULL,
  locale text NOT NULL,
  name text NOT NULL,
  description text,
  created_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT menu_translations_unique UNIQUE (entity_type, entity_id, locale)
);

ALTER TABLE public.menu_items ADD COLUMN IF NOT EXISTS category_id uuid REFERENCES public.menu_categories(id) ON DELETE SET NULL;
ALTER TABLE public.menu_items ADD COLUMN IF NOT EXISTS is_available boolean NOT NULL DEFAULT true;
ALTER TABLE public.menu_items ADD COLUMN IF NOT EXISTS image_url text;
ALTER TABLE public.menu_items ADD COLUMN IF NOT EXISTS tags jsonb NOT NULL DEFAULT '[]'::jsonb;
ALTER TABLE public.menu_items ADD COLUMN IF NOT EXISTS sort int NOT NULL DEFAULT 0;

CREATE INDEX IF NOT EXISTS idx_menu_categories_business_id ON public.menu_categories (business_id, sort);
CREATE INDEX IF NOT EXISTS idx_menu_translations_entity ON public.menu_translations (entity_type, entity_id, locale);
CREATE INDEX IF NOT EXISTS idx_menu_items_category_sort ON public.menu_items (business_id, category_id, sort);

ALTER TABLE public.menu_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.menu_translations ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public' AND tablename = 'menu_categories' AND policyname = 'menu_categories_owner_all'
  ) THEN
    EXECUTE $sql$
      CREATE POLICY menu_categories_owner_all
      ON public.menu_categories
      FOR ALL
      TO authenticated
      USING (is_admin() OR is_owner_of_business(business_id))
      WITH CHECK (is_admin() OR is_owner_of_business(business_id))
    $sql$;
  END IF;
END
$$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public' AND tablename = 'menu_categories' AND policyname = 'menu_categories_public_read'
  ) THEN
    EXECUTE $sql$
      CREATE POLICY menu_categories_public_read
      ON public.menu_categories
      FOR SELECT
      TO public
      USING (
        is_active = true
        AND EXISTS (
          SELECT 1
          FROM public.businesses b
          WHERE b.id = menu_categories.business_id
            AND b.is_active = true
        )
      )
    $sql$;
  END IF;
END
$$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public' AND tablename = 'menu_translations' AND policyname = 'menu_translations_owner_all'
  ) THEN
    EXECUTE $sql$
      CREATE POLICY menu_translations_owner_all
      ON public.menu_translations
      FOR ALL
      TO authenticated
      USING (
        is_admin() OR (
          (entity_type = 'business' AND is_owner_of_business(entity_id))
          OR (entity_type = 'category' AND EXISTS (
            SELECT 1 FROM public.menu_categories c
            WHERE c.id = entity_id
              AND is_owner_of_business(c.business_id)
          ))
          OR (entity_type = 'item' AND EXISTS (
            SELECT 1 FROM public.menu_items i
            WHERE i.id = entity_id
              AND is_owner_of_business(i.business_id)
          ))
        )
      )
      WITH CHECK (
        is_admin() OR (
          (entity_type = 'business' AND is_owner_of_business(entity_id))
          OR (entity_type = 'category' AND EXISTS (
            SELECT 1 FROM public.menu_categories c
            WHERE c.id = entity_id
              AND is_owner_of_business(c.business_id)
          ))
          OR (entity_type = 'item' AND EXISTS (
            SELECT 1 FROM public.menu_items i
            WHERE i.id = entity_id
              AND is_owner_of_business(i.business_id)
          ))
        )
      )
    $sql$;
  END IF;
END
$$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public' AND tablename = 'menu_translations' AND policyname = 'menu_translations_public_read'
  ) THEN
    EXECUTE $sql$
      CREATE POLICY menu_translations_public_read
      ON public.menu_translations
      FOR SELECT
      TO public
      USING (true)
    $sql$;
  END IF;
END
$$;

NOTIFY pgrst, 'reload schema';

-- ===== END MIGRATION: 20260323000028_qr_menu_schema_sync.sql =====

-- ===== BEGIN MIGRATION: 20260323000029_fix_menu_item_audit_trigger.sql =====
-- Fix legacy audit trigger against current menu_items schema
create or replace function public.trg_audit_menu_items_cud_v1()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_menu_id uuid;
begin
  select s.menu_id into v_menu_id
  from public.menu_sections s
  where s.id = coalesce(new.section_id, old.section_id)
  limit 1;

  if TG_OP = 'INSERT' then
    perform public.insert_audit_log_v1(
      'menu_item.created',
      'menu_item',
      NEW.id,
      null,
      jsonb_build_object(
        'business_id', NEW.business_id,
        'menu_id', v_menu_id,
        'name', NEW.name,
        'price_cents', NEW.price_cents,
        'currency', NEW.currency,
        'is_available', NEW.is_available
      )
    );
    return NEW;
  elsif TG_OP = 'UPDATE' then
    if row(NEW.name, NEW.price_cents, NEW.currency, NEW.is_available)
       is distinct from
       row(OLD.name, OLD.price_cents, OLD.currency, OLD.is_available) then
      perform public.insert_audit_log_v1(
        'menu_item.updated',
        'menu_item',
        NEW.id,
        jsonb_build_object(
          'name', OLD.name,
          'price_cents', OLD.price_cents,
          'currency', OLD.currency,
          'is_available', OLD.is_available
        ),
        jsonb_build_object(
          'name', NEW.name,
          'price_cents', NEW.price_cents,
          'currency', NEW.currency,
          'is_available', NEW.is_available
        )
      );
    end if;
    return NEW;
  else
    perform public.insert_audit_log_v1(
      'menu_item.deleted',
      'menu_item',
      OLD.id,
      jsonb_build_object(
        'business_id', OLD.business_id,
        'menu_id', v_menu_id,
        'name', OLD.name,
        'price_cents', OLD.price_cents
      ),
      null
    );
    return OLD;
  end if;
end;
$$;

-- ===== END MIGRATION: 20260323000029_fix_menu_item_audit_trigger.sql =====

-- ===== BEGIN MIGRATION: 20260324000001_menu_variants_and_owner_history.sql =====
-- Multi-menu roadmap phase-1:
-- 1) Product-level variants (size/gramaj/portion)
-- 2) Owner edits on menu_items price are persisted into price history

create table if not exists public.menu_item_variants (
  id uuid primary key default gen_random_uuid(),
  menu_item_id uuid not null references public.menu_items(id) on delete cascade,
  label text not null,
  price_cents integer not null check (price_cents >= 0),
  currency text not null default 'TRY',
  is_default boolean not null default false,
  is_available boolean not null default true,
  sort_order integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_menu_item_variants_item_sort
  on public.menu_item_variants (menu_item_id, sort_order, created_at);

create unique index if not exists uq_menu_item_variants_default_per_item
  on public.menu_item_variants (menu_item_id)
  where is_default = true;

alter table public.menu_item_variants enable row level security;

drop policy if exists menu_item_variants_owner_all on public.menu_item_variants;
create policy menu_item_variants_owner_all
on public.menu_item_variants
for all
to authenticated
using (
  is_admin()
  or exists (
    select 1
    from public.menu_items mi
    where mi.id = menu_item_variants.menu_item_id
      and is_owner_of_business(mi.business_id)
  )
)
with check (
  is_admin()
  or exists (
    select 1
    from public.menu_items mi
    where mi.id = menu_item_variants.menu_item_id
      and is_owner_of_business(mi.business_id)
  )
);

drop policy if exists menu_item_variants_public_read on public.menu_item_variants;
create policy menu_item_variants_public_read
on public.menu_item_variants
for select
to public
using (
  is_available = true
  and exists (
    select 1
    from public.menu_items mi
    join public.businesses b on b.id = mi.business_id
    where mi.id = menu_item_variants.menu_item_id
      and b.is_active = true
  )
);

create or replace function public.get_menu_item_variants_v1(
  p_menu_item_id uuid
)
returns table (
  id uuid,
  menu_item_id uuid,
  label text,
  price_cents integer,
  currency text,
  is_default boolean,
  is_available boolean,
  sort_order integer
)
language sql
stable
security definer
set search_path = public
as $$
  select
    v.id,
    v.menu_item_id,
    v.label,
    v.price_cents,
    v.currency,
    v.is_default,
    v.is_available,
    v.sort_order
  from public.menu_item_variants v
  where v.menu_item_id = p_menu_item_id
  order by v.sort_order asc, v.created_at asc;
$$;

grant all on function public.get_menu_item_variants_v1(uuid) to anon;
grant all on function public.get_menu_item_variants_v1(uuid) to authenticated;
grant all on function public.get_menu_item_variants_v1(uuid) to service_role;

create or replace function public.trg_menu_items_owner_price_history_v1()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if tg_op = 'UPDATE'
     and (
       coalesce(new.price_cents, -1) <> coalesce(old.price_cents, -1)
       or coalesce(new.currency, '') <> coalesce(old.currency, '')
     )
  then
    insert into public.menu_item_price_history (
      menu_item_id,
      price_cents,
      currency,
      source,
      created_by
    )
    values (
      new.id,
      new.price_cents,
      coalesce(new.currency, 'TRY'),
      'owner_edit',
      auth.uid()
    );
  end if;
  return new;
end;
$$;

drop trigger if exists trg_menu_items_owner_price_history_v1 on public.menu_items;
create trigger trg_menu_items_owner_price_history_v1
after update of price_cents, currency on public.menu_items
for each row
execute function public.trg_menu_items_owner_price_history_v1();

-- ===== END MIGRATION: 20260324000001_menu_variants_and_owner_history.sql =====

-- ===== BEGIN MIGRATION: 20260324000002_menu_categories_menu_id.sql =====
-- Bind QR categories to a concrete menu so one business can host multiple menus.

alter table public.menu_categories
  add column if not exists menu_id uuid references public.menus(id) on delete cascade;

-- Backfill existing rows: attach each category to latest non-archived menu of same business.
with latest_menu as (
  select distinct on (m.business_id)
    m.business_id,
    m.id as menu_id
  from public.menus m
  where m.status <> 'archived'
  order by m.business_id, m.updated_at desc, m.created_at desc
)
update public.menu_categories c
set menu_id = lm.menu_id
from latest_menu lm
where c.menu_id is null
  and c.business_id = lm.business_id;

create index if not exists idx_menu_categories_menu_id_sort_order
  on public.menu_categories (menu_id, sort_order);

-- ===== END MIGRATION: 20260324000002_menu_categories_menu_id.sql =====

-- ===== BEGIN MIGRATION: 20990101_000001_business_fee_flags.sql =====
-- Hidden fees flags (crowd verified)
create table if not exists public.business_fee_flags (
  business_id uuid primary key references public.businesses(id) on delete cascade,
  has_cover_charge boolean null,
  cover_charge_cents int null,
  has_service_fee boolean null,
  service_fee_pct int null,
  bottled_water_paid boolean null,
  updated_at timestamptz default now()
);

create table if not exists public.business_fee_votes (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses(id) on delete cascade,
  user_id uuid not null,
  field text not null check (field in ('cover','service','water')),
  value boolean not null,
  note text null,
  created_at timestamptz default now(),
  created_day date generated always as ((created_at at time zone 'utc')::date) stored
);

create unique index if not exists business_fee_votes_unique_day
  on public.business_fee_votes (business_id, user_id, field, created_day);

create index if not exists business_fee_votes_business_time_idx
  on public.business_fee_votes (business_id, created_at desc);

alter table public.business_fee_flags enable row level security;
alter table public.business_fee_votes enable row level security;

-- RLS: read for all, write for authed users (votes), admin full
drop policy if exists "business_fee_flags_read_all" on public.business_fee_flags;
create policy "business_fee_flags_read_all"
  on public.business_fee_flags
  for select using (true);

drop policy if exists "business_fee_votes_read_all" on public.business_fee_votes;
create policy "business_fee_votes_read_all"
  on public.business_fee_votes
  for select using (true);

drop policy if exists "business_fee_votes_insert_authed" on public.business_fee_votes;
create policy "business_fee_votes_insert_authed"
  on public.business_fee_votes
  for insert
  with check (auth.uid() is not null and user_id = auth.uid());

drop policy if exists "business_fee_flags_admin_all" on public.business_fee_flags;
create policy "business_fee_flags_admin_all"
  on public.business_fee_flags
  for all using (public.is_admin()) with check (public.is_admin());

drop policy if exists "business_fee_votes_admin_all" on public.business_fee_votes;
create policy "business_fee_votes_admin_all"
  on public.business_fee_votes
  for all using (public.is_admin()) with check (public.is_admin());

create or replace function public.vote_business_fee_v1(
  p_business_id uuid,
  p_field text,
  p_value boolean,
  p_note text default null
)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  v_limit jsonb;
  v_day date := (now() at time zone 'utc')::date;
  v_key text := 'business_fee_vote:' || auth.uid()::text || ':' || p_field || ':' || v_day::text;
  v_row public.user_rate_limits%rowtype;
  v_yes int;
  v_no int;
  v_total int;
  v_majority boolean;
begin
  if auth.uid() is null then
    return jsonb_build_object('ok', false, 'error', 'not_authenticated');
  end if;

  if p_field not in ('cover','service','water') then
    return jsonb_build_object('ok', false, 'error', 'invalid_field');
  end if;

  -- rate limit (daily 10 per user)
  v_limit := public.consume_rate_limit_v1('business_fee_vote', 10);
  if (v_limit->>'ok')::boolean is false then
    return v_limit;
  end if;

  insert into public.business_fee_votes(business_id, user_id, field, value, note)
  values (p_business_id, auth.uid(), p_field, p_value, p_note);

  select
    count(*) filter (where value = true),
    count(*) filter (where value = false),
    count(*)
  into v_yes, v_no, v_total
  from public.business_fee_votes
  where business_id = p_business_id
    and field = p_field
    and created_at >= now() - interval '30 days';

  v_majority := case
    when v_total = 0 then null
    when v_yes >= v_no then true
    else false
  end;

  insert into public.business_fee_flags(business_id, updated_at)
  values (p_business_id, now())
  on conflict (business_id) do update
  set updated_at = excluded.updated_at;

  if p_field = 'cover' then
    update public.business_fee_flags
    set has_cover_charge = v_majority, updated_at = now()
    where business_id = p_business_id;
  elsif p_field = 'service' then
    update public.business_fee_flags
    set has_service_fee = v_majority, updated_at = now()
    where business_id = p_business_id;
  else
    update public.business_fee_flags
    set bottled_water_paid = v_majority, updated_at = now()
    where business_id = p_business_id;
  end if;

  return jsonb_build_object('ok', true);
exception
  when unique_violation then
    return jsonb_build_object('ok', false, 'error', 'rate_limited');
end;
$$;

create or replace function public.get_business_fee_summary_v1(
  p_business_id uuid
)
returns jsonb
language sql
stable
security definer
set search_path to 'public'
as $$
  with votes as (
    select
      field,
      count(*) filter (where value = true) as yes_count,
      count(*) filter (where value = false) as no_count,
      count(*) as total_count,
      max(created_at) as last_vote_at
    from public.business_fee_votes
    where business_id = p_business_id
      and created_at >= now() - interval '30 days'
    group by field
  ),
  scored as (
    select
      field,
      yes_count,
      no_count,
      total_count,
      last_vote_at,
      case
        when total_count = 0 then null
        when yes_count >= no_count then true
        else false
      end as value,
      case
        when total_count = 0 then 0
        else least(1.0,
          (abs(yes_count - no_count)::float / total_count) * 0.7 +
          (1 - least(extract(epoch from (now() - last_vote_at)) / (30*86400.0), 1)) * 0.3
        )
      end as confidence
    from votes
  )
  select jsonb_build_object(
    'cover', (
      select jsonb_build_object(
        'value', value,
        'confidence', confidence,
        'total', total_count
      )
      from scored where field = 'cover'
    ),
    'service', (
      select jsonb_build_object(
        'value', value,
        'confidence', confidence,
        'total', total_count
      )
      from scored where field = 'service'
    ),
    'water', (
      select jsonb_build_object(
        'value', value,
        'confidence', confidence,
        'total', total_count
      )
      from scored where field = 'water'
    )
  );
$$;

-- ===== END MIGRATION: 20990101_000001_business_fee_flags.sql =====
