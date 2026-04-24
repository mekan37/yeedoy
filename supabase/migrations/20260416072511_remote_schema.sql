create extension if not exists "hypopg" with schema "extensions";

create extension if not exists "index_advisor" with schema "extensions";

drop extension if exists "pg_net";

create schema if not exists "deprecated";

drop trigger if exists "trg_account_deletion_requests_capture_request_metadata_v1" on "public"."account_deletion_requests";

drop trigger if exists "trg_notify_price_alert_event_v1" on "public"."alert_events";

drop trigger if exists "trg_analytics_events_privacy_v1" on "public"."analytics_events";

drop trigger if exists "trg_recompute_achievements_analytics_v1" on "public"."analytics_events";

drop trigger if exists "trg_business_activity_log_feed" on "public"."business_activity_log";

drop trigger if exists "trg_business_media_require_verified_contact_v1" on "public"."business_media";

drop trigger if exists "trg_business_menu_presentation_settings_touch_v1" on "public"."business_menu_presentation_settings";

drop trigger if exists "trg_business_perks_feed" on "public"."business_perks";

drop trigger if exists "trg_business_policy_acceptances_capture_request_metadata_v1" on "public"."business_policy_acceptances";

drop trigger if exists "trg_assign_business_public_slug_v2" on "public"."businesses";

drop trigger if exists "trg_audit_businesses_update_v1" on "public"."businesses";

drop trigger if exists "trg_businesses_sync_geog" on "public"."businesses";

drop trigger if exists "trg_businesses_sync_search_tsv" on "public"."businesses";

drop trigger if exists "trg_menu_item_photos_abuse_controls_v1" on "public"."menu_item_photos";

drop trigger if exists "trg_menu_item_photos_delete_edge_guard_v1" on "public"."menu_item_photos";

drop trigger if exists "trg_menu_item_photos_edge_guard_v1" on "public"."menu_item_photos";

drop trigger if exists "trg_menu_item_photos_require_verified_contact_v1" on "public"."menu_item_photos";

drop trigger if exists "trg_recompute_achievements_menu_photos_v1" on "public"."menu_item_photos";

drop trigger if exists "trg_price_alerts_history" on "public"."menu_item_price_history";

drop trigger if exists "trg_menu_item_price_suggestions_rate_limit_v1" on "public"."menu_item_price_suggestions";

drop trigger if exists "trg_notify_owner_new_price_suggestion_v1" on "public"."menu_item_price_suggestions";

drop trigger if exists "trg_notify_price_suggestion_result_v1" on "public"."menu_item_price_suggestions";

drop trigger if exists "trg_price_suggestions_abuse_controls_v1" on "public"."menu_item_price_suggestions";

drop trigger if exists "trg_price_suggestions_collect_risk_signals_v1" on "public"."menu_item_price_suggestions";

drop trigger if exists "trg_price_suggestions_edge_guard_v1" on "public"."menu_item_price_suggestions";

drop trigger if exists "trg_price_suggestions_require_verified_contact_v1" on "public"."menu_item_price_suggestions";

drop trigger if exists "trg_recompute_achievements_price_suggestions_v1" on "public"."menu_item_price_suggestions";

drop trigger if exists "menu_items_activity_log_trg" on "public"."menu_items";

drop trigger if exists "trg_audit_menu_items_cud_v1" on "public"."menu_items";

drop trigger if exists "trg_menu_items_assign_section" on "public"."menu_items";

drop trigger if exists "trg_menu_items_new_feed" on "public"."menu_items";

drop trigger if exists "trg_menu_items_owner_price_history_v1" on "public"."menu_items";

drop trigger if exists "menu_sections_activity_log_trg" on "public"."menu_sections";

drop trigger if exists "trg_audit_menus_cud_v1" on "public"."menus";

drop trigger if exists "trg_menus_versioning_v1" on "public"."menus";

drop trigger if exists "trg_notification_dispatch_jobs_touch_v1" on "public"."notification_dispatch_jobs";

drop trigger if exists "trg_enqueue_notification_dispatch_v1" on "public"."notifications";

drop trigger if exists "trg_audit_owner_claims_update_v1" on "public"."owner_claims";

drop trigger if exists "trg_privacy_requests_capture_request_metadata_v1" on "public"."privacy_requests";

drop trigger if exists "trg_audit_reports_update_v1" on "public"."reports";

drop trigger if exists "trg_auto_moderate_report" on "public"."reports";

drop trigger if exists "trg_hide_reported_business_media_v1" on "public"."reports";

drop trigger if exists "trg_hide_reported_menu_photo_v1" on "public"."reports";

drop trigger if exists "trg_notify_owner_reported_v1" on "public"."reports";

drop trigger if exists "trg_recompute_achievements_reports_v1" on "public"."reports";

drop trigger if exists "trg_reports_edge_guard_v1" on "public"."reports";

drop trigger if exists "trg_review_votes_del" on "public"."review_votes";

drop trigger if exists "trg_review_votes_edge_guard_delete_v1" on "public"."review_votes";

drop trigger if exists "trg_review_votes_edge_guard_insert_v1" on "public"."review_votes";

drop trigger if exists "trg_review_votes_helpful_count" on "public"."review_votes";

drop trigger if exists "trg_review_votes_ins" on "public"."review_votes";

drop trigger if exists "trg_business_stats_reviews" on "public"."reviews";

drop trigger if exists "trg_notify_owner_new_review_v1" on "public"."reviews";

drop trigger if exists "trg_recompute_achievements_reviews_v1" on "public"."reviews";

drop trigger if exists "trg_reviews_abuse_controls_v1" on "public"."reviews";

drop trigger if exists "trg_reviews_collect_risk_signals_v1" on "public"."reviews";

drop trigger if exists "trg_reviews_edge_guard_v1" on "public"."reviews";

drop trigger if exists "trg_reviews_rate_limit_v1" on "public"."reviews";

drop trigger if exists "trg_reviews_require_verified_contact_v1" on "public"."reviews";

drop trigger if exists "trg_reviews_sync_overall_rating_v1" on "public"."reviews";

drop trigger if exists "trg_user_policy_acceptances_capture_request_metadata_v1" on "public"."user_policy_acceptances";

drop trigger if exists "trg_audit_user_ban_toggle_v1" on "public"."user_profiles";

drop trigger if exists "trg_user_profiles_minimize_v1" on "public"."user_profiles";

drop trigger if exists "trg_visits_edge_guard_delete_v1" on "public"."visits";

drop trigger if exists "trg_visits_edge_guard_insert_v1" on "public"."visits";

drop policy "account_deletion_requests_select_own" on "public"."account_deletion_requests";

drop policy "admin_audit_log_admin_all" on "public"."admin_audit_log";

drop policy "admin_runtime_settings_admin_all" on "public"."admin_runtime_settings";

drop policy "admin_users_admin_all" on "public"."admin_users";

drop policy "analytics_events_admin_all" on "public"."analytics_events";

drop policy "business_amenities_admin_delete" on "public"."business_amenities";

drop policy "business_amenities_admin_insert" on "public"."business_amenities";

drop policy "business_amenities_admin_update" on "public"."business_amenities";

drop policy "business_amenity_map_owner_delete" on "public"."business_amenity_map";

drop policy "business_amenity_map_owner_insert" on "public"."business_amenity_map";

drop policy "business_amenity_map_owner_update" on "public"."business_amenity_map";

drop policy "business_checkins_admin_all" on "public"."business_checkins";

drop policy "business_fee_flags_admin_all" on "public"."business_fee_flags";

drop policy "business_fee_votes_admin_all" on "public"."business_fee_votes";

drop policy "business_hours_owner_update" on "public"."business_hours";

drop policy "business_hours_owner_write" on "public"."business_hours";

drop policy "business_hours_select_public" on "public"."business_hours";

drop policy "business_meal_card_providers_owner_delete" on "public"."business_meal_card_providers";

drop policy "business_meal_card_providers_owner_insert" on "public"."business_meal_card_providers";

drop policy "business_meal_card_providers_owner_update" on "public"."business_meal_card_providers";

drop policy "business_menu_presentation_settings_delete_manage" on "public"."business_menu_presentation_settings";

drop policy "business_menu_presentation_settings_insert_manage" on "public"."business_menu_presentation_settings";

drop policy "business_menu_presentation_settings_update_manage" on "public"."business_menu_presentation_settings";

drop policy "business_merge_log_admin_only_policy" on "public"."business_merge_log";

drop policy "business_perks_select_policy" on "public"."business_perks";

drop policy "business_perks_write_policy" on "public"."business_perks";

drop policy "business_policy_acceptances_insert_owned" on "public"."business_policy_acceptances";

drop policy "business_policy_acceptances_select_owned" on "public"."business_policy_acceptances";

drop policy "business_premium_admin_all" on "public"."business_premium";

drop policy "business_presence_admin_select" on "public"."business_presence_events";

drop policy "business_pricing_rules_write_policy" on "public"."business_pricing_rules";

drop policy "stories_owner_admin_delete" on "public"."business_stories";

drop policy "stories_owner_admin_insert" on "public"."business_stories";

drop policy "stories_owner_admin_update" on "public"."business_stories";

drop policy "business_submissions_admin_all" on "public"."business_submissions";

drop policy "business_suggestions_select_public_or_owner_admin" on "public"."business_suggestions";

drop policy "business_suggestions_update_admin" on "public"."business_suggestions";

drop policy "business_team_memberships_admin_all" on "public"."business_team_memberships";

drop policy "business_team_memberships_self_read" on "public"."business_team_memberships";

drop policy "businesses_delete_admin" on "public"."businesses";

drop policy "businesses_insert_admin" on "public"."businesses";

drop policy "businesses_update_owner_admin" on "public"."businesses";

drop policy "chain_memberships_admin_all" on "public"."chain_memberships";

drop policy "chain_memberships_owner_read" on "public"."chain_memberships";

drop policy "collection_items_owner_delete" on "public"."collection_items";

drop policy "collection_items_owner_insert" on "public"."collection_items";

drop policy "collection_items_select_access" on "public"."collection_items";

drop policy "edge_ip_denylist_admin_all" on "public"."edge_ip_denylist";

drop policy "edge_rate_limit_events_admin_all" on "public"."edge_rate_limit_events";

drop policy "embeds_delete_owner_admin" on "public"."embeds";

drop policy "embeds_insert_business_owner_admin" on "public"."embeds";

drop policy "embeds_update_owner_admin" on "public"."embeds";

drop policy "feed_events_admin_select" on "public"."feed_events";

drop policy "group_offers_business_insert" on "public"."group_offers";

drop policy "group_offers_business_select" on "public"."group_offers";

drop policy "group_offers_business_update" on "public"."group_offers";

drop policy "group_requests_owner_insert" on "public"."group_requests";

drop policy "group_requests_owner_select" on "public"."group_requests";

drop policy "group_requests_owner_update" on "public"."group_requests";

drop policy "import_places_stage_admin_all" on "public"."import_places_stage";

drop policy "incident_updates_admin_delete" on "public"."incident_updates";

drop policy "incident_updates_admin_insert" on "public"."incident_updates";

drop policy "incident_updates_admin_update" on "public"."incident_updates";

drop policy "meal_card_providers_admin_delete" on "public"."meal_card_providers";

drop policy "meal_card_providers_admin_insert" on "public"."meal_card_providers";

drop policy "meal_card_providers_admin_update" on "public"."meal_card_providers";

drop policy "menu_categories_owner_all" on "public"."menu_categories";

drop policy "menu_categories_public_read" on "public"."menu_categories";

drop policy "owner_read_allergens" on "public"."menu_item_allergens";

drop policy "nutrition_owner_select" on "public"."menu_item_nutrition";

drop policy "menu_item_photo_votes_admin_all" on "public"."menu_item_photo_votes";

drop policy "menu_item_photos_read" on "public"."menu_item_photos";

drop policy "price_hist_admin_delete" on "public"."menu_item_price_history";

drop policy "price_hist_admin_insert" on "public"."menu_item_price_history";

drop policy "price_hist_admin_update" on "public"."menu_item_price_history";

drop policy "price_sugg_delete_admin" on "public"."menu_item_price_suggestions";

drop policy "price_sugg_delete_own_pending" on "public"."menu_item_price_suggestions";

drop policy "price_sugg_insert_auth" on "public"."menu_item_price_suggestions";

drop policy "price_sugg_select_public_or_actor" on "public"."menu_item_price_suggestions";

drop policy "price_sugg_update_admin" on "public"."menu_item_price_suggestions";

drop policy "price_sugg_update_own_pending" on "public"."menu_item_price_suggestions";

drop policy "menu_item_price_votes_admin_all" on "public"."menu_item_price_votes";

drop policy "menu_item_suggestions_read_owner_admin" on "public"."menu_item_suggestions";

drop policy "menu_item_suggestions_update_owner_admin" on "public"."menu_item_suggestions";

drop policy "menu_item_variants_owner_all" on "public"."menu_item_variants";

drop policy "menu_item_variants_public_read" on "public"."menu_item_variants";

drop policy "menu_items_owner_delete" on "public"."menu_items";

drop policy "menu_items_owner_insert" on "public"."menu_items";

drop policy "menu_items_owner_update" on "public"."menu_items";

drop policy "menu_items_read" on "public"."menu_items";

drop policy "menu_sections_owner_delete" on "public"."menu_sections";

drop policy "menu_sections_owner_insert" on "public"."menu_sections";

drop policy "menu_sections_owner_update" on "public"."menu_sections";

drop policy "menu_sections_read" on "public"."menu_sections";

drop policy "menu_translations_owner_all" on "public"."menu_translations";

drop policy "menus_owner_delete" on "public"."menus";

drop policy "menus_owner_insert" on "public"."menus";

drop policy "menus_owner_update" on "public"."menus";

drop policy "menus_read_published" on "public"."menus";

drop policy "appeals_select_owner_or_mod_v1" on "public"."moderation_appeals";

drop policy "appeals_update_mod_only_v1" on "public"."moderation_appeals";

drop policy "notification_dispatch_jobs_admin_policy" on "public"."notification_dispatch_jobs";

drop policy "offer_messages_insert" on "public"."offer_messages";

drop policy "offer_messages_read" on "public"."offer_messages";

drop policy "owner_claims_select_access" on "public"."owner_claims";

drop policy "owner_claims_update_admin" on "public"."owner_claims";

drop policy "owner_onboarding_progress_owner_read" on "public"."owner_onboarding_progress";

drop policy "owner_onboarding_progress_owner_update" on "public"."owner_onboarding_progress";

drop policy "owner_onboarding_progress_owner_write" on "public"."owner_onboarding_progress";

drop policy "policy_versions_admin_write" on "public"."policy_versions";

drop policy "policy_versions_read_all" on "public"."policy_versions";

drop policy "privacy_requests_select_own" on "public"."privacy_requests";

drop policy "receipt_matches_admin_all" on "public"."receipt_matches";

drop policy "receipt_matches_owner_insert" on "public"."receipt_matches";

drop policy "receipt_matches_owner_select" on "public"."receipt_matches";

drop policy "receipt_submissions_admin_all" on "public"."receipt_submissions";

drop policy "reports_delete_admin" on "public"."reports";

drop policy "reports_select_admin" on "public"."reports";

drop policy "reports_update_admin" on "public"."reports";

drop policy "review_votes_admin_all" on "public"."review_votes";

drop policy "reviews_delete_admin" on "public"."reviews";

drop policy "reviews_select_access" on "public"."reviews";

drop policy "reviews_update_admin" on "public"."reviews";

drop policy "runtime_experiments_admin_write" on "public"."runtime_experiments";

drop policy "runtime_feature_flags_admin_write" on "public"."runtime_feature_flags";

drop policy "runtime_release_controls_admin_write" on "public"."runtime_release_controls";

drop policy "sponsorship_impressions_admin_all" on "public"."sponsorship_impressions_daily";

drop policy "sponsorship_leads_delete_admin" on "public"."sponsorship_leads";

drop policy "sponsorship_leads_insert_access" on "public"."sponsorship_leads";

drop policy "sponsorship_leads_select_access" on "public"."sponsorship_leads";

drop policy "sponsorship_leads_update_admin" on "public"."sponsorship_leads";

drop policy "sponsorship_packages_admin_all" on "public"."sponsorship_packages";

drop policy "sponsorships_admin_all" on "public"."sponsorships";

drop policy "storage_deletion_queue_admin_select" on "public"."storage_deletion_queue";

drop policy "storage_deletion_queue_admin_write" on "public"."storage_deletion_queue";

drop policy "claims_select_access" on "public"."suspended_meal_claims";

drop policy "claims_update_owner_admin" on "public"."suspended_meal_claims";

drop policy "meals_admin_delete" on "public"."suspended_meals";

drop policy "meals_admin_insert" on "public"."suspended_meals";

drop policy "meals_admin_update" on "public"."suspended_meals";

drop policy "meals_select_access" on "public"."suspended_meals";

drop policy "table_feedback_admin_select" on "public"."table_feedback";

drop policy "user_device_fingerprints_admin_all" on "public"."user_device_fingerprints";

drop policy "user_mission_claims_admin_all" on "public"."user_mission_claims";

drop policy "user_moderation_strikes_admin_write_policy" on "public"."user_moderation_strikes";

drop policy "user_moderation_strikes_select_policy" on "public"."user_moderation_strikes";

drop policy "user_points_admin_all" on "public"."user_points";

drop policy "user_policy_acceptances_select_own" on "public"."user_policy_acceptances";

drop policy "user_rate_limits_admin_all" on "public"."user_rate_limits";

drop policy "user_risk_signals_admin_all" on "public"."user_risk_signals";

drop policy "user_safety_actions_admin_all" on "public"."user_safety_actions";

revoke delete on table "public"."client_mutation_idempotency_keys" from "anon";

revoke insert on table "public"."client_mutation_idempotency_keys" from "anon";

revoke references on table "public"."client_mutation_idempotency_keys" from "anon";

revoke select on table "public"."client_mutation_idempotency_keys" from "anon";

revoke trigger on table "public"."client_mutation_idempotency_keys" from "anon";

revoke truncate on table "public"."client_mutation_idempotency_keys" from "anon";

revoke update on table "public"."client_mutation_idempotency_keys" from "anon";

revoke delete on table "public"."client_mutation_idempotency_keys" from "authenticated";

revoke insert on table "public"."client_mutation_idempotency_keys" from "authenticated";

revoke references on table "public"."client_mutation_idempotency_keys" from "authenticated";

revoke select on table "public"."client_mutation_idempotency_keys" from "authenticated";

revoke trigger on table "public"."client_mutation_idempotency_keys" from "authenticated";

revoke truncate on table "public"."client_mutation_idempotency_keys" from "authenticated";

revoke update on table "public"."client_mutation_idempotency_keys" from "authenticated";

alter table "public"."alert_events" drop constraint "alert_events_alert_id_fkey";

alter table "public"."alert_events" drop constraint "alert_events_business_id_fkey";

alter table "public"."analytics_events" drop constraint "analytics_events_business_id_fkey";

alter table "public"."analytics_events" drop constraint "analytics_events_menu_id_fkey";

alter table "public"."business_activity_log" drop constraint "business_activity_log_business_id_fkey";

alter table "public"."business_amenity_map" drop constraint "business_amenity_map_amenity_id_fkey";

alter table "public"."business_amenity_map" drop constraint "business_amenity_map_business_id_fkey";

alter table "public"."business_checkins" drop constraint "business_checkins_business_id_fkey";

alter table "public"."business_checkins" drop constraint "business_checkins_menu_id_fkey";

alter table "public"."business_fee_flags" drop constraint "business_fee_flags_business_id_fkey";

alter table "public"."business_fee_votes" drop constraint "business_fee_votes_business_id_fkey";

alter table "public"."business_follows" drop constraint "business_follows_business_id_fkey";

alter table "public"."business_hours" drop constraint "business_hours_business_id_fkey";

alter table "public"."business_meal_card_providers" drop constraint "business_meal_card_providers_business_id_fkey";

alter table "public"."business_meal_card_providers" drop constraint "business_meal_card_providers_provider_id_fkey";

alter table "public"."business_media" drop constraint "business_media_business_id_fkey";

alter table "public"."business_menu_presentation_settings" drop constraint "business_menu_presentation_settings_business_id_fkey";

alter table "public"."business_merge_log" drop constraint "business_merge_log_duplicate_business_id_fkey";

alter table "public"."business_merge_log" drop constraint "business_merge_log_primary_business_id_fkey";

alter table "public"."business_perks" drop constraint "business_perks_business_id_fkey";

alter table "public"."business_policy_acceptances" drop constraint "business_policy_acceptances_business_id_fkey";

alter table "public"."business_policy_acceptances" drop constraint "business_policy_acceptances_policy_version_id_fkey";

alter table "public"."business_premium" drop constraint "business_premium_business_id_fkey";

alter table "public"."business_premium" drop constraint "business_premium_created_by_fkey";

alter table "public"."business_presence_events" drop constraint "business_presence_events_business_id_fkey";

alter table "public"."business_pricing_rules" drop constraint "business_pricing_rules_business_id_fkey";

alter table "public"."business_stats" drop constraint "business_stats_business_id_fkey";

alter table "public"."business_stories" drop constraint "business_stories_business_id_fkey";

alter table "public"."business_team_memberships" drop constraint "business_team_memberships_business_id_fkey";

alter table "public"."business_team_memberships" drop constraint "business_team_memberships_chain_id_fkey";

alter table "public"."businesses" drop constraint "businesses_chain_id_fkey";

alter table "public"."businesses" drop constraint "businesses_verified_by_fkey";

alter table "public"."chain_memberships" drop constraint "chain_memberships_chain_id_fkey";

alter table "public"."collection_items" drop constraint "collection_items_business_id_fkey";

alter table "public"."collection_items" drop constraint "collection_items_collection_id_fkey";

alter table "public"."favorites" drop constraint "favorites_business_id_fkey";

alter table "public"."feed_events" drop constraint "feed_events_business_id_fkey";

alter table "public"."food_catalog_items" drop constraint "food_catalog_items_category_id_fkey";

alter table "public"."group_offers" drop constraint "group_offers_business_id_fkey";

alter table "public"."group_offers" drop constraint "group_offers_request_id_fkey";

alter table "public"."menu_categories" drop constraint "menu_categories_business_id_fkey";

alter table "public"."menu_categories" drop constraint "menu_categories_menu_id_fkey";

alter table "public"."menu_item_allergens" drop constraint "menu_item_allergens_item_id_fkey";

alter table "public"."menu_item_diet_tags" drop constraint "menu_item_diet_tags_item_id_fkey";

alter table "public"."menu_item_ingredients" drop constraint "menu_item_ingredients_item_id_fkey";

alter table "public"."menu_item_nutrition" drop constraint "menu_item_nutrition_item_id_fkey";

alter table "public"."menu_item_photo_votes" drop constraint "menu_item_photo_votes_photo_id_fkey";

alter table "public"."menu_item_photos" drop constraint "menu_item_photos_business_id_fkey";

alter table "public"."menu_item_photos" drop constraint "menu_item_photos_menu_item_id_fkey";

alter table "public"."menu_item_price_history" drop constraint "menu_item_price_history_menu_item_id_fkey";

alter table "public"."menu_item_price_suggestions" drop constraint "menu_item_price_suggestions_business_id_fkey";

alter table "public"."menu_item_price_suggestions" drop constraint "menu_item_price_suggestions_menu_item_id_fkey";

alter table "public"."menu_item_price_votes" drop constraint "menu_item_price_votes_menu_item_id_fkey";

alter table "public"."menu_item_suggestions" drop constraint "menu_item_suggestions_business_id_fkey";

alter table "public"."menu_item_suggestions" drop constraint "menu_item_suggestions_menu_item_id_fkey";

alter table "public"."menu_item_variant_groups" drop constraint "menu_item_variant_groups_item_id_fkey";

alter table "public"."menu_item_variant_options" drop constraint "menu_item_variant_options_group_id_fkey";

alter table "public"."menu_item_variants" drop constraint "menu_item_variants_menu_item_id_fkey";

alter table "public"."menu_items" drop constraint "menu_items_business_id_fkey";

alter table "public"."menu_items" drop constraint "menu_items_category_id_fkey";

alter table "public"."menu_items" drop constraint "menu_items_section_id_fkey";

alter table "public"."menu_sections" drop constraint "menu_sections_menu_id_fkey";

alter table "public"."menu_snapshots" drop constraint "menu_snapshots_business_id_fkey";

alter table "public"."menu_snapshots" drop constraint "menu_snapshots_source_menu_id_fkey";

alter table "public"."menus" drop constraint "menus_business_id_fkey";

alter table "public"."notification_dispatch_jobs" drop constraint "notification_dispatch_jobs_notification_id_fkey";

alter table "public"."offer_messages" drop constraint "offer_messages_business_id_fkey";

alter table "public"."offer_messages" drop constraint "offer_messages_offer_id_fkey";

alter table "public"."offer_messages" drop constraint "offer_messages_request_id_fkey";

alter table "public"."owner_claims" drop constraint "owner_claims_business_id_fkey";

alter table "public"."owner_onboarding_progress" drop constraint "owner_onboarding_progress_business_id_fkey";

alter table "public"."photo_missions" drop constraint "photo_missions_business_id_fkey";

alter table "public"."receipt_matches" drop constraint "receipt_matches_menu_item_id_fkey";

alter table "public"."receipt_matches" drop constraint "receipt_matches_receipt_id_fkey";

alter table "public"."receipt_submissions" drop constraint "receipt_submissions_business_id_fkey";

alter table "public"."review_votes" drop constraint "review_votes_review_id_fkey";

alter table "public"."reviews" drop constraint "reviews_business_id_fkey";

alter table "public"."sponsorship_impressions_daily" drop constraint "sponsorship_impressions_daily_sponsorship_id_fkey";

alter table "public"."sponsorship_leads" drop constraint "sponsorship_leads_business_id_fkey";

alter table "public"."sponsorships" drop constraint "sponsorships_business_id_fkey";

alter table "public"."sponsorships" drop constraint "sponsorships_created_by_fkey";

alter table "public"."sponsorships" drop constraint "sponsorships_package_id_fkey";

alter table "public"."suspended_meal_claims" drop constraint "suspended_meal_claims_suspended_meal_id_fkey";

alter table "public"."suspended_meals" drop constraint "suspended_meals_business_id_fkey";

alter table "public"."table_feedback" drop constraint "table_feedback_business_id_fkey";

alter table "public"."temp_uploads" drop constraint "temp_uploads_business_id_fkey";

alter table "public"."user_achievement_awards" drop constraint "user_achievement_awards_achievement_id_fkey";

alter table "public"."user_achievements" drop constraint "user_achievements_achievement_id_fkey";

alter table "public"."user_mission_claims" drop constraint "user_mission_claims_mission_id_fkey";

alter table "public"."user_mission_claims" drop constraint "user_mission_claims_photo_id_fkey";

alter table "public"."user_policy_acceptances" drop constraint "user_policy_acceptances_policy_version_id_fkey";

alter table "public"."visits" drop constraint "visits_business_id_fkey";

drop view if exists "public"."business_quality_score_v1";

drop view if exists "public"."businesses_with_stats";

drop view if exists "public"."businesses_with_stats_mv";

-- drop type if exists "public"."geometry_dump" cascade; -- managed by postgis extension

drop function if exists "public"."get_business_menus_v1"(p_business_id uuid);

drop function if exists "public"."get_business_stories_v1"(p_business_id uuid, p_limit integer);

-- drop type if exists "public"."valid_detail" cascade; -- managed by postgis extension

drop index if exists "public"."businesses_address_trgm";

drop index if exists "public"."businesses_name_trgm";

drop index if exists "public"."food_catalog_name_trgm";

drop index if exists "public"."idx_menu_items_desc_trgm";

drop index if exists "public"."idx_menu_items_name_trgm";

alter table "public"."business_presence_events" alter column "crowd" set data type public.crowd_level using "crowd"::text::public.crowd_level;

alter table "public"."business_stories" alter column "type" set default 'update'::public.story_type;

alter table "public"."business_stories" alter column "type" set data type public.story_type using "type"::text::public.story_type;

alter table "public"."businesses" alter column "geog" set data type public.geography(Point,4326) using "geog"::public.geography(Point,4326);

alter table "public"."edge_rate_limit_events" alter column "id" set default nextval('public.edge_rate_limit_events_id_seq'::regclass);

alter table "public"."food_catalog_items" alter column "id" set default nextval('public.food_catalog_items_id_seq'::regclass);

alter table "public"."menu_item_price_suggestions" alter column "status" set default 'pending'::public.menu_price_suggestion_status;

alter table "public"."menu_item_price_suggestions" alter column "status" set data type public.menu_price_suggestion_status using "status"::text::public.menu_price_suggestion_status;

alter table "public"."menu_item_suggestions" alter column "status" set default 'pending'::public.contrib_status;

alter table "public"."menu_item_suggestions" alter column "status" set data type public.contrib_status using "status"::text::public.contrib_status;

alter table "public"."menu_translations" alter column "entity_type" set data type public.translation_entity_type using "entity_type"::text::public.translation_entity_type;

alter table "public"."menus" alter column "status" set default 'published'::public.menu_status;

alter table "public"."menus" alter column "status" set data type public.menu_status using "status"::text::public.menu_status;

alter table "public"."suspended_meal_claims" alter column "status" set default 'pending'::public.suspended_claim_status;

alter table "public"."suspended_meal_claims" alter column "status" set data type public.suspended_claim_status using "status"::text::public.suspended_claim_status;

alter table "public"."suspended_meals" alter column "status" set default 'active'::public.suspended_meal_status;

alter table "public"."suspended_meals" alter column "status" set data type public.suspended_meal_status using "status"::text::public.suspended_meal_status;

alter table "public"."user_risk_signals" alter column "id" set default nextval('public.user_risk_signals_id_seq'::regclass);

CREATE INDEX businesses_address_trgm ON public.businesses USING gin (address extensions.gin_trgm_ops);

CREATE INDEX businesses_name_trgm ON public.businesses USING gin (name extensions.gin_trgm_ops);

CREATE INDEX food_catalog_name_trgm ON public.food_catalog_items USING gin (name_norm extensions.gin_trgm_ops);

CREATE INDEX idx_menu_items_desc_trgm ON public.menu_items USING gin (lower(COALESCE(description, ''::text)) extensions.gin_trgm_ops);

CREATE INDEX idx_menu_items_name_trgm ON public.menu_items USING gin (lower(name) extensions.gin_trgm_ops);

alter table "public"."alert_events" add constraint "alert_events_alert_id_fkey" FOREIGN KEY (alert_id) REFERENCES public.price_alerts(id) ON DELETE CASCADE not valid;

alter table "public"."alert_events" validate constraint "alert_events_alert_id_fkey";

alter table "public"."alert_events" add constraint "alert_events_business_id_fkey" FOREIGN KEY (business_id) REFERENCES public.businesses(id) not valid;

alter table "public"."alert_events" validate constraint "alert_events_business_id_fkey";

alter table "public"."analytics_events" add constraint "analytics_events_business_id_fkey" FOREIGN KEY (business_id) REFERENCES public.businesses(id) ON DELETE SET NULL not valid;

alter table "public"."analytics_events" validate constraint "analytics_events_business_id_fkey";

alter table "public"."analytics_events" add constraint "analytics_events_menu_id_fkey" FOREIGN KEY (menu_id) REFERENCES public.menus(id) ON DELETE SET NULL not valid;

alter table "public"."analytics_events" validate constraint "analytics_events_menu_id_fkey";

alter table "public"."business_activity_log" add constraint "business_activity_log_business_id_fkey" FOREIGN KEY (business_id) REFERENCES public.businesses(id) ON DELETE CASCADE not valid;

alter table "public"."business_activity_log" validate constraint "business_activity_log_business_id_fkey";

alter table "public"."business_amenity_map" add constraint "business_amenity_map_amenity_id_fkey" FOREIGN KEY (amenity_id) REFERENCES public.business_amenities(id) ON DELETE CASCADE not valid;

alter table "public"."business_amenity_map" validate constraint "business_amenity_map_amenity_id_fkey";

alter table "public"."business_amenity_map" add constraint "business_amenity_map_business_id_fkey" FOREIGN KEY (business_id) REFERENCES public.businesses(id) ON DELETE CASCADE not valid;

alter table "public"."business_amenity_map" validate constraint "business_amenity_map_business_id_fkey";

alter table "public"."business_checkins" add constraint "business_checkins_business_id_fkey" FOREIGN KEY (business_id) REFERENCES public.businesses(id) ON DELETE CASCADE not valid;

alter table "public"."business_checkins" validate constraint "business_checkins_business_id_fkey";

alter table "public"."business_checkins" add constraint "business_checkins_menu_id_fkey" FOREIGN KEY (menu_id) REFERENCES public.menus(id) ON DELETE SET NULL not valid;

alter table "public"."business_checkins" validate constraint "business_checkins_menu_id_fkey";

alter table "public"."business_fee_flags" add constraint "business_fee_flags_business_id_fkey" FOREIGN KEY (business_id) REFERENCES public.businesses(id) ON DELETE CASCADE not valid;

alter table "public"."business_fee_flags" validate constraint "business_fee_flags_business_id_fkey";

alter table "public"."business_fee_votes" add constraint "business_fee_votes_business_id_fkey" FOREIGN KEY (business_id) REFERENCES public.businesses(id) ON DELETE CASCADE not valid;

alter table "public"."business_fee_votes" validate constraint "business_fee_votes_business_id_fkey";

alter table "public"."business_follows" add constraint "business_follows_business_id_fkey" FOREIGN KEY (business_id) REFERENCES public.businesses(id) ON DELETE CASCADE not valid;

alter table "public"."business_follows" validate constraint "business_follows_business_id_fkey";

alter table "public"."business_hours" add constraint "business_hours_business_id_fkey" FOREIGN KEY (business_id) REFERENCES public.businesses(id) ON DELETE CASCADE not valid;

alter table "public"."business_hours" validate constraint "business_hours_business_id_fkey";

alter table "public"."business_meal_card_providers" add constraint "business_meal_card_providers_business_id_fkey" FOREIGN KEY (business_id) REFERENCES public.businesses(id) ON DELETE CASCADE not valid;

alter table "public"."business_meal_card_providers" validate constraint "business_meal_card_providers_business_id_fkey";

alter table "public"."business_meal_card_providers" add constraint "business_meal_card_providers_provider_id_fkey" FOREIGN KEY (provider_id) REFERENCES public.meal_card_providers(id) ON DELETE CASCADE not valid;

alter table "public"."business_meal_card_providers" validate constraint "business_meal_card_providers_provider_id_fkey";

alter table "public"."business_media" add constraint "business_media_business_id_fkey" FOREIGN KEY (business_id) REFERENCES public.businesses(id) ON DELETE CASCADE not valid;

alter table "public"."business_media" validate constraint "business_media_business_id_fkey";

alter table "public"."business_menu_presentation_settings" add constraint "business_menu_presentation_settings_business_id_fkey" FOREIGN KEY (business_id) REFERENCES public.businesses(id) ON DELETE CASCADE not valid;

alter table "public"."business_menu_presentation_settings" validate constraint "business_menu_presentation_settings_business_id_fkey";

alter table "public"."business_merge_log" add constraint "business_merge_log_duplicate_business_id_fkey" FOREIGN KEY (duplicate_business_id) REFERENCES public.businesses(id) ON DELETE CASCADE not valid;

alter table "public"."business_merge_log" validate constraint "business_merge_log_duplicate_business_id_fkey";

alter table "public"."business_merge_log" add constraint "business_merge_log_primary_business_id_fkey" FOREIGN KEY (primary_business_id) REFERENCES public.businesses(id) ON DELETE CASCADE not valid;

alter table "public"."business_merge_log" validate constraint "business_merge_log_primary_business_id_fkey";

alter table "public"."business_perks" add constraint "business_perks_business_id_fkey" FOREIGN KEY (business_id) REFERENCES public.businesses(id) ON DELETE CASCADE not valid;

alter table "public"."business_perks" validate constraint "business_perks_business_id_fkey";

alter table "public"."business_policy_acceptances" add constraint "business_policy_acceptances_business_id_fkey" FOREIGN KEY (business_id) REFERENCES public.businesses(id) ON DELETE CASCADE not valid;

alter table "public"."business_policy_acceptances" validate constraint "business_policy_acceptances_business_id_fkey";

alter table "public"."business_policy_acceptances" add constraint "business_policy_acceptances_policy_version_id_fkey" FOREIGN KEY (policy_version_id) REFERENCES public.policy_versions(id) ON DELETE CASCADE not valid;

alter table "public"."business_policy_acceptances" validate constraint "business_policy_acceptances_policy_version_id_fkey";

alter table "public"."business_premium" add constraint "business_premium_business_id_fkey" FOREIGN KEY (business_id) REFERENCES public.businesses(id) ON DELETE CASCADE not valid;

alter table "public"."business_premium" validate constraint "business_premium_business_id_fkey";

alter table "public"."business_premium" add constraint "business_premium_created_by_fkey" FOREIGN KEY (created_by) REFERENCES public.admin_users(user_id) not valid;

alter table "public"."business_premium" validate constraint "business_premium_created_by_fkey";

alter table "public"."business_presence_events" add constraint "business_presence_events_business_id_fkey" FOREIGN KEY (business_id) REFERENCES public.businesses(id) ON DELETE CASCADE not valid;

alter table "public"."business_presence_events" validate constraint "business_presence_events_business_id_fkey";

alter table "public"."business_pricing_rules" add constraint "business_pricing_rules_business_id_fkey" FOREIGN KEY (business_id) REFERENCES public.businesses(id) ON DELETE CASCADE not valid;

alter table "public"."business_pricing_rules" validate constraint "business_pricing_rules_business_id_fkey";

alter table "public"."business_stats" add constraint "business_stats_business_id_fkey" FOREIGN KEY (business_id) REFERENCES public.businesses(id) ON DELETE CASCADE not valid;

alter table "public"."business_stats" validate constraint "business_stats_business_id_fkey";

alter table "public"."business_stories" add constraint "business_stories_business_id_fkey" FOREIGN KEY (business_id) REFERENCES public.businesses(id) ON DELETE CASCADE not valid;

alter table "public"."business_stories" validate constraint "business_stories_business_id_fkey";

alter table "public"."business_team_memberships" add constraint "business_team_memberships_business_id_fkey" FOREIGN KEY (business_id) REFERENCES public.businesses(id) ON DELETE CASCADE not valid;

alter table "public"."business_team_memberships" validate constraint "business_team_memberships_business_id_fkey";

alter table "public"."business_team_memberships" add constraint "business_team_memberships_chain_id_fkey" FOREIGN KEY (chain_id) REFERENCES public.chains(id) ON DELETE CASCADE not valid;

alter table "public"."business_team_memberships" validate constraint "business_team_memberships_chain_id_fkey";

alter table "public"."businesses" add constraint "businesses_chain_id_fkey" FOREIGN KEY (chain_id) REFERENCES public.chains(id) ON DELETE SET NULL not valid;

alter table "public"."businesses" validate constraint "businesses_chain_id_fkey";

alter table "public"."businesses" add constraint "businesses_verified_by_fkey" FOREIGN KEY (verified_by) REFERENCES public.admin_users(user_id) not valid;

alter table "public"."businesses" validate constraint "businesses_verified_by_fkey";

alter table "public"."chain_memberships" add constraint "chain_memberships_chain_id_fkey" FOREIGN KEY (chain_id) REFERENCES public.chains(id) ON DELETE CASCADE not valid;

alter table "public"."chain_memberships" validate constraint "chain_memberships_chain_id_fkey";

alter table "public"."collection_items" add constraint "collection_items_business_id_fkey" FOREIGN KEY (business_id) REFERENCES public.businesses(id) ON DELETE CASCADE not valid;

alter table "public"."collection_items" validate constraint "collection_items_business_id_fkey";

alter table "public"."collection_items" add constraint "collection_items_collection_id_fkey" FOREIGN KEY (collection_id) REFERENCES public.collections(id) ON DELETE CASCADE not valid;

alter table "public"."collection_items" validate constraint "collection_items_collection_id_fkey";

alter table "public"."favorites" add constraint "favorites_business_id_fkey" FOREIGN KEY (business_id) REFERENCES public.businesses(id) ON DELETE CASCADE not valid;

alter table "public"."favorites" validate constraint "favorites_business_id_fkey";

alter table "public"."feed_events" add constraint "feed_events_business_id_fkey" FOREIGN KEY (business_id) REFERENCES public.businesses(id) ON DELETE SET NULL not valid;

alter table "public"."feed_events" validate constraint "feed_events_business_id_fkey";

alter table "public"."food_catalog_items" add constraint "food_catalog_items_category_id_fkey" FOREIGN KEY (category_id) REFERENCES public.food_catalog_categories(id) ON DELETE CASCADE not valid;

alter table "public"."food_catalog_items" validate constraint "food_catalog_items_category_id_fkey";

alter table "public"."group_offers" add constraint "group_offers_business_id_fkey" FOREIGN KEY (business_id) REFERENCES public.businesses(id) ON DELETE CASCADE not valid;

alter table "public"."group_offers" validate constraint "group_offers_business_id_fkey";

alter table "public"."group_offers" add constraint "group_offers_request_id_fkey" FOREIGN KEY (request_id) REFERENCES public.group_requests(id) ON DELETE CASCADE not valid;

alter table "public"."group_offers" validate constraint "group_offers_request_id_fkey";

alter table "public"."menu_categories" add constraint "menu_categories_business_id_fkey" FOREIGN KEY (business_id) REFERENCES public.businesses(id) ON DELETE CASCADE not valid;

alter table "public"."menu_categories" validate constraint "menu_categories_business_id_fkey";

alter table "public"."menu_categories" add constraint "menu_categories_menu_id_fkey" FOREIGN KEY (menu_id) REFERENCES public.menus(id) ON DELETE CASCADE not valid;

alter table "public"."menu_categories" validate constraint "menu_categories_menu_id_fkey";

alter table "public"."menu_item_allergens" add constraint "menu_item_allergens_item_id_fkey" FOREIGN KEY (item_id) REFERENCES public.menu_items(id) ON DELETE CASCADE not valid;

alter table "public"."menu_item_allergens" validate constraint "menu_item_allergens_item_id_fkey";

alter table "public"."menu_item_diet_tags" add constraint "menu_item_diet_tags_item_id_fkey" FOREIGN KEY (item_id) REFERENCES public.menu_items(id) ON DELETE CASCADE not valid;

alter table "public"."menu_item_diet_tags" validate constraint "menu_item_diet_tags_item_id_fkey";

alter table "public"."menu_item_ingredients" add constraint "menu_item_ingredients_item_id_fkey" FOREIGN KEY (item_id) REFERENCES public.menu_items(id) ON DELETE CASCADE not valid;

alter table "public"."menu_item_ingredients" validate constraint "menu_item_ingredients_item_id_fkey";

alter table "public"."menu_item_nutrition" add constraint "menu_item_nutrition_item_id_fkey" FOREIGN KEY (item_id) REFERENCES public.menu_items(id) ON DELETE CASCADE not valid;

alter table "public"."menu_item_nutrition" validate constraint "menu_item_nutrition_item_id_fkey";

alter table "public"."menu_item_photo_votes" add constraint "menu_item_photo_votes_photo_id_fkey" FOREIGN KEY (photo_id) REFERENCES public.menu_item_photos(id) ON DELETE CASCADE not valid;

alter table "public"."menu_item_photo_votes" validate constraint "menu_item_photo_votes_photo_id_fkey";

alter table "public"."menu_item_photos" add constraint "menu_item_photos_business_id_fkey" FOREIGN KEY (business_id) REFERENCES public.businesses(id) ON DELETE CASCADE not valid;

alter table "public"."menu_item_photos" validate constraint "menu_item_photos_business_id_fkey";

alter table "public"."menu_item_photos" add constraint "menu_item_photos_menu_item_id_fkey" FOREIGN KEY (menu_item_id) REFERENCES public.menu_items(id) ON DELETE CASCADE not valid;

alter table "public"."menu_item_photos" validate constraint "menu_item_photos_menu_item_id_fkey";

alter table "public"."menu_item_price_history" add constraint "menu_item_price_history_menu_item_id_fkey" FOREIGN KEY (menu_item_id) REFERENCES public.menu_items(id) ON DELETE CASCADE not valid;

alter table "public"."menu_item_price_history" validate constraint "menu_item_price_history_menu_item_id_fkey";

alter table "public"."menu_item_price_suggestions" add constraint "menu_item_price_suggestions_business_id_fkey" FOREIGN KEY (business_id) REFERENCES public.businesses(id) ON DELETE CASCADE not valid;

alter table "public"."menu_item_price_suggestions" validate constraint "menu_item_price_suggestions_business_id_fkey";

alter table "public"."menu_item_price_suggestions" add constraint "menu_item_price_suggestions_menu_item_id_fkey" FOREIGN KEY (menu_item_id) REFERENCES public.menu_items(id) ON DELETE CASCADE not valid;

alter table "public"."menu_item_price_suggestions" validate constraint "menu_item_price_suggestions_menu_item_id_fkey";

alter table "public"."menu_item_price_votes" add constraint "menu_item_price_votes_menu_item_id_fkey" FOREIGN KEY (menu_item_id) REFERENCES public.menu_items(id) ON DELETE CASCADE not valid;

alter table "public"."menu_item_price_votes" validate constraint "menu_item_price_votes_menu_item_id_fkey";

alter table "public"."menu_item_suggestions" add constraint "menu_item_suggestions_business_id_fkey" FOREIGN KEY (business_id) REFERENCES public.businesses(id) ON DELETE CASCADE not valid;

alter table "public"."menu_item_suggestions" validate constraint "menu_item_suggestions_business_id_fkey";

alter table "public"."menu_item_suggestions" add constraint "menu_item_suggestions_menu_item_id_fkey" FOREIGN KEY (menu_item_id) REFERENCES public.menu_items(id) ON DELETE CASCADE not valid;

alter table "public"."menu_item_suggestions" validate constraint "menu_item_suggestions_menu_item_id_fkey";

alter table "public"."menu_item_variant_groups" add constraint "menu_item_variant_groups_item_id_fkey" FOREIGN KEY (item_id) REFERENCES public.menu_items(id) ON DELETE CASCADE not valid;

alter table "public"."menu_item_variant_groups" validate constraint "menu_item_variant_groups_item_id_fkey";

alter table "public"."menu_item_variant_options" add constraint "menu_item_variant_options_group_id_fkey" FOREIGN KEY (group_id) REFERENCES public.menu_item_variant_groups(id) ON DELETE CASCADE not valid;

alter table "public"."menu_item_variant_options" validate constraint "menu_item_variant_options_group_id_fkey";

alter table "public"."menu_item_variants" add constraint "menu_item_variants_menu_item_id_fkey" FOREIGN KEY (menu_item_id) REFERENCES public.menu_items(id) ON DELETE CASCADE not valid;

alter table "public"."menu_item_variants" validate constraint "menu_item_variants_menu_item_id_fkey";

alter table "public"."menu_items" add constraint "menu_items_business_id_fkey" FOREIGN KEY (business_id) REFERENCES public.businesses(id) ON DELETE CASCADE not valid;

alter table "public"."menu_items" validate constraint "menu_items_business_id_fkey";

alter table "public"."menu_items" add constraint "menu_items_category_id_fkey" FOREIGN KEY (category_id) REFERENCES public.menu_categories(id) ON DELETE SET NULL not valid;

alter table "public"."menu_items" validate constraint "menu_items_category_id_fkey";

alter table "public"."menu_items" add constraint "menu_items_section_id_fkey" FOREIGN KEY (section_id) REFERENCES public.menu_sections(id) ON DELETE CASCADE not valid;

alter table "public"."menu_items" validate constraint "menu_items_section_id_fkey";

alter table "public"."menu_sections" add constraint "menu_sections_menu_id_fkey" FOREIGN KEY (menu_id) REFERENCES public.menus(id) ON DELETE CASCADE not valid;

alter table "public"."menu_sections" validate constraint "menu_sections_menu_id_fkey";

alter table "public"."menu_snapshots" add constraint "menu_snapshots_business_id_fkey" FOREIGN KEY (business_id) REFERENCES public.businesses(id) ON DELETE CASCADE not valid;

alter table "public"."menu_snapshots" validate constraint "menu_snapshots_business_id_fkey";

alter table "public"."menu_snapshots" add constraint "menu_snapshots_source_menu_id_fkey" FOREIGN KEY (source_menu_id) REFERENCES public.menus(id) ON DELETE CASCADE not valid;

alter table "public"."menu_snapshots" validate constraint "menu_snapshots_source_menu_id_fkey";

alter table "public"."menus" add constraint "menus_business_id_fkey" FOREIGN KEY (business_id) REFERENCES public.businesses(id) ON DELETE CASCADE not valid;

alter table "public"."menus" validate constraint "menus_business_id_fkey";

alter table "public"."notification_dispatch_jobs" add constraint "notification_dispatch_jobs_notification_id_fkey" FOREIGN KEY (notification_id) REFERENCES public.notifications(id) ON DELETE CASCADE not valid;

alter table "public"."notification_dispatch_jobs" validate constraint "notification_dispatch_jobs_notification_id_fkey";

alter table "public"."offer_messages" add constraint "offer_messages_business_id_fkey" FOREIGN KEY (business_id) REFERENCES public.businesses(id) ON DELETE SET NULL not valid;

alter table "public"."offer_messages" validate constraint "offer_messages_business_id_fkey";

alter table "public"."offer_messages" add constraint "offer_messages_offer_id_fkey" FOREIGN KEY (offer_id) REFERENCES public.group_offers(id) ON DELETE SET NULL not valid;

alter table "public"."offer_messages" validate constraint "offer_messages_offer_id_fkey";

alter table "public"."offer_messages" add constraint "offer_messages_request_id_fkey" FOREIGN KEY (request_id) REFERENCES public.group_requests(id) ON DELETE CASCADE not valid;

alter table "public"."offer_messages" validate constraint "offer_messages_request_id_fkey";

alter table "public"."owner_claims" add constraint "owner_claims_business_id_fkey" FOREIGN KEY (business_id) REFERENCES public.businesses(id) ON DELETE CASCADE not valid;

alter table "public"."owner_claims" validate constraint "owner_claims_business_id_fkey";

alter table "public"."owner_onboarding_progress" add constraint "owner_onboarding_progress_business_id_fkey" FOREIGN KEY (business_id) REFERENCES public.businesses(id) ON DELETE CASCADE not valid;

alter table "public"."owner_onboarding_progress" validate constraint "owner_onboarding_progress_business_id_fkey";

alter table "public"."photo_missions" add constraint "photo_missions_business_id_fkey" FOREIGN KEY (business_id) REFERENCES public.businesses(id) ON DELETE CASCADE not valid;

alter table "public"."photo_missions" validate constraint "photo_missions_business_id_fkey";

alter table "public"."receipt_matches" add constraint "receipt_matches_menu_item_id_fkey" FOREIGN KEY (menu_item_id) REFERENCES public.menu_items(id) ON DELETE CASCADE not valid;

alter table "public"."receipt_matches" validate constraint "receipt_matches_menu_item_id_fkey";

alter table "public"."receipt_matches" add constraint "receipt_matches_receipt_id_fkey" FOREIGN KEY (receipt_id) REFERENCES public.receipt_submissions(id) ON DELETE CASCADE not valid;

alter table "public"."receipt_matches" validate constraint "receipt_matches_receipt_id_fkey";

alter table "public"."receipt_submissions" add constraint "receipt_submissions_business_id_fkey" FOREIGN KEY (business_id) REFERENCES public.businesses(id) ON DELETE CASCADE not valid;

alter table "public"."receipt_submissions" validate constraint "receipt_submissions_business_id_fkey";

alter table "public"."review_votes" add constraint "review_votes_review_id_fkey" FOREIGN KEY (review_id) REFERENCES public.reviews(id) ON DELETE CASCADE not valid;

alter table "public"."review_votes" validate constraint "review_votes_review_id_fkey";

alter table "public"."reviews" add constraint "reviews_business_id_fkey" FOREIGN KEY (business_id) REFERENCES public.businesses(id) ON DELETE CASCADE not valid;

alter table "public"."reviews" validate constraint "reviews_business_id_fkey";

alter table "public"."sponsorship_impressions_daily" add constraint "sponsorship_impressions_daily_sponsorship_id_fkey" FOREIGN KEY (sponsorship_id) REFERENCES public.sponsorships(id) ON DELETE CASCADE not valid;

alter table "public"."sponsorship_impressions_daily" validate constraint "sponsorship_impressions_daily_sponsorship_id_fkey";

alter table "public"."sponsorship_leads" add constraint "sponsorship_leads_business_id_fkey" FOREIGN KEY (business_id) REFERENCES public.businesses(id) ON DELETE CASCADE not valid;

alter table "public"."sponsorship_leads" validate constraint "sponsorship_leads_business_id_fkey";

alter table "public"."sponsorships" add constraint "sponsorships_business_id_fkey" FOREIGN KEY (business_id) REFERENCES public.businesses(id) ON DELETE CASCADE not valid;

alter table "public"."sponsorships" validate constraint "sponsorships_business_id_fkey";

alter table "public"."sponsorships" add constraint "sponsorships_created_by_fkey" FOREIGN KEY (created_by) REFERENCES public.admin_users(user_id) not valid;

alter table "public"."sponsorships" validate constraint "sponsorships_created_by_fkey";

alter table "public"."sponsorships" add constraint "sponsorships_package_id_fkey" FOREIGN KEY (package_id) REFERENCES public.sponsorship_packages(id) not valid;

alter table "public"."sponsorships" validate constraint "sponsorships_package_id_fkey";

alter table "public"."suspended_meal_claims" add constraint "suspended_meal_claims_suspended_meal_id_fkey" FOREIGN KEY (suspended_meal_id) REFERENCES public.suspended_meals(id) ON DELETE CASCADE not valid;

alter table "public"."suspended_meal_claims" validate constraint "suspended_meal_claims_suspended_meal_id_fkey";

alter table "public"."suspended_meals" add constraint "suspended_meals_business_id_fkey" FOREIGN KEY (business_id) REFERENCES public.businesses(id) ON DELETE CASCADE not valid;

alter table "public"."suspended_meals" validate constraint "suspended_meals_business_id_fkey";

alter table "public"."table_feedback" add constraint "table_feedback_business_id_fkey" FOREIGN KEY (business_id) REFERENCES public.businesses(id) ON DELETE CASCADE not valid;

alter table "public"."table_feedback" validate constraint "table_feedback_business_id_fkey";

alter table "public"."temp_uploads" add constraint "temp_uploads_business_id_fkey" FOREIGN KEY (business_id) REFERENCES public.businesses(id) ON DELETE CASCADE not valid;

alter table "public"."temp_uploads" validate constraint "temp_uploads_business_id_fkey";

alter table "public"."user_achievement_awards" add constraint "user_achievement_awards_achievement_id_fkey" FOREIGN KEY (achievement_id) REFERENCES public.achievements(id) ON DELETE CASCADE not valid;

alter table "public"."user_achievement_awards" validate constraint "user_achievement_awards_achievement_id_fkey";

alter table "public"."user_achievements" add constraint "user_achievements_achievement_id_fkey" FOREIGN KEY (achievement_id) REFERENCES public.achievements(id) ON DELETE CASCADE not valid;

alter table "public"."user_achievements" validate constraint "user_achievements_achievement_id_fkey";

alter table "public"."user_mission_claims" add constraint "user_mission_claims_mission_id_fkey" FOREIGN KEY (mission_id) REFERENCES public.photo_missions(id) ON DELETE CASCADE not valid;

alter table "public"."user_mission_claims" validate constraint "user_mission_claims_mission_id_fkey";

alter table "public"."user_mission_claims" add constraint "user_mission_claims_photo_id_fkey" FOREIGN KEY (photo_id) REFERENCES public.menu_item_photos(id) ON DELETE SET NULL not valid;

alter table "public"."user_mission_claims" validate constraint "user_mission_claims_photo_id_fkey";

alter table "public"."user_policy_acceptances" add constraint "user_policy_acceptances_policy_version_id_fkey" FOREIGN KEY (policy_version_id) REFERENCES public.policy_versions(id) ON DELETE CASCADE not valid;

alter table "public"."user_policy_acceptances" validate constraint "user_policy_acceptances_policy_version_id_fkey";

alter table "public"."visits" add constraint "visits_business_id_fkey" FOREIGN KEY (business_id) REFERENCES public.businesses(id) ON DELETE CASCADE not valid;

alter table "public"."visits" validate constraint "visits_business_id_fkey";

set check_function_bodies = off;

CREATE OR REPLACE FUNCTION public.admin_approve_business_suggestion_v1(p_suggestion_id uuid, p_admin_note text DEFAULT NULL::text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  v_s public.business_suggestions%rowtype;
  v_new_business_id uuid;
begin
  if not public.is_admin() then
    raise exception 'not_admin';
  end if;

  select *
  into v_s
  from public.business_suggestions
  where id = p_suggestion_id;

  if v_s.id is null then
    return jsonb_build_object('ok', false, 'error', 'suggestion_not_found');
  end if;

  if v_s.status <> 'pending' then
    return jsonb_build_object('ok', false, 'error', 'not_pending');
  end if;

  insert into public.businesses (
    name,
    category,
    address,
    city,
    district,
    lat,
    lng
  ) values (
    v_s.name,
    v_s.category,
    v_s.address,
    v_s.city,
    v_s.district,
    null,
    null
  )
  returning id into v_new_business_id;

  update public.business_suggestions
  set
    status = 'approved',
    approved_business_id = v_new_business_id,
    admin_note = p_admin_note,
    handled_by = auth.uid(),
    handled_at = now()
  where id = p_suggestion_id;

  -- 🔍 AUDIT LOG
  perform public.log_admin_action_v1(
    'suggestion.approve',
    'business_suggestions',
    p_suggestion_id,
    jsonb_build_object(
      'business_id', v_new_business_id,
      'admin_note', p_admin_note
    )
  );

  return jsonb_build_object(
    'ok', true,
    'business_id', v_new_business_id
  );
end;
$function$
;

CREATE OR REPLACE FUNCTION public.admin_approve_suspended_claim_v1(p_claim_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  v_meal_id uuid;
  v_meal_status public.suspended_meal_status;
begin
  if not public.is_admin() then
    return jsonb_build_object('ok', false, 'error', 'not_admin');
  end if;

  select suspended_meal_id into v_meal_id
  from public.suspended_meal_claims
  where id = p_claim_id and status='pending';

  if v_meal_id is null then
    return jsonb_build_object('ok', false, 'error', 'not_found_or_not_pending');
  end if;

  select status into v_meal_status
  from public.suspended_meals
  where id = v_meal_id;

  if v_meal_status <> 'active' then
    return jsonb_build_object('ok', false, 'error', 'meal_not_active');
  end if;

  update public.suspended_meal_claims
  set status='approved',
      handled_by=auth.uid(),
      handled_at=now()
  where id = p_claim_id;

  update public.suspended_meals
  set status='claimed'
  where id = v_meal_id;

  return jsonb_build_object('ok', true);
end;
$function$
;

CREATE OR REPLACE FUNCTION public.admin_assign_business_suggestion_v1(p_suggestion_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
begin
  if not public.is_admin() then raise exception 'not_admin'; end if;

  update public.business_suggestions
  set assigned_to = auth.uid(),
      assigned_at = now()
  where id = p_suggestion_id;

  perform public.log_admin_action_v1(
    'suggestion.assign',
    'business_suggestions',
    p_suggestion_id,
    jsonb_build_object('assigned_to', auth.uid())
  );

  return jsonb_build_object('ok', true);
end;
$function$
;

CREATE OR REPLACE FUNCTION public.admin_assign_owner_claim_v1(p_claim_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
begin
  if not public.is_admin() then raise exception 'not_admin'; end if;

  update public.owner_claims
  set assigned_to = auth.uid(),
      assigned_at = now()
  where id = p_claim_id;

  perform public.log_admin_action_v1(
    'claim.assign',
    'owner_claims',
    p_claim_id,
    jsonb_build_object('assigned_to', auth.uid())
  );

  return jsonb_build_object('ok', true);
end;
$function$
;

CREATE OR REPLACE FUNCTION public.admin_assign_report_v1(p_report_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
begin
  if not public.is_admin() then raise exception 'not_admin'; end if;

  update public.reports
  set assigned_to = auth.uid(),
      assigned_at = now()
  where id = p_report_id;

  perform public.log_admin_action_v1(
    'report.assign',
    'reports',
    p_report_id,
    jsonb_build_object('assigned_to', auth.uid())
  );

  return jsonb_build_object('ok', true);
end;
$function$
;

CREATE OR REPLACE FUNCTION public.admin_bulk_decide_owner_claims_v1(p_claim_ids uuid[], p_decision text, p_note text DEFAULT NULL::text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  v_count int;
begin
  if not public.is_admin() then
    raise exception 'not_admin';
  end if;

  update public.owner_claims
  set
    status = p_decision,
    handled_by = auth.uid(),
    handled_at = now(),
    admin_note = p_note
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
$function$
;

CREATE OR REPLACE FUNCTION public.admin_bulk_reject_business_suggestions_v1(p_suggestion_ids uuid[], p_admin_note text DEFAULT NULL::text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  v_count int;
begin
  if not public.is_admin() then
    raise exception 'not_admin';
  end if;

  update public.business_suggestions
  set
    status = 'rejected',
    handled_by = auth.uid(),
    handled_at = now(),
    admin_note = p_admin_note
  where id = any(p_suggestion_ids)
    and status = 'pending';

  get diagnostics v_count = row_count;

  perform public.log_admin_action_v1(
    'suggestion.bulk_reject',
    'business_suggestions',
    null,
    jsonb_build_object('count', v_count)
  );

  return jsonb_build_object('ok', true, 'updated', v_count);
end;
$function$
;

CREATE OR REPLACE FUNCTION public.admin_bulk_replace_preview_v1(p_table text, p_column text, p_from text, p_case_insensitive boolean DEFAULT true)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  v_sql text;
  v_count int;
begin
  if not public.is_admin() then raise exception 'not_admin'; end if;

  if p_table not in ('businesses','business_suggestions') then
    return jsonb_build_object('ok', false, 'error', 'bad_table');
  end if;
  if p_column not in ('city','district') then
    return jsonb_build_object('ok', false, 'error', 'bad_column');
  end if;

  if p_case_insensitive then
    v_sql := format('select count(*) from public.%I where lower(%I) = lower($1)', p_table, p_column);
  else
    v_sql := format('select count(*) from public.%I where %I = $1', p_table, p_column);
  end if;

  execute v_sql into v_count using p_from;

  return jsonb_build_object('ok', true, 'count', v_count);
end;
$function$
;

CREATE OR REPLACE FUNCTION public.admin_bulk_replace_text_v1(p_table text, p_column text, p_from text, p_to text, p_case_insensitive boolean DEFAULT true)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  v_sql text;
  v_count int;
begin
  if not public.is_admin() then raise exception 'not_admin'; end if;

  if p_table not in ('businesses','business_suggestions') then
    return jsonb_build_object('ok', false, 'error', 'bad_table');
  end if;

  if p_column not in ('city','district') then
    return jsonb_build_object('ok', false, 'error', 'bad_column');
  end if;

  if p_case_insensitive then
    v_sql := format('update public.%I set %I = $1 where lower(%I) = lower($2)', p_table, p_column, p_column);
  else
    v_sql := format('update public.%I set %I = $1 where %I = $2', p_table, p_column, p_column);
  end if;

  execute v_sql using p_to, p_from;
  get diagnostics v_count = row_count;

  perform public.log_admin_action_v1(
    'admin.bulk_replace_text',
    p_table,
    null,
    jsonb_build_object('column', p_column, 'from', p_from, 'to', p_to, 'count', v_count)
  );

  return jsonb_build_object('ok', true, 'updated', v_count);
end;
$function$
;

CREATE OR REPLACE FUNCTION public.admin_bulk_replace_url_prefix_v1(p_field text, p_from_prefix text, p_to_prefix text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  v_count int;
begin
  if not public.is_admin() then raise exception 'not_admin'; end if;
  if p_field not in ('logo_url','cover_url') then
    return jsonb_build_object('ok', false, 'error', 'bad_field');
  end if;

  execute format(
    'update public.businesses set %I = regexp_replace(%I, $1, $2) where %I like ($1 || ''%%'')',
    p_field, p_field, p_field
  )
  using p_from_prefix, p_to_prefix;

  get diagnostics v_count = row_count;

  perform public.log_admin_action_v1(
    'business.bulk_replace_url_prefix',
    'businesses',
    null,
    jsonb_build_object('field', p_field, 'from', p_from_prefix, 'to', p_to_prefix, 'count', v_count)
  );

  return jsonb_build_object('ok', true, 'updated', v_count);
end;
$function$
;

create or replace view "public"."admin_business_suggestions_queue_v1" as  SELECT id,
    created_at,
    user_id,
    name,
    category,
    address,
    city,
    district,
    notes,
    status
   FROM public.business_suggestions s;


CREATE OR REPLACE FUNCTION public.admin_decide_owner_claim_v1(p_claim_id uuid, p_decision text, p_note text DEFAULT NULL::text)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
begin
  if not public.is_admin() then
    raise exception 'not_admin';
  end if;

  update public.owner_claims
  set
    status = p_decision,
    handled_by = auth.uid(),
    handled_at = now(),
    admin_note = p_note
  where id = p_claim_id;

  -- 🔍 AUDIT LOG
  perform public.log_admin_action_v1(
    case
      when p_decision = 'approved' then 'claim.approve'
      else 'claim.reject'
    end,
    'owner_claims',
    p_claim_id,
    jsonb_build_object(
      'decision', p_decision,
      'admin_note', p_note
    )
  );
end;
$function$
;

CREATE OR REPLACE FUNCTION public.admin_export_business_suggestions_csv_v1(p_status text DEFAULT NULL::text, p_q text DEFAULT NULL::text)
 RETURNS text
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  v_csv text;
begin
  if not public.is_admin() then
    raise exception 'not_admin';
  end if;

  select string_agg(line, E'\n') into v_csv
  from (
    select
      'id,created_at,status,user_id,name,category,address,city,district,notes,admin_note,approved_business_id,handled_by,handled_at' as line
    union all
    select
      concat_ws(',',
        s.id::text,
        to_char(s.created_at, 'YYYY-MM-DD"T"HH24:MI:SS"Z"'),
        replace(coalesce(s.status,''), ',', ' '),
        coalesce(s.user_id::text,''),
        replace(coalesce(s.name,''), ',', ' '),
        replace(coalesce(s.category,''), ',', ' '),
        replace(coalesce(s.address,''), ',', ' '),
        replace(coalesce(s.city,''), ',', ' '),
        replace(coalesce(s.district,''), ',', ' '),
        replace(coalesce(s.notes,''), E'\n', ' '),
        replace(coalesce(s.admin_note,''), E'\n', ' '),
        coalesce(s.approved_business_id::text,''),
        coalesce(s.handled_by::text,''),
        coalesce(to_char(s.handled_at, 'YYYY-MM-DD"T"HH24:MI:SS"Z"'),'')
      ) as line
    from public.business_suggestions s
    where (p_status is null or s.status = p_status)
      and (
        p_q is null
        or s.name ilike ('%'||p_q||'%')
        or s.address ilike ('%'||p_q||'%')
        or s.city ilike ('%'||p_q||'%')
        or s.district ilike ('%'||p_q||'%')
        or s.notes ilike ('%'||p_q||'%')
        or s.admin_note ilike ('%'||p_q||'%')
      )
    order by s.created_at desc
  ) t;

  perform public.log_admin_action_v1(
    'suggestion.export_csv',
    'business_suggestions',
    null,
    jsonb_build_object('status', p_status, 'q', p_q)
  );

  return v_csv;
end;
$function$
;

CREATE OR REPLACE FUNCTION public.admin_export_owner_claims_csv_v1(p_status text DEFAULT NULL::text, p_q text DEFAULT NULL::text)
 RETURNS text
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  v_csv text;
begin
  if not public.is_admin() then
    raise exception 'not_admin';
  end if;

  select string_agg(line, E'\n') into v_csv
  from (
    select
      'id,created_at,status,user_id,business_id,full_name,phone,evidence_url,note,handled_by,handled_at,admin_note' as line
    union all
    select
      concat_ws(',',
        c.id::text,
        to_char(c.created_at, 'YYYY-MM-DD"T"HH24:MI:SS"Z"'),
        replace(coalesce(c.status,''), ',', ' '),
        coalesce(c.user_id::text,''),
        coalesce(c.business_id::text,''),
        replace(coalesce(c.full_name,''), ',', ' '),
        replace(coalesce(c.phone,''), ',', ' '),
        replace(coalesce(c.evidence_url,''), ',', ' '),
        replace(coalesce(c.note,''), E'\n', ' '),
        coalesce(c.handled_by::text,''),
        coalesce(to_char(c.handled_at, 'YYYY-MM-DD"T"HH24:MI:SS"Z"'),''),
        replace(coalesce(c.admin_note,''), E'\n', ' ')
      ) as line
    from public.owner_claims c
    where (p_status is null or c.status = p_status)
      and (
        p_q is null
        or c.full_name ilike ('%'||p_q||'%')
        or c.phone ilike ('%'||p_q||'%')
        or c.note ilike ('%'||p_q||'%')
        or c.evidence_url ilike ('%'||p_q||'%')
        or c.admin_note ilike ('%'||p_q||'%')
      )
    order by c.created_at desc
  ) t;

  perform public.log_admin_action_v1(
    'claim.export_csv',
    'owner_claims',
    null,
    jsonb_build_object('status', p_status, 'q', p_q)
  );

  return v_csv;
end;
$function$
;

CREATE OR REPLACE FUNCTION public.admin_export_suspended_claims_csv_v1(p_status text DEFAULT 'pending'::text, p_sla_only boolean DEFAULT false)
 RETURNS text
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  with rows as (
    select *
    from public.admin_list_suspended_claims_v1(p_status, 5000, 0, p_sla_only)
  )
  select string_agg(
    claim_id::text || ',' ||
    claim_status || ',' ||
    claim_created_at::text || ',' ||
    business_name || ',' ||
    city || ',' ||
    district || ',' ||
    (meal_amount_cents::text) || ',' ||
    meal_currency || ',' ||
    coalesce(replace(meal_message, E'\n',' '),'') || ',' ||
    claimant_user_id::text || ',' ||
    replace(claimant_name, ',',' ')
  , E'\n')
  from rows;
$function$
;

CREATE OR REPLACE FUNCTION public.admin_find_duplicate_businesses_v1(p_suggestion_id uuid, p_threshold double precision DEFAULT 0.6)
 RETURNS TABLE(business_id uuid, name text, address text, city text, district text, score double precision)
 LANGUAGE sql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  with s as (
    select name, address, city, district
    from public.business_suggestions
    where id = p_suggestion_id
  )
  select
    b.id as business_id,
    b.name,
    b.address,
    b.city,
    b.district,
    (
      similarity(lower(b.name), lower(s.name)) * 0.7 +
      similarity(lower(coalesce(b.address,'')), lower(coalesce(s.address,''))) * 0.3
    ) as score
  from public.businesses b, s
  where public.is_admin()
    and b.city = s.city
    and b.district = s.district
    and (
      similarity(lower(b.name), lower(s.name)) > p_threshold
      or similarity(lower(coalesce(b.address,'')), lower(coalesce(s.address,''))) > p_threshold
    )
  order by score desc
  limit 5;
$function$
;

CREATE OR REPLACE FUNCTION public.admin_link_suggestion_to_business_v1(p_suggestion_id uuid, p_business_id uuid, p_admin_note text DEFAULT NULL::text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
begin
  if not public.is_admin() then
    raise exception 'not_admin';
  end if;

  update public.business_suggestions
  set
    status = 'approved',
    approved_business_id = p_business_id,
    handled_by = auth.uid(),
    handled_at = now(),
    admin_note = p_admin_note
  where id = p_suggestion_id
    and status = 'pending';

  perform public.log_admin_action_v1(
    'suggestion.link_existing',
    'business_suggestions',
    p_suggestion_id,
    jsonb_build_object('business_id', p_business_id)
  );

  return jsonb_build_object('ok', true);
end;
$function$
;

CREATE OR REPLACE FUNCTION public.admin_list_business_suggestions_v1(p_status text DEFAULT NULL::text, p_limit integer DEFAULT 50, p_offset integer DEFAULT 0, p_q text DEFAULT NULL::text)
 RETURNS TABLE(id uuid, created_at timestamp with time zone, status text, user_id uuid, name text, category text, address text, city text, district text, notes text, admin_note text, handled_by uuid, handled_at timestamp with time zone, approved_business_id uuid)
 LANGUAGE sql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  select
    s.id, s.created_at, s.status, s.user_id,
    s.name, s.category, s.address, s.city, s.district, s.notes,
    s.admin_note, s.handled_by, s.handled_at, s.approved_business_id
  from public.business_suggestions s
  where public.is_admin()
    and (p_status is null or s.status = p_status)
    and (
      p_q is null
      or s.name ilike ('%'||p_q||'%')
      or s.address ilike ('%'||p_q||'%')
      or s.city ilike ('%'||p_q||'%')
      or s.district ilike ('%'||p_q||'%')
      or s.notes ilike ('%'||p_q||'%')
      or s.admin_note ilike ('%'||p_q||'%')
    )
  order by s.created_at desc
  limit greatest(p_limit,0)
  offset greatest(p_offset,0);
$function$
;

CREATE OR REPLACE FUNCTION public.admin_list_business_suggestions_v3(p_status text DEFAULT NULL::text, p_limit integer DEFAULT 50, p_offset integer DEFAULT 0, p_q text DEFAULT NULL::text, p_assigned text DEFAULT NULL::text, p_sla_only boolean DEFAULT false)
 RETURNS TABLE(id uuid, created_at timestamp with time zone, status text, user_id uuid, name text, category text, address text, city text, district text, notes text, admin_note text, approved_business_id uuid, assigned_to uuid, assigned_at timestamp with time zone, handled_by uuid, handled_at timestamp with time zone, age_days double precision, sla_breached boolean)
 LANGUAGE sql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  with base as (
    select
      s.*,
      (extract(epoch from (now() - s.created_at))/86400.0)::float as age_days,
      (
        s.handled_at is null
        and s.status = 'pending'
        and s.created_at < now() - interval '7 days'
      ) as sla_breached
    from public.business_suggestions s
    where public.is_admin()
      and (p_status is null or s.status = p_status)
      and (
        p_assigned is null
        or (p_assigned='me' and s.assigned_to = auth.uid())
        or (p_assigned='unassigned' and s.assigned_to is null)
      )
      and (
        p_q is null
        or s.name ilike ('%'||p_q||'%')
        or s.address ilike ('%'||p_q||'%')
        or s.city ilike ('%'||p_q||'%')
        or s.district ilike ('%'||p_q||'%')
        or s.notes ilike ('%'||p_q||'%')
        or s.admin_note ilike ('%'||p_q||'%')
      )
  )
  select
    id, created_at, status, user_id, name, category, address, city, district, notes,
    admin_note, approved_business_id,
    assigned_to, assigned_at, handled_by, handled_at,
    age_days, sla_breached
  from base
  where (not p_sla_only) or sla_breached
  order by
    sla_breached desc,
    created_at desc
  limit greatest(p_limit,0)
  offset greatest(p_offset,0);
$function$
;

CREATE OR REPLACE FUNCTION public.admin_list_businesses_v1(p_limit integer DEFAULT 50, p_offset integer DEFAULT 0, p_q text DEFAULT NULL::text, p_city text DEFAULT NULL::text, p_district text DEFAULT NULL::text)
 RETURNS TABLE(id uuid, name text, category text, address text, city text, district text, lat double precision, lng double precision, logo_url text, cover_url text, created_at timestamp with time zone)
 LANGUAGE sql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  select
    b.id, b.name, b.category, b.address, b.city, b.district,
    b.lat, b.lng, b.logo_url, b.cover_url, b.created_at
  from public.businesses b
  where public.is_admin()
    and (p_city is null or b.city = p_city)
    and (p_district is null or b.district = p_district)
    and (
      p_q is null
      or b.name ilike ('%'||p_q||'%')
      or b.address ilike ('%'||p_q||'%')
      or b.category ilike ('%'||p_q||'%')
    )
  order by b.created_at desc
  limit greatest(p_limit,0)
  offset greatest(p_offset,0);
$function$
;

CREATE OR REPLACE FUNCTION public.admin_list_menu_price_suggestions_v1(p_status text DEFAULT 'pending'::text, p_limit integer DEFAULT 30, p_offset integer DEFAULT 0, p_sla_only boolean DEFAULT false)
 RETURNS TABLE(suggestion_id uuid, status text, created_at timestamp with time zone, sla_breached boolean, business_id uuid, business_name text, city text, district text, menu_item_id uuid, item_name text, current_price_cents integer, suggested_price_cents integer, currency text, created_by uuid)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
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

    s.created_by
  from public.menu_item_price_suggestions s
  join public.menu_items mi on mi.id = s.menu_item_id
  join public.businesses b on b.id = s.business_id
  where public.is_admin()
    and (p_status is null or s.status::text = p_status)
    and (not p_sla_only or (s.status='pending' and s.created_at < now() - interval '48 hours'))
  order by (s.status='pending') desc, s.created_at asc
  limit greatest(p_limit,0) offset greatest(p_offset,0);
$function$
;

CREATE OR REPLACE FUNCTION public.admin_list_owner_claims_v1(p_status text DEFAULT NULL::text, p_limit integer DEFAULT 50, p_offset integer DEFAULT 0, p_q text DEFAULT NULL::text)
 RETURNS TABLE(id uuid, created_at timestamp with time zone, status text, user_id uuid, business_id uuid, full_name text, phone text, evidence_url text, note text, handled_by uuid, handled_at timestamp with time zone, admin_note text)
 LANGUAGE sql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  select
    c.id, c.created_at, c.status, c.user_id, c.business_id,
    c.full_name, c.phone, c.evidence_url, c.note,
    c.handled_by, c.handled_at, c.admin_note
  from public.owner_claims c
  where public.is_admin()
    and (p_status is null or c.status = p_status)
    and (
      p_q is null
      or c.full_name ilike ('%'||p_q||'%')
      or c.phone ilike ('%'||p_q||'%')
      or c.note ilike ('%'||p_q||'%')
      or c.evidence_url ilike ('%'||p_q||'%')
      or c.admin_note ilike ('%'||p_q||'%')
    )
  order by c.created_at desc
  limit greatest(p_limit,0)
  offset greatest(p_offset,0);
$function$
;

CREATE OR REPLACE FUNCTION public.admin_list_suspended_claims_v1(p_status text DEFAULT 'pending'::text, p_limit integer DEFAULT 30, p_offset integer DEFAULT 0, p_sla_only boolean DEFAULT false)
 RETURNS TABLE(claim_id uuid, claim_status text, claim_created_at timestamp with time zone, sla_breached boolean, meal_id uuid, meal_amount_cents integer, meal_currency text, meal_message text, meal_created_at timestamp with time zone, business_id uuid, business_name text, city text, district text, claimant_user_id uuid, claimant_name text)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  select
    c.id as claim_id,
    c.status::text as claim_status,
    c.created_at as claim_created_at,
    (c.status='pending' and c.created_at < now() - interval '24 hours') as sla_breached,

    m.id as meal_id,
    m.amount_cents as meal_amount_cents,
    m.currency as meal_currency,
    m.message as meal_message,
    m.created_at as meal_created_at,

    b.id as business_id,
    b.name as business_name,
    b.city,
    b.district,

    c.claimant_user_id,
    coalesce(p.display_name,'Kullanıcı') as claimant_name
  from public.suspended_meal_claims c
  join public.suspended_meals m on m.id = c.suspended_meal_id
  join public.businesses b on b.id = m.business_id
  left join public.user_profiles p on p.user_id = c.claimant_user_id
  where public.is_admin()
    and (p_status is null or c.status::text = p_status)
    and (not p_sla_only or (c.status='pending' and c.created_at < now() - interval '24 hours'))
  order by
    (c.status='pending') desc,
    c.created_at asc
  limit greatest(p_limit,0)
  offset greatest(p_offset,0);
$function$
;

create or replace view "public"."admin_owner_claims_queue_v1" as  SELECT id,
    created_at,
    status,
    user_id,
    business_id,
    full_name,
    phone,
    evidence_url,
    note,
    handled_by,
    handled_at,
    admin_note
   FROM public.owner_claims c;


CREATE OR REPLACE FUNCTION public.admin_reject_business_suggestion_v1(p_suggestion_id uuid, p_admin_note text DEFAULT NULL::text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  v_status text;
begin
  if not public.is_admin() then
    raise exception 'not_admin';
  end if;

  select status
  into v_status
  from public.business_suggestions
  where id = p_suggestion_id;

  if v_status is null then
    return jsonb_build_object('ok', false, 'error', 'suggestion_not_found');
  end if;

  if v_status <> 'pending' then
    return jsonb_build_object('ok', false, 'error', 'not_pending');
  end if;

  update public.business_suggestions
  set
    status = 'rejected',
    admin_note = p_admin_note,
    handled_by = auth.uid(),
    handled_at = now()
  where id = p_suggestion_id;

  -- 🔍 AUDIT LOG
  perform public.log_admin_action_v1(
    'suggestion.reject',
    'business_suggestions',
    p_suggestion_id,
    jsonb_build_object(
      'admin_note', p_admin_note
    )
  );

  return jsonb_build_object('ok', true);
end;
$function$
;

CREATE OR REPLACE FUNCTION public.admin_reject_suspended_claim_v1(p_claim_id uuid, p_note text DEFAULT NULL::text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
begin
  if not public.is_admin() then
    return jsonb_build_object('ok', false, 'error', 'not_admin');
  end if;

  update public.suspended_meal_claims
  set status='rejected',
      note = coalesce(note, p_note),
      handled_by=auth.uid(),
      handled_at=now()
  where id = p_claim_id
    and status='pending';

  if not found then
    return jsonb_build_object('ok', false, 'error', 'not_found_or_not_pending');
  end if;

  return jsonb_build_object('ok', true);
end;
$function$
;

create or replace view "public"."admin_reports_queue_v1" as  SELECT id,
    created_at,
    status AS durum,
    reason,
    details,
    user_id,
    business_id,
    review_id,
    handled_by,
    handled_at,
    admin_note
   FROM public.reports r;


CREATE OR REPLACE FUNCTION public.admin_set_business_media_v1(p_business_id uuid, p_field text, p_url text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
begin
  if not public.is_admin() then raise exception 'not_admin'; end if;
  if p_field not in ('logo_url','cover_url') then
    return jsonb_build_object('ok', false, 'error', 'bad_field');
  end if;

  if p_field = 'logo_url' then
    update public.businesses set logo_url = p_url where id = p_business_id;
  else
    update public.businesses set cover_url = p_url where id = p_business_id;
  end if;

  perform public.log_admin_action_v1(
    'business.set_media',
    'businesses',
    p_business_id,
    jsonb_build_object('field', p_field, 'url', p_url)
  );

  return jsonb_build_object('ok', true);
end;
$function$
;

CREATE OR REPLACE FUNCTION public.admin_sla_metrics_v1()
 RETURNS jsonb
 LANGUAGE sql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  select jsonb_build_object(
    'reports_avg_minutes_to_assign',
      (select coalesce(avg(extract(epoch from (assigned_at - created_at))/60),0)
       from public.reports
       where public.is_admin()
         and assigned_at is not null
         and created_at >= now() - interval '30 days'),
    'reports_avg_minutes_to_close',
      (select coalesce(avg(extract(epoch from (handled_at - created_at))/60),0)
       from public.reports
       where public.is_admin()
         and handled_at is not null
         and created_at >= now() - interval '30 days'),

    'claims_avg_minutes_to_assign',
      (select coalesce(avg(extract(epoch from (assigned_at - created_at))/60),0)
       from public.owner_claims
       where public.is_admin()
         and assigned_at is not null
         and created_at >= now() - interval '30 days'),
    'claims_avg_minutes_to_decide',
      (select coalesce(avg(extract(epoch from (handled_at - created_at))/60),0)
       from public.owner_claims
       where public.is_admin()
         and handled_at is not null
         and created_at >= now() - interval '30 days')
  );
$function$
;

create or replace view "public"."admin_suggestions_v1" as  SELECT id,
    name,
    category,
    city,
    district,
    address,
    phone,
    website,
    notes,
    status,
    admin_note,
    created_at,
    reviewed_at,
    user_id
   FROM public.business_suggestions;


CREATE OR REPLACE FUNCTION public.admin_unassign_business_suggestion_v1(p_suggestion_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
begin
  if not public.is_admin() then raise exception 'not_admin'; end if;

  update public.business_suggestions
  set assigned_to = null,
      assigned_at = null
  where id = p_suggestion_id;

  perform public.log_admin_action_v1(
    'suggestion.unassign',
    'business_suggestions',
    p_suggestion_id,
    jsonb_build_object()
  );

  return jsonb_build_object('ok', true);
end;
$function$
;

CREATE OR REPLACE FUNCTION public.admin_unassign_owner_claim_v1(p_claim_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
begin
  if not public.is_admin() then raise exception 'not_admin'; end if;

  update public.owner_claims
  set assigned_to = null,
      assigned_at = null
  where id = p_claim_id;

  perform public.log_admin_action_v1(
    'claim.unassign',
    'owner_claims',
    p_claim_id,
    jsonb_build_object()
  );

  return jsonb_build_object('ok', true);
end;
$function$
;

CREATE OR REPLACE FUNCTION public.admin_unassign_report_v1(p_report_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
begin
  if not public.is_admin() then raise exception 'not_admin'; end if;

  update public.reports
  set assigned_to = null,
      assigned_at = null
  where id = p_report_id;

  perform public.log_admin_action_v1(
    'report.unassign',
    'reports',
    p_report_id,
    jsonb_build_object()
  );

  return jsonb_build_object('ok', true);
end;
$function$
;

CREATE OR REPLACE FUNCTION public.admin_update_business_v1(p_business_id uuid, p_name text, p_category text, p_address text, p_city text, p_district text, p_lat double precision, p_lng double precision, p_logo_url text, p_cover_url text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
begin
  if not public.is_admin() then raise exception 'not_admin'; end if;

  update public.businesses
  set
    name = p_name,
    category = p_category,
    address = p_address,
    city = p_city,
    district = p_district,
    lat = p_lat,
    lng = p_lng,
    logo_url = p_logo_url,
    cover_url = p_cover_url
  where id = p_business_id;

  perform public.log_admin_action_v1(
    'business.update',
    'businesses',
    p_business_id,
    jsonb_build_object('name', p_name, 'city', p_city, 'district', p_district)
  );

  return jsonb_build_object('ok', true);
end;
$function$
;

CREATE OR REPLACE FUNCTION public.approve_business_suggestion(p_suggestion_id uuid)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  v_is_admin boolean;
  v_s public.business_suggestions%rowtype;
  v_business_id uuid;
begin
  -- admin check
  select exists(
    select 1 from public.admin_users au
    where au.user_id = auth.uid()
  )
  into v_is_admin;

  if not v_is_admin then
    raise exception 'not_authorized';
  end if;

  -- lock suggestion row
  select *
  into v_s
  from public.business_suggestions
  where id = p_suggestion_id
  for update;

  if not found then
    raise exception 'suggestion_not_found';
  end if;

  if v_s.status <> 'pending' then
    raise exception 'suggestion_not_pending';
  end if;

  -- insert into businesses (YOUR SCHEMA)
  insert into public.businesses (
    name,
    category,
    description,
    phone,
    address,
    city,
    district,
    lat,
    lng,
    is_active
  )
  values (
    v_s.name,
    v_s.category,
    coalesce(nullif(v_s.notes, ''), null), -- description <- notes
    v_s.phone,
    v_s.address,
    v_s.city,
    v_s.district,
    null, -- lat (öneri tablosunda yoksa NULL)
    null, -- lng
    true
  )
  returning id into v_business_id;

  -- mark suggestion approved + link created business
  update public.business_suggestions
  set
    status = 'approved',
    reviewed_at = now(),
    approved_business_id = v_business_id
  where id = p_suggestion_id;

  return v_business_id;
end;
$function$
;

CREATE OR REPLACE FUNCTION public.approve_owner_claim(p_claim_id uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  v_is_admin boolean;
begin
  select exists(select 1 from public.admin_users where user_id = auth.uid())
  into v_is_admin;

  if not v_is_admin then
    raise exception 'not_authorized';
  end if;

  update public.owner_claims
  set status = 'approved',
      reviewed_at = now()
  where id = p_claim_id;
end;
$function$
;

CREATE OR REPLACE FUNCTION public.auto_approve_trusted_owner_claim_v1(p_claim_id uuid)
 RETURNS boolean
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  v_email text;
  v_url text;
begin
  select
    u.email,
    c.evidence_url
  into v_email, v_url
  from public.owner_claims c
  join auth.users u on u.id = c.user_id
  where c.id = p_claim_id;

  if v_email is null then return false; end if;

  -- basit heuristic: domain email + evidence_url aynı domain
  if v_url is not null and position(split_part(v_email,'@',2) in v_url) > 0 then
    update public.owner_claims
    set
      status = 'approved',
      admin_note = 'Otomatik: domain eşleşmesi (kontrol önerilir)',
      handled_at = now(),
      auto_moderated = true
    where id = p_claim_id;

    perform public.log_admin_action_v1(
      'claim.auto_approve_trusted',
      'owner_claims',
      p_claim_id,
      jsonb_build_object('email', v_email, 'url', v_url)
    );

    return true;
  end if;

  return false;
end;
$function$
;

CREATE OR REPLACE FUNCTION public.bump_food_catalog_popularity_v1(p_id bigint)
 RETURNS jsonb
 LANGUAGE sql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  update public.food_catalog_items
  set popularity = popularity + 1
  where id = p_id;
  select jsonb_build_object('ok', true);
$function$
;

create or replace view "public"."business_item_trends_v1" as  WITH price_votes AS (
         SELECT v.menu_item_id,
            count(*) FILTER (WHERE ((v.vote = 1) AND (v.created_at >= (now() - '7 days'::interval)))) AS price_votes_7d
           FROM public.menu_item_price_votes v
          GROUP BY v.menu_item_id
        ), photo_votes AS (
         SELECT p.menu_item_id,
            count(*) FILTER (WHERE ((v.vote = 1) AND (v.created_at >= (now() - '7 days'::interval)))) AS photo_votes_7d
           FROM (public.menu_item_photo_votes v
             JOIN public.menu_item_photos p ON ((p.id = v.photo_id)))
          GROUP BY p.menu_item_id
        ), price_changes AS (
         SELECT h.menu_item_id,
            count(*) FILTER (WHERE (h.created_at >= (now() - '7 days'::interval))) AS price_changes_7d
           FROM public.menu_item_price_history h
          GROUP BY h.menu_item_id
        )
 SELECT mi.id AS menu_item_id,
    mi.business_id,
    COALESCE(pv.price_votes_7d, (0)::bigint) AS price_votes_7d,
    COALESCE(phv.photo_votes_7d, (0)::bigint) AS photo_votes_7d,
    0 AS menu_item_views_7d,
    COALESCE(pc.price_changes_7d, (0)::bigint) AS price_changes_7d,
    ((((COALESCE(pv.price_votes_7d, (0)::bigint) * 3) + (COALESCE(phv.photo_votes_7d, (0)::bigint) * 2)) + COALESCE(pc.price_changes_7d, (0)::bigint)))::integer AS score
   FROM (((public.menu_items mi
     LEFT JOIN price_votes pv ON ((pv.menu_item_id = mi.id)))
     LEFT JOIN photo_votes phv ON ((phv.menu_item_id = mi.id)))
     LEFT JOIN price_changes pc ON ((pc.menu_item_id = mi.id)));


create or replace view "public"."business_rating_summary" as  SELECT business_id,
    (count(*))::integer AS rating_count,
    round(avg((COALESCE(overall_rating, (rating)::smallint))::numeric), 2) AS avg_overall_rating,
    round(avg((taste_rating)::numeric), 2) AS avg_taste_rating,
    round(avg((service_speed_rating)::numeric), 2) AS avg_service_speed_rating,
    round(avg((price_performance_rating)::numeric), 2) AS avg_price_performance_rating,
    round(avg((cleanliness_rating)::numeric), 2) AS avg_cleanliness_rating,
    round(avg((atmosphere_rating)::numeric), 2) AS avg_atmosphere_rating
   FROM public.reviews r
  WHERE (status = 'approved'::text)
  GROUP BY business_id;


create or replace view "public"."businesses_with_stats" as  SELECT b.id,
    b.name,
    b.category,
    b.description,
    b.phone,
    b.address,
    b.city,
    b.district,
    b.lat,
    b.lng,
    b.is_active,
    b.created_at,
    COALESCE(r.reviews_count, 0) AS reviews_count,
    (COALESCE(r.avg_rating, (0)::numeric))::numeric(3,2) AS avg_rating
   FROM (public.businesses b
     LEFT JOIN ( SELECT reviews.business_id,
            (count(*) FILTER (WHERE (reviews.status = 'approved'::text)))::integer AS reviews_count,
            avg(reviews.rating) FILTER (WHERE (reviews.status = 'approved'::text)) AS avg_rating
           FROM public.reviews
          GROUP BY reviews.business_id) r ON ((r.business_id = b.id)));


create or replace view "public"."businesses_with_stats_mv" as  SELECT b.id,
    b.name,
    b.category,
    b.address,
    b.city,
    b.district,
    b.lat,
    b.lng,
    b.geog,
    COALESCE(s.approved_reviews_count, 0) AS reviews_count,
        CASE
            WHEN (COALESCE(s.approved_reviews_count, 0) = 0) THEN (0)::double precision
            ELSE ((s.approved_rating_sum)::double precision / (s.approved_reviews_count)::double precision)
        END AS avg_rating,
    s.last_review_at
   FROM (public.businesses b
     LEFT JOIN public.business_stats s ON ((s.business_id = b.id)));


CREATE OR REPLACE FUNCTION public.consume_rate_limit_v1(p_action text, p_daily_limit integer DEFAULT 10)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  v_day date := (now() at time zone 'utc')::date;
  v_key text := p_action || ':' || auth.uid()::text || ':' || v_day::text;
  v_row public.user_rate_limits%rowtype;
begin
  if auth.uid() is null then
    return jsonb_build_object('ok', false, 'error', 'not_authenticated');
  end if;

  select * into v_row from public.user_rate_limits where key = v_key;

  if v_row.key is null then
    insert into public.user_rate_limits(key, user_id, action, day, count)
    values (v_key, auth.uid(), p_action, v_day, 1);
    return jsonb_build_object('ok', true, 'remaining', p_daily_limit - 1);
  end if;

  if v_row.count >= p_daily_limit then
    return jsonb_build_object('ok', false, 'error', 'rate_limited', 'remaining', 0);
  end if;

  update public.user_rate_limits
  set count = count + 1, updated_at = now()
  where key = v_key;

  return jsonb_build_object('ok', true, 'remaining', p_daily_limit - (v_row.count + 1));
end;
$function$
;

CREATE OR REPLACE FUNCTION public.create_owner_claim(p_business_id uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
begin
  -- zaten varsa tekrar ekleme
  if exists (
    select 1 from public.owner_claims
    where business_id = p_business_id
      and user_id = auth.uid()
  ) then
    return;
  end if;

  insert into public.owner_claims (business_id, user_id)
  values (p_business_id, auth.uid());
end;
$function$
;

CREATE OR REPLACE FUNCTION public.create_suspended_meal_v1(p_business_id uuid, p_amount_cents integer, p_currency text DEFAULT 'TRY'::text, p_message text DEFAULT NULL::text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
begin
  if auth.uid() is null then
    return jsonb_build_object('ok', false, 'error', 'not_authenticated');
  end if;

  if p_amount_cents < 1000 then
    return jsonb_build_object('ok', false, 'error', 'min_amount');
  end if;

  insert into public.suspended_meals(
    business_id, donor_user_id, amount_cents, currency, message, provider
  )
  values (p_business_id, auth.uid(), p_amount_cents, p_currency, p_message, 'mock');

  return jsonb_build_object('ok', true);
end;
$function$
;

CREATE OR REPLACE FUNCTION public.delete_business_story_v1(p_story_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  v_business uuid;
begin
  select business_id into v_business
  from public.business_stories
  where id = p_story_id;

  if v_business is null then
    return jsonb_build_object('ok', false, 'error', 'not_found');
  end if;

  if not (public.is_admin() or public.is_owner_of_business(v_business)) then
    return jsonb_build_object('ok', false, 'error', 'not_owner');
  end if;

  update public.business_stories
  set is_deleted = true
  where id = p_story_id;

  return jsonb_build_object('ok', true);
end;
$function$
;

CREATE OR REPLACE FUNCTION public.discover_gourmets_v1(p_limit integer DEFAULT 20, p_offset integer DEFAULT 0)
 RETURNS TABLE(user_id uuid, display_name text, avatar_url text, bio text, follower_count integer)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  select
    p.user_id, p.display_name, p.avatar_url, p.bio,
    (select count(*) from public.user_follows f where f.followee_id = p.user_id)::int as follower_count
  from public.user_profiles p
  where p.is_gourmet = true
  order by follower_count desc, p.created_at desc
  limit greatest(p_limit,0) offset greatest(p_offset,0);
$function$
;

CREATE OR REPLACE FUNCTION public.ensure_my_profile_v1(p_display_name text DEFAULT NULL::text, p_avatar_url text DEFAULT NULL::text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  v_name text;
begin
  if auth.uid() is null then
    return jsonb_build_object('ok', false, 'error', 'not_authenticated');
  end if;

  v_name := nullif(trim(coalesce(p_display_name,'')), '');
  if v_name is null then
    v_name := 'Kullanıcı';
  end if;

  insert into public.user_profiles(user_id, display_name, avatar_url)
  values (auth.uid(), v_name, p_avatar_url)
  on conflict (user_id) do update
    set display_name = coalesce(excluded.display_name, public.user_profiles.display_name),
        avatar_url = coalesce(excluded.avatar_url, public.user_profiles.avatar_url),
        updated_at = now();

  return jsonb_build_object('ok', true);
end;
$function$
;

create or replace view "public"."expired_temp_uploads_v1" as  SELECT id,
    business_id,
    user_id,
    kind,
    storage_bucket,
    storage_path,
    mime_type,
    bytes,
    width,
    height,
    sha1,
    phash,
    duplicate_candidate,
    status,
    created_at,
    expires_at,
    reviewed_by,
    reviewed_at,
    review_note
   FROM public.temp_uploads t
  WHERE ((status = ANY (ARRAY['pending'::text, 'rejected'::text])) AND (expires_at < now()));


DO $$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'geometry_dump' AND typnamespace = 'public'::regnamespace) THEN CREATE TYPE "public"."geometry_dump" AS ("path" integer[], "geom" public.geometry); END IF; END $$;

CREATE OR REPLACE FUNCTION public.get_business_crowd_v1(p_business_id uuid)
 RETURNS jsonb
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  with last_hour as (
    select
      crowd,
      case crowd
        when 'quiet' then 1
        when 'normal' then 2
        when 'busy' then 3
      end as score
    from public.business_presence_events
    where business_id = p_business_id
      and created_at >= now() - interval '60 minutes'
  ),
  agg as (
    select
      count(*) as n,
      avg(score)::float as avg_score
    from last_hour
  )
  select jsonb_build_object(
    'count_60m', coalesce((select n from agg),0),
    'avg_score', coalesce((select avg_score from agg), null),
    'level',
      case
        when coalesce((select n from agg),0) = 0 then 'unknown'
        when (select avg_score from agg) < 1.6 then 'quiet'
        when (select avg_score from agg) < 2.4 then 'normal'
        else 'busy'
      end
  );
$function$
;

CREATE OR REPLACE FUNCTION public.get_business_detail_v1(p_business_id uuid, p_latest_reviews_limit integer DEFAULT 5)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  v_stats jsonb;
  v_hist jsonb;
  v_latest jsonb;
begin
  select to_jsonb(s)
  into v_stats
  from (
    select
      m.id,
      m.name,
      m.category,
      m.address,
      m.city,
      m.district,
      m.lat,
      m.lng,
      m.avg_rating,
      m.reviews_count
    from public.businesses_with_stats_mv m
    where m.id = p_business_id
    limit 1
  ) s;

  if v_stats is null then
    return jsonb_build_object('ok', false, 'error', 'business_not_found');
  end if;

  -- breakdown stats'tan
  select jsonb_build_object(
    '5', coalesce(bs.rating_5,0),
    '4', coalesce(bs.rating_4,0),
    '3', coalesce(bs.rating_3,0),
    '2', coalesce(bs.rating_2,0),
    '1', coalesce(bs.rating_1,0)
  )
  into v_hist
  from public.business_stats bs
  where bs.business_id = p_business_id;

  if v_hist is null then
    v_hist := jsonb_build_object('5',0,'4',0,'3',0,'2',0,'1',0);
  end if;

  -- latest reviews yine reviews'tan (limitli + index ile hızlı)
  select coalesce(jsonb_agg(to_jsonb(r)), '[]'::jsonb)
  into v_latest
  from (
    select
      id,
      business_id,
      user_id,
      rating,
      title,
      content,
      helpful_count,
      created_at
    from public.reviews
    where business_id = p_business_id
      and status = 'approved'
    order by created_at desc
    limit greatest(p_latest_reviews_limit, 0)
  ) r;

  return jsonb_build_object(
    'ok', true,
    'stats', v_stats,
    'rating_breakdown', v_hist,
    'latest_reviews', v_latest
  );
end;
$function$
;

CREATE OR REPLACE FUNCTION public.get_business_menus_v1(p_business_id uuid)
 RETURNS TABLE(id uuid, title text, kind text, active_from time without time zone, active_to time without time zone, status public.menu_status)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  select m.id, m.title, m.kind, m.active_from, m.active_to, m.status
  from public.menus m
  where m.business_id = p_business_id
    and (m.status='published' or public.is_admin() or public.is_owner_of_business(p_business_id))
  order by m.created_at desc;
$function$
;

CREATE OR REPLACE FUNCTION public.get_business_price_trust_v1(p_business_id uuid)
 RETURNS jsonb
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  with items as (
    select mi.id
    from public.menu_items mi
    where mi.business_id = p_business_id and mi.status='published'
  ),
  agg as (
    select
      count(*)::int as total_items,
      count(*) filter (where ps.price_status='verified')::int as verified_items
    from items i
    left join public.menu_item_price_status_v1 ps on ps.menu_item_id = i.id
  )
  select jsonb_build_object(
    'total_items', (select total_items from agg),
    'verified_items', (select verified_items from agg),
    'verified_ratio',
      case when (select total_items from agg) = 0 then null
           else (select verified_items from agg)::float / (select total_items from agg)::float end
  );
$function$
;

CREATE OR REPLACE FUNCTION public.get_business_stories_v1(p_business_id uuid, p_limit integer DEFAULT 10)
 RETURNS TABLE(id uuid, type public.story_type, caption text, media_url text, media_thumb_url text, media_type text, created_at timestamp with time zone, expires_at timestamp with time zone)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  select
    s.id, s.type, s.caption, s.media_url, s.media_thumb_url, s.media_type, s.created_at, s.expires_at
  from public.business_stories s
  where s.business_id = p_business_id
    and s.is_deleted = false
    and s.expires_at > now()
  order by s.created_at desc
  limit greatest(p_limit,0);
$function$
;

CREATE OR REPLACE FUNCTION public.get_city_districts_v1()
 RETURNS TABLE(city text, district text, count integer)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  select
    city,
    district,
    count(*)::int as count
  from public.businesses
  where is_active = true
    and city is not null
    and district is not null
  group by city, district
  order by city asc, district asc;
$function$
;

CREATE OR REPLACE FUNCTION public.get_daily_picks(p_limit integer DEFAULT 3)
 RETURNS TABLE(business_id uuid, name text, category text, city text, district text, avg_rating numeric, reviews_count integer)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  with base as (
    select
      b.id as business_id,
      b.name,
      b.category,
      b.city,
      b.district,
      count(r.*)::int as reviews_count,
      coalesce(avg(r.rating), 0)::numeric(3,2) as avg_rating
    from public.businesses b
    left join public.reviews r
      on r.business_id = b.id
     and r.status = 'approved'
     and r.created_at >= (now() - interval '30 days')
    where b.is_active = true
    group by b.id
  ),
  scored as (
    select
      *,
      (
        -- rating ağırlığı
        (avg_rating * 10)
        +
        -- yorum sayısı ağırlığı
        (least(reviews_count, 20) * 1.0)
        +
        -- günlük stabil random: user+date ile
        (
          -- auth yoksa da çalışsın: uid null ise 'anon' kullan
          (abs(hashtext(coalesce(auth.uid()::text, 'anon') || ':' || current_date::text || ':' || business_id::text)) % 1000) / 1000.0
        )
      ) as score
    from base
  )
  select
    business_id, name, category, city, district, avg_rating, reviews_count
  from scored
  order by score desc
  limit p_limit;
$function$
;

CREATE OR REPLACE FUNCTION public.get_heroes_v1(p_limit integer DEFAULT 20)
 RETURNS TABLE(user_id uuid, donated_count integer, donated_amount_cents integer)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  select
    donor_user_id as user_id,
    count(*)::int as donated_count,
    sum(amount_cents)::int as donated_amount_cents
  from public.suspended_meals
  where status in ('active','claimed')
  group by donor_user_id
  order by donated_amount_cents desc
  limit greatest(p_limit,0);
$function$
;

CREATE OR REPLACE FUNCTION public.get_menu_item_price_history_v1(p_menu_item_id uuid, p_limit integer DEFAULT 10)
 RETURNS TABLE(new_price_cents integer, old_price_cents integer, currency text, source text, created_at timestamp with time zone)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  select
    coalesce(h.new_price_cents, h.price_cents) as new_price_cents,
    h.old_price_cents,
    h.currency,
    h.source,
    h.created_at
  from public.menu_item_price_history h
  where h.menu_item_id = p_menu_item_id
  order by h.created_at desc
  limit greatest(p_limit,0);
$function$
;

CREATE OR REPLACE FUNCTION public.get_menu_items_price_age_v1(p_item_ids uuid[])
 RETURNS TABLE(menu_item_id uuid, last_price_at timestamp with time zone)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  select
    h.menu_item_id,
    max(h.created_at) as last_price_at
  from public.menu_item_price_history h
  where h.menu_item_id = any(p_item_ids)
  group by h.menu_item_id;
$function$
;

CREATE OR REPLACE FUNCTION public.get_menu_sections_v1(p_menu_id uuid)
 RETURNS TABLE(id uuid, title text, sort_order integer)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  select id, title, sort_order
  from public.menu_sections
  where menu_id = p_menu_id
  order by sort_order asc, created_at asc;
$function$
;

CREATE OR REPLACE FUNCTION public.get_my_diet_profile_v1()
 RETURNS jsonb
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  select coalesce(to_jsonb(p.*), '{}'::jsonb)
  from public.user_diet_profiles p
  where p.user_id = auth.uid();
$function$
;

CREATE OR REPLACE FUNCTION public.get_my_favorites_v1(p_limit integer DEFAULT 50, p_offset integer DEFAULT 0)
 RETURNS TABLE(business_id uuid, favorited_at timestamp with time zone)
 LANGUAGE sql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  select
    f.business_id,
    f.created_at as favorited_at
  from public.favorites f
  where f.user_id = auth.uid()
  order by f.created_at desc
  limit greatest(p_limit, 0)
  offset greatest(p_offset, 0);
$function$
;

CREATE OR REPLACE FUNCTION public.get_my_following_v1(p_limit integer DEFAULT 50, p_offset integer DEFAULT 0)
 RETURNS TABLE(user_id uuid, display_name text, avatar_url text, bio text, is_gourmet boolean, followed_at timestamp with time zone)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  select
    p.user_id, p.display_name, p.avatar_url, p.bio, p.is_gourmet,
    f.created_at as followed_at
  from public.user_follows f
  join public.user_profiles p on p.user_id = f.followee_id
  where f.follower_id = auth.uid()
  order by f.created_at desc
  limit greatest(p_limit,0) offset greatest(p_offset,0);
$function$
;

CREATE OR REPLACE FUNCTION public.get_my_profile_stats()
 RETURNS TABLE(reviews_count integer, helpful_received integer, favorites_count integer, visits_count integer, contribution_score integer)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  with my_reviews as (
    select id, helpful_count
    from public.reviews
    where user_id = auth.uid()
  )
  select
    (select count(*)::int from my_reviews) as reviews_count,
    (select coalesce(sum(helpful_count), 0)::int from my_reviews) as helpful_received,
    (select count(*)::int from public.favorites where user_id = auth.uid()) as favorites_count,
    (select count(*)::int from public.visits where user_id = auth.uid()) as visits_count,
    (
      (select count(*)::int from my_reviews) * 5
      +
      (select coalesce(sum(helpful_count), 0)::int from my_reviews) * 2
      +
      (select count(*)::int from public.favorites where user_id = auth.uid())
      +
      (select count(*)::int from public.visits where user_id = auth.uid()) * 1
    ) as contribution_score;
$function$
;

CREATE OR REPLACE FUNCTION public.get_my_suspended_claim_badge_v1()
 RETURNS jsonb
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  select jsonb_build_object(
    'approved_count',
    (select count(*) from public.suspended_meal_claims
     where claimant_user_id = auth.uid() and status='approved')::int,
    'pending_count',
    (select count(*) from public.suspended_meal_claims
     where claimant_user_id = auth.uid() and status='pending')::int
  );
$function$
;

CREATE OR REPLACE FUNCTION public.get_my_suspended_claims_v1(p_status text DEFAULT NULL::text, p_limit integer DEFAULT 30, p_offset integer DEFAULT 0)
 RETURNS TABLE(claim_id uuid, claim_status text, created_at timestamp with time zone, handled_at timestamp with time zone, fulfilled_at timestamp with time zone, business_id uuid, business_name text, city text, district text, amount_cents integer, currency text, verify_code text)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  select
    c.id as claim_id,
    c.status::text as claim_status,
    c.created_at,
    c.handled_at,
    c.fulfilled_at,

    b.id as business_id,
    b.name as business_name,
    b.city,
    b.district,

    m.amount_cents,
    m.currency,

    case when c.status='approved' then c.verify_code else null end as verify_code
  from public.suspended_meal_claims c
  join public.suspended_meals m on m.id = c.suspended_meal_id
  join public.businesses b on b.id = m.business_id
  where c.claimant_user_id = auth.uid()
    and (p_status is null or c.status::text = p_status)
  order by c.created_at desc
  limit greatest(p_limit,0) offset greatest(p_offset,0);
$function$
;

CREATE OR REPLACE FUNCTION public.get_my_weekly_missions()
 RETURNS TABLE(week_start date, reviews_done integer, visits_done integer, votes_done integer, reviews_goal integer, visits_goal integer, votes_goal integer, completed_count integer)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  with w as (
    select date_trunc('week', now())::date as week_start
  ),
  reviews as (
    select count(*)::int as c
    from public.reviews r, w
    where r.user_id = auth.uid()
      and r.created_at >= w.week_start
  ),
  visits as (
    select count(*)::int as c
    from public.visits v, w
    where v.user_id = auth.uid()
      and v.created_at >= w.week_start
  ),
  votes as (
    select count(*)::int as c
    from public.review_votes rv, w
    where rv.user_id = auth.uid()
      and rv.created_at >= w.week_start
  )
  select
    (select week_start from w) as week_start,
    (select c from reviews) as reviews_done,
    (select c from visits) as visits_done,
    (select c from votes) as votes_done,
    1 as reviews_goal,
    3 as visits_goal,
    3 as votes_goal,
    (
      (case when (select c from reviews) >= 1 then 1 else 0 end) +
      (case when (select c from visits) >= 3 then 1 else 0 end) +
      (case when (select c from votes) >= 3 then 1 else 0 end)
    )::int as completed_count;
$function$
;

CREATE OR REPLACE FUNCTION public.get_signal_overlap_examples_v1(p_other_user_id uuid, p_limit integer DEFAULT 5)
 RETURNS TABLE(business_id uuid, business_name text, my_signal double precision, other_signal double precision)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  with my as (
    select business_id, signal_score
    from public.user_business_signals_v1
    where user_id = auth.uid()
  ),
  oth as (
    select business_id, signal_score
    from public.user_business_signals_v1
    where user_id = p_other_user_id
  )
  select
    b.id as business_id,
    b.name as business_name,
    my.signal_score as my_signal,
    oth.signal_score as other_signal
  from my
  join oth on oth.business_id = my.business_id
  join public.businesses b on b.id = my.business_id
  order by (my.signal_score + oth.signal_score) desc
  limit greatest(p_limit,0);
$function$
;

CREATE OR REPLACE FUNCTION public.get_taste_divergence_examples_v1(p_other_user_id uuid, p_limit integer DEFAULT 3)
 RETURNS TABLE(business_id uuid, business_name text, my_rating integer, other_rating integer, diff integer)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  with my as (
    select business_id, rating
    from public.reviews
    where user_id = auth.uid()
      and status='approved'
  ),
  oth as (
    select business_id, rating
    from public.reviews
    where user_id = p_other_user_id
      and status='approved'
  )
  select
    b.id as business_id,
    b.name as business_name,
    my.rating as my_rating,
    oth.rating as other_rating,
    abs(my.rating - oth.rating) as diff
  from my
  join oth on oth.business_id = my.business_id
  join public.businesses b on b.id = my.business_id
  order by diff desc
  limit greatest(p_limit,0);
$function$
;

CREATE OR REPLACE FUNCTION public.get_taste_matches_hybrid_v1(p_limit integer DEFAULT 10, p_min_overlap integer DEFAULT 5)
 RETURNS TABLE(user_id uuid, similarity double precision, overlap integer, review_similarity double precision, signal_similarity double precision)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  with my_r as (
    select business_id, (rating - 3)::float as r
    from public.reviews
    where user_id = auth.uid() and status='approved'
    order by created_at desc
    limit 200
  ),
  oth_r as (
    select user_id, business_id, (rating - 3)::float as r
    from public.reviews
    where user_id <> auth.uid() and status='approved'
  ),
  review_join as (
    select
      o.user_id,
      count(*) as overlap,
      sum(m.r * o.r) as dot,
      sqrt(sum(m.r*m.r)) as norm_my,
      sqrt(sum(o.r*o.r)) as norm_oth
    from my_r m
    join oth_r o on o.business_id = m.business_id
    group by o.user_id
  ),
  review_sim as (
    select
      user_id,
      overlap,
      case when norm_my=0 or norm_oth=0 then 0 else dot/(norm_my*norm_oth) end as review_similarity
    from review_join
    where overlap >= p_min_overlap
  ),

  my_s as (
    select business_id, signal_score as s
    from public.user_business_signals_v1
    where user_id = auth.uid()
    order by signal_score desc
    limit 300
  ),
  oth_s as (
    select user_id, business_id, signal_score as s
    from public.user_business_signals_v1
    where user_id <> auth.uid()
  ),
  signal_join as (
    select
      o.user_id,
      sum(m.s * o.s) as dot,
      sqrt(sum(m.s*m.s)) as norm_my,
      sqrt(sum(o.s*o.s)) as norm_oth
    from my_s m
    join oth_s o on o.business_id = m.business_id
    group by o.user_id
  ),
  signal_sim as (
    select
      user_id,
      case when norm_my=0 or norm_oth=0 then 0 else dot/(norm_my*norm_oth) end as signal_similarity
    from signal_join
  )

  select
    r.user_id,
    (0.75*r.review_similarity + 0.25*coalesce(s.signal_similarity,0)) as similarity,
    r.overlap,
    r.review_similarity,
    coalesce(s.signal_similarity,0) as signal_similarity
  from review_sim r
  left join signal_sim s on s.user_id = r.user_id
  order by similarity desc, overlap desc
  limit greatest(p_limit,0);
$function$
;

CREATE OR REPLACE FUNCTION public.get_taste_matches_v1(p_limit integer DEFAULT 10, p_min_overlap integer DEFAULT 5)
 RETURNS TABLE(user_id uuid, similarity double precision, overlap integer)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  with my as (
    select business_id, (rating - 3)::float as r
    from public.reviews
    where user_id = auth.uid()
      and status = 'approved'
    order by created_at desc
    limit 200
  ),
  others as (
    select user_id, business_id, (rating - 3)::float as r
    from public.reviews
    where user_id <> auth.uid()
      and status = 'approved'
  ),
  joined as (
    select o.user_id,
           count(*) as overlap,
           sum(m.r * o.r) as dot,
           sqrt(sum(m.r*m.r)) as norm_my,
           sqrt(sum(o.r*o.r)) as norm_other
    from my m
    join others o on o.business_id = m.business_id
    group by o.user_id
  )
  select
    user_id,
    case when norm_my = 0 or norm_other = 0 then 0 else (dot / (norm_my * norm_other)) end as similarity,
    overlap
  from joined
  where overlap >= p_min_overlap
  order by similarity desc, overlap desc
  limit greatest(p_limit,0);
$function$
;

CREATE OR REPLACE FUNCTION public.get_taste_overlap_examples_v1(p_other_user_id uuid, p_limit integer DEFAULT 5)
 RETURNS TABLE(business_id uuid, business_name text, my_rating integer, other_rating integer, created_at_my timestamp with time zone, created_at_other timestamp with time zone, score double precision)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  with my as (
    select business_id, rating, created_at
    from public.reviews
    where user_id = auth.uid()
      and status='approved'
  ),
  oth as (
    select business_id, rating, created_at
    from public.reviews
    where user_id = p_other_user_id
      and status='approved'
  ),
  joined as (
    select
      b.id as business_id,
      b.name as business_name,
      my.rating as my_rating,
      oth.rating as other_rating,
      my.created_at as created_at_my,
      oth.created_at as created_at_other,
      ((my.rating - 3)::float * (oth.rating - 3)::float) as score
    from my
    join oth on oth.business_id = my.business_id
    join public.businesses b on b.id = my.business_id
  )
  select *
  from joined
  order by score desc, greatest(created_at_my, created_at_other) desc
  limit greatest(p_limit,0);
$function$
;

CREATE OR REPLACE FUNCTION public.get_top_businesses(p_period text DEFAULT 'week'::text, p_limit integer DEFAULT 10, p_min_reviews integer DEFAULT 2)
 RETURNS TABLE(business_id uuid, name text, category text, city text, district text, avg_rating numeric, reviews_count integer)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  with period_reviews as (
    select
      r.business_id,
      r.rating
    from public.reviews r
    where r.status = 'approved'
      and r.created_at >= case
        when p_period = 'month' then (now() - interval '30 days')
        else (now() - interval '7 days')
      end
  ),
  agg as (
    select
      business_id,
      count(*)::int as reviews_count,
      avg(rating) as avg_rating
    from period_reviews
    group by business_id
    having count(*) >= p_min_reviews
  )
  select
    b.id as business_id,
    b.name,
    b.category,
    b.city,
    b.district,
    coalesce(a.avg_rating, 0)::numeric(3,2) as avg_rating,
    coalesce(a.reviews_count, 0)::int as reviews_count
  from agg a
  join public.businesses b on b.id = a.business_id
  where b.is_active = true
  order by a.avg_rating desc, a.reviews_count desc
  limit p_limit;
$function$
;

CREATE OR REPLACE FUNCTION public.get_top_businesses_period_v1(p_period text, p_limit integer DEFAULT 6, p_min_reviews integer DEFAULT 2)
 RETURNS TABLE(id uuid, name text, category text, city text, district text, avg_rating double precision, reviews_count integer, score double precision)
 LANGUAGE sql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  with bounds as (
    select
      case
        when p_period='week' then now() - interval '7 days'
        when p_period='month' then now() - interval '30 days'
        else now() - interval '7 days'
      end as since_at
  ),
  agg as (
    select
      r.business_id as id,
      count(*)::int as reviews_count,
      avg(r.rating)::double precision as avg_rating
    from public.reviews r, bounds b
    where r.status='approved'
      and r.created_at >= b.since_at
    group by r.business_id
    having count(*) >= p_min_reviews
  )
  select
    b.id,
    b.name,
    b.category,
    b.city,
    b.district,
    a.avg_rating,
    a.reviews_count,
    -- Basit skor: rating * log(1+count)
    (a.avg_rating * ln(1 + a.reviews_count))::double precision as score
  from agg a
  join public.businesses b on b.id = a.id
  order by score desc
  limit greatest(p_limit, 0);
$function$
;

CREATE OR REPLACE FUNCTION public.get_user_public_profile_v1(p_user_id uuid)
 RETURNS jsonb
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  select jsonb_build_object(
    'user_id', p.user_id,
    'display_name', p.display_name,
    'avatar_url', p.avatar_url,
    'bio', p.bio,
    'is_gourmet', p.is_gourmet
  )
  from public.user_profiles p
  where p.user_id = p_user_id;
$function$
;

CREATE OR REPLACE FUNCTION public.is_admin()
 RETURNS boolean
 LANGUAGE sql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  select exists(
    select 1
    from public.admin_users au
    where au.user_id = auth.uid()
  );
$function$
;

CREATE OR REPLACE FUNCTION public.list_active_suspended_meals_v1(p_business_id uuid, p_limit integer DEFAULT 20)
 RETURNS TABLE(id uuid, amount_cents integer, currency text, message text, created_at timestamp with time zone, expires_at timestamp with time zone)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  select id, amount_cents, currency, message, created_at, expires_at
  from public.suspended_meals
  where business_id = p_business_id
    and status='active'
    and expires_at > now()
  order by created_at desc
  limit greatest(p_limit,0);
$function$
;

create or replace view "public"."menu_item_price_status_v1" as  WITH last30 AS (
         SELECT menu_item_price_votes.menu_item_id,
            (sum(
                CASE
                    WHEN (menu_item_price_votes.vote = 1) THEN 1
                    ELSE 0
                END))::integer AS up_30d,
            (sum(
                CASE
                    WHEN (menu_item_price_votes.vote = '-1'::integer) THEN 1
                    ELSE 0
                END))::integer AS down_30d,
            (count(*))::integer AS total_30d
           FROM public.menu_item_price_votes
          WHERE (menu_item_price_votes.created_at >= (now() - '30 days'::interval))
          GROUP BY menu_item_price_votes.menu_item_id
        )
 SELECT mi.id AS menu_item_id,
    mi.business_id,
    COALESCE(l.up_30d, 0) AS up_30d,
    COALESCE(l.down_30d, 0) AS down_30d,
    COALESCE(l.total_30d, 0) AS total_30d,
        CASE
            WHEN (COALESCE(l.total_30d, 0) < 3) THEN 'unverified'::text
            WHEN (((l.up_30d)::double precision / (NULLIF(l.total_30d, 0))::double precision) >= (0.7)::double precision) THEN 'verified'::text
            WHEN (((l.down_30d)::double precision / (NULLIF(l.total_30d, 0))::double precision) >= (0.6)::double precision) THEN 'stale'::text
            ELSE 'unverified'::text
        END AS price_status
   FROM (public.menu_items mi
     LEFT JOIN last30 l ON ((l.menu_item_id = mi.id)))
  WHERE (mi.is_available = true);


create or replace view "public"."menu_item_value_score_v1" as  WITH votes_all AS (
         SELECT v.menu_item_id,
            count(*) FILTER (WHERE (v.vote = 1)) AS pos_votes,
            count(*) AS total_votes
           FROM public.menu_item_price_votes v
          GROUP BY v.menu_item_id
        ), votes_30d AS (
         SELECT v.menu_item_id,
            count(*) FILTER (WHERE ((v.vote = 1) AND (v.created_at >= (now() - '30 days'::interval)))) AS pos_votes_30d,
            count(*) FILTER (WHERE (v.created_at >= (now() - '30 days'::interval))) AS total_votes_30d
           FROM public.menu_item_price_votes v
          GROUP BY v.menu_item_id
        ), price_changes_30d AS (
         SELECT h.menu_item_id,
            count(*) FILTER (WHERE (h.created_at >= (now() - '30 days'::interval))) AS changes_30d
           FROM public.menu_item_price_history h
          GROUP BY h.menu_item_id
        )
 SELECT mi.id AS menu_item_id,
    COALESCE(((va.pos_votes)::double precision / (NULLIF(va.total_votes, 0))::double precision), (0)::double precision) AS verified_ratio,
    COALESCE(((v30.pos_votes_30d)::double precision / (NULLIF(v30.total_votes_30d, 0))::double precision), (0)::double precision) AS recent_positive_ratio,
    (((1)::numeric - LEAST(((COALESCE(pc.changes_30d, (0)::bigint))::numeric / 5.0), 1.0)))::double precision AS price_stability,
    COALESCE(pc.changes_30d, (0)::bigint) AS price_changes_30d,
    (((COALESCE(((va.pos_votes)::double precision / (NULLIF(va.total_votes, 0))::double precision), (0)::double precision) * (0.4)::double precision) + (COALESCE(((v30.pos_votes_30d)::double precision / (NULLIF(v30.total_votes_30d, 0))::double precision), (0)::double precision) * (0.3)::double precision)) + ((((1)::numeric - LEAST(((COALESCE(pc.changes_30d, (0)::bigint))::numeric / 5.0), 1.0)) * 0.3))::double precision) AS value_score
   FROM (((public.menu_items mi
     LEFT JOIN votes_all va ON ((va.menu_item_id = mi.id)))
     LEFT JOIN votes_30d v30 ON ((v30.menu_item_id = mi.id)))
     LEFT JOIN price_changes_30d pc ON ((pc.menu_item_id = mi.id)));


CREATE OR REPLACE FUNCTION public.normalize_tr_text(p text)
 RETURNS text
 LANGUAGE sql
 IMMUTABLE
 SET search_path TO 'public'
AS $function$
  select trim(
    regexp_replace(
      regexp_replace(
        translate(lower(coalesce(p,'')),
          'çğıöşüİÇĞÖŞÜ',
          'cgiosuicgiosu'
        ),
        '[^a-z0-9]+', ' ', 'g'
      ),
      '\s+', ' ', 'g'
    )
  );
$function$
;

CREATE OR REPLACE FUNCTION public.owner_approve_menu_price_suggestion_v1(p_suggestion_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  v_item_id uuid;
  v_business_id uuid;
  v_new int;
  v_old int;
  v_cur text;
begin
  if auth.uid() is null then
    return jsonb_build_object('ok', false, 'error', 'not_authenticated');
  end if;

  select s.menu_item_id, s.business_id, s.suggested_price_cents, s.currency
  into v_item_id, v_business_id, v_new, v_cur
  from public.menu_item_price_suggestions s
  where s.id = p_suggestion_id and s.status='pending';

  if v_item_id is null then
    return jsonb_build_object('ok', false, 'error', 'not_found_or_not_pending');
  end if;

  if not public.is_owner_of_business(v_business_id) and not public.is_admin() then
    return jsonb_build_object('ok', false, 'error', 'not_owner');
  end if;

  select price_cents into v_old
  from public.menu_items
  where id = v_item_id;

  update public.menu_items
  set price_cents = v_new,
      currency = v_cur,
      updated_at = now()
  where id = v_item_id;

  update public.menu_item_price_suggestions
  set status='approved',
      handled_by=auth.uid(),
      handled_at=now()
  where id = p_suggestion_id;

  insert into public.menu_item_price_history(
    menu_item_id, price_cents, currency, source, created_by
  )
  values (
    v_item_id, v_new, v_cur, 'owner', auth.uid()
  );

  return jsonb_build_object('ok', true, 'old_price_cents', v_old, 'new_price_cents', v_new);
end;
$function$
;

CREATE OR REPLACE FUNCTION public.owner_approve_suspended_claim_v1(p_claim_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  v_meal_id uuid;
  v_business_id uuid;
  v_meal_status public.suspended_meal_status;
  v_code text;
begin
  if auth.uid() is null then
    return jsonb_build_object('ok', false, 'error', 'not_authenticated');
  end if;

  select m.id, m.business_id into v_meal_id, v_business_id
  from public.suspended_meal_claims c
  join public.suspended_meals m on m.id = c.suspended_meal_id
  where c.id = p_claim_id and c.status='pending';

  if v_meal_id is null then
    return jsonb_build_object('ok', false, 'error', 'not_found_or_not_pending');
  end if;

  if not public.is_owner_of_business(v_business_id) and not public.is_admin() then
    return jsonb_build_object('ok', false, 'error', 'not_owner');
  end if;

  select status into v_meal_status
  from public.suspended_meals
  where id = v_meal_id;

  if v_meal_status <> 'active' then
    return jsonb_build_object('ok', false, 'error', 'meal_not_active');
  end if;

  -- 6 haneli code
  v_code := lpad((floor(random()*1000000))::int::text, 6, '0');

  update public.suspended_meal_claims
  set status='approved',
      verify_code=v_code,
      handled_by=auth.uid(),
      handled_at=now()
  where id = p_claim_id;

  update public.suspended_meals
  set status='claimed'
  where id = v_meal_id;

  return jsonb_build_object('ok', true, 'verify_code', v_code);
end;
$function$
;

CREATE OR REPLACE FUNCTION public.owner_fulfill_suspended_claim_v1(p_claim_id uuid, p_code text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  v_business_id uuid;
  v_code text;
begin
  select m.business_id, c.verify_code into v_business_id, v_code
  from public.suspended_meal_claims c
  join public.suspended_meals m on m.id = c.suspended_meal_id
  where c.id = p_claim_id and c.status='approved';

  if v_business_id is null then
    return jsonb_build_object('ok', false, 'error', 'not_found_or_not_approved');
  end if;

  if not public.is_owner_of_business(v_business_id) and not public.is_admin() then
    return jsonb_build_object('ok', false, 'error', 'not_owner');
  end if;

  if v_code is null or v_code <> p_code then
    return jsonb_build_object('ok', false, 'error', 'bad_code');
  end if;

  update public.suspended_meal_claims
  set status='fulfilled',
      fulfilled_at=now(),
      verify_code=null
  where id = p_claim_id;

  return jsonb_build_object('ok', true);
end;
$function$
;

CREATE OR REPLACE FUNCTION public.owner_list_suspended_claims_v1(p_business_id uuid, p_status text DEFAULT 'pending'::text, p_limit integer DEFAULT 30, p_offset integer DEFAULT 0)
 RETURNS TABLE(claim_id uuid, claim_status text, claim_created_at timestamp with time zone, meal_id uuid, amount_cents integer, currency text, meal_message text, claimant_user_id uuid, claimant_name text, verify_code text, fulfilled_at timestamp with time zone)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  select
    c.id,
    c.status::text,
    c.created_at,

    m.id,
    m.amount_cents,
    m.currency,
    m.message,

    c.claimant_user_id,
    coalesce(p.display_name,'Kullanıcı') as claimant_name,

    c.verify_code,
    c.fulfilled_at
  from public.suspended_meal_claims c
  join public.suspended_meals m on m.id = c.suspended_meal_id
  left join public.user_profiles p on p.user_id = c.claimant_user_id
  where m.business_id = p_business_id
    and public.is_owner_of_business(p_business_id)
    and (p_status is null or c.status::text = p_status)
  order by (c.status='pending') desc, c.created_at asc
  limit greatest(p_limit,0) offset greatest(p_offset,0);
$function$
;

CREATE OR REPLACE FUNCTION public.pick_one_menu_item_v1(p_user_lat double precision, p_user_lng double precision, p_radius_km double precision DEFAULT 5)
 RETURNS jsonb
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  with prof as (
    select *
    from public.user_diet_profiles
    where user_id = auth.uid()
  ),
  items as (
    select *
    from public.search_menu_items_v1(
      p_user_lat, p_user_lng, p_radius_km,
      null,
      coalesce((select is_vegan from prof), false),
      coalesce((select is_vegetarian from prof), false),
      coalesce((select is_gluten_free from prof), false),
      coalesce((select is_lactose_free from prof), false),
      coalesce((select is_halal from prof), false),
      (select max_calories from prof),
      false,
      40, 0
    )
  )
  select to_jsonb(x) from (
    select *
    from items
    order by
      (case when price_status='verified' then 0 else 1 end),
      distance_km asc
    limit 1
  ) x;
$function$
;

CREATE OR REPLACE FUNCTION public.recalc_review_helpful_count()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO 'public'
AS $function$
begin
  if (tg_op = 'INSERT') then
    update public.reviews
      set helpful_count = helpful_count + 1
    where id = new.review_id;
    return new;
  end if;

  if (tg_op = 'DELETE') then
    update public.reviews
      set helpful_count = greatest(helpful_count - 1, 0)
    where id = old.review_id;
    return old;
  end if;

  return null;
end;
$function$
;

CREATE OR REPLACE FUNCTION public.recompute_business_last_review_at(p_business_id uuid)
 RETURNS timestamp with time zone
 LANGUAGE sql
 STABLE
 SET search_path TO 'public'
AS $function$
  select max(created_at)
  from public.reviews
  where business_id = p_business_id
    and status = 'approved';
$function$
;

CREATE OR REPLACE FUNCTION public.refresh_businesses_with_stats_mv()
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
begin
  refresh materialized view concurrently public.businesses_with_stats_mv;
end$function$
;

CREATE OR REPLACE FUNCTION public.reject_business_suggestion(p_suggestion_id uuid, p_admin_note text DEFAULT NULL::text)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  v_is_admin boolean;
  v_status text;
begin
  select exists(select 1 from public.admin_users where user_id = auth.uid())
  into v_is_admin;

  if not v_is_admin then
    raise exception 'not_authorized';
  end if;

  select status into v_status
  from public.business_suggestions
  where id = p_suggestion_id
  for update;

  if not found then
    raise exception 'suggestion_not_found';
  end if;

  if v_status <> 'pending' then
    raise exception 'suggestion_not_pending';
  end if;

  update public.business_suggestions
  set
    status = 'rejected',
    reviewed_at = now(),
    admin_note = p_admin_note
  where id = p_suggestion_id;
end;
$function$
;

CREATE OR REPLACE FUNCTION public.search_businesses_v1(p_query text, p_city text DEFAULT NULL::text, p_district text DEFAULT NULL::text, p_limit integer DEFAULT 50, p_offset integer DEFAULT 0)
 RETURNS TABLE(id uuid, name text, category text, address text, city text, district text, lat double precision, lng double precision, rank double precision)
 LANGUAGE sql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  with q as (
    select nullif(trim(coalesce(p_query,'')), '') as query
  ),
  ts as (
    select
      websearch_to_tsquery('turkish', (select query from q)) as tsq
    where (select query from q) is not null
  )
  select
    b.id,
    b.name,
    b.category,
    b.address,
    b.city,
    b.district,
    b.lat,
    b.lng,
    case
      when (select query from q) is null then 0
      when exists (select 1 from ts) then ts_rank_cd(b.search_tsv, (select tsq from ts))
      else 0
    end as rank
  from public.businesses b
  where (p_city is null or b.city = p_city)
    and (p_district is null or b.district = p_district)
    and (
      (select query from q) is null
      or (
        exists (select 1 from ts)
        and b.search_tsv @@ (select tsq from ts)
      )
      or b.name ilike '%' || (select query from q) || '%'
      or b.address ilike '%' || (select query from q) || '%'
      or b.category ilike '%' || (select query from q) || '%'
    )
  order by
    rank desc,
    b.id desc
  limit greatest(p_limit, 0)
  offset greatest(p_offset, 0);
$function$
;

CREATE OR REPLACE FUNCTION public.search_food_catalog_v1(p_q text, p_limit integer DEFAULT 12)
 RETURNS TABLE(id bigint, name text, category_id text, category_name text)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  select
    i.id,
    i.name,
    c.id as category_id,
    c.name as category_name
  from public.food_catalog_items i
  join public.food_catalog_categories c on c.id = i.category_id
  where i.name_norm ilike ('%' || lower(p_q) || '%')
  order by i.popularity desc, i.name asc
  limit greatest(p_limit,0);
$function$
;

CREATE OR REPLACE FUNCTION public.search_nearby_businesses_v1(p_lat double precision, p_lng double precision, p_radius_km integer DEFAULT 5, p_query text DEFAULT NULL::text, p_category text DEFAULT NULL::text, p_limit integer DEFAULT 30)
 RETURNS TABLE(id uuid, name text, category text, city text, district text, address text, lat double precision, lng double precision, distance_km double precision)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  with base as (
    select
      b.*,
      -- Haversine distance (km)
      (6371.0 * 2.0 * asin(
        sqrt(
          power(sin(radians((b.lat - p_lat) / 2.0)), 2)
          + cos(radians(p_lat)) * cos(radians(b.lat))
          * power(sin(radians((b.lng - p_lng) / 2.0)), 2)
        )
      )) as distance_km
    from public.businesses b
    where b.is_active = true
      and b.lat is not null
      and b.lng is not null
      and (p_category is null or p_category = '' or b.category = p_category)
      and (
        p_query is null
        or p_query = ''
        or b.name ilike ('%' || p_query || '%')
        or coalesce(b.address,'') ilike ('%' || p_query || '%')
      )
  )
  select
    id, name, category, city, district, address, lat, lng, distance_km
  from base
  where distance_km <= greatest(1, p_radius_km)::double precision
  order by distance_km asc
  limit p_limit;
$function$
;

CREATE OR REPLACE FUNCTION public.search_nearby_businesses_v2(p_lat double precision, p_lng double precision, p_radius_km integer DEFAULT 5, p_query text DEFAULT NULL::text, p_category text DEFAULT NULL::text, p_limit integer DEFAULT 30)
 RETURNS TABLE(id uuid, name text, category text, city text, district text, address text, lat double precision, lng double precision, distance_km double precision, quality_score integer)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  with base as (
    select
      b.*,
      -- Haversine distance
      (6371.0 * 2.0 * asin(
        sqrt(
          power(sin(radians((b.lat - p_lat) / 2.0)), 2)
          + cos(radians(p_lat)) * cos(radians(b.lat))
          * power(sin(radians((b.lng - p_lng) / 2.0)), 2)
        )
      )) as distance_km,

      -- QUALITY SCORE
      (
        0
        + case when b.phone is not null and length(b.phone) >= 7 then 1 else 0 end
        + case when b.address is not null and length(b.address) >= 6 then 1 else 0 end
        + case when b.category is not null then 1 else 0 end
        + case when length(b.name) >= 6 then 1 else 0 end
        + case
            when lower(b.name) in (
              'restaurant','cafe','bar','pub','mekan','lokanta'
            ) then -3
            else 2
          end
        + case
            when b.phone is null and b.address is null then -2
            else 0
          end
      ) as quality_score

    from public.businesses b
    where b.is_active = true
      and b.lat is not null
      and b.lng is not null
      and (p_category is null or p_category = '' or b.category = p_category)
      and (
        p_query is null
        or p_query = ''
        or b.name ilike ('%' || p_query || '%')
        or coalesce(b.address,'') ilike ('%' || p_query || '%')
      )
  )
  select
    id, name, category, city, district, address, lat, lng,
    distance_km,
    quality_score
  from base
  where distance_km <= greatest(1, p_radius_km)::double precision
  order by
    quality_score desc,      -- 🔥 önce kalite
    distance_km asc          -- sonra mesafe
  limit p_limit;
$function$
;

CREATE OR REPLACE FUNCTION public.search_nearby_businesses_v3(p_lat double precision, p_lng double precision, p_radius_km integer DEFAULT 5, p_query text DEFAULT NULL::text, p_category text DEFAULT NULL::text, p_open_now boolean DEFAULT false, p_limit integer DEFAULT 30)
 RETURNS TABLE(id uuid, name text, category text, city text, district text, address text, lat double precision, lng double precision, distance_km double precision, quality_score integer)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  with base as (
    select
      b.*,
      (6371.0 * 2.0 * asin(
        sqrt(
          power(sin(radians((b.lat - p_lat) / 2.0)), 2)
          + cos(radians(p_lat)) * cos(radians(b.lat))
          * power(sin(radians((b.lng - p_lng) / 2.0)), 2)
        )
      )) as distance_km,
      (
        0
        + case when b.phone is not null and length(b.phone) >= 7 then 1 else 0 end
        + case when b.address is not null and length(b.address) >= 6 then 1 else 0 end
        + case when length(b.name) >= 6 then 1 else 0 end
        + case when lower(b.name) in ('restaurant','cafe','bar','pub','mekan','lokanta') then -3 else 2 end
      ) as quality_score
    from public.businesses b
    left join public.business_hours h on h.business_id = b.id
    where b.is_active = true
      and b.lat is not null
      and b.lng is not null
      and (p_category is null or p_category = '' or b.category = p_category)
      and (
        p_query is null
        or p_query = ''
        or b.name ilike ('%' || p_query || '%')
        or coalesce(b.address,'') ilike ('%' || p_query || '%')
      )
      and (
        p_open_now = false
        or (
          h.business_id is not null
          and (
            case extract(dow from now())
              when 1 then (h.mon_open is not null and current_time between h.mon_open and h.mon_close)
              when 2 then (h.tue_open is not null and current_time between h.tue_open and h.tue_close)
              when 3 then (h.wed_open is not null and current_time between h.wed_open and h.wed_close)
              when 4 then (h.thu_open is not null and current_time between h.thu_open and h.thu_close)
              when 5 then (h.fri_open is not null and current_time between h.fri_open and h.fri_close)
              when 6 then (h.sat_open is not null and current_time between h.sat_open and h.sat_close)
              when 0 then (h.sun_open is not null and current_time between h.sun_open and h.sun_close)
            end
          )
        )
      )
  )
  select
    id, name, category, city, district, address, lat, lng,
    distance_km,
    quality_score
  from base
  where distance_km <= greatest(1, p_radius_km)::double precision
  order by quality_score desc, distance_km asc
  limit p_limit;
$function$
;

CREATE OR REPLACE FUNCTION public.search_nearby_businesses_v3(p_user_lat double precision, p_user_lng double precision, p_radius_km double precision DEFAULT 5, p_limit integer DEFAULT 50, p_offset integer DEFAULT 0, p_city text DEFAULT NULL::text, p_district text DEFAULT NULL::text, p_query text DEFAULT NULL::text)
 RETURNS TABLE(id uuid, name text, category text, address text, city text, district text, lat double precision, lng double precision, distance_km double precision)
 LANGUAGE sql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  with params as (
    select
      st_setsrid(st_makepoint(p_user_lng, p_user_lat), 4326)::geography as user_geog,
      greatest(p_radius_km, 0.1) * 1000.0 as radius_m,
      nullif(trim(coalesce(p_query,'')), '') as q
  )
  select
    b.id,
    b.name,
    b.category,
    b.address,
    b.city,
    b.district,
    b.lat,
    b.lng,
    (st_distance(b.geog, (select user_geog from params)) / 1000.0)::double precision as distance_km
  from public.businesses b, params
  where b.geog is not null
    and st_dwithin(b.geog, params.user_geog, params.radius_m)
    and (p_city is null or b.city = p_city)
    and (p_district is null or b.district = p_district)
    and (
      params.q is null
      or b.search_tsv @@ websearch_to_tsquery('turkish', params.q)
      or b.name ilike '%' || params.q || '%'
      or b.address ilike '%' || params.q || '%'
    )
  order by st_distance(b.geog, params.user_geog) asc
  limit greatest(p_limit, 0)
  offset greatest(p_offset, 0);
$function$
;

CREATE OR REPLACE FUNCTION public.submit_business_suggestion(p_name text, p_category text, p_city text DEFAULT NULL::text, p_district text DEFAULT NULL::text, p_address text DEFAULT NULL::text, p_phone text DEFAULT NULL::text, p_website text DEFAULT NULL::text, p_notes text DEFAULT NULL::text)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  v_id uuid;
begin
  insert into public.business_suggestions(
    user_id, name, category, city, district, address, phone, website, notes, status
  )
  values (
    auth.uid(), p_name, p_category, p_city, p_district, p_address, p_phone, p_website, p_notes, 'pending'
  )
  returning id into v_id;

  return v_id;
end;
$function$
;

CREATE OR REPLACE FUNCTION public.submit_menu_item_suggestion_v1(p_business_id uuid, p_menu_item_id uuid, p_action text, p_payload jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
begin
  if auth.uid() is null then
    return jsonb_build_object('ok', false, 'error', 'not_authenticated');
  end if;

  insert into public.menu_item_suggestions(business_id, menu_item_id, action, payload, created_by)
  values (p_business_id, p_menu_item_id, p_action, p_payload, auth.uid());

  return jsonb_build_object('ok', true);
end;
$function$
;

CREATE OR REPLACE FUNCTION public.submit_owner_claim_v1(p_business_id uuid, p_full_name text, p_phone text, p_evidence_url text DEFAULT NULL::text, p_note text DEFAULT NULL::text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  v_uid uuid := auth.uid();
  v_recent_exists boolean;
  v_claim_id uuid;
begin
  if v_uid is null then
    return jsonb_build_object('ok', false, 'error', 'not_authenticated');
  end if;

  if p_business_id is null then
    return jsonb_build_object('ok', false, 'error', 'missing_business_id');
  end if;

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
    nullif(trim(p_note),''),
    'pending'
  )
  returning id into v_claim_id;

  return jsonb_build_object('ok', true, 'claim_id', v_claim_id);
exception
  when unique_violation then
    -- unique constraint'a takılırsa user aynı business'e daha önce başvurmuş demektir
    return jsonb_build_object('ok', false, 'error', 'already_submitted');
end;
$function$
;

CREATE OR REPLACE FUNCTION public.submit_presence_v1(p_business_id uuid, p_crowd text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  v_last timestamptz;
begin
  if auth.uid() is null then
    return jsonb_build_object('ok', false, 'error', 'not_authenticated');
  end if;

  if p_crowd not in ('quiet','normal','busy') then
    return jsonb_build_object('ok', false, 'error', 'bad_crowd');
  end if;

  select max(created_at) into v_last
  from public.business_presence_events
  where business_id = p_business_id and user_id = auth.uid();

  if v_last is not null and v_last > now() - interval '15 minutes' then
    return jsonb_build_object('ok', false, 'error', 'rate_limited_15m');
  end if;

  insert into public.business_presence_events(business_id, user_id, crowd)
  values (p_business_id, auth.uid(), p_crowd::public.crowd_level);

  return jsonb_build_object('ok', true);
end;
$function$
;

CREATE OR REPLACE FUNCTION public.submit_report_v1(p_business_id uuid DEFAULT NULL::uuid, p_review_id uuid DEFAULT NULL::uuid, p_reason text DEFAULT 'other'::text, p_details text DEFAULT NULL::text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  v_uid uuid := auth.uid();
  v_recent_exists boolean;
  v_report_id uuid;
begin
  if v_uid is null then
    return jsonb_build_object('ok', false, 'error', 'not_authenticated');
  end if;

  if p_business_id is null and p_review_id is null then
    return jsonb_build_object('ok', false, 'error', 'missing_target');
  end if;

  -- 24 saat rate limit:
  if p_business_id is not null then
    select exists(
      select 1
      from public.reports
      where user_id = v_uid
        and business_id = p_business_id
        and created_at >= now() - interval '24 hours'
    ) into v_recent_exists;
  else
    select exists(
      select 1
      from public.reports
      where user_id = v_uid
        and review_id = p_review_id
        and created_at >= now() - interval '24 hours'
    ) into v_recent_exists;
  end if;

  if v_recent_exists then
    return jsonb_build_object('ok', false, 'error', 'rate_limited_24h');
  end if;

  insert into public.reports(user_id, business_id, review_id, reason, details)
  values (v_uid, p_business_id, p_review_id, coalesce(nullif(trim(p_reason),''),'other'), nullif(trim(p_details),''))
  returning id into v_report_id;

  return jsonb_build_object('ok', true, 'report_id', v_report_id);
end;
$function$
;

CREATE OR REPLACE FUNCTION public.taste_recommendations_from_match_v1(p_match_user_id uuid, p_limit integer DEFAULT 10)
 RETURNS TABLE(business_id uuid, business_name text, city text, district text, match_rating integer, match_review_title text, match_review_excerpt text)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  with my_seen as (
    select distinct business_id
    from public.reviews
    where user_id = auth.uid()
      and status='approved'
  ),
  match_loved as (
    select r.business_id, r.rating, r.title, r.content
    from public.reviews r
    where r.user_id = p_match_user_id
      and r.status='approved'
      and r.rating >= 5
  )
  select
    b.id as business_id,
    b.name as business_name,
    b.city,
    b.district,
    ml.rating as match_rating,
    ml.title as match_review_title,
    left(ml.content, 140) as match_review_excerpt
  from match_loved ml
  join public.businesses b on b.id = ml.business_id
  left join my_seen ms on ms.business_id = ml.business_id
  where ms.business_id is null
  order by ml.rating desc, b.name asc
  limit greatest(p_limit,0);
$function$
;

CREATE OR REPLACE FUNCTION public.taste_recommendations_from_match_v2(p_match_user_id uuid, p_limit integer DEFAULT 10)
 RETURNS TABLE(business_id uuid, business_name text, city text, district text, match_rating integer, match_review_title text, match_review_excerpt text, match_review_created_at timestamp with time zone)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  with my_seen as (
    select distinct business_id
    from public.reviews
    where user_id = auth.uid()
      and status='approved'
  ),
  match_loved as (
    select r.business_id, r.rating, r.title, r.content, r.created_at
    from public.reviews r
    where r.user_id = p_match_user_id
      and r.status='approved'
      and r.rating >= 5
  )
  select
    b.id as business_id,
    b.name as business_name,
    b.city,
    b.district,
    ml.rating as match_rating,
    ml.title as match_review_title,
    left(ml.content, 140) as match_review_excerpt,
    ml.created_at as match_review_created_at
  from match_loved ml
  join public.businesses b on b.id = ml.business_id
  left join my_seen ms on ms.business_id = ml.business_id
  where ms.business_id is null
  order by ml.created_at desc, b.name asc
  limit greatest(p_limit,0);
$function$
;

CREATE OR REPLACE FUNCTION public.tg_business_stats_apply_review_change()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  v_bid uuid;
  v_old_approved boolean := false;
  v_new_approved boolean := false;
  v_need_recompute_last boolean := false;

  v_old_rating int;
  v_new_rating int;
  v_old_created timestamptz;
  v_new_created timestamptz;

  v_curr_last timestamptz;
begin
  if (tg_op = 'DELETE') then
    v_bid := old.business_id;
    v_old_approved := (old.status = 'approved');
    v_old_rating := old.rating;
    v_old_created := old.created_at;
  else
    v_bid := new.business_id;
    v_new_approved := (new.status = 'approved');
    v_new_rating := new.rating;
    v_new_created := new.created_at;

    if (tg_op = 'UPDATE') then
      v_old_approved := (old.status = 'approved');
      v_old_rating := old.rating;
      v_old_created := old.created_at;

      if old.business_id is distinct from new.business_id then
        if v_old_approved then
          perform public.tg_business_stats_apply_review_change_old_business(old.business_id, old.rating, old.created_at);
        end if;
        v_old_approved := false;
      end if;
    end if;
  end if;

  insert into public.business_stats (business_id) values (v_bid)
  on conflict (business_id) do nothing;

  select last_review_at into v_curr_last
  from public.business_stats
  where business_id = v_bid;

  if tg_op = 'INSERT' then
    if v_new_approved then
      update public.business_stats
      set
        approved_reviews_count = approved_reviews_count + 1,
        approved_rating_sum = approved_rating_sum + coalesce(v_new_rating,0),
        rating_5 = rating_5 + case when v_new_rating=5 then 1 else 0 end,
        rating_4 = rating_4 + case when v_new_rating=4 then 1 else 0 end,
        rating_3 = rating_3 + case when v_new_rating=3 then 1 else 0 end,
        rating_2 = rating_2 + case when v_new_rating=2 then 1 else 0 end,
        rating_1 = rating_1 + case when v_new_rating=1 then 1 else 0 end,
        last_review_at = case
          when v_curr_last is null then v_new_created
          when v_new_created > v_curr_last then v_new_created
          else v_curr_last
        end,
        updated_at = now()
      where business_id = v_bid;
    end if;
    return new;
  end if;

  if tg_op = 'DELETE' then
    if v_old_approved then
      if v_curr_last is not null and v_old_created = v_curr_last then
        v_need_recompute_last := true;
      end if;

      update public.business_stats
      set
        approved_reviews_count = greatest(approved_reviews_count - 1, 0),
        approved_rating_sum = greatest(approved_rating_sum - coalesce(v_old_rating,0), 0),
        rating_5 = greatest(rating_5 - case when v_old_rating=5 then 1 else 0 end, 0),
        rating_4 = greatest(rating_4 - case when v_old_rating=4 then 1 else 0 end, 0),
        rating_3 = greatest(rating_3 - case when v_old_rating=3 then 1 else 0 end, 0),
        rating_2 = greatest(rating_2 - case when v_old_rating=2 then 1 else 0 end, 0),
        rating_1 = greatest(rating_1 - case when v_old_rating=1 then 1 else 0 end, 0),
        updated_at = now()
      where business_id = v_bid;

      if v_need_recompute_last then
        update public.business_stats
        set last_review_at = public.recompute_business_last_review_at(v_bid),
            updated_at = now()
        where business_id = v_bid;
      end if;
    end if;
    return old;
  end if;

  if tg_op = 'UPDATE' then
    if v_old_approved and v_new_approved then
      if v_old_rating is distinct from v_new_rating then
        update public.business_stats
        set
          approved_rating_sum = greatest(approved_rating_sum - coalesce(v_old_rating,0) + coalesce(v_new_rating,0), 0),
          rating_5 = greatest(rating_5 - case when v_old_rating=5 then 1 else 0 end, 0) + case when v_new_rating=5 then 1 else 0 end,
          rating_4 = greatest(rating_4 - case when v_old_rating=4 then 1 else 0 end, 0) + case when v_new_rating=4 then 1 else 0 end,
          rating_3 = greatest(rating_3 - case when v_old_rating=3 then 1 else 0 end, 0) + case when v_new_rating=3 then 1 else 0 end,
          rating_2 = greatest(rating_2 - case when v_old_rating=2 then 1 else 0 end, 0) + case when v_new_rating=2 then 1 else 0 end,
          rating_1 = greatest(rating_1 - case when v_old_rating=1 then 1 else 0 end, 0) + case when v_new_rating=1 then 1 else 0 end,
          updated_at = now()
        where business_id = v_bid;
      end if;

      if v_new_created is distinct from v_old_created then
        if v_curr_last is not null and v_old_created = v_curr_last then
          v_need_recompute_last := true;
        end if;

        if v_curr_last is null or v_new_created > v_curr_last then
          update public.business_stats
          set last_review_at = v_new_created,
              updated_at = now()
          where business_id = v_bid;
        elsif v_need_recompute_last then
          update public.business_stats
          set last_review_at = public.recompute_business_last_review_at(v_bid),
              updated_at = now()
          where business_id = v_bid;
        end if;
      end if;

      return new;
    end if;

    if (not v_old_approved) and v_new_approved then
      update public.business_stats
      set
        approved_reviews_count = approved_reviews_count + 1,
        approved_rating_sum = approved_rating_sum + coalesce(v_new_rating,0),
        rating_5 = rating_5 + case when v_new_rating=5 then 1 else 0 end,
        rating_4 = rating_4 + case when v_new_rating=4 then 1 else 0 end,
        rating_3 = rating_3 + case when v_new_rating=3 then 1 else 0 end,
        rating_2 = rating_2 + case when v_new_rating=2 then 1 else 0 end,
        rating_1 = rating_1 + case when v_new_rating=1 then 1 else 0 end,
        last_review_at = case
          when v_curr_last is null then v_new_created
          when v_new_created > v_curr_last then v_new_created
          else v_curr_last
        end,
        updated_at = now()
      where business_id = v_bid;
      return new;
    end if;

    if v_old_approved and (not v_new_approved) then
      if v_curr_last is not null and v_old_created = v_curr_last then
        v_need_recompute_last := true;
      end if;

      update public.business_stats
      set
        approved_reviews_count = greatest(approved_reviews_count - 1, 0),
        approved_rating_sum = greatest(approved_rating_sum - coalesce(v_old_rating,0), 0),
        rating_5 = greatest(rating_5 - case when v_old_rating=5 then 1 else 0 end, 0),
        rating_4 = greatest(rating_4 - case when v_old_rating=4 then 1 else 0 end, 0),
        rating_3 = greatest(rating_3 - case when v_old_rating=3 then 1 else 0 end, 0),
        rating_2 = greatest(rating_2 - case when v_old_rating=2 then 1 else 0 end, 0),
        rating_1 = greatest(rating_1 - case when v_old_rating=1 then 1 else 0 end, 0),
        updated_at = now()
      where business_id = v_bid;

      if v_need_recompute_last then
        update public.business_stats
        set last_review_at = public.recompute_business_last_review_at(v_bid),
            updated_at = now()
        where business_id = v_bid;
      end if;

      return new;
    end if;

    return new;
  end if;

  return null;
end;
$function$
;

CREATE OR REPLACE FUNCTION public.tg_business_stats_apply_review_change_old_business(p_business_id uuid, p_old_rating integer, p_old_created timestamp with time zone)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  v_curr_last timestamptz;
  v_need_recompute boolean := false;
begin
  insert into public.business_stats (business_id) values (p_business_id)
  on conflict (business_id) do nothing;

  select last_review_at into v_curr_last
  from public.business_stats
  where business_id = p_business_id;

  if v_curr_last is not null and p_old_created = v_curr_last then
    v_need_recompute := true;
  end if;

  update public.business_stats
  set
    approved_reviews_count = greatest(approved_reviews_count - 1, 0),
    approved_rating_sum = greatest(approved_rating_sum - coalesce(p_old_rating,0), 0),
    rating_5 = greatest(rating_5 - case when p_old_rating=5 then 1 else 0 end, 0),
    rating_4 = greatest(rating_4 - case when p_old_rating=4 then 1 else 0 end, 0),
    rating_3 = greatest(rating_3 - case when p_old_rating=3 then 1 else 0 end, 0),
    rating_2 = greatest(rating_2 - case when p_old_rating=2 then 1 else 0 end, 0),
    rating_1 = greatest(rating_1 - case when p_old_rating=1 then 1 else 0 end, 0),
    updated_at = now()
  where business_id = p_business_id;

  if v_need_recompute then
    update public.business_stats
    set last_review_at = public.recompute_business_last_review_at(p_business_id),
        updated_at = now()
    where business_id = p_business_id;
  end if;
end;
$function$
;

CREATE OR REPLACE FUNCTION public.tg_businesses_sync_geog()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
begin
  if new.lat is not null and new.lng is not null then
    new.geog := st_setsrid(st_makepoint(new.lng::double precision, new.lat::double precision), 4326)::geography;
  else
    new.geog := null;
  end if;
  return new;
end$function$
;

CREATE OR REPLACE FUNCTION public.tg_businesses_sync_search_tsv()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
begin
  new.search_tsv :=
    to_tsvector(
      'turkish',
      coalesce(new.name,'') || ' ' ||
      coalesce(new.category,'') || ' ' ||
      coalesce(new.address,'') || ' ' ||
      coalesce(new.city,'') || ' ' ||
      coalesce(new.district,'')
    );
  return new;
end$function$
;

CREATE OR REPLACE FUNCTION public.tg_review_votes_sync_helpful_count()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
begin
  if (tg_op = 'INSERT') then
    update public.reviews
      set helpful_count = helpful_count + 1
    where id = new.review_id;
    return new;
  elsif (tg_op = 'DELETE') then
    update public.reviews
      set helpful_count = greatest(helpful_count - 1, 0)
    where id = old.review_id;
    return old;
  end if;
  return null;
end$function$
;

CREATE OR REPLACE FUNCTION public.toggle_favorite_v1(p_business_id uuid)
 RETURNS TABLE(is_favorited boolean)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  v_uid uuid := auth.uid();
begin
  if v_uid is null then
    raise exception 'not_authenticated';
  end if;

  if exists (
    select 1
    from public.favorites
    where user_id = v_uid
      and business_id = p_business_id
  ) then
    delete from public.favorites
    where user_id = v_uid
      and business_id = p_business_id;

    return query select false;
  else
    insert into public.favorites(user_id, business_id)
    values (v_uid, p_business_id)
    on conflict (user_id, business_id) do nothing;

    return query select true;
  end if;
end;
$function$
;

CREATE OR REPLACE FUNCTION public.toggle_follow_v1(p_followee_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
begin
  if auth.uid() is null then
    return jsonb_build_object('ok', false, 'error', 'not_authenticated');
  end if;

  if p_followee_id = auth.uid() then
    return jsonb_build_object('ok', false, 'error', 'cannot_follow_self');
  end if;

  if exists (
    select 1 from public.user_follows
    where follower_id = auth.uid() and followee_id = p_followee_id
  ) then
    delete from public.user_follows
    where follower_id = auth.uid() and followee_id = p_followee_id;

    return jsonb_build_object('ok', true, 'following', false);
  else
    insert into public.user_follows(follower_id, followee_id)
    values (auth.uid(), p_followee_id);

    return jsonb_build_object('ok', true, 'following', true);
  end if;
end;
$function$
;

CREATE OR REPLACE FUNCTION public.upsert_my_diet_profile_v1(p_is_vegan boolean, p_is_vegetarian boolean, p_is_gluten_free boolean, p_is_lactose_free boolean, p_is_halal boolean, p_max_calories integer)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
begin
  if auth.uid() is null then
    return jsonb_build_object('ok', false, 'error', 'not_authenticated');
  end if;

  insert into public.user_diet_profiles(user_id,is_vegan,is_vegetarian,is_gluten_free,is_lactose_free,is_halal,max_calories)
  values (auth.uid(), p_is_vegan,p_is_vegetarian,p_is_gluten_free,p_is_lactose_free,p_is_halal,p_max_calories)
  on conflict (user_id) do update
    set is_vegan=excluded.is_vegan,
        is_vegetarian=excluded.is_vegetarian,
        is_gluten_free=excluded.is_gluten_free,
        is_lactose_free=excluded.is_lactose_free,
        is_halal=excluded.is_halal,
        max_calories=excluded.max_calories,
        updated_at=now();

  return jsonb_build_object('ok', true);
end;
$function$
;

create or replace view "public"."user_business_signals_v1" as  WITH price_pos AS (
         SELECT mi.business_id,
            v.user_id,
            (count(*))::double precision AS score
           FROM (public.menu_item_price_votes v
             JOIN public.menu_items mi ON ((mi.id = v.menu_item_id)))
          WHERE (v.vote = 1)
          GROUP BY mi.business_id, v.user_id
        ), photo_pos AS (
         SELECT p.business_id,
            v.user_id,
            ((count(*))::double precision * (0.5)::double precision) AS score
           FROM (public.menu_item_photo_votes v
             JOIN public.menu_item_photos p ON ((p.id = v.photo_id)))
          WHERE (v.vote = 1)
          GROUP BY p.business_id, v.user_id
        ), uploads AS (
         SELECT menu_item_photos.business_id,
            menu_item_photos.created_by AS user_id,
            ((count(*))::double precision * (1.5)::double precision) AS score
           FROM public.menu_item_photos
          GROUP BY menu_item_photos.business_id, menu_item_photos.created_by
        ), merged AS (
         SELECT price_pos.business_id,
            price_pos.user_id,
            price_pos.score
           FROM price_pos
        UNION ALL
         SELECT photo_pos.business_id,
            photo_pos.user_id,
            photo_pos.score
           FROM photo_pos
        UNION ALL
         SELECT uploads.business_id,
            uploads.user_id,
            uploads.score
           FROM uploads
        )
 SELECT business_id,
    user_id,
    sum(score) AS signal_score
   FROM merged
  GROUP BY business_id, user_id;


DO $$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'valid_detail' AND typnamespace = 'public'::regnamespace) THEN CREATE TYPE "public"."valid_detail" AS ("valid" boolean, "reason" character varying, "location" public.geometry); END IF; END $$;

CREATE OR REPLACE FUNCTION public.vote_menu_item_photo_v1(p_photo_id uuid, p_vote smallint)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  v_prev smallint;
begin
  if auth.uid() is null then
    return jsonb_build_object('ok', false, 'error', 'not_authenticated');
  end if;

  if p_vote not in (-1,1) then
    return jsonb_build_object('ok', false, 'error', 'bad_vote');
  end if;

  select vote into v_prev
  from public.menu_item_photo_votes
  where photo_id = p_photo_id and user_id = auth.uid();

  if v_prev is null then
    insert into public.menu_item_photo_votes(photo_id, user_id, vote)
    values (p_photo_id, auth.uid(), p_vote);

    update public.menu_item_photos
    set up_votes = up_votes + case when p_vote=1 then 1 else 0 end,
        down_votes = down_votes + case when p_vote=-1 then 1 else 0 end
    where id = p_photo_id;

    return jsonb_build_object('ok', true, 'mode', 'insert', 'vote', p_vote);

  elsif v_prev = p_vote then
    -- toggle off
    delete from public.menu_item_photo_votes
    where photo_id = p_photo_id and user_id = auth.uid();

    update public.menu_item_photos
    set up_votes = up_votes - case when p_vote=1 then 1 else 0 end,
        down_votes = down_votes - case when p_vote=-1 then 1 else 0 end
    where id = p_photo_id;

    return jsonb_build_object('ok', true, 'mode', 'remove', 'vote', 0);

  else
    -- switch vote
    update public.menu_item_photo_votes
    set vote = p_vote
    where photo_id = p_photo_id and user_id = auth.uid();

    update public.menu_item_photos
    set up_votes = up_votes + case when p_vote=1 then 1 else -1 end,
        down_votes = down_votes + case when p_vote=-1 then 1 else -1 end
    where id = p_photo_id;

    return jsonb_build_object('ok', true, 'mode', 'switch', 'vote', p_vote);
  end if;
end;
$function$
;

CREATE OR REPLACE FUNCTION public.vote_menu_item_price_v1(p_menu_item_id uuid, p_vote smallint)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  v_prev smallint;
begin
  if auth.uid() is null then
    return jsonb_build_object('ok', false, 'error', 'not_authenticated');
  end if;

  if p_vote not in (-1,1) then
    return jsonb_build_object('ok', false, 'error', 'bad_vote');
  end if;

  select vote into v_prev
  from public.menu_item_price_votes
  where menu_item_id = p_menu_item_id and user_id = auth.uid();

  if v_prev is null then
    insert into public.menu_item_price_votes(menu_item_id, user_id, vote)
    values (p_menu_item_id, auth.uid(), p_vote);
    return jsonb_build_object('ok', true, 'mode', 'insert', 'vote', p_vote);

  elsif v_prev = p_vote then
    delete from public.menu_item_price_votes
    where menu_item_id = p_menu_item_id and user_id = auth.uid();
    return jsonb_build_object('ok', true, 'mode', 'remove', 'vote', 0);

  else
    update public.menu_item_price_votes
    set vote = p_vote, created_at = now()
    where menu_item_id = p_menu_item_id and user_id = auth.uid();
    return jsonb_build_object('ok', true, 'mode', 'switch', 'vote', p_vote);
  end if;
end;
$function$
;

create or replace view "deprecated"."admin_business_suggestions_queue_v1_deprecated_202603" as  SELECT id,
    created_at,
    user_id,
    name,
    category,
    address,
    city,
    district,
    notes,
    status
   FROM public.admin_business_suggestions_queue_v1;


create or replace view "deprecated"."admin_owner_claims_queue_v1_deprecated_202603" as  SELECT id,
    created_at,
    status,
    user_id,
    business_id,
    full_name,
    phone,
    evidence_url,
    note,
    handled_by,
    handled_at,
    admin_note
   FROM public.admin_owner_claims_queue_v1;


create or replace view "deprecated"."admin_reports_queue_v1_deprecated_202603" as  SELECT id,
    created_at,
    durum,
    reason,
    details,
    user_id,
    business_id,
    review_id,
    handled_by,
    handled_at,
    admin_note
   FROM public.admin_reports_queue_v1;


create or replace view "deprecated"."admin_suggestions_v1_deprecated_202603" as  SELECT id,
    name,
    category,
    city,
    district,
    address,
    phone,
    website,
    notes,
    status,
    admin_note,
    created_at,
    reviewed_at,
    user_id
   FROM public.admin_suggestions_v1;


create or replace view "public"."business_price_index_v1" as  WITH latest_prices AS (
         SELECT mi.business_id,
            mi.id AS menu_item_id,
            COALESCE(h.price_cents, h.new_price_cents, h.old_price_cents, mi.price_cents) AS price_cents,
            COALESCE(h.created_at, mi.updated_at, mi.created_at) AS price_updated_at
           FROM (public.menu_items mi
             LEFT JOIN LATERAL ( SELECT h_1.price_cents,
                    h_1.new_price_cents,
                    h_1.old_price_cents,
                    h_1.created_at
                   FROM public.menu_item_price_history h_1
                  WHERE (h_1.menu_item_id = mi.id)
                  ORDER BY h_1.created_at DESC
                 LIMIT 1) h ON (true))
          WHERE (COALESCE(h.price_cents, h.new_price_cents, h.old_price_cents, mi.price_cents) IS NOT NULL)
        ), items AS (
         SELECT lp.business_id,
            lp.menu_item_id,
            lp.price_cents,
            lp.price_updated_at,
                CASE
                    WHEN (ps.price_status = 'verified'::text) THEN 1
                    ELSE 0
                END AS is_verified,
                CASE
                    WHEN (ps.price_status = 'verified'::text) THEN 2
                    ELSE 1
                END AS weight
           FROM (latest_prices lp
             LEFT JOIN public.menu_item_price_status_v1 ps ON ((ps.menu_item_id = lp.menu_item_id)))
        ), expanded AS (
         SELECT i.business_id,
            i.price_cents
           FROM items i,
            LATERAL generate_series(1, i.weight) gs(gs)
        ), medians AS (
         SELECT expanded.business_id,
            (round(percentile_cont((0.5)::double precision) WITHIN GROUP (ORDER BY ((expanded.price_cents)::double precision))))::integer AS median_price_cents
           FROM expanded
          GROUP BY expanded.business_id
        ), stats AS (
         SELECT items.business_id,
            (((sum(items.is_verified))::numeric / (NULLIF(count(*), 0))::numeric))::numeric(5,4) AS verified_ratio,
            max(items.price_updated_at) AS last_update_at
           FROM items
          GROUP BY items.business_id
        )
 SELECT m.business_id,
    m.median_price_cents,
    s.verified_ratio,
    s.last_update_at
   FROM (medians m
     JOIN stats s USING (business_id));


create or replace view "public"."business_quality_score_v1" as  WITH menu_items_base AS (
         SELECT mi.business_id,
            mi.id
           FROM public.menu_items mi
          WHERE (mi.is_available = true)
        ), verified_stats AS (
         SELECT mb.business_id,
            (count(*))::integer AS total_items,
            (count(*) FILTER (WHERE (ps.price_status = 'verified'::text)))::integer AS verified_items
           FROM (menu_items_base mb
             LEFT JOIN public.menu_item_price_status_v1 ps ON ((ps.menu_item_id = mb.id)))
          GROUP BY mb.business_id
        ), last_updates AS (
         SELECT l.business_id,
            max(l.created_at) FILTER (WHERE (l.type = 'menu_update'::text)) AS last_menu_update_at
           FROM public.business_activity_log l
          GROUP BY l.business_id
        ), photos AS (
         SELECT bm.business_id,
            (count(*))::integer AS photos_count
           FROM public.business_media bm
          GROUP BY bm.business_id
        ), amenities AS (
         SELECT bam.business_id,
            (count(*))::integer AS amenities_count
           FROM public.business_amenity_map bam
          GROUP BY bam.business_id
        ), pricing AS (
         SELECT b.id AS business_id,
            (pr.business_id IS NOT NULL) AS has_pricing_rule,
            ((bf.business_id IS NOT NULL) AND ((bf.has_cover_charge IS NOT NULL) OR (bf.has_service_fee IS NOT NULL) OR (bf.bottled_water_paid IS NOT NULL))) AS has_fee_flags
           FROM ((public.businesses b
             LEFT JOIN public.business_pricing_rules pr ON ((pr.business_id = b.id)))
             LEFT JOIN public.business_fee_flags bf ON ((bf.business_id = b.id)))
        ), weekly_votes AS (
         SELECT mi.business_id,
            (count(*) FILTER (WHERE ((v.vote = 1) AND (v.created_at >= (now() - '7 days'::interval)))))::integer AS weekly_verified_votes
           FROM (public.menu_item_price_votes v
             JOIN public.menu_items mi ON ((mi.id = v.menu_item_id)))
          GROUP BY mi.business_id
        ), scored AS (
         SELECT b.id AS business_id,
            COALESCE(vs.total_items, 0) AS total_items,
            COALESCE(vs.verified_items, 0) AS verified_items,
            COALESCE(lu.last_menu_update_at, b.created_at) AS last_menu_update_at,
            COALESCE(p.photos_count, 0) AS photos_count,
            COALESCE(a.amenities_count, 0) AS amenities_count,
            COALESCE(pr.has_pricing_rule, false) AS has_pricing_rule,
            COALESCE(pr.has_fee_flags, false) AS has_fee_flags,
            COALESCE(wv.weekly_verified_votes, 0) AS weekly_verified_votes
           FROM ((((((public.businesses b
             LEFT JOIN verified_stats vs ON ((vs.business_id = b.id)))
             LEFT JOIN last_updates lu ON ((lu.business_id = b.id)))
             LEFT JOIN photos p ON ((p.business_id = b.id)))
             LEFT JOIN amenities a ON ((a.business_id = b.id)))
             LEFT JOIN pricing pr ON ((pr.business_id = b.id)))
             LEFT JOIN weekly_votes wv ON ((wv.business_id = b.id)))
        ), points AS (
         SELECT s.business_id,
            s.total_items,
            s.verified_items,
            s.last_menu_update_at,
            s.photos_count,
            s.amenities_count,
            s.has_pricing_rule,
            s.has_fee_flags,
            s.weekly_verified_votes,
                CASE
                    WHEN (s.total_items = 0) THEN 0
                    ELSE (LEAST((40)::numeric, round((((s.verified_items)::numeric / (NULLIF(s.total_items, 0))::numeric) * (40)::numeric))))::integer
                END AS verified_points,
                CASE
                    WHEN (s.last_menu_update_at >= (now() - '3 days'::interval)) THEN 20
                    WHEN (s.last_menu_update_at >= (now() - '7 days'::interval)) THEN 16
                    WHEN (s.last_menu_update_at >= (now() - '14 days'::interval)) THEN 10
                    WHEN (s.last_menu_update_at >= (now() - '30 days'::interval)) THEN 5
                    ELSE 0
                END AS recency_points,
            (LEAST((15)::numeric, round((((LEAST(s.photos_count, 3))::numeric / 3.0) * (15)::numeric))))::integer AS photos_points,
            (LEAST((10)::numeric, round((((LEAST(s.amenities_count, 4))::numeric / 4.0) * (10)::numeric))))::integer AS amenities_points,
            (
                CASE
                    WHEN s.has_pricing_rule THEN 8
                    ELSE 0
                END +
                CASE
                    WHEN s.has_fee_flags THEN 7
                    ELSE 0
                END) AS pricing_points
           FROM scored s
        )
 SELECT business_id,
    GREATEST(0, LEAST(100, ((((verified_points + recency_points) + photos_points) + amenities_points) + pricing_points))) AS score,
    verified_points,
    recency_points,
    photos_points,
    amenities_points,
    pricing_points,
    total_items,
    verified_items,
    last_menu_update_at,
    photos_count,
    amenities_count,
    has_pricing_rule,
    has_fee_flags,
    weekly_verified_votes
   FROM points;



  create policy "account_deletion_requests_select_own"
  on "public"."account_deletion_requests"
  as permissive
  for select
  to authenticated
using ((public.is_admin() OR (user_id = auth.uid())));



  create policy "admin_audit_log_admin_all"
  on "public"."admin_audit_log"
  as permissive
  for all
  to authenticated
using (public.is_admin())
with check (public.is_admin());



  create policy "admin_runtime_settings_admin_all"
  on "public"."admin_runtime_settings"
  as permissive
  for all
  to public
using (public.is_admin())
with check (public.is_admin());



  create policy "admin_users_admin_all"
  on "public"."admin_users"
  as permissive
  for all
  to authenticated
using (public.is_admin())
with check (public.is_admin());



  create policy "analytics_events_admin_all"
  on "public"."analytics_events"
  as permissive
  for all
  to public
using (public.is_admin())
with check (public.is_admin());



  create policy "business_amenities_admin_delete"
  on "public"."business_amenities"
  as permissive
  for delete
  to authenticated
using (public.is_admin());



  create policy "business_amenities_admin_insert"
  on "public"."business_amenities"
  as permissive
  for insert
  to authenticated
with check (public.is_admin());



  create policy "business_amenities_admin_update"
  on "public"."business_amenities"
  as permissive
  for update
  to authenticated
using (public.is_admin())
with check (public.is_admin());



  create policy "business_amenity_map_owner_delete"
  on "public"."business_amenity_map"
  as permissive
  for delete
  to authenticated
using ((public.is_admin() OR public.is_owner_of_business(business_id)));



  create policy "business_amenity_map_owner_insert"
  on "public"."business_amenity_map"
  as permissive
  for insert
  to authenticated
with check ((public.is_admin() OR public.is_owner_of_business(business_id)));



  create policy "business_amenity_map_owner_update"
  on "public"."business_amenity_map"
  as permissive
  for update
  to authenticated
using ((public.is_admin() OR public.is_owner_of_business(business_id)))
with check ((public.is_admin() OR public.is_owner_of_business(business_id)));



  create policy "business_checkins_admin_all"
  on "public"."business_checkins"
  as permissive
  for all
  to public
using (public.is_admin())
with check (public.is_admin());



  create policy "business_fee_flags_admin_all"
  on "public"."business_fee_flags"
  as permissive
  for all
  to public
using (public.is_admin())
with check (public.is_admin());



  create policy "business_fee_votes_admin_all"
  on "public"."business_fee_votes"
  as permissive
  for all
  to public
using (public.is_admin())
with check (public.is_admin());



  create policy "business_hours_owner_update"
  on "public"."business_hours"
  as permissive
  for update
  to public
using ((public.is_admin() OR public.is_owner_of_business(business_id)))
with check ((public.is_admin() OR public.is_owner_of_business(business_id)));



  create policy "business_hours_owner_write"
  on "public"."business_hours"
  as permissive
  for insert
  to public
with check ((public.is_admin() OR public.is_owner_of_business(business_id)));



  create policy "business_hours_select_public"
  on "public"."business_hours"
  as permissive
  for select
  to anon, authenticated
using (true);



  create policy "business_meal_card_providers_owner_delete"
  on "public"."business_meal_card_providers"
  as permissive
  for delete
  to public
using ((public.is_admin() OR public.is_owner_of_business(business_id)));



  create policy "business_meal_card_providers_owner_insert"
  on "public"."business_meal_card_providers"
  as permissive
  for insert
  to public
with check ((public.is_admin() OR public.is_owner_of_business(business_id)));



  create policy "business_meal_card_providers_owner_update"
  on "public"."business_meal_card_providers"
  as permissive
  for update
  to public
using ((public.is_admin() OR public.is_owner_of_business(business_id)))
with check ((public.is_admin() OR public.is_owner_of_business(business_id)));



  create policy "business_menu_presentation_settings_delete_manage"
  on "public"."business_menu_presentation_settings"
  as permissive
  for delete
  to authenticated
using (public.can_manage_business_v1(business_id));



  create policy "business_menu_presentation_settings_insert_manage"
  on "public"."business_menu_presentation_settings"
  as permissive
  for insert
  to authenticated
with check (public.can_manage_business_v1(business_id));



  create policy "business_menu_presentation_settings_update_manage"
  on "public"."business_menu_presentation_settings"
  as permissive
  for update
  to authenticated
using (public.can_manage_business_v1(business_id))
with check (public.can_manage_business_v1(business_id));



  create policy "business_merge_log_admin_only_policy"
  on "public"."business_merge_log"
  as permissive
  for all
  to authenticated
using (COALESCE(public.is_admin(), false))
with check (COALESCE(public.is_admin(), false));



  create policy "business_perks_select_policy"
  on "public"."business_perks"
  as permissive
  for select
  to authenticated, anon
using (((status = 'active'::text) OR COALESCE(public.is_admin(), false) OR COALESCE(public.can_access_business_v1(business_id), false)));



  create policy "business_perks_write_policy"
  on "public"."business_perks"
  as permissive
  for all
  to authenticated
using ((COALESCE(public.is_admin(), false) OR COALESCE(public.can_access_business_v1(business_id), false)))
with check ((COALESCE(public.is_admin(), false) OR COALESCE(public.can_access_business_v1(business_id), false)));



  create policy "business_policy_acceptances_insert_owned"
  on "public"."business_policy_acceptances"
  as permissive
  for insert
  to authenticated
with check (((user_id = auth.uid()) AND public.can_manage_business_v1(business_id)));



  create policy "business_policy_acceptances_select_owned"
  on "public"."business_policy_acceptances"
  as permissive
  for select
  to authenticated
using ((public.is_admin() OR (user_id = auth.uid()) OR public.can_manage_business_v1(business_id)));



  create policy "business_premium_admin_all"
  on "public"."business_premium"
  as permissive
  for all
  to public
using (public.is_admin())
with check (public.is_admin());



  create policy "business_presence_admin_select"
  on "public"."business_presence_events"
  as permissive
  for select
  to public
using (public.is_admin());



  create policy "business_pricing_rules_write_policy"
  on "public"."business_pricing_rules"
  as permissive
  for all
  to authenticated
using ((COALESCE(public.is_admin(), false) OR COALESCE(public.can_access_business_v1(business_id), false)))
with check ((COALESCE(public.is_admin(), false) OR COALESCE(public.can_access_business_v1(business_id), false)));



  create policy "stories_owner_admin_delete"
  on "public"."business_stories"
  as permissive
  for delete
  to authenticated
using ((public.is_admin() OR public.is_owner_of_business(business_id)));



  create policy "stories_owner_admin_insert"
  on "public"."business_stories"
  as permissive
  for insert
  to authenticated
with check ((public.is_admin() OR public.is_owner_of_business(business_id)));



  create policy "stories_owner_admin_update"
  on "public"."business_stories"
  as permissive
  for update
  to authenticated
using ((public.is_admin() OR public.is_owner_of_business(business_id)))
with check ((public.is_admin() OR public.is_owner_of_business(business_id)));



  create policy "business_submissions_admin_all"
  on "public"."business_submissions"
  as permissive
  for all
  to public
using (public.is_admin())
with check (public.is_admin());



  create policy "business_suggestions_select_public_or_owner_admin"
  on "public"."business_suggestions"
  as permissive
  for select
  to public
using (((status = 'approved'::text) OR (user_id = auth.uid()) OR public.is_admin()));



  create policy "business_suggestions_update_admin"
  on "public"."business_suggestions"
  as permissive
  for update
  to authenticated
using (public.is_admin())
with check (public.is_admin());



  create policy "business_team_memberships_admin_all"
  on "public"."business_team_memberships"
  as permissive
  for all
  to authenticated
using (public.is_admin())
with check (public.is_admin());



  create policy "business_team_memberships_self_read"
  on "public"."business_team_memberships"
  as permissive
  for select
  to authenticated
using ((public.is_admin() OR (user_id = auth.uid())));



  create policy "businesses_delete_admin"
  on "public"."businesses"
  as permissive
  for delete
  to authenticated
using (public.is_admin());



  create policy "businesses_insert_admin"
  on "public"."businesses"
  as permissive
  for insert
  to authenticated
with check (public.is_admin());



  create policy "businesses_update_owner_admin"
  on "public"."businesses"
  as permissive
  for update
  to authenticated
using ((public.is_admin() OR public.is_owner_of_business(id)))
with check ((public.is_admin() OR public.is_owner_of_business(id)));



  create policy "chain_memberships_admin_all"
  on "public"."chain_memberships"
  as permissive
  for all
  to authenticated
using (public.is_admin())
with check (public.is_admin());



  create policy "chain_memberships_owner_read"
  on "public"."chain_memberships"
  as permissive
  for select
  to authenticated
using (((user_id = auth.uid()) OR public.is_admin()));



  create policy "collection_items_owner_delete"
  on "public"."collection_items"
  as permissive
  for delete
  to public
using ((EXISTS ( SELECT 1
   FROM public.collections c
  WHERE ((c.id = collection_items.collection_id) AND (c.user_id = auth.uid())))));



  create policy "collection_items_owner_insert"
  on "public"."collection_items"
  as permissive
  for insert
  to public
with check ((EXISTS ( SELECT 1
   FROM public.collections c
  WHERE ((c.id = collection_items.collection_id) AND (c.user_id = auth.uid())))));



  create policy "collection_items_select_access"
  on "public"."collection_items"
  as permissive
  for select
  to public
using ((EXISTS ( SELECT 1
   FROM public.collections c
  WHERE ((c.id = collection_items.collection_id) AND ((c.user_id = ( SELECT auth.uid() AS uid)) OR (c.is_public = true))))));



  create policy "edge_ip_denylist_admin_all"
  on "public"."edge_ip_denylist"
  as permissive
  for all
  to public
using (public.is_admin())
with check (public.is_admin());



  create policy "edge_rate_limit_events_admin_all"
  on "public"."edge_rate_limit_events"
  as permissive
  for all
  to authenticated
using (public.is_admin())
with check (public.is_admin());



  create policy "embeds_delete_owner_admin"
  on "public"."embeds"
  as permissive
  for delete
  to public
using ((public.is_admin() OR ((owner_type = 'user'::text) AND (owner_id = auth.uid()) AND (created_by = auth.uid())) OR ((owner_type = 'business'::text) AND public.is_owner_of_business(owner_id))));



  create policy "embeds_insert_business_owner_admin"
  on "public"."embeds"
  as permissive
  for insert
  to public
with check (((auth.uid() IS NOT NULL) AND (owner_type = 'business'::text) AND (created_by = auth.uid()) AND (public.is_admin() OR public.is_owner_of_business(owner_id))));



  create policy "embeds_update_owner_admin"
  on "public"."embeds"
  as permissive
  for update
  to public
using ((public.is_admin() OR ((owner_type = 'user'::text) AND (owner_id = auth.uid()) AND (created_by = auth.uid())) OR ((owner_type = 'business'::text) AND public.is_owner_of_business(owner_id))))
with check ((public.is_admin() OR ((owner_type = 'user'::text) AND (owner_id = auth.uid()) AND (created_by = auth.uid())) OR ((owner_type = 'business'::text) AND public.is_owner_of_business(owner_id))));



  create policy "feed_events_admin_select"
  on "public"."feed_events"
  as permissive
  for select
  to public
using (public.is_admin());



  create policy "group_offers_business_insert"
  on "public"."group_offers"
  as permissive
  for insert
  to public
with check ((public.is_admin() OR public.is_owner_of_business(business_id)));



  create policy "group_offers_business_select"
  on "public"."group_offers"
  as permissive
  for select
  to public
using ((public.is_admin() OR public.is_owner_of_business(business_id) OR (EXISTS ( SELECT 1
   FROM public.group_requests r
  WHERE ((r.id = group_offers.request_id) AND (r.created_by = auth.uid()))))));



  create policy "group_offers_business_update"
  on "public"."group_offers"
  as permissive
  for update
  to public
using ((public.is_admin() OR public.is_owner_of_business(business_id)))
with check ((public.is_admin() OR public.is_owner_of_business(business_id)));



  create policy "group_requests_owner_insert"
  on "public"."group_requests"
  as permissive
  for insert
  to public
with check (((created_by = auth.uid()) OR public.is_admin()));



  create policy "group_requests_owner_select"
  on "public"."group_requests"
  as permissive
  for select
  to public
using (((created_by = auth.uid()) OR public.is_admin()));



  create policy "group_requests_owner_update"
  on "public"."group_requests"
  as permissive
  for update
  to public
using (((created_by = auth.uid()) OR public.is_admin()))
with check (((created_by = auth.uid()) OR public.is_admin()));



  create policy "import_places_stage_admin_all"
  on "public"."import_places_stage"
  as permissive
  for all
  to public
using (public.is_admin())
with check (public.is_admin());



  create policy "incident_updates_admin_delete"
  on "public"."incident_updates"
  as permissive
  for delete
  to public
using (public.is_admin());



  create policy "incident_updates_admin_insert"
  on "public"."incident_updates"
  as permissive
  for insert
  to public
with check (public.is_admin());



  create policy "incident_updates_admin_update"
  on "public"."incident_updates"
  as permissive
  for update
  to public
using (public.is_admin())
with check (public.is_admin());



  create policy "meal_card_providers_admin_delete"
  on "public"."meal_card_providers"
  as permissive
  for delete
  to public
using (public.is_admin());



  create policy "meal_card_providers_admin_insert"
  on "public"."meal_card_providers"
  as permissive
  for insert
  to public
with check (public.is_admin());



  create policy "meal_card_providers_admin_update"
  on "public"."meal_card_providers"
  as permissive
  for update
  to public
using (public.is_admin())
with check (public.is_admin());



  create policy "menu_categories_owner_all"
  on "public"."menu_categories"
  as permissive
  for all
  to authenticated
using ((public.is_admin() OR public.is_owner_of_business(business_id)))
with check ((public.is_admin() OR public.is_owner_of_business(business_id)));



  create policy "menu_categories_public_read"
  on "public"."menu_categories"
  as permissive
  for select
  to public
using (((is_active = true) AND (EXISTS ( SELECT 1
   FROM public.businesses b
  WHERE ((b.id = menu_categories.business_id) AND (b.is_active = true))))));



  create policy "owner_read_allergens"
  on "public"."menu_item_allergens"
  as permissive
  for select
  to public
using ((EXISTS ( SELECT 1
   FROM (((public.menu_items mi
     JOIN public.menu_sections ms ON ((ms.id = mi.section_id)))
     JOIN public.menus m ON ((m.id = ms.menu_id)))
     JOIN public.owner_claims oc ON ((oc.business_id = m.business_id)))
  WHERE ((mi.id = menu_item_allergens.item_id) AND (oc.user_id = auth.uid()) AND (oc.status = 'approved'::text)))));



  create policy "nutrition_owner_select"
  on "public"."menu_item_nutrition"
  as permissive
  for select
  to public
using ((EXISTS ( SELECT 1
   FROM (public.menu_items mi
     JOIN public.owner_claims oc ON ((oc.business_id = mi.business_id)))
  WHERE ((mi.id = menu_item_nutrition.item_id) AND (oc.user_id = auth.uid()) AND (oc.status = 'approved'::text)))));



  create policy "menu_item_photo_votes_admin_all"
  on "public"."menu_item_photo_votes"
  as permissive
  for all
  to authenticated
using (public.is_admin())
with check (public.is_admin());



  create policy "menu_item_photos_read"
  on "public"."menu_item_photos"
  as permissive
  for select
  to public
using ((EXISTS ( SELECT 1
   FROM public.menu_items mi
  WHERE ((mi.id = menu_item_photos.menu_item_id) AND ((mi.is_available = true) OR public.is_admin() OR public.is_owner_of_business(mi.business_id))))));



  create policy "price_hist_admin_delete"
  on "public"."menu_item_price_history"
  as permissive
  for delete
  to authenticated
using (public.is_admin());



  create policy "price_hist_admin_insert"
  on "public"."menu_item_price_history"
  as permissive
  for insert
  to authenticated
with check (public.is_admin());



  create policy "price_hist_admin_update"
  on "public"."menu_item_price_history"
  as permissive
  for update
  to authenticated
using (public.is_admin())
with check (public.is_admin());



  create policy "price_sugg_delete_admin"
  on "public"."menu_item_price_suggestions"
  as permissive
  for delete
  to authenticated
using (public.is_admin());



  create policy "price_sugg_delete_own_pending"
  on "public"."menu_item_price_suggestions"
  as permissive
  for delete
  to authenticated
using (((created_by = auth.uid()) AND (status = 'pending'::public.menu_price_suggestion_status)));



  create policy "price_sugg_insert_auth"
  on "public"."menu_item_price_suggestions"
  as permissive
  for insert
  to authenticated
with check ((public.is_admin() OR (created_by = ( SELECT auth.uid() AS uid))));



  create policy "price_sugg_select_public_or_actor"
  on "public"."menu_item_price_suggestions"
  as permissive
  for select
  to public
using ((((status)::text = 'approved'::text) OR (created_by = auth.uid()) OR public.is_admin() OR public.is_owner_of_business(business_id)));



  create policy "price_sugg_update_admin"
  on "public"."menu_item_price_suggestions"
  as permissive
  for update
  to authenticated
using (public.is_admin())
with check (public.is_admin());



  create policy "price_sugg_update_own_pending"
  on "public"."menu_item_price_suggestions"
  as permissive
  for update
  to authenticated
using (((created_by = auth.uid()) AND (status = 'pending'::public.menu_price_suggestion_status)))
with check (((created_by = auth.uid()) AND (status = 'pending'::public.menu_price_suggestion_status)));



  create policy "menu_item_price_votes_admin_all"
  on "public"."menu_item_price_votes"
  as permissive
  for all
  to authenticated
using (public.is_admin())
with check (public.is_admin());



  create policy "menu_item_suggestions_read_owner_admin"
  on "public"."menu_item_suggestions"
  as permissive
  for select
  to public
using ((public.is_admin() OR public.is_owner_of_business(business_id) OR (created_by = auth.uid())));



  create policy "menu_item_suggestions_update_owner_admin"
  on "public"."menu_item_suggestions"
  as permissive
  for update
  to public
using ((public.is_admin() OR public.is_owner_of_business(business_id)))
with check ((public.is_admin() OR public.is_owner_of_business(business_id)));



  create policy "menu_item_variants_owner_all"
  on "public"."menu_item_variants"
  as permissive
  for all
  to authenticated
using ((public.is_admin() OR (EXISTS ( SELECT 1
   FROM public.menu_items mi
  WHERE ((mi.id = menu_item_variants.menu_item_id) AND public.is_owner_of_business(mi.business_id))))))
with check ((public.is_admin() OR (EXISTS ( SELECT 1
   FROM public.menu_items mi
  WHERE ((mi.id = menu_item_variants.menu_item_id) AND public.is_owner_of_business(mi.business_id))))));



  create policy "menu_item_variants_public_read"
  on "public"."menu_item_variants"
  as permissive
  for select
  to public
using (((is_available = true) AND (EXISTS ( SELECT 1
   FROM (public.menu_items mi
     JOIN public.businesses b ON ((b.id = mi.business_id)))
  WHERE ((mi.id = menu_item_variants.menu_item_id) AND (b.is_active = true))))));



  create policy "menu_items_owner_delete"
  on "public"."menu_items"
  as permissive
  for delete
  to authenticated
using ((public.is_admin() OR public.is_owner_of_business(business_id)));



  create policy "menu_items_owner_insert"
  on "public"."menu_items"
  as permissive
  for insert
  to authenticated
with check ((public.is_admin() OR public.is_owner_of_business(business_id)));



  create policy "menu_items_owner_update"
  on "public"."menu_items"
  as permissive
  for update
  to authenticated
using ((public.is_admin() OR public.is_owner_of_business(business_id)))
with check ((public.is_admin() OR public.is_owner_of_business(business_id)));



  create policy "menu_items_read"
  on "public"."menu_items"
  as permissive
  for select
  to public
using (((is_available = true) OR public.is_admin() OR public.is_owner_of_business(business_id)));



  create policy "menu_sections_owner_delete"
  on "public"."menu_sections"
  as permissive
  for delete
  to authenticated
using ((EXISTS ( SELECT 1
   FROM public.menus m
  WHERE ((m.id = menu_sections.menu_id) AND (public.is_admin() OR public.is_owner_of_business(m.business_id))))));



  create policy "menu_sections_owner_insert"
  on "public"."menu_sections"
  as permissive
  for insert
  to authenticated
with check ((EXISTS ( SELECT 1
   FROM public.menus m
  WHERE ((m.id = menu_sections.menu_id) AND (public.is_admin() OR public.is_owner_of_business(m.business_id))))));



  create policy "menu_sections_owner_update"
  on "public"."menu_sections"
  as permissive
  for update
  to authenticated
using ((EXISTS ( SELECT 1
   FROM public.menus m
  WHERE ((m.id = menu_sections.menu_id) AND (public.is_admin() OR public.is_owner_of_business(m.business_id))))))
with check ((EXISTS ( SELECT 1
   FROM public.menus m
  WHERE ((m.id = menu_sections.menu_id) AND (public.is_admin() OR public.is_owner_of_business(m.business_id))))));



  create policy "menu_sections_read"
  on "public"."menu_sections"
  as permissive
  for select
  to public
using ((EXISTS ( SELECT 1
   FROM public.menus m
  WHERE ((m.id = menu_sections.menu_id) AND ((m.status = 'published'::public.menu_status) OR public.is_admin() OR public.is_owner_of_business(m.business_id))))));



  create policy "menu_translations_owner_all"
  on "public"."menu_translations"
  as permissive
  for all
  to authenticated
using ((public.is_admin() OR (((entity_type = 'business'::public.translation_entity_type) AND public.is_owner_of_business(entity_id)) OR ((entity_type = 'category'::public.translation_entity_type) AND (EXISTS ( SELECT 1
   FROM public.menu_categories c
  WHERE ((c.id = menu_translations.entity_id) AND public.is_owner_of_business(c.business_id))))) OR ((entity_type = 'item'::public.translation_entity_type) AND (EXISTS ( SELECT 1
   FROM public.menu_items i
  WHERE ((i.id = menu_translations.entity_id) AND public.is_owner_of_business(i.business_id))))))))
with check ((public.is_admin() OR (((entity_type = 'business'::public.translation_entity_type) AND public.is_owner_of_business(entity_id)) OR ((entity_type = 'category'::public.translation_entity_type) AND (EXISTS ( SELECT 1
   FROM public.menu_categories c
  WHERE ((c.id = menu_translations.entity_id) AND public.is_owner_of_business(c.business_id))))) OR ((entity_type = 'item'::public.translation_entity_type) AND (EXISTS ( SELECT 1
   FROM public.menu_items i
  WHERE ((i.id = menu_translations.entity_id) AND public.is_owner_of_business(i.business_id))))))));



  create policy "menus_owner_delete"
  on "public"."menus"
  as permissive
  for delete
  to authenticated
using ((public.is_admin() OR public.is_owner_of_business(business_id)));



  create policy "menus_owner_insert"
  on "public"."menus"
  as permissive
  for insert
  to authenticated
with check ((public.is_admin() OR public.is_owner_of_business(business_id)));



  create policy "menus_owner_update"
  on "public"."menus"
  as permissive
  for update
  to authenticated
using ((public.is_admin() OR public.is_owner_of_business(business_id)))
with check ((public.is_admin() OR public.is_owner_of_business(business_id)));



  create policy "menus_read_published"
  on "public"."menus"
  as permissive
  for select
  to public
using (((status = 'published'::public.menu_status) OR public.is_admin() OR public.is_owner_of_business(business_id)));



  create policy "appeals_select_owner_or_mod_v1"
  on "public"."moderation_appeals"
  as permissive
  for select
  to authenticated
using (((auth.uid() = appellant_user_id) OR public.is_admin_or_community_mod_v1()));



  create policy "appeals_update_mod_only_v1"
  on "public"."moderation_appeals"
  as permissive
  for update
  to authenticated
using (public.is_admin_or_community_mod_v1())
with check (public.is_admin_or_community_mod_v1());



  create policy "notification_dispatch_jobs_admin_policy"
  on "public"."notification_dispatch_jobs"
  as permissive
  for all
  to authenticated
using (COALESCE(public.is_admin(), false))
with check (COALESCE(public.is_admin(), false));



  create policy "offer_messages_insert"
  on "public"."offer_messages"
  as permissive
  for insert
  to public
with check ((public.is_admin() OR (EXISTS ( SELECT 1
   FROM public.group_requests r
  WHERE ((r.id = offer_messages.request_id) AND (r.created_by = auth.uid())))) OR ((business_id IS NOT NULL) AND public.is_owner_of_business(business_id))));



  create policy "offer_messages_read"
  on "public"."offer_messages"
  as permissive
  for select
  to public
using ((public.is_admin() OR (EXISTS ( SELECT 1
   FROM public.group_requests r
  WHERE ((r.id = offer_messages.request_id) AND (r.created_by = auth.uid())))) OR ((business_id IS NOT NULL) AND public.is_owner_of_business(business_id))));



  create policy "owner_claims_select_access"
  on "public"."owner_claims"
  as permissive
  for select
  to authenticated
using (((user_id = ( SELECT auth.uid() AS uid)) OR public.is_admin()));



  create policy "owner_claims_update_admin"
  on "public"."owner_claims"
  as permissive
  for update
  to authenticated
using (public.is_admin())
with check (public.is_admin());



  create policy "owner_onboarding_progress_owner_read"
  on "public"."owner_onboarding_progress"
  as permissive
  for select
  to public
using ((public.is_admin() OR public.is_owner_of_business(business_id)));



  create policy "owner_onboarding_progress_owner_update"
  on "public"."owner_onboarding_progress"
  as permissive
  for update
  to public
using ((public.is_admin() OR public.is_owner_of_business(business_id)))
with check ((public.is_admin() OR public.is_owner_of_business(business_id)));



  create policy "owner_onboarding_progress_owner_write"
  on "public"."owner_onboarding_progress"
  as permissive
  for insert
  to public
with check ((public.is_admin() OR public.is_owner_of_business(business_id)));



  create policy "policy_versions_admin_write"
  on "public"."policy_versions"
  as permissive
  for all
  to authenticated
using (public.is_admin())
with check (public.is_admin());



  create policy "policy_versions_read_all"
  on "public"."policy_versions"
  as permissive
  for select
  to anon, authenticated
using (true);



  create policy "privacy_requests_select_own"
  on "public"."privacy_requests"
  as permissive
  for select
  to authenticated
using ((public.is_admin() OR (user_id = auth.uid())));



  create policy "receipt_matches_admin_all"
  on "public"."receipt_matches"
  as permissive
  for all
  to public
using (public.is_admin());



  create policy "receipt_matches_owner_insert"
  on "public"."receipt_matches"
  as permissive
  for insert
  to public
with check ((EXISTS ( SELECT 1
   FROM public.receipt_submissions s
  WHERE ((s.id = receipt_matches.receipt_id) AND (s.user_id = auth.uid())))));



  create policy "receipt_matches_owner_select"
  on "public"."receipt_matches"
  as permissive
  for select
  to public
using ((EXISTS ( SELECT 1
   FROM public.receipt_submissions s
  WHERE ((s.id = receipt_matches.receipt_id) AND (s.user_id = auth.uid())))));



  create policy "receipt_submissions_admin_all"
  on "public"."receipt_submissions"
  as permissive
  for all
  to public
using (public.is_admin());



  create policy "reports_delete_admin"
  on "public"."reports"
  as permissive
  for delete
  to authenticated
using (public.is_admin());



  create policy "reports_select_admin"
  on "public"."reports"
  as permissive
  for select
  to authenticated
using (public.is_admin());



  create policy "reports_update_admin"
  on "public"."reports"
  as permissive
  for update
  to authenticated
using (public.is_admin())
with check (public.is_admin());



  create policy "review_votes_admin_all"
  on "public"."review_votes"
  as permissive
  for all
  to authenticated
using (public.is_admin())
with check (public.is_admin());



  create policy "reviews_delete_admin"
  on "public"."reviews"
  as permissive
  for delete
  to authenticated
using (public.is_admin());



  create policy "reviews_select_access"
  on "public"."reviews"
  as permissive
  for select
  to public
using (((status = 'approved'::text) OR (user_id = ( SELECT auth.uid() AS uid)) OR public.is_admin()));



  create policy "reviews_update_admin"
  on "public"."reviews"
  as permissive
  for update
  to authenticated
using (public.is_admin())
with check (public.is_admin());



  create policy "runtime_experiments_admin_write"
  on "public"."runtime_experiments"
  as permissive
  for all
  to authenticated
using (COALESCE(public.is_admin(), false))
with check (COALESCE(public.is_admin(), false));



  create policy "runtime_feature_flags_admin_write"
  on "public"."runtime_feature_flags"
  as permissive
  for all
  to authenticated
using (COALESCE(public.is_admin(), false))
with check (COALESCE(public.is_admin(), false));



  create policy "runtime_release_controls_admin_write"
  on "public"."runtime_release_controls"
  as permissive
  for all
  to authenticated
using (COALESCE(public.is_admin(), false))
with check (COALESCE(public.is_admin(), false));



  create policy "sponsorship_impressions_admin_all"
  on "public"."sponsorship_impressions_daily"
  as permissive
  for all
  to public
using (public.is_admin())
with check (public.is_admin());



  create policy "sponsorship_leads_delete_admin"
  on "public"."sponsorship_leads"
  as permissive
  for delete
  to authenticated
using (public.is_admin());



  create policy "sponsorship_leads_insert_access"
  on "public"."sponsorship_leads"
  as permissive
  for insert
  to authenticated
with check ((public.is_admin() OR (owner_user_id = ( SELECT auth.uid() AS uid))));



  create policy "sponsorship_leads_select_access"
  on "public"."sponsorship_leads"
  as permissive
  for select
  to public
using ((public.is_admin() OR (owner_user_id = ( SELECT auth.uid() AS uid))));



  create policy "sponsorship_leads_update_admin"
  on "public"."sponsorship_leads"
  as permissive
  for update
  to authenticated
using (public.is_admin())
with check (public.is_admin());



  create policy "sponsorship_packages_admin_all"
  on "public"."sponsorship_packages"
  as permissive
  for all
  to public
using (public.is_admin())
with check (public.is_admin());



  create policy "sponsorships_admin_all"
  on "public"."sponsorships"
  as permissive
  for all
  to public
using (public.is_admin())
with check (public.is_admin());



  create policy "storage_deletion_queue_admin_select"
  on "public"."storage_deletion_queue"
  as permissive
  for select
  to authenticated
using (COALESCE(public.is_admin(), false));



  create policy "storage_deletion_queue_admin_write"
  on "public"."storage_deletion_queue"
  as permissive
  for all
  to authenticated
using (COALESCE(public.is_admin(), false))
with check (COALESCE(public.is_admin(), false));



  create policy "claims_select_access"
  on "public"."suspended_meal_claims"
  as permissive
  for select
  to public
using ((public.is_admin() OR (claimant_user_id = ( SELECT auth.uid() AS uid)) OR public.is_owner_of_business(( SELECT m.business_id
   FROM public.suspended_meals m
  WHERE (m.id = suspended_meal_claims.suspended_meal_id)))));



  create policy "claims_update_owner_admin"
  on "public"."suspended_meal_claims"
  as permissive
  for update
  to authenticated
using ((public.is_admin() OR public.is_owner_of_business(( SELECT m.business_id
   FROM public.suspended_meals m
  WHERE (m.id = suspended_meal_claims.suspended_meal_id)))))
with check ((public.is_admin() OR public.is_owner_of_business(( SELECT m.business_id
   FROM public.suspended_meals m
  WHERE (m.id = suspended_meal_claims.suspended_meal_id)))));



  create policy "meals_admin_delete"
  on "public"."suspended_meals"
  as permissive
  for delete
  to authenticated
using (public.is_admin());



  create policy "meals_admin_insert"
  on "public"."suspended_meals"
  as permissive
  for insert
  to authenticated
with check (public.is_admin());



  create policy "meals_admin_update"
  on "public"."suspended_meals"
  as permissive
  for update
  to authenticated
using (public.is_admin())
with check (public.is_admin());



  create policy "meals_select_access"
  on "public"."suspended_meals"
  as permissive
  for select
  to public
using ((public.is_admin() OR (donor_user_id = ( SELECT auth.uid() AS uid)) OR ((status = 'active'::public.suspended_meal_status) AND (expires_at > now()))));



  create policy "table_feedback_admin_select"
  on "public"."table_feedback"
  as permissive
  for select
  to public
using (public.is_admin());



  create policy "user_device_fingerprints_admin_all"
  on "public"."user_device_fingerprints"
  as permissive
  for all
  to authenticated
using (public.is_admin())
with check (public.is_admin());



  create policy "user_mission_claims_admin_all"
  on "public"."user_mission_claims"
  as permissive
  for all
  to public
using (public.is_admin());



  create policy "user_moderation_strikes_admin_write_policy"
  on "public"."user_moderation_strikes"
  as permissive
  for all
  to authenticated
using (COALESCE(public.is_admin(), false))
with check (COALESCE(public.is_admin(), false));



  create policy "user_moderation_strikes_select_policy"
  on "public"."user_moderation_strikes"
  as permissive
  for select
  to authenticated
using (((user_id = auth.uid()) OR COALESCE(public.is_admin(), false)));



  create policy "user_points_admin_all"
  on "public"."user_points"
  as permissive
  for all
  to public
using (public.is_admin());



  create policy "user_policy_acceptances_select_own"
  on "public"."user_policy_acceptances"
  as permissive
  for select
  to authenticated
using ((public.is_admin() OR (user_id = auth.uid())));



  create policy "user_rate_limits_admin_all"
  on "public"."user_rate_limits"
  as permissive
  for all
  to public
using (public.is_admin())
with check (public.is_admin());



  create policy "user_risk_signals_admin_all"
  on "public"."user_risk_signals"
  as permissive
  for all
  to authenticated
using (public.is_admin())
with check (public.is_admin());



  create policy "user_safety_actions_admin_all"
  on "public"."user_safety_actions"
  as permissive
  for all
  to authenticated
using (public.is_admin())
with check (public.is_admin());


CREATE TRIGGER trg_account_deletion_requests_capture_request_metadata_v1 BEFORE INSERT ON public.account_deletion_requests FOR EACH ROW EXECUTE FUNCTION public.capture_request_metadata_v1();

CREATE TRIGGER trg_notify_price_alert_event_v1 AFTER INSERT ON public.alert_events FOR EACH ROW EXECUTE FUNCTION public.trg_notify_price_alert_event_v1();

CREATE TRIGGER trg_analytics_events_privacy_v1 BEFORE INSERT OR UPDATE OF meta ON public.analytics_events FOR EACH ROW EXECUTE FUNCTION public.trg_analytics_events_privacy_v1();

CREATE TRIGGER trg_recompute_achievements_analytics_v1 AFTER INSERT ON public.analytics_events FOR EACH ROW EXECUTE FUNCTION public.trg_recompute_achievements_analytics_v1();

CREATE TRIGGER trg_business_activity_log_feed AFTER INSERT ON public.business_activity_log FOR EACH ROW EXECUTE FUNCTION public.handle_business_activity_log_feed();

CREATE TRIGGER trg_business_media_require_verified_contact_v1 BEFORE INSERT ON public.business_media FOR EACH ROW EXECUTE FUNCTION public.trg_require_verified_contact_v1();

CREATE TRIGGER trg_business_menu_presentation_settings_touch_v1 BEFORE UPDATE ON public.business_menu_presentation_settings FOR EACH ROW EXECUTE FUNCTION public.touch_updated_at_v1();

CREATE TRIGGER trg_business_perks_feed AFTER INSERT OR UPDATE ON public.business_perks FOR EACH ROW EXECUTE FUNCTION public.handle_business_perk_feed();

CREATE TRIGGER trg_business_policy_acceptances_capture_request_metadata_v1 BEFORE INSERT ON public.business_policy_acceptances FOR EACH ROW EXECUTE FUNCTION public.capture_request_metadata_v1();

CREATE TRIGGER trg_assign_business_public_slug_v2 BEFORE INSERT OR UPDATE OF name, slug, public_slug ON public.businesses FOR EACH ROW EXECUTE FUNCTION public._assign_business_public_slug_v2();

CREATE TRIGGER trg_audit_businesses_update_v1 AFTER UPDATE ON public.businesses FOR EACH ROW EXECUTE FUNCTION public.trg_audit_businesses_update_v1();

CREATE TRIGGER trg_businesses_sync_geog BEFORE INSERT OR UPDATE OF lat, lng ON public.businesses FOR EACH ROW EXECUTE FUNCTION public.tg_businesses_sync_geog();

CREATE TRIGGER trg_businesses_sync_search_tsv BEFORE INSERT OR UPDATE OF name, category, address, city, district ON public.businesses FOR EACH ROW EXECUTE FUNCTION public.tg_businesses_sync_search_tsv();

CREATE TRIGGER trg_menu_item_photos_abuse_controls_v1 BEFORE INSERT ON public.menu_item_photos FOR EACH ROW EXECUTE FUNCTION public.enforce_abuse_controls_on_menu_photos_v1();

CREATE TRIGGER trg_menu_item_photos_delete_edge_guard_v1 BEFORE DELETE ON public.menu_item_photos FOR EACH ROW EXECUTE FUNCTION public.enforce_menu_item_photos_delete_edge_guard_v1();

CREATE TRIGGER trg_menu_item_photos_edge_guard_v1 BEFORE INSERT ON public.menu_item_photos FOR EACH ROW EXECUTE FUNCTION public.enforce_menu_item_photos_edge_guard_v1();

CREATE TRIGGER trg_menu_item_photos_require_verified_contact_v1 BEFORE INSERT ON public.menu_item_photos FOR EACH ROW EXECUTE FUNCTION public.trg_require_verified_contact_v1();

CREATE TRIGGER trg_recompute_achievements_menu_photos_v1 AFTER INSERT ON public.menu_item_photos FOR EACH ROW EXECUTE FUNCTION public.trg_recompute_achievements_menu_photos_v1();

CREATE TRIGGER trg_price_alerts_history AFTER INSERT ON public.menu_item_price_history FOR EACH ROW EXECUTE FUNCTION public.handle_price_alerts_for_history_v1();

CREATE TRIGGER trg_menu_item_price_suggestions_rate_limit_v1 BEFORE INSERT ON public.menu_item_price_suggestions FOR EACH ROW EXECUTE FUNCTION public.enforce_price_suggestion_insert_rate_limits_v1();

CREATE TRIGGER trg_notify_owner_new_price_suggestion_v1 AFTER INSERT ON public.menu_item_price_suggestions FOR EACH ROW EXECUTE FUNCTION public.trg_notify_owner_new_price_suggestion_v1();

CREATE TRIGGER trg_notify_price_suggestion_result_v1 AFTER UPDATE ON public.menu_item_price_suggestions FOR EACH ROW EXECUTE FUNCTION public.trg_notify_price_suggestion_result_v1();

CREATE TRIGGER trg_price_suggestions_abuse_controls_v1 BEFORE INSERT ON public.menu_item_price_suggestions FOR EACH ROW EXECUTE FUNCTION public.enforce_abuse_controls_on_price_suggestions_v1();

CREATE TRIGGER trg_price_suggestions_collect_risk_signals_v1 BEFORE INSERT ON public.menu_item_price_suggestions FOR EACH ROW EXECUTE FUNCTION public.collect_risk_signals_on_price_suggestions_v1();

CREATE TRIGGER trg_price_suggestions_edge_guard_v1 BEFORE INSERT ON public.menu_item_price_suggestions FOR EACH ROW EXECUTE FUNCTION public.enforce_price_suggestions_edge_guard_v1();

CREATE TRIGGER trg_price_suggestions_require_verified_contact_v1 BEFORE INSERT ON public.menu_item_price_suggestions FOR EACH ROW EXECUTE FUNCTION public.trg_require_verified_contact_v1();

CREATE TRIGGER trg_recompute_achievements_price_suggestions_v1 AFTER INSERT OR UPDATE OF status ON public.menu_item_price_suggestions FOR EACH ROW EXECUTE FUNCTION public.trg_recompute_achievements_price_suggestions_v1();

CREATE TRIGGER menu_items_activity_log_trg AFTER INSERT OR DELETE OR UPDATE ON public.menu_items FOR EACH ROW EXECUTE FUNCTION public.trg_log_menu_item_activity();

CREATE TRIGGER trg_audit_menu_items_cud_v1 AFTER INSERT OR DELETE OR UPDATE ON public.menu_items FOR EACH ROW EXECUTE FUNCTION public.trg_audit_menu_items_cud_v1();

CREATE TRIGGER trg_menu_items_assign_section BEFORE INSERT OR UPDATE OF section_id, business_id ON public.menu_items FOR EACH ROW EXECUTE FUNCTION public.menu_items_assign_section_v1();

CREATE TRIGGER trg_menu_items_new_feed AFTER INSERT ON public.menu_items FOR EACH ROW EXECUTE FUNCTION public.handle_menu_item_new_feed();

CREATE TRIGGER trg_menu_items_owner_price_history_v1 AFTER UPDATE OF price_cents, currency ON public.menu_items FOR EACH ROW EXECUTE FUNCTION public.trg_menu_items_owner_price_history_v1();

CREATE TRIGGER menu_sections_activity_log_trg AFTER INSERT OR DELETE OR UPDATE ON public.menu_sections FOR EACH ROW EXECUTE FUNCTION public.trg_log_menu_section_activity();

CREATE TRIGGER trg_audit_menus_cud_v1 AFTER INSERT OR DELETE OR UPDATE ON public.menus FOR EACH ROW EXECUTE FUNCTION public.trg_audit_menus_cud_v1();

CREATE TRIGGER trg_menus_versioning_v1 BEFORE INSERT OR UPDATE ON public.menus FOR EACH ROW EXECUTE FUNCTION public.bump_menu_version_v1();

CREATE TRIGGER trg_notification_dispatch_jobs_touch_v1 BEFORE UPDATE ON public.notification_dispatch_jobs FOR EACH ROW EXECUTE FUNCTION public.touch_updated_at_v1();

CREATE TRIGGER trg_enqueue_notification_dispatch_v1 AFTER INSERT ON public.notifications FOR EACH ROW EXECUTE FUNCTION public.enqueue_notification_dispatch_v1();

CREATE TRIGGER trg_audit_owner_claims_update_v1 AFTER UPDATE ON public.owner_claims FOR EACH ROW EXECUTE FUNCTION public.trg_audit_owner_claims_update_v1();

CREATE TRIGGER trg_privacy_requests_capture_request_metadata_v1 BEFORE INSERT ON public.privacy_requests FOR EACH ROW EXECUTE FUNCTION public.capture_request_metadata_v1();

CREATE TRIGGER trg_audit_reports_update_v1 AFTER UPDATE ON public.reports FOR EACH ROW EXECUTE FUNCTION public.trg_audit_reports_update_v1();

CREATE TRIGGER trg_auto_moderate_report AFTER INSERT ON public.reports FOR EACH ROW EXECUTE FUNCTION public.trg_auto_moderate_report_v1();

CREATE TRIGGER trg_hide_reported_business_media_v1 AFTER INSERT ON public.reports FOR EACH ROW EXECUTE FUNCTION public.trg_hide_reported_business_media_v1();

CREATE TRIGGER trg_hide_reported_menu_photo_v1 AFTER INSERT ON public.reports FOR EACH ROW EXECUTE FUNCTION public.trg_hide_reported_menu_photo_v1();

CREATE TRIGGER trg_notify_owner_reported_v1 AFTER INSERT ON public.reports FOR EACH ROW EXECUTE FUNCTION public.trg_notify_owner_reported_v1();

CREATE TRIGGER trg_recompute_achievements_reports_v1 AFTER INSERT ON public.reports FOR EACH ROW EXECUTE FUNCTION public.trg_recompute_achievements_reports_v1();

CREATE TRIGGER trg_reports_edge_guard_v1 BEFORE INSERT ON public.reports FOR EACH ROW EXECUTE FUNCTION public.enforce_reports_edge_guard_v1();

CREATE TRIGGER trg_review_votes_del AFTER DELETE ON public.review_votes FOR EACH ROW EXECUTE FUNCTION public.recalc_review_helpful_count();

CREATE TRIGGER trg_review_votes_edge_guard_delete_v1 BEFORE DELETE ON public.review_votes FOR EACH ROW EXECUTE FUNCTION public.enforce_review_votes_edge_guard_v1();

CREATE TRIGGER trg_review_votes_edge_guard_insert_v1 BEFORE INSERT ON public.review_votes FOR EACH ROW EXECUTE FUNCTION public.enforce_review_votes_edge_guard_v1();

CREATE TRIGGER trg_review_votes_helpful_count AFTER INSERT OR DELETE ON public.review_votes FOR EACH ROW EXECUTE FUNCTION public.tg_review_votes_sync_helpful_count();

CREATE TRIGGER trg_review_votes_ins AFTER INSERT ON public.review_votes FOR EACH ROW EXECUTE FUNCTION public.recalc_review_helpful_count();

CREATE TRIGGER trg_business_stats_reviews AFTER INSERT OR DELETE OR UPDATE ON public.reviews FOR EACH ROW EXECUTE FUNCTION public.tg_business_stats_apply_review_change();

CREATE TRIGGER trg_notify_owner_new_review_v1 AFTER INSERT ON public.reviews FOR EACH ROW EXECUTE FUNCTION public.trg_notify_owner_new_review_v1();

CREATE TRIGGER trg_recompute_achievements_reviews_v1 AFTER INSERT ON public.reviews FOR EACH ROW EXECUTE FUNCTION public.trg_recompute_achievements_reviews_v1();

CREATE TRIGGER trg_reviews_abuse_controls_v1 BEFORE INSERT ON public.reviews FOR EACH ROW EXECUTE FUNCTION public.enforce_abuse_controls_on_reviews_v1();

CREATE TRIGGER trg_reviews_collect_risk_signals_v1 BEFORE INSERT ON public.reviews FOR EACH ROW EXECUTE FUNCTION public.collect_risk_signals_on_reviews_v1();

CREATE TRIGGER trg_reviews_edge_guard_v1 BEFORE INSERT ON public.reviews FOR EACH ROW EXECUTE FUNCTION public.enforce_reviews_edge_guard_v1();

CREATE TRIGGER trg_reviews_rate_limit_v1 BEFORE INSERT ON public.reviews FOR EACH ROW EXECUTE FUNCTION public.enforce_review_insert_rate_limits_v1();

CREATE TRIGGER trg_reviews_require_verified_contact_v1 BEFORE INSERT ON public.reviews FOR EACH ROW EXECUTE FUNCTION public.trg_require_verified_contact_v1();

CREATE TRIGGER trg_reviews_sync_overall_rating_v1 BEFORE INSERT OR UPDATE ON public.reviews FOR EACH ROW EXECUTE FUNCTION public.sync_review_overall_rating_v1();

CREATE TRIGGER trg_user_policy_acceptances_capture_request_metadata_v1 BEFORE INSERT ON public.user_policy_acceptances FOR EACH ROW EXECUTE FUNCTION public.capture_request_metadata_v1();

CREATE TRIGGER trg_audit_user_ban_toggle_v1 AFTER UPDATE OF shadow_banned ON public.user_profiles FOR EACH ROW EXECUTE FUNCTION public.trg_audit_user_ban_toggle_v1();

CREATE TRIGGER trg_user_profiles_minimize_v1 BEFORE INSERT OR UPDATE OF display_name, bio ON public.user_profiles FOR EACH ROW EXECUTE FUNCTION public.trg_user_profiles_minimize_v1();

CREATE TRIGGER trg_visits_edge_guard_delete_v1 BEFORE DELETE ON public.visits FOR EACH ROW EXECUTE FUNCTION public.enforce_visits_edge_guard_v1();

CREATE TRIGGER trg_visits_edge_guard_insert_v1 BEFORE INSERT ON public.visits FOR EACH ROW EXECUTE FUNCTION public.enforce_visits_edge_guard_v1();

CREATE TRIGGER trg_auth_users_anonymize_v1 BEFORE DELETE ON auth.users FOR EACH ROW EXECUTE FUNCTION public.trg_auth_users_anonymize_v1();


  create policy "menu_media_delete_own_or_admin"
  on "storage"."objects"
  as permissive
  for delete
  to authenticated
using (((bucket_id = 'menu-media'::text) AND ((owner = auth.uid()) OR public.is_admin())));



  create policy "menu_media_insert_auth"
  on "storage"."objects"
  as permissive
  for insert
  to authenticated
with check (((bucket_id = 'menu-media'::text) AND (owner = auth.uid()) AND (name ~~ 'business/%'::text) AND ((lower(name) ~~ '%.jpg'::text) OR (lower(name) ~~ '%.jpeg'::text) OR (lower(name) ~~ '%.png'::text) OR (lower(name) ~~ '%.webp'::text))));



  create policy "menu_media_private_delete_owner_admin"
  on "storage"."objects"
  as permissive
  for delete
  to authenticated
using (((bucket_id = 'menu-media-private'::text) AND ((owner = auth.uid()) OR public.is_admin())));



  create policy "menu_media_private_insert_auth"
  on "storage"."objects"
  as permissive
  for insert
  to authenticated
with check (((bucket_id = 'menu-media-private'::text) AND (owner = auth.uid()) AND (name ~~ 'critical/business/%'::text) AND ((lower(name) ~~ '%.jpg'::text) OR (lower(name) ~~ '%.jpeg'::text) OR (lower(name) ~~ '%.png'::text) OR (lower(name) ~~ '%.webp'::text))));



  create policy "menu_media_private_read_owner_admin"
  on "storage"."objects"
  as permissive
  for select
  to authenticated
using (((bucket_id = 'menu-media-private'::text) AND ((owner = auth.uid()) OR public.is_admin())));



  create policy "menu_media_private_update_owner_admin"
  on "storage"."objects"
  as permissive
  for update
  to authenticated
using (((bucket_id = 'menu-media-private'::text) AND ((owner = auth.uid()) OR public.is_admin())))
with check (((bucket_id = 'menu-media-private'::text) AND ((owner = auth.uid()) OR public.is_admin())));



  create policy "menu_media_read_all"
  on "storage"."objects"
  as permissive
  for select
  to public
using ((bucket_id = 'menu-media'::text));



  create policy "menu_media_update_own_or_admin"
  on "storage"."objects"
  as permissive
  for update
  to authenticated
using (((bucket_id = 'menu-media'::text) AND ((owner = auth.uid()) OR public.is_admin())))
with check (((bucket_id = 'menu-media'::text) AND ((owner = auth.uid()) OR public.is_admin())));



