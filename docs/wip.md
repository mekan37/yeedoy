# WIP / Eksik Parça Listesi

Bu liste repo taramasında "mevcut ama tamamlanmamış" görünen parçaları içerir.

## Ürün Yüzeyi

- Next admin sayfası: placeholder metin var, kapsamlı admin UI yok.
  - Kanıt: `apps/web_next/app/admin/page.tsx`

- Next owner ve menu-builder route'ları: bağımsız ekran yerine redirect.
  - Kanıt: `apps/web_next/app/owner/page.tsx`, `apps/web_next/app/menu-builder/page.tsx`

- Panel web_order uygulaması: TODO metinli placeholder.
  - Kanıt: `apps/panel_flutter_web/lib/web_order/web_order_app.dart`

## Veri ve Şema

- `supabase/remote_schema.sql` ve `supabase/remote_schema_latest.sql` boş.
  - Kanıt: dosya boyutları 0 byte

- Uygulamada kullanılan bazı çekirdek tablolar için başlangıç DDL'i bu snapshot'ta görünmüyor.
  - Örnek: `businesses`, `menus`, `menu_items`, `menu_categories`

## Test

- Web Next tarafında test dosyası bulunamadı; test script'i smoke (lint+typecheck) odaklı.
  - Kanıt: `apps/web_next/package.json`, test dosyası taraması

## Paketleşme

- `packages/shared` klasöründe kod var, ancak `package.json` yok.
- `@yeedoy/*` paket importları uygulama kodunda görünmüyor.
  - Kanıt: `packages/shared/*`, import taraması
