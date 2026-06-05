# Yeedoy — Eksik / Kısmi Listesi

> **Tarih:** 2026-06-03 (Haziran 2026 PR #7–#23 sonrası güncellendi)  
> **Yöntem:** Canlı kod taraması — kaynak kod, migration'lar, edge function'lar, CI workflow'ları  
> **Kapsam:** Mobile Flutter · Personel Flutter · Next.js Web · Supabase

---

## 🔴 Dış Entegrasyon — Bağlanmadı

Bunlar diğer tüm kampanya/bildirim özelliklerinin önündeki blocker'lardır. Provider seçimi yapılmadan aşağıdaki 🟠 maddeler aktif hale gelemez.

| # | Alan | Dosya | Durum |
|---|---|---|---|
| 1 | **Push Bildirimi Gönderimi** | `app/sunucu/yonetici/push-kampanyalari/route.ts` | ✅ FCM delivery code hazır (PR #52). GitHub secrets var ama runtime env eksik (FIREBASE_PROJECT_ID/CLIENT_EMAIL/PRIVATE_KEY). `.env.local` eklenince lokal test aktif; production'da deployment platform env var'larına eklenince live. Şu an `providerNotConfigured: true` döndürüyor. Docs: `docs/push-delivery-integration-plan.md` |
| 2 | **SMS Kampanya Gönderimi** | `app/sunucu/sahip/sms-kampanya/route.ts:72` | DB'ye kaydediyor, Netgsm/Twilio çağrısı yok |
| 3 | **E-posta Kampanyası** | `supabase/functions/send-email-campaign/` (193 satır) | Edge function yazılmış, provider (SendGrid/Resend/vb.) bağlantısı yok |

---

## 🟠 Web — Owner Paneli

| # | Route | Durum |
|---|---|---|
| 4 | `owner/marketing/loyalty` | ✅ MVP tamamlandı — loyalty_programs + upsert_loyalty_program_v1 RPC, puan kuralları, aktif/pasif toggle (PR #48) |
| 5 | `owner/marketing/automations` | ✅ MVP tamamlandı — business_automations + toggle, dış provider beklemede (PR #51) |
| 6 | `owner/marketing/campaigns` | Push kampanya formu var, FCM bağlantısı yok → blocker: madde 1 |
| 7 | `owner/marketing/email` | E-posta form var, provider bağlantısı yok → blocker: madde 3 |
| 8 | `owner/qr` | QR görüntüleme/indirme UI iskeleti var, gerçek QR generate/download yok |
| 9 | `owner/settings/domain` | Custom domain doğrulama — `verify-domain` edge function yazılmış (119 satır), UI↔backend bağlantısı yok |
| 10 | `owner/ai-analysis` | AI menü analizi — `ai-menu-analyze` edge function yazılmış (345 satır), owner panel entegrasyonu yok |
| 11 | `owner/menu/translations` | ✅ MVP tamamlandı — EN/AR, per-item kaydet, tamamlanma istatistikleri (PR #38) |

---

## 🟠 Web — Admin Paneli

| # | Route | Durum |
|---|---|---|
| 12 | `admin/sponsorships` | Sponsorluk modülü — DB migration var (`20260601_sponsorship_vitrin_package`), admin UI stub |
| 13 | `admin/sponsorship-leads` | Aday modülü stub |
| 14 | `admin/sponsorship-packages` | Paket modülü stub |
| 15 | `admin/b2b-exports` | Veri dışa aktarma stub |
| 16 | `admin/incidents` | Olay yönetimi stub |
| 17 | `admin/locations` | ✅ MVP tamamlandı — veri kalitesi görünümü: koordinatsız/şehirsiz/slugsuz metrikler + işletme tablosu (PR #42) |
| 18 | `admin/receipt-submissions` | Fatura inceleme stub |
| 19 | `admin/appeals` | ✅ MVP tamamlandı — moderation_appeals + admin_list/decide_v1 RPC, status filtresi, admin note, pagination (PR #46) |

---

## 🟡 Web — Auth / Public

| # | Alan | Durum |
|---|---|---|
| 20 | **Taste Twin (web)** | Sayfa tam stub (`(auth)/taste-twin`) — mobil algoritması çalışıyor ama web'e özel RPC yok |
| 21 | **2FA / Hesap Güvenliği** | Şifre sıfırlama çalışıyor, 2FA kısmı "Yakında" badge'i |
| 22 | **Inbox toplu okundu** | "Hepsini okundu işaretle" butonu devre dışı ("yakında" tooltip) |

---

## 🟡 Mobil

| # | Alan | Dosya | Durum |
|---|---|---|---|
| 23 | **Profil Sosyal Bağlantı Kaydetme** | `features/profile/ui/profile_page.dart:179` | Form var, `profileSocialSaveComingSoon` — backend çağrısı yok |
| 24 | **Business Menü Grafiği** | `features/business/ui/parts/business_menu_preview.dart:58` | `chartPlaceholderSoon` — grafik alanı placeholder |
| 25 | **Zincir İşletmeler** | `features/chains/` | Feature klasörü 1 dosya — implementasyon başlanmamış |
| 26 | **Grup Oy** | `features/grup_oy/` | Feature klasörü 1 dosya — implementasyon başlanmamış |
| 27 | **Yerlestir QR** | `features/yerlestir/ui/yerlestir_sayfasi.dart:413` | UI var, QR generate placeholder (`qr_flutter` paketi pubspec'te yok) |

---

## 🟡 Personel

| # | Alan | Satır | Durum |
|---|---|---|---|
| 28 | **Kampanya Sayfası** | `features/kampanya/ui/kampanya_sayfasi.dart` (446 satır) | UI yazılmış, data/domain katmanı yok — backend bağlantısı kurulamaz |
| 29 | **QR Görüntüleme** | `features/qr/ui/qr_sayfasi.dart` (153 satır) | UI var, data/domain yok |
| 30 | **QR Tarayıcı** | `features/qr_tarayici/ui/qr_tarayici_sayfasi.dart` (515 satır) | UI var, data/domain yok — `mobile_scanner` pubspec'te mevcut |

---

## ⚪ Edge Function — Boş

| # | Fonksiyon | Durum |
|---|---|---|
| 31 | `supabase/functions/wp-upload/` | 0 satır — placeholder dizin |
| 32 | `supabase/functions/wp-upload-user/` | 0 satır — placeholder dizin |

---

## ⚪ Test Kapsamı

| # | Alan | Mevcut | Boşluk |
|---|---|---|---|
| 33 | **Personel unit test** | 7 dosya | 3 app için çok az; data/domain katmanlarına test yok |
| 34 | **Web unit test** | 8 dosya | `src/lib/*` yardımcılarının çoğu test edilmiyor |
| 35 | **Web E2E** | 7 spec | Owner flow, 2FA, taste-twin, admin flow hiç yok |
| 36 | **Mobil integration** | 4 dosya | Sadece offline queue smoke — feature bazlı integration test yok |

---

## ✅ Tamamlanan — Haziran 2026 (PR #7–#23)

| # | Alan | Madde | PR | Durum |
|---|---|---|---|---|
| — | DB | Business hours kalibrasyon hatası (owner → `business_weekly_hours` alignment) | #12 | ✅ |
| — | Web | Price level rozet tutarsızlığı | #13 | ✅ |
| — | Mobile | Discovery açık/kapalı + fiyat rozeti | #14, #18 | ✅ |
| — | DB | `businesses.price_level` sütunu | #15 | ✅ |
| — | Web | Price level entegrasyonu | #16 | ✅ |
| — | DB | `search_nearby_businesses_v3` genişletildi | #17 | ✅ |
| — | Web | SEO sitemap hub sayfaları | #9 | ✅ |
| — | Web | Panel noindex | #9 | ✅ |
| — | Ops | KVKK ConsentGuard startup | #7 | ✅ |
| — | Test | Consent + growth smoke testleri | #8 | ✅ |
| — | Mobile | Keşif haritası MVP | #22 | ✅ |
| — | Docs | Fiyat Endeksi medya raporu taslağı | #10 | ✅ |
| — | Docs | DB açık/kapalı + fiyat rozeti analiz | #11 | ✅ |
| — | Ops | `analytics_events` composite index | #19 | ✅ |
| — | DB | `get_business_busy_hours_v1` RPC | #20 | ✅ |
| — | Web | Owner panel Yoğun Saatler widget | #21 | ✅ |
| — | Docs | Mobile release readiness checklist | #23 | ✅ |
| — | Web | Owner menu translations MVP | #38 | ✅ |
| — | Web | Admin locations veri kalitesi MVP | feature/web-admin-locations-mvp | ✅ |

---

## Öncelik Sırası

```
🔴 1-3   → Provider seç ve bağla (FCM/OneSignal, Netgsm/Twilio, e-posta)
🟠 4-11  → Owner marketing aktif hale getir (sahip retention doğrudan etkileniyor)
🟠 12-19 → Admin ops araçlarını tamamla (şu an manuel moderasyon gerekiyor)
🟡 20-30 → UX ve özellik boşluklarını kapat (açık/kapalı, rozet, harita ✅ tamamlandı)
⚪ 31-36 → Teknik borç ve test kapsamı
```
