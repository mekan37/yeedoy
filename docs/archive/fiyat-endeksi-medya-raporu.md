# Yeedoy Türkiye Restoran Fiyat Endeksi — Pilot Rapor [Haziran 2026]

> **Hazırlanma Tarihi:** 3 Haziran 2026
> **Durum:** İlk taslak — dahili onay için
> **Hazırlayan:** Büyüme ve İletişim Ekibi

---

## 1. Rapor Başlığı ve Tek Cümle Özet

**Başlık:** Yeedoy Türkiye Restoran Fiyat Endeksi — Pilot Rapor, Haziran 2026

**Özet:** Yeedoy, Türkiye genelinde on binlerce menü kaleminin topluluk tarafından doğrulanmış gerçek zamanlı fiyatlarını izleyerek ülkenin ilk bağımsız restoran fiyat endeksini oluşturuyor; bu endeks %48,6'yı aşan gıda enflasyonu ortamında tüketicilere, araştırmacılara ve medyaya kanıta dayalı bir referans noktası sunuyor.

---

## 2. Neden Şimdi?

### Türkiye'de Gıda Enflasyonu Bağlamı

Türkiye'de gıda fiyat enflasyonu 2025 Aralık itibarıyla %48,6 olarak gerçekleşti ve son 67 aydır kesintisiz yükseliş sürmektedir. Bu süreçte dışarıda yemek yiyen tüketiciler iki kritik soruyla baş başa kalmaktadır: "Bu fiyat gerçek mi?" ve "Bu mekan pahalı mı, uygun mu?"

Söz konusu sorular yanıtsız kalmaya devam etmektedir çünkü Türkiye'de restoran fiyatlarını sistematik biçimde izleyen, karşılaştıran ve doğrulayan bağımsız bir platform bugüne kadar var olmamıştır.

### Tüketicilerin Restoran Fiyatlarına Erişim Sorunu

Tüketici, bir restoranın menü fiyatını öğrenmek için üç seçeneğe sahiptir: restoranın kapısına gidip bakmak, sipariş platformlarından teslimat fiyatlarına bakmak (ki bunlar yerinde yemek fiyatlarından farklıdır) ya da sosyal medya yorumlarında bahsi geçen eski fiyatlara güvenmek. Bu üç yolun hiçbiri güncel, doğrulanmış ve karşılaştırılabilir veri sunmamaktadır.

### Mevcut Çözümlerin Eksikliği

Yemeksepeti, Trendyol Go ve Getir Yemek gibi platformlar sipariş odaklıdır; fiyat şeffaflığı bu platformların değer önerisinin dışında kalmaktadır. Teslimat platformlarındaki fiyatlar hizmet bedeli, paketleme ücreti ve platform marjını içerdiğinden yerinde yemek fiyatlarını yansıtmamaktadır. Google Maps ve TripAdvisor'da görünen fiyat bilgileri aylarca eski kalabilmekte, tarihsel karşılaştırma ya da güven skoru içermemektedir.

Yeedoy bu boşluğu kapatmak için konumlanmıştır.

---

## 3. Yeedoy'un Farklı Konumu

### Fiyat İzleme Platformu Anlatısı

Yeedoy, Türkiye yemek-teknoloji pazarında rakiplerinden yapısal olarak ayrışan tek boyutu sahiptir: **gerçek zamanlı, topluluk doğrulamalı fiyat izleme ve tarihsel fiyat takibi**.

Rekabet matrisinde bu boyutlarda hiçbir rakip puan almamaktadır:

| Boyut | Yeedoy | Google Maps | Yemeksepeti | Trendyol Go |
|---|:---:|:---:|:---:|:---:|
| Gerçek zamanlı menü fiyatı | ✓ | — | Kısmi* | Kısmi* |
| Fiyat geçmişi / tarihsel trend | ✓ | — | — | — |
| Fiyat anomalisi tespiti | ✓ | — | — | — |
| Topluluk confidence skoru | ✓ | — | — | — |
| İlçe bazlı fiyat karşılaştırma | ✓ | — | — | — |

*Sipariş platformlarındaki fiyatlar teslimat marjını içerir; yerinde yemek fiyatlarını yansıtmaz.

### Üç Katmanlı Değer Önerisi

**1. Fiyat Karşılaştırma:** Aynı ürün adı için şehir genelinde ortalama, minimum ve maksimum fiyat; ilçe bazlı sapma analizi.

**2. Menü Şeffaflığı:** İşletme sahiplerinin kendi panellerinden güncelledikleri fiyatlar + topluluk doğrulama bildirimleri + confidence scoring mekanizması.

**3. Topluluk Yorumu:** Doğrulanmış ziyaret rozeti taşıyan kullanıcıların fiyat bildirimleri anonim aggregate analizde daha yüksek ağırlık taşır.

### Piyasada İşgal Edilmemiş Alan

"Restoran fiyatlarını izliyoruz" konumu tüm mevcut oyuncuların dışında, işgal edilmemiş bir mevkidir.

---

## 4. Beş Veri Hikayesi Önerisi

### Hikaye 1: "İstanbul'da Menü Fiyatları 6 Ayda Ne Kadar Değişti?"

**Medyaya verilebilir başlık:** "Yeedoy Verisi: İstanbul'da Restoran Fiyatları 6 Ayda Ortalama X% Arttı"

**Veri kaynağı — DB'den çekilebilir:**
- Tablo: `menu_item_price_history` + `businesses`
- RPC: `admin_export_menu_inflation_csv_v1(p_days => 180)`
- `first_price_cents`, `last_price_cents`, `inflation_pct` döndürür
- Filtre: `b.city = 'İstanbul'`, `p_days = 180`

**Medya çekicilik skoru: 5/5** — Somut sayı, kısa dönem, şehir odaklı.

---

### Hikaye 2: "En Uygun Semtler: İlçe Bazlı Fiyat Kıyaslaması"

**Medyaya verilebilir başlık:** "Yeedoy Haritası: İstanbul'da En Ucuz ve En Pahalı Yemek İlçeleri"

**Veri kaynağı — DB'den çekilebilir:**
- RPC: `admin_export_regional_price_index_csv_v1(p_days => 30)`
- `city`, `district`, `avg_price_cents`, `median_price_cents`, `item_count`, `change_pct` döndürür
- Minimum veri koşulu: `item_count >= 10`

**Medya çekicilik skoru: 5/5** — Harita görselliği sosyal medyada paylaşılabilir.

---

### Hikaye 3: "Kategori Bazlı Fiyat Endeksi: Kahve vs. Burger vs. Pizza"

**Medyaya verilebilir başlık:** "Türkiye'de Restoran Enflasyonu: Kahve mi Pahalılaştı, Kebap mı?"

**Veri kaynağı — DB'den çekilebilir:**
- RPC: `get_category_price_benchmark_v1(p_item_name, p_city)` — avg/min/max/sample_count
- Analiz: Standart ürün adları için şehir ortalaması; `menu_item_price_history` üzerinden dönem karşılaştırması
- Kısıt: `sample_count >= 3` RPC'de yerleşik

**Medya çekicilik skoru: 4/5**

---

### Hikaye 4: "Doğrulanmış Ziyaret Badge'i: Güvenilir Fiyat Verisi Neden Önemli?"

**Medyaya verilebilir başlık:** "Yeedoy'un Topluluk Doğrulama Sistemi: Sahte Fiyat Bildirimlerine Karşı Güven Kalkanı"

**Veri kaynağı — DB'den çekilebilir:**
- Tablo: `menu_item_price_suggestions`
- Alan: `status` (pending/approved/rejected), `submitted_at`, `confidence_score`
- Metrik: Doğrulanmış ziyaretçi bildirimlerinin kabul oranı vs. genel kullanıcı oranı

**Medya çekicilik skoru: 3/5** — Teknoloji medyası ve startup medyası için uygun.

---

### Hikaye 5: "Zincir vs. Bağımsız: Fiyat Farkı"

**Medyaya verilebilir başlık:** "Yeedoy Analizi: Büyük Zincirler mi Daha Ucuz, Bağımsız Kafeler mi?"

**Veri kaynağı:** **Ölçülecek metrik** — `businesses` tablosunda `is_chain` boolean alanı henüz yok. `businesses.name` üzerinde zincir adı pattern matching ile etkinleştirilebilir.

**Medya çekicilik skoru: 4/5** — Tüketicinin içgüdüsel sorusunu yanıtlar, viral potansiyel yüksek.

---

## 5. Hangi Veriler Kullanılacak?

| Veri | Tablo / Alan | RPC / Export | Durum |
|---|---|---|---|
| Güncel menü fiyatı | `menu_items.price_cents` | Doğrudan sorgu | Mevcut |
| Tarihsel fiyat serisi | `menu_item_price_history.price_cents`, `created_at` | `admin_export_menu_inflation_csv_v1` | Mevcut |
| İlçe bazlı fiyat endeksi | `businesses.city`, `businesses.district` | `admin_export_regional_price_index_csv_v1` | Mevcut |
| Kategori bazlı benchmark | `businesses.category`, `menu_items.name` | `get_category_price_benchmark_v1` | Mevcut |
| Topluluk güven sinyali | `menu_item_price_suggestions.status` | Doğrudan sorgu | Mevcut |
| Rakip karşılaştırma | `menu_items` + `businesses` | `get_business_price_comparison_v1` | Mevcut |
| Kalite sinyali | `businesses.avg_rating`, `businesses.review_count` | Doğrudan sorgu | Mevcut |
| Zincir tespiti | `businesses.name` pattern match | Ölçülecek metrik | Geliştirme gerekli |

---

## 6. Hangi Veriler Kullanılmayacak?

- **Bireysel kullanıcı verileri:** Kullanıcı ID'leri, demografik veriler — tüm analizler aggregate düzeyde
- **Lokasyon verisi:** Kullanıcı GPS geçmişi, check-in verileri
- **Rezervasyon ve sipariş verisi:** Yeedoy bir sipariş platformu değildir
- **Belirli işletme sahiplerini hedef alan veriler:** Tüm karşılaştırmalar aggregate; tek işletme hedeflenmez
- **Ham topluluk verileri:** Sadece `status = 'approved'` ve yeterli sample büyüklüğüne ulaşmış veriler

---

## 7. KVKK Dikkat Noktaları

### Aggregate Veri Kullanımı
Raporda kullanılacak tüm veriler aggregate niteliktedir. İlçe bazlı fiyat ortalamaları ve tarihsel trend hesaplamaları kişisel veri işleme kapsamına girmemektedir.

### Kullanıcı Yorum Verisi
KVKK consent akışı (`core/privacy/consent_bottom_sheet.dart`) mobil uygulamaya eklenmiştir. Web için de benzer mekanizma planlanmalıdır.

**Öneri:** Rapor yayınlanmadan önce hukuk danışmanıyla birlikte "Anonim aggregate veri işleme" kapsamında hizmet şartları gözden geçirilmeli; gerekirse "Fiyat Endeksi Veri Politikası" sayfası oluşturulmalıdır.

### Opt-Out Mekanizması
İşletme sahiplerinin aggregate analizden çıkabilmesi için ileride `businesses` tablosuna `exclude_from_price_index boolean DEFAULT false` alanı eklenebilir.

### Veri Saklama Süresi
`menu_item_price_history` için KVKK uyumlu saklama süresi politikası: iş amaçlı kullanım için 24 ay önerilir.

---

## 8. Landing Page İskeleti

**Route:** `/fiyat-endeksi`

```
HERO
H1: Türkiye'nin Restoran Fiyat Endeksi
Alt: Topluluk tarafından doğrulanmış, bağımsız fiyat verisi. Aylık yayınlanır. Ücretsiz erişim.
CTA (birincil): [PDF İndir — Haziran 2026]
CTA (ikincil): [E-posta Bülteni'ne Kayıt Ol]

VERİ ÖZET KARTLARI (3 adet)
Kart 1: [X.XXX] Doğrulanmış Fiyat Noktası
Kart 2: [XX] İlçe Kapsama
Kart 3: [X] Kategori Endeksi
→ İlk veri çekildikten sonra doldurulacak

METODOLOJİ ÖZETİ
"Veri Nasıl Toplanıyor?"
- İşletme sahipleri menülerini Yeedoy'da günceller
- Topluluk üyeleri fiyat değişikliklerini bildirir
- Onay mekanizması sahte bildirimleri filtreler
- Her ürün için güven skoru hesaplanır
[Tam Metodoloji →]

PDF İNDİRME
[Rapor Kapağı Görseli]
Yeedoy Türkiye Restoran Fiyat Endeksi — Haziran 2026
[PDF İndir — Ücretsiz]

MEDYA LOGOLARI
[Yer Ayrılacak — İlk medya yayınları gerçekleştikten sonra eklenecek]

E-POSTA LİSTESİ
"Aylık Raporu Kaçırmayın"
[E-posta adresi girin] [Kayıt Ol]
```

---

## 9. Medya Pitch Metni

**Konu satırı:** Yeni veri: Türkiye'de restoran fiyatları X ayda %XX arttı — Yeedoy Fiyat Endeksi

---

Sayın [Gazeteci Adı],

Türkiye'de gıda enflasyonu son 67 aydır yükselmeye devam ederken tüketiciler restoran menü fiyatlarındaki gerçek değişimi bağımsız bir kaynaktan takip edememekteydi. Yeedoy, bugün Türkiye'nin ilk bağımsız restoran fiyat endeksini yayınlıyor. Haziran 2026 pilot raporu, XX ilçede XX.XXX doğrulanmış menü fiyat noktasını kapsıyor ve İstanbul genelinde fiyatların son 6 ayda ortalama %XX arttığını ortaya koyuyor. En yüksek artış [kategori]'de, en düşük artış [kategori]'de gözlemlendi.

Yeedoy, Türkiye'de kurulu restoran keşif ve fiyat izleme platformudur. Topluluk tarafından doğrulanmış gerçek zamanlı menü fiyatları, tarihsel fiyat trendi ve ilçe bazlı karşılaştırma özelliklerinin bütününü bir arada sunan ülkedeki tek platform olma özelliğini taşımaktadır.

"Türkiye'deki restoran müşterileri yıllardır fiyatları karşılaştırmak için güvenilir bir kaynaktan yoksundu. Bu endeks, topluluğun gücüyle üretilmiş bağımsız bir referans noktası sunuyor. Amacımız her ay güncel tutarak politika yapıcılara, araştırmacılara ve tüketicilere gerçek veriye dayalı karar desteği sağlamak." — [Kurucu Adı], Yeedoy

İletişim: [iletisim@yeedoy.com]

---

## 10. 30 Günlük Dağıtım Planı

| Hafta | Kanal | Aksiyon |
|---|---|---|
| **Hafta 1** | İç hazırlık | Pilot raporu verisiyle doldur; PDF tasarımını tamamla; `/fiyat-endeksi` landing page yayına al; e-posta formu test et |
| **Hafta 1** | SEO | `/fiyat-endeksi` sitemap'e ekle; `Article` + `Dataset` JSON-LD schema ekle; Search Console'a bildir |
| **Hafta 2** | Medya outreach | Ekonomi muhabirlerine kişiselleştirilmiş pitch gönder (hedef: Dünya, Bloomberg HT, Ekonomist, Hürriyet Ekonomi, Webrazzi) |
| **Hafta 2** | LinkedIn | Kurucudan kişisel yazı: "Neden bir restoran fiyat endeksi kuruyoruz?" |
| **Hafta 2** | Twitter/X | Rapor thread'i: 5 tweet, her biri bir veri hikayesi + infografik görsel |
| **Hafta 3** | Medya takibi | Açılan bağlantıları takip et; pickup olursa LinkedIn/Twitter'da paylaş |
| **Hafta 3** | E-posta listesi | İlk bülten: kayıtlı adreslere raporu gönder |
| **Hafta 3** | Haber bülteni | Türkiye startup/teknoloji bültenlerine (Ekşi Şeyler vb.) submission |
| **Hafta 4** | SEO içeriği | Blog yazısı: `/blog/istanbul-restoran-fiyat-endeksi-haziran-2026` |
| **Hafta 4** | Değerlendirme | Backlink, landing page ziyareti, e-posta kayıt rakamlarını topla; bir sonraki aya plan yap |

---

## 11. Başarı Metrikleri

| Metrik | Hedef (30 gün) | Ölçüm Aracı |
|---|---|---|
| Medya pickup sayısı | 3+ yayın | Manuel takip + Google Alerts |
| Landing page benzersiz ziyaret | 2.000+ | Google Analytics / Vercel Analytics |
| E-posta bülteni kaydı | 200+ | Form submission sayacı |
| Backlink sayısı | 10+ kaliteli domain | Search Console + Ahrefs/Semrush |
| Organik arama tıklaması | 500+ (`/fiyat-endeksi`) | Google Search Console |
| LinkedIn erişimi | 5.000+ görüntülenme | LinkedIn Analytics |
| PDF indirme | 500+ | Vercel Analytics |

---

## Ekler

### A. Teknik Metodoloji Notu (Dahili)

Veri pipeline:

1. `admin_export_regional_price_index_csv_v1(p_days => 180)` ile bölgesel endeks CSV
2. `admin_export_menu_inflation_csv_v1(p_days => 180)` ile ürün bazlı enflasyon
3. `item_count < 5` olan satırlar elenir
4. Her şehir/ilçe için median fiyat hesaplanır (`median_price_cents` RPC'de yerleşik)
5. Önceki dönemle karşılaştırma: ikinci 180 günlük pencere (`change_pct` alanı)
6. Sonuçlar CSV → JSON → PDF + web için iki format

### B. Veri Tazeliği Notu

Minimum endeks koşulu: Aynı kategoride en az 5 farklı işletmeden en az 3 doğrulanmış fiyat noktası. Bu eşiğin altındaki kombinasyonlar "Yetersiz Veri" olarak raporlanır.

---

*Son Güncelleme: 3 Haziran 2026*
*Bağlantılı belgeler: `docs/rekabet.md`, `docs/store_listing.md`, `docs/eksik-listesi.md`*
*DB referansları: `admin_export_regional_price_index_csv_v1`, `admin_export_menu_inflation_csv_v1`, `get_category_price_benchmark_v1`, `get_business_price_comparison_v1`*
