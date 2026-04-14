# Moderasyon Kuyrugu

`/admin/queue`, dağınık moderasyon ekranlarını tek operasyon kuyruğunda toplar. Amaç, 10k+ işletme ve çok operatörlü moderasyon akışında atama, SLA ve bulk işlem disiplinini tek yerden yönetmektir.

Bu dokuman queue operasyon sozlesmesini aciklar.

Su konular burada tutulmaz:

- upload adapter kontrati
- audit tablo veya RPC ayrintisi
- ekran bazli business veya submission tablo dokumani

Tek kaynaklar:

- upload adapter: `docs/media_upload.md`
- audit gorunurlugu: `docs/audit.md`
- business operasyon tablosu: `docs/admin_businesses.md`
- business submission operasyonu: `docs/admin_business_submissions.md`

## Kapsam

Queue şu kayıt tiplerini tek veri sözleşmesi altında birleştirir:

- `business_submission`
- `report`
- `price_suggestion`
- `claim`
- `media_flag`

`media_flag`, raporların `business_media` ve `menu_item_photo` hedefli alt kümesidir. Böylece genel rapor akışı ile medya moderasyonu aynı ekranda ayrı tip olarak izlenebilir.

## Filtreler

Queue ekranında şu filtreler vardır:

- arama
- durum
- tip
- şehir
- tarih aralığı
- local saved views

Saved view yapısı `AdminTableSavedViewsPrefs` üzerinden tarayıcıda tutulur; backend state yazmaz.

## SLA

Queue satırlarında bekleme süresi saat bazında gösterilir. Mevcut eşikler:

- business submissions: `24 saat`
- reports: `24 saat`
- media flags: `24 saat`
- claims: `48 saat`
- price suggestions: `48 saat`

Kırmızı badge SLA ihlalini, turuncu badge bekleyen ama henüz ihlal etmemiş kaydı gösterir.

## Assignment

Queue assignment davranışı kayıt tipine göre şöyledir:

- reports / media flags: mevcut report assignment akışı kullanılır
- claims: mevcut owner claim assignment akışı kullanılır
- price suggestions: `handled_by` / `handled_at` queue assignment helper ile güncellenir
- business submissions: minimal `assigned_to` / `assigned_at` alanları ile queue assignment açılmıştır

Write path `admin_queue_assign_v1` üzerinden admin-only çalışır.

## Bulk İşlemler

Queue şu bulk aksiyonları sağlar:

- assign to me
- unassign
- approve selected
- reject selected

`approve/reject`, desteklemeyen tiplerde işlem yapmaz; sonuç kullanıcıya `işlenen / atlanan` sayısı olarak döner.

## Drill-down

Her satır için detail drawer açılır. Drawer içinde:

- normalize edilmiş özet alanlar
- decision support karti
  - why pending
  - why anomaly
  - risk / reputation / quality / anomaly sinyalleri
- benzer karar gecmisi karti
  - ayni kayit veya ayni business + target type baglaminda son audit kayitlari
  - onay / red / atama / handled sayaclari
- tip bazlı aksiyonlar
- kaynak ekrana geçiş
- ham payload görünümü

Queue detail decision-support sözleşmesi `admin_queue_v1` detay payload’ı ile beslenir. Özellikle:

- price suggestions icin quality confidence, anomaly score, conflict varyantlari, contributor reputation/risk ve business quality skoru
- reports icin reporter reputation/risk ve auto-moderated bilgisi
- claims icin claimant reputation/risk, evidence durumu ve auto-pending bilgisi
- business submissions icin missing field listesi ve review reason

Bu yapı, operasyon ekibinin tek queue üzerinden triage yapıp gerektiğinde kaynağa inmesini sağlar; karar gerekçesi ekranda görünür hale gelir.

## Sinir Notu

`media_flag` queue icinde operasyon tipi olarak gorunur; ancak dosya yukleme backend kontrati veya storage migration kararlari bu dokumanin kapsamina girmez.
