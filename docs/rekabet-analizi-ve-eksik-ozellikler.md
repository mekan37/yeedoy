# Yeedoy — Rekabet Analizi & Eksik Özellikler Raporu

> **Hazırlık:** 2026-05-06  
> **Amaç:** Piyasadaki benzer hizmetlerle kıyaslamalı boşluk analizi. Kullanıcının her yemek ihtiyacında Yeedoy'a dönmesini, işletmenin "müşterim arttı" demesini sağlayacak kritik eksiklerin tamamı.

---

## 1. Mevcut Güçlü Taraflar (Korunmalı)

Bunları rakiplerin hiçbiri birlikte sunmuyor — Yeedoy'un kimliği burada:

| Güçlü Yan | Rakipte Var mı? |
|---|---|
| QR tabanlı gerçek zamanlı dijital menü (owner self-serve) | Zayıf — çoğu statik PDF veya pahalı SaaS |
| Fiyat geçmişi + fiyat şeffaflığı + kalabalık kaynaklı fiyat güncellemesi | Yok |
| Fiyat anomalisi tespiti (şişirilmiş fiyat uyarısı) | Yok |
| Kitle bazlı güven/kalite skoru (gerçeklik skoru) | Yok |
| Bütçe kombinasyonu önerici ("150 TL'ye ne yesem") | Yok |
| Tat ikizi eşleştirme | Benzer: Netflix tarzı; yemek alanında yok |
| Askıda öğün sistemi | Yok |
| Ortak liste + oylama (grup karar desteği) | Benzer: grup rezervasyon uygulamaları; fiyat boyutu yok |
| Katkı tabanlı itibar sistemi (gurme/kahraman) | Benzer: Yelp Elite; daha az yapısal |
| B2B anonim fiyat endeksi veri ürünü | Yok |

---

## 2. Rakip Haritası

### 2.1 Doğrudan Rakipler (Türkiye'de Aktif)

| Platform | Güçlü Yan | Yeedoy'un Üstün Olduğu |
|---|---|---|
| **Google Maps (Restoran)** | Erişim, arama kalitesi, harita, fotoğraf kitlesi | Fiyat şeffaflığı, menü derinliği, topluluk katkı |
| **Trendyol Yemek / Getir Yemek** | Sipariş + teslimat, sıfır sürtünme | Restorana gitme deneyimi, menü keşfi, işletme araçları |
| **Foursquare / Swarm** | Check-in kültürü, konum zekâsı | Fiyat katmanı, aktif topluluk |
| **TripAdvisor** | Yorum kitlesi, turist trafiği | Yerel gerçek zamanlı fiyat, Türkçe kullanıcı deneyimi |
| **Yelp** | Yorum derinliği, işletme yanıtları | Fiyat şeffaflığı, topluluk görev sistemi |
| **Yemeksepeti** | Sipariş altyapısı, sadakat | Keşif deneyimi, menü detayı |

### 2.2 Dolaylı Rakipler (Kullanıcı Zamanı Çalan)

| Platform | Aldığı Kullanıcı Davranışı |
|---|---|
| **Instagram / TikTok** | Yemek ilham içeriği, restoran keşfi |
| **YouTube Shorts** | "Bu restoranı deneyin" videoları |
| **WhatsApp grup sohbetleri** | "Nereye gidelim?" kararları |
| **Twitter/X** | "Bu yerde yedim, berbattı/harikaydı" anlık paylaşım |

---

## 3. Kullanıcı Tarafı Kritik Eksikler

### P0 — Günlük Kullanım Alışkanlığı Oluşturan (Olmazsa Olmaz)

#### 3.1 Gerçek Zamanlı Açık/Kapalı + Kalabalık Durumu
**Ne eksik:** Kullanıcı uygulamayı açtığında "şu an açık mı?" sorusunu doğrudan göremez. Kalabalık tahmini (pik saatler) yok.  
**Rakip:** Google Maps "Genellikle bu saatte yoğun" gösteriyor.  
**Etki:** Kullanıcı Google Maps'e geçiyor, geri gelmiyor.  
**Çözüm:**
- `business_hours` zaten var → `is_open_now()` hesabı UI'a taşınsın
- `visits` tablosundan saatlik yoğunluk grafiği türetilsin
- Push notification: "Favori yerindeki kalabalık azaldı, tam vakti!"

#### 3.2 Yemek Fotoğrafı Galerisinin Yetersizliği
**Ne eksik:** `business_media` var ama kullanıcı yüklenen fotoğrafları kolayca tarayamıyor. Yemek başına fotoğraf sayısı düşük. Votable fotoğraf zaten var ama discovery yüzeyi eksik.  
**Rakip:** Zomato ve TripAdvisor'da her yemeğin onlarca fotoğrafı var.  
**Etki:** "Nasıl bir şey bu?" sorusu yanıtsız kalıyor.  
**Çözüm:**
- Menü ürünü detail sheet'te fotoğraf karusel — zaten `menu_item_photos` var, UI eksik
- Kullanıcı fotoğraf yükleme akışını basitleştir (kamera → yemek seç → yükle, 3 adım)
- "Bu yemeğin fotoğrafı yok" empty state'inde fotoğraf çek CTA

#### 3.3 Sosyal Check-In / "Buradayım" Akışı
**Ne eksik:** Kullanıcı restorandayken bunu paylaşamıyor. Arkadaşlar nerede yiyor göremiyor.  
**Rakip:** Foursquare'in temel özelliği buydu. Instagram story'nin yaptığı bu.  
**Etki:** App sosyal bir katman olmadan izole kalıyor.  
**Çözüm:**
- `visits` tablosu zaten var → "Check-in" UI akışı (1 tap: konumda mısın → onayla → paylaş)
- Takip ettiğin gurmelerin check-in'leri feed'de görünsün
- Check-in badge'i ile itibar katkısı

#### 3.4 Gerçek Zamanlı Günlük Menü / Spesiyaliteler
**Ne eksik:** İşletme "bugün mercimek çorbası var" diyemiyor; kullanıcı "bugün ne var?" göremez.  
**Rakip:** Hiçbiri tam yapamıyor — bu boş bir alan, Yeedoy doldurabilir.  
**Etki:** Hem işletme hem kullanıcı için günlük kullanım sebebi.  
**Çözüm:**
- `menu_items` tablosuna `is_today_special` boolean + notif trigger
- Push: "Favori yerinin bugünkü spesiyali: Kuzu tandır"
- Discovery'de "Bugünün Spesiyalleri" section

#### 3.5 Sesli Arama ve Doğal Dil Keşfi
**Ne eksik:** "Soğuk havada sıcak tutacak, 80 TL altı, yürüme mesafesinde" gibi arama yok.  
**Rakip:** Henüz kimse tam yapmadı — bu fırsat penceresi.  
**Çözüm:**
- Mevcut `find_businesses_v*` RPC'lerine semantik katman ekle
- Mikrofon CTA + konuşma metne dönüştürme + intent parsing (LLM ile)

#### 3.6 Kişiselleştirilmiş Diyet Filtresi ile Tam Menü Tarama
**Ne eksik:** `diyet_profil` modeli var ama discovery'de filtre olarak çalışmıyor. Glutensiz insan Yeedoy'da arama yapamıyor.  
**Çözüm:**
- `menu_items` tablosundaki alerjen alanlarını discovery filtrelerine bağla
- "Vejetaryen dostu işletmeler" discovery segment'i
- Profildeki diyet bilgisi otomatik olarak filtreleri pre-set etsin

#### 3.7 Offline Tam Çalışma
**Ne eksik:** Kayıtlı menüler internetsiz açılamıyor.  
**Çözüm:** `yerel_db` modelleri zaten var → favorileri tam offline önbellekle

---

### P1 — Güçlü Diferansiyatörler (Rakipten Kopar)

#### 3.8 Kullanıcı-Yemek Fotoğrafı → Otomatik Yemek Tanıma
Kullanıcı yemek fotoğrafı çekiyor → uygulama yemeği tanıyor → "Bu Adana kebap mı? Yeedoy'da değerlendir" CTA.

#### 3.9 Paylaşılabilir Yemek Kartı (Viral Döngü)
Her yemek/işletme için şık paylaşım kartı oluştur → WhatsApp, Instagram'da paylaşınca geri trafik gelsin.

#### 3.10 Grup Karar Yardımcısı (WhatsApp'a Rakip)
"5 kişi gidiyoruz, herkese sor" → link paylaş → herkes oyluyor → oy birliğiyle karar. Mevcut `grup_istekleri` bunun taslağı ama yeterli değil.

#### 3.11 Yemek Okul Çıkışı / Saat Bazlı Keşif
"Öğle arası 45 dk var, yürüme mesafesinde hızlı servis yapan" → zaman kısıtı filtresi.

#### 3.12 Fiyat Karşılaştırma: Aynı Yemek Farklı Restoran
"Bu şehirde adana kebap en ucuz nerede?" → doğrudan fiyat karşılaştırma sayfası.  
`karsilastirma` feature var ama menü ürünü bazında fiyat karşılaştırma yok.

#### 3.13 Kişisel Yemek Günlüğü
Yediklerini kaydet, harcama takibi yap, aylık istatistik gör. "Bu ay 12 farklı yerde yedim, 2.400 TL harcadım."

#### 3.14 İşletmeye Özel Menü Widget'ı
QR menü URL'sini işletme kendi sitesine/Instagram'ına gömebilmeli. `business_menu_presentation_settings` var ama embed kodu yok.

---

### P2 — Pazar Olgunlaştıkça Gerekli

- AR menü (yemeği masanın üstünde 3D gör)
- Apple Watch quick-glance (yakındaki favori açık mı?)
- Kalori bütçe takipçisi (günlük hedef)
- Mevsimsel menü vurgulama (kış menüsü, Ramazan menüsü)
- Hediye kartı sistemi
- Yemek kursu/workshop etkinlikleri

---

## 4. İşletme Tarafı Kritik Eksikler

### P0 — İşletmenin "Müşterim Arttı" Demesi İçin Zorunlu

#### 4.1 Müşteri Yorumlarına Cevap Verme
**Ne eksik:** İşletme sahibi yorumlara cevap veremiyor.  
**Rakip:** Yelp, TripAdvisor, Google Maps — hepsi var.  
**Etki:** İşletme pasif kalıyor. Olumsuz yorum patlaması kontrol edilemiyor.  
**Çözüm:**
- `reviews` tablosuna `owner_reply` alanı ekle
- Sahip panelinde "Yanıtlanmamış yorumlar" öncelik kuyruku
- Mobil uygulamada yanıt bildirim gösterimi

#### 4.2 Bugünün Spesiyali / Anlık Duyuru
**Ne eksik:** İşletme "bugün çorba bedava" diyemiyor.  
**Çözüm:**
- Sahip panelinde tek tap "Bugünün spesiyali" ekranı
- Takipçilere otomatik push bildirimi
- Discovery'de "Bugün indirimli" filtresi

#### 4.3 Takipçi Bildirimi Gönderme
**Ne eksik:** İşletmenin pazarlama kanalı yok. Takipçilerine hedefli mesaj gönderemiyor.  
**Rakip:** Instagram DM, WhatsApp Business bunu yapıyor.  
**Çözüm:**
- `favorites` = abone kitlesi → segmentli push bildirimi
- "Tüm takipçilere" veya "Son 30 günde gelenlere" gönder

#### 4.4 Rakip Fiyat Karşılaştırma Raporu
**Ne eksik:** İşletme rakiplerinin fiyatlarını sistematik göremez.  
**Yeedoy'un benzersiz avantajı:** Fiyat şeffaflığı verisi zaten var — B2B ürüne dönüştür.  
**Çözüm:**
- Sahip panelinde "Pazar Fiyat Raporu": benim X ürünüm bölge ortalamasının üstünde/altında mı?
- `admin_export_regional_price_index_csv_v1` verisi owner'a görsel rapor olarak sun

#### 4.5 Müşteri Geri Bildirim Dashboard'u (Gerçek Zamanlı)
**Ne eksik:** Sahip panelindeki analytics 30 günlük statik sayılar. Gerçek zamanlı yorum akışı yok.  
**Çözüm:**
- "Bugün gelen yorumlar" canlı akışı
- Duygu analizi özeti (pozitif/negatif/nötr)
- En çok bahsedilen menü ürünleri

#### 4.6 Menü Güncelleme Kolaylığı (Mobil Hızlı Düzenleme)
**Ne eksik:** Sahip sadece web panelinden menü güncelleyebiliyor. Sabah fiyat değişti → telefonda düzeltemez.  
**Çözüm:**
- Sahip uygulaması (owner-facing mobile app veya mobile-first web panel)
- "Hızlı fiyat güncelleme" tek ekran: ürün seç → yeni fiyat → kaydet

#### 4.7 QR'dan Sipariş (Table Ordering)
**Ne eksik:** QR menü sadece görüntüleme. Müşteri karekoddan sipariş veremiyor.  
**Rakip:** Yaygınlaşıyor (Square, Toast, Lightspeed).  
**Etki:** İşletme için masa devir hızı artar. Kullanıcı için bekleme azalır.  
**Çözüm:**
- Phase 1: "Garsona bildir" butonu (sipariş listesi gönder, garson geliyor)
- Phase 2: Entegre ödeme

---

### P1 — Diferansiyatör İşletme Araçları

#### 4.8 Müşteri Segmentasyonu (Kim Geliyor?)
Hangi mahalle, hangi yaş, hangi zaman → basit demografik analiz.  
`analytics_events` verisi var → raporlama katmanı eksik.

#### 4.9 Sadakat Kartı Oluşturucu
"10 kafaltı al, 1 bedava" → dijital damga kartı. Gerçekten basit. Müşteriyi tekrar getirir.

#### 4.10 Etkinlik / Özel Gece Duyurusu
"Cuma: Canlı müzik + özel menü" → etkinlik takvimi + bildirim.

#### 4.11 İşletme Sağlık Belgesi Gösterimi
Belediye denetim notu, hijyen sertifikası — güven artışı.

#### 4.12 Personel Tanıtımı / Şef Profili
"Ahmet Usta 20 yıllık deneyim" → insansallaştırma → bağ kurma.

#### 4.13 Teslimat / Paket Servis Durumu
"Şu an paket servis kapalı" gibi dinamik durum. Getir/Trendyol entegrasyon URL'si.

---

### P2 — Büyüme Fazında

- Catering talep formu ("50 kişilik organizasyon yapmak istiyorum")
- Hediye kartı satışı
- Masa rezervasyon entegrasyonu (The Fork, Resy API)
- POS entegrasyonu (otomatik menü senkronizasyonu)
- CRM: müşteri satın alma geçmişi (izinli, anonim aggregate)

---

## 5. Platform & Teknik Eksikler

### 5.1 Arama Kalitesi (Kritik P0)
**Mevcut durum:** Metin eşleşmesi bazlı arama.  
**Eksik:**
- Yazım hatası toleransı ("lahmacan" → "lahmacun")
- Semantik arama ("doyurucu ekonomik öğle yemeği")
- Konum ağırlıklı sıralama (500m yakın → önce göster)
- Popülerlik sinyali (anlık trend)

**Çözüm:** pgvector ile embedding tabanlı hibrit arama (metin + semantik + konum).

### 5.2 Bildirim Stratejisi (P0)
Mevcut: Push var ama hangi kullanıcıya ne zaman ne gönderilmeli tanımlı değil.

| Bildirim Türü | Tetikleyici | Hedef |
|---|---|---|
| "Favori yerinde fiyat değişti" | price_suggestion onaylandı | Fiyat alarmı koymuş kullanıcı |
| "Yakınında yeni açılan" | business onaylandı, <500m | Bölge kullanıcısı |
| "Gitmeyi düşündüğün yerde kalabalık azaldı" | visit yoğunluk verisi | Favori listesindeki |
| "Bugünün spesiyali" | owner ekledi | İşletme takipçisi |
| "Gurmen arkadaşın bir yere gitti" | check-in | Takip eden kullanıcı |

### 5.3 Deep Link Kalitesi (P1)
Her menü ürünü, her yorum, her işletme → direkt açılan paylaşılabilir URL.  
Sosyal paylaşımda OG görsel otomatik üretilsin (menü ürünü fotoğrafı + fiyat).

### 5.4 Web SEO (P0)
**Kritik sorun:** Public menü sayfaları Google'da indexlenmeli. "Adana'da en iyi kebap" araması Yeedoy'a gelmeli.  
`/m/[slug]` zaten SSR — ama:
- Her menü ürününün kendi URL'si yok (`/m/slug/urun/id` gibi)
- Structured data (JSON-LD: Restaurant, Menu, MenuItem) eksik
- İlçe/şehir bazlı category sayfaları yok (`/istanbul/besiktas/kahvalti`)
- Sitemap dinamik üretimi

### 5.5 Performans: İlk Açılış Hızı (P0)
Mobil uygulama ilk açılış hızı ve feed yüklenme süresi doğrudan bırakma oranını etkiler.  
RepaintBoundary var ama:
- Görsel lazy loading agresifliği
- Shimmer süresi → gerçek içerik geçişi
- Ağ yavaşken degraded mode (partial data göster, spin ettirme)

### 5.6 Harita Entegrasyonu Derinliği (P1)
Mevcut `kesif_harita_yuzeyi` var ama:
- İşletmeleri kümeleme (cluster) eksik → çok işletme varsa harita kullanılamaz
- Sokak görüntüsü (Street View) entegrasyonu
- Rota önerisi ("Yürüyerek 8 dk, toplu taşımayla 3 dk")

---

## 6. İçerik & Veri Kalitesi Eksikleri

### 6.1 Menü Veri Zenginliği (P0)
**Mevcut:** İsim + fiyat + bazen alerjen.  
**Eksik:**

| Alan | Önemi | Nasıl Doldurulur |
|---|---|---|
| Porsiyon büyüklüğü | Fiyat/değer kararı | OCR + owner form |
| Kalori aralığı | Diyet kararı | AI menü analizi planı zaten var |
| Hazırlama süresi | "Acelesi var mı" kararı | Owner girer |
| Ana malzeme | Alerjen + lezzet | AI + owner |
| Servis sıcaklığı | Soğuk/sıcak tercihi | Owner seçer |
| Spicy seviyesi | Kişisel tercih | 1-5 skalası, community vote |

### 6.2 Fotoğraf Kalitesi Standardı (P1)
Kullanıcı yüklediği fotoğraflar düşük kalite olabiliyor.  
- Minimum çözünürlük filtresi
- Blur detection (net olmayan fotoğraf reddedilsin)
- İşletme "onaylı kapak fotoğrafı" seçsin
- AI ile yemek/yemek-dışı sınıflandırma

### 6.3 Yorum Kalitesi (P1)
**Eksik:**
- Minimum karakter sınırı (anlamlı yorum)
- "Ne sipariş ettiniz?" zorunlu alanı
- Fotoğraflı yorum → daha görünür
- Yorum kullanışlılık oylaması (helpful/not helpful)
- Periyodik "Hâlâ aynı kalite mi?" hatırlatması

### 6.4 İşletme Bilgi Tazeliği (P0)
Kapanan işletmeler uygulamada aktif görünüyor. Kritik güven kaybı.
- "Bu işletme hâlâ açık mı?" topluluk sinyali
- Telefon numarası aktif mi? Otomatik test
- Google Maps ile çapraz referans (kapandı bildirimi)

---

## 7. Güven & Güvenlik Eksikleri

### 7.1 Sahte Yorum Tespiti (P0)
- Hesap yaşı < 7 gün + yorum → şüpheli flag
- Aynı IP'den birden fazla yorum
- Sıfır katkılı hesap yorumu ağırlığı düşük

### 7.2 İşletme Doğrulama Rozeti (P1)
"Bu işletme kimliğini doğruladı" → vergi no / ticaret sicil no ile eşleştirme.  
Doğrulanmış işletme → discovery'de üste çık.

### 7.3 Kullanıcı Yorum Geçmişi Şeffaflığı (P1)
Bir kullanıcının sadece bir işletmeye 5 yıldız verdiği görünür olmalı → güvenilirlik sorgulanabilsin.

### 7.4 KVKK / GDPR Tamamlanması (P0 — Yasal)
`lib/core/privacy` klasörü boş.  
- Açık rıza ekranı
- Veri silme talebi akışı
- Hangi veriler neden saklanıyor açıklaması
- Cookie consent (web)

---

## 8. Büyüme Motoru Eksikleri

### 8.1 Viral Döngü Yok (P0)
**Mevcut:** Kullanıcı büyümesi organik. Viral mekanik yok.  
**Gerekli:**
- Arkadaşını davet et → her ikisine de ödül
- "Paylaş kartı" → menü ürünü şık görsel + fiyat → WhatsApp'ta viral
- Yorum paylaş → Instagram story formatında

### 8.2 Onboarding Zayıf (P0)
İlk açılışta kullanıcıya değer gösterilmiyor.  
**Gerekli:**
- "Konumuna yakın 3 işletme" hemen göster (konum izni iste → kabul et → instant value)
- Diyet tercihi sor (3 seçenek, 1 ekran)
- İlk fiyat uyarısı kurma deneyimi

### 8.3 Email / SMS Pazarlama Döngüsü (P1)
Kullanıcı 7 gün girmedi → "Gittiğin yerden yeni yorum var" emaili.  
Mevcut: Push var. Email marketing yok.

### 8.4 Bölge Genişleme Altyapısı (P1)
Şehir bazlı içerik olgunluğu izlenmeli.  
"İzmir'de 50'den az işletme var → 'Yeedoy henüz burada zayıf' göster, katkı davetiyle birlikte."

---

## 9. Öncelik Matrisi

### Derhal Başlanacaklar (Kullanıcıyı Kaybetmeden Önce)

| # | Özellik | Etki | Durum |
|---|---|---|---|
| 1 | "Şu an açık mı?" gerçek zamanlı durumu | ⭐⭐⭐⭐⭐ | ✅ Tamamlandı (2026-05-06) |
| 2 | İşletme yorumlarına sahip yanıtı | ⭐⭐⭐⭐⭐ | ✅ Tamamlandı (2026-05-06) |
| 3 | Menü ürünü fotoğraf karuseli (`menu_item_photos` mevcut) | ⭐⭐⭐⭐⭐ | ✅ Tamamlandı (2026-05-06) |
| 4 | Yazım hatası toleranslı arama | ⭐⭐⭐⭐⭐ | ✅ Tamamlandı (2026-05-06) |
| 5 | KVKK rıza + veri silme akışı | ⭐⭐⭐⭐⭐ | ✅ Tamamlandı (2026-05-06) |
| 6 | SEO: JSON-LD structured data | ⭐⭐⭐⭐⭐ | ✅ Tamamlandı (2026-05-06) |
| 7 | Kapanan işletme tespiti | ⭐⭐⭐⭐ | ✅ Tamamlandı (2026-05-06) |
| 8 | Bildirim stratejisi (5 kritik trigger) | ⭐⭐⭐⭐ | ✅ Tamamlandı (2026-05-06) |

### 30 Gün İçinde (Diferansiyasyon)

| # | Özellik | Etki | Durum |
|---|---|---|---|
| 9 | Bugünün spesiyali (owner + kullanıcı) | ⭐⭐⭐⭐⭐ | ✅ Tamamlandı (2026-05-07) |
| 10 | Check-in akışı (visits tablosundan UI) | ⭐⭐⭐⭐ | ✅ Tamamlandı (2026-05-07) |
| 11 | Paylaşım kartı (menü ürünü/işletme) | ⭐⭐⭐⭐ | ✅ Tamamlandı (2026-05-07) |
| 12 | Kalori/porsiyon alanları + AI doldur | ⭐⭐⭐⭐ | ✅ Tamamlandı (2026-05-07) |
| 13 | Diyet filtresi discovery'ye bağlı | ⭐⭐⭐⭐ | ✅ Tamamlandı (2026-05-07) |
| 14 | Sahip → takipçi push bildirimi | ⭐⭐⭐⭐⭐ | ✅ Tamamlandı (2026-05-07) |
| 15 | Arama: konum + popülerlik sinyali | ⭐⭐⭐⭐ | ✅ Tamamlandı (2026-05-07) |

### 60–90 Gün (Büyüme Mekaniği)

| # | Özellik | Etki | Süre |
|---|---|---|---|
| 16 | Onboarding redesign (konum → anlık değer) | ⭐⭐⭐⭐⭐ | ✅ Tamamlandı (2026-05-07) |
| 17 | Rakip fiyat raporu (sahip paneli) | ⭐⭐⭐⭐⭐ | ✅ Tamamlandı (2026-05-07) |
| 18 | SEO: İlçe/şehir kategori sayfaları | ⭐⭐⭐⭐⭐ | ✅ Tamamlandı (2026-05-07) |
| 19 | QR → masa siparişi (Phase 1: garson bildir) | ⭐⭐⭐⭐⭐ | ✅ Tamamlandı (2026-05-07) |
| 20 | Grup karar yardımcısı (link paylaş → oy) | ⭐⭐⭐⭐ | ✅ Tamamlandı (2026-05-07) |
| 21 | Sadakat kartı (sahip → müşteri) | ⭐⭐⭐⭐ | ✅ Tamamlandı (2026-05-07) |
| 22 | Kişisel yemek günlüğü + harcama | ⭐⭐⭐⭐ | ✅ Tamamlandı (2026-05-07) |

---

## 10. Sektörde Boş Olan ve Yeedoy'un Sahiplenebileceği Alanlar

Bunları hiçbir rakip yapmıyor — Yeedoy erken hareket ederse piyasanın tek sahibi olabilir:

### 10.1 Fiyat Şeffaflığı Platformu
Zaten temeli var. Bunu medyaya, tüketici örgütlerine açık API olarak sun. "Türkiye'nin en büyük restoran fiyat endeksi" → PR, medya dikkat, organik büyüme.

### 10.2 Grup Yemek Karar Platformu
WhatsApp'ta "nereye gidelim?" sorusu milyonlarca kez soruluyor. Yeedoy bu kararı yönetmeli. Mevcut `grup_istekleri` bunu yapmak için tasarlanmış ama yüzey eksik.

### 10.3 Çalışan Öğle Yemeği Avantajı (B2B SaaS)
Şirketlere "Çalışanlarınıza aylık yemek bütçesi tahsis et, Yeedoy'da kullanılsın" → kurumsal abonelik. Yemek çeki'nin dijital versiyonu.

### 10.4 Askıda Yemek Ağının Genişletilmesi
Sosyal sorumluluk projesi + PR + kullanıcı bağlılığı üçlüsü. Hiçbir rakip yapmıyor.

### 10.5 Menü Enflasyon Takipçisi (Kamuoyuna Açık)
"Türkiye restoran menü fiyatları son 6 ayda %38 arttı" haberi medyaya kaynak olur → Yeedoy marka bilinirliği.

---

## 11. Kullanıcı Tutundurma (Retention) Formülü

Kullanıcı şu döngüde tutulmalı:

```
SABAH: "Bugünkü öğle seçeneklerin hazır" (push) → keşif
ÖĞLE: Menü bak → git → check-in → fotoğraf çek → puan kazan
AKŞAM: Yorum yaz → gurme puanı artar → haftalık liderlik tablosu
HAFTA SONU: Grubuna öneri yap → favori listesi paylaş → arkadaşları gelir
```

Bu döngüyü kapatan son iki halka eksik: **check-in** ve **paylaşım kartı**.

---

## 12. İşletme Büyütme Formülü

İşletme şunu yaşamalı:

```
DAY 1: Menüsünü 10 dakikada yükle → QR kodu çıktı al → masalara koy
WEEK 1: İlk yorumlar geldi → yanıt verdim → müşteri geri döndü
MONTH 1: Kalabalık saatlerimi gördüm → rakip fiyatlarını gördüm → bir ürünü indirdim
MONTH 3: Takipçilerime "hafta sonu özel menü" gönderdim → 40 rezervasyon
MONTH 6: "Yeedoy sayesinde müşterim arttı, olmaktan mutluyum"
```

Bu deneyimi kapatan son halkalar: **yanıt verme**, **takipçiye bildirim**, **rakip raporu**, **masa siparişi**.

---

*Son güncelleme: 2026-05-06 | Kaynak: Kod tabanı analizi + rakip araştırması*
