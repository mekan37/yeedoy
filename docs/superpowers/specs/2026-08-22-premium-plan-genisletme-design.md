# Premium Plan Genişletmesi — Design

## Bağlam

`docs/superpowers/specs/2026-08-03-premium-plan-gating-design.md` ile kurulan plan/gating altyapısı (`plan_features`, `plan_feature_usage`, `_check_plan_limit_v1`, `_increment_plan_usage_v1`, `get_my_plan_v1`), o turda 14 kalemlik bir denetim raporunun yalnızca bir alt kümesini kapsamıştı. O doküman şu kalemleri açıkça kapsam dışı bırakmıştı: **CRM, sadakat/loyalty, envanter, çoklu şube, destek sistemi, operasyonel personel app** — ayrıca "Ekip" (takım daveti) sayfasına üye sayısı limiti "kullanıcı tarafından bu turda istenmedi" notuyla bilinçli olarak atlanmıştı.

O tarihten bu yana:
- **Sadakat** kendi ayrı tasarımını aldı (`2026-08-10-sadakat-design.md`, 4 fazlı plan) ve **zaten premium-gate'li** olarak inşa edildi — `plan_features`'a `sadakat_programi` anahtarı eklendi, `/sahip/pazarlama/sadakat/page.tsx` `get_my_plan_v1` ile kontrol ediyor. Bu doküman sadakat'a dokunmuyor.
- **Çoklu Şube** (`2026-08-06-coklu-sube-yonetimi-design.md`), **Destek Sistemi** (`2026-08-06-destek-sistemi-design.md`), **CRM v1+v2** (5 ayrı tasarım dokümanı, `2026-08-11` → `2026-08-15`) inşa edildi ama **hiçbirinin kendi tasarımında premium-gating hiç geçmiyor** (doğrulandı: sıfır referans). Bu özellikler bugün tüm kademelerde sınırsız/eşit.
- **Envanter/stok** ve **operasyonel personel app**: kodda hiç yok, henüz inşa edilmedi — bu doküman kapsamında değil.
- Bir subagent denetimi (2026-08-21), mevcut gösterim katmanında ek bir sorun buldu: `ayarlar/plan/page.tsx`'teki `FEATURE_LABELS` (7 anahtar) ile `premium/premium-veri.ts`'teki `PLAN_OZELLIKLERI` (8 anahtar, `sadakat_programi` dahil) birbirinden bağımsız, senkron değil — `ayarlar/plan` sayfasında sadakat satırı ham anahtar adıyla (`sadakat_programi`) render oluyor, Türkçe etiketsiz. Bu, oturum boyunca tekrar tekrar yakalanan "aynı listenin iki yerde bağımsız tutulması" hata sınıfının bir örneği daha (bkz. alerjen kod uyuşmazlığı, 2026-08-20).

Bu tur, kullanıcıyla üç ayrı soruda netleştirilen kapsamı hayata geçiriyor: **Ekip üyesi limiti** (fikir değişti, artık isteniyor), **Destek önceliği** (kademeye göre yanıt önceliği), **Analitik derinliği** (yeni fikir, orijinal 14 kalemin parçası değil) — artı **Çoklu Şube** limiti (orijinal 14 kalemin parçasıydı, hâlâ gate'siz) ve **CRM e-posta kampanyası** limiti (orijinal 14 kalemin CRM kalemine karşılık geliyor).

## Kapsam

**Sadece web, sadece `uygulamalar/web/app/sahip/**` ve ilgili `src/lib`/Supabase katmanı** — 2026-08-03 dokümanıyla aynı sınır. Mobil, genel kullanıcı tarafı, admin panel bu turda dokunulmuyor.

### Dahil

1. Dört yeni sayısal/boolean `plan_features` anahtarı: `team_seat_count`, `campaign_count_per_month`, `branch_count`, `analytics_range_days`.
2. Destek ticket önceliği — kademeye göre otomatik `priority` ataması (yeni `plan_features` anahtarı değil, doğrudan kod mantığı — aşağıda gerekçeli).
3. Etiket kaynağı tekilleştirme: `FEATURE_LABELS`/`TIER_LABELS` tek paylaşılan modüle taşınır, `sadakat_programi` eksik etiketi düzeltilir.
4. Paylaşılan `<PlanKullanimOzeti>` bileşeni — `gosterge-panosu` (kompakt) ve `ayarlar/plan` (tam) aynı bileşeni iki modda kullanır.
5. `baslangic` (onboarding) sayfasına plan durumu entegrasyonu + "Sadakat programı oluştur" önerisinin kilit kontrolü.

### Kapsam dışı

- Ödeme/checkout entegrasyonu — hâlâ ayrı bir tur (2026-08-03 dokümanıyla aynı gerekçe).
- CRM'in müşteri profili/segmentasyon/etiketleme/zincir-görünüm özelliklerinin (yalnızca e-posta kampanyası hariç) gate'lenmesi — kullanıcı yalnızca kampanya limitini istedi, CRM'in geri kalanı bu turda ele alınmıyor.
- Envanter/stok, operasyonel personel app — kodda yok.
- `/sahip/premium` ile `/sahip/ayarlar/plan` sayfalarının birleştirilmesi — **birleştirilmiyor**, ikisi farklı amaca hizmet ediyor (biri statik pazarlama/fiyat karşılaştırma, diğeri canlı hesap durumu); yalnızca etiket kaynakları ortaklaştırılıyor.

## Yaklaşım

Mevcut mimari birebir korunuyor: `plan_features` veri satırı olarak yeni limitler, `_check_plan_limit_v1`/`_increment_plan_usage_v1` internal helper'ları ile zorlama, `get_my_plan_v1` ile owner-facing özet. Yeni bir tablo, yeni bir gating sistemi icat edilmiyor — 2026-08-03 dokümanının "DB-seviyeli plan + özellik tablosu" mimari kararı hâlâ geçerli ve bu 4 yeni özellik de aynı `(plan_tier, feature_key) → limit_value` şekline birebir uyuyor.

**Destek önceliği farklı bir yaklaşım gerektiriyor:** `support_tickets.priority` zaten `text check (priority in ('low','medium','high','urgent')) default 'medium'` olarak var (`20260520000001_admin_api_keys_support_tickets.sql`). Bu bir sayısal limit ya da açık/kapalı boolean değil, kademeye göre değişen bir *değer* — `plan_features`'ın `limit_value int` şemasına zorlamak yerine, ticket oluşturma RPC'sinde doğrudan `case plan_tier when 'pro' then 'urgent' when 'standard' then 'high' else 'medium' end` ile çözülüyor. Bu, `plan_features` şemasını genişletmeden (YAGNI) mevcut enum'u yeniden kullanıyor.

### Kademe tablosu (yeni eklenenler)

| feature_key | Free | Başlangıç | Standart | Pro |
|---|---|---|---|---|
| `team_seat_count` | 1 | 3 | 10 | Sınırsız (`limit_value = NULL`) |
| `campaign_count_per_month` | 0 | 1 | 5 | Sınırsız |
| `branch_count` | 1 | 1 | 3 | Sınırsız |
| `analytics_range_days` | 7 | 30 | 90 | 90 |

`branch_count = 1` pratikte "zincir oluşturamaz" demek — `owner_create_chain_v1` bu limitle aynı mantıkla kapanıyor (mevcut satır sayısı + 1 ≤ limit kontrolü, `menu_item_count`'un çalıştığı şekilde).

`analytics_range_days`, standart/pro'da 90'da eşitleniyor çünkü mevcut UI'nin (`app/sahip/analitik/page.tsx`) üst sınırı zaten 90g — daha yüksek bir sayı vaat etmek UI'nin desteklemediği bir şey olurdu.

## Veri Modeli

Şema değişikliği yok — `plan_features` tablosu zaten `(plan_tier, feature_key, limit_value, enabled)` şeklinde genel amaçlı. Yeni migration yalnızca 16 satır (4 anahtar × 4 kademe) `INSERT`, mevcut tabloya:

```sql
insert into public.plan_features (plan_tier, feature_key, limit_value, enabled) values
  ('free','team_seat_count',1,true), ('starter','team_seat_count',3,true),
  ('standard','team_seat_count',10,true), ('pro','team_seat_count',null,true),
  ('free','campaign_count_per_month',0,true), ('starter','campaign_count_per_month',1,true),
  ('standard','campaign_count_per_month',5,true), ('pro','campaign_count_per_month',null,true),
  ('free','branch_count',1,true), ('starter','branch_count',1,true),
  ('standard','branch_count',3,true), ('pro','branch_count',null,true),
  ('free','analytics_range_days',7,true), ('starter','analytics_range_days',30,true),
  ('standard','analytics_range_days',90,true), ('pro','analytics_range_days',90,true)
on conflict (plan_tier, feature_key) do nothing;
```

`limit_value = null` mevcut kuralla (`_check_plan_limit_v1`'de NULL = sınırsız) tutarlı — 2026-08-03 dokümanındaki `menu_item_count` "Sınırsız" satırlarıyla aynı desen.

## RPC Katmanı

Yeni internal helper yok — mevcut `_check_plan_limit_v1(p_business_id, p_feature_key)` / `_increment_plan_usage_v1(...)` doğrudan yeni `feature_key` değerleriyle çağrılıyor. Değişen 4 RPC:

| RPC | Değişiklik |
|---|---|
| `upsert_team_member_v1` | Yeni üye eklerken (mevcut aktif üye sayısı) `_check_plan_limit_v1('team_seat_count')`; başarılıysa `_increment_plan_usage_v1` **gerekmiyor** — bu bir "anlık durum sayısı" (kaç aktif üye var), aylık sayaç değil; kontrol doğrudan `count(*) from team_members where business_id=... and status='active'` ile `limit_value`'ya karşı yapılıyor (menu_item_count ile aynı desen, ocr_scans_per_month ile farklı — o aylık sayaç). **Sınır, işletme sahibinin kendisini de kapsar** — yani Free'de (`limit_value=1`) sahip zaten 1 koltuğu doldurduğu için hiç ek üye davet edilemez; bu, kullanıcıyla onaylanan "Free: 1 (sadece sahip)" çerçevesiyle birebir tutarlı. Sayıma dahil edilecek `status` değerleri: `active` ve `invited` (bekleyen davet de bir koltuk işgal eder — aksi halde bir owner limitin üstünde davet gönderip hepsi kabul edilince limiti aşabilir). |
| `owner_upsert_campaign_v1` | Yeni kampanya oluştururken `_check_plan_limit_v1('campaign_count_per_month')` + başarılı oluşturmada `_increment_plan_usage_v1('campaign_count_per_month')` — `ocr_scans_per_month` ile birebir aynı aylık-sayaç deseni. |
| `owner_create_chain_v1` | Zincir oluştururken (bu, `branch_count` sayacının başlangıcı — chain oluşturma = 1. şube zaten var demek) `_check_plan_limit_v1('branch_count')`. |
| `owner_add_business_to_chain_v1` | Zincire yeni şube eklerken mevcut şube sayısına göre `_check_plan_limit_v1('branch_count')`. |
| Destek ticket oluşturma RPC'si (`20260806000002_create_support_ticket_rpc.sql`'deki fonksiyon) | `_get_business_plan_tier_v1` ile tier okunur, `priority` sütunu `case` ifadesiyle otomatik set edilir — kullanıcı girdisi değil. |

Analitik sayfası (`app/sahip/analitik/page.tsx`) bir RPC değil, server component — `get_my_plan_v1`'den `analytics_range_days` okunup `aralikGun` seçicisinde izin verilmeyen aralıklar (`disabled` + kilit ikonu) olarak render edilir; sunucu tarafında da `gunSayisi` sorgu parametresi `min(istenen, izin_verilen)` ile clamp edilir (yalnızca UI'a güvenmemek için — CLAUDE.md'nin "her mutation route handler auth+limit" ilkesiyle tutarlı, ama bu bir GET/read olduğu için tam RAISE EXCEPTION yerine sessiz clamp yeterli: kullanıcı 90g istese bile free planda en fazla 7g veri görür).

Tüm limit-aşım hataları mevcut desenle aynı: `P0003 validation_error`, mesaj `plan_limit_exceeded: {feature_key}`.

## Özellik Entegrasyon Noktaları

| Özellik | Bağlanacağı yer | Gating türü |
|---|---|---|
| Ekip üyesi | `app/sahip/ekip/ekip-islemleri.ts` → `upsert_team_member_v1` | Anlık sayaç: `team_seat_count` |
| CRM kampanyası | `app/sahip/pazarlama/kampanyalar/kampanya-islemleri.ts` → `owner_upsert_campaign_v1` | Aylık sayaç: `campaign_count_per_month` |
| Çoklu şube | `app/sahip/coklu-sube/coklu-sube-islemleri.ts` → `owner_create_chain_v1` / `owner_add_business_to_chain_v1` | Anlık sayaç: `branch_count` |
| Destek önceliği | Ticket oluşturma RPC'si | Otomatik değer ataması (limit değil) |
| Analitik aralığı | `app/sahip/analitik/page.tsx` | Anlık sayaç + sunucu-taraflı clamp: `analytics_range_days` |

## Owner Panel UI Değişiklikleri

1. **`src/lib/plan/plan-sabitleri.ts`** (yeni dosya) — `FEATURE_LABELS` (12 anahtar: mevcut 8 + yeni 4) ve `TIER_LABELS` tek yerden export edilir. `ayarlar/plan/page.tsx` ve `premium/premium-veri.ts` bu dosyadan import eder, kendi kopyalarını silerler.
2. **`ayarlar/plan/page.tsx`** — `sadakat_programi` artık "Sadakat programı" etiketiyle render olur (bug fix); 4 yeni satır otomatik listeye eklenir (mevcut döngü `plan_features`'tan geldiği için kod değişikliği gerekmez, yalnızca etiket eksikse görünür).
3. **`premium/premium-veri.ts`** — `PLAN_OZELLIKLERI`'ne 4 yeni satır eklenir (ekip/kampanya/şube/analitik), `label` alanları `plan-sabitleri.ts`'ten türetilir.
4. **`<PlanKullanimOzeti businessId compact?: boolean />`** (yeni paylaşılan bileşen, `src/ui/plan/plan-kullanim-ozeti.tsx`) — `get_my_plan_v1` çağırır, `compact=true` iken yalnızca kademe rozeti + en kritik 1-2 uyarı (örn. "%90 dolu") gösterir, `compact=false` iken tam çubuk listesi (bugünkü `plan-ozet-istemcisi.tsx` mantığı bu bileşene taşınır).
5. **`gosterge-panosu`** — bugünkü "yalnızca free ise banner" mantığı `<PlanKullanimOzeti compact />` ile değiştirilir; her kademede (free dahil) görünür, ama içerik kademeye göre değişir.
6. **`baslangic/page.tsx`** — plan durumu kartı eklenir (`<PlanKullanimOzeti compact />`); "Sadakat programı oluştur" önerisi artık `features.find(f => f.feature_key === 'sadakat_programi')?.enabled` kontrolüyle koşullu — kilitliyse öneri yerine "Sadakat programı Standart+ planda" upsell rozeti gösterilir (mevcut "kilitli özellik" bileşeni, 2026-08-03 dokümanının §8 maddesi, yeniden kullanılır).

## Hata Yönetimi

2026-08-03 dokümanıyla birebir aynı: `P0003` + `plan_limit_exceeded: {feature_key}`, admin-dışı erişim `P0002`. Yeni route handler yok (mevcut server action'lar genişletiliyor), dolayısıyla yeni zod şeması gerekmiyor — yalnızca RPC imzalarına dokunuluyor.

## Test Planı

- `pnpm run typecheck` + `pnpm run lint`.
- Yeni/değişen 4 RPC için vitest: her biri için "limit içinde → izin" ve "limit aşıldı → `P0003`" senaryosu (2026-08-03 dokümanının test desenine uyumlu).
- `plan-sabitleri.ts` için: her `plan_features.feature_key` değerinin karşılığı olduğunu doğrulayan bir unit test (bu, `sadakat_programi` sınıfı hataların bir daha sessizce oluşmasını engeller).
- `supabase db reset` sonrası local'de uçtan uca: ekip daveti/kampanya/şube ekleme/analitik aralığı limit senaryoları.
- `pnpm run test:ci`.

## Kapsam Dışı (bu turda yok)

- Ödeme sağlayıcı entegrasyonu / self-service checkout.
- CRM'in kampanya-dışı özelliklerinin gate'lenmesi.
- Envanter/stok, operasyonel personel app (kodda yok).
- `/sahip/premium` ↔ `/sahip/ayarlar/plan` birleştirmesi (kasıtlı olarak yapılmıyor — farklı amaçlar).
- "Kurumsal" kademesi.
