# YEEDOY Web Panel — Kapsamı Belirsiz 5 Sayfanın Karar Raporu

**Tarih:** 2026-06-24
**Başlangıç:** Health-check raporundaki D3 bulgusu (5 sayfanın MVP scope'unda belirsiz olması)
**Kaynak kararları:** `docs/product/2026-yeedoy-final-scope-source-of-truth.md`

---

## 1. Owner Paneli "Grup İstekleri" (/owner/requests)

**Etiket:** `REDIRECT_NOW`

**Gerçek işlevi:**
Sayfanız owner'ın şehirlerine gelen grup/organizasyon yemek isteklerini (group_requests tablosu) gösteriyor. 127 satır, tam işlevsellik:
- Dinamik Supabase sorgularıyla şehire göre filtreleme
- İstek büyüklüğü (kişi sayısı), bütçe, tarih, kategori eşleşme gösteriliyor
- Durum filtresi (Açık/Kapalı/Tamamlandı/İptal)

**Final scope analizi:**
Final scope'ta (2026-yeedoy-final-scope-source-of-truth.md) `group_requests` tablosu veya "grup istekleri" özelliği **açıkça yer almıyor.** KAPSAMDA sayılanlar:
- Keşif, Arama, Filtre, Favoriler
- İşletme Profili & Menü & Fiyat Yönetimi
- Yorum & Kanıt & Doğrulanmış Bilgi
- QR Menü & Analytics
- **Claim/Sahiplenme & Veri Kalitesi/Moderasyon** (grup istekleri bunlara dahil DEĞİL)

**Gerekçe:**
Grup yemek istekleri bir **sosyal/platform-ekonomisi** özelliğidir ve MVP kapsamına dahil edilmemiştir. Hem owner hem admin'e açık (admin/group-requests sayfası mevcut), henüz kullanıcı talebi yoktur. Health-check'te zaten "scope-belirsiz canlı sayfa" olarak işaretlenmiş durumda.

**Önerilen aksiyon:**
1. Nav linkini kaldır (owner-shell-client.tsx satır 31)
2. /owner/requests route'unu `/owner/*` redirect-stub pattern'ine indir
3. `admin/group-requests` sayfasını da parallel olarak kontrol et (aşağıya bakınız)

**Bağlantı:** Final scope'ta `KAPSAM DIŞI` → Kullanıcı Katılımı / Gamification (sosyal özellikler kategorisinde)

---

## 2. Owner Paneli "Askıya Alma" (/owner/suspended)

**Etiket:** `REDIRECT_NOW`

**Gerçek işlevi:**
Owner'ın işletmelerine bırakılan "suspended_meals" (askıya alınan yemek bağışları) ve talepleri (suspended_meal_claims) gösteriyor. 151 satır, tam işlevsellik:
- Bağış miktarı, işletme, durum (Aktif/Süresi Doldu)
- İlgili talepleri ve talep sahibi gösteriliyor
- created_at ve expires_at tarihlerini izliyor

**Final scope analizi:**
Final scope'ta "sadakat/loyalty" **açıkça KAPSAM DIŞI** olarak listelenmiş:
> "Sadakat/Loyalty Sistemi — müşteri sadakat puanları, çekinler, ödüller MVP'de değildir"

`suspended_meals` tablosu bu "loyalty" kategorisine giriyor (bir tür sanal veya fiziki hediye/çek sistemi). Aynı migration'larda "achievement.reset" ve "suspended_meal_claims" loyalty/gamification aksiyon kodları yer alıyor.

**Gerekçe:**
Askıya alma (suspended meals) sistem bir **sadakat/bağış programı** özelliğidir ve final scope'ta açıkça KAPSAM DIŞI işaretlenmiştir. MVP'de bu özellik kullanılmamaktadır.

**Önerilen aksiyon:**
1. Nav linkini kaldır (owner-shell-client.tsx satır 32)
2. /owner/suspended route'unu redirect-stub pattern'ine indir
3. Admin'in suspended sekmesi var mı kontrol et (ek cleanup)

**Bağlantı:** Final scope'ta `KAPSAM DIŞI` → Sadakat/Loyalty Sistemi (açıkça belirtilmiş)

---

## 3. Owner Paneli "AI Analizi" (/owner/ai-analysis)

**Etiket:** `NEEDS_HUMAN_DECISION`

**Gerçek işlevi:**
**Sayfa dosyası yok.** Nav'da link'i var (owner-shell-client.tsx satır 34: `/owner/ai-analysis`) ama `uygulamalar/web/app/owner/ai-analysis/page.tsx` mevcut değil. Tıklanırsa Next.js 404 döndürür.

**Final scope analizi:**
Final scope'ta "yapay zeka analizi" herhangi bir yerde zikredilmiyor. Benzer analytics sayfaları var:
- "QR Analytics" (kapsamda) → owner QR scan stats
- "İşletme İstatistikleri" (kapsamda) → yorum sayısı, puan ortalaması

"AI Analizi" muhtemelen ileri düzey **iş zekası/tavsiye motoru** özelliğidir (owner'a AI-driven insight'lar, tavsiyeler vermek gibi).

**Gerekçe:**
Sayfa uygulanmamış ve final scope'ta açıkça tanımlanmamış. Muhtemelen **ertelenmiş özellik** veya **ürün geçmişinde kaldı**. Her iki durumda da:
- Ürün sahibinin net "keep/drop" kararı gerekiyor
- Eğer kaldırılacaksa nav'dan link'i silmek yeterli
- Eğer tutulacaksa (gelecek sprint) dev'in sayfayı implement etmesi gerekiyor

**Önerilen aksiyon:**
Ürün sahibine soru:
- "AI Analizi" özelliği MVP kapsamında kalacak mı? (Yanında: analiz miktarı, geliştirme süresi)
- Değilse nav linkini kaldır (satır 34) ve deprecation kararı kapat

**Bağlantı:** Final scope'ta karşılığı yok → İçerik tanımı yapılması gerekiyor

---

## 4. Admin Paneli "Olay Merkezi" (/admin/incidents)

**Etiket:** `KEEP_P0`

**Gerçek işlevi:**
Admin audit timeline'ını (list_audit_timeline_v2 RPC) gösteriyor. 271 satır, tam işlevsellik:
- Admin aksiyonlarını loglıyor (impersonation, ban, shadow ban, feature flag, data export vb.)
- Severity filtresi (Düşük/Orta/Yüksek/Kritik)
- Arama (aksiyon adı, hedef tipi)
- Sayfalama

**Final scope analizi:**
Final scope'ta **"Veri Kalitesi & Moderasyon"** başlığı altında:
> "Veri Kalitesi & Moderasyon — admin panelinden işletme bilgileri, yorum, fotoğraf moderasyonu"

ve

> "Admin Web Paneli — admin kullanıcı sistem moderasyonu, veri kalitesi, raporlama"

`incidents` sayfası bu kapsamın bir parçası: **sistem moderasyonu ve veri kalitesi denetimi** için admin aksiyonları izlemek kritik özellik.

**Gerekçe:**
MVP'de admin paneli kapsamında ve "sistem moderasyonu" kategorisine giriyor. Yorum/fotoğraf/işletme moderasyonunun audit trail'ini tutmak ve görüntülemek **güvenlik ve uyum** açısından esastır.

**Önerilen aksiyon:**
Sayfayı **koruyun.** Nav linkini tutun. Bu sayfanın E2E veya smoke testleri varsa güçlendirin.

**Bağlantı:** Final scope'ta `KAPSAMDA` → Admin Web Paneli / Veri Kalitesi & Moderasyon

---

## 5. Admin Paneli "Grup İstekleri" (/admin/group-requests)

**Etiket:** `REDIRECT_NOW`

**Gerçek işlevi:**
Admin'in tüm group_requests tablosunu görmesi. 145 satır, tam işlevsellik:
- İstek kategori/şehir/tarih/kişi/bütçe/durum/oluşturan
- Status filtresi (Açık/Kapalı/Tamamlandı/İptal/Tümü)
- Sayfalama

**Final scope analizi:**
#1 sayfanın (owner/requests) aynı mantığıyla: "Grup İstekleri" final scope'ta yer almıyor. Admin'in bunu görebilmesi ürün politikası değil, sadece owner'ın görebilmesinin admin versiyonu. İkisi de sosyal/platform-ekonomisi özelliğidir.

**Gerekçe:**
Sistem moderasyonu ve veri kalitesi kapsamında grup istekleri **matching/approval** fonksiyonu yoktur. Admin sadece **read-only** olarak tüm istekleri görüyor. Bu MVP'de gerekli değildir.

**Önerilen aksiyon:**
1. Nav linkini kaldır (admin-shell-client.tsx satır 36)
2. /admin/group-requests route'unu redirect-stub pattern'ine indir
3. Owner/requests sayfasıyla aynı commit'te kapayın

**Bağlantı:** Final scope'ta `KAPSAM DIŞI` → Kullanıcı Katılımı / Sosyal Özellikler

---

## Karar Özeti Tablosu

| Sayfa | Etiket | 1 Satır Gerekçe | Final Scope Kategorisi |
|---|---|---|---|
| `/owner/requests` | REDIRECT_NOW | Grup istekleri sosyal/platform-ekonomisi; MVP'de tanımlanmamış | KAPSAM DIŞI: Sosyal Özellikler |
| `/owner/suspended` | REDIRECT_NOW | Askıya alınan yemekler sadakat/loyalty sistemi; final scope KAPSAM DIŞI | KAPSAM DIŞI: Sadakat/Loyalty |
| `/owner/ai-analysis` | NEEDS_HUMAN_DECISION | Sayfa uygulanmamış; final scope'ta tanımlanmamış; ürün kararı gerekiyor | Tanımlanmamış |
| `/admin/incidents` | KEEP_P0 | Admin audit trail'i sistem moderasyonu; final scope'ta "Veri Kalitesi & Moderasyon" kapsamında | KAPSAMDA: Admin Paneli / Moderasyon |
| `/admin/group-requests` | REDIRECT_NOW | Group requests tablosu sosyal özellik; admin read-only view; MVP'de gerekli değil | KAPSAM DIŞI: Sosyal Özellikler |

---

## Yönetim Kararları

### Hemen Yap (REDIRECT_NOW)
1. `owner/requests` → nav linkini kaldır, route'u redirect-stub'a indir
2. `owner/suspended` → nav linkini kaldır, route'u redirect-stub'a indir
3. `admin/group-requests` → nav linkini kaldır, route'u redirect-stub'a indir
4. İlgili dosyalar:
   - `uygulamalar/web/src/ui/shell/owner-shell-client.tsx` (satırlar 31, 32, 34)
   - `uygulamalar/web/src/ui/shell/admin-shell-client.tsx` (satır 36)

### Ürün Kararı Bekliyor (NEEDS_HUMAN_DECISION)
- `/owner/ai-analysis` — yönetim tarafından karar verilmeli (keep/drop ve eğer keep ise sprint takvimi)

### Koruyun (KEEP_P0)
- `/admin/incidents` — audit trail sayfası moderasyon açısından kritik; sayfayı ve nav linkini tutun

---

## Ek Not

Health-check raporundaki ek bulgu: owner panel `ai-analysis` sayfası hâlâ nav'da linkli ama **dosya yok**. Kullanıcı tıklarsa 404 görür. Nav'dan çıkarıncaya dek ürün sahibinin karar vermesi bekleniyor; teknik olarak kırık değil (sayfayı ziyaret etmezse sorun olmaz), ama UX açısından kafa karıştırıcı.

**Final scope'ta mutlaka tanımlanmalıdır:** Eğer 5 sayfanın tamamı REDIRECT_NOW olursa, `docs/product/2026-yeedoy-final-scope-source-of-truth.md` bu kararı yansıtsın.
