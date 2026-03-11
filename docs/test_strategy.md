# Panel Test Stratejisi

Bu dokuman `apps/panel_flutter_web` test yuzeyini, nasil kosuldugunu ve hangi testlerin aktif oldugunu listeler.

## Durum Ozeti

- `test/`: Aktif. Korunmali.
- `e2e/`: Aktif. Panel browser smoke artik Playwright ile kosuyor.
- Golden test: Aktif kullanimda degil. Asset'i olmayan placeholder golden kaldirildi.
- Repo kokunde panel icin `.github/workflows/panel_quality.yml` workflow'u mevcut.
- Panel test hatti artik lokal komutlara ek olarak merkezi CI seviyesinde analyze/test/build kapisina baglidir.
- Playwright smoke halen opsiyonel `workflow_dispatch` girisi ile ayrik tutulur.

## Calistirma Komutlari

### Tum testler

```powershell
cd apps/panel_flutter_web
flutter test
```

veya

```powershell
npm --prefix apps/panel_flutter_web run test
```

### Browser smoke

```powershell
cd apps/panel_flutter_web
npm run test:smoke
```

veya

```powershell
npm --prefix apps/panel_flutter_web run test:integration
```

Gereksinim:

- Chromium browser
- `apps/web_next/node_modules` altindaki Playwright toolchain

## Aktif Test Dosyalari

### Unit / Contract benzeri saf mantik testleri

#### `test/core/cache/ttl_memory_cache_test.dart`

- Neden var: TTL cache davranisini dogrular.
- Tetikleme:
  - `flutter test`
  - `npm --prefix apps/panel_flutter_web run test`
- Kod tarafindan import/trigger: Test runner disinda yok.
- Uretim sureci: Perf ve cache regressions icin degerli. Koru.

#### `test/core/content/microcopy_style_guide_test.dart`

- Neden var: Kritik mikro kopya dil kurallarini sabitler.
- Tetikleme:
  - `flutter test`
- Kod tarafindan import/trigger: Test runner disinda yok.
- Uretim sureci: UX tutarliligi icin degerli. Koru.

#### `test/web/auth/business_auth_redirect_test.dart`

- Neden var: Login sonrasi role gore yonlendirme kontratini dogrular.
- Tetikleme:
  - `flutter test`
- Uretim sureci: Auth redirect regressions icin kritik. Koru.

#### `test/web/security/admin_permissions_test.dart`

- Neden var: Admin rota erisim matrisi ve queue write iznini dogrular.
- Tetikleme:
  - `flutter test`
- Uretim sureci: Yetki/regression kontrolu icin kritik. Koru.

#### `test/web/security/route_sanitizer_test.dart`

- Neden var: Internal redirect ve UUID sanitization kurallarini dogrular.
- Tetikleme:
  - `flutter test`
- Uretim sureci: Open redirect ve guvenlik regressions icin kritik. Koru.

### Widget testleri

#### `test/ui/design_system_quality_gates_test.dart`

- Neden var: Temel UI bilesenlerinin font scaling ve minimum hit target davranisini kontrol eder.
- Tetikleme:
  - `flutter test`
- Uretim sureci: UI kalite kapisi. Koru.

### Browser smoke

#### `e2e/panel-smoke.spec.cjs`

- Neden var: Derlenmis Flutter web artifact'i uzerinde gercek router ve shell davranisini browser seviyesinde smoke eder.
- Tetikleme:
  - `npm --prefix apps/panel_flutter_web run test:smoke`
  - `npm --prefix apps/panel_flutter_web run test:integration`
- Uretim sureci: Release dogrulamasi icin aktif cekirdek panel kapisidir; owner shell, owner businesses, owner business submissions, owner new business submit, owner menus, owner menu editor, owner trash, owner trash restore, owner onboarding, owner requests, owner suspended, owner activity, owner analytics, owner audit alias, owner growth, owner growth lead submit, owner team, owner price suggestions, admin dashboard, admin login redirect, admin search, admin queue, admin reports, admin businesses, admin receipt submissions ve admin observability route smoke kapsami vardir. Ayrica secili write/modal aksiyonlari browser seviyesinde dogrulanir: owner commerce links save, owner menus create, owner requests offer sheet, owner team invite, owner price suggestion approve, admin queue assign, admin reports assign ve admin observability calibration save.
- Destek dosyalari:
  - `playwright.config.cjs`
  - `lib/main_web_smoke.dart`
  - `lib/smoke/panel_smoke_harness.dart`
  - `scripts/serve-smoke.cjs`
- Not: Smoke app, owner/admin provider'larini fake verilerle override eder; boylece browser smoke CI'da Supabase verisine baglanmadan kosabilir.

## Kaldirilan Test Kalintilari

- `test/ui/golden/basic_surfaces_golden_test.dart`
  - Varsayilan olarak skip idi.
  - Repo icinde golden asset dosyalari yoktu.
  - `package.json` veya CI tarafinda tetikleyen script yoktu.

- `test/core/contracts/README.md`
  - Sadece placeholder aciklama idi.
  - Gercek contract test dosyasi icermiyordu.

## Sonraki Oneri

1. Panelde yeni owner/admin route veya kritik write akisleri eklendiginde ayni sprint icinde `panel-smoke.spec.cjs` kapsamina alinmalidir.
2. Golden test geri gelecekse once referans png seti ve guncelleme akisi eklenmeli.
3. Browser smoke derinligi bugun cekirdek release kapisi icin yeterlidir; bundan sonraki artirimlar yeni urun akislarina gore secici yapilmalidir.

## Son Dogrulama

- Tarih: `2026-03-10`
- `flutter test` basariyla gecti
- `npm --prefix apps/panel_flutter_web run test:smoke` basariyla gecti (`30 passed`)
- Repo-root workflow durumu yeniden tarandi; panel icin `panel_quality` workflow'u mevcut ve quality gate scriptleriyle bagli
