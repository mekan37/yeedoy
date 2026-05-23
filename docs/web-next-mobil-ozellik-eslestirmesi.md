# Web Next Mobile Feature Mapping

| Mobil özellik | Web karşılığı | Route | Component | Durum |
|---|---|---|---|---|
| Discovery feed | Web keşif sayfası | `/kesif` | `BusinessGrid` | yapıldı |
| Business detail | İşletme detay | `/isletme/[slug]` | `BusinessHero`, `BusinessInfoPanel` | yapıldı |
| Public menu | Menü sayfası | `/m/[slug]` | `PublicMenuClient`, `MenuItemCard` sistemi | yapıldı |
| Reviews | Yorum listesi | `/isletme/[slug]` içinde ve `/isletme/[slug]/reviews` mevcut | `ReviewsSection` | yapıldı |
| Favorites | Favori butonu | kart/detail içinde | `FavoriteButton` | yapıldı, kalıcılık yapılacak |
| Reports | Rapor et | modal/akisback flow | `ReportBusinessButton`, `ReportReviewButton` | yapıldı, report table entegrasyonu yapılacak |
| Owner claim | İşletme sahibi misin | `/sahiplen` | `OwnerClaimCTA` | yapıldı |
| QR entry | QR menü | `/karekod/[businessId]` mevcut | `QRMenuEntry` mevcut QR generator flow | korundu |

## Notlar

- Flutter tarafındaki `search_nearby_businesses_v3`, `get_business_detail_v1`, favorites ve reviews RPC kontratları değiştirilmedi.
- Web public adapter’ları mevcut tablo/RPC yapılarından okur; migration yapılmadı.
- Owner/admin CRUD Next public route’larına taşınmadı.


