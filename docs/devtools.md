# DevTools Yuzeyleri (Kod Tabanli)

## Mobile

- Route: `/dev-tools`
- Dosya: `apps/mobile_flutter/lib/features/devtools/ui/developer_tools_page.dart`
- Gate: debug veya `DEV_TOOLS_ENABLED`
- Surface: release checklist, golden path kontrolu, feature flag/dev override ayarlari, env check
- Offline queues: verify + submission queue ozetleri, retry/pending/bloklu sayilari, sonraki retry zamani, en sik hata nedenleri, conflict policy ozeti, dikkat isteyen queue item listesi, suggested action ipuclari ve manuel flush (verify/submission/all)

Kanit: `apps/mobile_flutter/lib/app/router.dart`

## Panel

- Route: `/admin/dev-tools`
- Dosya: `apps/panel_flutter_web/lib/features/admin/ui/admin_dev_tools_page.dart`
- Gate: debug veya `DEV_TOOLS_ENABLED`

Kanit: `apps/panel_flutter_web/lib/app/router.dart`

## Web Next

- Route: `/devtools`
- Dosya: `apps/web_next/app/devtools/page.tsx`
- Gate: `DEV_TOOLS_ENABLED=true` ve production disi

## Not

`core/monitoring` ve `core/perf` altyapisi mevcut olsa da ayrik, tam kapsamli monitoring/perf/prefs explorer ekranlari tum platformlarda tamamlanmis degil.

Kanit:
- `apps/mobile_flutter/lib/core/monitoring/request_trace.dart`
- `apps/mobile_flutter/lib/core/perf/firebase_perf_trace.dart`
- `apps/mobile_flutter/lib/core/storage/*_prefs.dart`
- `apps/mobile_flutter/lib/core/storage/offline_queue_diagnostics.dart`
