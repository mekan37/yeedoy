# Web Next Figma Conversion

Kaynak: Figma Make `Food Discovery Marketplace UI`.

## Çıkarılan Yapı

- Hero: büyük marketplace arama alanı, şehir girişi, güven/fiyat/QR rozetleri.
- Category filter: yatay, mobile-first chip sistemi.
- Business grid: görsel, rating, fiyat sinyali, doğrulanmış/açık durumları ve menü CTA.
- Detail surface: işletme hero, bilgi paneli, konum/güven, saatler, yorum ve menü önizlemesi.
- Footer/header: public navigasyon, owner/admin ayrımını açık tutan claim yönlendirmesi.

## Uygulanan Componentler

- Layout: `PublicHeader`, `PublicFooter`, `MobileBottomNav`, `PublicShell`, `Container`, `SectionHeader`.
- Discovery: `HeroSearchSection`, `SearchBar`, `LocationSearchInput`, `CategoryFilterChips`, `BusinessGrid`, `BusinessCard`, `BusinessCardSkeleton`, `EmptyDiscoveryState`, `LoadMoreButton`.
- Business: `BusinessHero`, `BusinessInfoPanel`, `BusinessStatusBadge`, `VerifiedBadge`, `RatingSummary`, `BusinessHoursBlock`, `BusinessLocationBlock`, `OwnerClaimCTA`, `ReportBusinessButton`.
- Menu: `PublicMenuLayout`, `MenuSectionTabs`, `MenuCategoryBlock`, `MenuItemCard`, `MenuItemPhoto`, `PriceBadge`, `AllergenBadges`, `MenuItemSkeleton`, `EmptyMenuState`.
- Reviews: `ReviewsSection`, `ReviewCard`, `HelpfulVoteButton`, `ReportReviewButton`, `EmptyReviewsState`.
- Common: `FavoriteButton`, `ShareButton`, `Skeleton`, `EmptyState`, `ErrorState`, `LoadingState`, `Badge`, `Card`, `ButtonLink`.

## Tasarım Adaptasyonu

- FoodHub kopyası yapılmadı; Yeedoy marka adı, Türkçe copy ve mevcut web tokenları kullanıldı.
- Renk/spacing/radius kararları `uygulamalar/mobil/lib/uygulama/theme/*` kaynaklarından aynalanan `tokens.css` ve Tailwind semantic sınıflarıyla hizalandı.
- Büyük dependency eklenmedi; ikonlar inline SVG, interactionlar küçük client componentler.
- Server component varsayılanı korundu; sadece favori, paylaşım ve rapor etkileşimleri client component.

## Öneriler

- Menü kategori adları için public read modelde `menu_translations` adapter’ı genişletilebilir.
- Favori optimistic UI şu an local state; auth-aware kalıcı favori için mevcut favorites akışıyla server action eklenmeli.
- Rapor modalı mevcut `/sunucu/geri-bildirim` endpointini kullanıyor; domain-specific report türleri için mevcut `reports` tablosuyla ayrı route eklenebilir.

