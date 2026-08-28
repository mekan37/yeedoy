# YEEDOY Ürün Kapsamı — Güncel Karar Kaynağı (2026-06-24)

**Bu doküman YEEDOY ürün kapsamının TEK güncel karar kaynağıdır.** Tüm kapsam kararları, özellik talebi ve MVP sınırlandırmaları bu belgeden okunmalıdır.

---

## KAPSAM DIŞI (MVP'DE YER ALMAYACAK)

Aşağıdaki özellikler MVP kapsamında yer almamaktadır. Bu özellikler ileride, ayrı bir stratejik karar ile yeniden değerlendirilebilir.

### Sipariş & Ödeme
- **Masa siparişi (order)** — müşteri mobil uygulamadan veya QR menü üzerinden siparişi alındığı özellik MVP'de değildir
- **POS/Adisyon** — işletme personeli yönetim panelinden satış kaydı tutma MVP'de değildir
- **Ödeme & Sepet** — online ödeme işlemleri ve alışveriş sepeti MVP'de değildir
- **Teslimat** — sipariş teslimat veya kargo yönetimi MVP'de değildir

### İşletme Operasyonları
- **KDS/Mutfak Ekranı** — işletme mutfağındaki dijital sipariş yönetim sistemi MVP'de değildir

### Kullanıcı Katılımı
- **Sadakat/Loyalty Sistemi** — müşteri sadakat puanları, çekinler, ödüller MVP'de değildir
- **Gamification Ögeleri** — rozet (badge), görev (quest), XP, seviye (level), check-in, başarım sistemi MVP'de değildir

---

## KAPSAMDA (MVP'DE KALACAK)

Aşağıdaki özellikler MVP'nin temel eksiksiz ürün bileşenleridir.

### Keşif & Arama
- **Mekan Keşfi** — müşteri konum tabanlı mekan keşfi ve filtreleme
- **Yakın Mekan Keşfi** — harita/liste üzerinde yakında bulunan işletmeler
- **Arama & Filtre** — işletme adı, kategori, fiyat seviyesi, açık/kapalı statüsüne göre arama
- **Favoriler** — müşteri favori işletmeleri kaydetme ve listeleme

### İşletme Profili & Bilgisi
- **Mekan Profili** — işletme detay sayfası, açıklama, iletişim, adres, saat
- **Açık/Kapalı Bilgisi** — işletmenin anlık açık/kapalı durumu ve çalışma saatleri
- **Menü & Fiyat Görseli** — işletme menüsü, ürün fotoğrafı, fiyat bilgisi, açıklama

### Menü Yönetimi (Owner)
- **Menü Düzenleme** — işletme sahibi menü, kategoriler, ürünler ekleme/düzenleme/silme
- **Fiyat Yönetimi** — işletme sahibi ürün fiyatlarını güncelleme
- **Açık/Kapalı Ayarı** — işletme sahibi işletme açık/kapalı statusü ayarı

### Gözlemlenmiş Bilgi
- **Masa Feedback** — müşteri masadaki yemek/deneyim fotoğrafı ve yorum yapma
- **Yorum & Kanıt** — müşteri yorum ve doğrulanmış ziyaret bilgisi görseli
- **Doğrulanmış Bilgi** — müşteri masada fotoğraf çektiğinde sistem otomatik ziyareti doğrulama

### QR Menü
- **Public QR Menü** — müşteri telefonundan QR kodu okuyarak mekanın güncel menüsünü görme
- **QR Analytics** — işletme sahibi QR kod erişim istatistikleri (kaç kez tıklandı, ne zaman vb.)

### Sahiplenme & Moderasyon
- **Claim/Sahiplenme** — işletme sahibi işletmeyi yönetim panelinde sahiplenme (claim) işlemi
- **Veri Kalitesi & Moderasyon** — admin panelinden işletme bilgileri, yorum, fotoğraf moderasyonu

### İşletme Paneli (Web)
- **Owner Web Paneli** — işletme sahibi yönetim: menü, fiyat, istatistik, müşteri iletişim
- **Admin Web Paneli** — admin kullanıcı sistem moderasyonu, veri kalitesi, raporlama

### Analitik & Raporlama
- **QR Analytics** — işletme sahibi menü QR kod açılış sayıları, trend analiz
- **İşletme İstatistikleri** — yorum sayısı, puan ortalaması, ziyaret istatistikleri
- **Moderasyon Raporları** — admin panel içinde şüpheli yorum, fotoğraf, işletme bilgisi listeleme

---

## Diğer Dokümanlarla İlişki

`docs/research/` ve `docs/muhendislik/` klasörlerindeki eski raporlar (MVP Scope Prune Audit, Selective Restore Plan, Loyalty Defer Decision vb.) **tarihsel bağlam ve analiz** sağlarken, **tek başına karar kaynağı değildir**. Bu raporlar 2026 Haziran başında hazırlanmış ve o zamanın varsayımlarını yansıtmaktadır.

**Bu dosya (2026-yeedoy-final-scope-source-of-truth.md) tüm önceki raporları üstün tutar.**

Eğer bir özelliğin durumu hakkında şüphe varsa:
1. **Önce bu dosyayı kontrol et** — bu dokumentte tanımlanmış mı?
2. Sonrasında gerekirse eski raporları tarihsel bağlam için incele

---

## Güncelleme Tarihi
- **2026-06-24** — İlk sürüm, MVP final scope belirleme
