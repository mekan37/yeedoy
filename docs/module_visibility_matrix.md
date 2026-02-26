# Modül Görünürlük Matrisi

## Mobile (`apps/mobile_flutter`)

| Modül | Route / Giriş | UI Giriş Noktası | Durum |
|---|---|---|---|
| Discovery | `/discover` | Alt menü + drawer | Görünür |
| Smart Feed | `/feed` | Drawer (labs) | Görünür |
| Business | `/b/:id` | Discovery kartları | Görünür |
| Menus | `/b/:id/menu/:menuId` | Business sayfası | Görünür |
| Menu Item | `/b/:id/menu-item/:itemId` | Menü listesi | Görünür |
| Reviews | `/b/:id/reviews`, `/b/:id/review` | Business sayfası | Görünür |
| Favorites | `/favorites` | Alt menü + drawer | Görünür |
| Profile | `/profile` | Alt menü + drawer | Görünür |
| Inbox | `/inbox` | Drawer + bildirim | Görünür |
| Suggestions | `/suggest`, `/my-suggestions` | Drawer + profil | Görünür |
| Group Requests | `/group-requests` | Drawer (labs) | Görünür |
| Taste Twin | `/taste-twin` | Drawer (labs) | Görünür |
| Heroes | `/heroes` | Drawer (labs) | Görünür |
| Compare | `/compare` | Drawer (labs) | Görünür |
| Chains | `/chain/:id` | Discovery/business linkleri | Görünür |
| Suspended Meals | `/my-suspended` | Drawer | Görünür |
| Top Businesses | `/top-businesses` | Drawer | Görünür |
| Legal | `/legal` | Drawer | Görünür |
| Developer Tools | `/dev-tools` | Drawer + Profil Ayarları | Görünür (dev gate) |

## Web Next (`apps/web_next`)

| Modül | Route / Giriş | Durum |
|---|---|---|
| Public Landing | `/` | Görünür |
| Public Menu | `/b/[slug]` | Görünür |
| QR Redirect | `/q/[code]` | Görünür |
| Dashboard | `/dashboard` | Görünür |
| Menu Builder | `/dashboard/businesses/[id]/menu` | Görünür |
| QR Generator | `/dashboard/businesses/[id]/qr` | Görünür |
| DevTools | `/devtools` | Görünür (dev gate) |

## Panel (`apps/panel_flutter_web`)

| Modül | Route / Giriş | Durum |
|---|---|---|
| Admin Dashboard | `/admin` | Görünür |
| Admin DevTools | `/admin/dev-tools` | Görünür (dev gate) |
| Owner Dashboard | `/owner` | Görünür |

## Bekleyen Entegrasyonlar
- `core/monitoring/request_trace.dart`: detay paneli henüz yok
- `core/perf/firebase_perf_trace.dart`: trace bazlı izleme UI henüz yok
- `core/storage/*_prefs.dart`: tam prefs tarayıcı ekranı henüz yok
