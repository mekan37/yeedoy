# Yemekler Tab Redesign + Örnek Yeedoy Seed Data

## Context

Discovery page'in "Yemekler" tabı (`MenuItemsTab`) şu an düz bir liste + filtre UI'sı. Yeni tasarım (mockup ekran görüntüsü) "Merhaba!" karşılama başlığı, pill arama çubuğu, kategori chip'leri, "Günün lezzeti" öne çıkan kart ve görselli "Popüler yemekler" listesi içeriyor.

Production veritabanında `menu_items`, `menus`, `reviews` tabloları şu an boş (0 satır) — gerçek menü verisi yok. Bu yüzden önce demo amaçlı "Örnek Yeedoy" işletmesi tam veriyle (menü, görseller, kampanya, yorum) eklenecek, sonra Yemekler tabı bu veriyi gösterecek şekilde yeniden tasarlanacak.

İki bağımsız aşama olarak yürütülecek: **A) seed data**, sonra **B) UI redesign**. A tamamlanıp doğrulandıktan sonra B'ye geçilecek.

## Bölüm A — "Örnek Yeedoy" seed verisi (production Supabase)

### businesses
- `name`: "Örnek Yeedoy"
- `category`: "Restoran"
- `lat`/`lng`: 40.012933 / 32.740723
- `city`: "Ankara", `district`: "Yenimahalle" (yakın işletmelerle aynı bölge)
- `neighborhood`: yakın işletmelerden alınan mahalle adına benzer bir değer
- `source`: "manual", `is_active`: true
- `slug` / `public_slug`: "ornek-yeedoy"
- `cover_url`, `logo_url`: doğrulanmış Unsplash URL'leri

### menus / menu_sections / menu_items
- 1 menü: "Ana Menü" (`status='published'`)
- Bölümler: Kebaplar, Pideler, Çorbalar, Tatlılar
- Ürünler (mockup'taki "Popüler yemekler" listesiyle aynı):
  | Ürün | Bölüm | Fiyat | Not |
  |---|---|---|---|
  | Adana Kebap | Kebaplar | ₺260 | `is_today_special=true`, "Köz biber, bulgur pilavı ile" |
  | Kuşbaşılı Pide | Pideler | ₺240 | "Kaşar ve tereyağlı" |
  | Mercimek Çorbası | Çorbalar | ₺90 | "Limon ve kıtır ekmek ile" |
  | Fıstıklı Baklava | Tatlılar | ₺180 | "Günlük taze üretim" |

  Her ürün `image_url` alanına doğrulanmış Unsplash URL'si ile dolduruluyor.

### business_stories (kampanya)
- `type='promo'`, `media_url`: kampanya görseli, `caption`: "Örnek Yeedoy'a özel kampanya", `expires_at = now() + 30 gün`, `created_by`: admin user (`aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa`)

### reviews
- 1 adet: `rating=5`, mevcut test kullanıcısı (`b0b0b0b0-...` Ahmet Demir), olumlu Türkçe yorum metni

### Doğrulama
- Görsel URL'leri eklemeden önce HTTP erişilebilirlik kontrolü (WebFetch)
- Insert sonrası `mcp__supabase__get_advisors` ile yeni hata/uyarı oluşmadığını kontrol et

## Bölüm B — Yemekler Tab Redesign

### Backend: `search_menu_items_v2`
- `search_menu_items_v1` ile aynı imza/parametreler
- Dönen tabloya ek alanlar: `image_url`, `is_today_special`, `special_note`
- v1 değiştirilmez (internal diet-aware wrapper v1'i kullanmaya devam eder)
- `pick_one_menu_item_v1` değişmez

### Mobile model/repository
- `MenuItemSearchResult`: `imageUrl`, `isTodaySpecial`, `specialNote` alanları eklenir
- `MenuItemSearchRepository.searchMenuItems` → `search_menu_items_v2` çağırır

### UI (`MenuItemsTab` / `menu_items_tab.dart`)

1. **Başlık bölümü**: "Merhaba! 👋" (greeting) + büyük "Yemekler" başlığı. App shell'deki mevcut bildirim ziline ek bir zil eklenmiyor (tekrar olmaması için).
2. **Arama çubuğu**: pill-şekilli `TextField`, placeholder "Yemek veya kategori ara...", yanında mevcut tune/filtre ikonu.
3. **Kategori chip'leri**: "Tümü" + `discoveryHomeCategories` listesindeki kategoriler (yatay scroll). Seçim → `searchTerm` query olarak set edilir ve `refresh()` çağrılır. "Tümü" → query temizlenir.
4. **"Günün lezzeti" banner**: sonuç listesinde `isTodaySpecial=true` olan ilk öğe varsa üstte kart olarak gösterilir (görsel + ad + açıklama + detay sayfasına giden ok butonu).
5. **"Popüler yemekler" listesi**: yeniden tasarlanan kart —
   - Sol: `imageUrl` (yoksa kategori ikonu fallback) — 64x64 yuvarlatılmış görsel
   - Orta: ürün adı, açıklama (varsa), işletme adı (mağaza ikonu ile), mesafe
   - Sağ: fiyat, üstte küçük fiyat-takibi ikon butonu (mevcut `setPriceAlert` aksiyonu)
   - Diyet rozetleri (vegan/glutensiz) ve fiyat-durumu rozeti küçültülmüş halde korunur
6. **Filtreler**: değişmez — tune ikonu mevcut `_MenuItemFilterSheet`'i açar.

### L10n
- Yeni TR/EN ARB anahtarları: karşılama metni, "Tümü" kategori etiketi, "Günün lezzeti", "Popüler yemekler" (mevcut anahtarlar varsa onlar kullanılır)

### Test/Doğrulama
- `flutter analyze`
- `flutter test` (mevcut discovery/menu testleri + varsa yeni widget testi)
- Yemekler tabı manuel olarak çalıştırılıp "Örnek Yeedoy" verisiyle görsel kontrol
