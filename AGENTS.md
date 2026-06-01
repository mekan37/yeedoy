# Yeedoy AI Calisma Kurallari

Bu repo tek bir Node projesi degil. Aktif urun yuzeyi iki app'ten olusur:

- `uygulamalar/mobil`: son kullanici mobil uygulamasi
- `uygulamalar/web`: public menu, QR, branding, owner ve admin Next.js uygulamasi

## Aktif Kaynaklar

- Flutter ortak model kaynagi: `packages/shared_models`
- Flutter ortak UI primitive kaynagi: `packages/shared_ui_components`
- Flutter ortak l10n senkron kaynagi: `packages/l10n_assets/common_en.arb`, `packages/l10n_assets/common_tr.arb`
- Flutter tema source-of-truth: `uygulamalar/mobil/lib/uygulama/theme/*`
- Web token aynasi: `uygulamalar/web/src/styles/tokens.css`, `uygulamalar/web/tailwind.config.js`

Not:
- `packages/ui_tokens` mevcut ama `uygulamalar/web` icin aktif source-of-truth degil.
- `packages/api_client`, `packages/shared_config`, `packages/shared_types` repo icinde neredeyse baglanmiyor; yeni is bunlara tasinmamalidir.

## Mimari Standart

### Flutter app'ler

Baskin yapi feature-first ve `data/domain/ui` ayrimidir.

- `data`: Supabase/RPC, cache, local storage, upload, IO
- `domain`: Riverpod provider/controller/state/model orkestrasyonu
- `ui`: `Page`, `Sheet`, `Card`, `Section`, `Widget`

Kurallar:
- Yeni Supabase erisimi once deposu'ye eklenir.
- Yeni state orkestrasyonu `domain` altinda `Provider`, `Notifier`, `AsyncNotifier` ile kurulur.
- UI katmani yeni RPC yazmasi eklememelidir.
- Var olan UI-icinde-provider ornekleri teknik borctur; yeni kodda tekrar edilmez.

### Next app

`uygulamalar/web` ikiye ayrilir:

- `uygulama/`: route, metadata, route handler
- `src/lib`: db, supabase, schema, analytics, route helpers
- `src/ui`: client component ve section'lar

Kurallar:
- Public veri okuma `src/lib/veri/*` ve ilgili helper'larda kalir.
- Mutation route'lari `uygulama/api/**/route.ts` altinda olur.
- Route handler icinde `zod.safeParse`, auth ve rate-limit desenleri korunur.
- Owner/admin CRUD ekranlari `uygulamalar/web/uygulama/owner/**` ve `uygulamalar/web/uygulama/admin/**` altinda kalir.

## Uygulama Sinirlari

- `mobile_flutter` kesif, menu, review, favori, profil, katki ve offline/notification akislarina bakar.
- `web_next` public menu dagitimi, QR Studio, branding upload, owner/admin operasyonu, moderation, menu CRUD, onboarding, analytics ve growth akislarini tasir.

Ban:
- Mobil icine admin/owner operasyon paneli ekleme.
- Owner/admin CRUD icin yeni Flutter web panel yuzeyi ekleme.
- Public SEO menu render mantigini Next disina tasima.

## Tema ve UI

- Flutter'da yeni renk/spacing/radius dogrudan verilmez; `AppColors`, `AppTokens`, `buildAppTheme()` kullanilir.
- Web'de semantik Tailwind/token siniflari kullanilir: `bg-card`, `text-textStrong`, `border-border`, `shadow-yd*`.
- Min hit target 44 px alti yeni button/icon button eklenmez.
- Font ailesi `Sora` cizgisi korunur.
- Responsive davranis mevcut `LayoutBuilder`, `ConstrainedBox`, `MediaQuery`, `ScreenUtilInit` kaliplariyla kurulur.

## I18n

- Flutter app'lerde kullaniciya gorunen yeni metin `app_en.arb` + `app_tr.arb` icine eklenir.
- Mobil Flutter'da kullaniciya gorunen ortak anahtar gerekiyorsa `packages/l10n_assets/common_*.arb` kaynagini guncelle, sonra `node packages/l10n_assets/scripts/sync-l10n.mjs` calistir.
- Web public UI copy'si `uygulamalar/web/src/lib/i18n.ts` ve benzeri merkezi dosyalarda tutulur; component icine yeni sabit string gomulmez.

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
npm --prefix uygulamalar/mobil run lint
npm --prefix uygulamalar/web run typecheck
npm --prefix uygulamalar/web run lint
npm --prefix uygulamalar/web run test
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
