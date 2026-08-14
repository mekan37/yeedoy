# CRM v2 — Zincir-Çapında Birleşik Görünüm Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Zincirli (çoklu şube) bir owner'ın `/sahip/musteriler` liste ve detay/zaman çizelgesi sayfalarında tüm şubelerindeki müşterileri tek, birleşik bir görünümde görmesini sağlamak.

**Architecture:** Yeni bir `_resolve_chain_business_ids_v1(p_business_id)` SQL helper'ı (sadakat'teki `_resolve_loyalty_program_v1` deseninin aynısı) — işletme bir zincirdeyse ve çağıran zincirdeki HER şubede `menu_write` yetkisine sahipse zincirdeki tüm şube id'lerini, aksi halde sadece `[p_business_id]` döner. Mevcut `get_business_customers_v1` ve `get_customer_timeline_v1` RPC'lerinin iç `WHERE business_id = p_business_id` filtreleri `business_id = ANY(chain_ids)` olur — imza/dönüş şekli değişmediği için `_v2` gerekmiyor. `get_customer_timeline_v1` her olaya bir `branch_label` alanı ekler (hangi şubeden geldiği). Web tarafında liste sayfasına zincir açıklaması, detay sayfasına şube rozeti eklenir.

**Tech Stack:** Supabase/Postgres (plpgsql), Next.js 15 App Router (TypeScript), Vitest.

**Design doc:** `docs/superpowers/specs/2026-08-13-crm-v2-zincir-capinda-gorunum-design.md`

---

### Task 1: DB — `_resolve_chain_business_ids_v1` helper + RPC güncellemeleri

**Files:**
- Create: `supabase/migrations/20260813000001_crm_v2_zincir_capinda_gorunum.sql`

- [ ] **Step 1: Migration dosyasını oluştur**

```sql
-- CRM v2 — zincir-çapında birleşik görünüm. bkz.
-- docs/superpowers/specs/2026-08-13-crm-v2-zincir-capinda-gorunum-design.md
--
-- _resolve_loyalty_program_v1 (sadakat v1) ile aynı desen: verilen bir
-- business_id'nin ait olduğu zinciri çözümleyip zincir-çapında paylaşılan
-- veriye erişim sağlar. Fark: burada ayrıca çağıranın zincirdeki HER şubede
-- ayrı ayrı yetkili olup olmadığı kontrol ediliyor — business_team_memberships
-- "sadece bu şube" veya "tüm şubeler" (chain_id) kapsamında davet
-- destekliyor (canlı özellik, get_business_role_v1), "sadece bu şube"
-- kapsamlı bir manager'ın kardeş şubelere sızıntısı olmamalı.

-- ── Yardımcı: verilen business_id için zincir-çapında erişilebilir id'leri bul ──
CREATE OR REPLACE FUNCTION public._resolve_chain_business_ids_v1(p_business_id uuid)
RETURNS uuid[]
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_chain_id uuid;
BEGIN
  SELECT chain_id INTO v_chain_id FROM public.businesses WHERE id = p_business_id;

  IF v_chain_id IS NULL THEN
    RETURN ARRAY[p_business_id];
  END IF;

  IF EXISTS (
    SELECT 1 FROM public.businesses sib
    WHERE sib.chain_id = v_chain_id
      AND NOT public.has_business_permission_v1(sib.id, 'menu_write')
  ) THEN
    RETURN ARRAY[p_business_id];
  END IF;

  RETURN (SELECT array_agg(id) FROM public.businesses WHERE chain_id = v_chain_id);
END;
$$;

REVOKE ALL ON FUNCTION public._resolve_chain_business_ids_v1(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public._resolve_chain_business_ids_v1(uuid) TO authenticated;
REVOKE EXECUTE ON FUNCTION public._resolve_chain_business_ids_v1(uuid) FROM authenticated;
REVOKE EXECUTE ON FUNCTION public._resolve_chain_business_ids_v1(uuid) FROM anon;
COMMENT ON FUNCTION public._resolve_chain_business_ids_v1 IS
  'Internal: p_business_id bir zincirdeyse ve çağıran zincirdeki HER şubede menu_write yetkisine sahipse zincirdeki tüm business id''lerini döner, aksi halde sadece [p_business_id]. Called by: get_business_customers_v1, get_customer_timeline_v1.';

-- ── get_business_customers_v1 (genişletildi: zincir-çapında ANY(chain_ids)) ──
CREATE OR REPLACE FUNCTION public.get_business_customers_v1(p_business_id uuid)
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_program_id       uuid;
  v_reward_threshold int;
  v_chain_ids        uuid[];
BEGIN
  IF NOT public.has_business_permission_v1(p_business_id, 'menu_write') THEN
    RAISE EXCEPTION 'unauthorized' USING ERRCODE = 'P0002';
  END IF;

  v_chain_ids := public._resolve_chain_business_ids_v1(p_business_id);
  v_program_id := public._resolve_loyalty_program_v1(p_business_id);

  IF v_program_id IS NOT NULL THEN
    SELECT reward_threshold INTO v_reward_threshold FROM public.loyalty_programs WHERE id = v_program_id;
  END IF;

  RETURN COALESCE(
    (
      WITH customer_ids AS (
        SELECT user_id FROM public.reviews
          WHERE business_id = ANY(v_chain_ids) AND user_id IS NOT NULL AND status = 'approved'
        UNION
        SELECT user_id FROM public.reservations
          WHERE business_id = ANY(v_chain_ids) AND user_id IS NOT NULL
        UNION
        SELECT user_id FROM public.business_follows
          WHERE business_id = ANY(v_chain_ids)
        UNION
        SELECT lm.user_id FROM public.loyalty_members lm
          WHERE v_program_id IS NOT NULL AND lm.program_id = v_program_id
      ),
      summary AS (
        SELECT
          ci.user_id,
          (SELECT count(*) FROM public.reviews r
             WHERE r.business_id = ANY(v_chain_ids) AND r.user_id = ci.user_id AND r.status = 'approved') AS review_count,
          (SELECT count(*) FROM public.reservations rs
             WHERE rs.business_id = ANY(v_chain_ids) AND rs.user_id = ci.user_id) AS reservation_count,
          (SELECT lm.progress FROM public.loyalty_members lm
             WHERE v_program_id IS NOT NULL AND lm.program_id = v_program_id AND lm.user_id = ci.user_id) AS loyalty_progress,
          (SELECT coalesce(jsonb_agg(jsonb_build_object('id', ct.id, 'tag', ct.tag) ORDER BY ct.created_at), '[]'::jsonb)
             FROM public.customer_tags ct
             WHERE ct.business_id = ANY(v_chain_ids) AND ct.user_id = ci.user_id) AS tags,
          GREATEST(
            COALESCE((SELECT max(r.created_at) FROM public.reviews r
               WHERE r.business_id = ANY(v_chain_ids) AND r.user_id = ci.user_id AND r.status = 'approved'), 'epoch'::timestamptz),
            COALESCE((SELECT max(rs.created_at) FROM public.reservations rs
               WHERE rs.business_id = ANY(v_chain_ids) AND rs.user_id = ci.user_id), 'epoch'::timestamptz),
            COALESCE((SELECT max(bf.created_at) FROM public.business_follows bf
               WHERE bf.business_id = ANY(v_chain_ids) AND bf.user_id = ci.user_id), 'epoch'::timestamptz),
            COALESCE((SELECT max(le.created_at) FROM public.loyalty_events le
               JOIN public.loyalty_members lm2 ON lm2.id = le.member_id
               WHERE v_program_id IS NOT NULL AND lm2.program_id = v_program_id AND lm2.user_id = ci.user_id), 'epoch'::timestamptz)
          ) AS last_interaction_at
        FROM customer_ids ci
      )
      SELECT jsonb_agg(
        jsonb_build_object(
          'user_id', s.user_id,
          'display_name', coalesce(up.display_name, 'Kullanıcı'),
          'avatar_url', up.avatar_url,
          'last_interaction_at', s.last_interaction_at,
          'review_count', s.review_count,
          'reservation_count', s.reservation_count,
          'loyalty_progress', s.loyalty_progress,
          'loyalty_reward_threshold', v_reward_threshold,
          'tags', s.tags
        )
        ORDER BY s.last_interaction_at DESC
      )
      FROM summary s
      LEFT JOIN public.user_profiles up ON up.user_id = s.user_id
    ),
    '[]'::jsonb
  );
END;
$$;

-- ── get_customer_timeline_v1 (genişletildi: ANY(chain_ids) + branch_label) ──
CREATE OR REPLACE FUNCTION public.get_customer_timeline_v1(p_business_id uuid, p_user_id uuid)
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_program_id uuid;
  v_chain_ids  uuid[];
BEGIN
  IF NOT public.has_business_permission_v1(p_business_id, 'menu_write') THEN
    RAISE EXCEPTION 'unauthorized' USING ERRCODE = 'P0002';
  END IF;

  v_chain_ids := public._resolve_chain_business_ids_v1(p_business_id);
  v_program_id := public._resolve_loyalty_program_v1(p_business_id);

  RETURN COALESCE(
    (
      SELECT jsonb_agg(evt ORDER BY (evt->>'occurred_at')::timestamptz DESC)
      FROM (
        SELECT jsonb_build_object(
          'event_type', 'review',
          'occurred_at', r.created_at,
          'summary', r.rating || ' yıldız' || CASE WHEN r.title IS NOT NULL AND trim(r.title) <> '' THEN ' — "' || r.title || '"' ELSE '' END,
          'branch_label', (SELECT coalesce(nullif(trim(b.branch_label), ''), b.name) FROM public.businesses b WHERE b.id = r.business_id)
        ) AS evt
        FROM public.reviews r
        WHERE r.business_id = ANY(v_chain_ids) AND r.user_id = p_user_id AND r.status = 'approved'

        UNION ALL

        SELECT jsonb_build_object(
          'event_type', 'reservation',
          'occurred_at', rs.created_at,
          'summary', rs.party_size || ' kişi, ' || to_char(rs.reservation_date, 'DD.MM.YYYY') || ' ' || to_char(rs.reservation_time, 'HH24:MI'),
          'branch_label', (SELECT coalesce(nullif(trim(b.branch_label), ''), b.name) FROM public.businesses b WHERE b.id = rs.business_id)
        )
        FROM public.reservations rs
        WHERE rs.business_id = ANY(v_chain_ids) AND rs.user_id = p_user_id

        UNION ALL

        SELECT jsonb_build_object(
          'event_type', CASE WHEN le.source = 'redeem' THEN 'loyalty_redeem' ELSE 'loyalty_scan' END,
          'occurred_at', le.created_at,
          'summary', CASE WHEN le.source = 'redeem' THEN 'Ödül kullanıldı' ELSE '+' || le.amount || ' ilerleme' END,
          'branch_label', NULL
        )
        FROM public.loyalty_events le
        JOIN public.loyalty_members lm ON lm.id = le.member_id
        WHERE v_program_id IS NOT NULL AND lm.program_id = v_program_id AND lm.user_id = p_user_id

        UNION ALL

        SELECT jsonb_build_object(
          'event_type', 'follow',
          'occurred_at', bf.created_at,
          'summary', 'İşletmeyi takip etmeye başladı',
          'branch_label', (SELECT coalesce(nullif(trim(b.branch_label), ''), b.name) FROM public.businesses b WHERE b.id = bf.business_id)
        )
        FROM public.business_follows bf
        WHERE bf.business_id = ANY(v_chain_ids) AND bf.user_id = p_user_id

        UNION ALL

        SELECT jsonb_build_object(
          'event_type', 'note',
          'occurred_at', cn.created_at,
          'summary', cn.note,
          'branch_label', (SELECT coalesce(nullif(trim(b.branch_label), ''), b.name) FROM public.businesses b WHERE b.id = cn.business_id)
        )
        FROM public.customer_notes cn
        WHERE cn.business_id = ANY(v_chain_ids) AND cn.user_id = p_user_id
      ) sub
    ),
    '[]'::jsonb
  );
END;
$$;
```

**Not 1:** Sadakat (`loyalty_events`) olaylarının şema seviyesinde `business_id` kolonu yok (program zaten zincir-çapında paylaşılan tek bir kayıt, hangi fiziksel şubede tarandığı izlenmiyor) — bu yüzden `branch_label` bu olay tipi için her zaman `NULL` döner. Bu bilinçli bir sınır, UI tarafında `NULL` durumunda rozet render edilmez.

**Not 2:** `_resolve_chain_business_ids_v1` için `REVOKE EXECUTE ... FROM anon` satırı bilerek eklendi — Supabase yeni oluşturulan fonksiyonlara varsayılan olarak `anon`'a doğrudan EXECUTE veriyor, `REVOKE ALL ... FROM PUBLIC` bu ayrı doğrudan grant'ı kaldırmıyor (aynı boşluk `_resolve_loyalty_program_v1`'de de yaşanmış, `20260810000006_sadakat_v1_revoke_anon_execute.sql` ile ayrıca kapatılmıştı — bu sefer baştan doğru yazıldı).

- [ ] **Step 2: Local doğrulama**

Run: `supabase db reset`
Expected: Tüm migration'lar (bu dosya dahil) hatasız uygulanır.

- [ ] **Step 3: Commit**

```bash
git add supabase/migrations/20260813000001_crm_v2_zincir_capinda_gorunum.sql
git commit -m "feat(db): CRM v2 — zincir-çapında birleşik müşteri görünümü RPC'leri"
```

---

### Task 2: DB — advisors + manuel RPC smoke test (yetkilendirme dahil)

**Files:** (yalnızca doğrulama, dosya değişikliği yok)

- [ ] **Step 1: Supabase advisors kontrolü**

`mcp__supabase__get_advisors` (tip: `security`) çalıştır.
Expected: `_resolve_chain_business_ids_v1`, `get_business_customers_v1`, `get_customer_timeline_v1` için (RLS eksikliği, GRANT fazlalığı vb.) yeni bir uyarı çıkmaz.

- [ ] **Step 2: `has_function_privilege` ile GRANT durumunu doğrudan doğrula**

Local Supabase Studio SQL editöründen (veya `psql`):

```sql
select
  has_function_privilege('anon', 'public._resolve_chain_business_ids_v1(uuid)', 'execute') as anon_can_call,
  has_function_privilege('authenticated', 'public._resolve_chain_business_ids_v1(uuid)', 'execute') as authenticated_can_call;
```

Expected: İkisi de `false` (helper sadece internal çağrılarla, definer yetkisiyle çalışır — advisor cache'ine güvenilmez, doğrudan doğrulanır).

- [ ] **Step 3: Yetkilendirme senaryolarını test için test verisi kur**

Local Supabase Studio SQL editöründen, gerçek bir owner test kullanıcısı (`<owner_user_id>`), bir "tüm şubeler" kapsamlı manager test kullanıcısı (`<all_branches_manager_id>`) ve bir "sadece bu şube" kapsamlı manager test kullanıcısı (`<single_branch_manager_id>`) local Auth'tan oluşturulduktan sonra:

```sql
-- Zincir + 2 şube
insert into public.chains (id, name) values
  ('c1111111-1111-1111-1111-111111111111', 'Test Zinciri');

insert into public.businesses (id, owner_id, name, slug, public_slug, city, district, address, phone, currency, is_active, chain_id, branch_label)
values
  ('b1111111-1111-1111-1111-111111111111', '<owner_user_id>', 'Test Şube A', 'test-sube-a', 'test-sube-a', 'Istanbul', 'Kadikoy', 'A Sok. 1', '+90 555 000 00 01', 'TRY', true, 'c1111111-1111-1111-1111-111111111111', 'Kadıköy'),
  ('b2222222-2222-2222-2222-222222222222', '<owner_user_id>', 'Test Şube B', 'test-sube-b', 'test-sube-b', 'Istanbul', 'Besiktas', 'B Sok. 2', '+90 555 000 00 02', 'TRY', true, 'c1111111-1111-1111-1111-111111111111', 'Beşiktaş');

insert into public.owner_claims (business_id, user_id, status)
values
  ('b1111111-1111-1111-1111-111111111111', '<owner_user_id>', 'approved'),
  ('b2222222-2222-2222-2222-222222222222', '<owner_user_id>', 'approved');

-- Aynı müşteri her iki şubeye de yorum bırakmış
insert into public.reviews (business_id, user_id, rating, status, created_at)
values
  ('b1111111-1111-1111-1111-111111111111', '<customer_user_id>', 5, 'approved', now() - interval '2 days'),
  ('b2222222-2222-2222-2222-222222222222', '<customer_user_id>', 4, 'approved', now() - interval '1 day');

-- "Tüm şubeler" kapsamlı manager (chain_id set, business_id null)
insert into public.business_team_memberships (chain_id, user_id, role, created_by, accepted_at)
values ('c1111111-1111-1111-1111-111111111111', '<all_branches_manager_id>', 'manager', '<owner_user_id>', now());

-- "Sadece bu şube" (A) kapsamlı manager
insert into public.business_team_memberships (business_id, user_id, role, created_by, accepted_at)
values ('b1111111-1111-1111-1111-111111111111', '<single_branch_manager_id>', 'manager', '<owner_user_id>', now());
```

- [ ] **Step 4: `_resolve_chain_business_ids_v1`'i doğrudan çağırıp üç rolde ham diziyi doğrula**

Her çağrıdan önce ilgili kullanıcı olarak oturum simüle ederek:

```sql
select public._resolve_chain_business_ids_v1('b1111111-1111-1111-1111-111111111111');
```

Expected:
- Owner olarak → `{b1111111-1111-1111-1111-111111111111,b2222222-2222-2222-2222-222222222222}` (sıra önemsiz, iki id).
- "Tüm şubeler" manager olarak → aynı iki id.
- "Sadece bu şube" (A) manager olarak → `{b1111111-1111-1111-1111-111111111111}` (tek id).

- [ ] **Step 5: Üç rol için RPC'yi çağır ve doğrula**

Her çağrıdan önce `set local role authenticated; set local request.jwt.claim.sub = '<ilgili_user_id>';` ile o kullanıcı olarak oturum simüle et (veya uygulamadan gerçek oturumla test et):

```sql
-- Owner olarak: b1111111... üzerinden çağır
select public.get_business_customers_v1('b1111111-1111-1111-1111-111111111111');
```

Expected: Tek satır, `review_count = 2` (her iki şubeden), `<customer_user_id>` — zincir-çapında birleşmiş.

```sql
-- "Tüm şubeler" manager olarak: aynı çağrı
select public.get_business_customers_v1('b1111111-1111-1111-1111-111111111111');
```

Expected: Owner ile aynı sonuç — `review_count = 2`.

```sql
-- "Sadece bu şube" (A) manager olarak: aynı çağrı
select public.get_business_customers_v1('b1111111-1111-1111-1111-111111111111');
```

Expected: `review_count = 1` (sadece A şubesinden) — B şubesindeki yoruma sızıntı yok.

- [ ] **Step 6: Test verisini temizle**

```sql
delete from public.businesses where chain_id = 'c1111111-1111-1111-1111-111111111111';
delete from public.chains where id = 'c1111111-1111-1111-1111-111111111111';
```

Expected: `ON DELETE CASCADE` ile ilişkili `reviews`/`owner_claims`/`business_team_memberships` satırları da silinir.

- [ ] **Step 7: Kullanıcıya rapor**

Advisors sonucu, GRANT doğrulaması ve üç rol senaryosunun sonucunu özetle.

---

### Task 3: Web — liste sayfasına zincir açıklaması

**Files:**
- Create: `uygulamalar/web/app/sahip/musteriler/musteriler-yardimcilari.ts`
- Create: `uygulamalar/web/test/lib/musteriler-yardimcilari.test.ts`
- Modify: `uygulamalar/web/app/sahip/musteriler/page.tsx`

- [ ] **Step 1: Write the failing test**

Create `uygulamalar/web/test/lib/musteriler-yardimcilari.test.ts`:

```typescript
import { describe, it, expect } from 'vitest';
import { zincirAciklamasiOlustur } from '@/app/sahip/musteriler/musteriler-yardimcilari';

describe('zincirAciklamasiOlustur', () => {
  it('zincirsizken temel açıklamayı döner', () => {
    expect(zincirAciklamasiOlustur(null)).toBe('İşletmenizle etkileşimi olan tüm müşteriler');
  });

  it('zincir adı varsa zincir ibaresini ekler', () => {
    expect(zincirAciklamasiOlustur('Demo Zinciri')).toBe(
      'İşletmenizle etkileşimi olan tüm müşteriler — Zincir çapında • Demo Zinciri',
    );
  });
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd uygulamalar/web && pnpm run test:unit -- musteriler-yardimcilari`
Expected: FAIL — `Cannot find module '@/app/sahip/musteriler/musteriler-yardimcilari'`.

- [ ] **Step 3: Implement the helper**

Create `uygulamalar/web/app/sahip/musteriler/musteriler-yardimcilari.ts`:

```typescript
export function zincirAciklamasiOlustur(zincirAdi: string | null): string {
  const temel = 'İşletmenizle etkileşimi olan tüm müşteriler';
  if (!zincirAdi) return temel;
  return `${temel} — Zincir çapında • ${zincirAdi}`;
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd uygulamalar/web && pnpm run test:unit -- musteriler-yardimcilari`
Expected: PASS — 2/2 tests green.

- [ ] **Step 5: `page.tsx`'e zincir sorgusu ve açıklama ekle**

Modify `uygulamalar/web/app/sahip/musteriler/page.tsx` — mevcut içerik:

```tsx
import type { Metadata } from 'next';
import { redirect } from 'next/navigation';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { getOwnerBusinessIds } from '@/src/lib/veri/owner/sahip-isletmeleri';
import { PanelSayfaBasligi } from '@/src/ui/yerlesim/panel-page-header';
import { PanelIcerikYuzeyi } from '@/src/ui/yerlesim/panel-section-card';
import { MusteriListesi, type MusteriOzet } from './musteri-listesi';

export const metadata: Metadata = {
  title: 'Müşteriler | Sahip Paneli',
  robots: { index: false, follow: false },
};

export default async function MusterilerSayfasi() {
  const supabase = await createSupabaseServerClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) redirect('/giris?redirect=/sahip/musteriler');

  const businessIds = await getOwnerBusinessIds(supabase as any, user.id);
  const businessId = businessIds[0];
  if (!businessId) redirect('/sahip');

  const { data } = (await (supabase as any).rpc('get_business_customers_v1', {
    p_business_id: businessId,
  })) as { data: MusteriOzet[] | null };

  return (
    <div className="flex flex-col gap-6">
      <PanelSayfaBasligi
        eyebrow="Müşteriler"
        title="Müşteriler"
        description="İşletmenizle etkileşimi olan tüm müşteriler"
      />
      <PanelIcerikYuzeyi>
        <MusteriListesi musteriler={data ?? []} />
      </PanelIcerikYuzeyi>
    </div>
  );
}
```

Yeni içerikle değiştir:

```tsx
import type { Metadata } from 'next';
import { redirect } from 'next/navigation';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { getOwnerBusinessIds } from '@/src/lib/veri/owner/sahip-isletmeleri';
import { PanelSayfaBasligi } from '@/src/ui/yerlesim/panel-page-header';
import { PanelIcerikYuzeyi } from '@/src/ui/yerlesim/panel-section-card';
import { MusteriListesi, type MusteriOzet } from './musteri-listesi';
import { zincirAciklamasiOlustur } from './musteriler-yardimcilari';

export const metadata: Metadata = {
  title: 'Müşteriler | Sahip Paneli',
  robots: { index: false, follow: false },
};

export default async function MusterilerSayfasi() {
  const supabase = await createSupabaseServerClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) redirect('/giris?redirect=/sahip/musteriler');

  const businessIds = await getOwnerBusinessIds(supabase as any, user.id);
  const businessId = businessIds[0];
  if (!businessId) redirect('/sahip');

  const [{ data }, { data: businessChain }] = await Promise.all([
    (supabase as any).rpc('get_business_customers_v1', {
      p_business_id: businessId,
    }) as Promise<{ data: MusteriOzet[] | null }>,
    (supabase as any)
      .from('businesses')
      .select('chain_id, chains(name)')
      .eq('id', businessId)
      .maybeSingle() as Promise<{ data: { chain_id: string | null; chains: { name: string } | null } | null }>,
  ]);

  const zincirAdi = businessChain?.chains?.name ?? null;

  return (
    <div className="flex flex-col gap-6">
      <PanelSayfaBasligi
        eyebrow="Müşteriler"
        title="Müşteriler"
        description={zincirAciklamasiOlustur(zincirAdi)}
      />
      <PanelIcerikYuzeyi>
        <MusteriListesi musteriler={data ?? []} />
      </PanelIcerikYuzeyi>
    </div>
  );
}
```

- [ ] **Step 6: Typecheck and lint**

Run: `cd uygulamalar/web && pnpm run typecheck && pnpm run lint`
Expected: no new errors.

- [ ] **Step 7: Commit**

```bash
git add uygulamalar/web/app/sahip/musteriler/musteriler-yardimcilari.ts uygulamalar/web/test/lib/musteriler-yardimcilari.test.ts uygulamalar/web/app/sahip/musteriler/page.tsx
git commit -m "feat(web): CRM v2 — müşteri listesinde zincir-çapında açıklama"
```

---

### Task 4: Web — zaman çizelgesinde şube rozeti

**Files:**
- Modify: `uygulamalar/web/app/sahip/musteriler/[user_id]/zaman-cizelgesi.tsx`
- Modify: `uygulamalar/web/app/sahip/musteriler/[user_id]/page.tsx`

- [ ] **Step 1: `ZamanCizelgesiOlayi` tipine `branch_label` ekle, rozet render et**

Modify `uygulamalar/web/app/sahip/musteriler/[user_id]/zaman-cizelgesi.tsx` — mevcut içerik:

```tsx
export type ZamanCizelgesiOlayi = {
  event_type: 'review' | 'reservation' | 'loyalty_scan' | 'loyalty_redeem' | 'follow' | 'note';
  occurred_at: string;
  summary: string;
};

const OLAY_ETIKETLERI: Record<ZamanCizelgesiOlayi['event_type'], string> = {
  review: '⭐ Yorum yaptı',
  reservation: '📅 Rezervasyon',
  loyalty_scan: '🎁 Sadakat',
  loyalty_redeem: '🎁 Ödül',
  follow: '❤️ Takip',
  note: '📝 Not',
};

export function ZamanCizelgesi({ olaylar }: { olaylar: ZamanCizelgesiOlayi[] }) {
  if (olaylar.length === 0) {
    return <p className="text-sm text-muted">Henüz kayıtlı bir etkileşim yok.</p>;
  }

  return (
    <ul className="flex flex-col gap-3">
      {olaylar.map((o, i) => (
        <li key={i} className="rounded-xl border border-border bg-card p-3">
          <p className="text-xs font-bold uppercase tracking-wide text-muted">
            {OLAY_ETIKETLERI[o.event_type]} — {new Date(o.occurred_at).toLocaleDateString('tr-TR')}
          </p>
          <p className="mt-1 text-sm text-textStrong">{o.summary}</p>
        </li>
      ))}
    </ul>
  );
}
```

Yeni içerikle değiştir:

```tsx
export type ZamanCizelgesiOlayi = {
  event_type: 'review' | 'reservation' | 'loyalty_scan' | 'loyalty_redeem' | 'follow' | 'note';
  occurred_at: string;
  summary: string;
  branch_label: string | null;
};

const OLAY_ETIKETLERI: Record<ZamanCizelgesiOlayi['event_type'], string> = {
  review: '⭐ Yorum yaptı',
  reservation: '📅 Rezervasyon',
  loyalty_scan: '🎁 Sadakat',
  loyalty_redeem: '🎁 Ödül',
  follow: '❤️ Takip',
  note: '📝 Not',
};

export function ZamanCizelgesi({
  olaylar,
  subeEtiketiGoster = false,
}: {
  olaylar: ZamanCizelgesiOlayi[];
  subeEtiketiGoster?: boolean;
}) {
  if (olaylar.length === 0) {
    return <p className="text-sm text-muted">Henüz kayıtlı bir etkileşim yok.</p>;
  }

  return (
    <ul className="flex flex-col gap-3">
      {olaylar.map((o, i) => (
        <li key={i} className="rounded-xl border border-border bg-card p-3">
          <p className="text-xs font-bold uppercase tracking-wide text-muted">
            {OLAY_ETIKETLERI[o.event_type]} — {new Date(o.occurred_at).toLocaleDateString('tr-TR')}
            {subeEtiketiGoster && o.branch_label && (
              <span className="ml-2 rounded-full bg-primary/10 px-2 py-0.5 text-[10px] font-bold normal-case tracking-normal text-primary">
                {o.branch_label}
              </span>
            )}
          </p>
          <p className="mt-1 text-sm text-textStrong">{o.summary}</p>
        </li>
      ))}
    </ul>
  );
}
```

- [ ] **Step 2: `page.tsx`'te zincir bilgisini sorgula ve `subeEtiketiGoster` prop'unu geç**

Modify `uygulamalar/web/app/sahip/musteriler/[user_id]/page.tsx` — mevcut içerik:

```tsx
import type { Metadata } from 'next';
import { redirect, notFound } from 'next/navigation';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { getOwnerBusinessIds } from '@/src/lib/veri/owner/sahip-isletmeleri';
import { PanelSayfaBasligi } from '@/src/ui/yerlesim/panel-page-header';
import { PanelIcerikYuzeyi, PanelBolumKarti } from '@/src/ui/yerlesim/panel-section-card';
import { ZamanCizelgesi, type ZamanCizelgesiOlayi } from './zaman-cizelgesi';
import { EtiketNotFormu } from './etiket-not-formu';
import type { MusteriOzet } from '../musteri-listesi';

export const metadata: Metadata = {
  title: 'Müşteri Profili | Sahip Paneli',
  robots: { index: false, follow: false },
};

export default async function MusteriDetaySayfasi({
  params,
}: {
  params: Promise<{ user_id: string }>;
}) {
  const { user_id: musteriId } = await params;
  const supabase = await createSupabaseServerClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) redirect('/giris?redirect=/sahip/musteriler');

  const businessIds = await getOwnerBusinessIds(supabase as any, user.id);
  const businessId = businessIds[0];
  if (!businessId) redirect('/sahip');

  const [{ data: musteriler }, { data: olaylar }] = await Promise.all([
    (supabase as any).rpc('get_business_customers_v1', { p_business_id: businessId }) as Promise<{
      data: MusteriOzet[] | null;
    }>,
    (supabase as any).rpc('get_customer_timeline_v1', {
      p_business_id: businessId,
      p_user_id: musteriId,
    }) as Promise<{ data: ZamanCizelgesiOlayi[] | null }>,
  ]);

  const musteri = (musteriler ?? []).find((m) => m.user_id === musteriId);
  if (!musteri) notFound();

  return (
    <div className="flex flex-col">
      <PanelSayfaBasligi eyebrow="Müşteriler" title={musteri.display_name} />
      <PanelIcerikYuzeyi className="pt-6">
        <div className="grid grid-cols-1 gap-5 md:grid-cols-[280px_1fr]">
          <PanelBolumKarti title="Müşteri Bilgileri">
            <div className="flex flex-col gap-2 text-sm">
              <p className="text-muted">Yorum: {musteri.review_count}</p>
              <p className="text-muted">Rezervasyon: {musteri.reservation_count}</p>
              {musteri.loyalty_progress !== null && (
                <p className="text-muted">
                  Sadakat ilerlemesi: {musteri.loyalty_progress}
                  {musteri.loyalty_reward_threshold !== null
                    ? ` / ${musteri.loyalty_reward_threshold}`
                    : ''}
                </p>
              )}
            </div>
            <EtiketNotFormu
              businessId={businessId}
              userId={musteriId}
              mevcutEtiketler={musteri.tags}
            />
          </PanelBolumKarti>
          <PanelBolumKarti title="Zaman Çizelgesi">
            <ZamanCizelgesi olaylar={olaylar ?? []} />
          </PanelBolumKarti>
        </div>
      </PanelIcerikYuzeyi>
    </div>
  );
}
```

Yeni içerikle değiştir:

```tsx
import type { Metadata } from 'next';
import { redirect, notFound } from 'next/navigation';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { getOwnerBusinessIds } from '@/src/lib/veri/owner/sahip-isletmeleri';
import { PanelSayfaBasligi } from '@/src/ui/yerlesim/panel-page-header';
import { PanelIcerikYuzeyi, PanelBolumKarti } from '@/src/ui/yerlesim/panel-section-card';
import { ZamanCizelgesi, type ZamanCizelgesiOlayi } from './zaman-cizelgesi';
import { EtiketNotFormu } from './etiket-not-formu';
import type { MusteriOzet } from '../musteri-listesi';

export const metadata: Metadata = {
  title: 'Müşteri Profili | Sahip Paneli',
  robots: { index: false, follow: false },
};

export default async function MusteriDetaySayfasi({
  params,
}: {
  params: Promise<{ user_id: string }>;
}) {
  const { user_id: musteriId } = await params;
  const supabase = await createSupabaseServerClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) redirect('/giris?redirect=/sahip/musteriler');

  const businessIds = await getOwnerBusinessIds(supabase as any, user.id);
  const businessId = businessIds[0];
  if (!businessId) redirect('/sahip');

  const [{ data: musteriler }, { data: olaylar }, { data: businessChain }] = await Promise.all([
    (supabase as any).rpc('get_business_customers_v1', { p_business_id: businessId }) as Promise<{
      data: MusteriOzet[] | null;
    }>,
    (supabase as any).rpc('get_customer_timeline_v1', {
      p_business_id: businessId,
      p_user_id: musteriId,
    }) as Promise<{ data: ZamanCizelgesiOlayi[] | null }>,
    (supabase as any)
      .from('businesses')
      .select('chain_id')
      .eq('id', businessId)
      .maybeSingle() as Promise<{ data: { chain_id: string | null } | null }>,
  ]);

  const musteri = (musteriler ?? []).find((m) => m.user_id === musteriId);
  if (!musteri) notFound();

  const zincirli = Boolean(businessChain?.chain_id);

  return (
    <div className="flex flex-col">
      <PanelSayfaBasligi eyebrow="Müşteriler" title={musteri.display_name} />
      <PanelIcerikYuzeyi className="pt-6">
        <div className="grid grid-cols-1 gap-5 md:grid-cols-[280px_1fr]">
          <PanelBolumKarti title="Müşteri Bilgileri">
            <div className="flex flex-col gap-2 text-sm">
              <p className="text-muted">Yorum: {musteri.review_count}</p>
              <p className="text-muted">Rezervasyon: {musteri.reservation_count}</p>
              {musteri.loyalty_progress !== null && (
                <p className="text-muted">
                  Sadakat ilerlemesi: {musteri.loyalty_progress}
                  {musteri.loyalty_reward_threshold !== null
                    ? ` / ${musteri.loyalty_reward_threshold}`
                    : ''}
                </p>
              )}
            </div>
            <EtiketNotFormu
              businessId={businessId}
              userId={musteriId}
              mevcutEtiketler={musteri.tags}
            />
          </PanelBolumKarti>
          <PanelBolumKarti title="Zaman Çizelgesi">
            <ZamanCizelgesi olaylar={olaylar ?? []} subeEtiketiGoster={zincirli} />
          </PanelBolumKarti>
        </div>
      </PanelIcerikYuzeyi>
    </div>
  );
}
```

- [ ] **Step 3: Typecheck and lint**

Run: `cd uygulamalar/web && pnpm run typecheck && pnpm run lint`
Expected: no new errors.

- [ ] **Step 4: Commit**

```bash
git add "uygulamalar/web/app/sahip/musteriler/[user_id]/zaman-cizelgesi.tsx" "uygulamalar/web/app/sahip/musteriler/[user_id]/page.tsx"
git commit -m "feat(web): CRM v2 — zaman çizelgesinde zincir-çapında şube rozeti"
```

---

### Task 5: Doğrulama — gerçek tarayıcı testi

**Files:** Yok (sadece manuel doğrulama, kod değişikliği yok).

- [ ] **Step 1: Dev server'ı başlat**

Run: `cd uygulamalar/web && pnpm run dev` (arka planda).

- [ ] **Step 2: Zincirli owner ile `/sahip/musteriler` ve detay sayfasını doğrula**

Task 2'de kurulan test verisiyle (veya benzer bir zincirli owner fikstürüyle) `<owner_user_id>` olarak giriş yap:
- `/sahip/musteriler` başlığının altında "Zincir çapında • Test Zinciri" ibaresi görünmeli.
- Her iki şubeye de yorum bırakmış test müşterisi listede **tek satır** olarak görünmeli, yorum sayısı 2 olmalı.
- Müşteriye tıklayınca detay sayfasında zaman çizelgesindeki her olayın yanında hangi şubeden geldiğini gösteren bir rozet ("Kadıköy" / "Beşiktaş") görünmeli.

- [ ] **Step 3: Zincirsiz owner ile regresyon kontrolü**

Zincire bağlı olmayan bir işletmesi olan bir owner ile giriş yap: liste sayfasında zincir ibaresi **görünmemeli**, zaman çizelgesinde şube rozeti **görünmemeli** (davranış bugünküyle birebir aynı).

- [ ] **Step 4: Dev server'ı durdur, tarayıcı sekmesini kapat**

- [ ] **Step 5: Kullanıcıya rapor**

Hangi senaryoların test edildiğini özetle. **Not:** Yerelde onaylı bir zincirli owner test hesabı yoksa (arama/filtre turunda karşılaşılan aynı kısıt), bu task atlanır ve Task 1-4'teki otomatik testler + Task 2'deki manuel SQL smoke test yeterli kabul edilir.

---

### Task 6: Son doğrulama

**Files:** (yalnızca doğrulama, dosya değişikliği yok)

- [ ] **Step 1: Tam web doğrulaması**

Run: `cd uygulamalar/web && pnpm run test:ci`
Expected: typecheck + lint + unit + build hepsi geçer.

- [ ] **Step 2: Supabase tip dosyalarını yeniden üret**

Run: `mcp__supabase__generate_typescript_types` (veya `supabase gen types typescript --local`), çıktıyı `uygulamalar/web/src/lib/supabase/database.types.ts`'e yaz.
Expected: `_resolve_chain_business_ids_v1` internal fonksiyon olduğu için tip dosyasında görünmez (beklenen); `get_business_customers_v1`/`get_customer_timeline_v1` dönüş tipleri değişmez (JSON dönüş tipleri zaten `jsonb`/`any` olarak temsil ediliyor).

- [ ] **Step 3: Kullanıcıya rapor**

Hangi senaryoların (zincirli owner, tüm-şubeler manager, tek-şube manager, zincirsiz owner) doğrulandığını ve hangi dosyaların değiştiğini özetle.
