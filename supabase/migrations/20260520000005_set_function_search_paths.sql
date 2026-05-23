-- Pin search_path for project-owned public functions flagged by the DB linter.

do $$
declare
  fn record;
begin
  for fn in
    select p.oid::regprocedure as signature
    from pg_proc p
    join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'public'
      and p.proname = any (array[
        '_allocate_business_slug_token_v1',
        '_assign_business_public_slug_v1',
        '_assign_business_public_slug_v2',
        '_fn_sync_business_geog',
        '_normalize_public_slug_v1',
        'bump_menu_version_v1',
        'contains_contact_or_url_v1',
        'contains_obfuscated_profanity_v1',
        'create_email_campaign_v1',
        'estimate_email_segment_v1',
        'get_business_automations_v1',
        'list_email_campaigns_v1',
        'mask_contact_tokens_v1',
        'normalize_for_moderation_v1',
        'request_header_v1',
        'request_ip_v1',
        'run_loyalty_automations_v1',
        'sanitize_plain_text_v1',
        'set_review_reply_updated_at',
        'sync_review_overall_rating_v1',
        'touch_updated_at_v1',
        'upsert_business_automation_v1'
      ])
      and not exists (
        select 1
        from pg_depend d
        join pg_extension e on e.oid = d.refobjid
        where d.objid = p.oid
          and d.deptype = 'e'
      )
  loop
    execute format('alter function %s set search_path = public, extensions, pg_temp', fn.signature);
  end loop;
end $$;
