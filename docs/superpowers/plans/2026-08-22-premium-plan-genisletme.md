# Premium Plan Genişletmesi Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Mevcut premium plan/gating altyapısını (`plan_features`, `_check_plan_limit_v1`, `get_my_plan_v1`) dört yeni özelliğe (ekip üyesi sayısı, CRM e-posta kampanyası, çoklu şube, analitik derinliği) ve destek ticket önceliğine genişletmek; owner panelindeki plan gösterimini (`baslangic`, `gosterge-panosu`, `ayarlar/plan`, `premium`) tutarlı hale getirmek.

**Architecture:** Yeni tablo/RPC sistemi yok — 2026-08-03'te kurulan `plan_features`/`_check_plan_limit_v1`/`get_my_plan_v1` deseni birebir genişletiliyor. `team_seat_count` ve `branch_count`, `menu_item_count` gibi "anlık durum sayısı" (mevcut satır sayısı limitle karşılaştırılır); `campaign_count_per_month`, `ocr_scans_per_month` gibi aylık sayaç (`plan_feature_usage`). Destek önceliği `plan_features`'a girmiyor — mevcut `support_tickets.priority` enum'una ticket oluşturma anında doğrudan kademe bazlı değer atanıyor. UI tarafında `FEATURE_LABELS`/`TIER_LABELS` tek paylaşılan modülde birleştiriliyor (bugün iki bağımsız kopya var, biri `sadakat_programi` etiketini eksik bırakmış).

**Tech Stack:** Supabase (Postgres/plpgsql), Next.js 15 App Router (Server Components + Server Actions), TypeScript, vitest.

**Spec:** `docs/superpowers/specs/2026-08-22-premium-plan-genisletme-design.md`

**Önemli notlar (spec onayından sonra kod denetiminde netleşen detaylar):**
1. `upsert_team_member_v1` `RAISE EXCEPTION` değil, `jsonb {ok, code}` döndürüyor — plan limiti aşımı bu fonksiyonda `_check_plan_limit_v1`'in fırlattığı `P0003`'ü yakalayıp `{ok:false, code:'plan_limit_exceeded', feature_key:'team_seat_count'}`'a çeviren bir `BEGIN...EXCEPTION` bloğu gerektiriyor. `owner_upsert_campaign_v1`, `owner_add_business_to_chain_v1`, `create_support_ticket_v1` zaten `RAISE EXCEPTION` deseninde — doğrudan çağrılabilir.
2. Ekip koltuğu sayımı `business_team_memberships` tablosundan (`team_members` diye bir tablo yok) `revoked_at is null` filtresiyle yapılır ve işletme sahibinin kendisini de kapsar (Free'de sahip zaten 1 koltuğu doldurur).
3. Şube sayımı `businesses.chain_id` üzerinden yapılır (`chains` tablosu ayrı, üyelik `businesses.chain_id` FK'siyle). Limit kontrolü yalnızca `owner_add_business_to_chain_v1`'de gerekli — `owner_create_chain_v1` tek işletmeli bir zincir oluşturduğu için (1 ≤ herhangi bir limit) hiçbir kademede engellenmiyor.
4. `get_my_plan_v1`'in kendi ayrı bir "used" hesaplama `CASE` bloğu var (`_check_plan_limit_v1`'den bağımsız) — ikisi de güncellenmeli, aksi halde Plan sayfası yanlış "kullanılan" sayısı gösterir.
5. `analytics_range_days` bir "kullanım sayacı" değil, bir "izin verilen tavan" — Plan sayfasında `{used}/{limit}` yerine düz "Son {limit} gün" rozeti gösterilir (aksi halde anlamsız "0/90" görünür).
6. 2026-08-03 dokümanının §8'inde bahsedilen "ortak kilitli özellik bileşeni" **kodda mevcut değil** (`/sahip/pazarlama/sadakat/page.tsx` kilitliyken doğrudan `PanelEmptyState` kullanıyor, ayrı bir paylaşılan bileşen yok) — bu plan yeni bir tane icat etmiyor, `baslangic` sayfasındaki `OneriKarti`'ye küçük bir `locked` prop'u ekliyor.

---

### Task 1: Migration — yeni `plan_features` satırları

**Files:**
- Create: `supabase/migrations/20260822000001_premium_plan_genisletme_features.sql`

- [ ] **Step 1: Migration dosyasını yaz**

Create `supabase/migrations/20260822000001_premium_plan_genisletme_features.sql`:

```sql
-- Premium plan genişletmesi: ekip üyesi, CRM kampanyası, çoklu şube, analitik derinliği.
-- Şema değişikliği yok — plan_features zaten genel amaçlı (plan_tier, feature_key, limit_value, enabled).

INSERT INTO public.plan_features (plan_tier, feature_key, limit_value, enabled) VALUES
  ('free',     'team_seat_count',           1,    true),
  ('starter',  'team_seat_count',           3,    true),
  ('standard', 'team_seat_count',           10,   true),
  ('pro',      'team_seat_count',           NULL, true),

  ('free',     'campaign_count_per_month',  0,    true),
  ('starter',  'campaign_count_per_month',  1,    true),
  ('standard', 'campaign_count_per_month',  5,    true),
  ('pro',      'campaign_count_per_month',  NULL, true),

  ('free',     'branch_count',              1,    true),
  ('starter',  'branch_count',              1,    true),
  ('standard', 'branch_count',              3,    true),
  ('pro',      'branch_count',              NULL, true),

  ('free',     'analytics_range_days',      7,    true),
  ('starter',  'analytics_range_days',      30,   true),
  ('standard', 'analytics_range_days',      90,   true),
  ('pro',      'analytics_range_days',      90,   true)
ON CONFLICT (plan_tier, feature_key) DO NOTHING;
```

- [ ] **Step 2: Uygula ve doğrula**

Run:
```bash
psql "$SUPABASE_DB_URL" -f supabase/migrations/20260822000001_premium_plan_genisletme_features.sql
psql "$SUPABASE_DB_URL" -c "select plan_tier, feature_key, limit_value from public.plan_features where feature_key in ('team_seat_count','campaign_count_per_month','branch_count','analytics_range_days') order by feature_key, plan_tier"
```
Expected: 16 satır döner (4 kademe × 4 özellik), `campaign_count_per_month`/`free` satırı `limit_value=0`.

- [ ] **Step 3: Commit**

```bash
git add supabase/migrations/20260822000001_premium_plan_genisletme_features.sql
git commit -m "feat(db): premium plan genişletmesi — ekip/CRM/çoklu-şube/analitik plan_features satırları"
```

---

### Task 2: Migration — `_check_plan_limit_v1` ve `get_my_plan_v1`'e anlık-sayaç desteği

**Files:**
- Create: `supabase/migrations/20260822000002_check_plan_limit_instant_counters.sql`

- [ ] **Step 1: Migration dosyasını yaz**

Create `supabase/migrations/20260822000002_check_plan_limit_instant_counters.sql`:

```sql
-- _check_plan_limit_v1: menu_item_count'a ek olarak team_seat_count ve branch_count için de
-- "anlık durum sayısı" hesabı ekleniyor (plan_feature_usage aylık sayacı yerine).
CREATE OR REPLACE FUNCTION public._check_plan_limit_v1(p_business_id uuid, p_feature_key text)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_tier    text;
  v_enabled boolean;
  v_limit   int;
  v_used    int;
  v_chain_id uuid;
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM public.owner_claims oc
    WHERE oc.business_id = p_business_id
      AND oc.user_id = auth.uid()
      AND oc.status = 'approved'
  ) AND NOT public.is_admin() THEN
    RAISE EXCEPTION 'unauthorized' USING ERRCODE = 'P0002';
  END IF;

  v_tier := public._get_business_plan_tier_v1(p_business_id);

  SELECT enabled, limit_value INTO v_enabled, v_limit
  FROM public.plan_features
  WHERE plan_tier = v_tier AND feature_key = p_feature_key;

  IF NOT FOUND OR NOT v_enabled THEN
    RAISE EXCEPTION 'plan_limit_exceeded: %', p_feature_key USING ERRCODE = 'P0003';
  END IF;

  IF v_limit IS NULL THEN
    RETURN; -- sınırsız
  END IF;

  IF p_feature_key = 'menu_item_count' THEN
    SELECT count(*) INTO v_used
    FROM public.menu_items mi
    WHERE mi.business_id = p_business_id;
  ELSIF p_feature_key = 'team_seat_count' THEN
    SELECT b.chain_id INTO v_chain_id FROM public.businesses b WHERE b.id = p_business_id;
    SELECT count(*) INTO v_used
    FROM public.business_team_memberships btm
    WHERE btm.revoked_at IS NULL
      AND (btm.business_id = p_business_id OR (v_chain_id IS NOT NULL AND btm.chain_id = v_chain_id));
  ELSIF p_feature_key = 'branch_count' THEN
    SELECT b.chain_id INTO v_chain_id FROM public.businesses b WHERE b.id = p_business_id;
    IF v_chain_id IS NULL THEN
      v_used := 1; -- henüz zincirde değil = kendi başına 1 şube sayılır
    ELSE
      SELECT count(*) INTO v_used FROM public.businesses WHERE chain_id = v_chain_id;
    END IF;
  ELSE
    SELECT COALESCE(usage_count, 0) INTO v_used
    FROM public.plan_feature_usage
    WHERE business_id = p_business_id
      AND feature_key = p_feature_key
      AND period_start = date_trunc('month', now())::date;
    v_used := COALESCE(v_used, 0);
  END IF;

  IF v_used >= v_limit THEN
    RAISE EXCEPTION 'plan_limit_exceeded: %', p_feature_key USING ERRCODE = 'P0003';
  END IF;
END;
$$;

COMMENT ON FUNCTION public._check_plan_limit_v1 IS
  'Plan limiti kontrolü. menu_item_count/team_seat_count/branch_count anlık satır sayımı, diğerleri plan_feature_usage aylık sayacı. Aşılmışsa P0003 plan_limit_exceeded fırlatır.';

-- get_my_plan_v1: owner-facing özet de aynı iki yeni anlık-sayaç özelliğini doğru "used" ile göstermeli.
CREATE OR REPLACE FUNCTION public.get_my_plan_v1(p_business_id uuid)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_tier     text;
  v_features jsonb;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'unauthorized' USING ERRCODE = 'P0002';
  END IF;
  IF NOT EXISTS (
    SELECT 1 FROM public.owner_claims oc
    WHERE oc.business_id = p_business_id AND oc.user_id = auth.uid() AND oc.status = 'approved'
  ) AND NOT public.is_admin() THEN
    RAISE EXCEPTION 'unauthorized' USING ERRCODE = 'P0002';
  END IF;

  v_tier := public._get_business_plan_tier_v1(p_business_id);

  SELECT jsonb_agg(jsonb_build_object(
    'feature_key', pf.feature_key,
    'enabled', pf.enabled,
    'limit_value', pf.limit_value,
    'used', CASE
      WHEN pf.feature_key = 'menu_item_count' THEN (
        SELECT count(*) FROM public.menu_items WHERE business_id = p_business_id
      )
      WHEN pf.feature_key = 'language_count' THEN (
        SELECT 1 + count(DISTINCT mt.locale)
        FROM public.menu_translations mt
        JOIN public.menu_items mi ON mi.id = mt.entity_id AND mt.entity_type = 'item'
        WHERE mi.business_id = p_business_id
      )
      WHEN pf.feature_key = 'team_seat_count' THEN (
        SELECT count(*) FROM public.business_team_memberships btm
        WHERE btm.revoked_at IS NULL
          AND (
            btm.business_id = p_business_id
            OR (btm.chain_id IS NOT NULL AND btm.chain_id = (SELECT chain_id FROM public.businesses WHERE id = p_business_id))
          )
      )
      WHEN pf.feature_key = 'branch_count' THEN (
        SELECT CASE
          WHEN b.chain_id IS NULL THEN 1
          ELSE (SELECT count(*) FROM public.businesses WHERE chain_id = b.chain_id)
        END
        FROM public.businesses b WHERE b.id = p_business_id
      )
      ELSE COALESCE((
        SELECT usage_count FROM public.plan_feature_usage
        WHERE business_id = p_business_id
          AND feature_key = pf.feature_key
          AND period_start = date_trunc('month', now())::date
      ), 0)
    END
  ) ORDER BY pf.feature_key)
  INTO v_features
  FROM public.plan_features pf
  WHERE pf.plan_tier = v_tier;

  RETURN jsonb_build_object('plan_tier', v_tier, 'features', COALESCE(v_features, '[]'::jsonb));
END;
$$;
```

- [ ] **Step 2: Uygula ve doğrula**

Run:
```bash
psql "$SUPABASE_DB_URL" -f supabase/migrations/20260822000002_check_plan_limit_instant_counters.sql
```

Doğrulama — gerçek bir free-kademe işletme ID'si ile (`select id from businesses where id in (select business_id from owner_claims where status='approved') limit 1`):
```bash
psql "$SUPABASE_DB_URL" -c "select public.get_my_plan_v1('<business_id>'::uuid)" 
```
Expected: dönen jsonb'de `team_seat_count` ve `branch_count` satırlarının `used` alanı 0/NULL değil, gerçek sayı (en az sahip için 1) gösteriyor.

- [ ] **Step 3: Commit**

```bash
git add supabase/migrations/20260822000002_check_plan_limit_instant_counters.sql
git commit -m "feat(db): _check_plan_limit_v1 ve get_my_plan_v1'e team_seat_count/branch_count anlık sayım desteği"
```

---

### Task 3: Migration — `upsert_team_member_v1` koltuk limiti

**Files:**
- Create: `supabase/migrations/20260822000003_team_seat_limit.sql`

- [ ] **Step 1: Migration dosyasını yaz**

`upsert_team_member_v1` yalnızca YENİ üyelik (INSERT dalı) için limit kontrolü yapmalı — mevcut bir üyeliği güncellemek (rol değişikliği, yeniden davet) koltuk tüketmiyor. Fonksiyon `jsonb {ok,code}` döndürdüğü için `_check_plan_limit_v1`'in `P0003` fırlatması yakalanıp aynı sözleşmeye çevriliyor.

Create `supabase/migrations/20260822000003_team_seat_limit.sql`:

```sql
CREATE OR REPLACE FUNCTION public.upsert_team_member_v1(
  p_business_id uuid, p_email text, p_role text, p_scope text DEFAULT 'this_business'::text
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_email text := lower(nullif(trim(coalesce(p_email, '')), ''));
  v_role text := lower(nullif(trim(coalesce(p_role, '')), ''));
  v_scope text := lower(nullif(trim(coalesce(p_scope, '')), ''));
  v_chain_id uuid;
  v_user_id uuid;
  v_membership_id uuid;
  v_is_new boolean := false;
BEGIN
  if auth.uid() is null then
    return jsonb_build_object('ok', false, 'code', 'not_authenticated');
  end if;

  if not (public.is_admin() or public.has_business_permission_v1(p_business_id, 'team_manage')) then
    return jsonb_build_object('ok', false, 'code', 'forbidden');
  end if;

  if v_email is null then
    return jsonb_build_object('ok', false, 'code', 'email_required');
  end if;

  if v_role not in ('owner', 'manager', 'editor', 'staff', 'viewer') then
    return jsonb_build_object('ok', false, 'code', 'invalid_role');
  end if;

  if v_scope not in ('this_business', 'all_branches') then
    return jsonb_build_object('ok', false, 'code', 'invalid_scope');
  end if;

  select b.chain_id
  into v_chain_id
  from public.businesses b
  where b.id = p_business_id;

  if v_scope = 'all_branches' and v_chain_id is null then
    return jsonb_build_object('ok', false, 'code', 'chain_required');
  end if;

  select u.id
  into v_user_id
  from auth.users u
  where lower(u.email::text) = v_email
  limit 1;

  select btm.id
  into v_membership_id
  from public.business_team_memberships btm
  where btm.revoked_at is null
    and (
      (
        v_scope = 'this_business'
        and btm.business_id = p_business_id
      ) or (
        v_scope = 'all_branches'
        and btm.chain_id = v_chain_id
      )
    )
  order by btm.created_at desc
  limit 1;

  v_is_new := v_membership_id is null;

  IF v_is_new THEN
    BEGIN
      PERFORM public._check_plan_limit_v1(p_business_id, 'team_seat_count');
    EXCEPTION WHEN SQLSTATE 'P0003' THEN
      RETURN jsonb_build_object('ok', false, 'code', 'plan_limit_exceeded', 'feature_key', 'team_seat_count');
    END;
  END IF;

  if v_membership_id is null then
    insert into public.business_team_memberships(
      business_id,
      chain_id,
      user_id,
      invite_email,
      role,
      created_by,
      accepted_at
    )
    values (
      case when v_scope = 'this_business' then p_business_id else null end,
      case when v_scope = 'all_branches' then v_chain_id else null end,
      v_user_id,
      v_email,
      v_role,
      auth.uid(),
      case when v_user_id is not null then now() else null end
    )
    returning id into v_membership_id;
  else
    update public.business_team_memberships
    set
      business_id = case when v_scope = 'this_business' then p_business_id else null end,
      chain_id = case when v_scope = 'all_branches' then v_chain_id else null end,
      user_id = coalesce(v_user_id, user_id),
      invite_email = v_email,
      role = v_role,
      accepted_at = case
        when v_user_id is not null then coalesce(accepted_at, now())
        else accepted_at
      end,
      revoked_at = null,
      updated_at = now()
    where id = v_membership_id;
  end if;

  insert into public.admin_audit_log(action, target_table, target_id, meta)
  values (
    'owner.team.upsert',
    'business_team_memberships',
    v_membership_id,
    jsonb_build_object(
      'actor_id', auth.uid(),
      'business_id', p_business_id,
      'email', v_email,
      'role', v_role,
      'scope', v_scope
    )
  );

  return jsonb_build_object('ok', true, 'membership_id', v_membership_id, 'linked_user_id', v_user_id);
END;
$$;
```

- [ ] **Step 2: Uygula ve doğrula**

Run:
```bash
psql "$SUPABASE_DB_URL" -f supabase/migrations/20260822000003_team_seat_limit.sql
```

Doğrulama — free kademedeki (limit=1) bir işletmede sahip zaten 1 koltuğu dolduruyor, yeni davet denemesi engellenmeli:
```bash
psql "$SUPABASE_DB_URL" -c "select public.upsert_team_member_v1('<free_business_id>'::uuid, 'test@example.com', 'staff', 'this_business')"
```
Expected: `{"ok": false, "code": "plan_limit_exceeded", "feature_key": "team_seat_count"}`

- [ ] **Step 3: Commit**

```bash
git add supabase/migrations/20260822000003_team_seat_limit.sql
git commit -m "feat(db): upsert_team_member_v1'e team_seat_count plan limiti eklendi"
```

---

### Task 4: Migration — CRM kampanyası aylık limiti

**Files:**
- Create: `supabase/migrations/20260822000004_campaign_monthly_limit.sql`

- [ ] **Step 1: Migration dosyasını yaz**

Yalnızca YENİ kampanya oluşturma (`p_id IS NULL` dalı) sayaç tüketir; düzenleme tüketmez.

Create `supabase/migrations/20260822000004_campaign_monthly_limit.sql`:

```sql
CREATE OR REPLACE FUNCTION public.owner_upsert_campaign_v1(
  p_business_id uuid, p_title text, p_type text, p_status text DEFAULT 'draft'::text,
  p_description text DEFAULT NULL::text, p_discount_percent smallint DEFAULT NULL::smallint,
  p_starts_at timestamp with time zone DEFAULT NULL::timestamp with time zone,
  p_ends_at timestamp with time zone DEFAULT NULL::timestamp with time zone,
  p_image_url text DEFAULT NULL::text, p_id uuid DEFAULT NULL::uuid
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE v_id UUID;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'unauthorized' USING ERRCODE = 'P0002';
  END IF;
  IF NOT EXISTS (
    SELECT 1 FROM public.owner_claims oc
    WHERE oc.business_id = p_business_id AND oc.user_id = auth.uid() AND oc.status = 'approved'
  ) THEN
    RAISE EXCEPTION 'unauthorized' USING ERRCODE = 'P0002';
  END IF;

  IF p_id IS NULL THEN
    PERFORM public._check_plan_limit_v1(p_business_id, 'campaign_count_per_month');

    INSERT INTO public.campaigns
      (business_id, title, description, type, status,
       discount_percent, starts_at, ends_at, image_url, created_by)
    VALUES
      (p_business_id, p_title, p_description, p_type, p_status,
       p_discount_percent, p_starts_at, p_ends_at, p_image_url, auth.uid())
    RETURNING id INTO v_id;

    PERFORM public._increment_plan_usage_v1(p_business_id, 'campaign_count_per_month');
  ELSE
    UPDATE public.campaigns SET
      title            = p_title,
      description      = p_description,
      type             = p_type,
      status           = p_status,
      discount_percent = p_discount_percent,
      starts_at        = p_starts_at,
      ends_at          = p_ends_at,
      image_url        = p_image_url
    WHERE id = p_id AND business_id = p_business_id
    RETURNING id INTO v_id;
    IF v_id IS NULL THEN
      RAISE EXCEPTION 'not_found' USING ERRCODE = 'P0001';
    END IF;
  END IF;

  RETURN v_id;
END;
$$;
```

- [ ] **Step 2: Uygula ve doğrula**

Run:
```bash
psql "$SUPABASE_DB_URL" -f supabase/migrations/20260822000004_campaign_monthly_limit.sql
```

Doğrulama — free kademede (`campaign_count_per_month=0`) yeni kampanya denemesi:
```bash
psql "$SUPABASE_DB_URL" -c "select public.owner_upsert_campaign_v1('<free_business_id>'::uuid, 'Test Kampanya', 'discount')"
```
Expected: `ERROR: plan_limit_exceeded: campaign_count_per_month`

- [ ] **Step 3: Commit**

```bash
git add supabase/migrations/20260822000004_campaign_monthly_limit.sql
git commit -m "feat(db): owner_upsert_campaign_v1'e campaign_count_per_month aylık limiti eklendi"
```

---

### Task 5: Migration — Çoklu şube limiti

**Files:**
- Create: `supabase/migrations/20260822000005_branch_count_limit.sql`

- [ ] **Step 1: Migration dosyasını yaz**

Yalnızca `owner_add_business_to_chain_v1` değişiyor — `owner_create_chain_v1`'e dokunulmuyor (tek işletmeli zincir hiçbir kademede limiti aşmaz, bkz. plan başlığındaki not).

Create `supabase/migrations/20260822000005_branch_count_limit.sql`:

```sql
CREATE OR REPLACE FUNCTION public.owner_add_business_to_chain_v1(
  p_chain_id uuid, p_business_id uuid, p_branch_label text
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_next_sort integer;
  v_owner_business_id uuid;
BEGIN
  IF NOT public._is_approved_owner_of_business(p_business_id) THEN
    RAISE EXCEPTION 'unauthorized: eklenecek işletme size ait değil' USING ERRCODE = 'P0002';
  END IF;

  IF EXISTS (SELECT 1 FROM public.businesses WHERE id = p_business_id AND chain_id IS NOT NULL) THEN
    RAISE EXCEPTION 'validation_error: işletme zaten bir zincirde' USING ERRCODE = 'P0003';
  END IF;

  SELECT b.id INTO v_owner_business_id
  FROM public.businesses b
  WHERE b.chain_id = p_chain_id AND public._is_approved_owner_of_business(b.id)
  LIMIT 1;

  IF v_owner_business_id IS NULL THEN
    RAISE EXCEPTION 'unauthorized: bu zincir üzerinde yetkiniz yok' USING ERRCODE = 'P0002';
  END IF;

  -- Plan limiti, zincirin mevcut sahibi işletmesinin kademesine göre kontrol edilir
  -- (eklenen işletmenin kendi kademesi değil — zincirin limiti zincir sahibinin planına bağlı).
  PERFORM public._check_plan_limit_v1(v_owner_business_id, 'branch_count');

  SELECT COALESCE(MAX(chain_sort_order), -1) + 1 INTO v_next_sort
  FROM public.businesses WHERE chain_id = p_chain_id;

  UPDATE public.businesses
  SET chain_id = p_chain_id,
      branch_label = NULLIF(trim(coalesce(p_branch_label, '')), ''),
      chain_sort_order = v_next_sort
  WHERE id = p_business_id;
END;
$$;
```

- [ ] **Step 2: Uygula ve doğrula**

Run:
```bash
psql "$SUPABASE_DB_URL" -f supabase/migrations/20260822000005_branch_count_limit.sql
```

Doğrulama — free/başlangıç kademesinde (`branch_count=1`) zaten 1 şubesi olan bir zincire 2. şube eklemeyi dene:
```bash
psql "$SUPABASE_DB_URL" -c "select public.owner_add_business_to_chain_v1('<chain_id>'::uuid, '<second_business_id>'::uuid, 'Şube 2')"
```
Expected: `ERROR: plan_limit_exceeded: branch_count`

- [ ] **Step 3: Commit**

```bash
git add supabase/migrations/20260822000005_branch_count_limit.sql
git commit -m "feat(db): owner_add_business_to_chain_v1'e branch_count plan limiti eklendi"
```

---

### Task 6: Migration — Destek ticket önceliği kademeye göre

**Files:**
- Create: `supabase/migrations/20260822000006_support_ticket_priority.sql`

- [ ] **Step 1: Migration dosyasını yaz**

`p_business_id` NULL olabilir (genel destek talebi, işletmeyle ilgisiz) — bu durumda öncelik varsayılan `medium` kalır.

Create `supabase/migrations/20260822000006_support_ticket_priority.sql`:

```sql
CREATE OR REPLACE FUNCTION public.create_support_ticket_v1(
  p_business_id uuid, p_category text, p_subject text, p_message text
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_ticket_id uuid;
  v_display_name text;
  v_email text;
  v_priority text := 'medium';
  v_tier text;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'unauthorized' USING ERRCODE = 'P0002';
  END IF;

  IF p_business_id IS NOT NULL AND NOT public.is_owner_of_business(p_business_id) THEN
    RAISE EXCEPTION 'unauthorized: bu işletme için yetkiniz yok' USING ERRCODE = 'P0002';
  END IF;

  IF trim(coalesce(p_subject, '')) = '' OR trim(coalesce(p_message, '')) = '' THEN
    RAISE EXCEPTION 'validation_error: konu ve mesaj boş olamaz' USING ERRCODE = 'P0003';
  END IF;

  IF p_business_id IS NOT NULL THEN
    v_tier := public._get_business_plan_tier_v1(p_business_id);
    v_priority := CASE v_tier
      WHEN 'pro' THEN 'urgent'
      WHEN 'standard' THEN 'high'
      ELSE 'medium'
    END;
  END IF;

  SELECT display_name INTO v_display_name FROM public.user_profiles WHERE user_id = auth.uid();
  SELECT email INTO v_email FROM auth.users WHERE id = auth.uid();

  INSERT INTO public.support_tickets (user_id, business_id, requester_name, requester_email, subject, category, priority)
  VALUES (auth.uid(), p_business_id, v_display_name, v_email, trim(p_subject), p_category, v_priority)
  RETURNING id INTO v_ticket_id;

  INSERT INTO public.support_ticket_messages (ticket_id, sender, message, created_by)
  VALUES (v_ticket_id, 'user', trim(p_message), auth.uid());

  RETURN v_ticket_id;
END;
$$;

COMMENT ON FUNCTION public.create_support_ticket_v1 IS
  'Destek talebi oluşturur. İşletme bazlı taleplerde priority, işletmenin plan kademesine göre otomatik atanır (pro=urgent, standard=high, free/starter=medium). Kullanıcı girdisi değil.';
```

- [ ] **Step 2: Uygula ve doğrula**

Run:
```bash
psql "$SUPABASE_DB_URL" -f supabase/migrations/20260822000006_support_ticket_priority.sql
```

Doğrulama:
```bash
psql "$SUPABASE_DB_URL" -c "
select public.create_support_ticket_v1('<pro_business_id>'::uuid, 'other', 'Test', 'Test mesaj');
select priority from public.support_tickets order by created_at desc limit 1;
"
```
Expected: `priority = 'urgent'`

- [ ] **Step 3: Commit**

```bash
git add supabase/migrations/20260822000006_support_ticket_priority.sql
git commit -m "feat(db): create_support_ticket_v1'de plan kademesine göre otomatik ticket önceliği"
```

---

### Task 7: Web — Paylaşılan plan etiketleri modülü

**Files:**
- Create: `uygulamalar/web/src/lib/plan/plan-sabitleri.ts`
- Test: `uygulamalar/web/test/lib/plan-sabitleri.test.ts`

- [ ] **Step 1: Başarısız testi yaz**

Create `uygulamalar/web/test/lib/plan-sabitleri.test.ts`:

```typescript
import { describe, expect, it } from 'vitest';
import { FEATURE_LABELS, TIER_LABELS, PLAN_FEATURE_KEYS } from '@/src/lib/plan/plan-sabitleri';

describe('plan-sabitleri', () => {
  it('her bilinen feature_key için bir Türkçe etiket tanımlar', () => {
    for (const key of PLAN_FEATURE_KEYS) {
      expect(FEATURE_LABELS[key], `FEATURE_LABELS eksik: ${key}`).toBeTruthy();
      expect(FEATURE_LABELS[key]).not.toBe(key);
    }
  });

  it('4 kademe için etiket tanımlar', () => {
    expect(Object.keys(TIER_LABELS).sort()).toEqual(['free', 'pro', 'standard', 'starter']);
  });

  it('sadakat_programi etiketi tanımlı (regresyon: önceden eksikti)', () => {
    expect(FEATURE_LABELS.sadakat_programi).toBe('Sadakat programı');
  });
});
```

- [ ] **Step 2: Testi çalıştır, başarısız olduğunu doğrula**

Run: `cd uygulamalar/web && pnpm vitest run test/lib/plan-sabitleri.test.ts`
Expected: FAIL — `Cannot find module '@/src/lib/plan/plan-sabitleri'`

- [ ] **Step 3: Modülü yaz**

Create `uygulamalar/web/src/lib/plan/plan-sabitleri.ts`:

```typescript
export const PLAN_FEATURE_KEYS = [
  'menu_item_count',
  'ocr_scans_per_month',
  'allergen_ai',
  'language_count',
  'ai_image_gen',
  'qr_watermark',
  'map_boost',
  'sadakat_programi',
  'team_seat_count',
  'campaign_count_per_month',
  'branch_count',
  'analytics_range_days',
] as const;

export type PlanFeatureKey = (typeof PLAN_FEATURE_KEYS)[number];

export const FEATURE_LABELS: Record<PlanFeatureKey, string> = {
  menu_item_count: 'Ürün sayısı',
  ocr_scans_per_month: 'OCR taraması (bu ay)',
  allergen_ai: 'AI alerjen/kalori otomasyonu',
  language_count: 'Dil sayısı',
  ai_image_gen: 'AI görsel üretme',
  qr_watermark: 'QR filigranı',
  map_boost: 'Harita önceliklendirme',
  sadakat_programi: 'Sadakat programı',
  team_seat_count: 'Ekip üyesi',
  campaign_count_per_month: 'CRM kampanyası (bu ay)',
  branch_count: 'Şube sayısı',
  analytics_range_days: 'Analitik aralığı',
};

export const TIER_LABELS: Record<'free' | 'starter' | 'standard' | 'pro', string> = {
  free: 'Ücretsiz',
  starter: 'Başlangıç',
  standard: 'Standart',
  pro: 'Pro (İşletme)',
};

/** Plan sayfasında "{used}/{limit}" yerine düz metin gösterilmesi gereken özellikler
 * (aylık sayaç ya da işgal edilen kaynak değil, bir tavan değeri). */
export const PLAN_CEILING_FEATURE_KEYS: readonly PlanFeatureKey[] = ['analytics_range_days'];
```

- [ ] **Step 4: Testi çalıştır, geçtiğini doğrula**

Run: `cd uygulamalar/web && pnpm vitest run test/lib/plan-sabitleri.test.ts`
Expected: PASS (3/3)

- [ ] **Step 5: Commit**

```bash
git add uygulamalar/web/src/lib/plan/plan-sabitleri.ts uygulamalar/web/test/lib/plan-sabitleri.test.ts
git commit -m "feat(web): paylaşılan plan etiketleri modülü — FEATURE_LABELS/TIER_LABELS tekilleştirildi"
```

---

### Task 8: Web — `ayarlar/plan` sayfasını paylaşılan modüle taşı + tavan-değer gösterimi

**Files:**
- Modify: `uygulamalar/web/app/sahip/ayarlar/plan/page.tsx`
- Modify: `uygulamalar/web/app/sahip/ayarlar/plan/plan-ozet-istemcisi.tsx`

- [ ] **Step 1: `page.tsx`'teki yerel `FEATURE_LABELS`/`TIER_LABELS`'ı sil, paylaşılan modülden import et**

Modify `uygulamalar/web/app/sahip/ayarlar/plan/page.tsx` — dosyanın başındaki yerel sabitleri sil:

```typescript
// SİL:
const FEATURE_LABELS: Record<string, string> = {
  menu_item_count: 'Ürün sayısı',
  ocr_scans_per_month: 'OCR taraması (bu ay)',
  allergen_ai: 'AI alerjen/kalori otomasyonu',
  language_count: 'Dil sayısı',
  ai_image_gen: 'AI görsel üretme',
  qr_watermark: 'QR filigranı',
  map_boost: 'Harita önceliklendirme',
};

const TIER_LABELS: Record<string, string> = {
  free: 'Ücretsiz',
  starter: 'Başlangıç',
  standard: 'Standart',
  pro: 'Pro (İşletme)',
};
```

Import satırlarına ekle:

```typescript
import { FEATURE_LABELS, TIER_LABELS } from '@/src/lib/plan/plan-sabitleri';
```

- [ ] **Step 2: `plan-ozet-istemcisi.tsx`'e tavan-değer (ceiling) gösterimi ekle**

Modify `uygulamalar/web/app/sahip/ayarlar/plan/plan-ozet-istemcisi.tsx`:

```typescript
'use client';

import Link from 'next/link';
import { PLAN_CEILING_FEATURE_KEYS } from '@/src/lib/plan/plan-sabitleri';

type FeatureRow = {
  feature_key: string;
  label: string;
  enabled: boolean;
  limit_value: number | null;
  used: number;
};

export function PlanOzetIstemcisi({
  planTier,
  planLabel,
  features,
}: {
  planTier: string;
  planLabel: string;
  features: FeatureRow[];
}) {
  return (
    <div className="mx-auto max-w-2xl space-y-6">
      <div className="rounded-2xl border border-border bg-card p-5">
        <p className="text-xs font-bold uppercase tracking-wide text-muted">Kademeniz</p>
        <p className="mt-1 text-2xl font-black text-textStrong" data-plan-tier={planTier}>
          {planLabel}
        </p>
      </div>

      <div className="divide-y divide-border rounded-2xl border border-border bg-card">
        {features.map((feature) => {
          const isCeiling = (PLAN_CEILING_FEATURE_KEYS as readonly string[]).includes(feature.feature_key);
          return (
            <div key={feature.feature_key} className="flex items-center justify-between gap-4 px-5 py-3">
              <span className="text-sm font-semibold text-textStrong">{feature.label}</span>
              {!feature.enabled ? (
                <span className="rounded-full bg-zinc-100 px-2.5 py-1 text-xs font-bold text-zinc-500">
                  Kilitli
                </span>
              ) : feature.limit_value === null ? (
                <span className="rounded-full bg-emerald-50 px-2.5 py-1 text-xs font-bold text-emerald-700">
                  Sınırsız
                </span>
              ) : isCeiling ? (
                <span className="rounded-full border border-border bg-bg px-2.5 py-1 text-xs font-bold text-textStrong">
                  Son {feature.limit_value} gün
                </span>
              ) : (
                <span className="rounded-full border border-border bg-bg px-2.5 py-1 text-xs font-bold text-textStrong">
                  {feature.used} / {feature.limit_value}
                </span>
              )}
            </div>
          );
        })}
      </div>

      <Link
        href="/sahip/premium"
        className="flex min-h-10 items-center justify-center rounded-xl bg-(--yd-color-primary) px-4 text-sm font-extrabold text-white transition-opacity hover:opacity-90"
      >
        Planları Karşılaştır
      </Link>
    </div>
  );
}
```

- [ ] **Step 3: Typecheck**

Run: `cd uygulamalar/web && pnpm run typecheck`
Expected: Hata yok.

- [ ] **Step 4: Manuel doğrulama**

Run: `cd uygulamalar/web && pnpm run dev`, tarayıcıda `/sahip/ayarlar/plan`'a git.
Expected: "Sadakat programı" satırı artık ham anahtar değil Türkçe etiketle görünüyor; "Analitik aralığı" satırı "Son N gün" olarak görünüyor (0/N değil).

- [ ] **Step 5: Commit**

```bash
git add uygulamalar/web/app/sahip/ayarlar/plan/page.tsx uygulamalar/web/app/sahip/ayarlar/plan/plan-ozet-istemcisi.tsx
git commit -m "fix(web): plan sayfası paylaşılan etiket modülünü kullanıyor, tavan-değer özellikleri düz metinle gösteriliyor"
```

---

### Task 9: Web — `/sahip/premium` fiyat karşılaştırma tablosuna yeni özellikler

**Files:**
- Modify: `uygulamalar/web/app/sahip/premium/premium-veri.ts`

- [ ] **Step 1: `PLAN_OZELLIKLERI`'ne 4 yeni satır ekle, etiketleri paylaşılan modülden al**

Modify `uygulamalar/web/app/sahip/premium/premium-veri.ts`:

```typescript
import { FEATURE_LABELS } from '@/src/lib/plan/plan-sabitleri';

export type PlanTierId = 'free' | 'starter' | 'standard' | 'pro';

export interface PlanTanimi {
  id: PlanTierId;
  label: string;
  monthlyPrice: number;
  yearlyPrice: number;
  tagline: string;
  highlight?: boolean;
}

export const PLAN_TANIMLARI: PlanTanimi[] = [
  { id: 'free', label: 'Ücretsiz', monthlyPrice: 0, yearlyPrice: 0, tagline: 'Başlamak için' },
  { id: 'starter', label: 'Başlangıç', monthlyPrice: 99, yearlyPrice: 950, tagline: 'QR menüye tam geçiş' },
  { id: 'standard', label: 'Standart', monthlyPrice: 349, yearlyPrice: 3350, tagline: 'Büyüyen işletmeler için', highlight: true },
  { id: 'pro', label: 'Pro', monthlyPrice: 699, yearlyPrice: 6710, tagline: 'Çok şubeli / ileri düzey' },
];

export interface PlanOzellik {
  key: string;
  label: string;
  values: Record<PlanTierId, string>;
}

export const PLAN_OZELLIKLERI: PlanOzellik[] = [
  {
    key: 'menu_item_count',
    label: FEATURE_LABELS.menu_item_count,
    values: { free: '30 ürün', starter: 'Sınırsız', standard: 'Sınırsız', pro: 'Sınırsız' },
  },
  {
    key: 'ocr_scans_per_month',
    label: FEATURE_LABELS.ocr_scans_per_month,
    values: { free: 'Ayda 1', starter: 'Ayda 5', standard: 'Sınırsız', pro: 'Sınırsız' },
  },
  {
    key: 'allergen_ai',
    label: FEATURE_LABELS.allergen_ai,
    values: { free: '—', starter: '—', standard: 'Var', pro: 'Var' },
  },
  {
    key: 'language_count',
    label: FEATURE_LABELS.language_count,
    values: { free: '1 dil', starter: '1 dil', standard: '2 dil', pro: 'Sınırsız' },
  },
  {
    key: 'ai_image_gen',
    label: FEATURE_LABELS.ai_image_gen,
    values: { free: '—', starter: '—', standard: '—', pro: 'Var' },
  },
  {
    key: 'qr_watermark',
    label: 'QR kodda Yeedoy filigranı',
    values: { free: 'Var', starter: 'Yok', standard: 'Yok', pro: 'Yok' },
  },
  {
    key: 'map_boost',
    label: FEATURE_LABELS.map_boost,
    values: { free: '—', starter: '—', standard: 'Var', pro: 'Var' },
  },
  {
    key: 'sadakat_programi',
    label: FEATURE_LABELS.sadakat_programi,
    values: { free: '—', starter: '—', standard: 'Var', pro: 'Var' },
  },
  {
    key: 'team_seat_count',
    label: FEATURE_LABELS.team_seat_count,
    values: { free: '1 (sadece sahip)', starter: '3', standard: '10', pro: 'Sınırsız' },
  },
  {
    key: 'campaign_count_per_month',
    label: FEATURE_LABELS.campaign_count_per_month,
    values: { free: '—', starter: 'Ayda 1', standard: 'Ayda 5', pro: 'Sınırsız' },
  },
  {
    key: 'branch_count',
    label: FEATURE_LABELS.branch_count,
    values: { free: '1 (çoklu şube kapalı)', starter: '1 (kapalı)', standard: '3 şube', pro: 'Sınırsız' },
  },
  {
    key: 'analytics_range_days',
    label: FEATURE_LABELS.analytics_range_days,
    values: { free: 'Son 7 gün', starter: 'Son 30 gün', standard: 'Son 90 gün', pro: 'Son 90 gün' },
  },
];
```

- [ ] **Step 2: Typecheck + manuel doğrulama**

Run: `cd uygulamalar/web && pnpm run typecheck && pnpm run dev`, tarayıcıda `/sahip/premium`'a git.
Expected: 12 satırlık tam özellik karşılaştırma tablosu görünüyor.

- [ ] **Step 3: Commit**

```bash
git add uygulamalar/web/app/sahip/premium/premium-veri.ts
git commit -m "feat(web): /sahip/premium fiyat tablosuna ekip/CRM/çoklu-şube/analitik satırları eklendi"
```

---

### Task 10: Web — `baslangic` sayfasına plan durumu + sadakat önerisi kilit kontrolü

**Files:**
- Modify: `uygulamalar/web/app/sahip/baslangic/page.tsx`

- [ ] **Step 1: Plan verisini çek**

`OwnerOnboardingPage` fonksiyonunda, `businessIds` alındıktan sonra (satır ~27), `Promise.all` bloğuna (satır ~56 civarı, mevcut sorgularla birlikte) ekle:

```typescript
const { data: planData } = hasBusiness
  ? ((await (supabase as any).rpc('get_my_plan_v1', { p_business_id: businessIds[0] })) as {
      data: { plan_tier: string; features: Array<{ feature_key: string; enabled: boolean }> } | null;
    })
  : { data: null };

const sadakatAcik = planData?.features.some((f) => f.feature_key === 'sadakat_programi' && f.enabled) ?? false;
```

- [ ] **Step 2: `OneriKarti`'ye `locked` prop'u ekle**

Modify `uygulamalar/web/app/sahip/baslangic/page.tsx` — `OneriKarti` fonksiyonunu güncelle:

```typescript
function OneriKarti({
  title,
  description,
  href,
  label,
  locked,
  lockedLabel,
}: {
  title: string;
  description: string;
  href: string;
  label: string;
  locked?: boolean;
  lockedLabel?: string;
}) {
  return (
    <div className="rounded-xl border border-border p-3">
      <p className="text-xs font-extrabold text-textStrong">{title}</p>
      <p className="mt-0.5 text-[11px] text-muted">{description}</p>
      {locked ? (
        <Link href="/sahip/premium" className="mt-2 inline-block text-xs font-extrabold text-muted hover:underline">
          🔒 {lockedLabel ?? 'Yükselt'} →
        </Link>
      ) : (
        <Link href={href} className="mt-2 inline-block text-xs font-extrabold text-primary hover:underline">
          {label} →
        </Link>
      )}
    </div>
  );
}
```

- [ ] **Step 3: Sadakat kartını koşullu yap**

Modify `uygulamalar/web/app/sahip/baslangic/page.tsx` — "Sıradaki Öneriler" bloğundaki sadakat kartını değiştir:

```typescript
<OneriKarti
  title="Sadakat programı oluştur"
  description="Düzenli müşterilerini ödüllendir ve sadakati artır."
  href="/sahip/pazarlama/sadakat"
  label="Oluştur"
  locked={!sadakatAcik}
  lockedLabel="Standart+ planda"
/>
```

- [ ] **Step 4: Typecheck + manuel doğrulama**

Run: `cd uygulamalar/web && pnpm run typecheck && pnpm run dev`
Expected: Free/başlangıç kademesindeki bir işletmede sadakat kartı "🔒 Standart+ planda →" gösteriyor ve tıklanınca `/sahip/premium`'a gidiyor; standart/pro'da normal "Oluştur →" davranışı korunuyor.

- [ ] **Step 5: Commit**

```bash
git add uygulamalar/web/app/sahip/baslangic/page.tsx
git commit -m "fix(web): baslangic sayfasındaki sadakat önerisi artık plan kilidini kontrol ediyor"
```

---

### Task 11: Web — `gosterge-panosu`'na kompakt plan özeti

**Files:**
- Modify: `uygulamalar/web/app/sahip/gosterge-panosu/page.tsx`

- [ ] **Step 1: `get_my_plan_v1` sonucunun tamamını sakla (yalnızca tier değil)**

Modify `uygulamalar/web/app/sahip/gosterge-panosu/page.tsx` — plan sorgusunun bulunduğu `Promise.all` girdisini değiştir:

```typescript
// ÖNCE:
Promise.all(
  selectedIds.map((id) =>
    (supabase as any)
      .rpc('get_my_plan_v1', { p_business_id: id })
      .then((r: { data: { plan_tier?: string } | null }) => [id, r?.data?.plan_tier] as const)
      .catch(() => [id, undefined] as const),
  ),
),

// SONRA:
Promise.all(
  selectedIds.map((id) =>
    (supabase as any)
      .rpc('get_my_plan_v1', { p_business_id: id })
      .then((r: { data: PlanOzetVerisi | null }) => [id, r?.data ?? undefined] as const)
      .catch(() => [id, undefined] as const),
  ),
),
```

Dosyanın üstüne (import bloğunun altına) tip ekle:

```typescript
type PlanOzetVerisi = {
  plan_tier: string;
  features: Array<{ feature_key: string; enabled: boolean; limit_value: number | null; used: number }>;
};
```

`planTierByBiz` değişkenini `planByBiz` olarak yeniden adlandır (Map türü `Map<string, PlanOzetVerisi>`) ve doldurma döngüsünü güncelle:

```typescript
// ÖNCE:
for (const [id, tier] of (planResults as Array<readonly [string, string | undefined]>)) {
  if (tier) planTierByBiz.set(id, tier);
}

// SONRA:
for (const [id, plan] of (planResults as Array<readonly [string, PlanOzetVerisi | undefined]>)) {
  if (plan) planByBiz.set(id, plan);
}
```

Map tanımının olduğu satırı (`const planTierByBiz = new Map<string, string>();`) buna göre güncelle: `const planByBiz = new Map<string, PlanOzetVerisi>();`

- [ ] **Step 2: Render bölümünü güncelle**

Kart render döngüsünde (`const planTier = planTierByBiz.get(b.id);` satırı) değiştir:

```typescript
// ÖNCE:
const planTier = planTierByBiz.get(b.id);

// SONRA:
const plan = planByBiz.get(b.id);
```

Ve banner render satırını değiştir:

```typescript
// ÖNCE:
{planTier === 'free' && <PremiumBanner />}

// SONRA:
<PlanKompaktRozet plan={plan} />
```

- [ ] **Step 3: `PremiumBanner`'ı `PlanKompaktRozet` ile değiştir**

Modify `uygulamalar/web/app/sahip/gosterge-panosu/page.tsx` — `function PremiumBanner()` fonksiyonunu bul ve değiştir:

```typescript
function PlanKompaktRozet({ plan }: { plan: { plan_tier: string; features: Array<{ feature_key: string; enabled: boolean; limit_value: number | null; used: number }> } | undefined }) {
  if (!plan) return null;

  if (plan.plan_tier === 'free') {
    return (
      <div className="mt-3 flex items-center justify-between gap-3 rounded-xl border border-amber-200 bg-amber-50 px-4 py-3">
        <p className="text-xs font-bold text-amber-800">
          Ücretsiz plandasınız — daha fazla özellik için yükseltin.
        </p>
        <Link href="/sahip/premium" className="shrink-0 text-xs font-extrabold text-amber-800 underline">
          Planları Gör
        </Link>
      </div>
    );
  }

  const kritikOzellik = plan.features.find(
    (f) => f.enabled && f.limit_value !== null && f.used >= f.limit_value * 0.8,
  );

  if (!kritikOzellik) return null;

  return (
    <div className="mt-3 flex items-center justify-between gap-3 rounded-xl border border-border bg-cardAlt px-4 py-3">
      <p className="text-xs font-bold text-textStrong">
        {FEATURE_LABELS[kritikOzellik.feature_key] ?? kritikOzellik.feature_key}: {kritikOzellik.used}/{kritikOzellik.limit_value} kullanıldı
      </p>
      <Link href="/sahip/ayarlar/plan" className="shrink-0 text-xs font-extrabold text-primary underline">
        Detay
      </Link>
    </div>
  );
}
```

Dosyanın import bloğuna ekle: `import { FEATURE_LABELS } from '@/src/lib/plan/plan-sabitleri';`

- [ ] **Step 4: Typecheck + manuel doğrulama**

Run: `cd uygulamalar/web && pnpm run typecheck && pnpm run dev`
Expected: Free kademede sarı "Ücretsiz plandasınız" şeridi görünüyor; limiti %80+ dolu bir ücretli kademede "X/Y kullanıldı" şeridi görünüyor; her ikisi de değilse hiçbir şerit yok (regresyon değil, önceden de free-olmayan+doluluk-yok durumda hiçbir şey göstermiyordu).

- [ ] **Step 5: Commit**

```bash
git add uygulamalar/web/app/sahip/gosterge-panosu/page.tsx
git commit -m "feat(web): gosterge-panosu artık tüm kademelerde kompakt plan/kullanım özeti gösteriyor"
```

---

### Task 12: Web — Analitik sayfasında kademe bazlı aralık kısıtı

**Files:**
- Modify: `uygulamalar/web/app/sahip/analitik/tarih-araligi-secici.tsx`
- Modify: `uygulamalar/web/app/sahip/analitik/page.tsx`

- [ ] **Step 1: `AralikSecenegi` tipine `locked` alanı ekle, kilitli seçenek kilitli görünsün**

Modify `uygulamalar/web/app/sahip/analitik/tarih-araligi-secici.tsx`:

```typescript
export interface AralikSecenegi {
  aralik: Aralik;
  etiket: string;
  tarihAraligi: string;
  locked?: boolean;
}
```

Seçenek render bloğunu değiştir:

```typescript
{secenekler.map((s) =>
  s.locked ? (
    <div
      key={s.aralik}
      className="flex cursor-not-allowed flex-col gap-0.5 px-4 py-2.5 text-left opacity-50"
      title="Bu aralık kademenizde kilitli"
    >
      <span className="flex items-center gap-1.5 text-sm font-bold text-textStrong">
        🔒 {s.etiket}
      </span>
      <span className="text-[11px] text-muted">Yükseltmeniz gerekiyor</span>
    </div>
  ) : (
    <Link
      key={s.aralik}
      href={`/sahip/analitik?aralik=${s.aralik}`}
      onClick={() => setOpen(false)}
      className={clsx(
        'flex flex-col gap-0.5 px-4 py-2.5 text-left transition-colors hover:bg-cardAlt',
        s.aralik === aktif && 'bg-primary/5',
      )}
    >
      <span className="text-sm font-bold text-textStrong">{s.etiket}</span>
      <span className="text-[11px] text-muted">{s.tarihAraligi}</span>
    </Link>
  ),
)}
```

- [ ] **Step 2: `page.tsx`'te plan limitini oku, `gunSayisi`'yi kaynağında clamp'le**

Dosyanın gerçek yapısı (satır numaraları teyit edildi): `gunSayisi` satır 71'de `const gunSayisi = aralikGun[aralik];` olarak tanımlanıyor; `businessIds` satır 80'de hesaplanıyor; satır 82-95 arası `businessIds.length === 0` için erken `return`; `gunSayisi` ilk kez satır 98'de (`since` hesabı) kullanılıyor. Plan verisi `businessIds` gerektirdiği için, clamp işlemi erken-return bloğundan SONRA, `since`/`sincePrev` hesabından ÖNCE yapılıyor — bu sayede satır 98, 99, 197, 219, 220, 222, 285, 319'daki mevcut `gunSayisi` kullanımlarının HİÇBİRİNE dokunmaya gerek kalmıyor (hepsi otomatik olarak clamp'lenmiş değeri kullanır).

Modify `uygulamalar/web/app/sahip/analitik/page.tsx` satır 71'i değiştir:

```typescript
// ÖNCE (satır 71):
const gunSayisi = aralikGun[aralik];

// SONRA:
const gunSayisiIstenen = aralikGun[aralik];
```

Satır 95'teki erken-return bloğunun kapanışından (`}`) hemen sonra, satır 97'deki `const now = Date.now();`'dan hemen önce ekle:

```typescript
const { data: planData } = (await (supabase as any).rpc('get_my_plan_v1', {
  p_business_id: businessIds[0],
})) as { data: { features: Array<{ feature_key: string; limit_value: number | null }> } | null };

const analitikLimit =
  planData?.features.find((f) => f.feature_key === 'analytics_range_days')?.limit_value ?? 90;

// Kullanıcı URL'den ?aralik=90g gönderse bile (UI bypass), aşağıdaki tüm hesaplamalar
// (since/sincePrev/simdiMs/goruntulenmeGunluk/vb.) bu clamp'lenmiş değeri kullanır.
const gunSayisi = Math.min(gunSayisiIstenen, analitikLimit);
```

`aralikSecenekleri` tanımını (satır 299-303) güncelle:

```typescript
const aralikSecenekleri: AralikSecenegi[] = [
  { aralik: '7g', etiket: 'Son 7 Gün', tarihAraligi: formatTarihAraligi(7), locked: analitikLimit < 7 },
  { aralik: '30g', etiket: 'Son 30 Gün', tarihAraligi: formatTarihAraligi(30), locked: analitikLimit < 30 },
  { aralik: '90g', etiket: 'Son 90 Gün', tarihAraligi: formatTarihAraligi(90), locked: analitikLimit < 90 },
];
```

- [ ] **Step 3: Typecheck**

Run: `cd uygulamalar/web && pnpm run typecheck`
Expected: Hata yok.

- [ ] **Step 4: Manuel doğrulama**

Run: `pnpm run dev`, free kademedeki bir işletmeyle `/sahip/analitik?aralik=90g`'ye git.
Expected: Sayfa 90 günlük değil 7 günlük veri gösteriyor (URL manipülasyonu bypass edilemiyor); aralık seçicide 30g/90g kilitli (🔒) görünüyor.

- [ ] **Step 5: Commit**

```bash
git add uygulamalar/web/app/sahip/analitik/page.tsx uygulamalar/web/app/sahip/analitik/tarih-araligi-secici.tsx
git commit -m "feat(web): analitik sayfasında aralık seçimi plan kademesine göre kısıtlanıyor (UI + sunucu-taraflı clamp)"
```

---

### Task 13: Doğrulama — tam test paketi

**Files:** (yok — yalnızca doğrulama)

- [ ] **Step 1: Web tam kontrol**

Run:
```bash
cd uygulamalar/web
pnpm run typecheck
pnpm run lint
pnpm run test:unit
```
Expected: Üçü de hatasız/başarısız test olmadan biter.

- [ ] **Step 2: Supabase advisors kontrolü**

Yeni/değişen 6 fonksiyon için beklenmeyen güvenlik bulgusu var mı kontrol et (MCP `get_advisors(type=security)` ya da eşdeğer `supabase inspect` komutu).
Expected: Yeni bulgu yok (fonksiyonlar zaten `SECURITY DEFINER` + `SET search_path` desenini koruyor).

- [ ] **Step 3: Uçtan uca manuel senaryo listesi**

- Free işletmede ekip daveti → engellenir (`plan_limit_exceeded`).
- Free işletmede kampanya oluşturma → engellenir.
- Free/başlangıç işletmede 2. şube ekleme → engellenir.
- Free işletmede destek talebi → `priority='medium'`; pro işletmede → `priority='urgent'`.
- Free işletmede analitik `?aralik=90g` → sunucu 7 güne clamp'liyor.
- `/sahip/baslangic`, `/sahip/gosterge-panosu`, `/sahip/ayarlar/plan`, `/sahip/premium` dört sayfada da plan/kademe bilgisi tutarlı ve `sadakat_programi` doğru Türkçe etiketle görünüyor.

- [ ] **Step 4: Final commit**

```bash
git add -A
git commit -m "chore: premium plan genişletmesi doğrulama turu tamamlandı" --allow-empty
```

---

## Self-Review Notu

Spec'teki her madde bir task'a karşılık geliyor: veri modeli → Task 1, RPC katmanı → Task 2-6, etiket tekilleştirme → Task 7-9, UI entegrasyonu → Task 10-12, test planı → Task 13. Task 12, `analitik/page.tsx`'in gerçek satır numaraları (71, 80, 95, 98-99, 197, 219-222, 285, 299-303, 319) teyit edildikten sonra placeholder'sız, tam kodla yazıldı — `gunSayisi` kaynağında clamp'lendiği için downstream 8 kullanım noktasının hiçbirine dokunmaya gerek kalmadı.
