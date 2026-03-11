# web_next A11y Polish - 2026-03-02

Bu dosya tarihsel release snapshot'idir. Kalici source-of-truth degildir.

Kalici kaynaklar:

- deploy modeli: `docs/deploy.md`
- smoke ve incident adimlari: `docs/runbook.md`
- web_next perf olcumu: `docs/web_next_perf.md`

## Ne Degisti

- QR gate icin acilan login ekranindaki form alanlari ve CTA hedef boyutlari buyutuldu.
- Submit butonu, panel login linki ve input alanlari `44x44` mobil hedef standardina yaklastirildi.
- QR Studio urunlestirme notlari dokumantasyona eklendi:
  - `preview=1`
  - `Reset to Default`
  - `Unsaved changes` guard
  - `runbook`

## Issue Durumu

- Lighthouse accessibility icindeki `target-size` bulgusu login gate yuzeyinden geliyor.
- Sorunlu element:
  - `/qr/:businessId` route'una guest ulasilinca acilan `/login` ekranindaki `Sign in` butonu
- UI hedef boyutlari buyutuldu ve Lighthouse scripti owner-auth QR Studio auditine zorlandi, ancak 2026-03-02 olcumunde rapor halen login gate final URL'i uzerinden `Accessibility 91` vermeye devam ediyor.

## Olcum

Calistirildi:

- `npm --prefix apps/web_next run typecheck`
- `npm --prefix apps/web_next run lint`
- `npm --prefix apps/web_next run build`
- `npm --prefix apps/web_next run test:e2e:live`
- `npm --prefix apps/web_next run lighthouse:mobile`

Sonuc:

- `/m/[slug]` first load JS: `109 kB`
- `/qr/[businessId]` first load JS: `110 kB`
- `/m` temalari: `Accessibility 100`
- `/qr/:businessId?theme=bold`: `Performance 99`, `Accessibility 91`, `Best Practices 96`, `SEO 100`

## Risk

- Davranis degisikligi yok.
- Yalnizca UI hedef boyutu ve dokunma alanlari buyutuldu.
- Acik not: Lighthouse halen login gate final URL'ini audit ettigi icin `target-size` issue kapanmis sayilamaz.
