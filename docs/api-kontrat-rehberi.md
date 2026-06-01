# Yeedoy API Kontrat Rehberi
**Tarih:** 2026-05-26  
**Kapsam:** Supabase RPC, Next.js Route Handler, Supabase Edge Function  
**Durum:** Canlı belge — her yeni endpoint eklendiğinde güncellenmeli

---

## 1. RPC Versiyonlama Kuralları

### 1.1 Adlandırma Standardı

```
{eylem}_{konu}_{versiyon}
```

- **Dil:** İngilizce, snake_case
- **Versiyon:** her yeni RPC `_v1` ile başlar; breaking change `_v2` açar
- **Eylem örnekleri:** `get`, `search`, `submit`, `upsert`, `delete`, `list`, `update`, `admin_`, `owner_`

| Durum | Örnek |
|---|---|
| Doğru | `get_business_reviews_v1` |
| Doğru | `upsert_collab_vote_v1` |
| Doğru | `admin_approve_business_suggestion_v1` |
| Yanlış — camelCase | `getBusinessReviews` |
| Yanlış — Türkçe | `isletme_yorum_getir` |
| Yanlış — versiyon yok | `get_reviews` |

### 1.2 Trigger ve Helper Fonksiyonlar

- Trigger fonksiyonları `tg_` veya `_fn_` öneki alır; versiyonlama zorunlu değildir
- Internal helper'lar `_` öneki alır (`_review_verified_visit`, `_allocate_business_slug_token_v1`)

---

## 2. Breaking Change Politikası

### Neye Breaking Change Denir?

- Mevcut parametre kaldırma veya adı değiştirme
- Dönüş yapısında alan kaldırma
- SECURITY DEFINER → INVOKER değişikliği
- `GRANT` / `REVOKE` kapsamı daraltma

### Politika Kuralları

1. Breaking change → yeni versiyon (`_v1` → `_v2`)
2. Eski versiyon **en az 90 gün** `DEPRECATED` comment ile ayakta kalır
3. Eski versiyona `COMMENT ON FUNCTION ... IS 'DEPRECATED: YYYY-MM-DD, use _v2';` eklenir
4. Dart/TypeScript istemciler yeni versiyona geçtikten sonra eski versiyon kaldırılır
5. Parametre **ekleme** (DEFAULT değerli) breaking change sayılmaz

### Mevcut DEPRECATED Fonksiyonlar

| Fonksiyon | Yerine | Kaldırılabilir (hedef) |
|---|---|---|
| `approve_business_suggestion` | `admin_approve_business_suggestion_v1` | 2026-08-01 |
| `approve_owner_claim` | `admin_approve_owner_claim_v1` | 2026-08-01 |
| `reject_business_suggestion` | `admin_reject_business_suggestion_v1` | 2026-08-01 |
| `create_owner_claim` | `submit_owner_claim_v1` | 2026-08-01 |
| `get_my_profile_stats` | — (versiyon eklenecek) | Belirsiz |
| `get_daily_picks` | — (versiyon eklenecek) | Belirsiz |
| `get_top_businesses` | `get_top_businesses_period_v1` | 2026-08-01 |
| `search_nearby_businesses_v1` | `search_nearby_businesses_v3` | 2026-09-01 |
| `search_nearby_businesses_v2` | `search_nearby_businesses_v3` | 2026-09-01 |
| `admin_list_business_suggestions_v1` | `admin_list_business_suggestions_v3` | 2026-09-01 |
| `nearby_businesses_v2` | `search_nearby_businesses_v3` | 2026-09-01 |

---

## 3. Deprecation Süreci

```sql
-- 1. Eski fonksiyona comment ekle
COMMENT ON FUNCTION public.get_top_businesses IS
  'DEPRECATED 2026-05-26: Yerine get_top_businesses_period_v1 kullanın. '
  'Kaldırma hedefi: 2026-08-01';

-- 2. Yeni migration'da yeni fonksiyonu oluştur
CREATE OR REPLACE FUNCTION public.get_top_businesses_period_v1(...) ...

-- 3. İstemci kodu güncellendikten sonra kaldırma migration'ı yaz
DROP FUNCTION IF EXISTS public.get_top_businesses(text, integer, integer);
```

---

## 4. Hata Kodu Sözlüğü

### 4.1 Supabase RPC SQLSTATE Kodları

| SQLSTATE | Anlamı | Kullanım |
|---|---|---|
| `P0001` | `not_found` | Kayıt bulunamadığında |
| `P0002` | `unauthorized` | Yetki yoksa |
| `P0003` | `validation_error` | Geçersiz parametre |
| `P0004` | `not_implemented` | Stub fonksiyonlarda |

```sql
-- Standart RAISE EXCEPTION örnekleri
RAISE EXCEPTION 'not_found: İşletme bulunamadı'
  USING ERRCODE = 'P0001';

RAISE EXCEPTION 'unauthorized: Bu işlemi yapmaya yetkiniz yok'
  USING ERRCODE = 'P0002';

RAISE EXCEPTION 'validation_error: Geçersiz business_id'
  USING ERRCODE = 'P0003';
```

### 4.2 Next.js Route Handler HTTP Hata Kodları

| HTTP Kodu | `error` Alanı | Durum |
|---|---|---|
| 400 | `invalid_payload`, `invalid_json`, `no_fields_to_update` | İstemci hatası |
| 401 | `unauthorized`, `invalid_secret` | Auth eksik |
| 403 | `forbidden`, `forbidden_role` | Yetki yok |
| 404 | `business_not_found`, `domain_not_found` | Kayıt yok |
| 409 | `already_processing`, `already_completed` | Çakışma |
| 413 | `photo_size_limit_exceeded` | Dosya çok büyük |
| 422 | `no_text_extracted`, `no_items_detected` | İşlenemez içerik |
| 429 | `rate_limited` | Hız sınırı |
| 500 | `fetch_failed`, `insert_failed`, `upload_failed` | Sunucu hatası |
| 503 | `service_unavailable`, `tcmb_unavailable` | Servis kullanılamıyor |

### 4.3 Standart Error Response Formatı

```typescript
// Next.js route handler — standart format
// Basarı
NextResponse.json({ data: T, meta?: ApiMeta }, { status: 200 | 201 });

// Hata
NextResponse.json({ error: string, issues?: Record<string, string[]> }, { status: 4xx | 5xx });

// YANLIS (kullanılmamalı):
NextResponse.json({ message: string });   // 'message' yerine 'error' kullan
NextResponse.json({ ok: false });          // ok: false yerine error alanı kullan
// ISTISNA: /api/feedback ve /api/revalidate { ok: true } döner — backward compat.
```

---

## 5. Request/Response Şablonları

### 5.1 Sayfalandırılmış Liste (Next.js)

```typescript
// GET /api/admin/claims?page=1&page_size=50
// Response:
{
  data: BusinessClaim[],
  meta: {
    total: number,
    page: number,
    page_size: number
  }
}
```

### 5.2 Sayfalandırılmış RPC

```sql
CREATE OR REPLACE FUNCTION public.my_list_rpc_v1(
  p_limit   int DEFAULT 50,
  p_offset  int DEFAULT 0
)
RETURNS TABLE(id uuid, ..., total_count bigint)
-- total_count: COUNT(*) OVER() ile her satırda taşı
```

### 5.3 Tekil Kayıt Başarı

```typescript
// PATCH /api/owner/businesses/[id]
// Response:
{ data: BusinessUpdateResult }
```

### 5.4 Aksiyon Başarı (veri yok)

```typescript
// POST /api/admin/moderation
// Response:
{ data: { action, target_type, target_id, status } }
// VEYA (legacy compat): { ok: true }
```

---

## 6. Mevcut RPC Envanteri

### 6.1 İstatistik

| Kategori | Adet |
|---|---|
| Toplam RPC (migration'lardan) | ~185 |
| `_v1` veya üzeri versiyonlu | ~160 |
| Versiyonsuz (isimlendirme ihlali) | ~25 |
| DEPRECATED comment'li | 3 |
| STUB (implementasyon bekliyor) | 5 |

### 6.2 Admin RPC'leri

| Fonksiyon | Parametreler | Dönüş | Güvenlik |
|---|---|---|---|
| `admin_approve_business_suggestion_v1` | `p_suggestion_id uuid, p_admin_note text` | `jsonb` | SECURITY DEFINER |
| `admin_approve_suspended_claim_v1` | `p_claim_id uuid` | `jsonb` | SECURITY DEFINER |
| `admin_assign_business_suggestion_v1` | `p_suggestion_id uuid` | `jsonb` | SECURITY DEFINER |
| `admin_assign_owner_claim_v1` | `p_claim_id uuid` | `jsonb` | SECURITY DEFINER |
| `admin_assign_report_v1` | `p_report_id uuid` | `jsonb` | SECURITY DEFINER |
| `admin_bulk_decide_owner_claims_v1` | `p_claim_ids uuid[], p_decision text, p_note text` | `jsonb` | SECURITY DEFINER |
| `admin_bulk_reject_business_suggestions_v1` | `p_suggestion_ids uuid[], p_admin_note text` | `jsonb` | SECURITY DEFINER |
| `admin_bulk_replace_preview_v1` | `p_table text, p_column text, p_from text, p_case_insensitive bool` | `jsonb` | SECURITY DEFINER |
| `admin_bulk_replace_text_v1` | `p_table text, p_column text, p_from text, p_to text, p_case_insensitive bool` | `jsonb` | SECURITY DEFINER |
| `admin_decide_owner_claim_v1` | `p_claim_id uuid, p_decision text, p_note text` | `jsonb` | SECURITY DEFINER |
| `admin_find_duplicate_businesses_v1` | `p_suggestion_id uuid, p_threshold float8` | `TABLE(...)` | SECURITY DEFINER |
| `admin_get_queues_counts_v1` | — | `jsonb` | SECURITY DEFINER |
| `admin_list_business_suggestions_v3` | `p_status text, p_limit int, p_offset int, p_q text, p_assigned text, p_sla_only bool` | `TABLE(...)` | SECURITY DEFINER |
| `admin_list_businesses_v1` | `p_limit int, p_offset int, p_q text, p_city text, p_district text` | `TABLE(...)` | SECURITY DEFINER |
| `admin_list_owner_claims_v1` | `p_status text, p_limit int, p_offset int, p_q text` | `TABLE(...)` | SECURITY DEFINER |
| `admin_list_suspended_claims_v1` | `p_status text, p_limit int, p_offset int, p_sla_only bool` | `TABLE(...)` | SECURITY DEFINER |
| `admin_reject_business_suggestion_v1` | `p_suggestion_id uuid, p_admin_note text` | `jsonb` | SECURITY DEFINER |
| `admin_reject_suspended_claim_v1` | `p_claim_id uuid, p_note text` | `jsonb` | SECURITY DEFINER |
| `admin_set_business_media_v1` | `p_business_id uuid, p_field text, p_url text` | `jsonb` | SECURITY DEFINER |
| `admin_sla_metrics_v1` | — | `TABLE(...)` | SECURITY DEFINER |
| `admin_update_business_v1` | `p_business_id uuid, p_name text, ...` | `jsonb` | SECURITY DEFINER |
| `admin_approve_business_submission_v1` | `p_submission_id uuid` | `jsonb` | SECURITY DEFINER |
| `admin_bulk_update_reports_status_v2` | `p_report_ids uuid[], p_status text, p_admin_note text` | `jsonb` | SECURITY DEFINER |
| `admin_create_incident_update_v1` | `p_incident_key text, p_title text, p_summary text, ...` | `uuid` | SECURITY DEFINER |
| `admin_apply_user_safety_action_v1` | `p_user_id uuid, p_action text, p_minutes int, p_reason text` | `jsonb` | SECURITY DEFINER |
| `admin_get_overview_stats_v1` | — | `json` | SECURITY DEFINER — STUB |

### 6.3 Owner RPC'leri

| Fonksiyon | Parametreler | Dönüş | Güvenlik |
|---|---|---|---|
| `owner_approve_menu_price_suggestion_v1` | `p_suggestion_id uuid` | `jsonb` | SECURITY DEFINER |
| `owner_approve_suspended_claim_v1` | `p_claim_id uuid` | `jsonb` | SECURITY DEFINER |
| `owner_fulfill_suspended_claim_v1` | `p_claim_id uuid, p_code text` | `jsonb` | SECURITY DEFINER |
| `owner_list_suspended_claims_v1` | `p_business_id uuid, p_status text, p_limit int, p_offset int` | `TABLE(...)` | SECURITY DEFINER |
| `owner_upsert_menu_item_nutrition_v1` | `p_menu_item_id uuid, ...nutrition fields` | `jsonb` | SECURITY DEFINER |
| `upsert_business_hours_v1` | `p_business_id uuid, p_hours jsonb` | `void` | SECURITY DEFINER |
| `upsert_business_special_hour_v1` | `p_business_id uuid, p_date date, ...` | `void` | SECURITY DEFINER |
| `delete_business_special_hour_v1` | `p_business_id uuid, p_date date` | `void` | SECURITY DEFINER |
| `upsert_custom_domain_v1` | `p_business_id uuid, p_domain text` | `jsonb` | SECURITY DEFINER |
| `delete_custom_domain_v1` | `p_business_id uuid` | `void` | SECURITY DEFINER |
| `send_business_campaign_v1` | `p_business_id uuid, p_message text, ...` | `jsonb` | SECURITY DEFINER |

### 6.4 Genel Kullanıcı RPC'leri

| Fonksiyon | Parametreler | Dönüş | Güvenlik |
|---|---|---|---|
| `get_business_detail_v1` | `p_business_id uuid, p_latest_reviews_limit int` | `jsonb` | SECURITY DEFINER |
| `get_business_reviews_v3` | `p_business_id uuid, p_sort text, p_limit int, p_offset int` | `TABLE(...)` | SECURITY DEFINER |
| `get_business_rating_summary_v2` | `p_business_id uuid` | `jsonb` | SECURITY DEFINER |
| `get_business_hours_v1` | `p_business_id uuid` | `jsonb` | SECURITY DEFINER |
| `get_business_menus_v1` | `p_business_id uuid` | `TABLE(...)` | SECURITY DEFINER |
| `get_business_crowd_v1` | `p_business_id uuid` | `jsonb` | SECURITY DEFINER |
| `get_business_price_trust_v1` | `p_business_id uuid` | `jsonb` | SECURITY DEFINER |
| `get_business_stories_v1` | `p_business_id uuid, p_limit int` | `TABLE(...)` | SECURITY DEFINER |
| `search_businesses_v1` | `p_query text, p_city text, p_district text, p_limit int, p_offset int` | `TABLE(...)` | SECURITY DEFINER |
| `search_nearby_businesses_v3` | `p_lat float8, p_lng float8, p_radius_km int, ...` | `TABLE(...)` | SECURITY DEFINER |
| `nearby_businesses_v2` | `p_lat float8, p_lng float8, p_radius_m int, ...` | `TABLE(...)` | SECURITY DEFINER |
| `get_my_favorites_v1` | `p_limit int, p_offset int` | `TABLE(...)` | SECURITY DEFINER |
| `get_my_following_v1` | `p_limit int, p_offset int` | `TABLE(...)` | SECURITY DEFINER |
| `toggle_favorite_v1` | `p_business_id uuid` | `jsonb` | SECURITY DEFINER |
| `toggle_follow_v1` | `p_followee_id uuid` | `jsonb` | SECURITY DEFINER |
| `submit_owner_claim_v1` | `p_business_id uuid, p_full_name text, p_phone text, ...` | `jsonb` | SECURITY DEFINER |
| `submit_business_suggestion` | `p_name text, p_category text, ...` | `uuid` | SECURITY DEFINER — versiyonsuz |
| `submit_report_v1` | `p_business_id uuid, p_review_id uuid, p_reason text, p_details text` | `jsonb` | SECURITY DEFINER |
| `submit_presence_v1` | `p_business_id uuid, p_crowd text` | `jsonb` | SECURITY DEFINER |
| `get_taste_matches_hybrid_v1` | `p_limit int, p_min_overlap int` | `TABLE(...)` | SECURITY DEFINER |
| `get_weekly_contributor_leaderboard_v1` | `p_limit int` | `TABLE(...)` | SECURITY DEFINER |
| `vote_menu_item_price_v1` | `p_menu_item_id uuid, p_vote smallint` | `jsonb` | SECURITY DEFINER |
| `vote_menu_item_photo_v1` | `p_photo_id uuid, p_vote smallint` | `smallint` | SECURITY DEFINER |
| `ensure_my_profile_v1` | `p_display_name text, p_avatar_url text` | `jsonb` | SECURITY DEFINER |
| `upsert_my_diet_profile_v1` | `...diet flags` | `void` | SECURITY DEFINER |
| `get_my_diet_profile_v1` | — | `jsonb` | SECURITY DEFINER |
| `get_user_public_profile_v1` | `p_user_id uuid` | `jsonb` | SECURITY DEFINER |
| `consume_rate_limit_v1` | `p_action text, p_daily_limit int` | `boolean` | SECURITY DEFINER |
| `log_event_v1` | `p_event_name text, p_business_id text, ...` | `jsonb` | SECURITY DEFINER |
| `delete_user_account_v1` | — | `void` | SECURITY DEFINER |

### 6.5 Personel Uygulaması RPC'leri

| Fonksiyon | Parametreler | Dönüş | Güvenlik |
|---|---|---|---|
| `get_dashboard_stats_today_v1` | `p_business_id uuid` | `json` | SECURITY DEFINER |
| `get_pending_table_orders_v1` | `p_business_id uuid` | `TABLE(...)` | SECURITY DEFINER |
| `submit_table_order_v1` | `p_business_id uuid, p_table_no text, p_items_json jsonb` | `jsonb` | SECURITY DEFINER |
| `update_table_order_status_v1` | `p_order_id uuid, p_status text, p_business_id uuid` | `void` | SECURITY DEFINER |
| `update_table_order_staff_note_v1` | `p_order_id uuid, p_staff_note text, p_business_id uuid` | `void` | SECURITY DEFINER |
| `update_menu_item_availability_v1` | `p_menu_item_id uuid, p_is_available bool` | `void` | SECURITY DEFINER |
| `get_business_daily_stats_v1` | `p_business_id uuid` | `jsonb` | SECURITY DEFINER |
| `submit_checkin_v1` | `p_business_id uuid, ...` | `jsonb` | SECURITY DEFINER |
| `get_my_checkin_today_v1` | `p_business_id uuid` | `jsonb` | SECURITY DEFINER |
| `get_my_food_journal_v1` | `p_limit int, p_offset int` | `TABLE(...)` | SECURITY DEFINER |
| `get_my_spending_summary_v1` | — | `jsonb` | SECURITY DEFINER |
| `get_staff_performance_today_v1` | `p_business_id uuid` | `json` | SECURITY DEFINER — STUB |

### 6.6 PostGIS / Coğrafi RPC'ler

| Fonksiyon | Parametreler | Güvenlik |
|---|---|---|
| `nearby_businesses_v2` | `p_lat, p_lng, p_radius_m, p_category, p_limit, p_offset` | SECURITY DEFINER |
| `get_businesses_in_boundary_v1` | `p_boundary_id, p_limit, p_offset` | SECURITY DEFINER |
| `search_businesses_in_boundary_v1` | `p_query, p_boundary_id, p_limit, p_offset` | SECURITY DEFINER |
| `assign_business_to_boundary_v1` | `p_business_id` | SECURITY DEFINER — sadece service_role |
| `assign_all_businesses_to_boundaries_v1` | `p_batch` | SECURITY DEFINER — sadece service_role |
| `get_boundary_stats_v1` | `p_admin_level` | SECURITY DEFINER |
| `import_osm_boundaries_batch_v1` | `p_boundaries jsonb` | SECURITY DEFINER — sadece service_role |

---

## 7. Next.js Route Handler Envanteri

| Yöntem | Path | Auth | Rate Limit | Zod | Açıklama |
|---|---|---|---|---|---|
| GET | `/api/admin/claims` | JWT + admin rol | 60/dak | Yok | Bekleyen claim listesi |
| POST | `/api/admin/moderation` | JWT + admin rol | 30/dak | Var | Moderasyon aksiyonu |
| GET | `/api/admin/push-open` | — | — | — | Push notification tıklama |
| GET | `/api/owner/businesses` | JWT | 60/dak | Yok | Owner işletme listesi |
| PATCH | `/api/owner/businesses/[id]` | JWT + ownership | 20/dak | Var | İşletme güncelleme |
| GET | `/api/owner/menus` | JWT | 60/dak | Yok | Owner menü listesi |
| POST | `/api/owner/menus` | JWT + ownership | 20/dak | Var | Yeni menü oluştur |
| POST | `/api/media/upload` | JWT + business ownership | 10/dak | Var (formData) | Branding görseli yükle |
| POST | `/api/feedback` | Opsiyonel JWT | 2–10/dak | Var | Kullanıcı feedback |
| POST | `/api/track` | Yok | 40/dak | Var | Analytics event |
| GET | `/api/og` | Yok | Yok | Yok | OG image (Edge) |
| POST | `/api/revalidate` | Secret token | — | Var | Cache invalidation |
| GET/POST | `/api/presentation-settings` | — | — | — | Sunum ayarları |

### 7.1 Tutarsızlık Tespiti

| Endpoint | Sorun | Öneri |
|---|---|---|
| `POST /api/feedback` | `{ ok: true }` döner, standart `{ data: ... }` değil | Backward compat. için kalsın; yeni endpoint'lerde kullanma |
| `GET /api/og` | Auth yok, throttle yok | Edge fonksiyon olduğu için kabul edilebilir |
| `POST /api/track` | `{ ok: true, data: rpcResult }` — karışık format | Kabul edilebilir; RPC sonucunu doğrudan forward eder |
| `POST /api/revalidate` | `{ ok: true, invalidated: [...] }` | Kabul edilebilir; internal endpoint |

---

## 8. Edge Function Envanteri

| Fonksiyon | Endpoint | Auth Tipi | CORS | Açıklama |
|---|---|---|---|---|
| `admin-api` | `/functions/v1/admin-api` | JWT + admin rol | Yok | Admin RPC proxy, audit log |
| `ai-allergen-detect` | `/functions/v1/ai-allergen-detect` | JWT | Yok | AI alerjen tespiti |
| `ai-ingredient-detect` | `/functions/v1/ai-ingredient-detect` | JWT | Yok | AI malzeme tespiti |
| `ai-menu-analyze` | `/functions/v1/ai-menu-analyze` | JWT | Yok | OCR + AI menü analizi |
| `ai-menu-image-gen` | `/functions/v1/ai-menu-image-gen` | JWT | Yok | AI menü görseli üretimi |
| `ai-nutrition-estimate` | `/functions/v1/ai-nutrition-estimate` | JWT | Yok | AI kalori tahmini |
| `anti-spam-guard` | `/functions/v1/anti-spam-guard` | JWT | Yok | Spam koruması |
| `get-exchange-rates` | `/functions/v1/get-exchange-rates` | GET: açık / POST: cron-secret | Var (TCMB) | Döviz kuru |
| `import_places_json` | `/functions/v1/import_places_json` | service-role | Yok | Mekan import |
| `media-upload` | `/functions/v1/media-upload` | JWT + admin rol | Yok | WordPress medya yükleme |
| `media-upload-user` | `/functions/v1/media-upload-user` | JWT | Yok | Kullanıcı medya yükleme |
| `purge-temp-uploads` | `/functions/v1/purge-temp-uploads` | Cron secret | Yok | Geçici dosya temizliği |
| `push-dispatch` | `/functions/v1/push-dispatch` | JWT | Yok | FCM push dağıtımı |
| `send-email-campaign` | `/functions/v1/send-email-campaign` | JWT + admin | Yok | Email kampanya gönderimi |
| `send-push-campaign` | `/functions/v1/send-push-campaign` | JWT + admin | Yok | Push kampanya gönderimi |
| `verify-domain` | `/functions/v1/verify-domain` | JWT + ownership | Yok | DNS TXT doğrulama |
| `wp-upload` | `/functions/v1/wp-upload` | JWT + admin rol | Yok | WordPress upload |
| `wp-upload-user` | `/functions/v1/wp-upload-user` | JWT | Yok | Kullanıcı WP upload |
| `write-gatekeeper` | `/functions/v1/write-gatekeeper` | JWT | Yok | Yazma işlemleri kapı bekçisi |

---

## 9. Analytics Event Kataloğu

### 9.1 RPC log_event_v1 Event İsimleri (snake_case — standart)

Tüm event isimleri snake_case ve İngilizce:

| Event | Tetikleyici |
|---|---|
| `menu_shared` | Menü paylaşma |
| `qr_scanned` | QR kod tarama |
| `menu_link_opened` | Menü linki açılması (page_view alias) |
| `app_install_from_menu` | Menüden uygulama yükleme |
| `business_reservation_click` | Rezervasyon tıklama |
| `business_phone_click` | Telefon tıklama |
| `business_whatsapp_click` | WhatsApp tıklama |
| `business_order_click` | Sipariş tıklama |
| `business_directions_click` | Yol tarifi tıklama |
| `business_page_view` | İşletme sayfa görüntüleme |
| `menu_view` | Menü görüntüleme |
| `discovery_impression` | Keşif bölümü görünüm |
| `discovery_business_click` | Keşifte işletme tıklama |
| `business_impression` | İşletme görünüm |
| `price_suggestion_submitted` | Fiyat önerisi gönderme |

### 9.2 Web İstemci Event Eşlemesi (trackEventSchema → log_event_v1)

| trackEventSchema.eventName | log_event_v1 event | Alias |
|---|---|---|
| `page_view` | `menu_link_opened` | `event_alias: 'page_view'` |
| `category_view` | `menu_view` | `event_alias: 'category_view'` |
| `item_view` | `menu_view` | `event_alias: 'item_view'` |
| `item_click` | `menu_view` | `event_alias: 'item_click'` |
| `qr_scanned` | `qr_scanned` | — |

### 9.3 PII Kontrolü

Event property'lerine aşağıdakiler GİRMEMELİDİR:
- Email adresi
- Ad/soyad
- Telefon numarası
- Tam IP adresi (hash'lenmiş IP kabul edilebilir)
- Kredi kartı/ödeme bilgisi

`user_id` alanı varsa mutlaka UUID veya hash olmalı, hiçbir zaman email olmamalıdır.

---

## 10. Açık Maddeler

### 10.1 Adlandırma İhlalleri (Yüksek Öncelik)

Bu RPC'lerin versiyonsuz veya Türkçe isimli olduğu tespit edildi. Mevcut istemci çağrıları kırılmaması için isimler DEĞİŞTİRİLMEMELİ; bunun yerine yeni versiyonlu wrapper'lar oluşturulmalıdır.

| Mevcut İsim | Sorun | Önerilen Yeni İsim |
|---|---|---|
| `get_my_profile_stats` | Versiyon yok | `get_my_profile_stats_v1` (wrapper migration) |
| `get_daily_picks` | Versiyon yok | `get_daily_picks_v1` (wrapper migration) |
| `submit_business_suggestion` | Versiyon yok | `submit_business_suggestion_v1` (wrapper migration) |
| `create_owner_claim` | Versiyon yok, `submit_owner_claim_v1` ile örtüşüyor | DEPRECATED olarak işaretle |
| `approve_business_suggestion` | Versiyon yok | DEPRECATED — `admin_approve_business_suggestion_v1` kullan |
| `approve_owner_claim` | Versiyon yok | DEPRECATED — `admin_decide_owner_claim_v1` kullan |
| `reject_business_suggestion` | Versiyon yok | DEPRECATED — `admin_reject_business_suggestion_v1` kullan |
| `get_top_businesses` | Versiyon yok | DEPRECATED — `get_top_businesses_period_v1` kullan |
| `nearby_businesses_v2` | `search_` öneki yok, PostGIS sürümünü ifade etmiyor | `search_nearby_businesses_v4_postgis` (gelecekte) |
| `_review_verified_visit` | `_` önekli internal helper, bu doğru; ama `_v1` eksik | Mevcut haliyle kabul edilebilir |
| `normalize_tr_text` | Versiyon yok, public helper | `normalize_tr_text_v1` (wrapper) |
| `is_admin` | Versiyon yok, internal helper | Mevcut haliyle kabul edilebilir |
| `is_business_team_member` | Versiyon yok | `is_business_team_member_v1` (wrapper) |
| `tg_*` (trigger fonksiyonlar) | Versiyonsuz — trigger'lar için kuralın dışında | Kabul edilebilir |

### 10.2 N+1 Sorgu Düzeltme Gerektiren Alanlar

| Konum | Sorun | Öneri | Öncelik |
|---|---|---|---|
| `dashboard_istatistik_saglayicisi.dart` — `_yukle()` | `menu_items` tablosundan ayrı `.select()` sorgusu; `get_dashboard_stats_today_v1` bunu kapsamıyor | `get_menu_item_counts_v1` oluştur veya `get_dashboard_stats_today_v1`'e ekle | Orta |
| `dashboard_istatistik_saglayicisi.dart` — `haftalikVeriProvider` | 2 ayrı tablo sorgusu (`table_orders` + `table_order_items`) | `get_dashboard_weekly_v1` stub'ını implement et | Orta |
| `dashboard_istatistik_saglayicisi.dart` — `personelPerformansProvider` | `get_staff_performance_today_v1` çağrısı; bu RPC tanımlı değil; ama `get_dashboard_stats_today_v1.personel_performans` aynı veriyi döndürüyor | Dart tarafını refactor et — `get_dashboard_stats_today_v1` sonucunu kullan | Düşük |

### 10.3 Güvenlik Notları

| Konu | Durum |
|---|---|
| `search_path` sabit mi? | 2026-05-23 migration'larında tüm önemli fonksiyonlara eklendi (set_function_search_paths.sql) |
| SECURITY DEFINER kullanımı | Genel olarak doğru; `search_path = public` ile XS-PATH güvenli |
| Anonim erişim | `revoke_anon_admin_rpc.sql` ile kısıtlandı |
| Rate limiting | Hem RPC seviyesinde (`rate_limit_buckets`) hem Next.js handler seviyesinde var |

### 10.4 Eksik Test Kapsamı

- `get_dashboard_stats_today_v1` için Dart integration test yok
- `admin-api` edge function için happy-path E2E test yok
- `nearby_businesses_v2` PostGIS sorgu performansı production'da ölçülmedi

---

## Ekler

### Ek A: `search_path` Durumu

`20260520000005_set_function_search_paths.sql` ve `20260523000003_security_function_search_paths.sql` migration'larında büyük çoğunluğa `SET search_path = public` eklendi. Yeni yazılan tüm fonksiyonlarda bu clause zorunludur.

### Ek B: Yeni RPC Yazma Şablonu

```sql
CREATE OR REPLACE FUNCTION public.{eylem}_{konu}_v1(
  p_{param1} {tip},
  p_{param2} {tip} DEFAULT {varsayilan}
)
RETURNS {json | TABLE(...) | void}
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  -- değişkenler
BEGIN
  -- yetki kontrolü
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'unauthorized: Oturum açmanız gerekiyor'
      USING ERRCODE = 'P0002';
  END IF;

  -- iş mantığı

  RETURN ...;
END;
$$;

-- Grant
REVOKE ALL ON FUNCTION public.{eylem}_{konu}_v1(...) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.{eylem}_{konu}_v1(...) TO authenticated;

-- (gerekirse)
GRANT EXECUTE ON FUNCTION public.{eylem}_{konu}_v1(...) TO anon;

-- Dokümantasyon
COMMENT ON FUNCTION public.{eylem}_{konu}_v1 IS
  'Kısa açıklama. Çağıran: {Dart dosyası / TS dosyası}.';
```
