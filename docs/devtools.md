# DevTools

## Genel Kural
- `DEV_TOOLS_ENABLED=true` ise geliştirme araçları açılır.
- Production’da devtools kapalı kalmalıdır.

## Mobil (`apps/mobile_flutter`)
- Route: `/dev-tools`
- İçerik:
  - Release checklist (`ReleaseGate`)
  - Golden path kontrolleri (`GoldenPaths`)
  - Feature flag yönetimi
  - Dev override görünümü
  - Env doğrulama özeti

## Panel (`apps/panel_flutter_web`)
- Route: `/admin/dev-tools`
- Admin operasyon ve teşhis ekranı
- Debug/flag ile erişim

## Web (`apps/web_next`)
- Route: `/devtools`
- İçerik:
  - Env doğrulama
  - SEO/test bağlantıları
  - API/download smoke bağlantıları
