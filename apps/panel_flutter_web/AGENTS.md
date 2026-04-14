# Panel App Kurallari

Bu app owner ve admin operasyon panelidir. Public SEO menu render veya public QR landing buraya tasinmaz.

## Kanonik Yapi

- Entry: `lib/main_web_owner.dart`, `lib/main_web_admin.dart`
- Router: `lib/app/router.dart`
- State: Riverpod
- Tema: `lib/app/theme/*`
- L10n: `lib/l10n/*.arb`
- Shared shell: `lib/shared/ui/components/panel_*`

## Yazim Kurali

- Owner/admin ekranlari `PanelShell` cizgisine oturur.
- Yeni Supabase/RPC erisimi repository'de kalir.
- Owner business context bozulmaz; business-bagimli ekranlar secili business ile calisir.
- Yeni string ARB'ye gider; inline label/tooltip eklemek son tercih degil.

## Responsive

- Sidebar collapse/drawer deseni korunur.
- `LayoutBuilder`, `ConstrainedBox`, `Wrap` mevcut panel davranisinin parcasidir.
- 1520 max-width content surface cizgisi korunur.

## Validation

```bash
npm --prefix apps/panel_flutter_web run lint
npm --prefix apps/panel_flutter_web run test
```
