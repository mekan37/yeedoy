# Panel Tools Envanteri

Bu doküman `apps/panel_flutter_web` için aktif yardımcı script envanteridir.

## Durum Özeti

- `apps/panel_flutter_web/tools/`: Dosya yok. Ayrı bir aktif `tools/` klasoru kullanilmiyor.
- `apps/panel_flutter_web/tool/`: Aktif manuel denetim ve yuk scriptleri burada.
- Repo kokunde istemci bazli workflow omurgasi artik vardir:
  - `.github/workflows/mobile_quality.yml`
  - `.github/workflows/mobile_readiness.yml`
  - `.github/workflows/panel_quality.yml`
  - `.github/workflows/web_quality.yml`
- Mobile signed release tarafinda yeni ek denetim araci:
  - `apps/mobile_flutter/tool/ios_signing_assets_check.dart`
- `mobile_readiness` workflow'u signed iOS IPA ve Android APK artifact'larini run ciktisi olarak yukleyebilir.
- Panel `tool/` scriptleri artik yalnizca lokal degil; `panel_quality` workflow'u icinde de quality gate olarak kosulur.

## Scriptler

### `apps/panel_flutter_web/tool/api_version_gate_check.dart`

- Amac: `rpc('...')` cagrilarinda versiyon suffix'i (`_v1`, `_v2`) zorunlulugunu denetler.
- Nasil calistirilir:

```powershell
cd apps/panel_flutter_web
dart run tool/api_version_gate_check.dart
```

- Input/env: Yok.
- Output:
  - `API_VERSION_GATE: PASS`
  - veya `API_VERSION_GATE: BLOCK` ve ihlalli dosya listesi
- Tetikleyen yer:
  - Kod tarafindan import edilmez.
  - `package.json` icinde script olarak bagli degil.
  - Repo-root `panel_quality` workflow'u icinde kalite kapisi olarak kosulur.
- Uretim/release gerekliligi: Build icin zorunlu degil, fakat release hijyeni acisindan korunmali.

### `apps/panel_flutter_web/tool/security_review_check.dart`

- Amac: Yetkisiz katmanlarda dogrudan DB write ve kritik RPC kullanimlarini tarar.
- Nasil calistirilir:

```powershell
cd apps/panel_flutter_web
dart run tool/security_review_check.dart
dart run tool/security_review_check.dart --strict
```

- Input/env:
  - Opsiyonel `--strict`
- Output:
  - `SECURITY_REVIEW: PASS`
  - veya `SECURITY_REVIEW: FINDINGS`
- Tetikleyen yer:
  - Kod tarafindan import edilmez.
  - `package.json` icinde script olarak bagli degil.
  - Repo-root `panel_quality` workflow'u icinde `--strict` moduyla release kapisi olarak kosulur.
- Uretim/release gerekliligi: Runtime icin zorunlu degil, fakat audit/release sureci icin yararlidir.

### `apps/panel_flutter_web/tool/load/k6_home_search_business.js`

- Amac: Edge function tabanli `home-feed`, `search-businesses` ve `business-detail` akislarina temel k6 yuk testi uygular.
- Nasil calistirilir:

```powershell
cd apps/panel_flutter_web
k6 run tool/load/k6_home_search_business.js -e BASE_URL=https://<edge-base-url> -e AUTH_HEADER="Bearer <token>" -e BUSINESS_ID=<uuid>
```

- Input/env:
  - `BASE_URL`
  - `AUTH_HEADER`
  - `BUSINESS_ID`
- Output:
  - k6 latency, threshold ve check raporu
- Tetikleyen yer:
  - Kod tarafindan import edilmez.
  - `package.json` icinde script olarak bagli degil.
  - Manuel performans/profiling yardimcisi olarak kullanilir.
- Uretim/release gerekliligi: Zorunlu degil, ancak operasyonel perf takibi icin korunmali.

## Kaldirilan Tekrar Dokumanlari

Asagidaki dosyalar tek kaynak kuralina gecmek icin kaldirildi:

- `apps/panel_flutter_web/tool/README_release_gate.md`
- `apps/panel_flutter_web/tool/README_qa_strategy.md`

Bu icerik artik:

- `docs/tools_inventory.md`
- `docs/test_strategy.md`

dosyalarinda tutulur.

## Son Dogrulama

- Tarih: `2026-03-09`
- Durum: `apps/panel_flutter_web/tool/` altindaki aktif scriptler yeniden tarandi.
- Sonuc: Ek olarak kaldirilacak script bulunmadi; `api_version_gate_check.dart`, `security_review_check.dart` ve `load/k6_home_search_business.js` halen anlamli kalite kapilari olarak korunuyor. `api_version_gate_check.dart` ve `security_review_check.dart` artik repo-root `panel_quality` workflow'u ile merkezi CI omurgasina bagli.
