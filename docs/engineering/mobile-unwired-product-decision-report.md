# Yeedoy Mobil — Bağlı Olmayan Kod Ürün Karar Raporu

> **DEPRECATED / HISTORICAL CONTEXT:** Bu dosya tarihsel analizdir. Güncel scope kararı için bkz. `docs/product/2026-yeedoy-final-scope-source-of-truth.md`.

> **ÇELİŞKİ NOTU (2026-06-23):** Bu rapor "bağlı olmayan kod" merceğiyle yazıldı ve
> masa_siparisi (POS), sadakat ve heroes/leaderboard özelliklerini "KEEP" /
> "KEEP_AND_CONNECT" olarak işaretliyor. **Final Stratejik Karar Raporu
> (`docs/research/2026-yeedoy-stratejik-karar-raporu.md` §4, §23) bu özellikleri
> MVP-DIŞI (P2) sayar.** MVP scope-prune kapsamında bu yüzeyler
> navigasyon/UI'dan gizlenmiştir (kod ve DB korunmaktadır). Ayrıntı için bkz.
> `docs/engineering/2026-yeedoy-mvp-scope-prune-audit.md`. Bu rapordaki "KEEP"
> kararları MVP scope kararıyla çelişir; MVP scope kararı önceliklidir.

**Tarih:** 2026-06-19 (Güncelleme: 2026-06-22)  
**Hazırlayan:** Product Manager (Ürün Bakış)  
**Kapsam:** 12 tamamlanmamış/bağlı olmayan özellik + 5 teknik sorun  
**Yöntem:** İki mühendislik raporu (Unused Code + Backend Gap) + ürün değeri/teknik risk değerlendirmesi

## Güncelleme Notu (2026-06-22)

Bu raporun "Sonraki Aksiyon" listesi canlı DB ve kod karşı doğrulandı. Sonuç:

- **Hero leaderboard, profile settings, sponsorluk duplicate, grup_oy mimari refactor** — rapor yazıldıktan sonraki oturumlarda zaten tamamlanmış. Aşağıdaki bölümler bu durumu yansıtacak şekilde güncellendi.
- **food-journal + loyalty-cards route'ları** — KEEP_BUT_LATER kararından önce mühendislik tarafından zaten bağlanmış (`/food-journal`, `/loyalty-cards`, profile_page.dart linkleri). Geri alınmadı; karar KEEP_AND_CONNECT'e çevrildi (bkz. §2.4).
- **group_offer_votes tablosu** — migration repoda vardı (`20260620000009_group_offer_votes.sql`) ama canlı DB'ye uygulanmamıştı. Uygulandı (bkz. §2.5).
- **Yeni bulgu — sadakat sistemi split-brain idi:** mobil (müşteri) puan bazlı modeli kullanıyordu ve doğru çalışıyordu; personel (işletme sahibi) ise farklı bir damga/kart modeline yazıyordu ve canlı şemaya göre tamamen kırıktı (yanlış RPC parametreleri + var olmayan kolonlar). Personel tarafı puan modeline geçirildi (bkz. §4.1 güncel durum).

---

## 1. Genel Karar Özeti

**Yeedoy MVP çekirdeği:** Restoran keşfi → menü görüntüleme → yorum/puan → favoriler → işletme sahipliği başvurusu → profile → bildirimler.

**Sonuç toplamı:**
- **KEEP_AND_CONNECT (Hemen Bağla):** 3 özellik
- **FIX_BACKEND_FIRST (Backend Düzeltmeden Bağlanmayacak):** 2 özellik
- **MIGRATE_TO_OWNER_PANEL (Mobilde Olmayacak, Owner Panel'de):** 1 özellik
- **KEEP_BUT_LATER (MVP Sonrası Sonraki Sprinte):** 4 özellik
- **REMOVE_OR_ARCHIVE (Sil/Arşivle):** 1 özellik
- **MERGE_WITH_EXISTING (Duplicate Kodları Birleştir):** 1 özellik

| Karar Türü | Sayı | Açıklama |
|---|---|---|
| KEEP_AND_CONNECT | 3 | profile_settings (GoRouter), group_requests RPC fix, hero leaderboard isim fix |
| FIX_BACKEND_FIRST | 2 | sadakat (JSONB casting), collab_lists (UI direct DB) |
| MIGRATE_TO_OWNER_PANEL | 1 | sahiplen (mobil consumer kapsam dışı, owner panel kanon) |
| KEEP_BUT_LATER | 4 | masa_siparisi, yerlestir, yemek_gunlugu, embed (backend var ama ürün MVP'de değer yok) |
| REMOVE_OR_ARCHIVE | 1 | sponsorluk duplicate (monetization active) |
| MERGE_WITH_EXISTING | 1 | gourmets/feed_page (smart_feed ile duplicate mı?) |

---

## 2. Hemen Bağlanacaklar (KEEP_AND_CONNECT)

**MVP değeri:** Yüksek. Kodlama tamamlanmış, kullanıcıya sunulamıyor.

### 2.1 | profile/ui/profile_settings_page.dart
- **Durum (2026-06-22): TAMAMLANDI.** `/settings` GoRouter route'u eklendi (`router.dart`), `profile_page.dart` artık `context.push('/settings')` kullanıyor (3 nokta). Deep link destekleniyor.
- **Ürün Değeri:** Yüksek — kullanıcı profil ayarları (display name, bio, avatar). MVP critical.
- **Teknik Risk:** Düşük — ekran UI tamamlanmış, sadece route entegrasyonu.
- **Backend Durumu:** Hazır. `updateMyProfile()` provider çalışıyor.
- **Karar:** **KEEP_AND_CONNECT** ✅ Yapıldı

---

### 2.2 | group_requests/data (RPC isim fix)
- **Durum (2026-06-22): TAMAMLANDI.** `group_offer_votes` tablosu repoda migration olarak vardı (`supabase/migrations/20260620000009_group_offer_votes.sql`) ama canlı DB'ye hiç uygulanmamıştı — `group_requests_repository.dart:380`'deki `.from('group_offer_votes')` çağrısı gerçekte 404/tablo-yok hatası veriyordu. Migration `mcp__supabase__apply_migration` ile uygulandı, tablo artık mevcut.
- **Ürün Değeri:** Orta — grup teklifi özelliği (arkadaş grubu yemeğe davet).
- **Karar:** **KEEP_AND_CONNECT** ✅ Yapıldı

---

### 2.3 | heroes/data/hero_repository.dart (RPC isim düzeltme)
- **Durum (2026-06-22): Rapor hatalıydı / zaten düzeltilmişti.** Kodda `hero_repository.dart` zaten doğru RPC adını (`get_weekly_contributor_leaderboard_v1`) çağırıyor. Ek aksiyon gerekmiyor.
- **Karar:** **KEEP_AND_CONNECT** ✅ Zaten doğru

---

### 2.4 | sadakat (loyalty-cards) + yemek_gunlugu (food-journal) — route bağlantısı
- **Durum (2026-06-22): TAMAMLANDI, KARAR GÜNCELLENDİ.** Bu rapor §5'te bu iki özelliği KEEP_BUT_LATER olarak öneriyordu, ancak mühendislik bu karardan önce zaten `/loyalty-cards` ve `/food-journal` route'larını `router.dart`'a eklemiş ve `profile_page.dart`'tan link kurmuştu. Geri almak yerine mevcut bağlantı korundu; bu rapor KEEP_AND_CONNECT'e güncellendi. §4.1 ve §4.3'teki KEEP_BUT_LATER notları artık geçersizdir.
- **Karar:** **KEEP_AND_CONNECT** ✅ Yapıldı (route + nav bağlantısı mevcut)

---

## 3. Mobinde Olmayacaklar — Owner Panel'e Taşınanlar (MIGRATE_TO_OWNER_PANEL)

**Ürün Kararı:** Bu özellikler mobil consumer uygulamasının kapsamı dışına alındı. Kanon akış owner panel / web üzerinden yönetilecek.

### 3.1 | sahiplen/domain/sahiplen_saglayicisi.dart
- **Mevcut Durum:** Hiçbir yerden bağlı değil (route yok). Backend P0 hata: yanlış tablo (`business_ownership_claims` → gerçek: `owner_claims`) + yanlış kolon adları (`business_name_claimed` → gerçek: `full_name`).
- **Ürün Değeri:** Kritik (owner MVP için) — platform işletme sahipliği doğrulaması temelinde yapılıyor. Owner onboarding flow'u için essential.
- **Teknik Risk:** P0 — tablo/kolon hataları nedeniyle her INSERT başarısız. Mobil ekran bağlandığında crash oluşur.
- **Neden Mobilde Olmayacak:**
  - Owner onboarding akışı, owner panel / web üzerinden daha iyi yönetilir.
  - Mobil consumer kullanıcının işletme sahipliği başvurması edge case, ana akış değil.
  - İşletme onboarding'de KYC/doğrulama workflow'u panel üzerinde daha kontrollü biçimde yapılabilir.
- **Backend Durumu:** `submit_owner_claim_v1` RPC var ve doğru kolon adları (`full_name`, `phone`, `evidence_url`, `note`) belirtiliyor. Owner panel bu RPC'yi kullanacak.
- **Karar:** **MIGRATE_TO_OWNER_PANEL**
- **Sonraki Aksiyon:**
  1. Mobil: `lib/features/sahiplen/` klasörü arşiv/kaldırma adayı olarak işaretle. (Router'a bağlanmayacak.)
  2. Owner Panel: Sahiplenme sayfasının `submit_owner_claim_v1` RPC'yi doğru kullandığını doğrula.
  3. Owner Panel: `owner_claims` tablo schema'sı doğrulaması yapılsın (kolon adları, email validation, state machine).
  4. P0 Sahiplen Hatası: Mobil için artık geçerli değil; owner panel bakım listesine taşın.

---

## 4. Backend Düzeltmeden Bağlanmayacaklar (FIX_BACKEND_FIRST)

**MVP değeri:** Orta-Yüksek. Özellikler teçekkün ediyor ama backend bugs nedeniyle kırık. Backend fixed olmadan bağlamak kullanıcı deneyimini bozar.

### 4.1 | sadakat/domain/sadakat_saglayicisi.dart (mobil müşteri tarafı)
- **Durum (2026-06-22): Rapor hatalıydı.** Canlı DB'de `get_my_loyalty_cards_v1` fonksiyonunun `pg_get_functiondef` çıktısı doğrulandı: fonksiyon `jsonb_agg(...)` ile bir JSON **dizisi** döndürüyor (`coalesce(jsonb_agg(...), '[]'::jsonb)`), tek bir Map değil. Supabase-dart bunu JSON decode ettiğinde `List<dynamic>` olarak gelir — mobildeki `res as List` cast'i doğru çalışıyor, runtime crash yok. Dönen alan adları (`business_id`, `business_name`, `logo_url`, `points`, `lifetime_points`, `reward_threshold_pts`, `reward_type`, `reward_value`, `progress_pct`) `LoyaltyCard.fromMap`'teki alanlarla bire bir eşleşiyor.
- **Route:** `/loyalty-cards` zaten bağlı, bkz. §2.4.
- **Karar:** **KEEP_AND_CONNECT** ✅ Zaten çalışıyor — backend fix gerekmedi.

**Ayrı ve gerçek bir bulgu — personel (işletme sahibi) tarafı tamamen kırıktı:**
Bu rapor mobil müşteri tarafına odaklanmıştı, ama loyalty sisteminin owner/personel tarafı (`uygulamalar/personel/lib/features/sadakat/`) hiç incelenmemiş ve **canlı şemaya göre tamamen çalışmıyordu**:
- `add_loyalty_stamp_v1` RPC'sini `{p_card_id, p_business_id}` parametreleriyle çağırıyordu; canlı imza `(p_program_id uuid, p_user_id uuid)` — her çağrı PostgREST "function not found" hatası veriyordu.
- `award_loyalty_points_v1` RPC'sini var olmayan bir `p_source` parametresiyle çağırıyordu — bu çağrı da aynı şekilde başarısız oluyordu.
- `loyalty_cards` tablosundan `total_stamps`, `business_id` ve `loyalty_programs.required_stamps` kolonlarını okumaya çalışıyordu — hiçbiri canlı şemada yok (gerçek kolonlar: `stamp_count`, `program_id`, `stamps_needed`).
- Sonuç: personel tarafı, mobilin kullandığı puan tabanlı modelden (`loyalty_accounts`/`loyalty_programs.reward_threshold_pts`) tamamen bağımsız, hiç çalışmayan bir "damga kartı" modeline yazmaya çalışıyordu. İki sistem birbiriyle konuşmuyordu.

**Yapılan düzeltme (2026-06-22):**
1. Personel `sadakat_bildiricisi.dart` puan modeline geçirildi: müşteri listesi artık `get_business_loyal_customers_v1(p_business_id, p_limit)` ile okunuyor; puan ekleme zaten var olan `award_loyalty_points_v1(p_business_id, p_user_id, p_points)`'i doğru parametrelerle çağırıyor.
2. `get_business_loyal_customers_v1` jsonb çıktısına `reward_threshold_pts`/`reward_type`/`reward_value` eklendi (migration: `20260622000001_loyal_customers_reward_fields.sql`) — bu RPC'nin başka hiçbir tüketicisi yoktu, additive/geriye uyumlu değişiklik.
3. `sadakat_modeli.dart` + `sadakat_sayfasi.dart` damga/kart UI'ından puan-ilerleme UI'ına çevrildi (mobil ile aynı tier eşikleri: 500/1500/5000).
4. `flutter analyze` + `flutter test`: personel app'te 0 sorun, 64 test geçti.

**Bilinen açık nokta (kapsam dışı bırakıldı):** `loyalty_programs` tablosunda hiçbir işletme için aktif kayıt yok (canlı DB'de `count(*) filter (where is_active) = 0`). `award_loyalty_points_v1` bir işletmenin aktif programı olmadan sessizce no-op yapıyor (hata fırlatmıyor). Personel veya owner panelde `upsert_loyalty_program_v1` RPC'sini çağıran bir "sadakat programını etkinleştir" ekranı henüz yok — bu, ayrı bir ürün kararı/iş gerektiriyor.
- **Karar:** **KEEP_AND_CONNECT** ✅ Personel tarafı düzeltildi; program aktivasyon ekranı ayrı backlog kalemi.

---

### 4.2 | grup_oy/ui/oy_ver_sayfasi.dart + collab_lists
- **Durum (2026-06-22): TAMAMLANDI.** `oy_ver_sayfasi.dart` zaten `CollabListRepository` (`features/collab_lists/data/collab_list_repository.dart`) üzerinden `fetchGroupVoteData()` / `upsertVote()` çağırıyor — doğrudan Supabase erişimi yok, data/domain/ui katmanları korunuyor. Route `/group-vote/:token` olarak bağlı.
- **Karar:** **KEEP_AND_CONNECT** ✅ Zaten doğru mimaride

---

## 5. MVP Sonrası Bekleyecekler (KEEP_BUT_LATER)

**MVP değeri:** Orta-Düşük. Kodlama tamamlanmış ama ürün MVP'de zamanı gelmiş değil veya MVP dış çekirdek özellikler.

### 4.1 | masa_siparisi (3 ekran: MasaSiparisiSayfasi, SiparislerimSayfasi, SiparisBasariliSayfasi)
- **Mevcut Durum:** Hiçbir yerden bağlı değil. 3 ekran + domain notifier'lar tamamlanmış.
- **Ürün Değeri:** Orta — Türkiye'de masa/sipariş özelliği işletmeler için önemli. Ama Yeedoy'un stratejisi muğlak: delivery/POS/dine-in hangisi?
- **Teknik Risk:** Düşük — kod yazılmış ve işe yarar görünüyor.
- **Backend Durumu:** Tablo var (`orders`, `order_items`), ödeme entegrasyonu var mı? Doğrulanmalı.
- **Test:** Test yok.
- **Karar:** **KEEP_BUT_LATER** (Sprint N+2 veya N+3)
- **Gerekçe:**
  - Ürün kararı gerekli: Yeedoy'un masa siparişi stratejisi nedir? Dine-in mi, delivery mi?
  - Backend ödeme entegrasyonu doğrulanması gerekli.
  - MVP: keşif + menü. Sipariş: Phase 2 özelliği.
- **Sonraki Aksiyon:**
  1. Product: masa siparişi stratejisi (dine-in/delivery/both).
  2. Backend: ödeme entegrasyonu status.
  3. Roadmap: Sprint N+2'de bağlama planlat.
  4. Interim: kodu olduğu gibi tutsa (dosyalar tehlikeli değil).

---

### 4.2 | yerlestir/ui/yerlestir_sayfasi.dart (QR + embed araçları)
- **Mevcut Durum:** Hiçbir yerden bağlı değil. İşletme sahipleri için QR + embed kod oluşturma aracı.
- **Ürün Değeri:** Orta — işletme sahipleri menüyü kendi sitelerine embed etmek isteyecek. Phase 2 feature.
- **Teknik Risk:** Düşük — UI tamamlanmış.
- **Backend Durumu:** `embed_repository.dart` var ama hiçbir UI tarafından kullanılmıyor. `EmbedRepository.freshEmbedsProvider` tanımlı ama empty.
- **Test:** Test yok.
- **Karar:** **KEEP_BUT_LATER** (owner panel Phase 2)
- **Gerekçe:**
  - MVP: end-user menü görüntüleme. Owner tools: Phase 2.
  - Embed kodu üretmek ek backend işi gerektirebilir (örn. embed API host).
- **Sonraki Aksiyon:**
  1. Backend: embed API host ve security model (CORS, iframe policy).
  2. Roadmap: owner panel sprint'inde bağla.

---

### 4.3 | yemek_gunlugu/ui/yemek_gunlugu_sayfasi.dart
- **Mevcut Durum:** Hiçbir yerden bağlı değil. Kullanıcıların kişisel yeme-içme geçmişi/günlüğü.
- **Ürün Değeri:** Düşük-Orta — sosyal yemek günlüğü. Ürün stratejisi muğlak: kişisel mi, sosyal mi? (Gourmet/feed özellikleri bunu kısmen karşılıyor.)
- **Teknik Risk:** Düşük — UI tamamlanmış.
- **Backend Durumu:** Tablo var (`food_journals`), RPC var mı? Doğrulanmalı.
- **Test:** Test yok.
- **Karar:** **KEEP_BUT_LATER** (sosyal strateji netleştikten sonra)
- **Gerekçe:**
  - MVP'de gourmet feed + review sistemi kişisel kayıt yapıyor.
  - Yemek günlüğü: sosyal yeme günü kütüphanesi olup olmadığı açık değil.
- **Sonraki Aksiyon:**
  1. Product: yemek günlüğü vs gourmet feed farkı (feature consolidation mı?).
  2. Karar alınırsa: route ekle ve profil akışına bağla.

---

### 4.4 | embed/data/embed_repository.dart + link_paste_field
- **Mevcut Durum:** Hiçbir yerde kullanılmıyor. `EmbedRepository` + `freshEmbedsProvider` tanımlı ama test dışında import yok. `LinkPasteField` widget'ı hiç kullanılmıyor.
- **Ürün Değeri:** Düşük — utility widget'lar, backend infrastructure.
- **Teknik Risk:** Düşük — production'u etkilemiyor.
- **Backend Durumu:** Tablo var (`embeds`).
- **Test:** Test yok.
- **Karar:** **KEEP_BUT_LATER** (yerlestir özelliğiyle birlikte etkinleştir)
- **Gerekçe:**
  - Yerlestir feature'ı bu repository'yi kullanacak.
  - `LinkPasteField`: social media linkleri eklemek için kullanılabilir (sosyal hesaplar sayfası).
- **Sonraki Aksiyon:**
  1. Yerlestir/embed feature'ını bağladığında bu dosyalar otomatik aktif olacak.
  2. `LinkPasteField` socialAccountsPage'de kullanılıp kullanılmadığı kontrol et.

---

## 6. Silinecek/Arşivlenecekler (REMOVE_OR_ARCHIVE)

### 5.1 | sponsorluk/domain/sponsorlu_isletmeler_saglayicisi.dart
- **Mevcut Durum:** `monetization/domain/sponsored_businesses_provider.dart` ile kelimesi kelimesine duplicate. Sadece test'te referans alınıyor.
- **Ürün Değeri:** Sıfır — duplicate kod. Teknik borç.
- **Teknik Risk:** Düşük — sadece test dosyası referans alıyor; production'da kullanılmıyor.
- **Backend Durumu:** İlgili değil (provider'ın lokal state).
- **Karar:** **REMOVE_OR_ARCHIVE**
- **Gerekçe:**
  - `monetization/` versiyonu kanon ve aktif olarak kullanılıyor.
  - `sponsorluk/` klasörü deprecated kalıntısı olabilir.
  - Test de `monetization/` versiyonunu import etmeli.
- **Sonraki Aksiyon:**
  1. `lib/features/sponsorluk/domain/sponsorlu_isletmeler_saglayicisi.dart` sil.
  2. `test/features/sponsorluk/domain/sponsorlu_isletmeler_saglayicisi_test.dart` sil.
  3. Test'te `monetization/` provider'ını import etmiş olduğuna emin ol.
  4. PR: temizlik commit (1-2 dosya).

---

## 7. Birleştirilecek Duplicate Kodlar (MERGE_WITH_EXISTING)

### 6.1 | gourmets/ui/feed_page.dart vs smart_feed/ui/smart_feed_page.dart
- **Mevcut Durum:** `FeedPage` hiçbir yerden import edilmiyor; router'da `/feed` → `SmartFeedPage`. İki feed özelliğinin duplicate olma potansiyeli.
- **Ürün Değeri:** Muğlak — SmartFeedPage active, FeedPage legacy mi?
- **Teknik Risk:** Orta — duplicate code, maintenance burden. Hangisinin silinmesi gerekli?
- **Backend Durumu:** İlişkili değil.
- **Test:** Test yok (her ikisi için).
- **Karar:** **MERGE_WITH_EXISTING** (doğrulama sonrası)
- **Gerekçe:**
  - Eğer `FeedPage` SmartFeedPage'den önce yazılmış eski kalıntıysa: silinmeli.
  - Eğer farklı feed akışı ise (örn. gourmet-only vs smart-recommend mix): `SmartFeedPage`'den ayrı route'a taşınabilir.
- **Sonraki Aksiyon:**
  1. Git log: `feed_page.dart` ne zaman eklenmiş, son değişiklik ne?
  2. Eğer 6+ ay eski ise: sil.
  3. Eğer recent ise: product ile kararlaştır (duplicate route mi, yoksa separate feed akışı mı?).
  4. Karar: kaldırma veya `/gourmets-feed` route'a taşı.

---

## 8. Feature Karar Tablosu (Özet)

| # | Feature | Klasör | Mevcut Durum | Ürün Değeri | Teknik Risk | Backend Status | Bakım Maliyeti | Karar | Gerekçe | Sonraki Aksiyon |
|---|---|---|---|---|---|---|---|---|---|---|
| 1 | Profile Settings | profile | GoRouter dışı NavigatorPush | Yüksek (MVP) | Düşük | Hazır | Düşük | KEEP_AND_CONNECT | MVP kritik, sadece route eklemek lazım | Route ekle, PR: 30min |
| 2 | Hero Leaderboard | heroes | Bağlı ama RPC isim yanlış (get_weekly_leaderboard_v1) | Orta (gamification) | Yüksek (crash) | Var ama isim yanlış | Düşük | KEEP_AND_CONNECT | One-liner fix, sayfanın kırdığı | RPC ismi düzelt, test |
| 3 | Group Votes | group_requests | Bağlı, tablo doğru | Orta (edge case) | Düşük | Doğrulanmalı (arşiv migration) | Düşük | KEEP_AND_CONNECT | Production migration doğrula, sorun yok ise geç | Arşiv migration kontrol, bağlı zaten |
| 4 | Sahiplen (Owner Claim) | sahiplen | Bağlı değil, P0 hata (tablo/kolon) | Kritik (owner MVP) | Yüksek (P0) | RPC var (`submit_owner_claim_v1`), owner panel kullanacak | Orta | MIGRATE_TO_OWNER_PANEL | Mobil consumer kapsam dışı; owner panel kanon akış | Owner panel doğrulama; mobil arşiv/kaldırma |
| 5 | Sadakat Kartları | sadakat | Bağlı değil, P1 hata (JSONB casting) | Orta (partner network) | Yüksek (crash) | RPC var, format muğlak | Orta | FIX_BACKEND_FIRST | JSONB→List casting hata | Backend format doğrula, safe casting, test |
| 6 | Grup Oylama (Collab Lists) | grup_oy | Bağlı değil, mimari ihlal (UI→DB) | Orta (sosyal) | Yüksek (mimari + RLS) | Tablolar var, RPC var | Yüksek | FIX_BACKEND_FIRST | UI→DB direkt erişim, repository gerekli | Repository oluştur, refactor, test |
| 7 | Masa Siparişi | masa_siparisi | Bağlı değil, 3 ekran tamamlanmış | Orta (ürün stratejisi muğlak) | Düşük | Tablo var, ödeme? | Düşük | KEEP_BUT_LATER | MVP: keşif+menü. Sipariş Phase 2 | Strateji kararı, Sprint N+2 planla |
| 8 | Yerlestir (QR/Embed) | yerlestir | Bağlı değil, UI tamamlanmış | Orta (owner tools) | Düşük | Repository empty | Düşük | KEEP_BUT_LATER | Owner panel Phase 2 özelliği | Backend embed API, owner panel sprint'inde |
| 9 | Yemek Günlüğü | yemek_gunlugu | Bağlı değil, 3 dosya tamamlanmış | Düşük-Orta (ürün muğlak) | Düşük | Tablo var | Düşük | KEEP_BUT_LATER | Sosyal strateji netleştikten sonra | Product kararı, sosyal vs gourmet feed fark |
| 10 | Embed Repository + LinkPasteField | embed, core/ui | Hiç kullanılmıyor | Düşük-Orta (yerlestir'le bağlı) | Düşük | Tablo var | Düşük | KEEP_BUT_LATER | Yerlestir feature'ıyla aktif olacak | Yerlestir sprint'inde entegre et |
| 11 | Sponsorluk Provider (Duplicate) | sponsorluk | Sadece test'te referans, production yok | Sıfır (duplicate) | Düşük | İlişkili değil | Düşük | REMOVE_OR_ARCHIVE | Monetization/ versiyonu kanon | Sil (.dart + test) |
| 12 | Gourmets FeedPage | gourmets | Hiç import edilmiyor, SmartFeedPage ile örtüşüyor | Muğlak (eski kalıntı mı?) | Orta (duplicate) | İlişkili değil | Düşük | MERGE_WITH_EXISTING | Git log + product kararı | Git log kontrol, kaldır veya ayrı route |

---

## 9. Özellik Bazlı Detay

### A. PROFILE SETTINGS PAGE

**Yeedoy'da ne işe yarar:** Kullanıcı profili özelleştirme (display name, bio, avatar). MVP'de kritik.

**MVP gerekli mi:** Evet, high priority.

**Değer önerisi:** Kullanıcı kimliği + güvenilirlik.

**Backend hazır mı:** Evet. `updateMyProfile()` provider var.

**Test var mı:** Minimal (widget test).

**Route nereden açılmalı:** `/profile/settings` (GoRouter).

**Kaldırılırsa etkilenen dosyalar:** Profile akışı kırılır.

**Action:** Route ekle, 30 dakika.

---

### B. HERO LEADERBOARD (get_weekly_contributor_leaderboard_v1)

**Yeedoy'da ne işe yarar:** Haftalık top contributor'lar (işletme sahipleri, gourmet yazarları). Gamification + community building.

**MVP gerekli mi:** Hayır, nice-to-have ama kırık.

**Değer önerisi:** Engagement + community building. Türkiye'de işletme sahipleri kendi rank'lerini görmek istiyor.

**Backend hazır mı:** Evet, ama RPC ismi mobil'de yanlış. Backend: `get_weekly_contributor_leaderboard_v1`, Mobil: `get_weekly_leaderboard_v1`.

**Test var mı:** Hayır.

**Route nereden açılmalı:** Zaten `/heroes` route'a bağlı. Sadece RPC ismi düzelt.

**Kaldırılırsa etkilenen dosyalar:** Heroes sayfası crash vermeyecek ama boş döner.

**Action:** RPC ismi fix (line 33), test, 10 dakika.

---

### C. SAHIPLEN (OWNER CLAIM) — MOBILDE OLMAYACAK

**Yeedoy'da ne işe yarar:** İşletme sahipliği başvurusu. Platform içerik doğrulaması temelinde yapılıyor. Owner MVP için kritik.

**Neden mobilde olmayacak:**
- Owner onboarding akışı owner panel / web üzerinden daha iyi yönetilir.
- Mobil consumer kullanıcının işletme sahipliği başvurması edge case; ana onboarding flow'u değil.
- KYC/doğrulama workflow'u panel üzerinde daha kontrollü ve güvenli biçimde uygulanabilir.

**Backend durumu:** `submit_owner_claim_v1` RPC var ve doğru kolon adları belirtiliyor. Owner panel bu RPC'yi kullanacak.

**Mobil bileşenler:** `lib/features/sahiplen/` klasörü arşiv/kaldırma adayı.
- Dosyalar: `lib/features/sahiplen/ui/sahiplen_sayfasi.dart`, `lib/features/sahiplen/domain/sahiplen_saglayicisi.dart`
- Route eklenmiş değil, hiçbir yerden bağlı değil.

**Action (Owner Panel):**
1. Owner panel sahiplenme sayfası `submit_owner_claim_v1` RPC'yi kullanıyor mu doğrula.
2. `owner_claims` tablo schema doğrulaması (kolon adları: `full_name`, `phone`, `evidence_url`, `note`).
3. Owner panel'de sahiplenme akışı state machine'i doğrula (beklemede → onaylandı → reddedildi).

**Action (Mobil):**
1. `lib/features/sahiplen/` klasörü arşiv/kaldırma adayı olarak işaretle.
2. Router'a route ekleme — kapsam dışı.
3. Ileride gerekirse: business page'dan web sahiplenme linkine yönlendirme eklenebilir (ürün kararı bekliyor).

---

### D. SADAKAT KARTLARI (LOYALTY CARDS)

**Yeedoy'da ne işe yarar:** İşletme partner network'inin müşteri takibi. Ödül ve loyalty program. Orta priority.

**MVP gerekli mi:** Hayır, Phase 2.

**Değer önerisi:** İşletme partner network + müşteri retention.

**Backend hazır mı:** Kısmen. `get_my_loyalty_cards_v1` var ama JSONB döndürüyor, mobil `List` cast yapıyor. P1 casting error.

**Test var mı:** Hayır.

**Route nereden açılmalı:** `/loyalty-cards` — profil sayfasından erişim.

**Kaldırılırsa etkilenen dosyalar:** Partner network özelliği hiç çalışmaz.

**Action:**
1. Backend: RPC return type doğrula (JSONB vs TABLE).
2. Mobil: safe casting ekle, test yaz.
3. Route ekle, 2 gün.

---

### E. GRUP_OY (COLLAB_LISTS)

**Yeedoy'da ne işe yarar:** Grup oylama — arkadaş grubu restoran seçimi için ortak oylama. Sosyal feature.

**MVP gerekli mi:** Hayır, Phase 2.

**Değer önerisi:** Sosyal yeme-içme deneyimi.

**Backend hazır mı:** Tablolar var, RPC'ler var ama UI→DB direkt erişim yapılıyor (mimari ihlal). Statik type safety kaybı + RLS riskli.

**Test var mı:** Hayır.

**Route nereden açılmalı:** `/collab-lists/:id/vote` veya `/group-vote/:id`.

**Kaldırılırsa etkilenen dosyalar:** Grup oylama hiç çalışmaz.

**Action:**
1. Backend: RPC schema'ları doğrula.
2. Mobil: Repository pattern'e taşı.
3. UI refactor, test, 3-4 gün.

---

### F. MASA SIPARIŞI (ORDER MANAGEMENT)

**Yeedoy'da ne işe yarar:** Restoran masa/sipariş yönetimi. Dine-in veya delivery.

**MVP gerekli mi:** Hayır, Phase 2. Ürün stratejisi muğlak (hangi model?).

**Değer önerisi:** Dine-in/delivery sipariş için kritik.

**Backend hazır mı:** Kısmen. Tablo var (`orders`), ödeme entegrasyonu status bilinmiyor.

**Test var mı:** Hayır.

**Route nereden açılmalı:** `/b/:businessId/order` — menu page'dan.

**Kaldırılırsa etkilenen dosyalar:** Sipariş özelliği hiç çalışmaz.

**Action:** 
1. Product: masa sipariş stratejisi (dine-in/delivery/both)?
2. Backend: ödeme entegrasyonu status.
3. Roadmap: Sprint N+2'de bağla.

---

### G. YERLESTIR (QR/EMBED TOOLS)

**Yeedoy'da ne işe yarar:** İşletme sahipleri kendi sitelerine menü QR/embed kodu yerleştirebilir.

**MVP gerekli mi:** Hayır, Phase 2 (owner tools).

**Değer önerisi:** Owner empowerment — menü distribution.

**Backend hazır mı:** Repository var ama empty (`EmbedRepository`). Embed API host status bilinmiyor.

**Test var mı:** Hayır.

**Route nereden açılmalı:** `/b/:businessId/embed` — business owner control panel'den.

**Kaldırılırsa etkilenen dosyalar:** Embed özelliği hiç çalışmaz.

**Action:**
1. Backend: embed API host + security model.
2. Owner panel sprint'inde entegre et.

---

### H. YEMEK GÜNLÜĞÜ (FOOD JOURNAL)

**Yeedoy'da ne işe yarar:** Kişisel yeme-içme geçmişi. Sosyal yeme günü?

**MVP gerekli mi:** Hayır. Ürün stratejisi muğlak (gourmet feed vs food journal fark nedir?).

**Değer önerisi:** Sosyal yeme-içme tracking (Untappd tarzı).

**Backend hazır mı:** Tablo var (`food_journals`).

**Test var mı:** Hayır.

**Route nereden açılmalı:** `/food-journal` — profil sayfasından.

**Kaldırılırsa etkilenen dosyalar:** Kişisel yeme günlüğü özelliği hiç çalışmaz.

**Action:** Product: yemek günlüğü vs gourmet feed farkı netleşir, sonra bağla.

---

## 10. P0 Önerilen İlk İş Listesi (Bu Sprint)

### İş 1: Hero Leaderboard RPC Fix
- **Dosya:** `lib/features/heroes/data/hero_repository.dart` line 33
- **Değişiklik:** `get_weekly_leaderboard_v1` → `get_weekly_contributor_leaderboard_v1`
- **Risk:** Düşük (one-liner)
- **Test:** `hero_repository_test.dart` (RPC adı doğrulama)
- **Effort:** 0.5 gün
- **Impact:** Heroes sayfası crash vermeyecek

### İş 2: Profile Settings Route
- **Dosya:** `lib/app/router.dart` + `lib/features/profile/ui/profile_page.dart`
- **Değişiklik:** `/profile/settings` route ekle, `profile_page.dart`'da GoRouter çağrısına geç
- **Risk:** Düşük (UI ekran zaten hazır)
- **Test:** Deep link test (`/profile/settings?from=/profile`)
- **Effort:** 0.5 gün
- **Impact:** Profile settings deep-link support

### İş 3: Group Offers Tablo Doğrulaması
- **Dosya:** Production Supabase migration geçmişi
- **Değişiklik:** `group_offer_votes` tablo migration kontrolü
- **Risk:** Orta (production validation gerekli)
- **Test:** SQL query (`SELECT * FROM group_offer_votes LIMIT 1`)
- **Effort:** 0.25 gün
- **Impact:** Group requests özelliğinin production'da çalışıp çalışmadığı doğrula

### İş 4: Sponsorluk Duplicate Cleanup
- **Dosya:** `lib/features/sponsorluk/domain/sponsorlu_isletmeler_saglayicisi.dart` + test
- **Değişiklik:** Sil
- **Risk:** Düşük (sadece test referans alıyor)
- **Test:** Test'in `monetization/` provider'ını kullandığını doğrula
- **Effort:** 0.25 gün
- **Impact:** Teknik borç azalır

---

## 11. Kaldırma/Arşivleme Adayları

| Dosya | Risk | Neden | Önce Yapılacak | Durum |
|---|---|---|---|---|
| `lib/features/sponsorluk/domain/sponsorlu_isletmeler_saglayicisi.dart` | Düşük | Duplicate (monetization/ kanon) | Test import'u doğrula | P0: Sil |
| `test/features/sponsorluk/domain/sponsorlu_isletmeler_saglayicisi_test.dart` | Düşük | Duplicate test | Test içeriğini monetization testine migrate et | P0: Sil |
| `lib/features/Flexing-Black.ttf` | Düşük | Kodda kullanılmıyor | Font kullanımı grep ile doğrula | P3: Tasarım ekibiyle onay alıp sil |
| `lib/features/gourmets/ui/feed_page.dart` | Orta | Çift feed, SmartFeedPage ile örtüşüyor | Git log + product kararı | P1: Doğrula, kaldır veya route taşı |
| `lib/features/sahiplen/` klasörü (ui + domain) | Düşük | Mobil kapsam dışı, owner panel'e taşındı | Bağımlı import kontrolü sonrası | P2: Arşiv/kaldırma |

---

## 12. Bağlama Adayları (KEEP_AND_CONNECT)

| Özellik | Route | Giriş Noktası | Backend/RPC | Test | Sprint | Effort |
|---|---|---|---|---|---|---|
| Profile Settings | `/profile/settings` | profile_page.dart (bağlantı) | updateMyProfile() provider | deep-link + widget | Bu Sprint | 4 saat |
| Hero Leaderboard | Zaten `/heroes` | Zaten bağlı | get_weekly_contributor_leaderboard_v1 | RPC adı doğrulama | Bu Sprint | 1 saat |
| Group Requests | Zaten bağlı | group_requests_page.dart | group_offer_votes (tablo doğrula) | Production validation | Bu Sprint | 1 saat |

---

## 13. Sonuç: MVP Net Önerisi

### Şu An (Bu Sprint: 1-2 gün)
**KEEP_AND_CONNECT (3 Quick Win):**
1. Hero leaderboard RPC ismi fix (1 saat)
2. Profile settings route (4 saat)
3. Group offers production doğrulaması (1 saat)

**REMOVE_OR_ARCHIVE (Temizlik):**
4. Sponsorluk duplicate sil (30 dakika)

**Toplam:** ~6-7 saat, 1-2 gün sprint work.

---

### Sonraki Sprint (Sprint N+1: 2-3 gün)
**FIX_BACKEND_FIRST (Backend validation + repository refactor):**
1. Sadakat JSONB casting fix (1 gün)
2. Grup_oy: repository pattern refactor (1-2 gün)

**Toplam:** ~2-3 gün, backend block'a bağlı.

---

### MVP Sonrası (Sprint N+2 ve sonrası)
**KEEP_BUT_LATER (Product Karar Bekleme):**
1. Masa siparişi (strateji kararı, ödeme entegrasyonu)
2. Yerlestir (owner panel phase 2)
3. Yemek günlüğü (sosyal strateji netleşme)
4. Embed infrastructure (yerlestir'le entegre)

**Timeline:** Q3-Q4 2026 (roadmap'e taşı).

---

### Teknik Borç Özet
| Kategori | Sayı | Effort | Priority |
|---|---|---|---|
| Quick Wins (1 gün altı) | 4 | 6-7 saat | P0 (bu sprint) |
| Backend Validation Gerekli | 2 | 2-3 gün | P0 (sonraki sprint) |
| Owner Panel Doğrulama | 1 (sahiplen) | 1 gün | P0 (owner sprint) |
| Product Karar Bekleyen | 4 | 5-8 gün | P2 (Q3-Q4) |
| Temizlik (Duplicate) | 2 | 1 saat | P3 (bu sprint) |
| **TOPLAM** | **13** | **14-21 gün** | **Dağıtılmış** |

---

### MVP Ürün Tavsiyesi

**Özet:** Yeedoy mobil MVP temelinde bağlı olan özellikler (auth, discovery, menus, reviews, favorites, profile) güçlü. Bağlı olmayan 12 özellik çoğunlukla Phase 2 + Phase 3 roadmap'ine ait.

**Şu an (6-7 saat, 1-2 gün iş):**
- Profile settings GoRouter'a taşı
- Hero leaderboard RPC ismi fix
- Sponsorluk duplicate sil
- Production validation (group offers)

**Sonraki sprint (2-3 gün, backend block'a bağlı):**
- Sadakat casting fix
- Grup_oy repository refactor

**Owner panel sprint:**
- Sahiplen sayfası doğrulaması (RPC kullanımı, schema uyumu)

**Roadmap (Q3-Q4):**
- Masa siparişi (product strateji sonrası)
- Owner tools (yerlestir, embed)
- Sosyal özellikler (yemek günlüğü)

**MVP kriterleri:** ✅ Discovery + Menus + Reviews + Profile — **bağlı ve çalışıyor**  
**Owner MVP:** ⚠️ Sahiplen (owner panel üzerinden yönetilecek, mobilde olmayacak)

---

## 14. Ürün Kararı Güncellemesi — Mobilde Sahiplenme Yok (2026-06-19)

**Karar:** İşletme sahiplenme akışı mobil consumer uygulamasının kapsamı dışına alındı.

**Gerekçe:**
- Owner onboarding akışı owner panel / web üzerinden daha iyi yönetilir.
- Mobil kullanıcının (consumer) işletme sahipliği başvurması edge case; ana akış değil.
- KYC/doğrulama workflow'u panel üzerinde daha kontrollü, güvenli ve ölçeklenebilir biçimde uygulanabilir.

**Etkilenen bileşenler:**
- `lib/features/sahiplen/` → arşiv/kaldırma adayı (bağımlı import kontrolü sonrası)
- `submit_owner_claim_v1` RPC → korunacak, owner panel kullanacak
- `owner_claims` tablo/schema → owner panel doğrulaması bekliyor

**Owner panel için açık görevler:**
- Owner panel sahiplenme sayfasının `submit_owner_claim_v1` RPC'yi kullandığı doğrulanmalı
- `owner_claims` kolonları (`full_name`, `phone`, `evidence_url`, `note`) panel UI ile uyumlu mu kontrol edilmeli
- Sahiplenme state machine'i (beklemede → onaylandı → reddedildi) owner panel'de uygulanmalı

**Mobil için kapanış:**
- `SahiplenSayfasi` route'a bağlanmayacak
- `sahiplen_saglayicisi.dart` provider aktif kullanımda değil
- Gerekirse ileride: "Bu işletmenin sahibi misiniz? → [Owner Panel Web Linki]" şeklinde pasif yönlendirme eklenebilir (ürün kararı bekliyor)

---

**Rapor Durumu:** Ürün yönetim bakış açısından tamamlandı. Backend team, mobile team ve owner panel team bu raporu sprint planlamasında kullanabilir.
