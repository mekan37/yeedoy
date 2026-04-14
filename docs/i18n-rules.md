# Yeedoy I18n Kurallari

## 1. Mevcut Yapi

### Flutter app'ler

- Mobile: `apps/mobile_flutter/lib/l10n/app_en.arb`, `app_tr.arb`
- Panel: `apps/panel_flutter_web/lib/l10n/app_en.arb`, `app_tr.arb`
- Uretilen siniflar: `AppLocalizations`

### Ortak Flutter key havuzu

- `packages/l10n_assets/common_en.arb`
- `packages/l10n_assets/common_tr.arb`
- senkron script: `packages/l10n_assets/scripts/sync-l10n.mjs`

### Web

- Public menu copy kaynagi: `apps/web_next/src/lib/i18n.ts`
- Bazi sabit link/copy dosyalari: `apps/web_next/src/lib/legal-links.ts`

## 2. Mevcut Sayisal Durum

Repo taramasina gore:

- mobile EN key sayisi: `1092`
- panel EN key sayisi: `1537`
- ortak EN key sayisi: `64`
- ayni EN degeri tasiyan ortak key: `62`
- hala farkli EN degeri tasiyan ortak key: `2`

Bu iki farkli EN key:
- `legalCopyrightIntro`
- `legalOwnershipAppealIntro`

## 3. Kanonik Kural

### Flutter

- Yeni kullanici metni ARB disinda yazilmaz.
- Key iki Flutter app'te de kullanilacaksa once `common_*.arb` guncellenir.
- Sonra:

```bash
node packages/l10n_assets/scripts/sync-l10n.mjs
node tools/l10n_audit.mjs
```

- Gerekirse her app'te `flutter gen-l10n` yenilenir.

### Web

- Yeni public web copy'si component icine inline yazilmaz.
- `apps/web_next/src/lib/i18n.ts` icindeki `copy.tr` / `copy.en` yapisi genisletilir.
- Sabit legal/dis baglanti etiketleri ilgili merkezi dosyada tutulur.

## 4. Mikro Kopya Standardi

Panelde mevcut kanonik fiiller `MicrocopyStyleGuide` ile korunuyor:

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

- Panel ve mobile icinde hala cok sayida inline Turkce/English string var.
- `apps/panel_flutter_web/lib/shared/ui/components/status_badge.dart` hala sabit English label kullaniyor.
- `apps/web_next/src/ui/sections/public-menu-client.tsx` icinde lokalize edilmeyen metinler var.
- `apps/web_next/app/auth/panel-handoff/route.ts` HTML fallback metni i18n katmani disinda.

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
node tools/l10n_audit.mjs
```

Flutter key degisimi iki app'i etkiliyorsa:

```bash
node packages/l10n_assets/scripts/sync-l10n.mjs
```
