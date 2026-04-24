# Yeedoy Kod ve Mimari Stil Rehberi

> Surum: 1.0 — Son guncelleme: 2026-04-08
> Bu belge ekip standardidir. PR review'da bu kurallara atifta bulunulabilir.
> Icerik mevcut koddan cikarilmistir; uydurma kural yoktur.

---

## 1. Genel Ilkeler

**Kural:** Mevcut deseni boz; yeni bir desen eklemek icin iki uygulama tarafinda da tekrar ettigini goster.

**Kural:** Her yeni abstraction, mevcut iki somut ornekle gerekcelendirilmelidir. Tek ornekle abstraction eklenmez.

**Kural:** Feature kodu monorepo sinirlarini korur: mobile'a owner/admin CRUD eklenemez, panel'e public SEO menu render eklenemez, web_next'e owner/admin CRUD eklenemez.

**Kural:** Supabase'e yazma islemleri repository katmanina girer; UI'dan `client.rpc()` veya `client.from()` ile dogrudan yazma yapilmaz.

---

## 2. Dart / Flutter Kurallari

### 2.1 Dosya ve Klasor Isimlendirmesi

**Kural:** Tum Dart dosyalari `snake_case.dart` formatinda adlandirilir.

**Kural:** Feature klasor yapisi sabit uclu ayrimdan olusur:
```
features/<feature_name>/
  data/       -- repository, remote/local data source, cache, IO
  domain/     -- model, provider, controller, state
  ui/         -- page, section, widget, sheet
```

**Kural:** Dosya tipi sufixlerle belirtilir:
- Sayfa dosyasi: `*_page.dart`
- Sheet dosyasi: `*_sheet.dart`
- Kart dosyasi: `*_card.dart`
- Provider/Controller: `*_provider.dart`, `*_controller.dart`
- Repository: `*_repository.dart`

**Neden:** IDE arama ve kod incelemesinde dosya tipini ek aciklama olmadan anlamak icin.

### 2.2 Sinif ve Widget Isimlendirmesi

**Kural:** Dart class, enum ve widget isimleri `PascalCase` olur.

**Kural:** Widget tipi sufixle belirtilir:
- Sayfa: `*Page` (ornek: `BusinessDetailPage`)
- Shell: `*Shell` (ornek: `PanelShell`)
- Section: `*Section` (ornek: `MenuItemSection`)
- Durum view'leri: `*EmptyState`, `*LoadingView`, `*ErrorView`

**Kural:** Mobile/panel primitive ailesi `App*` veya `Panel*` prefix'ini korur; rastgele yeni prefix uydurulmaz.
- Dogru: `AppButton`, `AppBadge`, `AppChip`, `PanelPageHeader`
- Yanlis: `YdButton`, `CustomBadge`

**Istisna:** Shared primitives icin once `packages/shared_ui_components` kontrol edilir; mevcut bir primitive varsa yeni kopya yazilmaz.

### 2.3 Repository Metodlari

**Kural:** Metod ismi okuma kaynagini acik gosterir:
- `get*` — yerel/cache'den okuma (ag cagrisi yapilmaz)
- `fetch*` — ag/Supabase'den okuma (her cagri RPC'ye gider)

**Neden:** Bu kurali ihlal eden metodlar gereksiz ag cagrisina veya stale data'ya neden olur. Bu oturumda yapilan yeniden isimlendirme karar budur.

**Ornek:**
```dart
// Dogru
Future<Business?> getCachedBusiness(String id); // yerel cache
Future<Business> fetchBusiness(String id);       // Supabase RPC

// Yanlis
Future<Business?> readBusiness(String id);       // kaynak belirsiz
Future<Business> loadBusiness(String id);        // kaynak belirsiz
```

### 2.4 State Yonetimi (Riverpod)

**Kural:** Provider adlari `Provider` sufixiyle biter:
```dart
sessionProvider
businessDetailRepositoryProvider
adminDashboardProvider
```

**Kural:** Controller sinifi `Controller` sufixiyle biter:
```dart
BusinessDetailController
AdminDashboardController
```

**Kural:** Repository sinifi `Repository` sufixiyle biter.

**Kural:** UI state yoneten Riverpod nesnesi controller veya provider olarak adlandirilir; `service` ismi state icin kullanilmaz.

**Kural:** Controller'lar ince kalir. Is mantigi repository'ye, UI state domain katmanina tasimir. Controller icinde dogrudan Supabase cagrisi acilmaz.

### 2.5 Widget Yapisi

**Kural:** Minimum hit target `44` px altina inmez.

**Kural:** Buyuk font scale (`1.3+`) altinda render bozulmamalidir; `LayoutBuilder` + `ConstrainedBox` tercih edilir.

**Kural:** `ScreenUtilInit` mobile'da acik kalir; genis yuzeylerde `720` ve `1040` max-width kalibi kullanilir.

**Kural:** Bos, hata ve loading yuzeyleri mevcut `AppEmptyState`, `AppSkeleton` kaliplarina oturur; inline yazilmaz.

---

## 3. Mimari Kurallar

### 3.1 Katman Sinirlari

**Kural:** Katman gecisleri tek yonludur: `UI -> domain -> data`. Ters yonde cagriya izin verilmez.

**Kural:** Yeni Supabase sorgusu `data/` klasorundeki repository'ye gider.

**Kural:** UI'da yeni `client.rpc()` veya `client.from()` acilmaz.

**Kural:** Legacy UI-local provider varsa dokunan yerde yeni ornek eklenmez; yeni kod `domain/` altina tasinir.

**Neden:** Katman sinirlari bozuldugunda test edilebilirlik duser ve Supabase sorgusu degistiginde kac yerde duzeltme yapilacagi belirsizlesir.

### 3.2 Part Dosyalari

**Kural:** Part dosyalari `part of '../xyz.dart'` formatinda taninir; relative path kullanilir.

**Kural:** Part dosyasinda import tekrarlanmaz; import'lar ana dosyada tanimlanir.

**Ornek:**
```dart
// ana dosya: business_detail_page.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
part 'sections/business_info_section.dart';

// part dosyasi: sections/business_info_section.dart
part of '../business_detail_page.dart';
// Burada import tekrar edilmez
```

### 3.3 Paylasimli Paketler

**Kural:** Iki veya daha fazla uygulamada tekrar eden primitive `packages/shared_ui_components` altina tasinir.

**Kural:** Iki veya daha fazla uygulamada tekrar eden model `packages/shared_models` altina tasinir.

**Kural:** Ortak ARB anahtarlari `packages/l10n_assets/common_en.arb` ve `common_tr.arb` dosyalarinda tutulur; her uygulamada tekrar yazilmaz.

**Istisna:** Yeni abstraction ancak mevcut iki uygulama tarafinda ayni primitive gercekten tekrar ediyorsa eklenir. Tek ornekle paket olusturulmaz.

---

## 4. Panel (Flutter Web) Ozel Kurallari

### 4.1 Sayfa Header Standardi (PanelPageHeader)

**Kural:** Tum owner ve admin sayfalari `PanelPageHeader` componentini kullanir.

**Kural:** Yeni panel sayfasi `PanelShell` disinda ayri layout kurmaz. Gecerli shell ailesi:
- `PanelShell`
- `PanelContentSurface`
- `PanelPageHeader`
- `PanelToolbar`
- `PanelSidebar`

**Neden:** Panel shell disinda layout kurmak sidebar collapse/drawer mantigini bozar ve responsive davranisti degistirir.

### 4.2 Admin Sayfalari

**Kural:** Admin listelerinde `AdminVirtualTableCard` kullanilir; dataset tamamini widget agacina yukleyen yaklasim secilmez.

**Kural:** Admin listeleri server-side pagination uzerinden calisir; istemci tarafinda yuzlerce satir cekip filtreleme yapilmaz.

**Kural:** Tekrarlanan sorgular icin bellek ici TTL cache kullanilir. Cache anahtarina filtre, offset ve limit parametreleri dahil edilir.

**Kural:** Write aksindan sonra ilgili cache prefix'i invalidate edilir; global cache wipe yapilmaz.

**Responsive kirilma noktalari:** `960`, `1160`, `1280`, `1520`

---

## 5. Lokalizasyon (L10n) Kurallari

**Kural:** ARB anahtari `lowerCamelCase` formatindadir.

**Kural:** Placeholder adi anlamli olmali:
- Dogru: `{businessName}`, `{tableNo}`, `{count}`
- Yanlis: `{x}`, `{value1}`

**Kural:** Ortak anahtarlar `packages/l10n_assets/common_en.arb` ve `common_tr.arb` dosyalarinda tutulur.

**Kural:** Yeni CTA metni inline widget'a yazilmaz; l10n kaynagina tasinir.

**Kural:** Status badge, chip ve tooltip metinleri lokalize edilir.

**Istisna:** Harici form/RPC kontratinda `snake_case` alani varsa (ornek: `access_token`, `refresh_token`) Dart tarafinda camelCase'e cevrilmez; kontrat oldugu gibi korunur.

---

## 6. Test Kurallari

**Kural:** Her yeni repository methodu icin birim testi yazilir.

**Kural:** Supabase cagrisi mock'lanir; gercek ag gerektiren testler `integration_test/` altina gider.

**Kural:** Panel browser smoke testleri Playwright ile `e2e/` altinda tutulur.

**Kural:** Golden test asset'i olmayan placeholder golden dosyasi eklenmez.

**Kural:** CI kapisi: analyze + test + build. Bu kapidan gecemeyen PR merge edilmez.

**Referans dosyalar:**
- `apps/mobile_flutter/integration_test/golden_paths_integration_test.dart`
- `apps/panel_flutter_web/test/`
- `.github/workflows/panel_quality.yml`

---

## 7. Git ve PR Kurallari

**Kural:** Commit mesaji ne yapildigini degil neden yapildigini anlatir.

**Kural:** PR icinde dosya degisikligi ve etkilenen test listesi belirtilir.

**Kural:** Secret, credential veya `.env` dosyasi commit'e dahil edilmez.

**Kural:** Yeni Supabase migration dosyasi adi: `YYYYMMDDHHMMSS_snake_case_aciklama.sql`

**Kural:** Edge function entry point: `supabase/functions/<name>/index.ts`

---

## 8. Yasak Pratikler (Anti-pattern Listesi)

| Yasak | Dogru Alternatif |
|---|---|
| UI'dan `client.rpc()` veya `client.from()` cagrisi | Repository metodunu cagir |
| `print()` kullanimi production kodunda | `debugPrint()` kullan |
| Inline hardcoded renk veya spacing | `AppColors`, `AppTokens` kullan |
| Raw hex kodu web'de | `tokens.css` CSS variable kullan |
| `service` ismi UI state Riverpod nesnesi icin | `provider` veya `controller` kullan |
| Panel shell disinda yeni owner/admin layout | `PanelShell` ve panel component ailesi kullan |
| Istemci tarafinda buyuk veri seti cekip filtreleme | Server-side pagination + RPC |
| Ortak primitive'i her uygulamaya yeniden yazma | `packages/shared_ui_components` kullan |
| Part dosyasinda import tekrari | Import'u ana dosyada tut |
| Feature sinirlarini asma (ornek: mobile'a admin CRUD) | Ilgili uygulamada kalmasini sagla |
| ARB anahtari olarak anlamsiz placeholder: `{x}` | Anlamli placeholder: `{businessName}` |
| Global cache wipe | Prefix bazli invalidation |
| Tek ornekle yeni abstraction paketi | Iki somut ornek gosterdikten sonra ekle |
