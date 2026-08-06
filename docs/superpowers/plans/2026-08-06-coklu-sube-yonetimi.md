# Çoklu Şube Yönetimi (Owner) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Owner panelinde (`app/sahip/**`) owner'ın kendi onaylı işletmelerini bir zincir altında gruplayabildiği, gerçek analytics/rezervasyon verisinden istatistikler gösteren, sürükle-bırak sıralamalı, toplu çalışma-saati/kampanya işlemleri yapabildiği `/sahip/coklu-sube` sayfasını inşa etmek.

**Architecture:** Yeni migration `businesses.chain_sort_order` kolonu + 6 owner-facing RPC ekliyor (`is_owner_of_business` deseniyle sahiplik kontrollü). Web tarafında saf yardımcı fonksiyonlar + server action'lar + toplu-işlem sarmalayıcıları (mevcut tek-işletme `saveHours`/`kampanyaKaydet` fonksiyonlarını döngüyle çağırır, yeni RPC yazmaz) + orkestratör + `bilesenler/` alt klasöründe bileşenler (Destek Sistemi planındaki aynı desen).

**Tech Stack:** Next.js 15 (App Router, Server Actions), Supabase (Postgres/RLS/RPC), TypeScript, Vitest, Tailwind (semantic tokens).

**Spec:** `docs/superpowers/specs/2026-08-06-coklu-sube-yonetimi-design.md`

---

### Task 0: Migration — chain_sort_order + owner RPC'leri

**Files:**
- Create: `supabase/migrations/20260806000004_coklu_sube_owner.sql`

- [ ] **Step 1: Migration dosyasını yaz**

Create `supabase/migrations/20260806000004_coklu_sube_owner.sql`:

```sql
-- Çoklu Şube Yönetimi (Owner) — chain_sort_order kolonu + owner-facing chain RPC'leri.
-- Admin tarafı (chains, admin_create_chain_v1 vb., 20260709000001) değişmiyor.
-- chain_memberships tablosu bilerek KULLANILMIYOR — kod tabanında hiç referansı
-- yok, gerçek "hangi işletme hangi zincirde" mekanizması businesses.chain_id.

ALTER TABLE public.businesses
  ADD COLUMN IF NOT EXISTS chain_sort_order integer;

-- ── owner_create_chain_v1 ────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.owner_create_chain_v1(
  p_business_id uuid,
  p_chain_name  text
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_chain_id uuid;
BEGIN
  IF NOT public.is_owner_of_business(p_business_id) THEN
    RAISE EXCEPTION 'unauthorized' USING ERRCODE = 'P0002';
  END IF;

  IF EXISTS (SELECT 1 FROM public.businesses WHERE id = p_business_id AND chain_id IS NOT NULL) THEN
    RAISE EXCEPTION 'validation_error: işletme zaten bir zincirde' USING ERRCODE = 'P0003';
  END IF;

  IF p_chain_name IS NULL OR trim(p_chain_name) = '' THEN
    RAISE EXCEPTION 'validation_error: zincir adı boş olamaz' USING ERRCODE = 'P0003';
  END IF;

  INSERT INTO public.chains (name) VALUES (trim(p_chain_name)) RETURNING id INTO v_chain_id;

  UPDATE public.businesses
  SET chain_id = v_chain_id, chain_sort_order = 0
  WHERE id = p_business_id;

  RETURN v_chain_id;
END;
$$;

REVOKE ALL ON FUNCTION public.owner_create_chain_v1(uuid, text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.owner_create_chain_v1(uuid, text) TO authenticated;
REVOKE EXECUTE ON FUNCTION public.owner_create_chain_v1(uuid, text) FROM anon;
COMMENT ON FUNCTION public.owner_create_chain_v1 IS
  'Owner: kendi işletmesi için yeni bir zincir oluşturur, işletmeyi Ana Şube (chain_sort_order=0) yapar. Called by: app/sahip/coklu-sube/coklu-sube-islemleri.ts.';

-- ── owner_add_business_to_chain_v1 ───────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.owner_add_business_to_chain_v1(
  p_chain_id     uuid,
  p_business_id  uuid,
  p_branch_label text
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_next_sort integer;
BEGIN
  IF NOT public.is_owner_of_business(p_business_id) THEN
    RAISE EXCEPTION 'unauthorized: eklenecek işletme size ait değil' USING ERRCODE = 'P0002';
  END IF;

  IF EXISTS (SELECT 1 FROM public.businesses WHERE id = p_business_id AND chain_id IS NOT NULL) THEN
    RAISE EXCEPTION 'validation_error: işletme zaten bir zincirde' USING ERRCODE = 'P0003';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM public.businesses b
    WHERE b.chain_id = p_chain_id AND public.is_owner_of_business(b.id)
  ) THEN
    RAISE EXCEPTION 'unauthorized: bu zincir üzerinde yetkiniz yok' USING ERRCODE = 'P0002';
  END IF;

  SELECT COALESCE(MAX(chain_sort_order), -1) + 1 INTO v_next_sort
  FROM public.businesses WHERE chain_id = p_chain_id;

  UPDATE public.businesses
  SET chain_id = p_chain_id,
      branch_label = NULLIF(trim(coalesce(p_branch_label, '')), ''),
      chain_sort_order = v_next_sort
  WHERE id = p_business_id;
END;
$$;

REVOKE ALL ON FUNCTION public.owner_add_business_to_chain_v1(uuid, uuid, text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.owner_add_business_to_chain_v1(uuid, uuid, text) TO authenticated;
REVOKE EXECUTE ON FUNCTION public.owner_add_business_to_chain_v1(uuid, uuid, text) FROM anon;
COMMENT ON FUNCTION public.owner_add_business_to_chain_v1 IS
  'Owner: kendi zincirine, kendine ait ve henüz zincirsiz bir işletme ekler. Called by: app/sahip/coklu-sube/coklu-sube-islemleri.ts.';

-- ── owner_remove_business_from_chain_v1 ──────────────────────────────────────
CREATE OR REPLACE FUNCTION public.owner_remove_business_from_chain_v1(p_business_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_chain_id  uuid;
  v_remaining integer;
BEGIN
  IF NOT public.is_owner_of_business(p_business_id) THEN
    RAISE EXCEPTION 'unauthorized' USING ERRCODE = 'P0002';
  END IF;

  SELECT chain_id INTO v_chain_id FROM public.businesses WHERE id = p_business_id;
  IF v_chain_id IS NULL THEN
    RAISE EXCEPTION 'validation_error: işletme bir zincirde değil' USING ERRCODE = 'P0003';
  END IF;

  UPDATE public.businesses
  SET chain_id = NULL, branch_label = NULL, chain_sort_order = NULL
  WHERE id = p_business_id;

  SELECT count(*) INTO v_remaining FROM public.businesses WHERE chain_id = v_chain_id;
  IF v_remaining = 0 THEN
    DELETE FROM public.chains WHERE id = v_chain_id;
  END IF;
END;
$$;

REVOKE ALL ON FUNCTION public.owner_remove_business_from_chain_v1(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.owner_remove_business_from_chain_v1(uuid) TO authenticated;
REVOKE EXECUTE ON FUNCTION public.owner_remove_business_from_chain_v1(uuid) FROM anon;
COMMENT ON FUNCTION public.owner_remove_business_from_chain_v1 IS
  'Owner: kendi işletmesini zincirden çıkarır. Zincirde başka işletme kalmazsa chains satırı da silinir. Called by: app/sahip/coklu-sube/coklu-sube-islemleri.ts.';

-- ── owner_reorder_chain_branch_v1 ────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.owner_reorder_chain_branch_v1(
  p_business_id     uuid,
  p_new_sort_order  integer
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NOT public.is_owner_of_business(p_business_id) THEN
    RAISE EXCEPTION 'unauthorized' USING ERRCODE = 'P0002';
  END IF;

  UPDATE public.businesses
  SET chain_sort_order = p_new_sort_order
  WHERE id = p_business_id AND chain_id IS NOT NULL;
END;
$$;

REVOKE ALL ON FUNCTION public.owner_reorder_chain_branch_v1(uuid, integer) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.owner_reorder_chain_branch_v1(uuid, integer) TO authenticated;
REVOKE EXECUTE ON FUNCTION public.owner_reorder_chain_branch_v1(uuid, integer) FROM anon;
COMMENT ON FUNCTION public.owner_reorder_chain_branch_v1 IS
  'Owner: kendi şubesinin zincir içi sıralamasını günceller (sürükle-bırak). Called by: app/sahip/coklu-sube/coklu-sube-islemleri.ts.';

-- ── owner_get_chain_overview_v1 ──────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.owner_get_chain_overview_v1(p_business_id uuid)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_chain_id uuid;
  v_result   jsonb;
BEGIN
  IF NOT public.is_owner_of_business(p_business_id) THEN
    RAISE EXCEPTION 'unauthorized' USING ERRCODE = 'P0002';
  END IF;

  SELECT chain_id INTO v_chain_id FROM public.businesses WHERE id = p_business_id;

  IF v_chain_id IS NULL THEN
    RETURN jsonb_build_object(
      'chain_id', null, 'chain_name', null, 'branches', '[]'::jsonb,
      'total_views', 0, 'total_reservations', 0
    );
  END IF;

  SELECT jsonb_build_object(
    'chain_id', c.id,
    'chain_name', c.name,
    'branches', (
      SELECT COALESCE(jsonb_agg(jsonb_build_object(
        'business_id', b.id,
        'name', b.name,
        'branch_label', b.branch_label,
        'city', b.city,
        'district', b.district,
        'is_active', b.is_active,
        'logo_url', b.logo_url,
        'chain_sort_order', b.chain_sort_order,
        'is_main_branch', (b.chain_sort_order = 0),
        'views', (
          SELECT count(*) FROM public.analytics_events e
          WHERE e.business_id = b.id AND e.event_name IN ('business_page_view', 'menu_view')
        ),
        'reservations', (
          SELECT count(*) FROM public.reservations r WHERE r.business_id = b.id
        )
      ) ORDER BY b.chain_sort_order), '[]'::jsonb)
      FROM public.businesses b WHERE b.chain_id = c.id
    ),
    'total_views', (
      SELECT count(*) FROM public.analytics_events e
      WHERE e.business_id IN (SELECT id FROM public.businesses WHERE chain_id = c.id)
        AND e.event_name IN ('business_page_view', 'menu_view')
    ),
    'total_reservations', (
      SELECT count(*) FROM public.reservations r
      WHERE r.business_id IN (SELECT id FROM public.businesses WHERE chain_id = c.id)
    )
  ) INTO v_result
  FROM public.chains c WHERE c.id = v_chain_id;

  RETURN v_result;
END;
$$;

REVOKE ALL ON FUNCTION public.owner_get_chain_overview_v1(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.owner_get_chain_overview_v1(uuid) TO authenticated;
REVOKE EXECUTE ON FUNCTION public.owner_get_chain_overview_v1(uuid) FROM anon;
COMMENT ON FUNCTION public.owner_get_chain_overview_v1 IS
  'Owner: işletmesinin bağlı olduğu zincirin tüm şubelerini + görüntülenme/rezervasyon istatistiklerini döner. Zincirsizse boş sonuç döner (hata değil). Called by: app/sahip/coklu-sube/coklu-sube-islemleri.ts, app/sunucu/sahip/coklu-sube-rapor-csv/route.ts.';

-- ── owner_list_addable_businesses_v1 ─────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.owner_list_addable_businesses_v1()
RETURNS TABLE(business_id uuid, name text, city text)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT b.id, b.name, b.city
  FROM public.businesses b
  JOIN public.owner_claims oc ON oc.business_id = b.id
  WHERE oc.user_id = auth.uid() AND oc.status = 'approved' AND b.chain_id IS NULL
  ORDER BY b.name;
$$;

REVOKE ALL ON FUNCTION public.owner_list_addable_businesses_v1() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.owner_list_addable_businesses_v1() TO authenticated;
REVOKE EXECUTE ON FUNCTION public.owner_list_addable_businesses_v1() FROM anon;
COMMENT ON FUNCTION public.owner_list_addable_businesses_v1 IS
  'Owner: henüz hiçbir zincire bağlı olmayan, kendi onaylı işletmelerini listeler ("Yeni Şube Ekle" modalı için). Called by: app/sahip/coklu-sube/coklu-sube-islemleri.ts.';
```

- [ ] **Step 2: Lokal Supabase'i sıfırla ve doğrula**

Run: `supabase db reset`
Expected: Hatasız biter.

Run (doğrulama):
```bash
psql "postgresql://postgres:postgres@127.0.0.1:54322/postgres" -c "\d public.businesses" | grep chain_sort_order
psql "postgresql://postgres:postgres@127.0.0.1:54322/postgres" -c "select proname from pg_proc where proname like 'owner_%chain%' or proname = 'owner_list_addable_businesses_v1' order by proname"
```
Expected: `chain_sort_order` kolonu listelenir; 6 fonksiyon adı döner.

- [ ] **Step 3: Commit**

```bash
git add supabase/migrations/20260806000004_coklu_sube_owner.sql
git commit -m "feat(db): çoklu şube — chain_sort_order kolonu + owner zincir RPC'leri"
```

---

### Task 1: Saf yardımcı fonksiyonlar + testler

**Files:**
- Create: `uygulamalar/web/app/sahip/coklu-sube/coklu-sube-yardimcilari.ts`
- Test: `uygulamalar/web/test/lib/coklu-sube-yardimcilari.test.ts`

- [ ] **Step 1: Başarısız testi yaz**

`uygulamalar/web/test/lib/coklu-sube-yardimcilari.test.ts`:

```ts
import { describe, it, expect } from 'vitest';
import {
  branchMatchesTab,
  filterBranches,
  cityDistribution,
  type CokluSubeBranch,
} from '@/app/sahip/coklu-sube/coklu-sube-yardimcilari';

const BRANCHES: CokluSubeBranch[] = [
  {
    business_id: 'b1', name: 'No 18 Coffee - Merkez', branch_label: 'Merkez', city: 'Ankara',
    district: 'Çankaya', is_active: true, logo_url: null, chain_sort_order: 0, is_main_branch: true,
    views: 100, reservations: 10,
  },
  {
    business_id: 'b2', name: 'No 18 Coffee - Kadıköy', branch_label: 'Kadıköy', city: 'İstanbul',
    district: 'Kadıköy', is_active: true, logo_url: null, chain_sort_order: 1, is_main_branch: false,
    views: 50, reservations: 5,
  },
  {
    business_id: 'b3', name: 'No 18 Coffee - Alsancak', branch_label: 'Alsancak', city: 'İzmir',
    district: 'Konak', is_active: false, logo_url: null, chain_sort_order: 2, is_main_branch: false,
    views: 20, reservations: 0,
  },
];

describe('branchMatchesTab', () => {
  it('tumu her durumu kapsar', () => {
    expect(branchMatchesTab(BRANCHES[0], 'tumu')).toBe(true);
    expect(branchMatchesTab(BRANCHES[2], 'tumu')).toBe(true);
  });

  it('aktif sadece is_active=true olanları kapsar', () => {
    expect(branchMatchesTab(BRANCHES[0], 'aktif')).toBe(true);
    expect(branchMatchesTab(BRANCHES[2], 'aktif')).toBe(false);
  });

  it('pasif sadece is_active=false olanları kapsar', () => {
    expect(branchMatchesTab(BRANCHES[2], 'pasif')).toBe(true);
    expect(branchMatchesTab(BRANCHES[0], 'pasif')).toBe(false);
  });
});

describe('filterBranches', () => {
  it('arama metnine göre ada/etikete/şehre göre filtreler (case-insensitive)', () => {
    const result = filterBranches(BRANCHES, 'kadıköy', 'tumu');
    expect(result.map((b) => b.business_id)).toEqual(['b2']);
  });

  it('sekme ve arama birlikte AND mantığıyla uygulanır', () => {
    const result = filterBranches(BRANCHES, '', 'aktif');
    expect(result.map((b) => b.business_id).sort()).toEqual(['b1', 'b2']);
  });

  it('boş aramada sekmeye uyan tüm şubeleri döner', () => {
    const result = filterBranches(BRANCHES, '', 'tumu');
    expect(result).toHaveLength(3);
  });
});

describe('cityDistribution', () => {
  it('şehre göre sayarak azalan sırada döner', () => {
    const result = cityDistribution(BRANCHES);
    expect(result).toEqual([
      { city: 'Ankara', count: 1 },
      { city: 'İstanbul', count: 1 },
      { city: 'İzmir', count: 1 },
    ]);
  });

  it('aynı şehirdeki birden fazla şubeyi doğru sayar', () => {
    const twoInSameCity: CokluSubeBranch[] = [
      { ...BRANCHES[0], business_id: 'b4' },
      { ...BRANCHES[0], business_id: 'b5' },
    ];
    const result = cityDistribution(twoInSameCity);
    expect(result).toEqual([{ city: 'Ankara', count: 2 }]);
  });
});
```

- [ ] **Step 2: Testin başarısız olduğunu doğrula**

Run: `cd uygulamalar/web && pnpm vitest run test/lib/coklu-sube-yardimcilari.test.ts`
Expected: FAIL — modül bulunamadı hatası.

- [ ] **Step 3: Yardımcı modülü yaz**

`uygulamalar/web/app/sahip/coklu-sube/coklu-sube-yardimcilari.ts`:

```ts
export type CokluSubeBranch = {
  business_id: string;
  name: string;
  branch_label: string | null;
  city: string | null;
  district: string | null;
  is_active: boolean;
  logo_url: string | null;
  chain_sort_order: number;
  is_main_branch: boolean;
  views: number;
  reservations: number;
};

export type CokluSubeOverview = {
  chain_id: string | null;
  chain_name: string | null;
  branches: CokluSubeBranch[];
  total_views: number;
  total_reservations: number;
};

export type SubeTab = 'tumu' | 'aktif' | 'pasif';

export function branchMatchesTab(branch: CokluSubeBranch, tab: SubeTab): boolean {
  if (tab === 'tumu') return true;
  if (tab === 'aktif') return branch.is_active;
  return !branch.is_active;
}

export function filterBranches(branches: CokluSubeBranch[], search: string, tab: SubeTab): CokluSubeBranch[] {
  const q = search.trim().toLowerCase();
  return branches
    .filter((b) => branchMatchesTab(b, tab))
    .filter((b) => {
      if (!q) return true;
      const haystack = `${b.name} ${b.branch_label ?? ''} ${b.city ?? ''}`.toLowerCase();
      return haystack.includes(q);
    });
}

export function cityDistribution(branches: CokluSubeBranch[]): Array<{ city: string; count: number }> {
  const counts = new Map<string, number>();
  for (const b of branches) {
    const city = b.city ?? 'Bilinmiyor';
    counts.set(city, (counts.get(city) ?? 0) + 1);
  }
  return Array.from(counts.entries())
    .map(([city, count]) => ({ city, count }))
    .sort((a, b) => b.count - a.count);
}
```

- [ ] **Step 4: Testin geçtiğini doğrula**

Run: `cd uygulamalar/web && pnpm vitest run test/lib/coklu-sube-yardimcilari.test.ts`
Expected: PASS — 7 test.

- [ ] **Step 5: Commit**

```bash
git add uygulamalar/web/app/sahip/coklu-sube/coklu-sube-yardimcilari.ts uygulamalar/web/test/lib/coklu-sube-yardimcilari.test.ts
git commit -m "feat(web): çoklu şube — saf yardımcı fonksiyonlar (tab filtresi/arama/şehir dağılımı) + testler"
```

---

### Task 2: Server actions — zincir yönetimi

**Files:**
- Create: `uygulamalar/web/app/sahip/coklu-sube/coklu-sube-islemleri.ts`
- Test: `uygulamalar/web/test/lib/coklu-sube-islemleri.test.ts`

- [ ] **Step 1: Server action dosyasını yaz**

`uygulamalar/web/app/sahip/coklu-sube/coklu-sube-islemleri.ts`:

```ts
'use server';

import { revalidatePath } from 'next/cache';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import type { CokluSubeOverview } from './coklu-sube-yardimcilari';

export type AddableBusiness = { business_id: string; name: string; city: string | null };

async function requireUser() {
  const supabase = await createSupabaseServerClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) return { ok: false as const, error: 'Oturum bulunamadı' };
  return { ok: true as const, supabase, user };
}

export async function subeYonetimVerisiGetir(businessId: string): Promise<{ error: string } | CokluSubeOverview> {
  const context = await requireUser();
  if (!context.ok) return { error: context.error };

  const { data, error } = (await (context.supabase as any).rpc('owner_get_chain_overview_v1', {
    p_business_id: businessId,
  })) as { data: CokluSubeOverview | null; error: { message: string } | null };

  if (error) return { error: error.message };
  return data ?? { chain_id: null, chain_name: null, branches: [], total_views: 0, total_reservations: 0 };
}

export async function zincirOlustur(
  businessId: string,
  chainName: string,
): Promise<{ error: string } | { chainId: string }> {
  const context = await requireUser();
  if (!context.ok) return { error: context.error };

  const trimmed = chainName.trim();
  if (!trimmed) return { error: 'Zincir adı boş olamaz' };

  const { data, error } = (await (context.supabase as any).rpc('owner_create_chain_v1', {
    p_business_id: businessId,
    p_chain_name: trimmed,
  })) as { data: string | null; error: { message: string } | null };

  if (error) return { error: error.message };
  revalidatePath('/sahip/coklu-sube');
  return { chainId: data ?? '' };
}

export async function subeEkle(
  chainId: string,
  businessId: string,
  branchLabel: string,
): Promise<{ error: string } | null> {
  const context = await requireUser();
  if (!context.ok) return { error: context.error };

  const { error } = (await (context.supabase as any).rpc('owner_add_business_to_chain_v1', {
    p_chain_id: chainId,
    p_business_id: businessId,
    p_branch_label: branchLabel.trim() || null,
  })) as { error: { message: string } | null };

  if (error) return { error: error.message };
  revalidatePath('/sahip/coklu-sube');
  return null;
}

export async function subeCikar(businessId: string): Promise<{ error: string } | null> {
  const context = await requireUser();
  if (!context.ok) return { error: context.error };

  const { error } = (await (context.supabase as any).rpc('owner_remove_business_from_chain_v1', {
    p_business_id: businessId,
  })) as { error: { message: string } | null };

  if (error) return { error: error.message };
  revalidatePath('/sahip/coklu-sube');
  return null;
}

export async function subeSirasiGuncelle(businessId: string, newSortOrder: number): Promise<{ error: string } | null> {
  const context = await requireUser();
  if (!context.ok) return { error: context.error };

  const { error } = (await (context.supabase as any).rpc('owner_reorder_chain_branch_v1', {
    p_business_id: businessId,
    p_new_sort_order: newSortOrder,
  })) as { error: { message: string } | null };

  if (error) return { error: error.message };
  revalidatePath('/sahip/coklu-sube');
  return null;
}

export async function eklenebilirIsletmeleriListele(): Promise<{ error: string } | { businesses: AddableBusiness[] }> {
  const context = await requireUser();
  if (!context.ok) return { error: context.error };

  const { data, error } = (await (context.supabase as any).rpc('owner_list_addable_businesses_v1')) as {
    data: AddableBusiness[] | null;
    error: { message: string } | null;
  };

  if (error) return { error: error.message };
  return { businesses: data ?? [] };
}
```

- [ ] **Step 2: Test yaz**

`uygulamalar/web/test/lib/coklu-sube-islemleri.test.ts`:

```ts
import { describe, it, expect } from 'vitest';
import {
  subeYonetimVerisiGetir,
  zincirOlustur,
  subeEkle,
  subeCikar,
  subeSirasiGuncelle,
  eklenebilirIsletmeleriListele,
} from '@/app/sahip/coklu-sube/coklu-sube-islemleri';

describe('çoklu şube server action\'ları', () => {
  it('fonksiyonlar export edilir', () => {
    expect(typeof subeYonetimVerisiGetir).toBe('function');
    expect(typeof zincirOlustur).toBe('function');
    expect(typeof subeEkle).toBe('function');
    expect(typeof subeCikar).toBe('function');
    expect(typeof subeSirasiGuncelle).toBe('function');
    expect(typeof eklenebilirIsletmeleriListele).toBe('function');
  });
});
```

(Bu codebase'de server action'lar için genel konvansiyon budur — gerçek DB davranışı son doğrulama task'ında test edilir.)

- [ ] **Step 3: Typecheck + test çalıştır**

Run: `cd uygulamalar/web && pnpm run typecheck && pnpm vitest run test/lib/coklu-sube-islemleri.test.ts`
Expected: PASS.

- [ ] **Step 4: Commit**

```bash
git add uygulamalar/web/app/sahip/coklu-sube/coklu-sube-islemleri.ts uygulamalar/web/test/lib/coklu-sube-islemleri.test.ts
git commit -m "feat(web): çoklu şube — zincir yönetimi server action'ları"
```

---

### Task 3: Toplu çalışma saatleri action'ı (mevcut saveHours'ı sarmalar)

**Files:**
- Create: `uygulamalar/web/app/sahip/coklu-sube/coklu-sube-toplu-saat.ts`

- [ ] **Step 1: Dosyayı yaz**

`uygulamalar/web/app/sahip/coklu-sube/coklu-sube-toplu-saat.ts`:

```ts
'use server';

import { saveHours } from '@/app/sahip/ayarlar/saatler/saat-islemleri';

const DAY_KEYS = ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'] as const;
export type DayKey = (typeof DAY_KEYS)[number];
export type HoursTemplate = Partial<Record<DayKey, { open: string; close: string } | null>>;

export type TopluIslemSonucu = { successCount: number; failedBusinessIds: string[] };

export async function saatleriTopluUygula(
  businessIds: string[],
  template: HoursTemplate,
): Promise<TopluIslemSonucu> {
  let successCount = 0;
  const failedBusinessIds: string[] = [];

  for (const businessId of businessIds) {
    try {
      const fd = new FormData();
      for (const day of DAY_KEYS) {
        const value = template[day];
        if (value) {
          fd.set(`${day}_open`, value.open);
          fd.set(`${day}_close`, value.close);
        }
      }
      await saveHours(businessId, fd);
      successCount += 1;
    } catch {
      failedBusinessIds.push(businessId);
    }
  }

  return { successCount, failedBusinessIds };
}
```

- [ ] **Step 2: Typecheck**

Run: `cd uygulamalar/web && pnpm run typecheck`
Expected: PASS (import edilen `saveHours`'ın gerçek imzasıyla uyumlu olmalı — `saveHours(businessId: string, fd: FormData): Promise<void>`, hata durumunda throw eder, bu yüzden try/catch kullanılıyor).

- [ ] **Step 3: Commit**

```bash
git add uygulamalar/web/app/sahip/coklu-sube/coklu-sube-toplu-saat.ts
git commit -m "feat(web): çoklu şube — toplu çalışma saati action'ı (mevcut saveHours'ı döngüyle çağırır)"
```

---

### Task 4: Toplu kampanya action'ı (mevcut kampanyaKaydet'i sarmalar)

**Files:**
- Create: `uygulamalar/web/app/sahip/coklu-sube/coklu-sube-toplu-kampanya.ts`

- [ ] **Step 1: Dosyayı yaz**

`uygulamalar/web/app/sahip/coklu-sube/coklu-sube-toplu-kampanya.ts`:

```ts
'use server';

import { kampanyaKaydet } from '@/app/sahip/pazarlama/kampanyalar/kampanya-islemleri';
import type { TopluIslemSonucu } from './coklu-sube-toplu-saat';

export type KampanyaSablonu = {
  title: string;
  type: 'discount' | 'special_offer' | 'loyalty' | 'announcement';
  status: 'draft' | 'planned' | 'active' | 'completed';
  description?: string;
  discountPercent?: number;
  startsAt?: string;
  endsAt?: string;
};

export async function kampanyaTopluOlustur(
  businessIds: string[],
  template: KampanyaSablonu,
): Promise<TopluIslemSonucu> {
  let successCount = 0;
  const failedBusinessIds: string[] = [];

  for (const businessId of businessIds) {
    const fd = new FormData();
    fd.set('business_id', businessId);
    fd.set('title', template.title);
    fd.set('type', template.type);
    fd.set('status', template.status);
    if (template.description) fd.set('description', template.description);
    if (template.discountPercent != null) fd.set('discount_percent', String(template.discountPercent));
    if (template.startsAt) fd.set('starts_at', template.startsAt);
    if (template.endsAt) fd.set('ends_at', template.endsAt);

    const result = await kampanyaKaydet(null, fd);
    if (result?.error) {
      failedBusinessIds.push(businessId);
    } else {
      successCount += 1;
    }
  }

  return { successCount, failedBusinessIds };
}
```

- [ ] **Step 2: Typecheck**

Run: `cd uygulamalar/web && pnpm run typecheck`
Expected: PASS.

- [ ] **Step 3: Commit**

```bash
git add uygulamalar/web/app/sahip/coklu-sube/coklu-sube-toplu-kampanya.ts
git commit -m "feat(web): çoklu şube — toplu kampanya action'ı (mevcut kampanyaKaydet'i döngüyle çağırır)"
```

---

### Task 5: CSV export route

**Files:**
- Create: `uygulamalar/web/app/sunucu/sahip/coklu-sube-rapor-csv/route.ts`

- [ ] **Step 1: Route dosyasını yaz**

`uygulamalar/web/app/sunucu/sahip/coklu-sube-rapor-csv/route.ts`:

```ts
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import type { CokluSubeOverview } from '@/app/sahip/coklu-sube/coklu-sube-yardimcilari';

export async function GET(request: Request) {
  const url = new URL(request.url);
  const businessId = url.searchParams.get('businessId');
  if (!businessId) return new Response('missing_business_id', { status: 400 });

  const supabase = await createSupabaseServerClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) return new Response('Unauthorized', { status: 401 });

  const { data: overview, error } = (await (supabase as any).rpc('owner_get_chain_overview_v1', {
    p_business_id: businessId,
  })) as { data: CokluSubeOverview | null; error: { message: string } | null };

  if (error) return new Response('internal_error', { status: 500 });
  if (!overview) return new Response('not_found', { status: 404 });

  const safeStr = (s: string | null) => `"${(s ?? '').replace(/"/g, '""')}"`;
  const header = 'Şube Adı,Şube Etiketi,Şehir,Durum,Görüntülenme,Rezervasyon';
  const lines = overview.branches.map((b) =>
    [safeStr(b.name), safeStr(b.branch_label), safeStr(b.city), b.is_active ? 'Aktif' : 'Pasif', b.views, b.reservations].join(','),
  );
  const csv = [header, ...lines].join('\n');
  const ts = new Date().toISOString().slice(0, 10);

  return new Response('﻿' + csv, {
    headers: {
      'Content-Type': 'text/csv; charset=utf-8',
      'Content-Disposition': `attachment; filename="subeler-${ts}.csv"`,
    },
  });
}
```

- [ ] **Step 2: Typecheck + lint**

Run: `cd uygulamalar/web && pnpm run typecheck && pnpm run lint`
Expected: İkisi de hatasız biter.

- [ ] **Step 3: Commit**

```bash
git add uygulamalar/web/app/sunucu/sahip/coklu-sube-rapor-csv/route.ts
git commit -m "feat(web): çoklu şube — CSV export route'u"
```

---

### Task 6: İstatistik Kartları bileşeni

**Files:**
- Create: `uygulamalar/web/app/sahip/coklu-sube/bilesenler/istatistik-kartlari.tsx`

- [ ] **Step 1: Bileşeni yaz**

```tsx
import type { CokluSubeOverview } from '../coklu-sube-yardimcilari';

export function IstatistikKartlari({ overview }: { overview: CokluSubeOverview }) {
  const cityCount = new Set(overview.branches.map((b) => b.city ?? 'Bilinmiyor')).size;

  const kartlar = [
    { label: 'Toplam Şube', value: String(overview.branches.length) },
    { label: 'Toplam Görüntülenme', value: overview.total_views.toLocaleString('tr-TR') },
    { label: 'Toplam Rezervasyon', value: overview.total_reservations.toLocaleString('tr-TR') },
    { label: 'Şehir Sayısı', value: String(cityCount) },
  ];

  return (
    <div className="grid grid-cols-2 gap-3 sm:grid-cols-4">
      {kartlar.map((kart) => (
        <div key={kart.label} className="rounded-2xl border border-border bg-card p-4">
          <p className="text-[11px] font-bold uppercase tracking-wide text-muted">{kart.label}</p>
          <p className="mt-1 text-2xl font-black text-textStrong">{kart.value}</p>
        </div>
      ))}
    </div>
  );
}
```

- [ ] **Step 2: Typecheck**

Run: `cd uygulamalar/web && pnpm run typecheck`
Expected: PASS.

- [ ] **Step 3: Commit**

```bash
git add uygulamalar/web/app/sahip/coklu-sube/bilesenler/istatistik-kartlari.tsx
git commit -m "feat(web): çoklu şube — istatistik kartları bileşeni"
```

---

### Task 7: Şube Tablosu bileşeni (sürükle-bırak dahil)

**Files:**
- Create: `uygulamalar/web/app/sahip/coklu-sube/bilesenler/sube-tablosu.tsx`

- [ ] **Step 1: Bileşeni yaz**

```tsx
'use client';

import { useState } from 'react';
import Image from 'next/image';
import type { CokluSubeBranch } from '../coklu-sube-yardimcilari';
import { filterBranches, type SubeTab } from '../coklu-sube-yardimcilari';

export function SubeTablosu({
  branches,
  onRemove,
  onReorder,
  reorderMode,
}: {
  branches: CokluSubeBranch[];
  onRemove: (businessId: string) => void;
  onReorder: (businessId: string, newSortOrder: number) => void;
  reorderMode: boolean;
}) {
  const [tab, setTab] = useState<SubeTab>('tumu');
  const [search, setSearch] = useState('');
  const [draggedId, setDraggedId] = useState<string | null>(null);

  const visible = filterBranches(branches, search, tab);

  const tabs: Array<{ id: SubeTab; label: string }> = [
    { id: 'tumu', label: `Tümü (${branches.length})` },
    { id: 'aktif', label: `Aktif (${branches.filter((b) => b.is_active).length})` },
    { id: 'pasif', label: `Pasif (${branches.filter((b) => !b.is_active).length})` },
  ];

  function handleDrop(targetBranch: CokluSubeBranch) {
    if (!draggedId || draggedId === targetBranch.business_id) {
      setDraggedId(null);
      return;
    }
    onReorder(draggedId, targetBranch.chain_sort_order);
    setDraggedId(null);
  }

  return (
    <div className="rounded-2xl border border-border bg-card">
      <div className="flex flex-wrap items-center justify-between gap-3 border-b border-border p-4">
        <div className="flex flex-wrap gap-1">
          {tabs.map((t) => (
            <button
              key={t.id}
              type="button"
              onClick={() => setTab(t.id)}
              className={`rounded-lg px-3 py-1.5 text-xs font-bold cursor-pointer ${
                tab === t.id ? 'bg-primary text-white' : 'text-muted hover:bg-bg'
              }`}
            >
              {t.label}
            </button>
          ))}
        </div>
        <input
          value={search}
          onChange={(e) => setSearch(e.target.value)}
          placeholder="Şube adı, şehir veya adres ara..."
          className="min-w-[200px] flex-1 rounded-xl border border-border bg-bg px-3 py-2 text-sm text-textStrong placeholder:text-muted focus:outline-hidden focus:ring-2 focus:ring-primary/30"
        />
      </div>

      {reorderMode && (
        <div className="border-b border-border bg-primary/5 px-4 py-2 text-xs font-bold text-primary">
          Sıralama modu açık — satırları sürükleyerek şube sırasını değiştirin.
        </div>
      )}

      {visible.length === 0 ? (
        <div className="flex flex-col items-center gap-2 py-12 text-center">
          <p className="text-sm font-bold text-textStrong">Bu sekmede şube yok</p>
        </div>
      ) : (
        <div className="overflow-x-auto">
          <table className="w-full min-w-[720px] text-sm">
            <thead>
              <tr className="border-b border-border text-left text-xs font-bold uppercase tracking-wide text-muted">
                {reorderMode && <th className="w-8 px-3 py-2"></th>}
                <th className="px-3 py-2">Şube Adı</th>
                <th className="px-3 py-2">Şehir</th>
                <th className="px-3 py-2">Durum</th>
                <th className="px-3 py-2">Görüntülenme</th>
                <th className="px-3 py-2">Rezervasyon</th>
                <th className="px-3 py-2">İşlemler</th>
              </tr>
            </thead>
            <tbody>
              {visible.map((branch) => (
                <tr
                  key={branch.business_id}
                  draggable={reorderMode}
                  onDragStart={() => reorderMode && setDraggedId(branch.business_id)}
                  onDragOver={(e) => reorderMode && e.preventDefault()}
                  onDrop={() => reorderMode && handleDrop(branch)}
                  className={`border-b border-border last:border-0 hover:bg-bg/60 ${
                    draggedId === branch.business_id ? 'opacity-40' : ''
                  }`}
                >
                  {reorderMode && (
                    <td className="px-3 py-2 text-muted">
                      <span className="cursor-grab select-none" title="Sürükleyerek sırala">
                        ⠿
                      </span>
                    </td>
                  )}
                  <td className="px-3 py-2">
                    <div className="flex items-center gap-2">
                      {branch.logo_url ? (
                        <Image
                          src={branch.logo_url}
                          alt={branch.name}
                          width={32}
                          height={32}
                          className="h-8 w-8 rounded-lg object-cover"
                          unoptimized
                        />
                      ) : (
                        <div className="flex h-8 w-8 items-center justify-center rounded-lg border border-dashed border-border bg-bg text-[9px] font-bold text-muted">
                          Yok
                        </div>
                      )}
                      <div>
                        <p className="font-bold text-textStrong">
                          {branch.name}
                          {branch.is_main_branch && (
                            <span className="ml-2 rounded-full bg-primary/10 px-2 py-0.5 text-[10px] font-extrabold text-primary">
                              Ana Şube
                            </span>
                          )}
                        </p>
                        {branch.branch_label && <p className="text-xs text-muted">{branch.branch_label}</p>}
                      </div>
                    </div>
                  </td>
                  <td className="px-3 py-2 text-muted">{branch.city ?? '—'}</td>
                  <td className="px-3 py-2">
                    <span
                      className={`rounded-full px-2 py-0.5 text-[11px] font-extrabold ${
                        branch.is_active ? 'bg-green-50 text-green-700' : 'bg-zinc-100 text-zinc-500'
                      }`}
                    >
                      {branch.is_active ? 'Aktif' : 'Pasif'}
                    </span>
                  </td>
                  <td className="px-3 py-2 font-bold text-textStrong">{branch.views.toLocaleString('tr-TR')}</td>
                  <td className="px-3 py-2 font-bold text-textStrong">{branch.reservations.toLocaleString('tr-TR')}</td>
                  <td className="px-3 py-2">
                    <button
                      type="button"
                      onClick={() => {
                        if (confirm(`"${branch.name}" şubesini zincirden çıkarmak istediğinize emin misiniz?`)) {
                          onRemove(branch.business_id);
                        }
                      }}
                      className="rounded-lg border border-red-200 px-2 py-1 text-[11px] font-bold text-red-600 hover:bg-red-50 cursor-pointer"
                    >
                      Zincirden Çıkar
                    </button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </div>
  );
}
```

- [ ] **Step 2: Typecheck**

Run: `cd uygulamalar/web && pnpm run typecheck`
Expected: PASS.

- [ ] **Step 3: Commit**

```bash
git add uygulamalar/web/app/sahip/coklu-sube/bilesenler/sube-tablosu.tsx
git commit -m "feat(web): çoklu şube — sürükle-bırak sıralamalı şube tablosu bileşeni"
```

---

### Task 8: Şehir Dağılımı (statik pin listesi) bileşeni

**Files:**
- Create: `uygulamalar/web/app/sahip/coklu-sube/bilesenler/sehir-dagilimi.tsx`

- [ ] **Step 1: Bileşeni yaz**

Not: Mockup'taki interaktif harita yerine, araştırma sırasında bulunan riskler nedeniyle (bkz. spec — `/kesif/harita` business filtresi desteklemiyor, maplibre-gl'in bu projede geçmiş bir Turbopack worker bug'ı var) **statik bir şehir/pin listesi** kullanılıyor. Yeni harita kütüphanesi bağımlılığı eklenmiyor.

```tsx
import Link from 'next/link';
import { cityDistribution, type CokluSubeBranch } from '../coklu-sube-yardimcilari';

export function SehirDagilimi({ branches }: { branches: CokluSubeBranch[] }) {
  const distribution = cityDistribution(branches);

  return (
    <div className="rounded-2xl border border-border bg-card p-4">
      <h3 className="mb-3 text-sm font-black text-textStrong">Şehre Göre Dağılım</h3>
      {distribution.length === 0 ? (
        <p className="text-xs text-muted">Henüz şube yok.</p>
      ) : (
        <div className="flex flex-col gap-2">
          {distribution.map((item) => (
            <div key={item.city} className="flex items-center justify-between gap-2 text-sm">
              <span className="flex items-center gap-2 text-textStrong">
                <span aria-hidden="true">📍</span>
                {item.city}
              </span>
              <span className="rounded-full bg-bg px-2 py-0.5 text-xs font-bold text-muted">{item.count} şube</span>
            </div>
          ))}
        </div>
      )}
      <Link
        href="/kesif/harita"
        target="_blank"
        rel="noopener noreferrer"
        className="mt-3 block rounded-xl border border-border px-3 py-2 text-center text-xs font-bold text-textStrong hover:bg-bg"
      >
        Haritada Görüntüle
      </Link>
    </div>
  );
}
```

- [ ] **Step 2: Typecheck**

Run: `cd uygulamalar/web && pnpm run typecheck`
Expected: PASS.

- [ ] **Step 3: Commit**

```bash
git add uygulamalar/web/app/sahip/coklu-sube/bilesenler/sehir-dagilimi.tsx
git commit -m "feat(web): çoklu şube — şehir dağılımı (statik pin listesi) bileşeni"
```

---

### Task 9: Zincir Oluştur (boş durum) bileşeni

**Files:**
- Create: `uygulamalar/web/app/sahip/coklu-sube/bilesenler/zincir-olustur-formu.tsx`

- [ ] **Step 1: Bileşeni yaz**

```tsx
'use client';

import { useState, useTransition } from 'react';
import { zincirOlustur } from '../coklu-sube-islemleri';

export function ZincirOlusturFormu({ businessId, onSuccess }: { businessId: string; onSuccess: () => void }) {
  const [chainName, setChainName] = useState('');
  const [error, setError] = useState<string | null>(null);
  const [isPending, startTransition] = useTransition();

  function handleSubmit(e: React.FormEvent<HTMLFormElement>) {
    e.preventDefault();
    const trimmed = chainName.trim();
    if (!trimmed) {
      setError('Zincir adı boş olamaz');
      return;
    }
    setError(null);
    startTransition(async () => {
      const result = await zincirOlustur(businessId, trimmed);
      if ('error' in result) {
        setError(result.error);
        return;
      }
      onSuccess();
    });
  }

  return (
    <div className="flex flex-col items-center gap-4 rounded-2xl border border-dashed border-border bg-card p-10 text-center">
      <p className="text-lg font-black text-textStrong">Henüz bir zinciriniz yok</p>
      <p className="max-w-sm text-sm text-muted">
        Birden fazla şubeniz varsa, bir zincir oluşturup işletmelerinizi tek panelden yönetebilirsiniz.
      </p>
      <form onSubmit={handleSubmit} className="flex w-full max-w-sm flex-col gap-2">
        <input
          value={chainName}
          onChange={(e) => setChainName(e.target.value)}
          placeholder="Zincir adı (örn. No 18 Coffee Co.)"
          className="rounded-xl border border-border bg-bg px-3 py-2 text-sm text-textStrong placeholder:text-muted focus:outline-hidden focus:ring-2 focus:ring-primary/30"
        />
        {error && <p className="text-xs font-bold text-red-600">{error}</p>}
        <button
          type="submit"
          disabled={isPending}
          className="rounded-xl bg-primary px-3 py-2 text-sm font-bold text-white disabled:opacity-60 cursor-pointer"
        >
          {isPending ? 'Oluşturuluyor...' : 'Zincir Oluştur'}
        </button>
      </form>
    </div>
  );
}
```

- [ ] **Step 2: Typecheck**

Run: `cd uygulamalar/web && pnpm run typecheck`
Expected: PASS.

- [ ] **Step 3: Commit**

```bash
git add uygulamalar/web/app/sahip/coklu-sube/bilesenler/zincir-olustur-formu.tsx
git commit -m "feat(web): çoklu şube — zincir oluştur (boş durum) bileşeni"
```

---

### Task 10: Yeni Şube Ekle modalı

**Files:**
- Create: `uygulamalar/web/app/sahip/coklu-sube/bilesenler/yeni-sube-ekle-formu.tsx`

- [ ] **Step 1: Bileşeni yaz**

```tsx
'use client';

import { useEffect, useState, useTransition } from 'react';
import Link from 'next/link';
import { eklenebilirIsletmeleriListele, subeEkle, type AddableBusiness } from '../coklu-sube-islemleri';

export function YeniSubeEkleFormu({
  chainId,
  onSuccess,
  onCancel,
}: {
  chainId: string;
  onSuccess: () => void;
  onCancel: () => void;
}) {
  const [businesses, setBusinesses] = useState<AddableBusiness[] | null>(null);
  const [loadError, setLoadError] = useState<string | null>(null);
  const [selectedId, setSelectedId] = useState('');
  const [branchLabel, setBranchLabel] = useState('');
  const [error, setError] = useState<string | null>(null);
  const [isPending, startTransition] = useTransition();

  useEffect(() => {
    let cancelled = false;
    void eklenebilirIsletmeleriListele().then((result) => {
      if (cancelled) return;
      if ('error' in result) {
        setLoadError(result.error);
        return;
      }
      setBusinesses(result.businesses);
    });
    return () => {
      cancelled = true;
    };
  }, []);

  function handleSubmit(e: React.FormEvent<HTMLFormElement>) {
    e.preventDefault();
    if (!selectedId) {
      setError('Bir işletme seçin');
      return;
    }
    setError(null);
    startTransition(async () => {
      const result = await subeEkle(chainId, selectedId, branchLabel);
      if (result?.error) {
        setError(result.error);
        return;
      }
      onSuccess();
    });
  }

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
      <div className="absolute inset-0 bg-black/30" onClick={onCancel} />
      <div className="relative z-10 w-full max-w-md rounded-2xl bg-card p-5 shadow-2xl">
        <h2 className="mb-4 text-sm font-black text-textStrong">Yeni Şube Ekle</h2>

        {businesses === null && !loadError && <p className="text-sm text-muted">Yükleniyor...</p>}
        {loadError && <p className="text-sm font-bold text-red-600">{loadError}</p>}

        {businesses !== null && businesses.length === 0 && (
          <div className="flex flex-col gap-3">
            <p className="text-sm text-muted">
              Zincire eklenebilecek, henüz başka bir zincire bağlı olmayan onaylı bir işletmeniz yok.
            </p>
            <Link
              href="/sahip/isletmeler/yeni"
              className="rounded-xl bg-primary px-3 py-2 text-center text-sm font-bold text-white"
            >
              Yeni İşletme Başvurusu Yap
            </Link>
            <button
              type="button"
              onClick={onCancel}
              className="rounded-xl border border-border px-3 py-2 text-sm font-bold text-textStrong cursor-pointer"
            >
              Kapat
            </button>
          </div>
        )}

        {businesses !== null && businesses.length > 0 && (
          <form onSubmit={handleSubmit} className="flex flex-col gap-3">
            <div className="flex flex-col gap-1">
              <label className="text-xs font-bold text-muted">İşletme</label>
              <select
                value={selectedId}
                onChange={(e) => setSelectedId(e.target.value)}
                required
                className="rounded-xl border border-border bg-bg px-3 py-2 text-sm text-textStrong"
              >
                <option value="">Bir işletme seçin</option>
                {businesses.map((b) => (
                  <option key={b.business_id} value={b.business_id}>
                    {b.name} {b.city ? `(${b.city})` : ''}
                  </option>
                ))}
              </select>
            </div>

            <div className="flex flex-col gap-1">
              <label className="text-xs font-bold text-muted">Şube Etiketi (opsiyonel)</label>
              <input
                value={branchLabel}
                onChange={(e) => setBranchLabel(e.target.value)}
                placeholder="örn. Kadıköy Şubesi"
                className="rounded-xl border border-border bg-bg px-3 py-2 text-sm text-textStrong placeholder:text-muted"
              />
            </div>

            {error && <p className="text-xs font-bold text-red-600">{error}</p>}

            <div className="flex gap-2 pt-2">
              <button
                type="submit"
                disabled={isPending}
                className="rounded-xl bg-primary px-3 py-2 text-xs font-bold text-white disabled:opacity-60 cursor-pointer"
              >
                {isPending ? 'Ekleniyor...' : 'Şubeyi Ekle'}
              </button>
              <button
                type="button"
                onClick={onCancel}
                className="rounded-xl border border-border px-3 py-2 text-xs font-bold text-textStrong cursor-pointer"
              >
                İptal
              </button>
            </div>
          </form>
        )}
      </div>
    </div>
  );
}
```

- [ ] **Step 2: Typecheck**

Run: `cd uygulamalar/web && pnpm run typecheck`
Expected: PASS.

- [ ] **Step 3: Commit**

```bash
git add uygulamalar/web/app/sahip/coklu-sube/bilesenler/yeni-sube-ekle-formu.tsx
git commit -m "feat(web): çoklu şube — yeni şube ekle modalı"
```

---

### Task 11: Toplu Çalışma Saatleri modalı

**Files:**
- Create: `uygulamalar/web/app/sahip/coklu-sube/bilesenler/toplu-saat-formu.tsx`

- [ ] **Step 1: Bileşeni yaz**

```tsx
'use client';

import { useState, useTransition } from 'react';
import type { CokluSubeBranch } from '../coklu-sube-yardimcilari';
import { saatleriTopluUygula, type DayKey, type HoursTemplate } from '../coklu-sube-toplu-saat';

const DAYS: Array<{ key: DayKey; label: string }> = [
  { key: 'mon', label: 'Pazartesi' },
  { key: 'tue', label: 'Salı' },
  { key: 'wed', label: 'Çarşamba' },
  { key: 'thu', label: 'Perşembe' },
  { key: 'fri', label: 'Cuma' },
  { key: 'sat', label: 'Cumartesi' },
  { key: 'sun', label: 'Pazar' },
];

export function TopluSaatFormu({
  branches,
  onDone,
  onCancel,
}: {
  branches: CokluSubeBranch[];
  onDone: (successCount: number, failedCount: number) => void;
  onCancel: () => void;
}) {
  const [selectedIds, setSelectedIds] = useState<Set<string>>(new Set());
  const [openTime, setOpenTime] = useState('09:00');
  const [closeTime, setCloseTime] = useState('22:00');
  const [applyDays, setApplyDays] = useState<Set<DayKey>>(new Set(DAYS.map((d) => d.key)));
  const [error, setError] = useState<string | null>(null);
  const [isPending, startTransition] = useTransition();

  function toggleBusiness(id: string) {
    setSelectedIds((prev) => {
      const next = new Set(prev);
      if (next.has(id)) next.delete(id);
      else next.add(id);
      return next;
    });
  }

  function toggleDay(day: DayKey) {
    setApplyDays((prev) => {
      const next = new Set(prev);
      if (next.has(day)) next.delete(day);
      else next.add(day);
      return next;
    });
  }

  function handleSubmit(e: React.FormEvent<HTMLFormElement>) {
    e.preventDefault();
    if (selectedIds.size === 0) {
      setError('En az bir şube seçin');
      return;
    }
    setError(null);
    const template: HoursTemplate = {};
    for (const day of applyDays) {
      template[day] = { open: openTime, close: closeTime };
    }
    startTransition(async () => {
      const result = await saatleriTopluUygula([...selectedIds], template);
      onDone(result.successCount, result.failedBusinessIds.length);
    });
  }

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
      <div className="absolute inset-0 bg-black/30" onClick={onCancel} />
      <div className="relative z-10 w-full max-w-lg rounded-2xl bg-card p-5 shadow-2xl">
        <h2 className="mb-4 text-sm font-black text-textStrong">Çalışma Saatlerini Yönet</h2>
        <form onSubmit={handleSubmit} className="flex flex-col gap-4">
          <div>
            <p className="mb-2 text-xs font-bold text-muted">Şubeler</p>
            <div className="flex max-h-40 flex-col gap-1 overflow-y-auto rounded-xl border border-border p-2">
              {branches.map((b) => (
                <label key={b.business_id} className="flex items-center gap-2 text-sm text-textStrong cursor-pointer">
                  <input
                    type="checkbox"
                    checked={selectedIds.has(b.business_id)}
                    onChange={() => toggleBusiness(b.business_id)}
                    className="rounded"
                  />
                  {b.name}
                </label>
              ))}
            </div>
          </div>

          <div className="grid grid-cols-2 gap-3">
            <div className="flex flex-col gap-1">
              <label className="text-xs font-bold text-muted">Açılış</label>
              <input
                type="time"
                value={openTime}
                onChange={(e) => setOpenTime(e.target.value)}
                className="rounded-xl border border-border bg-bg px-3 py-2 text-sm text-textStrong"
              />
            </div>
            <div className="flex flex-col gap-1">
              <label className="text-xs font-bold text-muted">Kapanış</label>
              <input
                type="time"
                value={closeTime}
                onChange={(e) => setCloseTime(e.target.value)}
                className="rounded-xl border border-border bg-bg px-3 py-2 text-sm text-textStrong"
              />
            </div>
          </div>

          <div>
            <p className="mb-2 text-xs font-bold text-muted">Hangi günlere uygulanacak</p>
            <div className="flex flex-wrap gap-2">
              {DAYS.map((d) => (
                <button
                  key={d.key}
                  type="button"
                  onClick={() => toggleDay(d.key)}
                  className={`rounded-lg px-2.5 py-1 text-xs font-bold cursor-pointer ${
                    applyDays.has(d.key) ? 'bg-primary text-white' : 'border border-border text-muted'
                  }`}
                >
                  {d.label}
                </button>
              ))}
            </div>
          </div>

          {error && <p className="text-xs font-bold text-red-600">{error}</p>}

          <div className="flex gap-2 pt-2">
            <button
              type="submit"
              disabled={isPending}
              className="rounded-xl bg-primary px-3 py-2 text-xs font-bold text-white disabled:opacity-60 cursor-pointer"
            >
              {isPending ? 'Uygulanıyor...' : `${selectedIds.size} Şubeye Uygula`}
            </button>
            <button
              type="button"
              onClick={onCancel}
              className="rounded-xl border border-border px-3 py-2 text-xs font-bold text-textStrong cursor-pointer"
            >
              İptal
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}
```

- [ ] **Step 2: Typecheck**

Run: `cd uygulamalar/web && pnpm run typecheck`
Expected: PASS.

- [ ] **Step 3: Commit**

```bash
git add uygulamalar/web/app/sahip/coklu-sube/bilesenler/toplu-saat-formu.tsx
git commit -m "feat(web): çoklu şube — toplu çalışma saatleri modalı"
```

---

### Task 12: Toplu Kampanya modalı

**Files:**
- Create: `uygulamalar/web/app/sahip/coklu-sube/bilesenler/toplu-kampanya-formu.tsx`

- [ ] **Step 1: Bileşeni yaz**

```tsx
'use client';

import { useState, useTransition } from 'react';
import type { CokluSubeBranch } from '../coklu-sube-yardimcilari';
import { kampanyaTopluOlustur, type KampanyaSablonu } from '../coklu-sube-toplu-kampanya';

export function TopluKampanyaFormu({
  branches,
  onDone,
  onCancel,
}: {
  branches: CokluSubeBranch[];
  onDone: (successCount: number, failedCount: number) => void;
  onCancel: () => void;
}) {
  const [selectedIds, setSelectedIds] = useState<Set<string>>(new Set());
  const [error, setError] = useState<string | null>(null);
  const [isPending, startTransition] = useTransition();

  function toggleBusiness(id: string) {
    setSelectedIds((prev) => {
      const next = new Set(prev);
      if (next.has(id)) next.delete(id);
      else next.add(id);
      return next;
    });
  }

  function handleSubmit(e: React.FormEvent<HTMLFormElement>) {
    e.preventDefault();
    if (selectedIds.size === 0) {
      setError('En az bir şube seçin');
      return;
    }
    const fd = new FormData(e.currentTarget);
    const title = String(fd.get('title') ?? '').trim();
    if (!title) {
      setError('Kampanya başlığı boş olamaz');
      return;
    }
    setError(null);
    const template: KampanyaSablonu = {
      title,
      type: fd.get('type') as KampanyaSablonu['type'],
      status: 'draft',
      description: String(fd.get('description') ?? '') || undefined,
      discountPercent: fd.get('discount_percent') ? Number(fd.get('discount_percent')) : undefined,
    };
    startTransition(async () => {
      const result = await kampanyaTopluOlustur([...selectedIds], template);
      onDone(result.successCount, result.failedBusinessIds.length);
    });
  }

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
      <div className="absolute inset-0 bg-black/30" onClick={onCancel} />
      <div className="relative z-10 w-full max-w-lg rounded-2xl bg-card p-5 shadow-2xl">
        <h2 className="mb-4 text-sm font-black text-textStrong">Kampanya Ata</h2>
        <form onSubmit={handleSubmit} className="flex flex-col gap-4">
          <div>
            <p className="mb-2 text-xs font-bold text-muted">Şubeler</p>
            <div className="flex max-h-40 flex-col gap-1 overflow-y-auto rounded-xl border border-border p-2">
              {branches.map((b) => (
                <label key={b.business_id} className="flex items-center gap-2 text-sm text-textStrong cursor-pointer">
                  <input
                    type="checkbox"
                    checked={selectedIds.has(b.business_id)}
                    onChange={() => toggleBusiness(b.business_id)}
                    className="rounded"
                  />
                  {b.name}
                </label>
              ))}
            </div>
          </div>

          <div className="flex flex-col gap-1">
            <label className="text-xs font-bold text-muted">Başlık</label>
            <input
              name="title"
              required
              maxLength={120}
              placeholder="örn. Hafta Sonu %20 İndirim"
              className="rounded-xl border border-border bg-bg px-3 py-2 text-sm text-textStrong placeholder:text-muted"
            />
          </div>

          <div className="flex flex-col gap-1">
            <label className="text-xs font-bold text-muted">Tür</label>
            <select
              name="type"
              defaultValue="discount"
              className="rounded-xl border border-border bg-bg px-3 py-2 text-sm text-textStrong"
            >
              <option value="discount">İndirim</option>
              <option value="special_offer">Özel Teklif</option>
              <option value="loyalty">Sadakat</option>
              <option value="announcement">Duyuru</option>
            </select>
          </div>

          <div className="flex flex-col gap-1">
            <label className="text-xs font-bold text-muted">İndirim Yüzdesi (opsiyonel)</label>
            <input
              name="discount_percent"
              type="number"
              min={1}
              max={100}
              className="rounded-xl border border-border bg-bg px-3 py-2 text-sm text-textStrong"
            />
          </div>

          <div className="flex flex-col gap-1">
            <label className="text-xs font-bold text-muted">Açıklama (opsiyonel)</label>
            <textarea
              name="description"
              maxLength={500}
              rows={2}
              className="rounded-xl border border-border bg-bg px-3 py-2 text-sm text-textStrong"
            />
          </div>

          {error && <p className="text-xs font-bold text-red-600">{error}</p>}

          <div className="flex gap-2 pt-2">
            <button
              type="submit"
              disabled={isPending}
              className="rounded-xl bg-primary px-3 py-2 text-xs font-bold text-white disabled:opacity-60 cursor-pointer"
            >
              {isPending ? 'Oluşturuluyor...' : `${selectedIds.size} Şubeye Ata`}
            </button>
            <button
              type="button"
              onClick={onCancel}
              className="rounded-xl border border-border px-3 py-2 text-xs font-bold text-textStrong cursor-pointer"
            >
              İptal
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}
```

- [ ] **Step 2: Typecheck**

Run: `cd uygulamalar/web && pnpm run typecheck`
Expected: PASS.

- [ ] **Step 3: Commit**

```bash
git add uygulamalar/web/app/sahip/coklu-sube/bilesenler/toplu-kampanya-formu.tsx
git commit -m "feat(web): çoklu şube — toplu kampanya atama modalı"
```

---

### Task 13: Orkestratör + sayfa

**Files:**
- Create: `uygulamalar/web/app/sahip/coklu-sube/coklu-sube-istemcisi.tsx`
- Create: `uygulamalar/web/app/sahip/coklu-sube/page.tsx`

- [ ] **Step 1: Orkestratörü yaz**

`uygulamalar/web/app/sahip/coklu-sube/coklu-sube-istemcisi.tsx`:

```tsx
'use client';

import { useState } from 'react';
import type { CokluSubeOverview } from './coklu-sube-yardimcilari';
import { subeCikar, subeSirasiGuncelle } from './coklu-sube-islemleri';
import { IstatistikKartlari } from './bilesenler/istatistik-kartlari';
import { SubeTablosu } from './bilesenler/sube-tablosu';
import { SehirDagilimi } from './bilesenler/sehir-dagilimi';
import { ZincirOlusturFormu } from './bilesenler/zincir-olustur-formu';
import { YeniSubeEkleFormu } from './bilesenler/yeni-sube-ekle-formu';
import { TopluSaatFormu } from './bilesenler/toplu-saat-formu';
import { TopluKampanyaFormu } from './bilesenler/toplu-kampanya-formu';

type ActiveModal = 'yeni-sube' | 'toplu-saat' | 'toplu-kampanya' | null;

export function CokluSubeIstemcisi({
  businessId,
  initialOverview,
}: {
  businessId: string;
  initialOverview: CokluSubeOverview;
}) {
  const overview = initialOverview;
  const [activeModal, setActiveModal] = useState<ActiveModal>(null);
  const [error, setError] = useState<string | null>(null);
  const [bulkResult, setBulkResult] = useState<string | null>(null);
  const [reorderMode, setReorderMode] = useState(false);

  async function handleRemove(businessIdToRemove: string) {
    setError(null);
    const result = await subeCikar(businessIdToRemove);
    if (result?.error) setError(result.error);
  }

  async function handleReorder(businessIdToMove: string, newSortOrder: number) {
    setError(null);
    const result = await subeSirasiGuncelle(businessIdToMove, newSortOrder);
    if (result?.error) setError(result.error);
  }

  function handleBulkDone(kind: 'saat' | 'kampanya', successCount: number, failedCount: number) {
    setActiveModal(null);
    const label = kind === 'saat' ? 'Çalışma saatleri' : 'Kampanya';
    setBulkResult(
      failedCount === 0
        ? `${label} ${successCount} şubeye başarıyla uygulandı.`
        : `${label} ${successCount} şubeye uygulandı, ${failedCount} şubede hata oluştu.`,
    );
  }

  if (!overview.chain_id) {
    return <ZincirOlusturFormu businessId={businessId} onSuccess={() => setActiveModal(null)} />;
  }

  return (
    <div className="flex flex-col gap-6 lg:flex-row lg:items-start">
      <div className="flex min-w-0 flex-1 flex-col gap-6">
        <IstatistikKartlari overview={overview} />

        {error && <p className="text-xs font-bold text-red-600">{error}</p>}
        {bulkResult && <p className="rounded-xl bg-bg px-4 py-3 text-sm text-textStrong">{bulkResult}</p>}

        <div className="flex justify-end">
          <button
            type="button"
            onClick={() => setActiveModal('yeni-sube')}
            className="rounded-xl bg-primary px-3 py-2 text-sm font-bold text-white cursor-pointer"
          >
            + Yeni Şube Ekle
          </button>
        </div>

        <SubeTablosu
          branches={overview.branches}
          onRemove={handleRemove}
          onReorder={handleReorder}
          reorderMode={reorderMode}
        />
      </div>

      <div className="flex w-full flex-col gap-4 lg:w-80 lg:shrink-0">
        <SehirDagilimi branches={overview.branches} />

        <div className="rounded-2xl border border-border bg-card p-4">
          <h3 className="mb-3 text-sm font-black text-textStrong">Hızlı İşlemler</h3>
          <div className="flex flex-col gap-2">
            <button
              type="button"
              onClick={() => setReorderMode((prev) => !prev)}
              className={`rounded-xl border px-3 py-2 text-left text-xs font-bold cursor-pointer ${
                reorderMode ? 'border-primary bg-primary/10 text-primary' : 'border-border text-textStrong hover:bg-bg'
              }`}
            >
              {reorderMode ? 'Sıralamayı Bitir' : 'Şube Sıralamasını Düzenle'}
            </button>
            <button
              type="button"
              onClick={() => setActiveModal('toplu-saat')}
              className="rounded-xl border border-border px-3 py-2 text-left text-xs font-bold text-textStrong hover:bg-bg cursor-pointer"
            >
              Çalışma Saatlerini Yönet
            </button>
            <button
              type="button"
              onClick={() => setActiveModal('toplu-kampanya')}
              className="rounded-xl border border-border px-3 py-2 text-left text-xs font-bold text-textStrong hover:bg-bg cursor-pointer"
            >
              Kampanya Ata
            </button>
            <a
              href={`/sunucu/sahip/coklu-sube-rapor-csv?businessId=${businessId}`}
              className="rounded-xl border border-border px-3 py-2 text-left text-xs font-bold text-textStrong hover:bg-bg"
            >
              Raporu Dışa Aktar (CSV)
            </a>
          </div>
        </div>
      </div>

      {activeModal === 'yeni-sube' && (
        <YeniSubeEkleFormu
          chainId={overview.chain_id}
          onSuccess={() => setActiveModal(null)}
          onCancel={() => setActiveModal(null)}
        />
      )}
      {activeModal === 'toplu-saat' && (
        <TopluSaatFormu
          branches={overview.branches}
          onDone={(s, f) => handleBulkDone('saat', s, f)}
          onCancel={() => setActiveModal(null)}
        />
      )}
      {activeModal === 'toplu-kampanya' && (
        <TopluKampanyaFormu
          branches={overview.branches}
          onDone={(s, f) => handleBulkDone('kampanya', s, f)}
          onCancel={() => setActiveModal(null)}
        />
      )}
    </div>
  );
}
```

- [ ] **Step 2: Sayfayı yaz**

`uygulamalar/web/app/sahip/coklu-sube/page.tsx`:

Not: Owner'ın birden fazla, farklı zincirlere/hiç zincire bağlı olmayan işletmesi varsa, sayfa `getOwnerBusinessIds()[0]`'ı ("çapa" işletme) kullanır — bu basitleştirme V1 için kabul edilebilir (spec'te belgelendi).

```tsx
import type { Metadata } from 'next';
import { redirect } from 'next/navigation';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { getOwnerBusinessIds } from '@/src/lib/veri/owner/sahip-isletmeleri';
import { PanelSayfaBasligi } from '@/src/ui/yerlesim/panel-page-header';
import { PanelIcerikYuzeyi } from '@/src/ui/yerlesim/panel-section-card';
import { CokluSubeIstemcisi } from './coklu-sube-istemcisi';
import type { CokluSubeOverview } from './coklu-sube-yardimcilari';

export const metadata: Metadata = {
  title: 'Çoklu Şube Yönetimi | Sahip Paneli',
  robots: { index: false, follow: false },
};

export default async function CokluSubeSayfasi() {
  const supabase = await createSupabaseServerClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) redirect('/giris?redirect=%2Fsahip%2Fcoklu-sube');

  const businessIds = await getOwnerBusinessIds(supabase, user.id);
  const anchorBusinessId = businessIds[0];
  if (!anchorBusinessId) redirect('/sahip');

  const { data: overviewData } = await (supabase as any).rpc('owner_get_chain_overview_v1', {
    p_business_id: anchorBusinessId,
  });
  const overview = (overviewData ?? {
    chain_id: null,
    chain_name: null,
    branches: [],
    total_views: 0,
    total_reservations: 0,
  }) as CokluSubeOverview;

  return (
    <div className="flex flex-col">
      <PanelSayfaBasligi
        eyebrow="Çoklu Şube"
        title="Çoklu Şube Yönetimi"
        description="Tüm şubelerinizi yönetin, performanslarını takip edin ve detaylara hızlıca erişin."
      />
      <PanelIcerikYuzeyi className="pt-6">
        <CokluSubeIstemcisi businessId={anchorBusinessId} initialOverview={overview} />
      </PanelIcerikYuzeyi>
    </div>
  );
}
```

- [ ] **Step 3: Typecheck + lint**

Run: `cd uygulamalar/web && pnpm run typecheck && pnpm run lint`
Expected: İkisi de hatasız biter.

- [ ] **Step 4: Commit**

```bash
git add uygulamalar/web/app/sahip/coklu-sube/coklu-sube-istemcisi.tsx uygulamalar/web/app/sahip/coklu-sube/page.tsx
git commit -m "feat(web): çoklu şube — orkestratör + /sahip/coklu-sube sayfası"
```

---

### Task 14: Sidebar navigasyon

**Files:**
- Modify: `uygulamalar/web/src/ui/kabuk/sahip-kabuk-istemcisi.tsx`

- [ ] **Step 1: Nav öğesini ekle**

`'Yönetim'` bölümündeki `items` dizisinde, Task 10'da (Destek Sistemi planı) eklenen `/sahip/destek` satırından hemen önce ekle:

```tsx
      { href: '/sahip/coklu-sube', label: 'Çoklu Şube Yönetimi', icon: <ChoklusubeIcon /> },
      { href: '/sahip/destek', label: 'Destek', icon: <HeadsetIcon /> },
```

- [ ] **Step 2: İkon fonksiyonunu ekle**

`function HeadsetIcon()`'ın hemen üstüne veya altına ekle:

```tsx
function ChoklusubeIcon() {
  return (
    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <rect x="3" y="3" width="7" height="7" rx="1" />
      <rect x="14" y="3" width="7" height="7" rx="1" />
      <rect x="14" y="14" width="7" height="7" rx="1" />
      <rect x="3" y="14" width="7" height="7" rx="1" />
    </svg>
  );
}
```

- [ ] **Step 3: Typecheck**

Run: `cd uygulamalar/web && pnpm run typecheck`
Expected: PASS.

- [ ] **Step 4: Commit**

```bash
git add uygulamalar/web/src/ui/kabuk/sahip-kabuk-istemcisi.tsx
git commit -m "feat(web): çoklu şube — sahip panel sidebar'a Çoklu Şube Yönetimi nav öğesi ekle"
```

---

### Task 15: Son doğrulama

**Files:** Yok (sadece doğrulama)

- [ ] **Step 1: Tam doğrulama paketini çalıştır**

Run: `cd uygulamalar/web && pnpm run test:ci`
Expected: typecheck + lint + unit + build hepsi başarılı.

- [ ] **Step 2: Supabase migration zincirinin baştan sona temiz kurulduğunu doğrula**

Run: `supabase db reset`
Expected: Hatasız biter, `20260806000004_coklu_sube_owner` migration'ı sırayla uygulanır.

- [ ] **Step 3: RPC/RLS çapraz erişim testi**

Local Supabase'de iki farklı owner (A ve B, ikisinin de en az bir onaylı işletmesi olmalı) ile, `psql` + `set_config('request.jwt.claims', ...)` deseniyle:
1. Owner A `owner_create_chain_v1` ile kendi işletmesi için zincir oluşturur.
2. Owner B, Owner A'nın zincirine `owner_add_business_to_chain_v1` ile kendi işletmesini eklemeye çalışır (`p_chain_id` = A'nın zinciri) — reddedilmeli (A'nın zincirinde B'ye ait hiçbir işletme yok, "bu zincir üzerinde yetkiniz yok" hatası).
3. Owner A kendi başka bir onaylı işletmesini (varsa) aynı zincire ekler — başarılı olmalı.
4. Owner B, Owner A'nın işletmesini `owner_remove_business_from_chain_v1` ile çıkarmaya çalışır (`p_business_id` = A'nın işletmesi) — reddedilmeli.
5. Owner A kendi zincirinin genel bakışını `owner_get_chain_overview_v1` ile alır — doğru şube sayısı/istatistikler dönmeli.
6. Owner B aynı RPC'yi kendi (zincirsiz) işletmesiyle çağırır — `chain_id: null` ile boş sonuç dönmeli (hata değil).

- [ ] **Step 4: Dev server ile uçtan uca manuel senaryo**

`pnpm run dev` başlat (gerekiyorsa `supabase start`, ve `.env.local` yerine local Supabase URL/anon key ortam değişkenleriyle override edilerek — bu oturumda daha önce kullanılan yöntem), bir owner hesabıyla (en az 2 onaylı işletmesi olan):
1. `/sahip/coklu-sube` sayfasını aç — "Henüz bir zinciriniz yok" boş durumu görünüyor mu.
2. Zincir oluştur — sayfa şube tablosuna geçiyor mu, "Ana Şube" rozeti doğru işletmede mi.
3. "+ Yeni Şube Ekle" ile ikinci işletmeyi ekle — tabloda görünüyor mu, istatistik kartları güncellendi mi.
4. Sürükle-bırak ile şube sırasını değiştir — kalıcı mı (sayfa yenilendiğinde korunuyor mu).
5. "Çalışma Saatlerini Yönet" ile iki şubeyi seçip saat uygula — "X/Y başarılı" mesajı doğru mu, `/sahip/ayarlar/saatler` sayfasında (her iki işletme için ayrı ayrı) gerçekten kaydedildi mi.
6. "Kampanya Ata" ile aynı şekilde toplu kampanya oluştur — `/sahip/pazarlama/kampanyalar` sayfasında görünüyor mu.
7. "Raporu Dışa Aktar (CSV)" — dosya iniyor mu, içerik doğru mu.
8. Bir şubeyi zincirden çıkar — tablo güncelleniyor mu, `businesses.chain_id` gerçekten NULL oluyor mu.

Ortam bu testi desteklemiyorsa (`.env.local` production'a bağlıysa, local Supabase'de owner'ın 2 onaylı işletmesi yoksa vb.), bunu raporda açıkça belirt.

- [ ] **Step 5: Nihai commit (gerekirse temizlik)**

Doğrulama sırasında küçük düzeltmeler gerekirse, ayrı commit'ler halinde yap.

---

## Kapsam Dışı (bu planda yok — spec'in "Gelecek" bölümünde belgelendi)

- Owner'ın başka bir owner'ın zaten oluşturduğu bir zincire katılması (franchise senaryosu)
- Chain-menu-template özelliğiyle entegrasyon
- "Toplu Bilgi Güncelle" (hangi alanların toplu güncellenebilir olacağı net değildi, V1'den çıkarıldı)
