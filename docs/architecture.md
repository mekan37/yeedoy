# Mimari (Kaynak Doküman)

Bu doküman yalnızca yerel kod tabanına dayanır.

## Üst Seviye Mimari

Sistem, tek Supabase backend'e bağlanan üç istemci uygulamadan oluşur:

- Mobil istemci: `apps/mobile_flutter` (Flutter)
- Panel istemci: `apps/panel_flutter_web` (Flutter Web)
- Web istemci: `apps/web_next` (Next.js)

## İstemci Katmanı

### Mobil (Flutter)

- Giriş: `apps/mobile_flutter/lib/main.dart`
- Router: `apps/mobile_flutter/lib/app/router.dart`
- Supabase init: `.env` içinden `SUPABASE_URL` ve `SUPABASE_ANON_KEY`
- Ek telemetri: Firebase Analytics/Crashlytics/Performance

### Panel (Flutter Web)

- Admin giriş: `apps/panel_flutter_web/lib/main_web_admin.dart`
- Owner giriş: `apps/panel_flutter_web/lib/main_web_owner.dart`
- Router: `apps/panel_flutter_web/lib/app/router.dart`
- Supabase init: `apps/panel_flutter_web/lib/shared/bootstrap/web_bootstrap.dart`

### Web (Next.js)

- Route katmanı: `apps/web_next/app/**/*`
- Middleware auth/rol kontrolü: `apps/web_next/middleware.ts`
- Supabase sunucu istemcisi: `apps/web_next/src/lib/supabaseServer.ts`
- Supabase tarayıcı istemcisi: `apps/web_next/src/lib/supabaseClient.ts`
- Service role istemcisi: `apps/web_next/src/lib/supabaseAdmin.ts`

## Backend Katmanı (Supabase)

Repo'da Supabase bileşenleri:

- Migration SQL: `supabase/migrations/*.sql`
- Edge Functions: `supabase/functions/*`
- Seed: `supabase/seed/*`
- Policy notu: `supabase/policies/README.md`

Not:

- `supabase/remote_schema.sql` ve `supabase/remote_schema_latest.sql` boş (0 byte).
- Bu yüzden veri modeli çıkarımı migration dosyaları ve uygulama sorgularından yapılır.

## Güvenlik ve Yetkilendirme

- Web middleware, `/dashboard`, `/owner`, `/admin`, `/menu-builder` için login zorlar.
- `/admin` için ek admin kontrolü (`is_admin` RPC + `admin_users` tablosu) uygulanır.
- Owner yazma akışlarında `is_owner_of_business` ve/veya `admin_users` kontrolü kullanılır.

Kanıt:

- `apps/web_next/middleware.ts`
- `apps/web_next/src/lib/auth.ts`
- `apps/web_next/src/lib/ownership.ts`

## QR Menü Akışı Mimari Konumu

- QR üretim: dashboard -> `POST /api/qr`
- Hedef URL: `/b/{slugOrId}?lang=tr`
- Kısa link route'u: `/q/[code]` -> `/b/{slug}?lang=tr`
- Public render: `/b/[slug]` sayfası Supabase'den menü verisini çekip render eder.

Kanıt:

- `apps/web_next/app/(dashboard)/dashboard/businesses/[id]/qr/page.tsx`
- `apps/web_next/app/api/qr/route.tsx`
- `apps/web_next/app/q/[code]/page.tsx`
- `apps/web_next/app/(public)/b/[slug]/page.tsx`

## Edge Function Katmanı

Mevcut fonksiyonlar:

- `admin-api`
- `anti-spam-guard`
- `purge-temp-uploads`
- `push-dispatch`
- `wp-upload`
- `wp-upload-user`
- `write-gatekeeper`
- `import_places_json`

Kaynak: `supabase/functions/*`

## Mevcut Ama Kısmi/Kullanımı Sınırlı Unsurlar

- Next `/admin` sayfası placeholder düzeyinde.
- Next `/owner` ve `/menu-builder` bağımsız ekran değil, redirect.
- Panel `web_order` uygulaması TODO metni içeriyor.

Kanıt:

- `apps/web_next/app/admin/page.tsx`
- `apps/web_next/app/owner/page.tsx`
- `apps/web_next/app/menu-builder/page.tsx`
- `apps/panel_flutter_web/lib/web_order/web_order_app.dart`
