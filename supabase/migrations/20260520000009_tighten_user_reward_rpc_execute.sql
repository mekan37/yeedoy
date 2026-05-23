do $$
declare
  target_function regprocedure;
begin
  -- RPCs that require auth.uid() should not be callable by anon.
  for target_function in
    select p.oid::regprocedure
    from pg_proc p
    join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'public'
      and p.prosecdef
      and p.proname in (
        'add_loyalty_stamp_v1',
        'assert_owner_scope_v1',
        'can_access_business_v1',
        'can_manage_branch_v1',
        'claim_mission_v1',
        'delete_user_account_v1',
        'get_my_loyalty_cards_v1',
        'get_my_weekly_missions',
        'submit_mission_proof_v1'
      )
  loop
    execute format('revoke execute on function %s from public', target_function);
    execute format('revoke execute on function %s from anon', target_function);
  end loop;

  -- Internal reward/audit/moderation helpers accept arbitrary user ids or privileged payloads.
  for target_function in
    select p.oid::regprocedure
    from pg_proc p
    join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'public'
      and p.prosecdef
      and p.proname in (
        'add_moderation_strike_v1',
        'anonymize_user_content_v1',
        'apply_profile_xp_v1',
        'award_achievement_v1',
        'award_loyalty_points_v1',
        'insert_audit_log_v1'
      )
  loop
    execute format('revoke execute on function %s from public', target_function);
    execute format('revoke execute on function %s from anon', target_function);
    execute format('revoke execute on function %s from authenticated', target_function);
  end loop;
end $$;
