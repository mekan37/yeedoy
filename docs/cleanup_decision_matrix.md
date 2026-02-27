# Temizlik Karar Matrisi (Sil/Koru)

Bu matris kod baglantisina gore hazirlandi.

| Yol | Durum | Kod Baglantisi | Karar | Gerekce |
|---|---|---|---|---|
| `qr_menu_next/` | Sadece artifact (`.next`, `node_modules`) | Workspace referansi yok | Sil | Kaynak kod degil, depo gurultusu |
| `apps/panel_flutter_web/lib/web_order/` | Placeholder app | `main_web_order.dart` var ama root scriptte yok | Koru (gecici) | Urun karari netlesene kadar tutulabilir |
| `packages/shared/` | Eski ortak klasor | `package.json` yok, dogrudan import izi yok | Koru (inceleme) | Once konsolidasyon karari verilmeli |

## Kanit

- `qr_menu_next/*`
- `apps/panel_flutter_web/lib/main_web_order.dart`
- `apps/panel_flutter_web/lib/web_order/web_order_app.dart`
- `packages/shared/README.md`
- `packages/*`
