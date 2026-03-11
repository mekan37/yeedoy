# Web Next Performans Raporu

Bu dosya yalnizca `apps/web_next` performans notlarini tutar. `apps/panel_flutter_web` performans olcumleri icin tek kaynak `docs/panel_perf.md` dosyasidir.

Not: Tarihsel performans snapshot'larindaki ornek istek URL'leri UUID tabanli olabilir; bugunku canonical public route semantigi `/m/:publicSlugOrId` olup slug varsa final hedef slug path'idir.

Tarih: 2026-03-03T06:33:42.631Z
Commit: 4da7acf

## Build Ciktisi

- `/m/[slug]` first load JS: 109 kB
- `/qr/[businessId]` first load JS: 110 kB

## Public Menu Lighthouse

| Senaryo | Requested URL | Final URL | Performance | Accessibility | Best Practices | SEO | FCP | LCP | TBT | CLS | Speed Index |
|---|---|---|---:|---:|---:|---:|---|---|---|---|---|
| /m/:publicSlugOrId?theme=minimal | `/m/6f3f0372-65a4-40ef-b915-da05908d98c7?lang=tr&theme=minimal` | `/m/6f3f0372-65a4-40ef-b915-da05908d98c7?lang=tr&theme=minimal` | 91 | 100 | 96 | 90 | 1.2 s | 2.4 s | 180 ms | 0.005 | 5.2 s |
| /m/:publicSlugOrId?theme=photo-heavy | `/m/6f3f0372-65a4-40ef-b915-da05908d98c7?lang=tr&theme=photo-heavy` | `/m/6f3f0372-65a4-40ef-b915-da05908d98c7?lang=tr&theme=photo-heavy` | 94 | 100 | 96 | 90 | 1.2 s | 2.5 s | 220 ms | 0.006 | 1.4 s |
| /m/:publicSlugOrId?theme=dark-modern | `/m/6f3f0372-65a4-40ef-b915-da05908d98c7?lang=tr&theme=dark-modern` | `/m/6f3f0372-65a4-40ef-b915-da05908d98c7?lang=tr&theme=dark-modern` | 95 | 100 | 96 | 90 | 1.2 s | 2.5 s | 170 ms | 0.006 | 1.4 s |

## Login Gate Lighthouse

| Senaryo | Requested URL | Final URL | Performance | Accessibility | Best Practices | SEO | FCP | LCP | TBT | CLS | Speed Index |
|---|---|---|---:|---:|---:|---:|---|---|---|---|---|
| /login?redirect=/qr/:businessId | `/login?redirect=%2Fqr%2F6f3f0372-65a4-40ef-b915-da05908d98c7%3Flang%3Dtr%26theme%3Dbold` | `/login?redirect=%2Fqr%2F6f3f0372-65a4-40ef-b915-da05908d98c7%3Flang%3Dtr%26theme%3Dbold` | 97 | 100 | 96 | 100 | 1.2 s | 2.4 s | 70 ms | 0 | 1.2 s |

## Authenticated QR Studio Lighthouse

| Senaryo | Requested URL | Final URL | Performance | Accessibility | Best Practices | SEO | FCP | LCP | TBT | CLS | Speed Index |
|---|---|---|---:|---:|---:|---:|---|---|---|---|---|
| /qr/:businessId?theme=bold (authenticated) | `/qr/d40c3d0b-c5b6-437c-8e0e-e60acc80b859?lang=tr&theme=bold` | `/qr/d40c3d0b-c5b6-437c-8e0e-e60acc80b859?lang=tr&theme=bold` | 97 | 98 | 100 | 100 | 0.7 s | 0.9 s | 190 ms | 0 | 1.1 s |

## Target-Size Closure

- Login Gate:
  0 aktif node, hedef skor 100
- Authenticated QR Studio:
  0 aktif node, hedef skor 98
- Kapanan yuzeyler:
  Public menu senaryolari `Accessibility 100` ile temiz.
- Kalan odak:
  kalan QR Studio target-size node yok

## Bundle Audit

Analyzer raporlari:
- `apps/web_next/reports/bundle/latest/client.html`
- `apps/web_next/reports/bundle/latest/nodejs.html`
- `apps/web_next/reports/bundle/latest/edge.html`

## Kok Neden ve Uygulanan Duzeltmeler

Bu snapshot'a gelene kadar yapilan inceleme sonucu minimal tema regresyonunun temel nedeni LCP image discovery degil, client baslangic bundle'i ve render gecikmesiydi.

Ana bulgular:

- `presentation-view.ts`
- `presentation-accent.ts`
- `templates/registry.ts`
- `templates/schema.ts`

zinciri ortak chunk'a siziyor ve hem public menu hem QR Studio ilk yuklemesine maliyet ekliyordu.

Ek maliyet yuzeyleri:

- `public-menu-client.tsx`
- `qr-generator.tsx`
- client bundle'a sizan i18n string tablolari

Bu soruna karsi yapilan ana duzeltmeler:

1. Client'a tasinan string tablolar server prop'a cekildi.
2. Theme definition ve blur placeholder verileri server tarafinda resolve edildi.
3. Template fallback lookup, agir registry zinciri yerine daha hafif statik map ile kuruldu.
4. QR branding ve menu detail alt akislarinda lazy split korundu.

Sonuc:

- `/m/[slug]` first load JS `138 kB` -> `109 kB`
- `/qr/[businessId]` first load JS `138 kB` -> `110 kB`
- `minimal` Lighthouse `88` -> `91+`
- `Authenticated QR Studio` Lighthouse `97`

## Artefact'lar

- `apps/web_next/reports/lighthouse/latest/menu-minimal.report.html`
- `apps/web_next/reports/lighthouse/latest/menu-photo-heavy.report.html`
- `apps/web_next/reports/lighthouse/latest/menu-dark-modern.report.html`
- `apps/web_next/reports/lighthouse/latest/login.report.html`
- `apps/web_next/reports/lighthouse/latest/qr-auth.report.html`

## Not

Detayli onceki inceleme notlari artik bu dosyaya tasinmistir. Ayrik `docs/perf_investigation.md` korunmaz.
