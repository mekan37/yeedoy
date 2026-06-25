# YEEDOY — Kalan Kapsam Riski Mini-Audit (2026-06-24)

**Görev tipi:** Salt-okuma denetim raporu (2026-06-24, STALE — Updated 2026-06-25 post-cleanup).
**Referans karar kaynağı:** `docs/product/2026-yeedoy-final-scope-source-of-truth.md`
**Not:** Bu rapor 2026-06-24 tarihinde yazılmıştır. Forbidden-scope temizlik (commit b5c68cc vb.) sonrası, çoğu bulgu artık tarihsel. Güncel durum `2026-yeedoy-final-forbidden-scope-sweep.md` (2026-06-25) ile doğrulanmalıdır.

---

## 1. Özet — UPDATED 2026-06-25

Bu mini-audit, 2026-06-24'te working tree'de duran adaylara odaklanmıştır. **Forbidden-scope temizlik sonrası (commit b5c68cc, 6523c12), çoğu bulgu artık KAPANMIŞTIR.**

Özgün bulgu özeti (2026-06-24):
| Kategori dağılımı | Adet | Güncel durum |
|---|---|---|
| `REDIRECT_NOW` | 2 | ✅ CLOSED (commit b5c68cc) |
| `REMOVE_SAFE` | 2 | ✅ CLOSED (mobile gamification gated/flag-removed) |
| `DO_NOT_TOUCH_DB` | 1 | ✅ DB intentionally preserved |
| `NEEDS_HUMAN_DECISION` | 1 | 🟡 price_alerts: tarihsel karar beklemiyor (şu anki durum belirsiz) |

**En kritik tespit (2026-06-24):** Admin askıya-alma sayfaları canlıydı. **Güncel durum (2026-06-25):** ✅ CLOSED (commit b5c68cc).

---

## 2. `/yonetici/askiya-alinanlar` Özel Bölümü — UPDATED 2026-06-25 (CLOSED)

### Dosyalar (Güncel durum)
- `uygulamalar/web/app/yonetici/askiya-alinanlar/page.tsx` — ✅ REDIRECT (commit b5c68cc)
- `uygulamalar/web/app/admin/suspended/page.tsx` — ✅ REDIRECT (commit b5c68cc)
- Nav linki `admin-shell-client.tsx:19` — ✅ REMOVED (commit b5c68cc)

### (a) Admin moderasyonu için gerekli mi?
**HAYIR.** Bu sayfa moderasyon yapmıyor. Salt-okuma bir liste:
`suspended_meals` (askıya alınan yemek bağışları) + `suspended_meal_claims` (talepler)
tablolarından miktar/işletme/durum/tarih gösteriyor. Hiçbir onay/red/silme/şikayet
aksiyonu yok. Final scope'taki "Veri Kalitesi & Moderasyon" tanımına (işletme bilgisi,
yorum, fotoğraf moderasyonu) girmiyor — bir bağış/sadakat programının read-only raporu.

### (b) Owner suspended'dan farklı mı? Nasıl?
**Aynı ÖZELLİK ailesi (suspended_meals), farklı PERSPEKTIF.**
- Owner sayfası (`/owner/suspended`, `/sahip/askiya-alinanlar`): owner'ın KENDİ
  işletmelerine bırakılan askı yemeklerini gösteriyordu. **Zaten redirect'e çevrildi**
  (`redirect('/owner/dashboard')` / `redirect('/sahip/gosterge-panosu')`).
- Admin sayfası (`/admin/suspended`, `/yonetici/askiya-alinanlar`): TÜM işletmelerin
  askı yemeklerinin platform-geneli görünümü + bekleyen talep/süresi-dolmuş metrikleri.
- Teknik olarak ikisi de aynı `suspended_meals` / `suspended_meal_claims` tablolarını
  okuyor. Admin versiyonu owner versiyonunun "tümünü gör" hali; yeni/bağımsız bir
  yetenek değil.

### (c) MVP/P1 kapsamında kalmalı mı? — ANSWERED
**HAYIR.** `suspended_meals` = askıya alınan yemek = sadakat/bağış programı.
Final scope: *"Sadakat/Loyalty Sistemi — müşteri sadakat puanları, çekinler, ödüller
MVP'de değildir"* → açıkça KAPSAM DIŞI.

### (d) Redirect Durumu — COMPLETED
✅ **YER ALMIŞTIR.** Commit b5c68cc'de:
1. Her iki dosya (`admin/suspended/page.tsx` ve `yonetici/askiya-alinanlar/page.tsx`)
   `redirect('/admin/dashboard')` (EN) ve `redirect('/yonetici/gosterge-panosu')` (TR) haline getirildi.
2. `admin-shell-client.tsx:19` "Askıya Alma" nav linki kaldırıldı.
3. Owner suspended ile aynı temizlik commit'inde kapatıldı.

---

## 3. Diğer Bulgular Tablosu

| Dosya yolu | Kategori | Açıklama (2026-06-24) | Güncel durum (2026-06-25) |
|---|---|---|---|
| `uygulamalar/mobil/lib/features/profile/ui/achievements_page.dart` | achievement | Tam gamification ekranı. Router'da bağlı değil — untracked dirty dosya. | ✅ Router'da hala bağlı değil. Gamification gated/removed; optional cleanup. |
| `uygulamalar/mobil/lib/features/profile/ui/profile_page.dart` | achievement | "İçerik Üretici Rozeti" + XP/seviye ilerleme çubuğu canlı gösteriliyor. | ✅ CLOSED — profile gamification UI kaldırıldı (mobil gamification removal commit'leri). |
| `uygulamalar/mobil/lib/features/profile/ui/components/achievements_grid.dart` + destek katmanı | achievement | achievements_page'e bağlı destek katmanı. | ✅ DEAD (sayfa + gamification kapatıldı) |
| `uygulamalar/mobil/lib/features/price_alerts/ui/price_alerts_page.dart` | price-alert | Fiyat uyarısı + promo banner. Router'da bağlı. | ⚠️ Ürün kararı bekleniyor (P1 mi, kapsam dışı mı) |
| `uygulamalar/web/app/(auth)/price-alerts/page.tsx` | price-alert | Web fiyat alarmı listesi. | ⚠️ Ürün kararı bekleniyor |
| `uygulamalar/mobil/lib/features/business/data/check_in_repository.dart` | checkin | Check-in logic. Mevcut karar bekleniyor (verified-visit vs. gamification). | 🟡 Tarihsel karar bekleniyor (feature-flagged false) |

### check-in / loyalty / achievement tarama notları
- **loyalty/sadakat:** Web'de `app/(auth)/loyalty`, `app/(kimlik)/sadakat`,
  `app/owner/marketing/loyalty`, `app/sahip/pazarlama/sadakat`, mobilde
  `features/sadakat/*`, web `src/lib/veri/owner/sadakat.ts` + route'lar canlı.
  Bunlar bu görevin "özellikle kontrol edilecekler" listesinde değildi ama
  **loyalty yüzeyleri hâlâ çok yerde mevcut** — ayrı bir loyalty-kapatma denetimi gerekli
  (bkz. `2026-yeedoy-loyalty-mvp-defer-decision.md`).
- **achievement/rozet/XP:** Yukarıdaki profil + achievements bulguları dışında, mobil
  l10n'de `profileMyAchievementsTitle`, `achievementStatus*` anahtarları duruyor (ölü kopya).
- **check-in:** `feature_flags.dart`, `business_checkins_provider`, migration
  `20260507000002_check_in.sql` + `20260421000007_friend_checkin_notification.sql` mevcut.
- **price alert:** mobil feature seti router'da bağlı (canlı), web (auth) sayfası canlı.

---

## 4. DO_NOT_TOUCH_DB Detayları

Bu görevde migration OLUŞTURULMADI ve mevcut migration'lara DOKUNULMADI.
Aşağıdakiler DB seviyesinde olduğundan ayrı, kontrollü bir DB-cleanup süreci gerektirir
(bkz. `docs/engineering/2026-yeedoy-db-scope-cleanup-risk-report.md`).

| Migration / obje | İçerik | Neden DO_NOT_TOUCH_DB |
|---|---|---|
| `supabase/migrations/20260622000001_loyal_customers_reward_fields.sql` (untracked, dirty) | `get_business_loyal_customers_v1` RPC'sini same-signature gövde değişikliğiyle güncelliyor: `loyalty_accounts` + `loyalty_programs` tablolarından `reward_threshold_pts`, `reward_type`, `reward_value` döndürüyor. **Saf loyalty/sadakat kapsamı.** Yorumda "no consumers existed yet (grep confirmed)" diyor — yani client bağlı değil. | Sadakat (KAPSAM DIŞI) ama DB objesi. Silmek/geri almak migration gerektirir; çalışan ortamda RPC drop riski. İnsan onaylı DB-cleanup'a bırakılmalı. |
| `suspended_meals`, `suspended_meal_claims` tabloları | Admin askıya-alma sayfalarının okuduğu tablolar. Kaynak: `00000000000000_base_schema.sql` / `20260416072511_remote_schema.sql` + arşiv `_archive/20260326000002_meal_card_support.sql`. | Sadakat/bağış kapsamı; tablo drop'u migration ve veri kaybı riski taşır. UI redirect'i (Bölüm 2) yeterli; tablo temizliği ayrı süreç. |
| `loyalty_accounts`, `loyalty_programs` + `20260424000007_loyalty_program.sql`, `20260507000008_sadakat_karti.sql`, `20260522000001_loyalty_auto_points_on_order.sql`, `20260424000010_loyalty_automations.sql` | Loyalty sistem tabloları/RPC'leri/otomasyonları. | KAPSAM DIŞI ama DB. Toplu loyalty DB-cleanup kararına bağlı. |
| `20260507000002_check_in.sql`, `20260421000007_friend_checkin_notification.sql` | Check-in tabloları/tetikleyicileri. | Check-in kararına (verified-visit) tabi DB objeleri. |

---

## 5. NEEDS_HUMAN_DECISION Detayları

### 5.1 Fiyat Uyarıları (price_alerts) — mobil + web
**Karar gereken soru:** Fiyat uyarısı MVP/P1'de kalacak mı?

- Final scope, fiyat uyarısını ne KAPSAMDA ne KAPSAM DIŞI olarak açıkça listelemiyor.
  Görev brief'i "fiyat uyarısı sadece P1 olarak değerlendirilebilir — gamification veya
  reklam DEĞİLSE" diyor.
- `price_alerts_page.dart`: **gerçek fiyat uyarısı** (hedef fiyat, tetiklenen alarm,
  yüzde düşüş). Gamification/XP/rozet YOK. Reklam YOK.
- Tek pürüz: pazarlama tonlu UI parçaları — "Merhaba! 👋", "Fiyat düşünce haberin olsun!"
  promo banner, alt tip banner. Bunlar reklam değil, kendi özelliğinin tanıtım metni.
- Web (`(auth)/price-alerts`) sade ve temiz.

**Öneri (insan kararı):** Özelliği P1 olarak TUT; tutulursa promo/tip banner'ları
sadeleştir (gereksiz "Merhaba 👋" gibi). DROP kararı verilirse mobil router (`router.dart:267`)
ve web (auth) sayfası + nav (`uygulama-cekmecesi.tsx:34` "Fiyat Uyarıları") redirect/kaldır.

### 5.2 Profil Gamification UI'ı — sınır kararı
`profile_page.dart` içindeki "İçerik Üretici Rozeti" + XP/seviye ilerleme bölümü
teknik olarak gamification (KAPSAM DIŞI). Ancak "İçerik Üretici" bir moderasyon/güven
sinyali olarak da yorumlanabilir. **İnsan kararı:** Rozet/XP/seviye dilini kaldırıp
saf "güven/katkı seviyesi" göstergesine indirgemek mi, yoksa tüm bloğu gizlemek mi?
Raporda `REDIRECT_NOW` etiketlendi ama uygulanış biçimi ürün kararına bağlı.

---

## 6. Doğrulama Notları — UPDATED 2026-06-25

**Rapor yazıldığında (2026-06-24):** Hiçbir kaynak dosya değiştirilmedi (salt-okuma).

**Sonrası (2026-06-25):** Forbidden-scope temizlik commit'leri uygulandı:
- ✅ `askıya-alma` sayfaları redirect'e çevrildi (b5c68cc)
- ✅ Admin nav linki kaldırıldı
- ✅ Mobile gamification UI kaldırıldı (chore: remove remaining mobile gamification UI)
- ✅ Web feed/heroes/leaderboard redirects (6523c12)

**Ön koşul raporların durumu:** Bu rapor tarihsel bağlam sağlar; güncel durum `2026-yeedoy-final-forbidden-scope-sweep.md` (2026-06-25) ile doğrulanmalıdır.
