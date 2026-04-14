# Release Dokumanlari Indeksi

Bu dizin altindaki belgeler tarihsel release snapshot kayitlaridir. Kalici source-of-truth degildir.

Kalici operasyon kaynaklari:

- deploy modeli ve env sozlesmesi: `docs/deploy.md`
- smoke ve incident adimlari: `docs/runbook.md`
- web_next perf snapshot'i: `docs/web_next_perf.md`
- panel perf snapshot'i: `docs/panel_perf.md`

## Tarihsel Release Belgeleri

### `docs/release/web_next_release_20260228.md`

- Kapsam: ilk production-ready release toplama notlari
- Icerik: build, smoke, security ve perf kapanis ozeti

### `docs/release/web_next_a11y_polish_20260302.md`

- Kapsam: QR gate/login a11y ve target-size polish turu
- Icerik: Lighthouse bulgulari, mobil hedef boyutu kapanislari, kalan riskler

### `docs/release/web_next_production_release_20260303.md`

- Kapsam: production release snapshot'i
- Icerik: bundle, Lighthouse, smoke ve release sonucu

## Kullanim Kurali

- Yeni release raporu yazilacaksa bu dizine tarihli snapshot olarak eklenir.
- Ayni bilgiyi tekrar `deploy.md` veya `runbook.md` icine kopyalamayin.
- Operasyonel karar alirken once kalici kaynaklara, sonra gerekirse tarihsel snapshot'lara bakilmalidir.
