# Audit Yüzeyi

Bu dokuman audit veri sozlesmesini, gorunurlugu ve owner/admin okuma yuzeylerini aciklar.

Su konular burada tutulmaz:

- unified moderation queue triage davranisi
- upload adapter kontrati
- tek tek operasyon ekranlarinin bulk veya saved view detaylari

Tek kaynaklar:

- queue davranisi: `docs/moderation_queue.md`
- upload adapter: `docs/media_upload.md`

## Amaç

`panel_flutter_web` içinde owner ve admin tarafı için ayrı ama aynı veri sözleşmesini kullanan zorunlu denetim görünürlüğü sağlanır.

- Owner yalnızca erişebildiği işletme veya şubeye ait kritik aksiyonları görür.
- Admin sistem genelindeki aksiyonları filtreleyip inceleyebilir.
- Analytics olayları ile audit kayıtları karıştırılmaz; audit için ayrı tablo ve RPC kullanılır.

## Kullanılan Altyapı

Yeni bir audit tablosu açılmadı. Mevcut altyapı genişletildi:

- Tablo: `public.admin_audit_log`
- Yazım yardımcıları: `public.insert_audit_log_v1`, `public.log_admin_action_v1`
- Okuma RPC:
  - Eski: `public.list_audit_timeline_v1`
  - Yeni: `public.list_audit_timeline_v2`

`analytics_events` ve `log_event_v1` yalnızca ürün analitiği içindir. Audit ekranları bunları kullanmaz.

## Okuma Yetkisi

### Admin

Admin kullanıcılar tüm kayıtları görebilir.

### Owner / ekip üyesi

Owner tarafı doğrudan `admin_audit_log` tablosunu okumaz. Okuma yalnızca `security definer` RPC üzerinden yapılır.

`list_audit_timeline_v2` şu kapsamları destekler:

- sahiplik talebiyle erişilen işletmeler
- takım üyeliğiyle erişilen işletmeler
- seçili işletme filtresi (`p_business_id`)
- aksiyon filtresi
- entity filtresi
- aktör filtresi
- tarih aralığı
- serbest arama (`p_q`)

## Kapsanan Kritik Aksiyonlar

Bu turda audit yazımı eksik olan kritik path’ler tamamlandı:

- işletme doğrulama durumu değişimi
- fiyat önerisi onaylama
- fiyat önerisi reddetme
- owner fiyat önerisi reddetme

Zaten audit yazan ve owner/admin yüzeyinde görünür kalan aksiyonlar:

- menü düzenleme
- menü ürün düzenleme
- business merge
- team member ekleme / güncelleme / kaldırma
- impersonation start / stop
- owner price override

Not:
- `media_flag` gibi queue tipleri audit yuzeyinde ayri operasyon tipi olarak degil, ilgili aksiyon kaydi ve entity tipi uzerinden izlenir.

## UI Yüzeyleri

### `/owner/activity`

- seçili işletme bağlamı ile çalışır
- filtreler:
  - arama
  - aksiyon türü
  - entity
  - tarih aralığı
  - yalnızca benim işlemlerim
- erişim yoksa standart yetki ekranı gösterilir

Eski `/owner/audit` route’u kırılmadı; yeni sayfaya alias olarak bırakıldı.

### `/admin/audit`

- global arama
- aksiyon filtresi
- entity filtresi
- tarih aralığı
- yalnızca benim aksiyonlarım
- mevcut filtrelenmiş kayıtlar için CSV dışa aktarma

## Ortak Bileşen

Her iki yüzey aynı tablo bileşenini kullanır:

- `apps/panel_flutter_web/lib/features/admin/ui/widgets/audit_table.dart`

Bu bileşen şunları tek yerde toplar:

- filtre barı
- boş / yükleniyor / hata yüzeyi
- detay sheet
- aksiyon ve entity etiketlerinin insan okunur gösterimi

## Güvenlik Notları

- `admin_audit_log` public okunmaz.
- Owner görünürlüğü yalnızca çözülmüş `business_id` üzerinden verilir.
- `list_audit_timeline_v2` içinde `menus`, `menu_items`, `price_suggestion`, `team_member` gibi eski/yeni target tipleri normalize edilir.
- İşletme scope’u çözülemeyen kayıtlar owner tarafında görünmez, admin tarafında görünür.

## Smoke Plan

### Owner

1. `owner` rolüyle giriş yap.
2. Seçili işletme değiştir.
3. `/owner/activity` sayfasında yalnız seçili işletmeye ait kayıtları doğrula.
4. “Yalnızca benim işlemlerim” açıldığında aktör filtresinin daraldığını doğrula.

### Manager / editor / staff

1. Takım üyeliği olan kullanıcıyla giriş yap.
2. Erişebildiği işletme için aktiviteyi görebildiğini doğrula.
3. Yetkisi olmayan işletmede route açıldığında standart forbidden UX’in geldiğini doğrula.

### Admin

1. `/admin/audit` aç.
2. Aksiyon ve entity filtrelerini uygula.
3. Tarih aralığı ve arama birlikte çalışıyor mu kontrol et.
4. CSV dışa aktarmanın mevcut filtrelenmiş listeyi indirdiğini doğrula.
5. Impersonation başlat / durdur aksiyonlarının audit’te göründüğünü doğrula.
