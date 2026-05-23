# Yeedoy Owner/Personel Uygulaması — Mimari Plan

> **Tarih:** 2026-05-07 | **Güncelleme:** 2026-05-07  
> **Statü:** ✅ AKTİF — Phase 1 + 2 + 3 TAMAMLANDI  
> **Karar:** Owner panel + Admin panel + Public Web → ayrı URL'ler + Garson/Owner Flutter app

---

## 1. Neden Mantıklı?

### Mevcut sorunlar

| Sorun | Sonucu |
|---|---|
| Owner paneli ve public menü aynı Next.js app'te | Bundle boyutu büyük, owner/garson mobilde kullanamıyor |
| Garsonun masadan siparişi web panelinden takip etmesi gerekiyor | Telefon yerine masaüstü bağımlılığı |
| Müşteri uygulaması (uygulamalar/mobil) owner özelliği taşıyamaz | `AGENTS.md` mimarisi bunu yasaklıyor |
| Admin paneli subdomain'e taşınmak için sadece env var gerekiyor | Middleware zaten hazır |

### Çözüm avantajları

1. **Garson/waiter deneyimi** → Telefona uygun, gerçek zamanlı, tek odaklı
2. **URL ayrımı** → Güvenlik sınırı netleşir, bağımsız deploy
3. **Shared backend** → Aynı Supabase, aynı auth — sıfır veri tekrarı
4. **Pazarlama** → "İşletme sahibi? İndir" vs "Müşteri misin? İndir" ayrımı net

---

## 2. URL / Deployment Mimarisi

```
yeedoy.com              → public (müşteri keşif, QR menü, vb.)
panel.yeedoy.com        → owner panel web (zaten middleware'de OWNER_HOSTNAMES)
ops.yeedoy.com          → admin panel web (zaten middleware'de ADMIN_HOSTNAME)
```

### Gereken değişiklik: sıfır kod, sadece env/DNS

```env
# .env.production (zaten var, sadece doldurulacak)
OWNER_HOSTNAMES=panel.yeedoy.com,panel.localhost
ADMIN_HOSTNAME=ops.yeedoy.com,ops.localhost
```

**middleware.ts zaten şunu yapıyor:**
```typescript
// panel.yeedoy.com/... → /sahip/...  (mevcut rewrite)
// ops.yeedoy.com/...   → /yonetici/... (mevcut rewrite)
```

→ DNS kaydı + env değişkeni yeterli. Kod değişikliği YOK.

---

## 3. Owner / Personel Flutter Uygulaması

### Uygulama adı: **Yeedoy İşletme**
### Klasör: `uygulamalar/personel/` (ya da `uygulamalar/isletme/`)

### Hedef kullanıcı
- **Sahip:** İşletme performansı, menü yönetimi, kampanya
- **Garson:** Masa siparişleri, bugünün spesiyali, stok durumu

### Kritik fark: müşteri app'inden
| | Müşteri App | İşletme App |
|---|---|---|
| Odak | Keşif, yemek seçimi | Operasyon, hız |
| Auth | Supabase kullanıcı | Supabase kullanıcı + `owner_claims` zorunlu |
| UI | Rich, discovery | Dense, functional, hızlı |
| Network | Read-heavy | Write-heavy (sipariş güncelle, stok) |

---

## 4. İşletme App — Özellik Listesi

### Phase 1 — Garson Odağı ✅ TAMAMLANDI (2026-05-07)

#### 4.1 Masa Siparişi Yönetimi ✅ ⭐⭐⭐⭐⭐
- Supabase Realtime subscribe → `table_orders` (INSERT + UPDATE)
- `status: pending → seen → done` geçişi (optimistic update)
- Yeni sipariş gelince vibrasyon (pattern `[0, 200, 100, 200]`)
- 2-sütun tablet / tab-based mobile layout
- `get_pending_table_orders_v1` RPC ile ilk yükleme

#### 4.2 Hızlı Müsaitlik Güncelleme ✅ ⭐⭐⭐⭐
- `menu_items.is_available` toggle — optimistic + `update_menu_item_availability_v1` RPC
- `is_available` kolonu: migration `20260507000010`

#### 4.3 Bugünün Spesiyali ✅ ⭐⭐⭐⭐
- `is_today_special` toggle — tek aktif kural (spesiyel değişince diğerleri sıfırlanır)
- `set_today_special_v1` RPC

---

### Phase 2 — Sahip Özellikleri ✅ TAMAMLANDI (2026-05-07)

#### 4.4 Anlık Dashboard ✅ ⭐⭐⭐⭐
```
Bugün:
├── Bekleyen / Hazırlanıyor / Tamamlandı sipariş sayıları
├── Aktif / Pasif menü kalemi
└── Tamamlanma oranı %
```
- `DashboardIstatistik` model + `dashboardIstatistikProvider`
- Doğrudan Supabase query (RPC yerine — daha esnek)

#### 4.5 Yorum Yönetimi ⏳ Phase 4
#### 4.6 Kampanya / Bildirim Gönder ⏳ Phase 4
#### 4.7 Temel Analitik ⏳ Phase 4

---

### Phase 3 — Operasyon ✅ TAMAMLANDI (2026-05-07)

#### 4.8 QR Masa Kartı Üretimi ✅ ⭐⭐⭐
- `qr_flutter` ile her masa için QR oluşturma
- Format: `https://yeedoy.com/masa?b={businessId}&t={tableNo}`
- `/qr` route — tab olarak erişilebilir

#### 4.8b QR Masa Tarayıcı ✅ ⭐⭐⭐ (ek)
- `mobile_scanner` ile masa QR kodu okuma
- Business ID doğrulaması + aktif siparişler bottom sheet
- Siparişler AppBar'ında `qr_code_scanner` ikonu → `/qr-tarayici` push route

#### 4.9 Sadakat Damgası Ekleme ✅ ⭐⭐⭐
- Kart listesi + stamp grid (○ → ★) + progress bar
- `add_loyalty_stamp_v1` RPC çağrısı

#### 4.9b Realtime Menü Sync ✅ ⭐⭐⭐ (ek)
- `menu_items` tablosu UPDATE eventleri dinleniyor
- Farklı garson cihazları arasında senkron

#### 4.9c Bekleyen Sipariş Rozeti ✅ ⭐⭐⭐ (ek)
- NavigationBar "Siparişler" tab'ında `Badge` (Material3)
- `bekleyenSiparisSayisiProvider` — `Provider<int>` derived

#### 4.10 Fiyat Hızlı Güncelleme ⏳ Phase 4

---

### Phase 4 — Yorum + Kampanya + Fiyat 🔜 SONRAKİ ADIM

#### 4.5 Yorum Yönetimi ⭐⭐⭐⭐
- `business_reviews` tablosundan listeleme (rating, text, author)
- `owner_reply` alanı → yanıt formu + kaydetme
- Realtime: yeni yorum gelince bildirim

#### 4.6 Kampanya / Bildirim Gönder ⭐⭐⭐
- Serbest mesaj: title + body → `notifications` INSERT
- Hedef: işletme takipçileri (`business_followers`)
- Firebase Messaging trigger (sunucu tarafı mevcut)

#### 4.10 Fiyat Hızlı Güncelleme ⭐⭐⭐
- Menü listesinden ürün seç → fiyat alanı düzenlenebilir
- `menu_items.price` doğrudan UPDATE
- Optimistic UI + hata geri alma

---

## 5. Teknik Mimari

### Klasör yapısı

```
uygulamalar/
├── mobil/          ← müşteri app (değişmiyor)
├── web/            ← public + owner web + admin web (değişmiyor)
└── personel/       ← YENİ: owner/garson Flutter app
    ├── lib/
    │   ├── uygulama/
    │   │   ├── uygulama.dart
    │   │   ├── uygulama_rotalari.dart
    │   │   └── tema/           ← ayrı tema (daha koyu, daha yoğun)
    │   ├── core/               ← az — sadece Supabase, auth, analytics
    │   └── features/
    │       ├── kimlik/         ← giriş + owner_claims kontrolü
    │       ├── masa_siparisleri/  ← realtime, temel sipariş yönetimi
    │       ├── menu_yonetimi/  ← müsaitlik, spesiyel, fiyat
    │       ├── yorumlar/       ← görüntüle + yanıtla
    │       ├── kampanya/       ← bildirim gönder
    │       └── analitik/       ← özet dashboard
    ├── android/
    ├── ios/
    └── pubspec.yaml
```

### Paylaşılan paketler (değişmeden kullanılır)

```yaml
# uygulamalar/personel/pubspec.yaml
dependencies:
  yeedoy_shared_models:
    path: ../../packages/shared_models
  yeedoy_shared_ui_components:
    path: ../../packages/shared_ui_components
  supabase_flutter: ^2.x
  go_router: ^17.x
  flutter_riverpod: ^3.x
  # EKLENECEK:
  # supabase realtime için:
  # (zaten supabase_flutter içinde)
```

### Auth akışı

```dart
// Giriş: supabase email/password
// Onay: owner_claims tablosunda approved kayıt var mı?

final claimProvider = FutureProvider<bool>((ref) async {
  final user = ref.watch(userProvider);
  if (user == null) return false;
  final res = await supabase
    .from('owner_claims')
    .select('id')
    .eq('user_id', user.id)
    .eq('status', 'approved')
    .limit(1);
  return (res as List).isNotEmpty;
});

// Claim yoksa → "İşletme sahibi değilsiniz" ekranı göster
// Claim varsa → normal akış
```

### Realtime — Masa Siparişleri

```dart
// masa_siparisleri_saglayicisi.dart
final pendingOrdersProvider = StreamProvider<List<TableOrder>>((ref) {
  final bizId = ref.watch(activeBizIdProvider);
  return supabase
    .from('table_orders')
    .stream(primaryKey: ['id'])
    .eq('business_id', bizId)
    .inFilter('status', ['pending', 'seen'])
    .order('created_at');
  // → yeni sipariş gelince otomatik güncellenir
});
```

---

## 6. Uygulama Store Stratejisi

| | Müşteri App | İşletme App |
|---|---|---|
| **Store adı** | Yeedoy | Yeedoy İşletme |
| **Bundle ID** | com.yeedoy.app | com.yeedoy.isletme |
| **İkon** | Kırmızı keşif teması | Koyu/profesyonel |
| **Açıklama** | "Yakınındaki lezzetleri keşfet" | "İşletmenizi yönetin" |
| **Hedef kitle** | Herkes | B2B / Restoran sahibi |
| **Fiyat** | Ücretsiz | Ücretsiz |

---

## 7. Geliştirme Takvimi

### ✅ Phase 1 (2026-05-07 tamamlandı)
- [x] `uygulamalar/personel/` klasörü ve pubspec
- [x] Auth akışı + owner_claims doğrulama + GoRouter guard
- [x] Realtime `table_orders` — INSERT/UPDATE Supabase channel
- [x] Sipariş listesi UI + `seen/done` güncelleme (optimistic)
- [x] Vibrasyon bildirimi (yeni sipariş)
- [x] 5-tab NavigationBar + ShellRoute

### ✅ Phase 2 (2026-05-07 tamamlandı)
- [x] Müsaitlik toggle (optimistic + RPC + realtime sync)
- [x] Bugünün spesiyali işaretleme
- [x] Anlık Dashboard (stat kartlar, tamamlanma oranı)
- [x] Sadakat kartları (stamp grid, progress bar)
- [x] Supabase migration: `is_available` kolonu + RPC'ler

### ✅ Phase 3 (2026-05-07 tamamlandı)
- [x] QR masa kartı üretimi (qr_flutter)
- [x] QR masa tarayıcı (mobile_scanner, bottom sheet detay)
- [x] Bekleyen sipariş rozeti (NavigationBar Badge)
- [x] Realtime menü availability sync (Supabase channel)
- [x] `flutter analyze`: No issues found

### ✅ Phase 4 (2026-05-07 tamamlandı)
- [x] Yorum listeleme + owner yanıt formu (`/yorumlar`, `YorumlarSayfasi`)
- [x] Takipçiye bildirim gönder — `send_business_campaign_v1` RPC + `KampanyaSayfasi`
- [x] Fiyat hızlı güncelleme — menü listesinde edit ikonu, `fiyatGuncelle()` + optimistic
- [x] Dashboard AppBar'da Yorumlar + Kampanya ikonları
- [x] Migration: `20260507000011_personel_kampanya.sql`
- [x] `flutter analyze`: No issues found (tüm Phase 1–4)

### ✅ Web URL Ayrımı — Kod Tarafı Tamamlandı (2026-05-07)
- [x] `.env.example` güncellendi — `OWNER_HOSTNAMES`, `ADMIN_HOSTNAME`, `OWN_HOSTNAMES`, `NEXT_PUBLIC_PANEL_URL` belgelendi
- [x] `middleware.ts` → panel subdomain `robots.txt` → `Disallow: /` + `X-Robots-Tag: noindex` yanıtı
- [x] `next.config.mjs` → `allowedDevOrigins` → `panel.localhost`, `ops.localhost` eklendi
- [x] `DEPLOY_CHECKLIST.md` → env vars güncellendi + subdomain smoke test adımları eklendi
- [x] TypeScript: clean | ESLint middleware/config: no warnings

**Kalan (infrastructure / ops):**
- [ ] DNS kayıtları: `panel.yeedoy.com` → Vercel deployment | `ops.yeedoy.com` → aynı
- [ ] Vercel env vars: `OWNER_HOSTNAMES`, `ADMIN_HOSTNAME`, `NEXT_PUBLIC_PANEL_URL`
- [ ] Vercel custom domains: `panel.yeedoy.com` + `ops.yeedoy.com` projede eklenmeli

### ✅ Personel App — Deploy Hazırlığı (2026-05-07)
- [x] Platform dizinleri: `android/`, `ios/`, `linux/`, `macos/`, `web/`, `windows/` — mevcut
- [x] `.env` → `APP_ENV=development` (Firebase init atlanır, local Supabase çalışır)
- [x] `.env.example` oluşturuldu — tüm değişkenler belgelendi
- [x] `main.dart` → Firebase init koşullu: `APP_ENV=production` olduğunda çalışır
- [x] `flutter analyze`: No issues found

**Production'a geçmeden önce (ops):**
- [ ] `flutterfire configure` → `lib/firebase_options.dart` + `android/app/google-services.json` + `ios/Runner/GoogleService-Info.plist`
- [ ] `.env` → `APP_ENV=production` + production Supabase URL/key
- [ ] `android/app/build.gradle.kts` → `applicationId`, signing config
- [ ] iOS `Runner.xcodeproj` → Bundle ID, provisioning profile

---

## 8. Dikkat Edilecekler

### 8.1 Maintenance yükü
İki Flutter app = iki CI/CD, iki store, iki sürüm yönetimi.  
**Azaltma yöntemi:** Ortak kodun max'ını `packages/` içine taşı.

### 8.2 Owner kimlik doğrulaması
`owner_claims.status = 'approved'` kontrolü her ekranda yapılmalı.  
Middleware benzeri bir `AsyncGuard` widget yazılmalı.

### 8.3 Garson vs Sahip rolleri
Phase 2'de gerekebilir: garson sadece `masa_siparisleri` görsün, sahip her şeyi.  
Şimdi gerekmiyor — `owner_claims` yeterli.

### 8.4 Web panel hâlâ yaşıyor
Owner web paneli kaldırılmıyor — masaüstü kullanım, raporlar, ayarlar için gerekli.  
App sadece mobil/hızlı operasyon içindir.

---

## 9. MVP Sonrası Özellikler (backlog)

- Masa planı (floor plan görünümü)
- Rezervasyon yönetimi
- Ürün stok takibi
- Vardiya yönetimi
- Garson performans istatistiği
- Çevrimiçi ödeme entegrasyonu (Phase 2 sipariş sistemi)

---

## 10. Karar: Yapılmalı mı?

### Evet, şu koşullarla:

1. **MVP = sadece Masa Siparişi** (hafta 1-2). Yalnızca bu özellik bile değer yaratır.
2. **Tüm müşteri feature'larını kopyalamak yok.** App tek odaklı kalır.
3. **URL ayrımı önce yapılır** — ücretsiz, DNS + env değişikliği.
4. **Shared packages önce güçlendirilir** — kod tekrarını önler.

### Başlangıç için minimum:
```
personel app = Giriş + Sipariş listesi (realtime) + Görüldü/Tamamlandı
```
Bu kadarı bile garsonun telefon başında olmak yerine müşteriye gitmesini sağlar.

---

---

## 11. Mevcut Durum Özeti (2026-05-07)

| Özellik | Durum | Dosya |
|---|---|---|
| Auth + owner_claims gating | ✅ | `features/kimlik/` |
| Realtime sipariş akışı | ✅ | `features/masa_siparisleri/` |
| Dashboard istatistikleri | ✅ | `features/dashboard/` |
| Menü availability toggle | ✅ | `features/menu_yonetimi/` |
| Bugünün spesiyali | ✅ | `features/menu_yonetimi/` |
| Realtime menü sync | ✅ | `MenuYonetimiBildiricisi` |
| Sadakat kartları | ✅ | `features/sadakat/` |
| QR kod üretimi | ✅ | `features/qr/` |
| QR kod tarayıcı | ✅ | `features/qr_tarayici/` |
| Tab rozeti (pending sayısı) | ✅ | `AnaKabuk + bekleyenSiparisSayisiProvider` |
| Yorum yönetimi | ✅ | `features/yorumlar/` |
| Kampanya / bildirim | ✅ | `features/kampanya/` + RPC |
| Fiyat güncelleme | ✅ | `MenuYonetimiBildiricisi.fiyatGuncelle()` |
| Platform dizinleri (iOS/Android) | ⏳ Build zamanı | `flutter create` |

`flutter analyze`: **No issues found** (tüm phase'ler sonrası)
