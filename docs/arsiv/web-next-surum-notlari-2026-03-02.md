# web_next Surum Notlari - Public Menu + QR Studio (CRUD Yok)

Tarih: 2026-03-02
Durum: READY

## Kapsam Ozeti

`uygulamalar/web` production release kapsaminda yalnizca su yuzeyleri sunar:

- Public dijital menu goruntuleme: `/m/:businessId`
- Authenticated owner QR Studio: `/qr/:businessId`
- Template Studio: presentation settings, preview link, QR uretimi
- SEO, analytics, performans ve tema dili

Kapsam disi:

- Owner/admin CRUD ekranlari
- Menu veya business create/update/delete
- Panel yonetim akisinin `web_next` icine tasinmasi

Owner ve admin CRUD islemleri `uygulamalar/panel_flutter_web` icinde kalir. `web_next` panelden link veya session handoff ile baslatilan dagitim ve sunum katmanidir.

## Kapatilan Kritik Sorunlar

### 1. Owner handoff payload dogrulamasi duzeltildi

- `uygulama/auth/panel-devir/route.ts` icindeki `refresh_token` uzunluk varsayimi kaldirildi.
- Payload validation artik minimum `1` karakter kabul eder.
- Gercek oturum dogrulamasi `supabase.auth.setSession()` ve takip eden oturum yenileme zinciri ile yapilir.
- HTTP davranisi:
  - invalid payload -> `400`
  - auth fail -> `401`
  - success -> `200`

### 2. Analytics event mapping `log_event_v1` ile hizalandi

- `src/lib/analytics.ts` icinde UI event'leri canli RPC event setine map edilir.
- Alias korunumu `meta.event_alias` uzerinden tutulur.
- Aktif mapping:
  - `page_view` -> `menu_link_opened`
  - `category_view` -> `menu_view`
  - `item_view` -> `menu_view`
  - `item_click` -> `menu_view`
  - `qr_scanned` -> `qr_scanned`
- `uygulama/sunucu/izleme/route.ts` artik RPC sonucu `{ ok: false }` ise sessiz `200` donmez.

### 3. Veritabani enum/text operator hatasi kapatildi

- SQL patch: `supabase/migrations/20260325000002_fix_recompute_user_achievements_enum_cast.sql`
- Duzeltilen fonksiyonlar:
  - `public.recompute_user_achievements_v1`
  - `public.get_user_reputation_score_v2`
- Enum/text karsilastirmalari geriye donuk uyumlu olacak sekilde duzeltildi.
- Analytics zincirindeki `42883 operator does not exist: menu_price_suggestion_status = text` crash'i kapatildi.

### 4. HTTP semantigi duzeltildi

- Malformed public route artik `404` doner:
  - `/m/not-a-uuid`
- Yetkisiz QR akisi artik finalde `403` doner:
  - `/qr/:businessId` -> `307 /forbidden` -> final `403`
- Query normalization aktif:
  - allowed themes: `minimal|bold|elegant|photo-heavy|dark-modern`
  - invalid theme -> canonical normalize

## Template Studio Urunlestirme

Bu surumle QR Studio yalnizca QR ureten bir ekran olmaktan cikip kalici presentation settings editor'u haline geldi.

- Preview link: `/m/:businessId?theme=...&preview=1`
- Kaydetmeden once preview linki acma ve kopyalama
- `Reset to Default`: kayitli DB ayarlarina tek tusla donus
- `Unsaved changes` uyarisi
- Her template icin thumbnail preview
- `logo / cover / background` medya secimi ve yukleme
- Cache-busting icin media URL version param'i (`updated_at`)

## Performans Kazanimi

### First Load JS

- `/m/[slug]`: `138 kB -> 109 kB`
- `/qr/[businessId]`: `138 kB -> 109 kB`

### Mobil Lighthouse

| Senaryo | Route | Performance | Accessibility | Best Practices | SEO |
|---|---|---:|---:|---:|---:|
| minimal | `/m/...?lang=tr&theme=minimal` | 99 | 100 | 96 | 90 |
| photo-heavy | `/m/...?lang=tr&theme=photo-heavy` | 99 | 100 | 96 | 90 |
| dark-modern | `/m/...?lang=tr&theme=dark-modern` | 99 | 100 | 96 | 90 |
| qr bold | `/qr/...?lang=tr&theme=bold` | 97 | 100 | 96 | 100 |

## Medya ve Guvenlik Sertlestirmesi

- Upload mime allowlist: `image/jpeg`, `image/png`, `image/webp`
- Max upload: `5MB`
- Path izolasyonu: `businesses/{businessId}/branding/{type}/{uuid}.{ext}`
- Yetki: `can_manage_business_v1(business_id)` zorunlu
- Storage cache suresi: `31536000`
- Public render cache bust: `updated_at` tabanli `?v=` param'i
- `next/image remotePatterns` artik yalnizca site ve Supabase host'lariyla sinirli

## Riskler ve Notlar

- Yetkisiz QR akisi tek hop `403` degil; `307 -> /forbidden -> 403` seklinde sonlanir.
- `preview=1` route'u DB'ye yazmaz; yalnizca query override katmanidir.
- `scripts/build.mjs` stale `.next` kaynakli build dengesizlikleri icin sertlestirilmistir.

## Geriye Donuk Uyumluluk

- Schema isimleri degismedi.
- RLS politikalari korunuyor.
- `can_manage_business_v1` owner gate kaynagi olarak kaldi.
- `web_next` icine CRUD eklenmedi.
- Panel -> `web_next` URL kontrati korunuyor:
  - `/qr/:businessId?lang=tr&theme=bold`
  - `/m/:businessId?lang=tr&theme=bold`

## Surum Dogrulama Ozeti

Canli smoke sonucu: PASS

- Owner handoff `200`
- Yetkisiz QR final `403`
- Analytics DB'ye yaziyor
- Short link `qr_scanned` ve `redirect_ms` uretiyor
- Owner save/upload/apply akisi PASS
- Public menu performans hedefleri korunuyor
- QR Studio Lighthouse accessibility notu: `target-size` nedeniyle `91`


