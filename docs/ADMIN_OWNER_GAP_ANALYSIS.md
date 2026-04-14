# Admin ve Owner Panel Bosluk Analizi

**Tarih:** 2026-03-11
**Kapsam:** `apps/panel_flutter_web/lib/features/`

## Amac

Bu belge admin ve owner panelde hangi ekranin tamamlandigini, hangisinin kismen tamam oldugunu ve hangi alanlarda halen bosluk bulundugunu gosterir. Panel tarafi icin ana durum matrisi budur.

## Lejant

- ✅ Tamam: Uretim kullanimi icin hazir
- 🟡 Kismi: Calisiyor ama teknik borc veya eksik polish var
- ❌ Eksik: Planli ya da gerekli ama henuz yok

## Admin Panel Ozellikleri

### Cekirdek operasyonlar

| Ozellik | Route | Durum | Not |
|---|---|---|---|
| Dashboard | `/admin` | ✅ | Istatistik, banner ve hizli aksiyonlar |
| Business list | `/admin/businesses` | ✅ | Arama, filtre, verify, assign |
| Business submissions | `/admin/business-submissions` | ✅ | Server-side paginated onay akisi |
| Moderation queue | `/admin/queue` | ✅ | Report, suggestion ve claim birlesik kuyruk |
| Price suggestions | `/admin/price-suggestions` | ✅ | Fiyat onerisi onay akisleri |
| Reports | `/admin/reports` | ✅ | Durum ve tip filtresi ile rapor yonetimi |
| Owner claims | `/admin/claims` | ✅ | Sahiplik talepleri |
| Receipt workbench | `/admin/receipts` | ✅ | Fis inceleme ve match linking |
| Group requests | `/admin/group-requests` | ✅ | Grup talep operasyonu |

### Analytics ve observability

| Ozellik | Route | Durum | Not |
|---|---|---|---|
| Observability | `/admin/observability` | ✅ | Offline mutation, SLO, feature flag ve tracing |
| Admin search | `/admin/search` | ✅ | Cross-entity arama |

### Erisim ve guvenlik

| Ozellik | Route | Durum | Not |
|---|---|---|---|
| User access management | `/admin/users/:id` | ✅ | Erisim preview ve role override |
| Impersonation audit | Kullanici sayfasi ici | ✅ | `admin_audit_log` yazimi var |
| RBAC permission preview | Kullanici sayfasi ici | ✅ | Kullanici bazli business erisimi gorulebiliyor |

### B2B ve veri urunleri

| Ozellik | Route | Durum | Not |
|---|---|---|---|
| B2B exports | `/admin/b2b-exports` | ✅ | Trend, fiyat endeksi ve CSV urunleri |
| Monetization management | `/admin/monetization` | ✅ | Sponsorluk paket ve gelir ozeti |

### Tasarim sistemi gecisi

| Sayfa | Kalip | Durum |
|---|---|---|
| `admin_dashboard_page.dart` | `PanelPageHeader` | ✅ |
| `admin_businesses_page.dart` | `PanelPageHeader` | ✅ |
| `admin_business_submissions_page.dart` | `PanelPageHeader` | ✅ |
| `admin_reports_page.dart` | `PanelPageHeader` | ✅ |
| `admin_claims_page.dart` | `PanelPageHeader` | ✅ |
| `admin_queue_page.dart` | `PanelPageHeader` | ✅ |
| `admin_group_requests_page.dart` | `PanelPageHeader` | ✅ |
| `admin_user_access_page.dart` | `PanelPageHeader` | ✅ |
| `admin_dev_tools_page.dart` | `PanelPageHeader` | ✅ |

## Owner Panel Ozellikleri

### Isletme yonetimi

| Ozellik | Route | Durum | Not |
|---|---|---|---|
| Business list | `/owner/businesses` | ✅ | Multi-branch, status badge ve hizli aksiyon |
| New business application | `/owner/businesses/new` | ✅ | Basvuru formu |
| Submitted applications | `/owner/businesses/submissions` | ✅ | Onay durum takibi |
| Business context bar | Global owner shell | ✅ | Aktif business secimi |

### Menu yonetimi

| Ozellik | Route | Durum | Not |
|---|---|---|---|
| Menu list | `/owner/menus` | ✅ | SliverList ve filtreler |
| Menu editor | `/owner/menus/:id/edit` | ✅ | Tam CRUD |
| Menu PDF export | Editor ici | ✅ | Deferred load |
| Menu QR flow | Editor ici | ✅ | Deferred load |
| Menu share flow | Editor ici | ✅ | Deferred load |
| Menu embed flow | Editor ici | ✅ | Deferred load |

### Analytics ve growth

| Ozellik | Route | Durum | Not |
|---|---|---|---|
| Analytics dashboard | `/owner/analytics` | ✅ | QR scan, menu view ve top item/category |
| Growth hub | `/owner/growth` | ✅ | Sponsorluk ve growth sinyalleri |
| Sponsorship catalog | Growth icinde | ✅ | `sponsorship_packages` okur |
| Sponsorship lead form | Growth icinde | ✅ | `sponsorship_leads` yazar |

### Fiyat ve kalite

| Ozellik | Route | Durum | Not |
|---|---|---|---|
| Price suggestions review | `/owner/price-suggestions` | ✅ | Topluluk onerilerini degerlendirir |
| Suspended claims | `/owner/suspended` | ✅ | Ekran var; Ingilizce filtre etiketleri Turkceye cevrildi. |

### Takim yonetimi

| Ozellik | Route | Durum | Not |
|---|---|---|---|
| Team list | `/owner/team` | ✅ | Davet, rol, scope ve revoke |
| Branch veya all-branches scope | Team ici | ✅ | Scope toggle var |
| Impersonation banner | Owner shell | ✅ | Admin impersonation durumunu gosterir |

### Tasarim sistemi gecisi

Owner shell mutlu yol ekranlari buyuk olcude `PanelPageHeader` kullaniyor. Kalan `AppScaffold` kullanimi daha cok public, auth veya fallback yuzeylerinde.

## Bosluk Ozeti

### Eksik alanlar

| Ozellik | Oncelik | Not |
|---|---|---|
| ~~Saatlik analytics granulerligi~~ | ~~Orta~~ | `list_owner_analytics_hourly_v1` RPC eklendi (migration 20260408). `owner_analytics_page.dart`'a "Son 24 Saat" chip, `fetchAnalyticsHourly` repo metodu ve `_HourlyTrendCard` widget'i eklendi. |
| ~~AI Menü Analizi~~ | ~~Yüksek~~ | Migration 20260411, Edge Function `ai-menu-analyze`, `owner_ai_analysis` Flutter feature, router `/owner/ai-analysis`, owner shell nav item eklendi. Claude Haiku ile görsel → allerjen/kalori/içerik analizi; insan onay akışı. |
| Analytics permalink | Dusuk | Filtre durumunu paylasilabilir yapmak |
| Otomatik batch moderation UI | Dusuk | RPC izi var, tam UI yok |

### Kismi alanlar

| Ozellik | Bosluk | Oncelik |
|---|---|---|
| Admin liste sanallastirma | `businesses`, `business-submissions`, `reports` ve `claims` sanal govde kullanirken ana acik artik daha cok `queue` tarafinda | Orta |
| Admin panel tasarim sistemi | Ana admin yuzeyleri `PanelPageHeader` standardina tasindi; kalan borc artik ikincil ve dusuk etkili ekranlarda toplaniyor | Dusuk |
| e2e test coverage | Web ve panel smoke iyi, mobil live smoke release gate'te degil | Orta |

## Oncelik Sirasi

### Ilk dalga

1. `admin_queue_page.dart` icin sanal govde ve pagination standardini tamamlamak
2. Mobil live smoke icin stabil release gate kurmak
3. Ikincil admin ekranlarindaki son tasarim sistemi borcunu kapatmak

### Sonraki dalga

4. Saatlik analytics granulerligi
5. Analytics permalink
6. Batch moderation UI

## Ilgili Belgeler

- Sistem ozeti: `docs/SYSTEM_OVERVIEW.md`
- Mimari denetim: `docs/ARCHITECTURE_AUDIT.md`
- Yetki modeli: `docs/rbac.md`
- Owner analytics: `docs/analytics_owner.md`
- Moderation queue: `docs/moderation_queue.md`
