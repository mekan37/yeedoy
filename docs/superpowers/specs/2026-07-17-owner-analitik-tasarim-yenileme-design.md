# Owner Analitik Sayfası — Görsel Tasarım Yenilemesi

## Arka plan

Kullanıcı, `owner/(panel)/analytics` sayfası için bir mockup görseli
(ChatGPT ile üretilmiş, `docs/design-previews/analitik-mockup-2026-07-16.png`
olarak referans alınıyor — dosya kullanıcının Downloads klasöründe) paylaştı
ve bu görselin **görsel/yapısal tasarımının** mevcut koda uygulanmasını
istedi. Mockup'taki bazı metrikler (`Ziyaretçi Demografisi`, `Ortalama
görüntülenme süresi`) üretim ortamında hiç izlenmiyor; kullanıcının açık
talimatı: mockup'ın *tasarımını* benimse, veri karşılığı olmayan metrikleri
elimizdeki gerçek verilerle karşıla — hiçbir alanda uydurma/mock veri
gösterilmeyecek.

Kapsam **sadece** şu an gerçekten linklenen `app/owner/(panel)/analytics/`
(page.tsx + analytics-client.tsx) ile sınırlıdır. Ayrı bir `app/sahip/analitik`
ağacı da var (Türkçeleştirme fazı bekliyor, `docs/superpowers/plans/2026-07-13-owner-panel-turkification-plan.md`)
ama bu proje o birleştirmeye dokunmaz; oradaki `get_business_busy_hours_v1`
RPC'si sadece saat-of-day (0-23, tek boyut) döndürüyor, ihtiyaç duyduğumuz
gün×saat kırılımını karşılamıyor, o yüzden yeni aggregation `owner/analytics/page.tsx`
içinde mevcut ham event sorgusu (`rawEvents`) üzerinden yapılacak.

## Veri envanteri (doğrulanmış)

Gerçek, üretimde çalışan event/tablo kaynakları:

| Metrik | Kaynak |
|---|---|
| Görüntülenme | `analytics_events.event_name in (menu_view, business_impression, menu_link_opened, business_page_view)` — mevcut `VIEW_EVENTS` |
| Profil Ziyaretleri | `analytics_events.event_name = business_page_view` |
| Telefon Aramaları | `analytics_events.event_name = business_phone_click` |
| Yol Tarifi İstekleri | `analytics_events.event_name = business_directions_click` (şu an `page.tsx`'te `directions={0}` hardcoded — bug, gerçek sorguyla değişecek) |
| Favorilere Ekleme | `favorites` tablosu (mevcut) |
| Yorum | `business_reviews` (status=approved) — KPI satırından ve ısı haritasından tamamen kalkıyor (Yorumlar sayfasında zaten görünür) |
| Arama Görünümü | `discovery_impression`, `business_impression` — KPI satırından ve ısı haritasından tamamen kalkıyor, bu sayfada kapsam dışı |
| QR Kod Tarama | `analytics_events.event_name = qr_scanned` |
| Menü Paylaşımı | `analytics_events.event_name = menu_shared` |
| Rezervasyon | `reservations` tablosu (`20260711000001_reservations.sql`, status kolonu: pending/confirmed/cancelled/completed vb.) |

Karşılığı **olmayan** ve bu nedenle tasarımdan çıkarılan/değiştirilen:
- Yaş/cinsiyet demografisi — hiçbir tabloda yok
- Görüntülenme süresi (session duration) — hiç izlenmiyor
- "Web Sitesi Tıklama" — ayrı bir tracked event yok

## Tasarım — bölüm bölüm

### 1. KPI satırı (5 kart)

Mockup'taki 5 kartla birebir aynı metrik seti, gerçek veriyle:
Görüntülenme (mavi ikon/bg) · Profil Ziyaretleri (mor) · Telefon Aramaları
(yeşil) · Yol Tarifi İstekleri (turuncu) · Favorilere Ekleme (pembe).

- `KpiCard` bileşenine `iconBg`/`iconColor` prop eklenir (şu an sabit
  `bg-[#fef2f2] text-[#dc2626]`), her kart kendi rengini geçer.
- Üst/alt yüzde değişim rozeti (yeşil ↑ / kırmızı ↓) davranışı aynen kalır.
- `AnalyticsClientProps`'tan `reviews`/`reviewsPrev`/`searches`/`searchesPrev`
  KPI satırından tamamen kalkar. Bölüm 5'te açıklandığı gibi eski
  "Günlere Göre Performans" (metrik×gün) tablosu da tamamen kaldırıldığı
  için bu iki metrik artık hiçbir grafikte gösterilmez — Yorum sayısı zaten
  Yorumlar sayfasında görünür durumda, Arama/keşif metriği bu sayfada
  kapsam dışına çıkar. Yerine `profileVisits`/`profileVisitsPrev`,
  `phoneCalls`/`phoneCallsPrev` eklenir. `directions`/`directionsPrev`
  artık gerçek sorgudan gelir.

### 2. Görüntülenme Grafiği (line chart)

Değişmiyor. Mockup'taki kart-içi "Günlük ▾" dropdown'u eklenmeyecek —
sayfanın üstündeki global dönem seçici (7/30/90 gün) zaten aynı işi görüyor,
ikinci bir kontrol kafa karıştırır.

### 3. Trafik Kaynakları (donut)

- Donut'un ortasına mockup'taki gibi "Toplam" + sayı eklenir (SVG üstüne
  absolute-positioned `<div>` veya recharts `label` ile).
- Legend satırlarında yüzdenin yanına gerçek adet eklenir: `%46 · 5.741`.
  Bu, `page.tsx`'te zaten hesaplanan `count`'un `TrafficSource` tipine
  eklenmesini gerektirir (`{ name, value, color, count }`).

### 4. Rezervasyon Durumu (Demografi kartının yerine)

Aynı grid slotunda (satır 3, sol sütun): `reservations` tablosundan
`status` bazlı dağılım — Onaylandı / Bekliyor / İptal Edildi / Tamamlandı —
donut + liste, `DonutCard`'a benzer bir bileşenle (`ReservationStatusCard`).
İşletme rezervasyon kabul etmiyorsa veya hiç kayıt yoksa mevcut
`NoDataIcon` + "Henüz veri yok" pattern'i kullanılır.

### 5. Popüler Saatler (birleşik ısı haritası)

Mevcut iki ayrı bileşen — "Günlere Göre Performans" (metrik×gün tablosu)
ve "Popüler Saatler" (saatlik bar chart) — **kaldırılıp** tek bir gün×saat
ısı haritasıyla değiştirilir:

- Satırlar: 6 saat bloğu (`00:00, 04:00, 08:00, 12:00, 16:00, 20:00` —
  her biri 4 saatlik pencereyi temsil eder)
- Sütunlar: `Pzt Sal Çar Per Cum Cmt Paz` (mevcut `DOW_ORDER` korunur)
- Hücre değeri: o gün×saat-bloğu için `VIEW_EVENTS` sayımı; renk yoğunluğu
  mevcut `heatColor()` fonksiyonuyla (0-100 normalize) belirlenir
- Veri kaynağı: `page.tsx`'teki mevcut `currRaw` (zaten çekilen ham event
  listesi) üzerinden `[dow][hourBucket]` şeklinde yeni bir 7×6 aggregation;
  ekstra sorgu gerekmez.
- Alt kısımdaki Az→Çok renk skalası legend'ı korunur.
- Bu blok, satır 3'ün orta/geniş sütununda yer alır (aşağıya bkz).

### 6. Eylemler listesi (yeni bölüm)

Satır 3'ün sağ sütununda, mockup'takine benzer liste formatı: her satırda
solda renkli ikon kutusu, ortada etiket, sağda sayı + yüzde değişim rozeti.

- Menü Görüntüleme — `menu_view` sayımı
- QR Kod Tarama — `qr_scanned` sayımı
- Menü Paylaşımı — `menu_shared` sayımı
- Rezervasyon — `reservations` tablosu satır sayımı (dönem içinde
  oluşturulanlar)

Alt "Tüm Eylemleri Görüntüle" butonu, ürünün başka yerlerinde zaten
kullanılan disabled + "Yakında aktif olacak" tooltip pattern'iyle
(bkz. mevcut "Detaylı Raporu İndir" butonu) devre dışı bırakılır — ayrı bir
"tüm eylemler" sayfası bu kapsamda yok.

**Satır 3 grid düzeni:** `xl:grid-cols-3` — Rezervasyon Durumu | Popüler
Saatler (ısı haritası) | Eylemler. Küçük ekranlarda tek sütuna düşer
(mevcut breakpoint pattern'i, `AppTokens.bp` benzeri Tailwind karşılığı).

### 7. Performans Özeti (alt bar)

- "En iyi gün" — `dailyData`'daki en yüksek `current` değerine sahip gün
  (gerçek veri, yeni hesap)
- "En yoğun saat" — birleşik ısı haritasındaki en yüksek hücreden türetilen
  saat aralığı (örn. "16:00–20:00")
- "Ortalama görüntülenme süresi" satırı **kaldırılır** — session duration
  hiç izlenmiyor, uydurma veri gösterilmeyecek
- "Detaylı Raporu İndir" butonu mevcut disabled/"yakında" davranışını korur
  (export özelliği bu kapsamın dışında)
- Toplam etkileşim metni (`Performans Özeti` başlığı altı) aynen kalır

## Kapsam dışı

- `app/sahip/analitik` ağacına dokunulmaz (ayrı Türkçeleştirme fazı)
- Yeni bir "tüm eylemleri görüntüle" alt sayfası yazılmaz
- Rapor export/indirme özelliği implemente edilmez (buton disabled kalır)
- Demografi/duration için yeni tracking altyapısı eklenmez (kapsam dışı,
  ayrı bir proje olurdu)

## Test / doğrulama planı

- `npm run typecheck` + `npm run lint` (CLAUDE.md minimum doğrulama —
  Next.js değişikliği)
- Manuel: `npm run dev` ile `/owner/analytics` sayfası açılıp gerçek/boş
  veri durumları (rezervasyon yokken empty state, ısı haritası tüm sıfırken
  empty state) gözle doğrulanır
