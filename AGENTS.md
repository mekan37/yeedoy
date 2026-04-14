# Yeedoy AI Calisma Kurallari

Bu repo tek bir Node projesi degil. Aktif urun yuzeyi uc app'ten olusur:

- `apps/mobile_flutter`: son kullanici mobil uygulamasi
- `apps/panel_flutter_web`: owner + admin Flutter web paneli
- `apps/web_next`: public menu + QR + branding Next.js uygulamasi

## Aktif Kaynaklar

- Flutter ortak model kaynagi: `packages/shared_models`
- Flutter ortak UI primitive kaynagi: `packages/shared_ui_components`
- Flutter ortak l10n senkron kaynagi: `packages/l10n_assets/common_en.arb`, `packages/l10n_assets/common_tr.arb`
- Flutter tema source-of-truth: `apps/mobile_flutter/lib/app/theme/*`
- Web token aynasi: `apps/web_next/src/styles/tokens.css`, `apps/web_next/tailwind.config.js`

Not:
- `packages/ui_tokens` mevcut ama `apps/web_next` icin aktif source-of-truth degil.
- `packages/api_client`, `packages/shared_config`, `packages/shared_types` repo icinde neredeyse baglanmiyor; yeni is bunlara tasinmamalidir.

## Mimari Standart

### Flutter app'ler

Baskin yapi feature-first ve `data/domain/ui` ayrimidir.

- `data`: Supabase/RPC, cache, local storage, upload, IO
- `domain`: Riverpod provider/controller/state/model orkestrasyonu
- `ui`: `Page`, `Sheet`, `Card`, `Section`, `Widget`

Kurallar:
- Yeni Supabase erisimi once repository'ye eklenir.
- Yeni state orkestrasyonu `domain` altinda `Provider`, `Notifier`, `AsyncNotifier` ile kurulur.
- UI katmani yeni RPC yazmasi eklememelidir.
- Var olan UI-icinde-provider ornekleri teknik borctur; yeni kodda tekrar edilmez.

### Next app

`apps/web_next` ikiye ayrilir:

- `app/`: route, metadata, route handler
- `src/lib`: db, supabase, schema, analytics, route helpers
- `src/ui`: client component ve section'lar

Kurallar:
- Public veri okuma `src/lib/db/*` ve ilgili helper'larda kalir.
- Mutation route'lari `app/api/**/route.ts` altinda olur.
- Route handler icinde `zod.safeParse`, auth ve rate-limit desenleri korunur.
- Owner/admin CRUD ekranlari `web_next` icine tasinmaz.

## Uygulama Sinirlari

- `mobile_flutter` kesif, menu, review, favori, profil, katki ve offline/notification akislarina bakar.
- `panel_flutter_web` owner/admin operasyonu, moderation, menu CRUD, onboarding, analytics ve growth akislarina bakar.
- `web_next` public menu dagitimi, QR Studio, branding upload, panel handoff ve analytics toplar.

Ban:
- Mobil icine admin/owner operasyon paneli ekleme.
- Next icine panel CRUD ekleme.
- Panel icine public SEO menu render mantigi tasima.

## Tema ve UI

- Flutter'da yeni renk/spacing/radius dogrudan verilmez; `AppColors`, `AppTokens`, `buildAppTheme()` kullanilir.
- Web'de semantik Tailwind/token siniflari kullanilir: `bg-card`, `text-textStrong`, `border-border`, `shadow-yd*`.
- Min hit target 44 px alti yeni button/icon button eklenmez.
- Font ailesi `Sora` cizgisi korunur.
- Responsive davranis mevcut `LayoutBuilder`, `ConstrainedBox`, `MediaQuery`, `ScreenUtilInit` kaliplariyla kurulur.

## I18n

- Flutter app'lerde kullaniciya gorunen yeni metin `app_en.arb` + `app_tr.arb` icine eklenir.
- Iki Flutter app'te ayni anahtar kullaniliyorsa `packages/l10n_assets/common_*.arb` kaynagini guncelle, sonra `node packages/l10n_assets/scripts/sync-l10n.mjs` calistir.
- Web public UI copy'si `apps/web_next/src/lib/i18n.ts` ve benzeri merkezi dosyalarda tutulur; component icine yeni sabit string gomulmez.

## Adlandirma

- Dart dosyalari: `snake_case.dart`
- TS/TSX dosyalari: `kebab-case.ts`, `kebab-case.tsx`
- Dart siniflari/widget'lari: `PascalCase`
- Riverpod provider'lari: `*Provider`
- Controller/Notifier siniflari: `*Controller`
- Repository siniflari: `*Repository`
- Page widget/component'leri: `*Page`
- Supabase RPC wrapper/adlari mevcut kontratla uyumlu kalir (`*_v1`, `*_v2`)

## Dogrulama

Repo kokunde gecerli komutlar:

```bash
npm run l10n:audit
npm run verify:matrix
```

App bazli:

```bash
npm --prefix apps/mobile_flutter run lint
npm --prefix apps/panel_flutter_web run lint
npm --prefix apps/panel_flutter_web run test
npm --prefix apps/web_next run typecheck
npm --prefix apps/web_next run lint
npm --prefix apps/web_next run test
```

Not:
- Kokte `npm test` script'i yok. Talimatlarda kullanma.
- Kod degisikliklerinden sonra tum repo yerine once dokunulan yuzeyin dogrulamasini calistir.

## Degisiklik Politikasi

- Mevcut dominant deseni koru, yeni mimari uydurma.
- Halihazirda ortaklasmis primitive varsa ucuncu kopya yazma.
- Review edilebilir, kucuk diff'ler tercih et.
- Hardcoded secret, path, public URL, user-facing string ve raw theme degeri ekleme.
- Eski/stub paketleri yeni source-of-truth gibi kullanma.
