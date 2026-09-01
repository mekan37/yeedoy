# Paylaşımlı Moderasyon Kara Listesi + Strike Entegrasyonu Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Mobildeki `karaliste.txt` (699 terim) ile sunucudaki küçük regex listesi arasındaki senkronsuzluğu, tek bir Postgres tablosuna taşıyarak gidermek; web'in yorum yazma sayfalarını RPC katmanına (`submit_review_v3`) bağlayarak profanity kontrolünü aktifleştirmek; ve profanity tespit edildiğinde mevcut strike/shadow-ban altyapısını (`add_moderation_strike_v1`) tetiklemek.

**Architecture:** Yeni `moderation_blacklist_terms` tablosu tek doğru kaynak olur. `contains_obfuscated_profanity_v1` (mevcut regex + yeni tablo kontrolü) tüm sunucu tarafı doğrulamanın tek giriş noktası kalır — `submit_review_v3` ve `submit_menu_item_price_suggestion_v2` zaten bunu çağırıyor, imza değişmediği için otomatik kapsanırlar. Mobil ve web istemcileri yeni bir public RPC (`get_moderation_blacklist_terms_v1`) ile listeyi çekip yerel önbelleğe alarak anlık ön-kontrol yapar; kesin karar her zaman sunucudadır.

**Tech Stack:** Supabase (Postgres/plpgsql), Next.js 15 (App Router, Server Actions), Flutter/Riverpod.

**Spec:** `docs/superpowers/specs/2026-09-01-paylasimli-moderasyon-karaliste-design.md`

---

## Dosya Yapısı

**Yeni:**
- `supabase/migrations/20260901######_moderation_blacklist_terms.sql`
- `supabase/migrations/20260901######_moderation_blacklist_profanity_check.sql`
- `supabase/migrations/20260901######_wire_profanity_strikes.sql`
- `supabase/migrations/20260901######_moderation_blacklist_admin_rpcs.sql`
- `uygulamalar/web/app/yonetici/kara-liste/page.tsx`
- `uygulamalar/web/app/yonetici/kara-liste/kara-liste-istemcisi.tsx`
- `uygulamalar/web/app/yonetici/kara-liste/kara-liste-islemleri.ts`
- `uygulamalar/web/src/lib/moderasyon/kara-liste-on-kontrol.ts`
- `uygulamalar/web/test/lib/moderasyon/kara-liste-on-kontrol.test.ts`
- `uygulamalar/mobil/lib/core/content/moderation_blacklist_repository.dart`
- `uygulamalar/mobil/test/core/content/content_moderation_test.dart`

**Değiştirilecek:**
- `uygulamalar/web/src/lib/admin-izinler.ts`
- `uygulamalar/web/src/ui/kabuk/yonetici-kabuk-istemcisi.tsx`
- `uygulamalar/web/app/(kimlik)/isletme/[slug]/yorumlar/new/page.tsx`
- `uygulamalar/mobil/lib/core/storage/local_db/local_db_models.dart`
- `uygulamalar/mobil/lib/core/content/content_moderation.dart`
- `uygulamalar/mobil/pubspec.yaml`

**Silinecek:**
- `uygulamalar/web/app/(kimlik)/b/[slug]/reviews/new/page.tsx`
- `uygulamalar/mobil/assets/json/karaliste.txt`

---

### Task 1: `moderation_blacklist_terms` tablosu + 699 terimin seed edilmesi

**Files:**
- Create: `supabase/migrations/20260901073000_moderation_blacklist_terms.sql`

- [ ] **Step 1: Tabloyu oluşturan migration'ı yaz**

```sql
CREATE TABLE public.moderation_blacklist_terms (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  term text NOT NULL UNIQUE,
  is_active boolean NOT NULL DEFAULT true,
  created_by uuid REFERENCES auth.users(id),
  created_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.moderation_blacklist_terms ENABLE ROW LEVEL SECURITY;
-- Doğrudan tablo erişimi yok — sadece admin_* RPC'ler (SECURITY DEFINER) ve
-- get_moderation_blacklist_terms_v1 / contains_obfuscated_profanity_v1 üzerinden okunur/yazılır.
-- RLS policy eklenmiyor: policy olmayan bir tabloya anon/authenticated'ın doğrudan
-- SELECT/INSERT hakkı yok (RLS enabled + policy yok = tüm doğrudan erişim reddedilir).

COMMENT ON TABLE public.moderation_blacklist_terms IS
  'Küfür/argo kara liste terimleri — tek doğru kaynak. contains_obfuscated_profanity_v1 '
  '(sunucu tarafı kesin kontrol) ve get_moderation_blacklist_terms_v1 (istemci ön-kontrolü '
  'için salt-okunur liste) buradan besleniyor. Yönetimi: /yonetici/kara-liste.';
```

- [ ] **Step 2: `karaliste.txt`'den seed SQL'ini üret**

Bu script `karaliste.txt`'deki 699 satırı okuyup, trim+lowercase ile normalize edip
(exact-duplicate satırları eleyerek) tek bir `INSERT` bloğu üretir. Repo kökünden çalıştır:

```bash
python3 -c "
import pathlib

lines = pathlib.Path('uygulamalar/mobil/assets/json/karaliste.txt').read_text(encoding='utf-8').splitlines()
terms = []
seen = set()
for line in lines:
    t = line.strip().lower()
    if not t or t in seen:
        continue
    seen.add(t)
    terms.append(t)

def esc(s):
    return s.replace(chr(39), chr(39) * 2)

values = ',\n'.join(f\"  ('{esc(t)}')\" for t in terms)
sql = f'INSERT INTO public.moderation_blacklist_terms (term) VALUES\n{values}\nON CONFLICT (term) DO NOTHING;\n'
pathlib.Path('docs/superpowers/plans/_scratch_blacklist_seed.sql').write_text(sql, encoding='utf-8')
print(f'{len(terms)} terim yazildi -> docs/superpowers/plans/_scratch_blacklist_seed.sql')
"
```

Beklenen çıktı: `699 terim yazildi -> docs/superpowers/plans/_scratch_blacklist_seed.sql` (veya exact-duplicate varsa biraz daha az — dosyada birebir aynı satır olup olmadığı önemli değil, script zaten eliyor).

- [ ] **Step 3: Üretilen INSERT bloğunu migration dosyasının sonuna ekle**

`docs/superpowers/plans/_scratch_blacklist_seed.sql`'in içeriğini oku ve Step 1'de yazdığın migration dosyasının
sonuna (tablo tanımından sonra) ekle — böylece migration dosyası hem `CREATE TABLE`
hem 699 satırlık `INSERT`'i tek dosyada barındırır. Sonra scratch dosyasını sil:

```bash
rm docs/superpowers/plans/_scratch_blacklist_seed.sql
```

- [ ] **Step 4: Migration'ı uygula ve doğrula**

`mcp__supabase__apply_migration` ile `name: moderation_blacklist_terms`, `query`: dosyanın
tam içeriği. Sonra doğrula:

```sql
select count(*) from public.moderation_blacklist_terms;
```

Beklenen: `699` (veya Step 2'nin bastığı sayı).

- [ ] **Step 5: Commit**

```bash
git add supabase/migrations/20260901073000_moderation_blacklist_terms.sql
git commit -m "feat(supabase): moderation_blacklist_terms tablosu + karaliste.txt'den 699 terim seed edildi"
```

---

### Task 2: Sunucu tarafı profanity kontrolü tabloyu kapsayacak şekilde genişletiliyor

**Files:**
- Create: `supabase/migrations/20260901074000_moderation_blacklist_profanity_check.sql`

- [ ] **Step 1: `contains_obfuscated_profanity_v1`'i genişleten migration'ı yaz**

```sql
-- IMMUTABLE -> STABLE düzeltmesi: fonksiyon artık bir tabloyu okuyor, sonucu
-- sadece girdilere bağlı değil (tablo değişirse sonuç değişebilir).
CREATE OR REPLACE FUNCTION public.contains_obfuscated_profanity_v1(p_text text)
 RETURNS boolean
 LANGUAGE plpgsql
 STABLE
 SET search_path TO 'public', 'extensions', 'pg_temp'
AS $function$
declare
  v_norm text := public.normalize_for_moderation_v1(p_text);
  v_compact text := regexp_replace(v_norm, '\s+', '', 'g');
begin
  if v_norm ~* '(^| )a\s*m\s*k( |$)' then
    return true;
  end if;

  if v_compact ~* '(amk|amq|aq|siktir|sikik|sikicem|orospu|orosbu|pic|yarrak|gavat|ibne|gotveren)' then
    return true;
  end if;

  if exists (
    select 1
    from public.moderation_blacklist_terms t
    where t.is_active
      and v_compact like '%' || replace(public.normalize_for_moderation_v1(t.term), ' ', '') || '%'
  ) then
    return true;
  end if;

  return false;
end;
$function$;

COMMENT ON FUNCTION public.contains_obfuscated_profanity_v1 IS
  'Küfür/argo tespiti: hardcoded regex kalıpları + moderation_blacklist_terms tablosu. '
  'STABLE (tablo okuyor, IMMUTABLE değil). Called by: submit_review_v1/v2/v3, '
  'submit_menu_item_price_suggestion_v2.';

CREATE OR REPLACE FUNCTION public.get_moderation_blacklist_terms_v1()
RETURNS TABLE (term text)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT t.term FROM public.moderation_blacklist_terms t WHERE t.is_active ORDER BY t.term;
$$;

REVOKE ALL ON FUNCTION public.get_moderation_blacklist_terms_v1() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_moderation_blacklist_terms_v1() TO anon;
GRANT EXECUTE ON FUNCTION public.get_moderation_blacklist_terms_v1() TO authenticated;
COMMENT ON FUNCTION public.get_moderation_blacklist_terms_v1 IS
  'Kara liste terimlerini döner — mobil/web istemci taraflı anlık ön-kontrol için. '
  'Anon dahil herkese açık (terimlerin kendisi zaten mobil app bundle''ında herkese açıktı). '
  'Called by: uygulamalar/mobil/lib/core/content/moderation_blacklist_repository.dart, '
  'uygulamalar/web/src/lib/moderasyon/kara-liste-on-kontrol.ts.';
```

- [ ] **Step 2: Migration'ı uygula**

`mcp__supabase__apply_migration` ile `name: moderation_blacklist_profanity_check`.

- [ ] **Step 3: Doğrula — tablo terimi artık yakalanıyor mu**

```sql
select public.contains_obfuscated_profanity_v1('bu bir amk yorumu');
select public.contains_obfuscated_profanity_v1('normal bir yorum, gayet temiz');
select * from public.get_moderation_blacklist_terms_v1() limit 5;
```

Beklenen: ilki `true`, ikincisi `false`, üçüncüsü 5 satır terim.

- [ ] **Step 4: Regresyon — mevcut RPC'ler hâlâ çalışıyor mu**

```sql
select proname from pg_proc where proname='contains_obfuscated_profanity_v1' and provolatile='s';
```

Beklenen: 1 satır (`s` = stable). `submit_review_v3`'ün kendisine dokunulmadı, bu adımda
sadece bağımlılığı (contains_obfuscated_profanity_v1) değişti — imza aynı kaldığı için
ek bir test gerekmiyor, Task 3'te uçtan uca test edilecek.

- [ ] **Step 5: Commit**

```bash
git add supabase/migrations/20260901074000_moderation_blacklist_profanity_check.sql
git commit -m "feat(supabase): contains_obfuscated_profanity_v1 kara liste tablosunu da kapsıyor, get_moderation_blacklist_terms_v1 eklendi"
```

---

### Task 3: Profanity tespitinde strike tetiklenmesi

**Files:**
- Create: `supabase/migrations/20260901075000_wire_profanity_strikes.sql`

- [ ] **Step 1: `submit_review_v3`'e strike çağrısı ekleyen migration'ı yaz**

Mevcut fonksiyonun tamamı korunuyor, sadece `v_has_profanity` hesaplandıktan hemen
sonra bir `if` bloğu ekleniyor (davranış değişmiyor: profanity'li yorum yine
`status='pending'` kaydediliyor, `ok:true` dönüyor — bu migration sadece üstüne strike ekliyor):

```sql
CREATE OR REPLACE FUNCTION public.submit_review_v3(p_business_id uuid, p_overall_rating integer, p_title text DEFAULT NULL::text, p_content text DEFAULT NULL::text, p_taste_rating integer DEFAULT NULL::integer, p_service_speed_rating integer DEFAULT NULL::integer, p_price_performance_rating integer DEFAULT NULL::integer, p_cleanliness_rating integer DEFAULT NULL::integer, p_atmosphere_rating integer DEFAULT NULL::integer, p_idempotency_key text DEFAULT NULL::text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  v_user_id uuid := auth.uid();
  v_content text := public.sanitize_plain_text_v1(p_content);
  v_title text := nullif(public.sanitize_plain_text_v1(p_title), '');
  v_profile_created_at timestamptz;
  v_recent_count int := 0;
  v_same_business_count int := 0;
  v_shadow boolean := false;
  v_rate jsonb;
  v_has_contact boolean := false;
  v_has_profanity boolean := false;
  v_status text := 'approved';
  v_idempotency_key text := nullif(trim(coalesce(p_idempotency_key, '')), '');
  v_cached_response jsonb;
  v_response jsonb;
  v_review_id uuid;
begin
  if v_user_id is null then
    return jsonb_build_object('ok', false, 'error', 'not_authenticated');
  end if;

  if v_idempotency_key is not null then
    perform pg_advisory_xact_lock(
      hashtext('submit_review_v3'),
      hashtext(v_user_id::text || ':' || v_idempotency_key)
    );

    select k.response
      into v_cached_response
    from public.client_mutation_idempotency_keys k
    where k.user_id = v_user_id
      and k.action = 'submit_review_v3'
      and k.idempotency_key = v_idempotency_key
    limit 1;

    if v_cached_response is not null then
      return v_cached_response;
    end if;
  end if;

  if p_business_id is null then
    return jsonb_build_object('ok', false, 'error', 'business_required');
  end if;

  if p_overall_rating < 1 or p_overall_rating > 5 then
    return jsonb_build_object('ok', false, 'error', 'bad_rating');
  end if;

  if p_taste_rating is not null and (p_taste_rating < 1 or p_taste_rating > 5) then
    return jsonb_build_object('ok', false, 'error', 'bad_taste_rating');
  end if;

  if p_service_speed_rating is not null and (p_service_speed_rating < 1 or p_service_speed_rating > 5) then
    return jsonb_build_object('ok', false, 'error', 'bad_service_speed_rating');
  end if;

  if p_price_performance_rating is not null and (p_price_performance_rating < 1 or p_price_performance_rating > 5) then
    return jsonb_build_object('ok', false, 'error', 'bad_price_performance_rating');
  end if;

  if p_cleanliness_rating is not null and (p_cleanliness_rating < 1 or p_cleanliness_rating > 5) then
    return jsonb_build_object('ok', false, 'error', 'bad_cleanliness_rating');
  end if;

  if p_atmosphere_rating is not null and (p_atmosphere_rating < 1 or p_atmosphere_rating > 5) then
    return jsonb_build_object('ok', false, 'error', 'bad_atmosphere_rating');
  end if;

  if length(v_content) < 8 then
    return jsonb_build_object('ok', false, 'error', 'content_too_short');
  end if;

  if length(regexp_replace(v_content, '[[:alnum:][:space:]]', '', 'g')) > 12 then
    return jsonb_build_object('ok', false, 'error', 'emoji_spam');
  end if;

  v_has_contact := public.contains_contact_or_url_v1(coalesce(p_content, ''))
    or public.contains_contact_or_url_v1(v_content);

  v_has_profanity := public.contains_obfuscated_profanity_v1(v_content)
    or public.contains_obfuscated_profanity_v1(coalesce(v_title, ''));

  if v_has_profanity then
    perform public.add_moderation_strike_v1(v_user_id, 'profanity', 'submit_review_v3');
  end if;

  if v_has_contact then
    v_content := public.mask_contact_tokens_v1(v_content);
    v_title := nullif(public.mask_contact_tokens_v1(coalesce(v_title, '')), '');
  end if;

  v_rate := public.consume_rate_limit_v1('review', 15);
  if coalesce((v_rate->>'ok')::boolean, false) is false then
    return jsonb_build_object('ok', false, 'error', 'review_daily_rate_limited');
  end if;

  select up.created_at
    into v_profile_created_at
  from public.user_profiles up
  where up.user_id = v_user_id;

  if v_profile_created_at is not null and v_profile_created_at >= now() - interval '7 days' then
    select count(*)
      into v_recent_count
    from public.reviews r
    where r.user_id = v_user_id
      and r.created_at >= now() - interval '24 hours';

    if v_recent_count >= 2 then
      return jsonb_build_object('ok', false, 'error', 'new_account_rate_limited');
    end if;
  end if;

  select count(*)
    into v_same_business_count
  from public.reviews r
  where r.user_id = v_user_id
    and r.business_id = p_business_id
    and r.created_at >= now() - interval '12 hours';

  if v_same_business_count > 0 then
    return jsonb_build_object('ok', false, 'error', 'same_business_cooldown');
  end if;

  v_shadow := public.is_shadow_banned_v1();
  v_status := case
    when v_shadow or v_has_contact or v_has_profanity then 'pending'
    else 'approved'
  end;

  insert into public.reviews(
    business_id,
    user_id,
    rating,
    overall_rating,
    taste_rating,
    service_speed_rating,
    price_performance_rating,
    cleanliness_rating,
    atmosphere_rating,
    title,
    content,
    status
  ) values (
    p_business_id,
    v_user_id,
    p_overall_rating,
    p_overall_rating,
    p_taste_rating,
    p_service_speed_rating,
    p_price_performance_rating,
    p_cleanliness_rating,
    p_atmosphere_rating,
    v_title,
    v_content,
    v_status
  )
  returning id into v_review_id;

  v_response := jsonb_build_object(
    'ok', true,
    'review_id', v_review_id,
    'shadowed', v_shadow,
    'pending', v_status = 'pending',
    'contains_contact', v_has_contact,
    'contains_profanity', v_has_profanity,
    'has_detailed_ratings',
      (p_taste_rating is not null
        or p_service_speed_rating is not null
        or p_price_performance_rating is not null
        or p_cleanliness_rating is not null
        or p_atmosphere_rating is not null)
  );

  if v_idempotency_key is not null then
    insert into public.client_mutation_idempotency_keys(
      user_id,
      action,
      idempotency_key,
      response,
      resource_type,
      resource_id
    )
    values (
      v_user_id,
      'submit_review_v3',
      v_idempotency_key,
      v_response,
      'review',
      v_review_id
    )
    on conflict (user_id, action, idempotency_key) do update
    set response = excluded.response,
        resource_type = excluded.resource_type,
        resource_id = excluded.resource_id;
  end if;

  return v_response;
end;
$function$;
```

- [ ] **Step 2: `submit_menu_item_price_suggestion_v2`'ye strike çağrısı ekleyen kısmı aynı migration'a ekle**

Mevcut fonksiyonun tamamı korunuyor, sadece profanity reddinin hemen öncesine bir
`perform` satırı ekleniyor:

```sql
CREATE OR REPLACE FUNCTION public.submit_menu_item_price_suggestion_v2(p_menu_item_id uuid, p_suggested_price_cents integer, p_currency text DEFAULT 'TRY'::text, p_note text DEFAULT NULL::text, p_evidence_url text DEFAULT NULL::text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  v_business_id uuid;
  v_cnt int;
  v_note text;
  v_evidence_url text;
  v_current_price int;
  v_ok_30d int := 0;
  v_bad_30d int := 0;
  v_total_30d int := 0;
  v_confidence numeric := 0;
  v_auto_approved boolean := false;
  v_pending_count int := 0;
  v_shadow boolean := false;
  v_rate jsonb;
begin
  if auth.uid() is null then
    return jsonb_build_object('ok', false, 'error', 'not_authenticated');
  end if;

  if p_suggested_price_cents < 0 then
    return jsonb_build_object('ok', false, 'error', 'bad_price');
  end if;

  if p_currency is null or length(trim(p_currency)) <> 3 then
    return jsonb_build_object('ok', false, 'error', 'bad_currency');
  end if;

  v_note := nullif(public.sanitize_plain_text_v1(p_note), '');
  v_evidence_url := nullif(trim(p_evidence_url), '');

  if v_note is not null and public.contains_contact_or_url_v1(v_note) then
    return jsonb_build_object('ok', false, 'error', 'contains_link_or_phone');
  end if;

  if v_note is not null and public.contains_obfuscated_profanity_v1(v_note) then
    perform public.add_moderation_strike_v1(auth.uid(), 'profanity', 'submit_menu_item_price_suggestion_v2');
    return jsonb_build_object('ok', false, 'error', 'contains_profanity');
  end if;

  if v_note is not null
     and length(regexp_replace(v_note, '[[:alnum:][:space:]]', '', 'g')) > 12 then
    return jsonb_build_object('ok', false, 'error', 'emoji_spam');
  end if;

  if v_evidence_url is not null and left(v_evidence_url, 4) <> 'http' then
    return jsonb_build_object('ok', false, 'error', 'bad_evidence_url');
  end if;

  v_rate := public.consume_rate_limit_v1('price_suggestion', 40);
  if coalesce((v_rate->>'ok')::boolean, false) is false then
    return jsonb_build_object('ok', false, 'error', 'price_suggestion_daily_rate_limited');
  end if;

  select mi.business_id, mi.price_cents
    into v_business_id, v_current_price
  from public.menu_items mi
  where mi.id = p_menu_item_id and mi.status = 'published';

  if v_business_id is null then
    return jsonb_build_object('ok', false, 'error', 'not_found');
  end if;

  select count(*) into v_cnt
  from public.menu_item_price_suggestions
  where menu_item_id = p_menu_item_id
    and created_by = auth.uid()
    and created_at >= now() - interval '24 hours';

  if v_cnt > 0 then
    return jsonb_build_object('ok', false, 'error', 'rate_limited_24h');
  end if;

  select
    count(*) filter (where vote = 1 and created_at >= now() - interval '30 days'),
    count(*) filter (where vote = -1 and created_at >= now() - interval '30 days'),
    count(*) filter (where created_at >= now() - interval '30 days')
    into v_ok_30d, v_bad_30d, v_total_30d
  from public.menu_item_price_votes
  where menu_item_id = p_menu_item_id;

  v_confidence :=
    greatest(
      0::numeric,
      least(
        1::numeric,
        (case when v_total_30d <= 0 then 0.2 else (v_ok_30d::numeric / nullif(v_total_30d, 0)) end) * 0.8
        +
        (case
          when v_total_30d >= 12 then 0.2
          when v_total_30d >= 6 then 0.12
          when v_total_30d >= 3 then 0.06
          else 0
        end)
      )
    );

  v_shadow := public.is_shadow_banned_v1();
  if v_shadow then
    v_auto_approved := false;
  end if;

  if v_current_price is not null
     and v_current_price > 0
     and v_total_30d >= 8
     and v_ok_30d >= (v_bad_30d * 3)
     and abs(p_suggested_price_cents - v_current_price)::numeric / v_current_price::numeric <= 0.05
  then
    v_auto_approved := true;
  end if;

  if v_auto_approved then
    update public.menu_items
    set price_cents = p_suggested_price_cents,
        currency = upper(trim(p_currency)),
        updated_at = now()
    where id = p_menu_item_id;

    insert into public.menu_item_price_suggestions(
      menu_item_id, business_id, suggested_price_cents, currency, note, created_by,
      evidence_url, status, handled_at, approved_at, is_shadow
    )
    values (
      p_menu_item_id, v_business_id, p_suggested_price_cents, upper(trim(p_currency)), v_note, auth.uid(),
      v_evidence_url, 'approved', now(), now(), v_shadow
    );

    insert into public.menu_item_price_history(
      menu_item_id, price_cents, currency, source, created_by
    )
    values (
      p_menu_item_id, p_suggested_price_cents, upper(trim(p_currency)), 'auto_rule', auth.uid()
    );

    return jsonb_build_object(
      'ok', true,
      'auto_approved', true,
      'confidence_score', v_confidence,
      'pending_count', 0,
      'shadowed', v_shadow
    );
  end if;

  insert into public.menu_item_price_suggestions(
    menu_item_id, business_id, suggested_price_cents, currency, note, created_by, evidence_url, is_shadow
  )
  values (
    p_menu_item_id, v_business_id, p_suggested_price_cents, upper(trim(p_currency)), v_note, auth.uid(), v_evidence_url, v_shadow
  );

  select count(*) into v_pending_count
  from public.menu_item_price_suggestions
  where menu_item_id = p_menu_item_id
    and status = 'pending';

  return jsonb_build_object(
    'ok', true,
    'auto_approved', false,
    'confidence_score', v_confidence,
    'pending_count', v_pending_count,
    'shadowed', v_shadow
  );
end;
$function$;
```

- [ ] **Step 3: Migration'ı uygula**

`mcp__supabase__apply_migration` ile `name: wire_profanity_strikes`.

- [ ] **Step 4: Uçtan uca doğrula — gerçek bir test kullanıcısıyla**

```sql
-- Test kullanıcısı ve işletme seç (canlıda gerçek bir kayıt kullan, id'leri kendi ortamından al)
select id from auth.users limit 1;  -- v_test_user
select id from public.businesses where is_active limit 1;  -- v_test_business

-- Strike sayısını önce oku
select count(*) from public.user_moderation_strikes where user_id = '<v_test_user>';
```

Sonra `auth.uid()`'i o kullanıcıya set edecek bir yol yoksa (SQL Editor'de `auth.uid()`
session'a bağlıdır), bu adımı **gerçek uygulama üzerinden** (mobil review formu veya
Task 6'da düzeltilecek web formu) test et — profanity içeren bir yorum gönder, sonra:

```sql
select status, content from public.reviews where user_id = '<v_test_user>' order by created_at desc limit 1;
select count(*) from public.user_moderation_strikes where user_id = '<v_test_user>' and reason = 'profanity';
```

Beklenen: `status = 'pending'`, strike sayısı 1 artmış.

- [ ] **Step 5: Commit**

```bash
git add supabase/migrations/20260901075000_wire_profanity_strikes.sql
git commit -m "feat(supabase): profanity tespitinde submit_review_v3 ve submit_menu_item_price_suggestion_v2 add_moderation_strike_v1 çağırıyor"
```

---

### Task 4: Admin CRUD RPC'leri + izin kaydı

**Files:**
- Create: `supabase/migrations/20260901076000_moderation_blacklist_admin_rpcs.sql`

- [ ] **Step 1: Admin RPC'lerini + enum değerini + super-admin refresh'i yaz**

```sql
ALTER TYPE public.admin_permission_key ADD VALUE 'page:kara-liste';
```

- [ ] **Step 2: Aynı migration dosyasına (ayrı bir SQL statement olarak — enum değeri
aynı transaction içinde bir önceki statement'tan sonra kullanılabilir, Postgres 12+) devam et**

```sql
CREATE OR REPLACE FUNCTION public.admin_list_blacklist_terms_v1(p_query text DEFAULT NULL, p_limit int DEFAULT 50, p_offset int DEFAULT 0)
RETURNS TABLE (id bigint, term text, is_active boolean, created_at timestamptz)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'unauthorized' USING ERRCODE = 'P0002';
  END IF;
  RETURN QUERY
    SELECT t.id, t.term, t.is_active, t.created_at
    FROM public.moderation_blacklist_terms t
    WHERE p_query IS NULL OR trim(p_query) = '' OR t.term ILIKE '%' || trim(p_query) || '%'
    ORDER BY t.created_at DESC
    LIMIT p_limit OFFSET p_offset;
END;
$$;

REVOKE ALL ON FUNCTION public.admin_list_blacklist_terms_v1(text, int, int) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.admin_list_blacklist_terms_v1(text, int, int) TO authenticated;
REVOKE EXECUTE ON FUNCTION public.admin_list_blacklist_terms_v1(text, int, int) FROM anon;
COMMENT ON FUNCTION public.admin_list_blacklist_terms_v1 IS
  'Admin: kara liste terimlerini arama+sayfalama ile listeler. Called by: app/yonetici/kara-liste.';

CREATE OR REPLACE FUNCTION public.admin_add_blacklist_term_v1(p_term text)
RETURNS bigint
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_id bigint;
  v_term text := lower(trim(coalesce(p_term, '')));
BEGIN
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'unauthorized' USING ERRCODE = 'P0002';
  END IF;
  IF v_term = '' THEN
    RAISE EXCEPTION 'validation_error: term zorunlu' USING ERRCODE = 'P0003';
  END IF;
  INSERT INTO public.moderation_blacklist_terms (term, created_by)
  VALUES (v_term, auth.uid())
  ON CONFLICT (term) DO UPDATE SET is_active = true
  RETURNING id INTO v_id;
  RETURN v_id;
END;
$$;

REVOKE ALL ON FUNCTION public.admin_add_blacklist_term_v1(text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.admin_add_blacklist_term_v1(text) TO authenticated;
REVOKE EXECUTE ON FUNCTION public.admin_add_blacklist_term_v1(text) FROM anon;
COMMENT ON FUNCTION public.admin_add_blacklist_term_v1 IS
  'Admin: yeni kara liste terimi ekler (varsa ve pasifse yeniden aktifleştirir). Called by: app/yonetici/kara-liste.';

CREATE OR REPLACE FUNCTION public.admin_remove_blacklist_term_v1(p_id bigint)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'unauthorized' USING ERRCODE = 'P0002';
  END IF;
  UPDATE public.moderation_blacklist_terms SET is_active = false WHERE id = p_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'not_found' USING ERRCODE = 'P0001';
  END IF;
END;
$$;

REVOKE ALL ON FUNCTION public.admin_remove_blacklist_term_v1(bigint) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.admin_remove_blacklist_term_v1(bigint) TO authenticated;
REVOKE EXECUTE ON FUNCTION public.admin_remove_blacklist_term_v1(bigint) FROM anon;
COMMENT ON FUNCTION public.admin_remove_blacklist_term_v1 IS
  'Admin: kara liste terimini pasifleştirir (soft delete — geçmiş için satır kalır). Called by: app/yonetici/kara-liste.';

UPDATE public.admin_roles
SET permissions = enum_range(NULL::public.admin_permission_key)
WHERE is_system = true;
```

- [ ] **Step 3: Migration'ı uygula**

`mcp__supabase__apply_migration` ile `name: moderation_blacklist_admin_rpcs`.

**Not:** `ALTER TYPE ... ADD VALUE` içeren migration'lar bazı Supabase CLI sürümlerinde
tek `apply_migration` çağrısında sorun çıkarabilir (enum değeri eklenip aynı migration
içinde SECURITY DEFINER fonksiyon gövdesinde kullanılmıyor olması önemli — burada
enum değeri sadece `UPDATE ... enum_range(NULL::...)` içinde dolaylı kullanılıyor,
doğrudan bir `'page:kara-liste'::admin_permission_key` cast'i yok, bu yüzden güvenli).
Eğer `unsafe use of new value` hatası alınırsa, `ALTER TYPE` satırını ayrı bir migration'a
(`20260901075900_...`) bölüp önce onu uygula, sonra bu dosyanın geri kalanını ayrı uygula.

- [ ] **Step 4: Doğrula**

```sql
select enumlabel from pg_enum e join pg_type t on t.oid=e.enumtypid where t.typname='admin_permission_key' and enumlabel='page:kara-liste';
select admin_add_blacklist_term_v1('test-kufur-terimi-xyz');
select * from admin_list_blacklist_terms_v1('test-kufur-terimi-xyz', 10, 0);
select admin_remove_blacklist_term_v1((select id from moderation_blacklist_terms where term='test-kufur-terimi-xyz'));
```

(Not: SQL Editor'de `auth.uid()` NULL olacağı için `is_admin()` false dönebilir ve bu
çağrılar `unauthorized` ile patlayabilir — bu beklenen bir durumdur, gerçek doğrulama
Task 5'te admin panelinden yapılacak. Burada sadece fonksiyonların var olduğunu ve enum
değerinin eklendiğini doğrulamak yeterli.)

- [ ] **Step 5: Commit**

```bash
git add supabase/migrations/20260901076000_moderation_blacklist_admin_rpcs.sql
git commit -m "feat(supabase): kara liste admin CRUD RPC'leri + page:kara-liste izni eklendi"
```

---

### Task 5: Web admin paneli — `/yonetici/kara-liste`

**Files:**
- Create: `uygulamalar/web/app/yonetici/kara-liste/page.tsx`
- Create: `uygulamalar/web/app/yonetici/kara-liste/kara-liste-istemcisi.tsx`
- Create: `uygulamalar/web/app/yonetici/kara-liste/kara-liste-islemleri.ts`
- Modify: `uygulamalar/web/src/lib/admin-izinler.ts`
- Modify: `uygulamalar/web/src/ui/kabuk/yonetici-kabuk-istemcisi.tsx`

- [ ] **Step 1: `admin-izinler.ts`'e izin kaydını ekle**

`uygulamalar/web/src/lib/admin-izinler.ts` dosyasında `AdminPermissionKey` union'ına
`| 'page:kara-liste'` ekle (son satıra) ve `ADMIN_PERMISSIONS` dizisine şu satırı ekle
(Operasyon grubuna, `page:itirazlar`'dan sonra):

```ts
  { key: 'page:kara-liste', label: 'Kara Liste', group: 'Operasyon', href: '/yonetici/kara-liste' },
```

- [ ] **Step 2: Nav linkini `yonetici-kabuk-istemcisi.tsx`'e ekle**

`yoresel-mutfak` satırının olduğu Operasyon bölümüne (aynı array'e) şu satırı ekle:

```tsx
      { href: '/yonetici/kara-liste', label: 'Kara Liste', icon: <AlertIcon /> },
```

- [ ] **Step 3: `kara-liste-islemleri.ts` server action dosyasını yaz**

```typescript
'use server';

import { revalidatePath } from 'next/cache';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { checkAdminAccess } from '@/src/lib/auth/admin-guard';
import { logger } from '@/src/lib/kayitci';

type IslemSonucu = { ok: true } | { ok: false; error: string };

export type BlacklistTerim = { id: number; term: string; is_active: boolean; created_at: string };

export async function terimAra(query: string): Promise<BlacklistTerim[]> {
  const guard = await checkAdminAccess();
  if (!guard.authorized) return [];

  const supabase = await createSupabaseServerClient();
  const sb = supabase as unknown as { rpc: (fn: string, args: Record<string, unknown>) => Promise<{ data: unknown; error: unknown }> };

  const { data, error } = await sb.rpc('admin_list_blacklist_terms_v1', { p_query: query, p_limit: 50, p_offset: 0 });
  if (error) {
    logger.warn('terimAra: RPC hatası', { error, query });
  }
  return Array.isArray(data) ? (data as BlacklistTerim[]) : [];
}

export async function terimEkle(term: string): Promise<IslemSonucu> {
  const guard = await checkAdminAccess();
  if (!guard.authorized) return { ok: false, error: 'Bu işlem için yetkiniz yok.' };
  if (!term.trim()) return { ok: false, error: 'Terim boş olamaz.' };

  const supabase = await createSupabaseServerClient();
  const sb = supabase as unknown as { rpc: (fn: string, args: Record<string, unknown>) => Promise<{ data: unknown; error: unknown }> };

  const { error } = await sb.rpc('admin_add_blacklist_term_v1', { p_term: term.trim() });
  if (error) {
    logger.warn('terimEkle: RPC hatası', { error, term });
    return { ok: false, error: 'Terim eklenemedi, tekrar deneyin.' };
  }

  revalidatePath('/yonetici/kara-liste');
  return { ok: true };
}

export async function terimSil(id: number): Promise<IslemSonucu> {
  const guard = await checkAdminAccess();
  if (!guard.authorized) return { ok: false, error: 'Bu işlem için yetkiniz yok.' };

  const supabase = await createSupabaseServerClient();
  const sb = supabase as unknown as { rpc: (fn: string, args: Record<string, unknown>) => Promise<{ data: unknown; error: unknown }> };

  const { error } = await sb.rpc('admin_remove_blacklist_term_v1', { p_id: id });
  if (error) {
    logger.warn('terimSil: RPC hatası', { error, id });
    return { ok: false, error: 'Terim silinemedi, tekrar deneyin.' };
  }

  revalidatePath('/yonetici/kara-liste');
  return { ok: true };
}
```

- [ ] **Step 4: `kara-liste-istemcisi.tsx` client component'ini yaz**

```tsx
'use client';

import { useState, useTransition } from 'react';
import { terimAra, terimEkle, terimSil, type BlacklistTerim } from './kara-liste-islemleri';

export function KaraListeIstemcisi({ initialTerimler }: { initialTerimler: BlacklistTerim[] }) {
  const [terimler, setTerimler] = useState(initialTerimler);
  const [yeniTerim, setYeniTerim] = useState('');
  const [query, setQuery] = useState('');
  const [error, setError] = useState<string | null>(null);
  const [isPending, startTransition] = useTransition();

  function handleAdd() {
    setError(null);
    startTransition(async () => {
      const res = await terimEkle(yeniTerim);
      if (!res.ok) { setError(res.error); return; }
      setYeniTerim('');
      const yenile = await terimAra(query);
      setTerimler(yenile);
    });
  }

  function handleDelete(t: BlacklistTerim) {
    if (!confirm(`"${t.term}" terimini kaldırmak istediğinize emin misiniz?`)) return;
    startTransition(async () => {
      const res = await terimSil(t.id);
      if (res.ok) setTerimler((prev) => prev.filter((x) => x.id !== t.id));
    });
  }

  function handleSearch(q: string) {
    setQuery(q);
    startTransition(async () => {
      const sonuc = await terimAra(q);
      setTerimler(sonuc);
    });
  }

  return (
    <div className="flex flex-col gap-6">
      <div className="rounded-xl border border-border bg-card p-4">
        <p className="mb-3 text-sm font-extrabold text-textStrong">Yeni Terim Ekle</p>
        <div className="flex flex-wrap gap-2">
          <input value={yeniTerim} onChange={(e) => setYeniTerim(e.target.value)} placeholder="Terim..." className="min-h-11 flex-1 min-w-[200px] rounded-xl border border-border bg-bg px-4 py-2 text-sm" />
          <button type="button" onClick={handleAdd} disabled={isPending || !yeniTerim.trim()} className="min-h-11 rounded-xl bg-primary px-4 text-sm font-extrabold text-white disabled:opacity-50">Ekle</button>
        </div>
        {error && <p className="mt-2 text-xs font-bold text-danger">{error}</p>}
      </div>

      <div className="rounded-xl border border-border bg-card p-4">
        <input value={query} onChange={(e) => handleSearch(e.target.value)} placeholder="Terim ara..." className="min-h-11 w-full rounded-xl border border-border bg-bg px-4 py-2 text-sm" />
      </div>

      <div className="rounded-xl border border-border bg-card">
        <table className="w-full text-sm">
          <thead>
            <tr className="border-b border-border text-left text-xs font-bold uppercase text-muted">
              <th className="px-4 py-2.5">Terim</th>
              <th className="px-4 py-2.5">Eklenme Tarihi</th>
              <th className="px-4 py-2.5"></th>
            </tr>
          </thead>
          <tbody>
            {terimler.map((t) => (
              <tr key={t.id} className="border-b border-border last:border-0">
                <td className="px-4 py-2.5 font-bold text-textStrong">{t.term}</td>
                <td className="px-4 py-2.5 text-muted">{new Date(t.created_at).toLocaleDateString('tr-TR')}</td>
                <td className="px-4 py-2.5 text-right">
                  <button type="button" onClick={() => handleDelete(t)} disabled={isPending} className="text-xs font-bold text-danger hover:underline">Kaldır</button>
                </td>
              </tr>
            ))}
            {terimler.length === 0 && (
              <tr><td colSpan={3} className="px-4 py-6 text-center text-muted">Sonuç yok.</td></tr>
            )}
          </tbody>
        </table>
      </div>
    </div>
  );
}
```

- [ ] **Step 5: `page.tsx`'i yaz**

```tsx
import type { Metadata } from 'next';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { hasPermission } from '@/src/lib/yetki-kontrol';
import { PanelSayfaBasligi } from '@/src/ui/yerlesim/panel-page-header';
import { PanelIcerikYuzeyi } from '@/src/ui/yerlesim/panel-section-card';
import { YetkisizErisim } from '@/src/ui/bilesenler/yetkisiz-erisim';
import { KaraListeIstemcisi } from './kara-liste-istemcisi';
import type { BlacklistTerim } from './kara-liste-islemleri';

export const metadata: Metadata = {
  title: 'Kara Liste | Yönetici Paneli',
  robots: { index: false, follow: false },
};

export default async function KaraListePage() {
  const yetkili = await hasPermission('page:kara-liste');
  if (!yetkili) {
    return (
      <div className="flex flex-col">
        <PanelSayfaBasligi eyebrow="Yönetici" title="Kara Liste" description="Bu sayfayı görüntüleme yetkiniz yok." />
        <PanelIcerikYuzeyi className="pt-6"><YetkisizErisim sayfaAdi="Kara Liste" /></PanelIcerikYuzeyi>
      </div>
    );
  }

  const supabase = await createSupabaseServerClient();
  const sb = supabase as unknown as { rpc: (fn: string, args: Record<string, unknown>) => Promise<{ data: unknown; error: unknown }> };
  const { data } = await sb.rpc('admin_list_blacklist_terms_v1', { p_query: null, p_limit: 50, p_offset: 0 });
  const terimler: BlacklistTerim[] = Array.isArray(data) ? (data as BlacklistTerim[]) : [];

  return (
    <div className="flex flex-col">
      <PanelSayfaBasligi
        eyebrow="Yönetim"
        title="Kara Liste"
        description="Küfür/argo moderasyon kara listesini yönetin. Bu liste hem mobil hem web istemcilerin anlık ön-kontrolünde, hem de sunucu tarafı kesin kontrolde kullanılır."
      />
      <PanelIcerikYuzeyi className="pt-6">
        <KaraListeIstemcisi initialTerimler={terimler} />
      </PanelIcerikYuzeyi>
    </div>
  );
}
```

- [ ] **Step 6: Typecheck + lint**

```bash
cd uygulamalar/web && pnpm run typecheck && pnpm run lint
```

Beklenen: hatasız geçmeli.

- [ ] **Step 7: Commit**

```bash
git add uygulamalar/web/app/yonetici/kara-liste/ uygulamalar/web/src/lib/admin-izinler.ts uygulamalar/web/src/ui/kabuk/yonetici-kabuk-istemcisi.tsx
git commit -m "feat(web): /yonetici/kara-liste admin paneli eklendi"
```

---

### Task 6: Web yorum yazma sayfası `submit_review_v3`'e bağlanıyor, duplicate route siliniyor

**Files:**
- Modify: `uygulamalar/web/app/(kimlik)/isletme/[slug]/yorumlar/new/page.tsx`
- Delete: `uygulamalar/web/app/(kimlik)/b/[slug]/reviews/new/page.tsx`

- [ ] **Step 1: `handleSubmit`'i RPC çağrısına çevir**

`uygulamalar/web/app/(kimlik)/isletme/[slug]/yorumlar/new/page.tsx` içindeki
`handleSubmit` fonksiyonunu tamamen şununla değiştir:

```typescript
  const ERROR_MESSAGES: Record<string, string> = {
    not_authenticated: 'Oturum açmanız gerekiyor.',
    business_required: 'İşletme bulunamadı.',
    bad_rating: 'Geçerli bir puan seçin.',
    content_too_short: 'Yorum en az 8 karakter olmalı.',
    emoji_spam: 'Çok fazla emoji/özel karakter kullanımı tespit edildi.',
    review_daily_rate_limited: 'Günlük yorum limitine ulaştınız, yarın tekrar deneyin.',
    new_account_rate_limited: 'Yeni hesaplar için günlük yorum limiti aşıldı.',
    same_business_cooldown: 'Bu işletmeye kısa süre önce yorum yaptınız, biraz bekleyin.',
  };

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    if (rating === 0) { setError('Lütfen genel puanınızı seçin'); return; }
    if (content.length < 20) { setError('Yorum en az 20 karakter olmalı'); return; }
    if (!bizId || !userId) return;
    setLoading(true);
    setError(null);
    try {
      const supabase = createSupabaseBrowserClient();
      const sb = supabase as unknown as { rpc: (fn: string, args: Record<string, unknown>) => Promise<{ data: unknown; error: unknown }> };
      const { data, error: err } = await sb.rpc('submit_review_v3', {
        p_business_id: bizId,
        p_overall_rating: rating,
        p_title: title.trim() || null,
        p_content: content,
        p_taste_rating: criteria.taste_rating > 0 ? criteria.taste_rating : null,
        p_service_speed_rating: criteria.service_speed_rating > 0 ? criteria.service_speed_rating : null,
        p_price_performance_rating: criteria.price_performance_rating > 0 ? criteria.price_performance_rating : null,
        p_cleanliness_rating: criteria.cleanliness_rating > 0 ? criteria.cleanliness_rating : null,
        p_atmosphere_rating: criteria.atmosphere_rating > 0 ? criteria.atmosphere_rating : null,
      });
      if (err) throw err;
      const sonuc = data as { ok?: boolean; error?: string } | null;
      if (!sonuc?.ok) {
        const kod = sonuc?.error ?? 'unknown_error';
        setError(ERROR_MESSAGES[kod] ?? 'Yorum gönderilemedi, tekrar deneyin.');
        return;
      }
      router.push(`/isletme/${slug}/yorumlar`);
    } catch (err: unknown) {
      setError(err instanceof Error ? err.message : 'Bir hata oluştu');
    } finally {
      setLoading(false);
    }
  }
```

`ERROR_MESSAGES` sabitini `YeniYorumSayfasi` fonksiyonunun İÇİNE değil, dosyanın en üstüne
(component tanımından önce, `CRITERIA` sabitinin yanına) taşı — her render'da yeniden
oluşturulmasın.

- [ ] **Step 2: Eski İngilizce duplicate route'u sil**

```bash
rm -rf "uygulamalar/web/app/(kimlik)/b/[slug]/reviews"
```

Eğer `uygulamalar/web/app/(kimlik)/b/[slug]/` altında `reviews/` dışında başka bir şey
kalmadıysa, boş kalan `[slug]` ve `b` klasörlerini de temizle:

```bash
find "uygulamalar/web/app/(kimlik)/b" -type d -empty -delete
```

- [ ] **Step 3: Typecheck + lint**

```bash
cd uygulamalar/web && pnpm run typecheck && pnpm run lint
```

- [ ] **Step 4: Manuel doğrulama**

`pnpm dev` ile web'i başlat, gerçek bir test kullanıcısıyla `/isletme/<slug>/yorumlar/new`
üzerinden küfürlü bir test yorumu gönder (örn. "bu işletme tam bir amk yeri"). Sonra
Supabase'de doğrula:

```sql
select status, content from public.reviews where business_id = '<test_business_id>' order by created_at desc limit 1;
select count(*) from public.user_moderation_strikes where user_id = '<test_user_id>' and reason='profanity';
```

Beklenen: `status='pending'`, strike sayısı arttı. Eski `/b/<slug>/reviews/new` route'una
gidince 404 döndüğünü doğrula.

- [ ] **Step 5: Commit**

```bash
git add "uygulamalar/web/app/(kimlik)/isletme/[slug]/yorumlar/new/page.tsx" "uygulamalar/web/app/(kimlik)/b"
git commit -m "fix(web): yorum yazma sayfası submit_review_v3 RPC'sine bağlandı (ham insert kaldırıldı), duplicate İngilizce route silindi"
```

---

### Task 7: Web istemci taraflı anlık ön-kontrol

**Files:**
- Create: `uygulamalar/web/src/lib/moderasyon/kara-liste-on-kontrol.ts`
- Create: `uygulamalar/web/test/lib/moderasyon/kara-liste-on-kontrol.test.ts`
- Modify: `uygulamalar/web/app/(kimlik)/isletme/[slug]/yorumlar/new/page.tsx`

- [ ] **Step 1: Saf normalize+eşleşme fonksiyonlarının testini yaz**

```typescript
// uygulamalar/web/test/lib/moderasyon/kara-liste-on-kontrol.test.ts
import { describe, expect, it } from 'vitest';
import { normalizeForModeration, matchesBlacklist } from '@/src/lib/moderasyon/kara-liste-on-kontrol';

describe('kara-liste-on-kontrol', () => {
  it('normalizes obfuscated characters', () => {
    expect(normalizeForModeration('4mk')).toBe('amk');
    expect(normalizeForModeration('ÇÖPLÜK')).toBe('coplk');
  });

  it('detects a blacklisted term regardless of case/spacing', () => {
    expect(matchesBlacklist('Bu bir SIKTIR yorumu', ['siktir'])).toBe(true);
    expect(matchesBlacklist('bu s i k t i r yorumu', ['siktir'])).toBe(true);
  });

  it('does not flag clean text', () => {
    expect(matchesBlacklist('gayet güzel bir mekan', ['siktir', 'amk'])).toBe(false);
  });

  it('handles an empty blacklist safely', () => {
    expect(matchesBlacklist('herhangi bir metin', [])).toBe(false);
  });
});
```

- [ ] **Step 2: Testi çalıştır, fail ettiğini doğrula**

```bash
cd uygulamalar/web && npx vitest run test/lib/moderasyon/kara-liste-on-kontrol.test.ts
```

Beklenen: FAIL (`Cannot find module '@/src/lib/moderasyon/kara-liste-on-kontrol'`).

- [ ] **Step 3: `kara-liste-on-kontrol.ts`'i yaz**

```typescript
import { createSupabaseBrowserClient } from '@/src/lib/taban/istemci';

const CACHE_KEY = 'yeedoy_moderation_blacklist_v1';
const CACHE_TTL_MS = 24 * 60 * 60 * 1000;

export function normalizeForModeration(text: string): string {
  let s = text.toLowerCase();
  s = s
    .replace(/ç/g, 'c').replace(/ğ/g, 'g').replace(/ı/g, 'i')
    .replace(/ö/g, 'o').replace(/ş/g, 's').replace(/ü/g, 'u')
    .replace(/@/g, 'a').replace(/4/g, 'a').replace(/0/g, 'o')
    .replace(/1/g, 'i').replace(/!/g, 'i').replace(/\$/g, 's')
    .replace(/5/g, 's').replace(/3/g, 'e');
  return s.replace(/[^a-z0-9]+/g, ' ').trim();
}

export function matchesBlacklist(text: string, blacklist: string[]): boolean {
  if (blacklist.length === 0) return false;
  const normalizedText = normalizeForModeration(text);
  const compactText = normalizedText.replace(/ /g, '');
  for (const term of blacklist) {
    const normalizedTerm = normalizeForModeration(term);
    if (!normalizedTerm) continue;
    if (normalizedText.includes(normalizedTerm)) return true;
    const compactTerm = normalizedTerm.replace(/ /g, '');
    if (compactTerm && compactText.includes(compactTerm)) return true;
  }
  return false;
}

type CachedList = { terms: string[]; cachedAt: number };

async function fetchBlacklist(): Promise<string[]> {
  const supabase = createSupabaseBrowserClient();
  const sb = supabase as unknown as { rpc: (fn: string) => Promise<{ data: unknown; error: unknown }> };
  const { data, error } = await sb.rpc('get_moderation_blacklist_terms_v1');
  if (error || !Array.isArray(data)) return [];
  return (data as Array<{ term?: string }>).map((row) => row.term ?? '').filter(Boolean);
}

export async function getBlacklistTerms(): Promise<string[]> {
  if (typeof window === 'undefined') return [];
  try {
    const raw = window.localStorage.getItem(CACHE_KEY);
    if (raw) {
      const cached = JSON.parse(raw) as CachedList;
      if (Date.now() - cached.cachedAt < CACHE_TTL_MS && Array.isArray(cached.terms)) {
        return cached.terms;
      }
    }
  } catch {
    // localStorage erişilemez veya bozuk veri — sessizce sunucudan çek
  }

  const terms = await fetchBlacklist();
  try {
    window.localStorage.setItem(CACHE_KEY, JSON.stringify({ terms, cachedAt: Date.now() } satisfies CachedList));
  } catch {
    // localStorage yazılamadı — önbellek olmadan devam, sorun değil
  }
  return terms;
}
```

- [ ] **Step 4: Testi tekrar çalıştır, geçtiğini doğrula**

```bash
cd uygulamalar/web && npx vitest run test/lib/moderasyon/kara-liste-on-kontrol.test.ts
```

Beklenen: PASS (4/4).

- [ ] **Step 5: Yorum formuna anlık ön-kontrol uyarısını ekle**

`uygulamalar/web/app/(kimlik)/isletme/[slug]/yorumlar/new/page.tsx`'te, dosyanın en
üstüne import ekle:

```typescript
import { getBlacklistTerms, matchesBlacklist } from '@/src/lib/moderasyon/kara-liste-on-kontrol';
```

`YeniYorumSayfasi` component'i içine, `useEffect` importunun yanına yeni bir state ve
effect ekle:

```typescript
  const [blacklist, setBlacklist] = useState<string[]>([]);
  const [warnProfanity, setWarnProfanity] = useState(false);

  useEffect(() => {
    getBlacklistTerms().then(setBlacklist);
  }, []);

  useEffect(() => {
    const t = setTimeout(() => {
      setWarnProfanity(content.trim().length > 0 && matchesBlacklist(content, blacklist));
    }, 400);
    return () => clearTimeout(t);
  }, [content, blacklist]);
```

`textarea`'nın altındaki karakter sayacının hemen altına uyarı bloğunu ekle:

```tsx
            {warnProfanity && (
              <p className="mt-1 text-xs font-bold text-danger">
                Yorumunuzda uygunsuz içerik olabilir — gönderdiğinizde inceleme sırasına alınabilir.
              </p>
            )}
```

- [ ] **Step 6: Typecheck + lint + testler**

```bash
cd uygulamalar/web && pnpm run typecheck && pnpm run lint && npx vitest run test/lib/moderasyon/
```

- [ ] **Step 7: Commit**

```bash
git add uygulamalar/web/src/lib/moderasyon/ uygulamalar/web/test/lib/moderasyon/ "uygulamalar/web/app/(kimlik)/isletme/[slug]/yorumlar/new/page.tsx"
git commit -m "feat(web): yorum formunda anlık kara liste ön-kontrolü eklendi"
```

---

### Task 8: Mobil — `LocalDbBucket.moderationBlacklist` + repository

**Files:**
- Modify: `uygulamalar/mobil/lib/core/storage/local_db/local_db_models.dart`
- Create: `uygulamalar/mobil/lib/core/content/moderation_blacklist_repository.dart`

- [ ] **Step 1: Yeni bucket'ı ekle**

`uygulamalar/mobil/lib/core/storage/local_db/local_db_models.dart` içindeki `enum LocalDbBucket`'a
ve `LocalDbBucketX.key`'e ekle:

```dart
enum LocalDbBucket {
  discoveryFeed,
  businessSnapshot,
  menuSnapshot,
  offlineMutationQueue,
  telemetrySnapshot,
  moderationBlacklist,
}

extension LocalDbBucketX on LocalDbBucket {
  String get key {
    return switch (this) {
      LocalDbBucket.discoveryFeed => 'discovery_feed',
      LocalDbBucket.businessSnapshot => 'business_snapshot',
      LocalDbBucket.menuSnapshot => 'menu_snapshot',
      LocalDbBucket.offlineMutationQueue => 'offline_mutation_queue',
      LocalDbBucket.telemetrySnapshot => 'telemetry_snapshot',
      LocalDbBucket.moderationBlacklist => 'moderation_blacklist',
    };
  }
}
```

- [ ] **Step 2: `moderation_blacklist_repository.dart`'ı yaz**

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../network/supabase_provider.dart';
import '../storage/local_db/local_db_models.dart';
import '../storage/local_db/local_db_provider.dart';
import '../storage/local_db/local_db_store.dart';

final moderationBlacklistRepositoryProvider =
    Provider<ModerationBlacklistRepository>((ref) {
  return ModerationBlacklistRepository(
    ref.watch(supabaseProvider),
    ref.watch(localDbStoreProvider),
  );
});

class ModerationBlacklistRepository {
  ModerationBlacklistRepository(this.client, this._localDb);

  final SupabaseClient client;
  final LocalDbStore _localDb;

  static const String _cacheId = 'terms';
  static const Duration _cacheTtl = Duration(hours: 24);

  /// Sunucudan kara liste terimlerini çeker; başarısız olursa (offline vb.)
  /// en son önbelleklenen listeyi (süresi geçmiş olsa dahi) döner, o da yoksa
  /// boş liste döner — çağıran taraf bunu "ön-kontrol atlanabilir" olarak
  /// yorumlamalı, hata fırlatılmaz.
  Future<List<String>> fetchTerms() async {
    final fresh = await _readCache(allowExpired: false);
    if (fresh != null) return fresh;

    try {
      final res = await client.rpc('get_moderation_blacklist_terms_v1');
      final terms = (res as List)
          .whereType<Map>()
          .map((row) => (row['term'] ?? '').toString())
          .where((term) => term.isNotEmpty)
          .toList(growable: false);
      await _localDb.upsert(
        bucket: LocalDbBucket.moderationBlacklist,
        id: _cacheId,
        payload: <String, dynamic>{'terms': terms},
        expiresAt: DateTime.now().toUtc().add(_cacheTtl),
      );
      return terms;
    } catch (_) {
      final stale = await _readCache(allowExpired: true);
      return stale ?? const [];
    }
  }

  Future<List<String>?> _readCache({required bool allowExpired}) async {
    final record = await _localDb.read(
      LocalDbBucket.moderationBlacklist,
      _cacheId,
      allowExpired: allowExpired,
    );
    final terms = record?.payload['terms'];
    if (terms is! List) return null;
    return terms.map((e) => e.toString()).toList(growable: false);
  }
}
```

- [ ] **Step 3: `flutter analyze`**

```bash
cd uygulamalar/mobil && flutter analyze lib/core/content/moderation_blacklist_repository.dart lib/core/storage/local_db/local_db_models.dart
```

Beklenen: `No issues found!`

- [ ] **Step 4: Commit**

```bash
git add uygulamalar/mobil/lib/core/content/moderation_blacklist_repository.dart uygulamalar/mobil/lib/core/storage/local_db/local_db_models.dart
git commit -m "feat(mobil): moderation_blacklist LocalDbBucket + ModerationBlacklistRepository eklendi"
```

---

### Task 9: Mobil — `ContentModeration` sunucudan gelen listeyi kullanacak şekilde refaktör + testler

**Files:**
- Modify: `uygulamalar/mobil/lib/core/content/content_moderation.dart`
- Create: `uygulamalar/mobil/test/core/content/content_moderation_test.dart`

- [ ] **Step 1: Saf eşleşme mantığını test edilebilir hale getiren testi yaz**

```dart
// uygulamalar/mobil/test/core/content/content_moderation_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:yeedoy/core/content/content_moderation.dart';

void main() {
  group('blacklistMatches', () {
    test('detects a blacklisted term regardless of case and spacing', () {
      expect(blacklistMatches('Bu bir SIKTIR yorumu', ['siktir']), isTrue);
      expect(blacklistMatches('bu s i k t i r yorumu', ['siktir']), isTrue);
    });

    test('does not flag clean text', () {
      expect(
        blacklistMatches('gayet güzel bir mekan', ['siktir', 'amk']),
        isFalse,
      );
    });

    test('handles an empty blacklist safely', () {
      expect(blacklistMatches('herhangi bir metin', const []), isFalse);
    });

    test('matches obfuscated variants via normalization', () {
      expect(blacklistMatches('4mk yorumu', ['amk']), isTrue);
    });
  });

  group('ContentModeration.validateReview', () {
    test('rejects content shorter than minimum length', () async {
      final result = await ContentModeration.instance.validateReview(
        content: 'kisa',
      );
      expect(result, isNotNull);
      expect(result!.code, 'content_too_short');
    });
  });
}
```

- [ ] **Step 2: Testi çalıştır, fail ettiğini doğrula**

```bash
cd uygulamalar/mobil && flutter test test/core/content/content_moderation_test.dart
```

Beklenen: FAIL (`blacklistMatches` tanımlı değil — henüz export edilmedi).

- [ ] **Step 3: `content_moderation.dart`'ı refaktör et**

Dosyanın tamamını şununla değiştir (mevcut regex/normalize mantığı aynen korunuyor,
sadece `_loadBlacklist`'in kaynağı değişiyor ve saf eşleşme mantığı top-level, test
edilebilir bir fonksiyona çıkarılıyor):

```dart
import 'dart:async';

import '../errors/app_error_codes.dart';
import 'moderation_blacklist_repository.dart';

class ContentModerationResult {
  const ContentModerationResult({required this.code, required this.message});

  final String code;
  final String message;
}

/// Verilen metnin, verilen kara liste terimlerinden herhangi birini içerip
/// içermediğini kontrol eden saf fonksiyon (I/O yok, doğrudan test edilebilir).
bool blacklistMatches(String text, List<String> blacklist) {
  if (blacklist.isEmpty) return false;

  final raw = text.toLowerCase();
  final normalizedText = _normalizeForSearch(raw);
  final compactText = normalizedText.replaceAll(' ', '');

  for (final term in blacklist) {
    if (term.isEmpty) continue;

    final t = term.toLowerCase();
    if (raw.contains(t)) return true;

    final normalizedTerm = _normalizeForSearch(t);
    if (normalizedTerm.isEmpty) continue;
    if (normalizedText.contains(normalizedTerm)) return true;

    final compactTerm = normalizedTerm.replaceAll(' ', '');
    if (compactTerm.isNotEmpty && compactText.contains(compactTerm)) {
      return true;
    }
  }

  return false;
}

String _normalizeForSearch(String text) {
  var s = text.toLowerCase();
  s = s
      .replaceAll('ç', 'c')
      .replaceAll('ğ', 'g')
      .replaceAll('ı', 'i')
      .replaceAll('ö', 'o')
      .replaceAll('ş', 's')
      .replaceAll('ü', 'u')
      .replaceAll('@', 'a')
      .replaceAll('4', 'a')
      .replaceAll('0', 'o')
      .replaceAll('1', 'i')
      .replaceAll('!', 'i')
      .replaceAll('5', 's')
      .replaceAll(r'$', 's')
      .replaceAll('3', 'e');
  return s.replaceAll(RegExp(r'[^a-z0-9]+'), ' ').trim();
}

class ContentModeration {
  ContentModeration._();

  static final ContentModeration instance = ContentModeration._();

  static const _minContentLength = 8;
  static const _maxEmojiCount = 6;

  ModerationBlacklistRepository? _repository;

  /// Test'lerde veya widget ağacı dışında çağrılırken gerçek Supabase client'a
  /// ihtiyaç duymamak için repository dışarıdan enjekte edilebilir.
  void configureRepository(ModerationBlacklistRepository repository) {
    _repository = repository;
  }

  Future<ContentModerationResult?> validateReview({
    required String content,
    String? title,
  }) async {
    if (content.trim().length < _minContentLength) {
      return const ContentModerationResult(
        code: AppErrorCodes.contentTooShort,
        message: 'Yorum en az 8 karakter olmali.',
      );
    }

    final risky = await _validateText(content);
    if (risky != null) return risky;

    if (title != null && title.trim().isNotEmpty) {
      final titleRisk = await _validateText(title);
      if (titleRisk != null) return titleRisk;
    }

    return null;
  }

  Future<ContentModerationResult?> validateNote(String text) async {
    if (text.trim().isEmpty) return null;
    return _validateText(text);
  }

  Future<ContentModerationResult?> _validateText(String text) async {
    if (_containsLinkPhoneOrEmail(text)) {
      return const ContentModerationResult(
        code: AppErrorCodes.containsLinkOrPhone,
        message: 'Link, e-posta veya telefon paylasamazsin.',
      );
    }

    if (_isEmojiSpam(text)) {
      return const ContentModerationResult(
        code: AppErrorCodes.emojiSpam,
        message: 'Çok fazla emoji kullanımı tespit edildi.',
      );
    }

    if (_hasRepeatedJunk(text)) {
      return const ContentModerationResult(
        code: AppErrorCodes.emojiSpam,
        message: 'Tekrarlayan spam icerik tespit edildi.',
      );
    }

    if (_containsObfuscatedProfanity(text) ||
        blacklistMatches(text, await _loadBlacklist())) {
      return const ContentModerationResult(
        code: AppErrorCodes.containsProfanity,
        message: 'Uygunsuz içerik tespit edildi.',
      );
    }

    return null;
  }

  bool _containsLinkPhoneOrEmail(String text) {
    final pattern = RegExp(
      r'(https?://|www\.|t\.me/|wa\.me/|instagram\.com/|[A-Z0-9._%+\-]+@[A-Z0-9.\-]+\.[A-Z]{2,}|(\+?\d[\d\s\-\(\)]{7,}\d))',
      caseSensitive: false,
    );
    return pattern.hasMatch(text);
  }

  bool _isEmojiSpam(String text) {
    final emojiPattern = RegExp(
      r'[\u{1F300}-\u{1FAFF}\u{2600}-\u{27BF}]',
      unicode: true,
    );
    final matches = emojiPattern.allMatches(text);
    if (matches.length >= _maxEmojiCount) return true;

    final nonWord = text.replaceAll(RegExp(r'[A-Za-z0-9\sÀ-ſ]'), '');
    return nonWord.length >= 10;
  }

  bool _hasRepeatedJunk(String text) {
    final normalized = text.trim();
    if (normalized.isEmpty) return false;
    if (RegExp(r'(.)\1{5,}').hasMatch(normalized)) return true;
    if (RegExp(r'([!?.,])\1{4,}').hasMatch(normalized)) return true;
    if (RegExp(
      r'\b(\w{2,})\b(?:\s+\1\b){3,}',
      caseSensitive: false,
    ).hasMatch(normalized)) {
      return true;
    }
    return false;
  }

  bool _containsObfuscatedProfanity(String text) {
    final normalized = _normalizeForSearch(text);
    final compact = normalized.replaceAll(' ', '');

    if (RegExp(
      r'(^| )a\s*m\s*k( |$)',
      caseSensitive: false,
    ).hasMatch(normalized)) {
      return true;
    }

    if (RegExp(
      r'(amk|amq|aq|siktir|sikik|sikicem|orospu|orosbu|pic|yarrak|gavat|ibne|gotveren)',
      caseSensitive: false,
    ).hasMatch(compact)) {
      return true;
    }

    return false;
  }

  static Future<List<String>>? _blacklistCache;

  Future<List<String>> _loadBlacklist() {
    return _blacklistCache ??= _fetchBlacklist();
  }

  Future<List<String>> _fetchBlacklist() async {
    final repo = _repository;
    if (repo == null) return const [];
    try {
      return await repo.fetchTerms();
    } catch (_) {
      return const [];
    }
  }
}
```

**Not:** `_blacklistCache` process ömrü boyunca bir kez set edilir (uygulama yeniden
başlatılınca sıfırlanır) — asıl TTL/yenileme mantığı zaten `ModerationBlacklistRepository`
içinde (24 saatlik `LocalDbStore` cache'i) yaşıyor, burada sadece aynı process içinde
tekrar tekrar repository'ye gitmemek için basit bir in-memory memoization var.

`configureRepository` çağrısı uygulama başlangıcında (`main.dart` veya bir provider
initialization noktasında) `ContentModeration.instance.configureRepository(ref.read(moderationBlacklistRepositoryProvider))`
şeklinde yapılmalı — **bunu Step 4'te ekleyeceğiz**.

- [ ] **Step 4: `main.dart`'ta repository'yi bağla**

`uygulamalar/mobil/lib/main.dart`'ta zaten `main()` içinde bir `rootContainer = ProviderContainer();`
(satır 108) var ve `_installFrameDropObserver(rootContainer);` (satır 109) ile hemen
kullanılıyor. Bu satırın hemen altına ekle:

```dart
  final rootContainer = ProviderContainer();
  _installFrameDropObserver(rootContainer);
  ContentModeration.instance.configureRepository(
    rootContainer.read(moderationBlacklistRepositoryProvider),
  );
```

Dosyanın en üstündeki import bloğuna (`import 'core/security/safe_debug_print.dart';`
satırının altına) şu iki import'u ekle:

```dart
import 'core/content/content_moderation.dart';
import 'core/content/moderation_blacklist_repository.dart';
```

- [ ] **Step 5: Testi tekrar çalıştır**

```bash
cd uygulamalar/mobil && flutter test test/core/content/content_moderation_test.dart
```

Beklenen: PASS (5/5). (`validateReview` testi `_repository` set edilmemiş olsa da
`content_too_short` kontrolü blacklist'e hiç gitmeden erken döndüğü için sorunsuz geçer.)

- [ ] **Step 6: `flutter analyze`**

```bash
cd uygulamalar/mobil && flutter analyze
```

Beklenen: `No issues found!`

- [ ] **Step 7: Commit**

```bash
git add uygulamalar/mobil/lib/core/content/content_moderation.dart uygulamalar/mobil/lib/main.dart uygulamalar/mobil/test/core/content/content_moderation_test.dart
git commit -m "refactor(mobil): ContentModeration sunucudan gelen kara listeyi kullanıyor, saf eşleşme mantığı test edilebilir hale getirildi"
```

---

### Task 10: `karaliste.txt` kaldırılıyor

**Files:**
- Delete: `uygulamalar/mobil/assets/json/karaliste.txt`
- Modify: `uygulamalar/mobil/pubspec.yaml`

- [ ] **Step 1: Dosyayı sil**

```bash
rm uygulamalar/mobil/assets/json/karaliste.txt
```

- [ ] **Step 2: `pubspec.yaml`'dan asset kaydını kaldır**

`uygulamalar/mobil/pubspec.yaml` içindeki `assets:` listesinden şu satırı sil:

```yaml
    - assets/json/karaliste.txt
```

- [ ] **Step 3: Hiçbir yerde referans kalmadığını doğrula**

```bash
grep -rn "karaliste" uygulamalar/mobil/lib uygulamalar/mobil/pubspec.yaml
```

Beklenen: boş (hiç sonuç yok).

- [ ] **Step 4: `flutter analyze` + `flutter pub get`**

```bash
cd uygulamalar/mobil && flutter pub get && flutter analyze
```

Beklenen: `No issues found!`

- [ ] **Step 5: Commit**

```bash
git add uygulamalar/mobil/assets/json/karaliste.txt uygulamalar/mobil/pubspec.yaml
git commit -m "chore(mobil): karaliste.txt kaldırıldı, kara liste artık sunucudan geliyor"
```

---

### Task 11: Uçtan uca doğrulama

**Files:** Yok (sadece doğrulama)

- [ ] **Step 1: Sunucu tarafı regresyon — 3 strike sonrası shadow-ban**

```sql
-- Gerçek bir test kullanıcısının id'sini kullan
select add_moderation_strike_v1('<test_user_id>', 'test', 'manual_test');
select add_moderation_strike_v1('<test_user_id>', 'test', 'manual_test');
select add_moderation_strike_v1('<test_user_id>', 'test', 'manual_test');
select shadow_banned from user_profiles where user_id = '<test_user_id>';
```

Beklenen: 3. çağrıdan sonra `shadow_banned = true`. (Test sonrası `shadow_banned`'i
`false`'a geri al ve `user_moderation_strikes`'tan test satırlarını sil — gerçek bir
kullanıcıyı kalıcı olarak etkileme.)

- [ ] **Step 2: Mobil — gerçek cihaz/emulator olmadan, kod okuma + testlerle doğrulama**

```bash
cd uygulamalar/mobil && flutter test test/core/content/content_moderation_test.dart -v
```

Beklenen: tüm testler PASS.

- [ ] **Step 3: Web — tam test paketi**

```bash
cd uygulamalar/web && pnpm run test
```

Beklenen: `typecheck` + `lint` + `test:unit` hepsi geçmeli.

- [ ] **Step 4: Admin paneli manuel kontrolü**

`/yonetici/kara-liste` sayfasını gerçek bir admin hesabıyla aç, bir terim ekle, listede
göründüğünü doğrula, sil, listeden kalktığını doğrula.

- [ ] **Step 5: Sonuç özeti**

Bu adımda kod değişikliği yok — sadece Task 1-10'un tamamının commit edildiğini
doğrula (`git log --oneline -15`) ve varsa kalan `git status` kirliliğini kontrol et.

---

## Faz Sonrası Not

Bu plan sırasında (kapsamsız) fark edilen ayrı bir bug: `page:yoresel-mutfak` izni
`admin-izinler.ts`'e ve nav'a eklenmiş ama **DB'deki `admin_permission_key` enum'una hiç
eklenmemiş** — yani `/yonetici/yoresel-mutfak` sayfası muhtemelen hiçbir admin hesabı için
açılamıyor. Bu, bu planın kapsamı dışında (ayrı bir bug, ayrı bir düzeltme gerektiriyor)
ama önceki oturumun bekleyen "Task 12: uçtan uca doğrulama" adımını doğrudan
engelleyebilir — ayrıca ele alınmalı.
