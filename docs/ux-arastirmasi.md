# Yeedoy UX Araştırması

**Tarih:** 2026-06-01
**Kapsam:** Mobil uygulama ve web platformu — kullanıcı deneyimi analizi ve aksiyon önerileri
**Yöntem:** Rekabet analizi, kod tabanı incelemesi, heuristic evaluation

---

## İçindekiler

1. [İlk 60 Saniye Karar Modeli](#1-i̇lk-60-saniye-karar-modeli)
2. [Google Maps'e Kaçış Noktaları](#2-google-mapse-kaçış-noktaları)
3. [Onboarding UX Önerileri](#3-onboarding-ux-önerileri)
4. [Keşif Ekranı UX Önerileri](#4-keşif-ekranı-ux-önerileri)
5. [İşletme Kartı UX Önerileri](#5-i̇şletme-kartı-ux-önerileri)
6. [Fiyat Güven Skoru UX Önerileri](#6-fiyat-güven-skoru-ux-önerileri)
7. [Harita Görünümü UX Önerileri](#7-harita-görünümü-ux-önerileri)
8. [Öncelikli UX Backlog](#8-öncelikli-ux-backlog)

---

## 1. İlk 60 Saniye Karar Modeli

### 1.1 Cognitive Load Haritası

| Zaman | Kullanıcının Zihinsel Sorusu | Kritik Unsur |
|---|---|---|
| **0-10s** | "Bu uygulama ne yapıyor, benim için mi?" | Karşılama ekranı değer önermesi |
| **10-20s** | "Benim konumuma yakın içerik var mı?" | Konum izni zamanı + boş durum |
| **20-40s** | "Bu bilgiler güncel ve güvenilir mi?" | Fotoğraf, fiyat, açık/kapalı göstergesi |
| **40-60s** | "Bu uygulamada neden kalayım?" | Aha moment — fiyat geçmişi, güven skoru |

---

**0-10 saniye — Değer Algısı:**
Kullanıcı iki paralel soru sorar: "Bu ne?" ve "Bu bana lazım mı?" Karşılama ekranı veya onboarding yüzeyi, Yeedoy'un fiyat şeffaflığı anlatısını bu ilk 10 saniyede net iletmezse kullanıcı yönelimini kaybeder.

**10-20 saniye — Mekan veya Kategori Seçimi:**
Kullanıcı keşif ekranına geçtiyse şehir/ilçe seçimi veya konum izni kararıyla karşılaşır. Bu dilimde zihinsel yük yüksektir. Uygulama konumu otomatik algılamazsa boş liste veya alakasız içerikle karşılaşılır; ilk kaçış tetiklenir.

**20-40 saniye — İçerik Kalitesi Değerlendirmesi:**
Kullanıcı ilk işletme kartlarını görür ve üç soruyu yanıtlamaya çalışır: "Bildiğim yerler var mı?", "Fiyatlar gerçek mi?", "Fotoğraf var mı?" Bu soruların yanıtı olumlu değilse kalma motivasyonu hızla düşer. Fotoğraf eksikliği ve açık/kapalı durumun görünmemesi bu dilimde kritik kaçış tetikleyicisidir.

**40-60 saniye — Eylem veya Terk:**
Kullanıcı ya bir işletme kartına dokunur, filtrelerle oynar ya da uygulamayı kapatır. "Aha moment" gelmişse (fiyat geçmişi sparkline'ı ilk kez görüldüğünde) kullanıcı kalır. Gelmemişse uygulama arka plana atılır.

---

### 1.2 Kaçış Tetikleyicileri

1. **Açık/kapalı durumu görünmüyor** → Gidecek yer var mı bilinmiyor → Google Maps
2. **Fotoğraf yok** → Yemeğin nasıl göründüğü bilinmiyor → Instagram / Google Maps
3. **Boş keşif ekranı** → Konum izni verilmedi veya ilçede işletme yok → Uygulama kapatılır
4. **Yükleme çok uzun** → Sabırsızlanır → Uygulama kapatılır
5. **Değer anlaşılamadı** → Fiyat şeffaflığının ne anlama geldiği ilk bakışta anlaşılmıyor

### 1.3 Retention Tetikleyicileri

1. Tanınan işletmenin listede görünmesi → anlık tanıma bağlılığı
2. Fiyat geçmişi sparkline'ı → "rakiplerde bu yok" hissi
3. "X kişi onayladı" rozeti → topluluk güveni
4. Yakında beklenenden ucuz işletme → eylem motivasyonu

---

## 2. Google Maps'e Kaçış Noktaları

### Senaryo 1 — Açık/Kapalı Bilgisi Eksikliği

**Tetikleyici:** İşletmeyi beğendi ama şu an açık olup olmadığını göremedi.
**Kaçış:** Google Maps'te işletme adını arar, açık/kapalı bilgisini görür, navigasyon alır — geri dönmez.
**Çözüm:** `business_hours` tablosu mevcut. `is_open_now()` hesabı UI'a taşınmalı; kart üzerinde yeşil "Açık" / kırmızı "Kapalı" badge görünmeli.
**Öncelik:** **Acil**

---

### Senaryo 2 — Fotoğraf Eksikliği

**Tetikleyici:** Menü öğesi için fotoğraf yok. "Nasıl bir şey bu?" sorusu yanıtsız kaldı.
**Kaçış:** Instagram veya Google Maps'e geçer, fotoğraflara bakar, orada kalır.
**Çözüm:** `menu_item_photos` tablosu var, UI yüzeyi eksik. Menü item detail sheet'te fotoğraf karuseli eklenmeli. Empty state'te "Fotoğraf Ekle" CTA gösterilmeli.
**Öncelik:** **Acil**

---

### Senaryo 3 — Harita Görünümü Yok

**Tetikleyici:** "Yakınımda ne var?" sorusunu görsel olarak yanıtlamak istedi. Liste mekansal ilişkiyi göstermiyor.
**Kaçış:** Doğrudan Google Maps'i açar, "restoran" arar, haritada yakını görür. Geri dönmez.
**Çözüm:** `HaritaIstemcisi` ve `react-leaflet` altyapısı kurulmuş. Pin tasarımı fiyat bilgisi göstermeli, cluster mekanizması eklenmeli.
**Öncelik:** **Acil**

---

### Senaryo 4 — Yönlendirme Eksikliği

**Tetikleyici:** Adresi gördü ama navigasyon almak istiyor.
**Kaçış:** Adrese dokunuyor → Google Maps açılıyor → orada kalıyor.
**Çözüm:** "Yol Tarifi Al" butonu işletme detay sayfasında açıkça yerleştirilmeli. Bu davranış pattern kabul edilebilir; ancak mesafe ve tahmini yürüyüş süresi kart üzerinde gösterilmeli.
**Öncelik:** 3 ay

---

### Senaryo 5 — Çalışma Saatleri Belirsizliği

**Tetikleyici:** Saatler liste formatında gösterildi ama "şu an kapalı, ne zaman açılıyor?" bilgisi net değil.
**Kaçış:** Google Maps'te "Bugün 09:00'da açılıyor" gibi dinamik mesajı görür.
**Çözüm:** Aktif güne highlight, "Şu an kapalı — 18:00'de açılıyor" dinamik mesajı. `eksik.md` W-26 bunu işaret ediyor.
**Öncelik:** **Acil**

---

### Senaryo 6 — Arama Kalitesi

**Tetikleyici:** "lahmacan" yazdı ama "lahmacun" bulamadı. Semantik sonuç gelmiyor.
**Kaçış:** Google'da "[ilçe] kahvaltı yerleri" arar → TripAdvisor veya Google Maps'e gider.
**Çözüm:** Yazım hatası toleranslı arama (fuzzy matching), konum ağırlıklı sıralama. `rekabet-analizi-ve-eksik-ozellikler.md` P0 5.1 belgeliyor.
**Öncelik:** **Acil**

---

### Senaryo 7 — Kapanan/Yanlış İşletme

**Tetikleyici:** Uygulamada aktif görünen işletmeye gitti ama kapalıydı veya kapanmıştı.
**Kaçış:** Güven tamamen kaybedilir. Kullanıcı bir daha Yeedoy'a güvenmeyebilir.
**Çözüm:** "Bu işletme hâlâ açık mı?" topluluk sinyali arayüzü. Kapanan işletmeler için "Kapalı Olduğu Bildirildi" badge.
**Öncelik:** **Acil**

---

### Senaryo 8 — Fiyat Güncelliği Şüphesi

**Tetikleyici:** Fiyatı gördü ama "Bu bilgi ne kadar eski?" diye merak etti. Confidence skoru görünmüyorsa bilgiye güvenmez.
**Kaçış:** Google Maps'e geçer (fiyat yok ama "daha güncel olabilir" hissi) veya uygulamayı kapatır.
**Çözüm:** Her fiyatın yanında "N gün önce güncellendi" veya güven skoru rozeti. Confidence düşükse farklı renk. "Fiyatı Doğrula" CTA.
**Öncelik:** **Acil**

---

## 3. Onboarding UX Önerileri

### 3.1 Karşılama Ekranı — 5 Slayt Yapısı

Mevcut onboarding 5 slayttan oluşuyor (`onboarding_sayfasi.dart`). Yeniden yapılandırma önerisi:

| Slayt | İçerik | Amaç |
|---|---|---|
| **1** | Problem: "Menüde fiyat yok mu? Restorana gidince farklı fiyat mı gördün?" | Duygusal bağ kur |
| **2** | Çözüm: Fiyat geçmişi sparkline görseli + "Türkiye'nin ilk fiyat şeffaflık platformu" | Differansiyatörü göster |
| **3** | Sosyal kanıt: "47.000 fiyat topluluk tarafından doğrulandı" sayısı | Güven ver |
| **4** | Konum izni (bağlam kurulduktan sonra) | İzin kabul oranını artır |
| **5** | "Yakınındaki 3 işletmeyi şimdi gör" CTA | Keşife bağla |

**Değer önermesi "Fiyat Endeksi" somut örnekle güçlendirilebilir:**
"Adana kebap 6 ayda %40 arttı — sen bunu bildin mi?" → "Türkiye'nin ilk fiyat şeffaflık platformu" ifadesinden çok daha güçlü.

---

### 3.2 Konum İzni Zamanlaması

**Yanlış:** Uygulama açılır açılmaz native dialog sormak → kabul oranı düşük.

**Doğru:** Kullanıcı keşif sekmesine ilk dokunduğu anda sormak. Bu noktada:
- Bağlam netleşmiş: "Yakınımdakileri görmek istiyorum"
- Kullanıcı motivasyonu zirve noktasında

**İzin verilmezse fallback:**
1. İstanbul seçili olarak şehir dropdown'ı aç
2. İlçe seçimi opsiyonel — şehir seçimi yeterli
3. "Yeedoy bu bölgede henüz az veri var" mesajı dürüstçe verilmeli
4. Asla boş beyaz sayfa gösterilmemeli

---

### 3.3 Aha Moment Tasarımı

Yeedoy'un "aha moment"i fiyat geçmişini ilk gördüğünde gerçekleşir. Bu momenti hızlandırmak için:

- Onboarding biter bitmez keşif listesinde "Fiyatı Son 3 Ayda En Çok Değişen" section'ı göster
- Kullanıcı ilk işletme kartına dokunduğunda menü item sparkline'ının görünürlüğü artırılmalı
- İlk oturumda fiyat geçmişi alanı pulse animasyonu ile dikkat çekmeli

---

### 3.4 Boş Durum Standartları

İlçede işletme yoksa veya konum izni verilmediyse:

- İlüstrasyon (mekan arama teması — `AppEmptyState` component mevcut)
- Dürüst mesaj: "Bu ilçede henüz az işletme var"
- Birincil CTA: "İşletme Ekle" veya "Başka İlçeye Bak"
- İkincil CTA: Şehir değiştir
- **Asla** sadece spinner veya boş liste gösterilmemeli

---

## 4. Keşif Ekranı UX Önerileri

### 4.1 Bilgi Hiyerarşisi

Ana keşif ekranında içerik öncelik sırası:

1. Konum/bağlam bilgisi (şu an hangi ilçeye bakılıyor?)
2. Hızlı kategori filtreleri (yatay scroll chip'ler)
3. Öne çıkan section (bugün popüler / fiyatı düşen / yeni eklenen)
4. Ana işletme listesi

HeroSearchSection + CategoryFilterChips + BusinessGrid yapısı korunmalı; üstteki section kişiselleştirilmeli.

---

### 4.2 Filtre UX

Maximum 5 primary filtre — çok filtre kullanıcıyı bunaltır:

| Filtre | Format | Notlar |
|---|---|---|
| Şu An Açık | Toggle (her zaman görünür) | En sık kullanılan |
| Mutfak türü | Dropdown / bottom sheet | — |
| Fiyat aralığı | ₺ / ₺₺ / ₺₺₺ chip | — |
| Mesafe | Yakınımda / 500m / 1km | Konum varsa aktif |
| Puan | 4+ yıldız toggle | — |

Aktif filtre sayısı badge olarak gösterilmeli (`eksik.md` M-23: filtre badge sayısı eksik).
"Tümünü Temizle" tek dokunuşla çalışmalı.

---

### 4.3 Liste–Harita Geçiş Mekanizması

**Öneri: FAB (Floating Action Button)**

| Mekanizma | Avantaj | Dezavantaj |
|---|---|---|
| FAB (önerilen) | Liste alanını kaplamaz | Haritayı geçici gizleyebilir |
| Tab (Liste / Harita) | Her zaman görünür | Yer kaplar |
| Toggle button (üst sağ) | Kompakt | Göze çarpmayabilir |

Implementasyon:
- Listede sağ alt köşe → "Haritada Gör" FAB
- Haritada sol alt → "Listeye Dön" butonu
- Görünüm tercihi oturum boyunca saklanmalı

---

### 4.4 Infinite Scroll vs. Pagination

- Mobil: Infinite scroll — ilk 20 kart, scroll sonunda 20 daha
- Web: Pagination — SEO ve URL state için daha uygun
- Yükleme sırasında skeleton card (mevcut `AppSkeletonCard` var — kullanım kapsamı artırılmalı)
- "Sonuna ulaştınız" mesajı açıkça verilmeli

---

### 4.5 Yükleme ve Boş Sonuç Durumları

**Yükleme:**
- Shimmer animasyonu soldan sağa
- 3 saniye aşılırsa "Yavaş bağlantı — kısmi veri gösteriliyor" degraded modu

**Filtre sonrası boş sonuç:**
- "Bu kriterlere uyan işletme bulunamadı"
- Hangi filtreler aktif → göster
- "Filtreleri Temizle" birincil CTA
- "Yakın ilçelere bak" alternatif öneri

---

## 5. İşletme Kartı UX Önerileri

### 5.1 Kart Boyutu

- Mobil liste: Fotoğraf 16:9 oranında, kart toplam yüksekliği ~200-220px
- Web grid: 3 kolon (masaüstü) / 2 kolon (tablet) / 1 kolon (mobil)
- Dokunma hedefi minimum 44×44 px (iOS HIG + Material Design standardı)
- Kart tamamı tıklanabilir; favori/paylaş ikonları ayrı hit alanı

---

### 5.2 Zorunlu Bilgiler (Eksikse Kart Eksiktir)

| Bilgi | Notlar |
|---|---|
| İşletme adı | Her zaman görünür |
| Açık/Kapalı badge | Yeşil/kırmızı — şu an durumu |
| Fiyat aralığı | ₺₺ sembol + kişi başı ortalama TL |
| Kategori / mutfak türü | "Kebap", "Kahvaltı", "Kafe" |
| Mesafe | "350 m" veya "1.2 km" (konum varsa) |
| Güven göstergesi | Yıldız veya confidence rozeti |

---

### 5.3 Opsiyonel Bilgiler

| Bilgi | Etki |
|---|---|
| Fotoğraf | En yüksek etki |
| "N fiyat doğrulandı" rozeti | Yeedoy differansiyatörü |
| Fiyat değişim oku (↑↓) | Trend sinyali |
| "Bugünün spesiyali" etiketi | Engagement artıran |
| Son yorum snippet | Tek cümle sosyal kanıt |

---

### 5.4 Fotoğraf Eksikliği Durumu

Fotoğraf yoksa placeholder tercih sırası:
1. Kategori ikonu + renkli gradient (kahvaltı = sarı-turuncu, kebap = kırmızı-turuncu)
2. İşletme adının baş harfleri avatar formatında
3. **Asla boş gri kutu gösterilmemeli**

"Fotoğraf Ekle" CTA overlay olarak placeholder üzerinde gösterilebilir.

---

### 5.5 Açık/Kapalı Badge Tasarımı

- "Açık": Yeşil arka plan, beyaz metin, kart üst sol köşe
- "Kapalı": Gri — daha az dikkat çekici
- Dinamik format tercih: "Kapalı — 18:00'de açılıyor"
- Fotoğraf varsa badge foto üzerine overlay; yoksa başlık satırında

---

### 5.6 Fiyat Gösterimi

İkili gösterim:
```
₺₺  ·  Ort. 180 TL/kişi
```

Türkiye'de yıllık gıda enflasyonu %48,6 (Aralık 2025) ortamında sayısal değer sembol kadar kritik. Yalnızca ₺₺₺ sembolü yeterli bilgi taşımıyor.

---

### 5.7 Güven Skoru Kart Üzerinde

- Yıldız (1-5) + "N değerlendirme" — tanıdık pattern
- Fiyat confidence için ayrı mini rozet: "127 onay" veya "Yüksek Güven" etiketi
- İki katmanlı sistem (topluluk güveni + veri güveni) kart üzerinde tek puana indirgenebilir; detay sayfasında ayrıştırılır

---

## 6. Fiyat Güven Skoru UX Önerileri

### 6.1 Görsel Dil Seçenekleri

| Seçenek | Biçim | Avantaj |
|---|---|---|
| A — Sayısal + Renk | "Güven: 87" — 0-40 kırmızı, 41-70 sarı, 71-100 yeşil | Hızlı okuma |
| B — İkon + Metin **(önerilen)** | "Yüksek Güven" / "Orta Güven" / "Düşük Güven" + renk | "87 ne anlama geliyor?" sorusunu önler |
| C — Progress Bar | Görsel yüzde bar | Sezgisel ama yer kaplar |

**Öneri: Seçenek B** — ikon + metin üçlü skalası. Kullanıcı araştırmalarında en anlaşılır bulunan format.

---

### 6.2 "Topluluk Tarafından Doğrulandı" Mesaj Formatları

| Bağlam | Format |
|---|---|
| Kart üzerinde (kısa) | "127 kişi onayladı" |
| İşletme detayı (orta) | "Bu fiyat son 30 günde 127 Yeedoy kullanıcısı tarafından doğrulandı" |
| Bilgi tooltip (uzun) | Doğrulamanın nasıl yapıldığını açıklayan kısa paragraf |
| Fiş doğrulaması | "Fişle doğrulandı" rozeti — en yüksek güven sinyali, ayrıca belirtilmeli |

---

### 6.3 Fiyat Geçmişi Sparkline

- **Nerede:** Menü item detail sheet'te fiyatın hemen altında
- **Boyut:** Genişlik ~80px, yükseklik ~24px
- **Veri:** Son 6 veya 12 ay
- **Renk:** Artış trendi → kırmızı, düşüş → yeşil, stabil → nötr
- **Etkileşim:** Dokunulduğunda tam grafik modal açılır
- **NOT:** Discovery listesinde kart üzerinde gösterilmemeli — kart kalabalıklaşır

---

### 6.4 Fiyat Anomalisi Uyarısı

- **Menü item satırı:** Turuncu badge — "Son 1 ayda %20 arttı"
- **İşletme detay banner:** "Bu işletmede son 30 günde ortalama fiyat artışı: %23 — şehir ortalamasının 2x üzerinde"
- **Push bildirim:** "Favorindeki [işletme adı]'nda fiyat değişimi algılandı"

Uyarı tonlaması nötr ve bilgilendirici olmalı:
- ❌ "Dikkat! Fiyat arttı!"
- ✅ "Bilgi: Bu işletmede fiyat değişimi algılandı"

---

### 6.5 "Fiyat Güncelle" CTA Zamanlaması

CTA her zaman görünür olmamalı — yalnızca bağlamda anlam ifade ettiğinde:

- Menü item detail sayfasında fiyat satırı yanında küçük düzenle ikonu
- Güven skoru düşükse (3+ aylık veri): "Bu fiyat 3 ay önce güncellendi — doğru mu?" banner
- İşletmeden yeni çıkan kullanıcıya push önerisi: "Fiyatları doğrula"
- Sürekli görünen CTA → banner körlüğü riski

---

### 6.6 Düşük Güven İşletmeleri

- Sarı uyarı badge: "Fiyat bilgisi eski olabilir"
- Kart üzerinde hafif opacity azaltma veya farklı border
- İşletme detayında: "Son güncelleme 4 ay önce — fiyatlar değişmiş olabilir"
- Discovery listesinde düşük güvenli işletmeler varsayılan olarak alta sıralanmalı
- **Asla yanlış bilgi varmış gibi gösterilmemeli** — şeffaflık öncelikli

---

## 7. Harita Görünümü UX Önerileri

### 7.1 Liste-Harita Geçiş Mekanizması

**Öneri: FAB**

- Liste ekranı sağ alt köşe → "Haritada Gör" FAB (harita ikonu + metin label)
- Harita ekranı sol alt → "Listeye Dön" butonu
- Aynı pattern: Google Maps, Airbnb, Booking.com

---

### 7.2 Harita Pin Tasarımı

**Varsayılan:** Minimal pin (kategori ikonu) — kalabalıkta okunabilirlik yüksek

**Seçili durumda:** Fiyat/isim etiketi açılır

**Cluster:** "5+" sayı göstergesi — kalabalık şehirlerde zorunlu. Tıklandığında zoom veya mini liste açılır.

Mevcut `HaritaIstemcisi` `CircleMarker` kullanıyor. Özel pin SVG + cluster kütüphanesi (örn. `react-leaflet-cluster`) eklenmeli.

---

### 7.3 Seçili Pin Bottom Sheet

- Karta dokunulduğunda ekranın altından mini bottom sheet açılır (drag to expand)
- **Mini kart içeriği:** Küçük fotoğraf + İsim + Açık/Kapalı + Puan + "Detaya Git" butonu
- **Expand:** Tam işletme kartı bilgisi
- **Dismiss:** Aşağı swipe veya haritaya dokun
- Harita arka planda görünür kalmaya devam etmeli

---

### 7.4 "Şu An Açık" Filtresi — Haritada Davranış

- Toggle aktifken kapalı işletme pinleri gizlenir veya saydam gösterilir
- Filtre değiştiğinde pin animasyonu (fade in/out)
- Harita üzerinde sürekli görünür mini filtre bar: "Şu An Açık" toggle + kategori chip

---

### 7.5 Mesafe ve Yön

- Konum varsa: "350 m · Yürüyerek 4 dk" kart ve bottom sheet'te gösterilmeli
- Sürüş süresi: Opsiyonel (basit mesafe hesabı OpenStreetMap ile yeterli)
- "Konumuma Git" butonu harita üst sağ — haritayı kaydıran kullanıcının dönmesi için

---

## 8. Öncelikli UX Backlog

| # | Öneri | Kategori | Etki | Efor | Öncelik |
|---|---|---|---|---|---|
| 1 | Açık/Kapalı badge tüm kartlarda | Kart | Yüksek | Düşük | **Acil** |
| 2 | Harita görünümü (altyapı hazır) | Keşif | Yüksek | Orta | **Acil** |
| 3 | Menü item fotoğraf karuseli | Detay | Yüksek | Düşük | **Acil** |
| 4 | Fiyat confidence rozeti kart üzerinde | Güven | Yüksek | Düşük | **Acil** |
| 5 | "N kişi onayladı" rozeti | Güven | Yüksek | Düşük | **Acil** |
| 6 | "18:00'de açılıyor" dinamik mesajı | Kart | Yüksek | Düşük | **Acil** |
| 7 | Boş durum illüstrasyonu + CTA | Keşif | Orta | Düşük | **Acil** |
| 8 | Skeleton card tüm liste ekranlarında | Yükleme | Orta | Düşük | **Acil** |
| 9 | Onboarding Slayt 1: problem ekranı | Onboarding | Yüksek | Düşük | **Acil** |
| 10 | Konum izni bağlamlı zamanlama | Onboarding | Orta | Düşük | **Acil** |
| 11 | Fiyat geçmişi sparkline (item detail) | Güven | Yüksek | Orta | 3 ay |
| 12 | Liste-Harita FAB | Keşif | Yüksek | Düşük | 3 ay |
| 13 | Harita cluster mekanizması | Harita | Yüksek | Orta | 3 ay |
| 14 | Seçili pin bottom sheet | Harita | Yüksek | Orta | 3 ay |
| 15 | Filtre badge sayısı (aktif filtre) | Keşif | Orta | Düşük | 3 ay |
| 16 | Fiyat anomalisi uyarı badge | Güven | Yüksek | Orta | 3 ay |
| 17 | "Fotoğraf Ekle" CTA placeholder üzerinde | Kart | Orta | Düşük | 3 ay |
| 18 | Aha moment — fiyat history highlight (ilk oturum) | Onboarding | Yüksek | Düşük | 3 ay |
| 19 | Kişi başı ortalama TL kart üzerinde | Kart | Orta | Düşük | 3 ay |
| 20 | Düşük güven işletme badge + sıralama | Güven | Yüksek | Orta | 3 ay |
| 21 | "Yol Tarifi Al" butonu detay sayfasında | Detay | Orta | Düşük | 3 ay |
| 22 | Harita "Şu An Açık" toggle filtresi | Harita | Orta | Düşük | 3 ay |
| 23 | Onboarding Slayt 2: somut fiyat örneği | Onboarding | Yüksek | Düşük | 3 ay |
| 24 | "Fiyat Güncelle" CTA bağlamsal gösterim | Güven | Orta | Düşük | 6 ay |
| 25 | Fiyat anomalisi push bildirimi | Güven | Yüksek | Orta | 6 ay |
| 26 | Harita pin — fiyat etiketi (seçili hâlde) | Harita | Orta | Orta | 6 ay |
| 27 | "Konumuma Git" butonu harita | Harita | Orta | Düşük | 6 ay |
| 28 | Kapanan işletme topluluk sinyali | Veri Kalitesi | Yüksek | Orta | 6 ay |
| 29 | İşletme detayında doğrulanmış bilgi rozeti | Güven | Orta | Orta | 6 ay |
| 30 | Keşif "bugün popüler" section | Keşif | Orta | Orta | 6 ay |

---

*İlgili dosyalar:*
- `docs/rekabet.md` — rekabet analizi ve fırsat haritası
- `docs/seo-stratejisi.md` — SEO ve URL mimarisi
- `uygulamalar/mobil/` — Flutter mobil uygulama
- `uygulamalar/web/` — Next.js web uygulaması
