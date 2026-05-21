# Yeedoy — Eksikler & Güçlendirme Listesi

> **Tarih:** 2026-05-21  
> Kapsamlı codebase analizi sonucu tespit edilen eksikler. Her madde uygulanabilir ve ölçülebilir.  
> Öncelik: 🔴 Kritik → 🟠 Yüksek → 🟡 Orta → ⚪ Düşük

---

## WEB (`uygulamalar/web`)

### 🔴 Kritik — Kullanıcı Deneyimini Engelliyor

| # | Eksik | Nerede | Notlar |
|---|---|---|---|
| W-1 | **Profil düzenleme** sayfası/modalı yok | `/profil/settings` linki var, sayfa yok | Ad, şehir, bio güncellenemiyor |
| W-2 | **Avatar yükleme/kırpma** arayüzü yok | `profil/page.tsx` | `avatar_url` sütunu var ama UI yok |
| W-3 | **Şifre sıfırlama** sayfası yok | `/sifre-sifirlama` route tanımlı ama boş | `resetPassword()` servisi mevcut |
| W-4 | **Boş durum grafikleri** yok | Discovery, inbox, feed | Sadece metin var, illüstrasyon yok |
| W-5 | **Yükleniyor iskelet** animasyonları yok | Tüm liste sayfaları | Kart shimmer eksik |
| W-6 | **E-posta zaten kayıtlı** hatası ham Supabase mesajı | Kayıt formu | Türkçe, anlaşılır hata mesajı yok |

---

### 🟠 Yüksek — Profesyonellik Farkı

| # | Eksik | Nerede | Notlar |
|---|---|---|---|
| W-7 | **Toast bildirimleri** yok | Favori, check-in, silme sonrası | `bildirim-toast.tsx` var ama tetiklenmiyor |
| W-8 | **Optimistik UI** güncelleme yok | Favori butonu, beğeni | Tıklayınca anında değişmeli |
| W-9 | **Buton yükleme durumu** yok | Tüm submit butonları | OAuth butonları tıklanınca spinner yok |
| W-10 | **Şifre göster/gizle** ikonu eksik | Kayıt ve giriş formu | Tek göz ikonu toggle yeterli |
| W-11 | **Aktif menü göstergesi** yok | Header nav | Hangi sayfada olunduğu belli değil |
| W-12 | **Hata mesajları** `aria-describedby` ile bağlı değil | Tüm formlar | Erişilebilirlik sorunu |
| W-13 | **Oturumu kapat** çalışıyor mu tüm cihazlarda? | `profil/security/page.tsx` | "Tüm cihazlardan çıkış" kontrolü belirsiz |
| W-14 | **Sayfa başlığı animasyonu** yok | Header scroll | Scroll'da header küçülmüyor/gizlenmiyor |
| W-15 | **Mobil arama formu** yok | Header `<1024px` | Hamburger açılıyor ama arama yok |
| W-16 | **Telefon numarası otomatik formatı** yok | Kayıt formu | `05XX XXX XX XX` gibi yazarken formatlanmıyor |

---

### 🟡 Orta — Özellik Tamamlama

| # | Eksik | Nerede | Notlar |
|---|---|---|---|
| W-17 | **Harita görünümü** uygulanmamış | `/kesif/harita` route var | Sekme görünüyor, sayfa boş |
| W-18 | **Arama sayfası** belirsiz | `/arama` linki var | İçerik bilinmiyor |
| W-19 | **Taste Twin** tamamlanmamış | `/tat-ikizi` | Footer linki var, sayfa minimal |
| W-20 | **Bütçe planlayıcı** tamamlanmamış | `/butce` | Link var, içerik eksik |
| W-21 | **Profil gizlilik** seçeneği yok | Profil sayfası | Kimler görebilir seçeneği yok |
| W-22 | **Bio karakter sayacı** yok | Profil formu (olmayan) | Max 280 karakter ama sayaç gösterilmiyor |
| W-23 | **Güvenlik sekmesi** tamamlanmamış | `/profil/security` | Oturum geçmişi yok |
| W-24 | **Bildirim tercihleri** bağlı değil | `/bildirim-ayarlari` | Sayfa var ama kaydetme var mı? |
| W-25 | **İşletme adresi** kopyalanabilir değil | İşletme detay sayfası | "Kopyala" butonu yok |
| W-26 | **Çalışma saatleri** "Şu an kapalı" kırmızı gösterge yok | İşletme saati bölümü | Sadece liste gösteriliyor |

---

### ⚪ Düşük — İnce Dokunuşlar

| # | Eksik | Nerede |
|---|---|---|
| W-27 | Tahmin edilen kaydolma akışı yok (onboarding) | Yeni kullanıcı sonrası |
| W-28 | Hızlandırma sınırı bilgisi gösterilmiyor | Çok deneme sonrası |
| W-29 | Oturum zaman aşımı uyarısı yok | Uzun oturumlar |
| W-30 | Yıldız derecesi renk göstergesi yok | İşletme kartları |
| W-31 | Fiyat seviyesi rozeti (€/€€/€€€) yok | İşletme detayı |

---

## MOBİL (`uygulamalar/mobil`)

### 🔴 Kritik

| # | Eksik | Nerede | Notlar |
|---|---|---|---|
| M-1 | **Şifre güç göstergesi** yok | `giris_sayfasi.dart` | Web'e eklendi, mobil'e eklenmedi |
| M-2 | **Şifremi Unuttum** sayfası tamamlanmamış | `/forgot-password` route var | Butona bağlı ama sayfa içeriği belirsiz |
| M-3 | **Profil düzenleme** eksik | Profil sayfası | Sütunlar var (city, district, phone) ama form yok |
| M-4 | **OTP yeniden gönder** sayacı yok | `_PhoneForm` | Süre dolmadan yeniden gönderme önlenmiyor |
| M-5 | **Boş durum** grafikleri eksik | Discovery, feed | Metin var, illüstrasyon yok |

---

### 🟠 Yüksek

| # | Eksik | Nerede | Notlar |
|---|---|---|---|
| M-6 | **Biyometrik giriş** yok | Giriş sayfası | Face ID / Parmak izi standart beklenti |
| M-7 | **Şifre göster/gizle** ikonu yok | Şifre inputu | TextField `obscureText` toggle eksik |
| M-8 | **Haptic feedback** tutarsız | Butonlar, kartlar | Bazı aksiyonlarda yok |
| M-9 | **İskelet yükleme** animasyonları eksik | Liste sayfaları | `AppSkeletonLine` var ama çoğu yerde kullanılmıyor |
| M-10 | **Hata silkeleme** animasyonu yok | Giriş başarısız | Yanlış şifrede form titremeli |
| M-11 | **Başarılı kayıt** animasyonu yok | Kayıt sonrası | Confetti veya tick animasyonu yok |
| M-12 | **Kişisel veri** güncelleme formu yok | Profil ayarları | `city`, `district`, `phone` düzenlenemiyor |
| M-13 | **Avatar yükleme** yok | Profil | `avatar_url` sütunu var, UI yok |
| M-14 | **Telefon numarası** ülke kodu seçici yok | Telefon OTP | Sadece Türkiye (+90), sabit |
| M-15 | **Oturum geçmişi** ve "tüm cihazlardan çıkış" yok | Güvenlik ayarları |  |

---

### 🟡 Orta

| # | Eksik | Nerede | Notlar |
|---|---|---|---|
| M-16 | **Hesap silme** seçeneği yok | Profil/Ayarlar | GDPR/KVKK gereği olmalı |
| M-17 | **Veri dışa aktarma** yok | Profil/Ayarlar | KVKK gereği |
| M-18 | **Bildirim ses/titreşim** tercihleri | Bildirim ayarları | Tür bazlı kontrol yok |
| M-19 | **Çevrimdışı mod** göstergesi yok | Uygulama geneli | İnternet yok → sessiz hata |
| M-20 | **Fotoğraf yükleme** yorum formunda yok | Yorum oluşturma | Görsel proof önemli |
| M-21 | **SMS otomatik doldurma** yok | OTP girişi | Android `RECEIVE_SMS` + iOS autofill eksik |
| M-22 | **Tab geçiş** animasyonları yok | Discovery sekmeleri | Anlık geçiyor, smooth değil |
| M-23 | **Filtre badge sayısı** yok | Discovery filtreleri | Kaç filtre aktif belli değil |
| M-24 | **İl/ilçe seçici** yok | Profil güncelleme | Web'e eklendi, mobil'de yok |

---

### ⚪ Düşük

| # | Eksik | Nerede |
|---|---|---|
| M-25 | Uygulama değerlendirme prompt yok | N kullanım sonrası |
| M-26 | Yeni özellik tanıtım tooltip'leri yok | Feature rollout |
| M-27 | Çalışma saatleri "şu an kapalı" indicator | İşletme detayı |
| M-28 | Fiyat seviyesi rozeti (€/€€/€€€) | İşletme kartları |
| M-29 | Ses ile arama yok | Discovery arama |

---

## HER İKİ PLATFORM — Ortak Eksikler

| # | Eksik | Öncelik | Notlar |
|---|---|---|---|
| C-1 | **Onboarding akışı** sonlanmamış | 🟠 | `baslangic/page.tsx` var ama yönlendirme belirsiz |
| C-2 | **Gerçek zamanlı bildirimler** (WebSocket/SSE) | 🟡 | Supabase realtime kullanılmıyor |
| C-3 | **Karanlık mod** mobil implementasyonu | 🟡 | Tema token'ları var ama flutter dark theme tamamlanmamış |
| C-4 | **Çevrimdışı sıra** (offline queue) | 🟡 | Smoke test var ama gerçek impl. belirsiz |
| C-5 | **Deep link** yönetimi | 🟡 | Ortak liste, işletme link'i çalışıyor mu? |
| C-6 | **İki faktörlü doğrulama** (2FA) | 🟡 | Supabase destekliyor, UI yok |
| C-7 | **Puan sistemi** görselleştirmesi | 🟡 | XP/level var, animasyon yok |
| C-8 | **Fotoğraf galerisi** görüntüleyici | 🟡 | İşletme fotoğrafları tam ekran göstergesi yok |
| C-9 | **Engelleme/şikayet** sistemi | ⚪ | Kullanıcı engelleme UI'ı yok |
| C-10 | **Yardım/SSS** sayfası | ⚪ | `yasal` var, yardım yok |

---

## Kısa Vadeli Uygulama Sırası (Önerilen)

```
1. M-1  Mobilde şifre güç göstergesi (web'den port et)
2. W-10 / M-7  Şifre göster/gizle toggle
3. W-7  Toast bildirimleri sistemi (favori, check-in vb.)
4. W-1 / M-3  Profil düzenleme formu (city, district, phone, bio)
5. W-2 / M-13  Avatar yükleme (Supabase Storage)
6. W-3  Şifre sıfırlama sayfası (web)
7. M-2  Şifremi unuttum sayfası (mobil)
8. W-5 / M-9  İskelet yükleme animasyonları
9. W-4 / M-5  Boş durum grafikleri
10. M-6  Biyometrik giriş
```

---

## İlk Kullanım Turu (Feature Tour / Coach Marks) — Detaylı Plan

> Kullanıcıya "bu ekran ne işe yarıyor" diye anlatan sistem.  
> Mobil onboarding slaytları **değer önerisi** anlatır; bu plan **uygulama içi UI turu** tasarlar.

---

### Mevcut Durum

| Uygulama | Onboarding Slaytları | UI Turu | Durum |
|---|---|---|---|
| Mobil | ✅ 5 slayt (konum, diyet, fiyat, topluluk, bildirim) | ❌ yok | Kısmen var |
| Personel | ❌ yok | ❌ yok | Hiç yok |
| Web | — | — | Web'de bu gerekmiyor (hover tooltip yeterli) |

---

### Teknik Yaklaşım: `showcaseview` paketi

```yaml
# Her iki uygulamanın pubspec.yaml dosyasına eklenecek
showcaseview: ^3.0.0
```

**Neden `showcaseview`:**
- Pub.dev'de en popüler Flutter tur paketi (1000+ like)
- Belirli widget'ları `Showcase` ile sararsın, SDK sıralı vurgu yapar
- `GlobalKey` bazlı, herhangi bir widget'ı hedef alabilir
- Konum bilgisi otomatik hesaplanır (overlay + ok + açıklama balonu)
- `SharedPreferences` ile "ilk gösterim" kontrolü kolay entegre edilir

---

### 1. Personel Uygulaması Planı

#### 1a. Onboarding Slaytları (yeni ekran)

**Dosya:** `uygulamalar/personel/lib/features/onboarding/ui/personel_onboarding_sayfasi.dart`

3 slayt (basit, hızlı):

```
Slayt 1 — Hoş Geldiniz
┌─────────────────────────┐
│  [Yeedoy Logo]          │
│                         │
│  Personel Paneline      │
│  Hoş Geldiniz           │
│                         │
│  Masaları yönetin,      │
│  siparişleri takip      │
│  edin, menüyü           │
│  güncelleyin.           │
│                         │
│  [Devam →]              │
└─────────────────────────┘

Slayt 2 — Sipariş Yönetimi
┌─────────────────────────┐
│  [🧾 ikon]              │
│                         │
│  Siparişler             │
│                         │
│  Masalardan gelen       │
│  QR siparişleri         │
│  gerçek zamanlı         │
│  görürsünüz.            │
│                         │
│  [İleri →]              │
└─────────────────────────┘

Slayt 3 — Mutfak Ekranı
┌─────────────────────────┐
│  [🍳 ikon]              │
│                         │
│  Mutfak Ekranı (KDS)    │
│                         │
│  Hazırlanacak           │
│  siparişler burada      │
│  görünür, tamamlanınca  │
│  işaretlersiniz.        │
│                         │
│  [Başla →]              │
└─────────────────────────┘
```

**Tetikleme:** `main.dart` → `SharedPreferences` → `personel_onboarding_goruldu` key'i `false` ise onboarding'e yönlendir.

#### 1b. UI Turu (showcaseview)

**Dosya:** `uygulamalar/personel/lib/features/shared/ui/ana_kabuk.dart` (güncellenir)

6 coach mark — bottom nav her öğesine birer tane:

```dart
// GlobalKey'ler AnaKabuk state'inde tanımlanır
final _siparislerKey = GlobalKey();
final _dashboardKey  = GlobalKey();
final _menuKey       = GlobalKey();
final _sadakatKey    = GlobalKey();
final _kdsKey        = GlobalKey();
final _ayarlarKey    = GlobalKey();

// Showcase açıklamaları:
// siparisler: "Masalardan gelen siparişleri buradan takip edin"
// dashboard:  "Günlük satış özeti ve istatistikler"
// menu:       "Menü kalemlerini ekle, fiyat güncelle"
// sadakat:    "Müşteri sadakat puanlarını tara ve onayla"
// kds:        "Mutfak ekranı — hazırlanacak siparişler"
// ayarlar:    "Hesap ve uygulama tercihleri"
```

**Tetikleme:** Onboarding bittikten sonra ilk açılışta otomatik başlar.  
`SharedPreferences` key: `personel_tur_goruldu`

**Kullanıcı her zaman tekrar başlatabilir:** Ayarlar sayfasına "Turu Yeniden Göster" butonu eklenir.

---

### 2. Mobil Uygulama Planı

#### 2a. Mevcut Onboarding'e Eklenti (6. Slayt)

Mevcut `onboarding_sayfasi.dart` dosyasında `_pageCount = 5` → `6` yapılır.  
Son slayt "Uygulamayı keşfet" olur:

```
Slayt 6 (yeni) — Uygulama Turu
┌─────────────────────────┐
│  [🗺 ikon]              │
│                         │
│  Her Şey Elinizde       │
│                         │
│  • Alt menüden          │
│    istediğiniz bölüme   │
│    geçin                │
│  • ☰ Hamburger ile      │
│    tüm özelliklere      │
│    ulaşın               │
│  • Profil → XP ve       │
│    başarımlarınız       │
│                         │
│  [Keşfetmeye Başla →]   │
└─────────────────────────┘
```

#### 2b. Ana Sayfa UI Turu (showcaseview)

**Dosya:** `uygulamalar/mobil/lib/features/shared/ui/bilesenler/alt_navigasyon.dart` (güncellenir)

4 coach mark — alt navigasyon öğelerine:

```dart
// GlobalKey'ler
final _discoverKey  = GlobalKey();  // "Keşfet" sekmesi
final _mapKey       = GlobalKey();  // "Harita" sekmesi
final _favoritesKey = GlobalKey();  // "Favoriler" sekmesi
final _profileKey   = GlobalKey();  // "Profil" sekmesi

// + Ana sayfada merkez QR butonu için ayrı key
final _qrKey        = GlobalKey();
```

Açıklama baloncukları:
- **Keşfet:** "Yakınındaki restoran ve kafeleri keşfet, fiyatları karşılaştır"
- **Harita:** "Haritada konuma göre mekanları gör"
- **Favoriler:** "Beğendiğin yerleri kaydet, koleksiyonlar oluştur"
- **Profil:** "XP kazan, başarım aç, katkılarını gör"
- **QR Butonu:** "QR kodu tara → menüyü gör veya check-in yap"

**Tetikleme:**  
- Onboarding tamamlandıktan sonra ilk /discover açılışında otomatik başlar
- `SharedPreferences` key: `mobil_ui_turu_goruldu`
- Drawer → Ayarlar → "Turu Tekrar Göster" butonu

---

### 3. Ortak Altyapı

#### Dosyalar

```
uygulamalar/
├── mobil/lib/core/depolama/
│   └── tur_tercihleri.dart          # SharedPreferences wrapper
│       ├── setTurGoruldu(key)
│       └── isTurGoruldu(key) → bool
│
└── personel/lib/core/depolama/
    └── tur_tercihleri.dart          # Aynı pattern
```

#### pubspec.yaml değişiklikleri

```yaml
# uygulamalar/mobil/pubspec.yaml
dependencies:
  showcaseview: ^3.0.0

# uygulamalar/personel/pubspec.yaml
dependencies:
  showcaseview: ^3.0.0
```

---

### 4. Uygulama Sırası

```
1. pubspec'lere showcaseview ekle + flutter pub get
2. tur_tercihleri.dart oluştur (her iki uygulama)
3. Personel: personel_onboarding_sayfasi.dart (3 slayt)
4. Personel: main.dart → onboarding yönlendirme
5. Personel: ana_kabuk.dart → 6 coach mark + ShowCaseWidget wrapper
6. Personel: ayarlar sayfasına "Turu Yeniden Göster" butonu
7. Mobil: onboarding_sayfasi.dart → 6. slayt ekle
8. Mobil: alt_navigasyon.dart → 5 coach mark + ShowCaseWidget wrapper
9. Mobil: profil/ayarlar → "Turu Yeniden Göster" butonu
```

---

### 5. showcaseview Kullanım Örneği

```dart
// Herhangi bir widget'ı vurgula
Showcase(
  key: _siparislerKey,
  title: 'Siparişler',
  description: 'Masalardan gelen siparişleri buradan takip edin.',
  tooltipBackgroundColor: AppColors.primary,
  textColor: Colors.white,
  child: NavigationDestination(
    icon: Icon(Icons.receipt_long_outlined),
    label: 'Siparişler',
  ),
),

// Turu başlat
ShowCaseWidget.of(context).startShowCase([
  _siparislerKey,
  _dashboardKey,
  _menuKey,
  _sadakatKey,
  _kdsKey,
  _ayarlarKey,
]);
```

---

*Bu dosya canlı tutulmalıdır. Tamamlanan maddeler ~~üstü çizili~~ veya ✅ ile işaretlenmeli.*
