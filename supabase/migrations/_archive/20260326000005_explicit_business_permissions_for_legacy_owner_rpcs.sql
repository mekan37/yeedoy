do $$
declare
  rec record;
  v_ddl text;
begin
  for rec in
    select *
    from (
      values
        ('public.owner_create_menu_v1(uuid, text, text, timestamptz, timestamptz)', 'menu_write'),
        ('public.owner_update_menu_v1(uuid, text, text, timestamptz, timestamptz)', 'menu_write'),
        ('public.owner_archive_menu_v1(uuid)', 'menu_write'),
        ('public.owner_publish_menu_v1(uuid)', 'menu_write'),
        ('public.owner_create_menu_section_v1(uuid, text, integer)', 'menu_write'),
        ('public.owner_update_menu_section_v1(uuid, text)', 'menu_write'),
        ('public.owner_delete_menu_section_v1(uuid, boolean)', 'menu_write'),
        ('public.owner_reorder_menu_sections_v1(uuid, uuid[])', 'menu_write'),
        ('public.owner_create_menu_item_v1(uuid, text, text, integer, text, bigint)', 'menu_write'),
        ('public.owner_update_menu_item_v1(uuid, text, text, integer, text, bigint)', 'menu_write'),
        ('public.owner_archive_menu_item_v1(uuid)', 'menu_write'),
        ('public.owner_publish_menu_item_v1(uuid)', 'menu_write'),
        ('public.owner_list_menu_price_suggestions_v1(uuid, text, integer, integer)', 'menu_write'),
        ('public.owner_reject_menu_price_suggestion_v1(uuid, text)', 'menu_write'),
        ('public.owner_override_price_suggestion_v1(uuid, text, integer)', 'menu_write'),
        ('public.create_business_story_v1(uuid, text, text, text, text, integer, text)', 'menu_write'),
        ('public.get_owner_onboarding_progress_v1(uuid)', 'business_read'),
        ('public.owner_set_onboarding_progress_v1(uuid, integer)', 'business_write'),
        ('public.owner_update_business_profile_v1(uuid, text, text)', 'business_write'),
        ('public.owner_upsert_business_hours_v1(uuid, time without time zone, time without time zone)', 'business_write'),
        ('public.owner_update_business_amenities_v1(uuid, text[])', 'business_write'),
        ('public.get_business_profile_score_v1(uuid)', 'business_read'),
        ('public.get_business_quality_score_v1(uuid)', 'business_read'),
        ('public.owner_update_business_commerce_links_v1(uuid, text, text, text, text)', 'business_write'),
        ('public.owner_create_perk_v1(uuid, text, text, timestamptz, timestamptz, boolean)', 'business_write'),
        ('public.owner_set_perk_status_v1(uuid, text)', 'business_write'),
        ('public.list_open_requests_for_business_v1(text, text[], integer, integer, uuid)', 'business_read'),
        ('public.submit_group_offer_v1(uuid, uuid, integer, jsonb, text)', 'business_write'),
        ('public.analytics_growth_v2(integer, uuid)', 'analytics_view'),
        ('public.analytics_growth_v3(integer, uuid)', 'analytics_view'),
        ('public.owner_get_sponsorship_catalog_v1(uuid)', 'analytics_view'),
        ('public.submit_sponsorship_lead_v1(uuid, text, text, text, jsonb)', 'business_write'),
        ('public.owner_update_business_meal_card_providers_v1(uuid, text[])', 'business_write')
    ) as mapped(signature, permission)
  loop
    select pg_get_functiondef(rec.signature::regprocedure) into v_ddl;
    if v_ddl is null then
      raise exception 'legacy function not found: %', rec.signature;
    end if;

    v_ddl := regexp_replace(
      v_ddl,
      '(?:public\.)?is_owner_of_business\(([^)]+)\)',
      format('public.has_business_permission_v1(\1, ''%s'')', rec.permission),
      'g'
    );

    execute v_ddl;
  end loop;
end;
$$;
