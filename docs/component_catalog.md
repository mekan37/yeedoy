# Yeedoy Bileşen Kataloğu

> **Amaç:** Hangi shared component nerede tanımlanmış, nerede kullanılıyor?  
> **Son Güncelleme:** 2026-04-22  
> **Kaynak:** `packages/shared_ui_components` + `packages/shared_models`

---

## 1. Flutter Shared Bileşenler (`packages/shared_ui_components`)

### Renk & Token Sistemi

| Dosya | Dışa Aktarılan | Açıklama |
|-------|----------------|----------|
| `src/colors.dart` | `AppColors`, `AppPalette` | Tüm semantik renkler (primary, text, surface, status) |
| `src/dark_colors.dart` | `AppDarkColors` | Dark mode semantik renkler (parallel set) |
| `src/app_tokens.dart` | `AppTokens` | Spacing, radius, elevation, duration token'ları |
| `src/app_typography.dart` | `buildAppTextTheme()` | Sora font text theme |

### Temel Bileşenler

| Bileşen | Dosya | Kullanım Yerleri |
|---------|-------|-----------------|
| `AppCard` | `src/app_card.dart` | Mobile: discovery, business detail, menu item; Panel: PanelSectionCard içinde |
| `AppSkeletonCard` | `src/app_skeleton_card.dart` | Mobile loading states |
| `AppSkeletonLine` | `src/app_skeleton_line.dart` | Inline text skeleton |
| `AppSkeletonBox` | `src/app_skeleton_box.dart` | Image placeholder skeleton |
| `AppEmptyState` | `src/app_empty_state.dart` | Mobile boş liste durumları (45+ kullanım) |
| `AppChip` | `src/app_chip.dart` | Filter chips, status badges |
| `AppRatingBar` | `src/app_rating_bar.dart` | Yıldız gösterimi (read-only ve interactive) |
| `AppStarPicker` | `src/app_star_picker.dart` | Review yazma — 1-5 yıldız seçici |

---

## 2. Panel Flutter Web Bileşenleri (`apps/panel_flutter_web/lib/shared/ui/`)

### `components/` dizini

| Bileşen | Dosya | Açıklama |
|---------|-------|----------|
| `PanelShell` | `panel_shell.dart` | Ana layout: sidebar + topbar + içerik |
| `PanelSidebar` / `PanelSidebarItem` | `panel_sidebar.dart` | Daraltılabilir nav (260/72px) |
| `PanelPageHeader` | `panel_page_header.dart` | Sayfa başlığı: eyebrow + title + description + actions |
| `PanelContentSurface` | `panel_content_surface.dart` | Merkez max-width (1520px) içerik sarıcı |
| `PanelSectionCard` | `panel_section_card.dart` | Bölüm kartı (AppCard wrapper) |
| `PanelContentCard` | `panel_content_card.dart` | İçerik kartı |
| `PanelToolbar` | `panel_toolbar.dart` | Wrap tabanlı filtre araç çubuğu |
| `PanelDataToolbar` | `panel_data_toolbar.dart` | Veri sayfası araç çubuğu |
| `PanelSearchField` | `panel_search_field.dart` | Arama input'u |
| `PanelActionButton` | `panel_action_button.dart` | Çok varyantlı buton (primary / secondary / neutral / ghost / danger) |
| `PanelDataTableWrapper` | `panel_data_table_wrapper.dart` | Yatay kaydırmalı tablo sarıcı |
| `PanelEmptyState` | `panel_empty_state.dart` | Tablo/liste boş durumu |
| `PanelIcon` | `panel_icon.dart` | Akıllı ikon (FontAwesome + Material) |
| `AppScaffold` | `app_scaffold.dart` | PanelShellScope uyumlu scaffold (nested scaffold sorununu önler) |

### Kullanım Kuralları

- Panel sayfası her zaman `PanelPageHeader` ile başlamalıdır (AppScaffold istisnası için MEMORY.md bakın).
- Tüm bileşenler `lib/shared/ui/design_system.dart` barrel export üzerinden import edilir.
- Renk için `AppColors.*`, spacing için `AppTokens.of(context).*` kullanılır; hardcoded değerler yasaktır.

---

## 3. Mobile Flutter Yerel Bileşenler (`apps/mobile_flutter/lib/features/shared/ui/`)

| Bileşen | Dosya | Açıklama |
|---------|-------|----------|
| `AppScaffold` | `components/app_scaffold.dart` | PanelShellScope uyumlu (mobile versiyonu) |
| `AppHeroHeader` | `components/app_hero_header.dart` | Sayfa üstü başlık: ikon + title + subtitle |
| `AppErrorRetry` | `components/app_error_retry.dart` | Hata + retry butonu |
| `AppLoadingOverlay` | `components/app_loading_overlay.dart` | Tam ekran yükleme katmanı |
| `ReportBottomSheet` | `widgets/report_bottom_sheet.dart` | Yorum/içerik şikâyet bottom sheet |

---

## 4. Next.js Web Bileşenleri (`apps/web_next/src/ui/`)

| Bileşen | Açıklama |
|---------|----------|
| `components/menu-item-card.tsx` | Menü öğesi kartı |
| `components/category-filter.tsx` | Kategori filtresi (toggle-deselect destekli) |
| `components/language-toggle.tsx` | TR/EN dil değiştirici |
| `components/share-button.tsx` | Web Share API + clipboard fallback |
| `components/feedback-widget.tsx` | İşletme geri bildirim butonu + modal |
| `sections/menu-hero.tsx` | Menü sayfası başlık bölümü |

---

## 5. Bileşen Kullanım Matrisi

| Bileşen | Mobile | Panel | Web |
|---------|--------|-------|-----|
| `AppColors` | ✅ 300+ | ✅ 200+ | CSS var |
| `AppEmptyState` | ✅ 45+ | Panel'de `PanelEmptyState` | — |
| `AppSkeletonCard` | ✅ 12+ | ✅ 8+ | — |
| `AppRatingBar` | ✅ 20+ | — | — |
| `PanelPageHeader` | — | ✅ 15+ | — |
| `PanelActionButton` | — | ✅ 40+ | — |
| `AppScaffold` | ✅ 10+ | ✅ 8+ | — |

---

## 6. Bileşen Ekleme Kuralları

1. Aynı primitive 3+ yerde tekrarlanıyorsa `packages/shared_ui_components`'a taşı.
2. Yalnızca panel'e özel → `apps/panel_flutter_web/lib/shared/ui/`.
3. Yalnızca mobile'a özel → `apps/mobile_flutter/lib/features/shared/ui/`.
4. Web bileşeni → `apps/web_next/src/ui/`.
5. Duplicated primitive'e 4. kopya yazılmaz (CLAUDE.md kuralı).
