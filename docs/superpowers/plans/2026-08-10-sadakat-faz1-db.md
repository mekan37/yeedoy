# Sadakat v1 — Faz 1: DB Şeması + RPC Yüzeyi Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** `docs/superpowers/specs/2026-08-10-sadakat-design.md`'de onaylanan birleşik sadakat şemasını (damga+puan, tek RPC yüzeyi, audit log) DB'ye kurmak — eski iki çakışan tasarımı (+ P4 otomasyon eklentisini) tamamen kaldırıp yerine yeni tabloları/RPC'leri/tetikleyicileri/premium-gating'i getirmek. Bu faz sadece DB; web/mobil UI sonraki fazlarda.

**Architecture:** 5 küçük, sıralı migration dosyası: (1) eski nesneleri DROP, (2) yeni tablolar+RLS, (3) owner RPC'leri, (4) müşteri RPC'si + yorum tetikleyicisi, (5) premium plan gating seed. Her dosya kendi başına `supabase db reset` ile doğrulanabilir. Son task, kullanıcının açık talebiyle production'a push eder.

**Tech Stack:** Supabase/Postgres (plpgsql + sql), mevcut `_check_plan_limit_v1`/`is_owner_of_business` altyapısı.

---

### Task 1: Eski loyalty/sadakat DB nesnelerini kaldır

**Files:**
- Create: `supabase/migrations/20260810000001_drop_old_loyalty_designs.sql`

- [ ] **Step 1: Migration dosyasını oluştur**

```sql
-- Sadakat/Loyalty ölü kod temizliği — iki çakışan eski tasarım + P4 otomasyon
-- eklentisi kaldırılıyor, yerine docs/superpowers/specs/2026-08-10-sadakat-design.md
-- tasarımı gelecek (bu migration'ı takip eden 4 migration'da).
--   20260424000007_loyalty_program.sql      (puan-bazlı tasarım)
--   20260424000010_loyalty_automations.sql  (P4 otomasyon: doğum günü/eşik/missed_you)
--   20260507000008_sadakat_karti.sql        (damga-kartı tasarımı, çakışan 2. tasarım)
-- run_loyalty_automations_v1 cron'u zaten 20260723000003_unschedule_dead_cron_jobs.sql
-- içinde unschedule edilmişti; bu migration fonksiyonun kendisini de kaldırır.

DROP TRIGGER IF EXISTS trg_loyalty_review ON public.reviews;
DROP TRIGGER IF EXISTS trg_loyalty_checkin ON public.business_checkins;

DROP FUNCTION IF EXISTS public.trg_award_loyalty_on_review();
DROP FUNCTION IF EXISTS public.trg_award_loyalty_on_checkin();
DROP FUNCTION IF EXISTS public.award_loyalty_points_v1(uuid, uuid, int);
DROP FUNCTION IF EXISTS public.get_loyalty_status_v1(uuid);
DROP FUNCTION IF EXISTS public.get_my_loyalty_cards_v1();
DROP FUNCTION IF EXISTS public.upsert_loyalty_program_v1(uuid, boolean, int, int, int, int, text, int);
DROP FUNCTION IF EXISTS public.get_business_loyal_customers_v1(uuid, int);
DROP FUNCTION IF EXISTS public.create_loyalty_program_v1(uuid, text, int, text);
DROP FUNCTION IF EXISTS public.add_loyalty_stamp_v1(uuid, uuid);
DROP FUNCTION IF EXISTS public.get_business_automations_v1(uuid);
DROP FUNCTION IF EXISTS public.upsert_business_automation_v1(uuid, text, boolean, text);
DROP FUNCTION IF EXISTS public.run_loyalty_automations_v1();

DROP TABLE IF EXISTS public.loyalty_cards;
DROP TABLE IF EXISTS public.loyalty_accounts;
DROP TABLE IF EXISTS public.loyalty_programs;
DROP TABLE IF EXISTS public.business_automations;
```

- [ ] **Step 2: Commit**

```bash
git add supabase/migrations/20260810000001_drop_old_loyalty_designs.sql
git commit -m "fix(db): sadakat/loyalty ölü DB nesnelerini kaldır (2 çakışan tasarım + P4 otomasyon)"
```

---

### Task 2: Yeni şema — tablolar + RLS

**Files:**
- Create: `supabase/migrations/20260810000002_sadakat_v1_schema.sql`

- [ ] **Step 1: Migration dosyasını oluştur**

```sql
-- Sadakat v1 — birleşik şema (damga+puan, tek RPC/UI yüzeyi).
-- bkz. docs/superpowers/specs/2026-08-10-sadakat-design.md

CREATE TABLE public.loyalty_programs (
  id               uuid primary key default gen_random_uuid(),
  business_id      uuid references public.businesses(id) on delete cascade,
  chain_id         uuid references public.chains(id) on delete cascade,
  mode             text not null check (mode in ('stamp','points')),
  name             text not null,
  reward_desc      text not null,
  reward_threshold int not null check (reward_threshold > 0),
  is_active        boolean not null default false,
  created_at       timestamptz not null default now(),
  constraint loyalty_programs_scope_check check (
    (business_id is not null and chain_id is null) or
    (business_id is null and chain_id is not null)
  )
);

CREATE UNIQUE INDEX idx_loyalty_programs_business ON public.loyalty_programs(business_id) WHERE business_id IS NOT NULL;
CREATE UNIQUE INDEX idx_loyalty_programs_chain ON public.loyalty_programs(chain_id) WHERE chain_id IS NOT NULL;

CREATE TABLE public.loyalty_members (
  id             uuid primary key default gen_random_uuid(),
  program_id     uuid not null references public.loyalty_programs(id) on delete cascade,
  user_id        uuid not null references auth.users(id) on delete cascade,
  progress       int not null default 0,
  redeemed_count int not null default 0,
  updated_at     timestamptz not null default now(),
  unique (program_id, user_id)
);

CREATE INDEX idx_loyalty_members_user ON public.loyalty_members(user_id);

CREATE TABLE public.loyalty_events (
  id         uuid primary key default gen_random_uuid(),
  member_id  uuid not null references public.loyalty_members(id) on delete cascade,
  source     text not null check (source in ('qr_scan','review','redeem')),
  amount     int not null,
  actor_id   uuid references auth.users(id),
  created_at timestamptz not null default now()
);

CREATE INDEX idx_loyalty_events_member ON public.loyalty_events(member_id);

ALTER TABLE public.loyalty_programs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.loyalty_members  ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.loyalty_events   ENABLE ROW LEVEL SECURITY;

-- Herkes okuyabilir (public read, mevcut desen); yazma yalnızca RPC üzerinden.
CREATE POLICY "loyalty_programs_public_read" ON public.loyalty_programs
  FOR SELECT USING (true);

-- Müşteri sadece kendi satırını görür; yazma yalnızca RPC üzerinden.
CREATE POLICY "loyalty_members_self_read" ON public.loyalty_members
  FOR SELECT USING (auth.uid() = user_id);

-- loyalty_events: hiçbir client rolüne GRANT yok — audit log, sadece SECURITY
-- DEFINER RPC'ler (get_business_loyalty_members_v1 vb.) içinden okunur/yazılır.

REVOKE ALL ON public.loyalty_programs FROM anon, authenticated;
REVOKE ALL ON public.loyalty_members  FROM anon, authenticated;
REVOKE ALL ON public.loyalty_events   FROM anon, authenticated;
GRANT SELECT ON public.loyalty_programs TO anon, authenticated;
GRANT SELECT ON public.loyalty_members  TO authenticated;

COMMENT ON TABLE public.loyalty_programs IS 'Bir işletmenin (business_id) veya zincirin (chain_id) sadakat programı — mode: stamp|points. Tam biri set olmalı.';
COMMENT ON TABLE public.loyalty_members IS 'Bir müşterinin bir programdaki ilerlemesi (damga sayısı veya puan).';
COMMENT ON TABLE public.loyalty_events IS 'Her ilerleme/kullanım olayının audit kaydı — kaynak: qr_scan|review|redeem.';
```

- [ ] **Step 2: Local doğrulama**

Run: `supabase db reset`
Expected: Tüm migration'lar (Task 1 + bu dosya dahil) hatasız uygulanır.

- [ ] **Step 3: Commit**

```bash
git add supabase/migrations/20260810000002_sadakat_v1_schema.sql
git commit -m "feat(db): sadakat v1 — loyalty_programs/loyalty_members/loyalty_events şeması + RLS"
```

---

### Task 3: Owner RPC'leri

**Files:**
- Create: `supabase/migrations/20260810000003_sadakat_v1_owner_rpcs.sql`

Kurulum/aktivasyon (`create_loyalty_program_v1`, `set_loyalty_program_active_v1`) `_check_plan_limit_v1` üzerinden **literal onaylı owner_claims sahibine** kapalı (para/plan kararı); günlük operasyon (`scan_loyalty_qr_v1`, `redeem_loyalty_reward_v1`, `get_business_loyalty_members_v1`) `is_owner_of_business` üzerinden **owner + delegeli ekip üyelerine** açık (kasadaki personel de tarayabilsin diye — bkz. tasarımdaki "sahip/personel QR okutur").

- [ ] **Step 1: Migration dosyasını oluştur**

```sql
-- Sadakat v1 — owner RPC yüzeyi. bkz. docs/superpowers/specs/2026-08-10-sadakat-design.md

-- ── Yardımcı: verilen business_id için doğru program scope'unu bul ──────────
CREATE OR REPLACE FUNCTION public._resolve_loyalty_program_v1(p_business_id uuid)
RETURNS uuid
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_chain_id   uuid;
  v_program_id uuid;
BEGIN
  SELECT chain_id INTO v_chain_id FROM public.businesses WHERE id = p_business_id;

  IF v_chain_id IS NOT NULL THEN
    SELECT id INTO v_program_id FROM public.loyalty_programs WHERE chain_id = v_chain_id;
  ELSE
    SELECT id INTO v_program_id FROM public.loyalty_programs WHERE business_id = p_business_id;
  END IF;

  RETURN v_program_id;
END;
$$;

REVOKE ALL ON FUNCTION public._resolve_loyalty_program_v1(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public._resolve_loyalty_program_v1(uuid) TO authenticated;
COMMENT ON FUNCTION public._resolve_loyalty_program_v1 IS
  'Internal: verilen business_id için doğru sadakat programını bulur (zincirdeyse chain_id üzerinden, değilse kendi business_id üzerinden). Called by: create_loyalty_program_v1, scan_loyalty_qr_v1, get_business_loyalty_members_v1, get_my_loyalty_cards_v1, _award_loyalty_progress.';

-- ── create_loyalty_program_v1 ────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.create_loyalty_program_v1(
  p_business_id      uuid,
  p_mode             text,
  p_name             text,
  p_reward_desc      text,
  p_reward_threshold int
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_chain_id   uuid;
  v_program_id uuid;
BEGIN
  PERFORM public._check_plan_limit_v1(p_business_id, 'sadakat_programi');

  IF p_mode NOT IN ('stamp','points') THEN
    RAISE EXCEPTION 'validation_error: geçersiz mode' USING ERRCODE = 'P0003';
  END IF;
  IF p_reward_threshold <= 0 THEN
    RAISE EXCEPTION 'validation_error: reward_threshold pozitif olmalı' USING ERRCODE = 'P0003';
  END IF;

  SELECT chain_id INTO v_chain_id FROM public.businesses WHERE id = p_business_id;

  IF v_chain_id IS NOT NULL THEN
    INSERT INTO public.loyalty_programs (chain_id, mode, name, reward_desc, reward_threshold)
    VALUES (v_chain_id, p_mode, trim(p_name), trim(p_reward_desc), p_reward_threshold)
    RETURNING id INTO v_program_id;
  ELSE
    INSERT INTO public.loyalty_programs (business_id, mode, name, reward_desc, reward_threshold)
    VALUES (p_business_id, p_mode, trim(p_name), trim(p_reward_desc), p_reward_threshold)
    RETURNING id INTO v_program_id;
  END IF;

  RETURN v_program_id;
END;
$$;

REVOKE ALL ON FUNCTION public.create_loyalty_program_v1(uuid, text, text, text, int) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.create_loyalty_program_v1(uuid, text, text, text, int) TO authenticated;
COMMENT ON FUNCTION public.create_loyalty_program_v1 IS
  'Owner: sadakat programı oluşturur (is_active=false başlar). Premium plan kontrolü _check_plan_limit_v1 üzerinden. Called by: app/sahip/pazarlama/sadakat (Faz 2).';

-- ── set_loyalty_program_active_v1 ────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.set_loyalty_program_active_v1(
  p_program_id uuid,
  p_is_active  boolean
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_business_id uuid;
  v_chain_id    uuid;
  v_owner_biz   uuid;
BEGIN
  SELECT business_id, chain_id INTO v_business_id, v_chain_id
  FROM public.loyalty_programs WHERE id = p_program_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'not_found: program bulunamadı' USING ERRCODE = 'P0001';
  END IF;

  IF v_business_id IS NOT NULL THEN
    v_owner_biz := v_business_id;
    PERFORM public._check_plan_limit_v1(v_owner_biz, 'sadakat_programi');
  ELSE
    IF NOT EXISTS (
      SELECT 1 FROM public.businesses b
      WHERE b.chain_id = v_chain_id AND public.is_owner_of_business(b.id)
    ) THEN
      RAISE EXCEPTION 'unauthorized' USING ERRCODE = 'P0002';
    END IF;
    v_owner_biz := (
      SELECT id FROM public.businesses
      WHERE chain_id = v_chain_id
      ORDER BY chain_sort_order NULLS LAST, id
      LIMIT 1
    );
    PERFORM public._check_plan_limit_v1(v_owner_biz, 'sadakat_programi');
  END IF;

  UPDATE public.loyalty_programs SET is_active = p_is_active WHERE id = p_program_id;
END;
$$;

REVOKE ALL ON FUNCTION public.set_loyalty_program_active_v1(uuid, boolean) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.set_loyalty_program_active_v1(uuid, boolean) TO authenticated;
COMMENT ON FUNCTION public.set_loyalty_program_active_v1 IS
  'Owner: programı aktif/pasif yapar (eski tasarımda eksik olan adım). Called by: app/sahip/pazarlama/sadakat (Faz 2).';

-- ── scan_loyalty_qr_v1 ────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.scan_loyalty_qr_v1(
  p_business_id uuid,
  p_user_id     uuid
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_program_id uuid;
  v_member_id  uuid;
  v_progress   int;
  v_threshold  int;
  v_last_scan  timestamptz;
BEGIN
  IF NOT public.is_owner_of_business(p_business_id) THEN
    RAISE EXCEPTION 'unauthorized' USING ERRCODE = 'P0002';
  END IF;

  v_program_id := public._resolve_loyalty_program_v1(p_business_id);
  IF v_program_id IS NULL THEN
    RAISE EXCEPTION 'not_found: sadakat programı yok' USING ERRCODE = 'P0001';
  END IF;

  SELECT reward_threshold INTO v_threshold
  FROM public.loyalty_programs WHERE id = v_program_id AND is_active = true;

  IF v_threshold IS NULL THEN
    RAISE EXCEPTION 'not_found: program pasif' USING ERRCODE = 'P0001';
  END IF;

  INSERT INTO public.loyalty_members (program_id, user_id, progress)
  VALUES (v_program_id, p_user_id, 0)
  ON CONFLICT (program_id, user_id) DO NOTHING;

  SELECT id INTO v_member_id
  FROM public.loyalty_members WHERE program_id = v_program_id AND user_id = p_user_id;

  SELECT max(created_at) INTO v_last_scan
  FROM public.loyalty_events
  WHERE member_id = v_member_id AND source = 'qr_scan';

  IF v_last_scan IS NOT NULL AND v_last_scan > now() - interval '60 seconds' THEN
    RAISE EXCEPTION 'validation_error: çok hızlı tekrar tarama' USING ERRCODE = 'P0003';
  END IF;

  UPDATE public.loyalty_members SET progress = progress + 1, updated_at = now()
  WHERE id = v_member_id
  RETURNING progress INTO v_progress;

  INSERT INTO public.loyalty_events (member_id, source, amount, actor_id)
  VALUES (v_member_id, 'qr_scan', 1, auth.uid());

  RETURN jsonb_build_object(
    'member_id', v_member_id,
    'progress', v_progress,
    'reward_threshold', v_threshold,
    'reward_ready', v_progress >= v_threshold
  );
END;
$$;

REVOKE ALL ON FUNCTION public.scan_loyalty_qr_v1(uuid, uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.scan_loyalty_qr_v1(uuid, uuid) TO authenticated;
COMMENT ON FUNCTION public.scan_loyalty_qr_v1 IS
  'Owner/personel: kasada müşteri QR''sini okutup damga/puan ekler. Rate limit: aynı üyede 60sn içinde tekrar tarama engellenir. Called by: app/sahip/pazarlama/sadakat (QR tarama ekranı, Faz 2).';

-- ── redeem_loyalty_reward_v1 ─────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.redeem_loyalty_reward_v1(p_member_id uuid)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_business_id uuid;
  v_chain_id    uuid;
  v_threshold   int;
  v_progress    int;
BEGIN
  SELECT lp.business_id, lp.chain_id, lp.reward_threshold, lm.progress
  INTO v_business_id, v_chain_id, v_threshold, v_progress
  FROM public.loyalty_members lm
  JOIN public.loyalty_programs lp ON lp.id = lm.program_id
  WHERE lm.id = p_member_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'not_found: üye bulunamadı' USING ERRCODE = 'P0001';
  END IF;

  IF v_business_id IS NOT NULL THEN
    IF NOT public.is_owner_of_business(v_business_id) THEN
      RAISE EXCEPTION 'unauthorized' USING ERRCODE = 'P0002';
    END IF;
  ELSE
    IF NOT EXISTS (
      SELECT 1 FROM public.businesses b
      WHERE b.chain_id = v_chain_id AND public.is_owner_of_business(b.id)
    ) THEN
      RAISE EXCEPTION 'unauthorized' USING ERRCODE = 'P0002';
    END IF;
  END IF;

  IF v_progress < v_threshold THEN
    RAISE EXCEPTION 'validation_error: eşiğe ulaşılmadı' USING ERRCODE = 'P0003';
  END IF;

  UPDATE public.loyalty_members
  SET progress = progress - v_threshold, redeemed_count = redeemed_count + 1, updated_at = now()
  WHERE id = p_member_id
  RETURNING progress INTO v_progress;

  INSERT INTO public.loyalty_events (member_id, source, amount, actor_id)
  VALUES (p_member_id, 'redeem', v_threshold, auth.uid());

  RETURN jsonb_build_object('member_id', p_member_id, 'progress', v_progress);
END;
$$;

REVOKE ALL ON FUNCTION public.redeem_loyalty_reward_v1(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.redeem_loyalty_reward_v1(uuid) TO authenticated;
COMMENT ON FUNCTION public.redeem_loyalty_reward_v1 IS
  'Owner/personel: eşiğe ulaşmış üyenin ödülünü düşürür. Called by: app/sahip/pazarlama/sadakat (QR tarama ekranı, Ödülü Kullan butonu, Faz 2).';

-- ── get_business_loyalty_members_v1 ──────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.get_business_loyalty_members_v1(p_business_id uuid)
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_program_id uuid;
BEGIN
  IF NOT public.is_owner_of_business(p_business_id) THEN
    RAISE EXCEPTION 'unauthorized' USING ERRCODE = 'P0002';
  END IF;

  v_program_id := public._resolve_loyalty_program_v1(p_business_id);
  IF v_program_id IS NULL THEN
    RETURN '[]'::jsonb;
  END IF;

  RETURN COALESCE(
    (
      SELECT jsonb_agg(
        jsonb_build_object(
          'member_id', lm.id,
          'user_id', lm.user_id,
          'display_name', coalesce(up.display_name, 'Kullanıcı'),
          'progress', lm.progress,
          'redeemed_count', lm.redeemed_count
        )
        ORDER BY lm.progress DESC
      )
      FROM public.loyalty_members lm
      LEFT JOIN public.user_profiles up ON up.user_id = lm.user_id
      WHERE lm.program_id = v_program_id
    ),
    '[]'::jsonb
  );
END;
$$;

REVOKE ALL ON FUNCTION public.get_business_loyalty_members_v1(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_business_loyalty_members_v1(uuid) TO authenticated;
COMMENT ON FUNCTION public.get_business_loyalty_members_v1 IS
  'Owner/personel: sadakat programının üye/CRM listesi. Called by: app/sahip/pazarlama/sadakat (Faz 2).';
```

- [ ] **Step 2: Local doğrulama**

Run: `supabase db reset`
Expected: Hatasız uygulanır.

- [ ] **Step 3: Commit**

```bash
git add supabase/migrations/20260810000003_sadakat_v1_owner_rpcs.sql
git commit -m "feat(db): sadakat v1 — owner RPC'leri (create/activate/scan/redeem/get_members)"
```

---

### Task 4: Müşteri RPC'si + yorum tetikleyicisi

**Files:**
- Create: `supabase/migrations/20260810000004_sadakat_v1_customer_rpc_and_triggers.sql`

- [ ] **Step 1: Migration dosyasını oluştur**

```sql
-- Sadakat v1 — müşteri RPC'si + otomatik kazanma tetikleyicisi.
-- bkz. docs/superpowers/specs/2026-08-10-sadakat-design.md

-- ── get_my_loyalty_cards_v1 ───────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.get_my_loyalty_cards_v1()
RETURNS jsonb
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT COALESCE(
    jsonb_agg(
      jsonb_build_object(
        'program_id', lp.id,
        'mode', lp.mode,
        'business_name', b.name,
        'logo_url', b.logo_url,
        'progress', lm.progress,
        'reward_threshold', lp.reward_threshold,
        'reward_desc', lp.reward_desc
      )
      ORDER BY lm.updated_at DESC
    ),
    '[]'::jsonb
  )
  FROM public.loyalty_members lm
  JOIN public.loyalty_programs lp ON lp.id = lm.program_id AND lp.is_active = true
  LEFT JOIN public.businesses b ON b.id = COALESCE(
    lp.business_id,
    (SELECT id FROM public.businesses WHERE chain_id = lp.chain_id ORDER BY chain_sort_order NULLS LAST LIMIT 1)
  )
  WHERE lm.user_id = auth.uid();
$$;

REVOKE ALL ON FUNCTION public.get_my_loyalty_cards_v1() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_my_loyalty_cards_v1() TO authenticated;
COMMENT ON FUNCTION public.get_my_loyalty_cards_v1 IS
  'Müşteri: tüm sadakat kartlarını döner. Called by: mobil features/sadakat (Faz 4), web app/(kimlik)/sadakat (Faz 3).';

-- ── _award_loyalty_progress (internal, client''a GRANT edilmez) ──────────────
CREATE OR REPLACE FUNCTION public._award_loyalty_progress(
  p_business_id uuid,
  p_user_id     uuid,
  p_amount      int,
  p_source      text
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_program_id uuid;
  v_member_id  uuid;
BEGIN
  IF p_source NOT IN ('review') THEN
    RAISE EXCEPTION 'validation_error: geçersiz source' USING ERRCODE = 'P0003';
  END IF;

  v_program_id := public._resolve_loyalty_program_v1(p_business_id);
  IF v_program_id IS NULL THEN
    RETURN;
  END IF;

  IF NOT EXISTS (SELECT 1 FROM public.loyalty_programs WHERE id = v_program_id AND is_active = true) THEN
    RETURN;
  END IF;

  INSERT INTO public.loyalty_members (program_id, user_id, progress)
  VALUES (v_program_id, p_user_id, p_amount)
  ON CONFLICT (program_id, user_id) DO UPDATE SET
    progress = loyalty_members.progress + excluded.progress,
    updated_at = now()
  RETURNING id INTO v_member_id;

  INSERT INTO public.loyalty_events (member_id, source, amount, actor_id)
  VALUES (v_member_id, p_source, p_amount, NULL);
END;
$$;

REVOKE ALL ON FUNCTION public._award_loyalty_progress(uuid, uuid, int, text) FROM PUBLIC;
COMMENT ON FUNCTION public._award_loyalty_progress IS
  'Internal: public RPC değil, client''a hiç GRANT edilmez. Called by: trg_award_loyalty_on_review.';

-- ── Yorum onaylanınca otomatik kazanma ────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.trg_award_loyalty_on_review()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NEW.status = 'approved' AND (OLD.status IS NULL OR OLD.status <> 'approved') THEN
    PERFORM public._award_loyalty_progress(NEW.business_id, NEW.user_id, 1, 'review');
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_loyalty_review ON public.reviews;
CREATE TRIGGER trg_loyalty_review
  AFTER INSERT OR UPDATE OF status ON public.reviews
  FOR EACH ROW EXECUTE FUNCTION public.trg_award_loyalty_on_review();
```

- [ ] **Step 2: Local doğrulama**

Run: `supabase db reset`
Expected: Hatasız uygulanır.

- [ ] **Step 3: Commit**

```bash
git add supabase/migrations/20260810000004_sadakat_v1_customer_rpc_and_triggers.sql
git commit -m "feat(db): sadakat v1 — get_my_loyalty_cards_v1 + yorum-tetikleyicili otomatik kazanma"
```

---

### Task 5: Premium plan gating seed

**Files:**
- Create: `supabase/migrations/20260810000005_sadakat_v1_plan_gating.sql`

`map_boost` ile aynı kademe eşiği kullanılıyor (standard+pro açık, free+starter kilitli) — kullanıcının "premium-only" kararıyla tutarlı, mevcut bir örnek üzerinden.

- [ ] **Step 1: Migration dosyasını oluştur**

```sql
-- Sadakat v1 — premium plan gating seed. map_boost ile aynı kademe eşiği.
INSERT INTO public.plan_features (plan_tier, feature_key, limit_value, enabled) VALUES
  ('free',     'sadakat_programi', NULL, false),
  ('starter',  'sadakat_programi', NULL, false),
  ('standard', 'sadakat_programi', NULL, true),
  ('pro',      'sadakat_programi', NULL, true);
```

- [ ] **Step 2: Local doğrulama**

Run: `supabase db reset`
Expected: Hatasız uygulanır. Ardından şu sorguyla seed'in girdiğini doğrula:

Run: `psql "$(supabase status -o env | grep DB_URL | cut -d= -f2)" -c "select * from plan_features where feature_key='sadakat_programi';"`
Expected: 4 satır (free/starter/standard/pro), free ve starter `enabled=false`, standard ve pro `enabled=true`.

- [ ] **Step 3: Commit**

```bash
git add supabase/migrations/20260810000005_sadakat_v1_plan_gating.sql
git commit -m "feat(db): sadakat v1 — premium plan gating seed (standard+pro açık)"
```

---

### Task 6: Son doğrulama — advisors + manuel RPC smoke test

**Files:** (yalnızca doğrulama, dosya değişikliği yok)

- [ ] **Step 1: Supabase advisors kontrolü**

`mcp__supabase__get_advisors` (tip: `security`) çalıştır.
Expected: Yeni tablolar/RPC'ler için (RLS eksikliği, GRANT fazlalığı vb.) uyarı çıkmaz. Çıkarsa ilgili Task'a geri dön ve düzelt.

- [ ] **Step 2: Manuel RPC smoke test (local)**

Local Supabase Studio SQL editöründen (veya `psql`) test işletmesi ve test kullanıcısıyla:

```sql
-- 1) Program oluştur (gerçek bir business_id + standard/pro planlı işletme ile)
select public.create_loyalty_program_v1('<business_id>', 'stamp', 'Test Sadakat', '1 bedava kahve', 5);
-- 2) Aktive et
select public.set_loyalty_program_active_v1('<program_id>', true);
-- 3) QR okut (owner rolüyle)
select public.scan_loyalty_qr_v1('<business_id>', '<customer_user_id>');
-- 4) Müşteri rolüyle kartları getir
select public.get_my_loyalty_cards_v1();
```

Expected: Adım 3 `reward_ready: false` döner (1/5), adım 4 kartı `progress=1` ile listeler. Free/starter planlı bir işletmede adım 1 `plan_limit_exceeded` hatası vermeli.

- [ ] **Step 3: Kullanıcıya rapor**

Faz 1 tamamlandığında kullanıcıya: hangi migration'lar eklendi, smoke test sonucu, Faz 2'ye (owner web UI) geçiş hazır mı — özetle.

---

### Task 7: Production'a uygula (kullanıcı talebi: "iş bitiminde canlı supabase'de push yaparsın")

**Bu task sadece Task 1-6 tamamlanmış, local'de sorunsuz çalıştığı doğrulanmış VE branch main'e merge edilmiş/kullanıcı onaylamışsa çalıştırılır.** Worktree'den çıkıp main'e dönüldükten sonra uygulanmalı — production push bir worktree branch'inden değil, birleştirilmiş main state'inden yapılmalı.

**Files:** (dosya değişikliği yok, sadece deploy)

- [ ] **Step 1: Hangi migration'ların push edileceğini göster**

Run: `supabase migration list --linked`
Expected: `20260810000001`...`20260810000005` "Local" sütununda var, "Remote" sütununda henüz yok (push edilmemiş) olarak görünür. Kullanıcıya bu listeyi göster, push'tan önce son bir onay iste.

- [ ] **Step 2: Production'a push et**

Run: `supabase db push --linked`
Expected: 5 migration sırayla uygulanır, hata çıkmaz.

- [ ] **Step 3: Production advisors kontrolü**

`mcp__supabase__get_advisors` (tip: `security`) — bu sefer **linked production projesine karşı**.
Expected: Yeni tablolar/RPC'ler için uyarı yok.

- [ ] **Step 4: TypeScript tiplerini yeniden üret**

Run (uygulamalar/web içinden): `mcp__supabase__generate_typescript_types` çıktısını `src/lib/supabase/database.types.ts` ve `src/lib/taban/veri-tanimlari.ts` dosyalarına yaz.
Expected: Artık silinen eski loyalty/business_automations tipleri kaybolur, yeni loyalty_programs/loyalty_members/loyalty_events + RPC dönüş tipleri belirir.

- [ ] **Step 5: Kullanıcıya son rapor**

Push edilen migration sayısı, advisors sonucu, tip regen sonucu — özetle. Faz 2 (owner web UI) planına geçmeye hazır olduğunu bildir.
