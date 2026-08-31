# Yöresel Yemek Önerisi (Alt-Proje 1/3) — Design Doc

## Bağlam

Kullanıcı, Yeedoy için üç senaryolu bir "konum-farkında, davranış-öğrenen keşif motoru" vizyonu tanımladı:

1. **Yöresel yemek önerisi** — kullanıcı Ankara'da yaşıyor ama Kayseri'ye seyahat ettiğinde uygulama Kayseri'nin yöresel lezzetlerini hem push bildirim hem akış olarak önermeli.
2. **Alışkanlık öğrenme** — kullanıcı sık sık pazar günü kahvaltı yapıyorsa uygulama bunu öğrenip önermeli.
3. **Fiziksel varlık tespiti + menü teşviki** — kullanıcı menüsü olmayan bir işletmede (örn. Şimşek Aspava) bir süre bulunduysa, uygulama menü yüklemesi için teşvik etmeli.

Bu üç senaryo bağımsız alt-sistemler gerektiriyor (artan mühendislik zorluğunda: 1 en hafif, 3 en ağır — sürekli/arka plan konum takibi ve geofencing bugün hiç yok). Kullanıcıyla **1 → 2 → 3** sırasıyla ilerlenmesi kararlaştırıldı. Bu doküman sadece **Alt-Proje 1**'i kapsıyor.

**Altyapı denetimi bulguları** (mevcut kod tabanı taranarak):
- Konum: `uygulamalar/mobil/lib/core/location/user_location_controller.dart` — `geolocator` ile **tek seferlik** (uygulama açılışında) konum çekimi, şehir/ilçe/mahalleye reverse-geocode ediyor. Sürekli takip veya geofencing yok.
- Yöresel mutfak etiketleme: hiçbir yerde yok (`packages/shared_models`, migrasyonlar, her iki uygulama tarandı).
- Öneri motoru: `get_smart_feed_v2` (şehir + saat + hava durumu bağlamlı, ama kullanıcı bazlı kişiselleştirme yok).
- Push: `firebase_messaging` mobilde kurulu, gerçek FCM token kaydı var (`push_notification_service.dart`) — ama sadece admin'in elle gönderdiği kampanyalar (`/yonetici/push-kampanyalari`) için. Kullanıcı-tetiklemeli/otomatik push yolu yok.
- `user_profiles.city` kolonu DB'de var ama hiçbir UI'da (kayıt formu, profil ayarları) düzenlenemiyor — şu an tüm kullanıcılarda boş.

## Hedefler

- Kullanıcı ev şehrinden farklı bir şehirde olduğunda, o şehrin yöresel lezzetlerini sunan işletmeleri hem keşif akışında hem de (tekilleştirilmiş) bir push bildirimle önermek.
- Yöresel etiket kataloğunu yönetici panelinden yönetilebilir kılmak — 81 il için başlangıç seed verisiyle.
- Var olan FCM gönderim altyapısını genişletmek (yeniden kurmadan), tek-kullanıcı hedefli tetikleme yolu eklemek.

## Kapsam Dışı

- Sürekli/arka plan konum takibi, geofencing, dwell-time tespiti (Alt-Proje 3'ün konusu).
- Kullanıcı davranış/alışkanlık öğrenme (Alt-Proje 2'nin konusu).
- Web uygulaması — bu özellik v1'de **sadece mobil**. Konum tespiti ve push altyapısı bugün yalnızca mobil uygulamada var; web'de bugün var olan bir özelliğin mobile taşınması değil, sıfırdan mobile özgü bir yetenek inşası olduğu için CLAUDE.md'nin web/mobil parite kuralına aykırı değil, bilinçli bir v1 kapsam kararı.
- Bir işletmenin birden fazla yöresel etiket taşıması (v1'de 1 işletme → 0 veya 1 etiket).
- Ödeme/entitlement, tema/kampanya entegrasyonu.

## Mimari

```
Mobil uygulama açılır
        │
        ▼
user_location_controller.dart (mevcut, tek seferlik) → şehir çözümlenir
        │
        ▼
current_city != user_profiles.city (ev şehri)?  ──── hayır → hiçbir şey olmaz
        │ evet
        ▼
İlgili şehir için regional_cuisine_tags + etiketli işletme var mı?  ──── hayır → hiçbir şey olmaz
        │ evet
        ├──────────────────────────────┬───────────────────────────────────┐
        ▼                               ▼
   FEED (her açılışta,             PUSH (check_regional_recommendation_v1 RPC)
   dedup yok)                       ├─ son 14 günde bu user+city için event var mı?
   → keşif akışının üstünde         │    varsa → hiçbir şey yapma
     kaydırılabilir bant            │    yoksa → regional_recommendation_events'e yaz
                                     │            + mevcut FCM gönderim yolunu tetikle
```

**Neden feed dedup'suz, push dedup'lu:** Feed banner'ı pasif ve göz ardı edilebilir — spam sayılmaz, her açılışta güncel durumu yansıtması doğaldır. Push interrupt edicidir; kullanıcı Kayseri'de 5 gün kalsa bile 14 günlük pencerede sadece 1 bildirim alır.

**Push gönderimi:** Var olan admin-broadcast FCM gönderim mekanizması (implementasyon planında tam olarak bulunacak) yeniden kullanılır — sadece tek-kullanıcı hedefli yeni bir tetikleme yolu eklenir, FCM entegrasyonu sıfırdan kurulmaz.

**Şehir karşılaştırma riski:** `current_city != user_profiles.city` basit bir string eşitliği değil — Google Maps V5 pipeline'ında daha önce tam bu sınıftan bir bug yaşandı (Türkçe İ/i harflerinin `lower()` ile birleşik işaret/combining-mark üretmesi, il/ilçe eşleşmesini bozması). Reverse-geocode'dan gelen şehir adı ile `regional_cuisine_tags.city`/`user_profiles.city`'de saklanan kanonik il adı, aynı normalize fonksiyonuyla (Türkçe-güvenli, `toLocaleLowerCase('tr')` veya eşdeğeri) karşılaştırılmalı — implementasyon planında ayrı bir adım olarak ele alınacak.

## Veri Modeli

```sql
-- Şehir bazlı yöresel yemek kataloğu — yönetici panelinden CRUD
CREATE TABLE public.regional_cuisine_tags (
  id          uuid primary key default gen_random_uuid(),
  city        text not null,
  label       text not null,        -- örn. "Kayseri Mantısı"
  created_at  timestamptz not null default now(),
  unique (city, label)
);

-- businesses'a genişletme (nullable FK, v1'de 1 işletme → 0 veya 1 etiket)
ALTER TABLE public.businesses
  ADD COLUMN regional_tag_id uuid references public.regional_cuisine_tags(id);

-- user_profiles.city zaten var — sadece profil ayarları UI'sinde
-- düzenlenebilir hale getiriliyor, şema değişikliği yok.

-- Push tekilleştirme
CREATE TABLE public.regional_recommendation_events (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null references auth.users(id) on delete cascade,
  city        text not null,
  sent_at     timestamptz not null default now()
);
CREATE INDEX ON public.regional_recommendation_events (user_id, city, sent_at);
```

Yeni `admin_*` RPC'ler (kategori CRUD, işletmeye etiket atama) CLAUDE.md'nin standart kuralına tabi: `GRANT EXECUTE ... TO authenticated` sonrası açıkça `REVOKE EXECUTE ... FROM anon`. RPC adlandırması ve route handler şablonu için `rpc-and-route-handler-standards` skill'i uygulama planı aşamasında referans alınacak.

## Bileşenler

**Yönetici paneli** (`/yonetici` altına yeni bölüm):
- Şehir → yöresel etiket kataloğu yönetimi (ekle/düzenle/sil).
- Mevcut işletme düzenleme sayfasına "Yöresel Etiket" alanı (o işletmenin şehrindeki etiketlerden dropdown).
- **81 il için başlangıç seed verisi**: yaygın bilinen yöresel mutfak eşleşmeleriyle (Kayseri→Mantı/Pastırma/Sucuk, Gaziantep→Baklava/Katmer, Adana→Kebap, Hatay→Künefe, vb.) önceden doldurulmuş bir migration; admin daha sonra düzenler/genişletir. Boş kalan iller için sistem sessizce hiçbir şey önermez (bkz. Uç Durumlar).

**Mobil**:
- Kayıt formuna "Yaşadığın şehir" seçici — yeni kullanıcılar en baştan ev şehrini belirtir (opsiyonel, atlanabilir).
- Profil ayarlarına da aynı seçici — daha sonra değiştirebilmek veya kayıt sırasında atlayan kullanıcıların sonradan doldurabilmesi için.
- Keşif/anasayfa akışının üstüne "📍 {Şehir}'desin! İşte yöresel lezzetler" başlıklı, kaydırılabilir kart bandı.
- `check_regional_recommendation_v1` RPC çağrısı (uygulama açılışında, şehir uyuşmazlığı tespit edildiğinde).

## Uç Durumlar

- Kullanıcı kayıt sırasında şehir seçmeyi atlamış ve profilden de doldurmamış → karşılaştırma yapılamaz, özellik sessizce devre dışı. Kayıt formunda bu alan zorunlu tutulmaz (kayıt sürtünmesini artırmamak için — bkz. 4.5 no'lu UX denetimi maddesi "gereksiz alan yok" ilkesi).
- Gidilen şehirde etiketli işletme yok (81 il baştan doldurulsa da bazı iller/etiketler eksik kalabilir) → ne banner ne push, sessiz atlama.
- Push izni verilmemiş → feed banner yine çalışır (yerel state'e dayanır), push atlanır — mevcut FCM altyapısı zaten izinsiz token üretmiyor.
- Aynı gün uygulama defalarca açılıyor → RPC'nin 14 günlük penceresi tekrar push atılmasını sunucu tarafında engeller (istemci taklit edemez).
- Kullanıcı ev şehrinde geziniyor ama farklı bir ilçede → mevcut konum çözümleme zaten il (city) seviyesinde çalışıyor, ilçe farkı tetiklemez.

## Test Stratejisi

- RPC: 14 günlük dedup penceresinin sınır durumları (tam 14 gün önce, 13 gün önce, farklı şehir aynı gün).
- Admin CRUD: `admin_*` RPC'lerde anon revoke'un gerçekten uygulandığının doğrulanması (proje standardı, `get_advisors` ile kontrol edilebilir).
- Mobil: ev şehri boşken/doluyken, konum izni verilmemişken, push izni verilmemişken banner'ın doğru davranması (manuel/widget test, CLAUDE.md gereği `flutter analyze` zorunlu).
