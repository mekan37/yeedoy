# B2B Exports

Bu dokuman admin paneldeki `/admin/b2b-exports` ekraninin urun sinirini tanimlar.

Amac:

- hangi export'un sadece ic operasyon araci oldugunu
- hangisinin premium raporlama adayi oldugunu
- hangisinin potansiyel dis veri urunu olabilecegini
- hangi veri setlerinin hangi anonimlestirme seviyesi ile kullanilacagini

tek yerde netlestirmek.

## Kapsam

Mevcut admin export katalogu dort dataset'ten olusur:

1. `anonymous_trends`
2. `regional_price_index`
3. `menu_inflation`
4. `price_anomalies`

Teknik kaynaklar:

- `apps/panel_flutter_web/lib/features/admin/ui/admin_b2b_exports_page.dart`
- `apps/panel_flutter_web/lib/features/admin/domain/admin_b2b_export_catalog.dart`
- `apps/panel_flutter_web/lib/features/admin/data/admin_b2b_exports_repository.dart`
- `supabase/migrations/20260321000009_b2b_exports.sql`
- `supabase/migrations/20260321000023_data_moat_analytics.sql`

## Urun Hatlari

### 1. Internal Ops

Bu hat yalnizca ic operasyon ekiplerinin kullanimi icindir.

Dataset:

- `price_anomalies`

Kullanim amaci:

- asiri fiyat hareketlerini bulmak
- kalite ve moderasyon ekiplerine erken sinyal vermek
- operasyonel inceleme veya sozmeli analiz icin kucuk bir inceleme havuzu uretmek

Not:

- bu dataset varsayilan olarak dis satis urunu sayilmaz
- hassas sinyal tasidigi icin `contract_only` sinifindadir

### 2. Premium Reporting Candidate

Bu hat owner veya enterprise raporlama uzantisi icin aday veri urunlerini kapsar.

Dataset:

- `menu_inflation`

Kullanim amaci:

- menu fiyat degisiminin donemsel etkisini gostermek
- owner tarafinda benchmark veya trend raporlama katmani kurmak
- premium analitik paketi icin anlamli fiyat seyrini hazirlamak

Not:

- dataset aggregate duzeyde olsa da urun veya isletme hassasiyeti tasir
- bu nedenle `restricted_aggregate` sinifindadir

### 3. External Data Product Candidate

Bu hat dis satis veya market intelligence urunu olabilecek daha guclu aggregate veri setlerini kapsar.

Dataset:

- `anonymous_trends`
- `regional_price_index`

Kullanim amaci:

- bolgesel ilgi ve talep degisimini gostermek
- sehir/ilce bazli fiyat hareketlerini anonim aggregate olarak sunmak
- pazar izleme, kategori takibi ve fiyat endeksi gibi kurumsal ciktillar uretmek

Not:

- bu iki dataset ham kullanici izi disariya tasimaz
- dis veri urunu adayi sayilir ama ticari paketleme yine sozlesme ve hukuk gozden gecirmesi ister

## Gizlilik Siniflari

### Anonymous Aggregate

Kurallar:

- ham kullanici kimligi, cihaz kimligi veya bireysel iz cikmaz
- veri city/district/day gibi aggregate eksenlerde kalir
- tek business'e geri donen sinyal uretilmemelidir

Bu sinif:

- `anonymous_trends`
- `regional_price_index`

### Restricted Aggregate

Kurallar:

- aggregate gorunur ama urun veya isletme seviyesinde hassas sinyal vardir
- owner premium raporlama veya enterprise rapor icin kullanilabilir
- dis satis oncesi ek gozden gecirme gerekir

Bu sinif:

- `menu_inflation`

### Contract Only

Kurallar:

- dataset operasyonel karar veya hassas anomaly tespiti icin tutulur
- varsayilan kanal ic operasyon veya sozmeli analizdir
- self-serve public/premium dataset olarak sunulmaz

Bu sinif:

- `price_anomalies`

## Freshness Modeli

- `anonymous_trends`: `daily_series`
- `regional_price_index`: `rolling_window`
- `menu_inflation`: `rolling_window`
- `price_anomalies`: `rolling_window`

Anlam:

- `daily_series`: export gun bazli satirlar uretir
- `rolling_window`: secilen 7/30/90 gun penceresinden turetilen analiz ciktisidir

## Panel Davranisi

`/admin/b2b-exports` ekrani artik sadece indirme butonlari sunmaz.

Ekran:

- export'lari urun hatti bazinda sayar
- her export icin product lane, privacy class ve freshness gosterir
- veri urunu siniri karti ile hangi dataset'in ne kadar disa acik oldugunu operatora aciklar
- CSV indirme aksiyonunu korur

Bu davranis sayesinde admin ekibi artik su ayrimi net gorur:

- bugun icin sadece ic kullanima hazir olanlar
- premium raporlama adaylari
- dis veri urunu adayi olanlar

## Bugunku Durum

Calisanlar:

- admin panelden dort export indirilebilir
- export'lar artik tek katalogta siniflandirilir
- urun hatti ve gizlilik siniri UI ve dokumanda ayni dille anlatilir

Halen bilerek acik birakilanlar:

- otomatik hukuk/sozlesme onay akisi
- export talep/izin kaydi
- self-serve customer-facing satis yuzeyi
- dataset bazli watermark veya lisanslama mekanizmasi

## Is Kurali

- `price_anomalies` public veya self-serve premium dataset sayilmaz
- `menu_inflation` owner premium raporlama adayi olarak ele alinir
- `anonymous_trends` ve `regional_price_index` dis veri urunu adayi sayilabilir ama anonim aggregate sinirini asmamalidir
- yeni bir B2B export eklendiginde ayni katalogta product lane ve privacy class almadan yayinlanmamalidir
