# Firebase + Supabase Kurulum Rehberi
> **Hedef:** Yeni Gmail hesabıyla Yeedoy personel uygulaması + web için tüm backend servislerini kurmak.

---

## ADIM 0 — Hazırlık

### Gerekli araçlar (henüz kurulu değilse)

| Araç | Komut |
|---|---|
| Node.js (v20+) | `node --version` ile kontrol et |
| Flutter SDK | `flutter --version` |
| Dart | Flutter ile gelir |
| Firebase CLI | `npm install -g firebase-tools` |
| FlutterFire CLI | `dart pub global activate flutterfire_cli` |
| Supabase CLI | `npm install -g supabase` |

---

## ADIM 1 — Supabase Kurulumu

### 1.1 Hesap Oluştur

1. **`supabase.com`** adresine git
2. **"Start your project"** → **"Sign in with GitHub"** veya **"Sign up"** ile Gmail ile kayıt ol
3. E-posta doğrulamasını tamamla

### 1.2 Proje Oluştur

1. Dashboard'da **"New project"** tıkla
2. **Organization:** Personal (veya yeni org oluştur → "Yeedoy")
3. Doldur:
   ```
   Project name:  yeedoy-production
   Database password: [GÜÇLİ BİR ŞİFRE — kaydet, tekrar göremezsin]
   Region: West EU (Frankfurt) veya sana en yakın
   Plan: Free (başlangıç için yeterli)
   ```
4. **"Create new project"** tıkla — ~2 dakika bekle

### 1.3 Gerekli Değerleri Kopyala

Proje oluştuktan sonra **Settings → API** sayfasına git:

```
┌─────────────────────────────────────────────────────┐
│  Kopyalaman gerekenler:                             │
│                                                     │
│  Project URL:                                       │
│  https://dktdnbeougrmhkzplbap.supabase.co                  │
│           └─ bunu not al                            │
│                                                     │
│  anon / public key:                                 │
│  eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRrdGRuYmVvdWdybWhrenBsYmFwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzgxNTUxNDMsImV4cCI6MjA5MzczMTE0M30.IHYJKW4N2E25bbUvNR-nzNh1XPcivDPzTx2uWcqMi78          │
│           └─ bunu not al                            │
│                                                     │
│  service_role key:  [reveal tıkla]                  │
│  eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRrdGRuYmVvdWdybWhrenBsYmFwIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3ODE1NTE0MywiZXhwIjoyMDkzNzMxMTQzfQ.BlSX6Uouy_0hKKoVnBOYOkMgMkDL3IMyARaU4KGAHlA           │
│  ⚠️  BU ANAHTARI GİZLİ TUT — asla frontend'e koyma │
└─────────────────────────────────────────────────────┘
```

### 1.4 Migration'ları Uygula

Supabase CLI ile local migration'ları production'a gönder:

```bash
# Terminalde yeedoy/ ana klasörüne git
cd C:\yeedoy

# Supabase'e giriş yap
supabase login
# Tarayıcı açılır → Gmail ile giriş yap → terminal'e döner

# Remote projeyle bağlantı kur (project-ref = URL'deki XXXXXXXXXXXX kısmı)
supabase link --project-ref XXXXXXXXXXXX

# Migration'ları uygula
supabase db push
```

---

## ADIM 2 — Firebase Kurulumu

### 2.1 Firebase Projesi Oluştur

1. **`console.firebase.google.com`** adresine git
2. Gmail hesabınla giriş yap
3. **"Add project"** tıkla
4. Doldur:
   ```
   Project name:  Yeedoy
   (Proje ID otomatik gelir: yeedoy-XXXXX)
   ```
5. Google Analytics: **Enable** → hesap seç/oluştur → **"Create project"**
6. ~1 dakika bekle → **"Continue"**

### 2.2 Android Uygulaması Ekle

**Console → Project Overview → Android ikonu**

```
Android package name:  com.yeedoy.personel
App nickname:          Yeedoy Personel (opsiyonel)
Debug signing certificate SHA-1:  (şimdilik boş bırak)
```

**"Register app"** → **"Download google-services.json"** tıkla

> 📥 **İndirilen dosya:** `google-services.json`
>
> **Nereye koy:**
> ```
> C:\yeedoy\uygulamalar\personel\android\app\google-services.json
> ```

"Next → Next → Continue to console" ile devam et.

### 2.3 iOS Uygulaması Ekle

**Console → Project Overview → iOS ikonu**

```
Apple bundle ID:  com.yeedoy.personel
App nickname:     Yeedoy Personel (opsiyonel)
App Store ID:     (şimdilik boş bırak)
```

**"Register app"** → **"Download GoogleService-Info.plist"** tıkla

> 📥 **İndirilen dosya:** `GoogleService-Info.plist`
>
> **Nereye koy:**
> ```
> C:\yeedoy\uygulamalar\personel\ios\Runner\GoogleService-Info.plist
> ```

"Next → Next → Continue to console" ile devam et.

### 2.4 Firebase Messaging (Push Bildirimler) Etkinleştir

1. Console'da **Build → Cloud Messaging** sayfasına git
2. Zaten aktif olmalı — **"Get started"** butonuna tıkla (gerekiyorsa)

### 2.5 firebase_options.dart Oluştur

Terminalde personel klasörüne git:

```bash
cd C:\yeedoy\uygulamalar\personel

# Firebase'e giriş yap (daha önce yapmadıysan)
firebase login
# Tarayıcı açılır → Gmail ile giriş yap

# FlutterFire CLI ile yapılandır
flutterfire configure
```

**Komut çalışınca şunları sorar:**

```
? Select a Firebase project:
  ▸ yeedoy-XXXXX (Yeedoy)     ← bunu seç

? Which platforms should your configuration support?
  ◉ android
  ◉ ios
  ○ web                         ← personel app için web gerekmez
  ○ macos
  ○ linux
  ○ windows
```

**Seç → Enter**

> 📄 **Oluşturulan dosya:** `lib/firebase_options.dart`
>
> ✅ `android/app/google-services.json` zaten doğru yerde olacak
> ✅ `ios/Runner/GoogleService-Info.plist` zaten doğru yerde olacak

### 2.6 main.dart Güncelle

`flutterfire configure` sonrası `lib/firebase_options.dart` oluşur.
`main.dart`'ı güncelleyerek bunu kullan:

```dart
// lib/main.dart — APP_ENV=production olduğunda bu satırı ekle
import 'firebase_options.dart';

// Firebase.initializeApp() çağrısını şöyle güncelle:
if (dotenv.env['APP_ENV'] == 'production') {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
}
```

---

## ADIM 3 — Env Dosyalarını Güncelle

### 3.1 Personel App (.env)

`C:\yeedoy\uygulamalar\personel\.env` dosyasını aç, şöyle güncelle:

```env
# Supabase — 1.3'te kopyaladığın değerler
SUPABASE_URL=https://XXXXXXXXXXXX.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...

# Production build için production yap
APP_ENV=production
```

### 3.2 Web App (.env.local)

`C:\yeedoy\uygulamalar\web\` klasöründe `.env.local` dosyası oluştur
(`.env.example` dosyasını kopyala, adını değiştir, değerleri doldur):

```env
# Supabase
NEXT_PUBLIC_SUPABASE_URL=https://XXXXXXXXXXXX.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
SUPABASE_SERVICE_ROLE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...

# Site
NEXT_PUBLIC_SITE_URL=https://yeedoy.com
NEXT_PUBLIC_PANEL_URL=https://panel.yeedoy.com

# Subdomain routing (DNS kurulunca)
OWNER_HOSTNAMES=panel.yeedoy.com,panel.localhost
ADMIN_HOSTNAME=ops.yeedoy.com,ops.localhost
OWN_HOSTNAMES=yeedoy.com,www.yeedoy.com,localhost

# Güvenlik
REVALIDATE_SECRET=en_az_32_karakter_rastgele_bir_string_gir
```

---

## ADIM 4 — Android Package Name Güncelle

`C:\yeedoy\uygulamalar\personel\android\app\build.gradle.kts` dosyasında:

```kotlin
android {
    namespace = "com.yeedoy.personel"     // ← bunu ekle/güncelle
    defaultConfig {
        applicationId = "com.yeedoy.personel"   // ← bunu güncelle
        ...
    }
}
```

iOS için `C:\yeedoy\uygulamalar\personel\ios\Runner\` klasöründe:
- Xcode veya VS Code'da `Runner.xcodeproj` aç
- **TARGETS → Runner → General → Bundle Identifier** → `com.yeedoy.personel`

---

## ADIM 5 — Doğrulama

### Flutter App

```bash
cd C:\yeedoy\uygulamalar\personel
flutter analyze          # 0 hata olmalı
flutter run              # emülatörde dene
```

### Web App

```bash
cd C:\yeedoy\uygulamalar\web
npm run typecheck        # TypeScript hata olmamalı
npm run dev              # localhost:3000'de aç
```

---

## ADIM 6 — Vercel Deploy (Web)

1. **`vercel.com`** → Gmail ile giriş yap
2. **"Add New → Project"** → GitHub repo'yu bağla
3. **Root Directory:** `uygulamalar/web`
4. **Environment Variables** sekmesine tıkla, yukarıdaki `.env.local` değerlerini ekle
5. **Deploy**
6. Deploy sonrası:
   - **Settings → Domains** → `yeedoy.com` ekle
   - **Settings → Domains** → `panel.yeedoy.com` ekle
   - **Settings → Domains** → `ops.yeedoy.com` ekle

---

## Özet — Nereye Ne Koyulacak

```
C:\yeedoy\
├── uygulamalar\
│   ├── personel\
│   │   ├── .env                              ← Supabase URL/key + APP_ENV=production
│   │   ├── lib\
│   │   │   └── firebase_options.dart         ← flutterfire configure ile oluşur
│   │   ├── android\app\
│   │   │   └── google-services.json          ← Firebase console'dan indir
│   │   └── ios\Runner\
│   │       └── GoogleService-Info.plist      ← Firebase console'dan indir
│   └── web\
│       └── .env.local                        ← .env.example'den kopyala, doldur
└── supabase\
    └── migrations\                           ← supabase db push ile production'a gönderilir
```

---

## Kontrol Listesi

- [ ] Supabase hesabı oluşturuldu (Gmail ile)
- [ ] Supabase projesi oluşturuldu (`yeedoy-production`)
- [ ] URL + anon key + service_role key not alındı
- [ ] `supabase db push` çalıştırıldı
- [ ] Firebase projesi oluşturuldu (`Yeedoy`)
- [ ] Android uygulaması eklendi → `google-services.json` indirildi ve yerleştirildi
- [ ] iOS uygulaması eklendi → `GoogleService-Info.plist` indirildi ve yerleştirildi
- [ ] `flutterfire configure` çalıştırıldı → `firebase_options.dart` oluştu
- [ ] `main.dart` `DefaultFirebaseOptions` ile güncellendi
- [ ] `personel/.env` production değerleriyle güncellendi
- [ ] `web/.env.local` oluşturuldu ve dolduruldu
- [ ] `android/app/build.gradle.kts` → `applicationId = "com.yeedoy.personel"`
- [ ] `flutter analyze` → No issues
- [ ] `npm run typecheck` → No errors
- [ ] Vercel'e deploy edildi
- [ ] `panel.yeedoy.com` ve `ops.yeedoy.com` Vercel'de eklendi
