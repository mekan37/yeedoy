# Yöresel Yemek Önerisi — Faz 1 (Temel: Veri Modeli + Admin + Akış) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Kullanıcı ev şehrinden farklı bir Türkiye ilindeyken, o ilin yöresel lezzetlerini sunan işletkonuşmeleri mobil keşif akışında bir bant olarak göstermek — admin panelinden yönetilen bir katalog üzerinden, 81 il için başlangıç seed verisiyle.

**Architecture:** Yeni `regional_cuisine_tags` kataloğu + `businesses.regional_tag_id` ile bir işletme bir yöresel etikete bağlanır. Mobil `UserLocationController` her konum güncellemesinde yeni bir `check_regional_recommendation_v1` RPC'sini çağırır; bu RPC kullanıcının `user_profiles.city` (ev şehri) ile geçerli şehri karşılaştırır, eşleşen işletmeleri döner ve (14 günde bir) `notifications` tablosuna bir satır düşer. Web admin panelinde yeni bir sayfa katalog CRUD'u ve işletmeye etiket atamayı sağlar.

**Tech Stack:** Supabase (Postgres/plpgsql RPC), Next.js 15 App Router (admin panel), Flutter/Riverpod (mobil).

**Kapsam notu:** Bu plan sadece **akış** (feed banner) + **uygulama içi bildirim kutusu** kaydını kapsar. Gerçek FCM push gönderimi (telefonun kilit ekranında bildirim) ayrı bir "Faz 2 — Push" planında ele alınacak; bu planın sonunda `notifications` tablosuna doğru satır düşüyor olacak, Faz 2 sadece onu gerçek push'a çevirecek bir katman ekleyecek.

---

## Dosya Yapısı

**Yeni:**
- `supabase/migrations/20260831000001_regional_cuisine_tags.sql` — tablolar + seed
- `supabase/migrations/20260831000002_regional_cuisine_admin_rpcs.sql` — admin CRUD RPC'leri
- `supabase/migrations/20260831000003_check_regional_recommendation_v1.sql` — çekirdek RPC + `ensure_my_profile_v1` genişletmesi
- `uygulamalar/web/src/lib/turkiye-illeri.ts` — 81 il sabit listesi (web)
- `uygulamalar/web/app/yonetici/yoresel-mutfak/page.tsx`
- `uygulamalar/web/app/yonetici/yoresel-mutfak/yoresel-mutfak-istemcisi.tsx`
- `uygulamalar/web/app/yonetici/yoresel-mutfak/yoresel-mutfak-islemleri.ts`
- `uygulamalar/mobil/lib/core/location/turkiye_illeri.dart` — 81 il sabit listesi (mobil)
- `uygulamalar/mobil/lib/features/smart_feed/domain/regional_recommendation_controller.dart`
- `uygulamalar/mobil/lib/features/smart_feed/data/regional_recommendation_repository.dart`
- `uygulamalar/mobil/lib/features/smart_feed/ui/regional_recommendation_banner.dart`

**Değiştirilecek:**
- `uygulamalar/web/src/ui/kabuk/yonetici-kabuk-istemcisi.tsx` — nav linki
- `uygulamalar/web/src/lib/admin-izinler.ts` — izin kaydı
- `uygulamalar/mobil/lib/features/profile/data/profile_model.dart` — `city` alanı
- `uygulamalar/mobil/lib/features/profile/data/profile_repository.dart` — `fetchMyProfile` + `updateCity()`
- `uygulamalar/mobil/lib/features/profile/ui/account_info_page.dart` — "Yaşadığın Şehir" satırı + sheet
- `uygulamalar/mobil/lib/features/auth/ui/register_page.dart` — şehir seçici (opsiyonel)
- `uygulamalar/mobil/lib/core/location/user_location_controller.dart` — RPC tetikleme çağrısı
- `uygulamalar/mobil/lib/features/smart_feed/ui/smart_feed_page.dart` — banner insertion
- `uygulamalar/mobil/lib/features/notifications/domain/notification_target_path_resolver.dart` — yeni `type` case'i

---

### Task 1: Veri modeli migration'ı

**Files:**
- Create: `supabase/migrations/20260831000001_regional_cuisine_tags.sql`

- [ ] **Step 1: Migration dosyasını yaz**

```sql
-- Şehir bazlı yöresel yemek kataloğu — yönetici panelinden CRUD, mobilde
-- konum-farkında öneri motorunun veri kaynağı.
CREATE TABLE public.regional_cuisine_tags (
  id          uuid primary key default gen_random_uuid(),
  city        text not null,
  label       text not null,
  created_at  timestamptz not null default now(),
  unique (city, label)
);

ALTER TABLE public.regional_cuisine_tags ENABLE ROW LEVEL SECURITY;
-- Bilinçli olarak hiç policy yok — tüm erişim SECURITY DEFINER RPC'ler üzerinden.

-- Bir işletme en fazla bir yöresel etiket taşır (v1 basitliği).
ALTER TABLE public.businesses
  ADD COLUMN regional_tag_id uuid REFERENCES public.regional_cuisine_tags(id) ON DELETE SET NULL;

-- Push/bildirim tekilleştirme — "aynı şehir için 14 günde 1 kez" kuralını sunucu tarafında garanti eder.
CREATE TABLE public.regional_recommendation_events (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null references auth.users(id) on delete cascade,
  city        text not null,
  sent_at     timestamptz not null default now()
);
CREATE INDEX regional_recommendation_events_user_city_idx
  ON public.regional_recommendation_events (user_id, city, sent_at DESC);

ALTER TABLE public.regional_recommendation_events ENABLE ROW LEVEL SECURITY;
-- Policy yok — sadece SECURITY DEFINER RPC erişir.

-- 81 il için başlangıç seed'i — en az 1 iyi bilinen yöresel lezzet/ürün.
-- Admin panelinden düzenlenebilir/genişletilebilir.
INSERT INTO public.regional_cuisine_tags (city, label) VALUES
  ('Adana', 'Adana Kebap'),
  ('Adıyaman', 'Çiğ Köfte'),
  ('Afyonkarahisar', 'Afyon Sucuğu'),
  ('Ağrı', 'Abgoşt'),
  ('Aksaray', 'Bulgur Pilavı'),
  ('Amasya', 'Amasya Elması'),
  ('Ankara', 'Ankara Tava'),
  ('Antalya', 'Piyaz'),
  ('Ardahan', 'Ardahan Balı'),
  ('Artvin', 'Muşmula Tatlısı'),
  ('Aydın', 'İncirli Kebap'),
  ('Balıkesir', 'Manda Yoğurdu'),
  ('Bartın', 'Bartın Pidesi'),
  ('Batman', 'Kaburga Dolması'),
  ('Bayburt', 'Bayburt Pilavı'),
  ('Bilecik', 'Bozüyük Şeftalisi'),
  ('Bingöl', 'Kadıköy Kebabı'),
  ('Bitlis', 'Kete'),
  ('Bolu', 'Bolu Mantısı'),
  ('Burdur', 'Burdur Şiş Köfte'),
  ('Bursa', 'İskender Kebap'),
  ('Çanakkale', 'Çanakkale Peyniri'),
  ('Çankırı', 'Çorba Tarhanası'),
  ('Çorum', 'Çorum Leblebisi'),
  ('Denizli', 'Denizli Kebabı'),
  ('Diyarbakır', 'Diyarbakır Kaburga Dolması'),
  ('Düzce', 'Düzce Fındığı'),
  ('Edirne', 'Edirne Ciğeri'),
  ('Elazığ', 'Elazığ Kadayıf Dolması'),
  ('Erzincan', 'Erzincan Tulum Peyniri'),
  ('Erzurum', 'Cağ Kebabı'),
  ('Eskişehir', 'Çibörek'),
  ('Gaziantep', 'Baklava'),
  ('Giresun', 'Karalahana Çorbası'),
  ('Gümüşhane', 'Kuymak'),
  ('Hakkari', 'Kaburga Dolması'),
  ('Hatay', 'Künefe'),
  ('Iğdır', 'Kayısı Kurusu'),
  ('Isparta', 'Gül Reçeli'),
  ('İstanbul', 'İstanbul Balık Ekmek'),
  ('İzmir', 'İzmir Kumru'),
  ('Kahramanmaraş', 'Maraş Dondurması'),
  ('Karabük', 'Safranbolu Lokumu'),
  ('Karaman', 'Karaman Etli Ekmek'),
  ('Kars', 'Kars Kaşarı'),
  ('Kastamonu', 'Kastamonu Pastırması'),
  ('Kayseri', 'Kayseri Mantısı'),
  ('Kırıkkale', 'Kırıkkale Pidesi'),
  ('Kırklareli', 'Kırklareli Cevizli Sucuk'),
  ('Kırşehir', 'Kırşehir Çekirdek'),
  ('Kilis', 'Kilis Tava'),
  ('Kocaeli', 'Pişmaniye'),
  ('Konya', 'Etli Ekmek'),
  ('Kütahya', 'Kütahya Yağlaması'),
  ('Malatya', 'Malatya Kayısısı'),
  ('Manisa', 'Manisa Mesir Macunu'),
  ('Mardin', 'İkbebet'),
  ('Mersin', 'Mersin Tantunisi'),
  ('Muğla', 'Muğla Tarhanası'),
  ('Muş', 'Muş Balı'),
  ('Nevşehir', 'Testi Kebabı'),
  ('Niğde', 'Niğde Pekmezi'),
  ('Ordu', 'Ordu Fındığı'),
  ('Osmaniye', 'Osmaniye Bici Bici'),
  ('Rize', 'Rize Çayı'),
  ('Sakarya', 'Sakarya Pidesi'),
  ('Samsun', 'Samsun Pidesi'),
  ('Siirt', 'Siirt Büryan'),
  ('Sinop', 'Hamsili Pilav'),
  ('Sivas', 'Sivas Köftesi'),
  ('Şanlıurfa', 'Urfa Kebabı'),
  ('Şırnak', 'Kadeh Kebabı'),
  ('Tekirdağ', 'Tekirdağ Köftesi'),
  ('Tokat', 'Tokat Kebabı'),
  ('Trabzon', 'Trabzon Akçaabat Köftesi'),
  ('Tunceli', 'Tunceli Balı'),
  ('Uşak', 'Uşak Külünçesi'),
  ('Van', 'Van Kahvaltısı'),
  ('Yalova', 'Yalova Kivisi'),
  ('Yozgat', 'Yozgat Testi Kebabı'),
  ('Zonguldak', 'Zonguldak Pidesi');
```

- [ ] **Step 2: Migration'ı uygula**

`mcp__supabase__apply_migration` aracını `name: "regional_cuisine_tags"` ve yukarıdaki `query` içeriğiyle çağır (bu araç hem migration dosyasını `supabase/migrations/` altına yazar hem canlı DB'ye uygular — dosya adı `20260831000001_regional_cuisine_tags.sql` ile eşleşmeli).

- [ ] **Step 3: Doğrula**

`mcp__supabase__execute_sql` ile:
```sql
SELECT count(*) FROM public.regional_cuisine_tags;
```
Beklenen: `81`.

```sql
SELECT column_name FROM information_schema.columns
WHERE table_schema='public' AND table_name='businesses' AND column_name='regional_tag_id';
```
Beklenen: 1 satır.

- [ ] **Step 4: Commit**

```bash
git add supabase/migrations/20260831000001_regional_cuisine_tags.sql
git commit -m "feat(supabase): regional_cuisine_tags kataloğu + businesses.regional_tag_id + regional_recommendation_events eklendi"
```

---

### Task 2: Admin CRUD RPC'leri

**Files:**
- Create: `supabase/migrations/20260831000002_regional_cuisine_admin_rpcs.sql`

- [ ] **Step 1: Migration dosyasını yaz**

```sql
CREATE OR REPLACE FUNCTION public.admin_list_regional_cuisine_tags_v1()
RETURNS TABLE (id uuid, city text, label text, business_count bigint, created_at timestamptz)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'unauthorized' USING ERRCODE = 'P0002';
  END IF;
  RETURN QUERY
    SELECT t.id, t.city, t.label,
           (SELECT count(*) FROM public.businesses b WHERE b.regional_tag_id = t.id),
           t.created_at
    FROM public.regional_cuisine_tags t
    ORDER BY t.city, t.label;
END;
$$;

REVOKE ALL ON FUNCTION public.admin_list_regional_cuisine_tags_v1() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.admin_list_regional_cuisine_tags_v1() TO authenticated;
REVOKE EXECUTE ON FUNCTION public.admin_list_regional_cuisine_tags_v1() FROM anon;
COMMENT ON FUNCTION public.admin_list_regional_cuisine_tags_v1 IS
  'Admin: tüm yöresel mutfak etiketlerini + kaç işletmede kullanıldığını listeler. Called by: app/yonetici/yoresel-mutfak.';

CREATE OR REPLACE FUNCTION public.admin_upsert_regional_cuisine_tag_v1(
  p_id uuid DEFAULT NULL,
  p_city text DEFAULT NULL,
  p_label text DEFAULT NULL
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_id uuid;
BEGIN
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'unauthorized' USING ERRCODE = 'P0002';
  END IF;

  IF p_id IS NULL THEN
    IF p_city IS NULL OR trim(p_city) = '' THEN
      RAISE EXCEPTION 'validation_error: city zorunlu' USING ERRCODE = 'P0003';
    END IF;
    IF p_label IS NULL OR trim(p_label) = '' THEN
      RAISE EXCEPTION 'validation_error: label zorunlu' USING ERRCODE = 'P0003';
    END IF;
    INSERT INTO public.regional_cuisine_tags (city, label)
    VALUES (trim(p_city), trim(p_label))
    RETURNING id INTO v_id;
  ELSE
    UPDATE public.regional_cuisine_tags
    SET
      city = COALESCE(NULLIF(trim(p_city), ''), city),
      label = COALESCE(NULLIF(trim(p_label), ''), label)
    WHERE id = p_id
    RETURNING id INTO v_id;
    IF v_id IS NULL THEN
      RAISE EXCEPTION 'not_found' USING ERRCODE = 'P0001';
    END IF;
  END IF;

  RETURN v_id;
END;
$$;

REVOKE ALL ON FUNCTION public.admin_upsert_regional_cuisine_tag_v1(uuid, text, text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.admin_upsert_regional_cuisine_tag_v1(uuid, text, text) TO authenticated;
REVOKE EXECUTE ON FUNCTION public.admin_upsert_regional_cuisine_tag_v1(uuid, text, text) FROM anon;
COMMENT ON FUNCTION public.admin_upsert_regional_cuisine_tag_v1 IS
  'Admin: yöresel mutfak etiketi oluşturur (p_id=NULL) veya günceller. Called by: app/yonetici/yoresel-mutfak.';

CREATE OR REPLACE FUNCTION public.admin_delete_regional_cuisine_tag_v1(p_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'unauthorized' USING ERRCODE = 'P0002';
  END IF;
  -- İşletmelerdeki referansı temizle (FK ON DELETE SET NULL zaten yapar, açık DELETE de tetikler).
  DELETE FROM public.regional_cuisine_tags WHERE id = p_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'not_found' USING ERRCODE = 'P0001';
  END IF;
END;
$$;

REVOKE ALL ON FUNCTION public.admin_delete_regional_cuisine_tag_v1(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.admin_delete_regional_cuisine_tag_v1(uuid) TO authenticated;
REVOKE EXECUTE ON FUNCTION public.admin_delete_regional_cuisine_tag_v1(uuid) FROM anon;
COMMENT ON FUNCTION public.admin_delete_regional_cuisine_tag_v1 IS
  'Admin: etiketi siler (kullanan işletmelerde regional_tag_id NULL olur). Called by: app/yonetici/yoresel-mutfak.';

CREATE OR REPLACE FUNCTION public.admin_search_businesses_for_tagging_v1(p_query text)
RETURNS TABLE (id uuid, name text, city text, current_tag_label text)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'unauthorized' USING ERRCODE = 'P0002';
  END IF;
  IF p_query IS NULL OR trim(p_query) = '' THEN
    RETURN;
  END IF;
  RETURN QUERY
    SELECT b.id, b.name, b.city, t.label
    FROM public.businesses b
    LEFT JOIN public.regional_cuisine_tags t ON t.id = b.regional_tag_id
    WHERE b.name ILIKE '%' || trim(p_query) || '%'
    ORDER BY b.name
    LIMIT 20;
END;
$$;

REVOKE ALL ON FUNCTION public.admin_search_businesses_for_tagging_v1(text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.admin_search_businesses_for_tagging_v1(text) TO authenticated;
REVOKE EXECUTE ON FUNCTION public.admin_search_businesses_for_tagging_v1(text) FROM anon;
COMMENT ON FUNCTION public.admin_search_businesses_for_tagging_v1 IS
  'Admin: isme göre işletme arar (etiket atama aracı için). Called by: app/yonetici/yoresel-mutfak.';

CREATE OR REPLACE FUNCTION public.admin_set_business_regional_tag_v1(p_business_id uuid, p_tag_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'unauthorized' USING ERRCODE = 'P0002';
  END IF;
  UPDATE public.businesses SET regional_tag_id = p_tag_id WHERE id = p_business_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'not_found' USING ERRCODE = 'P0001';
  END IF;
END;
$$;

REVOKE ALL ON FUNCTION public.admin_set_business_regional_tag_v1(uuid, uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.admin_set_business_regional_tag_v1(uuid, uuid) TO authenticated;
REVOKE EXECUTE ON FUNCTION public.admin_set_business_regional_tag_v1(uuid, uuid) FROM anon;
COMMENT ON FUNCTION public.admin_set_business_regional_tag_v1 IS
  'Admin: bir işletmeye yöresel etiket atar/kaldırır (p_tag_id=NULL ile kaldırır). Called by: app/yonetici/yoresel-mutfak.';
```

- [ ] **Step 2: Migration'ı uygula**

`mcp__supabase__apply_migration` — `name: "regional_cuisine_admin_rpcs"`.

- [ ] **Step 3: Doğrula — anon revoke gerçekten uygulandı mı**

```sql
SELECT has_function_privilege('anon', 'public.admin_list_regional_cuisine_tags_v1()', 'EXECUTE') AS anon_can_execute;
```
Beklenen: `false`. Aynı kontrolü `admin_upsert_regional_cuisine_tag_v1(uuid,text,text)`, `admin_delete_regional_cuisine_tag_v1(uuid)`, `admin_search_businesses_for_tagging_v1(text)`, `admin_set_business_regional_tag_v1(uuid,uuid)` için de tekrarla.

- [ ] **Step 4: Commit**

```bash
git add supabase/migrations/20260831000002_regional_cuisine_admin_rpcs.sql
git commit -m "feat(supabase): yöresel mutfak kataloğu için admin CRUD + işletme etiketleme RPC'leri"
```

---

### Task 3: `check_regional_recommendation_v1` + `ensure_my_profile_v1` genişletmesi

**Files:**
- Create: `supabase/migrations/20260831000003_check_regional_recommendation_v1.sql`

- [ ] **Step 1: Migration dosyasını yaz**

```sql
-- ensure_my_profile_v1'e p_city eklendi — DEFAULT'lu yeni parametre, breaking change değil.
CREATE OR REPLACE FUNCTION public.ensure_my_profile_v1(
  p_display_name text DEFAULT NULL,
  p_avatar_url text DEFAULT NULL,
  p_city text DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_name text;
BEGIN
  IF auth.uid() IS NULL THEN
    RETURN jsonb_build_object('ok', false, 'error', 'not_authenticated');
  END IF;

  v_name := nullif(trim(coalesce(p_display_name,'')), '');
  IF v_name IS NULL THEN
    v_name := 'Kullanıcı';
  END IF;

  INSERT INTO public.user_profiles(user_id, display_name, avatar_url, city)
  VALUES (auth.uid(), v_name, p_avatar_url, nullif(trim(coalesce(p_city, '')), ''))
  ON CONFLICT (user_id) DO UPDATE
    SET display_name = COALESCE(excluded.display_name, public.user_profiles.display_name),
        avatar_url = COALESCE(excluded.avatar_url, public.user_profiles.avatar_url),
        city = COALESCE(nullif(trim(coalesce(p_city, '')), ''), public.user_profiles.city),
        updated_at = now();

  RETURN jsonb_build_object('ok', true);
END;
$$;
-- Mevcut GRANT/REVOKE zaten yerinde (CREATE OR REPLACE imzayı korur, yeniden vermeye gerek yok).

-- ── Çekirdek RPC: konum uyuşmazlığını tespit eder, tekilleştirir, bildirim satırı düşer ──
CREATE OR REPLACE FUNCTION public.check_regional_recommendation_v1(p_current_city text)
RETURNS TABLE (
  business_id uuid,
  business_name text,
  business_slug text,
  logo_url text,
  tag_label text
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id uuid := auth.uid();
  v_home_city text;
  v_current_city text := nullif(trim(coalesce(p_current_city, '')), '');
  v_already_sent boolean;
BEGIN
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'unauthorized' USING ERRCODE = 'P0002';
  END IF;
  IF v_current_city IS NULL THEN
    RETURN;
  END IF;

  SELECT up.city INTO v_home_city FROM public.user_profiles up WHERE up.user_id = v_user_id;

  -- Ev şehri boşsa veya zaten o şehirdeyse — öneri yok.
  IF v_home_city IS NULL OR v_home_city = v_current_city THEN
    RETURN;
  END IF;

  -- O şehirde etiketli işletme yoksa — öneri yok.
  IF NOT EXISTS (
    SELECT 1 FROM public.businesses b
    WHERE b.city = v_current_city AND b.regional_tag_id IS NOT NULL AND b.is_active = true
  ) THEN
    RETURN;
  END IF;

  -- Push tekilleştirme: son 14 günde bu user+city için event var mı?
  SELECT EXISTS (
    SELECT 1 FROM public.regional_recommendation_events e
    WHERE e.user_id = v_user_id AND e.city = v_current_city AND e.sent_at > now() - interval '14 days'
  ) INTO v_already_sent;

  IF NOT v_already_sent THEN
    INSERT INTO public.regional_recommendation_events (user_id, city) VALUES (v_user_id, v_current_city);
    INSERT INTO public.notifications (user_id, type, title, body, data)
    VALUES (
      v_user_id,
      'regional_recommendation',
      v_current_city || '''desin! İşte yöresel lezzetler',
      v_current_city || '''nin yöresel mutfağını keşfetmeye ne dersin?',
      jsonb_build_object('city', v_current_city)
    );
  END IF;

  RETURN QUERY
    SELECT b.id, b.name, b.slug, b.logo_url, t.label
    FROM public.businesses b
    JOIN public.regional_cuisine_tags t ON t.id = b.regional_tag_id
    WHERE b.city = v_current_city AND b.is_active = true
    ORDER BY b.name
    LIMIT 20;
END;
$$;

REVOKE ALL ON FUNCTION public.check_regional_recommendation_v1(text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.check_regional_recommendation_v1(text) TO authenticated;
COMMENT ON FUNCTION public.check_regional_recommendation_v1 IS
  'Kullanıcının ev şehri dışında bir ilde olup olmadığını kontrol eder, o ildeki yöresel işletmeleri döner, 14 günde bir bildirim satırı düşer. p_current_city çağıran tarafça canonicalCity() ile normalize edilmiş olmalı. Called by: user_location_controller.dart.';
```

**Önemli:** `p_current_city` parametresi `user_profiles.city` ve `regional_cuisine_tags.city`/`businesses.city` ile **birebir aynı yazımda** (aynı `canonicalCity()` normalize fonksiyonundan geçmiş) gelmelidir — RPC düz `=` karşılaştırması yapar, fuzzy matching yoktur (bkz. design doc'taki "Şehir karşılaştırma riski" notu).

- [ ] **Step 2: Migration'ı uygula**

`mcp__supabase__apply_migration` — `name: "check_regional_recommendation_v1"`.

- [ ] **Step 3: Doğrula — uçtan uca manuel test**

```sql
-- Gerçek bir test kullanıcısının user_id'sini bul (kendi hesabınla test et, veya bir test kullanıcısı oluştur).
-- Ev şehrini Ankara yap:
UPDATE public.user_profiles SET city = 'Ankara' WHERE user_id = '<test-user-id>';

-- Kayseri'de etiketli en az 1 aktif işletme olduğunu doğrula:
SELECT b.id, b.name FROM public.businesses b
WHERE b.city = 'Kayseri' AND b.regional_tag_id IS NOT NULL AND b.is_active = true LIMIT 3;
-- Eğer 0 satır dönerse, gerçek bir Kayseri işletmesine admin_set_business_regional_tag_v1 ile
-- geçici olarak etiket ata, test sonrası kaldır.
```

Sonra o kullanıcı olarak (Supabase Studio SQL editöründe `set local role authenticated; set local "request.jwt.claims" = '{"sub":"<test-user-id>"}';` ile simüle edilebilir, veya doğrudan mobil uygulamadan test edilebilir — Task 8'den sonra):
```sql
SELECT * FROM public.check_regional_recommendation_v1('Kayseri');
```
Beklenen: Kayseri'deki etiketli işletmeler dönmeli. Aynı çağrıyı tekrar yap — `regional_recommendation_events`'te ikinci bir satır oluşmamalı (`SELECT count(*) FROM regional_recommendation_events WHERE user_id='<test-user-id>' AND city='Kayseri';` hâlâ `1` olmalı) ama işletme listesi yine dönmeli (feed dedup'suz).

- [ ] **Step 4: Commit**

```bash
git add supabase/migrations/20260831000003_check_regional_recommendation_v1.sql
git commit -m "feat(supabase): check_regional_recommendation_v1 + ensure_my_profile_v1'e p_city eklendi"
```

---

### Task 4: 81 il sabit listesi (web + mobil)

**Files:**
- Create: `uygulamalar/web/src/lib/turkiye-illeri.ts`
- Create: `uygulamalar/mobil/lib/core/location/turkiye_illeri.dart`

- [ ] **Step 1: Web sabitini yaz**

```typescript
// uygulamalar/web/src/lib/turkiye-illeri.ts
export const TURKIYE_ILLERI = [
  'Adana', 'Adıyaman', 'Afyonkarahisar', 'Ağrı', 'Aksaray', 'Amasya', 'Ankara',
  'Antalya', 'Ardahan', 'Artvin', 'Aydın', 'Balıkesir', 'Bartın', 'Batman',
  'Bayburt', 'Bilecik', 'Bingöl', 'Bitlis', 'Bolu', 'Burdur', 'Bursa',
  'Çanakkale', 'Çankırı', 'Çorum', 'Denizli', 'Diyarbakır', 'Düzce', 'Edirne',
  'Elazığ', 'Erzincan', 'Erzurum', 'Eskişehir', 'Gaziantep', 'Giresun',
  'Gümüşhane', 'Hakkari', 'Hatay', 'Iğdır', 'Isparta', 'İstanbul', 'İzmir',
  'Kahramanmaraş', 'Karabük', 'Karaman', 'Kars', 'Kastamonu', 'Kayseri',
  'Kırıkkale', 'Kırklareli', 'Kırşehir', 'Kilis', 'Kocaeli', 'Konya',
  'Kütahya', 'Malatya', 'Manisa', 'Mardin', 'Mersin', 'Muğla', 'Muş',
  'Nevşehir', 'Niğde', 'Ordu', 'Osmaniye', 'Rize', 'Sakarya', 'Samsun',
  'Siirt', 'Sinop', 'Sivas', 'Şanlıurfa', 'Şırnak', 'Tekirdağ', 'Tokat',
  'Trabzon', 'Tunceli', 'Uşak', 'Van', 'Yalova', 'Yozgat', 'Zonguldak',
] as const;
```

- [ ] **Step 2: Mobil sabitini yaz**

```dart
// uygulamalar/mobil/lib/core/location/turkiye_illeri.dart
const List<String> turkiyeIlleri = [
  'Adana', 'Adıyaman', 'Afyonkarahisar', 'Ağrı', 'Aksaray', 'Amasya', 'Ankara',
  'Antalya', 'Ardahan', 'Artvin', 'Aydın', 'Balıkesir', 'Bartın', 'Batman',
  'Bayburt', 'Bilecik', 'Bingöl', 'Bitlis', 'Bolu', 'Burdur', 'Bursa',
  'Çanakkale', 'Çankırı', 'Çorum', 'Denizli', 'Diyarbakır', 'Düzce', 'Edirne',
  'Elazığ', 'Erzincan', 'Erzurum', 'Eskişehir', 'Gaziantep', 'Giresun',
  'Gümüşhane', 'Hakkari', 'Hatay', 'Iğdır', 'Isparta', 'İstanbul', 'İzmir',
  'Kahramanmaraş', 'Karabük', 'Karaman', 'Kars', 'Kastamonu', 'Kayseri',
  'Kırıkkale', 'Kırklareli', 'Kırşehir', 'Kilis', 'Kocaeli', 'Konya',
  'Kütahya', 'Malatya', 'Manisa', 'Mardin', 'Mersin', 'Muğla', 'Muş',
  'Nevşehir', 'Niğde', 'Ordu', 'Osmaniye', 'Rize', 'Sakarya', 'Samsun',
  'Siirt', 'Sinop', 'Sivas', 'Şanlıurfa', 'Şırnak', 'Tekirdağ', 'Tokat',
  'Trabzon', 'Tunceli', 'Uşak', 'Van', 'Yalova', 'Yozgat', 'Zonguldak',
];
```

- [ ] **Step 3: Doğrula**

```bash
cd uygulamalar/web && node -e "console.log(require('./src/lib/turkiye-illeri.ts'))" 2>/dev/null; node -e "
const fs = require('fs');
const content = fs.readFileSync('src/lib/turkiye-illeri.ts', 'utf8');
const matches = content.match(/'[^']+'/g);
console.log('İl sayısı:', matches.length);
"
```
Beklenen: `İl sayısı: 81`.

- [ ] **Step 4: Commit**

```bash
git add uygulamalar/web/src/lib/turkiye-illeri.ts uygulamalar/mobil/lib/core/location/turkiye_illeri.dart
git commit -m "feat: 81 il sabit listesi (web + mobil) eklendi"
```

---

### Task 5: Admin panel — yöresel mutfak sayfası

**Files:**
- Create: `uygulamalar/web/app/yonetici/yoresel-mutfak/yoresel-mutfak-islemleri.ts`
- Create: `uygulamalar/web/app/yonetici/yoresel-mutfak/yoresel-mutfak-istemcisi.tsx`
- Create: `uygulamalar/web/app/yonetici/yoresel-mutfak/page.tsx`

- [ ] **Step 1: Server actions dosyasını yaz**

```typescript
// uygulamalar/web/app/yonetici/yoresel-mutfak/yoresel-mutfak-islemleri.ts
'use server';

import { revalidatePath } from 'next/cache';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { checkAdminAccess } from '@/src/lib/auth/admin-guard';
import { logger } from '@/src/lib/kayitci';

type IslemSonucu = { ok: true } | { ok: false; error: string };
type KaydetSonucu = { ok: true; id: string } | { ok: false; error: string };

export async function etiketKaydet(id: string | null, city: string, label: string): Promise<KaydetSonucu> {
  const guard = await checkAdminAccess();
  if (!guard.authorized) return { ok: false, error: 'Bu işlem için yetkiniz yok.' };
  if (!city.trim() || !label.trim()) return { ok: false, error: 'Şehir ve etiket adı zorunlu.' };

  const supabase = await createSupabaseServerClient();
  const sb = supabase as unknown as { rpc: (fn: string, args: Record<string, unknown>) => Promise<{ data: unknown; error: unknown }> };

  const { data, error } = await sb.rpc('admin_upsert_regional_cuisine_tag_v1', {
    p_id: id,
    p_city: city.trim(),
    p_label: label.trim(),
  });

  if (error || typeof data !== 'string') {
    logger.warn('etiketKaydet: RPC hatası', { error, id });
    return { ok: false, error: 'Etiket kaydedilemedi, tekrar deneyin.' };
  }

  revalidatePath('/yonetici/yoresel-mutfak');
  return { ok: true, id: data };
}

export async function etiketSil(id: string): Promise<IslemSonucu> {
  const guard = await checkAdminAccess();
  if (!guard.authorized) return { ok: false, error: 'Bu işlem için yetkiniz yok.' };

  const supabase = await createSupabaseServerClient();
  const sb = supabase as unknown as { rpc: (fn: string, args: Record<string, unknown>) => Promise<{ data: unknown; error: unknown }> };

  const { error } = await sb.rpc('admin_delete_regional_cuisine_tag_v1', { p_id: id });
  if (error) {
    logger.warn('etiketSil: RPC hatası', { error, id });
    return { ok: false, error: 'Etiket silinemedi, tekrar deneyin.' };
  }

  revalidatePath('/yonetici/yoresel-mutfak');
  return { ok: true };
}

export type IsletmeAramaSonucu = { id: string; name: string; city: string; current_tag_label: string | null };

export async function isletmeAra(query: string): Promise<IsletmeAramaSonucu[]> {
  const guard = await checkAdminAccess();
  if (!guard.authorized) return [];

  const supabase = await createSupabaseServerClient();
  const sb = supabase as unknown as { rpc: (fn: string, args: Record<string, unknown>) => Promise<{ data: unknown; error: unknown }> };

  const { data } = await sb.rpc('admin_search_businesses_for_tagging_v1', { p_query: query });
  return Array.isArray(data) ? (data as IsletmeAramaSonucu[]) : [];
}

export async function isletmeyeEtiketAta(businessId: string, tagId: string | null): Promise<IslemSonucu> {
  const guard = await checkAdminAccess();
  if (!guard.authorized) return { ok: false, error: 'Bu işlem için yetkiniz yok.' };

  const supabase = await createSupabaseServerClient();
  const sb = supabase as unknown as { rpc: (fn: string, args: Record<string, unknown>) => Promise<{ data: unknown; error: unknown }> };

  const { error } = await sb.rpc('admin_set_business_regional_tag_v1', { p_business_id: businessId, p_tag_id: tagId });
  if (error) {
    logger.warn('isletmeyeEtiketAta: RPC hatası', { error, businessId });
    return { ok: false, error: 'Etiket atanamadı, tekrar deneyin.' };
  }

  revalidatePath('/yonetici/yoresel-mutfak');
  return { ok: true };
}
```

- [ ] **Step 2: Client komponenti yaz**

```tsx
// uygulamalar/web/app/yonetici/yoresel-mutfak/yoresel-mutfak-istemcisi.tsx
'use client';

import { useState, useTransition } from 'react';
import { TURKIYE_ILLERI } from '@/src/lib/turkiye-illeri';
import { etiketKaydet, etiketSil, isletmeAra, isletmeyeEtiketAta, type IsletmeAramaSonucu } from './yoresel-mutfak-islemleri';

export type YoreselEtiket = { id: string; city: string; label: string; business_count: number; created_at: string };

export function YoreselMutfakIstemcisi({ initialEtiketler }: { initialEtiketler: YoreselEtiket[] }) {
  const [etiketler, setEtiketler] = useState(initialEtiketler);
  const [city, setCity] = useState(TURKIYE_ILLERI[0]);
  const [label, setLabel] = useState('');
  const [error, setError] = useState<string | null>(null);
  const [isPending, startTransition] = useTransition();

  const [query, setQuery] = useState('');
  const [results, setResults] = useState<IsletmeAramaSonucu[]>([]);
  const [selectedBusiness, setSelectedBusiness] = useState<IsletmeAramaSonucu | null>(null);

  function handleAddTag() {
    setError(null);
    startTransition(async () => {
      const res = await etiketKaydet(null, city, label);
      if (!res.ok) { setError(res.error); return; }
      setEtiketler((prev) => [...prev, { id: res.id, city, label, business_count: 0, created_at: new Date().toISOString() }].sort((a, b) => a.city.localeCompare(b.city, 'tr')));
      setLabel('');
    });
  }

  function handleDeleteTag(id: string) {
    startTransition(async () => {
      const res = await etiketSil(id);
      if (res.ok) setEtiketler((prev) => prev.filter((t) => t.id !== id));
    });
  }

  function handleSearch(q: string) {
    setQuery(q);
    startTransition(async () => {
      setResults(q.trim() ? await isletmeAra(q) : []);
    });
  }

  function handleAssign(tagId: string) {
    if (!selectedBusiness) return;
    startTransition(async () => {
      const res = await isletmeyeEtiketAta(selectedBusiness.id, tagId);
      if (res.ok) {
        setSelectedBusiness(null);
        setQuery('');
        setResults([]);
      }
    });
  }

  return (
    <div className="flex flex-col gap-6">
      <div className="rounded-xl border border-border bg-card p-4">
        <p className="mb-3 text-sm font-extrabold text-textStrong">Yeni Etiket Ekle</p>
        <div className="flex flex-wrap gap-2">
          <select value={city} onChange={(e) => setCity(e.target.value)} className="min-h-11 rounded-xl border border-border bg-bg px-3 py-2 text-sm font-bold text-textStrong">
            {TURKIYE_ILLERI.map((il) => <option key={il} value={il}>{il}</option>)}
          </select>
          <input value={label} onChange={(e) => setLabel(e.target.value)} placeholder="Etiket adı (ör. Kayseri Mantısı)" className="min-h-11 flex-1 min-w-[200px] rounded-xl border border-border bg-bg px-4 py-2 text-sm" />
          <button type="button" onClick={handleAddTag} disabled={isPending || !label.trim()} className="min-h-11 rounded-xl bg-primary px-4 text-sm font-extrabold text-white disabled:opacity-50">Ekle</button>
        </div>
        {error && <p className="mt-2 text-xs font-bold text-danger">{error}</p>}
      </div>

      <div className="rounded-xl border border-border bg-card">
        <table className="w-full text-sm">
          <thead>
            <tr className="border-b border-border text-left text-xs font-bold uppercase text-muted">
              <th className="px-4 py-2.5">Şehir</th>
              <th className="px-4 py-2.5">Etiket</th>
              <th className="px-4 py-2.5">İşletme Sayısı</th>
              <th className="px-4 py-2.5"></th>
            </tr>
          </thead>
          <tbody>
            {etiketler.map((t) => (
              <tr key={t.id} className="border-b border-border last:border-0">
                <td className="px-4 py-2.5 font-bold text-textStrong">{t.city}</td>
                <td className="px-4 py-2.5">{t.label}</td>
                <td className="px-4 py-2.5 text-muted">{t.business_count}</td>
                <td className="px-4 py-2.5 text-right">
                  <button type="button" onClick={() => handleDeleteTag(t.id)} disabled={isPending} className="text-xs font-bold text-danger hover:underline">Sil</button>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      <div className="rounded-xl border border-border bg-card p-4">
        <p className="mb-3 text-sm font-extrabold text-textStrong">İşletmeye Etiket Ata</p>
        <input value={query} onChange={(e) => handleSearch(e.target.value)} placeholder="İşletme adı ara..." className="min-h-11 w-full rounded-xl border border-border bg-bg px-4 py-2 text-sm" />
        {results.length > 0 && !selectedBusiness && (
          <div className="mt-2 flex flex-col gap-1">
            {results.map((b) => (
              <button key={b.id} type="button" onClick={() => setSelectedBusiness(b)} className="flex items-center justify-between rounded-lg px-3 py-2 text-left text-sm hover:bg-black/4">
                <span className="font-bold text-textStrong">{b.name} <span className="font-normal text-muted">({b.city})</span></span>
                <span className="text-xs text-muted">{b.current_tag_label ?? 'Etiketsiz'}</span>
              </button>
            ))}
          </div>
        )}
        {selectedBusiness && (
          <div className="mt-3 rounded-lg border border-border p-3">
            <p className="mb-2 text-sm font-bold text-textStrong">{selectedBusiness.name} ({selectedBusiness.city}) için etiket seç:</p>
            <div className="flex flex-wrap gap-2">
              {etiketler.filter((t) => t.city === selectedBusiness.city).map((t) => (
                <button key={t.id} type="button" onClick={() => handleAssign(t.id)} disabled={isPending} className="rounded-full border border-border px-3 py-1.5 text-xs font-bold hover:border-primary/40 hover:text-primary">{t.label}</button>
              ))}
              {etiketler.filter((t) => t.city === selectedBusiness.city).length === 0 && (
                <p className="text-xs text-muted">Bu şehir için henüz etiket yok — önce yukarıdan ekleyin.</p>
              )}
            </div>
            <button type="button" onClick={() => setSelectedBusiness(null)} className="mt-2 text-xs font-bold text-muted hover:underline">Vazgeç</button>
          </div>
        )}
      </div>
    </div>
  );
}
```

- [ ] **Step 3: Sayfayı yaz**

```tsx
// uygulamalar/web/app/yonetici/yoresel-mutfak/page.tsx
import type { Metadata } from 'next';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { hasPermission } from '@/src/lib/yetki-kontrol';
import { PanelSayfaBasligi } from '@/src/ui/yerlesim/panel-page-header';
import { PanelIcerikYuzeyi } from '@/src/ui/yerlesim/panel-section-card';
import { YetkisizErisim } from '@/src/ui/bilesenler/yetkisiz-erisim';
import { YoreselMutfakIstemcisi, type YoreselEtiket } from './yoresel-mutfak-istemcisi';

export const metadata: Metadata = {
  title: 'Yöresel Mutfak | Yönetici Paneli',
  robots: { index: false, follow: false },
};

export default async function YoreselMutfakPage() {
  const yetkili = await hasPermission('page:yoresel-mutfak');
  if (!yetkili) {
    return (
      <div className="flex flex-col">
        <PanelSayfaBasligi eyebrow="Yönetici" title="Yöresel Mutfak" description="Bu sayfayı görüntüleme yetkiniz yok." />
        <PanelIcerikYuzeyi className="pt-6"><YetkisizErisim sayfaAdi="Yöresel Mutfak" /></PanelIcerikYuzeyi>
      </div>
    );
  }

  const supabase = await createSupabaseServerClient();
  const sb = supabase as unknown as { rpc: (fn: string) => Promise<{ data: unknown; error: unknown }> };
  const { data } = await sb.rpc('admin_list_regional_cuisine_tags_v1');
  const etiketler: YoreselEtiket[] = Array.isArray(data) ? (data as YoreselEtiket[]) : [];

  return (
    <div className="flex flex-col">
      <PanelSayfaBasligi
        eyebrow="Yönetim"
        title="Yöresel Mutfak"
        description="Şehir bazlı yöresel yemek kataloğunu ve işletme eşleşmelerini yönetin."
      />
      <PanelIcerikYuzeyi className="pt-6">
        <YoreselMutfakIstemcisi initialEtiketler={etiketler} />
      </PanelIcerikYuzeyi>
    </div>
  );
}
```

- [ ] **Step 4: Nav'a ve izin listesine ekle**

`uygulamalar/web/src/lib/admin-izinler.ts` içinde permission key union'ına `| 'page:yoresel-mutfak'` ekle ve registry array'ine (gorsel-kutuphanesi girdisinin yanına, aynı `group: 'Operasyon'` altına) şu satırı ekle:
```typescript
{ key: 'page:yoresel-mutfak', label: 'Yöresel Mutfak', group: 'Operasyon', href: '/yonetici/yoresel-mutfak' },
```

`uygulamalar/web/src/ui/kabuk/yonetici-kabuk-istemcisi.tsx` içinde `gorsel-kutuphanesi` linkinin hemen altına:
```tsx
{ href: '/yonetici/yoresel-mutfak', label: 'Yöresel Mutfak', icon: <ImageIcon /> },
```
(mevcut `ImageIcon` komponenti zaten dosyada tanımlı, aynısı yeniden kullanılabilir — yeni ikon gerekmiyor.)

- [ ] **Step 5: Doğrula**

```bash
cd uygulamalar/web && pnpm run typecheck && pnpm run lint
```
Beklenen: 0 hata.

- [ ] **Step 6: Commit**

```bash
git add uygulamalar/web/app/yonetici/yoresel-mutfak uygulamalar/web/src/lib/admin-izinler.ts uygulamalar/web/src/ui/kabuk/yonetici-kabuk-istemcisi.tsx
git commit -m "feat(web): yöresel mutfak admin paneli eklendi (katalog CRUD + işletme etiketleme)"
```

---

### Task 6: Mobil — Profile modeline `city` ekle

**Files:**
- Modify: `uygulamalar/mobil/lib/features/profile/data/profile_model.dart`
- Modify: `uygulamalar/mobil/lib/features/profile/data/profile_repository.dart`

- [ ] **Step 1: `Profile` modeline `city` alanı ekle**

`profile_model.dart`'ta constructor, alan listesi, `copyWith`, `fromMap`, `toMap`'e `city` ekle:

```dart
class Profile {
  const Profile({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.displayName,
    this.privacyMode = NamePrivacyMode.full,
    this.languageCode,
    this.socialLinks = const {},
    this.birthDate,
    this.gender,
    this.city,
  });

  final String id;
  final String firstName;
  final String lastName;
  final String? displayName;
  final NamePrivacyMode privacyMode;
  final String? languageCode;
  final Map<String, String> socialLinks;
  final DateTime? birthDate;
  final String? gender;
  final String? city;

  Profile copyWith({
    String? id,
    String? firstName,
    String? lastName,
    String? displayName,
    NamePrivacyMode? privacyMode,
    String? languageCode,
    Map<String, String>? socialLinks,
    DateTime? birthDate,
    String? gender,
    String? city,
  }) {
    return Profile(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      displayName: displayName ?? this.displayName,
      privacyMode: privacyMode ?? this.privacyMode,
      languageCode: languageCode ?? this.languageCode,
      socialLinks: socialLinks ?? this.socialLinks,
      birthDate: birthDate ?? this.birthDate,
      gender: gender ?? this.gender,
      city: city ?? this.city,
    );
  }

  factory Profile.fromMap(Map<String, dynamic> map) {
    final socialRaw = map['social_links'];
    final socialLinks = <String, String>{};
    if (socialRaw is Map) {
      for (final entry in socialRaw.entries) {
        final key = entry.key.toString().trim();
        final value = entry.value?.toString().trim() ?? '';
        if (key.isEmpty || value.isEmpty) continue;
        socialLinks[key] = value;
      }
    }

    final firstName = (map['first_name'] ?? map['firstName'] ?? '')
        .toString()
        .trim();
    final lastName = (map['last_name'] ?? map['lastName'] ?? '')
        .toString()
        .trim();

    return Profile(
      id: (map['id'] ?? '').toString(),
      firstName: firstName,
      lastName: lastName,
      displayName: map['display_name']?.toString(),
      privacyMode: parsePrivacy(map['privacy_mode']?.toString()),
      languageCode: _normalizeLanguageCode(map['language_code']?.toString()),
      socialLinks: socialLinks,
      birthDate: map['birth_date'] != null
          ? DateTime.tryParse(map['birth_date'].toString())
          : null,
      gender: map['gender']?.toString(),
      city: map['city']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'first_name': firstName.trim(),
      'last_name': lastName.trim(),
      'display_name': (displayName ?? '').trim().isEmpty
          ? null
          : displayName!.trim(),
      'privacy_mode': privacyToDb(privacyMode),
      if (languageCode != null) 'language_code': languageCode,
      'social_links': socialLinks,
      if (birthDate != null)
        'birth_date': birthDate!.toIso8601String().substring(0, 10),
      if (gender != null) 'gender': gender,
      if (city != null) 'city': city,
    };
  }
}
```

- [ ] **Step 2: `fetchMyProfile` select'ine `city` ekle, `updateCity()` metodu ekle**

`profile_repository.dart`'ta `fetchMyProfile`'daki `.select(...)` satırını genişlet:

```dart
      final row = await _supabase
          .from('user_profiles')
          .select('user_id,display_name,social_links,language_code,birth_date,gender,city')
          .eq('user_id', uid)
          .single();
```

Ve dönüş nesnesine `city: data['city']?.toString(),` ekle (Profile constructor çağrısının içine, `gender:` satırının hemen altına).

`updateBirthDate`'in hemen altına, aynı narrow-update deseniyle:

```dart
  /// Sadece city kolonunu günceller; diğer alanları dokunmaz.
  Future<void> updateCity(String? city) async {
    final uid = _supabase.auth.currentUser?.id;
    if (uid == null) return;
    await _supabase.rpc('ensure_my_profile_v1', params: {'p_city': city});
  }
```

(`ensure_my_profile_v1` diğer alanlara dokunmadan `city`'i COALESCE ile günceller — `upsert` yerine bu RPC'yi kullanmak, `display_name` gibi zorunlu alanları elle taşımaya gerek bırakmıyor.)

- [ ] **Step 3: Doğrula**

```bash
cd uygulamalar/mobil && flutter analyze
```
Beklenen: `No issues found!`

- [ ] **Step 4: Commit**

```bash
git add uygulamalar/mobil/lib/features/profile/data/profile_model.dart uygulamalar/mobil/lib/features/profile/data/profile_repository.dart
git commit -m "feat(mobil): Profile modeline city alanı + updateCity() eklendi"
```

---

### Task 7: Mobil — Hesap Bilgileri sayfasına "Yaşadığın Şehir"

**Files:**
- Modify: `uygulamalar/mobil/lib/features/profile/ui/account_info_page.dart`

- [ ] **Step 1: `turkiye_illeri.dart` import'unu ekle**

Dosyanın başına:
```dart
import '../../../core/location/turkiye_illeri.dart';
```

- [ ] **Step 2: "Kişisel Bilgiler" grubuna yeni satır ekle**

`_AccountInfoPageState.build()` içinde `final gender = profile?.gender;` satırının altına:
```dart
    final city = profile?.city;
```

`_InfoGroup` içindeki "Cinsiyet" `_InfoRow`'unun (`isLast: true` olan) hemen üstüne yeni bir `_InfoRow` ekle ve `isLast: true`'yu bu yeni satıra taşı:

```dart
                _InfoRow(
                  icon: Icons.location_city_outlined,
                  title: 'Yaşadığın Şehir',
                  value: city ?? 'Ekle',
                  valueColor: city == null ? AppColors.primary : null,
                  onTap: () => _showCitySheet(context, city),
                ),
                _InfoRow(
                  icon: Icons.people_outline_rounded,
                  title: 'Cinsiyet',
                  value: _genderLabel(gender),
                  valueColor: gender == null ? AppColors.primary : null,
                  onTap: () => _showGenderSheet(context, gender),
                  isLast: true,
                ),
```

- [ ] **Step 3: `_showCitySheet` metodunu ekle**

`_showGenderSheet` metodunun hemen altına:
```dart
  void _showCitySheet(BuildContext context, String? current) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _EditCitySheet(
        ref: ref,
        current: current,
        onSaved: () => ref.invalidate(_myProfileProvider),
      ),
    );
  }
```

- [ ] **Step 4: `_EditCitySheet` widget'ını ekle**

`_EditGenderSheetState` class'ının kapanışından hemen sonra, dosyanın sonuna:

```dart
// ── Şehir sheet ───────────────────────────────────────────────────────────────

class _EditCitySheet extends StatefulWidget {
  const _EditCitySheet({
    required this.ref,
    required this.current,
    required this.onSaved,
  });
  final WidgetRef ref;
  final String? current;
  final VoidCallback onSaved;

  @override
  State<_EditCitySheet> createState() => _EditCitySheetState();
}

class _EditCitySheetState extends State<_EditCitySheet> {
  final _searchCtrl = TextEditingController();
  String _filter = '';
  bool _saving = false;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _save(String il) async {
    setState(() => _saving = true);
    try {
      await widget.ref.read(profileRepositoryProvider).updateCity(il);
      widget.onSaved();
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kaydedilemedi.')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = turkiyeIlleri
        .where((il) => il.toLowerCase().contains(_filter.toLowerCase()))
        .toList();
    final maxHeight = MediaQuery.sizeOf(context).height * 0.75;

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Yaşadığın Şehir',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17),
              ),
              const SizedBox(height: 4),
              const Text(
                'Farklı bir şehirdeyken sana o şehrin yöresel lezzetlerini önerebilmemiz için kullanılır.',
                style: TextStyle(fontSize: 12, color: AppColors.muted),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _searchCtrl,
                onChanged: (v) => setState(() => _filter = v),
                decoration: const InputDecoration(
                  hintText: 'Şehir ara...',
                  prefixIcon: Icon(Icons.search_rounded, size: 20),
                ),
              ),
              const SizedBox(height: 8),
              Flexible(
                child: _saving
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final il = filtered[index];
                          final isSelected = widget.current == il;
                          return ListTile(
                            title: Text(il),
                            trailing: isSelected
                                ? const Icon(Icons.check_rounded, color: AppColors.primary)
                                : null,
                            onTap: () => _save(il),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 5: Doğrula**

```bash
cd uygulamalar/mobil && flutter analyze
```
Beklenen: `No issues found!`

- [ ] **Step 6: Commit**

```bash
git add uygulamalar/mobil/lib/features/profile/ui/account_info_page.dart
git commit -m "feat(mobil): Hesap Bilgileri'ne Yaşadığın Şehir alanı eklendi"
```

---

### Task 8: Mobil — Kayıt formuna opsiyonel şehir seçici

**Files:**
- Modify: `uygulamalar/mobil/lib/features/auth/ui/register_page.dart`

- [ ] **Step 1: Import ekle**

```dart
import '../../../core/location/turkiye_illeri.dart';
```

- [ ] **Step 2: State'e `_selectedCity` ekle**

`_RegisterPageState` içinde `DateTime? _birthDate;` satırının altına:
```dart
  String? _selectedCity;
```

- [ ] **Step 3: `_signUp()`'a kayıt sonrası şehir kaydetme ekle**

`_signUp()` metodunda, `if (response.session != null) { ... }` bloğunun içine, `snapshot` ile ilgili try/finally'nin ALTINA (aynı `if` bloğu içinde, legal-acceptance işleminden sonra) ekle:

```dart
      if (response.session != null) {
        try {
          final snapshot = await ref
              .read(legalRepositoryProvider)
              .loadAcceptanceSnapshot();
          if (snapshot != null && snapshot.pendingRequiredVersions.isNotEmpty) {
            await ref
                .read(legalRepositoryProvider)
                .acceptPolicyVersions(snapshot.pendingRequiredVersions);
          }
        } finally {
          ref.invalidate(legalAcceptanceSnapshotProvider);
        }
        if (_selectedCity != null) {
          try {
            await ref
                .read(profileRepositoryProvider)
                .updateCity(_selectedCity);
          } catch (_) {
            // Şehir kaydedilemese bile kayıt akışını bloklamaz — profilden sonra eklenebilir.
          }
        }
      }
```

Dosyanın importlarına `profileRepositoryProvider` için ekle:
```dart
import '../../profile/data/profile_repository.dart';
```

- [ ] **Step 4: Doğum tarihi seçici alanının altına şehir seçici ekle**

`GestureDetector(onTap: _pickBirthDate, ...)` bloğunu içeren `SizedBox(height: 16)` satırından hemen önce (doğum tarihi ile yasal onay arasına), aynı `Container`/`Row` deseniyle:

```dart
              const SizedBox(height: 12),

              // ── Şehir (opsiyonel) ────────────────────────────────────
              GestureDetector(
                onTap: () => _pickCity(context),
                child: Container(
                  height: 52,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.location_city_outlined,
                        color: AppColors.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _selectedCity ?? 'Yaşadığın şehir (opsiyonel)',
                          style: TextStyle(
                            fontSize: 14,
                            color: _selectedCity == null
                                ? AppColors.muted
                                : AppColors.textStrong,
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: AppColors.muted,
                        size: 22,
                      ),
                    ],
                  ),
                ),
              ),
```

- [ ] **Step 5: `_pickCity` metodunu ekle**

`_pickBirthDate()` metodunun hemen altına:

```dart
  Future<void> _pickCity(BuildContext context) async {
    final searchCtrl = TextEditingController();
    final picked = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        var filter = '';
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final maxHeight = MediaQuery.sizeOf(context).height * 0.72;
            final filtered = turkiyeIlleri
                .where((il) => il.toLowerCase().contains(filter.toLowerCase()))
                .toList();
            return SafeArea(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxHeight: maxHeight),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Yaşadığın Şehir',
                        style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: searchCtrl,
                        onChanged: (v) => setSheetState(() => filter = v),
                        decoration: const InputDecoration(
                          hintText: 'Şehir ara...',
                          prefixIcon: Icon(Icons.search_rounded, size: 20),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Flexible(
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final il = filtered[index];
                            return ListTile(
                              title: Text(il),
                              onTap: () => Navigator.of(sheetContext).pop(il),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
    if (picked != null) setState(() => _selectedCity = picked);
  }
```

- [ ] **Step 6: Doğrula**

```bash
cd uygulamalar/mobil && flutter analyze
```
Beklenen: `No issues found!`

- [ ] **Step 7: Commit**

```bash
git add uygulamalar/mobil/lib/features/auth/ui/register_page.dart
git commit -m "feat(mobil): kayıt formuna opsiyonel şehir seçici eklendi"
```

---

### Task 9: Mobil — bildirim tap yönlendirmesine yeni tip

**Files:**
- Modify: `uygulamalar/mobil/lib/features/notifications/domain/notification_target_path_resolver.dart`

- [ ] **Step 1: `regional_recommendation` case'ini ekle**

`'nearby_trending':` `'owner_daily_summary':` case grubuna ekle:

```dart
    case 'nearby_trending':
    case 'owner_daily_summary':
    case 'regional_recommendation':
      return '/discover';
```

- [ ] **Step 2: Doğrula**

```bash
cd uygulamalar/mobil && flutter analyze
```

- [ ] **Step 3: Commit**

```bash
git add uygulamalar/mobil/lib/features/notifications/domain/notification_target_path_resolver.dart
git commit -m "feat(mobil): regional_recommendation bildirim tipi /discover'a yönlendiriliyor"
```

---

### Task 10: Mobil — Konum controller'ına RPC tetikleme + yeni provider

**Files:**
- Create: `uygulamalar/mobil/lib/features/smart_feed/data/regional_recommendation_repository.dart`
- Create: `uygulamalar/mobil/lib/features/smart_feed/domain/regional_recommendation_controller.dart`
- Modify: `uygulamalar/mobil/lib/core/location/user_location_controller.dart`

- [ ] **Step 1: Repository'yi yaz**

```dart
// uygulamalar/mobil/lib/features/smart_feed/data/regional_recommendation_repository.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/supabase_provider.dart';
import '../domain/regional_recommendation_models.dart';

final regionalRecommendationRepositoryProvider =
    Provider<RegionalRecommendationRepository>((ref) {
  return RegionalRecommendationRepository(ref.watch(supabaseProvider));
});

class RegionalRecommendationRepository {
  RegionalRecommendationRepository(this._supabase);
  final dynamic _supabase;

  Future<List<RegionalBusiness>> check(String currentCity) async {
    final res = await _supabase.rpc(
      'check_regional_recommendation_v1',
      params: {'p_current_city': currentCity},
    );
    if (res is! List) return const [];
    return res
        .whereType<Map>()
        .map((row) => RegionalBusiness.fromMap(row.cast<String, dynamic>()))
        .toList();
  }
}
```

- [ ] **Step 2: Model dosyasını yaz**

```dart
// uygulamalar/mobil/lib/features/smart_feed/domain/regional_recommendation_models.dart
class RegionalBusiness {
  const RegionalBusiness({
    required this.businessId,
    required this.businessName,
    required this.businessSlug,
    required this.logoUrl,
    required this.tagLabel,
  });

  final String businessId;
  final String businessName;
  final String businessSlug;
  final String? logoUrl;
  final String tagLabel;

  factory RegionalBusiness.fromMap(Map<String, dynamic> map) {
    return RegionalBusiness(
      businessId: (map['business_id'] ?? '').toString(),
      businessName: (map['business_name'] ?? '').toString(),
      businessSlug: (map['business_slug'] ?? '').toString(),
      logoUrl: map['logo_url']?.toString(),
      tagLabel: (map['tag_label'] ?? '').toString(),
    );
  }
}
```

- [ ] **Step 3: Controller'ı yaz**

```dart
// uygulamalar/mobil/lib/features/smart_feed/domain/regional_recommendation_controller.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/regional_recommendation_repository.dart';
import 'regional_recommendation_models.dart';

class RegionalRecommendationState {
  const RegionalRecommendationState({required this.city, required this.businesses});

  final String? city;
  final List<RegionalBusiness> businesses;

  static const empty = RegionalRecommendationState(city: null, businesses: []);
}

final regionalRecommendationProvider = NotifierProvider<
    RegionalRecommendationController, RegionalRecommendationState>(
  RegionalRecommendationController.new,
);

class RegionalRecommendationController
    extends Notifier<RegionalRecommendationState> {
  @override
  RegionalRecommendationState build() => RegionalRecommendationState.empty;

  Future<void> checkCity(String city) async {
    try {
      final businesses =
          await ref.read(regionalRecommendationRepositoryProvider).check(city);
      state = RegionalRecommendationState(city: city, businesses: businesses);
    } catch (_) {
      // Sessizce yut — konum akışını bloklamamalı.
      state = RegionalRecommendationState(city: city, businesses: const []);
    }
  }
}
```

- [ ] **Step 4: `user_location_controller.dart`'ta `_syncFeatures`'ı genişlet**

```dart
import '../../features/smart_feed/domain/regional_recommendation_controller.dart';
```
importunu diğer importların yanına ekle (`smart_feed_controller.dart` importunun hemen altına).

`_syncFeatures` metodunu:
```dart
  Future<void> _syncFeatures({
    required String city,
    required String district,
  }) async {
    await ref
        .read(discoverySearchProvider.notifier)
        .setLocation(city: city, district: district);
    await ref
        .read(smartFeedProvider.notifier)
        .setLocation(city: city, district: district);
    unawaited(
      ref.read(regionalRecommendationProvider.notifier).checkCity(city),
    );
  }
```

şeklinde güncelle (son satır yeni — `unawaited` kullanıyoruz çünkü bu çağrı konum akışını bloklamamalı, `dart:async` importu dosyada zaten mevcut).

- [ ] **Step 5: Doğrula**

```bash
cd uygulamalar/mobil && flutter analyze
```
Beklenen: `No issues found!`

- [ ] **Step 6: Commit**

```bash
git add uygulamalar/mobil/lib/features/smart_feed/data/regional_recommendation_repository.dart uygulamalar/mobil/lib/features/smart_feed/domain/regional_recommendation_controller.dart uygulamalar/mobil/lib/features/smart_feed/domain/regional_recommendation_models.dart uygulamalar/mobil/lib/core/location/user_location_controller.dart
git commit -m "feat(mobil): konum güncellemesinde check_regional_recommendation_v1 tetikleniyor"
```

---

### Task 11: Mobil — Akıllı Akış'a banner

**Files:**
- Create: `uygulamalar/mobil/lib/features/smart_feed/ui/regional_recommendation_banner.dart`
- Modify: `uygulamalar/mobil/lib/features/smart_feed/ui/smart_feed_page.dart`

- [ ] **Step 1: Banner widget'ını yaz**

```dart
// uygulamalar/mobil/lib/features/smart_feed/ui/regional_recommendation_banner.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/colors.dart';
import '../../../core/media/app_network_image.dart';
import '../domain/regional_recommendation_controller.dart';

class RegionalRecommendationBanner extends ConsumerWidget {
  const RegionalRecommendationBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(regionalRecommendationProvider);
    if (state.city == null || state.businesses.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.location_on_rounded, color: AppColors.primary, size: 18),
              const SizedBox(width: 6),
              Text(
                '${state.city}\'desin!',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textStrong,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          const Text(
            'İşte yöresel lezzetler',
            style: TextStyle(fontSize: 12, color: AppColors.muted),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 130,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: state.businesses.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final b = state.businesses[index];
                return GestureDetector(
                  onTap: () => context.push('/b/${b.businessId}'),
                  child: Container(
                    width: 140,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                          child: SizedBox(
                            height: 70,
                            width: double.infinity,
                            child: (b.logoUrl ?? '').isEmpty
                                ? Container(color: AppColors.primarySoft)
                                : AppNetworkImage(url: b.logoUrl!, fit: BoxFit.cover),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                b.businessName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textStrong,
                                ),
                              ),
                              Text(
                                b.tagLabel,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 10, color: AppColors.muted),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: `smart_feed_page.dart`'a ekle**

Import ekle:
```dart
import 'regional_recommendation_banner.dart';
```

`const SliverToBoxAdapter(child: SizedBox(height: 20)),` satırının (başlıktan hemen sonraki, "3 quick-access cards" bölümünden önceki) üstüne yeni bir sliver ekle:

```dart
          SliverToBoxAdapter(
            child: const RegionalRecommendationBanner(),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 20)),
```

- [ ] **Step 3: Doğrula**

```bash
cd uygulamalar/mobil && flutter analyze
```
Beklenen: `No issues found!`

- [ ] **Step 4: Commit**

```bash
git add uygulamalar/mobil/lib/features/smart_feed/ui/regional_recommendation_banner.dart uygulamalar/mobil/lib/features/smart_feed/ui/smart_feed_page.dart
git commit -m "feat(mobil): Akıllı Akış'a yöresel öneri bandı eklendi"
```

---

### Task 12: Uçtan uca manuel doğrulama

- [ ] **Step 1: Admin panelde bir test etiketi + işletme ataması yap**

`www.yeedoy.com/yonetici/yoresel-mutfak` (veya yerel `pnpm dev`) üzerinden gerçek bir Kayseri işletmesine "Kayseri Mantısı" etiketini ata.

- [ ] **Step 2: Mobil uygulamada test kullanıcısının ev şehrini Ankara yap**

Hesap Bilgileri → Yaşadığın Şehir → Ankara.

- [ ] **Step 3: Dev location override ile Kayseri'yi simüle et**

`dev_overrides_prefs.dart`'ın sağladığı geliştirici konum override akışını kullanarak (uygulamada zaten var olan dev-mode test-location özelliği) şehri Kayseri olarak ayarla.

- [ ] **Step 4: Doğrula**

- Akıllı Akış ekranında "Kayseri'desin! İşte yöresel lezzetler" bandının, atanan işletmeyle birlikte göründüğünü kontrol et.
- Uygulama içi bildirim kutusunda (`/inbox`) yeni bir "Kayseri'desin!" bildiriminin göründüğünü kontrol et.
- Aynı konumu tekrar tetikle (uygulamayı yeniden başlat) — banner yine görünmeli ama bildirim kutusunda İKİNCİ bir satır OLUŞMAMALI (`regional_recommendation_events` dedup'ı SQL'den de doğrulanabilir).

---

## Faz 2'ye not

Bu plan tamamlandığında `notifications` tablosuna doğru satırlar düşüyor ve uygulama içi bildirim kutusunda görünüyor olacak — ama telefonun kilit ekranında gerçek bir push bildirimi ÇIKMAYACAK (FCM gönderim altyapısı henüz yok, bkz. design doc'taki bulgu). Bu, ayrı bir **Faz 2 — Push** planında ele alınacak: `pg_net` extension'ı etkinleştirme, yeni bir `send-regional-push` Supabase Edge Function'ı, ve kullanıcının Firebase Console'dan alacağı bir servis hesabı anahtarının `supabase secrets set` ile eklenmesi (bu son adım manuel, kullanıcı tarafından yapılmalı).
