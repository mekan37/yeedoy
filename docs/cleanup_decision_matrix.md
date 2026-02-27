# Temizlik Karar Matrisi (Sil/Koru)

Bu matris kod baglantisina gore hazirlandi.

| Yol | Durum | Kod Baglantisi | Karar | Gerekce |
|---|---|---|---|---|
| `qr_menu_next/` | Sadece artifact (`.next`, `node_modules`) | Workspace referansi yok | Sil (tamamlandi) | Kaynak kod degil, depo gurultusu |
| `apps/panel_flutter_web/lib/web_order/` | Placeholder app | Aktif route/script baglantisi yoktu | Sil (tamamlandi) | Panel web kapsaminda olmayacak gecici app kodu |
| `packages/shared/` | Eski ortak klasor | `package.json` yok, dogrudan import izi yok | Sil (tamamlandi) | Aktif kod `apps/web_next/src/shared/*` altinda; cift kaynak maliyeti olusuyordu |

## Kanit

- `qr_menu_next/*`
- `apps/panel_flutter_web/lib/main_web_owner.dart`
- `apps/panel_flutter_web/lib/main_web_admin.dart`
- `apps/web_next/src/shared/schemas/*`
