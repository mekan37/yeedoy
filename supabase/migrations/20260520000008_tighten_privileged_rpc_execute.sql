do $$
declare
  target_function regprocedure;
begin
  -- Trigger functions are invoked by triggers, not directly through PostgREST RPC.
  for target_function in
    select p.oid::regprocedure
    from pg_proc p
    join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'public'
      and p.prorettype = 'trigger'::regtype
  loop
    execute format('revoke execute on function %s from public', target_function);
    execute format('revoke execute on function %s from anon', target_function);
    execute format('revoke execute on function %s from authenticated', target_function);
  end loop;

  -- Owner, admin-like, audit, moderation, campaign, team, and automation RPCs require a signed-in caller.
  for target_function in
    select p.oid::regprocedure
    from pg_proc p
    join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'public'
      and p.prosecdef
      and (
        p.proname like 'owner\_%' escape '\'
        or p.proname in (
          'add_moderation_strike_v1',
          'anonymize_user_content_v1',
          'apply_auto_moderation_rules_v1',
          'approve_business_suggestion',
          'approve_menu_item_suggestion_v1',
          'approve_owner_claim',
          'auto_approve_trusted_owner_claim_v1',
          'auto_close_duplicate_report_v1',
          'auto_queue_grey_report_v1',
          'auto_reject_low_quality_report_v1',
          'create_email_campaign_v1',
          'create_push_campaign_v1',
          'delete_custom_domain_v1',
          'estimate_campaign_segment_v1',
          'get_business_automations_v1',
          'get_custom_domain_v1',
          'insert_audit_log_v1',
          'list_audit_timeline_v1',
          'list_audit_timeline_v2',
          'list_email_campaigns_v1',
          'list_owner_analytics_hourly_v1',
          'list_owner_analytics_v1',
          'list_push_campaigns_v1',
          'list_team_members_v1',
          'reject_business_suggestion',
          'reject_owner_claim',
          'revoke_team_member_v1',
          'send_business_campaign_v1',
          'update_team_member_v1',
          'upsert_business_automation_v1',
          'upsert_custom_domain_v1',
          'upsert_team_member_v1'
        )
      )
  loop
    execute format('revoke execute on function %s from public', target_function);
    execute format('revoke execute on function %s from anon', target_function);
  end loop;
end $$;
