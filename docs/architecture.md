# Mimari (Kod Tabanli)

Bu dokuman sistem bilesenleri, istemci sinirlari, route akislari ve yetkilendirme mimarisinin tek kaynagidir.

Su konular burada detaylandirilmaz:

- tum tablo kolonlari veya tum RPC listesi
- owner/admin operasyon ekranlarinin ayrintili UI sozlesmesi
- tarihsel release snapshot'lari

Tek kaynaklar:

- tablo ve RPC envanteri: `docs/data-model.md`
- ekran bazli operasyon sozlesmeleri: `docs/admin_businesses.md`, `docs/admin_business_submissions.md`, `docs/moderation_queue.md`, `docs/audit.md`
- tarihsel release notlari: `docs/archive/history/release_index.md`

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
- Public menu render: `apps/web_next/app/(public)/m/**/*`
- QR uretim ve redirect: `apps/web_next/app/qr/**/*`, `apps/web_next/app/q/**/*`
- Login ve panel handoff: `apps/web_next/app/login/**/*`, `apps/web_next/app/auth/panel-handoff/**/*`
- Middleware: `apps/web_next/middleware.ts`
- Supabase client katmani hibrittir:
  - re-export dosyalari: `apps/web_next/src/lib/supabaseServer.ts`, `apps/web_next/src/lib/supabaseClient.ts`
  - aktif implementasyonlar: `apps/web_next/src/lib/supabase/server.ts`, `apps/web_next/src/lib/supabase/client.ts`, `apps/web_next/src/lib/supabase/service.ts`

## Yetkilendirme ve Erisim

- Public menu sayfalari canli RLS politikalari ile public read olarak calisir.
- QR sayfasi public degildir; aktif session ve `can_manage_business_v1` yetkisi ister.
- Panelden gelen owner/admin session'i `POST /auth/panel-handoff` ile Next SSR cookie'sine cevrilir.
- `SUPABASE_SERVICE_ROLE_KEY` sadece server-side analytics yazimi icin opsiyoneldir.
- `/api/track`, `/qr/*` ve `/auth/panel-handoff` icin middleware tabanli rate limit vardir.

Kanit:
- `apps/web_next/middleware.ts`
- `apps/web_next/app/login/page.tsx`
- `apps/web_next/app/auth/panel-handoff/route.ts`
- `apps/web_next/src/lib/qr-access.ts`
- `apps/web_next/app/api/track/route.ts`
- `apps/web_next/src/lib/supabase/server.ts`
- `apps/web_next/src/lib/supabase/service.ts`

## QR Menu Akisinin Mimarideki Yeri

1. Public hedef route canonical olarak `/m/{public_slug}` uzerinden render edilir; slug yoksa fallback `/m/{businessId}` kullanilir.
2. Panel kullanicisi `QR Menu Olustur` butonundan `POST /auth/panel-handoff` ile session tasir.
3. Next cookie yazildiktan sonra `/qr/{businessId}` sayfasi canonical public link ve deterministic short link uretir.
4. QR gorseli istemci tarafinda PNG/SVG olarak uretilir; yeni tablo veya storage yazimi yoktur.
5. `/q/{code}` deterministic kisaltmayi `businessId`'ye cozer.
6. `log_event_v1` ile `qr_scanned` eventi yazilir.
7. Kullanici public route'a yonlendirilir; ilk hop `businessId` olsa bile route canonical `/m/{public_slug}` adresine temizlenir.

Kanit:
- `apps/web_next/app/auth/panel-handoff/route.ts`
- `apps/web_next/app/qr/[businessId]/page.tsx`
- `apps/web_next/src/ui/sections/qr-generator.tsx`
- `apps/web_next/src/lib/short-code.ts`
- `apps/web_next/app/q/[code]/route.ts`

## Public Menu Render Akisi

1. Route `publicSlugOrId` alir.
2. Repository katmani `businesses`, `menus`, `menu_categories`, `menu_items`, `menu_translations`, `business_media` ve ilgili RPC'leri okur.
3. `generateMetadata` ile SEO metadata ve OG gorseli ayarlanir.
4. Sayfa `Restaurant` + `Menu` JSON-LD uretir.
5. UUID veya legacy slug ile gelen istekler canonical `public_slug` path'ine redirect edilir.
6. Client katmani kategori, urun detay, filtre ve tracking davranisini isletir.

Kanit:
- `apps/web_next/src/lib/db/menu-read.ts`
- `apps/web_next/src/lib/public-menu-page.ts`
- `apps/web_next/app/(public)/m/[slug]/page.tsx`
- `apps/web_next/src/ui/sections/public-menu-client.tsx`

Not:
- Semantik public route slug merkezlidir; buna ragmen App Router klasor yolu teknik olarak `apps/web_next/app/(public)/m/[slug]/...` seklindedir.

## Backend (Supabase)

Canli public menu akisinda kullanilan temel tablolar:
- `businesses`
- `business_hours`
- `business_media`
- `menus`
- `menu_sections`
- `menu_categories`
- `menu_items`
- `menu_item_variants`
- `menu_item_photos`
- `menu_translations`
- `analytics_events`

Temel RPC'ler:
- `get_menu_items_v1`
- `get_menu_item_variants_v1`
- `get_menu_item_photos_v1`
- `log_event_v1`
- `public_menu_share_view_v1`

Not:
- `public.businesses.slug` ve `public.businesses.public_slug` alanlari `20260325000016_business_slug_schema_v1.sql` ve `20260325000017_business_slug_backfill_trigger_v1.sql` ile canli schema'ya yerlestirilmis; canonical public URL modeli bu alanlar uzerine kurulmustur.
- Public read RLS `businesses`, `menus`, `menu_categories`, `menu_items`, `menu_sections`, `menu_item_variants`, `menu_item_photos`, `menu_translations`, `business_media` icin mevcuttur.
- Daha genis tablo/RPC envanteri icin `docs/data-model.md` kullanilmalidir.

## Mimari Notlar

- `apps/web_next/app/(public)/b/[slug]/page.tsx` sadece eski link uyumlulugu icin UUID redirect yapar.
- QR sayfasi login + yetki kontrolludur; suistimali azaltmak icin ek rate limit de uygulanir.
- Owner/admin yazma akislari mimari olarak panel uygulamasinda kalir.
