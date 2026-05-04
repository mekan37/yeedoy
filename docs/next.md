# Flutter Web → Next.js Tam Geçiş Planı

**Tarih:** 2026-04-27  
**Hedef:** `apps/panel_flutter_web` tamamen kaldırılacak, tüm işlevsellik `apps/web_next` altında React/Next.js olarak yeniden inşa edilecek. Mobil uygulama (`apps/mobile_flutter`) korunur — yalnızca _yönetici/işletme paneli_ taşınır. Ayrıca mobil uygulamadaki kullanıcıya yönelik keşif/sosyal özellikler web'de de sunulacak.

---

## 1. Mevcut Durum Envanteri

### 1.1 `apps/panel_flutter_web` — Tüm Sayfalar

#### Auth / Public
| Flutter Route | Sayfa | Açıklama |
|---|---|---|
| `/` | `WebHomePage` | Pazarlama / landing sayfası |
| `/login` / `/isletme-giris` | `BusinessLoginPage` | İşletme sahibi girişi |
| `/isletme-kayit` | `BusinessRegisterPage` | İşletme kaydı |
| `/legal` | `LegalPage` | Yasal hub |
| `/legal/:slug` | `LegalPage` | Belirli yasal içerik |
| `/forbidden` | inline | 403 sayfası |
| `/m/:slug` | `PublicMenuSharePage` | Halka açık menü görünümü |
| `/embed/:businessId` | `EmbedViewerPage` | Embed iframe viewer |

#### Owner Shell (24 rota)
| Flutter Route | Sayfa | Öncelik |
|---|---|---|
| `/owner` | `OwnerDashboardPage` | P0 |
| `/owner/growth` | `OwnerGrowthPage` | P1 |
| `/owner/suspended` | `OwnerSuspendedClaimsPage` | P1 |
| `/owner/price-suggestions` | `OwnerPriceSuggestionsPage` | P1 |
| `/owner/menus` | `OwnerMenusPage` | P0 |
| `/owner/menu/editor` | `OwnerMenuEditorPage` | P0 |
| `/owner/menu/section-editor` | `OwnerSectionEditorPage` | P0 |
| `/owner/trash` | `OwnerMenuTrashPage` | P2 |
| `/owner/analytics` | `OwnerAnalyticsPage` | P1 |
| `/owner/requests` | `OwnerGroupRequestsPage` | P1 |
| `/owner/businesses` | `OwnerBusinessesPage` | P0 |
| `/owner/businesses/new` | `OwnerNewBusinessPage` | P0 |
| `/owner/businesses/submissions` | `OwnerBusinessSubmissionsPage` | P1 |
| `/owner/onboarding` | `OwnerOnboardingPage` | P0 |
| `/owner/activity` | `OwnerActivityPage` | P2 |
| `/owner/audit` | `OwnerAuditPage` | P2 |
| `/owner/team` | `OwnerTeamPage` | P1 |
| `/owner/ai-analysis` | `OwnerAiAnalysisPage` | P2 |
| `/owner/reviews` | `OwnerReviewsPage` | P1 |
| `/owner/settings/hours` | `OwnerBusinessHoursPage` | P0 |
| `/owner/settings/domain` | `OwnerCustomDomainPage` | P2 |
| `/owner/marketing/loyalty` | `OwnerLoyaltyPage` | P2 |
| `/owner/marketing/campaigns` | `OwnerPushCampaignsPage` | P3 |
| `/owner/marketing/email` | `OwnerEmailCampaignsPage` | P3 |
| `/owner/marketing/automations` | `OwnerAutomationsPage` | P3 |
| `/owner/qr/design` | `OwnerQrDesignKitPage` | P2 |
| `/owner/menu/translations` | `OwnerTranslationsPage` | P2 |

#### Admin Shell (27 rota)
| Flutter Route | Sayfa | Öncelik |
|---|---|---|
| `/admin` | `AdminDashboardPage` | P0 |
| `/admin/search` | `AdminSearchPage` | P0 |
| `/admin/queue` | `AdminQueuePage` | P0 |
| `/admin/reports` | `AdminReportsPage` | P0 |
| `/admin/appeals` | `AdminAppealsPage` | P1 |
| `/admin/growth` | `AdminGrowthPage` | P1 |
| `/admin/claims` | `AdminClaimsPage` | P0 |
| `/admin/suspended` | `AdminSuspendedClaimsPage` | P0 |
| `/admin/price-suggestions` | `AdminPriceSuggestionsPage` | P1 |
| `/admin/suggestions` | `AdminSuggestionsPage` | P1 |
| `/admin/sponsorships` | `AdminSponsorshipsPage` | P2 |
| `/admin/sponsorship-packages` | `AdminSponsorshipPackagesPage` | P2 |
| `/admin/sponsorship-leads` | `AdminSponsorshipLeadsPage` | P2 |
| `/admin/verified` | `AdminVerifiedPage` | P1 |
| `/admin/group-requests` | `AdminGroupRequestsPage` | P1 |
| `/admin/business-submissions` | `AdminBusinessSubmissionsPage` | P0 |
| `/admin/businesses` | `AdminBusinessesPage` | P0 |
| `/admin/table-feedback` | `AdminTableFeedbackPage` | P2 |
| `/admin/receipt-submissions` | `AdminReceiptSubmissionsPage` | P1 |
| `/admin/audit` | `AdminAuditPage` | P2 |
| `/admin/trash` | `AdminMenuRestorePage` | P1 |
| `/admin/dev-tools` | `AdminDevToolsPage` | P3 |
| `/admin/observability` | `AdminObservabilityPage` | P2 |
| `/admin/b2b-exports` | `AdminB2bExportsPage` | P2 |
| `/admin/incidents` | `AdminIncidentCenterPage` | P1 |
| `/admin/temp-uploads` | `AdminTempUploadsPage` | P2 |
| `/admin/users/:id` | `AdminUserAccessPage` | P1 |
| `/admin/locations` | `AdminLocationsPage` | P1 |

### 1.2 `apps/mobile_flutter` — Tam Özellik Envanteri ve Web Pariteleri

Mobil uygulama tamamen korunur. Her özelliğin web karşılığı aşağıda tanımlanmıştır.

#### Halka Açık Sayfalar (Auth Gerektirmez)
| Mobil Özellik | Sayfa | Web Hedef Rota | Web Öncelik |
|---|---|---|---|
| Keşif / Arama | `DiscoveryPage` | `/(public)/discover/` | P0 — SEO + SSR |
| İşletme Detay | `BusinessPage` | `/(public)/b/[slug]/` | P0 — var, genişletilecek |
| Menü Görüntüle | `MenuPage` | `/(public)/m/[slug]/` | P0 — var |
| Menü Öğe Detay | `MenuItemPage` | `/(public)/m/[slug]/i/[itemId]/` | P0 — var |
| Menü Paylaşım | `PublicMenuSharePage` | `/(public)/m/[slug]/` | P0 — var |
| Zincir Detay | `ChainPage` | `/(public)/chain/[slug]/` | P1 |
| İşletme Karşılaştır | `ComparePage` | `/(public)/compare/` | P1 — query param: `?a=slug1&b=slug2` |
| Top İşletmeler | `TopBusinessesPage` | `/(public)/top/` | P1 |
| İşletme Yorumları | `BusinessReviewsPage` | `/(public)/b/[slug]/reviews/` | P1 |
| Gurme Profili / Akış | `FeedPage` / `GourmetsPage` | `/(public)/feed/` | P2 |
| Haftalık Kahramanlar | `HeroesPage` | `/(public)/heroes/` | P2 |
| Bütçe Kombolar | `BudgetComboResultsPage` | `/(public)/budget/` | P2 |
| İşletme Öneri | `SuggestBusinessPage` | `/(public)/suggest/` | P2 |
| Embed Viewer | `EmbedViewerPage` | `/(public)/embed/[businessId]/` | P2 |
| Yasal İçerik | `LegalPage` | `/(public)/legal/` | P1 — var (/legal) |
| Yasal Kabul | `LegalAcceptancePage` | auth flow içinde inline | P1 |

#### Authenticated Kullanıcı Sayfaları
| Mobil Özellik | Sayfa | Web Hedef Rota | Web Öncelik |
|---|---|---|---|
| Profil | `ProfilePage` | `/(auth)/profile/` | P1 |
| Profil Ayarları | `ProfileSettingsPage` | `/(auth)/profile/settings/` | P1 |
| Favoriler | `FavoritesPage` | `/(auth)/favorites/` | P1 |
| Bildirimler / Gelen Kutusu | `InboxPage` | `/(auth)/inbox/` | P2 |
| Avantajlar | `PerksPage` | `/(auth)/perks/` | P2 |
| Puan Kartlarım (Loyalty) | profil içi `_LoyaltyCardsSection` | `/(auth)/loyalty/` | P2 |
| Süspanse Taleplerim | `MySuspendedClaimsPage` | `/(auth)/claims/` | P2 |
| Katkı Girişi | `contribute_entry.dart` | `/(auth)/contribute/` | P2 |
| Yorum Yaz | `ReviewCreatePage` | `/(auth)/b/[slug]/reviews/new/` | P1 |
| Takip Ettiğim Gurmeleri | `FollowingPage` | `/(auth)/following/` | P2 |
| Collab Listelerim | `CollabListsPage` | `/(auth)/collab-lists/` | P2 |
| Collab Liste Detay | `CollabListDetailPage` | `/(auth)/collab-lists/[id]/` | P2 |
| Collab Liste Katıl | `CollabListJoinPage` | `/(auth)/collab-lists/join/` | P2 — `?token=` param |
| Grup İsteği Oluştur | `GroupRequestWizardPage` | `/(auth)/group-requests/new/` | P2 |
| Grup İsteği Detay | `GroupRequestDetailPage` | `/(auth)/group-requests/[id]/` | P2 |
| Grup İsteklerim | `MyGroupRequestsPage` | `/(auth)/group-requests/` | P2 |
| Önerilerim | `MySuggestionsPage` | `/(auth)/suggestions/` | P2 |
| Fiyat Alarmlarım | `price_alert_sheet.dart` | `/(auth)/price-alerts/` | P3 |
| Akıllı Besleme | `SmartFeedPage` | `/(auth)/smart-feed/` | P3 |
| Taste Twin | `TasteTwinPage` | `/(auth)/taste-twin/` | P3 |

#### Auth Akışı
| Mobil Özellik | Sayfa | Web Hedef Rota | Web Öncelik |
|---|---|---|---|
| Giriş | `LoginPage` | `/(auth)/login/` veya `/login/` | P0 — var |
| Şifre Unutma | `ForgotPasswordPage` | `/(auth)/forgot-password/` | P1 |
| Hesap Güvenliği | `AccountSecurityPage` | `/(auth)/profile/security/` | P2 |
| Kullanıcı Onboarding | `OnboardingPage` | `/(auth)/onboarding/` | P2 |

### 1.3 `apps/web_next` — Mevcut Durum

Zaten var olan şeyler:
- `app/(public)/b/[slug]/page.tsx` — işletme sayfası
- `app/(public)/m/[slug]/page.tsx` — public menü
- `app/(public)/m/[slug]/i/[itemId]/page.tsx` — menü item detay
- `app/(public)/m/[slug]/c/[categoryId]/page.tsx` — kategori filtresi
- `app/login/page.tsx` — basit login (panel handoff için)
- `app/qr/[businessId]/page.tsx` — QR landing
- `app/api/feedback/route.ts`, `media/upload`, `og`, `presentation-settings`, `track`
- `src/lib/db/menu-read.ts` — menü okuma katmanı
- Design system: `tokens.css`, `globals.css`, Tailwind config

---

## 2. Hedef Mimari

### 2.0 Domain Mimarisi

Tek bir Next.js deployment; subdomain'e göre farklı deneyimler sunulur.

| Domain | Hedef Kitle | İçerik |
|---|---|---|
| `yeedoy.com` | Tüm kullanıcılar | Keşif, işletme/menü sayfaları, auth (mobil parçalığı) |
| `isletme.yeedoy.com` | İşletme sahipleri | Owner panel (tüm `/owner/*` rotaları) |
| `ops.yeedoy.com` | Sadece admin ekibi | Admin panel (tüm `/admin/*` rotaları) |

**`ops.yeedoy.com` neden güvenli?**
- DNS'te var ancak hiçbir public sayfadan link verilmez → arama motorları keşfedemez
- Middleware: `ops.*` subdomaini hem `/admin/*` rewrite hem de session + admin rol kontrolü gerektirir
- `robots.txt` `Disallow: /admin/` ve `X-Robots-Tag: noindex` response header ile tarama engeli
- Güvenlik katmanları **çoğaltılır**: gizli subdomain + Supabase session + `user_profiles.role` admin kontrolü

**Subdomain Routing (middleware.ts):**
```typescript
// OWN_HOSTNAMES = "localhost,yeedoy.com"
// OWNER_HOSTNAMES = "isletme.yeedoy.com,isletme.localhost"
// ADMIN_HOSTNAME  = "ops.yeedoy.com,ops.localhost"   ← env var, NOT hardcoded

if (hostname matches OWNER_HOSTNAMES) {
  rewrite to /owner/[...path]  // tüm owner/* rotaları buraya
}
if (hostname matches ADMIN_HOSTNAME) {
  rewrite to /admin/[...path]  // tüm admin/* rotaları buraya
}
```

**Vercel'de DNS:**
```
isletme.yeedoy.com  CNAME  cname.vercel-dns.com
ops.yeedoy.com      CNAME  cname.vercel-dns.com   (internal only, no public docs)
```

**Avantaj:** İşletme sahipleri `isletme.yeedoy.com` adresini kolayca hatırlar; admin URL'si gizli tutulduğu sürece ekstra güvenlik katmanı sağlar. Gerçek güvenlik auth'tan gelir, gizlilik yalnızca ek frictio sağlar.

### 2.1 Next.js App Router Yapısı

```
apps/web_next/app/
│
│  ── yeedoy.com ─────────────────────────────────────────────
│
├── page.tsx                     # Ana sayfa / Keşif (mobil DiscoveryPage eşdeğeri)
├── (public)/                    # Halka açık (SEO, no auth)
│   ├── b/[slug]/                # İşletme detay (+ /reviews alt rota)
│   ├── m/[slug]/                # Menü görüntüleyici
│   ├── discover/                # Keşif (var, genişletilecek)
│   ├── chain/[slug]/            # Zincir detay (YENİ)
│   ├── compare/                 # İşletme karşılaştır (YENİ)
│   ├── top/                     # Top işletmeler (YENİ)
│   ├── budget/                  # Bütçe komboları (YENİ)
│   ├── feed/                    # Gurme aktivite akışı (YENİ)
│   ├── heroes/                  # Haftalık liderlik (YENİ)
│   ├── suggest/                 # İşletme öneri formu (YENİ)
│   ├── embed/[businessId]/      # Embed viewer (YENİ)
│   ├── gourmet/[username]/      # Gurme profil (YENİ)
│   └── legal/                   # Yasal içerikler
├── login/                       # Kullanıcı girişi (consumer + owner)
├── forgot-password/             # Şifre sıfırlama
├── (auth)/                      # Authenticated tüketici
│   ├── profile/
│   │   ├── page.tsx             # Profil
│   │   ├── settings/page.tsx    # Profil ayarları
│   │   └── security/page.tsx    # Hesap güvenliği
│   ├── favorites/               # Favoriler
│   ├── inbox/                   # Bildirimler
│   ├── perks/                   # Avantajlar
│   ├── loyalty/                 # Puan kartları
│   ├── claims/                  # Süspanse talepler
│   ├── suggestions/             # Önerilerim
│   ├── following/               # Takip ettiğim gurmeleri
│   ├── contribute/              # Katkı girişi
│   ├── price-alerts/            # Fiyat alarmları
│   ├── smart-feed/              # Akıllı besleme
│   ├── taste-twin/              # Taste Twin
│   ├── onboarding/              # Kullanıcı onboarding
│   ├── group-requests/          # Grup istekleri
│   │   ├── page.tsx
│   │   ├── new/page.tsx
│   │   └── [id]/page.tsx
│   └── collab-lists/            # İşbirlikçi listeler
│       ├── page.tsx
│       ├── join/page.tsx
│       └── [id]/page.tsx
│
│  ── isletme.yeedoy.com → middleware rewrites to /owner/* ───
│
├── owner/                       # Owner panel (isletme.yeedoy.com)
│   ├── layout.tsx               # OwnerShellClient (PanelShell)
│   ├── page.tsx                 # → redirect /owner/dashboard
│   ├── dashboard/page.tsx
│   ├── businesses/
│   │   ├── page.tsx             # İşletme listesi
│   │   ├── new/page.tsx         # Yeni işletme formu
│   │   └── [id]/page.tsx        # İşletme detay
│   ├── menus/
│   │   ├── page.tsx             # Menü listesi
│   │   └── [id]/page.tsx        # Menü editör
│   ├── analytics/page.tsx
│   ├── reviews/page.tsx
│   ├── team/page.tsx
│   ├── qr/page.tsx
│   ├── pricing/page.tsx
│   ├── marketing/
│   │   ├── loyalty/page.tsx
│   │   └── campaigns/page.tsx
│   └── settings/
│       ├── page.tsx
│       ├── hours/page.tsx
│       └── domain/page.tsx
│
│  ── ops.yeedoy.com → middleware rewrites to /admin/* ────────
│  ── (URL is NOT public — no links, robots disallow) ─────────
│
├── admin/                       # Admin panel (ops.yeedoy.com)
│   ├── layout.tsx               # AdminShellClient (PanelShell)
│   ├── page.tsx                 # → redirect /admin/dashboard
│   ├── dashboard/page.tsx
│   ├── businesses/page.tsx
│   ├── claims/page.tsx
│   ├── users/page.tsx
│   ├── reviews/page.tsx
│   ├── analytics/page.tsx
│   ├── price-suggestions/page.tsx
│   ├── group-requests/page.tsx
│   ├── business-submissions/page.tsx
│   ├── roles/page.tsx
│   ├── observability/page.tsx
│   └── dev-tools/page.tsx
│
├── api/                         # Route handlers
│   ├── owner/                   # Owner mutations (YENİ)
│   ├── admin/                   # Admin mutations (YENİ)
│   └── ...
└── middleware.ts                # Domain routing + Auth + RBAC
```

### 2.2 State Management

| Flutter (Riverpod) | React Karşılığı | Kullanım |
|---|---|---|
| `AsyncNotifierProvider` | `@tanstack/react-query` `useQuery` | Tüm sunucu verisi |
| `NotifierProvider` | `zustand` store | Kalıcı UI state (sidebar, filtreler) |
| `StateProvider` / `Provider` | React `useState` / `useContext` | Lokal UI state |
| Supabase Realtime stream | `supabase-js` `channel().on(...)` + `useEffect` | Gerçek zamanlı |
| `ref.invalidate()` | `queryClient.invalidateQueries()` | Mutation sonrası yenileme |

**Paket seçimi:**
```json
"@tanstack/react-query": "^5.x",
"zustand": "^5.x",
"@supabase/supabase-js": "^2.x",
"@supabase/ssr": "^0.x"
```

### 2.3 Auth & RBAC

Flutter'da GoRouter'ın `redirect` callback'i ve `is_admin` RPC kullanılıyor.

Next.js karşılığı:
```typescript
// middleware.ts
// 1. Supabase SSR session → kullanıcı var mı?
// 2. /owner/* → business_owner rolü var mı? (user_roles tablosu)
// 3. /admin/* → is_admin() RPC veya admin_role claim
// 4. /(auth)/* → basit oturum kontrolü
```

`@supabase/ssr` paketi middleware + server component için cookie-based session sağlar.

### 2.4 Veri Katmanı

**Server Components (RSC)** → Supabase Server Client (cookie-based)  
**Client Components** → React Query + Supabase Browser Client  
**Mutations** → `app/api/**/route.ts` (zod + rate-limit + auth)

```
src/lib/db/
├── menu-read.ts          (var)
├── business-read.ts      (YENİ)
├── discovery-read.ts     (YENİ)
├── owner/
│   ├── owner-menus.ts    (YENİ)
│   ├── owner-analytics.ts (YENİ)
│   └── ...
└── admin/
    ├── admin-queue.ts    (YENİ)
    ├── admin-moderation.ts (YENİ)
    └── ...
```

### 2.5 Bileşen Sistemi

Flutter'ın `PanelShell`, `PanelSidebar`, `PanelPageHeader` → React eşdeğerleri:

```
src/ui/
├── shell/
│   ├── panel-shell.tsx          # Sidebar + topbar layout
│   ├── panel-sidebar.tsx        # Nav item listesi
│   ├── panel-sidebar-item.tsx   # Aktif state, hover animasyonu
│   └── panel-topbar.tsx         # Başlık + kullanıcı menüsü
├── layout/
│   ├── panel-page-header.tsx    # Eyebrow + title + description + actions
│   ├── panel-section-card.tsx   # İçerik kartı
│   └── panel-content-surface.tsx # max-w-[1520px] wrapper
├── components/
│   ├── metric-card.tsx          # KPI widget, hover lift
│   ├── panel-action-button.tsx  # Gradient primary + variants
│   ├── panel-data-table.tsx     # Horizontal scroll tablo
│   ├── panel-empty-state.tsx    # İkon + başlık + CTA
│   ├── panel-search-field.tsx   # Search input
│   └── panel-toolbar.tsx        # Filter/action toolbar
└── sections/                    # (var) public sections
```

Tailwind + CSS Modules veya sade Tailwind kullanılacak. Yeni bir component library eklenmez — sadece `shadcn/ui` primitives (Radix tabanlı) alınabilir; karar: **headless Radix + kendi Tailwind stilleri**.

---

## 3. Rota Eşleme

### Owner Panel
| Flutter | Next.js App Router |
|---|---|
| `/owner` | `/(owner)/owner/dashboard/page.tsx` |
| `/owner/growth` | `/(owner)/owner/growth/page.tsx` |
| `/owner/suspended` | `/(owner)/owner/suspended/page.tsx` |
| `/owner/price-suggestions` | `/(owner)/owner/price-suggestions/page.tsx` |
| `/owner/menus` | `/(owner)/owner/menus/page.tsx` |
| `/owner/menus` (editor push) | `/(owner)/owner/menus/[menuId]/edit/page.tsx` |
| `/owner/trash` | `/(owner)/owner/trash/page.tsx` |
| `/owner/analytics` | `/(owner)/owner/analytics/page.tsx` |
| `/owner/requests` | `/(owner)/owner/requests/page.tsx` |
| `/owner/businesses` | `/(owner)/owner/businesses/page.tsx` |
| `/owner/businesses/new` | `/(owner)/owner/businesses/new/page.tsx` |
| `/owner/businesses/submissions` | `/(owner)/owner/businesses/submissions/page.tsx` |
| `/owner/onboarding` | `/(owner)/owner/onboarding/page.tsx` |
| `/owner/activity` | `/(owner)/owner/activity/page.tsx` |
| `/owner/audit` | `/(owner)/owner/audit/page.tsx` |
| `/owner/team` | `/(owner)/owner/team/page.tsx` |
| `/owner/ai-analysis` | `/(owner)/owner/ai-analysis/page.tsx` |
| `/owner/reviews` | `/(owner)/owner/reviews/page.tsx` |
| `/owner/settings/hours` | `/(owner)/owner/settings/hours/page.tsx` |
| `/owner/settings/domain` | `/(owner)/owner/settings/domain/page.tsx` |
| `/owner/marketing/loyalty` | `/(owner)/owner/marketing/loyalty/page.tsx` |
| `/owner/marketing/campaigns` | `/(owner)/owner/marketing/campaigns/page.tsx` |
| `/owner/marketing/email` | `/(owner)/owner/marketing/email/page.tsx` |
| `/owner/marketing/automations` | `/(owner)/owner/marketing/automations/page.tsx` |
| `/owner/qr/design` | `/(owner)/owner/qr/page.tsx` |
| `/owner/menu/translations` | `/(owner)/owner/menu/translations/page.tsx` |

### Admin Panel
| Flutter | Next.js App Router |
|---|---|
| `/admin` | `/(admin)/admin/page.tsx` |
| `/admin/search` | `/(admin)/admin/search/page.tsx` |
| `/admin/queue` | `/(admin)/admin/queue/page.tsx` |
| `/admin/reports` | `/(admin)/admin/reports/page.tsx` |
| `/admin/appeals` | `/(admin)/admin/appeals/page.tsx` |
| `/admin/growth` | `/(admin)/admin/growth/page.tsx` |
| `/admin/claims` | `/(admin)/admin/claims/page.tsx` |
| `/admin/suspended` | `/(admin)/admin/suspended/page.tsx` |
| `/admin/price-suggestions` | `/(admin)/admin/price-suggestions/page.tsx` |
| `/admin/suggestions` | `/(admin)/admin/suggestions/page.tsx` |
| `/admin/sponsorships` | `/(admin)/admin/sponsorships/page.tsx` |
| `/admin/sponsorship-packages` | `/(admin)/admin/sponsorship-packages/page.tsx` |
| `/admin/sponsorship-leads` | `/(admin)/admin/sponsorship-leads/page.tsx` |
| `/admin/verified` | `/(admin)/admin/verified/page.tsx` |
| `/admin/group-requests` | `/(admin)/admin/group-requests/page.tsx` |
| `/admin/business-submissions` | `/(admin)/admin/business-submissions/page.tsx` |
| `/admin/businesses` | `/(admin)/admin/businesses/page.tsx` |
| `/admin/users/:id` | `/(admin)/admin/users/[id]/page.tsx` |
| `/admin/table-feedback` | `/(admin)/admin/table-feedback/page.tsx` |
| `/admin/receipt-submissions` | `/(admin)/admin/receipt-submissions/page.tsx` |
| `/admin/audit` | `/(admin)/admin/audit/page.tsx` |
| `/admin/trash` | `/(admin)/admin/trash/page.tsx` |
| `/admin/dev-tools` | `/(admin)/admin/dev-tools/page.tsx` |
| `/admin/observability` | `/(admin)/admin/observability/page.tsx` |
| `/admin/b2b-exports` | `/(admin)/admin/b2b-exports/page.tsx` |
| `/admin/incidents` | `/(admin)/admin/incidents/page.tsx` |
| `/admin/temp-uploads` | `/(admin)/admin/temp-uploads/page.tsx` |
| `/admin/locations` | `/(admin)/admin/locations/page.tsx` |

### Kullanıcı (Consumer) Sayfaları — Public
| Mobil | Next.js App Router |
|---|---|
| `DiscoveryPage` | `/(public)/discover/page.tsx` |
| `BusinessPage` | `/(public)/b/[slug]/page.tsx` (genişletilecek) |
| `ChainPage` | `/(public)/chain/[slug]/page.tsx` |
| `ComparePage` | `/(public)/compare/page.tsx` |
| `TopBusinessesPage` | `/(public)/top/page.tsx` |
| `BusinessReviewsPage` | `/(public)/b/[slug]/reviews/page.tsx` |
| `FeedPage` / `GourmetsPage` | `/(public)/feed/page.tsx` |
| `HeroesPage` | `/(public)/heroes/page.tsx` |
| `BudgetComboResultsPage` | `/(public)/budget/page.tsx` |
| `SuggestBusinessPage` | `/(public)/suggest/page.tsx` |
| `EmbedViewerPage` | `/(public)/embed/[businessId]/page.tsx` |
| `LegalPage` | `/(public)/legal/page.tsx` |

### Kullanıcı (Consumer) Sayfaları — Auth Gerekli
| Mobil | Next.js App Router |
|---|---|
| `ProfilePage` | `/(auth)/profile/page.tsx` |
| `ProfileSettingsPage` | `/(auth)/profile/settings/page.tsx` |
| `AccountSecurityPage` | `/(auth)/profile/security/page.tsx` |
| `FavoritesPage` | `/(auth)/favorites/page.tsx` |
| `InboxPage` | `/(auth)/inbox/page.tsx` |
| `PerksPage` | `/(auth)/perks/page.tsx` |
| Puan Kartlarım | `/(auth)/loyalty/page.tsx` |
| `ReviewCreatePage` | `/(auth)/b/[slug]/reviews/new/page.tsx` |
| `MySuspendedClaimsPage` | `/(auth)/claims/page.tsx` |
| `MySuggestionsPage` | `/(auth)/suggestions/page.tsx` |
| `FollowingPage` | `/(auth)/following/page.tsx` |
| `GroupRequestWizardPage` | `/(auth)/group-requests/new/page.tsx` |
| `GroupRequestDetailPage` | `/(auth)/group-requests/[id]/page.tsx` |
| `MyGroupRequestsPage` | `/(auth)/group-requests/page.tsx` |
| `CollabListsPage` | `/(auth)/collab-lists/page.tsx` |
| `CollabListDetailPage` | `/(auth)/collab-lists/[id]/page.tsx` |
| `CollabListJoinPage` | `/(auth)/collab-lists/join/page.tsx` |
| Fiyat Alarmları | `/(auth)/price-alerts/page.tsx` |
| `SmartFeedPage` | `/(auth)/smart-feed/page.tsx` |
| `TasteTwinPage` | `/(auth)/taste-twin/page.tsx` |
| `OnboardingPage` | `/(auth)/onboarding/page.tsx` |

### Auth Akışı
| Mobil | Next.js App Router |
|---|---|
| `LoginPage` | `/login/page.tsx` (var) |
| `ForgotPasswordPage` | `/forgot-password/page.tsx` |
| `AccountSecurityPage` | `/(auth)/profile/security/page.tsx` |

---

## 4. Supabase RPC Envanteri

### Panel Web RPC'leri (taşınacak)
```
admin_get_queues_counts_v1
admin_get_sponsorship_summary_v1
admin_list_sponsorship_inventory_v1
admin_sla_metrics_v1
is_admin
get_owner_dashboard_summary_v1  (varsayım — owner dashboard)
get_owner_analytics_v1
get_owner_reviews_v1
```

### Mobil RPC'leri (web'e eklenecek)
```
get_city_districts_v1
get_my_achievements_v1/v2
get_my_behavior_segment_v1
get_my_daily_micro_task_v1
get_my_diet_profile_v1
get_my_loyalty_cards_v1
get_my_profile_progress_v1
get_my_profile_stats
get_my_reputation_score_v1
get_my_silent_quality_score_v1
get_my_suspended_claim_badge_v1
get_my_trust_graph_v1
get_my_weekly_missions
mark_all_notifications_read_v1
get_business_reviews_v3
get_weekly_contributor_leaderboard_v1
```

Tüm RPC çağrıları `src/lib/db/` altında typed wrapper fonksiyonlar olarak sarılacak. Doğrudan client'tan `.rpc()` çağrısı yapılmaz.

---

## 5. Geçiş Fazları

### Faz 0 — Altyapı (1-2 hafta)

**Hedef:** Next.js'in Owner ve Admin için hazır olması.

1. `middleware.ts` genişletme: `/owner/*` ve `/admin/*` koruma
2. `app/(owner)/layout.tsx` — Owner shell layout bileşeni
3. `app/(admin)/layout.tsx` — Admin shell layout bileşeni
4. `src/ui/shell/` — PanelShell, PanelSidebar, PanelTopbar bileşenleri
5. `src/ui/layout/` — PanelPageHeader, PanelSectionCard bileşenleri
6. `src/ui/components/` — MetricCard, PanelActionButton, PanelDataTable, PanelEmptyState
7. `@tanstack/react-query` + `QueryClientProvider` global kurulumu
8. Zustand store: sidebar state, filtreler, business context
9. `src/lib/supabase/owner.ts` — owner-role client helper
10. `src/lib/supabase/admin.ts` — admin-role server client helper

**Kontrol:** `/owner` ve `/admin` rotaları yükleniyor, auth redirect çalışıyor.

---

### Faz 1 — Owner Core (3-4 hafta)

**P0 sayfalar — iş yapabilirlik için zorunlu:**

| Sıra | Sayfa | Önce Ne |
|---|---|---|
| 1 | `owner/dashboard` | MetricCard, KPI RPC wrapper |
| 2 | `owner/businesses` | Business list + CRUD mutations |
| 3 | `owner/businesses/new` | Form (zod validation), 2-column layout |
| 4 | `owner/onboarding` | Stepper bileşeni |
| 5 | `owner/menus` | Menu list + FAB pattern |
| 6 | `owner/menus/[menuId]/edit` | Full menu editor (ağır, ayrı milestone) |
| 7 | `owner/settings/hours` | Business hours form |

**P1 sayfalar — operasyonel tamamlanma:**

| Sayfa | Notlar |
|---|---|
| `owner/analytics` | Chart library: Recharts (zaten web-friendly) |
| `owner/reviews` | Filtreleme + yorum moderasyonu |
| `owner/suspended` | Süspanse talep yönetimi |
| `owner/price-suggestions` | Öneri approve/reject akışı |
| `owner/requests` | Grup istekleri tablosu |
| `owner/team` | Üye davet + rol yönetimi |
| `owner/businesses/submissions` | Başvuru durumu takibi |
| `owner/growth` | Growth metrikleri |

---

### Faz 2 — Admin Core (3-4 hafta)

**P0 sayfalar:**

| Sıra | Sayfa | Önce Ne |
|---|---|---|
| 1 | `admin/dashboard` | Admin KPI, SLA metrikleri |
| 2 | `admin/queue` | İnceleme kuyruğu (realtime?) |
| 3 | `admin/businesses` | İşletme arama + aksiyon |
| 4 | `admin/business-submissions` | Başvuru onay akışı |
| 5 | `admin/claims` | Talep yönetimi |
| 6 | `admin/suspended` | Süspanse yönetimi |
| 7 | `admin/reports` | Raporlar tablosu |
| 8 | `admin/search` | Global admin arama |

**P1 sayfalar:**

| Sayfa | Notlar |
|---|---|
| `admin/users/[id]` | Kullanıcı erişim sayfası |
| `admin/incidents` | Olay merkezi |
| `admin/group-requests` | Grup istekleri onayı |
| `admin/verified` | Doğrulanmış işletmeler |
| `admin/appeals` | İtiraz akışı |
| `admin/receipt-submissions` | Fiş başvuruları |
| `admin/trash` | Silinmiş menü restore |
| `admin/price-suggestions` | Admin fiyat onayları |
| `admin/suggestions` | Platform önerileri |
| `admin/growth` | Platform büyüme metrikleri |
| `admin/locations` | Konum yönetimi |

---

### Faz 3 — Owner Tamamlama + İleri (2 hafta)

**P2 sayfalar:**

- `owner/activity` — Aktivite akışı
- `owner/audit` — Audit log
- `owner/ai-analysis` — AI menü analizi
- `owner/qr/design` — QR tasarım kiti
- `owner/menu/translations` — Menü çevirileri
- `owner/marketing/loyalty` — Sadakat programı
- `owner/settings/domain` — Özel domain
- `owner/trash` — Silinmiş menü geri yükleme

**P3 sayfalar:**

- `owner/marketing/campaigns` — Push kampanyaları
- `owner/marketing/email` — E-posta kampanyaları
- `owner/marketing/automations` — Otomasyon akışları

**P2-P3 Admin:**
- `admin/sponsorships` serisi (3 sayfa)
- `admin/observability`
- `admin/b2b-exports`
- `admin/table-feedback`
- `admin/temp-uploads`
- `admin/dev-tools`
- `admin/audit`

---

### Faz 4 — Consumer Web Sayfaları (4-6 hafta)

**P0 — Hemen (SEO değeri yüksek, auth gerektirmez):**

| Sayfa | Not |
|---|---|
| `/(public)/discover/` | SSR + React Query, filtreli arama, SEO |
| `/(public)/b/[slug]/` genişletme | Yorum bölümü, açılış saatleri badge, sosyal linkler |
| `/(public)/b/[slug]/reviews/` | Yorum listesi (public görünüm) |
| `/(public)/top/` | Top işletmeler listesi |
| `/(public)/chain/[slug]/` | Zincir sayfası |
| `/(public)/legal/` | Yasal içerik hub |

**P1 — Önemli (kullanıcı etkileşimi):**

| Sayfa | Not |
|---|---|
| `/(public)/compare/` | 2 işletme yan yana karşılaştırma |
| `/(public)/budget/` | Bütçe bazlı öneriler |
| `/(public)/suggest/` | İşletme öneri formu |
| `/(auth)/profile/` | Profil görüntüle |
| `/(auth)/profile/settings/` | Ad, fotoğraf, tercihler |
| `/(auth)/favorites/` | Favori işletmeler |
| `/(auth)/b/[slug]/reviews/new/` | Yorum yazma akışı (auth gerekli) |
| `/forgot-password/` | Şifre sıfırlama |

**P2 — Tamamlanma (topluluk özellikleri):**

| Sayfa | Not |
|---|---|
| `/(public)/feed/` | Gurme aktivite akışı |
| `/(public)/heroes/` | Haftalık liderlik tablosu |
| `/(public)/embed/[businessId]/` | Iframe embed viewer |
| `/(auth)/inbox/` | Bildirim gelen kutusu |
| `/(auth)/perks/` | Avantajlar + ödüller listesi |
| `/(auth)/loyalty/` | Puan kartları (tüm işletmeler) |
| `/(auth)/claims/` | Süspanse talep geçmişim |
| `/(auth)/suggestions/` | Gönderdiğim öneriler |
| `/(auth)/following/` | Takip ettiğim gurmeleri |
| `/(auth)/group-requests/` | Grup isteklerim (liste) |
| `/(auth)/group-requests/new/` | Yeni grup isteği wizard |
| `/(auth)/group-requests/[id]/` | İstek detayı |
| `/(auth)/collab-lists/` | Collab listelerim |
| `/(auth)/collab-lists/[id]/` | Liste detayı + oylama |
| `/(auth)/collab-lists/join/` | Token ile listeye katıl |
| `/(auth)/contribute/` | Katkı giriş noktası |
| `/(auth)/onboarding/` | Diyet profili + tercihler wizard |
| `/(auth)/profile/security/` | 2FA + şifre değiştir |

**P3 — Gelişmiş (algoritma destekli):**

| Sayfa | Not |
|---|---|
| `/(auth)/smart-feed/` | Kişiselleştirilmiş öneri akışı |
| `/(auth)/taste-twin/` | Zevk eşleşmesi keşif |
| `/(auth)/price-alerts/` | Fiyat alarm yönetimi |

---

### Faz 5 — Flutter Web Silme ✅ TAMAMLANDI (2026-05-04)

1. ✅ Tüm P0 + P1 sayfalar Next.js'te çalışıyor (107 sayfa, typecheck + lint temiz).
2. ✅ Flutter panel URL'lerinden Next.js'e 301 redirectler eklendi (`next.config.mjs`): `/isletme-giris`, `/isletme-kayit`, `/owner/qr/design`, `/owner/menu/editor`, `/owner/menu/section-editor`.
3. ✅ `apps/panel_flutter_web/` dizini repo'dan silindi (443 dosya kaldırıldı).
4. ✅ `panel_quality.yml` CI pipeline arşivlendi (`if: false` ile deaktif edildi).
5. ⬜ `pubspec.yaml` kök bağımlılıkları temizleme — opsiyonel, `packages/shared_ui_components` mobil için korunuyor.

---

## 6. Teknik Kararlar

### 6.1 Component Library

**Karar: Headless Radix UI + Tailwind**

- `@radix-ui/react-*` primitive'leri (Dialog, Select, Dropdown, Tooltip, etc.)
- `clsx` + `tailwind-merge` utility
- shadcn/ui registry'den ihtiyaç duyulan bileşenler kopyalanır (dependency eklenmez)
- Mevcut `tokens.css` + design token sınıfları korunur
- Yeni bir component library (MUI, Chakra, Mantine) eklenmez

### 6.2 Tablo / Data Grid

**Karar: TanStack Table (headless)**

- `@tanstack/react-table` v8 — Flutter'ın `DataTable` widget'ı yerine
- Pagination, sorting, filtering client-side veya server-side
- `PanelDataTable` wrapper bileşen TanStack Table'ı sarmalar

### 6.3 Charts

**Karar: Recharts**

- Zaten web-friendly, React tabanlı
- Owner analytics, Admin growth sayfaları için

### 6.4 Form Yönetimi

**Karar: React Hook Form + Zod**

- Zod schema'lar hem client-side validation hem route handler server-side için paylaşılır
- `src/lib/schemas/` altında ortak Zod şemaları

### 6.5 Gerçek Zamanlı

- Supabase Realtime: `@supabase/supabase-js` client `.channel().on()`
- Admin queue, raporlar gibi sayfalar için React Query'nin `refetchInterval` yeterli olabilir
- Gerçek zamanlı kritik sayfalar (queue): Supabase Realtime subscription

### 6.6 i18n

- Mevcut `src/lib/i18n.ts` genişletilecek (owner + admin + consumer keys)
- `next-intl` kütüphanesi eklenmez — mevcut basit i18n sistemi korunur
- Owner/Admin sayfaları önce Türkçe yazılır, i18n sonra eklenir

### 6.7 Edge Runtime vs Node.js

- Public sayfalar: Edge Runtime (hızlı, CDN yakın)
- Owner/Admin sayfaları: Node.js runtime (daha az kısıtlama, Supabase server client)
- API route handlers: Node.js runtime

---

## 7. Silinecekler

Flutter Web kaldırıldığında şunlar da silinir:

```
apps/panel_flutter_web/          ← tamamen silinecek
packages/shared_ui_components/   ← Flutter mobile için korunur, Flutter web bağımlılıkları temizlenir
```

`packages/shared_ui_components` mobil uygulama için kullanılmaya devam eder. İçindeki sadece panel web'e özel bileşenler temizlenir.

---

## 8. Takip Edilmesi Gerekenler

Geçiş sırasında dikkat edilecek noktalar:

### Auth Tokeni
Flutter panel `auth/panel-handoff/route.ts` aracılığıyla Next.js'e zaten handoff yapıyor. Bu mekanizma, full geçiş sonrasında tamamen Supabase SSR cookie tabanlı auth'a geçecek.

### File Upload
`app/api/media/upload/route.ts` zaten var. Owner menü editöründe fotoğraf yükleme bu endpoint'i kullanacak.

### Custom Domain Verification
`owner_custom_domain_page.dart` → Next.js'te Supabase Edge Function çağrıları korunacak.

### Menu Editor Karmaşıklığı
`OwnerMenuEditorPage` + `OwnerSectionEditorPage` en karmaşık sayfalar. Push navigation + inline düzenleme + sıralama içeriyor. Next.js'te:
- `/(owner)/owner/menus/[menuId]/edit/page.tsx` — tek büyük interactive sayfa
- React Query mutations + optimistic updates
- Drag-and-drop: `@dnd-kit/core` veya `@hello-pangea/dnd`

### Embed Viewer
`/embed/:businessId` → `/(public)/embed/[businessId]/page.tsx` (public, no auth)

---

## 9. Başarı Kriterleri

- [x] Tüm P0 Owner sayfaları çalışıyor (32 sayfa, 2026-05-04)
- [x] Tüm P0 Admin sayfaları çalışıyor (33 sayfa, 2026-05-04)
- [x] Flutter panel URL'lerinden Next.js URL'lerine redirect yapılandırıldı (`next.config.mjs`)
- [x] `apps/panel_flutter_web/` silindi, `panel_quality.yml` arşivlendi
- [x] Keşif ve İşletme sayfaları mobil feature parity'ye ulaştı (BusinessTile, AppSectionHeader, yorum sort + verified badge)
- [x] Auth (owner + admin + consumer) middleware tam çalışıyor (`middleware.ts`)
- [x] `npm run typecheck` ve `npm run lint` temiz

---

## 10. Öneri: İlk Çalışma Sırası

Sıfırdan başlanacaksa şu sıra önerilir:

1. `middleware.ts` → `/owner` ve `/admin` koruma
2. `app/(owner)/layout.tsx` + sidebar bileşenleri (shell)
3. `/(owner)/owner/dashboard/page.tsx` (en basit, MetricCard + RPC)
4. `/(owner)/owner/businesses/page.tsx` (list + temel CRUD)
5. `/(owner)/owner/menus/page.tsx` (menü listesi)
6. `/(owner)/owner/menus/[menuId]/edit/` (menü editörü — en ağır iş)
7. Admin shell + `/(admin)/admin/queue/page.tsx`
8. Kalan P0/P1 sayfalar paralel ilerlenebilir

---

*Bu belge canlı tutulacak. Her faz tamamlandığında ilgili satırlar güncellenecek.*
