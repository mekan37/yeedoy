# Menü Düzenleyici Yeniden Tasarımı — Design

## Bağlam

2026-08-05'te, premium-plan-gating turunun deploy'undan sonra kullanıcı owner panelde birkaç sayfanın eski/kayıp tasarımda kaldığını bildirdi. Bunlardan ikisi (gösterge panosu, üst header) gerçek 2026-07-22 EN→TR migration kaybıydı ve restore edildi (commit `bcfefbb6`/`f64c3a22`/`177b633a`). Üçüncüsü (fiyat raporu) tasarım değil, algoritmik bir bug'dı (düzeltildi, `6d9a61cb`). "QR kodlar" ve "başlangıç rehberi" incelendi, gerçek bir kayıp bulunamadı.

Kullanıcı ayrıca bir referans görsel paylaştı ("Menü Yönetimi" başlıklı, ChatGPT ile üretilmiş bir mockup) ve bunun daha önce yapılmış bir tasarıma benzediğini belirtti. Hem eski `app/owner/(panel)/menus/[menuId]/edit/menu-editor-client.tsx` (767 satır, silinmeden önceki son hali) hem şu anki `app/sahip/menuler/[menuId]/duzenle/` (869 satır) incelendi: **bu tablo-tabanlı, istatistik kartlı, canlı önizlemeli tasarım ikisinde de hiç var olmamış.** Bu bir restorasyon değil, yeni bir hedef tasarıma göre baştan inşa.

## Kapsam

**Sadece** `app/sahip/menuler/[menuId]/duzenle/` sayfası (menü içindeki ürünleri düzenleme ekranı). Menü listesi sayfası (`app/sahip/menuler/page.tsx`) ve Kategoriler sayfası (`app/sahip/menuler/[menuId]/kategoriler/`) bu turda **değiştirilmiyor** — sadece düzenleyiciden bağlanıyor/referans alınıyor.

### Dahil
1. Üst istatistik kartları (Toplam Kategori, Toplam Ürün, Aktif Ürün, Pasif Ürün, Son Güncelleme)
2. Kategori sekmeleri (Tümü + her bölüm)
3. Araç çubuğu: arama, kategori/durum filtresi, sıralama, toplu işlemler
4. Sürüklenebilir sıralama (gerçek `sort_order` güncellemesi)
5. Veri tablosu (görsel, ad/açıklama, kategori rozeti, fiyat, durum, son güncelleme, işlemler)
6. Satır tıklama → mevcut TÜM düzenleme özelliklerini içeren yan panel/modal
7. Sağ sidebar: Kategori Yönetimi widget'ı (widget içi hızlı ekleme/düzenleme) + Canlı Önizleme (seçili ürün kartı)
8. "Kategori Ekle" / "Yeni Ürün Ekle" modalleri

### Kapsam dışı
- Menü listesi sayfasının yeniden tasarımı
- Ayrı Kategoriler sayfasının kaldırılması (widget ona link verir, o sayfa kalır)
- 3 durumlu (Aktif/Taslak/Gizli) ürün statüsü — kullanıcı kararıyla 2 duruma (Aktif/Pasif) indirildi, `is_available` alanı yeterli
- `menu_categories`/`category_id` — incelendi, `name` kolonu bile yok, kullanılmayan/eski bir yapı; "kategori" kavramı mevcut editörün zaten kullandığı `menu_sections`/`section_id` modeline bağlanacak

## Mimari

### Veri modeli — yeni migration gerekmiyor (bir istisna hariç, aşağıda)

Mevcut `menu_sections` (id, title, sort_order) = "Kategori". Mevcut `menu_items` (name, description, price_cents, is_available, image_url, sort_order, section_id) yeterli. Yeni sütun/tablo gerekmiyor.

### Bulunan, çözülmesi gereken bir tutarsızlık

`list_owner_menu_trash_v1` RPC'si `entity_type: 'item'` döndürebiliyor (çöp kutusu sayfası bunu render ediyor) ama `menu_items` tablosunda soft-delete için `deleted_at` gibi bir kolon **yok**, ve mevcut `deleteItem` server action'ı gerçek bir `DELETE` yapıyor (hard delete). Yani ya çöp kutusu ürünler için hiç çalışmıyor, ya da farklı bir mekanizma var ve henüz bulunamadı. **Implementasyon sırasında netleştirilmeli**: toplu silme (ve varsa mevcut tekli silme) hangi gerçek mekanizmayı kullanacak — plan yazma aşamasında bu araştırılıp kesinleştirilecek; tasarım bunu varsaymıyor.

### Sürükle-bırak sıralama

Yeni bir server action gerekli (örn. `reorderItems(menuId, itemId, newSortOrder)` veya toplu güncelleme) — mevcut `upsertItem`'ın `sort_order` alanını da kabul edip etmediği implementasyon sırasında kontrol edilecek; muhtemelen yeni, dar kapsamlı bir action yazılacak.

### Toplu işlemler

Yeni server action'lar gerekli: toplu aktif/pasif (`upsertItem`'ın tekrarlı çağrısı veya yeni bir toplu RPC), toplu kategori değiştirme (`section_id` güncelleme), toplu silme (yukarıdaki tutarsızlık çözüldükten sonra doğru mekanizmayla).

## UI Bileşenleri

Tüm yeni bileşenler mevcut tasarım sistemi token'larını kullanacak (`bg-card`, `text-textStrong`, `border-border`, `shadow-yd*`, `text-primary` vb.) — mockup'taki ham renk paleti (`#dc2626` kırmızı, mavi/yeşil/mor rozet renkleri) birebir kopyalanmayacak, mevcut `AppColors`/tema ile eşlenecek.

1. **İstatistik kartları** — 5 kart, gerçek veriden (`menu_sections` sayısı, `menu_items` sayısı, `is_available=true/false` sayıları, `MAX(updated_at)`).
2. **Kategori sekmeleri** — `menu_sections` listesinden dinamik, "Tümü" + her bölüm; tablo filtreleme, URL state veya client state (implementasyon sırasında karar verilecek — sayfa zaten `'use client'` bir bileşen olduğu için client state de makul).
3. **Araç çubuğu** — arama input, kategori dropdown, durum dropdown (Tümü/Aktif/Pasif), sıralama dropdown (ad/fiyat/son güncelleme gibi kolon bazlı sıralama — sürükle-bırak'tan farklı, sürükle-bırak'ı geçersiz kılar/sadece "Manuel" sıralama modundayken sürükle-bırak aktif olur), "Toplu İşlemler" dropdown (satır seçimi checkbox'larıyla birlikte aktif olur).
4. **Tablo** — sürükle-bırak handle (#), görsel thumbnail, ad+açıklama (truncate), kategori rozeti, fiyat, durum pill, son güncelleme, işlemler (düzenle → yan panel aç, kopyala, sil).
5. **Düzenleme yan paneli/modal** — mevcut `menu-duzenleyici-istemcisi.tsx` içindeki TÜM form alanları ve AI özellikleri (alerjen/kalori AI doldurma, AI görsel üretme, alerjen/malzeme editörü, çeviriler linki, spesiyel işaretleme) buraya taşınır — hiçbiri kaldırılmaz, sadece konteyner değişir (accordion/inline yerine yan panel).
6. **Kategori Yönetimi widget'ı** — sağ sidebar, her kategori için ürün sayısı + widget içinde hızlı ekle/düzenle (mevcut `createSection`/`updateSection` action'larını kullanır) + "Tüm Kategorileri Yönet" linki (mevcut `/sahip/menuler/[menuId]/kategoriler` sayfasına).
7. **Canlı Önizleme widget'ı** — sağ sidebar, seçili/son düzenlenen ürünün basit kart önizlemesi (görsel + ad + açıklama + fiyat + durum rozeti) — mockup'taki gibi, gerçek public sayfa embed'i değil.
8. **"Kategori Ekle" / "Yeni Ürün Ekle" modalleri** — üst sağ butonlar, sayfadan ayrılmadan hızlı ekleme.

## Hata Yönetimi

Mevcut sayfanın zaten kullandığı hata gösterim kalıpları (kırmızı banner, `useActionState` benzeri desenler — implementasyon sırasında `menu-duzenleyici-istemcisi.tsx`'in mevcut hata yönetim deseni referans alınacak) korunacak.

## Test Planı

- `pnpm run typecheck` + `pnpm run lint`.
- Sürükle-bırak sıralama, toplu işlemler, ve (varsa yeni) silme mekanizması için en az birer vitest/unit test.
- `pnpm run test:unit`.
- Mevcut AI-doldurma/görsel-üretme/alerjen editör akışlarının yan panelde de çalıştığı manuel/otomatik doğrulanacak (mevcut testler varsa korunacak).

## Kapsam Dışı (net karar)

- 3 durumlu ürün statüsü
- Menü listesi ve Kategoriler sayfalarının yeniden tasarımı
- Gerçek public sayfa embed'i (canlı önizleme sadece kart)
