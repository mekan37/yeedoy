# Modul Gorunurluk Matrisi (Kod Tabanli)

## Mobile (`apps/mobile_flutter`)

| Modul | Route | Durum |
|---|---|---|
| Discovery | `/discover` | Gorunur |
| Business | `/b/:id` | Gorunur |
| Menu | `/b/:id/menu/:menuId` | Gorunur |
| Menu Item | `/b/:id/menu/:menuId/item/:itemId` | Gorunur |
| Reviews | `/b/:id/reviews`, `/b/:id/review` | Gorunur |
| Favorites | `/favorites`, `/c/:slug` | Gorunur |
| Profile | `/profile` | Gorunur |
| Inbox | `/inbox` | Gorunur |
| Suggestion/Contribute | `/suggest`, `/my-suggestions` | Gorunur |
| Group Requests | `/group-requests*` | Gorunur |
| Labs | `/taste-twin`, `/heroes`, `/compare`, `/chain/:id` | Gorunur (feature flag bagli) |
| DevTools | `/dev-tools` | Gorunur (debug/env gate) |
| Panel erisimi | `/admin`, `/owner` | Mobilde `/panel-web` yonlendirmesine dusurulur |

Kanit: `apps/mobile_flutter/lib/app/router.dart`

## Panel (`apps/panel_flutter_web`)

| Modul | Route | Durum |
|---|---|---|
| Admin dashboard | `/admin` | Gorunur |
| Admin operasyon | `/admin/reports`, `/admin/claims`, `/admin/suggestions`, `/admin/verified`, ... | Gorunur |
| Owner dashboard | `/owner` ve altlari | Gorunur |
| Admin devtools | `/admin/dev-tools` | Gorunur (debug/env gate) |
| Public web giris | `/`, `/isletme-giris`, `/isletme-kayit` | Gorunur |

Kanit:
- `apps/panel_flutter_web/lib/app/router.dart`
- `apps/panel_flutter_web/lib/app_admin.dart`

## Web Next (`apps/web_next`)

| Modul | Route | Durum |
|---|---|---|
| Landing | `/` | Gorunur |
| Login | `/login` | Gorunur |
| Public menu | `/m/[businessId]` | Gorunur |
| Category menu | `/m/[businessId]/c/[categoryId]` | Gorunur |
| Item detail menu | `/m/[businessId]/i/[itemId]` | Gorunur |
| QR generator | `/qr/[businessId]` | Sadece authenticated owner/admin + yetkili business |
| QR redirect | `/q/[code]` | Gorunur |
| Panel handoff | `/auth/panel-handoff` | Route handler, panel session bridge |
| Legacy menu redirect | `/b/[slug]` | Yalnizca UUID -> `/m/[businessId]` yonlendirme |
| Tracking API | `/api/track` | Gorunur |
| OG image API | `/api/og` | Gorunur |

Kanit:
- `apps/web_next/app/page.tsx`
- `apps/web_next/app/login/page.tsx`
- `apps/web_next/app/(public)/m/[slug]/page.tsx`
- `apps/web_next/app/(public)/m/[slug]/c/[categoryId]/page.tsx`
- `apps/web_next/app/(public)/m/[slug]/i/[itemId]/page.tsx`
- `apps/web_next/app/qr/[businessId]/page.tsx`
- `apps/web_next/app/auth/panel-handoff/route.ts`
- `apps/web_next/app/q/[code]/route.ts`
- `apps/web_next/app/(public)/b/[slug]/page.tsx`
- `apps/web_next/app/api/track/route.ts`
- `apps/web_next/app/api/og/route.tsx`

Not:
- Admin/owner/menu-builder CRUD akislarinin sahibi `apps/web_next` degildir.
- QR erisimi panel session handoff veya Next login ile acilir.
- Bu akislar `apps/panel_flutter_web` uygulamasinda yer alir.
- Semantik public route `/m/[businessId]` olsa da mevcut App Router klasor yolu `apps/web_next/app/(public)/m/[slug]/...` seklindedir.

## Mevcut Ama Bagli Olmayan/Kismi Unsurlar

- `packages/shared` kaldirildi.
- `apps/web_next` tarafinda route param klasor adi `[slug]` olsa da semantik olarak `businessId` kullanilir.

Kanit:
- `apps/web_next/app/(public)/m/[slug]/page.tsx`
- `apps/web_next/src/lib/public-menu-page.ts`
