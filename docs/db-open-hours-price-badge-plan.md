# DB Plan: Açık/Kapalı, Yoğun Saat ve Fiyat Seviyesi Rozeti

> Hazırlanma: 2026-06-03
> Durum: Planlama — migration henüz yazılmadı
> Yazar: postgres-pro analizi

---

## 1. Mevcut Durum

### 1.1 business_hours (eski, wide format)

`base_schema.sql` satır 22305'te tanımlı:

```
business_hours
  business_id   uuid  PK (unique constraint implied by upsert onConflict)
  mon_open / mon_close  time
  tue_open / tue_close  time
  wed_open / wed_close  time
  thu_open / thu_close  time
  fri_open / fri_close  time
  sat_open / sat_close  time
  sun_open / sun_close  time
  updated_at    timestamptz
```

- Timezone bilgisi saklanmıyor — sütunlar `time without time zone`
- `is_closed` flag yok — NULL open/close ile kapalı ifade ediliyor
- Özel gün (bayram, tatil) desteği yok
- RLS: SELECT anon+authenticated USING (true); INSERT/UPDATE owner/admin

Owner web paneli bu tabloyu doğrudan `from('business_hours').upsert()` ile yazıyor.
`pazar-okuma.ts` getBusinessHoursRows() bu tablodan okuyarak `{label, value, active}` satırları üretiyor — açık/kapalı hesaplaması client tarafında `new Date().getDay()` ile yapılıyor.

### 1.2 business_weekly_hours + business_special_hours (yeni, 20260424)

Migration `20260424000001_business_hours.sql`:

```
business_weekly_hours
  id            uuid  PK
  business_id   uuid  FK → businesses
  day_of_week   smallint  0=Pazar..6=Cumartesi  UNIQUE(business_id, day_of_week)
  open_time     time  (timezone yok)
  close_time    time  (timezone yok)
  is_closed     bool  DEFAULT false
  created_at / updated_at  timestamptz

business_special_hours
  id            uuid  PK
  business_id   uuid  FK → businesses
  special_date  date
  open_time     time  (null = tüm gün kapalı)
  close_time    time
  is_closed     bool  DEFAULT true
  note          text
  created_at    timestamptz
  UNIQUE(business_id, special_date)
```

- Timezone yine yok; `open_time/close_time` `time without timezone`
- RLS: SELECT anon+authenticated USING (true) — halka açık okuma mevcut
- Index: `business_weekly_hours_business_id_idx` ve `business_special_hours_business_date_idx` mevcut
- Composite `(business_id, day_of_week)` index örtülü olarak UNIQUE constraint'ten geliyor

`get_business_hours_v1` RPC sunucu tarafında açık/kapalı hesaplayabiliyor:
```sql
current_timestamp AT TIME ZONE 'Europe/Istanbul'
```
RPC `is_open_now` bool döndürüyor; special days öncelikli.

### 1.3 İkili Tablo Durumu (Kritik Bulgu)

Sistemde iki çakışan tablo yapısı var:

| | business_hours | business_weekly_hours |
|---|---|---|
| Format | Wide (1 satır/işletme) | Normalized (7 satır/işletme) |
| Special days | Yok | business_special_hours ile |
| is_closed flag | Yok (NULL=kapalı) | Var |
| RLS | Mevcut | Mevcut |
| Caller (web) | saveHours() action, getBusinessHoursRows() | get_business_hours_v1 RPC |
| is_open_now | Client tarafı (JS Date) | Server tarafı (PG timezone) |

Owner panel saatleri `business_hours` (eski)'e yazıyor.
Menü sayfası `get_business_hours_v1` ile `business_weekly_hours`'u okuyor.
İkisi arasında senkronizasyon yok.

### 1.4 Analytics / Log

- `analytics_events` tablosu mevcut (base_schema 22200):
  - `event_name text`, `business_id uuid`, `menu_id uuid`, `source text`, `client_id text`, `user_id uuid`, `meta jsonb`, `created_at timestamptz`
  - Desteklenen event'ler: `menu_shared`, `qr_scanned`, `menu_link_opened`, `app_install_from_menu`, `business_reservation_click`, `business_phone_click`, `business_whatsapp_click`, `business_order_click`, `business_directions_click`, `business_page_view`, `menu_view`, `discovery_impression`, `discovery_business_click`, `business_impression`, `price_suggestion_submitted`
  - `log_event_v1` RPC ile yazılıyor; `anon` + `authenticated` + `service_role` GRANT'lı
- `table_orders` tablosu mevcut (20260507000006):
  - `created_at timestamptz`, `seen_at timestamptz`, `done_at timestamptz`
  - `business_id`, `table_number`, `status` (pending/seen/done)
  - Bu tablo sipariş zaman damgası içeriyor — yoğun saat analizi için kullanılabilir
- `owner_analytics_hourly_v1` (20260414000008): `analytics_events` üzerinden saatlik agregasyon yapıyor — yoğun saat altyapısı kısmen mevcut

### 1.5 Fiyat Verisi

- `menu_items.price_cents integer DEFAULT 0` — mevcut
- `menu_item_price_history` tablosu mevcut — historik fiyat kayıtları
- `business_price_index_v1` VIEW (remote_schema 5001): weighted median hesaplaması; verified fiyatlara 2x ağırlık veriyor
- `regional_price_index` VIEW'ı web tarafından `enrichBusinessCards()` içinde kullanılıyor (priceByBusiness map)
- `get_regional_price_index_v2` RPC — category + city/district bazlı medyan
- `get_category_price_benchmark_v1` RPC (20260421000003) — item name + city bazlı avg/min/max
- `medianPriceCents` BusinessCardModel'de mevcut; web `isletme-karti.tsx`'de `priceLevelLabel()` fonksiyonu var (sabit eşikler: <5000=₺, <15000=₺₺, ≥15000=₺₺₺)

---

## 2. Açık/Kapalı Hesaplama Mimarisi

### 2.1 Mevcut İki Yol (Sorun)

**Yol A — `getBusinessHoursRows()` (pazar-okuma.ts):**
- `business_hours` tablosundan direct SELECT
- Client JS'de `new Date().getDay()` ile today tespiti
- Timezone: sunucunun locale'ine göre değişebilir (hatalı)
- `is_open_now` hesaplaması yok — sadece görüntü amaçlı liste

**Yol B — `get_business_hours_v1` RPC:**
- `business_weekly_hours` + `business_special_hours` okuyor
- Sunucu tarafında `AT TIME ZONE 'Europe/Istanbul'` hesaplaması
- `is_open_now bool` döndürüyor — doğru yol

### 2.2 Öneri: Server Tarafı Kazanır

Açık/kapalı hesaplaması PostgreSQL sunucu tarafında kalmalı. Gerekçeler:

1. Türkiye tek timezone'da (Europe/Istanbul, UTC+3). DST (yaz saati) 2016'dan beri uygulanmıyor — saat farkı sabittir. `pg_timezone_names WHERE name = 'Europe/Istanbul'` bunu doğrular.
2. Client tarafı `new Date()` sunucu konumuna veya kullanıcı timezone ayarına göre kayabilir
3. `get_business_hours_v1` zaten `is_open_now` döndürüyor — kullanılmalı

### 2.3 Timezone Stratejisi

```
Europe/Istanbul = UTC+3 sabit (DST yok)
current_timestamp AT TIME ZONE 'Europe/Istanbul' — doğru hesaplama
```

`open_time`/`close_time` sütunları `time without timezone` olarak tutulabilir çünkü Türkiye tek timezone'da. Çok ülkeli genişleme planı varsa ilerleyen sürümde `businesses.timezone text DEFAULT 'Europe/Istanbul'` sütunu eklenebilir; şimdilik sabit.

### 2.4 Mevcut RPC Durumu

`get_business_hours_v1` zaten tamamlanmış ve doğru:
- `is_open_now` server-side hesaplanıyor
- Special days öncelikli
- `weekly` + `special` array döndürüyor
- `anon` + `authenticated` GRANT mevcut

Yeni bir `get_business_hours_status_v1` yazmaya gerek yok — mevcut RPC yeterli.

---

## 3. Yoğun Saat Modeli

### 3.1 Mevcut Veri Yeterliliği

| Kaynak | Kolon | Yoğun Saat İçin Uygunluk |
|---|---|---|
| `table_orders.created_at` | timestamptz | Yüksek — gerçek sipariş verisi |
| `analytics_events.created_at` + `event_name='menu_view'` | timestamptz | Yüksek — sayfa görüntüleme |
| `analytics_events` `qr_scanned` | timestamptz | Orta — QR tarama zamanı |
| `visits.checked_in_at` | timestamptz | Orta — check-in verisi |

`owner_analytics_hourly_v1` saatlik analytics agregasyonu zaten yapıyor (son 24-72 saat, `analytics_events` üzerinden). Bu RPC yoğun saat tespiti için temel alınabilir.

### 3.2 Yeni Tablo Gerekmez (Kısa Vadede)

Mevcut tablolar yeterli:
- `analytics_events` sayfa trafiği için
- `table_orders` sipariş yoğunluğu için

### 3.3 Öneri: Saatlik Agregasyon View

Yeni tablo yerine mevcut `analytics_events` üzerinde on-demand hesaplayan bir RPC:

```sql
-- Taslak imza
get_business_busy_hours_v1(p_business_id uuid, p_days_back integer DEFAULT 28)
RETURNS TABLE(hour_of_day smallint, avg_event_count numeric, peak_rank smallint)
```

28 günlük geçmiş veriden her saat diliminin ortalama event sayısı hesaplanır.
`table_orders` varsa ek ağırlık verilebilir (sipariş 3x, menu_view 1x).

Orta vadede (veri hacmi büyüdüğünde) `business_busy_hours_cache` materialized tablosu veya pg_cron ile günlük yenilenen snapshot değerlendirilebilir.

---

## 4. Fiyat Seviyesi Rozeti

### 4.1 Mevcut Durum

**Web `isletme-karti.tsx` sabit eşik mantığı (istemci tarafı):**
```typescript
function priceLevelLabel(cents: number): string {
  if (cents < 5000) return '₺';      // < 50 TL
  if (cents < 15000) return '₺₺';   // 50-150 TL
  return '₺₺₺';                     // > 150 TL
}
```

**Web `kesif.tsx` farklı eşikler:**
```typescript
function priceLevel(cents?: number | null) {
  if (!cents) return '₺';
  if (cents < 15000) return '₺';
  if (cents < 35000) return '₺₺';
  // else ₺₺₺
}
```

İki farklı dosyada iki farklı eşik — tutarsızlık mevcut.

**Veri kaynağı:** `regional_price_index` VIEW → `business_price_index_v1` VIEW → `menu_item_price_history` + `menu_items.price_cents` (weighted median).

### 4.2 Sorun: Mutlak Eşikler Enflasyona Karşı Kırılgan

150 TL eşiği bugün "orta" iken 6 ay sonra "ekonomik" olabilir. Percentile tabanlı dinamik hesaplama daha sağlıklı.

### 4.3 Önerilen Rozet Mantığı

**Percentile tabanlı city+category bazlı:**

```
Ekonomik (₺)   — median_price_cents <= p33 (şehir+kategori içinde)
Orta    (₺₺)   — p33 < median_price_cents <= p66
Premium (₺₺₺)  — median_price_cents > p66
```

Hesaplama yeri seçenekleri:

| Yaklaşım | Avantaj | Dezavantaj |
|---|---|---|
| RPC (anlık) | Her zaman güncel | Her listede query maliyeti |
| businesses sütunu (price_level text) | Sıfır query maliyeti | Periyodik güncelleme gerekir |
| Materialized view | Denge | pg_cron veya trigger gerekir |

**Öneri: `businesses.price_level text` sütunu + periyodik güncelleme**

Sütun değerleri: `'budget'`, `'mid'`, `'premium'`, `NULL` (yeterli veri yok).
Güncelleme: `analytics_events` temizleme veya gece yarısı pg_cron job ile.

Alternatif (daha basit, kısa vade): RPC `get_business_price_level_v1(p_business_id)` — city+category içindeki percentile hesaplaması döndürür, web/mobile bu değeri cache'ler.

### 4.4 Önerilen Rozetler

| Seviye | Sembol | Kritik Kriter |
|---|---|---|
| Ekonomik | ₺ | median_price_cents <= p33(şehir+kategori) |
| Orta | ₺₺ | p33 < median <= p66 |
| Premium | ₺₺₺ | median > p66 |
| Bilinmiyor | (gizli) | menu_item sayısı < 3 veya price_cents = 0 |

---

## 5. Yeni Tablo / Migration Gereksinimleri

### 5.1 Zorunlu: İkili Tablo Senkronizasyonu

**En büyük mevcut sorun:** Owner panel saatleri `business_hours` (eski wide format)'a yazıyor; menü sayfası `business_weekly_hours` (yeni normalize)'u okuyor. İki tablo arasında köprü yok.

Çözüm seçenekleri:
- A) Owner panel action'larını `upsert_business_hours_v1` RPC'ye geçir (önerilen)
- B) `business_hours`'a trigger ekle → `business_weekly_hours`'u senkronize et
- C) `get_business_hours_v1`'ı fallback olarak `business_hours`'u da okuyacak şekilde genişlet

**Önerilen yaklaşım A** — en temiz çözüm, gereksiz tablo duplikasyonunu önler.

### 5.2 Mevcut Tablolarda Eksik Sütunlar

**`businesses` tablosuna eklenecek:**
```sql
price_level text CHECK (price_level IN ('budget', 'mid', 'premium')) DEFAULT NULL
```

**`analytics_events` tablosuna eklenecek (isteğe bağlı):**
```sql
hour_of_day smallint GENERATED ALWAYS AS
  (EXTRACT(HOUR FROM created_at AT TIME ZONE 'Europe/Istanbul')::smallint) STORED
```
Bu hesaplanan sütun, yoğun saat sorgularında `EXTRACT` çağrısını index'lenebilir hale getirir.

### 5.3 Yeni Tablo Gereksinimleri

Kısa vadede yeni tablo gerekmez. Orta vadede veri hacmi artarsa:

```sql
-- Opsiyonel: saatlik busy_hours cache
business_busy_hours_cache
  business_id   uuid
  hour_of_day   smallint  (0-23, Istanbul saati)
  avg_events    numeric
  updated_at    timestamptz
  PRIMARY KEY (business_id, hour_of_day)
```

---

## 6. Migration Branch Planı

Sıralı migration'lar, bağımsız ve güvenli olarak uygulanabilir:

| Adım | Migration Adı | İçerik | Öncelik |
|---|---|---|---|
| 1 | `YYYYMMDD_sync_hours_tables.sql` | `business_weekly_hours` için owner panel RPC geçişi veya trigger köprüsü; `business_hours` legacy tablosu için DEPRECATED comment | Yüksek |
| 2 | `YYYYMMDD_price_level_column.sql` | `businesses.price_level text` sütunu + CHECK constraint + index | Orta |
| 3 | `YYYYMMDD_price_level_rpc.sql` | `compute_business_price_level_v1(p_business_id)` — percentile hesabı; ilk çalışma için batch güncelleme SQL | Orta |
| 4 | `YYYYMMDD_busy_hours_rpc.sql` | `get_business_busy_hours_v1(p_business_id, p_days_back)` — analytics_events + table_orders bazlı saatlik ağırlıklı ortalama | Düşük |
| 5 | `YYYYMMDD_analytics_hour_index.sql` | `analytics_events(business_id, created_at)` composite index — yoğun saat sorgularını hızlandırır (mevcut index var mı kontrol et) | Düşük |

**Migration 1 detayı (en kritik):**
```sql
-- Option A: owner web action'larını RPC'ye yönlendir (kod değişikliği)
-- Option B: trigger
CREATE OR REPLACE FUNCTION tg_sync_business_hours_to_weekly()
RETURNS trigger LANGUAGE plpgsql AS $$
DECLARE
  _map jsonb := '[
    {"day":1,"open":"mon_open","close":"mon_close"},
    {"day":2,"open":"tue_open","close":"tue_close"},
    -- ...
  ]'::jsonb;
  _entry jsonb;
BEGIN
  FOR _entry IN SELECT * FROM jsonb_array_elements(_map) LOOP
    INSERT INTO public.business_weekly_hours
      (business_id, day_of_week, open_time, close_time, is_closed)
    VALUES (
      NEW.business_id,
      (_entry->>'day')::smallint,
      (NEW::jsonb->>(_entry->>'open'))::time,
      (NEW::jsonb->>(_entry->>'close'))::time,
      (NEW::jsonb->>(_entry->>'open')) IS NULL
    )
    ON CONFLICT (business_id, day_of_week) DO UPDATE SET
      open_time  = EXCLUDED.open_time,
      close_time = EXCLUDED.close_time,
      is_closed  = EXCLUDED.is_closed,
      updated_at = now();
  END LOOP;
  RETURN NEW;
END;
$$;
```
Not: Trigger yolu çalışır ancak ileride legacy tabloyu kaldırırken ek iş çıkarır. RPC geçişi daha temiz.

---

## 7. Etkilenen Caller'lar

### 7.1 Web

| Dosya | Mevcut Durum | Gerekli Değişiklik |
|---|---|---|
| `app/owner/settings/hours/actions.ts` | `business_hours` direkt yazma | `upsert_business_hours_v1` RPC'ye geç |
| `app/sahip/ayarlar/saatler/saat-islemleri.ts` | Aynı — Türkçe route alias | Aynı |
| `src/lib/veri/pazar-okuma.ts` → `getBusinessHoursRows()` | `business_hours` direkt okuma | `get_business_hours_v1` RPC'ye geç; `is_open_now` zaten orada |
| `src/lib/veri/pazar-okuma.ts` → `enrichBusinessCards()` | `regional_price_index` VIEW okuma | `businesses.price_level` sütunu eklenince o da kullanılabilir |
| `src/ui/bilesenler/isletme-karti.tsx` | Sabit eşik `priceLevelLabel()` | Percentile bazlı rozet gelince güncelle; veya sütun değerini doğrudan kullan |
| `src/ui/acik/kesif.tsx` | Farklı sabit eşikler `priceLevel()` | `isletme-karti.tsx` ile birleştir |

### 7.2 Mobile

| Dosya | Mevcut Durum | Gerekli Değişiklik |
|---|---|---|
| `discovery/domain/business_card.dart` | `is_open_now: m['is_open_now']` okuma | RPC zaten bu alanı döndürüyor — değişiklik yok |
| `business/ui/sections/business_detail_sections.dart` | Saatler görüntüleme | `get_business_hours_v1` RPC entegrasyonu kontrol edilmeli |
| `discovery/data/search_repository.dart` | `search_nearby_businesses_v3` çağrısı | `is_open_now` alanını döndürüyor mu kontrol et |

### 7.3 Personel

Personel uygulamasında `business_hours` veya `is_open_now` kullanımı tespit edilmedi.

---

## 8. RLS ve Güvenlik

### 8.1 business_hours (eski)

- SELECT: `anon + authenticated` — USING (true) — açık
- INSERT: owner/admin — WITH CHECK
- UPDATE: owner/admin — USING + WITH CHECK

### 8.2 business_weekly_hours / business_special_hours

- SELECT: `anon + authenticated` — USING (true) — açık
- Tüm write: owner (business_claims tablosundan kontrol) — doğru

### 8.3 Yeni Sütun (businesses.price_level)

`businesses` tablosunun mevcut RLS'i incelenmeli. `price_level` sistem tarafından hesaplanacağından:
- Doğrudan kullanıcı yazmasına izin verilmemeli
- SECURITY DEFINER RPC ile güncellenecek
- `businesses` tablosuna yazma policy'si zaten sadece owner/admin'e açık

### 8.4 analytics_events Okuma

Yoğun saat RPC için `analytics_events` okuma gerekli. Bu tablo şu anda RLS'e sahip; `get_business_busy_hours_v1` SECURITY DEFINER olacak ve yalnızca aggregated (sayısal) veri döndürecek — bireysel event verisi expose edilmeyecek.

---

## 9. Index Planı

### 9.1 Mevcut Mevcut Index'ler (İlgili)

- `business_weekly_hours_business_id_idx` (business_id) — mevcut
- UNIQUE(business_id, day_of_week) — composite index sağlar
- `business_special_hours_business_date_idx` (business_id, special_date) — mevcut
- `idx_businesses_is_active_partial` (id) WHERE is_active=true — 20260523000004'te eklendi
- `idx_businesses_active_city_category` (city, category) WHERE is_active=true — mevcut

### 9.2 Eksik / Planlanan Index'ler

```sql
-- 1. businesses.price_level üzerinde partial index
-- Fiyat seviyesi rozet filtresi için
CREATE INDEX IF NOT EXISTS idx_businesses_price_level
  ON public.businesses (price_level)
  WHERE is_active = true AND price_level IS NOT NULL;

-- 2. analytics_events(business_id, created_at) composite
-- Yoğun saat RPC'si için — mevcut olup olmadığı kontrol edilmeli
CREATE INDEX IF NOT EXISTS idx_analytics_events_biz_created
  ON public.analytics_events (business_id, created_at DESC);

-- 3. analytics_events(event_name, business_id, created_at) partial
-- Spesifik event tiplerini business bazında hızlı çekmek için
CREATE INDEX IF NOT EXISTS idx_analytics_events_name_biz_created
  ON public.analytics_events (event_name, business_id, created_at DESC)
  WHERE event_name IN ('menu_view', 'qr_scanned', 'business_page_view');
```

---

## 10. Uygulama Öncelik Sırası

**P0 — Veri Tutarsızlığı Düzelt (Kritik)**
1. Owner panel saatleri: `actions.ts` / `saat-islemleri.ts` → `upsert_business_hours_v1` RPC'ye geç
2. `getBusinessHoursRows()` → `get_business_hours_v1` RPC'ye geç; `is_open_now` zaten mevcut
3. İki ayrı `priceLevel` eşiklerini (`isletme-karti.tsx` vs `kesif.tsx`) tek yerde birleştir

**P1 — Index Tamamlama**
4. `analytics_events(business_id, created_at)` composite index ekle
5. Analytics_events partial index for `menu_view/qr_scanned/business_page_view`

**P2 — Fiyat Seviyesi Rozeti**
6. `businesses.price_level text` sütunu ekle (migration)
7. `compute_business_price_level_v1` RPC yaz (percentile bazlı, city+category)
8. Web `BusinessTile` ve mobile `BusinessCardModel`'i sütun değerini okuyacak şekilde güncelle

**P3 — Yoğun Saat**
9. `get_business_busy_hours_v1` RPC yaz (`analytics_events` + `table_orders` birleştirme)
10. Owner dashboard'a saatlik yoğunluk grafiği ekle (mevcut hourly analytics'in yanında)

---

## 11. Açık Sorular

1. **Legacy `business_hours` tablosu ne zaman kaldırılacak?** Trigger köprüsü geçici mi, kalıcı mı? Owner panel RPC geçişi yapılırsa trigger gereksiz.

2. **`businesses.price_level` ne sıklıkla güncellenmeli?** Seçenekler: (a) gece yarısı pg_cron, (b) `menu_item_price_history` INSERT trigger'ı, (c) owner tarafından tetiklenen batch. Fiyat değişimleri sık değilse günlük pg_cron yeterli.

3. **`hour_of_day` generated sütun `analytics_events`'e eklemek performans avantajı sağlar mı?** 20260523000004 migration'ında `analytics_events` için hangi index'ler eklendiği kontrol edilmeli.

4. **`search_nearby_businesses_v3` RPC `is_open_now` döndürüyor mu?** Mobile discovery'de `BusinessCardModel.isOpenNow` alanı var ama RPC response kontrol edilmedi.
