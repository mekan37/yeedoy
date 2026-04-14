# Dagitim Notlari (Kod Tabanli)

Bu belge dagitim davranisini mevcut scriptler ve aktif route yapisina gore aciklar.

## Build Komutlari

```bash
npm run build:owner
npm run build:admin
npm run build:next
npm run build:all
```

Kanit: `package.json` (repo root)

Not:
- Bu komutlar `tools/workspace_ops.mjs` uzerinden calisir.
- `apps/web_next` Node.js process ister; salt statik kopya yeterli degildir.

## Cikti Klasorleri

- `deploy/owner` -> Flutter web owner
- `deploy/admin` -> Flutter web admin
- `deploy/next` -> Next.js build ciktisi

## Domain ve ENV Sozlesmesi

Bu bolumdeki degiskenler aktif kod tarafinda gercekten okunan anahtarlarin ozetidir.

### Panel Flutter Web (`apps/panel_flutter_web`)

Runtime `.env`:

- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`
- `BASE_URL_WEB_NEXT`
- `BASE_URL_PANEL` (deploy/domain sozlesmesi icin kullanilir)

Compile-time (`--dart-define`) tarafinda kullanilan tipik anahtarlar:

- `PLAY_STORE_URL`
- `APP_STORE_URL`
- `WEB_NEXT_URL`
- `APP_NAME`
- `APP_SLUG`
- `WEB_DOMAIN`
- `DEEPLINK_SCHEME`
- `DEV_TOOLS_ENABLED`

Kanit:
- `apps/panel_flutter_web/lib/shared/bootstrap/web_bootstrap.dart`
- `apps/panel_flutter_web/lib/core/config/app_config.dart`
- `apps/panel_flutter_web/lib/core/navigation/public_menu_url.dart`

### Web Next (`apps/web_next`)

Zorunlu:

- `NEXT_PUBLIC_SUPABASE_URL`
- `NEXT_PUBLIC_SUPABASE_ANON_KEY`
- `NEXT_PUBLIC_SITE_URL`

Opsiyonel:

- `NEXT_PUBLIC_PANEL_URL`
- `SUPABASE_SERVICE_ROLE_KEY`

Kanit:
- `apps/web_next/src/lib/config.ts`
- `apps/web_next/src/lib/supabase/client.ts`
- `apps/web_next/src/lib/supabase/server.ts`
- `apps/web_next/src/lib/supabase/service.ts`

Not:
- Public menu read akisi yalnizca anon key ile calisir.
- `SUPABASE_SERVICE_ROLE_KEY` su an esas olarak analytics yazimi icin kullanilir.
- `NEXT_PUBLIC_PANEL_URL` varsa Next login sayfasi panel login'e geri donus linki sunar.
- Eski `NEXT_PUBLIC_APP_URL` ve panel redirect anahtarlari aktif public menu akisinin parcasi degildir.
- Development ortaminda Playwright `127.0.0.1` origin'i icin `allowedDevOrigins` acik tutulur.

## Env Hijyeni

`.env.example` ve benzeri ornek dosyalar yalnizca placeholder degerler tasimalidir.

Kalici kurallar:

- gercek anon key veya service role key repo icine yazilmaz
- lokal makinelerde eski `.env` kopyalari temiz tutulur
- release oncesi secret scan veya en azindan regex tabanli hizli kontrol uygulanir

Hizli kontrol:

```bash
rg -n "eyJhbGci|SUPABASE_SERVICE_ROLE_KEY=.*[A-Za-z0-9_-]{20,}" apps/**/.env.example
```

Beklenen sonuc: eslesme olmamasi

## Dagitim Modeli

Onerilen dagitim ayrimi:

- Public Next app: `https://menu.example.com` veya ana domain
- Panel owner/admin: ayri domain veya ayri hosting hedefi

Bu modelde:

- `apps/web_next` sadece public menu + QR + analytics katmanidir.
- Owner/admin CRUD ekranlari `apps/panel_flutter_web` tarafinda kalir.
- Panel butonlari `POST /auth/panel-handoff` ile session tasiyip `https://.../qr/:businessId` rotasina iner.

### Panel Route ve Yetki Notlari

- `/owner/*` ve `/admin/*` panel origin'i altinda kalmalidir.
- `401` panel istekleri login ekranina yonlenir.
- `403` panel istekleri `/forbidden` ekranina dusur.
- `BASE_URL_WEB_NEXT`, panelden ayri origin olsa bile handoff, CORS ve yeni sekme davranisi ile uyumlu olmalidir.

## Cache Invalidation (`/api/revalidate`)

`POST /api/revalidate` ile on-demand cache temizleme yapilir. Bu endpoint deployment pipeline veya Supabase webhook tarafindan cagirilmali.

Gerekli env: `REVALIDATE_SECRET` (production'da zorunlu; yoksa endpoint 503 doner).

### Cagirim ornekleri

Tek slug temizle:
```bash
curl -X POST https://menu.example.com/api/revalidate \
  -H "Content-Type: application/json" \
  -d '{"secret":"$REVALIDATE_SECRET","slug":"kafe-yeedoy"}'
```

Business ID ile slug + QR temizle:
```bash
curl -X POST https://menu.example.com/api/revalidate \
  -H "Content-Type: application/json" \
  -d '{"secret":"$REVALIDATE_SECRET","businessId":"<uuid>"}'
```

Tum `/m/*` sayfalarini temizle (genis tarama):
```bash
curl -X POST https://menu.example.com/api/revalidate \
  -H "Content-Type: application/json" \
  -d '{"secret":"$REVALIDATE_SECRET"}'
```

### Deployment pipeline entegrasyonu

Her deploy sonrasinda genis tarama cagrisi onerilen minimum adimdir:
```bash
curl -sf -X POST "$NEXT_PUBLIC_SITE_URL/api/revalidate" \
  -H "Content-Type: application/json" \
  -d "{\"secret\":\"$REVALIDATE_SECRET\"}" || echo "revalidate skipped (secret not set)"
```

### Supabase webhook entegrasyonu

`businesses`, `menus` veya `menu_items` tablolarinda write sonrasi Supabase Database Webhook ile `/api/revalidate` cagrilabilir. Payload `businessId` icermeli; `REVALIDATE_SECRET` webhook secret olarak gonderilmeli.

### TTL fallback

`REVALIDATE_SECRET` set edilmezse endpoint 503 doner ve sayfalar zaman asimina (revalidate TTL) birakilir. Varsayilan TTL: `menu-read.ts` icinde route tipine gore 120-600 saniye.

## Vercel Notu (`apps/web_next`)

Onerilen ayar:

- Root directory: repo root
- Build command: `npm --prefix apps/web_next run build`
- Start command: `npm --prefix apps/web_next run start`
- Install command: `npm install`

Alternatif:

- Ayrik proje olarak `apps/web_next` dizini de deploy edilebilir.

## Operasyon Notlari

- `NEXT_PUBLIC_SITE_URL` production domain ile birebir ayni olmali.
- `NEXT_PUBLIC_PANEL_URL` Next login sayfasinda dogru panel domain'ini gostermeli.
- `BASE_URL_WEB_NEXT` panel tarafinda dogru production Next domain'ini gostermeli; aksi halde `QR Menu Olustur` butonlari localhost fallback'ine duser.
- `images.remotePatterns` tum HTTP/HTTPS hostlarini kabul eder; farkli medya saglayicilarindan gelen menu gorselleri icin bu bilincli olarak genistir.
- `/api/track`, `/qr/*` ve `/auth/panel-handoff` middleware rate limit altindadir.

## Web Kalite Yuzeyleri

`apps/web_next` tarafinda release kalitesi icin asgari beklenti:

- `robots.txt` route'u mevcut olmali
- `sitemap.xml` route'u mevcut olmali
- public menu canonical URL'leri `buildMenuHref(...)` uzerinden normalize edilmeli
- auth-only yüzeyler (`/login`, `/qr/*`, `/forbidden`) `noindex` davranisi tasimali
- `next.config.mjs` icinde image host allowlist'i kontrollu kalmali
- `next.config.mjs` icinde temel guvenlik basliklari (`Referrer-Policy`, `X-Content-Type-Options`, `X-Frame-Options`) tanimli olmali
- `robots.txt`, `sitemap.xml` ve `/api/og` icin cache header sozlesmesi korunmali

## Belge Siniri

Bu dokuman yalnizca:

- env sozlesmesi
- domain ve deploy modeli
- hosting ve cache/headers beklentisi

icin source-of-truth kabul edilir.

Su konular bu dosyada tutulmaz:

- smoke checklist
- incident response
- perf veya regression kontrol sirasi
- release gunu manuel operator adimlari

Bu operasyon akislari icin tek kaynak:

- `docs/runbook.md`

Ek tarihsel release notlari:

- `apps/web_next/RELEASE_NOTES.md`
- `apps/web_next/DEPLOY_CHECKLIST.md`
- `docs/archive/history/release_index.md`
