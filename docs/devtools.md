# DevTools Yüzeyleri (Gerçek Durum)

## Mobil

- Route: `/dev-tools`
- Dosya: `apps/mobile_flutter/lib/features/devtools/ui/developer_tools_page.dart`
- Gating: Debug veya `DEV_TOOLS_ENABLED` kontrolü (`router.dart` içinde)

## Panel

- Route: `/admin/dev-tools`
- Dosya: `apps/panel_flutter_web/lib/src/features/admin/ui/admin_dev_tools_page.dart`
- Gating: Debug veya `DEV_TOOLS_ENABLED` kontrolü (`app/router.dart` içinde)

## Web Next

- Route: `/devtools`
- Dosya: `apps/web_next/app/devtools/page.tsx`
- Gating: `DEV_TOOLS_ENABLED=true` ve production dışı

## Not

`core/monitoring` ve `core/perf` altında yardımcı altyapı dosyaları mevcut olsa da, tümü için ayrı tam teşhis ekranı bulunmuyor.

Örnek kanıtlar:

- `apps/mobile_flutter/lib/core/monitoring/request_trace.dart`
- `apps/mobile_flutter/lib/core/perf/firebase_perf_trace.dart`
- `apps/mobile_flutter/lib/core/storage/*_prefs.dart`
