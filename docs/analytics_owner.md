# Owner Analytics

Bu ekran owner panelde `/owner/analytics` route'u altında çalışır. Ust seviye growth merkezi ise `/owner/growth` route'udur. Amaç, işletme sahibine gerçekten operasyonel değeri olan analitik yuzeyi vermektir; pazarlama ve lead toplama katmani `/owner/growth` ekraninda, detayli analitik okuma ise bu ekranda tutulur.

Bu dokuman owner analytics veri yuzeyi ve panel davranisinin tek kaynagidir.

Su konular burada tutulmaz:

- audit gorunurlugu
- data safety veya trash/versioning akislari
- genel panel olcekleme veya perf butcesi

Tek kaynaklar:

- audit gorunurlugu: `docs/audit.md`
- data safety: `docs/data_safety.md`
- panel performans snapshot'i: `docs/panel_perf.md`
- panel olcekleme kararleri: `docs/panel_scale.md`

## Kapsam

- QR taramaları
- Menü açılışları
- Kategori görüntülemeleri
- Ürün tıklamaları
- En çok ilgi gören ilk 10 ürün
- En çok görüntülenen ilk 10 kategori
- Kaynak kırılımı: `qr_short_link` ve `normal`
- Franchise veya zincir erişimi varsa şube karşılaştırması

## Veri Kaynağı

Panel mevcut `analytics_events` tablosunu kullanır. Yeni bir analytics tablosu açılmadı.

Owner panel bu veriyi `public.list_owner_analytics_v1(p_business_id, p_days, p_compare_branches)` RPC'si üzerinden okur.

## Event Mapping

- `qr_scanned`
  Owner KPI: QR taramaları
- `menu_link_opened`
  Owner KPI: Menü açılışları
- `menu_view`
  Kategori görüntüleme ve ürün etkileşimi türetimi

Türemiş alanlar:

- `category_views`
  `menu_view` event'i içinde `meta.category_name` varsa, yoksa `menu_items.catalog_category_name` fallback'i ile sayılır.
- `item_clicks`
  `menu_view` event'i içinde `meta.menu_item_id` veya `meta.menu_item_name` varsa sayılır.
- `top_items`
  Önce `meta.menu_item_name`, sonra `menu_items.name`, sonra `menu_item_id` fallback'i ile gruplanır.
- `top_categories`
  Önce `meta.category_name`, sonra `menu_items.catalog_category_name` fallback'i ile gruplanır.

## Yetki Modeli

RPC yalnız şu kullanıcılar için çalışır:

- admin
- ilgili işletmede `business_read` izni olan owner ekip üyeleri

Şube karşılaştırması yalnız seçili işletmenin `chain_id` alanı doluysa açılır. Karşılaştırma listesi, aynı zincirde olup kullanıcının `business_read` erişimi bulunan işletmeler ile sınırlıdır.

## Panel Davranışı

- Tarih preset'leri: 7 / 30 / 90 gün
- İstemci tarafında 5 dakikalık TTL cache kullanılır
- Yükleme ve hata yüzeylerinde `OwnerPanelFeedback` standardı kullanılır
- Üstte seçili işletme context bar'ı zorunludur
- `/owner/growth` ekraninda kisa analytics ozeti, growth sinyalleri, sponsorship katalogu ve sponsorship/Pro lead formu bulunur
- `/owner/analytics` bu growth yuzeyinin detay inceleme ekranidir

## Bilinen Sınırlar

- Event metadata eksikse ürün ve kategori detayları daha zayıf görünür.
- Bu ekran şu an günlük agregasyon ve top listeler verir; saatlik kırılım vermez.
- Kaynak kırılımı şu an en anlamlı iki giriş yüzeyi olan `qr_short_link` ve `normal` etrafında sade tutulur.

## Sonraki Adımlar

1. Saatlik trend ve yoğun saat dilimi kartı eklenebilir.
2. `menu_view` tarafında `menu_item_id` ve `category_name` metadata zorunluluğu artırılabilir.
3. Şube karşılaştırmasına dönüşüm oranı ve outbound click metrikleri eklenebilir.
4. Growth hub ile analytics detayi arasinda ortak filtre/paylasilabilir permalink modeli eklenebilir.

## Sinir Notu

Bu ekran analytics amaclidir; audit, queue veya restore akislarinin kaynagi olarak kullanilmamalidir.
