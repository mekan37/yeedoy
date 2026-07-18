# Owner Denetim Kaydı Faz 1 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** `app/owner/(panel)/audit/` sayfasını, kullanıcının paylaştığı mockup'ın tasarımına göre çalışır hale getir — yeni bir `business_audit_log` tablosu, RLS, iki RPC (yazma + sayfalı/filtrelenmiş okuma) ve 12 aylık retention cron job'u ile (bkz. `docs/superpowers/specs/2026-07-17-owner-denetim-kaydi-faz1-design.md`). Bu Faz 1 — hiçbir owner-panel mutasyonu henüz bu tabloya yazmıyor (Faz 2, ayrı bir proje).

**Architecture:** Yeni SQL migration (tablo + RLS + 2 RPC + cron) mevcut `owner_claims`/`business_team_memberships`/`request_ip_v1()`/`request_header_v1()` altyapısını kullanır. `page.tsx` (server component) owner'ın erişebildiği tüm işletmeleri toplar ve `get_business_audit_log_v1` RPC'sini çağırır; `audit-client.tsx` (client component) filtre/tablo/sayfalamayı render eder.

**Tech Stack:** Supabase Postgres (plpgsql RPC'ler, RLS, pg_cron), Next.js 15 App Router server+client component ayrımı, Tailwind semantic token sınıfları (`text-textStrong`, `text-muted`, `border-border`, `bg-card` — bu sayfa ailesinin zaten kullandığı, CLAUDE.md'ye uygun konvansiyon).

---

## Dosya haritası

- **Create:** `supabase/migrations/20260717000001_business_audit_log.sql` — tablo, RLS, grants, `log_business_action_v1`, `get_business_audit_log_v1`, `purge_expired_business_audit_log` + pg_cron
- **Modify:** `uygulamalar/web/app/owner/(panel)/audit/page.tsx` (tüm dosya değiştirilecek — mevcut kırık sorgu tamamen kaldırılıyor)
- **Create:** `uygulamalar/web/app/owner/(panel)/audit/audit-client.tsx`

---

### Task 1: SQL migration — tablo, RLS, RPC'ler, retention cron

**Files:**
- Create: `supabase/migrations/20260717000001_business_audit_log.sql`

- [ ] **Step 1: Migration dosyasını oluştur**

`supabase/migrations/20260717000001_business_audit_log.sql`:

```sql
-- ============================================================
-- Part A: business_audit_log table
-- ============================================================

CREATE TABLE IF NOT EXISTS public.business_audit_log (
  id            UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id   UUID        NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
  actor_id      UUID        NOT NULL REFERENCES auth.users(id),
  actor_role    TEXT        NOT NULL,
  action        TEXT        NOT NULL,
  description   TEXT        NOT NULL,
  target_table  TEXT,
  target_id     UUID,
  target_label  TEXT,
  ip_address    TEXT,
  user_agent    TEXT,
  meta          JSONB       NOT NULL DEFAULT '{}'::jsonb,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_business_audit_log_business_created
  ON public.business_audit_log (business_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_business_audit_log_business_actor_created
  ON public.business_audit_log (business_id, actor_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_business_audit_log_business_action_created
  ON public.business_audit_log (business_id, action, created_at DESC);

ALTER TABLE public.business_audit_log ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "business_audit_log_select_owner_or_team" ON public.business_audit_log;
CREATE POLICY "business_audit_log_select_owner_or_team" ON public.business_audit_log
  FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.owner_claims oc
       WHERE oc.business_id = business_audit_log.business_id
         AND oc.user_id     = auth.uid()
         AND oc.status      = 'approved'
    )
    OR EXISTS (
      SELECT 1 FROM public.business_team_memberships btm
       WHERE btm.business_id  = business_audit_log.business_id
         AND btm.user_id      = auth.uid()
         AND btm.accepted_at IS NOT NULL
         AND btm.revoked_at  IS NULL
    )
  );

REVOKE ALL ON TABLE public.business_audit_log FROM PUBLIC;
GRANT SELECT ON TABLE public.business_audit_log TO authenticated;
-- No INSERT/UPDATE/DELETE grants to authenticated/anon — writes only via
-- log_business_action_v1 (SECURITY DEFINER). No update/delete path exists
-- at all for the app role, by design (immutability requirement).

COMMENT ON TABLE public.business_audit_log IS 'Owner-team audit trail: one row per tracked mutation performed by a business owner or active team member. Immutable — no UPDATE/DELETE grants exist. Written only via log_business_action_v1. Called by: owner panel Denetim Kaydı page.';


-- ============================================================
-- Part B: RPC log_business_action_v1 (write)
-- ============================================================

CREATE OR REPLACE FUNCTION public.log_business_action_v1(
  p_business_id  UUID,
  p_action       TEXT,
  p_description  TEXT,
  p_target_table TEXT DEFAULT NULL,
  p_target_id    UUID DEFAULT NULL,
  p_target_label TEXT DEFAULT NULL,
  p_meta         JSONB DEFAULT '{}'::jsonb
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_actor_role TEXT;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'unauthorized: Oturum açmanız gerekiyor' USING ERRCODE = 'P0002';
  END IF;

  IF EXISTS (
    SELECT 1 FROM public.owner_claims
     WHERE business_id = p_business_id
       AND user_id     = auth.uid()
       AND status      = 'approved'
  ) THEN
    v_actor_role := 'owner';
  ELSE
    SELECT role INTO v_actor_role
      FROM public.business_team_memberships
     WHERE business_id  = p_business_id
       AND user_id      = auth.uid()
       AND accepted_at IS NOT NULL
       AND revoked_at  IS NULL
     LIMIT 1;
  END IF;

  IF v_actor_role IS NULL THEN
    RAISE EXCEPTION 'unauthorized: Bu işletme için yetkiniz yok' USING ERRCODE = 'P0002';
  END IF;

  IF nullif(trim(coalesce(p_action, '')), '') IS NULL THEN
    RAISE EXCEPTION 'validation_error: action boş olamaz' USING ERRCODE = 'P0003';
  END IF;

  IF nullif(trim(coalesce(p_description, '')), '') IS NULL THEN
    RAISE EXCEPTION 'validation_error: description boş olamaz' USING ERRCODE = 'P0003';
  END IF;

  INSERT INTO public.business_audit_log (
    business_id, actor_id, actor_role, action, description,
    target_table, target_id, target_label, ip_address, user_agent, meta
  ) VALUES (
    p_business_id, auth.uid(), v_actor_role, p_action, p_description,
    p_target_table, p_target_id, p_target_label,
    public.request_ip_v1()::text, public.request_header_v1('user-agent'),
    coalesce(p_meta, '{}'::jsonb)
  );
END;
$$;

REVOKE ALL ON FUNCTION public.log_business_action_v1(
  UUID, TEXT, TEXT, TEXT, UUID, TEXT, JSONB
) FROM PUBLIC;

GRANT EXECUTE ON FUNCTION public.log_business_action_v1(
  UUID, TEXT, TEXT, TEXT, UUID, TEXT, JSONB
) TO authenticated;

COMMENT ON FUNCTION public.log_business_action_v1(
  UUID, TEXT, TEXT, TEXT, UUID, TEXT, JSONB
) IS 'Writes one immutable audit row for a business owner/team-member action. Captures actor role snapshot + IP/user-agent via request_ip_v1()/request_header_v1(). Called by: owner panel mutation server actions (Faz 2 — not yet wired up in Faz 1).';


-- ============================================================
-- Part C: RPC get_business_audit_log_v1 (read, paginated + filtered)
-- ============================================================

CREATE OR REPLACE FUNCTION public.get_business_audit_log_v1(
  p_business_ids UUID[],
  p_actor_id     UUID DEFAULT NULL,
  p_action       TEXT DEFAULT NULL,
  p_date_from    DATE DEFAULT NULL,
  p_date_to      DATE DEFAULT NULL,
  p_limit        INT  DEFAULT 10,
  p_offset       INT  DEFAULT 0
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_allowed_ids UUID[];
  v_limit       INT;
  v_total       INT;
  v_rows        JSONB;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'unauthorized: Oturum açmanız gerekiyor' USING ERRCODE = 'P0002';
  END IF;

  SELECT ARRAY(
    SELECT business_id FROM public.owner_claims
     WHERE user_id = auth.uid() AND status = 'approved'
    UNION
    SELECT business_id FROM public.business_team_memberships
     WHERE user_id = auth.uid() AND accepted_at IS NOT NULL AND revoked_at IS NULL
  ) INTO v_allowed_ids;

  v_limit := LEAST(GREATEST(p_limit, 1), 200);

  SELECT COUNT(*)
    INTO v_total
    FROM public.business_audit_log l
   WHERE l.business_id = ANY (p_business_ids)
     AND l.business_id = ANY (v_allowed_ids)
     AND (p_actor_id  IS NULL OR l.actor_id  = p_actor_id)
     AND (p_action    IS NULL OR l.action    = p_action)
     AND (p_date_from IS NULL OR l.created_at >= p_date_from)
     AND (p_date_to   IS NULL OR l.created_at <  (p_date_to + INTERVAL '1 day'));

  SELECT COALESCE(jsonb_agg(row_data), '[]'::jsonb)
    INTO v_rows
    FROM (
      SELECT jsonb_build_object(
        'id',               l.id,
        'created_at',       l.created_at,
        'actor_id',         l.actor_id,
        'actor_name',       COALESCE(up.display_name, 'Kullanıcı'),
        'actor_avatar_url', up.avatar_url,
        'actor_role',       l.actor_role,
        'action',           l.action,
        'description',      l.description,
        'target_table',     l.target_table,
        'target_id',        l.target_id,
        'target_label',     l.target_label,
        'ip_address',       l.ip_address,
        'business_id',      l.business_id,
        'business_name',    b.name
      ) AS row_data
      FROM public.business_audit_log l
      LEFT JOIN public.user_profiles up ON up.user_id = l.actor_id
      LEFT JOIN public.businesses    b  ON b.id        = l.business_id
     WHERE l.business_id = ANY (p_business_ids)
       AND l.business_id = ANY (v_allowed_ids)
       AND (p_actor_id  IS NULL OR l.actor_id  = p_actor_id)
       AND (p_action    IS NULL OR l.action    = p_action)
       AND (p_date_from IS NULL OR l.created_at >= p_date_from)
       AND (p_date_to   IS NULL OR l.created_at <  (p_date_to + INTERVAL '1 day'))
     ORDER BY l.created_at DESC
     LIMIT v_limit OFFSET p_offset
    ) sub;

  RETURN jsonb_build_object('rows', v_rows, 'total', v_total);
END;
$$;

REVOKE ALL ON FUNCTION public.get_business_audit_log_v1(
  UUID[], UUID, TEXT, DATE, DATE, INT, INT
) FROM PUBLIC;

GRANT EXECUTE ON FUNCTION public.get_business_audit_log_v1(
  UUID[], UUID, TEXT, DATE, DATE, INT, INT
) TO authenticated;

COMMENT ON FUNCTION public.get_business_audit_log_v1(
  UUID[], UUID, TEXT, DATE, DATE, INT, INT
) IS 'Returns paginated, filtered audit log rows across one or more owner-managed businesses. Filters: actor, action, date range. Returns {rows, total}. Called by: owner panel Denetim Kaydı page.';


-- ============================================================
-- Part D: Retention — purge rows older than 12 months (pg_cron, daily)
-- ============================================================

CREATE OR REPLACE FUNCTION public.purge_expired_business_audit_log()
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  DELETE FROM public.business_audit_log
   WHERE created_at < now() - interval '12 months';
END;
$$;

REVOKE ALL ON FUNCTION public.purge_expired_business_audit_log() FROM PUBLIC;

COMMENT ON FUNCTION public.purge_expired_business_audit_log() IS 'Deletes business_audit_log rows older than 12 months. Scheduled via pg_cron (business-audit-log-retention, daily 03:00). Called by: pg_cron only.';

-- ── pg_cron job (requires pg_cron extension to be enabled in Supabase) ──────
create extension if not exists pg_cron with schema extensions;

select cron.unschedule('business-audit-log-retention')
where exists (
  select 1 from cron.job where jobname = 'business-audit-log-retention'
);

select cron.schedule(
  'business-audit-log-retention',
  '0 3 * * *',                     -- daily at 03:00
  $cron$select public.purge_expired_business_audit_log();$cron$
);
```

> **Ortam notu (kullanıcı onayıyla değiştirildi):** Bu makinede Docker
> Desktop/yerel Supabase stack'i kullanılamadı; kullanıcı doğrudan bağlı
> **uzak/gerçek** Supabase projesine (`mcp__supabase__*` araçları,
> proje: `dktdnbeougrmhkzplbap`) migration uygulanmasını onayladı.
> Branching (`mcp__supabase__create_branch`) bu projede çalışmadı
> ("Project reference is missing" hatası) — bu yüzden izole bir dev
> branch YOK, doğrudan ana projeye uygulanıyor. Bu nedenle: (a) migration
> içeriği zaten Step 1'de dosyaya yazıldı ve sadece yeni nesneler
> ekliyor (mevcut hiçbir tabloyu/fonksiyonu değiştirmiyor/silmiyor —
> düşük riskli), (b) test verisi mutlaka Step son adımında temizlenmeli.

- [ ] **Step 2: Migration'ı uzak projeye uygula**

`mcp__supabase__apply_migration` aracını çağır:
- `name`: `business_audit_log`
- `query`: Step 1'de yazılan migration dosyasının TAM içeriği

Expected: Araç başarıyla döner, hata yok.

- [ ] **Step 3: RLS ve grants'i doğrula (`mcp__supabase__execute_sql`)**

```sql
SELECT table_name, privilege_type
  FROM information_schema.role_table_grants
 WHERE table_name = 'business_audit_log' AND grantee = 'authenticated';
```

Expected: Sadece `SELECT` satırı döner — `INSERT`/`UPDATE`/`DELETE` yok.

```sql
SELECT proname FROM pg_proc
 WHERE proname IN ('log_business_action_v1', 'get_business_audit_log_v1', 'purge_expired_business_audit_log');
```

Expected: Üç fonksiyonun üçü de listelenir.

```sql
SELECT jobname, schedule FROM cron.job WHERE jobname = 'business-audit-log-retention';
```

Expected: Bir satır döner, `schedule` = `0 3 * * *`. (Eğer `pg_cron`
uzantısı bu projede zaten etkin değilse ve `CREATE EXTENSION` izin
hatası verirse — Supabase Dashboard'da Database → Extensions'tan
`pg_cron`'un etkin olup olmadığını kontrol et; zaten etkinse migration
`create extension if not exists` sayesinde sorunsuz geçer.)

- [ ] **Step 4: `mcp__supabase__get_advisors` ile güvenlik taraması**

`type: "security"` ile çağır. Yeni `business_audit_log` tablosu/RLS
policy'siyle ilgili bir "Critical"/"High" bulgu OLMAMALI (RLS zaten
etkin ve policy tanımlı). Varsa bulguyu oku, gerekiyorsa migration'ı
düzelt ve Step 2'yi tekrarla.

- [ ] **Step 5: Test verisi oluştur (owner + işletme + approved claim)**

`mcp__supabase__execute_sql` ile:

```sql
INSERT INTO auth.users (id, email) VALUES
  ('11111111-1111-1111-1111-111111111111', 'test-owner-denetim-kaydi@example.com')
ON CONFLICT DO NOTHING;

INSERT INTO public.businesses (id, name, owner_id) VALUES
  ('22222222-2222-2222-2222-222222222222', 'Test Kafe (Denetim Kaydı)', '11111111-1111-1111-1111-111111111111')
ON CONFLICT DO NOTHING;

INSERT INTO public.owner_claims (business_id, user_id, status) VALUES
  ('22222222-2222-2222-2222-222222222222', '11111111-1111-1111-1111-111111111111', 'approved')
ON CONFLICT DO NOTHING;
```

Expected: Üç `INSERT` de hatasız çalışır.

- [ ] **Step 6: Yetkili owner olarak yazma+okuma RPC'lerini test et**

`auth.uid()` normalde gerçek bir JWT oturumundan okunur; `execute_sql` bir
service-role/postgres bağlantısı olduğundan `auth.uid()` NULL döner ve
RPC `unauthorized` fırlatır. Bunu aynı SQL çağrısı içinde `set_config`
ile simüle et (tek `execute_sql` çağrısında, tüm ifadeler aynı oturumda
çalışır):

```sql
SELECT set_config('request.jwt.claims', '{"sub":"11111111-1111-1111-1111-111111111111","role":"authenticated"}', true);
SET ROLE authenticated;

SELECT public.log_business_action_v1(
  '22222222-2222-2222-2222-222222222222'::uuid,
  'menu_item_updated',
  'Test: "Cheeseburger" adlı ürünün fiyatı güncellendi.',
  'menu_items', NULL, 'Menü Öğesi #TEST-1'
);

SELECT public.get_business_audit_log_v1(
  ARRAY['22222222-2222-2222-2222-222222222222']::uuid[]
);

RESET ROLE;
```

Expected:
- `log_business_action_v1` hatasız döner.
- `get_business_audit_log_v1` çağrısı `{"rows": [{...,"actor_role": "owner", "action": "menu_item_updated", ...}], "total": 1}` şeklinde tek bir JSONB değeri döner.

- [ ] **Step 7: Yetkisiz kullanıcı reddi testi**

Ayrı bir `execute_sql` çağrısı olarak (hata beklenir, bu normal):

```sql
SELECT set_config('request.jwt.claims', '{"sub":"33333333-3333-3333-3333-333333333333","role":"authenticated"}', true);
SET ROLE authenticated;

SELECT public.log_business_action_v1(
  '22222222-2222-2222-2222-222222222222'::uuid,
  'menu_item_updated', 'Yetkisiz deneme'
);
```

Expected: `unauthorized: Bu işletme için yetkiniz yok` hatası döner (bu
hata bekleniyor — araç hata gösterirse bu adım BAŞARILI demektir).

- [ ] **Step 8: Immutability testi (UPDATE reddi)**

```sql
SELECT set_config('request.jwt.claims', '{"sub":"11111111-1111-1111-1111-111111111111","role":"authenticated"}', true);
SET ROLE authenticated;

UPDATE public.business_audit_log SET description = 'değiştirildi' WHERE business_id = '22222222-2222-2222-2222-222222222222';
```

Expected: `permission denied for table business_audit_log` hatası
(bekleniyor — hata görülmesi bu adımın başarılı olduğu anlamına gelir).

- [ ] **Step 9: Test verisini MUTLAKA temizle (gerçek/paylaşılan proje!)**

```sql
DELETE FROM public.business_audit_log WHERE business_id = '22222222-2222-2222-2222-222222222222';
DELETE FROM public.owner_claims WHERE business_id = '22222222-2222-2222-2222-222222222222';
DELETE FROM public.businesses WHERE id = '22222222-2222-2222-2222-222222222222';
DELETE FROM auth.users WHERE id IN ('11111111-1111-1111-1111-111111111111', '33333333-3333-3333-3333-333333333333');
```

Bu adım atlanamaz — gerçek projede test kaydı bırakılmamalı. `execute_sql`
ile çalıştır ve dört `DELETE`'in de hatasız döndüğünü doğrula.

- [ ] **Step 10: Commit**

```bash
git add supabase/migrations/20260717000001_business_audit_log.sql
git commit -m "feat(db): business_audit_log tablosu + RLS + log/read RPC'leri + 12 ay retention cron"
```

---

### Task 2: `page.tsx` — server component

**Files:**
- Modify: `uygulamalar/web/app/owner/(panel)/audit/page.tsx` (tüm dosya değiştirilecek)

- [ ] **Step 1: Dosyanın tamamını aşağıdakiyle değiştir**

`uygulamalar/web/app/owner/(panel)/audit/page.tsx`:

```tsx
import type { Metadata } from 'next';
import { createSupabaseServerClient } from '@/src/lib/supabaseServer';
import { PanelPageHeader } from '@/src/ui/layout/panel-page-header';
import { PanelContentSurface } from '@/src/ui/layout/panel-section-card';
import { PanelEmptyState } from '@/src/ui/components/panel-empty-state';
import { PanelActionButton } from '@/src/ui/components/panel-action-button';
import { AuditClient } from './audit-client';
import type { AuditLogRow, MemberOption } from './audit-client';

export const metadata: Metadata = {
  title: 'Denetim Kaydı | Owner Panel',
  robots: { index: false, follow: false },
};

const PAGE_SIZE = 10;

type Props = {
  searchParams: Promise<{
    page?: string;
    actor?: string;
    action?: string;
    from?: string;
    to?: string;
  }>;
};

type BizJoinRow = { business_id: string; businesses: { id: string; name: string } | null };

export default async function OwnerAuditPage({ searchParams }: Props) {
  const { page: pageParam, actor, action, from, to } = await searchParams;
  const page = Math.max(1, Number(pageParam) || 1);

  const supabase = await createSupabaseServerClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return null;

  const [{ data: ownerBiz }, { data: teamBiz }, { data: ownProfile }] = await Promise.all([
    (supabase as any)
      .from('owner_claims')
      .select('business_id, businesses(id, name)')
      .eq('user_id', user.id)
      .eq('status', 'approved'),
    (supabase as any)
      .from('business_team_memberships')
      .select('business_id, businesses(id, name)')
      .eq('user_id', user.id)
      .not('accepted_at', 'is', null)
      .is('revoked_at', null),
    (supabase as any)
      .from('user_profiles')
      .select('user_id, display_name')
      .eq('user_id', user.id)
      .maybeSingle(),
  ]);

  const ownerRows = (ownerBiz ?? []) as BizJoinRow[];
  const teamRows = (teamBiz ?? []) as BizJoinRow[];

  const businessMap = new Map<string, string>();
  for (const r of [...ownerRows, ...teamRows]) {
    if (r.businesses) businessMap.set(r.businesses.id, r.businesses.name);
  }
  const businessIds = Array.from(businessMap.keys());

  if (businessIds.length === 0) {
    return (
      <div className="flex flex-col">
        <PanelPageHeader eyebrow="Owner" title="Denetim Kaydı" description="Ekip üyelerinizin yaptığı tüm işlemleri burada görüntüleyebilir ve filtreleyebilirsiniz." />
        <PanelContentSurface className="pt-6">
          <PanelEmptyState
            icon={<ShieldIcon />}
            title="İşletme bulunamadı"
            description="Denetim kaydını görmek için önce bir işletmeye erişiminiz olmalı."
          />
        </PanelContentSurface>
      </div>
    );
  }

  // ── Ekip üyeleri (Üye filtre dropdown'u için) ─────────────────────────────
  const { data: memberRows } = await (supabase as any)
    .from('business_team_memberships')
    .select('user_id, role, user_profiles(user_id, display_name)')
    .in('business_id', businessIds)
    .not('accepted_at', 'is', null)
    .is('revoked_at', null);

  type MemberJoinRow = { user_id: string; role: string; user_profiles: { user_id: string; display_name: string } | null };
  const memberMap = new Map<string, MemberOption>();

  // Owner'ın kendisi de listede olmalı (kendi eylemleri actor_role='owner' ile loglanır)
  const ownDisplayName = (ownProfile as { display_name: string } | null)?.display_name ?? 'Ben';
  memberMap.set(user.id, { user_id: user.id, display_name: ownDisplayName, role: 'owner' });

  for (const m of (memberRows ?? []) as MemberJoinRow[]) {
    if (!memberMap.has(m.user_id)) {
      memberMap.set(m.user_id, {
        user_id: m.user_id,
        display_name: m.user_profiles?.display_name ?? 'Kullanıcı',
        role: m.role,
      });
    }
  }
  const members = Array.from(memberMap.values());

  // ── Denetim kayıtlarını çek ────────────────────────────────────────────────
  const offset = (page - 1) * PAGE_SIZE;
  const { data: result } = await (supabase as any).rpc('get_business_audit_log_v1', {
    p_business_ids: businessIds,
    p_actor_id: actor || null,
    p_action: action || null,
    p_date_from: from || null,
    p_date_to: to || null,
    p_limit: PAGE_SIZE,
    p_offset: offset,
  });

  const logRows = (result?.rows ?? []) as AuditLogRow[];
  const total = (result?.total ?? 0) as number;

  return (
    <div className="flex flex-col">
      <PanelPageHeader
        eyebrow="Owner"
        title="Denetim Kaydı"
        description="Ekip üyelerinizin yaptığı tüm işlemleri burada görüntüleyebilir ve filtreleyebilirsiniz."
        actions={
          <>
            <PanelActionButton variant="secondary" disabled title="Yakında aktif olacak">Dışa Aktar</PanelActionButton>
            <PanelActionButton variant="primary" disabled title="Yakında aktif olacak">Denetim Raporu</PanelActionButton>
          </>
        }
      />
      <AuditClient
        logRows={logRows}
        total={total}
        page={page}
        pageSize={PAGE_SIZE}
        members={members}
        showBusinessColumn={businessIds.length > 1}
        filters={{ actor: actor ?? '', action: action ?? '', from: from ?? '', to: to ?? '' }}
      />
    </div>
  );
}

function ShieldIcon() {
  return (
    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z" />
    </svg>
  );
}
```

- [ ] **Step 2: Typecheck çalıştır (henüz `audit-client.tsx` yok, hata bekleniyor)**

Run: `cd uygulamalar/web && npm run typecheck`
Expected: FAIL — `Cannot find module './audit-client'` benzeri bir hata.
Bu beklenen bir ara durumdur — Task 3 düzeltecek.

- [ ] **Step 3: Commit etme** — Task 3 tamamlanmadan bu dosya tek başına derlenmez; Task 3'ün sonunda ikisi birlikte tek commit'te gönderilecek.

---

### Task 3: `audit-client.tsx` — client component

**Files:**
- Create: `uygulamalar/web/app/owner/(panel)/audit/audit-client.tsx`

- [ ] **Step 1: Dosyayı oluştur**

`uygulamalar/web/app/owner/(panel)/audit/audit-client.tsx`:

```tsx
'use client';

import { useRouter } from 'next/navigation';
import { useState } from 'react';
import { PanelSectionCard } from '@/src/ui/layout/panel-section-card';
import { PanelEmptyState } from '@/src/ui/components/panel-empty-state';

export type AuditLogRow = {
  id: string;
  created_at: string;
  actor_id: string;
  actor_name: string;
  actor_avatar_url: string | null;
  actor_role: string;
  action: string;
  description: string;
  target_table: string | null;
  target_id: string | null;
  target_label: string | null;
  ip_address: string | null;
  business_id: string;
  business_name: string | null;
};

export type MemberOption = { user_id: string; display_name: string; role: string };

interface Props {
  logRows: AuditLogRow[];
  total: number;
  page: number;
  pageSize: number;
  members: MemberOption[];
  showBusinessColumn: boolean;
  filters: { actor: string; action: string; from: string; to: string };
}

const ROLE_LABELS: Record<string, { label: string; className: string }> = {
  owner: { label: 'İşletme Sahibi', className: 'bg-red-50 text-red-700' },
  manager: { label: 'Yönetici', className: 'bg-purple-50 text-purple-700' },
  editor: { label: 'Editör', className: 'bg-blue-50 text-blue-700' },
  staff: { label: 'Personel', className: 'bg-zinc-100 text-zinc-600' },
  viewer: { label: 'İzleyici', className: 'bg-zinc-50 text-zinc-500' },
};

const ACTION_META: Record<string, { label: string; className: string; icon: React.ComponentType<{ className?: string }> }> = {
  menu_item_updated: { label: 'Menü öğesi güncellendi', className: 'bg-blue-50 text-blue-600', icon: PencilIcon },
  menu_item_created: { label: 'Yeni ürün eklendi', className: 'bg-emerald-50 text-emerald-600', icon: PlusIcon },
  menu_item_deleted: { label: 'Ürün silindi', className: 'bg-orange-50 text-orange-600', icon: TrashIcon },
  photo_uploaded: { label: 'Fotoğraf yüklendi', className: 'bg-purple-50 text-purple-600', icon: ImageIcon },
  business_info_updated: { label: 'İşletme bilgileri güncellendi', className: 'bg-slate-100 text-slate-600', icon: SettingsIcon },
  campaign_created: { label: 'Kampanya oluşturuldu', className: 'bg-pink-50 text-pink-600', icon: MegaphoneIcon },
  team_role_changed: { label: 'Ekip üyesi rolü değiştirildi', className: 'bg-teal-50 text-teal-600', icon: UsersIcon },
  review_replied: { label: 'Yorum yanıtlandı', className: 'bg-cyan-50 text-cyan-600', icon: MessageIcon },
  reservation_note_added: { label: 'Rezervasyon notu eklendi', className: 'bg-red-50 text-red-600', icon: LockIcon },
  qr_menu_previewed: { label: 'QR menü önizlendi', className: 'bg-zinc-100 text-zinc-600', icon: EyeIcon },
};

const ACTION_OPTIONS = Object.entries(ACTION_META).map(([key, meta]) => ({ key, label: meta.label }));

function buildPageNumbers(current: number, total: number): (number | '…')[] {
  if (total <= 7) return Array.from({ length: total }, (_, i) => i + 1);
  const pages = new Set<number>([1, 2, total - 1, total, current - 1, current, current + 1]);
  const sorted = Array.from(pages).filter((p) => p >= 1 && p <= total).sort((a, b) => a - b);
  const result: (number | '…')[] = [];
  let prev = 0;
  for (const p of sorted) {
    if (prev && p - prev > 1) result.push('…');
    result.push(p);
    prev = p;
  }
  return result;
}

export function AuditClient({ logRows, total, page, pageSize, members, showBusinessColumn, filters }: Props) {
  const router = useRouter();
  const [actor, setActor] = useState(filters.actor);
  const [action, setAction] = useState(filters.action);
  const [from, setFrom] = useState(filters.from);
  const [to, setTo] = useState(filters.to);

  function navigate(targetPage: number, overrides?: Partial<{ actor: string; action: string; from: string; to: string }>) {
    const params = new URLSearchParams();
    const a = overrides?.actor ?? actor;
    const ac = overrides?.action ?? action;
    const f = overrides?.from ?? from;
    const t = overrides?.to ?? to;
    if (a) params.set('actor', a);
    if (ac) params.set('action', ac);
    if (f) params.set('from', f);
    if (t) params.set('to', t);
    params.set('page', String(targetPage));
    router.push(`/owner/audit?${params.toString()}`);
  }

  const totalPages = Math.max(1, Math.ceil(total / pageSize));
  const pageNumbers = buildPageNumbers(page, totalPages);

  return (
    <div className="mx-auto w-full max-w-[1520px] px-6 pb-10 pt-2">
      {/* Filtre satırı */}
      <div className="mb-4 flex flex-wrap items-center gap-2">
        <input
          type="date"
          value={from}
          onChange={(e) => setFrom(e.target.value)}
          className="rounded-xl border border-border bg-card px-3 py-2 text-sm text-textStrong"
        />
        <span className="text-sm text-muted">—</span>
        <input
          type="date"
          value={to}
          onChange={(e) => setTo(e.target.value)}
          className="rounded-xl border border-border bg-card px-3 py-2 text-sm text-textStrong"
        />
        <select
          value={actor}
          onChange={(e) => setActor(e.target.value)}
          className="rounded-xl border border-border bg-card px-3 py-2 text-sm text-textStrong"
        >
          <option value="">Tüm Üyeler</option>
          {members.map((m) => (
            <option key={m.user_id} value={m.user_id}>{m.display_name}</option>
          ))}
        </select>
        <select
          value={action}
          onChange={(e) => setAction(e.target.value)}
          className="rounded-xl border border-border bg-card px-3 py-2 text-sm text-textStrong"
        >
          <option value="">Tüm İşlemler</option>
          {ACTION_OPTIONS.map((o) => (
            <option key={o.key} value={o.key}>{o.label}</option>
          ))}
        </select>
        <button
          onClick={() => navigate(1)}
          className="flex items-center gap-1.5 rounded-xl bg-primary px-4 py-2 text-sm font-[800] text-white transition hover:opacity-90"
        >
          <FilterIcon className="h-4 w-4" /> Filtrele
        </button>
      </div>

      {logRows.length === 0 ? (
        <PanelSectionCard>
          <PanelEmptyState
            icon={<ShieldIcon />}
            title="Denetim kaydı yok"
            description="Seçilen filtrelerle eşleşen bir kayıt bulunmuyor."
          />
        </PanelSectionCard>
      ) : (
        <PanelSectionCard noPadding>
          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead>
                <tr className="border-b border-border">
                  <th className="px-5 py-3 text-left text-xs font-[800] uppercase tracking-wide text-muted">Tarih & Saat</th>
                  <th className="px-5 py-3 text-left text-xs font-[800] uppercase tracking-wide text-muted">Kullanıcı</th>
                  {showBusinessColumn && (
                    <th className="px-5 py-3 text-left text-xs font-[800] uppercase tracking-wide text-muted">İşletme</th>
                  )}
                  <th className="px-5 py-3 text-left text-xs font-[800] uppercase tracking-wide text-muted">İşlem</th>
                  <th className="px-5 py-3 text-left text-xs font-[800] uppercase tracking-wide text-muted">Açıklama</th>
                  <th className="px-5 py-3 text-left text-xs font-[800] uppercase tracking-wide text-muted">İlgili Kayıt</th>
                  <th className="px-5 py-3 text-left text-xs font-[800] uppercase tracking-wide text-muted">IP Adresi</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-border">
                {logRows.map((log) => {
                  const roleConfig = ROLE_LABELS[log.actor_role] ?? ROLE_LABELS.viewer;
                  const actionConfig = ACTION_META[log.action];
                  const ActionIcon = actionConfig?.icon ?? EyeIcon;
                  return (
                    <tr key={log.id}>
                      <td className="whitespace-nowrap px-5 py-3 text-muted">
                        {new Date(log.created_at).toLocaleDateString('tr-TR', {
                          day: 'numeric', month: 'short', year: 'numeric', hour: '2-digit', minute: '2-digit',
                        })}
                      </td>
                      <td className="px-5 py-3">
                        <div className="flex items-center gap-2">
                          <Avatar name={log.actor_name} url={log.actor_avatar_url} />
                          <div>
                            <p className="font-[700] text-textStrong">{log.actor_name}</p>
                            <span className={`rounded-full px-2 py-0.5 text-[10px] font-[800] ${roleConfig.className}`}>
                              {roleConfig.label}
                            </span>
                          </div>
                        </div>
                      </td>
                      {showBusinessColumn && (
                        <td className="px-5 py-3 text-muted">{log.business_name ?? '—'}</td>
                      )}
                      <td className="px-5 py-3">
                        <div className="flex items-center gap-2">
                          <span className={`flex h-7 w-7 shrink-0 items-center justify-center rounded-lg ${actionConfig?.className ?? 'bg-zinc-100 text-zinc-600'}`}>
                            <ActionIcon className="h-3.5 w-3.5" />
                          </span>
                          <span className="font-[700] text-textStrong">{actionConfig?.label ?? log.action}</span>
                        </div>
                      </td>
                      <td className="max-w-[260px] px-5 py-3 text-muted">{log.description}</td>
                      <td className="px-5 py-3 text-muted">{log.target_label ?? '—'}</td>
                      <td className="whitespace-nowrap px-5 py-3 font-mono text-xs text-muted">{log.ip_address ?? '—'}</td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </div>
          <div className="flex flex-wrap items-center justify-between gap-3 border-t border-border px-5 py-3">
            <span className="text-xs text-muted">Toplam {total} işlem</span>
            <div className="flex items-center gap-1">
              <button
                disabled={page <= 1}
                onClick={() => navigate(page - 1)}
                className="flex h-7 w-7 items-center justify-center rounded-lg border border-border text-muted disabled:opacity-40"
              >
                <ChevLeftIcon className="h-3.5 w-3.5" />
              </button>
              {pageNumbers.map((p, i) =>
                p === '…' ? (
                  <span key={`ellipsis-${i}`} className="px-1 text-xs text-muted">…</span>
                ) : (
                  <button
                    key={p}
                    onClick={() => navigate(p)}
                    className={`flex h-7 w-7 items-center justify-center rounded-lg border text-[11px] font-[900] ${
                      p === page ? 'border-primary bg-primary text-white' : 'border-border text-muted hover:bg-black/[0.03]'
                    }`}
                  >
                    {p}
                  </button>
                ),
              )}
              <button
                disabled={page >= totalPages}
                onClick={() => navigate(page + 1)}
                className="flex h-7 w-7 items-center justify-center rounded-lg border border-border text-muted disabled:opacity-40"
              >
                <ChevRightIcon className="h-3.5 w-3.5" />
              </button>
            </div>
          </div>
        </PanelSectionCard>
      )}

      <div className="mt-4 flex items-center gap-2 rounded-2xl border border-border bg-card px-5 py-3 text-xs text-muted">
        <ShieldIcon className="h-4 w-4 shrink-0" />
        Denetim kayıtları 12 ay boyunca saklanır. Güvenliğiniz için bu kayıtlar düzenlenemez veya silinemez.
      </div>
    </div>
  );
}

function Avatar({ name, url }: { name: string; url: string | null }) {
  if (url) {
    return (
      // eslint-disable-next-line @next/next/no-img-element
      <img src={url} alt={name} className="h-8 w-8 rounded-full border border-border object-cover" />
    );
  }
  return (
    <div className="flex h-8 w-8 items-center justify-center rounded-full bg-primary text-[13px] font-[900] text-white">
      {name.charAt(0).toUpperCase()}
    </div>
  );
}

// ── Icons ─────────────────────────────────────────────────────────────────────
function ShieldIcon({ className = 'h-5 w-5' }: { className?: string }) {
  return <svg className={className} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z" /></svg>;
}
function FilterIcon({ className = 'h-4 w-4' }: { className?: string }) {
  return <svg className={className} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round"><polygon points="22 3 2 3 10 12.46 10 19 14 21 14 12.46 22 3" /></svg>;
}
function ChevLeftIcon({ className = 'h-4 w-4' }: { className?: string }) {
  return <svg className={className} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round"><polyline points="15 18 9 12 15 6" /></svg>;
}
function ChevRightIcon({ className = 'h-4 w-4' }: { className?: string }) {
  return <svg className={className} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round"><polyline points="9 6 15 12 9 18" /></svg>;
}
function PencilIcon({ className = 'h-4 w-4' }: { className?: string }) {
  return <svg className={className} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M17 3a2.85 2.83 0 1 1 4 4L7.5 20.5 2 22l1.5-5.5z" /></svg>;
}
function PlusIcon({ className = 'h-4 w-4' }: { className?: string }) {
  return <svg className={className} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round"><line x1="12" y1="5" x2="12" y2="19" /><line x1="5" y1="12" x2="19" y2="12" /></svg>;
}
function TrashIcon({ className = 'h-4 w-4' }: { className?: string }) {
  return <svg className={className} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><polyline points="3 6 5 6 21 6" /><path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2" /></svg>;
}
function ImageIcon({ className = 'h-4 w-4' }: { className?: string }) {
  return <svg className={className} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><rect x="3" y="3" width="18" height="18" rx="2" /><circle cx="8.5" cy="8.5" r="1.5" /><polyline points="21 15 16 10 5 21" /></svg>;
}
function SettingsIcon({ className = 'h-4 w-4' }: { className?: string }) {
  return <svg className={className} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><circle cx="12" cy="12" r="3" /><path d="M19.4 15a1.65 1.65 0 0 0 .33 1.82l.06.06a2 2 0 0 1-2.83 2.83l-.06-.06a1.65 1.65 0 0 0-1.82-.33 1.65 1.65 0 0 0-1 1.51V21a2 2 0 0 1-4 0v-.09A1.65 1.65 0 0 0 9 19.4a1.65 1.65 0 0 0-1.82.33l-.06.06a2 2 0 0 1-2.83-2.83l.06-.06A1.65 1.65 0 0 0 4.68 15a1.65 1.65 0 0 0-1.51-1H3a2 2 0 0 1 0-4h.09A1.65 1.65 0 0 0 4.6 9a1.65 1.65 0 0 0-.33-1.82l-.06-.06a2 2 0 0 1 2.83-2.83l.06.06A1.65 1.65 0 0 0 9 4.68a1.65 1.65 0 0 0 1-1.51V3a2 2 0 0 1 4 0v.09a1.65 1.65 0 0 0 1 1.51 1.65 1.65 0 0 0 1.82-.33l.06-.06a2 2 0 0 1 2.83 2.83l-.06.06A1.65 1.65 0 0 0 19.4 9a1.65 1.65 0 0 0 1.51 1H21a2 2 0 0 1 0 4h-.09a1.65 1.65 0 0 0-1.51 1z" /></svg>;
}
function MegaphoneIcon({ className = 'h-4 w-4' }: { className?: string }) {
  return <svg className={className} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M3 11l18-5v12L3 13v-2z" /><path d="M11.6 16.8a3 3 0 1 1-5.8-1.6" /></svg>;
}
function UsersIcon({ className = 'h-4 w-4' }: { className?: string }) {
  return <svg className={className} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2" /><circle cx="9" cy="7" r="4" /><path d="M23 21v-2a4 4 0 0 0-3-3.87" /><path d="M16 3.13a4 4 0 0 1 0 7.75" /></svg>;
}
function MessageIcon({ className = 'h-4 w-4' }: { className?: string }) {
  return <svg className={className} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z" /></svg>;
}
function LockIcon({ className = 'h-4 w-4' }: { className?: string }) {
  return <svg className={className} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><rect x="3" y="11" width="18" height="11" rx="2" /><path d="M7 11V7a5 5 0 0 1 10 0v4" /></svg>;
}
function EyeIcon({ className = 'h-4 w-4' }: { className?: string }) {
  return <svg className={className} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z" /><circle cx="12" cy="12" r="3" /></svg>;
}
```

- [ ] **Step 2: Typecheck çalıştır**

Run: `cd uygulamalar/web && npm run typecheck`
Expected: PASS — hata yok

- [ ] **Step 3: Lint çalıştır**

Run: `cd uygulamalar/web && npm run lint`
Expected: PASS için bu iki dosyada hata olmamalı. `<img>` satırı için
`eslint-disable-next-line @next/next/no-img-element` yorumu zaten eklendi
(bkz. `owner-dashboard-shell.tsx`'teki aynı desen), bu yüzden bu satırdan
uyarı gelmemeli.

- [ ] **Step 4: Commit (Task 2 + Task 3 birlikte)**

```bash
git add "uygulamalar/web/app/owner/(panel)/audit/page.tsx" "uygulamalar/web/app/owner/(panel)/audit/audit-client.tsx"
git commit -m "feat(web): owner denetim kaydı sayfasını mockup tasarımına göre yenile

business_audit_log RPC'lerine bağlı, filtre (tarih/üye/işlem türü) ve
sayfalama destekli yeni Denetim Kaydı sayfası. Faz 2'de owner panel
mutasyonlarına log_business_action_v1 çağrısı eklenene kadar sayfa
boş/az veriyle çalışır — bu kasıtlı."
```

---

### Task 4: Manuel doğrulama

**Files:** (yok — sadece çalıştırma)

- [ ] **Step 1: Uzak proje URL + publishable (anon) key'i al**

`mcp__supabase__get_project_url` ve `mcp__supabase__get_publishable_keys`
araçlarını çağır (bu Task 1'de kullandığımız aynı uzak proje).

- [ ] **Step 2: `.env.local` oluştur (yoksa)**

`uygulamalar/web/.env.local` dosyası yoksa oluştur:

```
NEXT_PUBLIC_SUPABASE_URL=<Step 1'den API URL>
NEXT_PUBLIC_SUPABASE_ANON_KEY=<Step 1'den publishable/anon key>
```

**Service role key'i BURAYA yazma** — bu gerçek bir projenin gizli
anahtarı, sadece public/anon key ile sınırlı kal (sayfa zaten normal
kullanıcı oturumu simülasyonuyla çalışacak, service role gerekmiyor).
`.env.local` zaten `.gitignore` içinde olmalı — commit etmeden önce
`git status` ile bu dosyanın izlenmediğini doğrula.

- [ ] **Step 3: Dev server'ı başlat**

Run: `cd uygulamalar/web && npm run dev`
Expected: Sunucu ayağa kalkar, port'u not al (3000 doluysa otomatik başka
porta geçer).

> **Ortam notu:** Bu proje uzak/gerçek bir Supabase projesine bağlı (yerel
> Docker stack yok — bkz. Task 1 notu). Bu yüzden Task 4'te YENİ bir
> gerçek test kullanıcısı/oturumu oluşturmuyoruz (paylaşılan projede auth
> kullanıcısı yaratmak/login akışını tetiklemek gereksiz risk). Bunun
> yerine sayfanın hatasız derlendiğini ve kimliksiz istekte beklenen
> davranışı (login'e yönlendirme, 500 hatası DEĞİL) gösterdiğini
> doğruluyoruz — bu, Task 1'in SQL-seviyesi doğrulamalarını (gerçek RPC
> çağrıları, RLS, immutability) tamamlayan hafif bir derleme/render
> kontrolüdür.

- [ ] **Step 4: `/owner/audit` route'unun derlendiğini ve hata vermediğini doğrula**

```bash
curl -s -D - -o /dev/null --max-time 8 http://localhost:<port>/owner/audit
```

Expected: `307`/`308` (login'e yönlendirme) veya `200` — **500 DEĞİL**. Dev
server log çıktısında bu route için bir derleme hatası (`Error:` satırı)
olmamalı. 500 alınırsa dev server log'undaki stack trace'i oku — eğer
hata `analytics` görevinde olduğu gibi sadece eksik env değişkeni
(`NEXT_PUBLIC_SUPABASE_URL` vb.) kaynaklıysa bu ortam kısıtıdır, kod
hatası değildir; farklı bir hata (ör. `page.tsx`/`audit-client.tsx`
içinde bir runtime hatası, prop tipi uyuşmazlığı) ise gerçek bir bug'dır
ve düzeltilmelidir.

- [ ] **Step 5: Dev server'ı durdur**

---

## Self-Review Notları

- **Spec kapsaması:** Spec'in tüm bölümleri (tablo, RLS, 2 RPC, retention
  cron, sayfa/filtre/tablo/sayfalama/alt not) Task 1-3'te karşılanıyor.
- **Tip tutarlılığı:** `AuditLogRow`/`MemberOption` tipleri tek yerde
  (`audit-client.tsx`) tanımlanıyor, `page.tsx` bunları import ediyor.
  RPC'nin JSONB `rows` alanındaki alan adları (`actor_name`,
  `actor_avatar_url`, `actor_role`, `target_label`, `business_name` vb.)
  `AuditLogRow` tipiyle birebir eşleşiyor.
- **Kapsam dışı hatırlatma:** Faz 2 (mutasyon noktalarına log çağrısı
  ekleme) bu planın kapsamında değil — sayfa Faz 1 sonunda çalışır ama
  gerçek işletmelerde veri birikene kadar çoğunlukla boş görünecektir.
