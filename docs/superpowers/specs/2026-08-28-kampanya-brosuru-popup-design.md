# Kampanya Broşürü Popup — Tasarım Dokümanı

## Bağlam

İşletme detay sayfasının (`/isletme/[slug]`) Kampanyalar sekmesi (`KampanyalarIcerik` / `KampanyaKartiDetay`, `uygulamalar/web/app/(genel)/isletme/[slug]/isletme-detay-tablari.tsx`) şu anda sadece düz, tıklanamayan metin kartları gösteriyor (rozet + başlık + açıklama). Kart hiçbir görsel içermiyor ve tıklama davranışı yok.

Buna karşın `public.campaigns` tablosunda bir `image_url` kolonu **zaten var** (`supabase/migrations/20260710000002_campaigns.sql`), kampanya okuma/yazma RPC'leri bu alanı zaten döndürüp/kabul ediyor, ve genel `/kampanyalar` keşif sayfası (`kampanyalar-canli.tsx`) bu alanı zaten render ediyor. Eksik olan tek şey:
1. Sahip panelindeki kampanya formunun (`kampanya-formu.tsx`) bu alanı hiç sunmaması — görsel hiçbir zaman set edilemiyor.
2. İşletme detay sayfasındaki kartın bu alanı hiç göstermemesi ve tıklanabilir olmaması.

Bu doküman, sahibin kampanya için bir görsel ("broşür/afiş") yükleyebilmesini ve ziyaretçinin bu görseli işletme detay sayfasında bir popup'ta büyük halde görebilmesini tasarlar.

## Kapsam

- **Dahil:** Sahip panelinde kampanya oluşturma/düzenleme formuna opsiyonel görsel yükleme; işletme detay sayfası Kampanyalar sekmesinde kart → tıklanabilir → popup (görsel + başlık + açıklama + rozet + bitiş tarihi).
- **Dahil değil (kullanıcı onayı ile kapsam dışı bırakıldı):**
  - Kampanya başına birden fazla görsel/galeri — tek görsel yeterli, mevcut `image_url` kolonu tek string.
  - Popup açılma/tıklama analytics'i (`click_count` artırma) — kolon zaten var ama şu an hiçbir yerden artırılmıyor; ayrı, küçük bir iş olarak sonra eklenebilir.
  - Genel `/kampanyalar` keşif sayfasında aynı popup davranışı — o sayfa şu anki "Fırsatı Gör →" linkiyle kalır, değişmez.
- Görsel **opsiyonel**: yüklenmezse kampanya yine oluşturulup aktif edilebilir (geriye dönük uyumlu — bugünkü tüm kampanyalar zaten görselsiz).

## Veri Modeli

Değişiklik yok. `public.campaigns.image_url` kolonu ve ilgili RPC parametreleri (`p_image_url`) zaten mevcut ve kullanılabilir durumda.

İstemci tarafı tip güncellemeleri (yeni alan eklenmiyor, sadece eksik olan `image_url` alanı tiplere ekleniyor):
- `Kampanya` interface (`kampanya-formu.tsx`): `image_url: string | null` eklenir.
- `KampanyaBilgi` type (`isletme-detay-tablari.tsx`): zaten `imageUrl: string | null` alanına sahip (kullanılmıyor, artık kullanılacak).

## Sahip Paneli — Görsel Yükleme

`kampanya-formu.tsx`'e, işletme profili düzenlemedeki logo/kapak yükleme akışıyla (`isletme-gorselleri-editoru.tsx` → `BrandingEditor`) aynı desende bir alan eklenir:

1. Sahip dosya seçer → istemci tarafında `compressToWebP` ile sıkıştırılır (kampanya afişleri için mantıklı bir üst sınır, örn. maxPx 1600 — logodan büyük, kapaktan biraz daha küçük tutulabilir).
2. `/sunucu/medya/yukleme` route'undaki `type` enum'una (`uygulamalar/web/app/sunucu/medya/yukleme/route.ts`, şu an `['logo', 'cover', 'background', 'item']`) yeni bir `'campaign'` değeri eklenir. Bu route zaten dosya boyutu/mime-type/rate-limit/sahiplik kontrolünü yapıyor — sadece yeni tip için storage path/limit kuralı eklenmesi yeterli.
3. Yüklenen URL, `kampanyaKaydet` server action'ına (`kampanya-islemleri.ts`) forma eklenen gizli/görünür bir `image_url` alanı üzerinden geçirilir; RPC çağrısına bu alan eklenir (RPC zaten kabul ediyor, sadece client'tan hiç gönderilmiyordu).
4. Formda önizleme: mevcut görsel varsa küçük bir thumbnail + "Değiştir"/"Kaldır" aksiyonları (branding editöründeki kapak alanına benzer, ama form içi bir alan olarak — ayrı bir sayfa değil).

Yükleme başarısız olursa (`rate_limited`, `file_too_large`, `invalid_mime_type` vb.) aynı hata mesajı sözlüğü (`BrandingEditor`'daki gibi) kullanılır — tekrar metin yazmaya gerek yok.

## İşletme Detay Sayfası — Kampanyalar Sekmesi

`KampanyaKartiDetay` bileşeni (`isletme-detay-tablari.tsx`):

- **Kart:** Görseli olan kampanyalarda kartın üstünde küçük bir görsel şeridi (mevcut `KampanyaKarti` — genel `/kampanyalar` sayfasındaki kart — ile görsel tarzı tutarlı: `buildMenuImageUrl`, `aspectRatio: 16/10`, rozet sol üstte overlay). Görseli olmayan kampanyalarda görsel alanı hiç render edilmez, kart bugünkü düz haliyle kalır.
- **Tıklama:** Kart artık `<button>`/tıklanabilir hale gelir (tüm kampanyalar için — görselli/görselsiz fark etmez, tutarlı davranış). Tıklayınca state ile seçili kampanya set edilir ve popup açılır.
- **Popup:** `kampanya-formu.tsx`'teki mevcut modal deseniyle aynı iskelet (backdrop + `fixed inset-0` + ortalanmış/bottom-sheet kart, `onClick` backdrop'ta kapatma, `Escape` ile kapatma eklenir — mevcut formda yok, burada eklenecek çünkü bu tamamen bilgilendirici bir görüntüleme, form değil):
  - Görseli olan kampanyalarda: üstte büyük görsel (tam genişlik, `aspectRatio` korunur), altında başlık + rozet + açıklama + bitiş tarihi.
  - Görseli olmayan kampanyalarda: aynı popup iskeleti, görsel alanı yerine rozet + başlık + açıklama daha büyük punto ile ortalanmış gösterilir (kartın büyütülmüş hali gibi).
  - Kapatma: sağ üstte X butonu (mevcut `CloseIcon` deseni), backdrop tıklaması, Escape tuşu.
  - Yeni bir modal kütüphanesi eklenmiyor — projede zaten kullanılan native `fixed`+backdrop deseni tekrar kullanılıyor.

## Test / Doğrulama

- `pnpm run typecheck` + `pnpm run lint` (CLAUDE.md minimum doğrulama tablosu — Web değişikliği).
- Manuel doğrulama: sahip panelinde bir kampanyaya görsel yükleyip kaydet → işletme detay sayfasında kartta thumbnail görünmeli → tıklayınca popup açılmalı → görsel büyük halde görünmeli → kapatma (X, backdrop, Escape) çalışmalı. Görselsiz eski bir kampanyada da tıklama/popup çalışmalı (metin büyütülmüş halde).
- `/sunucu/medya/yukleme` route'una eklenen `'campaign'` tipinin mevcut mime/size/rate-limit testleriyle çakışmadığından emin olunmalı (varsa `test/` altındaki ilgili route testi güncellenir).
