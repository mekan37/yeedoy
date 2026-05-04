# Mobil → Web Feature Parity Planı

**Tarih:** 2026-05-04  
**Amaç:** `apps/mobile_flutter` ile `apps/web_next` arasındaki kalite farkını kapatmak. Sayfa varlığı değil, **özellik derinliği** hedef alınıyor.

---

## Gap Özeti — Kod Ölçeği

| Alan | Mobil LOC | Web LOC | Eksiği |
|---|---|---|---|
| Discovery / Keşif | 5,129 | 196 | **%96** |
| Business Detail | 3,553 | 289 | **%92** |
| Profil | 2,080 | 175 | **%92** |
| Review Create | ~400 | 96 | **%76** |
| Smart Feed | ~600 | 53 | **%91** |
| Menu Item Detay | ~700 | mevcut | kısmi |

---

## 1. Discovery / Keşif Sayfası

### Mobilde var, webde yok
| Özellik | Açıklama | Öncelik |
|---|---|---|
| **CategoryQuickFilters** | Yatay kaydırmalı kategori chip'leri (Kafe, Restoran, Döner…) | P0 |
| **Top İşletmeler Strip** | Haftalık / aylık top işletmeler carousel | P0 |
| **RegionalPriceIndex** | Bölge fiyat ortalaması karşılaştırması | P1 |
| **PriceAnomaly Section** | Anormallik tespiti (beklenenden yüksek/düşük) | P1 |
| **MicroTrend Section** | "Son 7 günde %23 artış" gibi trend uyarıları | P1 |
| **WeatherHint Bar** | Hava durumuna bağlı öneri (yağmurda kapalı mekan vb.) | P2 |
| **Recent Searches** | Son aramalar (localStorage) | P2 |
| **Food Catalog Search** | Menü öğesi bazlı arama (tavuk şiş bul) | P2 |
| **Campaigns Tab** | Öne çıkan kampanyalar sekmesi | P2 |
| **Serendipity Cards** | Rastgele keşif önerileri (unexpected, value surprise) | P3 |

### Tasarım Hedefi
- Hero section: büyük başlık + arama çubuğu + kategori chip'leri
- İki sütun layout (büyük ekran): sol liste + sağ öne çıkanlar
- Skeleton loading states (shimmer)
- `search_businesses_v1` RPC ile SSR filtreleme

---

## 2. Business Detail — `/b/[slug]`

### Mobilde var, webde eksik
| Özellik | Kaynak (Dart) | Öncelik |
|---|---|---|
| **Hero kapak fotoğrafı** | `_BusinessHeroTrustHeader` — `cover_url` + gradient overlay | **P0** |
| **Açık / Kapalı badge** | `_BusinessHeaderCompactContainer` — `business_hours` tablosu | **P0** |
| **Ortalama fiyat** | `median_price_cents` / `average_price_cents` alanı | P0 |
| **Rating özeti** | Yıldız ortalaması + yorum sayısı header'da | P0 |
| **Trust Section** | Menü güncelleme tarihi, son fiyat doğrulama, kalite skoru | P1 |
| **Hours Section** | Tam haftalık tablo (Mon–Sun open/close) | P1 |
| **Contact Section** | Telefon, WhatsApp, Google Maps, Instagram, web | P1 |
| **Photos Gallery** | `menu_item_photos` / `business_photos` — 3 kolonlu grid | P1 |
| **Frequent Tags** | En çok geçen yorum etiketleri (lezzetli, hızlı servis vb.) | P2 |
| **Loyalty Badge** | İşletmede sadakat programı varsa rozet | P2 |
| **Price Change Mini Chart** | 3 aylık fiyat değişim sparkline | P2 |
| **QR Buton** | Menüyü mobilde tara butonu | P2 |

### Şu An Var Ama Geliştirilebilir
- Reviews section: verified badge var ama foto + yardımcı count eksik
- Menu preview: mevcut, detay sayfasına link var — yeterli

---

## 3. Profil Sayfası — `/(auth)/profile`

### Mobilde var, webde eksik
| Özellik | Kaynak | Öncelik |
|---|---|---|
| **3 Sekme** | Profil / Fiyat Alarmları / Besleme | **P0** |
| **Kimlik Kartı** | Avatar, ad, şehir, üye tarihi, düzenleme butonu | **P0** |
| **İstatistik Bar** | Yorum sayısı / Takipçi / Takip | **P0** |
| **Achievements Grid** | Rozetler 2x grid (VIP, Explorer, FoodHero vb.) | P1 |
| **Daily Micro Task** | Günlük görev kartı (yarın denesene: X) | P1 |
| **Reputation Score** | Topluluk skoru + seviye rozeti | P1 |
| **Profile Progress** | Tamamlanma yüzdesi progress bar | P1 |
| **Creator Profile** | Içerik üretici profil özeti (follower, post sayısı) | P2 |
| **Moat Signals** | "Güvenilir katkıcı" sinyalleri | P3 |

### RPC'ler
```
get_my_profile_stats
get_my_achievements_v2
get_my_daily_micro_task_v1
get_my_reputation_score_v1
get_my_profile_progress_v1
```

---

## 4. Yorum Yazma — `/(auth)/b/[slug]/reviews/new`

### Mobilde var, webde eksik
| Özellik | Açıklama | Öncelik |
|---|---|---|
| **Multi-criterion Ratings** | Lezzet / Servis / Fiyat-Değer / Temizlik / Atmosfer (5 ayrı yıldız) | **P0** |
| **Başlık Alanı** | Kısa başlık inputu | P1 |
| **Fotoğraf Yükleme** | Max 3 fotoğraf upload | P2 |

### Implementasyon
```typescript
const CRITERIA = [
  { key: 'r_taste', label: 'Lezzet' },
  { key: 'r_service', label: 'Servis' },
  { key: 'r_price_value', label: 'Fiyat / Değer' },
  { key: 'r_cleanliness', label: 'Temizlik' },
  { key: 'r_atmosphere', label: 'Atmosfer' },
]
```
`business_reviews` tablosuna `taste_rating`, `service_speed_rating`, `price_performance_rating`, `cleanliness_rating`, `atmosphere_rating` alanları zaten var.

---

## 5. Smart Feed — `/(auth)/smart-feed`

### Mobilde var, webde eksik
| Özellik | Açıklama | Öncelik |
|---|---|---|
| **Behavior Segment** | `get_my_behavior_segment_v1` ile kişisel segment | P1 |
| **Diet Profile Eşleşme** | Diyet tercihine uygun işletme filtreleme | P1 |
| **Budget Combo Widget** | Bütçeye göre kombo öneri (embed etme) | P2 |
| **WeatherHint** | Hava durumu entegrasyonu | P3 |

---

## 6. Menu Item Detay — `/m/[slug]/i/[itemId]`

### Mobilde var, webde eksik
| Özellik | Açıklama | Öncelik |
|---|---|---|
| **Fiyat Geçmişi** | 3 aylık sparkline chart | P1 |
| **TimeWindow Chip** | Öğle / akşam zaman penceresi badge'i | P1 |
| **Allergen Badge** | Alerjen uyarısı | P2 |
| **Nutrition Info** | Kalori / protein (varsa) | P3 |

---

## 7. Tasarım Sistemi — Yeni Elementler

Mevcut token sistemi güçlü (`tokens.css`). Eksikler:

| Element | Kullanım |
|---|---|
| **HeroCard** | cover_url + gradient overlay + başlık | Business sayfası |
| **StatusBadge** | "Şimdi Açık" (yeşil) / "Kapalı" (kırmızı) | Business, Discovery |
| **TrustLine** | Icon + metin satırı (✓ Menu güncellendi 3 gün önce) | Business trust |
| **StarCriteria** | Tek satırlık yıldız seçici | Review create |
| **Sparkline** | Mini SVG fiyat grafiği | Item detay, Business |
| **AchievementBadge** | Rozet ikonlu kart | Profil |
| **DailyTask** | Görev kartı (başlık + ilerleme + CTA) | Profil |

---

## 8. Uygulama Sırası

### Faz A — Hemen (Business + Review kalite artışı) ✅ TAMAMLANDI
1. ✅ `b/[slug]/page.tsx` → Hero + Hours + Contact + Trust + Photos (2026-05-04)
2. ✅ `reviews/new/page.tsx` → Multi-criterion ratings + başlık (2026-05-04)

### Faz B — Bu Sprint ✅ TAMAMLANDI
3. ✅ `(public)/discover/page.tsx` → 12 kategori chip + top haftanın en iyileri strip (2026-05-04)
4. ✅ `(auth)/profile/page.tsx` → 3 sekme (Profilim/Başarımlar/Besleme) + XP bar + daily task + achievements grid + katkı stats (2026-05-04)

### Faz C — Bu Sprint ✅ TAMAMLANDI (kısmen)
5. ✅ `(auth)/smart-feed` → behavior segment kartı + diyet profili etiketleri + segment bazlı işletme önerileri (2026-05-04)
6. ⬜ `/m/[slug]/i/[itemId]` → fiyat geçmişi sparkline (menu-item-detail-sheet data model değişikliği gerekiyor — ertelendi)
7. ✅ Ana sayfa (`/`) → gradient hero + sosyal kanıt + kategori filtresi + arama form + CTA'lar (2026-05-04)

---

## 9. Başarı Kriterleri

- [x] Business detail sayfası: cover hero + hours + contact + photos + 2-kolon layout (2026-05-04)
- [x] Review create: 5 kriter yıldızı + başlık alanı çalışıyor (2026-05-04)
- [x] Discovery: 12 kategori chip + top haftanın strip var (2026-05-04)
- [x] Profil: 3 sekme + XP bar + daily task + achievements grid + katkı stats (2026-05-04)
- [x] `npm run typecheck` temiz
- [x] Smart-feed: behavior segment + diyet profili + kişisel öneriler (2026-05-04)
- [x] Ana sayfa `/`: gradient hero + sosyal kanıt + kategori filtresi (2026-05-04)
- [ ] Menu item: fiyat geçmişi sparkline (data model değişikliği gerekiyor)
