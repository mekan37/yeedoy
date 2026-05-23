# web_next Surum Notu 20260228

Bu dosya tarihsel release snapshot'idir. Kalici source-of-truth degildir.

Kalici kaynaklar:

- deploy modeli: `docs/dagitim.md`
- smoke ve incident adimlari: `docs/operasyon-kilavuzu.md`
- web_next perf olcumu: `docs/web_next_perf.md`

## Ust Yonetici Ozeti

`uygulamalar/web` release candidate asamasindan production release asamasina alinmistir. Bu surum, public restoran menusu ve authenticated QR Studio yuzeyini production-safe hale getirir; owner/admin CRUD akislari panelde kalmaya devam eder. Canli smoke PASS durumundadir, analytics yazimi yeniden dogrulanmistir, bozuk route ve yetkisiz erisim davranislari HTTP seviyesinde sertlestirilmistir.

## Ne Degisti

- Owner panel session handoff'u production-safe hale geldi.
- UI analytics event'leri canli `log_event_v1` event setiyle hizalandi.
- Analytics zincirini bozan enum/text operator crash SQL patch ile kapatildi.
- Public route ve QR gate HTTP semantigi sertlestirildi.
- Build wrapper stale `.next` kaynakli surum risklerini azaltacak sekilde koruma altina alindi.

## Neden

- Kritik sorun olan owner handoff `400 invalid_payload` hatasi owner akislarini durduruyordu.
- Analytics tarafinda sessiz `200` ama gercekte yazilmayan event problemi vardi.
- `recompute_user_achievements_v1` icindeki enum/text karsilastirmasi analytics sonrasinda `500` uretiyordu.
- Malformed route ve unauthorized durumlarinda status code semantigi SEO ve izleme acisindan yetersizdi.

## Etki

- Panel -> `web_next` owner QR Studio akisi artik calisir.
- Analytics event'leri DB'ye yazilir ve alias bilgisi korunur.
- Short link redirect performansi `redirect_ms` ile izlenir.
- Public menu route'lari ve QR gate daha dogru HTTP davranisi verir.
- CRUD kapsami degismedi; schema isimleri ve RLS korunur.

## Teknik Detaylar

Etkilenen ana dosyalar:

- `uygulamalar/web/uygulama/auth/panel-devir/route.ts`
- `uygulamalar/web/src/lib/analytics.ts`
- `uygulamalar/web/uygulama/sunucu/izleme/route.ts`
- `uygulamalar/web/src/lib/route-normalization.ts`
- `uygulamalar/web/middleware.ts`
- `uygulamalar/web/scripts/build.mjs`
- `supabase/migrations/20260325000002_fix_recompute_user_achievements_enum_cast.sql`
- `docs/web_next_perf.md`

HTTP davranisi:

- `/auth/panel-devir`: `400 / 401 / 200`
- `/qr/:businessId`: unauthenticated `307`, unauthorized final `403`
- `/m/not-a-uuid`: `404`
- invalid theme: `307` ile normalized `theme=bold`

Analytics mapping:

- `page_view` -> `menu_link_opened`
- `category_view` -> `menu_view`
- `item_view` -> `menu_view`
- `item_click` -> `menu_view`
- `qr_scanned` -> `qr_scanned`

## Olcumler

Kaynak: `docs/web_next_perf.md`

Olculen URL'ler:

- `/m/6f3f0372-65a4-40ef-b915-da05908d98c7?lang=tr&theme=bold`
- `/qr/6f3f0372-65a4-40ef-b915-da05908d98c7?lang=tr&theme=bold` (unauthenticated QR gate)

Mobil Lighthouse:

- Public menu: Performance `94`, Accessibility `100`, Best Practices `96`, SEO `90`
- QR gate: Performance `96`, Accessibility `100`, Best Practices `96`, SEO `100`

Build output:

- `/m/[slug]` first load JS: `119 kB`
- `/qr/[businessId]` first load JS: `116 kB`
- Shared first load JS: `102 kB`
- Middleware bundle: `34.8 kB`

## Riskler ve Azaltma Yontemleri

Risk:

- Yetkisiz QR akisi tek hop `403` degil.

Azaltma:

- Final response `403` olarak sabitlenmistir; monitoring ve smoke checklist bu davranisi explicit kontrol eder.

Risk:

- Panel production env'de `BASE_URL_WEB_NEXT` set edilmezse localhost fallback olabilir.

Azaltma:

- Deploy checklist bunu zorunlu gate olarak tanimlar.

Risk:

- SQL patch uygulanmadan analytics zincirinde `500` geri gelebilir.

Azaltma:

- Migration release oncesi zorunlu adim olarak ayrildi, rollback icin fonksiyon DDL yedegi istendi.

## Surum Hazirlik Durumu

Mevcut durum: `READY WITH NOTES`

Notlar:

- Yetkisiz QR akisi `307 -> /forbidden -> 403`
- Production deploy oncesi migration ve live smoke tekrari zorunlu

## Onay Kontrol Listesi

- Product sign-off:
  - Ad / Tarih / Imza
- Engineering sign-off:
  - Ad / Tarih / Imza
- Surum onayi:
  - Ad / Tarih / Imza
- Veritabani veya Platform onayi:
  - Ad / Tarih / Imza

## Son Go/No-Go Sorulari

- Migration production'a uygulandi mi?
- `npm --prefix uygulamalar/web run build` PASS mi?
- `npm --prefix uygulamalar/web run test:e2e:live` PASS mi?
- `npm --prefix uygulamalar/web run lighthouse:mobile` guncel rapor uretti mi?
- Panel -> `Dijital Menu & QR` owner akisi production domain'de dogrulandi mi?


