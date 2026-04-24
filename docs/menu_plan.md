# Yeedoy — iMenuPro / Menubly / GloriaFood (Menü) Seviyesi Planı

> **Hazırlanış:** 2026-04-24  
> **Kapsam:** Mobile Flutter · Panel Flutter Web · Next.js Web · Supabase Backend  
> **Kapsam Dışı:** Online sipariş, ödeme işleme, teslimat yönetimi — bunlar ayrı bir işletme mobil uygulaması gerektirir  
> **Bakış açısı:** İşletme sahibi (panel) + Son kullanıcı (web + mobil)  
> **Öncelik:** P0 = Kritik · P1 = Yüksek · P2 = Orta · P3 = Uzun vadeli

---

## İçindekiler

1. [Rakip Benchmark Analizi](#1-rakip-benchmark-analizi)
2. [Mevcut Durum — Ne Var, Ne Yok](#2-mevcut-durum--ne-var-ne-yok)
3. [Menü Yönetimi Geliştirmeleri](#3-menü-yönetimi-geliştirmeleri)
4. [Müşteri Deneyimi Geliştirmeleri](#4-müşteri-deneyimi-geliştirmeleri)
5. [İşletme Araçları](#5-i̇şletme-araçları)
6. [Pazarlama ve Bağlılık Sistemi](#6-pazarlama-ve-bağlılık-sistemi)
7. [Teknik Altyapı ve Entegrasyonlar](#7-teknik-altyapı-ve-entegrasyonlar)
8. [Öncelik Tablosu](#8-öncelik-tablosu)
9. [Başarı Kriterleri](#9-başarı-kriterleri)

---

## 1. Rakip Benchmark Analizi

### 1.1 Platform Karşılaştırması (Menü Özellikleri)

| Özellik | iMenuPro | Menubly | GloriaFood | **Yeedoy Şu An** |
|---|---|---|---|---|
| Dijital QR menü | ✅ | ✅ | ✅ | ✅ |
| Çoklu tema / marka | ✅ | ✅ | ✅ | ✅ (6 tema) |
| Menü versiyonlama | ❌ | ❌ | ❌ | ✅ (benzersiz) |
| Besin değeri / alerjen | ✅ | ❌ | ❌ | ✅ |
| Fiyat geçmişi | ❌ | ❌ | ❌ | ✅ (benzersiz) |
| Toplu menü import | ✅ | ❌ | ❌ | ✅ |
| Varyant grupları | ✅ | ❌ | ✅ | ✅ |
| Yorum / değerlendirme | ❌ | ❌ | ❌ | ✅ (gelişmiş) |
| **Özel domain** | **✅** | **✅** | **✅** | **❌** |
| **Açılış saatleri yönetimi** | **✅** | **✅** | **✅** | **❌ (görüntüleme var, CRUD yok)** |
| **Çok dilli menü içeriği** | **✅** | **✅** | **❌** | **⚠️ altyapı var, UI yok** |
| **Menü zamanlama UI** | **✅** | **❌** | **❌** | **⚠️ model var, UI yok** |
| **Alerjen filtresi (müşteri)** | **✅** | **❌** | **❌** | **❌** |
| PDF menü export | ✅ | ✅ | ❌ | ✅ |
| Gömülebilir widget | ✅ | ✅ | ✅ | ✅ |
| QR tasarım kiti (poster) | ✅ | ❌ | ❌ | ❌ |
| Sosyal medya linkleri | ✅ | ✅ | ✅ | ❌ |
| Harita / yön alma | ❌ | ✅ | ✅ | ❌ |
| **Push kampanya** | **❌** | **❌** | **✅** | **❌** |
| **Sadakat / puan programı** | **❌** | **❌** | **❌** | **❌** |
| **E-posta pazarlama** | **❌** | **❌** | **✅** | **❌** |
| Structured data (JSON-LD) | ❌ | ❌ | ❌ | ❌ |
| Menü jump navigasyonu | ✅ | ❌ | ❌ | ❌ |
| Ana ekran widget (mobil) | ❌ | ❌ | ❌ | ✅ (benzersiz) |
| Siri / Google Assistant | ❌ | ❌ | ❌ | ✅ (benzersiz) |
| Topluluk fiyat doğrulama | ❌ | ❌ | ❌ | ✅ (benzersiz) |

### 1.2 Yeedoy'un Stratejik Pozisyonu

**Yeedoy = Dijital Menü + Fiyat Şeffaflığı + Topluluk**

Rakiplerinde olmayan dört benzersiz güç:
1. Topluluk destekli fiyat doğrulama ve geçmiş
2. Menü versiyonlama (hiçbir rakipte yok)
3. Müşteri kaynaklı içerik (fotoğraf, kriter puanı, verified ziyaret)
4. Bağlılık ekosistemleri (Siri, ana ekran widget'ı)

**Hedef:** Bu güçleri koruyarak menü builder ve işletme araçlarında rakip seviyesine çıkmak.

---

## 2. Mevcut Durum — Ne Var, Ne Yok

### 2.1 Zaten Var (kodda doğrulandı)

```
✅ Dijital menü (web + QR + mobil) — 6 tema
✅ Menü versiyonlama + diff görünümü (menu_versions_sheet.dart)
✅ Bulk import (CSV/Excel) — bulk_menu_import_sheet.dart
✅ PDF export — menu_editor_pdf_flow.dart
✅ Varyant grupları — menu_item_variant_groups_section.dart + migration
✅ Besin değeri (kalori/protein/yağ/karbonhidrat) — migration 20260414000001
✅ Alerjen veritabanı (14 AB alerjeni) — migration 20260414000002
✅ İçerik listesi — migration 20260414000003
✅ Zaman pencereleri (öğle/akşam farklı fiyat) — migration 20260422000003
✅ Gerçek zamanlı menü değişikliği yayını — migration 20260414000006
✅ Döviz kuru desteği — migration 20260414000004
✅ Gömülebilir widget (iframe/webview/YouTube embed)
✅ QR kod oluşturma + özelleştirme + SVG/PNG export
✅ Menü zamanlama modeli (activeFrom/activeTo — panelde UI yok)
✅ Çoklu menü per işletme (draft/published/archived + kind)
✅ Kısa link (shortCode) + paylaşım
✅ Push bildirimi altyapısı (FCM, push-dispatch Edge Function)
✅ Yorum sistemi (çoklu kriter, fotoğraf, sahip yanıtı, verified ziyaret)
✅ Check-in altyapısı (crowd check-in — sadakat temel verisi olarak kullanılabilir)
```

### 2.2 Bu Plan'ın Kapsamındaki Eksikler

```
❌ Özel domain (businessname.com → menü sayfası)
❌ Açılış saatleri CRUD (business_hours tablosu + panel UI + web banner)
❌ Menü zamanlama UI (activeFrom/activeTo panel'dan düzenlenemiyor)
❌ Çok dilli menü içeriği UI (owner panel'dan TR+EN yazma akışı yok)
❌ Alerjen filtresi — müşteri tarafı (web dropdown + mobil sheet)
❌ Stok tükendi — müşteri görünümü (is_available web+mobil'de görünmüyor)
❌ Realtime stok durumu web tarafında
❌ Menü jump navigasyonu (web sidebar + mobil "Bölüme Atla")
❌ QR Tasarım Kiti (masa çadırı, poster, dijital ekran şablonları)
❌ Müşteri menü önizleme iframe (panel içinde)
❌ Sosyal medya linkleri (Instagram/Facebook/TikTok)
❌ Harita entegrasyonu (Google Maps statik harita + yön alma)
❌ WhatsApp Chat linki (menü sayfasından doğrudan mesaj)
❌ Push kampanya gönderimi (owner-initiated broadcast)
❌ Sadakat / puan programı (check-in + yorum bazlı)
❌ E-posta pazarlama (Resend entegrasyonu)
❌ Otomatik tetikleyici kampanyalar (pg_cron bazlı)
❌ JSON-LD structured data (Restaurant + Menu + MenuItem + OpeningHours)
❌ Dinamik sitemap.xml (/m/[slug] sayfaları)
❌ Google Maps panel'da konum seçici
❌ Personel rol yönetimi (manager / cashier yetki ayrımı)
❌ Menü içerik kütüphanesi entegrasyonu (katalogdan otomatik doldurma)
```

---

## 3. Menü Yönetimi Geliştirmeleri

> **Benchmark:** iMenuPro (gelişmiş menü builder) + Menubly (müşteri odaklı sadelik)

### M1 — Özel Domain (P0)

**Durum:** Tüm rakiplerde var. İşletme sahipleri kendi markalarıyla menü sunmak istiyor.

```
[ ] custom_domains tablosu:
     business_id + domain + verified_at + dns_txt_token + is_active
[ ] Panel: OwnerCustomDomainPage — /owner/settings/domain
     Adım 1: Alan adını gir (örn. menu.bistrobodrum.com)
     Adım 2: DNS TXT kaydını kopyala (yd-verify=<token>)
     Adım 3: "Doğrula" butonu → /api/domain/verify
     Adım 4: SSL aktif → yönlendirme başlar
[ ] Supabase Edge Function: verify-domain/index.ts
     DNS over HTTPS API (1.1.1.1/dns-query) ile TXT kaydı sorgula
     Doğrulandıysa: custom_domains.verified_at = now()
[ ] Next.js middleware.ts:
     Request hostname → custom_domains tablosu lookup
     Eşleşirse: rewrite → /m/[slug] (iç yönlendirme, URL değişmez)
[ ] Cache: Supabase'den gelen custom_domain → slug, 5dk TTL (Edge config)
[ ] Fallback: yeedoy.com/m/[slug] her zaman çalışmaya devam eder
[ ] Panel: "Özel domain" / "yeedoy.com adresi" toggle + durum göstergesi
```

### M2 — Açılış Saatleri Yönetimi (P0)

**Durum:** Tüm rakiplerde var. Müşteri "kapalı mı açık mı" bilgisini göremeden menüye bakıyor.

```
[x] business_hours tablosu ✅ 2026-04-24
     business_id + day_of_week (0-6) + open_time text + close_time text + is_closed bool
[x] business_special_hours tablosu ✅ 2026-04-24
     business_id + date + open_time + close_time + note (bayram/etkinlik/tadilat)
[x] RPC: upsert_business_hours_v1 + get_business_hours_v1 + delete + upsert_special ✅ 2026-04-24
[x] Panel: OwnerBusinessHoursPage — /owner/settings/hours ✅ 2026-04-24
     Haftalık çizelge: 7 gün × (açık/kapalı toggle + saat aralığı TextFormField)
     Özel gün ekle: tarih seçici + saat + not
     "Şu an açık mı?" önizleme badge'i
[x] Web menü header'ına badge ✅ 2026-04-24
     Yeşil "Şu an açık" veya gri "Şu an kapalı" — get_business_hours_v1 RPC server-side
[x] Mobile: İşletme sayfası hero header'ına açılış badge'i ✅ 2026-04-24
     _BusinessHeroTrustHeader ← isOpenNow (from _businessHoursProvider via _BusinessSectionsScroll)
[x] schema.org/Restaurant JSON-LD: openingHoursSpecification ✅ 2026-04-24
     page.tsx → hoursInfo.weekly → OpeningHoursSpecification array → schema
```

### M3 — Menü Zamanlama UI (P1)

**Durum:** Model hazır (`OwnerMenu.activeFrom/activeTo/kind`), panel'da UI yok.

```
[ ] Panel: OwnerMenuEditorPage'e "Zamanlama" bölümü ekle
     Aktif dönem: DateTimeRangePicker (activeFrom ↔ activeTo)
     Günlük tekrar modu: "Her gün 11:00-15:00" (cron-style)
     Menü türü (kind): sabah / öğle / akşam / tüm gün dropdown
[ ] OwnerMenusPage liste görünümünde zamanlama badge'i:
     "Aktif" (yeşil) / "Bugün 11:00-15:00" (sarı) / "Arşiv" (gri)
[ ] Supabase Edge Function veya pg_cron: scheduled_menu_activation()
     Her 15 dakikada: activeFrom/activeTo aralığı doluysa status güncelle
     draft → published (zaman başlayınca), published → archived (zaman dolunca)
[ ] Mobil müşteri: menü sayfasında aktif menü badge'i ("Öğle Menüsü • 11:00-15:00")
```

### M4 — Çok Dilli Menü İçeriği UI (P1)

**Durum:** Web tarafında `getTranslationValue()` + TR/EN toggle zaten çalışıyor; owner panel'da içerik girişi yok.

```
[ ] Panel: item editör sheet'ine (item_editor_sheet.dart) dil sekmesi ekle
     "Türkçe" / "English" tab seçici
     Türkçe: name + description (zorunlu)
     English: name + description (opsiyonel, boşsa TR fallback)
[ ] Panel: OwnerSectionEditorPage'e bölüm başlığı çeviri alanı
[ ] Panel: OwnerTranslationsPage — /owner/menu/translations (toplu görünüm)
     Tüm öğeler: TR İsim | EN İsim | TR Açıklama | EN Açıklama sütunları
     Boş EN alanları sarı highlight → hızlı doldurma UX
     Satır başına inline edit (tıkla → düzenle → kaydet)
[ ] Supabase: upsert_menu_item_translation_v1 RPC
[ ] Web: TR/EN toggle'ın göstereceği içerik artık owner'dan geliyor
```

### M5 — Stok Durumu — Müşteri Görünümü (P1)

**Durum:** `OwnerMenuItem.status` ('active'/'inactive') var; müşteri tarafında yansıması yok.

```
[ ] Web public-menu-client.tsx:
     item.is_available = false → kart üzerine yarı saydam "Tükendi" overlay
     İçerik ve fiyat görünür, etkileşim engelli (opacity-50 + pointer-events-none)
[ ] Mobile MenuItemListTile: is_available = false → "Tükendi" badge + soluk renk
[ ] Web: Supabase JS channel → realtime_menu_items (migration zaten var)
     Item status değişikliği anında güncellenir, sayfa yenilemeden
[ ] Panel: OwnerMenuEditorPage item listesinde her satırda aktif/pasif inline Switch
     Zaten var ama görsel olarak belirginleştir: yeşil ● / kırmızı ● nokta + etiket
```

### M6 — Alerjen Filtresi — Müşteri Görünümü (P1)

**Durum:** 14 AB alerjeni veritabanı var; müşteri filtreleme yok.

```
[ ] Web: Menü sticky filter bar'a "Alerjen" dropdown butonu ekle
     Popover: 14 alerjen checkbox listesi (ikon + ad)
     Seçili alerjenlerden herhangi birini içeren öğeler gizlenir
     URL param: ?exclude_allergens=gluten,dairy (bookmark-friendly)
     Aktif filtre chip'i: "Gluten, Süt filtresi aktif ✕"
[ ] Mobile: Menü sayfası filtre bottom sheet'ine Alerjenler bölümü ekle
     CheckboxListTile ile 14 alerjen + ikon
     "X alerjen filtresi aktif" uyarı banner'ı (sarı, menü listesi üstünde)
[ ] Web: Öğe kartında alerjen ikonu satırı (önemli 5 alerjen, tooltip ile)
[ ] Mobile: MenuItemDetailSheet alerjen bölümü zaten var; filtre ile bağlantısını kur
[ ] Panel: Alerjen giriş UI zaten var (menu_item_allergen_section.dart) — mevcut kalır
```

### M7 — Menü İçerik Kütüphanesi Entegrasyonu (P2)

**Durum:** `food_catalog_repository.dart` + `local_food_catalog_data_source.dart` zaten var.

```
[ ] Panel: item_editor_sheet.dart'ta "Katalogdan Ekle" flow
     Katalog arama → seçim → besin değerleri + alerjenler otomatik doldurulur
     Kullanıcı üzerine yazabilir (override)
[ ] Panel: "Şablon olarak kaydet" — mevcut öğeyi kataloga ekle (işletme özel katalog)
     business_food_templates tablosu: business_id + name + description + nutrition jsonb + allergens jsonb
[ ] Otomatik öneri: item ismine göre en yakın katalog öğesi öneri (trgm benzerliği)
```

---

## 4. Müşteri Deneyimi Geliştirmeleri

> **Benchmark:** Menubly (sade, hızlı, mobil-first) + iMenuPro (zengin içerik görünümü)

### U1 — Menü Jump Navigasyonu (P1)

**Durum:** iMenuPro'da sidebar navigasyon var; uzun menülerde kritik UX özelliği.

```
[ ] Web (lg+ ekran): Sağda sticky kategori sidebar
     Menü listesinin sağına konumlandırılmış sabit panel (sticky top-24)
     Her kategori: ad + öğe sayısı + aktifse sol border highlight
     Tıklanınca: smooth scroll (scrollIntoView) + URL hash güncellenir
     Aktif kategori: scroll pozisyonuna göre otomatik vurgulama (IntersectionObserver)
[ ] Web (mobil): Mevcut pill nav bar yeterli — IntersectionObserver ile aktif auto-highlight ekle
[ ] Mobile: "Bölüme Atla" butonu — MenuPage AppBar sağ ikon
     SectionJumpSheet bottom sheet: bölüm listesi → tıklanınca scroll
     Her bölüm: ad + altındaki öğe sayısı
```

### U2 — Menü Sayfası İletişim ve Sosyal Bölümü (P1)

**Durum:** Menubly ve GloriaFood menü sayfalarında iletişim + sosyal linkler standard.

```
[ ] business_social_links tablosu:
     business_id + platform ('instagram'|'facebook'|'tiktok'|'twitter'|'youtube') + url
[ ] Panel: OwnerBusinessProfilePage'e (veya yeni OwnerContactPage) sosyal medya alanları
     Her platform: URL TextFormField + platform ikonu
[ ] Web menü footer bölümünü genişlet:
     Telefon butonu (tel: link) — zaten var
     WhatsApp Chat linki: wa.me/90XXXXXXXXXX?text=Merhaba, menünüz hakkında sormak istiyorum
     Google Maps yön alma: maps.google.com/?q={lat},{lng}
     Sosyal medya ikon butonları (Instagram, Facebook, TikTok)
     Çalışma saatleri özeti (M2 bağımlısı)
[ ] Mobile: İşletme sayfası "İletişim" bölümünü güncelle
     WhatsApp butonu + Maps butonu + sosyal linkler satırı
```

### U3 — Müşteri Menü Önizleme Modu (P2)

**Durum:** `?preview=1` var ama owner dışarıda tarayıcı açmak zorunda.

```
[ ] Panel: OwnerMenuEditorPage toolbar'ına "Müşteri Gözüyle Önizle" butonu
[ ] Panel içinde iframe overlay (tam ekran modal veya side drawer)
     Boyut seçici: masaüstü (1280px) / tablet (768px) / mobil (390px) çerçeve
     Seçili tema doğrudan yansır
[ ] Taslak değişiklikler önizlemesi: /m/[slug]?preview=1&draft_session=<token>
     Session token → Supabase'de geçici draft state (30dk TTL, owner_only)
```

### U4 — QR Tasarım Kiti (P2)

**Durum:** iMenuPro'da masa çadırı + poster şablonları var; QR baskı materyali işletmeler için kritik.

```
[ ] Panel: OwnerQrDesignKitPage — /owner/qr/design
[ ] Şablon 1: Masa Çadırı (Tent Card)
     A4 kağıda 2 adet, ön+arka, işletme adı + logo + QR + "Menü için tarayın"
     html-to-canvas → jsPDF veya flutter_to_pdf → indir
[ ] Şablon 2: Duvar Posteri
     A3 / A2 boyutu, yüksek çözünürlük, baskıya hazır SVG + PNG (300dpi equiv.)
[ ] Şablon 3: Dijital Ekran
     1920×1080 PNG (TV/tablet ekran), döngüsel slayt modu önerisi
[ ] Tüm şablonlarda: tema renkleri + işletme logosu otomatik uygulanır
[ ] "Hepsini İndir" → ZIP dosyası
```

---

## 5. İşletme Araçları

> **Benchmark:** GloriaFood (kapsamlı işletme paneli) + iMenuPro (profesyonel yönetim araçları)

### T1 — Google Maps Entegrasyonu (P1)

**Durum:** `business.location` PostGIS geography var; harita hiçbir yerde gösterilmiyor.

```
[ ] Web menü "Bize Ulaşın" bölümüne statik harita:
     Google Maps Static API veya Mapbox Static Tiles (API key)
     480×200px statik görüntü → tıklanınca Google Maps açılır
     API key: NEXT_PUBLIC_GMAPS_KEY (.env.example'a ekle)
[ ] Fallback: API key yoksa sadece "Yol Tarifi Al" text linki göster
     maps.google.com/?q={lat},{lng}
[ ] Mobile: İşletme sayfası "Yol Tarifi Al" butonu → google_maps_launcher paketi
     `launchMapsUrl(lat, lng, label: business.name)`
[ ] Panel: İşletme ekle/düzenle formunda haritadan konum seçme
     flutter_map (OpenStreetMap, ücretsiz) + tap-to-pin
     Seçilen koordinat → business.location kaydedilir
```

### T2 — Personel Hesabı Yönetimi (P2)

**Durum:** `owner_team` modeli var; rol ayrımı yeterince granüler değil.

```
[ ] business_staff_roles enum: 'owner' | 'manager' | 'editor'
     owner: tam yetki
     manager: menü CRUD + analitik görüntüleme + yorum yanıtı
     editor: sadece menü içerik düzenleme
[ ] Panel: OwnerTeamPage'i (zaten var) genişlet
     Davet ile personel ekle → e-posta → Supabase magic link
     Rol atama dropdown
     Aktif oturum göstergesi (son görülen)
[ ] RLS güncelleme: business_staff tablosuna göre menü/analitik RPC yetkisi
[ ] Panel oturumunda rol badge'i: "Manager olarak giriş yapıldı"
```

### T3 — Menü Analitik Derinleştirme (P2)

**Durum:** Analitik altyapı var (`owner_analytics_hourly_v1` migration); görsel eksik.

```
[ ] Öğe bazlı görüntülenme analitiği:
     En çok görüntülenen 10 öğe (item_view event'ten)
     En çok tıklanan kategori
     Ortalama menü sayfasında geçirilen süre (basit event delta)
[ ] Panel: OwnerAnalyticsPage'e "Menü Performansı" kartı
     Top öğeler listesi + görüntülenme sayısı + dün/bu hafta karşılaştırması
[ ] Heatmap alternatifi: kategori bazlı görüntülenme bar chart (CustomPaint, bağımlılık yok)
[ ] Ziyaretçi kaynak raporu: ?utm_source tracking (QR scan / direkt link / embed)
     utm parametreleri analytics event'e meta olarak eklenir
```

---

## 6. Pazarlama ve Bağlılık Sistemi

> **Benchmark:** GloriaFood (e-posta kampanyaları + push) + Flipdish (sadakat programı)  
> **Not:** Sipariş tabanlı değil; check-in, yorum ve fiyat doğrulama aktivitesine dayalı.

### P1 — Sadakat / Puan Programı (P1)

**Durum:** Check-in altyapısı ve contribution sistemi var; puan programına dönüştürülebilir.

```
[ ] loyalty_programs tablosu:
     business_id + is_active + checkin_points + review_points + photo_points
     reward_threshold_pts (eşik) + reward_type ('discount_pct'|'free_item') + reward_value
[ ] loyalty_accounts tablosu:
     business_id + user_id + points + lifetime_points + redeemed_points
[ ] RPC: award_loyalty_points_v1 — aktivite sonrası puan ver:
     Check-in → checkin_points (ör. 10 puan)
     Yorum bırakma → review_points (ör. 25 puan)
     Fotoğraf ekleme → photo_points (ör. 15 puan)
     Trigger: trg_award_loyalty_on_checkin / trg_award_loyalty_on_review
[ ] RPC: get_loyalty_status_v1 (user_id + business_id → puan, eşik, kalan)
[ ] Mobile: Profil > "Puan Kartlarım" bölümü
     Her kayıtlı işletme için kart: logo + puan + ilerleme çubuğu
     "Bistro Bodrum: 340 / 500 puan • 160 puan kaldı"
[ ] Mobile: İşletme sayfasına "Puan Kazan" badge'i
     Check-in sonrası "+10 puan kazandın!" animasyonlu toast
[ ] Panel: OwnerLoyaltyPage — /owner/marketing/loyalty
     Program aktif/pasif toggle
     Aktivite başına puan oranları ayarı
     En yüksek puanlı müşteri top 10 listesi
     "Ödüle ulaşan müşteriler bu ay: X kişi"
[ ] Push: "Ödül kazandın!" bildirimi (eşiğe ulaşıldığında)
     push-dispatch: 'loyalty_reward_unlocked' tipi ekle
```

### P2 — Push Kampanya Yönetimi (P1)

**Durum:** FCM altyapısı + push-dispatch var; owner'ın kendi kampanya göndermesi yok.

```
[ ] push_campaigns tablosu:
     business_id + title + body + target_segment + image_url
     scheduled_at + sent_at + sent_count + opened_count
     target_segment: 'all_followers' | 'loyal_top20' | 'inactive_30d' | 'new_30d'
[ ] Edge Function: send-push-campaign/index.ts
     Segment → FCM token listesi (500 kayıt/batch, FCM batch send API)
     Gönderim sonrası: push_campaigns.sent_count + sent_at güncelle
[ ] Panel: OwnerPushCampaignPage — /owner/marketing/campaigns
     Kampanya oluştur:
       Başlık + metin (max 150 karakter) + opsiyonel görsel URL
       Hedef segment seçici + tahmini kişi sayısı önizlemesi
       Zamanlama: "Hemen gönder" veya datetime picker
     Gönder / zamanla butonu
     Kampanya geçmişi: gönderildi, açılma oranı, tarih
[ ] Hazır şablonlar: "Yeni menü yayında", "Hafta sonu özel", "Sizi özledik"
[ ] Rate limiting: işletme başına günde max 1 kampanya
```

### P3 — E-posta Pazarlama (P2)

**Durum:** Yeedoy'da e-posta gönderimi hiç yok; Resend ücretsiz planla başlanabilir.

```
[ ] E-posta provider: Resend (3.000 e-posta/ay ücretsiz, Türkiye'ye çalışır)
[ ] email_campaigns tablosu:
     business_id + subject + html_body + target_segment + scheduled_at + sent_at + sent_count
[ ] Edge Function: send-email-campaign/index.ts (Resend SDK)
     business_followers → e-posta listesi (is_subscribed_email = true)
     Batch: 50/sn Resend limitine dikkat
[ ] Panel: OwnerEmailCampaignPage — /owner/marketing/email
     Şablon editörü: başlık + metin alanları + önizleme
     Hedef segment + gönder / zamanla
     Kampanya geçmişi: açılma oranı (Resend webhook ile)
[ ] E-posta şablonları:
     "Yeni menü yayında" (menü linki + öne çıkan öğe)
     "Ödülünüz hazır" (sadakat ödülü bildirimi)
     "Sizi özledik" (30+ gün gelmeyen müşteriye)
[ ] GDPR: her e-postada "Abonelikten çık" linki zorunlu
[ ] Opt-in: kullanıcı işletmeyi takip ederken e-posta aboneliği onay checkbox'ı
[ ] .env.example: RESEND_API_KEY ekle
```

### P4 — Otomatik Tetikleyici Kampanyalar (P2)

**Durum:** pg_cron altyapısı zaten kullanılıyor (revisit_reminders, leaderboard).

```
[ ] "Sizi özledik" — 30 gün check-in/yorum yapmayan → işletmenin push/e-posta kampanyası
[ ] "Doğum günü" — profile.birth_date varsa → hediye puan (loyalty_programs.birthday_bonus_pts)
[ ] "Yeni ödül eşiği yaklaşıyor" — %80 puana ulaşınca hatırlatma
[ ] pg_cron: her gece 09:00 UTC → run_loyalty_automations_v1()
[ ] Panel: OwnerAutomationsPage — /owner/marketing/automations
     Her trigger: açıklama + aktif/pasif toggle + mesaj özelleştirme
     "Son 30 günde X kişiye gönderildi" istatistik
```

---

## 7. Teknik Altyapı ve Entegrasyonlar

### A1 — Özel Domain Altyapısı (P0)

```
[ ] Vercel: wildcard subdomain *.yeedoy.com tanımı (dashboard'dan)
[ ] Custom domain desteği: Vercel her domain için otomatik Let's Encrypt SSL
[ ] Next.js middleware.ts'e custom domain lookup ekleme:
     const slug = await resolveCustomDomain(request.headers.get('host'))
     if (slug) rewrite to /m/[slug] with x-business-slug header
[ ] resolveCustomDomain: Supabase'den cached lookup
     cache: Map<domain, slug> + 5dk TTL (Edge runtime compatible)
[ ] Fallback: bilinmeyen hostname → 404 veya yeedoy.com'a yönlendir
[ ] Test: curl -H "Host: menu.testbusiness.com" https://yeedoy.com/m/test ile lokal test
```

### A2 — SEO ve Structured Data (P1)

**Durum:** schema.org/Organization var; Restaurant + Menu + MenuItem yok.

```
[ ] Web: menü sayfası (public RSC component) JSON-LD ekle:
     schema.org/Restaurant:
       name, description, image, address, geo, telephone
       openingHoursSpecification (M2 bağımlısı)
       hasMenu → schema.org/Menu
     schema.org/Menu → hasPart → schema.org/MenuSection[]
     schema.org/MenuItem: name, description, offers.price, nutrition
[ ] Next.js: generateMetadata() ile her /m/[slug] için:
     title: "{businessName} Dijital Menü | Yeedoy"
     description: "{businessDescription} — QR menü, fiyat takibi"
     og:image: işletme kapak fotoğrafı (zaten var)
     canonical: özel domain varsa custom URL kullan
[ ] Next.js: app/sitemap.ts (dinamik)
     Supabase'den aktif işletme slug'ları → /m/[slug] URL listesi
     Değişme sıklığı: 'weekly', priority: 0.8
[ ] robots.txt güncellemesi:
     Allow: /m/ — dijital menü sayfaları taranabilir
     Disallow: /panel — admin/owner panel'ı indekslenmez
[ ] Google Search Console doğrulama → Rich Results Test ile test
```

### A3 — Google Maps Entegrasyonu (P1)

```
[ ] .env.example: NEXT_PUBLIC_GMAPS_KEY ekle (Web Static API)
[ ] Web: Statik harita bileşeni
     src/ui/components/static-map.tsx
     URL: https://maps.googleapis.com/maps/api/staticmap?center={lat},{lng}&zoom=15&size=480x200&markers={lat},{lng}&key=...
     Fallback: key yoksa "Yol Tarifi Al" text link (maps.google.com/?q=lat,lng)
[ ] Mobile: google_maps_launcher paketi pubspec.yaml'a ekle
     url_launcher alternatifi: Uri.parse('geo:{lat},{lng}?q={label}')
[ ] Panel: İşletme form'una haritadan konum seçme
     flutter_map (OpenStreetMap, lisans gerektirmez) + tap-to-pin
     LatLng seçimi → business.location (PostGIS POINT) kaydedilir
[ ] Panel: Mevcut işletmeler için koordinat düzenleme ekranı
```

### A4 — WhatsApp Chat Entegrasyonu (P1)

**Not:** Sipariş sistemi değil; müşteri işletmeyle doğrudan iletişim kurabilsin.

```
[ ] businesses tablosuna whatsapp_number text kolonu ekle
[ ] Panel: OwnerBusinessProfilePage'e WhatsApp numarası alanı
     Format doğrulama: +90 5XX... (E.164)
[ ] Web menü iletişim bölümünde:
     "WhatsApp'tan Yaz" butonu:
     https://wa.me/{whatsapp_number}?text=Merhaba%2C+men%C3%BCn%C3%BCz+hakk%C4%B1nda+sormak+istiyorum
[ ] Mobile: İşletme sayfasına WhatsApp butonu
     url_launcher ile wa.me link açılır
[ ] Tracked: analytics event: 'whatsapp_click' (business_id meta)
```

### A5 — Bildirim Altyapısı Genişletmesi (P1)

**Durum:** FCM + push-dispatch Edge Function var; yeni event tipleri eklenecek.

```
[ ] push-dispatch/index.ts ALLOWED_PUSH_TYPES'a ekle:
     'loyalty_reward_unlocked' — eşiğe ulaşınca
     'loyalty_points_earned' — aktivite sonrası puan
     'menu_updated' — işletme yeni menü yayınladığında takipçilere
     'business_hours_changed' — sahip saatleri güncellediğinde takipçilere
[ ] supabase/functions/push-dispatch: batch send için recursive çağrı
     >500 takipçi → paginated FCM batch (şu an tek çağrı)
[ ] Açılma oranı tracking: FCM data payload'a campaign_id ekle
     Mobil uygulama: notification tapped → /api/track (event: 'push_opened')
```

---

## 8. Öncelik Tablosu

### 8.1 Faz 1 — Temel Platform (3-4 Hafta)

Bu olmadan iMenuPro/Menubly seviyesine ulaşılamaz:

| # | Alan | Değişiklik | Etki | Çaba | Öncelik | Durum |
|---|------|-----------|------|------|---------|-------|
| 1 | Backend | business_hours + special_hours tabloları + RPC | Kritik | Orta | **P0** | [ ] |
| 2 | Panel | OwnerBusinessHoursPage (haftalık çizelge + özel gün) | Kritik | Orta | **P0** | [ ] |
| 3 | Web | "Şu an açık/kapalı" header badge | Kritik | Düşük | **P0** | [ ] |
| 4 | Backend | custom_domains tablosu + verify Edge Function | Yüksek | Orta | **P0** | [ ] |
| 5 | Web/Panel | Özel domain DNS doğrulama + Next.js middleware | Yüksek | Yüksek | **P0** | [ ] |
| 6 | Panel | Menü zamanlama UI (DateTimeRangePicker + badge) | Yüksek | Düşük | **P0** | [ ] |
| 7 | Backend | pg_cron scheduled_menu_activation() | Yüksek | Düşük | **P0** | [ ] |

### 8.2 Faz 2 — Menü Kalitesi (3-4 Hafta)

| # | Alan | Değişiklik | Etki | Çaba | Öncelik | Durum |
|---|------|-----------|------|------|---------|-------|
| 8 | Panel | Çok dilli menü içeriği (dil sekmesi + toplu çeviri sayfası) | Yüksek | Orta | **P1** | [ ] |
| 9 | Web | Alerjen filtresi dropdown + URL param | Yüksek | Orta | **P1** | [ ] |
| 10 | Mobile | Alerjen filtresi bottom sheet | Yüksek | Orta | **P1** | [ ] |
| 11 | Web | Stok tükendi overlay + opacity | Yüksek | Düşük | **P1** | [ ] |
| 12 | Mobile | Stok tükendi badge | Yüksek | Düşük | **P1** | [ ] |
| 13 | Web | Realtime stok güncellemesi (Supabase channel) | Orta | Düşük | **P1** | [ ] |
| 14 | Web | Menü jump navigasyonu — sağ sticky sidebar (lg+) | Yüksek | Orta | **P1** | [ ] |
| 15 | Mobile | "Bölüme Atla" bottom sheet + AppBar butonu | Orta | Orta | **P1** | [ ] |

### 8.3 Faz 3 — İletişim ve Pazarlama (3-4 Hafta)

| # | Alan | Değişiklik | Etki | Çaba | Öncelik | Durum |
|---|------|-----------|------|------|---------|-------|
| 16 | Backend | business_social_links tablosu | Orta | Düşük | **P1** | [ ] |
| 17 | Panel | Sosyal medya + WhatsApp alanları (profil sayfası) | Orta | Düşük | **P1** | [ ] |
| 18 | Web | İletişim bölümü (WhatsApp + Maps + sosyal) | Yüksek | Düşük | **P1** | [ ] |
| 19 | Mobile | WhatsApp + Maps butonu (işletme sayfası) | Orta | Düşük | **P1** | [ ] |
| 20 | Web | Google Maps statik harita embed | Orta | Orta | **P1** | [ ] |
| 21 | Mobile | google_maps_launcher "Yol Tarifi Al" | Orta | Düşük | **P1** | [ ] |
| 22 | Backend | loyalty_programs + loyalty_accounts + RPC'ler | Yüksek | Orta | **P1** | [ ] |
| 23 | Mobile | Puan kartları (profil > "Puan Kartlarım") | Yüksek | Orta | **P1** | [ ] |
| 24 | Panel | OwnerLoyaltyPage | Yüksek | Orta | **P1** | [ ] |
| 25 | Backend | push_campaigns tablosu + send-push-campaign Edge Function | Yüksek | Orta | **P1** | [ ] |
| 26 | Panel | OwnerPushCampaignPage | Yüksek | Orta | **P1** | [ ] |

### 8.4 Faz 4 — SEO, Kalite ve Platform (Devam Eden)

| # | Alan | Değişiklik | Etki | Çaba | Öncelik | Durum |
|---|------|-----------|------|------|---------|-------|
| 27 | Web | JSON-LD Restaurant + Menu + MenuItem structured data | Yüksek | Orta | **P1** | [ ] |
| 28 | Web | Dinamik sitemap.xml (/m/ sayfaları) | Yüksek | Düşük | **P1** | [ ] |
| 29 | Panel | OwnerTranslationsPage (toplu çeviri tablosu) | Orta | Orta | **P2** | [ ] |
| 30 | Panel | Menü önizleme iframe (masaüstü/tablet/mobil çerçeve) | Orta | Orta | **P2** | [ ] |
| 31 | Panel | QR Design Kit (masa çadırı + poster + dijital ekran) | Yüksek | Yüksek | **P2** | [ ] |
| 32 | Panel | OwnerEmailCampaignPage (Resend entegrasyonu) | Orta | Yüksek | **P2** | [ ] |
| 33 | Panel | OwnerAutomationsPage (pg_cron tetikleyiciler) | Orta | Yüksek | **P2** | [ ] |
| 34 | Panel | OwnerMenuAnalyticsPage (öğe bazlı görüntülenme) | Yüksek | Orta | **P2** | [ ] |
| 35 | Panel | Google Maps haritadan konum seçme (flutter_map) | Orta | Orta | **P2** | [ ] |
| 36 | Panel | Personel rol yönetimi (manager/editor) | Orta | Orta | **P2** | [ ] |
| 37 | Web | Katalog öğesinden menüye ekle (besin + alerjen otomatik) | Düşük | Orta | **P2** | [ ] |
| 38 | Mobile | Alerjen filtresi kalıcı kaydet (profil diyet tercihleri) | Orta | Orta | **P3** | [ ] |
| 39 | Backend | business_food_templates (işletme özel katalog) | Düşük | Orta | **P3** | [ ] |
| 40 | Panel | UTM kaynak raporu (QR / direkt / embed) | Orta | Orta | **P3** | [ ] |

---

## 9. Başarı Kriterleri

### Rakip Denge Noktaları (6 Ay)

| Özellik | Şu An | Hedef |
|---|---|---|
| Özel domain | ❌ | ✅ Faz 1 |
| Açılış saatleri CRUD | ❌ | ✅ Faz 1 |
| Menü zamanlama UI | ❌ | ✅ Faz 1 |
| Çok dilli içerik | ⚠️ | ✅ Faz 2 |
| Alerjen filtresi | ❌ | ✅ Faz 2 |
| Stok durumu müşteri | ❌ | ✅ Faz 2 |
| Menü jump nav | ❌ | ✅ Faz 2 |
| WhatsApp Chat | ❌ | ✅ Faz 3 |
| Sadakat programı | ❌ | ✅ Faz 3 |
| Push kampanya | ❌ | ✅ Faz 3 |
| JSON-LD SEO | ❌ | ✅ Faz 4 |
| QR Design Kit | ❌ | ✅ Faz 4 |

### İşletme Metrikleri

- [ ] Özel domain kullanan işletme oranı ≥ %20
- [ ] Menü zamanlama kullanan işletme oranı ≥ %30
- [ ] EN içerik girilen öğe oranı ≥ %50 (çok dilli)
- [ ] Sadakat programı aktif işletme oranı ≥ %25
- [ ] Push kampanya açılma oranı ≥ %28
- [ ] WhatsApp tıklama oranı (menüde) ≥ %8

### Teknik Kalite

- [ ] Özel domain DNS doğrulama süresi < 2 dakika
- [ ] Menü zamanlama gecikmesi < 15 dakika (pg_cron döngüsü)
- [ ] Realtime stok güncellemesi < 500ms
- [ ] JSON-LD: Google Rich Results Test — sıfır hata
- [ ] Web menü LCP < 2.5s (özel domain dahil)
- [ ] Flutter analyze — sıfır uyarı

### Müşteri Deneyimi

- [ ] Alerjen filtresi kullanan ziyaretçi oranı ≥ %12
- [ ] Menü jump nav tıklanma oranı ≥ %25 (lg+ ekranda)
- [ ] İletişim bölümünden tıklama (WhatsApp/Maps) ≥ %10

---

## Minimum Doğrulama

Her değişiklik için zorunlu adımlar:

- **Backend migration:** `supabase db push` + lokal `supabase start` ile test, RLS policy doğrulama
- **Flutter dokunuşu:** `flutter analyze` (sıfır hata) + ilgili `flutter test`
- **Web dokunuşu:** `npm --prefix apps/web_next run typecheck` + `npm --prefix apps/web_next run lint`
- **Panel dokunuşu:** `npm --prefix apps/panel_flutter_web run lint` + `npm --prefix apps/panel_flutter_web run test`
- **L10n değişikliği:** `npm run l10n:audit`
- **SEO değişikliği:** Google Rich Results Test ile JSON-LD doğrulama

---

*Bu plan yaşayan bir belgedir. Sprint planlamasında `[ ]` maddeleri faz sırasına göre alınmalı, tamamlananlar `[x] ✅ YYYY-MM-DD` ile işaretlenmelidir.*
