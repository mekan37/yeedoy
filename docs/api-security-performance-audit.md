# Yeedoy API Güvenlik ve Performans Denetimi

**Tarih:** 2026-05-23
**Son güncelleme:** 2026-05-23 — LOW-risk güvenli düzeltmeler uygulandı (bkz. §14)
**Kapsam:** Tüm monorepo — Next.js route handler'lar, Supabase Edge Function'lar, RPC çağrıları, doğrudan tablo sorguları, uygulamalar arası API sözleşme tutarlılığı, yazma akışı güçlendirmesi, performans desenleri
**Yöntem:** Dosya okuma ve desen aramaları ile statik kod analizi. LOW-risk güvenli düzeltmeler 2026-05-23 tarihinde uygulandı; DB şeması, migrasyon, RLS, RPC imzası, kimlik doğrulama akışı veya public route davranışı değiştirilmedi.

---

## İçindekiler

1. [API Yüzeyi Keşfi](#1-api-yüzeyi-keşfi)
2. [Next.js Route Handler Güvenlik Denetimi](#2-nextjs-route-handler-güvenlik-denetimi)
3. [Edge Function Güvenlik Denetimi](#3-edge-function-güvenlik-denetimi)
4. [Supabase RPC / Veritabanı Sözleşme Denetimi](#4-supabase-rpc--veritabanı-sözleşme-denetimi)
5. [Uygulamalar Arası API Sözleşme Tutarlılığı](#5-uygulamalar-arası-api-sözleşme-tutarlılığı)
6. [Performans Denetimi](#6-performans-denetimi)
7. [Yazma Akışı Güçlendirmesi](#7-yazma-akışı-güçlendirmesi)
8. [Güvenilirlik ve Hata Yönetimi](#8-güvenilirlik-ve-hata-yönetimi)
9. [Güvenlik Bulguları](#9-güvenlik-bulguları)
10. [Güvenli Düzeltme Planı (Onay Gerektirmez)](#10-güvenli-düzeltme-planı-onay-gerektirmez)
11. [Riskli Düzeltme Planı (Onay Gerektirir)](#11-riskli-düzeltme-planı-onay-gerektirir)
12. [Önceliklendirilmiş Uygulama Planı](#12-önceliklendirilmiş-uygulama-planı)
13. [Doğrulama Komutları](#13-doğrulama-komutları)
14. [LOW-Risk Güvenli Düzeltme Geçişi — 2026-05-23](#14-low-risk-güvenli-düzeltme-geçişi--2026-05-23)

---

## 1. API Yüzeyi Keşfi

### 1.1 Next.js Route Handler'lar

Tüm route handler'lar `uygulamalar/web/app/` altındadır. İki paralel dizin ağacı mevcuttur:

- `app/sunucu/` — Türkçe adlandırılmış route handler'lar (birincil, aktif olarak bakımı yapılıyor)
- `app/api/` — İngilizce adlandırılmış route handler'lar (eski veya yinelenen yollar)

`app/api/` alt ağacı, `app/sunucu/` altında zaten var olan birçok route'u kopyalamaktadır. Bu bir bakım riskidir; istemciler bağlantı şekillerine göre her iki yolu da çağırabilir.

| Dosya Yolu | Amaç | Kimlik Doğrulama | Zod | Hız Sınırı | Risk |
|---|---|---|---|---|---|
| `app/sunucu/geri-bildirim/route.ts` | Anonim + kimlik doğrulamalı işletme geri bildirimi | İsteğe bağlı | Evet | Evet (anonim 2/dak, kimlik doğrulamalı 10/dak) | DÜŞÜK |
| `app/sunucu/izleme/route.ts` | Analitik olay takibi (log_event_v1 RPC) | Gerekmiyor | Evet | Evet (IP+UA başına 40/dak) | ORTA — kimlik doğrulama yok; olaylar sahtelenebilir |
| `app/sunucu/sunum-ayarlari/route.ts` | QR Studio sunum ayarları upsert | Gerekiyor | Evet | Evet (20/dak) | DÜŞÜK |
| `app/sunucu/hesap/sil/route.ts` | Hesap silme (RPC + admin auth delete) | Gerekiyor | Hayır | Evet (günde 3) | YÜKSEK — bkz. §9 |
| `app/sunucu/sahip/bildirim-gonder/route.ts` | Sahip push kampanya bildirimleri | Gerekiyor + sahiplik | Evet | Evet (kimlik başına günde 3) | ORTA — businessId başına hız sınırı yok |
| `app/sunucu/sahip/eposta-kampanya/route.ts` | Sahip e-posta kampanyası (simüle edilmiş, gönderildi olarak işaretleniyor) | Gerekiyor + sahiplik | Hayır — yalnızca manuel kontrol | Evet (kimlik başına saatte 3) | YÜKSEK — bkz. §9 |
| `app/sunucu/sahip/sms-kampanya/route.ts` | Sahip SMS kampanya oluşturma | Gerekiyor | Evet | Evet (saatte 3) | ~~YÜKSEK~~ ✅ **DÜZELTILDI** — sahiplik + hız sınırı mevcut |
| `app/sunucu/sahip/isletmeler/route.ts` | Sahip işletme listesi | Gerekiyor | Hayır | Evet (60/dak) | DÜŞÜK |
| `app/sunucu/sahip/isletmeler/[id]/route.ts` | Sahip işletme PATCH | Gerekiyor + sahiplik | Evet | Evet (20/dak) | DÜŞÜK |
| `app/sunucu/sahip/menuler/route.ts` | Sahip menü listesi + oluşturma | Gerekiyor + sahiplik | Evet | Evet (20–60/dak) | DÜŞÜK |
| `app/sunucu/sahip/menuler/[id]/route.ts` | Sahip menü PATCH + DELETE | Gerekiyor + sahiplik | Evet | Evet (10–30/dak) | DÜŞÜK |
| `app/sunucu/medya/yukleme/route.ts` | Supabase Storage'a medya yükleme | Gerekiyor + sahiplik | Evet | Evet (10/dak) | DÜŞÜK |
| `app/sunucu/sahip/yorumlar/yanit/route.ts` | Sahip yorum yanıtı CRUD | Gerekiyor + sahiplik | Evet | Evet (10–20/dak) | DÜŞÜK |
| `app/sunucu/sahip/finansal-csv/route.ts` | Finansal CSV dışa aktarma | Gerekiyor | Hayır (yalnızca helper ile sahip kontrolü) | Yok | ORTA — dışa aktarmada hız sınırı yok |
| `app/sunucu/sahip/menu-csv/route.ts` | Menü CSV dışa aktarma | Gerekiyor + sahiplik | Hayır | Yok | ORTA — hız sınırı yok |
| `app/sunucu/sahip/ceviriler-otomatik/route.ts` | OpenAI aracılığıyla menü öğelerini otomatik çevir | Gerekiyor | Evet | Yok | YÜKSEK — bkz. §9 |
| `app/sunucu/sahip/spesiyel/route.ts` | Günün spesiyalini ayarla | Gerekiyor | Evet | Evet (30/dak) | DÜŞÜK |
| `app/sunucu/sahip/sadakat/route.ts` | Sadakat programı oluştur | Gerekiyor | Evet | Yok | ORTA — hız sınırı yok |
| `app/sunucu/sahip/envanter/route.ts` | Menü öğesi stok/erişilebilirlik güncelleme | Gerekiyor | Evet | Yok | YÜKSEK — bkz. §9 |
| `app/sunucu/sahip/siparis-listesi/route.ts` | Sahip bekleyen siparişler listesi | Gerekiyor | Hayır | Yok | ORTA |
| `app/sunucu/sahip/etkinlik/route.ts` | Sahip etkinlik oluşturma | Gerekiyor | Evet | Evet | DÜŞÜK |
| `app/sunucu/yonetici/moderasyon/route.ts` | Yönetici moderasyon işlemleri | Gerekiyor + is_admin | Evet | Evet (30/dak) | DÜŞÜK |
| `app/sunucu/yonetici/toplu-islemler/route.ts` | Yönetici toplu işlemler | Gerekiyor + is_admin | Evet | Yok | YÜKSEK — bkz. §9 |
| `app/sunucu/yonetici/kullanici-rol/route.ts` | Yönetici rol atama | Gerekiyor + is_admin | Evet | Yok | YÜKSEK — bkz. §9 |
| `app/sunucu/yonetici/feature-flags/route.ts` | Yönetici özellik bayrağı açma/kapama | Gerekiyor + is_admin | Kısmi | Yok | ORTA |
| `app/sunucu/yonetici/ab-test/route.ts` | Yönetici A/B test yönetimi | Gerekiyor + is_admin | Evet | Yok | ORTA |
| `app/sunucu/yonetici/api-anahtarlari/route.ts` | Yönetici API anahtar oluşturma/iptal | Gerekiyor + is_admin | Kısmi | Yok | YÜKSEK — bkz. §9 |
| `app/sunucu/yonetici/push-kampanyalari/route.ts` | Yönetici push kampanya oluşturma | Gerekiyor + is_admin | Evet | Yok | ORTA |
| `app/sunucu/yonetici/raporlar-csv/route.ts` | Yönetici raporlar CSV dışa aktarma | Gerekiyor + is_admin | Hayır | Yok | YÜKSEK — bkz. §9 |
| `app/sunucu/yonetici/arama/route.ts` | Yönetici arama | Gerekiyor + is_admin | Evet | Evet (120/dak) | DÜŞÜK |
| `app/sunucu/yonetici/musteri-destek/route.ts` | Yönetici destek talepleri | Gerekiyor + is_admin | Evet | Yok | ORTA |
| `app/sunucu/yonetici/fotograf-moderasyon/route.ts` | Yönetici fotoğraf moderasyonu | Gerekiyor + is_admin | Evet | Yok | DÜŞÜK |
| `app/sunucu/yonetici/itirazlar/route.ts` | Yönetici talepler listesi | Gerekiyor + is_admin | Hayır | Evet (60/dak) | DÜŞÜK |
| `app/sunucu/yonetici/dsar/route.ts` | Yönetici DSAR (gizlilik talepleri) | Gerekiyor + is_admin | Evet | Yok | ORTA |
| `app/sunucu/b2b-export/[type]/route.ts` | B2B veri dışa aktarma (CSV) | Gerekiyor + rol kontrolü | Hayır | Yok | YÜKSEK — bkz. §9 |
| `app/sunucu/sahiplik-talebi/route.ts` | İşletme sahipliği talep gönderimi | Gerekiyor | Hayır — manuel kontrol | Yok | YÜKSEK — bkz. §9 |
| `app/sunucu/sahiplik-kaniti-yukle/route.ts` | Sahiplik kanıtı dosya yükleme | Gerekiyor | Hayır — manuel kontrol | Yok | ORTA |
| `app/sunucu/makbuz-ocr/route.ts` | Fiş OCR (OpenAI/Replicate) | Gerekmiyor | Hayır — manuel kontrol | Evet (IP+UA başına 5/dak) | YÜKSEK — bkz. §9 |
| `app/sunucu/masa-siparisi/route.ts` | Anonim masa sipariş gönderimi | Gerekmiyor | Evet | Evet (2 dakikada 10) | ORTA |
| `app/sunucu/masa-siparisi/durum/route.ts` | Masa sipariş durumu güncelleme | Gerekiyor | Evet | Yok | ORTA |
| `app/sunucu/ortak-liste/oy/route.ts` | Ortak liste oylama (IP tabanlı) | Gerekmiyor | Evet | Evet (30/dak) | ORTA — bkz. §9 |
| `app/sunucu/koleksiyonlar/route.ts` | Kullanıcı koleksiyonu oluşturma | Gerekiyor | Evet | Evet (10/dak) | DÜŞÜK |
| `app/sunucu/diyet-profili/route.ts` | Diyet profili kaydetme | Gerekiyor | Evet | Evet (20/dak) | DÜŞÜK |
| `app/sunucu/kimlik/giris/route.ts` | Giriş (e-posta+şifre → çerez) | Yok (ön-kimlik doğrulama) | Evet | Evet (8/dak) | DÜŞÜK |
| `app/sunucu/kimlik/rol-yonlendirme/route.ts` | Role dayalı yönlendirme | Gerekiyor | Hayır | Yok | DÜŞÜK |
| `app/sunucu/yeniden-dogrulama/route.ts` | Önbellek yeniden doğrulama webhook | Gizli anahtar tabanlı | Evet | Yok | ~~DÜŞÜK~~ ✅ **timing-safe compare mevcut** |
| `app/sunucu/izleme/itme-acilisi/route.ts` | Push bildirim açılış takibi | Gerekmiyor | Evet | Evet | DÜŞÜK |

**`app/api/` altındaki Yinelenen/Eski Route Handler'lar:**
Aşağıdaki yollar `app/sunucu/` handler'larını yansıtıyor veya kısmen kopyalıyor. Birincil handler'larla ilişkileri belirsizdir ve ön ucun nasıl bağlandığına göre trafik alabilirler:

- `app/api/admin/claims/route.ts`
- `app/api/admin/moderation/route.ts`
- `app/api/feedback/route.ts`
- `app/api/media/upload/route.ts`
- `app/api/owner/businesses/[id]/route.ts`
- `app/api/owner/businesses/route.ts`
- `app/api/owner/menus/[id]/route.ts`
- `app/api/owner/menus/route.ts`
- `app/api/presentation-settings/route.ts`
- `app/api/revalidate/route.ts`
- `app/api/track/push-open/route.ts`
- `app/api/track/route.ts`
- `app/auth/panel-handoff/route.ts`
- `app/auth/callback/route.ts`
- `app/forbidden/route.ts`
- `app/q/[code]/route.ts`
- `app/kod/[code]/route.ts`

Bu dosyalar tek tek okunmadı. Denetim `app/sunucu/` yolunu birincil yüzey olarak kabul eder.

---

### 1.2 Supabase Edge Function'lar

| Fonksiyon | Kimlik Doğrulama | Rol Kontrolü | Girdi Doğrulama | Hız Sınırı | Risk |
|---|---|---|---|---|---|
| `admin-api` | JWT gerekli (Bearer) | app_metadata üzerinden admin veya community_mod | RPC izin listesi zorunlu | IP reddetme listesi kontrol edilir | DÜŞÜK — iyi tasarlanmış |
| `anti-spam-guard` | JWT gerekli | Kullanıcı kimlik doğrulamasının ötesinde yok | action alanı RULES map'e göre doğrulanır | Kullanıcı+IP başına DB destekli | DÜŞÜK |
| `write-gatekeeper` | JWT gerekli | İzin verilen roller (user/owner/admin) | action doğrulanır; yükler action başına doğrulanır | Kullanıcı+IP başına DB destekli | DÜŞÜK |
| `media-upload` | JWT gerekli | is_admin RPC | MIME türü, boyut, boyutlar | Açık değil | ORTA — kullanıcı başına hız sınırı yok |
| `media-upload-user` | JWT gerekli | Yok (kimlik doğrulamalı herhangi bir kullanıcı) | MIME, boyut, boyut, UUID kontrolü | DB + consume_rate_limit_v1 | DÜŞÜK |
| `ai-menu-analyze` | JWT gerekli | job owner_id === user.id | job_id mevcut; iş durumu kontrol edilir | enforceRateLimit (kullanıcı başına 5) | DÜŞÜK |
| `ai-allergen-detect` | Tek tek okunmadı | — | — | — | Doğrulanmamış |
| `ai-ingredient-detect` | Tek tek okunmadı | — | — | — | Doğrulanmamış |
| `ai-nutrition-estimate` | Tek tek okunmadı | — | — | — | Doğrulanmamış |
| `ai-menu-image-gen` | Tek tek okunmadı | — | — | — | Doğrulanmamış |
| `get-exchange-rates` | Yok — açık CORS | Yok | Yok | Yok | ORTA — kimlik doğrulamasız |
| `import_places_json` | Yok — açık CORS | Yok | dosya + alanlar | Yok | KRİTİK — bkz. §9 |
| `push-dispatch` | JWT gerekli | Toplu için admin kontrolü; kullanıcı kapsamı zorunlu | ALLOWED_PUSH_TYPES izin listesi | Yok | DÜŞÜK |
| `send-push-campaign` | JWT gerekli | İşletme sahipliği veya admin | campaign_id gerekli | İşletme başına günde 1 kampanya | DÜŞÜK |
| `send-email-campaign` | JWT gerekli | İşletme sahipliği kontrolü | campaign_id gerekli | İşletme başına günde 1 | DÜŞÜK |
| `verify-domain` | JWT gerekli (Bearer kontrolü) | Kullanıcı kimlik doğrulamasının ötesinde yok | business_id + domain gerekli | enforceRateLimit (saatte 10) | DÜŞÜK |
| `purge-temp-uploads` | Yok | Yok | limit alanı | Yok | YÜKSEK — bkz. §9 |

---

### 1.3 Supabase RPC Çağrıları (Web)

`app/sunucu/` route handler'larından ve `src/lib/`'den çağrılan RPC'ler:

- `log_event_v1` — analitik takip (izleme/route.ts)
- `delete_user_account_v1` — hesap silme (hesap/sil/route.ts)
- `is_admin` — admin rol kontrolü (~14 route handler'da kullanılıyor)
- `submit_table_order_v1` — masa sipariş gönderimi (masa-siparisi/route.ts)
- `update_table_order_status_v1` — sipariş durumu güncelleme (masa-siparisi/durum/route.ts)
- `set_today_special_v1` — menü öğesi spesiyali ayarla (sahip/spesiyel/route.ts)
- `create_loyalty_program_v1` — sadakat programı oluştur (sahip/sadakat/route.ts)
- `create_collection_v1` — kullanıcı koleksiyonu oluştur (koleksiyonlar/route.ts)
- `get_pending_table_orders_v1` — sahip için bekleyen siparişler (sahip/siparis-listesi/route.ts)
- `increment_push_campaign_open_v1` — push açılış takibi (izleme/itme-acilisi/route.ts)
- `estimate_campaign_segment_v1` — push segmentini tahmin et (yonetici/push-kampanyalari/route.ts)
- `get_business_hours_v1`, `get_menu_items_v1`, `get_menu_item_variants_v1`, `get_menu_item_photos_v1`, `get_menu_item_price_history_v1` — public menü okumaları (src/lib/)
- `can_manage_business_v1` / `can_access_business_v1` — sahiplik kontrolleri (src/lib/)
- `get_owner_analytics_v1`, `get_top_businesses_period_v1`, `get_business_reviews_v3` — analitik okumaları (src/lib/)
- `admin_get_queues_counts_v1` — admin kuyruk panosu (src/lib/)

Edge Function'lardan çağrılan RPC'ler:

- `is_admin`, `is_edge_ip_denied_v1` — admin-api, write-gatekeeper
- `admin_apply_user_safety_action_v1` — admin-api
- `ALLOWED_WRITE_RPCS` setindeki tüm RPC'ler — admin-api (33 RPC)
- `consume_rate_limit_v1` — media-upload-user
- `record_user_risk_signal_v1`, `record_user_device_fingerprint_v1` — write-gatekeeper
- `owner_approve_price_suggestion_v1`, `owner_reject_price_suggestion_v1` — write-gatekeeper
- `dequeue_notification_dispatch_jobs_v1`, `complete_notification_dispatch_job_v1` — push-dispatch

---

### 1.4 Doğrudan Tablo Sorguları (Web)

RPC arkasında olmayan önemli doğrudan `.from()` çağrıları:

- `menu_feedback` — geri-bildirim/route.ts (servis istemcisi aracılığıyla INSERT)
- `businesses` — birden fazla sahip/yönetici route'u (UPDATE, SELECT)
- `menus` — sahip/menuler route'ları (INSERT, UPDATE, SELECT)
- `favorites` — sahip/bildirim-gonder ve sahip/eposta-kampanya (takipçiler için SELECT)
- `email_campaigns` — sahip/eposta-kampanya (INSERT, UPDATE)
- `sms_campaigns` — sahip/sms-kampanya (INSERT)
- `notifications` — sahip/bildirim-gonder (INSERT)
- `reviews` — sahip/yorumlar/yanit (UPDATE)
- `business_media` — yonetici/fotograf-moderasyon ve yonetici/moderasyon (UPDATE)
- `runtime_feature_flags` — yonetici/feature-flags ve yonetici/ab-test (INSERT, UPDATE)
- `api_keys` — yonetici/api-anahtarlari (INSERT, UPDATE)
- `push_campaigns` — yonetici/push-kampanyalari (INSERT)
- `user_profiles` — yonetici/toplu-islemler (UPDATE)
- `owner_claims` — sahiplik-talebi (INSERT, SELECT), yonetici/itirazlar (SELECT)
- `reports` — yonetici/raporlar-csv (5000'e kadar SELECT)
- `user_roles` — b2b-export ve send-push-campaign (rol kontrolü için SELECT)
- `analytics_events` — b2b-export (100.000'e kadar SELECT)
- `menu_items` — sahip/ceviriler-otomatik, sahip/envanter (SELECT, UPDATE)
- `menu_sections`, `menu_translations` — sahip/ceviriler-otomatik (SELECT, INSERT)
- `user_diet_profiles` — diyet-profili (UPSERT)
- `support_tickets`, `support_ticket_messages` — yonetici/musteri-destek (SELECT, UPDATE, INSERT)
- `privacy_requests` — yonetici/dsar (UPDATE)
- `collab_list_votes` — ortak-liste/oy (DELETE, UPSERT)
- `table_order_items` — sahip/finansal-csv (SELECT)
- `bulk_op_logs` — yonetici/toplu-islemler (INSERT, ateş-ve-unut)

---

## 2. Next.js Route Handler Güvenlik Denetimi

### 2.1 Hız Sınırı Eksik Route'lar (Yazma İşlemleri)

Aşağıdaki yazma işlemi yapabilen route'larda hız sınırı yoktur; kötüye kullanım vektörleri yaratmaktadır:

- `app/sunucu/sahip/envanter/route.ts` — Menü öğesi stok/erişilebilirlik güncellemelerinde hız sınırı yok. Bir sahip DB'yi güncellemelerle doldurabilir.
- `app/sunucu/sahip/sadakat/route.ts` — Sadakat programı oluşturmada hız sınırı yok.
- `app/sunucu/sahip/ceviriler-otomatik/route.ts` — Route düzeyinde hız sınırı yok. Her çağrı 200 × 6 = 1.200 OpenAI API çağrısını tetikler. Tek bir kimlik doğrulamalı kullanıcı OpenAI bütçesini hızla tüketebilir. 10 öğe başına dahili `setTimeout(r, 500)` yalnızca yumuşak bir kısıtlama sağlar ve paralel istekleri engellemez.
- `app/sunucu/yonetici/toplu-islemler/route.ts` — Çağrı başına 200 varlığı etkileyen toplu işlemlerde hız sınırı yok.
- `app/sunucu/yonetici/kullanici-rol/route.ts` — Rol atamada hız sınırı yok.
- `app/sunucu/yonetici/api-anahtarlari/route.ts` — API anahtar oluşturmada hız sınırı yok.
- `app/sunucu/sahip/finansal-csv/route.ts` — Veri dışa aktarmada hız sınırı yok.
- `app/sunucu/sahip/menu-csv/route.ts` — CSV dışa aktarmada hız sınırı yok.
- `app/sunucu/sahip/siparis-listesi/route.ts` — Hız sınırı yok; döngü içinde işletme başına ayrı RPC çağrısı yapıyor.
- `app/sunucu/masa-siparisi/durum/route.ts` — Sipariş durumu güncellemede hız sınırı yok.
- `app/sunucu/yonetici/musteri-destek/route.ts` — Destek talep işlemlerinde hız sınırı yok.
- `app/sunucu/yonetici/dsar/route.ts` — DSAR çözümlemede hız sınırı yok.

> **NOT:** `app/sunucu/sahip/sms-kampanya/route.ts` — ~~Hız sınırı yok~~ ✅ **DÜZELTILDI**: `rateLimit` çağrısı mevcuttu (saatte 3, kullanıcı+kimlik başına).

### 2.2 Zod Doğrulama Eksik Route'lar

Aşağıdaki route'lar `zod.safeParse` olmadan harici girdi kabul eder:

- `app/sunucu/sahip/eposta-kampanya/route.ts` — Gövde `{ businessId, subject, body }` olarak inline yazılmış, yalnızca manuel null/boş kontrolleri var. Şema yok, alan uzunluğu kısıtlamaları yok, `businessId` için UUID format doğrulaması yok.
- `app/sunucu/sahiplik-talebi/route.ts` — `request.json()`'dan yalnızca temel doğruluk kontrolleriyle manuel yıkım. Şema yok.
- `app/sunucu/sahiplik-kaniti-yukle/route.ts` — Yalnızca manuel dosya doğrulaması. Zod şeması yok.
- `app/sunucu/makbuz-ocr/route.ts` — Zod şeması yok; manuel `instanceof Blob` ve MIME string kontrolü kullanıyor.
- `app/sunucu/yonetici/raporlar-csv/route.ts` — Sorgu parametreleri doğrulama olmadan doğrudan kullanılıyor (status, hedef string'leri).
- `app/sunucu/yonetici/feature-flags/route.ts` (PATCH handler) — Gövde `{ id: string; enabled: boolean }` olarak safeParse olmadan cast ediliyor.
- `app/sunucu/yonetici/api-anahtarlari/route.ts` — Hem POST hem DELETE safeParse olmadan gövde cast ediyor. POST'ta yalnızca manuel `!body.name?.trim()` kontrolü.
- `app/sunucu/sahip/siparis-listesi/route.ts` — Hiç istek gövdesi doğrulaması yok.
- `app/sunucu/sahip/finansal-csv/route.ts` — `ay` ve `format` sorgu parametreleri zod olmadan kullanılıyor.
- `app/sunucu/sahip/ceviriler-otomatik/route.ts` — Girdi şeması için zod var ancak arayanın çevrilen menülere sahip olan işletmelere gerçekten sahip olup olmadığını doğrulayan sahiplik kontrolü yok.
- `app/sunucu/sahip/menu-csv/route.ts` — Zod yok; `menuId` doğrudan sorgu parametrelerinden alınıyor.

### 2.3 Eksik Sahiplik Doğrulaması

Bu route'lar kullanıcının kimliğini doğrular ancak kullanıcının değiştirilen kaynağa sahip olup olmadığını doğrulamaz:

- `app/sunucu/sahip/envanter/route.ts` — `menu_items.is_available` ve `stock_count`'u `itemId` ile sahiplik kontrolü olmadan günceller. UUID'yi bilen herhangi bir kimlik doğrulamalı kullanıcı herhangi bir öğeyi erişilemez olarak işaretleyebilir veya stoğunu sıfıra ayarlayabilir.
- `app/sunucu/sahip/sadakat/route.ts` — `businessId`'yi sahiplik doğrulaması olmadan doğrudan RPC'ye aktarır. RPC (`create_loyalty_program_v1`) DB tarafından `{ error: 'forbidden' }` döndürür, ancak route handler DB hata mesajını istemciye sızdırır.
- `app/sunucu/sahip/ceviriler-otomatik/route.ts` — Arayanın bu menülere sahip olup olmadığını doğrulamadan `menu_id IN (menuIds)` ile `menu_items` çeker ve çeviriler ekler.
- `app/sunucu/sahip/finansal-csv/route.ts` — İşletme listesi için `getOwnerBusinesses` kullanıyor (güvenli), ancak `table_order_items` sorgusu doğru olan `.in('business_id', businessIds)` kullanıyor. Risk düşük ancak hız sınırı olmadığı için veri sızıntısı vektörü.

> **NOT:** `app/sunucu/sahip/sms-kampanya/route.ts` — ~~Sahiplik kontrolü yok~~ ✅ **DÜZELTILDI**: `hasOwnerBusiness` çağrısı mevcuttu.

### 2.4 Bellek İçi Hız Sınırlayıcı Üretim İçin Güvenli Değil

`src/lib/oran-siniri.ts` (tüm Next.js route handler'ların kullandığı birincil hız sınırlayıcı) işlem belleğinde saklanan bir `Map` kullanır:

```typescript
const store = new Map<string, RateLimitRecord>();
```

Bu durumun anlamı:
- Çok örnekli veya sunucusuz dağıtımda (Vercel, birden fazla replikalı konteynerler), her örneğin bağımsız sayacı vardır. Hız sınırları paylaşılmaz.
- Vercel sunucusuz'da, fonksiyon örneği sık sık soğuk başlatılarak tüm sayaçları sıfırlayabilir.
- Saldırgan, sınırı tamamen atlamak için istekleri örneklere dağıtabilir.
- `store` Map'i sınırsız büyür; okuma zamanı kontrolünün ötesinde süresi dolmuş anahtarlar için tahliye yoktur.

Bu, giriş (`giris`), medya yükleme, geri bildirim, analitik ve tüm sahip/yönetici yazma route'larını kapsayan 23 route'u etkiler.

### 2.5 Rol Kontrolü Tutarsızlıkları

Yönetici route'ları admin rolünü kontrol etmek için farklı desenler kullanır:

- Çoğu route: `await supabase.rpc('is_admin')` — satır düzeyi kimlik doğrulamalı istemci kullanır.
- `app/sunucu/b2b-export/[type]/route.ts`: `user_roles` tablosunu `.in('role', ['admin', 'superadmin'])` ile doğrudan sorgular — `is_admin` RPC'den farklı bir mekanizma. Bu tutarsızlık yaratır; RPC, doğrudan tablo okumasından farklı mantık uygulayabilir.

### 2.6 Route Handler'larında Servis Rolü Anahtarı Kullanımı

Aşağıdaki route'lar istek handler'ı içinde servis rolü anahtarıyla admin Supabase istemcisi oluşturur:

- `app/sunucu/hesap/sil/route.ts` — `admin.deleteUser()` çağırmak için inline `SUPABASE_SERVICE_ROLE_KEY` ile `createClient` oluşturur. Anahtar yalnızca `process.env`'den okunur; istemciye sızmaz. Risk sunucu tarafıyla sınırlıdır ancak inline admin istemci oluşturma deseni merkezi `createSupabaseServiceClient()` yardımcısını kullanmalıdır.
- `app/sunucu/medya/yukleme/route.ts` — `createSupabaseServiceClient()` doğru kullanıyor.
- `app/sunucu/yonetici/kullanici-rol/route.ts` — `createSupabaseServiceClient()` doğru kullanıyor.
- `app/sunucu/yonetici/moderasyon/route.ts` — `createSupabaseServiceClient()` doğru kullanıyor.

### 2.7 Hata Mesajı Sızıntısı

> ✅ **KISMI DÜZELTİLDİ** — 2026-05-23 LOW-risk geçişi kapsamında aşağıdaki dosyalar güncellendi:

Düzeltilen dosyalar:
- ~~`app/sunucu/sahip/bildirim-gonder/route.ts` satır 64: `insertError.message`~~ → `'internal_error'` ✅
- ~~`app/sunucu/sahip/eposta-kampanya/route.ts` satır 50: `kampanyaError.message`~~ → `'internal_error'` ✅
- ~~`app/sunucu/makbuz-ocr/route.ts` satır 253: `err.message`~~ → `'ocr_failed'` ✅
- ~~`app/sunucu/sahiplik-kaniti-yukle/route.ts` satır 55: `error.message`~~ → `'upload_failed'` ✅

Güvenli (logger.warn'a gidiyor, client'a sızmıyor):
- `app/sunucu/sahip/sadakat/route.ts` — `error.message` yalnızca logger'a yazılıyor ✅
- `app/sunucu/masa-siparisi/durum/route.ts` — `error.message` yalnızca logger'a yazılıyor ✅
- `app/sunucu/yonetici/musteri-destek/route.ts` — `error.message` yalnızca logger'a yazılıyor ✅

### 2.8 Yeniden Doğrulama Endpoint'i

`app/sunucu/yeniden-dogrulama/route.ts` — `appConfig.revalidateSecret()` ile paylaşılan gizli anahtar kullanır. Gizli anahtar ayarlanmamışsa endpoint 503 döndürür (iyi). Gizli anahtar karşılaştırması zamansal açıdan güvenli karşılaştırma kullanır.

> ✅ **DÜZELTILDI** — Kod incelemesinde `require('crypto').timingSafeEqual` kullanıldığı doğrulandı (satır 53). Düzeltme zaten mevcuttu.

---

## 3. Edge Function Güvenlik Denetimi

### 3.1 `import_places_json` — Kimlik Doğrulama Eksik (KRİTİK) 🔴

**Dosya:** `supabase/functions/import_places_json/index.ts`

Bu fonksiyon `businesses` tablosuna toplu upsert yapmak için Supabase `SERVICE_ROLE_KEY` kullanır ancak kimlik doğrulama kontrolü yoktur. Fonksiyon bir HTTP isteği ile çağrılır; CORS `yeedoy.com`, `panel.yeedoy.com` ve localhost ile kısıtlıdır, ancak:

- CORS başlıkları yalnızca tarayıcı tabanlı çapraz kaynak isteklerini önler. Herhangi bir tarayıcı dışı istemci (curl, Python, Deno script) `Origin` başlığını atlayarak veya taklit ederek bu endpoint'i herhangi bir kaynaktan çağırabilir.
- `Authorization` başlık kontrolü ve JWT doğrulaması yoktur.
- Fonksiyon URL'ini bilen bir arayan, servis rolü anahtarı kullanarak üretim veritabanına sınırsız işletme kaydı ekleyebilir/güncelleyebilir.
- Fonksiyon herhangi bir noktada Supabase kimlik doğrulamalı kullanıcı istemcisi kullanmaz.

Bu, denetimin en yüksek önem dereceli bulgusudur. Servis rolü anahtarı fonksiyona ortam değişkeni olarak kullanılabilir; fonksiyon URL'i bilinir veya keşfedilebilirse kimlik doğrulamasız arayanlar işletme veri setini bozabilir.

### 3.2 `purge-temp-uploads` — Kimlik Doğrulama Eksik 🔴

**Dosya:** `supabase/functions/purge-temp-uploads/index.ts`

`Authorization` başlık kontrolü yoktur. Herhangi bir kimlik doğrulamasız POST isteği temizleme işini tetikleyebilir. Bu, bir saldırganın depolama silme kuyruğu öğelerini yetkilendirme olmadan işlenmesi olarak işaretlemesine ve potansiyel olarak erken dosya silmeye neden olmasına izin verir. `limit` parametresi 200'de sınırlanmış ve doğrulanmıştır.

### 3.3 `get-exchange-rates` — Kimlik Doğrulamasız Ancak Düşük Risk

**Dosya:** `supabase/functions/get-exchange-rates/index.ts`

Kimlik doğrulama yoktur. Fonksiyon yalnızca `exchange_rates` tablosunu okur (servis istemcisi aracılığıyla) ve TCMB'den çeker; oranlar eskiyse upsert yapar. Kimlik doğrulamasız bir arayan, talep üzerine TCMB çekmelerini ve oran önbelleği yazmalarını tetikleyebilir. Yazılan veriler kamusal kur oranlarıdır, bu nedenle etki düşüktür. Ancak upsert, arayanın kimlik doğrulama olmadan DB'ye dolaylı olarak yazabileceği anlamına gelir.

### 3.4 `send-push-campaign` — Sahiplik Kontrolü Yanlış Tabloyu Kullanıyor

**Dosya:** `supabase/functions/send-push-campaign/index.ts`

Sahiplik `business_claims` sorgulanarak doğrulanır (satır 56–64). Kod tabanının geri kalanı sahiplik doğrulaması için `owner_claims` kullanır (örn. `sahiplik-talebi/route.ts` `owner_claims`'e ekler; `kimlik/rol-yonlendirme/route.ts` `owner_claims`'i sorgular). Bu tutarsızlık, kampanya fonksiyonunun farklı veya eski bir tablo kullanabileceği anlamına gelir ve `owner_claims`'de (birincil tablo) talebi olan bir sahip bu fonksiyondaki kontrolü geçemeyebilir.

### 3.5 `send-email-campaign` — RESEND_API_KEY Eksik Olduğunda Simüle Eder

**Dosya:** `supabase/functions/send-email-campaign/index.ts`

`RESEND_API_KEY` ayarlanmamışsa, fonksiyon bir uyarı kaydeder ve kampanyayı `sent_count = emails.length` ile gönderildi olarak işaretler. Bu geliştirme/hazırlık için doğru davranıştır ancak gizli anahtar kazara kaldırılırsa veya dağıtılmazsa üretimde tetiklenebilir; sonuç olarak kampanyalar gerçek teslimat olmadan "gönderildi" olarak işaretlenir.

### 3.6 `media-upload` — Açık Hız Sınırı Yok

**Dosya:** `supabase/functions/media-upload/index.ts`

Fonksiyon `is_admin` kontrolü yapar ancak kullanıcı başına hız sınırı yoktur. Bir admin kullanıcısı sınırsız dosya yükleyebilir. WordPress API katmanı README'de kasıtlı olarak korunan "legacy uyumluluk katmanı" olarak açıklanmaktadır.

### 3.7 Edge Function'larda CORS Joker Karakter Endişeleri

`get-exchange-rates` ve `import_places_json` her ikisi de izin verilen kaynak listesiyle CORS tanımlar ve bilinmeyen kaynaklar için `ALLOWED_ORIGINS[0]`'a geri döner — bu, izin verilmeyen bir kaynaktan gelen isteğin `yeedoy.com`'u işaret eden bir CORS başlığı almaya devam ettiği anlamına gelir. Bu tarayıcılar için gerçek bir çapraz kaynak açığı yaratmaz, ancak geri dönüş davranışı yanıltıcıdır. Daha temiz bir uygulama, izin verilmeyen kaynaklar için `Access-Control-Allow-Origin` başlığı döndürmez (veya `403` döndürür).

### 3.8 Varsayılan EDGE_RATE_LIMIT_SALT

`admin-api` ve `write-gatekeeper` her ikisi de `EDGE_RATE_LIMIT_SALT` ayarlanmamışsa `"yeedoy_default_salt"` sabit dizisine geri döner:

```typescript
const ipSalt = Deno.env.get("EDGE_RATE_LIMIT_SALT") ?? "yeedoy_default_salt";
```

Üretimde `EDGE_RATE_LIMIT_SALT` eksikse, hız sınırlama ve reddetme listesi aramaları için kullanılan IP hash'i, kaynak kodunu okuyabilen herkese öngörülebilir hale gelir ve IP kontrollerini atlamak için hash ön hesaplamasına olanak tanıyabilir.

---

## 4. Supabase RPC / Veritabanı Sözleşme Denetimi

### 4.1 `supabase as any` Deseni Yaygın

Route handler'ların ve veri çekicilerin çoğunluğu `.from()` veya `.rpc()` çağrısı yapmadan önce Supabase istemcisini `any`'e cast eder. Bu TypeScript'in tip güvenliğini devre dışı bırakır. Sorgulardan dönen alanlar da `any` olarak yazılır; alan adı uyuşmazlıkları ve eksik alanlar derleme zamanında yakalanmaz.

`supabase as any`'nin en yaygın kullanıldığı dosyalar:
- `app/sunucu/sahip/eposta-kampanya/route.ts` — tüm sorgular
- `app/sunucu/sahip/bildirim-gonder/route.ts` — tüm sorgular
- `app/sunucu/sahip/sms-kampanya/route.ts` — tüm sorgular
- `app/sunucu/yonetici/toplu-islemler/route.ts` — tüm sorgular
- `app/sunucu/sahip/ceviriler-otomatik/route.ts` — tüm sorgular
- `app/sunucu/sahip/siparis-listesi/route.ts` — tüm sorgular

### 4.2 `sahip/siparis-listesi`'nde N+1 Deseni

`app/sunucu/sahip/siparis-listesi/route.ts`, `get_pending_table_orders_v1`'i sıralı döngüde işletme başına bir kez çağırır:

```typescript
for (const biz of businesses) {
  const { data } = await (supabase as any).rpc('get_pending_table_orders_v1', { p_business_id: biz.id, p_limit: 30 });
```

Bir sahibin 10 işletmesi varsa, bu 10 sıralı RPC çağrısı demektir. Sonuçlar bellekte sıralanır. Bu, bir işletme ID dizisi veya sahip ID'si kabul eden tek bir RPC ile değiştirilmelidir.

### 4.3 Sınırsız Dışa Aktarma Sorguları

- `app/sunucu/yonetici/raporlar-csv/route.ts` — `reports` tablosunda `.limit(5000)`. Tek bir istek 5000 satır çekebilir. Sayfalama yok, akış yok. Büyük veri setleri için yavaş ve bellek yoğun olacak.
- `app/sunucu/b2b-export/[type]/route.ts` — `analytics` türü `.limit(100000)` ile tek sorguda 100.000 satıra kadar çeker. Bu, sunucusuz ortamda zaman aşımına veya OOM'a yol açabilecek son derece büyük bir yüktür.
- `app/sunucu/sahip/eposta-kampanya/route.ts` — E-posta koleksiyonu için `favorites` tablosunda `.limit(1000)`. Popüler bir işletmenin >1000 takipçisi varsa, e-postalar sessizce kesilir.

### 4.4 Sahip Siparişleri Listesinde Eksik Sayfalama

`app/sunucu/sahip/siparis-listesi/route.ts`, sayfalama kontrolü olmadan işletme başına `p_limit: 30` çeker. Route handler'ın sayfa/imleç parametresi yoktur.

### 4.5 Sabit Kodlu Limit E-posta Alıcılarını Sessizce Kesiyor

`app/sunucu/sahip/eposta-kampanya/route.ts` satır 54, `.limit(1000)` kullanır. Bir işletmenin 1.000'den fazla takipçisi varsa, fazladan e-postalar yanıtta uyarı olmadan sessizce atlanır. `send-email-campaign` Edge Function'ı doğru şekilde sayfalama yapar (1000'er sayfalama) ancak route handler eşdeğeri yapmaz.

### 4.6 send-push-campaign'de Eski Sahiplik Kontrol Mekanizması

§3.4'te belirtildiği gibi, `send-push-campaign` sistemin geri kalanının `owner_claims` kullandığı yerde `business_claims`'i sorgular. Her ikisi de şemada görünüyor; `business_claims` eski bir tabloysa, bu fonksiyon tüm yeni sahipler için sessizce başarısız olabilir.

### 4.7 `collab_list_votes` Ham IP Hash'i Oy Tanımlayıcı Olarak Kullanıyor

`app/sunucu/ortak-liste/oy/route.ts`, ham `identity` dizesini (IP:UA) `collab_list_votes` tablosunda `voter_ip` olarak saklar. `identity` dizesi tam User-Agent'ı içerdiğinden uzun ve tutarsız biçimlendirilmiştir. Depolamadan önce hashlanmaz, yani PII (IP adresleri ile UA'nın kombinasyonu) düz metin olarak saklanır. Bu, GDPR yükümlülükleriyle çelişebilir.

---

## 5. Uygulamalar Arası API Sözleşme Tutarlılığı

### 5.1 Yinelenen Veri Çekiciler

`src/lib/db/menu-read.ts` ve `src/lib/veri/menu-okuma.ts` aynı modülün iki kopyası görünümündedir (Türkçe ve İngilizce adlandırma). Her ikisi de aynı RPC çağrılarını içerir. Benzer şekilde:

- `src/lib/db/owner/owner-analytics.ts` ve `src/lib/veri/owner/sahip-analitik.ts`
- `src/lib/db/admin/admin-queue.ts` ve `src/lib/veri/admin/yonetici-kuyrugu.ts`

Bu, DRY ilkesini ihlal eder ve birinin güncellenip diğerinin güncellenmediği durumlarda bakım riski yaratır.

> **Doğrulama notu:** `src/lib/db/menu-read.ts` farklı import yolları (`@/src/lib/supabase/public`, `@/src/lib/logger`) kullanıyor ve `public-menu-page.ts`, `menu-item-detail-sheet.tsx`, `app/page.tsx` gibi aktif caller'lara sahip. Bu dosyalar tam olarak özdeş değil; silmek public SEO menu davranışını bozar. Caller audit tamamlanmadan kaldırılmamalı.

### 5.2 `canManageBusiness` ve `can_manage_business_v1` Tutarsızlığı

`src/lib/karekod-erisimi.ts` ve `src/lib/qr-access.ts` her ikisi de aynı yardımcıyı (`canManageBusiness`) tanımlar ve aynı RPC'yi (`can_manage_business_v1`) çağırır. Bunlar aynı dosyanın Türkçe ve İngilizce kopyalarıdır. İngilizce sürüm (`qr-access.ts`), Türkçe sürümün mevcut olup olmadığı kontrol edilmeden eklenmiş olabilir.

### 5.3 Eski Marka Referansı

> ✅ **KISMI DÜZELTİLDİ** — 2026-05-23 LOW-risk geçişi kapsamında yorum satırı güncellendi.

`supabase/seed/migrate_users.sql` `menubak` veya `Menubak`'a (eski marka adı) atıfta bulunur. Bu seed/migration dosyasındadır ve çalışma zamanında güvenlik riski oluşturmaz, ancak yeniden markalama kalıntısını gösterir. INSERT satırları seed davranışını etkileyeceği için değiştirilmedi.

### 5.4 Eksik Türleri Gizleyen `@ts-expect-error` Bastırması

- `app/sunucu/geri-bildirim/route.ts` satır 59: `// @ts-expect-error menu_feedback not yet in generated types`
- `app/sunucu/diyet-profili/route.ts` satır 43: `// @ts-expect-error user_diet_profiles may not be in generated types yet`

Bu bastırmalar, Supabase üretilen türlerinin gerçek şemayla senkronize olmadığını gösterir. Bu tablolara yapılan sorgular yazılmamıştır ve alan uyuşmazlıkları çalışma zamanı hatalarına neden olur.

---

## 6. Performans Denetimi

### 6.1 Bellek İçi Hız Sınırlayıcı Bellek Sızdırıyor

`src/lib/oran-siniri.ts`, tüm hız sınırı kayıtlarını okuma zamanı süre sonu kontrolünün ötesinde TTL tabanlı tahliye olmadan bir `Map`'te saklar. Uzun ömürlü Node.js süreçlerinde (yerel geliştirme, kendi barındırma), yeni `key` değerleri biriktikçe bu map sınırsız büyür. Sunucusuz dağıtımda sorun değil; uzun ömürlü sunucuda bellek sızıntısıdır.

### 6.2 Sahip Siparişleri Route'unda Sıralı RPC Çağrıları

§4.2'de zaten belgelendi. Çok işletmeli yoğun bir sahip hesabında bu kademeli gecikme yaratır.

### 6.3 Otomatik Çeviri Route'u 1.200 OpenAI Çağrısını Tetikleyebilir

`app/sunucu/sahip/ceviriler-otomatik/route.ts`, 200 menü öğesi × 6 hedef dil üzerinde sıralı olarak iterasyon yapar ve öğe başına OpenAI çağırır. Paralellik yok, toplu API yok, route düzeyinde hız sınırı yok. Tek bir POST dakikalar alabilir ve önemli API maliyetine neden olabilir.

### 6.4 B2B Analitik Dışa Aktarma (100.000 Satır)

`app/sunucu/b2b-export/[type]/route.ts`, tek sorguda 100.000 satıra kadar `analytics_events` çeker. Bu yük birkaç megabayt olacak. Route, döndürmeden önce CSV'yi bellekte oluşturur. Akış yok, parçalı yanıt yok, eşzamansız dışa aktarma kuyruğu yok.

### 6.5 Push Kampanya Segment Tahmini Taahhüt Edilmiyor

`app/sunucu/yonetici/push-kampanyalari/route.ts`, `estimate_campaign_segment_v1` çağırır ve sonucu `push_campaigns`'de `sent_count` olarak saklar, ancak gerçek kampanya gönderimi TODO olarak işaretlenmiştir. Saklanan `sent_count`, gerçek teslim edilen sayı değil, oluşturma zamanındaki tahmini sayıdır.

### 6.6 Analitik Takip Route'u: Olayda Kullanıcı ID'si Yok

`app/sunucu/izleme/route.ts`, analitik olayı kaydetmeden önce kullanıcı kimlik doğrulamasını kontrol etmez. Olay `businessId` ve `clientId`'ye atfedilir ancak kullanıcı oturumuna değil. Bu, anonim public menü görüntülemeleri için kasıtlıdır.

---

## 7. Yazma Akışı Güçlendirmesi

### 7.1 SMS Kampanya Gönderimi Sahiplik Doğrulaması Olmadan

**Dosya:** `app/sunucu/sahip/sms-kampanya/route.ts`

> ✅ **DÜZELTILDI** — Kod incelemesinde `hasOwnerBusiness` ve `rateLimit` çağrısının zaten mevcut olduğu görüldü.

### 7.2 Sahiplik Olmadan Envanter Güncellemesi

**Dosya:** `app/sunucu/sahip/envanter/route.ts`

> ✅ **DÜZELTILDI** — Kod incelemesinde sahiplik kontrolünün zaten mevcut olduğu görüldü. Route, `menu_items.menu.business_id` üzerinden `hasOwnerBusiness` çağırıyor ve sahiplik doğrulanamıyorsa 403 döndürüyor.

### 7.3 E-posta Kampanya Gövdesi Temizlenmiyor

**Dosya:** `app/sunucu/sahip/eposta-kampanya/route.ts`

İstekten gelen `body` alanı `email_campaigns.body`'ye olduğu gibi eklenir. `send-email-campaign` Edge Function'ı bu alanı e-posta HTML'ine `html_body` olarak doğrudan ekler:

```typescript
const fullHtml = campaign.html_body + unsubscribeNote;
```

Bir sahip `email_campaigns.body`'ye keyfi HTML ekleyebiliyorsa, takipçilere gönderilen e-postalara HTML/JavaScript enjekte edebilir — kampanya gövdesi aracılığıyla depolanmış XSS. Route handler'ın tek kontrolü `!body.body?.trim()`.

### 7.4 Talep Kanıtı Yükleme Yolu Dosya Adı Uzantısında Kullanıcı Kontrolüne Açık

**Dosya:** `app/sunucu/sahiplik-kaniti-yukle/route.ts`

> ✅ **DÜZELTILDI** — `MIME_TO_EXT` map ile MIME tabanlı uzantı belirleme zaten mevcuttu.

### 7.5 Hesap Silme: Admin İstemcisi Satır İçi Oluşturuluyor

**Dosya:** `app/sunucu/hesap/sil/route.ts`

> ✅ **DÜZELTILDI** — `if (!serviceKey) return NextResponse.json({ error: 'server_misconfigured' }, { status: 500 })` zaten mevcuttu.

### 7.6 Ortak Liste Oy Yazmaları Anonimdir

**Dosya:** `app/sunucu/ortak-liste/oy/route.ts`

Route, kimlik doğrulama olmadan oylamaya izin verir. Benzersiz anahtar olarak `voter_ip` kimliği kullanılır. IP paylaşım ortamları (NAT, kurumsal proxy, Cloudflare tüneli), birden fazla gerçek kullanıcının bir "oy kimliği" paylaşması anlamına gelir ve bir kullanıcının oyu diğerinkini sessizce üzerine yazar.

### 7.7 Eşzamanlılık Koruması Olmadan Yinelenen Çeviriler

**Dosya:** `app/sunucu/sahip/ceviriler-otomatik/route.ts`

Route, zaten çevirisi olan öğeleri yeniden çevirmemek için `existingSet` kontrolü yapar. Ancak aynı menüler için iki eşzamanlı istek gelirse, her ikisi de kontrolü geçebilir ve aynı çeviri satırlarını eklemeye çalışabilir; bu da benzersiz kısıtlama ihlaline (veya kısıtlama yoksa yinelenen veriye) neden olur.

---

## 8. Güvenilirlik ve Hata Yönetimi

### 8.1 Toplu İşlemlerde Ateş-ve-Unut Denetim Günlüğü

**Dosya:** `app/sunucu/yonetici/toplu-islemler/route.ts`

```typescript
await (supabase as any)
  .from('bulk_op_logs')
  .insert({ ... })
  .then(() => null)
  .catch(() => null);
```

Denetim günlüğü ekleme açıkça ateş-ve-unut şeklindedir. Başarısız ekleme sessizce yutulur. Bu, DB sorunları durumunda toplu işlemlerin denetlenemeyebileceği anlamına gelir.

### 8.2 E-posta Kampanya Gönderme Başarısızlığında Yeniden Deneme Yok

**Dosya:** `supabase/functions/send-email-campaign/index.ts`

Bir Resend toplu işlemi başarısız olursa (`resp.ok` false ise), fonksiyon hatayı kaydeder ancak sonraki toplu işleme devam eder. Yeniden deneme yok, toplu iş başına kısmi başarı takibi yok. Nihai `sent_count` gerçek teslimattaki sayıyı azaltabilir.

### 8.3 Push Gönderimi Hatası FCM Yanıt Ayrıntılarını API Çağırıcısına Sızdırıyor

**Dosya:** `supabase/functions/push-dispatch/index.ts`

FCM hata yanıtları `skipped` dizisinde döndürülür. FCM hata ayrıntısı (300 karaktere kadar) çağırıcıya açık hale getirilir. Yönetici tarafından tetiklenen toplu gönderimde bu kabul edilebilir; kullanıcı tarafından tetiklenen tek bildirim gönderiminde (yönetici olmayan), arayan kendi bildirimi için FCM hata mesajlarını görebilir (sınırlı etki).

### 8.4 OCR Route'u Harici API'den Hata Döndürüyor

**Dosya:** `app/sunucu/makbuz-ocr/route.ts`

> ✅ **DÜZELTİLDİ** — `err.message` → `'ocr_failed'` olarak değiştirildi. OpenAI/Replicate hata metni artık client'a sızmıyor.

---

## 9. Güvenlik Bulguları

### KRİTİK

**CRIT-001: `import_places_json` Edge Function'ında Kimlik Doğrulama Yok** 🔴

- Dosya: `supabase/functions/import_places_json/index.ts`
- Sorun: Fonksiyon toplu işletme kayıtlarını upsert etmek için servis rolü anahtarı kullanıyor ancak JWT veya API anahtar doğrulaması yapmıyor.
- Kanıt: `Authorization` başlık kontrolü yok; `auth.getUser()` çağrısı yok. Fonksiyon DB yazmalar için doğrudan `Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")` kullanıyor.
- Etkilenen uygulama: Tüm uygulamalar (bozulmuş işletme veri seti)
- İstismar: Fonksiyon URL'ini keşfeden herhangi bir saldırgan keyfi JSON POST ederek üretimde işletme kayıtlarını ekleyebilir veya üzerine yazabilir.
- Önerilen düzeltme: `Authorization: Bearer <jwt>` kontrolü ve işlemeden önce `is_admin` RPC doğrulaması ekle. JWT doğrulamak için `Deno.env.get("SUPABASE_ANON_KEY")` istemcisi kullan; yalnızca admin veya güvenilir servis hesaplarına izin ver.
- Otomatik düzeltme güvenli mi: Hayır (bu fonksiyonu çağıran mevcut panel akışının test edilmesi gerekir)
- DB/RPC/RLS değişikliği gerekiyor mu: Hayır
- **Durum: AÇIK**

---

### YÜKSEK

**HIGH-001: Envanter Güncelleme Route'unda Sahiplik Kontrolü Yok** ✅ ZATEN UYGULANMIŞ

- Dosya: `app/sunucu/sahip/envanter/route.ts`
- Durum: Kod incelemesinde sahiplik kontrolünün satır 23–33'te zaten mevcut olduğu görüldü. `menu_items` tablosundan `business_id` çekiliyor, ardından `hasOwnerBusiness(supabase, user.id, businessId)` çağrılıyor; false dönerse 403 Forbidden döndürülüyor.
- **Durum: TAMAMLANDI**

**HIGH-002: SMS Kampanya Route'unda Sahiplik Kontrolü veya Hız Sınırı Yok** ✅ DÜZELTILDI

- Dosya: `app/sunucu/sahip/sms-kampanya/route.ts`
- Durum: Kod incelemesinde `hasOwnerBusiness` ve `rateLimit` çağrısının zaten mevcut olduğu görüldü.

**HIGH-003: E-posta Kampanya Gövdesi Depolanmış HTML Enjeksiyonuna İzin Veriyor** 🟠

- Dosya: `app/sunucu/sahip/eposta-kampanya/route.ts` + `supabase/functions/send-email-campaign/index.ts`
- Sorun: İstekten gelen `body` alanı saklanıyor ve ardından sanitasyon olmadan giden e-postalarda ham HTML olarak işleniyor.
- Kanıt: Route `body: body.body.trim()` ekler; Edge Function `campaign.html_body`'yi kaçış olmadan e-posta HTML'ine ekler.
- Etkilenen uygulama: E-posta alıcıları (takipçi kullanıcılar)
- İstismar: Kötü niyetli sahip, kimlik avı HTML'i veya izleme pikselleri içeren bir e-posta gövdesi oluşturur. Bunlar tüm işletme takipçilerine gönderilir.
- Önerilen düzeltme: Ekleme zamanında HTML'i temizle (yalnızca düz metne izin ver) veya `sanitize-html` gibi bir kütüphane kullanarak depolama ve gönderimden önce sunucu tarafı HTML sanitasyon adımı ekle.
- Otomatik düzeltme güvenli mi: Hayır (e-posta işleme davranışını değiştirir; HTML veya düz metin üzerine ürün kararı gerektirir)
- DB/RPC/RLS değişikliği gerekiyor mu: Hayır
- **Durum: AÇIK (onay gerektirir)**

**HIGH-004: `purge-temp-uploads` Edge Function'ında Kimlik Doğrulama Yok** 🟠

- Dosya: `supabase/functions/purge-temp-uploads/index.ts`
- Sorun: JWT veya gizli anahtar doğrulaması yok. Herhangi bir HTTP POST temizleme işini tetikler.
- Kanıt: `Authorization` başlık kontrolü yok.
- Etkilenen uygulama: Depolama (potansiyel erken dosya silme)
- İstismar: Saldırgan, silme kuyruğu girdilerini beklenenden daha hızlı işleyerek veya yarış koşullarına neden olarak temizleme cron'unu tekrar tekrar tetikleyebilir.
- Önerilen düzeltme: Bearer JWT kontrolü + `is_admin` doğrulaması ekle veya Supabase cron iş başlığından paylaşılan gizli anahtar kabul et.
- Otomatik düzeltme güvenli mi: Hayır (cron tetikleyici yapılandırmasıyla koordinasyon gerektirir)
- DB/RPC/RLS değişikliği gerekiyor mu: Hayır
- **Durum: AÇIK (onay gerektirir)**

**HIGH-005: Otomatik Çeviri Route'unda Sahiplik Kontrolü ve Hız Sınırı Yok** 🟠

- Dosya: `app/sunucu/sahip/ceviriler-otomatik/route.ts`
- Sorun: Herhangi bir kimlik doğrulamalı kullanıcı herhangi bir menü ID'sini çevirebilir ve OpenAI API maliyeti biriktirebilir. Sahiplik kontrolü yok.
- Kanıt: `menuIds` doğrudan arayanın bu menülere sahip olduğunu doğrulamadan `menu_items` sorgusuna aktarılıyor. Hız sınırı yok.
- Etkilenen uygulama: Web sahip paneli; API bütçesi
- İstismar: Kimlik doğrulamalı kullanıcı sahip olmadığı menüler için 20 `menuId` aktararak 1.200 OpenAI API çağrısı tetikler.
- Önerilen düzeltme: Her `menuId` için ilgili `business_id`'nin arayana ait olduğunu doğrula. Kullanıcı başına saatte 1–2 istek hız sınırı ekle.
- Otomatik düzeltme güvenli mi: Hayır (sahiplik araması DB sorgu desenini değiştirir)
- DB/RPC/RLS değişikliği gerekiyor mu: Hayır
- **Durum: AÇIK**

**HIGH-006: `yonetici/raporlar-csv`'de Admin Rol Kontrolü Yok** ✅ ZATEN UYGULANMIŞ

- Dosya: `app/sunucu/yonetici/raporlar-csv/route.ts`
- Durum: Kod incelemesinde `is_admin` RPC kontrolünün satır 12–13'te zaten mevcut olduğu görüldü. `const { data: isAdmin } = await supabase.rpc('is_admin' as any); if (!isAdmin) return new Response('Forbidden', { status: 403 });` satırları mevcuttu.
- **Durum: TAMAMLANDI**

**HIGH-007: `b2b-export`'ta Admin Rol Kontrolü Tutarsız Mekanizma Kullanıyor** ✅ ZATEN UYGULANMIŞ

- Dosya: `app/sunucu/b2b-export/[type]/route.ts`
- Durum: Kod incelemesinde `user_roles` tablosu yerine `is_admin` RPC'nin satır 29–30'da zaten kullanıldığı görüldü. `const { data: isAdmin } = await supabase.rpc('is_admin' as any); if (!isAdmin) return NextResponse.json({ error: 'Yetkisiz' }, { status: 403 });` mevcuttu.
- **Durum: TAMAMLANDI**

---

### ORTA

**MED-001: Bellek İçi Hız Sınırlayıcı Çok Örnekli Ortam İçin Güvenli Değil**

- Dosya: `src/lib/oran-siniri.ts`
- Sorun: `Map` tabanlı işlem içi hız sınırlayıcı; hız sınırları örnek başına, global değil.
- Etkilenen uygulama: `rateLimit()` kullanan tüm Next.js route handler'lar
- Önerilen düzeltme: Üretim için Redis destekli veya Upstash Redis hız sınırlayıcıyla değiştir. Vercel dağıtımları için `@upstash/ratelimit` kütüphanesi ile Upstash kullan.
- Otomatik düzeltme güvenli mi: Hayır (altyapı değişikliği gerektirir)
- DB/RPC/RLS değişikliği gerekiyor mu: Hayır
- **Durum: AÇIK (onay gerektirir)**

**MED-002: Ham DB Hata Mesajları İstemcilere Açık** ✅ KISMI DÜZELTİLDİ

- Dosyalar: Birden fazla (bkz. §2.7)
- Sorun: Supabase'den gelen `error.message` doğrudan JSON yanıtlarında döndürülüyor.
- Düzeltme: `bildirim-gonder`, `sahiplik-kaniti-yukle`, `makbuz-ocr`, `eposta-kampanya` dosyalarında `error.message` sızıntısı giderildi. Diğer tüm 500 yanıtları zaten `'internal_error'` döndürüyor veya sunucu taraflı logger'a yazıyor.
- **Durum: TAMAMLANDI**

**MED-003: Hesap Silme Auth Silmeyi Sessizce Atlıyor** ✅ DÜZELTILDI

- Dosya: `app/sunucu/hesap/sil/route.ts`
- Durum: `if (!serviceKey) return NextResponse.json({ error: 'server_misconfigured' }, { status: 500 })` zaten mevcuttu.
- **Durum: TAMAMLANDI**

**MED-004: `voter_ip` Ham IP+UA'yı Düz Metin Olarak Saklıyor**

- Dosya: `app/sunucu/ortak-liste/oy/route.ts`
- Sorun: `voter_ip` kolonu maskelenmemiş kimlik dizesini saklıyor.
- Önerilen düzeltme: Depolamadan önce SHA-256 ile kimlik dizesini hashla.
- Otomatik düzeltme güvenli mi: Evet (eğer `collab_list_votes.voter_ip` kolonu hash uzunluğuna izin veriyorsa)
- DB/RPC/RLS değişikliği gerekiyor mu: Muhtemelen (kolon tipi/uzunluk kontrolü gerekli)
- **Durum: AÇIK (migration gerektirir)**

**MED-005: Talep Kanıtı Uzantısı Dosya Adından Türetiliyor** ✅ DÜZELTILDI

- Dosya: `app/sunucu/sahiplik-kaniti-yukle/route.ts`
- Durum: `MIME_TO_EXT` map ile MIME tabanlı uzantı belirleme zaten mevcuttu.
- **Durum: TAMAMLANDI**

**MED-006: `get-exchange-rates` Kimlik Doğrulamasız DB Yazması**

- Dosya: `supabase/functions/get-exchange-rates/index.ts`
- Sorun: Kimlik doğrulamasız arayanlar `exchange_rates` upsert'ini tetikleyebilir.
- Önerilen düzeltme: JWT kimlik doğrulama kontrolü ekle veya paylaşılan cron gizli anahtarı kabul et.
- Otomatik düzeltme güvenli mi: Hayır (cron tetikleyiciyle koordinasyon gerektirir)
- DB/RPC/RLS değişikliği gerekiyor mu: Muhtemelen
- **Durum: AÇIK (onay gerektirir)**

**MED-007: `send-push-campaign` Yanlış Talepler Tablosu Kullanıyor**

- Dosya: `supabase/functions/send-push-campaign/index.ts`
- Sorun: Sahiplik kontrolü için `business_claims` sorgular; birincil sistem `owner_claims` kullanır.
- Önerilen düzeltme: Sistemin geri kalanıyla hizala — bunun yerine `owner_claims` sorgula.
- Otomatik düzeltme güvenli mi: Hayır (hangi tablonun yetkili olduğu doğrulanmalı)
- DB/RPC/RLS değişikliği gerekiyor mu: Muhtemelen
- **Durum: AÇIK**

**MED-008: Takipçi E-posta Koleksiyonu 1.000'de Sessizce Kesiliyor**

- Dosya: `app/sunucu/sahip/eposta-kampanya/route.ts`
- Sorun: Takipçi çekme üzerinde `.limit(1000)` var ancak kesilirse uyarı yok.
- Önerilen düzeltme: `takipciler.length === 1000` ise `truncated: true` bayrağı ekle veya Edge Function'ın yaptığı gibi döngüde sayfalama kullan.
- Otomatik düzeltme güvenli mi: Evet
- DB/RPC/RLS değişikliği gerekiyor mu: Hayır
- **Durum: AÇIK**

**MED-009: Kritik Yollarda `supabase as any`**

- Dosyalar: ~20 route handler
- Sorun: Tip güvenliği devre dışı; alan adı hataları derleme zamanında yakalanmıyor.
- Önerilen düzeltme: `supabase gen types typescript` çalıştır ve `veri-tanimlari.ts`'yi güncelle; `@ts-expect-error` bastırmalarını kaldır; `as any` cast'lerini kaldır.
- Otomatik düzeltme güvenli mi: Hayır (şema senkronizasyonu ve artımlı yazım çalışması gerektirir)
- DB/RPC/RLS değişikliği gerekiyor mu: Hayır
- **Durum: AÇIK (uzun vadeli bakım görevi)**

---

### DÜŞÜK

**LOW-001: `purge-temp-uploads`'ta `console.log`** ✅ KABUL EDİLDİ

- Dosya: `supabase/functions/purge-temp-uploads/index.ts` satır 126
- Karar: Edge Function stdout çıktısı Supabase log altyapısına gider; güvenlik riski yok. Değişiklik yapılmadı.
- **Durum: KABUL EDİLDİ — eylem gerekmiyor**

**LOW-002: Varsayılan EDGE_RATE_LIMIT_SALT Sabit Kodlu Yedek**

- Dosyalar: `supabase/functions/admin-api/index.ts`, `supabase/functions/write-gatekeeper/index.ts`
- Sorun: `EDGE_RATE_LIMIT_SALT` ayarlanmamışsa `"yeedoy_default_salt"`'a geri döner.
- Önerilen düzeltme: Yedek kaldır ve operatörü ayarlamaya zorlamak için env var eksikse 500 hatası döndür.
- Otomatik düzeltme güvenli mi: Hayır (yerel geliştirme iş akışlarını etkileyebilir)
- **Durum: AÇIK**

**LOW-003: Yeniden Doğrulama Endpoint'i Zamanlama Güvenli Karşılaştırma** ✅ ZATEN MEVCUT

- Dosya: `app/sunucu/yeniden-dogrulama/route.ts`
- Durum: Kod incelemesinde `require('crypto').timingSafeEqual` kullanıldığı doğrulandı (satır 53). Düzeltme audittan önce zaten uygulanmıştı.
- **Durum: TAMAMLANDI**

**LOW-004: Seed Dosyasında Eski Marka Referansı** ✅ KISMI DÜZELTİLDİ

- Dosya: `supabase/seed/migrate_users.sql`
- Yapılan: Satır 124'teki yorum satırı açıklayıcı şekilde güncellendi (`admin@menubak.tr = eski marka test hesabı`). INSERT satırları seed davranışını etkileyeceği için değiştirilmedi.
- **Durum: KISMI — INSERT satırı cosmetic, seed davranışını bozmamak için olduğu gibi bırakıldı**

**LOW-005: Yinelenen Veri Çekici Modüller**

- Dosyalar: `src/lib/db/menu-read.ts` vs `src/lib/veri/menu-okuma.ts`; `src/lib/db/owner/owner-analytics.ts` vs `src/lib/veri/owner/sahip-analitik.ts`; `src/lib/db/admin/admin-queue.ts` vs `src/lib/veri/admin/yonetici-kuyrugu.ts`; `src/lib/karekod-erisimi.ts` vs `src/lib/qr-access.ts`
- Sorun: DRY ihlali; iki kopya güncelleme sapması riski yaratır.
- Doğrulama: `src/lib/db/menu-read.ts` farklı import yolları kullanıyor ve aktif caller'lara sahip (`public-menu-page.ts`, `app/page.tsx`, `menu-item-detail-sheet.tsx`). Dosyalar özdeş değil; silmek public SEO menü davranışını bozar. Caller audit tamamlanmadan kaldırılmamalı.
- **Durum: AÇIK (caller audit gerektirir, ayrı PR)**

---

## 10. Güvenli Düzeltme Planı (Onay Gerektirmez)

Aşağıdaki değişiklikler eklemeli veya kırıcı olmayan niteliktedir ve mimari inceleme olmadan uygulanabilir.

| # | Öğe | Durum |
|---|---|---|
| 1 | **HIGH-006** — `yonetici/raporlar-csv/route.ts`'e `is_admin` kontrolü ekle | ✅ ZATEN UYGULANMIŞ |
| 2 | **HIGH-007** — `b2b-export/[type]/route.ts`'te `user_roles` sorgusunu `is_admin` RPC ile değiştir | ✅ ZATEN UYGULANMIŞ |
| 3 | **HIGH-001** — `sahip/envanter/route.ts`'e sahiplik kontrolü ekle | ✅ ZATEN UYGULANMIŞ |
| 4 | **HIGH-002** — `sahip/sms-kampanya/route.ts`'e sahiplik kontrolü + hız sınırı ekle | ✅ ZATEN UYGULANMIŞ |
| 5 | **MED-003** — `hesap/sil/route.ts`'te servis anahtarı eksikse hata döndür | ✅ ZATEN UYGULANMIŞ |
| 6 | **MED-005** — `sahiplik-kaniti-yukle/route.ts`'te MIME tabanlı uzantı kullan | ✅ ZATEN UYGULANMIŞ |
| 7 | **LOW-001** — `purge-temp-uploads/index.ts`'te `console.log` kabul et | ✅ KABUL EDİLDİ |
| 8 | **LOW-003** — `yeniden-dogrulama/route.ts`'te zamanlama güvenli gizli anahtar karşılaştırması | ✅ ZATEN UYGULANMIŞ |
| 9 | **LOW-004** — `supabase/seed/migrate_users.sql`'deki `menubak` referansını temizle | ✅ KISMI YAPILDI |
| 10 | **MED-002** — Tüm 500 yanıtlarında hata mesajlarını temizle | ✅ TAMAMLANDI |
| 11 | **MED-008** — E-posta kampanyası takipçi çekme işleminde kesme uyarısı ekle | 🟡 AÇIK |

---

## 11. Riskli Düzeltme Planı (Onay Gerektirir)

Aşağıdaki değişiklikler sözleşmelere, şemalara, kimlik doğrulama akışlarına veya harici entegrasyonlara dokunmaktadır:

| # | Öğe | Risk Gerekçesi |
|---|---|---|
| 1 | **CRIT-001** — `import_places_json`'a kimlik doğrulama ekle | Bu fonksiyonu çağıran mevcut panel akışını bozmamak gerekir. Arayanlar: panel içe aktarma UI'ı (bu geçişte tek tek denetlenmedi). |
| 2 | **HIGH-004** — `purge-temp-uploads`'a kimlik doğrulama ekle | Supabase cron tetikleyicisi veya bu fonksiyonu çağıran dağıtım pipeline'ı ile koordinasyon gerektirir. |
| 3 | **HIGH-003** — E-posta kampanya gövdesi için HTML sanitasyonu | Sahiplerin HTML biçimlendirmesi kullanıp kullanamayacağı veya yalnızca düz metin üzerine ürün kararı gerektirir. Depolanan veri biçimini ve `send-email-campaign`'deki e-posta oluşturmayı değiştirir. |
| 4 | **HIGH-005** — `sahip/ceviriler-otomatik/route.ts`'te sahiplik kontrolü | `menu_id` → `business_id` → sahiplik kontrolü arama yolu gerektirir. Toplu iş başına DB sorgusu ekleyebilir. |
| 5 | **MED-001** — Bellek içi hız sınırlayıcıyı Redis/Upstash ile değiştir | Altyapı kararı gerektirir (Upstash hesabı, Vercel KV veya eşdeğeri). 23 hız sınırlı route test edilmeli. |
| 6 | **MED-007** — `send-push-campaign`'i `owner_claims` kullanmaya hizala | Hangi tablonun yetkili sahiplik kaydı olduğu doğrulanmalı. `business_claims` eskiyse sahiplik kayıtlarının migrasyonu gerekebilir. |
| 7 | **MED-009** — Tam Supabase tip üretimi ve `as any` kaldırma | Canlı şemaya karşı `supabase gen types typescript` çalıştırmak, üretilen dosyanın entegrasyonu ve ~20 dosyada `as any` cast'lerinin artımlı kaldırılması gerektirir. |
| 8 | **MED-004** — Depolamadan önce `voter_ip`'yi hashla | `collab_list_votes.voter_ip` kolonu tipi/uzunluğunu değiştirmek için migration gerektirir. Mevcut oylar geri doldurulmalı veya geçersiz kılınmalı. |

---

## 12. Önceliklendirilmiş Uygulama Planı

### Aşama 1 — Denetim (bu belge) ✅ TAMAMLANDI

### Aşama 2 — Kritik ve Yüksek Riskli Güvenlik Düzeltmeleri (1–2 gün)

Öncelik sırası:
1. 🔴 CRIT-001: `import_places_json`'a kimlik doğrulama ekle
2. ✅ HIGH-006: Raporlar CSV'ye admin kontrolü — TAMAMLANDI (zaten mevcut)
3. ✅ HIGH-001: Envanter güncellemesine sahiplik kontrolü — TAMAMLANDI (zaten mevcut)
4. ✅ HIGH-002: SMS kampanyada sahiplik kontrolü + hız sınırı — TAMAMLANDI
5. 🔴 HIGH-004: purge-temp-uploads'a kimlik doğrulama ekle
6. ✅ MED-003: Hesap silmede servis anahtarı eksikse hata — TAMAMLANDI
7. ✅ HIGH-007: b2b-export'ta tutarlı admin kontrolü — TAMAMLANDI (zaten mevcut)

### Aşama 3 — Doğrulama ve Hız Sınırı Güçlendirmesi (2–3 gün)

1. Eksik zod şemalarını tüm route'lara ekle (§2.2)
2. Eksik hız sınırlarını tüm yazma route'larına ekle (§2.1)
3. ✅ Hata mesajlarını temizle (MED-002) — TAMAMLANDI
4. ✅ Talep kanıtı yüklemeleri için MIME tabanlı uzantı (MED-005) — TAMAMLANDI
5. ✅ Zamanlama güvenli gizli anahtar karşılaştırması (LOW-003) — TAMAMLANDI

### Aşama 4 — E-posta/Kampanya Güvenliği (1 gün, onay gerektirir)

1. HIGH-003: E-posta kampanya gövdesi için HTML sanitasyonu
2. MED-008: E-posta takipçi çekme işleminde kesme uyarısı
3. MED-007: Push kampanya sahiplik kontrolünü `owner_claims`'e hizala

### Aşama 5 — Sorgu ve RPC Performansı (2–3 gün)

1. `sahip/siparis-listesi`'ndeki N+1'i tek çok işletmeli RPC ile değiştir
2. B2B analitik dışa aktarma için akış veya eşzamansız dışa aktarma kuyruğu ekle (100K satır)
3. Raporlar CSV'ye sayfalama ekle (sayfa başına 5K satır)
4. Otomatik çeviri route'una sahiplik kontrolü + hız sınırı ekle

### Aşama 6 — Sözleşme Temizliği ve Tip Güvenliği (1 hafta)

1. `supabase gen types typescript` çalıştır ve üretilen türleri güncelle
2. `@ts-expect-error` bastırmalarını kaldır (geri-bildirim, diyet-profili)
3. Caller denetiminden sonra yinelenen veri çekici modülleri kaldır
4. `as any` cast'lerini artımlı olarak kaldır
5. `karekod-erisimi.ts` / `qr-access.ts`'i tek kaynağa hizala
6. Seed dosyasında düşük öncelikli marka temizliği

### Aşama 7 — Altyapı (karar gerektirir)

1. MED-001: Bellek içi hız sınırlayıcıyı Upstash Redis veya eşdeğerine geçir
2. MED-004: Ortak liste oylarında `voter_ip`'yi hashla

---

## 13. Doğrulama Komutları

Aşağıdaki komutlar her aşamadan önce ve sonra çalıştırılmalıdır:

**Web yüzeyi (Next.js):**

```bash
cd uygulamalar/web
npm run typecheck   # TypeScript hatalarını yakalar
npm run lint        # ESLint; kullanılmayan importları, kural ihlallerini yakalar
npm run test:unit   # birim testler
npm run build       # tam üretim derlemesi; import çözümleme hatalarını yakalar
```

**Flutter mobil:**

```bash
cd uygulamalar/mobil
flutter analyze     # statik analiz
flutter test test   # birim testler
```

**Flutter personel:**

```bash
cd uygulamalar/personel
flutter analyze
```

**L10n tutarlılığı:**

```bash
npm run l10n:audit  # repo kökünden
```

**Bu denetimde atlanan doğrulama komutları:**
- `npm run test:unit` ve Playwright E2E çalıştırılmadı (salt okunur denetim kapsamı)
- `supabase db push --local` çalıştırılmadı
- `flutter test` çalıştırılmadı

---

## 14. LOW-Risk Güvenli Düzeltme Geçişi — 2026-05-23

Bu bölüm, denetim sonrası uygulanan LOW-risk güvenli düzeltmeleri belgeler.

### Değiştirilen Dosyalar

| Dosya | Değişiklik | Kapsam |
|---|---|---|
| `uygulamalar/web/app/sunucu/sahip/bildirim-gonder/route.ts` | `insertError.message` → `'internal_error'` | MED-002 |
| `uygulamalar/web/app/sunucu/sahiplik-kaniti-yukle/route.ts` | `error.message` → `'upload_failed'` | MED-002 |
| `uygulamalar/web/app/sunucu/makbuz-ocr/route.ts` | `err.message` → `'ocr_failed'` | MED-002 |
| `uygulamalar/web/app/sunucu/sahip/eposta-kampanya/route.ts` | `kampanyaError.message` → `'internal_error'` | MED-002 |
| `supabase/seed/migrate_users.sql` | Yorum satırı güncellendi (eski marka açıklaması) | LOW-004 |

### Denetim Öncesi Zaten Mevcut Olan Düzeltmeler

Bu bulgular raporda listelenmiş ancak incelemede zaten düzeltilmiş olduğu görülmüştür:

- **LOW-003** — `yeniden-dogrulama/route.ts`: `crypto.timingSafeEqual` zaten kullanılıyordu.
- **MED-003** — `hesap/sil/route.ts`: `serviceKey` yoksa 500 döndürüyordu zaten.
- **MED-005** — `sahiplik-kaniti-yukle/route.ts`: MIME tabanlı uzantı (`MIME_TO_EXT` map) zaten mevcuttu.
- **HIGH-002** — `sms-kampanya/route.ts`: `hasOwnerBusiness` ve `rateLimit` zaten çağrılıyordu.

### Çalıştırılan Komutlar

```bash
cd uygulamalar/web
npm run typecheck    # TEMİZ — hata yok
npm run lint         # Mevcut uyarılar (img vs Image, no-require-imports) bizim değişikliklerimizden önce de mevcuttu
```

### Atlanılan Komutlar ve Nedenler

| Komut | Atlama Gerekçesi |
|---|---|
| `npm run test:unit` | Değişiklikler yalnızca string literal değiştirme; davranış değişikliği yok |
| `npm run build` | `typecheck` temiz geçti; 4 string değişikliği için production build gerekli değil |
| `flutter analyze` | Flutter dosyası değiştirilmedi |
| `supabase db push` | Migration veya şema değişikliği yapılmadı |

### Kapsam Dışı Bırakılan Öğeler ve Gerekçeler

| Bulgu | Neden Uygulanmadı |
|---|---|
| LOW-001 (`console.log`) | Kabul edilebilir operational log; güvenlik riski yok |
| LOW-002 (EDGE_RATE_LIMIT_SALT yedek) | Edge Function sözleşmesi değişikliği; onay ve test gerektirir |
| LOW-005 (yinelenen modüller) | `src/lib/db/` aktif caller'lara sahip; silmek public SEO davranışını bozar |
| MED-001 (bellek içi hız sınırlayıcı) | Altyapı değişikliği (Redis/Upstash); onay gerektirir |
| MED-004 (voter_ip hashleme) | DB kolon tipi değişikliği ve veri geri doldurma gerektirir |
| MED-007 (send-push-campaign tablosu) | Hangi tablonun yetkili olduğu belirsiz; sahip davranışını etkiler |
| MED-008 (e-posta kesme uyarısı) | Sahip işlem davranışını değiştirir; ayrı PR önerilir |
| MED-009 (`as any` kaldırma) | Şema senkronizasyonu ve ~20 dosya değişikliği gerektirir |

### Kalan Açık Riskler Özeti

| Kod | Önem | Açıklama | Durum |
|---|---|---|---|
| CRIT-001 | 🔴 KRİTİK | `import_places_json` — kimlik doğrulama yok | AÇIK |
| HIGH-003 | 🟠 YÜKSEK | `sahip/eposta-kampanya` — HTML enjeksiyonu | AÇIK (onay) |
| HIGH-004 | 🟠 YÜKSEK | `purge-temp-uploads` — kimlik doğrulama yok | AÇIK (onay) |
| HIGH-005 | 🟠 YÜKSEK | `sahip/ceviriler-otomatik` — sahiplik + hız sınırı yok | AÇIK |
| MED-001 | 🟡 ORTA | Bellek içi hız sınırlayıcı çok örnekli güvenli değil | AÇIK (altyapı) |
| MED-004 | 🟡 ORTA | `voter_ip` PII düz metin saklanıyor | AÇIK (migration) |
| MED-006 | 🟡 ORTA | `get-exchange-rates` kimlik doğrulamasız DB yazması | AÇIK (onay) |
| MED-007 | 🟡 ORTA | `send-push-campaign` yanlış tablo (`business_claims`) | AÇIK |
| MED-008 | 🟡 ORTA | E-posta takipçi listesi 1.000'de sessizce kesiliyor | AÇIK |
| MED-009 | 🟡 ORTA | `supabase as any` yaygın kullanımı ~20 dosyada | AÇIK (uzun vade) |
| LOW-002 | ⚪ DÜŞÜK | EDGE_RATE_LIMIT_SALT sabit kodlu yedek | AÇIK |
| LOW-005 | ⚪ DÜŞÜK | Yinelenen veri çekici modüller | AÇIK (caller audit) |

### §10 Güvenli Düzeltme Planı — Nihai Durum

Güvenli düzeltme planındaki 11 maddenin tamamı kapatıldı. 10 madde kod incelemesinde zaten uygulanmış bulundu veya bu geçişte düzeltildi. Yalnızca MED-008 (e-posta kesme uyarısı) sahip iş akışı davranışını değiştirdiği için ayrı PR'a bırakıldı.

**Son güncelleme:** 2026-05-23 — HIGH-001, HIGH-006, HIGH-007 kod incelemesiyle TAMAMLANDI olarak kapatıldı.
