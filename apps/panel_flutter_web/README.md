# panel_flutter_web

Flutter Web tabanli owner ve admin operasyon paneli.

Bu app'in kapsami bilerek nettir:
- Owner operasyon merkezi (`/owner`)
- Owner growth, sponsorship katalogu ve lead akisi (`/owner/growth`)
- Owner business/menu yonetimi
- Admin governance, moderation, observability ve receipt workbench ekranlari
- Public menu ve QR acilisina panelden handoff

Kapsam disi:
- Public menu render, SEO ve QR landing
- Son kullanici discovery, review ve mobile akislari

Bu alanlar sirasiyla `apps/web_next` ve `apps/mobile_flutter` icinde kalir.

## Tek Kaynak Belgeler

- `docs/system_full_documentation.md`
- `docs/apps.md`
- `docs/test_strategy.md`
- `docs/analytics_owner.md`
- `docs/runbook.md`

## Rol Ayrimi

Owner:
- business secimi ve onboarding
- menu/price/trash/requests/team/activity yuzeyleri
- operasyon ozeti ve growth hub

Admin:
- queue, reports, businesses, receipt submissions, observability
- moderation, claims, suggestions, sponsorship, B2B export
- audit, incident, user access ve governance yuzeyleri

## Route Omurgasi

Public/auth giris:
- `/`
- `/login`
- `/isletme-giris`
- `/isletme-kayit`
- `/legal`

Owner ana alanlari:
- `/owner`
- `/owner/growth`
- `/owner/analytics`
- `/owner/businesses`
- `/owner/businesses/new`
- `/owner/businesses/submissions`
- `/owner/menus`
- `/owner/trash`
- `/owner/price-suggestions`
- `/owner/requests`
- `/owner/suspended`
- `/owner/team`
- `/owner/activity`
- `/owner/onboarding`

Admin ana alanlari:
- `/admin`
- `/admin/search`
- `/admin/queue`
- `/admin/reports`
- `/admin/businesses`
- `/admin/receipt-submissions`
- `/admin/observability`

Not:
- Admin ve owner route'lari auth + role gate arkasindadir.
- Owner shell secili business baglamini ortak kullanir.
- Admin shell governance ve operator ekranlarini tek navigasyonda toplar.

## Public Link ve QR Kontrati

- Panel public menu linkini `public_slug -> slug -> businessId` fallback zinciriyle uretir.
- Panel QR akisini `apps/web_next` icindeki `/qr/:businessId` yuzeyine handoff eder.
- Owner/admin session varsa `POST /auth/panel-handoff` ile Next tarafina cookie session aktarilir.
- Varsayilan panel cikisi:
  - `/qr/:businessId?lang=tr&theme=bold`
  - canonical public link icin `/m/:publicSlugOrId?lang=tr&theme=bold`

## Calistirma

```bash
npm --prefix apps/panel_flutter_web run dev:owner
npm --prefix apps/panel_flutter_web run dev:admin
```

Release build:

```bash
npm --prefix apps/panel_flutter_web run build
npm --prefix apps/panel_flutter_web run build:admin
```

## Dogrulama

```bash
flutter analyze
flutter test
npm --prefix apps/panel_flutter_web run test:smoke
```

Browser smoke notlari:
- Smoke `integration_test` degil, Playwright browser suite olarak kosar.
- Derlenmis hedef `lib/main_web_smoke.dart` uzerinden static server ile acilir.
- Fake owner/admin provider override'lari `lib/smoke/panel_smoke_harness.dart` icindedir.
- Mevcut smoke kapsami `30 passed` cekirdek browser suite olarak su owner/admin yuzeylerini kapsar:
  - owner shell, businesses, business submissions, new business submit
  - owner menus, menu editor, trash, trash restore
  - owner onboarding, requests, suspended, activity, analytics, audit alias
  - owner growth, growth lead submit, team, price suggestions
  - admin dashboard, login redirect, search, queue, reports, businesses, receipt submissions, observability
- Secili write/modal aksiyonlari da browser seviyesinde dogrulanir:
  - owner commerce links save
  - owner menus create
  - owner requests offer sheet
  - owner team invite
  - owner price suggestion approve
  - admin queue assign
  - admin reports assign
  - admin observability calibration save

## CI

Repo-root workflow:
- `.github/workflows/panel_quality.yml`

Bu workflow su kapilari calistirir:
- `flutter analyze`
- `flutter test`
- `api_version_gate_check`
- `security_review_check --strict`
- owner/admin web build
- opsiyonel Playwright smoke

## Sinir Cizgisi

- Panel QR gorseli render etmez; bu is `apps/web_next` icindeki QR Studio'dadir.
- Panel public menuyu son kullaniciya render etmez; yalnizca link/handoff ve operasyon akislarini yonetir.
- Son kullanici discovery, social ve katki akislarini burada aramayin; bunlar mobil uygulamadadir.
