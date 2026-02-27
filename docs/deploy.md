# Dagitim Notlari (Kod Tabanli)

Bu belge dagitim davranisini koddaki scriptlere gore aciklar.

## Build Komutlari

```bash
npm run build:owner
npm run build:admin
npm run build:next
npm run build:all
```

Kanit: `package.json` (repo root)

Not:
- Bu komutlar `tools/workspace_ops.mjs` uzerinden calisir ve Windows/Linux/macOS ortamlarinda ayni akisi hedefler.

## Cikti Klasorleri

- `deploy/owner` -> Flutter web owner
- `deploy/admin` -> Flutter web admin
- `deploy/next` -> Next.js build ciktisi

## Operasyon Notu

- Flutter web owner/admin statik dagitilabilir.
- Next tarafi Node.js process ister (`next start`). Salt FTP statik kopya yeterli degil.

## Domain ve ENV Sozlesmesi (Kod Kanitli)

Bu bolumdeki degiskenler kodda gercekten okunan anahtarlarin ozetidir.

### Panel Flutter Web (`apps/panel_flutter_web`)

Runtime `.env` (zorunlu):

- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`

Kanit:
- `apps/panel_flutter_web/lib/shared/bootstrap/web_bootstrap.dart`

Panel `.env` icindeki diger anahtarlar:

- `BASE_URL_WEB_NEXT`
- `BASE_URL_PANEL`
- `SUPABASE_SERVICE_ROLE_KEY`
- `DEV_TOOLS_ENABLED`

Not:
- Bu anahtarlar panelde bootstrap zorunlulugu olarak okunmuyor; cross-app dokuman uyumu icin `.env.example` icinde tutuluyor.
- Kanit: `apps/panel_flutter_web/.env.example`, `apps/panel_flutter_web/lib/shared/bootstrap/web_bootstrap.dart`

Compile-time (`--dart-define`) anahtarlari:

- `PLAY_STORE_URL`, `APP_STORE_URL`, `WEB_NEXT_URL`
- `APP_NAME`, `APP_SLUG`, `WEB_DOMAIN`, `DEEPLINK_SCHEME`, `DEV_TOOLS_ENABLED`

Kanit:
- `apps/panel_flutter_web/lib/features/marketing/ui/web_home_page.dart`
- `apps/panel_flutter_web/lib/core/config/app_config.dart`

### Web Next (`apps/web_next`)

Supabase istemci/server (zorunlu):

- `NEXT_PUBLIC_SUPABASE_URL` veya `SUPABASE_URL`
- `NEXT_PUBLIC_SUPABASE_ANON_KEY` veya `SUPABASE_ANON_KEY`

Service role (admin API icin zorunlu):

- `SUPABASE_SERVICE_ROLE_KEY`

Panel yonlendirme:

- `BASE_URL_PANEL`

QR hedef URL:

- `NEXT_PUBLIC_APP_URL` (yoksa `http://localhost:3000`)

Kanit:
- `apps/web_next/src/lib/supabaseClient.ts`
- `apps/web_next/src/lib/supabaseServer.ts`
- `apps/web_next/src/lib/supabaseAdmin.ts`
- `apps/web_next/src/lib/panelUrl.ts`
- `apps/web_next/app/api/qr/route.tsx`

### Domain baglama modeli

Onerilen calisma sekli:

- Next public alan: `https://yeedoy.com` (Node process)
- Panel owner: `https://yeedoy.com/owner/` (statik Flutter web)
- Panel admin: `https://yeedoy.com/admin/` (statik Flutter web)

Bu modelde:

- Next `app/admin`, `app/owner`, `app/menu-builder` route'lari panel URL'ine redirect eder.
- Kanit: `apps/web_next/app/admin/page.tsx`, `apps/web_next/app/owner/page.tsx`, `apps/web_next/app/menu-builder/page.tsx`
