# Veri Güvenliği

Bu doküman owner panelde menü verisini yanlış silme ve yanlış yayınlama riskine karşı eklenen koruma katmanını açıklar.

Bu dokuman trash, soft delete ve menu version snapshot davranisinin tek kaynagidir.

Su konular burada tutulmaz:

- audit gorunurlugu
- owner analytics
- genel yetki veya RBAC modeli

Tek kaynaklar:

- audit gorunurlugu: `docs/audit.md`
- owner analytics: `docs/analytics_owner.md`
- rol ve izin modeli: `docs/rbac.md`

## Amaç

- Menü, ürün ve fotoğraf silmelerini geri alınabilir hale getirmek
- Publish anında geri dönülebilir snapshot üretmek
- Owner panelde güvenli bir `çöp kutusu + versiyonlar` iş akışı vermek

## Soft Delete Modeli

### Menü

`menus.status = 'archived'` mevcut yapıda soft delete olarak kullanılır.

- Trash ekranında görünür
- `restore` ile `draft` durumuna döner
- `force delete` yalnız trash içindeki arşivli kayıt için çalışır

### Ürün

`menu_items.is_available = false` mevcut yapıda soft delete olarak kullanılır.

- Trash ekranında görünür
- `restore` ile tekrar görünür hale gelir
- `force delete` yalnız arşivli kayıt için çalışır

### Fotoğraf

Fotoğraflar için bu turda minimal alanlar eklendi:

- `menu_item_photos.deleted_at`
- `menu_item_photos.deleted_by`

Normal owner silme artık hard delete yapmaz; kayıt trash'e taşınır. `get_menu_item_photos_v1` silinmiş fotoğrafları normal akışta göstermez.

## Snapshot ve Rollback

Yeni tablo:

- `menu_snapshots`

Publish sırasında:

- `owner_publish_menu_v1`
- önce `create_menu_snapshot_v1(menu_id, 'publish')`
- sonra menüyü `published` yapar

Rollback sırasında:

- `owner_restore_menu_version_v1(snapshot_id, archive_current_menu_id)`
- mevcut edit edilen menüyü arşivler
- snapshot'tan yeni bir published menü üretir

Bu yaklaşım bilinçli olarak “yerinde kırılgan overwrite” yerine “restore edilmiş yeni kopya” mantığını kullanır. Böylece section/item ilişkilerini sert şekilde parçalama riski azaltılır.

## Owner UI

### `/owner/trash`

- silinen menüler
- arşivlenmiş ürünler
- soft deleted fotoğraflar

Aksiyonlar:

- Geri yükle
- Kalıcı sil

### Menü Editöründe Versiyonlar

`OwnerMenuEditorPage` içinde `Versiyonlar` paneli vardır.

Burada:

- publish snapshot listesi görünür
- snapshot zamanı ve içerik sayısı görünür
- `Farkları gör` ile seçilen snapshot ile güncel menü arasındaki bölüm/ürün farkı açılır
- `Bu versiyona dön` ile restore edilmiş yeni menu kopyası üretilir

### Trash Verimliliği

Trash ekranında artık:

- arama
- tür filtresi
- en yeni / en eski / ada göre / türe göre sıralama

aynı yüzeyde kullanılabilir.

## Admin UI

### `/admin/trash`

Admin için ayrı restore merkezi vardır.

Burada:

- işletme araması yapılır
- seçilen işletmenin çöp kutusu açılır
- menü / ürün / fotoğraf restore edilir
- gerekirse kalıcı silme yapılır

## Güvenlik

- Read işlemleri `business_read`
- Restore / force delete / rollback işlemleri `menu_write`
- Admin her yerde geçebilir
- Foto hard delete sırasında mevcut edge guard zinciri korunur

## Bilinen Sınırlar

- Snapshot rollback yeni bir menu kopyası üretir; aynı `menu_id` üzerine destructive overwrite yapılmaz.
- Fotoğraf rollback'i snapshot içine alınmaz; data safety odağı menu structure üzerindedir.
- Trash şu an business scoped çalışır.

## Sonraki Adımlar

1. Restore sonrası yeni menü editörünü otomatik açan akış eklenebilir.
2. Snapshot diff görünümüne fiyat ve varyant farkları da eklenebilir.
3. Admin restore merkezine toplu restore aksiyonları eklenebilir.

## Sinir Notu

Bu dosya veri koruma akislarini anlatir; audit kaydi veya analytics dashboard davranisi burada tekrar edilmez.
