# YEEDOY MVP Sağlık Kontrolü — Kapsamda KALAN Özellikler (Ters Audit)

> **Tarih:** 2026-06-24
> **Tür:** SALT OKUMA / RAPOR. Hiçbir kod/dosya değiştirilmedi, commit yapılmadı.
> **Kapsam kaynağı:** `docs/urun/2026-yeedoy-final-scope-source-of-truth.md`.
> **Önceki audit (temizlik kapsamı):** `docs/muhendislik/2026-yeedoy-nonproduct-leftovers-audit.md`.
> **Yöntem:** Statik analiz (Grep/Glob/dosya okuma + git geçmişi) + canlı doğrulama komutları:
> - `flutter analyze` (mobil) → **No issues found**
> - `flutter test` (mobil) → **+371 ~4 (flaky: bir koşuda -2, sonraki koşularda yeşil)**
> - `npm run typecheck` (web) → **exit 0, hata yok**
> - `npm run lint` (web) → **No ESLint warnings or errors**
>
> **Denetlenen temizlik commit'leri:** `557b38b` prune nav · `34854ce` loyalty redirect · `db48e62` hide web nav · `41dad75` remove non-product leftover surfaces (en geniş; mobil profil/login/favoriler/discovery + web EN route stub'ları).

---

## 1. Özet

Kapsamda kalan 13 MVP özelliğinin tamamı **derleme/typecheck/lint açısından sağlam**. Temizlik commit'leri (özellikle `41dad75`) sponsorluk/loyalty/gamification kalıntılarını silerken **hiçbir in-scope özelliğin route'unu, RPC'sini veya import zincirini kırmamış**. `flutter analyze` sıfır sorun, web `typecheck`+`lint` temiz, mobil silinen `sponsored_businesses_provider` testi de düzgün silinmiş (yetim test yok).

İki gerçek bulgu var ve ikisi de **BROKEN değil, DEGRADED düzeyinde**: (1) mobil test paketi **flaky** (TR/EN ikiz widget testlerinin paylaşılan global state'i bir koşuda 2 başarısızlık üretti, ardışık koşularda yeşil — CI güvenilirliği riski), (2) bazı **out-of-scope-belirsiz** owner/admin panel sayfaları (`ai-analysis`, `requests`, `suspended`, `incidents`, `group-requests`) hâlâ TAM canlı ve nav'da linkli — bu in-scope özellikleri kırmaz ama panel yüzeyinde MVP-dışı içerik bırakır (ürün kararı kuyruğu).

### Durum dağılımı

| Etiket | Adet | Özellikler |
|---|---|---|
| `HEALTHY` | 10 | claim, işletme profili, menü/fiyat, public QR menü, QR analytics, masa feedback, is_open_now, yakın keşif, arama/filtre, yorum/kanıt/doğrulanmış |
| `DEGRADED` | 3 | favoriler (i18n regresyonu), owner/admin paneli (flaky test + scope-belirsiz canlı sayfalar), veri kalitesi/moderasyon (scope-belirsiz incidents/group-requests canlı) |
| `BROKEN` | 0 | — |
| `NEEDS_VERIFICATION` | 0 | (statik+canlı build doğrulamasıyla tüm zincirler teyit edildi) |

> **Not:** Hiçbir özellik BROKEN değil. DEGRADED işaretlenen 3 özellik fonksiyonel olarak çalışıyor; eksiklikleri ya test/CI kalitesinde ya da yanına bırakılmış MVP-dışı yüzeylerde.

---

## 2. Özellik bazlı detay

### 1. Claim / Sahiplenme — `HEALTHY`

- **Route/UI:** Mobil claim **bilinçli kaldırıldı** (commit `3eb7f07` "remove sahiplen feature"); MVP'de claim web-only. Web: `(genel)/sahiplen` (TR public form) + admin kuyruğu `app/admin/claims/page.tsx` ve canonical `yonetici/itirazlar/claims`. Kalan mobil "sahiplen" string eşleşmeleri yalnızca veri alanları (discovery/legal/inbox), kırık değil.
- **API/RPC:** `submit_owner_claim_v1` (`sunucu/sahiplik-talebi/route.ts`, zod + rateLimit 5/15dk + auth + işletme varlık kontrolü) ✓ standarda uygun. Karar: `admin_decide_owner_claim_v1` (`yonetici/itirazlar/claims/itiraz-islemleri.ts`, `is_admin` guard + claim karar e-postası). admin/claims actions.ts canonical'i mirror ediyor. RPC'ler migration'larda mevcut (`20260622000002`, `20260620000005`, base_schema).
- **Test:** Web claim için server-action + e2e `sahip-write-smoke.spec.ts` dolaylı kapsama. Doğrudan claim unit testi yok (kabul edilebilir).
- **Kırık bağlantı:** Yok.

### 2. İşletme Profili — `HEALTHY`

- **Route/UI:** Mobil `/b/:id` → `BusinessPage` (router.dart:379). Web: `(genel)/isletme/[slug]` + `(public)/b/[slug]` (her ikisi de loading/opengraph/yorumlar alt sayfalarıyla tam).
- **API/RPC:** `get_business_amenities_v1`, `get_business_crowd_v1`, `get_business_new_items_v1`, `get_business_trending_items_v1`, `get_business_hours_v1` vb. — hepsi migration'larda mevcut.
- **Test:** `yorum_katalogu_test.dart` business detail fallback testleri yeşil.
- **Kırık bağlantı:** Yok. `41dad75` `business_detail_sections.dart`'tan 60 satır sildi → check-in özet satırı (`_CheckinsSummaryLine`) temizliğiydi; profil zincirini etkilemedi.

### 3. Menü / Fiyat Yönetimi (Owner) — `HEALTHY`

- **Route/UI:** Web owner nav → `/owner/menus`, `/owner/menus/[menuId]/edit` (menu-editor-client), `/owner/pricing`, `/owner/price-suggestions`, `/owner/trash`, `/owner/menu/translations`. Hepsi mevcut.
- **API/RPC:** Mutation route'ları `app/api/owner/menus/route.ts`, `app/sunucu/sahip/menuler/route.ts` — her ikisinde de zod safeParse + auth (getUser) + rateLimit guard'ları doğrulandı (her birinde 6 eşleşme). CSV: `sunucu/sahip/menu-csv/route.ts`.
- **Test:** `menu-links.test.ts`, `menu-baglantilari.test.ts`, `menu-text.test.ts`, `menu-metinleri.test.ts` (lib seviyesi).
- **Kırık bağlantı:** Yok.

### 4. Public QR Menü — `HEALTHY`

- **Route/UI:** Mobil `/menu/:menuId` → `PublicMenuSharePage`. Web public render: `(genel)/m/[slug]` (kategori `c/[categoryId]` + ürün `i/[itemId]` alt route'larıyla), `revalidate=300`, zengin veri (`getPublicMenuPageData`, fiyat geçmişi, varyantlar, foto).
- **API/RPC:** `/q/[code]` ve `/kod/[code]` short-link route'ları → `decodeBusinessCode` → `buildMenuHref` → 307 redirect. `get_menu_items_v1`, `get_menu_item_photos_v1`, `get_menu_item_variants_v1`, `get_menu_item_price_history_v1`.
- **Test:** **En iyi kapsanan özellik** — e2e: `public-menu.spec.ts`, `public-menu-live.spec.ts`, `acik-menu.spec.ts`, `acik-menu-canli.spec.ts`, `karanlik-mod.spec.ts` + unit: `short-code.test.ts`, `kisa-kod.test.ts`.
- **Kırık bağlantı:** Yok.

### 5. QR Analytics — `HEALTHY`

- **Route/UI:** Owner nav → `/owner/qr` ("QR Design Kit") → her işletme için `/karekod/[id]` (QR Studio). Owner analytics `/owner/analytics` QR/track verisi tüketiyor (3 eşleşme: qr/scan/track/get_owner_analytics).
- **API/RPC:** `/q/[code]` route'u `eventName:'qr_scanned'`'ı `/api/track`'e POST ediyor (redirect_ms ölçümüyle). `get_owner_analytics_v1` (`20260414000008`), `get_business_busy_hours_v1` (`20260603000006`).
- **Test:** Lighthouse QR scriptleri var (`lighthouse:qr:auth`). Doğrudan analytics unit testi yok (DEGRADED'a düşürmeyecek kadar küçük).
- **Kırık bağlantı:** Yok.

### 6. Masa Feedback (sipariş-bağımsız) — `HEALTHY`

- **Route/UI:** Mobil `public_menu_share_page.dart` içinde feedback bölümü (8 eşleşme). Sipariş akışından bağımsız geri bildirim.
- **API/RPC:** `submit_table_feedback_v1` (`public_menu_share_page.dart:322`). RPC **`00000000000000_base_schema.sql`'de mevcut** (ilk grep'te ad-hoc desen kaçırdı, teyit edildi).
- **Not:** Admin tarafındaki `admin/table-feedback` ve TR `yonetici/masa-geri-bildirimleri` sayfaları `41dad75`'te redirect-stub'a indirildi — bu **masa SİPARİŞİ** geri bildirimiydi (kapsam dışı), in-scope masa-feedback'ten farklı. Karışıklık riski var ama in-scope mobil feedback zinciri sağlam.
- **Kırık bağlantı:** Yok.

### 7. Açık/Kapalı Bilgisi (is_open_now) — `HEALTHY`

- **Route/UI:** 21 dosyada kullanılıyor (business_tile, open_price_badge, business_header, favorites_page, discovery vb.). Owner ayarı: `/owner/settings/hours`.
- **API/RPC:** `businesses_with_stats` view'ı **commit `a47452d` ile düzeltildi** (P1-2: `is_open_now` + `recent_price_verified_count` kolonları view'a eklendi; öncesinde rozet hep gizliydi). `get_business_hours_v1`.
- **Test:** Dolaylı (badge testleri).
- **Kırık bağlantı:** Yok. Bu özellik en son aktif olarak ONARILMIŞ durumda.

### 8. Yakın Mekan Keşfi — `HEALTHY`

- **Route/UI:** Mobil bottom-nav "Harita" → `/discover?view=map` → `discovery_map_page.dart`. Web: `(public)/discover` + `(genel)/kesif/harita`.
- **API/RPC:** `search_nearby_businesses_v3` (güncel, deprecated v1/v2 değil) — `20260416072511_remote_schema.sql`'de mevcut. `get_daily_picks`, `get_city_districts_v1`.
- **Test:** Discovery widget testleri yeşil.
- **Kırık bağlantı:** Yok. `41dad75` discovery_repository.dart'tan 81 satır sildi → **yalnızca `fetchSponsoredBusinesses`/`get_sponsored_businesses_v1`** (sponsorluk, kapsam dışı); nearby/search kodu el değmeden duruyor.

### 9. Arama / Filtre — `HEALTHY`

- **Route/UI:** `search_filter_sheet.dart`, `discovery_search_notifier.dart`, `search_repository.dart`. Drawer'da "Arama & Filtreleme" linki → `/discover`. Admin `/admin/search`.
- **API/RPC:** `search_menu_items_v2` (`20260615000002`), `search_nearby_businesses_v3`. Filtre: kategori, fiyat seviyesi, açık/kapalı (is_open_now).
- **Test:** Discovery/search dolaylı.
- **Kırık bağlantı:** Yok.

### 10. Favoriler — `DEGRADED`

- **Route/UI:** Mobil bottom-nav "Favoriler" → `/favorites` → `FavoritesPage`. Paylaşılan koleksiyon `/c/:slug`, paylaşılan id listesi `?ids=`. Auth-gated (paylaşım hariç).
- **API/RPC:** `toggle_favorite_v1`, `get_my_favorites_v1` (remote_schema'da mevcut). `FavoritesRepository._businessSelect` `is_open_now`+`recent_price_verified_count` seçiyor (P1-2 view fix'iyle uyumlu).
- **Test:** Favorites controller/status provider testleri mevcut.
- **DEGRADED nedeni (küçük):** `41dad75`, `favorites_page.dart` `_FavoritesHeader`'ını sadeleştirirken l10n'lı selamlamayı (`discoveryGreetingHello`) **hardcoded `'Merhaba! 👋'` inline string'e** çevirdi (favorites_page.dart `_FavoritesHeader.build`). CLAUDE.md "no inline ARB-less user strings" kuralına aykırı i18n regresyonu — fonksiyonel kırık değil, EN dilde Türkçe metin görünür. Ayrıca taste_twin/notifications-bell importları kaldırıldı (doğru, kapsam dışı).
- **Kırık bağlantı:** Yok.

### 11. Yorum / Kanıt / Doğrulanmış Bilgi — `HEALTHY`

- **Route/UI:** Mobil `/b/:id/review` (oluştur), `/b/:id/reviews` (liste). `business_reviews_page.dart:255` `verifiedVisit` rozeti. Web `(genel)/isletme/[slug]/yorumlar`, `(public)/b/[slug]/reviews`.
- **API/RPC:** Yorum gönderimi `submit_review_v3` (`reviews_repository.dart:93`, base_schema). Doğrulanmış ziyaret server-side `_review_verified_visit()` (`20260422000001`, `20260422000005`). Liste `get_business_reviews_v3` (verified_visit bool + 'verified' sort). Foto: `review_photos` insert.
- **Test:** `yorum_katalogu_test.dart` (kriter serileştirme), review vote/reply testleri.
- **Kırık bağlantı:** Yok. `review.dart:30` yorumu doğrulanmış-ziyaret server hesaplamasını açıkça belgeliyor.

### 12. Owner / Admin Web Paneli — `DEGRADED`

- **Route/UI:** Owner shell (`owner-shell-client.tsx`) 3 bölüm: Operasyon (dashboard/businesses/menus/onboarding), Büyüme (analytics/reviews/qr), Yönetim (team/price-suggestions/requests/suspended/activity/ai-analysis/trash/settings). Admin shell (`admin-shell-client.tsx`) 3 bölüm, 16+5+5 öğe. **Tüm in-scope sayfalar mevcut ve linkli.**
- **API/RPC:** Owner/admin dashboard, analytics, claims, reviews, businesses zincirleri sağlam.
- **Kırık-nav kontrolü (önemli, NEGATİF=iyi):** `41dad75` redirect-stub'a indirilen sayfalara (`/owner/growth`, `/owner/marketing`, `/admin/growth`, `/admin/sponsorships`, `/admin/table-feedback`, `/admin/b2b-exports`) **nav shell'lerinde HİÇBİR link kalmamış** — yani redirect cleanup'tan kaynaklanan "tıkladım redirect oldu" kırık-his YOK. Nav linkleri sayfa stub'larıyla birlikte temizlenmiş.
- **DEGRADED nedenleri:**
  1. **Scope-belirsiz canlı sayfalar nav'da:** Owner nav hâlâ `/owner/requests` (grup istekleri — 127 satır TAM), `/owner/suspended` (askıya alma — 151 satır TAM), `/owner/ai-analysis` (75 satır TAM) linkliyor. Bunlar önceki audit'te `NEEDS_HUMAN_DECISION` idi; in-scope MVP listesinde yer almıyor ama redirect de edilmedi. Panel yüzeyinde MVP-dışı içerik bırakıyor (kullanıcı kararı bekliyor, in-scope kırık değil).
  2. **Flaky test** (bkz. §12 altı / madde 3 ortak).
- **Kırık bağlantı:** in-scope link yok; yukarıdaki scope-belirsiz linkler "kırık" değil ama "MVP-dışı".

### 13. Veri Kalitesi / Moderasyon — `DEGRADED`

- **Route/UI:** Admin moderasyon sayfalarının **tamamı mevcut**: `queue`, `reports`, `reviews`, `verified`, `appeals`, `receipt-submissions`, `business-submissions`, `suspended`, `roles`, `audit`, `temp-uploads`. Nav'da linkli.
- **API/RPC:** Moderasyon kuyruğu, rapor, doğrulama, fiş başvurusu zincirleri sağlam.
- **DEGRADED nedenleri:** Admin nav `/admin/incidents` (olay merkezi — 271 satır TAM) ve `/admin/group-requests` (grup istekleri — 145 satır TAM) linkliyor; ikisi de önceki audit'te `NEEDS_HUMAN_DECISION`. `incidents` P0 moderasyon sınırında olabilir (muhtemelen in-scope tutulmalı), `group-requests` sosyal/kapsam-dışı. Net scope kararı verilmeli. Bu, in-scope moderasyonu kırmaz; sadece nav'da karar bekleyen iki yüzey bırakır.
- **Kırık bağlantı:** Yok.

---

## 3. BROKEN bulgular — öncelikli düzeltme listesi

**BROKEN bulgu YOK.** Hiçbir in-scope özellikte kırık import, eksik RPC, derleme/typecheck/lint/analyze hatası bulunmadı. Temizlik commit'leri in-scope zincirlere zarar vermemiş.

> **Öncelikli (BROKEN olmayan ama düzeltilmesi gereken) iki madde aşağıda — bkz. §5.**

---

## 4. DEGRADED bulgular — düzeltme önerileri (öncelik sırası)

| # | Özellik | Bulgu | Dosya | Öneri |
|---|---|---|---|---|
| D1 | Mobil test paketi (genel) | **Flaky:** `flutter test` bir koşuda `-2` (onboarding_sayfasi_test "Register CTA routes" + profile_page_test "guest renders"), ardışık koşularda `+371` yeşil. Tek başına çalıştırılınca daima geçiyor → test-sırası/paylaşılan-global-state kirliliği. TR/EN ikiz dosyalar (`onboarding_page_test.dart`+`onboarding_sayfasi_test.dart`) aynı global state'i paylaşıyor olabilir. | `test/features/onboarding/ui/`, `test/features/profile/ui/profile_page_test.dart` | İkiz testleri izole et (setUp/tearDown'da global reset) veya birini kaldır. CI'da `--concurrency=1` veya flaky-retry. **CI yeşil-kırmızı güvenilirliği için en yüksek öncelik.** |
| D2 | Favoriler | i18n regresyonu: l10n'lı selamlama hardcoded `'Merhaba! 👋'` oldu | `uygulamalar/mobil/lib/features/favorites/ui/favorites_page.dart` `_FavoritesHeader` | Inline string yerine mevcut `discoveryGreetingHello`/`discoveryGreetingHelloAnon` ARB anahtarına geri dön. |
| D3 | Owner/Admin panel + Moderasyon | Scope-belirsiz MVP-dışı sayfalar nav'da canlı: owner `requests`/`suspended`/`ai-analysis`, admin `incidents`/`group-requests` | `src/ui/shell/owner-shell-client.tsx`, `src/ui/shell/admin-shell-client.tsx` ve ilgili `app/.../page.tsx` | Ürün kararı: in-scope ise koru, değilse §2.1/§4 (önceki audit) gibi nav-link kaldır + redirect-stub. **`admin/incidents` muhtemelen in-scope (P0 moderasyon), önce o netleştirilsin.** |

---

## 5. Önceki temizliklerin yan etkisi var mı?

**Net cevap: In-scope 13 özellikten HİÇBİRİ kırılmadı.** Detaylı yan-etki analizi:

### `41dad75` (en geniş temizlik) yan etkileri
- **Mobil sponsorluk silme:** `sponsored_businesses_provider.dart`, `sponsored_badge.dart`, `discovery_repository.fetchSponsoredBusinesses`, `_DiscoverySponsoredSection` kaldırıldı. → **Yetim/kırık referans kalmadı** (grep: 0 eşleşme; `flutter analyze`: 0 sorun). Silinen `sponsored_businesses_provider_test.dart` de düzgün kaldırılmış (yetim test yok). Discovery'nin **nearby/search** kodu el değmedi → Özellik #8, #9 sağlam.
- **Mobil login/profile/favorites yeniden yazımı:** `login_page.dart` (1311 satır değişim), `profile_settings_page.dart`, `favorites_page.dart`, `account_security_page.dart` büyük diff. → Derleme sağlam; tek somut regresyon **D2 (favorites inline string)**. Profile/onboarding testleri **flaky** oldu (**D1**) — bu yeniden yazımların test-state etkileşimi olası neden.
- **Web EN route stub'ları:** `(public)/feed|heroes|budget|compare`, `(auth)/smart-feed|collab-lists|group-requests|taste-twin`, `admin/sponsorships|growth|table-feedback`, `owner/growth|marketing/*` → ~14-15 satırlık redirect'e indirildi. Önceki audit'in **EN KRİTİK bulgusu (EN ağacı canlı) büyük ölçüde KAPATILMIŞ.** In-scope sayfalara dokunulmadı.
- **panel_flutter_web / personel app:** `.github/workflows/{panel,personel}_quality.yml`, ilgili docs/plan dosyaları silindi. `uygulamalar/` altında yalnızca `mobil`+`web` var. → In-scope hiçbir referans bu silinen yüzeylere bağlı değil.

### `557b38b` / `34854ce` / `db48e62` yan etkileri
- TR route ağaçları (`sahip/*`, `yonetici/*`, `(genel)/*`, `(kimlik)/*`) redirect-stub'a indirildi; loyalty/sadakat route'ları kapatıldı; nav linkleri kesildi. → In-scope sayfalar (claim, menü, QR, profil, yorum, favori, keşif) **korundu** (commit mesajı da bunu açıkça belirtiyor). Nav shell'lerinde redirected sayfaya link kalmadı → **kırık-nav hissi YOK** (§2 madde 12 doğrulandı).

### Sonuç
Temizlikler **cerrahi** yapılmış: out-of-scope yüzeyler kaldırılırken in-scope zincirler korunmuş. Geriye kalan iki gerçek sorun (flaky test, favorites inline string) küçük ve düzeltilebilir; üçüncü madde (scope-belirsiz panel sayfaları) bir ürün kararı, teknik kırık değil. **Acil/bloklayıcı hiçbir kırık bulunmadı.**

---

## 6. Doğrulama Komut Çıktıları (özet)

| Komut | Sonuç |
|---|---|
| `flutter analyze` (mobil) | No issues found (0 sorun) |
| `flutter test` (mobil) | +371 ~4 — **flaky**: bir koşu -2, sonraki koşular yeşil |
| `npm run typecheck` (web) | exit 0, hata yok |
| `npm run lint` (web) | No ESLint warnings or errors |
