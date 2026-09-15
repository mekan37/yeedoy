-- Canlı Supabase Güvenlik & Bütünlük Denetimi P2-1: 150+ tabloda grant
-- katmanında sıfır savunma derinliği — anon/authenticated'a tablo seviyesinde
-- INSERT/UPDATE/DELETE grant'i verilmiş ama karşılık gelen RLS politikası
-- hiç yok. RLS her tabloda açık (spatial_ref_sys istisnası hariç, PostGIS
-- sistem tablosu) — yani bu grant'ler şu an TAMAMEN ETKİSİZ (RLS zaten
-- reddediyor), tek risk "RLS bir şekilde bozulursa/devre dışı kalırsa" tek
-- savunma katmanının kalmaması.
--
-- Liste, canlıdan üretildi: information_schema.role_table_grants ∩
-- pg_policies (rol+komut eşleşmesi olmayan satırlar). RLS'i devre dışı olan
-- (spatial_ref_sys) ve base-table olmayan (view/matview) nesneler kapsam
-- dışı bırakıldı. business_media üzerinde manuel doğrulandı: yalnızca
-- DELETE(authenticated)+SELECT(public) politikası var, INSERT/UPDATE hiç
-- yok — yazmalar add_business_media_v1 RPC'si (SECURITY DEFINER, RLS'i
-- bypass eder) üzerinden geçiyor, ham tablo grant'i gerçekten kullanılmıyor.
--
-- Davranış değişikliği YOK — yalnızca zaten-engellenen erişim yollarının
-- grant katmanındaki kalıntısı kapatılıyor.

revoke DELETE, INSERT, UPDATE on public.account_deletion_requests from anon;
revoke DELETE, UPDATE on public.account_deletion_requests from authenticated;
revoke DELETE, INSERT, UPDATE on public.achievements from anon;
revoke DELETE, INSERT, UPDATE on public.achievements from authenticated;
revoke DELETE, INSERT, UPDATE on public.admin_alert_rules from anon;
revoke DELETE, INSERT, UPDATE on public.admin_alert_rules from authenticated;
revoke DELETE, INSERT, UPDATE on public.admin_roles from anon;
revoke DELETE, INSERT, UPDATE on public.admin_roles from authenticated;
revoke DELETE, INSERT, UPDATE on public.admin_runtime_settings from anon;
revoke DELETE, UPDATE on public.alert_events from anon;
revoke DELETE, UPDATE on public.alert_events from authenticated;
revoke DELETE, INSERT, UPDATE on public.allergen_ingredient_aliases from anon;
revoke DELETE, INSERT, UPDATE on public.allergen_ingredient_aliases from authenticated;
revoke DELETE, INSERT, UPDATE on public.allergens from anon;
revoke DELETE, INSERT, UPDATE on public.allergens from authenticated;
revoke DELETE, INSERT, UPDATE on public.analytics_events from anon;
revoke DELETE, INSERT, UPDATE on public.api_keys from anon;
revoke DELETE, UPDATE on public.audit_logs from anon;
revoke DELETE, UPDATE on public.audit_logs from authenticated;
revoke DELETE, INSERT, UPDATE on public.bulk_op_logs from anon;
revoke DELETE, INSERT, UPDATE on public.business_activity_log from anon;
revoke DELETE, INSERT, UPDATE on public.business_activity_log from authenticated;
revoke DELETE, INSERT, UPDATE on public.business_amenities from anon;
revoke DELETE, INSERT, UPDATE on public.business_amenity_map from anon;
revoke DELETE, INSERT, UPDATE on public.business_checkins from anon;
revoke DELETE, INSERT, UPDATE on public.business_fee_flags from anon;
revoke DELETE, UPDATE on public.business_fee_votes from anon;
revoke DELETE, INSERT, UPDATE on public.business_follows from anon;
revoke DELETE, INSERT, UPDATE on public.business_hours from anon;
revoke DELETE on public.business_hours from authenticated;
revoke DELETE, INSERT, UPDATE on public.business_meal_card_providers from anon;
revoke DELETE, INSERT, UPDATE on public.business_media from anon;
revoke INSERT, UPDATE on public.business_media from authenticated;
revoke DELETE, INSERT, UPDATE on public.business_menu_presentation_settings from anon;
revoke DELETE, INSERT, UPDATE on public.business_merge_log from anon;
revoke DELETE, INSERT, UPDATE on public.business_perks from anon;
revoke DELETE, INSERT, UPDATE on public.business_policy_acceptances from anon;
revoke DELETE, UPDATE on public.business_policy_acceptances from authenticated;
revoke DELETE, INSERT, UPDATE on public.business_premium from anon;
revoke DELETE, INSERT, UPDATE on public.business_presence_events from anon;
revoke DELETE, INSERT, UPDATE on public.business_presence_events from authenticated;
revoke DELETE, INSERT, UPDATE on public.business_pricing_rules from anon;
revoke DELETE, INSERT, UPDATE on public.business_qr_codes from anon;
revoke DELETE, INSERT, UPDATE on public.business_stats from anon;
revoke DELETE, INSERT, UPDATE on public.business_stats from authenticated;
revoke DELETE, INSERT, UPDATE on public.business_stories from anon;
revoke DELETE, UPDATE on public.business_submissions from anon;
revoke DELETE, INSERT, UPDATE on public.business_suggestions from anon;
revoke INSERT on public.business_suggestions from authenticated;
revoke DELETE, INSERT, UPDATE on public.business_team_memberships from anon;
revoke DELETE, INSERT, UPDATE on public.businesses from anon;
revoke DELETE, INSERT, UPDATE on public.campaigns from anon;
revoke DELETE, INSERT, UPDATE on public.chain_item_overrides from anon;
revoke DELETE, INSERT, UPDATE on public.chain_memberships from anon;
revoke DELETE, INSERT, UPDATE on public.chains from anon;
revoke DELETE, INSERT, UPDATE on public.chains from authenticated;
revoke DELETE, INSERT, UPDATE on public.city_search_aliases from anon;
revoke UPDATE on public.collab_list_items from anon;
revoke UPDATE on public.collab_list_items from authenticated;
revoke UPDATE on public.collab_list_members from anon;
revoke UPDATE on public.collab_list_members from authenticated;
revoke UPDATE on public.collection_items from anon;
revoke UPDATE on public.collection_items from authenticated;
revoke DELETE, UPDATE on public.collection_shares from anon;
revoke DELETE, UPDATE on public.collection_shares from authenticated;
revoke DELETE, INSERT, UPDATE on public.collection_social_stats from anon;
revoke DELETE, INSERT, UPDATE on public.collection_social_stats from authenticated;
revoke DELETE, INSERT, UPDATE on public.edge_rate_limit_events from anon;
revoke DELETE, UPDATE on public.email_campaigns from anon;
revoke DELETE, INSERT, UPDATE on public.exchange_rates from anon;
revoke DELETE, INSERT, UPDATE on public.exchange_rates from authenticated;
revoke DELETE, INSERT, UPDATE on public.favorites from anon;
revoke UPDATE on public.favorites from authenticated;
revoke DELETE, INSERT, UPDATE on public.feed_events from anon;
revoke DELETE, INSERT, UPDATE on public.feed_events from authenticated;
revoke DELETE, INSERT, UPDATE on public.food_catalog_categories from anon;
revoke DELETE, INSERT, UPDATE on public.food_catalog_categories from authenticated;
revoke DELETE, INSERT, UPDATE on public.food_catalog_items from anon;
revoke DELETE, INSERT, UPDATE on public.food_catalog_items from authenticated;
revoke DELETE, INSERT, UPDATE on public.food_image_prompts from anon;
revoke DELETE, INSERT, UPDATE on public.food_image_prompts from authenticated;
revoke UPDATE on public.group_offer_votes from anon;
revoke UPDATE on public.group_offer_votes from authenticated;
revoke DELETE on public.group_offers from anon;
revoke DELETE on public.group_offers from authenticated;
revoke DELETE on public.group_requests from anon;
revoke DELETE on public.group_requests from authenticated;
revoke DELETE, INSERT, UPDATE on public.legal_documents from anon;
revoke DELETE, INSERT, UPDATE on public.legal_documents from authenticated;
revoke DELETE, INSERT, UPDATE on public.menu_categories from anon;
revoke DELETE, UPDATE on public.menu_feedback from anon;
revoke DELETE, UPDATE on public.menu_feedback from authenticated;
revoke DELETE, INSERT, UPDATE on public.menu_item_ai_analysis from anon;
revoke DELETE, INSERT, UPDATE on public.menu_item_allergens from anon;
revoke DELETE, INSERT, UPDATE on public.menu_item_allergens from authenticated;
revoke DELETE, INSERT, UPDATE on public.menu_item_diet_tags from anon;
revoke DELETE, INSERT, UPDATE on public.menu_item_diet_tags from authenticated;
revoke DELETE, INSERT, UPDATE on public.menu_item_ingredients from anon;
revoke DELETE, INSERT, UPDATE on public.menu_item_ingredients from authenticated;
revoke DELETE, INSERT, UPDATE on public.menu_item_nutrition from anon;
revoke DELETE, INSERT, UPDATE on public.menu_item_nutrition from authenticated;
revoke DELETE, UPDATE on public.menu_item_photos from anon;
revoke DELETE, UPDATE on public.menu_item_photos from authenticated;
revoke DELETE, INSERT, UPDATE on public.menu_item_price_history from anon;
revoke DELETE, INSERT, UPDATE on public.menu_item_price_suggestions from anon;
revoke DELETE on public.menu_item_suggestions from anon;
revoke DELETE on public.menu_item_suggestions from authenticated;
-- menu_item_translations: 20260428000001_business_staff_rls.sql'nin kendi
-- yorumuna göre "hiç oluşturulmadı" — uygulama bunun yerine genel
-- menu_translations tablosunu kullanıyor (2026-07-23'te zaten tespit edilip
-- koşullu hale getirilmiş, ölü/legacy). Canlıda hâlâ var (elle oluşturulmuş
-- kalıntı) ama local'de yok — aynı to_regclass koruması burada da kullanıldı.
DO $$
BEGIN
  IF to_regclass('public.menu_item_translations') IS NOT NULL THEN
    EXECUTE 'revoke DELETE, INSERT, UPDATE on public.menu_item_translations from anon';
    EXECUTE 'revoke DELETE on public.menu_item_translations from authenticated';
  END IF;
END
$$;
revoke DELETE, INSERT, UPDATE on public.menu_item_variant_groups from anon;
revoke DELETE, INSERT, UPDATE on public.menu_item_variant_groups from authenticated;
revoke DELETE, INSERT, UPDATE on public.menu_item_variant_options from anon;
revoke DELETE, INSERT, UPDATE on public.menu_item_variant_options from authenticated;
revoke DELETE, INSERT, UPDATE on public.menu_item_variants from anon;
revoke DELETE, INSERT, UPDATE on public.menu_items from anon;
revoke DELETE, INSERT, UPDATE on public.menu_ocr_jobs from anon;
revoke DELETE, INSERT, UPDATE on public.menu_sections from anon;
revoke DELETE, INSERT, UPDATE on public.menu_translations from anon;
revoke DELETE, INSERT, UPDATE on public.menus from anon;
revoke DELETE, INSERT, UPDATE on public.moderation_appeals from anon;
revoke DELETE on public.moderation_appeals from authenticated;
revoke DELETE, INSERT, UPDATE on public.moderation_decision_templates from anon;
revoke DELETE, INSERT, UPDATE on public.moderation_decision_templates from authenticated;
revoke DELETE, INSERT, UPDATE on public.notification_dispatch_jobs from anon;
revoke DELETE, INSERT, UPDATE on public.notification_preferences from anon;
revoke DELETE on public.notification_preferences from authenticated;
revoke DELETE, INSERT, UPDATE on public.notifications from anon;
revoke DELETE, INSERT on public.notifications from authenticated;
revoke DELETE, UPDATE on public.offer_messages from anon;
revoke DELETE, UPDATE on public.offer_messages from authenticated;
revoke DELETE, INSERT, UPDATE on public.osm_admin_boundaries from anon;
revoke DELETE, INSERT, UPDATE on public.osm_admin_boundaries from authenticated;
revoke DELETE, INSERT, UPDATE on public.owner_claims from anon;
revoke DELETE on public.owner_onboarding_progress from anon;
revoke DELETE on public.owner_onboarding_progress from authenticated;
revoke DELETE, INSERT, UPDATE on public.photo_missions from anon;
revoke DELETE, INSERT, UPDATE on public.photo_missions from authenticated;
revoke DELETE, INSERT, UPDATE on public.plan_feature_usage from anon;
revoke DELETE, INSERT, UPDATE on public.plan_feature_usage from authenticated;
revoke DELETE, INSERT, UPDATE on public.policy_versions from anon;
revoke DELETE, INSERT, UPDATE on public.privacy_requests from anon;
revoke DELETE, UPDATE on public.privacy_requests from authenticated;
revoke DELETE, INSERT, UPDATE on public.push_campaigns from anon;
revoke DELETE, INSERT, UPDATE on public.rate_limit_counters from anon;
revoke DELETE, INSERT, UPDATE on public.rate_limit_counters from authenticated;
revoke DELETE, INSERT, UPDATE on public.regional_cuisine_tags from anon;
revoke DELETE, INSERT, UPDATE on public.regional_cuisine_tags from authenticated;
revoke DELETE, INSERT, UPDATE on public.regional_recommendation_events from anon;
revoke DELETE, INSERT, UPDATE on public.regional_recommendation_events from authenticated;
revoke DELETE, INSERT, UPDATE on public.reports from anon;
revoke DELETE, INSERT, UPDATE on public.reservations from anon;
revoke DELETE, INSERT, UPDATE on public.review_photos from anon;
revoke UPDATE on public.review_photos from authenticated;
revoke DELETE, INSERT, UPDATE on public.review_tags from anon;
revoke DELETE, INSERT, UPDATE on public.review_tags from authenticated;
revoke DELETE, INSERT, UPDATE on public.review_votes from anon;
revoke DELETE, INSERT, UPDATE on public.runtime_experiments from anon;
revoke DELETE, INSERT, UPDATE on public.runtime_feature_flags from anon;
revoke DELETE, INSERT, UPDATE on public.runtime_release_controls from anon;
revoke UPDATE on public.saved_campaigns from anon;
revoke UPDATE on public.saved_campaigns from authenticated;
revoke DELETE, INSERT, UPDATE on public.sponsorship_leads from anon;
revoke DELETE, INSERT, UPDATE on public.stock_dish_images from anon;
revoke DELETE, INSERT, UPDATE on public.stock_dish_images from authenticated;
revoke DELETE, INSERT, UPDATE on public.storage_deletion_queue from anon;
revoke DELETE, INSERT, UPDATE on public.support_ticket_messages from anon;
revoke DELETE, INSERT, UPDATE on public.support_tickets from anon;
revoke DELETE, INSERT, UPDATE on public.suspended_meal_claims from anon;
revoke DELETE, INSERT on public.suspended_meal_claims from authenticated;
revoke DELETE, INSERT, UPDATE on public.suspended_meals from anon;
revoke DELETE, INSERT, UPDATE on public.table_feedback from anon;
revoke DELETE, INSERT, UPDATE on public.table_feedback from authenticated;
revoke DELETE, INSERT, UPDATE on public.temp_uploads from anon;
revoke DELETE, INSERT, UPDATE on public.user_achievement_awards from anon;
revoke DELETE, INSERT, UPDATE on public.user_achievement_awards from authenticated;
revoke DELETE, INSERT, UPDATE on public.user_achievements from anon;
revoke DELETE, INSERT, UPDATE on public.user_achievements from authenticated;
revoke UPDATE on public.user_collection_follows from anon;
revoke UPDATE on public.user_collection_follows from authenticated;
revoke DELETE, INSERT, UPDATE on public.user_device_fingerprints from anon;
revoke DELETE, INSERT, UPDATE on public.user_devices from anon;
revoke DELETE, INSERT, UPDATE on public.user_moderation_strikes from anon;
revoke DELETE, INSERT, UPDATE on public.user_policy_acceptances from anon;
revoke DELETE, UPDATE on public.user_policy_acceptances from authenticated;
revoke DELETE, INSERT, UPDATE on public.user_profile_progress from anon;
revoke DELETE, INSERT, UPDATE on public.user_profile_progress from authenticated;
revoke DELETE, INSERT, UPDATE on public.user_profiles from anon;
revoke DELETE, INSERT, UPDATE on public.user_referrals from anon;
revoke DELETE, INSERT, UPDATE on public.user_referrals from authenticated;
revoke DELETE, INSERT, UPDATE on public.user_risk_signals from anon;
revoke DELETE, INSERT, UPDATE on public.user_safety_actions from anon;
