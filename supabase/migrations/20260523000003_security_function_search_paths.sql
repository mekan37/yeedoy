-- ─────────────────────────────────────────────────────────────────────────────
-- Security: Pin search_path on functions added after 20260520000005.
-- ─────────────────────────────────────────────────────────────────────────────
-- Functions without a pinned search_path are susceptible to search_path
-- injection attacks if an attacker can create objects in a schema that
-- appears before "public" in the search path.
-- ─────────────────────────────────────────────────────────────────────────────

do $$
declare
  fn record;
begin
  for fn in
    select p.oid::regprocedure as signature
    from pg_proc p
    join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'public'
      -- Only functions without a set search_path
      and not exists (
        select 1 from pg_options_to_table(p.proconfig)
        where option_name = 'search_path'
      )
      -- Only user-defined (not extension-owned)
      and not exists (
        select 1 from pg_depend d
        join pg_extension e on e.oid = d.refobjid
        where d.objid = p.oid and d.deptype = 'e'
      )
      and p.proname = any(array[
        -- Functions from 20260507+ migrations
        'submit_checkin_v1',
        'get_my_checkin_today_v1',
        'get_business_recent_checkins_v1',
        'set_today_special_v1',
        'notify_today_special_trigger',
        'set_menu_item_nutrition_v1',
        'search_businesses_v1',
        'create_loyalty_program_v1',
        'add_loyalty_stamp_v1',
        'get_my_loyalty_cards_v1',
        'update_visit_details_v1',
        'get_my_food_journal_v1',
        'update_table_order_status_v1',
        'get_pending_table_orders_v1',
        'submit_table_order_v1',
        'send_business_campaign_v1',
        'notify_favorite_revisit_reminders_v1',
        -- Functions from 20260420-20260422 migrations
        'get_business_reviews_v3',
        '_review_verified_visit',
        'trg_award_loyalty_on_order_done',
        -- Loyalty auto points trigger
        'award_loyalty_points_v1',
        'run_loyalty_automations_v1',
        -- Table order with staff fields
        'get_my_weekly_missions',
        'submit_mission_proof_v1'
      ])
  loop
    begin
      execute format(
        'alter function %s set search_path = public, extensions, pg_temp',
        fn.signature
      );
    exception when others then
      raise notice 'Could not set search_path for %: %', fn.signature, sqlerrm;
    end;
  end loop;
end $$;

-- Also catch any remaining public functions without search_path using a broader sweep.
-- This is safe to run multiple times (idempotent due to alter function).
do $$
declare
  fn record;
begin
  for fn in
    select p.oid::regprocedure as signature, p.proname
    from pg_proc p
    join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'public'
      and p.prokind in ('f', 'p')  -- functions and procedures only, not aggregates/windows
      and not exists (
        select 1 from pg_options_to_table(p.proconfig)
        where option_name = 'search_path'
      )
      and not exists (
        select 1 from pg_depend d
        join pg_extension e on e.oid = d.refobjid
        where d.objid = p.oid and d.deptype = 'e'
      )
      -- Only SECURITY DEFINER functions are the real risk
      and p.prosecdef = true
  loop
    begin
      execute format(
        'alter function %s set search_path = public, extensions, pg_temp',
        fn.signature
      );
    exception when others then
      raise notice 'search_path sweep: skipped %s: %', fn.proname, sqlerrm;
    end;
  end loop;
end $$;
