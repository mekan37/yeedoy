# Web Slug Resolver — Deterministik Çözüm Planı

## Sorun

`/[sehir]/[slug]` route'u slug'ın district mi kategori mi olduğunu count karşılaştırmasıyla
belirliyor. Aynı slug hem district hem category adıyla eşleşirse sonuç count'a bağlı.

## Mevcut Davranış

- district sonuçları >= category sonuçları → district modu
- Eşit sayıda → district öncelikli (`>=` bias — kabul edilebilir)
- `React cache()` sayesinde aynı request'te 2 sorgu (4'ten indirildi)

## Uzun Vadeli Çözüm

### Seçenek A — businesses tablosuna slug sütunları ekle (ÖNERİLEN)

```sql
ALTER TABLE businesses
  ADD COLUMN city_slug     text GENERATED ALWAYS AS (slugify(city)) STORED,
  ADD COLUMN district_slug text GENERATED ALWAYS AS (slugify(district)) STORED,
  ADD COLUMN category_slug text GENERATED ALWAYS AS (slugify(category)) STORED;

CREATE INDEX idx_businesses_district_slug ON businesses(district_slug) WHERE is_active;
CREATE INDEX idx_businesses_category_slug ON businesses(category_slug) WHERE is_active;
```

Route mantığı:
1. `district_slug = :slug` → district modu (kesin eşleşme)
2. `category_slug ILIKE %:slug%` → category modu
3. Her ikisi de eşleşirse → district öncelikli (deterministik)

**Avantajlar:** Tam deterministik, Türkçe karakter kayıp yok, tek sorgu yeterli.
**Gereklilik:** Migration + `slugify()` SQL fonksiyonu.

### Seçenek B — Prefix URL yapısı

`/[sehir]/ilce-[slug]/` vs `/[sehir]/kat-[slug]/` — URL kırılır, mevcut indeksler zarar görür.
**Önerilmez.**

### Seçenek C — Slug lookup tablosu

`slug_lookup (slug text, type text, ref_id uuid)` ayrı tablo.
Seçenek A'dan daha karmaşık, tercih edilmez.

## Öneri

Seçenek A — Sonraki büyük DB migration PR'ında `city_slug`, `district_slug`, `category_slug`
sütunları ekle ve route'u tek kesin-eşleşme sorgusuna dönüştür.
