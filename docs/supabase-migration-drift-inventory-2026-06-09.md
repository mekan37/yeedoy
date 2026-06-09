# Supabase Migration Drift Envanteri — 2026-06-09

## Özet
- Local migration sayısı: 108 aktif dosya (`supabase/migrations`); `git ls-files` archive dahil 290 kayıt döndürüyor.
- Remote applied migration sayısı: 95
- Matching migration sayısı: 64
- Remote-only migration sayısı: 31
- Local-only migration sayısı: 44
- Remote liste alınabildi mi: Evet, `supabase migration list` başarılı döndü.
- Connection/auth hatası var mı: Bu kontrolde yok. Önceki kontrolde görülen `ECIRCUITBREAKER / too many authentication failures` bu çalıştırmada tekrarlanmadı.

## Remote-only Migrationlar
| Version | Remote’da var | Local dosya var mı | Git geçmişinde bulundu mu | Silinmiş/rename edilmiş mi | Muhtemel sebep | Öneri |
|---|---|---|---|---|---|---|
| `20260515133138` | Evet | Hayır | Hayır | Hayır | Remote'a repo dışından uygulanmış migration history kaydı | İçeriği ve kaynağı bulunmadan `repair` çalıştırma |
| `20260515133207` | Evet | Hayır | Hayır | Hayır | Remote'a repo dışından uygulanmış migration history kaydı | İçeriği ve kaynağı bulunmadan `repair` çalıştırma |
| `20260515144203` | Evet | Hayır | Hayır | Hayır | Remote'a repo dışından uygulanmış migration history kaydı | İçeriği ve kaynağı bulunmadan `repair` çalıştırma |
| `20260515144919` | Evet | Hayır | Hayır | Hayır | Remote'a repo dışından uygulanmış migration history kaydı | İçeriği ve kaynağı bulunmadan `repair` çalıştırma |
| `20260515155342` | Evet | Hayır | Hayır | Hayır | Remote'a repo dışından uygulanmış migration history kaydı | İçeriği ve kaynağı bulunmadan `repair` çalıştırma |
| `20260516061601` | Evet | Hayır | Hayır | Hayır | Remote'a repo dışından uygulanmış migration history kaydı | İçeriği ve kaynağı bulunmadan `repair` çalıştırma |
| `20260516061848` | Evet | Hayır | Hayır | Hayır | Remote'a repo dışından uygulanmış migration history kaydı | İçeriği ve kaynağı bulunmadan `repair` çalıştırma |
| `20260516062016` | Evet | Hayır | Hayır | Hayır | Remote'a repo dışından uygulanmış migration history kaydı | İçeriği ve kaynağı bulunmadan `repair` çalıştırma |
| `20260516070305` | Evet | Hayır | Hayır | Hayır | Remote'a repo dışından uygulanmış migration history kaydı | İçeriği ve kaynağı bulunmadan `repair` çalıştırma |
| `20260516072004` | Evet | Hayır | Hayır | Hayır | Remote'a repo dışından uygulanmış migration history kaydı | İçeriği ve kaynağı bulunmadan `repair` çalıştırma |
| `20260516074319` | Evet | Hayır | Hayır | Hayır | Remote'a repo dışından uygulanmış migration history kaydı | İçeriği ve kaynağı bulunmadan `repair` çalıştırma |
| `20260518061541` | Evet | Hayır | Hayır | Hayır | Remote'a repo dışından uygulanmış migration history kaydı | İçeriği ve kaynağı bulunmadan `repair` çalıştırma |
| `20260518062116` | Evet | Hayır | Hayır | Hayır | Remote'a repo dışından uygulanmış migration history kaydı | İçeriği ve kaynağı bulunmadan `repair` çalıştırma |
| `20260518094023` | Evet | Hayır | Hayır | Hayır | Remote'a repo dışından uygulanmış migration history kaydı | İçeriği ve kaynağı bulunmadan `repair` çalıştırma |
| `20260518095042` | Evet | Hayır | Hayır | Hayır | Remote'a repo dışından uygulanmış migration history kaydı | İçeriği ve kaynağı bulunmadan `repair` çalıştırma |
| `20260518095331` | Evet | Hayır | Hayır | Hayır | Remote'a repo dışından uygulanmış migration history kaydı | İçeriği ve kaynağı bulunmadan `repair` çalıştırma |
| `20260518130718` | Evet | Hayır | Hayır | Hayır | Remote'a repo dışından uygulanmış migration history kaydı | İçeriği ve kaynağı bulunmadan `repair` çalıştırma |
| `20260518130830` | Evet | Hayır | Hayır | Hayır | Remote'a repo dışından uygulanmış migration history kaydı | İçeriği ve kaynağı bulunmadan `repair` çalıştırma |
| `20260518145644` | Evet | Hayır | Hayır | Hayır | Remote'a repo dışından uygulanmış migration history kaydı | İçeriği ve kaynağı bulunmadan `repair` çalıştırma |
| `20260520131128` | Evet | Hayır | Hayır | Hayır | Remote'a repo dışından uygulanmış migration history kaydı | İçeriği ve kaynağı bulunmadan `repair` çalıştırma |
| `20260520133611` | Evet | Hayır | Hayır | Hayır | Remote'a repo dışından uygulanmış migration history kaydı | İçeriği ve kaynağı bulunmadan `repair` çalıştırma |
| `20260520133814` | Evet | Hayır | Hayır | Hayır | Remote'a repo dışından uygulanmış migration history kaydı | İçeriği ve kaynağı bulunmadan `repair` çalıştırma |
| `20260521143020` | Evet | Hayır | Hayır | Hayır | Remote'a repo dışından uygulanmış migration history kaydı | İçeriği ve kaynağı bulunmadan `repair` çalıştırma |
| `20260523070533` | Evet | Hayır | Hayır | Hayır | Remote'a repo dışından uygulanmış migration history kaydı | İçeriği ve kaynağı bulunmadan `repair` çalıştırma |
| `20260523070554` | Evet | Hayır | Hayır | Hayır | Remote'a repo dışından uygulanmış migration history kaydı | İçeriği ve kaynağı bulunmadan `repair` çalıştırma |
| `20260523070613` | Evet | Hayır | Hayır | Hayır | Remote'a repo dışından uygulanmış migration history kaydı | İçeriği ve kaynağı bulunmadan `repair` çalıştırma |
| `20260523070655` | Evet | Hayır | Hayır | Hayır | Remote'a repo dışından uygulanmış migration history kaydı | İçeriği ve kaynağı bulunmadan `repair` çalıştırma |
| `20260523070730` | Evet | Hayır | Hayır | Hayır | Remote'a repo dışından uygulanmış migration history kaydı | İçeriği ve kaynağı bulunmadan `repair` çalıştırma |
| `20260601135822` | Evet | Hayır | Hayır | Hayır | Remote'a repo dışından uygulanmış migration history kaydı | İçeriği ve kaynağı bulunmadan `repair` çalıştırma |
| `20260601140042` | Evet | Hayır | Hayır | Hayır | Remote'a repo dışından uygulanmış migration history kaydı | İçeriği ve kaynağı bulunmadan `repair` çalıştırma |
| `20260605150838` | Evet | Hayır | Hayır | Hayır | Remote'a repo dışından uygulanmış migration history kaydı | İçeriği ve kaynağı bulunmadan `repair` çalıştırma |

## Local-only Migrationlar
| Version | Dosya | Remote applied mı | Kaynak PR/branch | Production’a uygulanmalı mı | Not |
|---|---|---|---|---|---|
| `20260516000001` | `20260516000001_osm_poi_import_rpc.sql` | Hayır | Belirsiz | Belirsiz | Riskli local-only; production durumunu ayrıca doğrula |
| `20260518000001` | `20260518000001_business_automations.sql` | Hayır | Belirsiz | Belirsiz | Riskli local-only; production durumunu ayrıca doğrula |
| `20260520000001` | `20260520000001_admin_api_keys_support_tickets.sql` | Hayır | Belirsiz | Belirsiz | Riskli local-only; production durumunu ayrıca doğrula |
| `20260520000002` | `20260520000002_harden_public_views.sql` | Hayır | Belirsiz | Belirsiz | Riskli local-only; production durumunu ayrıca doğrula |
| `20260520000003` | `20260520000003_rls_policy_baseline.sql` | Hayır | Belirsiz | Belirsiz | Riskli local-only; production durumunu ayrıca doğrula |
| `20260520000004` | `20260520000004_tighten_menu_feedback_policy.sql` | Hayır | Belirsiz | Belirsiz | Riskli local-only; production durumunu ayrıca doğrula |
| `20260520000005` | `20260520000005_set_function_search_paths.sql` | Hayır | Belirsiz | Belirsiz | Riskli local-only; production durumunu ayrıca doğrula |
| `20260520000006` | `20260520000006_revoke_anon_admin_rpc.sql` | Hayır | Belirsiz | Belirsiz | Riskli local-only; production durumunu ayrıca doğrula |
| `20260520000007` | `20260520000007_revoke_public_admin_rpc.sql` | Hayır | Belirsiz | Belirsiz | Riskli local-only; production durumunu ayrıca doğrula |
| `20260520000008` | `20260520000008_tighten_privileged_rpc_execute.sql` | Hayır | Belirsiz | Belirsiz | Riskli local-only; production durumunu ayrıca doğrula |
| `20260520000009` | `20260520000009_tighten_user_reward_rpc_execute.sql` | Hayır | Belirsiz | Belirsiz | Riskli local-only; production durumunu ayrıca doğrula |
| `20260522000001` | `20260522000001_loyalty_auto_points_on_order.sql` | Hayır | Belirsiz | Belirsiz | Riskli local-only; production durumunu ayrıca doğrula |
| `20260522000002` | `20260522000002_table_orders_staff_note_waiting.sql` | Hayır | Belirsiz | Belirsiz | Riskli local-only; production durumunu ayrıca doğrula |
| `20260522000003` | `20260522000003_table_orders_processed_by.sql` | Hayır | Belirsiz | Belirsiz | Riskli local-only; production durumunu ayrıca doğrula |
| `20260523000001` | `20260523000001_security_rls_to_public_roles.sql` | Hayır | Belirsiz | Belirsiz | Riskli local-only; production durumunu ayrıca doğrula |
| `20260523000002` | `20260523000002_security_rls_new_tables.sql` | Hayır | Belirsiz | Belirsiz | Riskli local-only; production durumunu ayrıca doğrula |
| `20260523000003` | `20260523000003_security_function_search_paths.sql` | Hayır | Belirsiz | Belirsiz | Riskli local-only; production durumunu ayrıca doğrula |
| `20260523000004` | `20260523000004_perf_missing_indexes.sql` | Hayır | Belirsiz | Belirsiz | Riskli local-only; production durumunu ayrıca doğrula |
| `20260523000005` | `20260523000005_perf_rpc_query_fixes.sql` | Hayır | Belirsiz | Belirsiz | Riskli local-only; production durumunu ayrıca doğrula |
| `20260525000001` | `20260525000001_get_dashboard_stats_today_v1.sql` | Hayır | Belirsiz | Belirsiz | Riskli local-only; production durumunu ayrıca doğrula |
| `20260526000001` | `20260526000001_postgis_business_location_index.sql` | Hayır | Belirsiz | Belirsiz | Riskli local-only; production durumunu ayrıca doğrula |
| `20260526000002` | `20260526000002_planned_rpc_stubs.sql` | Hayır | Belirsiz | Belirsiz | Riskli local-only; production durumunu ayrıca doğrula |
| `20260526000003` | `20260526000003_rls_hardening.sql` | Hayır | Belirsiz | Belirsiz | Riskli local-only; production durumunu ayrıca doğrula |
| `20260526000004` | `20260526000004_audit_triggers.sql` | Hayır | Belirsiz | Belirsiz | Riskli local-only; production durumunu ayrıca doğrula |
| `20260526000005` | `20260526000005_permission_rpcs.sql` | Hayır | Belirsiz | Belirsiz | Riskli local-only; production durumunu ayrıca doğrula |
| `20260526000006` | `20260526000006_moderation_queue.sql` | Hayır | Belirsiz | Belirsiz | Riskli local-only; production durumunu ayrıca doğrula |
| `20260526000007` | `20260526000007_consistency_indexes.sql` | Hayır | Belirsiz | Belirsiz | Riskli local-only; production durumunu ayrıca doğrula |
| `20260526000008` | `20260526000008_data_constraints.sql` | Hayır | Belirsiz | Belirsiz | Riskli local-only; production durumunu ayrıca doğrula |
| `20260601` | `20260601_000001_sponsorship_vitrin_package.sql` | Hayır | Belirsiz | Belirsiz | Version formatı `YYYYMMDD_000001`; CLI bunu `20260601` olarak listeliyor |
| `20260603000001` | `20260603000001_business_price_level_column.sql` | Hayır | Belirsiz | Belirsiz | Riskli local-only; production durumunu ayrıca doğrula |
| `20260603000002` | `20260603000002_compute_price_level_rpc.sql` | Hayır | Belirsiz | Belirsiz | Riskli local-only; production durumunu ayrıca doğrula |
| `20260603000003` | `20260603000003_price_level_rls_guard.sql` | Hayır | Belirsiz | Belirsiz | Riskli local-only; production durumunu ayrıca doğrula |
| `20260603000004` | `20260603000004_search_nearby_v3_extend_returns.sql` | Hayır | Belirsiz | Belirsiz | Riskli local-only; production durumunu ayrıca doğrula |
| `20260603000005` | `20260603000005_analytics_events_busy_hours_indexes.sql` | Hayır | Belirsiz | Belirsiz | Riskli local-only; production durumunu ayrıca doğrula |
| `20260603000006` | `20260603000006_business_busy_hours_rpc.sql` | Hayır | Belirsiz | Belirsiz | Riskli local-only; production durumunu ayrıca doğrula |
| `20260603000007` | `20260603000007_business_slug_columns.sql` | Hayır | Belirsiz | Belirsiz | Riskli local-only; production durumunu ayrıca doğrula |
| `20260603000008` | `20260603000008_menu_ocr_engine_deepseek.sql` | Hayır | Belirsiz | Belirsiz | Riskli local-only; production durumunu ayrıca doğrula |
| `20260603000009` | `20260603000009_marketing_automations_rls_owner_claims.sql` | Hayır | Belirsiz | Belirsiz | Riskli local-only; production durumunu ayrıca doğrula |
| `20260603000010` | `20260603000010_fix_estimate_email_segment_v1.sql` | Hayır | Belirsiz | Belirsiz | Riskli local-only; production durumunu ayrıca doğrula |
| `20260603000011` | `20260603000011_user_profiles_social_links.sql` | Hayır | Belirsiz | Belirsiz | Riskli local-only; production durumunu ayrıca doğrula |
| `20260609000001` | `20260609000001_city_search_aliases.sql` | Hayır | PR #95 | Evet, onaydan sonra | Beklenen local-only; alias apply setinin ilk dosyası |
| `20260609000002` | `20260609000002_normalize_tr_location.sql` | Hayır | PR #95 | Evet, onaydan sonra | Beklenen local-only; alias helper |
| `20260609000003` | `20260609000003_update_search_rpcs_city_alias.sql` | Hayır | PR #95 | Evet, onaydan sonra | Beklenen local-only; search RPC update |
| `20260609000004` | `20260609000004_fix_normalize_tr_location_combining_dot.sql` | Hayır | PR #96 | Evet, onaydan sonra | Beklenen local-only; PR #95 helper fix |

Not: PR #94 açık branch'te `20260609000005`, `20260609000006`, `20260609000007` olarak yeniden timestamp'lendi; bu dosyalar main'de olmadıkları için bu main envanterinin local-only listesinde yer almıyor.

## Matching Migrationlar
| Version | Local dosya | Remote applied | Not |
|---|---|---|---|
| `00000000000000` | `00000000000000_base_schema.sql` | Evet | Eşleşiyor |
| `20260414000001` | `20260414000001_menu_item_nutrition.sql` | Evet | Eşleşiyor |
| `20260414000002` | `20260414000002_menu_item_allergens.sql` | Evet | Eşleşiyor |
| `20260414000003` | `20260414000003_menu_item_ingredients.sql` | Evet | Eşleşiyor |
| `20260414000004` | `20260414000004_exchange_rates.sql` | Evet | Eşleşiyor |
| `20260414000005` | `20260414000005_menu_item_variant_groups.sql` | Evet | Eşleşiyor |
| `20260414000006` | `20260414000006_realtime_menu_items.sql` | Evet | Eşleşiyor |
| `20260414000007` | `20260414000007_bulk_import_menu_items.sql` | Evet | Eşleşiyor |
| `20260414000008` | `20260414000008_owner_analytics_hourly_v1.sql` | Evet | Eşleşiyor |
| `20260414000009` | `20260414000009_seed_policy_versions.sql` | Evet | Eşleşiyor |
| `20260414000010` | `20260414000010_fix_capture_request_metadata_trigger.sql` | Evet | Eşleşiyor |
| `20260414000011` | `20260414000011_seed_business_amenities.sql` | Evet | Eşleşiyor |
| `20260416072511` | `20260416072511_remote_schema.sql` | Evet | Eşleşiyor |
| `20260420000001` | `20260420000001_review_photo_support.sql` | Evet | Eşleşiyor |
| `20260420000002` | `20260420000002_review_rating_distribution.sql` | Evet | Eşleşiyor |
| `20260420000003` | `20260420000003_business_claims_compat.sql` | Evet | Eşleşiyor |
| `20260421000001` | `20260421000001_review_replies.sql` | Evet | Eşleşiyor |
| `20260421000002` | `20260421000002_business_review_counts_batch.sql` | Evet | Eşleşiyor |
| `20260421000003` | `20260421000003_category_price_benchmark.sql` | Evet | Eşleşiyor |
| `20260421000004` | `20260421000004_price_alert_savings_body.sql` | Evet | Eşleşiyor |
| `20260421000005` | `20260421000005_review_frequent_tags.sql` | Evet | Eşleşiyor |
| `20260421000006` | `20260421000006_favorite_revisit_reminder.sql` | Evet | Eşleşiyor |
| `20260421000007` | `20260421000007_friend_checkin_notification.sql` | Evet | Eşleşiyor |
| `20260422000001` | `20260422000001_verified_visit_badge.sql` | Evet | Eşleşiyor |
| `20260422000002` | `20260422000002_menu_feedback.sql` | Evet | Eşleşiyor |
| `20260422000003` | `20260422000003_menu_item_time_windows.sql` | Evet | Eşleşiyor |
| `20260422000004` | `20260422000004_weekly_leaderboard.sql` | Evet | Eşleşiyor |
| `20260422000005` | `20260422000005_reviews_sort_verified.sql` | Evet | Eşleşiyor |
| `20260422000006` | `20260422000006_collab_lists.sql` | Evet | Eşleşiyor |
| `20260424000001` | `20260424000001_business_hours.sql` | Evet | Eşleşiyor |
| `20260424000002` | `20260424000002_custom_domains.sql` | Evet | Eşleşiyor |
| `20260424000003` | `20260424000003_scheduled_menu_activation.sql` | Evet | Eşleşiyor |
| `20260424000004` | `20260424000004_menu_item_translation_rpc.sql` | Evet | Eşleşiyor |
| `20260424000005` | `20260424000005_business_social_links.sql` | Evet | Eşleşiyor |
| `20260424000006` | `20260424000006_owner_update_location.sql` | Evet | Eşleşiyor |
| `20260424000007` | `20260424000007_loyalty_program.sql` | Evet | Eşleşiyor |
| `20260424000008` | `20260424000008_push_campaigns.sql` | Evet | Eşleşiyor |
| `20260424000009` | `20260424000009_email_campaigns.sql` | Evet | Eşleşiyor |
| `20260424000010` | `20260424000010_loyalty_automations.sql` | Evet | Eşleşiyor |
| `20260424000011` | `20260424000011_bulk_menu_translations.sql` | Evet | Eşleşiyor |
| `20260427000001` | `20260427000001_menu_section_translation_rpc.sql` | Evet | Eşleşiyor |
| `20260427000002` | `20260427000002_favorites_email_optin.sql` | Evet | Eşleşiyor |
| `20260427000003` | `20260427000003_push_campaign_open_tracking.sql` | Evet | Eşleşiyor |
| `20260427000004` | `20260427000004_item_availability_rpc.sql` | Evet | Eşleşiyor |
| `20260427000005` | `20260427000005_rate_limit_buckets.sql` | Evet | Eşleşiyor |
| `20260428000001` | `20260428000001_business_staff_rls.sql` | Evet | Eşleşiyor |
| `20260504000001` | `20260504000001_audit_logs.sql` | Evet | Eşleşiyor |
| `20260504000002` | `20260504000002_revoke_anon_grants.sql` | Evet | Eşleşiyor |
| `20260506000001` | `20260506000001_review_owner_reply.sql` | Evet | Eşleşiyor |
| `20260506000002` | `20260506000002_delete_user_account.sql` | Evet | Eşleşiyor |
| `20260506000003` | `20260506000003_bildirim_tetikleyicileri.sql` | Evet | Eşleşiyor |
| `20260507000001` | `20260507000001_bugunun_spesiyali.sql` | Evet | Eşleşiyor |
| `20260507000002` | `20260507000002_check_in.sql` | Evet | Eşleşiyor |
| `20260507000003` | `20260507000003_kalori_porsiyon.sql` | Evet | Eşleşiyor |
| `20260507000004` | `20260507000004_arama_konum_populerite.sql` | Evet | Eşleşiyor |
| `20260507000005` | `20260507000005_rakip_fiyat_raporu.sql` | Evet | Eşleşiyor |
| `20260507000006` | `20260507000006_masa_siparisi.sql` | Evet | Eşleşiyor |
| `20260507000007` | `20260507000007_collab_anonim_oy.sql` | Evet | Eşleşiyor |
| `20260507000008` | `20260507000008_sadakat_karti.sql` | Evet | Eşleşiyor |
| `20260507000009` | `20260507000009_yemek_gunlugu.sql` | Evet | Eşleşiyor |
| `20260507000010` | `20260507000010_personel_menu_availability.sql` | Evet | Eşleşiyor |
| `20260507000011` | `20260507000011_personel_kampanya.sql` | Evet | Eşleşiyor |
| `20260515000001` | `20260515000001_osm_sinirlar.sql` | Evet | Eşleşiyor |
| `20260515000002` | `20260515000002_postgis_yakin_arama.sql` | Evet | Eşleşiyor |

## Kritik Bulgular
- Timestamp çakışması var mı: Main'de aktif `20260609000001`-`20260609000004` dosyaları arasında çakışma yok. PR #94 dosyaları açık branch'te `20260609000005`-`20260609000007` olarak düzeltilmiş durumda.
- Remote-only migrationlar local repo’dan neden eksik: Git geçmişindeki migration dosya adlarında veya silinmiş migration kayıtlarında bulunmadı. Bu, remote history'nin repo dışı apply/repair/db pull akışlarından etkilenmiş olabileceğini gösterir; kesin sebep için remote-only migration içeriklerinin kaynağı bulunmalı.
- Local migration klasörü production geçmişini temsil ediyor mu: Hayır. 31 remote-only ve 44 local-only version bulunduğu için `supabase/migrations` klasörü production history'nin tam ve tekil kaynağı değil.
- `supabase db push --dry-run` neden güvenli değil: Remote/local history drift varken dry-run'ın göstereceği apply listesi PR #95/#96 ile sınırlı olmayabilir; önceki dry-run zaten remote-only migration drift uyarısıyla tamamlanmadı.
- Pooler/auth hatası var mı: Bu envanterde `supabase migration list` başarılı oldu. Önceki denemede `ECIRCUITBREAKER / too many authentication failures` görüldüğü için auth/pooler sağlığı production apply öncesi tekrar doğrulanmalı.

## Güvenli Çözüm Seçenekleri

### Seçenek A — Remote-only migration dosyalarını local repo’ya geri kazandır
- Ne zaman doğru: Remote-only version'lar gerçekten production'a uygulanmış schema değişikliklerini temsil ediyor ve içerikleri bulunabiliyorsa.
- Avantaj: Repo yeniden production migration history'nin gerçek kaynağına yaklaşır; `db push --dry-run` daha anlamlı hale gelir.
- Risk: İçerikler yanlış reconstruct edilirse repo geçmişi yanıltıcı olur.
- Yapılacaklar:
  1. Remote-only version'ların hangi işlemle oluştuğunu belirle.
  2. Varsa eski branch, dashboard export, CI artifact veya Supabase project history kaynaklarından SQL içeriklerini bul.
  3. Dosyaları aynı version prefix'leriyle repo'ya geri kazandır.
  4. Sonra yalnızca dry-run ile history uyumunu tekrar kontrol et.

### Seçenek B — Supabase migration repair
- Ne zaman doğru: Remote-only kayıtların schema karşılığı olmadığı veya bilinçli olarak repo dışı/obsolete history kayıtları olduğu kanıtlanırsa.
- Avantaj: Migration history tablosu local repo ile hizalanabilir.
- Risk: Yanlış repair production history'yi bozabilir; gelecekte aynı migration'ların tekrar uygulanmasına veya atlanmasına yol açabilir.
- Neden şu an uygulanmamalı: Remote-only kayıtların gerçek içeriği ve schema etkisi bilinmiyor.

### Seçenek C — Manual SQL apply planı
- Ne zaman doğru: Drift kısa vadede çözülemiyor, ancak belirli migration setinin SQL etkisi bağımsız ve idempotent olarak review edilip production'a kontrollü uygulanmak zorundaysa.
- Avantaj: PR #95/#96 gibi sınırlı migration setleri drift'ten bağımsız uygulanabilir.
- Risk: Supabase migration history otomatik hizalanmaz; sonrasında history kaydı ayrı ve kontrollü ele alınmalıdır.
- Neden dikkatli olunmalı: Manual SQL apply ve history repair ayrı ayrı yanlış yapılırsa aynı değişiklikler tekrar uygulanabilir veya history gerçek schema durumundan kopabilir.

## Önerilen Yol
1. Production apply yapma; `repair`, `migration up`, normal `db push` veya SQL mutation çalıştırma.
2. Remote-only 31 version için kaynak envanteri çıkar: eski branch, CI artifact, Supabase dashboard export, ekip içi apply notları.
3. Local-only 44 version için production schema karşılığı tek tek doğrulanmadan `db push` planlama.
4. PR #95/#96 için kısa vadede gerekiyorsa ayrı, kontrollü manual SQL apply planı tasarla; bu plan history yazımını ayrıca ve açık onayla ele almalı.
5. PR #94 production apply, PR #95/#96 apply + alias smoke test tamamlanmadan beklemeli.

## Kesinlikle Yapılmaması Gerekenler
- `supabase migration repair` kör çalıştırılmamalı.
- Remote-only migrationlar incelenmeden migration history değiştirilmemeli.
- PR #95/#96 production’a drift çözülmeden veya kontrollü manual apply planı onaylanmadan uygulanmamalı.
- PR #94 production’a PR #95/#96 apply + smoke test olmadan uygulanmamalı.
