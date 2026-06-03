# Google Search Console — Submit Kılavuzu

## Ön Koşullar Kontrol Listesi

### robots.txt/ts Durumu
- [x] /sahip/* disallow ✓
- [x] /yonetici/* disallow ✓
- [x] /admin/* disallow ✓
- [x] /owner/* disallow ✓
- [x] /api/* disallow ✓
- [x] /auth/* disallow ✓
- [x] /login disallow ✓
- [x] sitemap URL doğru: `{siteUrl}/sitemap.xml` ✓

### Sitemap Durumu (sitemap.ts)
- [x] Statik rotalar dahil (ana sayfa, kesif, en-iyiler vb.)
- [x] İşletme detay sayfaları dahil: /isletme/[slug] (2500'e kadar)
- [x] QR alias sayfaları dahil: /b/[slug]
- [x] Public menü sayfaları dahil: /m/[slug] (5000'e kadar)
- [x] Şehir hub sayfaları dahil: /[sehir] (düzeltildi — daha önce eksikti)
- [x] İlçe listeleme sayfaları dahil: /[sehir]/[ilce] (düzeltildi — daha önce eksikti)
- [x] Kategori listeleme sayfaları dahil: /[sehir]/[ilce]/[kategori]
- [x] Panel/admin sayfaları dışarıda (/sahip, /owner, /yonetici, /admin)
- [x] changeFrequency ve priority mantıklı

### Canonical
- [x] / (ana sayfa) — metadataBase global layout'ta set
- [x] /[sehir] — alternates.canonical set
- [x] /[sehir]/[slug] — alternates.canonical set (district veya category modu)
- [x] /[sehir]/[slug]/[kategori] — alternates.canonical set
- [x] /isletme/[slug] — alternates.canonical set
- [x] /m/[slug] — alternates.canonical buildCanonicalPublicMenuHref ile set

### noindex Koruması
- [x] /sahip/* — layout.tsx'te robots: { index: false } (düzeltildi)
- [x] /owner/* — layout.tsx'te robots: { index: false } (düzeltildi)
- [x] /yonetici/* — layout.tsx'te robots: { index: false } (düzeltildi)
- [x] /admin/* — layout.tsx'te robots: { index: false } (düzeltildi)
- [x] (auth)/* kimlik gerektiren kullanıcı sayfaları — layout.tsx'te robots: { index: false } (düzeltildi)
- [x] (kimlik)/* — layout.tsx'te robots: { index: false } (düzeltildi)
- [x] Panel page başına ek robots: { index: false } de var (çift güvence)

### OG Image
- [x] /api/og route mevcut (İngilizce panel)
- [x] /sunucu/acik-grafik route mevcut (Türkçe panel)
- [x] openGraph.images isletme ve menü sayfalarında set

---

## 1. Domain Property Ekleme

1. https://search.google.com/search-console adresine git
2. "Property ekle" → "Domain" seç (www ve www-sız tüm URL'leri kapsar)
3. `yeedoy.com` gir (www olmadan)
4. DNS doğrulama TXT kaydını kopyala

## 2. DNS Doğrulama

DNS sağlayıcına git (Cloudflare, GoDaddy vb.):
1. TXT kaydı ekle:
   - Ad/Host: `@` (kök domain)
   - Değer: `google-site-verification=XXXX` (Console'dan alınan)
   - TTL: 3600 (veya otomatik)
2. Kaydı kaydet
3. Search Console'da "Doğrula" tıkla
4. DNS yayılımı 15 dk - 24 saat sürebilir

## 3. Sitemap Submit

1. Sol menü → Sitemaplar
2. "Yeni sitemap ekle"
3. URL: `https://yeedoy.com/sitemap.xml`
4. Gönder
5. Durum: "Başarı" görünene kadar bekle (~24 saat)

## 4. Kapsam (Coverage) Kontrolü

İlk 48 saat sonra:
1. Sol menü → Dizin Oluşturma → Sayfalar
2. "Neden dizine eklenmedi" kısmını kontrol et
3. Beklenen sorunlar (kabul edilebilir):
   - Yönlendirilen URL'ler
   - canonical olmayan (yinelenen içerik)
4. Gerçek sorunlar (düzelt):
   - "Robots.txt ile engellendi" — yanlış disallow
   - "noindex etiketi" — yanlış sayfada
   - "Bulunamadı (404)" — kırık URL

## 5. Canonical Kontrolü

URL İnceleme aracı ile kritik URL'leri test et:
- `https://yeedoy.com/istanbul` (şehir hub)
- `https://yeedoy.com/istanbul/besiktas` (ilçe)
- `https://yeedoy.com/istanbul/kahve` (kategori — /[sehir]/[slug] birleşik route)
- `https://yeedoy.com/istanbul/besiktas/kahve` (3-seviye)
- `https://yeedoy.com/isletme/ornek-isletme` (işletme)
- `https://yeedoy.com/m/ornek-isletme` (public menü)

Her biri için:
- "Google tarafından seçilen canonical" = "Kullanıcı tarafından beyan edilen canonical" olmalı
- Farklıysa canonical tag'i kontrol et

## 6. Index Request

Öncelikli sayfalar için manuel index isteği:
1. URL İnceleme → URL gir
2. "İndex için isteğe bağlı gönder" tıkla
3. Öncelik sırası:
   a. Ana sayfa: `https://yeedoy.com`
   b. Büyük şehirler: istanbul, ankara, izmir
   c. Popüler kategoriler: kahve, burger, pizza

## 7. İlk 30 Gün İzlenecek Metrikler

### Hafta 1-2
- [ ] Sitemap işlendi mi? (Sitemaplar sayfasında "Başarı")
- [ ] İlk URL'ler dizine eklendi mi?
- [ ] robots.txt doğru yorumlanıyor mu? (Robots.txt Test Aracı)

### Hafta 3-4
- [ ] Toplam dizine eklenen URL sayısı
- [ ] En çok gösterilen sorgular (Performans raporu)
- [ ] Ortalama sıralama pozisyonu
- [ ] Tıklama oranı (CTR)

### Ay Sonu Kontrol
- [ ] Kapsam sorunları çözüldü mü?
- [ ] Core Web Vitals raporu yeşil mi?
- [ ] Mobil kullanılabilirlik sorunları var mı?
- [ ] Zengin sonuç (structured data) hataları var mı?

## 8. Yapılandırılmış Veri Doğrulama

Zengin Sonuçlar Test Aracı: https://search.google.com/test/rich-results

Test edilecek sayfalar:
- İşletme detay (Restaurant + BreadcrumbList + Review schema)
- İlçe/kategori sayfaları (BreadcrumbList + FAQPage schema)
- 3-seviye kategori sayfaları (BreadcrumbList + FAQPage + ItemList schema)
- Public menü sayfası (Restaurant + Menu + MenuSection + MenuItem schema)
- Şehir hub sayfası (CollectionPage + BreadcrumbList schema)

---

## Notlar

- Yeedoy.com'un canlı sitemap URL'si: `https://yeedoy.com/sitemap.xml`
- robots.txt URL'si: `https://yeedoy.com/robots.txt`
- sitemap.ts revalidate: 3600 saniye (1 saat)
- /[sehir]/[slug] route: slug, district veya category olabilir — her iki tip canonical ile üretiliyor
- Panel sayfaları (/sahip, /owner, /yonetici, /admin) hem robots.ts disallow hem de layout-level noindex ile korunuyor
- (auth) ve (kimlik) kullanıcı sayfaları layout-level noindex + auth redirect ile korunuyor
- OG image iki route'ta: /api/og (İngilizce panel) ve /sunucu/acik-grafik (Türkçe panel)
