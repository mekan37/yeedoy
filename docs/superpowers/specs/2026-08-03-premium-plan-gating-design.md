# Premium Plan/Gating Altyapısı — Design

## Bağlam

İki ayrı araştırma turu (rakip piyasa analizi + kod tabanı denetimi, 2026-08-03) sonucunda şu tespit edildi: Yeedoy'da hiçbir plan/abonelik altyapısı yok — `businesses` tablosunda plan/tier alanı, ödeme entegrasyonu veya plan-bazlı özellik kilitleme mekanizması bulunmuyor. Buna karşılık birkaç "premium" adayı özellik (OCR menü tarama, AI alerjen/kalori tespiti, AI görsel üretme) Supabase edge function seviyesinde tam çalışır durumda ama hiçbir UI'dan çağrılmıyor (orphaned). Çoklu dil (`menu_translations`) ve QR özelleştirme (`karekod-uretici.tsx`) ise tamamen çalışıyor ama hiçbir kademeye kilitli değil.

Bu doküman, denetim raporundaki 14 kalemden kullanıcıyla birlikte teker teker onaylanan alt kümeyi kapsıyor. Kapsam dışı bırakılan kalemler (CRM, sadakat/loyalty, envanter, çoklu şube, destek sistemi, operasyonel personel app) ayrı bir stratejik karar/tur gerektiriyor; sadakat özellikle `docs/product/2026-yeedoy-final-scope-source-of-truth.md`'de MVP dışı sayıldığı için bilerek dışarıda bırakıldı.

## Kapsam

**Sadece web, sadece `uygulamalar/web/app/sahip/**` (işletme sahibi paneli) ve ilgili `src/lib`/Supabase katmanı.** Mobil uygulamada hiçbir değişiklik yok — işletme sahibi işlemleri mobilde yapılmıyor. Genel kullanıcı tarafı (`(genel)`, `(public)`) ve admin panel (`app/yonetici/**`) bu turda dokunulmuyor.

Bu round'da **ödeme tahsilatı (checkout/abonelik faturalandırma) yok** — plan ataması admin panelden manuel yapılacak (`admin_set_business_plan_v1`), gerçek ödeme sağlayıcı entegrasyonu (iyzico vb.) ayrı ve sonraki bir tasarım turu.

### Dahil özellikler
1. Plan/gating altyapısının kendisi (veri modeli + RPC katmanı)
2. Ürün/kategori sayısı limiti
3. OCR/AI menü tarama — mevcut `ai-menu-analyze` edge function'ının UI'a bağlanması
4. Alerjen & kalori AI otomasyonu — mevcut `ai-allergen-detect`/`ai-nutrition-estimate` edge function'larının UI'a bağlanması
5. Çoklu dil — mevcut özelliğin plana göre kademelenmesi (Free: 1 dil, üst kademe: daha fazla)
6. AI görsel üretme — mevcut `ai-menu-image-gen` edge function'ının UI'a bağlanması (Pro-only)
7. QR filigran — Free kademede yeni bir watermark mekanizması (bugün hiç yok)
8. Harita/keşif önceliklendirme — arama sıralamasına plan-bazlı ağırlık eklenmesi

### Kapsam dışı (bu turda yok, ayrı tur gerektirir)
CRM, sadakat/loyalty tier sistemi (MVP kapsam dokümanıyla tutarlı — bilinçli dışlama), envanter/stok, owner self-service çoklu şube, destek/ticket sistemi, operasyonel personel app (mobil gerektirir).

## Yaklaşım

### Mimari seçim

DB-seviyeli plan + özellik tablosu yaklaşımı seçildi (alternatifler: mevcut `runtime_feature_flags`'i işletme-bazlı genişletmek — sayısal limitler için doğal değil; ya da route handler'da config-driven kontrol — RPC'ler doğrudan çağrılabildiği için gerçek güvenlik sınırı oluşturmuyor, CLAUDE.md'nin "yeni Supabase erişimi repository/RPC üzerinden" ilkesiyle çelişiyor). Seçilen yaklaşım mevcut RPC/RLS/SECURITY DEFINER mimarisiyle tutarlı ve gerçek sunucu-taraflı zorlama sağlıyor.

### Kademe yapısı

4 kademe: `free`, `starter`, `standard`, `pro`. ("Kurumsal" kademesi bu turda yok — tek farkı olacak çoklu şube/CRM kapsam dışı bırakıldığı için, o özellikler eklendiğinde ayrı bir kademe olarak geri gelecek.)

| Özellik | Free | Starter | Standard | Pro |
|---|---|---|---|---|
| Ürün/kategori limiti | 30 ürün | Sınırsız | Sınırsız | Sınırsız |
| OCR/AI menü tarama | Ayda 1 (10 ürüne kadar) | Ayda 5, sınırsız ürün | Sınırsız | Sınırsız |
| Alerjen & kalori | Manuel | Manuel | AI otomatik | AI otomatik |
| Dil sayısı | 1 (TR) | 1 (TR) | 2 dil | Sınırsız |
| AI görsel üretme | — | — | — | Var |
| QR filigran | Filigranlı | Filigransız | Filigransız | Filigransız |
| Harita önceliklendirme | Standart sıralama | Standart sıralama | Öncelikli sıralama | Sponsorlu/öne çıkan |

### Veri modeli

```sql
-- businesses tablosuna
ALTER TABLE businesses ADD COLUMN plan_tier text NOT NULL DEFAULT 'free'
  CHECK (plan_tier IN ('free','starter','standard','pro'));

-- kademe → özellik/limit eşlemesi (veri, kod değil — SQL satırıyla değiştirilebilir)
CREATE TABLE plan_features (
  plan_tier text NOT NULL,
  feature_key text NOT NULL,
  limit_value int NULL,        -- sayısal limit (30, 5, 2 ...) — NULL = sınırsız/boolean özellik
  enabled boolean NOT NULL DEFAULT true,
  PRIMARY KEY (plan_tier, feature_key)
);

-- sayaçlı özellikler için kullanım takibi (ör. "bu ay kaç OCR taraması yapıldı")
CREATE TABLE plan_feature_usage (
  business_id uuid NOT NULL REFERENCES businesses(id),
  feature_key text NOT NULL,
  period_start date NOT NULL,   -- ayın 1'i, aylık sayaçlar için doğal reset noktası
  usage_count int NOT NULL DEFAULT 0,
  PRIMARY KEY (business_id, feature_key, period_start)
);
```

`feature_key` değerleri: `menu_item_count`, `ocr_scans_per_month`, `allergen_ai`, `language_count`, `ai_image_gen`, `qr_watermark`, `map_boost`.

### RPC katmanı

- `_check_plan_limit_v1(p_business_id uuid, p_feature_key text)` — internal helper. İşletmenin `plan_tier`'ına göre `plan_features`'tan limiti okur; sayaçlı özelliklerse `plan_feature_usage`'daki güncel dönem kullanımıyla karşılaştırır. Aşılmışsa `plan_limit_exceeded: {feature_key}` mesajıyla `P0003` fırlatır.
- `_increment_plan_usage_v1(p_business_id uuid, p_feature_key text)` — internal helper. Gated işlem başarıyla tamamlandıktan sonra ilgili dönem satırını `INSERT ... ON CONFLICT DO UPDATE` ile artırır.
- `admin_set_business_plan_v1(p_business_id uuid, p_plan_tier text)` — admin-only (auth.uid() rol kontrolü), `P0002` ile admin-dışı erişimi reddeder. Plan atamasının tek yolu bu round'da.
- `get_my_plan_v1()` — owner-facing, mevcut oturumun işletmesi için `plan_tier` + her `feature_key` için limit/kullanım özetini döner. Owner panelindeki plan kartı bunu tüketir.

Tüm yeni RPC'ler CLAUDE.md'deki `{action}_{subject}_v1` adlandırma, `SECURITY DEFINER`, `SET search_path = public`, `REVOKE ALL` + hedefli `GRANT` şablonunu izler.

### Özellik entegrasyon noktaları

| Özellik | Bağlanacağı yer | Gating türü |
|---|---|---|
| Ürün limiti | Menü ürünü ekleme RPC'si (mevcut) | Sayaç: `menu_item_count` |
| OCR tarama | Yeni route handler → mevcut `ai-menu-analyze` edge function | Aylık sayaç: `ocr_scans_per_month` |
| Alerjen/kalori AI | `menu-duzenleyici-istemcisi.tsx`'e yeni "AI ile doldur" butonu → mevcut `ai-allergen-detect`/`ai-nutrition-estimate` | Boolean: `allergen_ai` (Standard+) |
| Çoklu dil | `app/sahip/menu/ceviriler/` — yeni dil eklerken kontrol | Sayaç: `language_count` |
| AI görsel üretme | Yeni buton → mevcut `ai-menu-image-gen` | Boolean: `ai_image_gen` (Pro) |
| QR filigran | `karekod-uretici.tsx` çıktı üretimine watermark overlay | Boolean: `qr_watermark` (Free'de aktif) |
| Harita boost | `search_nearby_businesses_v3` sıralama mantığı — `ORDER BY` ifadesine plan-bazlı ağırlık eklenmesi | `map_boost` (Standard: öncelikli, Pro: sponsorlu) |

Tam RPC/dosya adları implementasyon planı sırasında kodun güncel haliyle teyit edilecek — yukarıdaki denetim raporunda (2026-08-03) doğrulanan dosya yolları referans alındı.

### Owner panel UI değişiklikleri

Tümü `app/sahip/**` içinde:

1. **Plan özeti kartı** — yeni sayfa (`app/sahip/ayarlar/plan/`): kademe adı + limit çubukları (`get_my_plan_v1()` tüketir).
2. **Ürün ekleme formu** — limit aşıldığında engelleyici hata + "Bu limit Free planda" mesajı.
3. **"Fotoğraftan Menü Oluştur" akışı** — `app/sahip/menu/` altına yeni sayfa/modal: yükleme → ilerleme → sonuç önizleme → onaylama.
4. **Menü düzenleyicide "AI ile doldur" butonu** — alerjen/kalori alanlarının yanına; kilitliyse tıklanınca upsell mesajı.
5. **Ürün görseli alanında "AI ile görsel oluştur" butonu** — sadece Pro'da aktif.
6. **Çeviriler sayfasında dil ekleme sınırı** — limit dolunca engelleyici mesaj.
7. **QR üretici** — filigran otomatik plana göre uygulanır, ekstra toggle yok.
8. **Ortak "kilitli özellik" bileşeni** — yukarıdaki tüm noktalarda tekrar kullanılacak upsell/rozet komponenti. Ödeme akışı olmadığı için CTA "Yükseltmek için bize ulaşın" (iletişim), gerçek checkout değil.

### Hata yönetimi

- Limit aşımı → `P0003 validation_error`, mesaj: `plan_limit_exceeded: {feature_key}`.
- Admin-dışı plan atama denemesi → `P0002 unauthorized`.
- Her yeni route handler: `zod.safeParse` + auth check + rate limit (mevcut proje standardı).

## Test planı

- `pnpm run typecheck` + `pnpm run lint`.
- `plan_features`/`plan_feature_usage`/`_check_plan_limit_v1` için vitest unit testleri: her gating noktası için en az bir "limit içinde → izin verildi" ve bir "limit aşıldı → engellendi" senaryosu.
- Migration sonrası `supabase db reset` ile local stack'te uçtan uca doğrulama.
- `pnpm run test:ci` (typecheck + lint + unit + build).

## Kapsam dışı

- Gerçek ödeme sağlayıcı entegrasyonu (iyzico vb.) ve self-service checkout/upgrade akışı — ayrı tur.
- CRM, sadakat/loyalty (MVP kapsam dokümanıyla tutarlı bilinçli dışlama), envanter/stok, owner self-service çoklu şube, destek/ticket sistemi — ayrı tur(lar).
- Operasyonel personel app (mobil) — bu round mobile dokunmuyor.
- "Kurumsal" kademesi — çoklu şube/CRM eklenene kadar tanımlanmayacak.
- Mevcut "Ekip" (takım daveti) sayfasına plan-bazlı üye sayısı limiti — kullanıcı tarafından bu turda istenmedi.
