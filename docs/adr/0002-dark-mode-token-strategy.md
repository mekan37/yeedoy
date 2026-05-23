# ADR-0002: Dark Mode Token Stratejisi

**Durum:** Kabul edildi  
**Tarih:** 2026-04-22  
**Karar verenler:** Geliştirme ekibi

## Bağlam

Üç uygulamada da dark mode altyapısı (token'lar, color scheme) mevcuttu ama aktif `darkTheme` / `themeMode` bağlantısı yapılmamıştı. Birden fazla yaklaşım değerlendirildi.

## Değerlendirilen Alternatifler

1. **CSS/JSON kaynak dosyasından otomatik token üretimi** — Build-time script ile Flutter ve web token'larını tek yerden üretmek.
2. **`packages/ui_tokens` merkezi paketi** — Shared token tanımları ortak paket içinde.
3. **Platform-native parallel token tanımları** — Her uygulama kendi `AppDarkColors` / `DarkColorScheme` dosyasını tutar; web CSS variables ayrı.

## Karar

**Seçenek 3**: Her uygulama kendi dark token setini tutar.

- Flutter mobile: `packages/shared_ui_components/lib/src/dark_colors.dart` → `AppDarkColors`
- Flutter panel: aynı `dark_colors.dart` import edilir (shared_ui_components)
- Web: `uygulamalar/web/src/styles/tokens.css` içine `[data-theme='dark']` scope eklenir

## Gerekçe

- Seçenek 1 ve 2 build pipeline karmaşıklığı getirir; projenin mevcut olgunluk seviyesi için overkill.
- Token'lar uygulamalar arasında genellikle farklı renk ihtiyacı doğurur (panel daha yoğun kontrast ister).
- `packages/ui_tokens` web için kaynak otorite yapmak Seçenek 1'e gider ve ADR-0001 kuralına göre gözden geçirilmesi gerekir.

## Sonuçlar

**Olumlu:** Basit, anında deploy edilebilir, bağımlılık yok.  
**Olumsuz:** Token güncellemeleri üç yerde yapılmalı; gelecekte `ui_tokens` paketi kurulursa bu ADR geçersiz olacak.

## Uygulama Notları

- Flutter `themeMode` → Riverpod `themeModeProvider` + `SharedPreferences` kalıcılık.
- Web dark mode → `document.documentElement.dataset.theme = 'dark'` + localStorage.
- Visual regression: ADR-0003 güncellenince eklenecek.
