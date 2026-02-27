# Modül Görünürlük Matrisi (Kod Tabanlı)

## Mobile (`apps/mobile_flutter`)

| Modül | Route | Durum |
|---|---|---|
| Discovery | `/discover` | Görünür |
| Business | `/b/:id` | Görünür |
| Menu | `/b/:id/menu/:menuId` | Görünür |
| Reviews | `/b/:id/reviews`, `/b/:id/review` | Görünür |
| Favorites | `/favorites` | Görünür |
| Profile | `/profile` | Görünür |
| Inbox | `/inbox` | Görünür |
| Suggestions | `/suggest`, `/my-suggestions` | Görünür |
| Group Requests | `/group-requests` | Görünür (labs) |
| Taste Twin | `/taste-twin` | Görünür (labs) |
| Heroes | `/heroes` | Görünür (labs) |
| Compare / Chain | `/compare`, `/chain/:id` | Görünür (labs) |
| Top Businesses | `/top-businesses` | Görünür |
| Developer Tools | `/dev-tools` | Görünür (gate'li) |
| Panel erişimi | `/admin`, `/owner` | Mobilde web yönlendirme ekranına düşer |

Kaynak: `apps/mobile_flutter/lib/app/router.dart`

## Panel (`apps/panel_flutter_web`)

| Modül | Route | Durum |
|---|---|---|
| Owner Dashboard | `/owner` | Görünür |
| Owner Menu/Requests/Businesses | `/owner/...` | Görünür |
| Admin Dashboard | `/admin` | Görünür |
| Admin operasyon ekranları | `/admin/reports`, `/admin/claims`, `/admin/suggestions`, ... | Görünür |
| Admin DevTools | `/admin/dev-tools` | Görünür (gate'li) |
| Labs Translations | `/labs/translations` | Görünür (debug/labs şartlı) |
| Web Order alt uygulaması | `main_web_order.dart` | Mevcut ama placeholder |

Kaynak: `apps/panel_flutter_web/lib/app/router.dart`, `apps/panel_flutter_web/lib/web_order/web_order_app.dart`

## Web Next (`apps/web_next`)

| Modül | Route | Durum |
|---|---|---|
| Public Landing | `/` | Görünür |
| Public Menu | `/b/[slug]` | Görünür |
| QR Redirect | `/q/[code]` | Görünür |
| Login | `/login` | Görünür |
| Dashboard | `/dashboard/...` | Görünür |
| Menu Editor | `/dashboard/businesses/[id]/menu` | Görünür |
| QR Generator | `/dashboard/businesses/[id]/qr` | Görünür |
| Admin sayfası | `/admin` | Görünür ama içerik placeholder |
| Owner sayfası | `/owner` | Mevcut ama dashboard'a redirect |
| Menu Builder sayfası | `/menu-builder` | Mevcut ama dashboard'a redirect |
| Devtools | `/devtools` | Görünür (gate'li) |

Kaynak: `apps/web_next/app/**/*`

## Mevcut Ama Tam Bağlı Olmayan Unsurlar

- `qr_menu_next/` klasörü: kaynak uygulama değil, artifact içeriği.
- `packages/*` paketleri: repo içinde mevcut, uygulama importlarında doğrudan kullanım görünmüyor.

Kaynak: klasör envanteri ve import taraması.
