# Yeedoy Adlandirma ve Stil Rehberi

Bu dosya `docs/naming-conventions.md` ve `docs/style-guide.md` kaynaklarinin birlestirilmis halidir.
Taban repo icin kanonik tasarim dili ve isimlendirme kurallarini icerir; uydurma degil, mevcut koddan cikarilmis halidir.

---

## 1. Dosya ve Klasor Isimlendirmesi

### Dart / Flutter

- Dosya adi: `snake_case.dart`
- Feature klasoru: `features/<feature_name>/data|domain|ui`
- Widget dosyalari:
  - sayfa: `*_page.dart`
  - sheet: `*_sheet.dart`
  - card: `*_card.dart`
  - provider/controller: `*_provider.dart`, `*_controller.dart`
  - repository: `*_repository.dart`

### TypeScript / Next

- Dosya adi: `kebab-case.ts` / `kebab-case.tsx`
- Route dosyalari framework standardini korur:
  - `page.tsx`
  - `layout.tsx`
  - `route.ts`
- Helper dosyalari anlam tabanli olur:
  - `menu-read.ts`
  - `public-menu-page.ts`
  - `presentation-settings.ts`

### SQL

- Migration: `YYYYMMDDHHMMSS_or_YYYYMMDD_..._snake_case.sql`
- Edge function entry: `supabase/functions/<name>/index.ts`

---

## 2. Tip ve Sinif Isimlendirmesi

- Dart class/enum/widget: `PascalCase`
- TS type/interface/component: `PascalCase`
- Hook/helper/function: `camelCase`
- Private Dart sabiti: `_camelCase`
- Private TS sabiti: `camelCase` veya `const` local helper

---

## 3. Riverpod Isimlendirmesi

- Provider adlari `Provider` ile biter:
  - `sessionProvider`
  - `businessDetailRepositoryProvider`
  - `adminDashboardProvider`
- Controller sinifi `Controller` ile biter:
  - `BusinessDetailController`
  - `AdminDashboardController`
- Repository sinifi `Repository` ile biter.

Kural:
- UI state yoneten Riverpod nesnesi controller/provider olarak adlandirilir; `service` ismi state icin kullanilmaz.

---

## 4. UI Bilesenleri Isimlendirmesi

- Sayfa: `*Page`
- Shell: `*Shell`
- Section: `*Section` veya `*_sections.dart`
- Primitive: `App*` veya `Panel*`
- Durum view'leri: `*StateView`, `*EmptyState`, `*LoadingView`, `*ErrorView`

Kural:
- Mobile/panel primitive ailesi `App*` veya `Panel*` cizgisini korur; rastgele yeni prefix uydurulmaz.

---

## 5. I18n ve API Alan Adlari

- ARB key: `lowerCamelCase`
- Placeholder adi anlamli olur:
  - iyi: `{businessName}`, `{tableNo}`, `{count}`
  - kotu: `{x}`, `{value1}`

Kontrat kurali:
- Ic Dart/TS API'lerinde mevcut desen `camelCase`
- Mevcut harici form/RPC kontrati `snake_case` ise korunur
  - ornek: `/auth/panel-handoff` form alanlari `access_token`, `refresh_token`, `business_id`

---

## 6. Kanonik Terimler

- Public menu slug yolu: `publicSlug` / `public_slug` alanindan tureyen canonical path
- Owner/admin yetki kontrolu: `canManageBusiness*`, `currentUserRole*`
- Shared localization: `common_en.arb`, `common_tr.arb`
- Template secimi: `templateKey`

Yeni isimler bu mevcut sozlugu bozmayacak sekilde secilir.

---

## 7. Token Kaynaklari

### Flutter source-of-truth

- `uygulamalar/mobil/lib/app/theme/colors.dart`
- `uygulamalar/mobil/lib/app/theme/app_tokens.dart`
- `uygulamalar/mobil/lib/app/theme/app_typography.dart`
- `uygulamalar/mobil/lib/app/theme/app_theme.dart`

### Web aynasi

- `uygulamalar/web/src/styles/tokens.css`
- `uygulamalar/web/src/styles/globals.css`
- `uygulamalar/web/tailwind.config.js`

Kural:
- Flutter'da `AppColors` ve `AppTokens` disinda yeni sabit renk/spacing/radius kullanma.
- Web'de token degiskenlerini semantik Tailwind siniflariyla kullan; raw hex ekleme.

---

## 8. Tipografi ve Marka

- Font ailesi `Sora` olarak korunur.
- Marka paleti koyu kirmizi/wine + slate tabanlidir.
- Flutter `AppTypographyX` uzantilarini, web ise `font-black`, `text-textStrong`, `text-muted` cizgisini izler.

---

## 9. Flutter UI Standarti

- Shared primitive'ler icin once `packages/shared_ui_components` bak:
  - `AppTokens`
  - `AppColors`
  - `AppSkeleton`
  - `AppFilterChip`
- Mobile ve panelde ayni primitive zaten varsa ucuncu kopya yazma.
- `AppButton`, `AppBadge`, `AppChip`, `AppEmptyState` cizgisi korunur.
- Minimum hit target `44` alti inmez.
- Buyuk font scale (`1.3+`) altinda render bozulmamali.

---

## 10. Panel UI Standarti

- Owner/admin shell yeni `panel_*` component ailesi uzerinden ilerler:
  - `PanelShell`
  - `PanelContentSurface`
  - `PanelPageHeader`
  - `PanelToolbar`
  - `PanelSidebar`
- Yeni panel ekranlari bu shell disinda ayri layout kurmamalidir.
- Owner baglamli ekranlarda secili business context korunur.

---

## 11. Web UI Standarti

- Public menu ve QR yuzeyi `tokens.css` + Tailwind semantic class'lariyla yazilir.
- Layout mobile-first olmalidir; `max-w-*`, `sm:`, `md:`, `lg:`, `xl:` ile kademeli acilir.
- Interaktif client adaciklari `startTransition`, `useDeferredValue` gibi mevcut React 19 kaliplariyla yazilir.
- Web tarafinda yeni global state kutuphanesi eklenmez.

---

## 12. Responsive Kurallari

### Mobile Flutter

- `ScreenUtilInit` acik kalir.
- Genis yuzeylerde `720` ve `1040` max-width kalibi baskindir.
- `LayoutBuilder` + `ConstrainedBox` tercih edilir.

### Panel Flutter Web

- `960`, `1160`, `1280`, `1520` esitleri etrafinda kademeli shell davranisi vardir.
- Sidebar collapse/drawer mantigi korunur.

### Web Next

- Public menu root container `max-w-7xl` cizgisindedir.
- Sticky category bar ve detail sheet davranisi korunur.

---

## 13. Copy ve Durum Yuzeyleri

- Bos, hata ve loading yuzeyleri mevcut `AppEmptyState`, `OwnerPanelFeedback`, `AppSkeleton` kaliplarina oturur.
- Yeni CTA metni inline yazilmaz; l10n kaynagina tasinir.
- Status badge, chip ve tooltip metinleri lokalize edilir.

---

## 14. Standardizasyon Hedefi

En guvenli hedef:
- Flutter primitive tekrarlarini `packages/shared_ui_components` cizgisine yaklastir.
- Web tokenlarini local `tokens.css` uzerinden surdur.
- Panel shell disindaki yeni owner/admin layout denemelerini durdur.

Yeni abstraction ancak mevcut iki uygulama tarafinda ayni primitive gercekten tekrar ediyorsa eklenir.
