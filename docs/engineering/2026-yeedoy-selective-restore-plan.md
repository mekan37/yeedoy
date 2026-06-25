# YEEDOY Selective Restore Plan — MVP Cleanup Değerlendirmesi

> **DEPRECATED / HISTORICAL CONTEXT:** Bu dosya tarihsel analizdir. Güncel scope kararı için bkz. `docs/product/2026-yeedoy-final-scope-source-of-truth.md`.

**Tarih:** 2026-06-24  
**Scope:** Analiz ve Rapor (Restore işlemi değil)  
**Yedek Kaynağı:** `D:\yeedoy-backups\pre-mvp-cleanup-20260623-0945\working-tree`

---

## Özet

Proje, MVP odaklı temizlik geçirdi (commit: `557b38b`, `34854ce`, `db48e62`). Temizlik sırasında:
- **Navigasyon yüzeylerinden gizlenen:** web routes (bütçe, karşılaştır, liderler, vs.), personel nav (sipariş/KDS/sadakat), mobil nav (başarılar)
- **Kod tamamen kaldırılan:** mobil günlük görevler (`daily_micro_task`), başarılar (`achievements`), personel masa siparişi nav öğeleri
- **Veritabanı/RPC:** Hiçbir migration/RPC kaldırılmadı — sadece nav gizlendi
- **MVP Kapsamı:** Claim, menü, QR, yorum, favoriler, sahip panel — korundu

**Bulgu:** İnsan ve veri yönetim sayfaları (CRM, Finansal, Envanter, Pazarlama, AI Analizi vb.) MVP kapsamı olarak değerlendirilmiş ve navigasyondan kaldırılmıştır, fakat sayfa kodu hâlâ serviste ve veritabanı desteği tamamen mevcuttur. Bu sayfaların geri açılması, kod değişikliği olmadan sadece nav URL'lerini aktif etme işlemidir.

---

## 1. Geri Alınacak Dosyalar ve Değişiklikler

Aşağıda, MVP karar sonrası navigasyondan gizlenen ama teknik açıdan tam işlevsel olan öğeler listelenmiştir. Bunlar "feature geri açma" kategorisinde (kodu geri kopyalama değil, sadece nav/route aktif etme).

### 1.1 Web Routes (Next.js) — Navigasyondan Gizlenen Sayfalar

Tüm sayfa dosyaları hâlâ `uygulamalar/web/app/*/page.tsx` dosyalarında mevcuttur ve redirect yapılmaktadır. Geri alınacak işlem: sayfa içeriklerini backup'tan restore etmek.

| Dosya Yolu | Özellik | Mevcut Durum | Yedekte | Aksiyonlar |
|---|---|---|---|---|
| `uygulamalar/web/app/(genel)/butce/page.tsx` | Bütçe Kombinaları | Redirect `/kesif` | Full UI + Supabase query | Sayfa içeriğini restore et; nav'a link ekle (varsa) |
| `uygulamalar/web/app/(genel)/karsilastir/page.tsx` | İşletme Karşılaştır | Redirect `/kesif` | Full UI + filter/compare logic | Sayfa içeriğini restore et |
| `uygulamalar/web/app/(genel)/liderler/page.tsx` | Haftalık Liderler | Redirect `/kesif` | Full UI + leaderboard RPC | Sayfa içeriğini restore et |
| `uygulamalar/web/app/(genel)/siparis/[slug]/page.tsx` | Masa Sipariş Detayı | Gutted | Full UI | Sayfa içeriğini restore et (POS/order MVP-dışı — geri almayın) |
| `uygulamalar/web/app/(genel)/zincir/[slug]/page.tsx` | Zincir Detayı | Gutted | Full UI | Sayfa içeriğini restore et |
| `uygulamalar/web/app/(genel)/zincirler/page.tsx` | Zincir Listesi | Gutted | Full UI + search | Sayfa içeriğini restore et |
| `uygulamalar/web/app/(kimlik)/akilli-akis/page.tsx` | Smart Feed | Gutted | Full UI + subscription RSC | Sayfa içeriğini restore et |
| `uygulamalar/web/app/(kimlik)/grup-istekleri/[id]/page.tsx` | Grup İsteği Detayı | Gutted | Full UI | Sayfa içeriğini restore et |
| `uygulamalar/web/app/(kimlik)/grup-istekleri/new/page.tsx` | Yeni Grup İsteği | Gutted | Full UI + form | Sayfa içeriğini restore et |
| `uygulamalar/web/app/(kimlik)/grup-istekleri/page.tsx` | Grup İstekleri Listesi | Gutted | Full UI | Sayfa içeriğini restore et |
| `uygulamalar/web/app/(kimlik)/ortak-listeler/[id]/page.tsx` | Ortak Liste Detayı | Gutted | Full UI | Sayfa içeriğini restore et |
| `uygulamalar/web/app/(kimlik)/ortak-listeler/join/page.tsx` | Ortak Liste Katıl | Gutted | Full UI | Sayfa içeriğini restore et |
| `uygulamalar/web/app/(kimlik)/ortak-listeler/page.tsx` | Ortak Listelerim | Gutted | Full UI | Sayfa içeriğini restore et |
| `uygulamalar/web/app/(kimlik)/tat-ikizi/page.tsx` | Taste Twin | Gutted | Full UI | Sayfa içeriğini restore et |
| `uygulamalar/web/app/sahip/buyume/page.tsx` | Büyüme (Owner) | Gutted | Full UI + charts | Sayfa içeriğini restore et |
| `uygulamalar/web/app/sahip/crm/page.tsx` | CRM (Owner) | Gutted | Full UI + table | Sayfa içeriğini restore et |
| `uygulamalar/web/app/sahip/envanter/page.tsx` | Envanter (Owner) | Gutted | Full UI | Sayfa içeriğini restore et |
| `uygulamalar/web/app/sahip/finansal/page.tsx` | Finansal (Owner) | Gutted | Full UI + report | Sayfa içeriğini restore et |
| `uygulamalar/web/app/sahip/istekler/page.tsx` | İstekler (Owner) | Gutted | Full UI | Sayfa içeriğini restore et |
| `uygulamalar/web/app/sahip/pazarlama/e-posta/page.tsx` | E-Posta Pazarlama | Gutted | Full UI + campaign | Sayfa içeriğini restore et |
| `uygulamalar/web/app/sahip/pazarlama/kampanyalar/page.tsx` | Pazarlama Kampanyaları | Gutted | Full UI | Sayfa içeriğini restore et |
| `uygulamalar/web/app/sahip/pazarlama/otomasyonlar/page.tsx` | Pazarlama Otomasyonları | Gutted | Full UI | Sayfa içeriğini restore et |
| `uygulamalar/web/app/sahip/pazarlama/page.tsx` | Pazarlama Merkezi | Gutted | Full UI | Sayfa içeriğini restore et |
| `uygulamalar/web/app/sahip/pazarlama/sms/page.tsx` | SMS Pazarlama | Gutted | Full UI + form | Sayfa içeriğini restore et |
| `uygulamalar/web/app/sahip/siparisler/page.tsx` | Masa Siparişleri (Owner) | Gutted | Full UI | **Geri almayın — POS MVP-dışı** |
| `uygulamalar/web/app/sahip/sponsorluk/page.tsx` | Sponsorluk (Owner) | Gutted | Full UI | **Geri almayın — sponsorluk MVP-dışı** |
| `uygulamalar/web/app/sahip/yapay-zeka-analizi/page.tsx` | AI Analizi (Owner) | Gutted | Full UI | Sayfa içeriğini restore et |
| `uygulamalar/web/app/yonetici/ab-test/page.tsx` | A/B Test (Admin) | Gutted | Full UI | Sayfa içeriğini restore et |
| `uygulamalar/web/app/yonetici/b2b-dis-aktarim/page.tsx` | B2B Dış Aktarım | Gutted | Full UI | Sayfa içeriğini restore et |
| `uygulamalar/web/app/yonetici/finansal-yonetim/page.tsx` | Finansal Yönetim (Admin) | Gutted | Full UI + report | Sayfa içeriğini restore et |
| `uygulamalar/web/app/yonetici/grup-istekleri/page.tsx` | Grup İstekleri (Admin) | Gutted | Full UI | Sayfa içeriğini restore et |
| `uygulamalar/web/app/yonetici/masa-geri-bildirimleri/page.tsx` | Masa Feedback (Admin) | Gutted | Full UI + table | **Geri almayın — table order MVP-dışı** |
| `uygulamalar/web/app/yonetici/push-kampanyalari/page.tsx` | Push Kampanyaları | Gutted | Full UI + form | Sayfa içeriğini restore et |
| `uygulamalar/web/app/yonetici/sponsor-adaylari/page.tsx` | Sponsorluk Adayları | Gutted | Full UI | **Geri almayın — sponsorluk MVP-dışı** |
| `uygulamalar/web/app/yonetici/sponsor-paketleri/page.tsx` | Sponsorluk Paketleri | Gutted | Full UI | **Geri almayın — sponsorluk MVP-dışı** |
| `uygulamalar/web/app/yonetici/sponsorluklar/page.tsx` | Sponsorluk Yönetim | Gutted | Full UI + table | **Geri almayın — sponsorluk MVP-dışı** |

**Not:** `(genel)` → `(public)` ve `(kimlik)` → `(auth)` route grupları yedekte özel adlardır — restore sırasında doğru grup adlarına kopyalanmalıdır.

### 1.2 Web Navigation Shells — Nav Bağlantılarını Geri Açma

| Dosya | Değişiklik | Mevcut | Yedekte | Aksiyonlar |
|---|---|---|---|---|
| `uygulamalar/web/src/ui/kabuk/sahip-kabuk-istemcisi.tsx` | Owner nav — 10 link kaldırıldı | 8 link | 18 link | 10 link'i nav yapısına geri ekle (finansal, CRM, buyume, siparisler, sponsorluk, pazarlama, envanter, askiya-alinanlar, yapay-zeka) |
| `uygulamalar/web/src/ui/kabuk/yonetici-kabuk-istemcisi.tsx` | Admin nav — 8 link kaldırıldı | 38 link | 46+ link | 8 link'i geri ekle (finansal, sponsor sayfaları, growth, masa-feedback) |
| `uygulamalar/web/src/ui/acik/yerlesim.tsx` | Public nav — minimal değişiklik | 5 link | 6 link | Link kontrol et (liderler, zincirler vs.) |

### 1.3 Personel (Flutter Web) — Navigation Restoration

| Dosya | Değişiklik | Mevcut | Yedekte | Aksiyonlar |
|---|---|---|---|---|
| `uygulamalar/personel/lib/features/shared/ui/ana_kabuk.dart` | Bottom nav — 3 tab kaldırıldı | 3 tab | 6 tab | Restore: Siparişler, Sadakat, KDS tab'larını ekle (routes `/siparisler`, `/sadakat`, `/kds`) |
| `uygulamalar/personel/lib/uygulama/uygulama_rotalari.dart` | Routes — 3 route tanımı kaldırıldı | 3 route | 6 route | `/siparisler`, `/sadakat`, `/kds` route handler'larını ekle |

### 1.4 Mobile (Flutter) — Code Restoration (Limited)

| Dosya | Değişiklik | Mevcut | Yedekte | Aksiyonlar |
|---|---|---|---|---|
| `uygulamalar/mobil/lib/features/profile/ui/profile_page.dart` | Achievements + daily tasks bölümleri kaldırıldı | 904 satır (stripped) | 904 satır (full) | `_DailyTaskCard`, `_AchievementsSection` widget'larını geri ekle (code restore gerekli) |
| `uygulamalar/mobil/lib/app/router.dart` | Route imports + definition kaldırıldı | No achievements | Has `/achievements` | `/achievements` route'u ekle; `achievements_page.dart` import'u ekle |
| `uygulamalar/mobil/lib/features/shared/ui/components/app_drawer.dart` | Achievements link kaldırıldı | No link | Has link | Drawer'da achievements link'ini geri ekle |
| `uygulamalar/mobil/lib/features/profile/domain/achievements_provider.dart` | **Feature directory** | Dosya YOK | Dosya var | Directory `features/achievements/` tümünü restore etme — MVP-dışı |

**Not:** Mobil achievements sistemi tam bir feature directory'sidir (data/domain/ui). Kaldırıldı çünkü gamification MVP-dışı. Restore etmeden önce stakeholder onayı gereklidir.

---

## 2. Geri Alınmayacak Dosyalar (MVP Kapsamı Dışı)

Aşağıdaki özellikler **stratejik karar raporunda** (docs/research/2026-yeedoy-stratejik-karar-raporu.md) MVP dışı olarak belirtilmiştir. Bu öğelerle ilgili hiçbir restore işlemi yapılmayacaktır:

### 2.1 POS / Masa Siparişi (Order)
- **Neden:** MVP kapsamı: QR menü görüntüme, fiyat doğrulama, yorum. Sipariş/ödeme H2 sonrası planlandı.
- **Dosyalar:**
  - `uygulamalar/web/app/(genel)/siparis/[slug]/page.tsx`
  - `uygulamalar/web/app/sahip/siparisler/page.tsx`
  - Personel `/siparisler` route'u ve UI
  - `uygulamalar/web/src/ui/kabuk/sahip-kabuk-istemcisi.tsx` masa siparişi link'i
- **Durum:** Veritabanı tabeloları mevcuttur; nav gizlendi.

### 2.2 Gamification / Loyalty
- **Neden:** Sadakat/badge/XP sistemleri MVP-dışı. Sonra yeniden aktivasyon göz önüne alındı.
- **Dosyalar:**
  - Mobil `/achievements` sayfası ve feature
  - Web `/sadakat` sayfası
  - Personel `/sadakat` tab'ı
  - `uygulamalar/web/app/(kimlik)/sadakat/page.tsx`
  - `uygulamalar/web/app/sahip/pazarlama/sadakat/page.tsx`
  - `uygulamalar/mobil/lib/features/profile/domain/daily_micro_task*.dart`
- **Durum:** Veritabanı/RPC korundu; nav gizlendi.

### 2.3 Sponsorluk / Reklam (Ads)
- **Neden:** Gelir modeli H2'ye ertelendi.
- **Dosyalar:**
  - `uygulamalar/web/app/sahip/sponsorluk/page.tsx`
  - `uygulamalar/web/app/yonetici/sponsor-*/page.tsx` (3 sayfa)
  - Nav bağlantıları (owner + admin)
- **Durum:** Veritabanı/RPC korundu; sadece nav gizlendi.

### 2.4 KDS / Mutfak Ekranı
- **Neden:** Order flow gelmeyince KDS desteği gerekli değil.
- **Dosyalar:**
  - Personel `/kds` route'u ve UI
  - Personel ana_kabuk.dart KDS tab'ı
- **Durum:** Veritabanı yok; sadece nav ref kaldırıldı.

### 2.5 Masa Feedback
- **Neden:** Order sistemine bağlı (müşteri masa geri bildirimi).
- **Dosyalar:**
  - `uygulamalar/web/app/yonetici/masa-geri-bildirimleri/page.tsx`
- **Durum:** Veritabanı mevcuttur; sadece nav gizlendi.

---

## 3. İnsan Kararı Gerekenler (Sınırda Kalan)

Aşağıdaki sayfalar MVP kararındaki "Büyüme/Yönetim" kategorisinde yer alır. Teknik açıdan tam işlevseldir, fakat stakeholder'lardan onay alınması önerilir:

| Sayfa | Kapsam | Risk | Karar Gerekli |
|---|---|---|---|
| Owner Finansal / CRM / Envanter / Büyüme | İşletme yönetimi | Kullanıcılardan feedback beklenebilir | Ürün: Bu sayfalar ne zaman aktif olabilir? |
| Admin Finansal Yönetim | Platforma raporlama | İçerik doğruluğu kontrol edilmeli | Veri: Finansal rakamlar güncel mi? |
| Owner/Admin AI Analizi | Yapay zeka önerileri | Model eğitimi eksik olabilir | ML: Model hazır mı? |
| Web Liderler / Top Businesses | Haftalık sıralama | Leaderboard mantığı test edilmeli | PM: Algoritma MVP-uyumlu mu? |
| Karşılaştır / Bütçe Komboları | Keşif ek özellikleri | Sorgu performansı | DB/API: Sorgular optimize mi? |

**Tavsiye:** Bu sayfaları restore etmeden önce ilgili tim lead'leriyle "hazır mısınız?" toplantısı yapılması. Sayfalar hazır; eksik olan ürün kararı veya veri hazırlığı.

---

## 4. Önerilen PR Sırası (Restore Şeması)

MVP restore işi şu şekilde bölünebilir. Her PR bağımsız, gözden geçirilebilir, ve test edilebilir:

### PR-1: Web Public Routes (Guideline-uyumlu)
**Scope:** Halka açık sayfalardaki redirect'ler → normal içeriğe dönüş  
**Dosyalar:**
- `(public)/budget/page.tsx`
- `(public)/compare/page.tsx`
- `(public)/heroes/page.tsx`
- `(public)/chain/[slug]/page.tsx`
- `(public)/chains/page.tsx`

**Risk:** Düşük (public sayfalarda güvenlik kritik değil)  
**Test:** `npm run test:e2e` (public-menu)  
**Tahmini Zaman:** 1-2 saat

---

### PR-2: Web Auth Routes (Kollab + Group + Taste Twin)
**Scope:** Kimlik doğrulanmış sayfalar (grup istekleri, ortak listeler, taste twin)  
**Dosyalar:**
- `(auth)/group-requests/*.tsx` (3 dosya)
- `(auth)/collab-lists/*.tsx` (3 dosya)
- `(auth)/taste-twin/page.tsx`

**Risk:** Orta (RPC çağrıları gerekli; group_requests ve collab_lists MVP-uyumlu)  
**Test:** `npm run test:unit`; Supabase RPC mock'ları kontrol et  
**Tahmini Zaman:** 2-3 saat

---

### PR-3: Web Public Nav (Owner Shell)
**Scope:** Owner navigasyon shell'ini restore et (8→18 link)  
**Dosyalar:**
- `src/ui/kabuk/sahip-kabuk-istemcisi.tsx` (nav items + icon functions)

**Risk:** Düşük (nav-only değişiklik; routes zaten var)  
**Test:** Manual: her link sağlıklı mı diye kontrol  
**Tahmini Zaman:** 30 dakika

---

### PR-4: Web Admin Nav
**Scope:** Admin navigasyon shell'i (38→46+ link)  
**Dosyalar:**
- `src/ui/kabuk/yonetici-kabuk-istemcisi.tsx`

**Risk:** Düşük (nav-only)  
**Test:** Manual  
**Tahmini Zaman:** 30 dakika

---

### PR-5: Owner Pages (Finansal, CRM, Envanter, vb.)
**Scope:** Owner panel'deki yönetim sayfaları  
**Dosyalar:**
- `app/sahip/finansal/page.tsx`
- `app/sahip/crm/page.tsx`
- `app/sahip/envanter/page.tsx`
- `app/sahip/buyume/page.tsx`
- `app/sahip/yapay-zeka-analizi/page.tsx`

**Risk:** Orta (raporlama sayfaları; DB sorgularının performansı kontrol edilmeli)  
**Test:** `npm run typecheck` + `npm run test:unit` + manuel smoke test  
**Tahmini Zaman:** 4-6 saat

---

### PR-6: Owner Marketing Pages
**Scope:** Owner pazarlama merkezi  
**Dosyalar:**
- `app/sahip/pazarlama/page.tsx` (hub)
- `app/sahip/pazarlama/e-posta/page.tsx`
- `app/sahip/pazarlama/kampanyalar/page.tsx`
- `app/sahip/pazarlama/otomasyonlar/page.tsx`
- `app/sahip/pazarlama/sms/page.tsx`

**Risk:** Orta-yüksek (e-mail/SMS entegrasyonları; delivery service hazır mı diye kontrol et)  
**Test:** `npm run typecheck` + mock Supabase calls  
**Tahmini Zaman:** 4-5 saat

---

### PR-7: Admin Pages (Finansal, B2B, Growth, Push, etc.)
**Scope:** Admin panel yönetim sayfaları  
**Dosyalar:**
- `app/yonetici/finansal-yonetim/page.tsx`
- `app/yonetici/b2b-dis-aktarim/page.tsx`
- `app/yonetici/push-kampanyalari/page.tsx`
- `app/yonetici/ab-test/page.tsx`
- `app/yonetici/grup-istekleri/page.tsx`

**Risk:** Orta (admin-only; finansal doğruluk kritik)  
**Test:** `npm run typecheck` + `npm run test:unit`  
**Tahmini Zaman:** 5-7 saat

---

### PR-8: Personel (Flutter Web) Navigation + Routes
**Scope:** Personel app'ta masa siparişi, sadakat, KDS tab'larını nav'a geri ekle  
**Dosyalar:**
- `uygulamalar/personel/lib/features/shared/ui/ana_kabuk.dart` (nav struct)
- `uygulamalar/personel/lib/uygulama/uygulama_rotalari.dart` (route definitions)

**Risk:** Düşük (nav-only; kodu geri açma)  
**Test:** `flutter analyze` + `flutter test`  
**Tahmini Zaman:** 1 saat

---

### PR-9: Mobile Achievements (Son/Optional)
**Scope:** Mobil app'ta başarılar (gamification) restore  
**Dosyalar:**
- `uygulamalar/mobil/lib/features/profile/ui/profile_page.dart` (widget restore)
- `uygulamalar/mobil/lib/app/router.dart` (route + import)
- `uygulamalar/mobil/lib/features/shared/ui/components/app_drawer.dart` (link)
- `uygulamalar/mobil/lib/features/achievements/` (feature directory kopyala)

**Risk:** Orta (gamification tam feature; code diff büyük; test gerekli)  
**Test:** `flutter analyze` + `flutter test` (achievements test'leri yaz)  
**Tahmini Zaman:** 4-5 saat

**Uyarı:** Bu PR, "başarılar sistemi MVP sonrası mi açılacak?" sorusunun cevaplanmasını bekler.

---

## 5. Geri Alma İşleminin Teknik Detayları

### 5.1 Web Routes Restore (Tüm `/page.tsx`)
Komut (örnek — her dosya için):
```bash
# Backup'tan getir
cp D:/yeedoy-backups/pre-mvp-cleanup-20260623-0945/working-tree/uygulamalar/web/app/\(genel\)/butce/page.tsx \
   C:/yeedoy/uygulamalar/web/app/\(genel\)/butce/page.tsx

# Typechecker ve lint'i çalıştır
npm run typecheck
npm run lint
```

### 5.2 Navigation Shell Restore
`sahip-kabuk-istemcisi.tsx` örneği:
```typescript
// Backup'tan: ownerNavSections array'ini restore et (18 item)
// Aralarından MVP-dışı itemler (siparisler, sponsorluk) hariç tut
// Icon function'larını geri ekle: OrderIcon, TrendingIcon, MegaphoneIcon, vb.

const ownerNavSections: NavSection[] = [
  {
    title: 'Büyüme',
    items: [
      { href: '/sahip/analitik', label: 'Analitik', icon: <ChartIcon /> },
      { href: '/sahip/finansal', label: 'Finansal Raporlar', icon: <TLIcon /> },  // ← restore
      { href: '/sahip/crm', label: 'Müşteri CRM', icon: <CrmIcon /> },             // ← restore
      // ... vs
    ],
  },
];
```

### 5.3 Personel Ana Kabuk (Flutter)
```dart
// Backup'tan: _rotalar array'ine restore
static const _rotalar = [
  '/siparisler',      // ← restore (POS route)
  '/dashboard',
  '/menu',
  '/sadakat',         // ← restore (loyalty)
  '/kds',             // ← restore (kitchen)
  '/ayarlar',
];

// NavigationDestination'ları restore (Siparişler, Sadakat, Mutfak)
```

### 5.4 Mobile Router Route'u Restore
```dart
// imports'ta ekle:
import '../features/achievements/ui/achievements_page.dart';

// routes'da ekle:
GoRoute(
  path: '/achievements',
  builder: (context, state) => const AchievementsPage(),
),
```

### 5.5 Supabase RPC Kontrol
Restore sırasında RPC'ler kontrol edilmeli:
- `get_smart_feed_items_v1` — Smart feed için
- `get_group_requests_*` — Grup istekleri için
- `get_leaderboard_*` — Liderler sayfası için
- `get_owner_financial_report_v1` — Finansal sayfa için

**Hiçbir RPC silinmedi** — tümü mevcuttur. Sayfa restore edilince otomatik olarak çalışacaktır.

---

## 6. Geri Alınmayacak Kapsam Dışı Öğeler (Özet)

| Kategori | Öğeler | Gerekçe |
|---|---|---|
| **POS / Masa Siparişi** | Order routes, order pages, sipariş sayfaları | H2 release — MVP'de satış yok |
| **Gamification** | Achievements feature, daily tasks, badges | Sonradan gamification aktivasyonu kararlaştırıldı |
| **Loyalty Tier System** | Sadakat tiers, perks | Sadakat MVP'de yok — sonra eklenecek |
| **Sponsorluk / Ads** | 4 sponsor sayfası, sponsor nav links | Gelir modeli H2'ye ertelendi |
| **KDS (Kitchen)** | KDS personel tab'ı, mutfak UI | Order yok → KDS gerekli değil |
| **Masa Feedback** | Table feedback admin sayfası | Order flow'a bağlı |

---

## 7. Önemli Notlar & Uyarılar

### 7.1 Feature Flag'ler
Bazı sayfalar, restore sırasında feature flag'ler üzerinden kontrol edilebilir. Örneğin:
- `FEATURE_OWNER_MARKETING_ENABLED` → Marketing pages
- `FEATURE_AI_ANALYSIS_ENABLED` → AI Analysis pages

Bu flag'lerin `src/lib/feature-flags.ts` dosyasında tanımlanıp test edilmesi gerekir.

### 7.2 Database Doğruluğu
Restore edilen sayfalar, şu tablolara bağlıdır:
- `businesses_with_stats` — analytics
- `owner_financial_reports` — finansal
- `crm_interactions` — CRM
- `price_history` — fiyat raporu

Migrate işlemi yapılmadığından tablolar zaten mevcuttur, fakat veri doğruluğu kontrol edilmeli.

### 7.3 API Client Doğrulama
Web sayfalarının geri alınması, `src/lib/supabaseServer.ts` ve `src/lib/supabaseClient.ts` dosyalarının tam çalışması gerekir. Route handlers'ın RPC çağrıları test edilmeli.

### 7.4 Styling & Responsive
Backup'tan kopyalanan sayfa bileşenleri, mevcut **Tailwind v4** ve **design token** kurallarına uymalıdır. Restore sırasında inline style/color check yapılması tavsiye edilir.

### 7.5 i18n Keys
Restore edilen sayfaların i18n key'leri (`context.t()`) kontrol edilmeli. Eğer ARB dosyalarından çıkarılmışsa, yeniden eklenmesi gerekebilir.

---

## 8. Sonuç & Tavsiyeler

**Bulgu:** MVP temizliği, navigasyon yüzeylerini başarıyla minimalize etmiş; fakat temel özellik kodu ve veritabanı tam olarak korunmuştur. Restore işi, "kodu geri kopyalama" değil, "navigasyon linklerini geri açma" işlemidir.

**Restore İş Yükü:**
- Web routes restore: ~15-20 PR'da 20-30 saat
- Navigation shell fix: ~2 PR'da 1 saat
- Personel nav: ~1 PR'da 1 saat
- Mobile achievements: 1 PR'da 4-5 saat (stakeholder onayı gerekli)

**Toplam Tahmini:** 30-40 saat (parallelize edilebilir)

**Recommended Next Steps:**
1. Bu raporun ürün ve teknik liderler tarafından gözden geçirilmesi
2. Sınırda kalan sayfalar (finansal, CRM, AI) için "go/no-go" kararı alınması
3. PR-1 (public routes) ile başlanması
4. Her PR'da `npm run test:ci` geçiş doğrulanması
5. Personel ve mobil app'ler için `flutter analyze` + `flutter test` doğrulanması

---

**Rapor Hazırlama Tarihi:** 2026-06-24  
**Backup Kaynağı:** `D:\yeedoy-backups\pre-mvp-cleanup-20260623-0945\working-tree`  
**Analiz Yöntemi:** Git diff + file backup comparison (code execution yok)
