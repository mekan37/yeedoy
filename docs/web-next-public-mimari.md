# Web Next Public Architecture

## Route Yapısı

- `/`: Yeedoy marketplace landing ve public keşif girişi.
- `/kesif`: işletme listeleme, kategori filtreleme, şehir ve arama.
- `/arama`: arama sonuçları için canonical public yüzey.
- `/isletme/[slug]`: işletme detay, menü önizlemesi, yorumlar, konum, claim ve rapor.
- `/m/[slug]`: mevcut public QR menü sayfası, korunur.
- `/karekod/[businessId]`: mevcut QR generator/giriş akışı, korunur.
- `/sahiplen`: işletme sahiplenme yönlendirme landing’i.

## Katmanlar

- `uygulama/`: metadata, route composition, SEO ve server rendering.
- `src/lib/veri/marketplace-read.ts`: public marketplace read adapter. Supabase sorguları burada kalır.
- `src/ui/public/*`: atomic ve reusable public component sistemi.
- `src/styles/tokens.css`: mobil theme kaynaklarıyla hizalanmış web token aynası.

## Veri İlkeleri

- Public okuma server component veya cached helper üzerinden yapılır.
- Mutation route’ları mevcut `uygulama/sunucu/**/route.ts` deseninde kalır.
- RPC imzaları ve return typeları değiştirilmedi.
- Owner/admin CRUD, `uygulama/owner/**` ve `uygulama/admin/**` içinde kalmaya devam eder.

## Performans

- `next/image` kart ve hero görsellerinde kullanıldı.
- Client component alanı favori, paylaşım, rapor ve helpful vote ile sınırlı.
- Public sayfalarda `metadata`, canonical ve Open Graph tanımlandı.
- Listeleme sayfalarında page size sınırlandı ve route revalidation kullanıldı.


