# Owner Denetim Kaydı Sayfası — Faz 1 (Audit Log Altyapısı + Sayfa)

## Arka plan

Kullanıcı, `owner/(panel)/audit` ("Denetim Kaydı") sayfası için bir mockup
görseli paylaştı: ekip üyelerinin (Personel/Yönetici) işletme üzerindeki
eylemlerini (menü düzenleme, ürün ekleme/silme, fotoğraf yükleme, işletme
bilgisi güncelleme, kampanya oluşturma, ekip rolü değişikliği, yorum
yanıtlama, rezervasyon notu, QR menü önizleme) tarih/üye/işlem-türü
filtreleriyle listeleyen, sayfalanmış bir tablo.

### Denetim bulguları (mevcut kod, 2026-07-17)

- `app/owner/(panel)/audit/page.tsx` doğrudan `admin_audit_log` tablosunu
  sorguluyor. Bu tablonun RLS politikası (`admin_audit_log_admin_all`)
  **sadece `is_admin()` olan kullanıcılara** SELECT izni veriyor — normal
  bir owner için sorgu her zaman boş döner.
- `app/owner/(panel)/activity/page.tsx` (paralel bir sayfa) var olmayan
  kolonlar (`resource_type`, `resource_id`, `metadata`) sorguluyor; gerçek
  şema `target_table`/`target_id`/`meta` kullanıyor — bu sayfa muhtemelen
  hata veriyor.
- **Kritik:** Owner panelindeki hiçbir mutasyon (menü CRUD, fotoğraf
  yükleme, işletme bilgisi güncelleme, kampanya oluşturma, ekip rolü
  değiştirme, yorum yanıtlama, rezervasyon notu, QR önizleme) şu anda
  hiçbir audit log'a yazmıyor. `admin_audit_log`'a yazan tek yerler
  platform admin işlemleridir (SuperAdmin onayları vb.).
- `business_team_memberships` tablosu gerçek ve kullanılabilir: `business_id,
  chain_id, user_id, invite_email, role (owner|manager|editor|staff|viewer),
  created_by, accepted_at, revoked_at`. Rol etiketleri zaten
  `app/owner/(panel)/team/page.tsx`'te tanımlı: `manager→Yönetici,
  editor→Editör, staff→Personel, viewer→İzleyici` — bu eşleme aynen
  kullanılacak, yeni bir etiketleme icat edilmeyecek.
- `request_ip_v1()` ve `request_header_v1()` fonksiyonları mevcut ve
  `admin_audit_log` akışında hâlâ kullanılıyor
  (`20260619000001_remove_ip_metadata_from_policy_acceptances.sql`
  yorumunda açıkça korunduğu belirtiliyor — 2026-06-19 KVKK kararı
  **sadece** `user_policy_acceptances`/`business_policy_acceptances`
  tablolarından IP/UA otomatik doldurmayı kaldırdı, audit log akışına
  kasıtlı olarak dokunmadı). Yeni tabloda IP/UA yakalamak için bu mevcut
  helper'lar tekrar kullanılacak — yeni bir mekanizma icat edilmeyecek.
- `pg_cron` bu projede zaten kullanılıyor
  (`20260424000003_scheduled_menu_activation.sql` örneği) — retention
  temizleme job'u aynı deseni takip edecek.

### Kapsam kararı

Bu proje **çok büyük** olduğu için iki faza bölündü:

- **Faz 1 (bu spec):** Yeni audit log tablosu + RLS + yazma/okuma RPC'leri
  + retention (12 ay) temizleme cron job'u + Denetim Kaydı sayfasının
  kendisi (filtre, tablo, sayfalama). Sayfa Faz 1 sonunda **çalışır** ama
  henüz hiçbir mutasyon log yazmadığı için **boş/az veriyle** gösterilir.
- **Faz 2 (ayrı spec+plan+PR, bu projenin kapsamı dışında):** 10 eylem
  türünün ilgili 8 özellik alanındaki (menü, fotoğraf, işletme bilgisi,
  kampanya, ekip, yorum, rezervasyon, QR) gerçek mutasyon noktalarına
  `log_business_action_v1` çağrısı eklenmesi.

## Veri modeli

### Yeni tablo: `business_audit_log`

| Kolon | Tip | Not |
|---|---|---|
| `id` | uuid PK | `gen_random_uuid()` |
| `business_id` | uuid NOT NULL | `references businesses(id) on delete cascade` |
| `actor_id` | uuid NOT NULL | `references auth.users(id)` |
| `actor_role` | text NOT NULL | Yazma anında `business_team_memberships.role`'den snapshot alınır (owner_claims eşleşiyorsa `'owner'`) |
| `action` | text NOT NULL | Sabit slug listesi (aşağıda) |
| `description` | text NOT NULL | Yazma anında oluşturulan, insan-okunur Türkçe açıklama (ör. `"Cheeseburger" adlı ürünün fiyatı güncellendi.`) |
| `target_table` | text | ör. `menu_items`, `businesses`, `campaigns` |
| `target_id` | uuid | |
| `target_label` | text | İlgili Kayıt kolonunda gösterilecek kısa etiket (ör. `Menü Öğesi #M-1024`) — yazma anında çağıran taraf oluşturur |
| `ip_address` | text | `request_ip_v1()` |
| `user_agent` | text | `request_header_v1('user-agent')` |
| `created_at` | timestamptz NOT NULL default now() | |

İndeksler: `(business_id, created_at desc)`, `(business_id, actor_id, created_at desc)`,
`(business_id, action, created_at desc)`.

**Immutability:** Tabloya `UPDATE`/`DELETE` grant edilmez (ne `authenticated`
ne `anon`) — sadece `SELECT` (RLS ile kısıtlı) ve yazma RPC'sinin
`SECURITY DEFINER` içinden yaptığı `INSERT`. Bu, mockup'taki "düzenlenemez
veya silinemez" notunu gerçek bir kısıt haline getirir.

### RLS

`SELECT`: İşletmenin approved `owner_claims` kaydı olan KULLANICI VEYA o
`business_id` için aktif (`accepted_at IS NOT NULL AND revoked_at IS NULL`)
`business_team_memberships` kaydı olan kullanıcı.

Doğrudan `INSERT`/`UPDATE`/`DELETE` grant edilmez.

### RPC 1 — Yazma: `log_business_action_v1`

```
log_business_action_v1(
  p_business_id uuid,
  p_action text,
  p_description text,
  p_target_table text DEFAULT NULL,
  p_target_id uuid DEFAULT NULL,
  p_target_label text DEFAULT NULL,
  p_meta jsonb DEFAULT '{}'::jsonb
) RETURNS void
```

- `SECURITY DEFINER`. `auth.uid()` işletmenin owner'ı ya da aktif ekip
  üyesi değilse `unauthorized` (`P0002`) fırlatır.
- `actor_role`'ü işletmedeki `owner_claims`/`business_team_memberships`
  kaydından türetir.
- `ip_address`/`user_agent`'ı `request_ip_v1()`/`request_header_v1('user-agent')`
  ile doldurur.
- Faz 2'de tüm mutasyon noktalarından çağrılacak. Faz 1'de sadece
  fonksiyon var olur, henüz hiçbir yerden çağrılmaz (kasıtlı — Faz 2 işi).

### RPC 2 — Okuma: `get_business_audit_log_v1`

```
get_business_audit_log_v1(
  p_business_id uuid,
  p_page int DEFAULT 1,
  p_page_size int DEFAULT 10,
  p_actor_id uuid DEFAULT NULL,
  p_action text DEFAULT NULL,
  p_date_from date DEFAULT NULL,
  p_date_to date DEFAULT NULL
) RETURNS TABLE(
  id uuid, created_at timestamptz, actor_id uuid, actor_name text,
  actor_avatar_url text, actor_role text, action text, description text,
  target_table text, target_id uuid, target_label text, ip_address text,
  total_count bigint
)
```

- `SECURITY DEFINER`. Aynı yetki kontrolü (owner veya aktif ekip üyesi).
- `actor_name`/`actor_avatar_url` `user_profiles` (`display_name`,
  `avatar_url`) ile join'lenir; kayıt yoksa e-posta/`Kullanıcı` fallback.
- `total_count` her satırda `count(*) OVER()` ile tekrarlanır (sayfalama
  toplamı için — sayfa bileşeninde ilk satırdan okunur).
- Filtreler: `p_actor_id`, `p_action`, `p_date_from`/`p_date_to` hepsi
  opsiyonel, `NULL` ise filtre uygulanmaz.

### Retention cron job

`purge_expired_business_audit_log()` fonksiyonu, `created_at < now() -
interval '12 months'` olan satırları siler. `pg_cron` ile günlük
(`0 3 * * *`, gece 03:00) çalışacak şekilde zamanlanır — mevcut
`scheduled_menu_activation` job'unun deseni birebir takip edilir
(`create extension if not exists pg_cron`, `cron.unschedule` sonra
`cron.schedule`).

## Eylem türleri (Faz 1'de sadece sabit liste olarak tanımlanır; yazma
noktaları Faz 2'de eklenir)

| `action` slug | Türkçe açıklama şablonu | İlgili tablo |
|---|---|---|
| `menu_item_updated` | `"{ürün}" adlı ürünün {alan} güncellendi.` | `menu_items` |
| `menu_item_created` | `"{ürün}" adlı yeni ürün eklendi.` | `menu_items` |
| `menu_item_deleted` | `"{ürün}" adlı ürün silindi.` | `menu_items` |
| `photo_uploaded` | `Ürün fotoğrafı yüklendi.` | `menu_items` / medya |
| `business_info_updated` | `İşletme {alan} güncellendi.` | `businesses` |
| `campaign_created` | `"{kampanya}" kampanyası oluşturuldu.` | `campaigns`/pazarlama |
| `team_role_changed` | `"{ad}" adlı kullanıcının rolü {yeni-rol} olarak güncellendi.` | `business_team_memberships` |
| `review_replied` | `Bir kullanıcı yorumuna yanıt verildi.` | `business_reviews` |
| `reservation_note_added` | `Rezervasyona işletme notu eklendi.` | `reservations` |
| `qr_menu_previewed` | `QR menü önizleme görüntülendi.` | `menus` |

Bu liste, sayfa tarafındaki "İşlem" filtre dropdown'unun seçeneklerini de
oluşturur (Faz 1'de sabit/hardcoded liste — henüz veri olmasa da filtre
seçenekleri gösterilir).

## Sayfa tasarımı — `app/owner/(panel)/audit/`

Mevcut `page.tsx` (80 satır, kırık sorgu) tamamen değiştirilir; yeni bir
`audit-client.tsx` eklenir (analytics sayfasındaki server/client component
ayrımı deseni takip edilir).

### Header
`PanelPageHeader` — eyebrow "Owner", title "Denetim Kaydı", description
"Ekip üyelerinizin yaptığı tüm işlemleri burada görüntüleyebilir ve
filtreleyebilirsiniz." `compactActions`: "Dışa Aktar" (ikincil/outline,
disabled) + "Denetim Raporu" (birincil/kırmızı, disabled) — ikisi de
analitik sayfasındaki "Detaylı Raporu İndir" ile aynı
`disabled title="Yakında aktif olacak"` deseninde.

### Filtre satırı
- Tarih aralığı: iki `<input type="date">` (başlangıç/bitiş), varsayılan
  son 30 gün
- Üye: `<select>` — işletmenin owner'ı + aktif `business_team_memberships`
  üyeleri (ad + rol etiketiyle)
- İşlem türü: `<select>` — yukarıdaki 10 sabit eylem türü + "Tüm İşlemler"
- "Filtrele" butonu — mevcut analitik sayfasındaki `router.push` ile
  query-param güncelleme deseni takip edilir (`?from=&to=&actor=&action=&page=`)

### Tablo
Kolonlar: Tarih & Saat, Kullanıcı (avatar + ad + rol rozeti — `team/page.tsx`
`ROLE_LABELS` renk/etiket eşlemesi birebir kullanılır), İşlem (eylem
türüne göre renkli ikon + Türkçe etiket), Açıklama, İlgili Kayıt
(`target_label`, yoksa `—`), IP Adresi (yoksa `—`). Satır sonu "⋮" — Faz
1'de işlevsiz/dekoratif (disabled), gerçek bir aksiyon yok.

Boş durum: mevcut `PanelEmptyState` + `ShieldIcon` deseni korunur (Faz 1
sonunda veri olmayacağı için bu durum sık görülecek — kasıtlı, Faz 2
sonrası dolacak).

### Sayfalama
Sayfa numarası butonları + önceki/sonraki, "Toplam N işlem" metni —
`get_business_audit_log_v1`'in döndürdüğü `total_count`'tan hesaplanır.
Sayfa başı 10 kayıt (mockup'taki gibi).

### Alt not
"Denetim kayıtları 12 ay boyunca saklanır. Güvenliğiniz için bu kayıtlar
düzenlenemez veya silinemez." — hem gerçek bir backend kısıtını (grant
yok + retention cron) hem de kullanıcıya bilgilendirmeyi yansıtır.

## Kapsam dışı (Faz 2'ye veya tamamen bu projenin dışına bırakılan)

- 10 eylem türünün gerçek mutasyon noktalarına (`menu-islemleri.ts`,
  `ekip` rol değiştirme, kampanya oluşturma, yorum yanıtlama, rezervasyon
  notu, QR önizleme, fotoğraf yükleme, işletme bilgisi güncelleme) log
  yazma çağrısı eklenmesi — **Faz 2, ayrı spec+plan+PR**.
- Gerçek CSV/PDF export özelliği (butonlar disabled kalır).
- "⋮" satır menüsünün işlevsel hale getirilmesi (ör. detay görüntüleme).
- Rol bazlı görünürlük kısıtlaması (ör. Personel sadece kendi eylemlerini
  görsün) — Faz 1'de herkes (owner + aktif ekip üyeleri) işletmenin tüm
  audit log'unu görebilir; daha ince taneli izin kontrolü istenirse ayrı
  bir karar.

## Test / doğrulama planı

- `flutter analyze` gerekmiyor (bu değişiklik sadece web + SQL)
- `npm run typecheck` + `npm run lint` (Next.js değişikliği)
- Yeni RPC'ler için: yerel Supabase'de manuel çağrı testi (owner ve
  ekip-dışı bir kullanıcı ile — ikincisi `unauthorized` almalı)
- Manuel: `npm run dev` ile `/owner/audit` sayfası açılıp boş durum,
  filtre kontrolleri ve sayfalama gözle doğrulanır
