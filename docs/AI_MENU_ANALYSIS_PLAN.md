# AI QR Menü Sistemi — Yeedoy

## Amaç

Yeedoy platformunda QR menü sistemine entegre çalışan yapay zeka destekli analiz, içerik üretimi ve işletme kolaylaştırma özelliklerinin tasarımını tanımlar.

Bu sistem:

- Menüleri otomatik analiz eder
- İçerik, alerjen ve kalori bilgisi üretir
- Çok dilli destek sağlar
- İşletmelerin operasyonunu hızlandırır

---

## Not (Kritik)

Bu sistemdeki tüm AI çıktıları:

- kesin bilgi değildir
- tahmin ve öneri niteliğindedir
- kullanıcıya bu şekilde sunulmalıdır

Zorunlu:
- güven skoru
- manuel düzenleme imkanı
- uyarı metni

---

## Ürün Özellikleri (AI + Sistem)

### 1. Yapay Zeka Kalori ve Besin Değeri Hesaplama

- Kalori (kcal)
- Protein
- Yağ
- Karbonhidrat

Nasıl çalışır:
- ürün adı + içerik analiz edilir
- tahmini değer hesaplanır

Kurallar:
- kesin değer verilmez
- aralık verilir (örn: 320–420 kcal)
- "yaklaşık" etiketi zorunlu

---

### 2. Alerjen Tespiti Sistemi

Desteklenen 14 alerjen:

- Gluten
- Kabuklu deniz ürünleri
- Yumurta
- Balık
- Yer fıstığı
- Soya
- Süt
- Sert kabuklu yemişler
- Kereviz
- Hardal
- Susam
- Kükürt dioksit
- Acı bakla
- Yumuşakçalar

Özellikler:
- otomatik tespit
- ikon ile gösterim
- risk seviyesi

---

### 3. Yapay Zeka Ürün İçeriği Tespiti

- ürün adı analiz edilir
- içerik listesi oluşturulur
- belirsiz alanlar işaretlenir

Kullanım:
- vegan / diyet kullanıcılar
- şeffaf menü deneyimi

---

### 4. Excel ile Toplu Menü Yükleme

- excel indir
- doldur
- yükle

Sonuç:
- yüzlerce ürün tek seferde eklenir

---

### 5. Öğrenen Yapay Zeka

- kullanıcı düzeltmelerinden öğrenir
- doğruluk zamanla artar
- güven skoru üretir

---

### 6. Çoklu Para Birimi

- TL / USD / EUR
- otomatik kur hesaplama
- kullanıcı seçimi

---

### 7. Anlık Fiyat Güncelleme

- saniyeler içinde güncelleme
- QR menü anında değişir
- baskı maliyeti yok

---

### 8. Ürün Varyantları

- porsiyon
- sos
- ekstra
- pişme derecesi

Sınırsız varyasyon desteklenir

---

### 9. PDF Menü Oluşturma

- tek tıkla PDF
- baskıya hazır çıktı

---

### 10. Analitik ve Raporlama

- görüntülenme sayısı
- ürün popülerliği
- zaman bazlı analiz

---

## AI Sistem Mimarisi

### 1. OCR Katmanı

Girdi:
- fotoğraf
- PDF
- menü görseli

Çıktı:
- raw_text
- ürün listesi
- fiyatlar
- kategoriler

Yaklaşım:
- web OCR (MVP)
- gerektiğinde server OCR

---

### 2. İçerik Analizi

- metin normalize edilir
- malzeme çıkarılır
- bilinmeyenler işaretlenir

Çıktı:
- ingredients[]
- unknown_terms[]
- confidence_score

---

### 3. Alerjen Motoru

- kural tabanlı eşleme
- varyasyon desteği

Örnek:
- süt → süt ürünleri
- un → gluten

Çıktı:
- allergens[]
- risk_level

---

### 4. Kalori Motoru

- içerik + ürün tipi
- tahmini hesaplama

Çıktı:
- min/max kcal
- porsiyon tahmini
- güven skoru

---

### 5. Çeviri Sistemi

- otomatik öneri
- kullanıcı onayı

Örnek:
- Mercimek Çorbası → Lentil Soup

---

## Veri Modeli

### menu_item_ai_analysis

- id
- menu_item_id
- source_text
- normalized_text
- ingredients_json
- allergens_json
- calorie_min
- calorie_max
- confidence
- requires_review

---

### menu_ocr_jobs

- id
- file_url
- status
- raw_text
- parsed_output

---

## Kullanım Akışı

### 1. Menü Yükleme

- kullanıcı görsel/PDF yükler
- OCR çalışır
- taslak oluşur

---

### 2. AI Analiz

- içerik çıkarılır
- alerjen tespit edilir
- kalori hesaplanır

---

### 3. Kullanıcı Onayı

- düzenleme yapılır
- onaylanır

---

### 4. Yayın

- QR menü aktif olur

---

## UI Kuralları

Zorunlu:

- "Bu bilgiler otomatik analiz ile oluşturulmuştur"
- "Lütfen işletmeden doğrulayınız"

Renkler:

- Yeşil → güvenli
- Sarı → kontrol
- Kırmızı → risk

---

## Geliştirme Aşamaları

### Faz 1
- OCR
- manuel düzenleme

### Faz 2
- içerik + alerjen

### Faz 3
- kalori + çeviri

### Faz 4
- öğrenen sistem

---

## Kod Kuralları

- AI çıktısı kesin kabul edilmez
- confidence zorunlu
- düşük güven → manuel kontrol
- tüm AI sonuçları etiketlenir

---

## Codex / Claude Görevleri

1. OCR entegrasyonu kur
2. Menü parser yaz
3. içerik sözlüğü oluştur
4. alerjen motoru yaz
5. kalori sistemi kur
6. panel entegrasyonu yap

---

## Sonuç

Bu sistem:

- işletmeye hız kazandırır
- kullanıcıya şeffaflık sağlar
- AI destekli ama insan kontrollü çalışır

Temel prensip:
**AI önerir, insan onaylar**