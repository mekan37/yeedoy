# Admin Global Search

Bu doküman `panel_flutter_web` içindeki global yönetici aramasının sözleşmesini ve operasyon davranışını tanımlar.

## Amaç

Admin panelde tek bir arama yüzeyinden şu kayıt tiplerine erişmek:

- İşletmeler
- Kullanıcılar
- Raporlar
- İşletme başvuruları
- Sahiplik talepleri
- Menü öğeleri

## Güvenlik

- Arama yalnızca `admin` yetkisine sahip kullanıcılar için açıktır.
- Veri erişimi `public.search_admin_v1` RPC fonksiyonu üzerinden yapılır.
- Fonksiyon `security definer` çalışır ve ilk satırda `public.is_admin()` kontrolü yapar.
- Admin olmayan çağrılarda fonksiyon veri döndürmez, `not_admin` hatası üretir.

## UX Kararı

- Giriş noktası admin shell topbar içindeki global arama alanıdır.
- Arama çalıştırıldığında `/admin/search?q=...` rotasına gidilir.
- Sonuçlar kategori bazlı gruplandırılır.
- Her satırda iki hızlı aksiyon vardır:
  - Yeni sekmede aç
  - Kimliği kopyala
- Klavye navigasyonu desteklenir:
  - `Yukarı / Aşağı`: sonuç seçimini taşır
  - `Enter`: seçili sonucu açar

## Rate Limit ve Performans

- İstemci tarafında `300ms` debounce uygulanır.
- `2` karakterden kısa sorgular için RPC çağrısı yapılmaz.
- RPC kategori başına en fazla `6` kayıt döndürür.

## Sonuç Yönlendirmeleri

- İşletme sonucu: `/admin/businesses?q=...`
- Kullanıcı sonucu: `/admin/users/:id`
- Rapor sonucu: `/admin/queue?type=report&q=...`
- İşletme başvurusu sonucu: `/admin/queue?type=business_submission&q=...`
- Sahiplik talebi sonucu: `/admin/queue?type=claim&q=...`
- Menü öğesi sonucu: `/admin/businesses?q=...`

## Notlar

- Bu ilk sürümde arama, mevcut admin workflow ekranlarına yönlendirir; her kayıt tipi için birebir detay deep-link zorunlu tutulmadı.
- Genişleme noktası olarak `search_admin_v1` içine ek kategori veya ağırlıklandırma mantığı eklenebilir.
