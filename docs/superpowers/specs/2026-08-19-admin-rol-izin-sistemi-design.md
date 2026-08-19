# Admin Rol/İzin Sistemi — Design

## Bağlam ve Sorun

Admin paneli (`app/yonetici/**`) bugün tamamen ikili bir erişim modeline sahip: `public.is_admin()` yalnızca `public.admin_users(user_id, created_at)` tablosunda bir üyelik olup olmadığına bakar. Bu tabloya eklenen **herkes** panelin tamamına (25 sayfa: İşletmeler, Kullanıcılar, Fraud Tespiti, Müşteri Destek, API Anahtarları, Roller, ...) sınırsız erişebiliyor.

`app/yonetici/roller/page.tsx` sayfası ve `auth.users.app_metadata.role` alanı (`super_admin` / `admin` / `community_mod` / `user`) bir rol *etiketi* gösteriyor, ama bu etiket hiçbir route veya RLS policy tarafından okunmuyor — tamamen kozmetik. Ayrıca `app/yonetici/kullanicilar/rol-degistir-istemci.tsx` bu etiketi **admin_users'a hiç girmemiş sıradan kullanıcılara bile** "Admin" olarak atayabiliyor; bu hiçbir gerçek yetki vermiyor ve yanıltıcı — mevcut bir hata.

Kullanıcı şu an panelin tek admini. İleride ekip büyürse, kimin hangi admin sayfalarını görebileceğini gerçekten kısıtlamak istiyor ("herşey herkese açık olmasın").

Referans: `roller.png` mockup'ı — rol listesi, izin matrisi, kullanıcı sayıları, aktif/pasif durum, rol türü (Sistem/Özel) gösteriyor. Mockup'taki 12 rolün çoğu (İçerik Yöneticisi, Reklam Yöneticisi, Ortak, Sadece Okuma, Askıya Alınmış...) **uydurma örnek veri** — gerçek sistemde seed edilmeyecek.

## Hedefler

1. Sayfa bazlı, gerçek (uygulanan) izin kontrolü: bir admin_users üyesinin hangi admin sayfalarını görebileceği rolüne bağlı olsun.
2. Roller sayfası mockup'a uyarlanır: gerçek rol CRUD'u (oluştur/düzenle/sil), gerçek istatistikler, gerçek kullanıcı atama.
3. Tek admin olan kullanıcı hiçbir aşamada kilitlenmesin (migration güvenli, geriye dönük uyumlu).
4. Eski kozmetik `app_metadata.role` sistemi kaldırılır, tek gerçek kaynak `admin_roles` olur.

## Hedef Dışı (Non-Goals)

- `admin_users`'a **yeni** üye ekleme UI'ı (bugün de yok, SQL ile yapılıyor — değişmiyor).
- Sayfa-içi aksiyon bazlı (okuma vs yazma) izin ayrımı — sadece sayfa görünürlüğü.
- RLS policy'lerinin per-role hale getirilmesi — bu tablolara yalnızca admin paneli erişiyor (başka istemci yok), bu yüzden Next.js katmanındaki kontrol yeterli gerçek güvenlik sınırı. `is_admin()` blanket RLS koruması savunma-derinliği olarak aynen kalır.
- Genel (`/yonetici/gosterge-panosu`) sayfası — her admin_users üyesi izinsiz görebilir, iniş sayfası.

## Veri Modeli

```sql
-- Kapalı küme: sidebar'daki 25 gerçek sayfayla birebir. "Genel Bakış" hariç (herkese açık).
CREATE TYPE public.admin_permission_key AS ENUM (
  'page:isletmeler', 'page:zincirler', 'page:kuyruklar', 'page:isletme-basvurulari',
  'page:raporlar', 'page:kullanicilar', 'page:yorumlar', 'page:itirazlar',
  'page:fis-basvurulari', 'page:cop-kutusu', 'page:olaylar', 'page:konumlar',
  'page:analitik', 'page:musteri-destek', 'page:oneriler', 'page:fiyat-onerileri',
  'page:fraud-tespiti', 'page:fotograf-moderasyon', 'page:feature-flags',
  'page:api-anahtarlari', 'page:roller', 'page:gozlemlenebilirlik',
  'page:gelistirme-araclari', 'page:kvkk-gdpr', 'page:gecici-yuklemeler'
);

CREATE TABLE public.admin_roles (
  id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name         text NOT NULL CHECK (char_length(btrim(name)) BETWEEN 1 AND 60),
  description  text CHECK (char_length(description) <= 200),
  is_system    boolean NOT NULL DEFAULT false,
  is_active    boolean NOT NULL DEFAULT true,
  permissions  admin_permission_key[] NOT NULL DEFAULT '{}',
  created_at   timestamptz NOT NULL DEFAULT now(),
  updated_at   timestamptz NOT NULL DEFAULT now(),
  created_by   uuid REFERENCES auth.users(id),
  updated_by   uuid REFERENCES auth.users(id)
);

ALTER TABLE public.admin_users ADD COLUMN role_id uuid REFERENCES public.admin_roles(id);
-- backfill: tüm mevcut admin_users → yeni seed edilen 'Süper Admin' sistem rolü
-- sonra: ALTER TABLE public.admin_users ALTER COLUMN role_id SET NOT NULL;
```

Seed (aynı migration içinde): tek bir **Süper Admin** sistem rolü, `is_system = true`, `permissions` = enum'daki tüm değerler. Mevcut `admin_users` satırları bu role bağlanır. Başka hiçbir rol seed edilmez (mockup'taki diğer roller gerçek değil).

`is_system = true` olan rol: silinemez, düzenlenemez, `is_active = false` yapılamaz (RPC seviyesinde blok, `P0003`).

## RPC'ler

- `public.has_permission_v1(p_permission admin_permission_key) RETURNS boolean` — `admin_users` → `admin_roles` join, `role.is_active AND p_permission = ANY(role.permissions)`.
- `public.get_my_admin_permissions_v1() RETURNS admin_permission_key[]` — kenar çubuğu filtrelemesi için, çağıranın rolünün tüm izinlerini döner (admin değilse boş dizi).
- `public.admin_create_role_v1(p_name text, p_description text, p_permissions admin_permission_key[])` — `has_permission_v1('page:roller')` gerektirir.
- `public.admin_update_role_v1(p_role_id uuid, p_name text, p_description text, p_permissions admin_permission_key[], p_is_active boolean)` — `is_system` ise `P0003`.
- `public.admin_delete_role_v1(p_role_id uuid)` — `is_system` veya role bağlı `admin_users` varsa `P0003` (önce kullanıcıları başka role taşı mesajı).
- `public.admin_assign_user_role_v1(p_user_id uuid, p_role_id uuid)` — yalnızca **var olan** `admin_users` satırını günceller; `p_user_id` admin_users'ta yoksa `P0001`.

Hepsi `SECURITY DEFINER`, `is_admin()` + ilgili `has_permission_v1('page:roller')` guard'ı ile.

## Next.js Uygulama Katmanı

- `src/lib/admin-izinler.ts` — `ADMIN_PERMISSIONS` sabiti: `{key, label, group}[]`, kabuktaki 3 nav bölümüyle birebir gruplu. Enum'la senkron tutulur (yorum satırıyla belgelenir).
- `src/lib/yetki-kontrol.ts` — `requirePermission(permission)`: server-side, `has_permission_v1` RPC'sini çağırır; `page.tsx`'lerde `false` ise `PanelEmptyState` ile "Yetkiniz Yok" render edilir (redirect değil — URL'i koruyarak net mesaj), `route.ts`'lerde `403` JSON döner.
- Kenar çubuğu (`yonetici-kabuk-istemcisi.tsx`): mount'ta `get_my_admin_permissions_v1()` çağrılır, `adminNavSections` bu izin listesine göre filtrelenir. Genel Bakış her zaman görünür.

## Roller Sayfası (mockup uyarlaması)

- Stat kartları: Toplam Rol, Aktif Rol (+trend), Sistem Rolü (=1 sabit), Özel Rol, Kullanıcı Atanan (=gerçek `admin_users` sayısı), Son Güncelleme (en son `updated_at` + `updated_by` adı).
- Arama + Durum filtresi (server-driven, mevcut sayfalarla aynı desen).
- Tablo: Rol Adı, Açıklama, Tür (Sistem/Özel rozeti), Kullanıcı Sayısı, Durum, Son Güncelleme, İşlemler (düzenle modal / sil — sistem veya kullanıcı-atanmışsa disabled+tooltip).
- Sidebar: Rol Türüne Göre Dağılım (donut, mevcut Donut bileşeni deseni), Rol Durumuna Göre Dağılım (bar), Hızlı İşlemler (Yeni Rol Oluştur modal).
- Yeni/Düzenle Rol modalı: ad, açıklama, 25 izin — 3 nav grubuna göre bölümlenmiş checkbox listesi (hepsini seç/temizle kısayolu grup başına).
- Kullanıcı atama: rol satırına tıklayınca açılan slide-over'da o role atanmış `admin_users` listesi + başka role taşıma dropdown'u (mevcut admin_users listesi zaten küçük olacağı için basit liste yeterli, pagination gereksiz).

## Eski Sistemin Temizliği

**Kapsam düzeltmesi (plan yazımı sırasında bulundu):** `app/yonetici/kullanicilar/**` sayfasındaki `role` / `ROLE_MAP` / `RolDegistirIstemci` / `app/sunucu/yonetici/kullanici-rol/route.ts` aslında **admin_users'tan tamamen bağımsız, kendi başına çalışan ayrı bir özellik** — tüm kullanıcı tabanında (admin olsun olmasın herkes) genel bir rol etiketi tutuyor ve `super_admin` etiketli tek bir hesabı toplu banlama/tekli banlamadan koruyor. Bu, admin panelin sayfa erişim izinleriyle ilgisi olmayan, kendi içinde tutarlı ve işlevsel bir mekanizma. **Bu spec kapsamında dokunulmuyor** — silinmiyor, değiştirilmiyor.

- `yonetici-kabuk-istemcisi.tsx` içindeki `ROL_ETIKETLERI` / `app_metadata.role` okuma mantığı — **yalnızca giriş yapmış admin'in kendi rozetini** gösteriyor (kenar çubuğu üstündeki "Süper Yönetici" etiketi); bu, o admin'in gerçek `admin_roles.name`'i ile değiştirilir. Kullanıcılar sayfasındaki genel `role` sistemiyle karışmaz, ayrı bir okuma noktası.
- `app/yonetici/roller/page.tsx` — mevcut `ROLES` sabiti, `getUserRole()`, statik `PERMISSIONS` dizisi tamamen kaldırılır, yerini yukarıdaki gerçek veri alır. Bu dosya `app_metadata.role` okumuyordu zaten sadece kendi içinde sabit bir liste tutuyordu — kaldırılması başka hiçbir dosyayı etkilemez.

## Faz Planı

**Plan A (bu spec'in birebir kapsamı, tek başına eksiksiz):** Migration (enum+tablolar+seed+RPC'ler) + `admin-izinler.ts` + `yetki-kontrol.ts` + kenar çubuğu filtreleme + Roller sayfası tam yeniden yazımı + Kullanıcılar sayfası entegrasyonu + eski sistem temizliği. Bu faz bittiğinde sistem tamamen çalışır ve test edilebilir durumda olur, ama **mevcut 25 sayfanın hiçbiri henüz `requirePermission` çağırmıyor** — yani Süper Admin dışında bir rol oluşturup kısıtlı izinler verseniz bile, o kullanıcı hâlâ URL'i doğrudan yazarak her sayfaya girebilir (kenar çubuğunda görünmez ama route açık).

**Plan B (ayrı plan/PR):** 25 sayfanın `page.tsx`'ine ve ilgili mutation `route.ts`'lerine `requirePermission(...)` eklenir — fiili kısıtlama burada devreye girer. Mekanik ama hacimli (25 × ~2 dosya). Plan A onaylanıp doğrulandıktan sonra ayrı bir plan olarak yazılacak.

## Doğrulama

- Migration sonrası: `select count(*) from admin_users where role_id is null` → 0 olmalı (kimse rolsüz kalmamalı).
- Süper Admin rolünün `permissions` dizisi enum'daki tüm değerleri içeriyor mu — otomatik sorguyla doğrulanır (yeni bir sayfa eklenip enum'a girilirse Süper Admin otomatik kapsar, çünkü tüm enum değerleri seed migration'da elle yazılır — yeni değer eklenirse ayrı migration'da Süper Admin'e de eklenmesi gerekir, bu nottan hatırlatılacak).
- `pnpm run typecheck` + `pnpm run lint` (0 hata).
- Tarayıcı: yeni bir test rolü oluştur (ör. yalnızca `page:musteri-destek` izniyle), mevcut admin kullanıcıya geçici atama YAPILMADAN sadece CRUD akışını doğrula (oluştur → listede görün → düzenle → sil), gerçek admin_users'ın rolü değiştirilmez (kilitlenme riski yok). Test rolü sonda silinir.
- `mcp__supabase__get_advisors(type=security)` — yeni RPC'ler için beklenmeyen bulgu kontrolü.
