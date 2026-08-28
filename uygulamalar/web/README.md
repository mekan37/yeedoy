# web_next

Next.js App Router tabanli public restoran QR menu uygulamasi.

Bu app'in kapsami bilerek dardir:
- Public menu goruntuleme
- Authenticated QR olusturma, link kopyalama, PNG/SVG indirme
- Business bazli template / branding ayari kaydetme
- Preview link ve kaydetmeden once canli onizleme
- SEO, tema dili, analytics toplama
- URL tabanli template override (`?theme=minimal|bold|elegant|photo-heavy|dark-modern`)

Kapsam disi:
- Owner/admin CRUD ekranlari
- Menu yazma/guncelleme
- Isletme yonetimi

Bu write akislari ayri panel uygulamasinda kalir.

## Tek Kaynak Belgeler

- `docs/system_full_documentation.md`
- `docs/apps.md`
- `docs/ui-style.md`
- `docs/runbook.md`
- `docs/web_next_perf.md`

## Tema Kaynagi

Web tasarim dili `apps/mobile_flutter/lib/app/theme` altindaki mobile tokenlara gore eslenmistir.

Aktif web token dosyalari:
- `apps/web_next/src/styles/tokens.css`
- `apps/web_next/tailwind.config.js`
- `apps/web_next/src/styles/globals.css`

Daha detayli harita:
- `docs/ui-style.md`

## Canli Schema Notu

Bu implementasyon canli Supabase schema'ya gore canonical `public_slug` merkezli route modeli kullanir.

Kullanilan temel tablolar:
- `businesses`
- `business_hours`
- `business_media`
- `business_menu_presentation_settings`
- `menus`
- `menu_sections`
- `menu_categories`
- `menu_items`
- `menu_item_variants`
- `menu_item_photos`
- `menu_translations`

Kullanilan temel RPC'ler:
- `get_menu_items_v1`
- `get_menu_item_variants_v1`
- `get_menu_item_photos_v1`
- `log_event_v1`

Not:
- `supabase/migrations/20260325000001_business_public_slug.sql` slug modelini tanimlar; `20260325000016_business_slug_schema_v1.sql` ve `20260325000017_business_slug_backfill_trigger_v1.sql` mevcut projeyi aktif schema ile hizalar.
- Canonical public route `public_slug` tercih eder; `public_slug` yoksa `slug`, o da yoksa `businessId` fallback olarak kullanilir.
- Eski `/m/{businessId}` ve legacy `/b/[slug]` istekleri backward-compatible kalir; public slug varsa canonical `/m/{publicSlug}` rotasina yonlenir.

## Route Yapisi

- `/login`
- `/m/:publicSlugOrId`
- `/m/:publicSlugOrId/c/:categoryId`
- `/m/:publicSlugOrId/i/:itemId`
- `/qr/:businessId`
- `/q/:shortCode`
- `/auth/panel-handoff`
- `/api/presentation-settings`
- `/sunucu/medya/yukleme`

`/q/:shortCode` deterministic UUID kisaltmasi kullanir; yeni tablo yazimi yapmaz. Redirect zinciri public slug varsa canonical `/m/{publicSlug}` ile sonlanir.
`/qr/:businessId` owner/admin session ve business yetkisi gerektirir.
Public menu route'lari `?theme=minimal|bold|elegant|photo-heavy|dark-modern` query'sini destekler.
Preview mode: `/m/:publicSlugOrId?theme=...&preview=1`
Panelden gelen varsayilan owner akisi `/qr/:businessId?lang=tr&theme=bold` ve canonical public link icin `/m/:publicSlugOrId?lang=tr&theme=bold` kontratini kullanir.
Query paramlari DB'deki varsayilan `template_key` ve `default_lang` degerlerini sadece override eder.

## Ortam Degiskenleri

`.env.local`:

```bash
NEXT_PUBLIC_SUPABASE_URL=https://your-project.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=your_anon_key
SUPABASE_SERVICE_ROLE_KEY=your_service_role_key_optional
NEXT_PUBLIC_SITE_URL=http://localhost:3000
PLAYWRIGHT_SMOKE_BUSINESS_ID=your_live_business_uuid
PLAYWRIGHT_SMOKE_BUSINESS_PATH=your_live_public_slug_or_uuid_optional
PLAYWRIGHT_SMOKE_CATEGORY_ID=your_live_category_uuid_optional
PLAYWRIGHT_SMOKE_ITEM_ID=your_live_item_uuid_optional
PLAYWRIGHT_SMOKE_LANG=tr
```

Kurallar:
- Public read icin yalnizca anon key yeterlidir.
- `SUPABASE_SERVICE_ROLE_KEY` upload route'u icin gereklidir.
- Analytics route service role varsa onu kullanir, yoksa server-side anon RPC fallback yapar.
- `PLAYWRIGHT_SMOKE_BUSINESS_ID`, `test:e2e:live` ve `lighthouse:mobile` icin zorunludur.
- `PLAYWRIGHT_SMOKE_BUSINESS_PATH` verilirse live smoke canonical slug route'unu ve `/m/:businessId -> /m/:publicSlugOrId` redirect zincirini de dogrular.

## QR Auth

`/qr/:businessId` akisinda:
- Session yoksa `/login?redirect=/qr/:businessId?...` yonlendirmesi yapilir.
- Next tarafi aktif Supabase session ister.
- Ek olarak `can_manage_business_v1` ile business yetkisi kontrol edilir.
- Panelde oturum acik kullanici `Dijital Menu & QR` butonuna bastiginda session tokenlari `POST /auth/panel-handoff` ile cookie'ye donusturulur.
- Standalone giriste kullanici `/login` uzerinden email/password ile oturum acar.
- `QR Studio` icindeki kaydet akisi sadece `business_menu_presentation_settings` tablosuna yazar; menu CRUD yapmaz.
- QR Studio kayitli DB ayarini baz alir; `Reset to Default` ile ayni kayitli duruma geri donebilir.
- `preview=1` query'si kayitsiz canli onizleme icindir; DB'ye yazmaz.
- Branding upload route'u `can_manage_business_v1` + mime/size/path validasyonu ile calisir.
- Presentation settings save sonrasi canonical public menu yolu (`/m/:publicSlugOrId`) ve `/qr/:businessId` route'u revalidate edilir; default theme/lang degisikligi public sayfaya hemen yansir.

## Kurulum

```bash
npm install
npm --prefix apps/web_next run dev
```

Release-candidate build:

```bash
npm --prefix apps/web_next run build
```

Not:
- `build` script'i `.next` klasorunu otomatik temizler.
- Stale artifact kaynakli `/_document` veya `PageNotFoundError` gorulurse wrapper bir kez daha temiz build dener.
- Son build log'u `apps/web_next/reports/build/build-latest.log` altina yazilir.

## Dogrulama

```bash
npm --prefix apps/web_next run typecheck
npm --prefix apps/web_next run lint
npm --prefix apps/web_next run test:e2e
```

Opsiyonel canli smoke:

```bash
npm --prefix apps/web_next run test:e2e:live
```

Bu test `.env.local` veya `.env.playwright.local` icinden su degiskenleri okur:
- `PLAYWRIGHT_SMOKE_BUSINESS_ID`
- `PLAYWRIGHT_SMOKE_BUSINESS_PATH`
- `PLAYWRIGHT_SMOKE_CATEGORY_ID`
- `PLAYWRIGHT_SMOKE_ITEM_ID`
- `PLAYWRIGHT_SMOKE_LANG`

`PLAYWRIGHT_SMOKE_BUSINESS_ID` eksikse test artik `skip` olmaz; anlamli hata ile fail eder.

Gercek mobil Lighthouse olcumu:

```bash
npm --prefix apps/web_next run lighthouse:mobile
```

Bu script:
- production build + bundle analyzer calistirir
- local `next start` uzerinde mobil emulation + throttling ile olcum alir
- raporlari `apps/web_next/reports/lighthouse/latest` altina yazar
- bundle analyzer ciktilarini `apps/web_next/reports/bundle/latest` altina kopyalar
- ozeti `docs/web_next_perf.md` icine yazar

## Supabase Type Generation

Repo icindeki `src/lib/supabase/database.types.ts` kullanilan public menu yuzeyi icin elle daraltilmis tip dosyasidir.

Canli projeden yeniden uretmek icin:

```bash
supabase gen types typescript --linked --schema public > apps/web_next/src/lib/supabase/database.types.generated.ts
```

Ardindan ihtiyaca gore mevcut `database.types.ts` yerine tum generated dosyayi kullanabilir veya daraltilmis adapter olusturabilirsiniz.

## Deployment

Vercel icin:
- Root directory: repo root
- Build command: `npm --prefix apps/web_next run build`
- Output: Next.js default
- Env vars: yukaridaki bes degisken

Not:
- `NEXT_PUBLIC_SITE_URL` production domain ile ayni olmali.
- `images.remotePatterns` yalnizca site host'u ve Supabase storage host'u ile sinirlidir.

## Analytics

Toplanan event tipleri:
- `page_view`
- `category_view`
- `item_view`
- `item_click`

Ozellikler:
- `/api/track` server route uzerinden yazilir
- IP saklanmaz
- Sadece minimal `ua_family` meta'si eklenir
- `/q/:shortCode` edge route'u redirect suresini `page_view` eventi altinda `source=qr_short_link` ve `meta.event_alias=qr_scanned` ile olcer
- `/api/track`, `/qr/*` ve `/auth/panel-handoff` icin basit rate limiting vardir

## Branding ve Storage

Kalici sunum ayarlari:

- tablo: `business_menu_presentation_settings`
- kolonlar: `business_id`, `default_lang`, `template_key`, `settings`, `logo_url`, `cover_url`, `background_url`

Storage kesfi:

- public bucket: `menu-media`
- private bucket: `menu-media-private`

Upload kontrati:

- route: `/sunucu/medya/yukleme`
- yetki: `hasOwnerBusiness` (owner_claims, status=approved)
- mime: `image/jpeg`, `image/png`, `image/webp`, `image/gif`, `image/heic`, `image/heif` (HEIC/HEIF sadece Safari'de <canvas> ile guvenilir aciliyor)
- max boyut: `20MB` (istemci tarafinda zaten WebP'ye sikistirilmis dosya gelir — bu sadece kotuye kullanima karsi bir tavan)
- path izolasyonu: `businesses/{businessId}/branding/{type}/{uuid}.{ext}`
- storage cache suresi: `3600`
- public render cache bust: `updated_at` tabanli `?v=` param'i
- save sonrasi public menu default `template_key` / `default_lang` degeri aninda gecerli olur; query param varsa gecici override eder

## Release Smoke

Deployment sonrasi manuel checklist:
- `docs/runbook.md`
- `docs/web_next_perf.md`
- UI token/source-of-truth haritasi: `docs/ui-style.md`

## Neden CRUD Yok?

Bu app'in urun rolu public dagitim katmanidir.

Sebep:
- Public menu performansi ile owner/admin write akislari farkli optimizasyon ister
- Public sayfalar cache ve SEO odakli olmalidir
- CRUD ekranlarini ayri panelde tutmak RLS, audit ve yetki modelini daha temiz korur
- Next app bu sayede edge-friendly ve daha dusuk riskli kalir
