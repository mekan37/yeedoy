# Premium Plan/Gating Altyapısı Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** İşletme paneline (`app/sahip/**`) plan-bazlı özellik kilitleme altyapısı kazandırmak — ürün limiti, OCR/AI menü tarama, AI alerjen/kalori otomasyonu, AI görsel üretme, çoklu dil, QR filigranı ve harita önceliklendirmesini `free/starter/standard/pro` kademelerine bağlamak.

**Architecture:** Mevcut `business_premium` tablosu (zaten var, verified/premium rozetleri için kullanılıyor) `tier` CHECK'i genişletilerek plan kademelerini de taşıyacak şekilde yeniden kullanılıyor — yeni bir "premium mi" kaynağı açılmıyor. Yeni `plan_features` tablosu kademe→özellik/limit eşlemesini veri olarak tutuyor (SQL satırıyla değiştirilebilir). Her gated işlem, kendi RPC'sinin veya Server Action'ının başında `_check_plan_limit_v1` çağırıyor — kısıtlama veritabanı seviyesinde, sadece arayüzde gizleme değil. OCR için arşivlenmiş (`supabase/migrations/_archive/`) ama hiç uygulanmamış bir şema diriltiliyor. Harita önceliklendirmesi zaten var olan `sponsorships`/`sponsorship_packages` tablolarına bağlanıyor — paralel bir mekanizma kurulmuyor.

**Tech Stack:** Supabase (Postgres/plpgsql + Edge Functions), Next.js 15 App Router (Server Actions), TypeScript, vitest.

**Spec:** `docs/superpowers/specs/2026-08-03-premium-plan-gating-design.md`

**Önemli not:** Bu plan, spec onayından SONRA yapılan kod denetiminde ortaya çıkan üç önemli düzeltmeyi yansıtıyor (kullanıcıyla teyit edildi): (1) yeni bir `plan_tier` kolonu yerine mevcut `business_premium` tablosu genişletiliyor, (2) harita önceliklendirmesi mevcut `sponsorships` tablosuna bağlanıyor ve hem web hem mobil keşif yüzeyini etkileyebilir (kullanıcı onayladı — "mobile dokunma" kısıtı sadece OCR'da ayrı sistem kurmama anlamındaydı), (3) OCR için arşivlenmiş şema diriltiliyor (basit buton bağlama değil).

---

### Task 1: Migration — plan/premium temel şeması

**Files:**
- Create: `supabase/migrations/20260803000001_premium_plan_foundation.sql`

- [ ] **Step 1: Migration dosyasını yaz**

Create `supabase/migrations/20260803000001_premium_plan_foundation.sql`:

```sql
-- Premium plan/gating altyapısı — temel şema.
-- business_premium.tier zaten var (verified/premium rozetleri için) — yeni bir
-- "bu işletme premium mi" kaynağı açmak yerine CHECK'i genişletip aynı tabloyu
-- SaaS plan kademeleri için de kullanıyoruz.

ALTER TABLE public.business_premium
  DROP CONSTRAINT business_premium_tier_check;

ALTER TABLE public.business_premium
  ADD CONSTRAINT business_premium_tier_check
  CHECK (tier = ANY (ARRAY['verified','premium','starter','standard','pro']::text[]));

-- Bir işletmede aynı anda yalnızca TEK bir plan kademesi (starter/standard/pro)
-- aktif olabilir. verified/premium rozetleri bundan bağımsız, birlikte var olabilir
-- (mevcut business_premium_active_unique (business_id, tier) bunu zaten koruyor,
-- ama o farklı tier değerlerinin AYNI ANDA aktif olmasını engellemiyor — bu yeni
-- index sadece plan kademeleri arasında karşılıklı dışlama sağlıyor).
CREATE UNIQUE INDEX business_premium_active_plan_unique
  ON public.business_premium (business_id)
  WHERE status = 'active' AND tier IN ('starter','standard','pro');

-- Kademe → özellik/limit eşlemesi. Veri, kod değil — SQL satırıyla değiştirilebilir.
CREATE TABLE public.plan_features (
  plan_tier   text NOT NULL CHECK (plan_tier IN ('free','starter','standard','pro')),
  feature_key text NOT NULL,
  limit_value int NULL,
  enabled     boolean NOT NULL DEFAULT true,
  PRIMARY KEY (plan_tier, feature_key)
);

ALTER TABLE public.plan_features ENABLE ROW LEVEL SECURITY;

CREATE POLICY "plan_features_public_read" ON public.plan_features
  FOR SELECT TO authenticated, anon USING (true);

CREATE POLICY "plan_features_admin_write" ON public.plan_features
  USING (public.is_admin()) WITH CHECK (public.is_admin());

-- Sayaçlı özellikler için aylık kullanım takibi (ör. "bu ay kaç OCR taraması").
CREATE TABLE public.plan_feature_usage (
  business_id  uuid NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
  feature_key  text NOT NULL,
  period_start date NOT NULL,
  usage_count  int NOT NULL DEFAULT 0,
  PRIMARY KEY (business_id, feature_key, period_start)
);

ALTER TABLE public.plan_feature_usage ENABLE ROW LEVEL SECURITY;

CREATE POLICY "plan_feature_usage_owner_read" ON public.plan_feature_usage
  FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.owner_claims oc
      WHERE oc.business_id = plan_feature_usage.business_id
        AND oc.user_id = auth.uid()
        AND oc.status = 'approved'
    )
  );

-- Seed: kademe → özellik eşlemesi (spec'teki Bölüm 1 tablosu)
INSERT INTO public.plan_features (plan_tier, feature_key, limit_value, enabled) VALUES
  ('free',     'menu_item_count',     30,   true),
  ('starter',  'menu_item_count',     NULL, true),
  ('standard', 'menu_item_count',     NULL, true),
  ('pro',      'menu_item_count',     NULL, true),

  ('free',     'ocr_scans_per_month', 1,    true),
  ('starter',  'ocr_scans_per_month', 5,    true),
  ('standard', 'ocr_scans_per_month', NULL, true),
  ('pro',      'ocr_scans_per_month', NULL, true),

  ('free',     'allergen_ai',         NULL, false),
  ('starter',  'allergen_ai',         NULL, false),
  ('standard', 'allergen_ai',         NULL, true),
  ('pro',      'allergen_ai',         NULL, true),

  ('free',     'language_count',      1,    true),
  ('starter',  'language_count',      1,    true),
  ('standard', 'language_count',      2,    true),
  ('pro',      'language_count',      NULL, true),

  ('free',     'ai_image_gen',        NULL, false),
  ('starter',  'ai_image_gen',        NULL, false),
  ('standard', 'ai_image_gen',        NULL, false),
  ('pro',      'ai_image_gen',        NULL, true),

  ('free',     'qr_watermark',        NULL, true),
  ('starter',  'qr_watermark',        NULL, false),
  ('standard', 'qr_watermark',        NULL, false),
  ('pro',      'qr_watermark',        NULL, false),

  ('free',     'map_boost',           NULL, false),
  ('starter',  'map_boost',           NULL, false),
  ('standard', 'map_boost',           NULL, true),
  ('pro',      'map_boost',           NULL, true);

COMMENT ON TABLE public.plan_features IS
  'Plan kademesi -> özellik/limit eşlemesi. limit_value NULL = sınırsız (sayısal) veya sadece enabled bakılır (boolean özellik).';
COMMENT ON TABLE public.plan_feature_usage IS
  'Aylık sayaçlı plan özellikleri için kullanım takibi (ör. ocr_scans_per_month).';
```

- [ ] **Step 2: Lokal Supabase'i sıfırla ve migration'ın uygulandığını doğrula**

Run: `supabase db reset`
Expected: Hatasız biter, migration listesinde `20260803000001_premium_plan_foundation` görünür.

Run (doğrulama sorgusu):
```bash
supabase db execute --sql "select plan_tier, feature_key, limit_value, enabled from public.plan_features order by plan_tier, feature_key"
```
Expected: 28 satır (4 kademe × 7 özellik) döner.

- [ ] **Step 3: Commit**

```bash
git add supabase/migrations/20260803000001_premium_plan_foundation.sql
git commit -m "feat(db): premium plan altyapısı — business_premium genişlet, plan_features/plan_feature_usage ekle"
```

---

### Task 2: Migration — plan limiti kontrol/artırım RPC'leri

**Files:**
- Create: `supabase/migrations/20260803000002_plan_limit_rpcs.sql`

- [ ] **Step 1: Migration dosyasını yaz**

Create `supabase/migrations/20260803000002_plan_limit_rpcs.sql`:

```sql
-- Plan limiti kontrol/artırım yardımcı RPC'leri.

CREATE OR REPLACE FUNCTION public._get_business_plan_tier_v1(p_business_id uuid)
RETURNS text
LANGUAGE sql STABLE
SET search_path = public
AS $$
  SELECT COALESCE(
    (SELECT tier FROM public.business_premium
     WHERE business_id = p_business_id
       AND status = 'active'
       AND tier IN ('starter','standard','pro')
       AND (ends_at IS NULL OR ends_at >= now())
     ORDER BY starts_at DESC
     LIMIT 1),
    'free'
  );
$$;

REVOKE ALL ON FUNCTION public._get_business_plan_tier_v1(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public._get_business_plan_tier_v1(uuid) TO authenticated;
COMMENT ON FUNCTION public._get_business_plan_tier_v1 IS
  'İşletmenin güncel plan kademesini döner (aktif starter/standard/pro yoksa free).';

-- p_feature_key = 'menu_item_count' -> menu_items tablosunda canlı sayım.
-- Diğer tüm feature_key'ler -> plan_feature_usage üzerinden aylık sayaç.
-- (language_count, upsert_menu_item_translation_v1 içinde ayrıca ve özel
--  mantıkla kontrol edilir — bkz. Task 12 — çünkü "zaten var olan dile
--  güncelleme" ile "yeni dil ekleme" ayrımı burada genelleştirilemez.)
CREATE OR REPLACE FUNCTION public._check_plan_limit_v1(
  p_business_id uuid,
  p_feature_key text
)
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
BEGIN
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

REVOKE ALL ON FUNCTION public._check_plan_limit_v1(uuid, text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public._check_plan_limit_v1(uuid, text) TO authenticated;
COMMENT ON FUNCTION public._check_plan_limit_v1 IS
  'İşletmenin plan kademesine göre bir özelliği kullanmasına izin var mı kontrol eder; aşılmışsa P0003 fırlatır. Called by: menu-islemleri.ts, create_menu_ocr_job_v1, ai-allergen-detect/ai-nutrition-estimate/ai-menu-image-gen çağrı noktaları.';

CREATE OR REPLACE FUNCTION public._increment_plan_usage_v1(
  p_business_id uuid,
  p_feature_key text
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  INSERT INTO public.plan_feature_usage (business_id, feature_key, period_start, usage_count)
  VALUES (p_business_id, p_feature_key, date_trunc('month', now())::date, 1)
  ON CONFLICT (business_id, feature_key, period_start)
  DO UPDATE SET usage_count = public.plan_feature_usage.usage_count + 1;
END;
$$;

REVOKE ALL ON FUNCTION public._increment_plan_usage_v1(uuid, text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public._increment_plan_usage_v1(uuid, text) TO authenticated;
COMMENT ON FUNCTION public._increment_plan_usage_v1 IS
  'Aylık sayaçlı bir plan özelliğinin kullanımını 1 artırır. _check_plan_limit_v1 ile başarılı geçen işlemden SONRA çağrılmalı.';
```

- [ ] **Step 2: Lokal Supabase'i sıfırla ve fonksiyonları SQL ile doğrula**

Run: `supabase db reset`

Run (doğrulama — free planda 30 ürün limitini simüle eden manuel bir SQL testi):
```bash
supabase db execute --sql "select public._get_business_plan_tier_v1('00000000-0000-0000-0000-000000000000'::uuid)"
```
Expected: `free` döner (var olmayan/premium'suz işletme için varsayılan).

- [ ] **Step 3: Commit**

```bash
git add supabase/migrations/20260803000002_plan_limit_rpcs.sql
git commit -m "feat(db): plan limiti kontrol/artırım RPC'leri (_check_plan_limit_v1, _increment_plan_usage_v1)"
```

---

### Task 3: Migration — admin_set_business_plan_v1

**Files:**
- Create: `supabase/migrations/20260803000003_admin_set_business_plan.sql`

- [ ] **Step 1: Migration dosyasını yaz**

Create `supabase/migrations/20260803000003_admin_set_business_plan.sql`:

```sql
-- Admin: işletmeye plan kademesi atar. Ödeme entegrasyonu gelene kadar
-- planların TEK atanma yolu bu (admin_set_business_verified_v1 pattern'i
-- izlenerek yazıldı, ama farklı kaygı — is_verified'a dokunmaz).

CREATE OR REPLACE FUNCTION public.admin_set_business_plan_v1(
  p_business_id uuid,
  p_plan_tier   text,
  p_ends_at     timestamptz DEFAULT NULL
)
RETURNS jsonb
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

  IF p_plan_tier NOT IN ('free','starter','standard','pro') THEN
    RAISE EXCEPTION 'validation_error: geçersiz plan_tier' USING ERRCODE = 'P0003';
  END IF;

  -- Var olan aktif plan kademesini sonlandır (starter/standard/pro karşılıklı dışlar)
  UPDATE public.business_premium
  SET status = 'ended', ends_at = now()
  WHERE business_id = p_business_id
    AND status = 'active'
    AND tier IN ('starter','standard','pro');

  IF p_plan_tier <> 'free' THEN
    INSERT INTO public.business_premium (business_id, tier, status, starts_at, ends_at, source, created_by)
    VALUES (p_business_id, p_plan_tier, 'active', now(), p_ends_at, 'manual', auth.uid())
    RETURNING id INTO v_id;
  END IF;

  PERFORM public.insert_audit_log_v1(
    'business.plan_changed',
    'business',
    p_business_id,
    '{}'::jsonb,
    jsonb_build_object('plan_tier', p_plan_tier, 'premium_id', v_id)
  );

  RETURN jsonb_build_object('ok', true, 'business_id', p_business_id, 'plan_tier', p_plan_tier, 'premium_id', v_id);
END;
$$;

REVOKE ALL ON FUNCTION public.admin_set_business_plan_v1(uuid, text, timestamptz) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.admin_set_business_plan_v1(uuid, text, timestamptz) TO authenticated;
COMMENT ON FUNCTION public.admin_set_business_plan_v1 IS
  'Admin: işletmeye premium plan kademesi atar (free/starter/standard/pro). Ödeme entegrasyonu gelene kadar manuel atama yolu — Supabase SQL/Studio üzerinden çağrılır, admin panelde UI'ı yok (bu turun kapsamı dışında).';
```

- [ ] **Step 2: Lokal Supabase'i sıfırla ve fonksiyonu doğrula**

Run: `supabase db reset`

Run (bir test işletmesine standard plan atayıp doğrula — `<business_id>` yerine seed'deki gerçek bir işletme id'si kullanılmalı):
```bash
supabase db execute --sql "select public.admin_set_business_plan_v1('<business_id>'::uuid, 'standard')"
```
Expected: `{"ok": true, "business_id": "...", "plan_tier": "standard", "premium_id": "..."}` döner. Ardından `select public._get_business_plan_tier_v1('<business_id>'::uuid)` çağrıldığında `standard` dönmeli.

- [ ] **Step 3: Commit**

```bash
git add supabase/migrations/20260803000003_admin_set_business_plan.sql
git commit -m "feat(db): admin_set_business_plan_v1 — manuel plan atama RPC'si"
```

---

### Task 4: Migration — get_menu_item_counts_v1'i tamamla + get_my_plan_v1

**Files:**
- Create: `supabase/migrations/20260803000004_plan_summary_rpcs.sql`

- [ ] **Step 1: Migration dosyasını yaz**

`get_menu_item_counts_v1` zaten var ama stub (`supabase/migrations/20260526000002_planned_rpc_stubs.sql:66-80`) — her zaman `not_implemented (P0004)` fırlatıyor. `CREATE OR REPLACE` ile gerçek implementasyonla eziyoruz (imza/dönüş tipi aynı kaldığı için bu breaking change değil).

Create `supabase/migrations/20260803000004_plan_summary_rpcs.sql`:

```sql
-- get_menu_item_counts_v1 stub'ını gerçek implementasyonla değiştir.
-- (Önceki tanım: supabase/migrations/20260526000002_planned_rpc_stubs.sql)
CREATE OR REPLACE FUNCTION public.get_menu_item_counts_v1(
  p_business_id uuid
)
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_active  int;
  v_passive int;
BEGIN
  SELECT
    count(*) FILTER (WHERE is_available),
    count(*) FILTER (WHERE NOT is_available)
  INTO v_active, v_passive
  FROM public.menu_items
  WHERE business_id = p_business_id;

  RETURN json_build_object('aktif', v_active, 'pasif', v_passive, 'toplam', v_active + v_passive);
END;
$$;

COMMENT ON FUNCTION public.get_menu_item_counts_v1 IS
  'Menü kalem aktif/pasif/toplam sayısı. 20260803000004 ile stub durumundan çıkarıldı.';

-- Owner: kendi işletmesinin plan kademesi + her özelliğin limit/kullanım özeti.
CREATE OR REPLACE FUNCTION public.get_my_plan_v1(
  p_business_id uuid
)
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
  ) THEN
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
      ELSE (
        SELECT COALESCE(usage_count, 0) FROM public.plan_feature_usage
        WHERE business_id = p_business_id
          AND feature_key = pf.feature_key
          AND period_start = date_trunc('month', now())::date
      )
    END
  ) ORDER BY pf.feature_key)
  INTO v_features
  FROM public.plan_features pf
  WHERE pf.plan_tier = v_tier;

  RETURN jsonb_build_object('plan_tier', v_tier, 'features', COALESCE(v_features, '[]'::jsonb));
END;
$$;

REVOKE ALL ON FUNCTION public.get_my_plan_v1(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_my_plan_v1(uuid) TO authenticated;
COMMENT ON FUNCTION public.get_my_plan_v1 IS
  'Owner: işletmenin plan kademesi + özellik limit/kullanım özeti. Called by: app/sahip/ayarlar/plan.';
```

- [ ] **Step 2: Lokal Supabase'i sıfırla ve doğrula**

Run: `supabase db reset`

Run:
```bash
supabase db execute --sql "select public.get_menu_item_counts_v1('<business_id>'::uuid)"
```
Expected: `{"aktif": N, "pasif": M, "toplam": N+M}` (artık `P0004` hatası yok).

- [ ] **Step 3: Commit**

```bash
git add supabase/migrations/20260803000004_plan_summary_rpcs.sql
git commit -m "feat(db): get_menu_item_counts_v1 stub'ını tamamla, get_my_plan_v1 ekle"
```

---

### Task 5: Web — ürün limiti kontrolü (menu-islemleri.ts)

**Files:**
- Modify: `uygulamalar/web/app/sahip/menuler/[menuId]/duzenle/menu-islemleri.ts`

- [ ] **Step 1: `upsertItem`'ın insert dalına limit kontrolü ekle**

Mevcut (satır 163-175):

```typescript
  } else {
    const { count } = await (context.supabase as any)
      .from('menu_items')
      .select('id', { count: 'exact', head: true })
      .eq('section_id', sectionId) as { count: number | null };
    const { data: newItem, error: insertErr } = await (context.supabase as any)
      .from('menu_items')
      .insert({ ...payload, business_id: context.businessId, sort_order: (count ?? 0) })
      .select('id')
      .single() as { data: { id: string } | null; error: { message: string } | null };
    if (insertErr) return { error: insertErr.message };
    resolvedItemId = newItem?.id ?? '';
  }
```

şununla değiştir:

```typescript
  } else {
    const { error: limitError } = await (context.supabase as any).rpc('_check_plan_limit_v1', {
      p_business_id: context.businessId,
      p_feature_key: 'menu_item_count',
    }) as { error: { message: string } | null };
    if (limitError) {
      return { error: 'Ürün limitine ulaştınız. Daha fazla ürün eklemek için planınızı yükseltin.' };
    }

    const { count } = await (context.supabase as any)
      .from('menu_items')
      .select('id', { count: 'exact', head: true })
      .eq('section_id', sectionId) as { count: number | null };
    const { data: newItem, error: insertErr } = await (context.supabase as any)
      .from('menu_items')
      .insert({ ...payload, business_id: context.businessId, sort_order: (count ?? 0) })
      .select('id')
      .single() as { data: { id: string } | null; error: { message: string } | null };
    if (insertErr) return { error: insertErr.message };
    resolvedItemId = newItem?.id ?? '';
  }
```

- [ ] **Step 2: typecheck ve lint çalıştır**

Run: `cd uygulamalar/web && pnpm run typecheck && pnpm run lint`
Expected: İkisi de hatasız biter.

- [ ] **Step 3: Manuel doğrulama**

Lokal Supabase'de bir test işletmesini `free` planda bırak (varsayılan zaten free), `menu_items`'a 30 ürün ekleyip 31.'de `upsertItem`'ın `{error: 'Ürün limitine ulaştınız...'}` döndürdüğünü owner panelinde (`/sahip/menuler/[menuId]/duzenle`) gözle doğrula. Ardından `supabase db execute --sql "select public.admin_set_business_plan_v1('<business_id>'::uuid, 'starter')"` ile planı yükselt, 31. ürünün artık eklenebildiğini doğrula.

- [ ] **Step 4: Commit**

```bash
git add uygulamalar/web/app/sahip/menuler/\[menuId\]/duzenle/menu-islemleri.ts
git commit -m "feat(web): menü ürünü ekleme akışına plan bazlı ürün limiti kontrolü ekle"
```

---

### Task 6: Web — plan özeti sayfası

**Files:**
- Create: `uygulamalar/web/app/sahip/ayarlar/plan/page.tsx`
- Create: `uygulamalar/web/app/sahip/ayarlar/plan/plan-ozet-istemcisi.tsx`

- [ ] **Step 1: Sunucu sayfasını yaz**

Create `uygulamalar/web/app/sahip/ayarlar/plan/page.tsx`:

```typescript
import { redirect } from 'next/navigation';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { getOwnerBusinessIds } from '@/src/lib/veri/owner/sahip-isletmeleri';
import { PlanOzetIstemcisi } from './plan-ozet-istemcisi';

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

export default async function PlanSayfasi() {
  const supabase = await createSupabaseServerClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) redirect('/giris?redirect=%2Fsahip%2Fayarlar%2Fplan');

  const businessIds = await getOwnerBusinessIds(supabase, user.id);
  const businessId = businessIds[0];
  if (!businessId) redirect('/sahip');

  const { data, error } = await (supabase as any).rpc('get_my_plan_v1', {
    p_business_id: businessId,
  }) as {
    data: { plan_tier: string; features: Array<{ feature_key: string; enabled: boolean; limit_value: number | null; used: number }> } | null;
    error: { message: string } | null;
  };

  if (error || !data) {
    return <p className="p-6 text-sm font-bold text-red-600">Plan bilgisi yüklenemedi.</p>;
  }

  return (
    <PlanOzetIstemcisi
      planTier={data.plan_tier}
      planLabel={TIER_LABELS[data.plan_tier] ?? data.plan_tier}
      features={data.features.map((f) => ({
        ...f,
        label: FEATURE_LABELS[f.feature_key] ?? f.feature_key,
      }))}
    />
  );
}
```

- [ ] **Step 2: İstemci bileşenini yaz**

Create `uygulamalar/web/app/sahip/ayarlar/plan/plan-ozet-istemcisi.tsx`:

```typescript
'use client';

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
    <div className="mx-auto max-w-2xl space-y-6 p-6">
      <div className="rounded-2xl border border-border bg-card p-5">
        <p className="text-xs font-bold uppercase tracking-wide text-muted">Kademeniz</p>
        <p className="mt-1 text-2xl font-black text-textStrong">{planLabel}</p>
      </div>

      <div className="divide-y divide-border rounded-2xl border border-border bg-card">
        {features.map((feature) => (
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
            ) : (
              <span className="rounded-full border border-border bg-bg px-2.5 py-1 text-xs font-bold text-textStrong">
                {feature.used} / {feature.limit_value}
              </span>
            )}
          </div>
        ))}
      </div>

      <p className="text-xs text-muted">
        Kademenizi yükseltmek için{' '}
        <a href="mailto:destek@yeedoy.com" className="font-bold text-primary hover:underline">
          bize ulaşın
        </a>
        .
      </p>
    </div>
  );
}
```

- [ ] **Step 3: typecheck ve lint çalıştır**

Run: `cd uygulamalar/web && pnpm run typecheck && pnpm run lint`
Expected: İkisi de hatasız biter.

- [ ] **Step 4: Manuel doğrulama**

`pnpm run dev` ile dev server'ı başlat, işletme sahibi hesabıyla giriş yap, `/sahip/ayarlar/plan` sayfasını aç. Kademe adının ve her özelliğin (Kilitli/Sınırsız/kullanım sayacı) doğru göründüğünü kontrol et.

- [ ] **Step 5: Commit**

```bash
git add uygulamalar/web/app/sahip/ayarlar/plan/
git commit -m "feat(web): plan özeti sayfası (app/sahip/ayarlar/plan)"
```

---

### Task 7: Migration — OCR şemasını diriltme (arşivden, güncel konvansiyonlarla)

**Files:**
- Create: `supabase/migrations/20260803000005_menu_ocr_revival.sql`

- [ ] **Step 1: Migration dosyasını yaz**

`supabase/migrations/_archive/20260411000001_ai_menu_analysis_v1.sql` temel alınıyor ama ownership kontrolleri güncel konvansiyona (`owner_claims`, `is_admin()`) taşınıyor — arşivdeki `businesses.owner_id` doğrudan kontrolü ve `auth.users` metadata admin kontrolü artık kullanılmıyor.

Create `supabase/migrations/20260803000005_menu_ocr_revival.sql`:

```sql
-- OCR/AI menü tarama şeması — arşivden diriltildi (_archive/20260411000001_ai_menu_analysis_v1.sql),
-- ownership kontrolleri güncel owner_claims/is_admin() konvansiyonuna taşındı.

CREATE TABLE public.menu_ocr_jobs (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id   uuid NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
  owner_id      uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  file_url      text NOT NULL,
  file_name     text,
  status        text NOT NULL DEFAULT 'queued'
                  CHECK (status IN ('queued', 'processing', 'completed', 'failed')),
  raw_text      text,
  parsed_output jsonb,
  error_message text,
  item_count    int,
  ocr_engine    text DEFAULT 'none' CHECK (ocr_engine IN ('none', 'deepseek-ocr', 'manual')),
  created_at    timestamptz NOT NULL DEFAULT now(),
  updated_at    timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX menu_ocr_jobs_business_id_idx ON public.menu_ocr_jobs(business_id, created_at DESC);
CREATE INDEX menu_ocr_jobs_status_idx ON public.menu_ocr_jobs(status, created_at DESC);

ALTER TABLE public.menu_ocr_jobs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "menu_ocr_jobs_owner_all" ON public.menu_ocr_jobs
  FOR ALL TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.owner_claims oc
      WHERE oc.business_id = menu_ocr_jobs.business_id
        AND oc.user_id = auth.uid()
        AND oc.status = 'approved'
    )
    OR public.is_admin()
  );

CREATE TABLE public.menu_item_ai_analysis (
  id               uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  ocr_job_id       uuid REFERENCES public.menu_ocr_jobs(id) ON DELETE SET NULL,
  business_id      uuid NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
  menu_item_id     uuid REFERENCES public.menu_items(id) ON DELETE SET NULL,
  source_text      text NOT NULL,
  normalized_text  text,
  ingredients_json jsonb DEFAULT '[]'::jsonb,
  allergens_json   jsonb DEFAULT '[]'::jsonb,
  calorie_min      int,
  calorie_max      int,
  confidence       numeric(4,3) NOT NULL DEFAULT 0 CHECK (confidence >= 0 AND confidence <= 1),
  requires_review  boolean NOT NULL DEFAULT true,
  status           text NOT NULL DEFAULT 'pending_review'
                     CHECK (status IN ('pending_review', 'applied', 'rejected')),
  ai_model         text,
  created_at       timestamptz NOT NULL DEFAULT now(),
  updated_at       timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX menu_item_ai_analysis_business_id_idx ON public.menu_item_ai_analysis(business_id, created_at DESC);
CREATE INDEX menu_item_ai_analysis_ocr_job_id_idx ON public.menu_item_ai_analysis(ocr_job_id);

ALTER TABLE public.menu_item_ai_analysis ENABLE ROW LEVEL SECURITY;

CREATE POLICY "menu_item_ai_analysis_owner_all" ON public.menu_item_ai_analysis
  FOR ALL TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.owner_claims oc
      WHERE oc.business_id = menu_item_ai_analysis.business_id
        AND oc.user_id = auth.uid()
        AND oc.status = 'approved'
    )
    OR public.is_admin()
  );

CREATE OR REPLACE FUNCTION public.tg_menu_ocr_touch_updated_at()
RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN NEW.updated_at := now(); RETURN NEW; END; $$;

CREATE TRIGGER menu_ocr_jobs_updated_at
  BEFORE UPDATE ON public.menu_ocr_jobs
  FOR EACH ROW EXECUTE FUNCTION public.tg_menu_ocr_touch_updated_at();

CREATE TRIGGER menu_item_ai_analysis_updated_at
  BEFORE UPDATE ON public.menu_item_ai_analysis
  FOR EACH ROW EXECUTE FUNCTION public.tg_menu_ocr_touch_updated_at();

-- ── RPC: create_menu_ocr_job_v1 ─────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.create_menu_ocr_job_v1(
  p_business_id uuid,
  p_file_url    text,
  p_file_name   text DEFAULT NULL
)
RETURNS uuid
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public
AS $$
DECLARE
  v_job_id uuid;
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

  PERFORM public._check_plan_limit_v1(p_business_id, 'ocr_scans_per_month');

  INSERT INTO public.menu_ocr_jobs (business_id, owner_id, file_url, file_name)
  VALUES (p_business_id, auth.uid(), p_file_url, p_file_name)
  RETURNING id INTO v_job_id;

  PERFORM public._increment_plan_usage_v1(p_business_id, 'ocr_scans_per_month');

  RETURN v_job_id;
END;
$$;

REVOKE ALL ON FUNCTION public.create_menu_ocr_job_v1(uuid, text, text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.create_menu_ocr_job_v1(uuid, text, text) TO authenticated;
COMMENT ON FUNCTION public.create_menu_ocr_job_v1 IS
  'Owner: OCR tarama işi oluşturur (plan limiti kontrollü). Called by: app/sahip/menu/ocr.';

-- ── RPC: list_menu_ocr_jobs_v1 ──────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.list_menu_ocr_jobs_v1(
  p_business_id uuid,
  p_limit       int DEFAULT 20,
  p_offset      int DEFAULT 0
)
RETURNS TABLE (
  id            uuid,
  file_url      text,
  file_name     text,
  status        text,
  item_count    int,
  error_message text,
  created_at    timestamptz,
  updated_at    timestamptz
)
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public
AS $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM public.owner_claims oc
    WHERE oc.business_id = p_business_id AND oc.user_id = auth.uid() AND oc.status = 'approved'
  ) THEN
    RAISE EXCEPTION 'unauthorized' USING ERRCODE = 'P0002';
  END IF;

  RETURN QUERY
    SELECT j.id, j.file_url, j.file_name, j.status,
           j.item_count, j.error_message, j.created_at, j.updated_at
    FROM public.menu_ocr_jobs j
    WHERE j.business_id = p_business_id
    ORDER BY j.created_at DESC
    LIMIT p_limit OFFSET p_offset;
END;
$$;

REVOKE ALL ON FUNCTION public.list_menu_ocr_jobs_v1(uuid, int, int) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.list_menu_ocr_jobs_v1(uuid, int, int) TO authenticated;
COMMENT ON FUNCTION public.list_menu_ocr_jobs_v1 IS
  'Owner: OCR tarama işlerini listeler. Called by: app/sahip/menu/ocr.';

-- ── RPC: list_menu_ai_analysis_v1 ───────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.list_menu_ai_analysis_v1(
  p_business_id uuid,
  p_ocr_job_id  uuid DEFAULT NULL,
  p_status      text DEFAULT NULL,
  p_limit       int DEFAULT 50,
  p_offset      int DEFAULT 0
)
RETURNS TABLE (
  id               uuid,
  ocr_job_id       uuid,
  source_text      text,
  normalized_text  text,
  ingredients_json jsonb,
  allergens_json   jsonb,
  calorie_min      int,
  calorie_max      int,
  confidence       numeric,
  requires_review  boolean,
  status           text,
  created_at       timestamptz
)
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public
AS $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM public.owner_claims oc
    WHERE oc.business_id = p_business_id AND oc.user_id = auth.uid() AND oc.status = 'approved'
  ) THEN
    RAISE EXCEPTION 'unauthorized' USING ERRCODE = 'P0002';
  END IF;

  RETURN QUERY
    SELECT a.id, a.ocr_job_id, a.source_text, a.normalized_text,
           a.ingredients_json, a.allergens_json,
           a.calorie_min, a.calorie_max,
           a.confidence, a.requires_review, a.status, a.created_at
    FROM public.menu_item_ai_analysis a
    WHERE a.business_id = p_business_id
      AND (p_ocr_job_id IS NULL OR a.ocr_job_id = p_ocr_job_id)
      AND (p_status IS NULL OR a.status = p_status)
    ORDER BY a.created_at DESC
    LIMIT p_limit OFFSET p_offset;
END;
$$;

REVOKE ALL ON FUNCTION public.list_menu_ai_analysis_v1(uuid, uuid, text, int, int) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.list_menu_ai_analysis_v1(uuid, uuid, text, int, int) TO authenticated;
COMMENT ON FUNCTION public.list_menu_ai_analysis_v1 IS
  'Owner: bir OCR taramasının AI analiz sonuçlarını listeler. Called by: app/sahip/menu/ocr.';
```

- [ ] **Step 2: Lokal Supabase'i sıfırla ve doğrula**

Run: `supabase db reset`
Expected: Hatasız biter (arşivdeki tablo/RPC isim çakışması olmaz, çünkü `_archive/` klasörü Supabase migration runner tarafından okunmaz).

Run:
```bash
supabase db execute --sql "select proname from pg_proc where proname in ('create_menu_ocr_job_v1','list_menu_ocr_jobs_v1','list_menu_ai_analysis_v1')"
```
Expected: 3 satır döner.

- [ ] **Step 3: Commit**

```bash
git add supabase/migrations/20260803000005_menu_ocr_revival.sql
git commit -m "feat(db): OCR/AI menü analiz şemasını arşivden diril, owner_claims/is_admin() konvansiyonuna taşı"
```

---

### Task 8: Migration — apply_menu_ai_analysis_v1 (onaylanan analizi menüye uygula)

**Files:**
- Create: `supabase/migrations/20260803000006_apply_menu_ai_analysis.sql`

Arşivdeki `approve_menu_ai_analysis_v1`/`reject_menu_ai_analysis_v1` yalnızca durum değiştiriyordu, gerçekten `menu_items` satırı oluşturmuyordu. Bu RPC, owner bir AI önerisini kabul ettiğinde onu gerçek bir menü ürününe dönüştürüyor.

- [ ] **Step 1: Migration dosyasını yaz**

Create `supabase/migrations/20260803000006_apply_menu_ai_analysis.sql`:

```sql
-- Owner bir OCR/AI analiz önerisini kabul ettiğinde: gerçek bir menu_items
-- satırı oluşturur, önerilen alerjenleri owner_upsert_menu_item_allergens_v1
-- ile detected_by='ai' olarak kaydeder, kalori alanlarını calorie_source='ai'
-- ile set eder, analiz satırını 'applied' olarak işaretler.

CREATE OR REPLACE FUNCTION public.apply_menu_ai_analysis_v1(
  p_analysis_id uuid,
  p_section_id  uuid
)
RETURNS uuid
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public
AS $$
DECLARE
  v_analysis   public.menu_item_ai_analysis%rowtype;
  v_menu_id    uuid;
  v_item_id    uuid;
  v_sort_order int;
  v_allergens  jsonb;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'unauthorized' USING ERRCODE = 'P0002';
  END IF;

  SELECT * INTO v_analysis
  FROM public.menu_item_ai_analysis
  WHERE id = p_analysis_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'not_found: analiz bulunamadı' USING ERRCODE = 'P0001';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM public.owner_claims oc
    WHERE oc.business_id = v_analysis.business_id
      AND oc.user_id = auth.uid()
      AND oc.status = 'approved'
  ) THEN
    RAISE EXCEPTION 'unauthorized' USING ERRCODE = 'P0002';
  END IF;

  SELECT menu_id INTO v_menu_id
  FROM public.menu_sections
  WHERE id = p_section_id;

  IF v_menu_id IS NULL THEN
    RAISE EXCEPTION 'not_found: bölüm bulunamadı' USING ERRCODE = 'P0001';
  END IF;

  PERFORM public._check_plan_limit_v1(v_analysis.business_id, 'menu_item_count');

  SELECT count(*) INTO v_sort_order
  FROM public.menu_items
  WHERE section_id = p_section_id;

  INSERT INTO public.menu_items (
    business_id, section_id, name, is_available,
    price_cents, currency, sort_order,
    calories_min, calories_max, calorie_source
  )
  VALUES (
    v_analysis.business_id, p_section_id, v_analysis.normalized_text, true,
    0, 'TRY', v_sort_order,
    v_analysis.calorie_min, v_analysis.calorie_max,
    CASE WHEN v_analysis.calorie_min IS NOT NULL THEN 'ai' ELSE 'unknown' END
  )
  RETURNING id INTO v_item_id;

  SELECT jsonb_agg(jsonb_build_object(
    'allergen', value,
    'risk_level', 'contains',
    'detected_by', 'ai'
  ))
  INTO v_allergens
  FROM jsonb_array_elements_text(v_analysis.allergens_json);

  IF v_allergens IS NOT NULL THEN
    PERFORM public.owner_upsert_menu_item_allergens_v1(v_item_id, v_allergens);
  END IF;

  UPDATE public.menu_item_ai_analysis
  SET status = 'applied', menu_item_id = v_item_id
  WHERE id = p_analysis_id;

  RETURN v_item_id;
END;
$$;

REVOKE ALL ON FUNCTION public.apply_menu_ai_analysis_v1(uuid, uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.apply_menu_ai_analysis_v1(uuid, uuid) TO authenticated;
COMMENT ON FUNCTION public.apply_menu_ai_analysis_v1 IS
  'Owner: bir AI analiz önerisini gerçek menu_items satırına dönüştürür (alerjenler dahil, detected_by=ai). Called by: app/sahip/menu/ocr.';

-- Reddetme — sadece durum güncellemesi.
CREATE OR REPLACE FUNCTION public.reject_menu_ai_analysis_v1(
  p_analysis_id uuid
)
RETURNS void
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public
AS $$
BEGIN
  UPDATE public.menu_item_ai_analysis a
  SET status = 'rejected'
  WHERE a.id = p_analysis_id
    AND EXISTS (
      SELECT 1 FROM public.owner_claims oc
      WHERE oc.business_id = a.business_id AND oc.user_id = auth.uid() AND oc.status = 'approved'
    );

  IF NOT FOUND THEN
    RAISE EXCEPTION 'not_found: analiz bulunamadı veya yetkiniz yok' USING ERRCODE = 'P0001';
  END IF;
END;
$$;

REVOKE ALL ON FUNCTION public.reject_menu_ai_analysis_v1(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.reject_menu_ai_analysis_v1(uuid) TO authenticated;
COMMENT ON FUNCTION public.reject_menu_ai_analysis_v1 IS
  'Owner: bir AI analiz önerisini reddeder. Called by: app/sahip/menu/ocr.';
```

**Not (bir sonraki oturum için doğrulanmalı):** `owner_upsert_menu_item_allergens_v1(p_item_id, p_allergens)` imzası `menu-islemleri.ts`'deki mevcut çağrıdan (`upsertItemAllergens`, satır 195-198) çıkarıldı — parametre adları `p_item_id`/`p_allergens` olarak kullanılıyor, `PERFORM` ile pozisyonel çağrı yapıldı. Migration'ı `supabase db reset` ile uygulamadan önce bu fonksiyonun gerçek imzasını `supabase/migrations/` içinde grep ederek teyit et; parametre adları farklıysa `PERFORM public.owner_upsert_menu_item_allergens_v1(p_item_id := v_item_id, p_allergens := v_allergens)` şeklinde adlandırılmış çağrıya çevir.

- [ ] **Step 2: Lokal Supabase'i sıfırla ve doğrula**

Run: `supabase db reset`
Expected: Hatasız biter. Hata alırsan yukarıdaki nottaki imza kontrolünü yap ve düzelt.

- [ ] **Step 3: Commit**

```bash
git add supabase/migrations/20260803000006_apply_menu_ai_analysis.sql
git commit -m "feat(db): apply_menu_ai_analysis_v1 — onaylanan OCR önerisini gerçek menü ürününe dönüştür"
```

---

### Task 9: Web — OCR yükleme akışı (owner panel)

**Files:**
- Create: `uygulamalar/web/app/sahip/menu/ocr/page.tsx`
- Create: `uygulamalar/web/app/sahip/menu/ocr/ocr-islemleri.ts`
- Create: `uygulamalar/web/app/sahip/menu/ocr/ocr-istemcisi.tsx`

- [ ] **Step 1: Server Action'ları yaz**

Create `uygulamalar/web/app/sahip/menu/ocr/ocr-islemleri.ts`:

```typescript
'use server';

import { revalidatePath } from 'next/cache';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { getOwnerBusinessIds } from '@/src/lib/veri/owner/sahip-isletmeleri';

async function requireOwnedBusiness(businessId: string) {
  const supabase = await createSupabaseServerClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) return { ok: false as const, error: 'Oturum bulunamadı' };

  const ownerBusinessIds = await getOwnerBusinessIds(supabase, user.id);
  if (!ownerBusinessIds.includes(businessId)) {
    return { ok: false as const, error: 'Bu işletme için yetkiniz yok' };
  }
  return { ok: true as const, supabase };
}

export async function ocrTaramasiBaslat(
  businessId: string,
  fileUrl: string,
  fileName: string,
): Promise<{ error: string } | { jobId: string }> {
  const context = await requireOwnedBusiness(businessId);
  if (!context.ok) return { error: context.error };

  const { data, error } = await (context.supabase as any).rpc('create_menu_ocr_job_v1', {
    p_business_id: businessId,
    p_file_url: fileUrl,
    p_file_name: fileName,
  }) as { data: string | null; error: { message: string } | null };

  if (error) {
    if (error.message.includes('plan_limit_exceeded')) {
      return { error: 'Bu ay OCR tarama limitinize ulaştınız. Planınızı yükseltin.' };
    }
    return { error: error.message };
  }

  const { error: invokeError } = await context.supabase.functions.invoke('ai-menu-analyze', {
    body: { job_id: data },
  });
  if (invokeError) return { error: 'Tarama başlatılamadı: ' + invokeError.message };

  return { jobId: data as string };
}

export async function ocrTaramaDurumu(
  businessId: string,
  jobId: string,
): Promise<
  | { error: string }
  | {
      status: string;
      itemCount: number | null;
      errorMessage: string | null;
      analizler: Array<{
        id: string;
        sourceText: string;
        normalizedText: string | null;
        allergens: string[];
        calorieMin: number | null;
        calorieMax: number | null;
        confidence: number;
        status: string;
      }>;
    }
> {
  const context = await requireOwnedBusiness(businessId);
  if (!context.ok) return { error: context.error };

  const { data: jobs, error: jobError } = await (context.supabase as any).rpc('list_menu_ocr_jobs_v1', {
    p_business_id: businessId,
    p_limit: 50,
    p_offset: 0,
  }) as { data: Array<{ id: string; status: string; item_count: number | null; error_message: string | null }> | null; error: { message: string } | null };

  if (jobError) return { error: jobError.message };
  const job = (jobs ?? []).find((j) => j.id === jobId);
  if (!job) return { error: 'Tarama bulunamadı' };

  const { data: analizler, error: analizError } = await (context.supabase as any).rpc('list_menu_ai_analysis_v1', {
    p_business_id: businessId,
    p_ocr_job_id: jobId,
    p_status: 'pending_review',
    p_limit: 100,
    p_offset: 0,
  }) as {
    data: Array<{
      id: string;
      source_text: string;
      normalized_text: string | null;
      allergens_json: string[];
      calorie_min: number | null;
      calorie_max: number | null;
      confidence: number;
      status: string;
    }> | null;
    error: { message: string } | null;
  };

  if (analizError) return { error: analizError.message };

  return {
    status: job.status,
    itemCount: job.item_count,
    errorMessage: job.error_message,
    analizler: (analizler ?? []).map((a) => ({
      id: a.id,
      sourceText: a.source_text,
      normalizedText: a.normalized_text,
      allergens: a.allergens_json ?? [],
      calorieMin: a.calorie_min,
      calorieMax: a.calorie_max,
      confidence: a.confidence,
      status: a.status,
    })),
  };
}

export async function ocrOnerisiniMenuyeEkle(
  businessId: string,
  analysisId: string,
  sectionId: string,
): Promise<{ error: string } | { itemId: string }> {
  const context = await requireOwnedBusiness(businessId);
  if (!context.ok) return { error: context.error };

  const { data, error } = await (context.supabase as any).rpc('apply_menu_ai_analysis_v1', {
    p_analysis_id: analysisId,
    p_section_id: sectionId,
  }) as { data: string | null; error: { message: string } | null };

  if (error) {
    if (error.message.includes('plan_limit_exceeded')) {
      return { error: 'Ürün limitine ulaştınız. Planınızı yükseltin.' };
    }
    return { error: error.message };
  }

  revalidatePath('/sahip/menuler');
  return { itemId: data as string };
}

export async function ocrOnerisiniReddet(
  businessId: string,
  analysisId: string,
): Promise<{ error: string } | null> {
  const context = await requireOwnedBusiness(businessId);
  if (!context.ok) return { error: context.error };

  const { error } = await (context.supabase as any).rpc('reject_menu_ai_analysis_v1', {
    p_analysis_id: analysisId,
  }) as { error: { message: string } | null };

  if (error) return { error: error.message };
  return null;
}
```

- [ ] **Step 2: Sunucu sayfasını yaz**

Create `uygulamalar/web/app/sahip/menu/ocr/page.tsx`:

```typescript
import { redirect } from 'next/navigation';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { getOwnerBusinessIds } from '@/src/lib/veri/owner/sahip-isletmeleri';
import { OcrIstemcisi } from './ocr-istemcisi';

export default async function OcrSayfasi() {
  const supabase = await createSupabaseServerClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) redirect('/giris?redirect=%2Fsahip%2Fmenu%2Focr');

  const businessIds = await getOwnerBusinessIds(supabase, user.id);
  const businessId = businessIds[0];
  if (!businessId) redirect('/sahip');

  const { data: menus } = await (supabase as any)
    .from('menus')
    .select('id, title, menu_sections(id, title)')
    .eq('business_id', businessId) as {
    data: Array<{ id: string; title: string; menu_sections: Array<{ id: string; title: string }> }> | null;
  };

  const sections = (menus ?? []).flatMap((menu) =>
    menu.menu_sections.map((section) => ({
      id: section.id,
      label: `${menu.title} / ${section.title}`,
    })),
  );

  return <OcrIstemcisi businessId={businessId} sections={sections} />;
}
```

- [ ] **Step 3: İstemci bileşenini yaz**

Create `uygulamalar/web/app/sahip/menu/ocr/ocr-istemcisi.tsx`:

```typescript
'use client';

import { useState, useTransition } from 'react';
import { ocrTaramasiBaslat, ocrTaramaDurumu, ocrOnerisiniMenuyeEkle, ocrOnerisiniReddet } from './ocr-islemleri';

type Analiz = {
  id: string;
  sourceText: string;
  normalizedText: string | null;
  allergens: string[];
  calorieMin: number | null;
  calorieMax: number | null;
  confidence: number;
  status: string;
};

export function OcrIstemcisi({
  businessId,
  sections,
}: {
  businessId: string;
  sections: Array<{ id: string; label: string }>;
}) {
  const [isPending, startTransition] = useTransition();
  const [uploading, setUploading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [jobId, setJobId] = useState<string | null>(null);
  const [status, setStatus] = useState<string | null>(null);
  const [analizler, setAnalizler] = useState<Analiz[]>([]);
  const [sectionId, setSectionId] = useState(sections[0]?.id ?? '');

  async function uploadAndScan(file: File | null) {
    if (!file) return;
    setUploading(true);
    setError(null);

    try {
      const formData = new FormData();
      formData.set('businessId', businessId);
      formData.set('type', 'item');
      formData.set('file', file);

      const response = await fetch('/sunucu/medya/yukleme', { method: 'POST', body: formData });
      const payload = (await response.json().catch(() => null)) as { data?: { url?: string } } | null;
      if (!response.ok || !payload?.data?.url) throw new Error('upload_failed');

      const result = await ocrTaramasiBaslat(businessId, payload.data.url, file.name);
      if ('error' in result) {
        setError(result.error);
        return;
      }
      setJobId(result.jobId);
      await pollStatus(result.jobId);
    } catch {
      setError('Yükleme başarısız oldu.');
    } finally {
      setUploading(false);
    }
  }

  async function pollStatus(id: string) {
    const result = await ocrTaramaDurumu(businessId, id);
    if ('error' in result) {
      setError(result.error);
      return;
    }
    setStatus(result.status);
    setAnalizler(result.analizler);
    if (result.status === 'queued' || result.status === 'processing') {
      setTimeout(() => pollStatus(id), 3000);
    }
  }

  function ekle(analysisId: string) {
    if (!sectionId) {
      setError('Önce bir bölüm seçin.');
      return;
    }
    startTransition(async () => {
      const result = await ocrOnerisiniMenuyeEkle(businessId, analysisId, sectionId);
      if ('error' in result) {
        setError(result.error);
        return;
      }
      setAnalizler((prev) => prev.filter((a) => a.id !== analysisId));
    });
  }

  function reddet(analysisId: string) {
    startTransition(async () => {
      const result = await ocrOnerisiniReddet(businessId, analysisId);
      if (result?.error) {
        setError(result.error);
        return;
      }
      setAnalizler((prev) => prev.filter((a) => a.id !== analysisId));
    });
  }

  return (
    <div className="mx-auto max-w-3xl space-y-6 p-6">
      <h1 className="text-2xl font-black text-textStrong">Fotoğraftan Menü Oluştur</h1>

      <div className="rounded-2xl border border-dashed border-border bg-card p-6">
        <label className="inline-flex cursor-pointer items-center rounded-xl border border-border bg-bg px-4 py-3 text-sm font-bold text-textStrong hover:bg-white">
          {uploading ? 'Yükleniyor...' : 'Menü fotoğrafı seç'}
          <input
            type="file"
            accept="image/png,image/jpeg,image/webp"
            disabled={uploading}
            onChange={(event) => uploadAndScan(event.target.files?.[0] ?? null)}
            className="sr-only"
          />
        </label>
        {status && <p className="mt-3 text-xs font-bold text-muted">Durum: {status}</p>}
      </div>

      {error && <div className="rounded-xl bg-red-50 px-4 py-3 text-sm text-red-700">{error}</div>}

      {analizler.length > 0 && (
        <div className="space-y-3">
          <label className="text-xs font-bold text-muted">Eklenecek bölüm</label>
          <select
            value={sectionId}
            onChange={(event) => setSectionId(event.target.value)}
            className="w-full rounded-xl border border-border bg-card px-3 py-2 text-sm text-textStrong"
          >
            {sections.map((section) => (
              <option key={section.id} value={section.id}>
                {section.label}
              </option>
            ))}
          </select>

          <div className="divide-y divide-border rounded-2xl border border-border bg-card">
            {analizler.map((analiz) => (
              <div key={analiz.id} className="flex items-center justify-between gap-4 px-5 py-3">
                <div className="min-w-0 flex-1">
                  <p className="font-semibold text-textStrong">{analiz.normalizedText ?? analiz.sourceText}</p>
                  <p className="text-xs text-muted">
                    {analiz.allergens.length > 0 ? `${analiz.allergens.length} alerjen` : 'Alerjen yok'}
                    {analiz.calorieMin ? ` · ${analiz.calorieMin}-${analiz.calorieMax} kcal` : ''}
                  </p>
                </div>
                <div className="flex shrink-0 gap-2">
                  <button
                    onClick={() => ekle(analiz.id)}
                    disabled={isPending}
                    className="rounded-lg bg-primary px-3 py-1.5 text-xs font-bold text-white disabled:opacity-60"
                  >
                    Menüye Ekle
                  </button>
                  <button
                    onClick={() => reddet(analiz.id)}
                    disabled={isPending}
                    className="rounded-lg border border-border px-3 py-1.5 text-xs font-bold text-muted disabled:opacity-60"
                  >
                    Reddet
                  </button>
                </div>
              </div>
            ))}
          </div>
        </div>
      )}
    </div>
  );
}
```

- [ ] **Step 4: typecheck ve lint çalıştır**

Run: `cd uygulamalar/web && pnpm run typecheck && pnpm run lint`
Expected: İkisi de hatasız biter.

- [ ] **Step 5: Manuel doğrulama**

`pnpm run dev` ile başlat, `/sahip/menu/ocr` sayfasına git, gerçek bir menü fotoğrafı yükle. Taramanın tamamlandığını, önerilerin listelendiğini, "Menüye Ekle"nin gerçekten `/sahip/menuler` altında yeni bir ürün oluşturduğunu doğrula. `OPENROUTER_API_KEY`/`REPLICATE_API_TOKEN` lokal `.env`'de yoksa bu adım prod/staging ortamında tekrarlanmalı.

- [ ] **Step 6: Commit**

```bash
git add uygulamalar/web/app/sahip/menu/ocr/
git commit -m "feat(web): fotoğraftan menü oluşturma akışı (OCR) — owner panel"
```

---

### Task 10: Web — alerjen/kalori AI otomasyonu

**Files:**
- Create: `uygulamalar/web/app/sahip/menuler/[menuId]/duzenle/ai-doldurma-islemleri.ts`
- Modify: `uygulamalar/web/app/sahip/menuler/[menuId]/duzenle/menu-duzenleyici-istemcisi.tsx`

- [ ] **Step 1: Server Action'ı yaz**

Create `uygulamalar/web/app/sahip/menuler/[menuId]/duzenle/ai-doldurma-islemleri.ts`:

```typescript
'use server';

import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { getOwnerBusinessIds } from '@/src/lib/veri/owner/sahip-isletmeleri';

export type AiDoldurmaSonuc =
  | { error: string }
  | {
      allergens: string[];
      calorieMin: number | null;
      calorieMax: number | null;
    };

export async function aiIleAlerjenKaloriDoldur(
  businessId: string,
  itemName: string,
  description: string,
): Promise<AiDoldurmaSonuc> {
  const supabase = await createSupabaseServerClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) return { error: 'Oturum bulunamadı' };

  const ownerBusinessIds = await getOwnerBusinessIds(supabase, user.id);
  if (!ownerBusinessIds.includes(businessId)) return { error: 'Bu işletme için yetkiniz yok' };

  const { error: limitError } = await (supabase as any).rpc('_check_plan_limit_v1', {
    p_business_id: businessId,
    p_feature_key: 'allergen_ai',
  }) as { error: { message: string } | null };
  if (limitError) return { error: 'Bu özellik planınızda yok. Standart kademeye yükseltin.' };

  const [allergenRes, nutritionRes] = await Promise.all([
    supabase.functions.invoke('ai-allergen-detect', {
      body: { item_name: itemName, description },
    }),
    supabase.functions.invoke('ai-nutrition-estimate', {
      body: { item_name: itemName, description },
    }),
  ]);

  if (allergenRes.error) return { error: 'Alerjen tespiti başarısız: ' + allergenRes.error.message };
  if (nutritionRes.error) return { error: 'Kalori tahmini başarısız: ' + nutritionRes.error.message };

  const allergenData = allergenRes.data as { ok: boolean; allergens?: Array<{ allergen: string; risk: string }> };
  const nutritionData = nutritionRes.data as { ok: boolean; calorie_min?: number; calorie_max?: number };

  if (!allergenData.ok || !nutritionData.ok) {
    return { error: 'AI otomasyonu şu an kullanılamıyor.' };
  }

  return {
    allergens: (allergenData.allergens ?? []).map((entry) => entry.allergen),
    calorieMin: nutritionData.calorie_min ?? null,
    calorieMax: nutritionData.calorie_max ?? null,
  };
}
```

- [ ] **Step 2: "AI ile doldur" butonunu `ItemForm`'a ekle**

`menu-duzenleyici-istemcisi.tsx` içindeki import satırlarını (satır 1-15):

```typescript
'use client';

import Image from 'next/image';
import { useState, useTransition } from 'react';
import {
  createSection,
  updateSection,
  deleteSection,
  upsertItem,
  deleteItem,
  publishMenu,
  updateMenuTitle,
  upsertItemAllergens,
  upsertItemIngredients,
} from './menu-islemleri';
```

şununla değiştir:

```typescript
'use client';

import Image from 'next/image';
import { useRef, useState, useTransition } from 'react';
import {
  createSection,
  updateSection,
  deleteSection,
  upsertItem,
  deleteItem,
  publishMenu,
  updateMenuTitle,
  upsertItemAllergens,
  upsertItemIngredients,
} from './menu-islemleri';
import { aiIleAlerjenKaloriDoldur } from './ai-doldurma-islemleri';
```

`ItemForm` fonksiyonunun props tipine `businessId` zaten var (satır 177) — form gövdesine bir ref ve AI doldurma state'i eklemek için, mevcut state tanımlarını (satır 206-212):

```typescript
  const [isPending, startTransition] = useTransition();
  const [formError, setFormError] = useState<string | null>(null);
  const [selectedAllergens, setSelectedAllergens] = useState<Set<string>>(
    new Set(initialAllergens),
  );
  const [ingredients, setIngredients] = useState<string[]>(initialIngredients);
  const [ingredientInput, setIngredientInput] = useState('');
```

şununla değiştir:

```typescript
  const [isPending, startTransition] = useTransition();
  const [formError, setFormError] = useState<string | null>(null);
  const [selectedAllergens, setSelectedAllergens] = useState<Set<string>>(
    new Set(initialAllergens),
  );
  const [ingredients, setIngredients] = useState<string[]>(initialIngredients);
  const [ingredientInput, setIngredientInput] = useState('');
  const [aiLoading, setAiLoading] = useState(false);
  const [calorieValue, setCalorieValue] = useState(initialValues?.calories_min ?? '');
  const formRef = useRef<HTMLFormElement>(null);

  async function aiIleDoldur() {
    const nameInput = formRef.current?.elements.namedItem('name') as HTMLInputElement | null;
    const descInput = formRef.current?.elements.namedItem('description') as HTMLInputElement | null;
    const name = nameInput?.value?.trim();
    if (!name) {
      setFormError('AI doldurmadan önce ürün adını girin.');
      return;
    }
    setAiLoading(true);
    setFormError(null);
    try {
      const result = await aiIleAlerjenKaloriDoldur(businessId, name, descInput?.value ?? '');
      if ('error' in result) {
        setFormError(result.error);
        return;
      }
      setSelectedAllergens(new Set(result.allergens));
      if (result.calorieMin !== null) setCalorieValue(String(result.calorieMin));
    } finally {
      setAiLoading(false);
    }
  }
```

Form açılış etiketini (satır 265: `<form className="p-4 flex flex-col gap-3" onSubmit={handleSubmit}>`) şununla değiştir:

```typescript
    <form ref={formRef} className="p-4 flex flex-col gap-3" onSubmit={handleSubmit}>
```

Kalori input'unu (satır 309-320):

```typescript
        {/* Kalori */}
        <div className="flex flex-col gap-1">
          <label className="text-xs font-bold text-muted">Enerji Değeri (kcal)</label>
          <input
            name="calories"
            type="number"
            defaultValue={initialValues?.calories_min ?? ''}
            min="0"
            max="9999"
            placeholder="örn: 450"
            className="rounded-xl border border-border bg-card px-3 py-2 text-sm text-textStrong placeholder:text-muted focus:outline-hidden focus:ring-2 focus:ring-primary/30"
          />
        </div>
```

şununla değiştir:

```typescript
        {/* Kalori */}
        <div className="flex flex-col gap-1">
          <label className="text-xs font-bold text-muted">Enerji Değeri (kcal)</label>
          <input
            name="calories"
            type="number"
            value={calorieValue}
            onChange={(e) => setCalorieValue(e.target.value)}
            min="0"
            max="9999"
            placeholder="örn: 450"
            className="rounded-xl border border-border bg-card px-3 py-2 text-sm text-textStrong placeholder:text-muted focus:outline-hidden focus:ring-2 focus:ring-primary/30"
          />
        </div>
```

Alerjen bölümü başlığının hemen üstüne (satır 399'dan hemen önce), "AI ile doldur" butonunu ekle — mevcut:

```typescript
      {/* Allerjen seçici */}
      <div className="flex flex-col gap-2">
        <p className="text-xs font-bold text-muted">Alerjenler (Tarım Bakanlığı zorunlu)</p>
```

şununla değiştir:

```typescript
      <button
        type="button"
        onClick={aiIleDoldur}
        disabled={aiLoading}
        className="self-start rounded-xl border border-primary/30 bg-primary/5 px-3 py-2 text-xs font-bold text-primary hover:bg-primary/10 disabled:opacity-60 cursor-pointer"
      >
        {aiLoading ? 'AI çalışıyor...' : '✨ AI ile alerjen ve kaloriyi doldur'}
      </button>

      {/* Allerjen seçici */}
      <div className="flex flex-col gap-2">
        <p className="text-xs font-bold text-muted">Alerjenler (Tarım Bakanlığı zorunlu)</p>
```

- [ ] **Step 3: typecheck ve lint çalıştır**

Run: `cd uygulamalar/web && pnpm run typecheck && pnpm run lint`
Expected: İkisi de hatasız biter.

- [ ] **Step 4: Manuel doğrulama**

`pnpm run dev`, `/sahip/menuler/[menuId]/duzenle` sayfasında bir ürün adı gir, "AI ile alerjen ve kaloriyi doldur"a bas. Free/Starter planda "Bu özellik planınızda yok" hatası, Standard+ planda alerjenlerin otomatik seçildiğini ve kalori alanının dolduğunu doğrula.

- [ ] **Step 5: Commit**

```bash
git add uygulamalar/web/app/sahip/menuler/\[menuId\]/duzenle/ai-doldurma-islemleri.ts uygulamalar/web/app/sahip/menuler/\[menuId\]/duzenle/menu-duzenleyici-istemcisi.tsx
git commit -m "feat(web): AI ile alerjen/kalori otomasyonu (Standard+ plan)"
```

---

### Task 11: Web — AI görsel üretme

**Files:**
- Modify: `uygulamalar/web/app/sahip/menuler/[menuId]/duzenle/ai-doldurma-islemleri.ts`
- Modify: `uygulamalar/web/app/sahip/menuler/[menuId]/duzenle/menu-duzenleyici-istemcisi.tsx`

- [ ] **Step 1: Server Action ekle**

`ai-doldurma-islemleri.ts` dosyasının sonuna ekle:

```typescript

export async function aiIleGorselUret(
  businessId: string,
  itemName: string,
): Promise<{ error: string } | { imageUrl: string }> {
  const supabase = await createSupabaseServerClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) return { error: 'Oturum bulunamadı' };

  const ownerBusinessIds = await getOwnerBusinessIds(supabase, user.id);
  if (!ownerBusinessIds.includes(businessId)) return { error: 'Bu işletme için yetkiniz yok' };

  const { error: limitError } = await (supabase as any).rpc('_check_plan_limit_v1', {
    p_business_id: businessId,
    p_feature_key: 'ai_image_gen',
  }) as { error: { message: string } | null };
  if (limitError) return { error: 'Bu özellik yalnızca Pro kademede var.' };

  const { data, error } = await supabase.functions.invoke('ai-menu-image-gen', {
    body: { item_name: itemName },
  });
  if (error) return { error: 'Görsel üretilemedi: ' + error.message };

  const payload = data as { ok: boolean; image_url?: string };
  if (!payload.ok || !payload.image_url) return { error: 'Görsel üretilemedi.' };

  return { imageUrl: payload.image_url };
}
```

- [ ] **Step 2: `ImageUrlField`'a "AI ile görsel oluştur" butonu ekle**

`menu-duzenleyici-istemcisi.tsx` içindeki import satırını güncelle — Task 10'da eklenen satırı:

```typescript
import { aiIleAlerjenKaloriDoldur } from './ai-doldurma-islemleri';
```

şununla değiştir:

```typescript
import { aiIleAlerjenKaloriDoldur, aiIleGorselUret } from './ai-doldurma-islemleri';
```

`ImageUrlField` bileşeninin prop tipine `itemName` ekle — mevcut (satır 84-92):

```typescript
function ImageUrlField({
  businessId,
  label,
  initialUrl = null,
}: {
  businessId: string;
  label: string;
  initialUrl?: string | null;
}) {
```

şununla değiştir:

```typescript
function ImageUrlField({
  businessId,
  label,
  initialUrl = null,
  itemNameRef,
}: {
  businessId: string;
  label: string;
  initialUrl?: string | null;
  itemNameRef: React.RefObject<HTMLFormElement | null>;
}) {
```

`ImageUrlField` gövdesinde, `upload` fonksiyonundan sonra (satır 126'dan sonra, `return` öncesi) yeni bir fonksiyon ekle:

```typescript

  const [aiGenerating, setAiGenerating] = useState(false);

  async function generateWithAi() {
    const nameInput = itemNameRef.current?.elements.namedItem('name') as HTMLInputElement | null;
    const name = nameInput?.value?.trim();
    if (!name) {
      setUploadError('Görsel oluşturmadan önce ürün adını girin.');
      return;
    }
    setAiGenerating(true);
    setUploadError(null);
    try {
      const result = await aiIleGorselUret(businessId, name);
      if ('error' in result) {
        setUploadError(result.error);
        return;
      }
      setUrl(result.imageUrl);
    } finally {
      setAiGenerating(false);
    }
  }
```

Buton grubuna (satır 147-168 civarı, "Bilgisayardan seç" etiketinin yanına) yeni buton ekle — mevcut:

```typescript
        <div className="flex flex-wrap items-center gap-2">
          <label className="inline-flex min-h-10 cursor-pointer items-center rounded-xl border border-border bg-card px-3 py-2 text-xs font-extrabold text-textStrong hover:bg-white">
            {uploading ? 'Yükleniyor...' : 'Bilgisayardan seç'}
```

şununla değiştir:

```typescript
        <div className="flex flex-wrap items-center gap-2">
          <button
            type="button"
            onClick={generateWithAi}
            disabled={aiGenerating}
            className="inline-flex min-h-10 items-center rounded-xl border border-primary/30 bg-primary/5 px-3 py-2 text-xs font-extrabold text-primary hover:bg-primary/10 disabled:opacity-60 cursor-pointer"
          >
            {aiGenerating ? 'AI çalışıyor...' : '✨ AI ile görsel oluştur'}
          </button>
          <label className="inline-flex min-h-10 cursor-pointer items-center rounded-xl border border-border bg-card px-3 py-2 text-xs font-extrabold text-textStrong hover:bg-white">
            {uploading ? 'Yükleniyor...' : 'Bilgisayardan seç'}
```

`ItemForm` içinde `ImageUrlField`'ı çağıran satırı (satır 289-293):

```typescript
      <ImageUrlField
        businessId={businessId}
        label="Ürün görseli"
        initialUrl={initialValues?.image_url ?? null}
      />
```

şununla değiştir (Task 10'da eklenen `formRef` yeniden kullanılıyor):

```typescript
      <ImageUrlField
        businessId={businessId}
        label="Ürün görseli"
        initialUrl={initialValues?.image_url ?? null}
        itemNameRef={formRef}
      />
```

- [ ] **Step 3: typecheck ve lint çalıştır**

Run: `cd uygulamalar/web && pnpm run typecheck && pnpm run lint`
Expected: İkisi de hatasız biter. (`useState` importu `ImageUrlField` içinde zaten mevcut — dosyanın en üstünde `useState` import edilmiş durumda, ek import gerekmez.)

- [ ] **Step 4: Manuel doğrulama**

Pro plana atanmış bir işletmeyle ürün adı girip "AI ile görsel oluştur"a bas, üretilen görselin önizlemede göründüğünü doğrula. Free/Starter/Standard planda "Bu özellik yalnızca Pro kademede var" hatasını doğrula.

- [ ] **Step 5: Commit**

```bash
git add uygulamalar/web/app/sahip/menuler/\[menuId\]/duzenle/ai-doldurma-islemleri.ts uygulamalar/web/app/sahip/menuler/\[menuId\]/duzenle/menu-duzenleyici-istemcisi.tsx
git commit -m "feat(web): AI ile ürün görseli üretme (Pro plan)"
```

---

### Task 12: Migration — çoklu dil plan limiti

**Files:**
- Create: `supabase/migrations/20260803000007_translation_language_limit.sql`

- [ ] **Step 1: Migration dosyasını yaz**

`upsert_menu_item_translation_v1`'i, mevcut `business_claims` ownership deseniyle (fonksiyonun zaten kullandığı, değiştirilmiyor) genişletiyoruz. Yeni bir dil eklerken (bu işletme için bu locale'de daha önce hiç çeviri yoksa) plan limitini kontrol ediyoruz; var olan bir dile güncelleme her zaman serbest.

Create `supabase/migrations/20260803000007_translation_language_limit.sql`:

```sql
-- upsert_menu_item_translation_v1'e plan bazlı dil sayısı limiti ekle.
-- (Önceki tanım: supabase/migrations/20260424000004_menu_item_translation_rpc.sql)

CREATE OR REPLACE FUNCTION public.upsert_menu_item_translation_v1(
  p_item_id     uuid,
  p_locale      text,
  p_name        text,
  p_description text DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  _business_id uuid;
  _row menu_translations%rowtype;
  _locale_exists boolean;
  _used_locales int;
  _limit int;
  _tier text;
BEGIN
  SELECT b.id INTO _business_id
  FROM business_claims bc
  JOIN businesses b ON b.id = bc.business_id
  JOIN menus m ON m.business_id = b.id
  JOIN menu_sections ms ON ms.menu_id = m.id
  JOIN menu_items mi ON mi.section_id = ms.id
  WHERE mi.id = p_item_id
    AND bc.user_id = auth.uid()
    AND bc.is_active = true
  LIMIT 1;

  IF _business_id IS NULL THEN
    RAISE EXCEPTION 'unauthorized';
  END IF;

  -- Bu item için bu locale'de zaten bir çeviri var mı? Varsa güncelleme serbest.
  SELECT EXISTS (
    SELECT 1 FROM menu_translations
    WHERE entity_type = 'item' AND entity_id = p_item_id AND locale = p_locale
  ) INTO _locale_exists;

  IF NOT _locale_exists THEN
    _tier := public._get_business_plan_tier_v1(_business_id);

    SELECT limit_value INTO _limit
    FROM public.plan_features
    WHERE plan_tier = _tier AND feature_key = 'language_count';

    IF _limit IS NOT NULL THEN
      SELECT 1 + count(DISTINCT mt.locale) INTO _used_locales
      FROM menu_translations mt
      JOIN menu_items mi2 ON mi2.id = mt.entity_id AND mt.entity_type = 'item'
      WHERE mi2.business_id = _business_id;

      IF _used_locales >= _limit THEN
        RAISE EXCEPTION 'plan_limit_exceeded: language_count' USING ERRCODE = 'P0003';
      END IF;
    END IF;
  END IF;

  INSERT INTO menu_translations (entity_type, entity_id, locale, name, description)
  VALUES ('item', p_item_id, p_locale, p_name, p_description)
  ON CONFLICT (entity_id, locale)
    WHERE entity_type = 'item'
  DO UPDATE SET
    name        = excluded.name,
    description = excluded.description;

  SELECT * INTO _row
  FROM menu_translations
  WHERE entity_type = 'item'
    AND entity_id = p_item_id
    AND locale = p_locale;

  RETURN jsonb_build_object(
    'id',          _row.id,
    'locale',      _row.locale,
    'name',        _row.name,
    'description', _row.description
  );
END;
$$;
```

- [ ] **Step 2: Lokal Supabase'i sıfırla ve doğrula**

Run: `supabase db reset`

Free planda (varsayılan, `language_count` limiti 1) bir işletme için `en` locale'inde çeviri eklemeyi dene:
```bash
supabase db execute --sql "select public.upsert_menu_item_translation_v1('<item_id>'::uuid, 'en', 'Test', null)"
```
Expected: `plan_limit_exceeded: language_count` hatası (çünkü free planda TR dışında 0 ek dil hakkı var — `_used_locales` = 1 (TR) zaten `_limit` = 1'e eşit).

- [ ] **Step 3: Commit**

```bash
git add supabase/migrations/20260803000007_translation_language_limit.sql
git commit -m "feat(db): upsert_menu_item_translation_v1'e plan bazlı dil sayısı limiti ekle"
```

---

### Task 13: Web — çeviriler sayfasında dil limiti mesajı

**Files:**
- Modify: `uygulamalar/web/app/sahip/menu/ceviriler/ceviri-islemleri.ts`

- [ ] **Step 1: `menuCevirisiniKaydet`'te plan limiti hatasını Türkçeleştir**

Mevcut (satır 156-166):

```typescript
  const { error } = await (supabase as any).rpc('upsert_menu_item_translation_v1', {
    p_item_id: itemId,
    p_locale: locale,
    p_name: trimmedName,
    p_description: description.trim() || null,
  });

  if (error) {
    logger.warn('upsert_menu_item_translation_v1 failed', { itemId, locale, error });
    return { success: false, hata: error.message };
  }
```

şununla değiştir:

```typescript
  const { error } = await (supabase as any).rpc('upsert_menu_item_translation_v1', {
    p_item_id: itemId,
    p_locale: locale,
    p_name: trimmedName,
    p_description: description.trim() || null,
  });

  if (error) {
    logger.warn('upsert_menu_item_translation_v1 failed', { itemId, locale, error });
    if (error.message.includes('plan_limit_exceeded')) {
      return { success: false, hata: 'Bu dil planınızda yok. Daha fazla dil eklemek için planınızı yükseltin.' };
    }
    return { success: false, hata: error.message };
  }
```

- [ ] **Step 2: typecheck ve lint çalıştır**

Run: `cd uygulamalar/web && pnpm run typecheck && pnpm run lint`
Expected: İkisi de hatasız biter.

- [ ] **Step 3: Manuel doğrulama**

Free/Starter planlı bir işletmeyle `/sahip/menu/ceviriler` sayfasında `en` çevirisi eklemeyi dene, Türkçe hata mesajını doğrula. Standard plana yükselttikten sonra çalıştığını doğrula.

- [ ] **Step 4: Commit**

```bash
git add uygulamalar/web/app/sahip/menu/ceviriler/ceviri-islemleri.ts
git commit -m "feat(web): çeviri kaydetme akışında plan dil limiti hatasını Türkçeleştir"
```

---

### Task 14: Web — QR filigranı

**Files:**
- Modify: `uygulamalar/web/app/karekod/[businessId]/page.tsx`
- Modify: `uygulamalar/web/src/ui/bolumler/karekod-uretici.tsx`

- [ ] **Step 1: `page.tsx`'te plan kademesini çek ve prop olarak geçir**

Mevcut importları (satır 1-13):

```typescript
import type { Metadata } from 'next';
import Link from 'next/link';
import { notFound, redirect } from 'next/navigation';
import { KarekodUreticiIstemcisi } from '@/src/ui/bolumler/karekod-uretici';
import { getBrandThemeDefinition, getBrandThemeOptions } from '@/src/lib/marka-temasi';
import { getPublicMenuPageData, getTranslationValue } from '@/src/lib/acik-menu-sayfasi';
import { appConfig } from '@/src/lib/ayarlar';
import { getImageBlurDataUrl } from '@/src/lib/gorsel-yer-tutucu';
import { copy } from '@/src/lib/ceviri';
import { encodeBusinessCode } from '@/src/lib/kisa-kod';
import { getQrAccessState } from '@/src/lib/karekod-erisimi';
import { buildMenuHref, buildQrHref, buildShortHref } from '@/src/lib/menu-baglantilari';
import { isUuid, normalizeDisplayParams } from '@/src/lib/yol-normalizasyonu';
```

şununla değiştir:

```typescript
import type { Metadata } from 'next';
import Link from 'next/link';
import { notFound, redirect } from 'next/navigation';
import { KarekodUreticiIstemcisi } from '@/src/ui/bolumler/karekod-uretici';
import { getBrandThemeDefinition, getBrandThemeOptions } from '@/src/lib/marka-temasi';
import { getPublicMenuPageData, getTranslationValue } from '@/src/lib/acik-menu-sayfasi';
import { appConfig } from '@/src/lib/ayarlar';
import { getImageBlurDataUrl } from '@/src/lib/gorsel-yer-tutucu';
import { copy } from '@/src/lib/ceviri';
import { encodeBusinessCode } from '@/src/lib/kisa-kod';
import { getQrAccessState } from '@/src/lib/karekod-erisimi';
import { buildMenuHref, buildQrHref, buildShortHref } from '@/src/lib/menu-baglantilari';
import { isUuid, normalizeDisplayParams } from '@/src/lib/yol-normalizasyonu';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
```

`QrPage` fonksiyonu içinde, `access.canManage` kontrolünden sonra (satır 84-86'dan hemen sonra) plan kademesini çek — mevcut:

```typescript
  if (!access.canManage) {
    redirect(`/yasakli?from=${encodeURIComponent(redirectTo)}`);
  }

  if (normalized.hasInvalidParams) {
```

şununla değiştir:

```typescript
  if (!access.canManage) {
    redirect(`/yasakli?from=${encodeURIComponent(redirectTo)}`);
  }

  const supabase = await createSupabaseServerClient();
  const { data: planData } = await (supabase as any).rpc('get_my_plan_v1', {
    p_business_id: businessId,
  }) as { data: { plan_tier: string; features: Array<{ feature_key: string; enabled: boolean }> } | null };
  const showQrWatermark = planData?.features.find((f) => f.feature_key === 'qr_watermark')?.enabled ?? true;

  if (normalized.hasInvalidParams) {
```

`KarekodUreticiIstemcisi`'ni çağıran bloğu (satır 154-169):

```typescript
      <KarekodUreticiIstemcisi
        lang={language}
        baseCopy={copy[language]}
        themeCatalog={themeCatalog}
        themeOptions={themeOptions}
        blurDataUrlByTheme={blurDataUrlByTheme}
        businessId={businessId}
        businessSlug={data.business.slug}
        businessPublicSlug={data.business.public_slug}
        businessName={businessName}
        logoUrl={data.media.logoUrl}
        canonicalUrl={canonicalUrl}
        shortUrl={shortUrl}
        initialPresentation={data.presentation}
        mediaOptions={mediaOptions}
      />
```

şununla değiştir:

```typescript
      <KarekodUreticiIstemcisi
        lang={language}
        baseCopy={copy[language]}
        themeCatalog={themeCatalog}
        themeOptions={themeOptions}
        blurDataUrlByTheme={blurDataUrlByTheme}
        businessId={businessId}
        businessSlug={data.business.slug}
        businessPublicSlug={data.business.public_slug}
        businessName={businessName}
        logoUrl={data.media.logoUrl}
        canonicalUrl={canonicalUrl}
        shortUrl={shortUrl}
        initialPresentation={data.presentation}
        mediaOptions={mediaOptions}
        showQrWatermark={showQrWatermark}
      />
```

- [ ] **Step 2: `karekod-uretici.tsx`'te filigranı QR SVG/PNG üretimine ekle**

`Props` tipine `showQrWatermark` ekle — mevcut (satır 21-42):

```typescript
type Props = {
  lang: AppLang;
  baseCopy: MenuCopy;
  themeCatalog: Record<BrandTheme, BrandThemeDefinition>;
  themeOptions: Array<{
    id: BrandTheme;
    label: string;
    description: string;
    previewBackground: string;
    previewAccent: string;
  }>;
  blurDataUrlByTheme: Record<BrandTheme, string>;
  businessId: string;
  businessSlug?: string | null;
  businessPublicSlug?: string | null;
  businessName: string;
  logoUrl: string | null;
  canonicalUrl: string;
  shortUrl: string;
  initialPresentation: ResolvedPresentationRecord;
  mediaOptions: MediaOption[];
};
```

şununla değiştir:

```typescript
type Props = {
  lang: AppLang;
  baseCopy: MenuCopy;
  themeCatalog: Record<BrandTheme, BrandThemeDefinition>;
  themeOptions: Array<{
    id: BrandTheme;
    label: string;
    description: string;
    previewBackground: string;
    previewAccent: string;
  }>;
  blurDataUrlByTheme: Record<BrandTheme, string>;
  businessId: string;
  businessSlug?: string | null;
  businessPublicSlug?: string | null;
  businessName: string;
  logoUrl: string | null;
  canonicalUrl: string;
  shortUrl: string;
  initialPresentation: ResolvedPresentationRecord;
  mediaOptions: MediaOption[];
  showQrWatermark: boolean;
};
```

`KarekodUreticiIstemcisi` fonksiyon imzasına `showQrWatermark` ekle — mevcut (satır 193-208):

```typescript
export function KarekodUreticiIstemcisi({
  lang,
  baseCopy,
  themeCatalog,
  themeOptions,
  blurDataUrlByTheme,
  businessId,
  businessSlug,
  businessPublicSlug,
  businessName,
  logoUrl,
  canonicalUrl,
  shortUrl,
  initialPresentation,
  mediaOptions,
}: Props) {
```

şununla değiştir:

```typescript
export function KarekodUreticiIstemcisi({
  lang,
  baseCopy,
  themeCatalog,
  themeOptions,
  blurDataUrlByTheme,
  businessId,
  businessSlug,
  businessPublicSlug,
  businessName,
  logoUrl,
  canonicalUrl,
  shortUrl,
  initialPresentation,
  mediaOptions,
  showQrWatermark,
}: Props) {
```

`generateQr` fonksiyonunun içinde, SVG'ye filigran metni eklemek için mevcut bloğu (satır 283-309):

```typescript
    async function generateQr() {
      const qrCode = await import('qrcode');
      const [svg, png] = await Promise.all([
        qrCode.toString(qrTarget, {
          errorCorrectionLevel: 'H',
          margin: 1,
          type: 'svg',
          color: {
            dark: themeDefinition.brandQrDark,
            light: '#ffffff',
          },
        }),
        qrCode.toDataURL(qrTarget, {
          errorCorrectionLevel: 'H',
          margin: 1,
          width: 1280,
          color: {
            dark: themeDefinition.brandQrDark,
            light: '#ffffff',
          },
        }),
      ]);

      if (!alive) return;
      setQrSvg(svg);
      setQrPng(png);
    }
```

şununla değiştir:

```typescript
    async function generateQr() {
      const qrCode = await import('qrcode');
      const [svg, png] = await Promise.all([
        qrCode.toString(qrTarget, {
          errorCorrectionLevel: 'H',
          margin: 1,
          type: 'svg',
          color: {
            dark: themeDefinition.brandQrDark,
            light: '#ffffff',
          },
        }),
        qrCode.toDataURL(qrTarget, {
          errorCorrectionLevel: 'H',
          margin: 1,
          width: 1280,
          color: {
            dark: themeDefinition.brandQrDark,
            light: '#ffffff',
          },
        }),
      ]);

      if (!alive) return;
      setQrSvg(showQrWatermark ? addSvgWatermark(svg) : svg);
      setQrPng(showQrWatermark ? await addPngWatermark(png) : png);
    }
```

Dosyanın en sonuna (`serializeDraft` fonksiyonundan sonra) filigran yardımcı fonksiyonlarını ekle:

```typescript

function addSvgWatermark(svg: string): string {
  const label = '<text x="50%" y="98%" text-anchor="middle" font-family="system-ui,sans-serif" font-size="14" fill="#7F1D1D" opacity="0.55">yeedoy.com ile oluşturuldu</text>';
  return svg.replace('</svg>', `${label}</svg>`);
}

async function addPngWatermark(dataUrl: string): Promise<string> {
  const image = new Image();
  const loaded = new Promise<void>((resolve, reject) => {
    image.onload = () => resolve();
    image.onerror = () => reject(new Error('watermark_image_load_failed'));
  });
  image.src = dataUrl;
  await loaded;

  const canvas = document.createElement('canvas');
  canvas.width = image.width;
  canvas.height = image.height;
  const ctx = canvas.getContext('2d');
  if (!ctx) return dataUrl;

  ctx.drawImage(image, 0, 0);
  ctx.font = `${Math.round(image.width / 26)}px system-ui, sans-serif`;
  ctx.fillStyle = 'rgba(127, 29, 29, 0.55)';
  ctx.textAlign = 'center';
  ctx.fillText('yeedoy.com ile oluşturuldu', canvas.width / 2, canvas.height - 24);

  return canvas.toDataURL('image/png');
}
```

- [ ] **Step 3: typecheck ve lint çalıştır**

Run: `cd uygulamalar/web && pnpm run typecheck && pnpm run lint`
Expected: İkisi de hatasız biter.

- [ ] **Step 4: Manuel doğrulama**

Free planlı bir işletmeyle `/karekod/[businessId]` sayfasını aç, hem SVG önizlemesinde hem indirilen PNG'de "yeedoy.com ile oluşturuldu" filigranının göründüğünü doğrula. Starter+ planında filigran olmadığını doğrula.

- [ ] **Step 5: Commit**

```bash
git add "uygulamalar/web/app/karekod/[businessId]/page.tsx" uygulamalar/web/src/ui/bolumler/karekod-uretici.tsx
git commit -m "feat(web): Free kademede QR koduna filigran ekle"
```

---

### Task 15: Migration — harita önceliklendirme (sponsorships entegrasyonu)

**Files:**
- Create: `supabase/migrations/20260803000008_plan_sponsorship_boost.sql`

- [ ] **Step 1: Migration dosyasını yaz**

Standard/Pro plan ataması, işletmeye otomatik olarak `surface='discovery'` bir `sponsorships` kaydı verir (var olan "Yeedoy Vitrin" ticari paketinden ayrı, planla gelen bir "dahili" paket). `search_nearby_businesses_v3` bu kayda göre öne çıkarır. Bu değişiklik hem web hem mobil keşif sonuçlarını etkiler (kullanıcı onayladı).

Create `supabase/migrations/20260803000008_plan_sponsorship_boost.sql`:

```sql
-- Plan-dahil harita önceliklendirmesi: mevcut sponsorships/sponsorship_packages
-- tablolarına bağlanıyor (paralel bir mekanizma kurulmuyor).

-- Standard/Pro planla gelen, ticari "Yeedoy Vitrin" paketinden ayrı, envanter
-- limiti olmayan dahili bir paket.
INSERT INTO public.sponsorship_packages (name, surface, duration_days, price_display, is_active, price_cents, currency_code, inventory_limit)
VALUES ('Plan Dahili Öncelik', 'discovery', 36500, 'Plana dahil', true, 0, 'TRY', 2147483647)
ON CONFLICT DO NOTHING;

CREATE OR REPLACE FUNCTION public._sync_plan_sponsorship_v1(
  p_business_id uuid,
  p_plan_tier   text,
  p_ends_at     timestamptz
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_package_id uuid;
  v_boost_enabled boolean;
BEGIN
  -- Önce bu işletmenin plan-kaynaklı mevcut discovery sponsorluğunu sonlandır.
  UPDATE public.sponsorships
  SET status = 'ended', updated_at = now()
  WHERE business_id = p_business_id
    AND surface = 'discovery'
    AND source = 'plan_grant'
    AND status = 'active';

  SELECT enabled INTO v_boost_enabled
  FROM public.plan_features
  WHERE plan_tier = p_plan_tier AND feature_key = 'map_boost';

  IF coalesce(v_boost_enabled, false) THEN
    SELECT id INTO v_package_id
    FROM public.sponsorship_packages
    WHERE name = 'Plan Dahili Öncelik' AND surface = 'discovery'
    LIMIT 1;

    INSERT INTO public.sponsorships (
      business_id, package_id, surface, status, starts_at, ends_at, source
    )
    VALUES (
      p_business_id, v_package_id, 'discovery', 'active', now(), p_ends_at, 'plan_grant'
    );
  END IF;
END;
$$;

COMMENT ON FUNCTION public._sync_plan_sponsorship_v1 IS
  'İşletmenin plan kademesi değiştiğinde discovery sponsorluğunu senkronize eder. Called by: admin_set_business_plan_v1.';

-- admin_set_business_plan_v1'i, plan değiştiğinde sponsorluğu senkronize edecek şekilde genişlet.
CREATE OR REPLACE FUNCTION public.admin_set_business_plan_v1(
  p_business_id uuid,
  p_plan_tier   text,
  p_ends_at     timestamptz DEFAULT NULL
)
RETURNS jsonb
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

  IF p_plan_tier NOT IN ('free','starter','standard','pro') THEN
    RAISE EXCEPTION 'validation_error: geçersiz plan_tier' USING ERRCODE = 'P0003';
  END IF;

  UPDATE public.business_premium
  SET status = 'ended', ends_at = now()
  WHERE business_id = p_business_id
    AND status = 'active'
    AND tier IN ('starter','standard','pro');

  IF p_plan_tier <> 'free' THEN
    INSERT INTO public.business_premium (business_id, tier, status, starts_at, ends_at, source, created_by)
    VALUES (p_business_id, p_plan_tier, 'active', now(), p_ends_at, 'manual', auth.uid())
    RETURNING id INTO v_id;
  END IF;

  PERFORM public._sync_plan_sponsorship_v1(p_business_id, p_plan_tier, p_ends_at);

  PERFORM public.insert_audit_log_v1(
    'business.plan_changed',
    'business',
    p_business_id,
    '{}'::jsonb,
    jsonb_build_object('plan_tier', p_plan_tier, 'premium_id', v_id)
  );

  RETURN jsonb_build_object('ok', true, 'business_id', p_business_id, 'plan_tier', p_plan_tier, 'premium_id', v_id);
END;
$$;

-- search_nearby_businesses_v3: sponsorlu (discovery, aktif) işletmeleri öne al.
-- (Önceki tanım: supabase/migrations/20260615000004_search_nearby_price_open.sql)
DROP FUNCTION IF EXISTS public.search_nearby_businesses_v3(
  double precision, double precision, integer, text, text, boolean, integer
);

CREATE OR REPLACE FUNCTION public.search_nearby_businesses_v3(
  p_lat double precision,
  p_lng double precision,
  p_radius_km integer DEFAULT 5,
  p_query text DEFAULT NULL::text,
  p_category text DEFAULT NULL::text,
  p_open_now boolean DEFAULT false,
  p_limit integer DEFAULT 30
)
RETURNS TABLE(
  id uuid,
  name text,
  category text,
  city text,
  district text,
  address text,
  lat double precision,
  lng double precision,
  distance_km double precision,
  quality_score integer,
  median_price_cents integer,
  is_open_now boolean
)
LANGUAGE sql
STABLE SECURITY DEFINER
SET search_path TO 'public'
AS $function$
  WITH base AS (
    SELECT
      b.*,
      (6371.0 * 2.0 * asin(
        sqrt(
          power(sin(radians((b.lat - p_lat) / 2.0)), 2)
          + cos(radians(p_lat)) * cos(radians(b.lat))
          * power(sin(radians((b.lng - p_lng) / 2.0)), 2)
        )
      )) AS distance_km,
      (
        0
        + CASE WHEN b.phone IS NOT NULL AND length(b.phone) >= 7 THEN 1 ELSE 0 END
        + CASE WHEN b.address IS NOT NULL AND length(b.address) >= 6 THEN 1 ELSE 0 END
        + CASE WHEN length(b.name) >= 6 THEN 1 ELSE 0 END
        + CASE WHEN lower(b.name) IN ('restaurant','cafe','bar','pub','mekan','lokanta') THEN -3 ELSE 2 END
      ) AS quality_score,
      (
        SELECT percentile_disc(0.5) WITHIN GROUP (ORDER BY mi.price_cents)
        FROM public.menu_items mi
        WHERE mi.business_id = b.id
          AND mi.price_cents IS NOT NULL
          AND mi.price_cents > 0
      )::int AS median_price_cents,
      CASE
        WHEN h.business_id IS NULL THEN NULL
        ELSE (
          CASE extract(dow FROM now())
            WHEN 1 THEN (h.mon_open IS NOT NULL AND current_time BETWEEN h.mon_open AND h.mon_close)
            WHEN 2 THEN (h.tue_open IS NOT NULL AND current_time BETWEEN h.tue_open AND h.tue_close)
            WHEN 3 THEN (h.wed_open IS NOT NULL AND current_time BETWEEN h.wed_open AND h.wed_close)
            WHEN 4 THEN (h.thu_open IS NOT NULL AND current_time BETWEEN h.thu_open AND h.thu_close)
            WHEN 5 THEN (h.fri_open IS NOT NULL AND current_time BETWEEN h.fri_open AND h.fri_close)
            WHEN 6 THEN (h.sat_open IS NOT NULL AND current_time BETWEEN h.sat_open AND h.sat_close)
            WHEN 0 THEN (h.sun_open IS NOT NULL AND current_time BETWEEN h.sun_open AND h.sun_close)
          END
        )
      END AS is_open_now,
      EXISTS (
        SELECT 1 FROM public.sponsorships s
        WHERE s.business_id = b.id
          AND s.surface = 'discovery'
          AND s.status = 'active'
          AND (s.starts_at IS NULL OR s.starts_at <= now())
          AND (s.ends_at IS NULL OR s.ends_at >= now())
      ) AS is_boosted
    FROM public.businesses b
    LEFT JOIN public.business_hours h ON h.business_id = b.id
    WHERE b.is_active = true
      AND b.lat IS NOT NULL
      AND b.lng IS NOT NULL
      AND (p_category IS NULL OR p_category = '' OR b.category = p_category)
      AND (
        p_query IS NULL
        OR p_query = ''
        OR b.name ILIKE ('%' || p_query || '%')
        OR coalesce(b.address,'') ILIKE ('%' || p_query || '%')
      )
      AND (
        p_open_now = false
        OR (
          h.business_id IS NOT NULL
          AND (
            CASE extract(dow FROM now())
              WHEN 1 THEN (h.mon_open IS NOT NULL AND current_time BETWEEN h.mon_open AND h.mon_close)
              WHEN 2 THEN (h.tue_open IS NOT NULL AND current_time BETWEEN h.tue_open AND h.tue_close)
              WHEN 3 THEN (h.wed_open IS NOT NULL AND current_time BETWEEN h.wed_open AND h.wed_close)
              WHEN 4 THEN (h.thu_open IS NOT NULL AND current_time BETWEEN h.thu_open AND h.thu_close)
              WHEN 5 THEN (h.fri_open IS NOT NULL AND current_time BETWEEN h.fri_open AND h.fri_close)
              WHEN 6 THEN (h.sat_open IS NOT NULL AND current_time BETWEEN h.sat_open AND h.sat_close)
              WHEN 0 THEN (h.sun_open IS NOT NULL AND current_time BETWEEN h.sun_open AND h.sun_close)
            END
          )
        )
      )
  )
  SELECT
    id, name, category, city, district, address, lat, lng,
    distance_km,
    quality_score,
    median_price_cents,
    is_open_now
  FROM base
  WHERE distance_km <= greatest(1, p_radius_km)::double precision
  ORDER BY is_boosted DESC, quality_score DESC, distance_km ASC
  LIMIT p_limit;
$function$;
```

- [ ] **Step 2: Lokal Supabase'i sıfırla ve doğrula**

Run: `supabase db reset`

Bir test işletmesini standard plana atayıp sponsorluk kaydının oluştuğunu doğrula:
```bash
supabase db execute --sql "select public.admin_set_business_plan_v1('<business_id>'::uuid, 'standard')"
supabase db execute --sql "select business_id, surface, status, source from public.sponsorships where business_id = '<business_id>'::uuid"
```
Expected: 1 satır, `surface=discovery`, `status=active`, `source=plan_grant`.

`search_nearby_businesses_v3`'ün bu işletmeyi mesafeden bağımsız öne aldığını doğrula (aynı bölgede sponsorsuz başka işletmelerle birlikte çağırıp sıralamayı kontrol et).

- [ ] **Step 3: Commit**

```bash
git add supabase/migrations/20260803000008_plan_sponsorship_boost.sql
git commit -m "feat(db): Standard/Pro plan grantı sponsorships'e bağla, search_nearby_businesses_v3'te öne çıkar"
```

---

### Task 16: Son doğrulama

**Files:** Yok (sadece doğrulama)

- [ ] **Step 1: Tam doğrulama paketini çalıştır**

Run: `cd uygulamalar/web && pnpm run test:ci`
Expected: typecheck + lint + unit + build hepsi başarılı.

- [ ] **Step 2: Supabase migration zincirinin baştan sona temiz kurulduğunu doğrula**

Run: `supabase db reset`
Expected: Hatasız biter, 8 yeni migration (`20260803000001`–`20260803000008`) sırayla uygulanır.

- [ ] **Step 3: Uçtan uca manuel senaryo**

1. Yeni bir test işletmesi oluştur (varsayılan: free plan).
2. `/sahip/ayarlar/plan` sayfasında "Ücretsiz" kademesini ve limitleri gözle doğrula.
3. 30 ürün ekleyip 31.'de engellendiğini doğrula.
4. `admin_set_business_plan_v1(business_id, 'pro')` ile Pro'ya yükselt.
5. Aynı sayfada "Pro (İşletme)" ve sınırsız limitleri doğrula.
6. `/sahip/menu/ocr`'da fotoğraftan menü oluşturmayı, `/sahip/menuler/[menuId]/duzenle`'de AI alerjen/kalori ve AI görsel butonlarını, `/sahip/menu/ceviriler`'de ek dil eklemeyi, `/karekod/[businessId]`'de filigransız QR'ı, ve keşif haritasında bu işletmenin öne çıktığını tek tek doğrula.

- [ ] **Step 4: Bulguları özetle**

Herhangi bir adım beklenmedik şekilde başarısız olursa (özellikle Task 8'deki `owner_upsert_menu_item_allergens_v1` imza notu), ilgili task'a dönüp düzelt ve bu task'ı tekrar çalıştır.

---

## Kapsam dışı (bu planda yok)

- Gerçek ödeme sağlayıcı entegrasyonu — plan ataması bu planda tamamen manuel (`admin_set_business_plan_v1`, SQL/Studio üzerinden).
- Admin panelde plan atama UI'ı — kullanıcı isteği üzerine bu round'da yok, sadece RPC var.
- CRM, envanter/stok, owner self-service çoklu şube, destek/ticket sistemi, sadakat/loyalty — kullanıcıyla birlikte teker teker gözden geçirilip bu turdan çıkarıldı.
- Operasyonel personel app (mobil) — bu round mobile dokunmuyor (harita boost istisnası hariç, o da sadece paylaşılan RPC'nin sıralama mantığını değiştiriyor, mobil kod tabanına dokunmuyor).
