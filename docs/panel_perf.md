# Panel Perf Report

Bu rapor `panel_flutter_web` için sprint bazlı web release performans takibi içindir. Her sprint sonunda aynı ölçüm komutlarıyla güncellenmelidir.

## Snapshot

- Date: `2026-03-04`
- Commit: `4da7acf`
- App: `apps/panel_flutter_web`

## Perf Budget

| Surface | Budget | Current | Status |
| --- | ---: | ---: | --- |
| Owner `main.dart.js` | `< 4,200,000` bytes | `4,624,648` bytes | Over budget |
| Admin `main.dart.js` | `< 4,000,000` bytes | `4,234,652` bytes | Over budget |

## Build Commands

```powershell
flutter build web --release --target lib/main_web_owner.dart --dart-define=DEV_TOOLS_ENABLED=false
flutter build web --release --target lib/main_web_admin.dart --dart-define=DEV_TOOLS_ENABLED=false
```

## Owner Release Metrics

| Metric | Value |
| --- | ---: |
| `main.dart.js` | `4,624,648` bytes |
| Total `build/web` | `38,316,771` bytes |

### Top 10 Chunks

| Rank | File | Size (bytes) |
| --- | --- | ---: |
| 1 | `main.dart.js_18.part.js` | `532,437` |
| 2 | `main.dart.js_20.part.js` | `532,259` |
| 3 | `main.dart.js_19.part.js` | `532,259` |
| 4 | `main.dart.js_31.part.js` | `125,250` |
| 5 | `main.dart.js_27.part.js` | `125,230` |
| 6 | `main.dart.js_23.part.js` | `125,071` |
| 7 | `main.dart.js_55.part.js` | `92,263` |
| 8 | `main.dart.js_69.part.js` | `70,939` |
| 9 | `main.dart.js_58.part.js` | `70,928` |
| 10 | `main.dart.js_64.part.js` | `61,966` |

## Admin Release Metrics

| Metric | Value |
| --- | ---: |
| `main.dart.js` | `4,234,652` bytes |
| Total `build/web` | `38,116,879` bytes |

### Top 10 Chunks

| Rank | File | Size (bytes) |
| --- | --- | ---: |
| 1 | `main.dart.js_18.part.js` | `532,437` |
| 2 | `main.dart.js_20.part.js` | `532,259` |
| 3 | `main.dart.js_19.part.js` | `532,259` |
| 4 | `main.dart.js_31.part.js` | `125,250` |
| 5 | `main.dart.js_27.part.js` | `125,230` |
| 6 | `main.dart.js_23.part.js` | `125,071` |
| 7 | `main.dart.js_55.part.js` | `92,263` |
| 8 | `main.dart.js_69.part.js` | `70,939` |
| 9 | `main.dart.js_58.part.js` | `70,928` |
| 10 | `main.dart.js_64.part.js` | `61,966` |

## Notes

- Owner build budget aşımı: `+424,648` bytes.
- Admin build budget aşımı: `+234,652` bytes.
- Owner ile admin arasındaki `main.dart.js` farkı: `389,996` bytes.
- Build sırasında bloklamayan bir font uyarısı var: `CupertinoIcons` family referansı asset olarak bulunmuyor.
- Owner build wasm dry-run uyarısı `image` paketinden geliyor; admin build wasm dry-run başarılı.
- Gercek `AdminVirtualTableCard` sanallastirmasi bugun yalnizca `/admin/business-submissions` ekraninda aktiftir. Diger admin listeleri icin tam satir sanallastirmasi henuz yoktur.

## Bu Sprintteki Delta

Önceki snapshot ile karşılaştırma:

| Surface | Önceki `main.dart.js` | Güncel `main.dart.js` | Delta |
| --- | ---: | ---: | ---: |
| Owner | `4,681,752` | `4,624,648` | `-57,104` |
| Admin | `4,159,017` | `4,234,652` | `+75,635` |

Yorum:

- owner tarafında ek route-level deferred import (`/owner/analytics`) ilk yük JS'ini anlamlı biçimde düşürdü
- admin tarafında `AdminVirtualTable`, yeni pagination akışı ve ek chunk sınırları toplam bundle dağılımını değiştirdi; ilk yük JS'i bütçe altına inmedi
- toplam `build/web` boyutu, daha fazla deferred parça ve yeni liste altyapısı nedeniyle arttı; bu metrik tek başına ilk yük maliyetini temsil etmez

## Runtime ve Ölçek Notları

Ölçek kararlarının ayrıntılı teknik kaydı `docs/panel_scale.md` içinde tutulur. Bu dosya yalnızca ölçüm snapshot'ını ve budget durumunu taşır.

Aktif lazy split envanteri ve embed provider split stratejisi de `docs/panel_scale.md` icinde tutulur.

## Recommended Next 3 Moves

1. `AdminVirtualTableCard` standardını `queue`, `reports`, `claims` ve `businesses` ekranlarına yay.
2. En büyük shared chunk blokları için feature attribution çıkar; `pdf`, `qr_flutter`, `webview_flutter`, `youtube_player_iframe`, `share_plus` ve admin moderation kodu hangi boundary içinde kaldığını netleştir.
3. `CupertinoIcons` referansını ya gerçekten ekle ya da kaldır; ardından font ve icon dependency yüzeyini tekrar ölç.

## Update Rule

- Bu dosya her sprint sonunda yeni tarih, commit ve ölçümlerle güncellenmeli.
- Budget aşımı varsa ilgili PR veya sprint raporunda sebep ve plan notu bırakılmalı.
