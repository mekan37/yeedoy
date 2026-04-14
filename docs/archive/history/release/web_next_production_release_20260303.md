# web_next Production Release 20260303

Bu dosya tarihsel release snapshot'idir. Kalici source-of-truth degildir.

Kalici kaynaklar:

- deploy modeli: `docs/deploy.md`
- smoke ve incident adimlari: `docs/runbook.md`
- web_next perf olcumu: `docs/web_next_perf.md`

## Urun Ozeti

Bu release, `apps/web_next` uygulamasini production dagitimi icin tamamlar: public restoran menusu, owner/admin yetkili QR Studio, business bazli kalici template ve branding ayarlari, kayitsiz `preview=1` canli onizleme, `Reset to Default`, secure media upload, SEO ve analytics katmani aktif; owner/admin CRUD akislarinin tamami panelde kalir.

## Bu Release'de Neler Var?

- `business_menu_presentation_settings` tablosu ile business bazli kalici template ve branding ayarlari
- `minimal`, `bold`, `elegant`, `photo-heavy`, `dark-modern` olmak uzere 5 template
- secure upload akisi, mime/size/path validasyonu ve `updated_at` tabanli cache bust
- analytics mapping, `/api/track` hardening ve `/q/:shortCode` edge redirect zinciri
- performans optimizasyonlari ile first load JS:
  - `/m/[slug]`: `109 kB`
  - `/qr/[businessId]`: `110 kB`
- a11y closure:
  - Login Gate Accessibility: `100`
  - Authenticated QR Studio Accessibility: `98`
  - target-size aktif node: `0`

## Olcumler

Kaynak: `docs/web_next_perf.md`

### Build

- `/m/[slug]` first load JS: `109 kB`
- `/qr/[businessId]` first load JS: `110 kB`

### Public Menu Lighthouse

- `/m/:businessId?theme=minimal`
  - Performance: `91`
  - Accessibility: `100`
  - Best Practices: `96`
  - SEO: `90`
- `/m/:businessId?theme=photo-heavy`
  - Performance: `94`
  - Accessibility: `100`
  - Best Practices: `96`
  - SEO: `90`
- `/m/:businessId?theme=dark-modern`
  - Performance: `95`
  - Accessibility: `100`
  - Best Practices: `96`
  - SEO: `90`

### Login Gate Lighthouse

- `/login?redirect=/qr/:businessId`
  - Performance: `97`
  - Accessibility: `100`
  - Best Practices: `96`
  - SEO: `100`

### Authenticated QR Studio Lighthouse

- `/qr/:businessId?theme=bold`
  - Performance: `97`
  - Accessibility: `98`
  - Best Practices: `100`
  - SEO: `100`

## Riskler ve Mitigasyon

- Panel env hatasi:
  - `BASE_URL_WEB_NEXT` veya `NEXT_PUBLIC_PANEL_URL` yanlis ya da bos kalirsa panel owner butonlari `localhost` fallback'ine dusebilir.
  - Mitigasyon: deploy oncesi panel ve web env'leri birlikte dogrulanmali.
- Unauthorized QR davranisi:
  - `/qr/:businessId` yetkisiz kullanici icin login redirect veya final `403` uretir.
  - Mitigasyon: post-deploy smoke'ta hem yetkili hem yetkisiz senaryo kontrol edilmeli.
- Analytics zinciri:
  - `/api/track` ve `log_event_v1` uyumsuzlugu tekrar olusursa izleme metriklerinde hemen gorulur.
  - Mitigasyon: `invalid_event` oraninin `0` oldugu deploy sonrasi teyit edilmeli.
- Upload zinciri:
  - Mime/size/path validation ihlallerinde save akisi etkilenebilir.
  - Mitigasyon: logo/background upload smoke senaryosu zorunlu tutulmali.

## Onay

- [ ] Product owner onayi
- [ ] Engineering onayi
- [ ] QA smoke onayi
- [ ] Analytics/ops izleme onayi
- [ ] Production deploy onayi
