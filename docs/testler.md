# Yeedoy Test Ortamı — Giriş Bilgileri

> **Supabase Projesi:** https://dktdnbeougrmhkzplbap.supabase.co  
> **Oluşturulma:** 2026-05-12  
> **Tüm şifreler:** `123`

---

## Kullanıcılar

### Admin

| Alan | Değer |
|---|---|
| **E-posta** | `admin@yeedoy.test` |
| **Şifre** | `123` |
| **Rol** | Admin (admin_users tablosunda kayıtlı) |
| **Ad** | Yeedoy Admin |
| **UUID** | `aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa` |

### Owner Kullanıcıları

| Ad | E-posta | Şifre | UUID | İşletmeler |
|---|---|---|---|---|
| **Ahmet Demir** | `owner1@yeedoy.test` | `123` | `b0b0b0b0-b0b0-b0b0-b0b0-b0b0b0b0b0b0` | Sultana Kebap, Boğaziçi Balık, Anadolu Pide, Bursa Köfte, Sürpriz Cafe |
| **Fatma Yılmaz** | `owner2@yeedoy.test` | `123` | `c0c0c0c0-c0c0-c0c0-c0c0-c0c0c0c0c0c0` | Mehmet Usta Döner, Çınaraltı Pide, Pizza Lazzara, Leziz Burger, Keyif Restoran |

### Normal Kullanıcılar

| Ad | E-posta | Şifre | UUID |
|---|---|---|---|
| **Mehmet Kaya** | `kullanici1@yeedoy.test` | `123` | `d1d1d1d1-d1d1-d1d1-d1d1-d1d1d1d1d1d1` |
| **Zeynep Arslan** | `kullanici2@yeedoy.test` | `123` | `d2d2d2d2-d2d2-d2d2-d2d2-d2d2d2d2d2d2` |
| **Ali Çelik** | `kullanici3@yeedoy.test` | `123` | `d3d3d3d3-d3d3-d3d3-d3d3-d3d3d3d3d3d3` |
| **Ayşe Şahin** | `kullanici4@yeedoy.test` | `123` | `d4d4d4d4-d4d4-d4d4-d4d4-d4d4d4d4d4d4` |
| **Emre Koç** | `kullanici5@yeedoy.test` | `123` | `d5d5d5d5-d5d5-d5d5-d5d5-d5d5d5d5d5d5` |

---

## İşletmeler (10 adet)

### Owner 1 — Ahmet Demir

| # | İşletme | Kategori | Şehir | UUID |
|---|---|---|---|---|
| 1 | **Sultana Kebap Salonu** | Kebap | İstanbul / Kadıköy | `b1111111-1111-1111-1111-111111111111` |
| 2 | **Boğaziçi Balıkçısı** | Balık & Deniz Ürünleri | İstanbul / Beşiktaş | `b2222222-2222-2222-2222-222222222222` |
| 3 | **Anadolu Pide Evi** | Pide & Lahmacun | Ankara / Çankaya | `b3333333-3333-3333-3333-333333333333` |
| 4 | **Bursa Köftecisi** | Köfte & Izgara | Bursa / Osmangazi | `b4444444-4444-4444-4444-444444444444` |
| 5 | **Sürpriz Cafe & Kahvaltı** | Kahvaltı & Cafe | İzmir / Konak | `b5555555-5555-5555-5555-555555555555` |

### Owner 2 — Fatma Yılmaz

| # | İşletme | Kategori | Şehir | UUID |
|---|---|---|---|---|
| 6 | **Mehmet Usta Dönercisi** | Döner | İstanbul / Şişli | `b6666666-6666-6666-6666-666666666666` |
| 7 | **Çınaraltı Pidecisi** | Pide & Lahmacun | Adana / Seyhan | `b7777777-7777-7777-7777-777777777777` |
| 8 | **Pizza Lazzara** | Pizza | İstanbul / Beyoğlu | `b8888888-8888-8888-8888-888888888888` |
| 9 | **Leziz Burger Co.** | Burger & Fast Food | Ankara / Yenimahalle | `b9999999-9999-9999-9999-999999999999` |
| 10 | **Keyif Restoran** | Restoran | İzmir / Bornova | `baaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaab` |

---

## Menüler

Her işletmenin 1 yayınlanmış menüsü var. Her menüde 2 bölüm, her bölümde 2-4 ürün bulunuyor.

| İşletme | Menü Başlığı | Bölümler | Ürünler |
|---|---|---|---|
| Sultana Kebap | Sultana Kebap Menüsü | Ana Yemekler, Yan Ürünler | Adana Kebap (₺180), Urfa Kebap (₺170), Kanat Izgara (₺150), Cacık (₺40), Mercimek Çorbası (₺50) |
| Boğaziçi Balık | Boğaziçi Balık Menüsü | Balık Çeşitleri, Mezeler | Lüfer Izgara (₺320), Levrek Buğulama (₺280), Karides Güveç (₺240), Tarama (₺80), Midye Dolma (₺90) |
| Anadolu Pide | Anadolu Pide Menüsü | Pideler, Lahmacun | Kaşarlı Pide (₺140), Kıymalı Pide (₺160), Yumurtalı Pide (₺145), Lahmacun (₺70) |
| Bursa Köfte | Bursa Köfte Menüsü | Köfte Çeşitleri, Izgara | Bursa Köftesi (₺160), İnegöl Köfte (₺150), Piliç Şiş (₺170) |
| Sürpriz Cafe | Sürpriz Cafe Menüsü | Kahvaltı Tabakları, İçecekler | Serpme Kahvaltı (₺180), Menemen (₺110), Filtre Kahve (₺65), Taze Sıkma OJ (₺50) |
| Mehmet Usta | Mehmet Usta Döner Menüsü | Döner Çeşitleri, Ekstralar | Ekmek Arası Döner (₺90), Tabak Döner (₺140), Dürüm Döner (₺100), Ayran (₺25) |
| Çınaraltı Pide | Çınaraltı Pide Menüsü | Pide Çeşitleri, Tatlılar | Kuşbaşılı Pide (₺180), Sucuklu Pide (₺160), Sütlaç (₺90) |
| Pizza Lazzara | Pizza Lazzara Menüsü | Pizzalar, Makarnalar | Margherita (₺180), Pepperoni (₺220), 4 Peynir (₺240), Carbonara (₺190) |
| Leziz Burger | Leziz Burger Menüsü | Burgerler, Yan Lezzetler | Classic Burger (₺180), Smash Burger (₺200), BBQ Burger (₺220), Patates Kızartması (₺70), Soğan Halkası (₺80) |
| Keyif Restoran | Keyif Restoran Menüsü | Başlangıçlar, Ana Yemekler | Zeytinyağlı Sarma (₺110), Mevsim Salatası (₺90), Kuzu Tandır (₺320), Testi Kebabı (₺380) |

---

## Yorumlar

5 kullanıcı × 10 işletme = **50 yorum** (hepsi `approved` statüsünde).

Her kullanıcı her işletmeye farklı bir yorum bırakmıştır. Puanlar 3-5 arasında değişmektedir ve lezzet, servis, fiyat-performans, atmosfer alt puanlarını içermektedir.

---

## Veri Özeti

| Tablo | Kayıt Sayısı |
|---|---|
| auth.users | 8 |
| user_profiles | 8 |
| admin_users | 1 |
| businesses | 10 |
| owner_claims (approved) | 10 |
| menus | 10 |
| menu_sections | 20 |
| menu_items | 41 |
| reviews | 50 |

---

## Notlar

- Tüm kullanıcılar e-posta onaylıdır (`email_confirmed_at` dolu).
- `owner_claims` tablosundaki status `approved` olduğu için owner'lar panel paneline erişebilir.
- `admin_users` tablosunda `aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa` UUID'si kayıtlıdır.
- Yorumlar doğrudan SQL ile eklendiğinden `business_stats` tablosu güncellenmemiştir — panelde ortalama puanlar boş görünebilir.
- `menus.trg_audit_menus_cud_v1` trigger'ında bozuk referans var (`NEW.name` yok, `NEW.title` olmalı) — trigger devre dışı bırakılmıştır.

---

## Sistemleri Çalıştırma

### Supabase Bağlantı Bilgileri (ortak)

```
SUPABASE_URL   = https://dktdnbeougrmhkzplbap.supabase.co
SUPABASE_ANON_KEY = eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRrdGRuYmVvdWdybWhrenBsYmFwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzgxNTUxNDMsImV4cCI6MjA5MzczMTE0M30.IHYJKW4N2E25bbUvNR-nzNh1XPcivDPzTx2uWcqMi78
```

---

### 1. Mobil Uygulama (Flutter)

**Konum:** `uygulamalar/mobil/`

**Adım 1 — `.env` dosyası oluştur:**
```
# uygulamalar/mobil/.env
SUPABASE_URL=https://dktdnbeougrmhkzplbap.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRrdGRuYmVvdWdybWhrenBsYmFwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzgxNTUxNDMsImV4cCI6MjA5MzczMTE0M30.IHYJKW4N2E25bbUvNR-nzNh1XPcivDPzTx2uWcqMi78
APP_ENV=development
```

**Adım 2 — Bağımlılıkları yükle:**
```bash
cd uygulamalar/mobil
flutter pub get
```

**Adım 3 — Çalıştır:**
```bash
# Android emülatör / fiziksel cihaz
flutter run -t lib/mobil_giris.dart

# Belirli cihaz ID ile
flutter run -d <device_id>

# Web tarayıcıda
flutter run -d chrome

# Cihaz listesini görmek için
flutter devices
```

**Giriş:** Herhangi bir kullanıcı e-postası + şifre `123`

---

### 2. Personel Uygulaması (Flutter)

**Konum:** `uygulamalar/personel/`

**Adım 1 — `.env` dosyası oluştur:**
```
# uygulamalar/personel/.env
SUPABASE_URL=https://dktdnbeougrmhkzplbap.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRrdGRuYmVvdWdybWhrenBsYmFwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzgxNTUxNDMsImV4cCI6MjA5MzczMTE0M30.IHYJKW4N2E25bbUvNR-nzNh1XPcivDPzTx2uWcqMi78
APP_ENV=development
```

**Adım 2 — Bağımlılıkları yükle:**
```bash
cd uygulamalar/personel
flutter pub get
```

**Adım 3 — Çalıştır:**
```bash
flutter run
```

**Giriş:** `owner1@yeedoy.test` veya `owner2@yeedoy.test` — şifre `123`  
> Personel uygulaması owner_claims tablosundaki işletmelere bağlı çalışır. Owner olarak giriniz.

---

### 3. Web Uygulaması (Next.js)

**Konum:** `uygulamalar/web/`  
**Web + Owner Panel + Admin Panel hepsi aynı Next.js uygulamasıdır.**

**Adım 1 — `.env.local` dosyası oluştur:**
```
# uygulamalar/web/.env.local
NEXT_PUBLIC_SUPABASE_URL=https://dktdnbeougrmhkzplbap.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRrdGRuYmVvdWdybWhrenBsYmFwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzgxNTUxNDMsImV4cCI6MjA5MzczMTE0M30.IHYJKW4N2E25bbUvNR-nzNh1XPcivDPzTx2uWcqMi78
```

**Adım 2 — Bağımlılıkları yükle:**
```bash
cd uygulamalar/web
npm install
```

**Adım 3 — Geliştirme sunucusunu başlat:**
```bash
npm run dev
```

Uygulama `http://localhost:3000` adresinde çalışır.

---

### 4. Owner Panel (Web içinde)

**URL:** `http://localhost:3000/sahip`

Web uygulaması çalışırken:

1. `http://localhost:3000/giris` adresine git
2. Owner kullanıcısıyla giriş yap:
   - `owner1@yeedoy.test` / `123` → Ahmet Demir'in 5 işletmesi
   - `owner2@yeedoy.test` / `123` → Fatma Yılmaz'ın 5 işletmesi
3. Giriş sonrası otomatik olarak `/sahip` paneline yönlendirilirsin

**Panel bölümleri:**
| Sayfa | URL |
|---|---|
| Dashboard | `/sahip/gosterge-panosu` |
| İşletmeler | `/sahip/isletmeler` |
| Menüler | `/sahip/menuler` |
| Siparişler | `/sahip/siparisler` |
| Yorumlar | `/sahip/yorumlar` |
| Analitik | `/sahip/analitik` |
| CRM | `/sahip/crm` |
| Finansal | `/sahip/finansal` |
| Envanter | `/sahip/envanter` |
| SMS Pazarlama | `/sahip/pazarlama/sms` |

---

### 5. Admin Panel (Web içinde)

**URL:** `http://localhost:3000/yonetici`

Web uygulaması çalışırken:

1. `http://localhost:3000/giris` adresine git
2. Admin kullanıcısıyla giriş yap:
   - `admin@yeedoy.test` / `123`
3. Giriş sonrası otomatik olarak `/yonetici` paneline yönlendirilirsin

**Panel bölümleri:**
| Sayfa | URL |
|---|---|
| Dashboard | `/yonetici/gosterge-panosu` |
| İşletmeler | `/yonetici/isletmeler` |
| Kullanıcılar | `/yonetici/kullanicilar` |
| Yorumlar | `/yonetici/yorumlar` |
| Fotoğraf Mod. | `/yonetici/fotograf-moderasyon` |
| A/B Test | `/yonetici/ab-test` |
| Feature Flags | `/yonetici/feature-flags` |
| Push Kampanya | `/yonetici/push-kampanyalari` |
| Müşteri Destek | `/yonetici/musteri-destek` |
| Toplu İşlemler | `/yonetici/toplu-islemler` |
| Finansal Yönetim | `/yonetici/finansal-yonetim` |
| KVKK / GDPR | `/yonetici/kvkk-gdpr` |
| Raporlar | `/yonetici/raporlar` |
| API Anahtarları | `/yonetici/api-anahtarlari` |
| Gözlemlenebilirlik | `/yonetici/gozlemlenebilirlik` |

---

### Hızlı Başlangıç — Hepsini Birden

3 terminal aç:

```bash
# Terminal 1 — Web (Owner + Admin Panel dahil)
cd uygulamalar/web && npm run dev

# Terminal 2 — Mobil
cd uygulamalar/mobil && flutter run

# Terminal 3 — Personel
cd uygulamalar/personel && flutter run
```

> **.env dosyaları .gitignore'dadır.** Her cihazda yukarıdaki adımları tekrar yapman gerekir.
