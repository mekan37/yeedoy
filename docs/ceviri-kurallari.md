# Yeedoy I18n Kurallari

## 1. Mevcut Yapi

### Flutter app

- Mobile: `uygulamalar/mobil/lib/l10n/app_en.arb`, `app_tr.arb`
- Uretilen siniflar: `AppLocalizations`

### Ortak Flutter key havuzu

- `packages/l10n_assets/common_en.arb`
- `packages/l10n_assets/common_tr.arb`
- senkron script: `packages/l10n_assets/scripts/sync-l10n.mjs`

### Web

- Public menu copy kaynagi: `uygulamalar/web/src/lib/i18n.ts`
- Bazi sabit link/copy dosyalari: `uygulamalar/web/src/lib/yasal-links.ts`

## 2. Mevcut Sayisal Durum

Repo taramasina gore:

- mobile EN key sayisi: `1092`
- ortak EN key sayisi: `64`
- ayni EN degeri tasiyan ortak key: `62`
- hala farkli EN degeri tasiyan ortak key: `2`

Bu iki farkli EN key:
- `legalCopyrightIntro`
- `legalOwnershipAppealIntro`

## 3. Kanonik Kural

### Flutter

- Yeni kullanici metni ARB disinda yazilmaz.
- Key ortak Flutter paketlerinde kullanilacaksa once `common_*.arb` guncellenir.
- Sonra:

```bash
node packages/l10n_assets/scripts/sync-l10n.mjs
node tools/ceviri-denetimi.mjs
```

- Gerekirse her app'te `flutter gen-l10n` yenilenir.

### Web

- Yeni public web copy'si component icine inline yazilmaz.
- `uygulamalar/web/src/lib/i18n.ts` icindeki `copy.tr` / `copy.en` yapisi genisletilir.
- Sabit legal/dis baglanti etiketleri ilgili merkezi dosyada tutulur.

## 4. Mikro Kopya Standardi

Mevcut kanonik fiiller:

- `Kaydet`
- `Vazgeç`
- `Tekrar dene`
- `Onayla`
- `Reddet`
- `Sil`
- `Kapat`

Safest standardization target:
- kritik CTA fiilleri Flutter app'lerde bu sozluk etrafinda hizalanir

## 5. Mevcut Tutarsizliklar

- Mobile icinde hala inline Turkce/English string borcu bulunabilir.
- `uygulamalar/web/src/ui/sections/public-menu-client.tsx` icinde lokalize edilmeyen metinler var.

Kural:
- Yeni is bu borcu buyutmez.
- Dokunulan ekranda yeni string eklemek yerine once mevcut merkezi kaynaga tasinir.

## 6. Placeholder ve Key Kalitesi

- Key'ler `lowerCamelCase` olmali.
- Placeholder adlari anlamsal olmali: `{count}`, `{businessName}`, `{error}`
- Ayni anlam icin farkli key acma; mevcut key ara ve tekrar kullan.
- App'e ozel key gerekiyorsa prefix ile baglam ver:
  - `owner*`
  - `admin*`
  - `tasteTwin*`

## 7. Validation

I18n degisikliginden sonra minimum:

```bash
node tools/ceviri-denetimi.mjs
```

Flutter key degisimi iki app'i etkiliyorsa:

```bash
node packages/l10n_assets/scripts/sync-l10n.mjs
```

