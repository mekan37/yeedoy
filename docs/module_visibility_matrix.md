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
| Hub root | `/` | Mevcut, login olmayani `/login`e yonlendiriyor |
| Login | `/login` | Gorunur |
| Dashboard | `/dashboard/*` | Gorunur |
| Menu editor | `/dashboard/businesses/[id]/menu` | Gorunur |
| QR generator | `/dashboard/businesses/[id]/qr` | Gorunur |
| Public menu | `/b/[slug]` | Gorunur |
| QR redirect | `/q/[code]` | Gorunur |
| Admin | `/admin` | Panel web'e yonlendirme (`BASE_URL_PANEL/admin`) |
| Owner | `/owner` | Panel web'e yonlendirme (`BASE_URL_PANEL/owner`) |
| Menu builder | `/menu-builder` | Panel web'e yonlendirme (`BASE_URL_PANEL/owner/menus`) |
| Devtools | `/devtools` | Gorunur (env + non-prod gate) |

Kanit:
- `apps/web_next/app/page.tsx`
- `apps/web_next/src/ui/sections/HomeHub.tsx`
- `apps/web_next/app/admin/page.tsx`
- `apps/web_next/app/owner/page.tsx`
- `apps/web_next/app/menu-builder/page.tsx`
- `apps/web_next/app/(public)/b/[slug]/page.tsx`
- `apps/web_next/app/q/[code]/page.tsx`

## Mevcut Ama Bagli Olmayan/Kismi Unsurlar

- `qr_menu_next/` kaldirildi (artifact temizlik tamamlandi).
- `packages/shared` kaldirildi; aktif schema kaynaklari `apps/web_next/src/shared/schemas/*`.

Kanit:
- `apps/web_next/app/admin/page.tsx`
- `apps/web_next/app/owner/page.tsx`
- `apps/web_next/app/menu-builder/page.tsx`
- `apps/web_next/src/lib/panelUrl.ts`
- `apps/web_next/src/shared/schemas/*`
