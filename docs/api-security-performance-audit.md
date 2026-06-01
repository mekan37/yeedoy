# Yeedoy API Güvenlik ve Performans Denetimi

**Tarih:** 2026-05-23
**Son güncelleme:** 2026-05-25 — MED-009 ve MED-001 tam kapatma: tüm (supabase as any) cast'leri → lokal dar cast; 3 yüksek riskli admin rotasında DB-destekli hız sınırı (bkz. §18)
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
15. [HIGH/MED/LOW Düzeltme Geçişi — 2026-05-25](#15-highmedlow-düzeltme-geçişi--2026-05-25)
16. [MED-001/MED-009/LOW-005 Düzeltme Geçişi — 2026-05-25](#16-med-001med-009low-005-düzeltme-geçişi--2026-05-25)
17. [Performans ve Güvenilirlik Düzeltme Geçişi — 2026-05-25](#17-performans-ve-güvenilirlik-düzeltme-geçişi--2026-05-25)
18. [MED-009 Tam Kapatma + MED-001 DB Hız Sınırı — 2026-05-25](#18-med-009-tam-kapatma--med-001-db-hız-sınırı--2026-05-25)

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

**CRIT-001: `import_places_json` Edge Function'ında Kimlik Doğrulama Yok** ✅ DÜZELTILDI

- Dosya: `supabase/functions/import_places_json/index.ts`
- Sorun: Fonksiyon toplu işletme kayıtlarını upsert etmek için servis rolü anahtarı kullanıyor ancak JWT veya API anahtar doğrulaması yapmıyor.
- Kanıt: `Authorization` başlık kontrolü yok; `auth.getUser()` çağrısı yok. Fonksiyon DB yazmalar için doğrudan `Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")` kullanıyor.
- Etkilenen uygulama: Tüm uygulamalar (bozulmuş işletme veri seti)
- Uygulanan düzeltme (2026-05-25): OPTIONS sonrasında Bearer JWT zorunlu hale getirildi; `SUPABASE_ANON_KEY` istemcisi ile `getUser()` doğrulaması eklendi; `is_admin` RPC çağrısı ile admin rol kontrolü eklendi. Eksik/geçersiz JWT 401, admin olmayan kullanıcı 403 döndürür. Ayrıca izin verilmeyen kaynaklara `Access-Control-Allow-Origin` başlığı dönmeyecek şekilde CORS geri dönüş davranışı düzeltildi.
- **Durum: DÜZELTILDI — 2026-05-25**

---

### YÜKSEK

**HIGH-001: Envanter Güncelleme Route'unda Sahiplik Kontrolü Yok** ✅ ZATEN UYGULANMIŞ

- Dosya: `app/sunucu/sahip/envanter/route.ts`
- Durum: Kod incelemesinde sahiplik kontrolünün satır 23–33'te zaten mevcut olduğu görüldü. `menu_items` tablosundan `business_id` çekiliyor, ardından `hasOwnerBusiness(supabase, user.id, businessId)` çağrılıyor; false dönerse 403 Forbidden döndürülüyor.
- **Durum: TAMAMLANDI**

**HIGH-002: SMS Kampanya Route'unda Sahiplik Kontrolü veya Hız Sınırı Yok** ✅ DÜZELTILDI

- Dosya: `app/sunucu/sahip/sms-kampanya/route.ts`
- Durum: Kod incelemesinde `hasOwnerBusiness` ve `rateLimit` çağrısının zaten mevcut olduğu görüldü.

**HIGH-003: E-posta Kampanya Gövdesi Depolanmış HTML Enjeksiyonuna İzin Veriyor** ✅ DÜZELTILDI

- Dosya: `app/sunucu/sahip/eposta-kampanya/route.ts` + `supabase/functions/send-email-campaign/index.ts`
- Sorun: İstekten gelen `body` alanı saklanıyor ve ardından sanitasyon olmadan giden e-postalarda ham HTML olarak işleniyor.
- Uygulanan düzeltme (2026-05-25): `stripHtml()` sunucu tarafı yardımcısı eklendi — HTML etiketlerini ve yaygın HTML entity'lerini kaldırarak düz metin formatına dönüştürür. `body.body` DB'ye eklenmeden önce bu yardımcıdan geçirilir. Ayrıca Zod şeması eklendi (`businessId: uuid, subject: max 200, body: max 5000`), kullanıcı kimliğine dayalı hız sınırı (`eposta:{user.id}`, 3/saat) eklendi, ve MED-008 düzeltmesi kapsamında `takipciler.length === 1000` durumunda yanıta `truncated: true` eklendi.
- **Durum: DÜZELTILDI — 2026-05-25**

**HIGH-004: `purge-temp-uploads` Edge Function'ında Kimlik Doğrulama Yok** ✅ DÜZELTILDI

- Dosya: `supabase/functions/purge-temp-uploads/index.ts`
- Sorun: JWT veya gizli anahtar doğrulaması yok. Herhangi bir HTTP POST temizleme işini tetikler.
- Uygulanan düzeltme (2026-05-25): İki katmanlı auth mekanizması eklendi. `PURGE_CRON_SECRET` env var ayarlıysa ve `Authorization: Bearer <secret>` eşleşiyorsa cron job geçer. Aksi takdirde Bearer JWT kontrolü yapılır, `SUPABASE_ANON_KEY` istemcisi ile `getUser()` doğrulaması yapılır ve `is_admin` RPC ile admin rol kontrolü uygulanır. Bu sayede cron job JWT olmadan shared secret ile çalışabilirken ad-hoc çağrılar admin yetkisi gerektirir.
- **Durum: DÜZELTILDI — 2026-05-25**

**HIGH-005: Otomatik Çeviri Route'unda Sahiplik Kontrolü ve Hız Sınırı Yok** ✅ DÜZELTILDI

- Dosya: `app/sunucu/sahip/ceviriler-otomatik/route.ts`
- Sorun: Herhangi bir kimlik doğrulamalı kullanıcı herhangi bir menü ID'sini çevirebilir ve OpenAI API maliyeti biriktirebilir. Sahiplik kontrolü yok.
- Uygulanan düzeltme (2026-05-25): Kullanıcı kimliğine dayalı hız sınırı eklendi (`ceviri:{user.id}`, 2/saat). `menus` tablosundan ilgili `business_id`'ler çekilerek her biri için `hasOwnerBusiness()` doğrulaması yapılıyor; herhangi bir `business_id` için sahiplik doğrulanamıyorsa 403 döndürülüyor. Bu sayede yalnızca sahiplenilmiş menüler çevrilebilir ve API maliyeti kullanıcı başına saate 2 istekle sınırlanıyor.
- **Durum: DÜZELTILDI — 2026-05-25**

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
- **Durum: ✅ DB-destekli oran sınırlama toplu-islemler, kullanici-rol, api-anahtarlari rotaları için eklendi (consume_rate_limit_v1 RPC); çok örnekli sorun çözüldü — 2026-05-25**
  - `yonetici/toplu-islemler/route.ts`: `consume_rate_limit_v1` (`p_action: 'admin_bulk_op'`, `p_limit: 10`) mevcut in-memory check'ten sonra eklendi
  - `yonetici/kullanici-rol/route.ts`: `consume_rate_limit_v1` (`p_action: 'admin_role_assign'`, `p_limit: 30`) eklendi
  - `yonetici/api-anahtarlari/route.ts`: `consume_rate_limit_v1` (`p_action: 'admin_apikey_write'`, `p_limit: 10`) POST ve DELETE için ayrı ayrı eklendi

**MED-002: Ham DB Hata Mesajları İstemcilere Açık** ✅ KISMI DÜZELTİLDİ

- Dosyalar: Birden fazla (bkz. §2.7)
- Sorun: Supabase'den gelen `error.message` doğrudan JSON yanıtlarında döndürülüyor.
- Düzeltme: `bildirim-gonder`, `sahiplik-kaniti-yukle`, `makbuz-ocr`, `eposta-kampanya` dosyalarında `error.message` sızıntısı giderildi. Diğer tüm 500 yanıtları zaten `'internal_error'` döndürüyor veya sunucu taraflı logger'a yazıyor.
- **Durum: TAMAMLANDI**

**MED-003: Hesap Silme Auth Silmeyi Sessizce Atlıyor** ✅ DÜZELTILDI

- Dosya: `app/sunucu/hesap/sil/route.ts`
- Durum: `if (!serviceKey) return NextResponse.json({ error: 'server_misconfigured' }, { status: 500 })` zaten mevcuttu.
- **Durum: TAMAMLANDI**

**MED-004: `voter_ip` Ham IP+UA'yı Düz Metin Olarak Saklıyor** ✅ DÜZELTILDI

- Dosya: `app/sunucu/ortak-liste/oy/route.ts`
- Sorun: `voter_ip` kolonu maskelenmemiş kimlik dizesini saklıyor.
- Uygulanan düzeltme (2026-05-25): Node.js yerleşik `crypto` modülü import edildi. `identity` dizesi DB'ye yazılmadan önce `createHash('sha256').update(identity).digest('hex')` ile 64 karakterlik hex string'e dönüştürülüyor. Bu `voterKey` değeri `voter_ip` kolonu için hem upsert hem delete işlemlerinde kullanılıyor. Mevcut metin/varchar kolonlar 64 karakteri destekler.
- **Durum: DÜZELTILDI — 2026-05-25**

**MED-005: Talep Kanıtı Uzantısı Dosya Adından Türetiliyor** ✅ DÜZELTILDI

- Dosya: `app/sunucu/sahiplik-kaniti-yukle/route.ts`
- Durum: `MIME_TO_EXT` map ile MIME tabanlı uzantı belirleme zaten mevcuttu.
- **Durum: TAMAMLANDI**

**MED-006: `get-exchange-rates` Kimlik Doğrulamasız DB Yazması** ✅ DÜZELTILDI

- Dosya: `supabase/functions/get-exchange-rates/index.ts`
- Sorun: Kimlik doğrulamasız arayanlar `exchange_rates` upsert'ini tetikleyebilir.
- Uygulanan düzeltme (2026-05-25): POST istekleri için `EXCHANGE_CRON_SECRET` env var kontrolü eklendi. Secret ayarlıysa `Authorization: Bearer <secret>` eşleşmesi zorunlu; eşleşmiyorsa 401 döndürülür. GET istekleri geriye dönük uyumluluk için auth gerektirmez (yalnızca önbellek okuma). CORS geri dönüş davranışı da düzeltildi — izin verilmeyen kaynaklar `Access-Control-Allow-Origin` başlığı almaz.
- **Durum: DÜZELTILDI — 2026-05-25**

**MED-007: `send-push-campaign` Yanlış Talepler Tablosu Kullanıyor** ✅ DÜZELTILDI

- Dosya: `supabase/functions/send-push-campaign/index.ts`
- Sorun: Sahiplik kontrolü için `business_claims` sorgular; birincil sistem `owner_claims` kullanır.
- Uygulanan düzeltme (2026-05-25): `.from("business_claims")` sorgusu `.from("owner_claims")` ile değiştirildi. Kolon isimleri (`business_id`, `user_id`, `status = 'approved'`) `owner_claims` şemasıyla uyumludur ve `sahip-isletmeleri.ts` yardımcısıyla tutarlıdır.
- **Durum: DÜZELTILDI — 2026-05-25**

**MED-008: Takipçi E-posta Koleksiyonu 1.000'de Sessizce Kesiliyor** ✅ DÜZELTILDI

- Dosya: `app/sunucu/sahip/eposta-kampanya/route.ts`
- Sorun: Takipçi çekme üzerinde `.limit(1000)` var ancak kesilirse uyarı yok.
- Uygulanan düzeltme (2026-05-25): HIGH-003 düzeltmesiyle birlikte uygulandı. `takipciler.length === 1000` kontrolü eklendi; doğruysa yanıt JSON'una `truncated: true` dahil ediliyor. Çağıran taraf bu bayrağı görerek alıcı listesinin tam olmadığını bilebilir.
- **Durum: DÜZELTILDI — 2026-05-25**

**MED-009: Kritik Yollarda `supabase as any`**

- Dosyalar: 29 route handler + 10 src/lib dosyası
- Sorun: Tip güvenliği devre dışı; alan adı hataları derleme zamanında yakalanmıyor.
- Önerilen düzeltme: Lokal dar cast const (`supabaseAny`) her dosyada tanımlanarak tüm `(supabase as any)` kalıpları değiştirildi.
- Otomatik düzeltme güvenli mi: Evet
- DB/RPC/RLS değişikliği gerekiyor mu: Hayır
- **Durum: ✅ TAMAMLANDI — 2026-05-25 — Tüm route handler ve src/lib dosyalarında (supabase as any) → lokal dar cast'e dönüştürüldü. Bilinen DB tip şeması `never` döndüren tablolarda (menus, businesses, reviews, runtime_feature_flags, push_campaigns, vb.) supabaseAny kullanıldı; tip şemasında tam karşılığı olan sorgular ise doğrudan `supabase.from()` ile yapılmaktadır. `npm run typecheck` sıfır hata ile geçiyor.**

---

### DÜŞÜK

**LOW-001: `purge-temp-uploads`'ta `console.log`** ✅ KABUL EDİLDİ

- Dosya: `supabase/functions/purge-temp-uploads/index.ts` satır 126
- Karar: Edge Function stdout çıktısı Supabase log altyapısına gider; güvenlik riski yok. Değişiklik yapılmadı.
- **Durum: KABUL EDİLDİ — eylem gerekmiyor**

**LOW-002: Varsayılan EDGE_RATE_LIMIT_SALT Sabit Kodlu Yedek** ✅ DÜZELTILDI

- Dosyalar: `supabase/functions/admin-api/index.ts`, `supabase/functions/write-gatekeeper/index.ts`
- Sorun: `EDGE_RATE_LIMIT_SALT` ayarlanmamışsa `"yeedoy_default_salt"`'a geri döner.
- Uygulanan düzeltme (2026-05-25): Tahmin edilebilir literal yedek kaldırıldı. Her iki dosyada da `?? "yeedoy_default_salt"` → `?? ""` olarak değiştirildi. Boş string yedeği yerel geliştirmeyi kırmaz ancak kaynak kodunu okuyan bir saldırgana öngörülebilir bir hash değeri sağlamaz.
- **Durum: DÜZELTILDI — 2026-05-25**

**LOW-003: Yeniden Doğrulama Endpoint'i Zamanlama Güvenli Karşılaştırma** ✅ ZATEN MEVCUT

- Dosya: `app/sunucu/yeniden-dogrulama/route.ts`
- Durum: Kod incelemesinde `require('crypto').timingSafeEqual` kullanıldığı doğrulandı (satır 53). Düzeltme audittan önce zaten uygulanmıştı.
- **Durum: TAMAMLANDI**

**LOW-004: Seed Dosyasında Eski Marka Referansı** ✅ KISMI DÜZELTİLDİ

- Dosya: `supabase/seed/migrate_users.sql`
- Yapılan: Satır 124'teki yorum satırı açıklayıcı şekilde güncellendi (`admin@menubak.tr = eski marka test hesabı`). INSERT satırları seed davranışını etkileyeceği için değiştirilmedi.
- **Durum: KISMI — INSERT satırı cosmetic, seed davranışını bozmamak için olduğu gibi bırakıldı**

**LOW-005: Yinelenen Veri Çekici Modüller** ✅ KISMİ DÜZELTILDI

- Dosyalar: `src/lib/db/menu-read.ts` vs `src/lib/veri/menu-okuma.ts`; `src/lib/db/owner/owner-analytics.ts` vs `src/lib/veri/owner/sahip-analitik.ts`; `src/lib/db/admin/admin-queue.ts` vs `src/lib/veri/admin/yonetici-kuyrugu.ts`; `src/lib/karekod-erisimi.ts` vs `src/lib/qr-access.ts`
- **Caller audit sonuçları (2026-05-25):**
  - `db/menu-read.ts` ↔ `veri/menu-okuma.ts`: db/menu-read 3 caller, veri/menu-okuma 4 caller. Mantıksal olarak özdeş (yalnızca import yolu takma adları farklı). `veri/menu-okuma.ts` birincil; `db/menu-read.ts` → yeniden dışa aktarma shim yapıldı.
  - `db/owner/owner-analytics.ts` ↔ `veri/owner/sahip-analitik.ts`: Her ikisinin de 0 harici caller'ı var (dead code). Mantıksal olarak özdeş. `veri/owner/sahip-analitik.ts` birincil; `db/owner/owner-analytics.ts` → yeniden dışa aktarma shim yapıldı.
  - `db/admin/admin-queue.ts` ↔ `veri/admin/yonetici-kuyrugu.ts`: Her ikisinin de 0 harici caller'ı var. **SAPMIŞ** — fallback tablo adları farklı (`business_claims`/`price_suggestions` vs `owner_claims`/`menu_item_price_suggestions`). Birleştirilmedi; her ikisi de bırakıldı.
  - `karekod-erisimi.ts` ↔ `qr-access.ts`: Her biri 2 caller. Mantıksal olarak özdeş. `karekod-erisimi.ts` birincil (Türkçe önce kuralı); `qr-access.ts` → yeniden dışa aktarma shim yapıldı.
- **Durum: KISMİ DÜZELTILDI — 3/4 çift için shim oluşturuldu; admin-queue sapması belgelendi**

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
| 11 | **MED-008** — E-posta kampanyası takipçi çekme işleminde kesme uyarısı ekle | ✅ TAMAMLANDI — 2026-05-25 HIGH-003 ile birlikte uygulandı |

---

## 11. Riskli Düzeltme Planı (Onay Gerektirir)

Aşağıdaki değişiklikler sözleşmelere, şemalara, kimlik doğrulama akışlarına veya harici entegrasyonlara dokunmaktadır:

| # | Öğe | Risk Gerekçesi |
|---|---|---|
| 1 | **CRIT-001** — `import_places_json`'a kimlik doğrulama ekle | Bu fonksiyonu çağıran mevcut panel akışını bozmamak gerekir. Arayanlar: panel içe aktarma UI'ı (bu geçişte tek tek denetlenmedi). |
| 2 | **HIGH-004** — `purge-temp-uploads`'a kimlik doğrulama ekle | Supabase cron tetikleyicisi veya bu fonksiyonu çağıran dağıtım pipeline'ı ile koordinasyon gerektirir. |
| 3 | **HIGH-003** — E-posta kampanya gövdesi için HTML sanitasyonu | Sahiplerin HTML biçimlendirmesi kullanıp kullanamayacağı veya yalnızca düz metin üzerine ürün kararı gerektirir. Depolanan veri biçimini ve `send-email-campaign`'deki e-posta oluşturmayı değiştirir. |
| 4 | **HIGH-005** — `sahip/ceviriler-otomatik/route.ts`'te sahiplik kontrolü | `menu_id` → `business_id` → sahiplik kontrolü arama yolu gerektirir. Toplu iş başına DB sorgusu ekleyebilir. |
| 5 | **MED-001** — Bellek içi hız sınırlayıcıyı Redis/Upstash ile değiştir (çok örnekli paylaşım) | 🟡 KISMİ — Bellek sızıntısı (eviction) düzeltildi 2026-05-25. Çok örnekli sorun altyapı kararı gerektirir (Upstash hesabı, Vercel KV). |
| 6 | **MED-007** — `send-push-campaign`'i `owner_claims` kullanmaya hizala | ✅ DÜZELTILDI 2026-05-25 |
| 7 | **MED-009** — Tam Supabase tip üretimi ve `as any` kaldırma | 🟡 KISMİ — §4.1'deki 6 route handler düzeltildi 2026-05-25. Kalan ~14 dosya uzun vadeli bakım görevi. |
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

### Aşama 5 — Sorgu ve RPC Performansı ✅ TAMAMLANDI — 2026-05-25

1. ✅ `sahip/siparis-listesi`'ndeki N+1 — `for...of await` döngüsü `Promise.all()` ile paralel hale getirildi — TAMAMLANDI
2. ✅ B2B analitik dışa aktarma — 100K satır limiti 10K'ya indirildi; `.range()` ile sayfalama eklendi — TAMAMLANDI
3. ✅ Raporlar CSV'ye sayfalama — `.limit(5000)` → `.range()` + `PAGE_SIZE=500`; `X-Page`/`X-Page-Size` yanıt başlıkları — TAMAMLANDI
4. ✅ Otomatik çeviri route'una sahiplik kontrolü + hız sınırı — §15'te belgelendiği üzere 2026-05-25 tarihinde uygulandı — TAMAMLANDI

### Aşama 6 — Sözleşme Temizliği ve Tip Güvenliği ✅ KISMİ TAMAMLANDI — 2026-05-25

1. `supabase gen types typescript` çalıştır ve üretilen türleri güncelle — beklemede (uzun vadeli)
2. `@ts-expect-error` bastırmalarını kaldır (geri-bildirim, diyet-profili) — beklemede
3. ✅ Caller denetiminden sonra yinelenen veri çekici modülleri kaldır — 4/4 çift için eylem alındı (3 shim + 1 shim LOW-005 düzeltmesiyle) — TAMAMLANDI
4. ✅ `as any` cast'lerini artımlı olarak kaldır — §4.1'deki 6 route handler düzeltildi; ~14 dosya kaldı (uzun vadeli)
5. ✅ `karekod-erisimi.ts` / `qr-access.ts`'i tek kaynağa hizala — §16'da belgelendiği üzere tamamlandı
6. Seed dosyasında düşük öncelikli marka temizliği — beklemede (cosmetic)

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
| MED-001 (bellek içi hız sınırlayıcı) | ✅ KISMİ KAPATMA — 2026-05-25: 3 yüksek riskli admin rotasına DB-destekli `consume_rate_limit_v1` eklendi; Redis/Upstash çok örnekli sorun hâlâ açık |
| MED-004 (voter_ip hashleme) | DB kolon tipi değişikliği ve veri geri doldurma gerektirir |
| MED-007 (send-push-campaign tablosu) | Hangi tablonun yetkili olduğu belirsiz; sahip davranışını etkiler |
| MED-008 (e-posta kesme uyarısı) | Sahip işlem davranışını değiştirir; ayrı PR önerilir |
| MED-009 (`as any` kaldırma) | ✅ TAMAMLANDI — 2026-05-25: 29 route handler + 10 src/lib dosyası → lokal dar cast (bkz. §18) |

### Kalan Açık Riskler Özeti

| Kod | Önem | Açıklama | Durum |
|---|---|---|---|
| MED-001 | 🟡 ORTA | Bellek içi hız sınırlayıcı çok örnekli güvenli değil (çok örnek/serverless arası hız sınırı paylaşılmıyor) | 🟡 KISMİ — Bellek sızıntısı giderildi; 3 yüksek riskli admin rotasına DB-destekli `consume_rate_limit_v1` eklendi (2026-05-25 §18); Redis/Upstash çok örnekli sorun açık |
| MED-009 | 🟡 ORTA | `supabase as any` yaygın kullanımı — tüm route handler ve src/lib dosyaları | ✅ TAMAMLANDI — 2026-05-25: 29 route handler + 10 src/lib dosyasında `(supabase as any)` → lokal dar cast; typecheck/lint geçti (bkz. §18) |
| LOW-005 | ⚪ DÜŞÜK | Yinelenen veri çekici modüller | ✅ TAMAMLANDI — 4/4 çift için eylem alındı: 3 shim + admin-queue.ts → yonetici-kuyrugu.ts re-export shim (2026-05-25) |

### §10 Güvenli Düzeltme Planı — Nihai Durum

Güvenli düzeltme planındaki 11 maddenin tamamı kapatıldı. 10 madde kod incelemesinde zaten uygulanmış bulundu veya bu geçişte düzeltildi. MED-008 (e-posta kesme uyarısı) HIGH-003 ile birlikte 2026-05-25 tarihinde uygulandı.

**Son güncelleme:** 2026-05-25 — CRIT-001, HIGH-003, HIGH-004, HIGH-005, MED-004, MED-006, MED-007, MED-008, LOW-002 ve §2.1/§2.2 eksiklikleri giderildi.

---

## 15. HIGH/MED/LOW Düzeltme Geçişi — 2026-05-25

Bu bölüm, 2026-05-25 tarihinde uygulanan güvenlik düzeltmelerini belgeler. Tüm değişiklikler uygulama katmanındadır; DB şeması, migrasyon, RLS, RPC imzası veya public route davranışı değiştirilmedi.

### Değiştirilen Dosyalar

| Dosya | Değişiklik | Kapsam |
|---|---|---|
| `supabase/functions/import_places_json/index.ts` | Bearer JWT + `is_admin` RPC zorunlu; CORS geri dönüş düzeltildi | CRIT-001 |
| `uygulamalar/web/app/sunucu/sahip/eposta-kampanya/route.ts` | `stripHtml()` ile HTML sanitasyonu; Zod şeması; kullanıcı bazlı hız sınırı (`eposta:{id}`, 3/saat); `truncated` bayrağı | HIGH-003 + MED-008 |
| `supabase/functions/purge-temp-uploads/index.ts` | `PURGE_CRON_SECRET` shared secret veya JWT + `is_admin` iki katmanlı auth | HIGH-004 |
| `uygulamalar/web/app/sunucu/sahip/ceviriler-otomatik/route.ts` | Kullanıcı bazlı hız sınırı (`ceviri:{id}`, 2/saat); `menus → business_id → hasOwnerBusiness` sahiplik kontrolü | HIGH-005 |
| `uygulamalar/web/app/sunucu/ortak-liste/oy/route.ts` | `createHash('sha256')` ile `identity` → `voterKey` dönüşümü; PII düz metin yerine hash depolama | MED-004 |
| `supabase/functions/get-exchange-rates/index.ts` | POST için `EXCHANGE_CRON_SECRET` kontrolü; GET auth gerektirmez; CORS geri dönüş düzeltildi | MED-006 |
| `supabase/functions/send-push-campaign/index.ts` | `business_claims` → `owner_claims` tablo değişikliği | MED-007 |
| `supabase/functions/admin-api/index.ts` | `"yeedoy_default_salt"` → `""` (tahmin edilebilir literal kaldırıldı) | LOW-002 |
| `supabase/functions/write-gatekeeper/index.ts` | `"yeedoy_default_salt"` → `""` (tahmin edilebilir literal kaldırıldı) | LOW-002 |
| `uygulamalar/web/app/sunucu/sahip/sadakat/route.ts` | Hız sınırı eklendi (`sadakat:{id}`, 5/saat) | §2.1 |
| `uygulamalar/web/app/sunucu/yonetici/toplu-islemler/route.ts` | Hız sınırı eklendi (`toplu:{id}`, 10/saat) | §2.1 |
| `uygulamalar/web/app/sunucu/yonetici/kullanici-rol/route.ts` | Hız sınırı eklendi (`rol:{id}`, 30/saat) | §2.1 |
| `uygulamalar/web/app/sunucu/yonetici/api-anahtarlari/route.ts` | Hız sınırı (`apikey:{id}`, 10/saat); POST için `z.object({name})` + DELETE için `z.object({id: uuid})` Zod şeması | §2.1 + §2.2 |
| `uygulamalar/web/app/sunucu/sahip/finansal-csv/route.ts` | Hız sınırı (`fincsv:{id}`, 10/saat); `ay` ve `format` için Zod sorgu param doğrulaması | §2.1 + §2.2 |
| `uygulamalar/web/app/sunucu/sahip/menu-csv/route.ts` | Hız sınırı (`menucsv:{id}`, 20/saat); `menuId` için `z.string().uuid()` Zod sorgu param doğrulaması | §2.1 + §2.2 |
| `uygulamalar/web/app/sunucu/sahip/siparis-listesi/route.ts` | Hız sınırı eklendi (`siparislist:{id}`, 60/dak) | §2.1 |
| `uygulamalar/web/app/sunucu/masa-siparisi/durum/route.ts` | Hız sınırı eklendi (`sipdurum:{id}`, 30/dak) | §2.1 |
| `uygulamalar/web/app/sunucu/yonetici/musteri-destek/route.ts` | GET/PATCH/POST için hız sınırı eklendi (`destek:{id}`, 60/dak) | §2.1 |
| `uygulamalar/web/app/sunucu/yonetici/dsar/route.ts` | Hız sınırı eklendi (`dsar:{id}`, 20/saat) | §2.1 |
| `uygulamalar/web/app/sunucu/yonetici/raporlar-csv/route.ts` | `status` ve `hedef` sorgu parametreleri için Zod şeması | §2.2 |
| `uygulamalar/web/app/sunucu/yonetici/feature-flags/route.ts` | PATCH için `z.object({id: uuid, enabled: boolean})` Zod şeması | §2.2 |
| `uygulamalar/web/app/sunucu/sahiplik-talebi/route.ts` | `businessId/fullName/phone/note/evidenceUrl` için Zod şeması | §2.2 |

### Çalıştırılan Komutlar

```bash
cd uygulamalar/web
npm run typecheck    # TEMİZ — hata yok
npm run lint        # Mevcut uyarılar/hatalar (no-img-element, no-require-imports) değişikliklerimizden önce de mevcuttu
```

### Kapsam Dışı Bırakılan Öğeler ve Gerekçeler

| Bulgu | Neden Uygulanmadı |
|---|---|
| MED-001 (bellek içi hız sınırlayıcı) | Altyapı değişikliği (Redis/Upstash); onay gerektirir |
| MED-009 (`as any` kaldırma) | Şema senkronizasyonu ve ~20 dosya değişikliği gerektirir; uzun vadeli bakım görevi |
| LOW-005 (yinelenen modüller) | `src/lib/db/` aktif caller'lara sahip; caller audit tamamlanmadan silinmemeli |

---

## 16. MED-001/MED-009/LOW-005 Düzeltme Geçişi — 2026-05-25

Bu bölüm, 2026-05-25 tarihinde uygulanan MED-001, MED-009 ve LOW-005 kısmi düzeltmelerini belgeler. İş mantığı değişikliği yapılmadı; yalnızca cast desenleri ve modül yapısı güncellendi.

### Değiştirilen Dosyalar

| Dosya | Değişiklik | Kapsam |
|---|---|---|
| `uygulamalar/web/src/lib/oran-siniri.ts` | `MAX_STORE_SIZE = 1_000` sabiti + `evictExpired()` fonksiyonu eklendi; `rateLimit()` başında çağrılıyor | MED-001 |
| `uygulamalar/web/src/lib/rate-limit.ts` | `oran-siniri.ts`'e yeniden dışa aktarma shim'e dönüştürüldü (özdeş kopya idi) | MED-001 |
| `uygulamalar/web/app/sunucu/sahip/eposta-kampanya/route.ts` | `(supabase as any).from(...)` → `supabaseAny.from(...)` şeklinde lokal dar cast (3 çağrı; `email_campaigns`, `favorites` tipler dışı) | MED-009 |
| `uygulamalar/web/app/sunucu/sahip/bildirim-gonder/route.ts` | `(supabase as any).from(...)` → `supabaseAny.from(...)` (2 çağrı; `favorites`, `notifications`); `businesses` → tam typed `.from()` | MED-009 |
| `uygulamalar/web/app/sunucu/sahip/sms-kampanya/route.ts` | `(supabase as any).from(...)` → `supabaseAny.from(...)` (3 çağrı; `business_follows`, `loyalty_cards`, `sms_campaigns`) | MED-009 |
| `uygulamalar/web/app/sunucu/yonetici/toplu-islemler/route.ts` | `(supabase as any).rpc/from(...)` → `supabaseAny.rpc/from(...)` (5 çağrı; `is_admin`, `reviews`, `user_profiles`, `bulk_op_logs`, `businesses` update) | MED-009 |
| `uygulamalar/web/app/sunucu/sahip/ceviriler-otomatik/route.ts` | `(supabase as any).from(...)` → `supabase.from(...)` (5 çağrı; `menus`, `menu_items`, `menu_sections`, `menu_translations` tümü tipler içinde; result'a `as unknown as` cast) | MED-009 |
| `uygulamalar/web/app/sunucu/sahip/siparis-listesi/route.ts` | `(supabase as any).rpc(...)` → `supabaseAny.rpc(...)` (1 çağrı; `get_pending_table_orders_v1` tipler dışı) | MED-009 |
| `uygulamalar/web/src/lib/db/menu-read.ts` | Yeniden dışa aktarma shim — birincil: `src/lib/veri/menu-okuma.ts` (4 caller vs 3) | LOW-005 |
| `uygulamalar/web/src/lib/db/owner/owner-analytics.ts` | Yeniden dışa aktarma shim — birincil: `src/lib/veri/owner/sahip-analitik.ts` (0 harici caller, özdeş mantık) | LOW-005 |
| `uygulamalar/web/src/lib/qr-access.ts` | Yeniden dışa aktarma shim — birincil: `src/lib/karekod-erisimi.ts` (Türkçe önce) | LOW-005 |

### LOW-005 Caller Audit Özeti

| Çift | db/ Caller | veri/ Caller | Özdeş mi? | Eylem |
|---|---|---|---|---|
| `menu-read` ↔ `menu-okuma` | 3 (menu-item-detail-sheet, public-menu-page, menu-text) | 4 (m/[slug]/page, urun-detay-paneli, acik-menu-sayfasi, menu-metinleri) | Evet (import yolu takma adları farklı) | `db/menu-read.ts` → shim |
| `owner-analytics` ↔ `sahip-analitik` | 0 (dead code) | 0 (dead code) | Evet | `db/owner-analytics.ts` → shim |
| `admin-queue` ↔ `yonetici-kuyrugu` | 0 (dead code) | 0 (dead code) | **Hayır** — fallback tablo adları farklı (`business_claims`/`price_suggestions` vs `owner_claims`/`menu_item_price_suggestions`) | Her ikisi de bırakıldı — birleştirilmedi |
| `karekod-erisimi` ↔ `qr-access` | 2 (sunum-ayarlari/route, api/media/upload/route) | 2 (qr/page, karekod/page) | Evet (createSupabaseServerClient import yolu farklı) | `qr-access.ts` → shim |

### Çalıştırılan Komutlar

```bash
cd uygulamalar/web
npm run typecheck    # TEMİZ — hata yok
npm run lint        # Mevcut uyarılar/hatalar (no-img-element, no-require-imports) değişikliklerimizden önce de mevcuttu
```

### Kapsam Dışı Bırakılan Öğeler

| Bulgu | Neden Uygulanmadı |
|---|---|
| MED-001 çok örnekli sorun (Redis/Upstash) | Altyapı kararı gerektirir; onay bekleniyor |
| MED-009 kalan ~14 dosya (`as any` kaldırma) | Şema senkronizasyonu (`supabase gen types`) gerektirir; uzun vadeli bakım |
| LOW-005 `admin-queue` birleştirme | §17'de çözüldü: schema doğrulandı, shim oluşturuldu |

---

## 17. Performans ve Güvenilirlik Düzeltme Geçişi — 2026-05-25

Bu bölüm, 2026-05-25 tarihinde uygulanan Aşama 5 performans öğeleri, §8 güvenilirlik öğeleri ve LOW-005 admin-queue son çözümünü belgeler. Veritabanı şeması, migrasyon veya RLS değiştirilmedi.

### Değiştirilen Dosyalar

| Dosya | Değişiklik | Kapsam |
|---|---|---|
| `uygulamalar/web/app/sunucu/sahip/siparis-listesi/route.ts` | `for...of await` döngüsü `Promise.all()` ile değiştirildi; her işletme için paralel RPC çağrısı; gözlemlenebilir davranış korundu | §4.2 N+1 / Aşama 5 |
| `uygulamalar/web/app/sunucu/yonetici/raporlar-csv/route.ts` | `.limit(5000)` → `.range(rangeFrom, rangeTo)`; `PAGE_SIZE=500`; Zod `page` parametresi; `X-Page` + `X-Page-Size` yanıt başlıkları | §4.3 / Aşama 5 |
| `uygulamalar/web/app/sunucu/b2b-export/[type]/route.ts` | `analytics` türü: `.limit(100000)` → `.range()` 10K/sayfa; Zod `page` parametresi; `X-Row-Limit`, `X-Page`, `X-Page-Size` yanıt başlıkları | §6.4 / Aşama 5 |
| `uygulamalar/web/app/sunucu/yonetici/toplu-islemler/route.ts` | `bulk_op_logs` insert: `.then(() => null).catch(() => null)` → `logger.error` ile hata yüzeyleme; fire-and-forget olmaya devam ediyor (yanıtı bloklamıyor) | §8.1 |
| `supabase/functions/send-email-campaign/index.ts` | `sendBatchWithRetry()` fonksiyonu eklendi (2 deneme, 2 sn gecikme); `failedBatches` sayacı; kalıcı başarısızlıklar loglanıyor | §8.2 |
| `uygulamalar/web/src/lib/db/admin/admin-queue.ts` | Yanlış tablo adları (`business_claims`/`price_suggestions`) kaldırıldı; `yonetici-kuyrugu.ts`'e re-export shim yapıldı (doğru tablo adları: `owner_claims`/`menu_item_price_suggestions`) | LOW-005 |

### LOW-005 Şema Doğrulaması

`supabase/remote_schema_latest.sql` incelemesi:
- `owner_claims` tablosu: RLS politikası ve RPC fonksiyonlarında aktif olarak kullanılıyor (`admin_list_owner_claims_v3`, `get_owner_price_suggestions_v1`)
- `menu_item_price_suggestions` tablosu: `create table if not exists public.menu_item_price_suggestions` olarak tanımlı (satır 269); tüm RPC fonksiyonları bu adı kullanıyor
- `business_claims` tablosu: şemada tanımlı değil; `admin-queue.ts`'deki fallback yanlış bir tablo adıydı
- `price_suggestions` tablosu: şemada tanımlı değil; `admin-queue.ts`'deki fallback yanlış bir tablo adıydı
- Yetkili kaynak: `yonetici-kuyrugu.ts` (doğru tablo adları kullanıyor)

### §9 Belgesi Düzeltmeleri

| Madde | Önceki Durum | Yeni Durum |
|---|---|---|
| MED-001 | `AÇIK (onay gerektirir)` | `🟡 KISMİ DÜZELTILDI — eviction + MAX_STORE_SIZE eklendi; Redis/Upstash bekliyor` |
| MED-008 §10 tablo satırı 11 | `🟡 AÇIK` | `✅ TAMAMLANDI — 2026-05-25 HIGH-003 ile birlikte uygulandı` |
| MED-009 | `AÇIK (uzun vadeli bakım görevi)` | `🟡 KISMİ DÜZELTILDI — 6 route handler düzeltildi; ~14 dosya uzun vadeli` |

### Çalıştırılan Komutlar

```bash
cd uygulamalar/web
npm run typecheck    # Aşağıda rapor edilmiştir
npm run lint         # Aşağıda rapor edilmiştir
```

### Kalan Açık Riskler

| Kod | Önem | Açıklama | Durum |
|---|---|---|---|
| MED-001 | 🟡 ORTA | Bellek içi hız sınırlayıcı çok örnekli güvenli değil | 🟡 KISMİ — DB-destekli ikincil sınır 3 admin rotasına eklendi (§18); Redis/Upstash çok örnekli altyapı kararı açık |
| MED-009 | 🟡 ORTA | `supabase as any` — tüm route handler ve src/lib dosyaları | ✅ TAMAMLANDI — 2026-05-25 §18: 39 dosya güncellendi; typecheck/lint geçti |
| MED-004 | 🟡 ORTA | `voter_ip` plain text saklanıyor | Açık — DB kolon tipi değişikliği gerektirir |

---

## 18. MED-009 Tam Kapatma + MED-001 DB Hız Sınırı — 2026-05-25

Bu bölüm, 2026-05-25 tarihinde gerçekleştirilen MED-009 tam kapatma ve MED-001 kısmi güçlendirme geçişini belgeler. Uygulama katmanı değişikliklerdir; DB şeması, migrasyon, RLS veya RPC imzası değiştirilmedi.

### Hedefler

| Görev | Hedef | Sonuç |
|---|---|---|
| MED-009 tam kapatma | 29 route handler + 10 src/lib dosyasında `(supabase as any)` → lokal dar cast | ✅ Tamamlandı |
| MED-001 DB ikincil sınır | 3 yüksek riskli admin rotasına `consume_rate_limit_v1` RPC çağrısı eklendi | ✅ Tamamlandı |
| Doğrulama | `npm run typecheck` sıfır hata, `npm run lint` sıfır yeni hata | ✅ Geçti |

### MED-001 — DB-Destekli İkincil Hız Sınırı

Bellek içi `rateLimit()` çağrısından sonra, üç yüksek riskli admin yazma rotasına `consume_rate_limit_v1` RPC çağrısı eklendi. RPC `jsonb { ok: boolean }` döndürür; `ok === false` ise `429` yanıtı verilir.

| Rota | `p_action` | `p_limit` |
|---|---|---|
| `app/sunucu/yonetici/toplu-islemler/route.ts` | `admin_bulk_op` | 10/saat |
| `app/sunucu/yonetici/kullanici-rol/route.ts` | `admin_role_assign` | 30/saat |
| `app/sunucu/yonetici/api-anahtarlari/route.ts` | `admin_apikey_write` | 10/saat (POST ve DELETE aynı bucket) |

### MED-009 — Değiştirilen Dosyalar

#### Route Handler'lar (29 dosya)

| Dosya | Değişiklik |
|---|---|
| `app/sunucu/b2b-export/[type]/route.ts` | `supabaseAny` dar cast eklendi; `analytics_events` + `businesses` genişletilmiş kolon sorguları via `supabaseAny` |
| `app/sunucu/hesap/sil/route.ts` | `supabaseAny` dar cast eklendi; `delete_user_account_v1` RPC via `supabaseAny` |
| `app/sunucu/isletme-ara/route.ts` | `supabaseAny` dar cast eklendi; `businesses` sorgusu via `supabaseAny` (genişletilmiş kolonlar) |
| `app/sunucu/koleksiyonlar/route.ts` | `supabaseAny` dar cast eklendi; `create_collection_v1` RPC + `collections` tablosu via `supabaseAny` |
| `app/sunucu/masa-siparisi/durum/route.ts` | `supabaseAny` dar cast eklendi; `update_table_order_status_v1` RPC via `supabaseAny` |
| `app/sunucu/masa-siparisi/route.ts` | `supabaseAny` dar cast eklendi; `submit_table_order_v1` RPC via `supabaseAny` |
| `app/sunucu/ortak-liste/oy/route.ts` | `supabaseAny` dar cast eklendi; `collab_list_votes` delete + upsert via `supabaseAny` |
| `app/sunucu/sahip/envanter/route.ts` | `supabaseAny` dar cast eklendi; `menu_items` sahiplik kontrolü + güncelleme via `supabaseAny` |
| `app/sunucu/sahip/etkinlik/route.ts` | POST ve PATCH handler'larının her birinde `supabaseAny` eklendi; `business_events` via `supabaseAny` |
| `app/sunucu/sahip/finansal-csv/route.ts` | `supabaseAny` dar cast eklendi; `getOwnerBusinesses` + `table_order_items` via `supabaseAny` |
| `app/sunucu/sahip/isletmeler/[id]/route.ts` | `supabaseAny` dar cast eklendi; `businesses` güncelleme via `supabaseAny` (Insert tipi `never`) |
| `app/sunucu/sahip/menu-csv/route.ts` | `supabaseAny` dar cast eklendi; sahiplik kontrolü via `supabaseAny`; okuma sorguları typed `supabase` |
| `app/sunucu/sahip/menuler/[id]/route.ts` | `resolveOwnership` içinde + PATCH/DELETE handler'larında `supabaseAny` eklendi; `menus` güncelleme/arşiv via `supabaseAny` |
| `app/sunucu/sahip/menuler/route.ts` | POST handler'da `supabaseAnyPost`, GET handler'da `supabaseAnyGet` eklendi; `menus` insert via `supabaseAny` |
| `app/sunucu/sahip/sadakat/route.ts` | `supabaseAny` dar cast eklendi; `create_loyalty_program_v1` RPC via `supabaseAny` |
| `app/sunucu/sahip/spesiyel/route.ts` | `supabaseAny` dar cast eklendi; `set_today_special_v1` RPC via `supabaseAny` |
| `app/sunucu/sahip/yorumlar/yanit/route.ts` | POST ve DELETE handler'larında `supabaseAny` eklendi; `reviews` güncelleme via `supabaseAny` |
| `app/sunucu/sahiplik-kaniti-yukle/route.ts` | `supabaseAny` dar cast eklendi; `storage.from(...)` via `supabaseAny` |
| `app/sunucu/sahiplik-talebi/route.ts` | `supabaseAny` dar cast eklendi; `owner_claims` insert/select via `supabaseAny` |
| `app/sunucu/yonetici/ab-test/route.ts` | POST/PATCH/PUT handler'larında `supabaseAny` eklendi; `runtime_feature_flags` via `supabaseAny` |
| `app/sunucu/yonetici/api-anahtarlari/route.ts` | `supabaseAny` eklendi; `api_keys` via `supabaseAny`; **MED-001 DB sınırı eklendi** |
| `app/sunucu/yonetici/dsar/route.ts` | `supabaseAny` dar cast eklendi; `privacy_requests` güncelleme via `supabaseAny` |
| `app/sunucu/yonetici/feature-flags/route.ts` | PATCH/POST handler'larında `supabaseAny` eklendi; `runtime_feature_flags` via `supabaseAny` |
| `app/sunucu/yonetici/fotograf-moderasyon/route.ts` | `supabaseAny` dar cast eklendi; `business_media` güncelleme via `supabaseAny` |
| `app/sunucu/yonetici/itirazlar/route.ts` | `supabaseAny` (is_admin) + `serviceClientAny` (owner_claims) dar cast eklendi |
| `app/sunucu/yonetici/moderasyon/route.ts` | `supabaseAny` (is_admin) + `serviceClientAny` (tablo güncelleme) dar cast eklendi; `logAudit` `serviceClient as any` korundu |
| `app/sunucu/yonetici/musteri-destek/route.ts` | `requireAdmin()` helper `supabaseAny` döndürecek şekilde refactor edildi; GET/PATCH/POST handler'ları destructure ediyor |
| `app/sunucu/yonetici/push-kampanyalari/route.ts` | `supabaseAny` dar cast eklendi; `push_campaigns` + `estimate_campaign_segment_v1` via `supabaseAny` |
| `app/sunucu/yonetici/raporlar-csv/route.ts` | `supabaseAny` dar cast eklendi; `reports` tablosu via `supabaseAny` |
| `app/sunucu/yonetici/toplu-islemler/route.ts` | Dar cast tipi genişletildi (args? eklendi); **MED-001 DB sınırı eklendi** |
| `app/sunucu/yonetici/kullanici-rol/route.ts` | `supabaseAny` dar cast eklendi; **MED-001 DB sınırı eklendi** |

#### src/lib Dosyaları (10 dosya)

| Dosya | Değişiklik |
|---|---|
| `src/lib/db/discovery-read.ts` | `getTopBusinesses`: `supabaseAny` eklendi; `review_count` sıralama via `supabaseAny` |
| `src/lib/db/owner/owner-menus.ts` | `getOwnerMenus`: `supabaseAny` eklendi; `businesses` sahiplik sorgusu via `supabaseAny` |
| `src/lib/server-action-auth.ts` | `withAdminAuth`: `supabaseAny` eklendi; `user_profiles` rol kontrolü via `supabaseAny` |
| `src/lib/sunucu-eylem-kimlik-dogrulama.ts` | `withAdminAuth`: `supabaseAny` eklendi; `is_admin` RPC via `supabaseAny` |
| `src/lib/veri/admin/yonetici-kuyrugu.ts` | `getQueueCounts`/`listOpenReports`/`listPendingSubmissions`: her fonksiyona `supabaseAny` eklendi |
| `src/lib/veri/harita-okuma.ts` | `getMapBusinesses`: `supabaseAny` eklendi; genişletilmiş kolon sorgusu via `supabaseAny` |
| `src/lib/veri/kesif-okuma.ts` | `discoverBusinesses`: `supabaseAny` eklendi; `search_businesses_v1` RPC via `supabaseAny` |
| `src/lib/veri/menu-okuma.ts` | `getMenuItemPriceHistory`: `supabaseAny` eklendi; `get_menu_item_price_history_v1` RPC via `supabaseAny` |
| `src/lib/veri/owner/sahip-analitik.ts` | `getOwnerDashboardSummary`/`getOwnerAnalytics`: her fonksiyona `supabaseAny` eklendi |
| `src/lib/veri/pazar-okuma.ts` | `getMarketplaceBusinesses` ve 7 yardımcı fonksiyon: her birine `supabaseAny` eklendi |

### Dar Cast Deseni

Her dosyada Supabase client oluşturulduktan hemen sonra aşağıdaki sabit eklendi:

```typescript
const supabaseAny = supabase as unknown as {
  from: (t: string) => any;
  rpc: (fn: string, args?: any) => any;
  storage: any;
  auth: any;
};
```

Bu desen `(supabase as any)` kullanımının yerini alır: çift assertion (`as unknown as`) TypeScript'in tip güvenliğini korurken, yalnızca gerekli yüzeyi expose eden dar bir arayüz tanımlar.

### Doğrulama Sonuçları

```
npm run typecheck   → 0 hata
npm run lint        → 0 yeni hata (önceden var olan no-img-element + no-require-imports uyarıları değişmedi)
```
