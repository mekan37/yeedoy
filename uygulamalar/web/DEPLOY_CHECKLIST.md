# web_next Production Deploy Checklist

Tarih: 2026-03-03

## 1. Kapsam Dogrulamasi

- `apps/web_next` public menu, authenticated QR Studio, template/branding, SEO, analytics ve owner/admin web yuzeyidir.
- Owner/admin CRUD ekranlari `apps/web_next/app/owner/**` ve `apps/web_next/app/admin/**` altindadir.
- Public route modeli `businessId` tabanlidir.

## 2. Ortam Degiskenleri

Production ortaminda asagidaki degiskenler dogru set edilmis olmali:

- `NEXT_PUBLIC_SUPABASE_URL`
- `NEXT_PUBLIC_SUPABASE_ANON_KEY`
- `SUPABASE_SERVICE_ROLE_KEY`
- `NEXT_PUBLIC_SITE_URL`

Kontroller:

- `SUPABASE_SERVICE_ROLE_KEY` yalnizca server-side ortamda kalmali.
- `NEXT_PUBLIC_SITE_URL` production host ile birebir ayni olmali.
- Owner/admin login redirect hedefleri production host ile uyumlu olmali.

## 3. Veritabani Migration Sirasi

Deploy oncesi asagidaki migration'lar production'da uygulanmis olmali:

1. `supabase/migrations/20260302000001_business_menu_presentation_settings.sql`
2. `supabase/migrations/20260325000002_fix_recompute_user_achievements_enum_cast.sql`

Dogrulama notlari:

- `business_menu_presentation_settings` tablosu ve RLS policy'leri aktif olmali.
- `recompute_user_achievements_v1` ve `get_user_reputation_score_v2` enum/text patch'i production'da yer almali.

## 4. Deploy Adimlari

Vercel veya esdeger target host icin tipik sira:

1. Production env degiskenlerini yukle.
2. DB migration durumunu dogrula.
3. `apps/web_next` icin production build al.
4. Yeni release'i deploy et.
5. Deploy sonrasi smoke ve Lighthouse komutlarini kos.

Repo icinde calistirilacak komutlar:

```bash
npm --prefix apps/web_next run typecheck
npm --prefix apps/web_next run lint
npm --prefix apps/web_next run build
npm --prefix apps/web_next run test:e2e:live
npm --prefix apps/web_next run lighthouse:mobile
npm --prefix apps/web_next run lighthouse:qr:auth
```

Notlar:

- `PLAYWRIGHT_SMOKE_BUSINESS_ID` live smoke icin zorunludur.
- `PLAYWRIGHT_SMOKE_BUSINESS_PATH` verilirse smoke canonical slug route'unu ve legacy UUID redirect'ini de dogrular.
- `lighthouse:qr:auth` icin owner test env'leri tanimli olmali.
- Build wrapper stale `.next` artifact'lerini temizleyip tekrar build dener.

## 5. Post-Deploy Smoke

### Owner/Admin -> QR Studio

1. Web'de owner veya yetkili admin oturumu ac.
2. `Dijital Menu & QR` butonuna tikla.
3. `/qr/:businessId?lang=tr&theme=bold` acildigini dogrula.
4. Session yoksa `/login?redirect=...` davranisinin dogru oldugunu kontrol et.

### QR Studio

1. Template secimi yap.
2. `tr/en` dil degistir.
3. `Preview` linki kopyala ve ac.
4. `Reset to Default` davranisini kontrol et.
5. `Linki Kopyala`, `PNG indir`, `SVG indir` aksiyonlarini kontrol et.
6. Gorsel upload ve mevcut medya secimini test et.

### Public Menu

1. `/m/:publicSlugOrId` ac.
2. Kayitli `template_key` ve `default_lang` uygulanmis mi kontrol et.
3. `?theme=` override davranisini kontrol et.
4. `?preview=1` ile kayitsiz canli onizlemeyi test et.
5. Isletmede `public_slug` varsa legacy `/m/:businessId` isteginin canonical slug path'ine redirect ettigini dogrula.
6. Deep link'leri kontrol et:
   - `/m/:publicSlugOrId/c/:categoryId`
   - `/m/:publicSlugOrId/i/:itemId`

### Short Link

1. `/q/:shortCode` ac.
2. Final URL'nin canonical `/m/:publicSlugOrId?...&src=qr` path'inde sonlandigini dogrula.
3. `qr_scanned` alias ve `redirect_ms` meta zincirini izleme tarafinda kontrol et.

### A11y / Perf

1. `npm --prefix apps/web_next run lighthouse:mobile`
2. `npm --prefix apps/web_next run lighthouse:qr:auth`
3. `docs/perf.md` icindeki son skorlarin su aralikta kaldigini dogrula:
   - `/m/[slug]` first load JS: `109 kB`
   - `/qr/[businessId]` first load JS: `110 kB`
   - Login Gate Accessibility: `100`
   - Authenticated QR Studio Accessibility: `98`

## 6. Beklenen HTTP Davranisi

- `POST /auth/panel-handoff`
  - invalid payload -> `400`
  - auth fail -> `401`
  - success -> `200`
- `GET /m/not-a-uuid` -> `404`
- `GET /qr/:businessId`
  - no session -> `307` login redirect
  - unauthorized -> final `403`
  - authorized -> `200`
- gecersiz `theme` -> normalize edilmis URL'ye `307`

## 7. Monitoring

Deploy sonrasi ilk izlenecek metrikler:

- `/api/track` error rate
- `401` ve `403` oranlari
- `log_event_v1 invalid_event` orani
- storage upload fail orani
- `429` rate-limit orani
- `qr_scanned` hacmi ve `redirect_ms` dagilimi

Beklenen durum:

- `invalid_event` orani `0`
- yetkisiz write/upload denemeleri `403`
- analytics yazimi sessiz `200` ile dusmez
- upload hatalari mime/size validation durumlariyla sinirli kalir

## 8. Rollback Hazirligi

- Uygulama rollback plani: `docs/rollback/web_next_rollback_plan.md`
- DB rollback oncesi mevcut fonksiyon DDL'lerini yedekle:
  - `select pg_get_functiondef('public.recompute_user_achievements_v1(uuid)'::regprocedure);`
  - `select pg_get_functiondef('public.get_user_reputation_score_v2(uuid)'::regprocedure);`
- `business_menu_presentation_settings` tablosu veri kaybi yaratmadan yerinde kalabilir; once app rollback degerlendirilmelidir.
