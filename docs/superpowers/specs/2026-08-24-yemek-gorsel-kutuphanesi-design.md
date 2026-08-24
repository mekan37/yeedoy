# Yemek Görsel Kütüphanesi (Stok Görsel Sistemi) — Tasarım Dokümanı

## Bağlam

2026-08-24'te menü ürünleri için otomatik yemek görseli fallback sistemi kuruldu: 117 adet stok yemek fotoğrafı (`assets/menu-kategroi-varsayilan/`, 800x800 webp) Supabase Storage'a (`menu-media/varsayilan-yemekler/{klasor}/{slug}.webp`) yüklendi, ürün adı bu isim sözlüğüyle eşleşirse (kod içine gömülü statik liste — `uygulamalar/web/src/lib/menu/varsayilan-yemek-gorseli.ts` ve `uygulamalar/mobil/lib/features/menus/data/varsayilan_yemek_sozlugu.dart`) o fotoğraf gösteriliyor, eşleşme yoksa jenerik ikon/emoji fallback'ine düşülüyor.

Bu statik sistemin iki sınırlaması var:
1. Yeni bir yemek görseli eklemek kod değişikliği + web/mobil deploy gerektiriyor.
2. Sahip, ürün adı yazdığında eşleşen stok görseli görüp bilinçli seçemiyor — sadece görsel yüklemezse arka planda sessizce bir eşleşme uygulanıyor (ya da uygulanmıyor).

Bu doküman, statik sistemi DB-tabanlı, admin tarafından yönetilebilen bir kütüphaneye dönüştürmeyi ve sahip tarafına aktif bir "sistemden seç" akışı eklemeyi tasarlar.

## Kapsam

Tek bir birleşik özellik olarak ele alınıyor (kullanıcı onayı: "tek yapalım"):
- Admin paneline yeni bir "Görsel Kütüphanesi" sayfası (CRUD)
- Sahip panelindeki ürün görsel seçicisine yeni bir "Sistemden Seç" sekmesi (hem web hem mobil)
- Mevcut 117 statik görselin yeni DB tablosuna taşınması, statik kod sözlüklerinin kaldırılması

## Veri Modeli

Yeni tablo: `public.stock_dish_images`

| Kolon | Tip | Açıklama |
|---|---|---|
| `id` | uuid, pk | `gen_random_uuid()` |
| `image_url` | text, not null | Storage'daki tam public URL (mevcut `menu-media` bucket, dosyalar yeniden yüklenmez) |
| `keywords` | text[], not null, default `'{}'` | Admin'in girdiği serbest metin eşleşme ifadeleri (ör. `["mercimek çorbası", "kırmızı mercimek çorbası"]`) |
| `is_active` | boolean, not null, default true | Pasifleştirilmiş görseller yeni eşleşmelerde önerilmez ama zaten seçilmiş `image_url`'ler etkilenmez |
| `created_by` | uuid, references `auth.users(id)` | |
| `created_at` | timestamptz, default `now()` | |
| `updated_at` | timestamptz, default `now()` | |

**Referans modeli (Yaklaşım 1 — onaylandı):** Sahip "Sistemden Seç" ile bir görsel seçtiğinde, o görselin `image_url` değeri doğrudan `menu_items.image_url`'e yazılır — tıpkı sahibin kendi fotoğrafını yüklediği durumdaki gibi, foreign-key/dinamik referans yok. Bir kez seçildikten sonra ürün kütüphaneden bağımsızlaşır: admin kütüphanedeki görseli değiştirse/pasifleştirse bile daha önce seçmiş ürünler etkilenmez. Bu, mevcut `image_url` alanının "düz URL string'i" davranışıyla %100 tutarlıdır ve web/mobil/admin'deki hiçbir mevcut render noktasında değişiklik gerektirmez.

## Eşleştirme Mantığı

Statik sistemdeki iki-aşamalı "önce kategori klasörünü belirle, sonra o klasör içinde ara" mantığı **kaldırılıyor**. Admin artık her görsele kendi hassas ifadelerini yazdığı için tek-aşamalı düz eşleştirme yeterli:

1. Ürün adı normalize edilir (Türkçe karakter sadeleştirme: ç→c, ğ→g, ı→i, ö→o, ş→s, ü→u; tüm boşluk/noktalama silinir — mevcut `normalizeTr`/`_normalize` fonksiyonlarıyla aynı).
2. Aktif her `stock_dish_images` satırının `keywords` dizisindeki her ifade de aynı şekilde normalize edilir.
3. Normalize edilmiş ürün adı, normalize edilmiş bir anahtar ifadeyi **içeriyorsa** eşleşme sayılır.
4. Eşleşmeler en uzun (en özgül) anahtar ifadeye göre sıralanır.

Aynı kelimenin farklı yemeklerde geçmesi riski (ör. "mercimek" hem çorbaya hem köfteye eşleşebilir) admin'in yeterince özgül ifadeler girmesiyle yönetilir (tek kelime yerine "mercimek çorbası" gibi) — bu bir admin-editoryal sorumluluğu, sistem seviyesinde zorlanmıyor.

## Erişim/Performans

- Yeni public RPC: `get_stock_dish_images_v1()` — tüm **aktif** görselleri (`id, image_url, keywords`) döner. `authenticated` ve `anon`'a açık (public menü sayfasındaki otomatik fallback anonim ziyaretçiler için de çalışmalı).
- Bu RPC'nin sonucu web ve mobilde cache'lenir (küçük veri seti — bugün 117, büyümesi yavaş bekleniyor). Hem **otomatik sessiz fallback** (sahip hiç dokunmadan, mevcut davranış) hem **"Sistemden Seç" arama** aynı cache'lenmiş veriyi ve aynı client-side eşleştirme fonksiyonunu kullanır — ürün başına ayrı RPC çağrısı yapılmaz.
- Admin yazma RPC'leri (`admin_upsert_stock_dish_image_v1`, `admin_deactivate_stock_dish_image_v1`, `admin_delete_stock_dish_image_v1`, `admin_list_stock_dish_images_v1` — pasif olanlar dahil tam liste) yalnızca admin rolüne açık, bu repodaki `admin_*` RPC konvansiyonuna uyar.

## Admin Paneli — Görsel Kütüphanesi Sayfası

Konum: `app/yonetici/gorsel-kutuphanesi/`, "Operasyon" nav grubuna eklenir (İşletmeler/Zincirler/Kuyruklar'ın yanına), label "Görsel Kütüphanesi".

- **Liste/ızgara**: her görsel bir kart — küçük resim, anahtar kelime "chip"leri, aktif/pasif anahtarı.
- **Yeni ekle**: dosya yükle (mevcut `menu-media` bucket kısıtları geçerli: jpeg/png/webp, 5MB) + bir veya daha fazla anahtar ifade.
- **Düzenle**: anahtar ifadeleri ekle/çıkar, aktif/pasif yap.
- **Pasifleştirme (birincil aksiyon)** vs **gerçek silme (ikincil, uyarılı aksiyon)**: pasifleştirme yeni eşleşmelerde görünmez yapar ama dosyayı silmez, zaten seçilmiş `image_url`'leri bozmaz. Gerçek silme dosyayı Storage'dan da kaldırır — "bunu seçmiş işletmeler olabilir, görselleri bozulabilir" uyarısıyla, daha az öne çıkan bir aksiyon olarak sunulur.

## Sahip Tarafı — "Sistemden Seç" Sekmesi

Hem web hem mobilde, mevcut ürün görsel seçicisine (bugünkü "Link ver / Cihazdan yükle / AI ile üret" seçeneklerinin yanına) yeni bir sekme olarak eklenir (onaylanan mockup A — sekmeli tam ekran seçici, otomatik öneri şeridi değil).

- Sekme açıldığında, formda o an yazılı ürün adına göre `get_stock_dish_images_v1()`'in cache'lenmiş sonucu üzerinde client-side eşleştirme yapılır, eşleşen adaylar ızgara halinde gösterilir.
- Sahip bir aday seçerse formun `image_url` alanı doldurulur — kaydet'e basana kadar kalıcı olmaz, mevcut link/yükleme akışıyla aynı davranış.
- Hiç eşleşme yoksa "Sistemden Seç" sekmesi boş durum gösterir, diğer sekmeler (link/yükle/AI) her zaman kullanılabilir kalır.

## 117 Görselin Taşınması

- Dosyalar Storage'da zaten duruyor, yeniden yüklenmiyor — sadece `stock_dish_images` tablosuna satır olarak kaydediliyor.
- Anahtar kelimeler bu sefer düzgün Türkçe yazımla giriliyor (dosya adı "kelle_paca" değil, ifade "kelle paça").
- Aynı kelimenin farklı klasörlerde farklı fotoğraflara karşılık geldiği durumlar (ör. "bamya" → çorba/sulu yemek/zeytinyağlı) migration sırasında ayırt edici ifadelerle ("bamya çorbası" / "etli bamya" / "zeytinyağlı bamya") giriliyor ki kütüphane admin'e ilk açıldığında tutarlı gelsin.
- Statik TS/Dart sözlükleri (`varsayilan-yemek-gorseli.ts`, `varsayilan_yemek_sozlugu.dart`) kaldırılıyor — mevcut normalize/eşleştirme *algoritması* aynen korunuyor, veri kaynağı sabit dizi yerine cache'lenmiş kütüphane listesi oluyor.

## Test/Doğrulama Planı

- **DB**: migration'lar psql ile production'a uygulanır (bu oturumun yöntemi), her yeni RPC spec-compliance + code-quality review'dan geçer.
- **Yetki**: admin yazma RPC'leri yalnızca admin; `get_stock_dish_images_v1()` `authenticated` + `anon`.
- **Web**: `pnpm run typecheck && pnpm run lint && pnpm run test:unit` — mevcut 7 eşleştirme testi yeni veri kaynağına uyarlanır, admin CRUD sayfası için ek testler.
- **Mobil**: `flutter analyze` + `flutter test` — aynı şekilde mevcut 7 test uyarlanır.
- **Uç durumlar**: kütüphane boşken/RPC hata verirken hem otomatik fallback hem "Sistemden Seç" sessizce mevcut ikon davranışına düşer (hata fırlatmaz); pasifleştirilmiş bir görseli daha önce seçmiş ürünler bozulmaz (URL-referans modeli bunu garantiler).

## Kapsam Dışı (v1)

- Görsel kullanım istatistikleri (hangi işletmeler hangi stok görseli seçti) — admin CRUD'da izlenmiyor.
- Otomatik görsel kırpma/boyutlandırma admin yüklemesinde — admin uygun boyutta (tercihen kare) görsel yüklemekle sorumlu, tıpkı orijinal 117 görselin hazırlanışında olduğu gibi.
- Dinamik/canlı güncellenen referans modeli (Yaklaşım 2) — v1'de basit URL-referans modeli (Yaklaşım 1) kullanılıyor.
