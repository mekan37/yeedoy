# Yeedoy Mimari Kurallari

## 1. Monorepo Sinirlari

### `uygulamalar/mobil`

Izinli:
- Discovery, business detail, menu, review, favorites, profile
- Offline queue, notifications, deep link, public/consumer flow

Yasak:
- Owner/admin operasyon CRUD'u
- Panel shell mantigini mobile'a tasimak

### `uygulamalar/web`

Izinli:
- Public menu render
- QR Studio, branding upload
- Public analytics, OG metadata, short link
- Owner dashboard, onboarding, team, menu CRUD, analytics, growth
- Admin queue, reports, businesses, moderation, observability

Yasak:
- Supabase write akislarini route handler disi client component icine tasimak

## 2. Flutter Katman Kurali

Feature klasorlerinde kanonik ayrim:

- `data/`: deposu, remote/local data source, cache, IO
- `domain/`: model, provider, controller, state
- `ui/`: page, section, widget, sheet

Kurallar:
- Yeni Supabase sorgusu deposu'ye gider.
- Controller'lar ince kalir; UI state'i deposu cagirir.
- UI'da yeni `client.rpc()` veya `client.from()` acilmaz.
- Legacy UI-local provider varsa dokunulan yerde yeni ornek eklenmez; yeni kod `domain` altina tasinir.

## 3. Web Katman Kurali

- `uygulama/**/page.tsx`: route, metadata, redirect/notFound
- `uygulama/sunucu/**/route.ts`: mutation/boundary
- `src/lib/veri/*`: read model
- `src/ui/sections/*`: interaktif client surface

Kurallar:
- Public data okuma `src/lib/veri/menu-read.ts` ve yakin helper'larda tutulur.
- `route.ts` icinde `zod.safeParse` olmadan yeni payload kabul edilmez.
- Auth gereken route'larda user kontrolu + yetki kontrolu + rate limit zorunludur.
- Client component, dogrudan Supabase client baglamaz; server route veya server helper kullanir.

## 4. Supabase Kurali

- Flutter tarafinda RPC-first desen baskindir; ayni isi yapan yeni REST/HTTP katmani uydurulmaz.
- Dogrudan tablo sorgusu ancak mevcut repo ornegi varsa ve gerekliyse kullanilir.
- Yeni SQL degisikligi yeni migration dosyasi ile gelir; eski migration editlenmez.
- Migration adlari mevcut timestamp + snake_case desenini izler.

## 5. Shared Paket Kurali

Aktif:
- `packages/shared_models`
- `packages/shared_ui_components`
- `packages/l10n_assets`

Pasif veya baglantisi zayif:
- `packages/api_client`
- `packages/shared_config`
- `packages/shared_types`
- `packages/ui_tokens` web source-of-truth olarak degil

Kural:
- Yeni ortaklama ihtiyacinda once aktif paketlerden biri hedeflenir.
- Pasif paketi canlandirmak explicit mimari karari olmadan yapilmaz.

## 6. Standartlastirma Hedefleri

En guvenli kanonik hedefler:
- Flutter: `deposu -> provider/controller -> page/widget`
- Web owner/admin: `PanelShell` etrafinda tek iskelet
- Web public: `page.tsx -> src/lib -> client section` ayrimi
- I18n: Flutter ARB + `common_*.arb`, web `src/lib/i18n.ts`
- UI token: Flutter theme source-of-truth, web local mirror
