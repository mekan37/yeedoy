# Paylaşımlı Moderasyon Kara Listesi + Strike Entegrasyonu

**Durum:** Onaylandı, plan aşamasına geçiliyor
**Tarih:** 2026-09-01

## Arka Plan / Kök Sorunlar

Bu tasarım, aynı oturumda yapılan bir denetim sırasında bulunan üç ayrı, birbirine bağlı sorunu çözüyor:

1. **Küfür/argo kara listesi mobilde bundle edilmiş bir `.txt` dosyası** (`assets/json/karaliste.txt`, 699 terim), sunucuda ise `contains_obfuscated_profanity_v1()` fonksiyonunun içinde ~15 kalıplık ayrı, çok daha küçük bir hardcoded regex var. İkisi senkron değil — mobil UI'ı bypass edip RPC'yi doğrudan çağıran biri (veya web) 699 terimin büyük çoğunluğunu sunucu tarafında hiç engellenmeden geçirebilir.
2. **Web'in yorum yazma sayfaları RPC katmanını tamamen bypass ediyor.** `app/(kimlik)/isletme/[slug]/yorumlar/new/page.tsx` ve `app/(kimlik)/b/[slug]/reviews/new/page.tsx` (ikincisi Temmuz'daki EN→TR temizliğinden kaçmış bir duplicate), `submit_review_v3` RPC'sini çağırmak yerine doğrudan `supabase.from('reviews').insert(...)` yapıyor. Bu da profanity kontrolünün (RPC gövdesinin içinde yaşadığı için) web'den gelen yorumlarda **hiç çalışmamasına** yol açıyor. RLS (`user_id = auth.uid()`) ve tablo trigger'ları (rate-limit, abuse-control) hâlâ çalışıyor — sadece profanity kontrolü atlanıyor.
3. **Küfürlü içerik tespit edildiğinde bir yaptırım uygulanmıyor.** Sunucuda zaten tam işleyen bir strike/shadow-ban altyapısı var (`user_moderation_strikes` tablosu + `add_moderation_strike_v1(user_id, reason, source)`: 30 günde 3 strike → otomatik `user_profiles.shadow_banned = true`), ama bu hiçbir yerden profanity tespitiyle tetiklenmiyor — sadece ayrı bir akışta (düşük kaliteli rapor reddi) kullanılıyor.

## Kapsam

**Dahil:**
- Kara liste terimlerinin tek doğru kaynağı: yeni bir Postgres tablosu.
- Sunucu tarafı profanity kontrolünün bu tabloyu da kapsayacak şekilde genişletilmesi.
- Web'in iki yorum sayfasının `submit_review_v3` RPC'sine geçirilmesi (duplicate İngilizce route silinerek).
- Mobilin `karaliste.txt` yerine sunucudan canlı liste çekip önbelleğe alması.
- Profanity tespitinde `add_moderation_strike_v1` çağrısı (mevcut strike sistemine entegrasyon — yeni bir yaptırım mantığı YAZILMIYOR, var olan kullanılıyor).
- `/yonetici` panelinde kara liste terimleri için basit CRUD.

**Kapsam Dışı (bilinçli olarak):**
- Kademeli uyarı sistemi (ilk ihlalde uyarı, ikincide daha sert vb.) — kullanıcı mevcut 30-gün/3-strike modelini onayladı, yeni bir kural yazılmıyor.
- Admin onay kuyruğuna düşürme (her ihlali admin'in tek tek onaylaması) — otomatik strike kullanılıyor.
- Yorum ve menü fiyat önerisi notu dışındaki yüzeyler (işletme öneri notu, grup talebi mesajları, profil biyografisi vb.) — kullanıcı açıkça sadece mevcut 2 yüzeyle sınırlı tutulmasını onayladı.
- Mobildeki hardcoded regex kontrolü (`_containsObfuscatedProfanity`) ve sunucudaki eşleniği (`contains_obfuscated_profanity_v1`'in regex kısmı) — bunlar aynen kalıyor, sadece flat-list kısmı tabloya taşınıyor.
- `contains_contact_or_url_v1` (link/telefon paylaşımı) tarafı — bu tasarımın konusu değil, dokunulmuyor.

## Veri Modeli

Yeni migration: `supabase/migrations/20260901######_moderation_blacklist_terms.sql`

```sql
create table public.moderation_blacklist_terms (
  id bigint generated always as identity primary key,
  term text not null,
  is_active boolean not null default true,
  created_by uuid references auth.users(id),
  created_at timestamptz not null default now()
);

create unique index moderation_blacklist_terms_term_norm_uq
  on public.moderation_blacklist_terms (public.normalize_for_moderation_v1(term))
  where is_active;

alter table public.moderation_blacklist_terms enable row level security;
-- RLS: sadece admin_* RPC'ler üzerinden yazılır, doğrudan tablo erişimi yok (owner_claims/regional_cuisine_tags ile aynı desen).
```

`karaliste.txt`'deki 699 terim aynı migration içinde (veya ardından gelen bir seed migration'ında) `insert into moderation_blacklist_terms (term) values (...), (...), ...` ile yüklenecek. Duplicate/varyant satırlar (örn. `amina`, `aminako`, `amina k` gibi aynı kökün çok sayıda yazım varyasyonu) olduğu gibi taşınacak — normalize edilmiş unique index zaten anlamsız duplicate'leri (aynı normalize sonucunu veren farklı yazımları) elemeyecek çünkü normalize edilmiş hallerinin bazıları gerçekten farklı (örn. "amina koyarim" vs "aminakoyarim" normalize sonrası aynı çıkar ama tabloya iki ayrı satır olarak girmeye çalışırsa unique index constraint hatası verir) — **implementer bunu migration yazarken göz önünde bulundurmalı**: seed INSERT'i `on conflict do nothing` ile yapılmalı ki normalize çakışmaları migration'ı kırmasın.

## Sunucu Değişiklikleri

### 1. `contains_obfuscated_profanity_v1(p_text text)` genişletiliyor

Mevcut imza ve dönüş tipi (`boolean`) aynı kalıyor — sadece gövdeye tablo kontrolü ekleniyor:

```sql
-- mevcut regex kontrollerinden sonra:
if exists (
  select 1 from public.moderation_blacklist_terms t
  where t.is_active
    and (
      v_norm like '%' || public.normalize_for_moderation_v1(t.term) || '%'
      or v_compact like '%' || replace(public.normalize_for_moderation_v1(t.term), ' ', '') || '%'
    )
) then
  return true;
end if;
```

**Önemli düzeltme:** Fonksiyon şu an `IMMUTABLE` işaretli ama artık bir tabloyu okuyor — bu yanlış (Postgres semantiğine göre IMMUTABLE, sonucun sadece girdilere bağlı olduğunu, hiçbir tablo durumuna bağlı olmadığını garanti eder). `STABLE` olarak değiştirilmeli. Bu, mevcut çağıran yerlerin (submit_review_v3, submit_menu_item_price_suggestion_v2) davranışını etkilemez, sadece query planner'ın doğru varsayımlar yapmasını sağlar.

Bu değişiklik sayesinde `submit_review_v1/v2/v3` ve `submit_menu_item_price_suggestion_v2` **hiçbir kod değişikliği olmadan** otomatik olarak tam kapsamı (699 terim + regex) kazanır.

### 2. Yeni public RPC: `get_moderation_blacklist_terms_v1()`

```sql
create or replace function public.get_moderation_blacklist_terms_v1()
returns table(term text)
language sql
stable
security definer
set search_path = public
as $$
  select t.term from public.moderation_blacklist_terms t where t.is_active order by t.term;
$$;

grant execute on function public.get_moderation_blacklist_terms_v1() to anon, authenticated;
```

Anon dahil herkese açık (kara liste terimlerinin kendisi gizli bir bilgi değil, zaten mobil app bundle'ında herkese açıktı).

### 3. Strike entegrasyonu

**`submit_review_v3`** — `v_has_profanity` hesaplandıktan hemen sonra (mevcut davranış korunuyor: profanity'li yorum yine `status='pending'` olarak kaydediliyor, `ok:true` dönüyor — bu tasarımın konusu bu davranışı DEĞİŞTİRMEK değil, üstüne strike eklemek):

```sql
v_has_profanity := public.contains_obfuscated_profanity_v1(v_content)
  or public.contains_obfuscated_profanity_v1(coalesce(v_title, ''));

if v_has_profanity then
  perform public.add_moderation_strike_v1(v_user_id, 'profanity', 'submit_review_v3');
end if;
```

**`submit_menu_item_price_suggestion_v2`** — mevcut hard-rejection davranışı korunuyor (`ok:false, error:'contains_profanity'`), strike çağrısı reddin hemen öncesine ekleniyor:

```sql
if v_note is not null and public.contains_obfuscated_profanity_v1(v_note) then
  perform public.add_moderation_strike_v1(auth.uid(), 'profanity', 'submit_menu_item_price_suggestion_v2');
  return jsonb_build_object('ok', false, 'error', 'contains_profanity');
end if;
```

İki RPC'nin de `SECURITY DEFINER` olduğu ve zaten `add_moderation_strike_v1`'in de `SECURITY DEFINER` olduğu doğrulandı — ek bir GRANT gerekmiyor.

### 4. Admin CRUD RPC'leri

`supabase/migrations/20260901######_moderation_blacklist_admin_rpcs.sql`:
- `admin_list_blacklist_terms_v1(p_query text, p_limit int, p_offset int)` — arama + sayfalama.
- `admin_add_blacklist_term_v1(p_term text)` — `is_admin()` kontrolü, insert.
- `admin_remove_blacklist_term_v1(p_id bigint)` — `is_admin()` kontrolü, `is_active = false` (soft delete, geçmiş için iz bırakılır).

CLAUDE.md kuralı gereği üçü de `GRANT EXECUTE ... TO authenticated;` sonrasında `REVOKE EXECUTE ON FUNCTION ... FROM anon;` içerecek.

## Web Değişiklikleri

1. **`app/(kimlik)/isletme/[slug]/yorumlar/new/page.tsx`** — `handleSubmit` içindeki `supabase.from('reviews').insert(payload)` çağrısı `supabase.rpc('submit_review_v3', { p_business_id, p_overall_rating, p_title, p_content, p_taste_rating, ... })` ile değiştirilecek. Dönen `{ok, error}` şekline göre hata mesajları güncellenecek (mevcut `err.message` yerine `error` kodunu Türkçe mesaja çeviren küçük bir map, mobildeki `AppErrorCodes` desenine benzer).
2. **`app/(kimlik)/b/[slug]/reviews/new/page.tsx`** — tamamen silinecek (Temmuz'daki EN→TR route temizliği emsaline uyarak, redirect değil silme).
3. Yeni: `src/lib/moderasyon/kara-liste-on-kontrol.ts` — `get_moderation_blacklist_terms_v1` RPC'sini çekip `localStorage`'da TTL'li (24s) önbelleğe alan, `normalizeForModeration(text)` (mobildeki `_normalizeForSearch`'ün TS karşılığı) + liste eşleşmesi yapan küçük bir yardımcı. Yorum formunda `content`/`title` her değiştiğinde debounce'lu bir ön-kontrol gösterecek (mobildeki anlık uyarıyla aynı UX).

## Mobil Değişiklikleri

1. **`lib/core/content/content_moderation.dart`** — `_readBlacklist()`, `rootBundle.loadString('assets/json/karaliste.txt')` yerine yeni bir `ModerationBlacklistRepository` üzerinden `get_moderation_blacklist_terms_v1` RPC'sini çekecek. Sonuç `SharedPreferences`'a JSON olarak, 24 saatlik TTL ile yazılacak (mevcut `CategoryPrefs`/`SearchPrefs` desenindeki gibi basit bir prefs sınıfı: `ModerationBlacklistPrefs`). Fetch başarısız olursa (offline), önbellekteki en son liste kullanılır; o da yoksa flat-list kontrolü sessizce atlanır (hardcoded regex kontrolü yine çalışır).
2. **Silinecek:** `assets/json/karaliste.txt`, `pubspec.yaml`'daki `- assets/json/karaliste.txt` satırı.
3. `_containsObfuscatedProfanity` (hardcoded regex) aynen kalıyor.

## Hata Durumları / Edge Case'ler

- **İstemci listeyi hiç çekemezse (ilk kurulum + offline):** Ön-kontrol sessizce devre dışı kalır, kullanıcı gönderir, sunucu (her zaman online olduğu için) kesin kararı verir. Kullanıcı "network hatası" değil, normal moderasyon sonucunu (yorumlarda: sessizce pending, fiyat önerisinde: `contains_profanity` reddi) görür.
- **Kara liste tablosu boşsa/erişilemezse (migration henüz koşmamış, vs.):** `contains_obfuscated_profanity_v1` içindeki `exists (select ...)` sorgusu boş sonuç döner, fonksiyon regex kontrolüne geri düşer — sistem tamamen açık kalmaz.
- **Aynı kullanıcı art arda çok hızlı denerse:** Mevcut rate-limit trigger'ları (`trg_reviews_rate_limit_v1` vb.) zaten devrede, bu tasarım onlara dokunmuyor.
- **Idempotency key ile tekrar deneme:** `submit_review_v3`'ün idempotency mekanizması aynı kalıyor — aynı `idempotency_key` ile tekrar çağrılırsa önbellekteki `v_response` dönüyor, strike ikinci kez sayılmıyor (çünkü fonksiyon gövdesinin geri kalanı hiç çalışmıyor, en baştaki `v_cached_response` kontrolünde erken dönüyor).

## Test Planı

- **Supabase (SQL/mcp ile doğrudan doğrulama):** `contains_obfuscated_profanity_v1` tablo terimiyle çağrılınca `true`, boş/temiz metinle `false` dönüyor mu. `submit_review_v3` profanity'li içerikle çağrılınca `status='pending'` kaydediliyor mu VE `user_moderation_strikes`'a satır düşüyor mu (SQL ile kontrol). `submit_menu_item_price_suggestion_v2` profanity'li notla çağrılınca reddediliyor mu VE strike düşüyor mu. 3 strike sonrası `user_profiles.shadow_banned = true` oluyor mu (mevcut mantık, regresyon testi).
- **Web:** Yorum formu üzerinden gerçek bir gönderim yapıp `reviews` tablosunda satırın `submit_review_v3` üzerinden (idempotency key ile) geldiğini doğrulamak. Eski `/b/[slug]/reviews/new` route'unun 404 döndüğünü doğrulamak.
- **Mobil:** `flutter analyze` + `flutter test` (varsa `content_moderation_test.dart` benzeri bir test dosyası — yoksa yeni bir tane eklenmeli: mock RPC ile blacklist fetch + TTL davranışı).
- **Uçtan uca (mobil, gerçek cihaz/emulator gerekmiyor, kod okuma + Supabase mcp ile canlı doğrulama yeterli):** Kara liste terimi içeren bir yorum gönder, sunucuda pending + strike oluştuğunu doğrula.

## Dosya Yapısı

**Yeni:**
- `supabase/migrations/20260901######_moderation_blacklist_terms.sql`
- `supabase/migrations/20260901######_moderation_blacklist_admin_rpcs.sql`
- `supabase/migrations/20260901######_wire_profanity_strikes_into_submit_rpcs.sql`
- `uygulamalar/web/app/yonetici/kara-liste/page.tsx`
- `uygulamalar/web/app/yonetici/kara-liste/kara-liste-istemcisi.tsx`
- `uygulamalar/web/app/yonetici/kara-liste/kara-liste-islemleri.ts`
- `uygulamalar/web/src/lib/moderasyon/kara-liste-on-kontrol.ts`
- `uygulamalar/mobil/lib/core/content/moderation_blacklist_repository.dart`
- `uygulamalar/mobil/lib/core/storage/moderation_blacklist_prefs.dart`

**Değiştirilecek:**
- `uygulamalar/mobil/lib/core/content/content_moderation.dart`
- `uygulamalar/mobil/pubspec.yaml` (asset kaydı siliniyor)
- `uygulamalar/web/app/(kimlik)/isletme/[slug]/yorumlar/new/page.tsx`
- `uygulamalar/web/src/ui/kabuk/yonetici-kabuk-istemcisi.tsx` (nav linki)
- `uygulamalar/web/src/lib/admin-izinler.ts` (izin kaydı)

**Silinecek:**
- `uygulamalar/mobil/assets/json/karaliste.txt`
- `uygulamalar/web/app/(kimlik)/b/[slug]/reviews/new/page.tsx`
