# Mimari (Kod Tabanli)

## Ust Seviye

Yapi, tek Supabase backend'e baglanan uc istemciden olusur:

- Mobil: `apps/mobile_flutter`
- Panel: `apps/panel_flutter_web`
- Web: `apps/web_next`

## Istemci Katmani

### Mobil

- Giris: `apps/mobile_flutter/lib/main.dart`
- Router: `apps/mobile_flutter/lib/app/router.dart`
- Supabase init: `SUPABASE_URL`, `SUPABASE_ANON_KEY`

### Panel

- Admin entry: `apps/panel_flutter_web/lib/main_web_admin.dart`
- Owner entry: `apps/panel_flutter_web/lib/main_web_owner.dart`
- Router/entry seti: `apps/panel_flutter_web/lib/app_admin.dart`, `apps/panel_flutter_web/lib/app/router.dart`

### Web (Next)

- Route katmani: `apps/web_next/app/**/*`
- Auth/middleware: `apps/web_next/middleware.ts`
- Supabase server/browser/admin clientleri: `apps/web_next/src/lib/supabaseServer.ts`, `apps/web_next/src/lib/supabaseClient.ts`, `apps/web_next/src/lib/supabaseAdmin.ts`

## Yetkilendirme ve Erisim

- Next middleware, `/dashboard`, `/owner`, `/admin`, `/menu-builder` icin login zorlar.
- `/admin` icin ek admin kontrolu (`is_admin` RPC + `admin_users`).
- Menu API'lerinde owner/admin kontrolleri var.

Kanit:
- `apps/web_next/middleware.ts`
- `apps/web_next/src/lib/auth.ts`
- `apps/web_next/src/lib/ownership.ts`
- `apps/web_next/app/api/menu/*`

## QR Menu Akisinin Mimarideki Yeri

1. Dashboard uzerinden QR uretim (`/dashboard/businesses/[id]/qr`)
2. `POST /api/qr` ile varlik olusturma ve storage upload
3. QR hedefi: `/b/{slugOrId}?lang=...`
4. Kisa route: `/q/[code]` (slug lookup)
5. Public render: `/b/[slug]`

Kanit:
- `apps/web_next/app/(dashboard)/dashboard/businesses/[id]/qr/page.tsx`
- `apps/web_next/app/api/qr/route.tsx`
- `apps/web_next/app/q/[code]/page.tsx`
- `apps/web_next/app/(public)/b/[slug]/page.tsx`

## Backend (Supabase)

- Migrationlar: `supabase/migrations/*.sql`
- Edge functionlar: `supabase/functions/*`
- Seed/policy notlari: `supabase/seed/*`, `supabase/policies/README.md`

Not:
- `supabase/remote_schema.sql` ve `supabase/remote_schema_latest.sql` su an bos.

## Mimari Aciklar

- Next admin yuzeyi urunsel olarak eksik (placeholder).
- Next owner/menu-builder bagimsiz moduller degil (redirect).

Kanit:
- `apps/web_next/app/admin/page.tsx`
- `apps/web_next/app/owner/page.tsx`
- `apps/web_next/app/menu-builder/page.tsx`
