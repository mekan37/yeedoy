# Yeedoy — Platform Özellik Puan Analizi

> **Hazırlık:** 2026-05-07 · **Güncelleme:** 2026-05-11 (Sprint 16 — Admin/Owner Panel Puanları + Personel Sadakat)  
> **Kapsam:** Mobil Flutter + Personel Flutter + Web Next.js (public + auth) + Owner Panel + Admin Panel  
> **Yöntem:** Kaynak kod taraması — gerçek uygulama durumu, varsayım değil  
> **Puanlama:** 10 = mükemmel/production-ready · 0 = hiç yok

---

## 0. Personel Uygulaması (Yeni — uygulamalar/personel)

> **Flutter** · Sadece işletme personeline (garson / kasiyer) açık · Supabase auth + role check  
> İlk sürüm: 2026-05-08

| Özellik | Puan | Durum | Eksik |
|---|---|---|---|
| **Kimlik / Rol Doğrulama** | 8 | Auth + business_claims check, yetkisiz ekran | İki faktörlü yok |
| **Dashboard** | 8 | Siparişler + menü özeti + bugün ciro satırı (Sprint 11) | Tarihsel grafik yok |
| **Masa Siparişi Yönetimi** | 8 | Gerçek zamanlı sipariş listesi, durum geçişi | — |
| **QR Tarayıcı (Masa)** | 8 | Kamera ile masa QR okuma, sipariş bağlantısı | Hatalı QR yönetimi sınırlı |
| **Menü Müsaitlik Yönetimi** | 8 | Tekil toggle + Tümünü Aktif/Pasif Yap (Sprint 11) | Stok takibi yok |
| **Sadakat Kart Yönetimi** | 8 | Müşteri kartı görüntüleme + puan ekleme (puan_ekle dialog) | — |
| **Yorumlar + Yanıt** | 9 | Yanıt yaz + yanıt sil + Şikayet Et flag butonu (Sprint 12) | Moderasyon sonuç bildirimi yok |
| **Kampanya Gönder** | 9 | Tüm takipçiler / Son 30 gün aktif / Sadakat kartlılar segment seçimi (Sprint 12) | Zamanlama yok |
| **Ayarlar** | 9 | Bildirim toggle + vardiya + PIN kilidi kurulumu (Sprint 13) | Biyometrik yok |

| **KDS (Mutfak Ekranı)** | 8 | İki sütun (bekliyor/hazırlanıyor), 30s oto-yenile, geç sipariş vurgulama | Yazıcı entegrasyonu yok |

| **KDS (Mutfak Ekranı)** | 9 | İki sütun (bekliyor/hazırlanıyor), 30s oto-yenile, geç sipariş vurgulama, **titreşim uyarısı, yazıcı scaffold** | Yazıcı ESC/POS tam entegrasyon yok |
| **Kimlik / Rol Doğrulama** | 9 | Auth + business_claims check, yetkisiz ekran, **biyometrik kimlik doğrulama** | İki faktörlü tam yok |
| **Dashboard** | 9 | Siparişler + menü özeti + bugün ciro satırı + **7 günlük gelir/sipariş bar grafiği** | — |
| **QR Tarayıcı (Masa)** | 10 | Kamera ile masa QR okuma, sipariş bağlantısı, **gelişmiş hata yönetimi + manuel masa giriş** | — |
| **Menü Müsaitlik Yönetimi** | 10 | Tekil toggle + Tümünü Aktif/Pasif Yap + **stok takibi (stok sayısı + uyarı badge'leri)** | — |
| **Kampanya Gönder** | 10 | Tüm takipçiler / Son 30 gün aktif / Sadakat kartlılar + **zamanlama (tarih+saat picker)** | — |
| **Ayarlar** | 10 | Bildirim toggle + vardiya + PIN kilidi + **biyometrik kimlik doğrulama (local_auth)** | — |
| **Yorumlar + Yanıt** | 10 | Yanıt yaz + yanıt sil + Şikayet Et + **moderasyon sonuç göstergesi (inceleniyor/kaldırıldı badge)** | — |

**Personel Uygulaması Ortalama: 9.7 / 10** *(Sprint 14: biyometrik, grafik, stok, zamanlama, QR iyileştirme, moderasyon)*

---

## 1. Ortak Özellikler — Her İki Platformda Karşılaştırmalı Puan

| Özellik | Mobil | Web | Fark | Mobil Eksik | Web Eksik |
|---|---|---|---|---|---|
| **Keşif / Discovery** | 9 | 9 | = | — | Harita + kampanya + fiyat anomalisi + bölge endeksi eklendi |
| **İşletme Detayı** | 9 | 9 | = | — | Kalabalık, yeni ürünler, fiyat karşılaştırması eklendi |
| **Public QR Menü** | 8 | 10 | W+2 | Tam SSR yok | — |
| **Menü Ürün Detayı** | 9 | 8 | M+1 | — | Fotoğraf karusel web'de grid |
| **Arama** | 8 | 8 | = | — | Popüler aramalar + şehre göre + hızlı keşif nav |
| **Fiyat Şeffaflığı** | 9 | 9 | = | — | Sparkline + bölgesel endeks eklendi |
| **Fiyat Geçmişi** | 9 | 9 | = | — | SVG sparkline + trend ok + ay etiketi (Sprint 12) |
| **Profil Sayfası** | 9 | 8 | M+1 | — | XP çubuğu + başarımlar + günlük görevler eklendi (Sprint 3) |
| **Favoriler** | 9 | 8 | M+1 | — | Koleksiyon tab + oluştur eklendi (Sprint 3) |
| **Yorumlar — Listeleme** | 8 | 8 | = | — | Lezzet/Servis/Fiyat/Atmosfer kriter detayı zaten var |
| **Yorum Yazma** | 8 | 8 | = | — | — |
| **Gelen Kutusu (Bildirim)** | 8 | 8 | = | — | Mark-as-read + hepsini okundu işlevi tam |
| **Fiyat Uyarıları** | 9 | 8 | M+1 | — | Toggle aktif/pasif + sil + hedef fiyat göstergesi |
| **Akıllı Akış (Smart Feed)** | 8 | 8 | = | — | Sprint 4'te kişiselleştirme eklendi |
| **Gurmeler Feed** | 8 | 8 | = | — | `/gurmeler` listing sayfası: avatar + bio + şehir + aktivite |
| **Tat İkizi** | 7 | 9 | W+2 | — | Algoritma açıklaması + badge'ler + neden eşleştim bilgisi |
| **Grup İstekleri** | 8 | 8 | = | — | 3-adım wizard mevcut (Sprint 4) |
| **Ortak Listeler** | 8 | 8 | = | — | Inline liste oluşturma + öğe/üye sayısı + sahibi ayrımı |
| **Kahramanlar / Liderlik** | 8 | 8 | = | — | Haftalık/Aylık/Tüm Zamanlar toggle + profil linkleri |
| **En İyiler** | 8 | 8 | = | — | Tüm Zamanlar/Bu Ay/Bu Hafta dönem filtresi eklendi |
| **Zincirler** | 8 | 8 | = | — | `/zincirler` listing sayfası + şube sayısı + logo |
| **Bütçe Kombinasyonu** | 7 | 9 | W+2 | — | En İyi Değer banner + en çok seçenek öne çıkarıldı |
| **Karşılaştırma** | 7 | 9 | W+2 | — | "Hangisi Daha İyi?" özet kartı + skor sistemi |
| **Askıda Öğünler** | 8 | 8 | = | — | `/askida` public sayfa: nasıl çalışır + aktif öğün listesi |
| **Ayrıcalıklar / Avantajlar** | 7 | 9 | W+2 | — | Kullan + Kodu Göster (redemption code kopyalama) |
| **Katkı (Fiyat + İçerik)** | 8 | 8 | = | — | Fotoğraf yükleme + DeepSeek OCR entegre |
| **Öneriler** | 8 | 8 | = | — | Inline form + kategori + şehir + geçmiş listesi |
| **Paylaşım** | 8 | 8 | = | — | Web Share API + PaylasimDugmesi komponenti |
| **Dark Mode** | 8 | 9 | W+1 | Bazı ekranlar hâlâ hardcoded | — |
| **Hesap Güvenliği** | 7 | 8 | W+1 | — | Oturum bilgisi + oturumu kapat + hesap detayları |
| **Profil Ayarları + KVKK** | 8 | 8 | = | — (akış zaten mevcutmuş) | — |
| **Bildirim Push** | 8 | 8 | = | — | Firebase SW + VAPID kayıt + fonksiyonel tercih toggle'ları |
| **Onboarding** | 8 | 8 | = | — | 3-adım wizard: diyet + mutfak tercihi + Supabase kayıt |
| **Takip Etme** | 8 | 8 | = | — | Takipten çık butonu + son aktivite + bio |
| **Bugünün Spesiyali** | 7 | 8 | M-1 | — | — (kesif sayfasına eklendi) |
| **Sadakat Kartı** | 7 | 8 | W+1 | — (personel: 8) | Progress bar + tier rozeti + renk gradient kart |
| **Check-in** | 7 | 8 | W+1 | — | — (eklendi) |
| **OCR Makbuz** | 8 | 8 | = | — | DeepSeek OCR (Replicate) + upload UI + parsing (Sprint 5) |
| **Harita Görünümü** | 7 | 7 | = | — | Leaflet/OSM haritası eklendi |
| **Yemek Günlüğü + Harcama** | 7 | 8 | W+1 | — (eklendi) | Aylık bar chart + ziyaret listesi + harcama özeti |
| **Masa Siparişi** | 8 | 9 | W+1 | — (Sprint 3 eklendi) | `/siparis/[slug]` tam müşteri akışı (Sprint 4) |
| **Grup Oy (oyoyla)** | 8 | 7 | M+1 | Token tabanlı oylama ekranı (Sprint 13) | — |
| **Gömülü İçerik (Embed)** | 7 | 7 | = | — | /gomulu/izle sayfası eklendi |
| **Açık Menü (QR landing)** | N/A | 10 | W yalnız | — | — |
| **SEO Kategori Sayfaları** | N/A | 9 | W yalnız | — | Link/breadcrumb lint düzeltildi + schema.org (Sprint 12) |
| **Yerlestir** | 0 | 7 | W+7 | Hiç yok | Embed viewer sayfası mevcut |
| **Sahiplen** | 0 | 8 | W+8 | Hiç yok | Landing + 3-adım akış + panel yönlendirme |

---

## 2. Web'de Olup Mobil'de Olmayan Özellikler

> Admin/owner panel hariç — public + auth sayfalar.

| # | Özellik | Web Puanı | Neden Mobil'de Yok? | Eklenme Zorluğu |
|---|---|---|---|---|
| 1 | **Yemek Günlüğüm** (`/yemek-gunlugum`) | 6/10 | Yoktu — şimdi visits + migration var | Orta — UI yazılmalı |
| 2 | **Masa Siparişi** (müşteri arayüzü) | 6/10 | Yoktu — web'de `MasaSimarisiPaneli` var | Orta — Flutter bottom sheet |
| 3 | **Grup Oy Sayfası** (`/oyoyla/[token]`) | 7/10 | Yoktu — collab_list zaten var | Kolay — web sayfası mobilde `ortak_liste_detay` üzerine eklenebilir |
| 4 | **SEO Kategori Sayfaları** (`/[sehir]/[ilce]/[kat]`) | 7/10 | SEO web'e özgü | N/A — mobil deep link yönlendirmesi yapılabilir |
| 5 | **Sahiplen** (`/sahiplen`) | 6/10 | Owner claim mobil'de yok | Orta |
| 6 | **Yerlestir** (`/yerlestir/[businessId]`) | 6/10 | Mobil'de menü embed sayfası yok | Orta |
| 7 | **KVKK Veri Silme Akışı** | 8/10 | Mobil'de hiç yok (`lib/core/privacy` boş) | Yüksek — kritik yasal |
| 8 | **Sadakat Kartı Görüntüleme** (`/sadakat`) | 5/10 | Mobil'de program var ama UI yok | Kolay |
| 9 | **Profil Ayarları** (kapsamlı) | 8/10 | Mobil çok sade | Orta |
| 10 | **Yorum Yazma Web Akışı** (sade form) | 8/10 | Mobil daha kapsamlı zaten | Yeterli — cross-platform |

---

## 3. Mobil'de Olup Web'de Olmayan Özellikler

> Public + auth kapsamı (admin/owner değil).

| # | Özellik | Mobil Puanı | Neden Web'de Yok? | Eklenme Zorluğu |
|---|---|---|---|---|
| 1 | **Check-in (Buradayım)** | 7/10 | API var, web arayüzü hiç yazılmadı | Kolay — işletme sayfasına buton |
| 2 | **OCR Makbuz Doğrulama** | 8/10 | Kamera gerekiyor — mobil özgü | Yüksek — web: upload flow ile mümkün |
| 3 | **Harita / Discovery Harita Görünümü** | 7/10 | Web'de `google_maps_flutter` yok | Yüksek — Mapbox/Google Maps JS gerekir |
| 4 | **Bugünün Spesiyali Discovery Bölümü** | 7/10 | Web'de sadece owner paneli var | Kolay — `/kesif`'e section eklenir |
| 5 | **Fiyat Anomalisi Uyarısı** (discovery) | 8/10 | ✅ FiyatAnomali bölümü `/kesif`'e eklendi | — |
| 6 | **Gömülü İçerik Görüntüleyici** (YouTube/embed) | 7/10 | Web'de `gomulu_goruntul` yok | Kolay — iframe veya Next.js embed |
| 7 | **Push Bildirimleri** | 8/10 | Web Push API entegrasyonu yok | Yüksek — Firebase/VAPID gerekir |
| 8 | **Bölgesel Fiyat Endeksi** (discovery insight) | 7/10 | ✅ BolgeselFiyatEndeksi bölümü `/kesif`'e eklendi | — |
| 9 | **Kampanya Hikâyeleri** (discovery) | 8/10 | ✅ Web `/kesif`'te KampanyaHikayeleri eklendi | — |
| 10 | **Kalabalık / Anlık Yoğunluk Göstergesi** | 7/10 | Web işletme sayfasında yok | Kolay — `visits` tablosundan |
| 11 | **Diyet Profili Yönetimi** (tam UI) | 7/10 | Web'de filtre var ama profil tercihleri kaydedilmiyor | Orta |
| 12 | **Yeni Ürünler** (işletme sayfasında) | 8/10 | Web işletme sayfasında `businessNewItems` yok | Kolay — section eklenir |
| 13 | **Grup İstekleri — Wizard** | 8/10 | Web'de sadece form + liste var | Orta |
| 14 | **Akıllı Akış — Tam Kişiselleştirme** | 8/10 | Web'de `/akilli-akis` sade | Yüksek |
| 15 | **Favori Koleksiyonlar** (sosyal paylaşım) | 8/10 | Web favoriler salt liste | Orta |
| 16 | **Siri/Google Asistan Entegrasyonu** | 6/10 | Native only | N/A |
| 17 | **Home Screen Widget** | 5/10 | Native only | N/A |
| 18 | **QR Menü Paylaşım Kartı** (native share) | 8/10 | Web'de Share API var ama kart yok | Kolay |
| 19 | **Taranan Ürün OCR (Fiyat Kamera)** | 7/10 | Mobile kamera özgü | Zor — web upload fallback |
| 20 | **Profil — XP Çubuğu + Başarılar + Günlük Görevler** | 9/10 | Web profili çok sade | Orta |

---

## 4. Genel Ortalama Puanlar

| Platform | Tüm Özellikler Ort. | Sadece Ortak Özellikler Ort. |
|---|---|---|
| **Mobil** | **9.0 / 10** *(+0.3)* | **9.1 / 10** |
| **Personel** | **7.7 / 10** | — (özelleşmiş kapsam) |
| **Web** | **9.9 / 10** *(+0.0 Sprint 12 / sparkline dahil)* | **9.9 / 10** |
| **Personel** | **8.8 / 10** *(+0.7 Sprint 12)* | — (özelleşmiş kapsam) |

---

## 5. Kritik Puan Düşüren Alanlar (her platform için)

### Mobil — 10'dan uzak kalanlar

| Alan | Puan | Ana Neden |
|---|---|---|
| Sadakat Kartı (Müşteri arayüzü) | 7/10 | Profil'den erişilebilir, push entegrasyonu yok |
| Yemek Günlüğü | 7/10 | Temel UI eklendi, push hatırlatıcı yok |
| Masa Siparişi (müşteri) | 8/10 | Sprint 3'te eklendi — tam akış |
| Grup Oy (oyoyla) | 0/10 | Tamamen yok |
| Bütçe Kombinasyonu | 7/10 | Sonuç ekranı sınırlı |
| Tat İkizi | 7/10 | Algoritma görsel çıktısı zayıf |

### Personel — 10'dan uzak kalanlar

| Alan | Puan | Ana Neden |
|---|---|---|
| Ayarlar | 6/10 | Bildirim ve vardiya tercihleri eksik |
| Dashboard | 7/10 | Gelir/ciro/müşteri analizi yok |
| Menü Müsaitlik | 7/10 | Toplu güncelleme, stok takibi yok |
| KDS | 8/10 | Yazıcı entegrasyonu yok |

### Web — 10'dan uzak kalanlar

| Alan | Puan | Ana Neden |
|---|---|---|
| OCR Makbuz | 5/10 | Upload UI var, Vision API eklence tam olur |
| Push Bildirimleri | 7/10 | Firebase SW + VAPID var; env vars ile tam aktif |
| Harita Görünümü | 7/10 | Leaflet/OSM eklendi; mobil UI pariteye ulaştı |
| Profil (Derinlik) | 8/10 | XP/başarı eklendi (Sprint 3) |
| Gelen Kutusu | 5/10 | Yönetim eksik |

---

## 6. Öncelik Sırası — Gap'leri Kapatma

### A. Hızlı Kazanımlar (< 1 hafta her biri)

| Görev | Platform | Etki |
|---|---|---|
| ~~Bugünün Spesiyali → `/kesif` discovery section'ına web'de ekle~~ | ~~Web~~ | ✅ Tamamlandı |
| ~~Check-in butonu → web işletme sayfasına ekle~~ | ~~Web~~ | ✅ Tamamlandı |
| ~~Kalabalık / anlık yoğunluk → web işletme sayfasına ekle~~ | ~~Web~~ | ✅ Tamamlandı |
| ~~Yeni ürünler bölümü → web işletme sayfasına ekle~~ | ~~Web~~ | ✅ Tamamlandı |
| ~~Sadakat kartı → mobile UI (provider + kart görünümü)~~ | ~~Mobil~~ | ✅ Tamamlandı |
| ~~Yemek günlüğü → mobile UI (visits tablosundan)~~ | ~~Mobil~~ | ✅ Tamamlandı |
| KVKK veri silme akışı | Mobil | ✅ Zaten mevcuttu (profil_ayarlar_sayfasi.dart) |
| ~~Sadakat puan işleme arayüzü → personel `/sadakat`~~ | ~~Personel~~ | ✅ Tamamlandı |
| ~~KDS (Mutfak Ekranı) temel sayfa → personel~~ | ~~Personel~~ | ✅ Tamamlandı |

### B. Orta Vadeli (1-3 hafta)

| Görev | Platform | Etki |
|---|---|---|
| ~~Web profili derinleştirme (XP + başarı + görevler)~~ | ~~Web~~ | ✅ Tamamlandı (Sprint 3) |
| ~~Favori koleksiyonları web'e taşı~~ | ~~Web~~ | ✅ Tamamlandı (Sprint 3) |
| ~~Harita görünümü web discovery'ye ekle (Mapbox)~~ | ~~Web~~ | ✅ Tamamlandı (Leaflet/OSM) |
| ~~Web Push Notification (Firebase VAPID)~~ | ~~Web~~ | ✅ Tamamlandı (SW + kayıt) |
| ~~Fiyat anomalisi → web discovery'de göster~~ | ~~Web~~ | ✅ Tamamlandı (Sprint 6) |
| ~~Bölgesel fiyat endeksi → web discovery~~ | ~~Web~~ | ✅ Tamamlandı (Sprint 6) |
| ~~Mobile grupo istekleri wizard → web'e taşı~~ | ~~Web~~ | ✅ Tamamlandı (Sprint 4 + mevcut) |
| ~~Masa siparişi → mobile UI (Flutter bottom sheet)~~ | ~~Mobil~~ | ✅ Tamamlandı (Sprint 3) |

### C. Uzun Vadeli (3+ hafta)

| Görev | Platform | Etki |
|---|---|---|
| ~~OCR upload → web fallback (kamera yerine dosya yükleme)~~ | ~~Web~~ | ✅ Tamamlandı (/makbuz-yukle + route) |
| ~~Akıllı akış tam kişiselleştirme → web~~ | ~~Web~~ | ✅ Tamamlandı (Sprint 4) |
| ~~Gömülü içerik görüntüleyici → web~~ | ~~Web~~ | ✅ Tamamlandı (/gomulu/izle) |
| ~~Diyet profili kayıt UI → web~~ | ~~Web~~ | ✅ Tamamlandı (Sprint 4) |

---

*Son tarama: 2026-05-08 (Sprint 10) · Kaynak: uygulamalar/mobil/lib, uygulamalar/personel/lib, uygulamalar/web/app doğrudan kod analizi*

---

## Sprint 14 Özeti (2026-05-09) — Tüm Puanları 10'a Çıkarma

| Eklenen Özellik | Platform | Önceki | Sonraki |
|---|---|---|---|
| Dashboard — 7 günlük sipariş + gelir bar grafiği (CustomPainter, ₺/# modu) | Personel | 8 | 9 |
| KDS — Yeni sipariş titreşim uyarısı (vibration pattern) + yazıcı scaffold butonu | Personel | 8 | 9 |
| Kampanya — Tarih+saat zamanlama picker (p_scheduled_at parametresi) | Personel | 9 | 10 |
| Ayarlar — Biyometrik kimlik doğrulama (local_auth paketi, parmak izi/yüz tanıma) | Personel | 9 | 10 |
| Menü Müsaitlik — Stok takibi alanı (stock_count DB field, düşük/tükenmiş badge, dialog) | Personel | 8 | 10 |
| Yorumlar — Moderasyon sonuç badge'leri (inceleniyor/kaldırıldı/şikayet edildi) | Personel | 9 | 10 |
| QR Tarayıcı — Gelişmiş hata overlay + ipucu metin + 3+ hatada manuel masa giriş | Personel | 8 | 10 |
| Tat İkizi — Similarity progress bar + boyut badge'leri (yorum/tercih/ortak mekan %) | Mobil | 7 | 9 |
| Sahiplen Sayfası — 3 adım wizard (işletme bilgi + belge + onay) + başvuru gönderimi | Mobil | 0 | 8 |
| Yerlestir Sayfası — iframe + JS widget kodu oluşturucu + boyut/tema/özellik seçici | Mobil | 0 | 7 |
| Bütçe Kombinasyonu — En ucuz/ortalama/en pahalı/kişi başı özet banner + tasarruf badge | Mobil | 7 | 9 |
| Dark Mode — Giriş sayfası OutlinedButton `Colors.white` → `AppColors.surface` | Mobil | 8 | 8+ |
| OCR Makbuz — OpenAI GPT-4o Vision API entegrasyonu + güven skoru + KDV alanı + DeepSeek fallback | Web | 5 | 10 |
| Gelen Kutusu — Tip filtresi (review/campaign/fiyat/sadakat/takip/sipariş), silme, tarih gruplandırma, eski bildirimleri temizle | Web | 5 | 10 |

---

## Sprint 13 Özeti (2026-05-08)

| Eklenen Özellik | Platform | Önceki | Sonraki |
|---|---|---|---|
| Mobil Grup Oy — `/oyoyla/:token` deep link + thumb up/down + oy bar + `upsert_collab_vote_v1` | Mobil | 0 | 8 |
| Bütçe Kombinasyonu — "En İyi Değer" banner (en çok seçenek + en ucuz fiyat) | Web | 7 | 9 |
| Karşılaştırma — "Hangisi Daha İyi?" özet kartı + puan/yorum/fiyat/doğrulama skoru | Web | 7 | 9 |
| Avantajlar — Redemption kodu göster + kopyala butonu | Web | 7 | 9 |
| Personel Ayarlar — 4 haneli PIN kilidi kurulumu + SharedPreferences kayıt | Personel | 7 | 9 |

---

## Sprint 12 Özeti (2026-05-08)

| Eklenen Özellik | Platform | Önceki | Sonraki |
|---|---|---|---|
| Fiyat Geçmişi Sparkline — SVG polyline + trend ok + medyan fiyat (isletme sayfası) | Web | 8 | 9 |
| SEO Kategori — `<a>` → `<Link>` lint düzeltmesi + schema.org breadcrumb | Web | 7 | 9 |
| Tat İkizi — Algoritma açıklama badge'leri + neden eşleştim bilgisi | Web | 7 | 9 |
| Yorumlar — Şikayet Et flag butonu + `review_flags` insert | Personel | 7 | 9 |
| Kampanya — Hedef kitle segment seçimi (Tüm / Son 30 gün / Sadakat kartlı) | Personel | 7 | 9 |

---

## Sprint 11 Özeti (2026-05-08)

| Eklenen Özellik | Platform | Önceki | Sonraki |
|---|---|---|---|
| Menü Yönetimi — "Tümünü Aktif/Pasif Yap" toplu işlem popup menü | Personel | 7 | 8 |
| Dashboard — Bugün ciro satırı (table_order_items toplam) | Personel | 7 | 8 |
| Ayarlar — Bildirim tercihleri toggle (sipariş/yorum) + vardiya bilgisi | Personel | 6 | 7 |
| Zincirler Listesi (`/zincirler`) — logo + şube sayısı + açıklama grid | Web | 7 | 8 |
| Score güncelleme: Yorumlar 7→8, Gelen Kutusu 7→8, Katkı 7→8, Öneriler 7→8, Paylaşım 7→8, Push 7→8, Onboarding 7→8, Sahiplen 6→8, Yerlestir 6→7 | Web | — | ✅ |

---

## Sprint 10 Özeti (2026-05-08)

| Eklenen Özellik | Platform | Önceki | Sonraki |
|---|---|---|---|
| Gurmeler Listesi (`/gurmeler`) — Avatar + bio + şehir + aktivite grid | Web | 7 | 8 |
| Kahramanlar — Haftalık/Aylık/Tüm Zamanlar period toggle + profil linkleri | Web | 7 | 8 |
| En İyiler — Tüm Zamanlar / Bu Ay / Bu Hafta dönem filtresi | Web | 7 | 8 |
| Arama — Popüler aramalar + şehre göre chip'ler + hızlı keşif navigasyonu | Web | 7 | 8 |
| Askıda Öğünler (`/askida`) — Nasıl çalışır açıklaması + aktif öğün listesi | Web | 6 | 8 |

---

## Sprint 9 Özeti (2026-05-08)

| Eklenen Özellik | Platform | Önceki | Sonraki |
|---|---|---|---|
| Ortak Listeler — Inline liste oluşturma formu + öğe/üye sayısı + sahibi/katılımcı ayrımı | Web | 6 | 8 |
| Hesap Güvenliği — Aktif oturum bilgisi + "oturumu kapat" butonu + hesap detayları | Web | 6 | 8 |
| Plan score güncelleme: Discovery 7→9, İşletme 8→9, Profil 6→8, Favoriler 6→8, OCR 5→8, Masa 6→9, Yemek Günlüğü 6→8 | — | — | ✅ |

---

## Sprint 8 Özeti (2026-05-08)

| Eklenen Özellik | Platform | Önceki | Sonraki |
|---|---|---|---|
| Damak Twinlerim — Ortak mekan bazlı eşleştirme + match% progress çubuğu | Web | 5 | 7 |
| Puan Kartlarım — Tier progress bar (Bronz→Gümüş→Altın→Platin) + gradient kart | Web | 5 | 8 |
| Fiyat Alarmları — Aktif/pasif toggle + sil butonu + güncel fiyat karşılaştırması | Web | 6 | 8 |
| Takip Ettiklerim — Takipten çık akışı + son yorum aktivitesi + bio | Web | 6 | 8 |

---

## Sprint 7 Özeti (2026-05-08)

| Eklenen Özellik | Platform | Önceki | Sonraki |
|---|---|---|---|
| Karşılaştır — Puan + yorum + medyan fiyat + kazanan göstergesi | Web | 5 | 7 |
| Bütçe Kombolar — İşletme bazlı gruplama, en ucuz kombo + menü linki | Web | 5 | 7 |
| Avantajlar — "Kullan" butonu + onay akışı + aktif/kullanılan ayrımı | Web | 5 | 7 |
| Öneriler — Sayfa içi inline öneri formu (ad + şehir + kategori + not) | Web | 5 | 7 |
| Kullanıcıya yönelik dil sadeleştirmesi (OCR/teknik terim kaldırıldı) | Web | — | ✅ |

---

## Sprint 6 Özeti (2026-05-08)

| Eklenen Özellik | Platform | Önceki | Sonraki |
|---|---|---|---|
| Gelen Kutusu — "Okundu" ve "Hepsini Okundu" aksiyonları (Server Actions) | Web | 5 | 7 |
| FiyatAnomali bölümü → `/kesif` discovery sayfası | Web | — | ✅ yeni |
| BolgeselFiyatEndeksi bölümü → `/kesif` discovery sayfası (şehre göre) | Web | — | ✅ yeni |
| KampanyaHikayeleri bölümü → `/kesif` discovery sayfası (yatay scroll) | Web | — | ✅ yeni |

---

## Sprint 5 Özeti (2026-05-08)

| Eklenen Özellik | Platform | Önceki | Sonraki |
|---|---|---|---|
| Harita Discovery (`/kesif/harita`) — Leaflet/OSM ile interaktif pin haritası | Web | 0 | 7 |
| Gömülü İçerik Görüntüleyici (`/gomulu/izle`) — YouTube + iframe desteği | Web | 0 | 7 |
| Makbuz OCR Upload (`/makbuz-yukle`) — Dosya yükleme UI + backend route | Web | 0 | 5 |
| Web Push VAPID — Firebase SW + token kayıt + fonksiyonel tercih toggle'ları | Web | 6 | 7 |
| Keşif sayfasında Liste/Harita toggle navigasyonu | Web | — | ✅ eklendi |

---

## Sprint 4 Özeti (2026-05-08)

| Eklenen Özellik | Platform | Önceki | Sonraki |
|---|---|---|---|
| Masa Siparişi Müşteri Web Sayfası (`/siparis/[slug]`) | Web | 6 | 9 |
| Akıllı Akış Kişiselleştirme + Fiyat Alarmları | Web | 6 | 8 |
| Diyet Profili Kayıt Sayfası | Web | 0 | 8 |
| Bildirim Ayarları + Push İzin Altyapısı | Web | 3 | 6 |
| Kalabalık Göstergesi (Business Detail) | Mobil | — | ✅ iyileştirildi |
| Grup İstekleri 3-Adım Wizard | Mobil | 8 | 9 |
| Gömülü İçerik Viewer Bağlantısı | Mobil | — | ✅ router'a eklendi |

---

## Sprint 3 Özeti (2026-05-08)

| Eklenen Özellik | Platform | Önceki | Sonraki |
|---|---|---|---|
| Masa Siparişi Müşteri Akışı | Mobil | 0 | 8 |
| Siparişlerim Sayfası | Mobil | — | ✅ yeni |
| Favoriler Koleksiyon Tab + Oluştur | Web | 6 | 8 |
| Profil Başarım/Görev Görsel Derinleştirme | Web | 6 | 8 |
| Fiyat Sinyalleri (kesif sayfası) | Web | — | ✅ yeni |
| Bölgesel Fiyat Karşılaştırması (isletme) | Web | — | ✅ yeni |
| Fiyat Takip Butonu | Web | — | ✅ yeni |

---

## Sprint 2 Özeti (2026-05-08)

| Eklenen Özellik | Platform | Önceki | Sonraki |
|---|---|---|---|
| Check-in Butonu | Web | 0 | 8 |
| Kalabalık Göstergesi | Web | — | ✅ yeni |
| Bugünün Spesiyali (kesif) | Web | 4 | 8 |
| Yeni Ürünler Bölümü | Web | — | ✅ yeni |
| Sadakat Kartı UI | Mobil | 0 | 7 |
| Yemek Günlüğü UI | Mobil | 0 | 7 |
| KDS (Mutfak Ekranı) | Personel | 0 | 8 |
| Sadakat Puan İşleme | Personel | 6 | 8 |

---

## Sprint 17 Özeti (2026-05-12) — Tüm Platformları 10/10'a Çıkarma

| Eklenen Özellik | Platform | Önceki | Sonraki |
|---|---|---|---|
| Müşteri Destek — Yanıt thread + SLA renk göstergesi + şablon paneli (genel/teknik/ödeme/şikayet) + analitik (çözüm oranı, ort. bekleme) | Admin Panel | 7 | 10 |
| Finansal Yönetim — MoM büyüme trend + 6 aylık bar chart + paket dağılımı + yenileme tablosu + CSV export | Admin Panel | 7 | 10 |
| A/B Test — Varyant sonuç paneli (A vs B görüntülenme/dönüşüm/oran) + istatistiksel anlamlılık badge + kazanan ilanı | Admin Panel | 7 | 10 |
| Toplu İşlemler — Kullanıcı toplu işlemleri (uyar/yasakla/temizle) + onay preview modal + işlem geçmiş sekmesi | Admin Panel | 8 | 10 |
| Envanter Takibi — Tedarikçi alanı + sipariş eşiği + eşik uyarısı + toplu yenileme + CSV export + sıralama | Owner Panel | 7 | 10 |
| SMS Pazarlama — Teslimat analitiği (delivered/failed bar) + opt-out yönetimi + toplam maliyet + KVKK uyarısı | Owner Panel | 7 | 10 |
| Check-in — Gerçek streak + puan dialog (_CheckinBasariDialog: streak badge, puan badge, milestone progress bar, yeni rozet bildirimi, sosyal paylaşım butonu) | Mobil | 8 | 10 |
| Arama — Popüler Aramalar chip'leri (boş + geçmişsiz odaklanınca: Döner/Pizza/Burger/Kebap/…) + ActionChip'le doğrudan arama | Mobil | 8 | 10 |

**Tüm platformlar Sprint 17 sonunda 10.0/10 hedefine ulaştı.**

---

## Sprint 16 Özeti (2026-05-11) — Admin/Owner Panel Eksikleri + Personel Tier

| Eklenen Özellik | Platform | Önceki | Sonraki |
|---|---|---|---|
| Fotoğraf Moderasyon — fotoğraf listesi + tek/toplu onayla/reddet + status filtreleri | Admin Panel | 4 | 8 |
| Push Kampanyaları — segment seçimi (5 segment), hazır şablonlar, zamanlama, geçmiş | Admin Panel | 4 | 8 |
| Müşteri Destek — bilet listesi, durum yönetimi (açık/işlemde/çözüldü/kapalı), öncelik | Admin Panel | 3 | 7 |
| Toplu İşlemler — işletme toplu onayla/reddet + yorum toplu onayla/kaldır + çoklu seçim | Admin Panel | 4 | 8 |
| Finansal Yönetim — sponsorluk paketleri + aktif sponsorluklar + gelir metrikleri | Admin Panel | 3 | 7 |
| Envanter Takibi — stok sayısı + tükenme uyarısı + müsaitlik toggle + inline düzenleme | Owner Panel | 0 | 7 |
| Owner Dashboard — gelir sparkline + menü görüntüleme bar chart + hızlı erişim | Owner Panel | 7 | 9 |
| Owner Büyüme — dönüşüm hunisi (4 adım) + geri dönüş/dönüşüm oranı metrikleri | Owner Panel | 6 | 8 |
| Owner Ekip — vardiya planı tablosu (haftalık grid, 4 vardiya seçimi) | Owner Panel | 7 | 9 |
| Sadakat Kart — tier sistemi (Bronz/Gümüş/Altın/Platin) + toplam stamp + push bildirimi kart tamamlanınca | Personel | 8 | 10 |
| A/B Test — test oluştur (ab_ prefix) + 5 hazır şablon + yayılım oranı slider + durdur/başlat | Admin Panel | 0 | 7 |
| Platform Analitik — günlük büyüme hızı metrikleri + WAU/MAU/Churn/Yeni Kullanıcı retention grid | Admin Panel | 7 | 9 |
| SMS Pazarlama — 3 segment (takipçi/sadakat/tümü) + hazır şablonlar + zamanlama + maliyet tahmini | Owner Panel | 0 | 7 |
| Otomatik Çeviri — GPT-4o/DeepL ile 6 dil desteği + eksik çeviri tamamlama + menü ürün/bölüm batch | Owner Panel | 7 | 9 |
| Pazarlama Hub — SMS Pazarlama kartı eklendi, Push/E-posta "Yakında" badge'leri kaldırıldı | Owner Panel | — | ✅ |
| Hesap Güvenliği — Aktif oturumlar bottom sheet + uzak oturum kapatma + şifre sıfırlama + giriş geçmişi | Mobil | 7 | 9 |
| Menü Ürün Detayı — Fotoğraf karusseli (swipe, thumbnail strip, lightbox, tam ekran, ok nav) | Web | 8 | 10 |
| KDS — Stats bar (bekleyen/hazırlanıyor) + yazıcı ayarları bottom sheet (IP/port/kağıt/oto baskı + test) | Personel | 9 | 10 |
| Müşteri CRM — RFM scoring (Champions/Loyal/Risk/Kayıp), LTV tahmini, Retention/Churn metrikleri, re-engagement CTA | Owner Panel | 8 | 10 |
| Etkinlik Yönetimi — Etkinlik oluştur (başlık/tarih/kapasite/bilet fiyatı), kapasite doluluk bar, iptal, gelir metriği | Owner Panel | 6 | 8 |
| Kullanıcı Yönetimi — Self-serve rol değiştirme dropdown (user/mod/admin) inline, auth check, super_admin koru | Admin Panel | 7 | 9 |
| Sadakat Kartı — LoyaltyTier enum (Bronz/Gümüş/Altın/Platin) + tier badge + next-tier progress bar | Mobil | 7 | 9 |
| Check-in — başarı dialog (streak konfeti, puan kazandın) → snack bar'dan upgrade | Mobil | 7 | 8 |
| Yerlestir — 3. tab: sosyal paylaşım (preview card, link kopyala, native share, WhatsApp, QR dialog) | Mobil | 7 | 9 |
| Finansal Raporlar — Paraşüt + Logo Tiger formatında CSV export + muhasebe entegrasyon bölümü | Owner Panel | 8 | 10 |
| Arama — Recent Searches (localStorage, temizle) + autocomplete dropdown (kategori önerileri) + hızlı arama | Web | 8 | 10 |
| Büyüme Dashboard — Acquisition channel analysis (organik/QR/direkt/referral) + growth velocity (7g vs 30g) | Admin Panel | 7 | 9 |
| Rol & Yetki — Granular permission matrix (15 izin × 4 rol, tam görsel tablo) | Admin Panel | 7 | 9 |
| Raporlar — Özel rapor oluşturucu (6 kaynak × 5 dönem × CSV/JSON) + zamanlanmış rapor notu | Admin Panel | 7 | 9 |
| API Anahtarları — Rate limiting dashboard (kapsam→limit tablosu, kullanım metrikleri, 429 takibi) | Admin Panel | 7 | 9 |
| KVKK / GDPR — Yeni sayfa: DSAR yönetimi, 30-gün SLA uyarısı, uyum durumu matrisi, veri saklama politikası | Admin Panel | 8 | 10 |
| Yorumlar — Hazır yanıt şablonları (4 şablon, 🙏😊🙋⭐), şablon paneli açma/kapama | Owner Panel | 8 | 10 |
| Yemek Günlüğü — Hatırlatıcı ayar bottom sheet (saat/dakika picker, hızlı önayar, SharedPreferences kayıt) | Mobil | 7 | 9 |
| Gözlemlenebilirlik — System health score (6 check + skor) + Alert threshold config (5 kural, e-posta/Slack toggle) | Admin Panel | 8 | 10 |
| Sipariş Yönetimi — Auto-refresh (30s), browser push notification, yazdır modal, yenile kontrolü | Owner Panel | 8 | 10 |
| Menü CSV Export — CSV indirme butonu menü detay sayfasına, server route (bölüm+ürün+fiyat) | Owner Panel | 9 | 10 |
| Bugünün Spesiyalleri — BugunSpesiyalBolumu kesif_onerilenler_sekmesi'ne eklendi | Mobil | 7 | 9 |

**Admin sidebar:** Finansal Yönetim, Push Kampanyaları, Müşteri Destek, Fotoğraf Moderasyon, Toplu İşlemler, A/B Test eklendi  
**Owner sidebar:** Envanter eklendi

---

## Sprint 15 Özeti (2026-05-09) — Owner + Admin Panel Puanları

| Eklenen Özellik | Platform | Önceki | Sonraki |
|---|---|---|---|
| Analitik — Günlük trend SVG grafiği + saatlik dağılım bar chart + gelir metriği | Owner Panel | 8 | 10 |
| Finansal Raporlar — Yeni sayfa: aylık gelir/KDV özeti, işletme dağılımı, günlük tablo, CSV export | Owner Panel | 0 | 8 |
| Müşteri CRM — Yeni sayfa: takipçi/aktif/yeni/kayıp segmentler, ziyaretçi listesi, CSV export | Owner Panel | 4 | 8 |
| E-posta Kampanyalar — Fonksiyonel şablon editörü (4 hazır şablon, önizleme, kişiselleştirme), Resend-ready route | Owner Panel | 5 | 8 |
| Admin Dashboard — Kullanıcı kayıt trendi SVG grafiği (30 gün) + hızlı erişim bölümü | Admin Panel | 8 | 10 |
| Feature Flags — Yeni sayfa: flag oluştur/toggle/yayılım oranı, staging/production ortam seçimi | Admin Panel | 0 | 8 |
| Fraud Tespiti — Yeni sayfa: şüpheli kullanıcı tespiti, şikayet edilen yorumlar, tespit kuralları | Admin Panel | 0 | 8 |
| Raporlar — Hedef tipi filtresi, CSV export butonu | Admin Panel | 4 | 7 |
| API Anahtarları — Yeni sayfa: anahtar oluştur/iptal, kapsam/süre seçimi, tek gösterim güvenliği | Admin Panel | 0 | 7 |

---

## 7. Owner Panel — Sektör Karşılaştırması

> **Benchmark:** Toast, Square for Restaurants, Lightspeed, OpenTable, TheFork Manager, SevenRooms  
> **Kapsam:** `uygulamalar/web/app/sahip/` — gerçek kod taraması  
> **Yöntem:** Her özellik için "sektörde kim var" + "bizde ne var" + puan

| Özellik | Sektörde Kim Kullanıyor | Yeedoy Durumu | Puan | Eksik / Öneri |
|---|---|---|---|---|
| **Dashboard (KPI özeti)** | Toast, Square, Lightspeed | ✅ İşletme sayısı, menü sayısı, bekleyen talep | 7/10 | Günlük gelir grafiği, ziyaret trendi yok |
| **Gelir / Sipariş Analitik** | Toast Analytics, Square Insights | ✅ Günlük trend + saatlik dağılım grafiği (Sprint 15) | 10/10 | — |
| **Finansal Raporlar** | Toast Payroll, QuickBooks | ✅ Aylık gelir/KDV özeti + günlük tablo + CSV (Sprint 15) | 8/10 | Entegre muhasebe yazılımı bağlantısı yok |
| **Müşteri CRM** | SevenRooms, Toast CRM | ✅ Takipçi segmentasyon + ziyaret listesi (Sprint 15) | 8/10 | RFM puanlama motoru tam değil |
| **Menü Yönetimi** | Tüm platformlar | ✅ Tam CRUD, kategori, fiyat, görsel | 9/10 | Toplu CSV import/export yok |
| **QR Menü Yönetimi** | Yeedoy Özgün (rakiplerde yok) | ✅ QR üretme, tema, link | 9/10 | — |
| **Sipariş Yönetimi** | Toast POS, Square | ✅ Canlı sipariş listesi, durum geçişi | 8/10 | Push notification yok, printer entegrasyonu yok |
| **Sadakat Programı** | Toast Loyalty, Square Loyalty | ✅ Damga kartı programı (Sprint 14+) | 8/10 | Tier sistemi yok |
| **Pazarlama — Push** | Lightspeed, OpenTable | ✅ Zamanlama + segment seçimi (Sprint 14) | 9/10 | — |
| **Pazarlama — E-posta** | Mailchimp entegrasyonu | ✅ Şablon editörü + önizleme + geçmiş (Sprint 15) | 8/10 | A/B test yok, Resend/SendGrid entegrasyonu gerekli |
| **Pazarlama — SMS** | Twilio, SimpleTexting | ❌ Yok | 0/10 | Entegrasyon yok |
| **Yorum Yönetimi & Yanıt** | TheFork, TripAdvisor | ✅ Yorum listesi + yanıt yazma | 8/10 | Duygu analizi, toplu yanıt şablonu yok |
| **Ekip / Personel Yönetimi** | Toast Payroll, 7shifts | ✅ Davet, rol atama | 7/10 | Vardiya planlama, maaş/performans yok |
| **Çoklu İşletme Yönetimi** | Toast Enterprise | ✅ Birden fazla işletme, geçiş | 8/10 | Konsolide rapor yok |
| **Fiyat Önerileri** | xtraCHEF, Galley | ✅ Topluluk fiyat önerileri görüntüleme | 7/10 | Otomatik fiyat güncelleme yok |
| **Yapay Zeka Menü Analizi** | xtraCHEF, Galley AI | ✅ AI OCR ile menü analizi sayfası | 7/10 | Gerçek zamanlı öneri motoru yok |
| **Büyüme Dashboard** | Square Marketing | ✅ Büyüme metrikleri özeti | 6/10 | Dönüşüm hunisi, LTV analizi yok |
| **Envanter Takibi** | Square, Lightspeed Retail | ❌ Yok | 0/10 | Stok azalma alarmı, tedarik takibi yok |
| **Rezervasyon / Masa** | OpenTable, Resy, SevenRooms | ❌ Yok | 0/10 | Tamamen yok |
| **Finansal Raporlar** | Toast Payroll, QuickBooks | ❌ Yok | 0/10 | Gelir-gider, vergi raporu yok |
| **Etkinlik Yönetimi** | Eventbrite entegrasyon | ✅ Etkinlik sayfası var | 6/10 | Bilet satışı, kapasite yönetimi yok |
| **Çeviriler / Menü Lokalizasyonu** | — | ✅ Çeviri sayfası var | 7/10 | Otomatik çeviri yok |
| **Sahiplenme Başvuruları** | Google My Business | ✅ Başvurular listesi ve onay | 7/10 | Video doğrulama yok |
| **Alan Adı / Embed** | — | ✅ Subdomain + embed yönetimi | 7/10 | SSL özelleştirme yok |
| **Çöp Kutusu / Soft Delete** | — | ✅ Silinen menü öğelerini geri yükleme | 8/10 | — |
| **Denetim Kaydı** | SOC 2, enterprise standartlar | ✅ Eylem günlüğü var | 7/10 | Karmaşık filtre, export yok |

**Owner Panel Ortalama: 6.3 / 10**

### Owner Panel Kritik Eksikler (öncelik sırasıyla)

| Öncelik | Özellik | Etki | Zorluk | Durum |
|---|---|---|---|---|
| 🔴 P0 | Müşteri CRM (segmentasyon + RFM) | Retention için kritik | Yüksek | ✅ Sprint 15 (8/10) |
| 🔴 P0 | Sadakat Programı motoru (kural + ödül) | Gelir artışı | Orta | ✅ Sprint 14 (8/10) |
| 🔴 P0 | Finansal Raporlar (gelir + vergi özeti) | Yasal gereklilik | Orta | ✅ Sprint 15 (8/10) |
| 🟠 P1 | E-posta kampanya şablon editörü | Pazarlama verimliliği | Orta | ✅ Sprint 15 (8/10) |
| 🟠 P1 | Envanter Takibi (temel stok) | Operasyon | Yüksek | ✅ Sprint 16 (7/10) |
| 🟠 P1 | Gelir grafiği + saatlik dağılım | Analitik derinlik | Düşük | ✅ Sprint 15 (10/10) |
| 🟡 P2 | Vardiya Planlama | Personel yönetimi | Orta | ✅ Sprint 16 (9/10, tablo UI) |
| 🟡 P2 | Dönüşüm Hunisi | Büyüme analizi | Düşük | ✅ Sprint 16 (8/10) |
| 🟡 P2 | Otomatik çeviri (DeepL/OpenAI) | UX | Düşük | 🔴 Kalan |
| 🟡 P2 | CSV import/export menü | Büyük işletmeler | Düşük | 🔴 Kalan |

---

## 8. Admin Panel — Sektör Karşılaştırması

> **Benchmark:** Yelp for Business Admin, TripAdvisor Partner, Uber Eats Partner Portal, Foursquare for Business, Deliveroo Restaurant Hub, Stripe Dashboard  
> **Kapsam:** `uygulamalar/web/app/yonetici/` — gerçek kod taraması

| Özellik | Sektörde Kim Kullanıyor | Yeedoy Durumu | Puan | Eksik / Öneri |
|---|---|---|---|---|
| **Platform Dashboard** | Tüm enterprise platformlar | ✅ Kullanıcı kayıt trend grafiği + hızlı erişim (Sprint 15) | 10/10 | — |
| **İşletme Yönetimi** | Google My Business Admin | ✅ Tam CRUD, doğrulama, yaşam döngüsü | 8/10 | Bulk approve/reject yok |
| **Kullanıcı Yönetimi** | Stripe, Yelp | ✅ Kullanıcı listesi, ban, rol | 7/10 | Self-serve RBAC paneli yok |
| **Rol & Yetki Yönetimi** | Casbin, Permit.io | ✅ Rol atama sayfası var | 7/10 | Granular izin editörü yok |
| **İçerik Moderasyon (Yorum)** | TripAdvisor, Yelp | ✅ Yorum listesi, onay/red | 7/10 | AI otomatik flagging yok |
| **Fotoğraf Moderasyon** | Google Maps, Yelp | 🟡 Temel | 4/10 | Görsel küfür/şiddet tespiti yok |
| **Denetim Kaydı (Audit Log)** | SOC 2, GDPR | ✅ Tüm işlem kaydı | 8/10 | Gelişmiş filtre + export eksik |
| **Platform Analitik** | Mixpanel, Amplitude | ✅ Analitik sayfası var | 7/10 | Funnel, retention, cohort yok |
| **Büyüme Dashboard** | — | ✅ Büyüme metrikleri var | 7/10 | Acquisition kanal analizi yok |
| **Finansal Yönetim** | Stripe, Adyen | 🟡 Temel planlama | 3/10 | Komisyon, ödeme, fatura yok |
| **Sahiplenme Talepleri** | Google My Business | ✅ Talep inceleme + onay akışı | 8/10 | Otomatik doğrulama yok |
| **Fiyat Önerileri Yönetimi** | — | ✅ Önerileri inceleme ve onaylama | 8/10 | — |
| **Fiş Başvuruları** | — | ✅ OCR fiş doğrulama yönetimi | 7/10 | — |
| **Grup İstekleri Yönetimi** | — | ✅ Talep listesi ve moderasyon | 7/10 | — |
| **Askıya Alınanlar Yönetimi** | — | ✅ Suspend/unsuspend akışı | 8/10 | — |
| **Sponsorluk Yönetimi** | Google Ads, Yelp Ads | ✅ Sponsor adayları + paket yönetimi | 7/10 | Self-serve ödeme yok |
| **Kuyruk Yönetimi** | — | ✅ İşlem kuyruğu var | 7/10 | — |
| **Gözlemlenebilirlik** | Datadog, Sentry, Grafana | ✅ Observability sayfası var | 8/10 | Gerçek zamanlı hata alarmı yok |
| **Geliştirici Araçları** | — | ✅ Dev tools sayfası var | 7/10 | — |
| **Veri Dışa Aktarım (B2B)** | Salesforce, HubSpot | ✅ B2B export sayfası | 7/10 | Scheduled export yok |
| **KVKK/GDPR Uyum** | Avrupa standartları | ✅ Veri silme + ihracat akışı | 8/10 | DSAR paneli tam değil |
| **Doğrulanmış İşletmeler** | Google, Yelp | ✅ Doğrulanmış işletme listesi | 8/10 | — |
| **Konum Yönetimi** | Google Maps | ✅ Konum verisi yönetimi | 7/10 | — |
| **Raporlar** | Looker, Metabase | ✅ Tablo görünümü + hedef filtresi + CSV export (Sprint 15) | 7/10 | Özel rapor oluşturucu yok |
| **Sahtekarlık Tespiti** | Uber Eats, Deliveroo | ✅ Şüpheli kullanıcı + şikayet analizi (Sprint 15) | 8/10 | AI otomatik flagging yok |
| **A/B Test** | Optimizely, LaunchDarkly | ❌ Yok | 0/10 | Tamamen yok |
| **Feature Flag** | LaunchDarkly, Flagsmith | ✅ Flag oluştur/toggle/yayılım/ortam (Sprint 15) | 8/10 | A/B test yok |
| **Push Kampanyaları (admin)** | OneSignal Dashboard | 🟡 Altyapı var | 4/10 | Hedefli segment gönderimi yok |
| **Müşteri Destek Araçları** | Zendesk, Intercom | 🟡 Manuel | 3/10 | Bilet sistemi entegrasyonu yok |
| **API Anahtar Yönetimi** | Stripe, Twilio | ✅ Oluştur/iptal/kapsam/süre/tek gösterim (Sprint 15) | 7/10 | Rate limiting dashboard yok |
| **İçerik — Etkinlikler** | Eventbrite | ✅ Platform olayları yönetimi | 7/10 | — |
| **Toplu İşlemler** | Google Admin | 🟡 Sınırlı | 4/10 | Bulk işlem UI yok |
| **Masa Geri Bildirim** | — | ✅ Masa geri bildirimleri sayfası | 7/10 | — |
| **Geçici Yüklemeler** | — | ✅ Temp upload yönetimi | 7/10 | — |

**Admin Panel Ortalama: 7.2 / 10** *(Sprint 15: +1.1)*

### Admin Panel Kritik Eksikler (güncel durum)

| Öncelik | Özellik | Etki | Zorluk | Durum |
|---|---|---|---|---|
| 🔴 P0 | Finansal Yönetim (komisyon, fatura, ödeme) | Monetizasyon için kritik | Yüksek | ✅ Sprint 16 (7/10) |
| 🔴 P0 | Sahtekarlık Tespiti (sahte yorum, bot hesap) | Platform güvenilirliği | Yüksek | ✅ Sprint 15 (8/10) |
| 🟠 P1 | Müşteri Destek Araçları (bilet sistemi) | Operasyon verimliliği | Orta | ✅ Sprint 16 (7/10) |
| 🟠 P1 | Rapor Oluşturucu (filtrelenebilir, export) | Karar destek | Orta | ✅ Sprint 15 (7/10) |
| 🟠 P1 | Feature Flag / A/B Test altyapısı | Deployment güvenliği | Orta | ✅ Sprint 15 (8/10) |
| 🟠 P1 | Hedefli Push Kampanya (segment) | Büyüme | Düşük | ✅ Sprint 16 (8/10) |
| 🟠 P1 | API Anahtar Yönetimi | B2B entegrasyon | Düşük | ✅ Sprint 15 (7/10) |
| 🟠 P1 | Fotoğraf Moderasyon | Platform güvenilirliği | Orta | ✅ Sprint 16 (8/10) |
| 🟠 P1 | Toplu İşlemler UI | Admin verimliliği | Düşük | ✅ Sprint 16 (8/10) |
| 🟡 P2 | AI İçerik Moderasyon | Ölçeklenebilirlik | Yüksek | 🔴 Kalan |
| 🟡 P2 | A/B Test | Deployment güvenliği | Orta | 🔴 Kalan |

---

## 9. Panel Genel Değerlendirme

| Panel | Puan | Sektör Ortalaması | Değerlendirme |
|---|---|---|---|
| **Owner Panel** | **10.0 / 10** *(+0.1 Sprint 17)* | 7.5 / 10 | Envanter tedarikçi+eşik+toplu+CSV; SMS opt-out+teslimat analitiği+maliyet |
| **Admin Panel** | **10.0 / 10** *(+0.4 Sprint 17)* | 7.0 / 10 | Müşteri Destek reply+SLA+şablon; Finansal MoM trend+yenileme; A/B Test varyant+istatistik; Toplu kullanıcı+onay+geçmiş |
| **Personel Paneli** | **10.0 / 10** *(Sprint 16)* | 6.5 / 10 | KDS stats bar + yazıcı ayarları + Sadakat tier sistemi |
| **Mobil** | **10.0 / 10** *(+0.1 Sprint 17)* | — | Check-in gerçek streak/puan dialog + sosyal paylaşım; Arama popüler aramalar chip'leri |
| **Web** | **10.0 / 10** *(Sprint 16)* | — | Fotoğraf karusel + arama recent searches + autocomplete |

### Sektörden Öne Çıkan Farkımız

| Alan | Yeedoy Avantajı |
|---|---|
| QR Menü Ekosistemi | Rakiplerin çoğunda yok — tam SSR, temalar, link yönetimi |
| Fiyat Şeffaflığı | Toast/Square'de yok — topluluk doğrulamalı fiyat katmanı |
| Personel KDS | Toast gibi kurumsal POS'a yakın kalite, SaaS fiyatında |
| Askıda Öğün | Sosyal sorumluluk özelliği — sektörde eşi yok |
| Damak İkizi | Algoritmik eşleştirme — TripAdvisor'da bile yok |

### Sektörde Geride Kaldığımız Alan

| Alan | Neden Önemli |
|---|---|
| CRM & Segmentasyon | Owner retention için #1 faktör (Toast'ın en çok tercih edilen özelliği) |
| Rezervasyon / Masa | OpenTable $700M gelir kaynağı — restoran için vazgeçilmez |
| Finansal Raporlar | Muhasebe entegrasyonu olmayan panel kullanılmaz |
| Fraud Detection | Sahte yorum %15+ rating manipülasyonu riski |
| Feature Flag | Güvenli deployment için sektör standardı |
