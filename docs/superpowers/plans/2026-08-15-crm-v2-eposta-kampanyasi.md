# CRM v2 — Etiket Bazlı Toplu E-posta Kampanyası Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Owner, CRM etiketlerine (veya mevcut 3 takipçi-segmentine) göre hedeflenmiş, gerçekten gönderilen (Resend), yasal olarak zorunlu abonelik-iptal linki içeren toplu e-posta kampanyaları oluşturabilsin.

**Architecture:** Alıcı çözümlemesi yeni bir `get_email_campaign_recipients_v1` RPC'sine taşınır (chain-wide görünümdeki `has_business_permission_v1` + üçlü-REVOKE deseniyle), çift onay filtresi (`marketing_email_opt_in` + duruma göre `is_subscribed_email`) düzeltilerek. Gönderim, yeniden etkinleştirilen bir route handler'da (`/sunucu/sahip/eposta-kampanya`) gerçekleşir — halihazırda canlı ve test edilmiş `unsubscribe-token.ts` altyapısını kullanarak. Yeni, bağımsız bir owner sayfası (`/sahip/pazarlama/eposta-kampanyalari`) eklenir — mevcut `/sahip/pazarlama/kampanyalar` (indirim duyuruları, ilgisiz bir özellik) sayfasına dokunulmaz.

**Tech Stack:** Supabase/Postgres (plpgsql), Next.js 15 App Router (TypeScript), Resend API (fetch, SDK yok), Vitest.

**Design doc:** `docs/superpowers/specs/2026-08-14-crm-v2-eposta-kampanya-design.md`

---

### Task 1: DB — alıcı çözümleme RPC'leri

**Files:**
- Create: `supabase/migrations/20260815000002_crm_v2_eposta_kampanyasi.sql`

- [ ] **Step 1: Migration dosyasını oluştur**

```sql
-- CRM v2 — etiket bazlı toplu e-posta kampanyası. bkz.
-- docs/superpowers/specs/2026-08-14-crm-v2-eposta-kampanya-design.md
--
-- email_campaigns tablosu ve create_email_campaign_v1/list_email_campaigns_v1/
-- estimate_email_segment_v1 RPC'leri zaten var (20260424000009_email_campaigns.sql).
-- Bu migration: (1) yeni bir alıcı-çözümleme RPC'si ekler — hem mevcut 3
-- takipçi-segmentini hem yeni tag:<etiket> segmentini destekler, her ikisinde
-- de user_profiles.marketing_email_opt_in taban filtresi zorunlu (eski
-- implementasyonda hiç yoktu — gerçek bir uyumluluk boşluğuydu); (2)
-- estimate_email_segment_v1'i aynı tag: önekini ve aynı çift-filtreyi
-- tanıyacak şekilde genişletir; (3) etiket dropdown'ı için list_customer_tags_v1.

-- ── get_email_campaign_recipients_v1 ────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.get_email_campaign_recipients_v1(
  p_business_id uuid,
  p_target_segment text
)
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_tag text;
BEGIN
  IF NOT public.has_business_permission_v1(p_business_id, 'menu_write') THEN
    RAISE EXCEPTION 'unauthorized' USING ERRCODE = 'P0002';
  END IF;

  IF p_target_segment LIKE 'tag:%' THEN
    v_tag := substring(p_target_segment FROM 5);

    RETURN COALESCE(
      (
        SELECT jsonb_agg(
          jsonb_build_object(
            'user_id', u.id,
            'email', u.email,
            'display_name', coalesce(up.display_name, 'Değerli Müşteri')
          )
        )
        FROM public.customer_tags ct
        JOIN auth.users u ON u.id = ct.user_id
        JOIN public.user_profiles up ON up.user_id = u.id
        WHERE ct.business_id = p_business_id
          AND ct.tag = v_tag
          AND up.marketing_email_opt_in = true
          AND u.email IS NOT NULL
      ),
      '[]'::jsonb
    );
  END IF;

  RETURN COALESCE(
    (
      SELECT jsonb_agg(
        jsonb_build_object(
          'user_id', u.id,
          'email', u.email,
          'display_name', coalesce(up.display_name, 'Değerli Müşteri')
        )
      )
      FROM public.business_follows bf
      JOIN auth.users u ON u.id = bf.user_id
      JOIN public.user_profiles up ON up.user_id = u.id
      WHERE bf.business_id = p_business_id
        AND bf.is_subscribed_email = true
        AND up.marketing_email_opt_in = true
        AND u.email IS NOT NULL
        AND (
          p_target_segment = 'all_followers'
          OR (p_target_segment = 'new_30d' AND bf.created_at >= now() - interval '30 days')
          OR (p_target_segment = 'inactive_30d' AND bf.created_at < now() - interval '30 days')
        )
    ),
    '[]'::jsonb
  );
END;
$$;

-- ── estimate_email_segment_v1 (genişletildi: tag: önekini tanır) ───────────
CREATE OR REPLACE FUNCTION public.estimate_email_segment_v1(
  p_business_id uuid,
  p_segment     text DEFAULT 'all_followers'
)
RETURNS int
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_tag text;
  v_count int;
BEGIN
  IF NOT public.has_business_permission_v1(p_business_id, 'menu_write') THEN
    RAISE EXCEPTION 'unauthorized' USING ERRCODE = 'P0002';
  END IF;

  IF p_segment LIKE 'tag:%' THEN
    v_tag := substring(p_segment FROM 5);
    SELECT count(*)::int INTO v_count
    FROM public.customer_tags ct
    JOIN auth.users u ON u.id = ct.user_id
    JOIN public.user_profiles up ON up.user_id = u.id
    WHERE ct.business_id = p_business_id
      AND ct.tag = v_tag
      AND up.marketing_email_opt_in = true
      AND u.email IS NOT NULL;
    RETURN v_count;
  END IF;

  SELECT count(*)::int INTO v_count
  FROM public.business_follows bf
  JOIN auth.users u ON u.id = bf.user_id
  JOIN public.user_profiles up ON up.user_id = u.id
  WHERE bf.business_id = p_business_id
    AND bf.is_subscribed_email = true
    AND up.marketing_email_opt_in = true
    AND u.email IS NOT NULL
    AND (
      p_segment = 'all_followers'
      OR (p_segment = 'new_30d'     AND bf.created_at >= now() - interval '30 days')
      OR (p_segment = 'inactive_30d' AND bf.created_at < now() - interval '30 days')
    );
  RETURN v_count;
END;
$$;

-- ── list_customer_tags_v1 (etiket dropdown veri kaynağı) ────────────────────
CREATE OR REPLACE FUNCTION public.list_customer_tags_v1(p_business_id uuid)
RETURNS text[]
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NOT public.has_business_permission_v1(p_business_id, 'menu_write') THEN
    RAISE EXCEPTION 'unauthorized' USING ERRCODE = 'P0002';
  END IF;

  RETURN COALESCE(
    (SELECT array_agg(DISTINCT tag ORDER BY tag) FROM public.customer_tags WHERE business_id = p_business_id),
    ARRAY[]::text[]
  );
END;
$$;

REVOKE ALL ON FUNCTION public.get_email_campaign_recipients_v1(uuid, text) FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION public.get_email_campaign_recipients_v1(uuid, text) FROM anon;
GRANT EXECUTE ON FUNCTION public.get_email_campaign_recipients_v1(uuid, text) TO authenticated;
COMMENT ON FUNCTION public.get_email_campaign_recipients_v1 IS
  'CRM v2 e-posta kampanyası: hedef segmentteki (takipçi ya da tag:) alıcıları, marketing_email_opt_in filtresiyle döner. Called by: app/sunucu/sahip/eposta-kampanya/route.ts.';

REVOKE ALL ON FUNCTION public.list_customer_tags_v1(uuid) FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION public.list_customer_tags_v1(uuid) FROM anon;
GRANT EXECUTE ON FUNCTION public.list_customer_tags_v1(uuid) TO authenticated;
COMMENT ON FUNCTION public.list_customer_tags_v1 IS
  'CRM v2 e-posta kampanyası: etiket dropdown''ı için distinct customer_tags.tag listesi. Called by: app/sahip/pazarlama/eposta-kampanyalari/page.tsx.';

-- estimate_email_segment_v1 zaten authenticated'a GRANT'lıydı (20260424000009);
-- CREATE OR REPLACE imzayı değiştirmediği için GRANT'ı korur, yeniden yazmaya gerek yok.
```

- [ ] **Step 2: Local doğrulama**

Run: `supabase db reset`
Expected: Tüm migration'lar (bu dosya dahil) hatasız uygulanır.

- [ ] **Step 3: Çift onay filtresi smoke test**

```bash
psql "postgresql://postgres:postgres@127.0.0.1:54322/postgres" <<'EOF'
insert into auth.users (id, email) values
  ('e1000000-0000-0000-0000-000000000001', 'owner@test.com'),
  ('e1000000-0000-0000-0000-000000000002', 'opted-in@test.com'),
  ('e1000000-0000-0000-0000-000000000003', 'opted-out@test.com');
insert into public.businesses (id, name, category, is_active) values
  ('c1000000-0000-0000-0000-000000000001', 'Test E-posta Isletme', 'restoran', true);
insert into public.owner_claims (business_id, user_id, status) values
  ('c1000000-0000-0000-0000-000000000001', 'e1000000-0000-0000-0000-000000000001', 'approved');

-- İki müşteri de VIP etiketli, ama sadece biri global pazarlama iznine sahip
insert into public.customer_tags (business_id, user_id, tag, created_by) values
  ('c1000000-0000-0000-0000-000000000001', 'e1000000-0000-0000-0000-000000000002', 'VIP', 'e1000000-0000-0000-0000-000000000001'),
  ('c1000000-0000-0000-0000-000000000001', 'e1000000-0000-0000-0000-000000000003', 'VIP', 'e1000000-0000-0000-0000-000000000001');
update public.user_profiles set marketing_email_opt_in = true, marketing_email_opted_in_at = now()
  where user_id = 'e1000000-0000-0000-0000-000000000002';
-- e1000000-...003 varsayılan false'ta kalır (opt-out)

SET ROLE authenticated;
SET request.jwt.claim.sub = 'e1000000-0000-0000-0000-000000000001';
\echo '--- expect only opted-in@test.com (1 satır) ---'
SELECT public.get_email_campaign_recipients_v1('c1000000-0000-0000-0000-000000000001', 'tag:VIP');
\echo '--- estimate ile tutarlı mı (1) ---'
SELECT public.estimate_email_segment_v1('c1000000-0000-0000-0000-000000000001', 'tag:VIP');
EOF
```

Expected: `get_email_campaign_recipients_v1` yalnızca `opted-in@test.com` içeren tek elemanlı bir dizi döner (`opted-out@test.com` görünmez); `estimate_email_segment_v1` de `1` döner (sayı tutarlı).

- [ ] **Step 4: Test verisini temizle**

```bash
psql "postgresql://postgres:postgres@127.0.0.1:54322/postgres" <<'EOF'
RESET request.jwt.claim.sub;
RESET ROLE;
delete from public.customer_tags where business_id = 'c1000000-0000-0000-0000-000000000001';
delete from public.owner_claims where business_id = 'c1000000-0000-0000-0000-000000000001';
delete from public.businesses where id = 'c1000000-0000-0000-0000-000000000001';
delete from auth.users where id in ('e1000000-0000-0000-0000-000000000001','e1000000-0000-0000-0000-000000000002','e1000000-0000-0000-0000-000000000003');
EOF
```

- [ ] **Step 5: Commit**

```bash
git add supabase/migrations/20260815000002_crm_v2_eposta_kampanyasi.sql
git commit -m "feat(db): CRM v2 — e-posta kampanyası alıcı çözümleme RPC'leri"
```

---

### Task 2: Resend gönderim yardımcısı

**Files:**
- Create: `uygulamalar/web/src/lib/email/resend-client.ts`
- Test: `uygulamalar/web/test/lib/resend-client.test.ts`

- [ ] **Step 1: Write the failing test**

Create `uygulamalar/web/test/lib/resend-client.test.ts`:

Not: `sendEmailCampaign` her alıcı için ayrı bir `htmlBody` kabul eder (paylaşımlı gövde değil) — çünkü Task 3'te her alıcının e-postasına kişiye özel bir abonelik-iptal linki gömülecek. `campaign` parametresi yalnızca `subject`/`fromName`/`fromEmail` taşır.

```typescript
import { describe, it, expect, vi, afterEach } from 'vitest';
import { sendEmailCampaign } from '@/src/lib/email/resend-client';

describe('sendEmailCampaign', () => {
  const originalKey = process.env.RESEND_API_KEY;

  afterEach(() => {
    process.env.RESEND_API_KEY = originalKey;
    vi.unstubAllGlobals();
  });

  it('provider_not_configured döner, RESEND_API_KEY yoksa', async () => {
    delete process.env.RESEND_API_KEY;
    const result = await sendEmailCampaign(
      [{ email: 'a@test.com', displayName: 'A', htmlBody: '<p>Test</p>' }],
      { subject: 'Test', fromName: 'Yeedoy', fromEmail: 'noreply@yeedoy.com' },
    );
    expect(result).toEqual({ success_count: 0, failure_count: 0, provider_not_configured: true });
  });

  it('alıcı yoksa hiç fetch çağırmadan 0/0 döner', async () => {
    process.env.RESEND_API_KEY = 'test-key';
    const fetchSpy = vi.fn();
    vi.stubGlobal('fetch', fetchSpy);
    const result = await sendEmailCampaign([], {
      subject: 'Test', fromName: 'Yeedoy', fromEmail: 'noreply@yeedoy.com',
    });
    expect(result).toEqual({ success_count: 0, failure_count: 0 });
    expect(fetchSpy).not.toHaveBeenCalled();
  });

  it('başarılı gönderimleri sayar', async () => {
    process.env.RESEND_API_KEY = 'test-key';
    vi.stubGlobal('fetch', vi.fn().mockResolvedValue({ ok: true, status: 200 }));
    const result = await sendEmailCampaign(
      [
        { email: 'a@test.com', displayName: 'A', htmlBody: '<p>A''ya özel</p>' },
        { email: 'b@test.com', displayName: 'B', htmlBody: '<p>B''ye özel</p>' },
      ],
      { subject: 'Test', fromName: 'Yeedoy', fromEmail: 'noreply@yeedoy.com' },
    );
    expect(result).toEqual({ success_count: 2, failure_count: 0 });
  });

  it('401 auth hatasını başarısız sayar, hiçbir e-posta adresini fırlatmaz', async () => {
    process.env.RESEND_API_KEY = 'test-key';
    vi.stubGlobal('fetch', vi.fn().mockResolvedValue({ ok: false, status: 401 }));
    const result = await sendEmailCampaign(
      [{ email: 'a@test.com', displayName: 'A', htmlBody: '<p>Test</p>' }],
      { subject: 'Test', fromName: 'Yeedoy', fromEmail: 'noreply@yeedoy.com' },
    );
    expect(result).toEqual({ success_count: 0, failure_count: 1 });
  });
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd uygulamalar/web && pnpm run test:unit -- resend-client`
Expected: FAIL — `Cannot find module '@/src/lib/email/resend-client'`.

- [ ] **Step 3: Implement the helper**

Create `uygulamalar/web/src/lib/email/resend-client.ts`:

```typescript
import { logger } from '@/src/lib/kayitci';

const RESEND_API_URL = 'https://api.resend.com/emails';
const BATCH_SIZE = 50;

export type EmailSendResult = {
  success_count: number;
  failure_count: number;
  provider_not_configured?: true;
};

/**
 * Kampanya e-postalarını Resend API üzerinden (SDK yok, fetch) gönderir.
 * RESEND_API_KEY tanımsızsa fail-safe döner. API key ve e-posta adresleri
 * hiçbir zaman loglanmaz.
 */
export async function sendEmailCampaign(
  recipients: Array<{ email: string; displayName: string; htmlBody: string }>,
  campaign: { subject: string; fromName: string; fromEmail: string },
): Promise<EmailSendResult> {
  const apiKey = process.env.RESEND_API_KEY?.trim();

  if (!apiKey) {
    logger.warn('resend: provider not configured — RESEND_API_KEY missing');
    return { success_count: 0, failure_count: 0, provider_not_configured: true };
  }

  if (recipients.length === 0) {
    logger.info('resend: no recipients to send to');
    return { success_count: 0, failure_count: 0 };
  }

  const from = `${campaign.fromName} <${campaign.fromEmail}>`;
  let totalSuccess = 0;
  let totalFailure = 0;

  for (let i = 0; i < recipients.length; i += BATCH_SIZE) {
    const batch = recipients.slice(i, i + BATCH_SIZE);
    const { success, failure } = await sendBatch(batch, campaign.subject, from, apiKey);
    totalSuccess += success;
    totalFailure += failure;
  }

  logger.info('resend: campaign send complete', { success_count: totalSuccess, failure_count: totalFailure });
  return { success_count: totalSuccess, failure_count: totalFailure };
}

async function sendBatch(
  recipients: Array<{ email: string; displayName: string; htmlBody: string }>,
  subject: string,
  from: string,
  apiKey: string,
): Promise<{ success: number; failure: number }> {
  const results = await Promise.allSettled(
    recipients.map((r) => sendSingleEmail(r, subject, from, apiKey)),
  );

  let success = 0;
  let failure = 0;
  for (const result of results) {
    if (result.status === 'fulfilled' && result.value) success++;
    else failure++;
  }
  return { success, failure };
}

async function sendSingleEmail(
  recipient: { email: string; displayName: string; htmlBody: string },
  subject: string,
  from: string,
  apiKey: string,
): Promise<boolean> {
  try {
    const res = await fetch(RESEND_API_URL, {
      method: 'POST',
      headers: { Authorization: `Bearer ${apiKey}`, 'Content-Type': 'application/json' },
      body: JSON.stringify({ from, to: recipient.email, subject, html: recipient.htmlBody }),
    });

    if (res.status === 401 || res.status === 403) {
      logger.warn('resend: send auth failed', { status: res.status });
      return false;
    }
    if (res.status === 422 || res.status === 400) {
      logger.warn('resend: send rejected', { status: res.status });
      return false;
    }
    return res.ok;
  } catch {
    return false;
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd uygulamalar/web && pnpm run test:unit -- resend-client`
Expected: PASS — 4/4 tests green.

- [ ] **Step 5: Commit**

```bash
git add uygulamalar/web/src/lib/email/resend-client.ts uygulamalar/web/test/lib/resend-client.test.ts
git commit -m "feat(web): CRM v2 e-posta kampanyası — Resend gönderim yardımcısı"
```

---

### Task 3: Route handler — kampanya oluştur + gönder

**Files:**
- Modify: `uygulamalar/web/app/sunucu/sahip/eposta-kampanya/route.ts`
- Create: `uygulamalar/web/app/sunucu/sahip/eposta-kampanya/sema.ts`
- Test: `uygulamalar/web/test/lib/eposta-kampanya-route.test.ts`

- [ ] **Step 1: Write the failing test (zod şema + segment doğrulama)**

Create `uygulamalar/web/test/lib/eposta-kampanya-route.test.ts`:

```typescript
import { describe, it, expect } from 'vitest';
import { epostaKampanyaGovdesi } from '@/app/sunucu/sahip/eposta-kampanya/sema';

describe('epostaKampanyaGovdesi', () => {
  it('geçerli bir gövdeyi kabul eder', () => {
    const result = epostaKampanyaGovdesi.safeParse({
      businessId: '11111111-1111-1111-1111-111111111111',
      subject: 'Yeni Kampanya',
      body: 'Merhaba, size özel bir teklifimiz var.',
      targetSegment: 'tag:VIP',
    });
    expect(result.success).toBe(true);
  });

  it('boş subject reddedilir', () => {
    const result = epostaKampanyaGovdesi.safeParse({
      businessId: '11111111-1111-1111-1111-111111111111',
      subject: '',
      body: 'Merhaba',
      targetSegment: 'all_followers',
    });
    expect(result.success).toBe(false);
  });

  it('geçersiz businessId (uuid değil) reddedilir', () => {
    const result = epostaKampanyaGovdesi.safeParse({
      businessId: 'not-a-uuid',
      subject: 'Test',
      body: 'Merhaba',
      targetSegment: 'all_followers',
    });
    expect(result.success).toBe(false);
  });
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd uygulamalar/web && pnpm run test:unit -- eposta-kampanya-route`
Expected: FAIL — `Cannot find module '@/app/sunucu/sahip/eposta-kampanya/sema'`.

- [ ] **Step 3: zod şemasını ayrı bir dosyada tanımla**

Create `uygulamalar/web/app/sunucu/sahip/eposta-kampanya/sema.ts`:

```typescript
import { z } from 'zod';

export const epostaKampanyaGovdesi = z.object({
  businessId: z.string().uuid(),
  subject: z.string().min(1).max(200),
  body: z.string().min(1).max(5000),
  targetSegment: z.string().min(1).max(80),
});

export type EpostaKampanyaGovdesi = z.infer<typeof epostaKampanyaGovdesi>;
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd uygulamalar/web && pnpm run test:unit -- eposta-kampanya-route`
Expected: PASS — 3/3 tests green.

- [ ] **Step 5: Route handler'ı yeniden yaz (kill-switch'i kaldır)**

Modify `uygulamalar/web/app/sunucu/sahip/eposta-kampanya/route.ts`. Mevcut içerik (410 kill-switch):

```typescript
import { NextResponse } from 'next/server';

// MVP scope dışı: pazarlama otomasyonu (e-posta kampanyaları) kapsam dışı bırakıldı
// (docs/arsiv/2026-yeedoy-final-forbidden-scope-sweep.md). Kill-switch.
export async function POST() {
  return NextResponse.json({ error: 'feature_disabled' }, { status: 410 });
}
```

Yeni içerikle değiştir:

```typescript
import { NextResponse } from 'next/server';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { rateLimit } from '@/src/lib/oran-siniri';
import { generateUnsubscribeToken } from '@/src/lib/email/unsubscribe-token';
import { sendEmailCampaign } from '@/src/lib/email/resend-client';
import { logger } from '@/src/lib/kayitci';
import { epostaKampanyaGovdesi } from './sema';

function stripHtml(input: string): string {
  return input
    .replace(/<[^>]*>/g, '')
    .replace(/&amp;/g, '&')
    .replace(/&lt;/g, '<')
    .replace(/&gt;/g, '>')
    .replace(/&quot;/g, '"')
    .replace(/&#39;/g, "'");
}

export async function POST(request: Request) {
  const supabase = await createSupabaseServerClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) {
    return NextResponse.json({ error: 'unauthorized' }, { status: 401 });
  }

  const limitResult = rateLimit(`eposta-kampanya:${user.id}`, 3, 3_600_000);
  if (!limitResult.ok) {
    return NextResponse.json(
      { error: 'rate_limited', issues: { general: ['Saatte en fazla 3 kampanya gönderilebilir.'] } },
      { status: 429 },
    );
  }

  const rawBody = await request.json().catch(() => null);
  const parsed = epostaKampanyaGovdesi.safeParse(rawBody);
  if (!parsed.success) {
    return NextResponse.json({ error: 'invalid_payload', issues: parsed.error.flatten().fieldErrors }, { status: 400 });
  }

  const { businessId, subject, body, targetSegment } = parsed.data;
  const safeBody = stripHtml(body).trim();

  const supabaseAny = supabase as unknown as { rpc: (fn: string, args?: unknown) => any };

  const { data: campaignId, error: createError } = await supabaseAny.rpc('create_email_campaign_v1', {
    p_business_id: businessId,
    p_subject: subject.trim(),
    p_html_body: `<p>${safeBody}</p>`,
    p_target_segment: targetSegment,
  }) as { data: string | null; error: { message: string } | null };

  if (createError || !campaignId) {
    return NextResponse.json({ error: 'forbidden' }, { status: 403 });
  }

  const { data: recipients, error: recipientsError } = await supabaseAny.rpc(
    'get_email_campaign_recipients_v1',
    { p_business_id: businessId, p_target_segment: targetSegment },
  ) as { data: Array<{ user_id: string; email: string; display_name: string }> | null; error: { message: string } | null };

  if (recipientsError) {
    return NextResponse.json({ error: 'internal_error' }, { status: 500 });
  }

  const baseRecipients = recipients ?? [];

  if (!process.env.UNSUBSCRIBE_HMAC_SECRET?.trim()) {
    logger.warn('eposta-kampanya: UNSUBSCRIBE_HMAC_SECRET yapılandırılmamış — kampanya iptal (6563 md.9/3)');
    return NextResponse.json(
      { error: 'internal_error', issues: { general: ['unsubscribe_secret_not_configured'] } },
      { status: 500 },
    );
  }

  const siteUrl = process.env.NEXT_PUBLIC_SITE_URL?.trim() || 'https://yeedoy.com';
  const emailRecipients: Array<{ email: string; displayName: string; htmlBody: string }> = [];
  for (const r of baseRecipients) {
    try {
      const token = generateUnsubscribeToken(r.user_id, businessId, 'biz');
      const unsubscribeUrl = `${siteUrl}/abonelik-iptal?token=${encodeURIComponent(token)}`;
      emailRecipients.push({
        email: r.email,
        displayName: r.display_name,
        htmlBody: `<p>${safeBody}</p><p style="margin-top:24px;font-size:12px;color:#888"><a href="${unsubscribeUrl}">Abonelikten çık</a></p>`,
      });
    } catch (err) {
      logger.warn('eposta-kampanya: token üretimi başarısız — kampanya iptal edildi', {
        message: err instanceof Error ? err.message : 'unknown',
      });
      return NextResponse.json({ error: 'internal_error' }, { status: 500 });
    }
  }

  const emailResult = await sendEmailCampaign(emailRecipients, {
    subject,
    fromName: 'Yeedoy',
    fromEmail: process.env.EMAIL_FROM?.trim() || 'noreply@yeedoy.com',
  });

  return NextResponse.json({
    data: {
      campaignId,
      sentCount: emailResult.success_count,
      providerNotConfigured: emailResult.provider_not_configured ?? false,
    },
  });
}
```

- [ ] **Step 6: Run test to verify it still passes**

Run: `cd uygulamalar/web && pnpm run test:unit -- resend-client eposta-kampanya-route`
Expected: PASS — tüm testler yeşil.

- [ ] **Step 7: Typecheck and lint**

Run: `cd uygulamalar/web && pnpm run typecheck && pnpm run lint`
Expected: no new errors.

- [ ] **Step 8: Commit**

```bash
git add uygulamalar/web/app/sunucu/sahip/eposta-kampanya/ uygulamalar/web/test/lib/eposta-kampanya-route.test.ts
git commit -m "feat(web): CRM v2 — e-posta kampanyası gönderim route handler'ı yeniden etkinleştirildi"
```

---

### Task 4: Owner sayfası — `/sahip/pazarlama/eposta-kampanyalari`

**Files:**
- Create: `uygulamalar/web/app/sahip/pazarlama/eposta-kampanyalari/page.tsx`
- Create: `uygulamalar/web/app/sahip/pazarlama/eposta-kampanyalari/kampanya-formu-istemcisi.tsx`
- Create: `uygulamalar/web/app/sahip/pazarlama/eposta-kampanyalari/kampanya-listesi.tsx`
- Modify: `uygulamalar/web/src/ui/kabuk/sahip-kabuk-istemcisi.tsx`

- [ ] **Step 1: Kampanya listesi component'i**

Create `uygulamalar/web/app/sahip/pazarlama/eposta-kampanyalari/kampanya-listesi.tsx`:

```tsx
export type KampanyaOzet = {
  id: string;
  subject: string;
  target_segment: string;
  sent_at: string | null;
  sent_count: number;
  created_at: string;
};

function segmentEtiketi(segment: string): string {
  if (segment.startsWith('tag:')) return `Etiket: ${segment.slice(4)}`;
  if (segment === 'all_followers') return 'Tüm takipçiler';
  if (segment === 'new_30d') return 'Son 30 gün yeni takipçiler';
  if (segment === 'inactive_30d') return '30+ gündür pasif takipçiler';
  return segment;
}

export function KampanyaListesi({ kampanyalar }: { kampanyalar: KampanyaOzet[] }) {
  if (kampanyalar.length === 0) {
    return <p className="text-sm text-muted">Henüz gönderilmiş bir kampanya yok.</p>;
  }

  return (
    <ul className="flex flex-col gap-3">
      {kampanyalar.map((k) => (
        <li key={k.id} className="rounded-xl border border-border bg-card p-3">
          <p className="font-semibold text-textStrong">{k.subject}</p>
          <p className="text-sm text-muted">
            {segmentEtiketi(k.target_segment)} — {k.sent_at ? `${k.sent_count} alıcıya gönderildi` : 'Henüz gönderilmedi'}
          </p>
        </li>
      ))}
    </ul>
  );
}
```

- [ ] **Step 2: Form component'i**

Create `uygulamalar/web/app/sahip/pazarlama/eposta-kampanyalari/kampanya-formu-istemcisi.tsx`:

```tsx
'use client';

import { useState, useTransition } from 'react';
import { createSupabaseBrowserClient } from '@/src/lib/taban/istemci';

export function KampanyaFormuIstemcisi({ businessId, etiketler }: { businessId: string; etiketler: string[] }) {
  const [segment, setSegment] = useState('all_followers');
  const [subject, setSubject] = useState('');
  const [body, setBody] = useState('');
  const [estimate, setEstimate] = useState<number | null>(null);
  const [result, setResult] = useState<{ sentCount: number; providerNotConfigured: boolean } | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [isPending, startTransition] = useTransition();

  const segmentDegisti = (value: string) => {
    setSegment(value);
    setResult(null);
    startTransition(async () => {
      const supabase = createSupabaseBrowserClient();
      const { data } = await (supabase as any).rpc('estimate_email_segment_v1', {
        p_business_id: businessId,
        p_segment: value,
      });
      setEstimate(typeof data === 'number' ? data : 0);
    });
  };

  const gonder = () => {
    setError(null);
    startTransition(async () => {
      const res = await fetch('/sunucu/sahip/eposta-kampanya', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ businessId, subject, body, targetSegment: segment }),
      });
      const json = await res.json();
      if (!res.ok) {
        setError(json.error ?? 'internal_error');
        return;
      }
      setResult(json.data);
      setSubject('');
      setBody('');
    });
  };

  return (
    <div className="flex flex-col gap-4 rounded-xl border border-border bg-card p-4">
      <label className="flex flex-col gap-1 text-sm">
        Hedef Segment
        <select
          className="rounded-lg border border-border p-2"
          value={segment}
          onChange={(e) => segmentDegisti(e.target.value)}
        >
          <option value="all_followers">Tüm takipçiler</option>
          <option value="new_30d">Son 30 gün yeni takipçiler</option>
          <option value="inactive_30d">30+ gündür pasif takipçiler</option>
          {etiketler.map((tag) => (
            <option key={tag} value={`tag:${tag}`}>
              Etiket: {tag}
            </option>
          ))}
        </select>
      </label>
      {estimate !== null && (
        <p className="text-sm text-muted">Tahmini alıcı sayısı: {estimate}</p>
      )}
      <label className="flex flex-col gap-1 text-sm">
        Konu
        <input
          className="rounded-lg border border-border p-2"
          value={subject}
          onChange={(e) => setSubject(e.target.value)}
          maxLength={200}
        />
      </label>
      <label className="flex flex-col gap-1 text-sm">
        İçerik
        <textarea
          className="min-h-32 rounded-lg border border-border p-2"
          value={body}
          onChange={(e) => setBody(e.target.value)}
          maxLength={5000}
        />
      </label>
      {error && <p className="text-sm text-red-600">Bir hata oluştu: {error}</p>}
      {result && (
        <p className="text-sm text-primary">
          {result.providerNotConfigured
            ? 'Kampanya kaydedildi ama e-posta sağlayıcısı yapılandırılmadığı için gönderilmedi.'
            : `${result.sentCount} alıcıya gönderildi.`}
        </p>
      )}
      <button
        type="button"
        className="self-start rounded-xl bg-primary px-4 py-2 text-sm font-bold text-white disabled:opacity-50"
        disabled={isPending || !subject.trim() || !body.trim() || estimate === 0}
        onClick={gonder}
      >
        {isPending ? 'Gönderiliyor…' : 'Gönder'}
      </button>
    </div>
  );
}
```

- [ ] **Step 3: Sayfa**

Create `uygulamalar/web/app/sahip/pazarlama/eposta-kampanyalari/page.tsx`:

```tsx
import type { Metadata } from 'next';
import { redirect } from 'next/navigation';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { getOwnerBusinessIds } from '@/src/lib/veri/owner/sahip-isletmeleri';
import { PanelSayfaBasligi } from '@/src/ui/yerlesim/panel-page-header';
import { PanelIcerikYuzeyi, PanelBolumKarti } from '@/src/ui/yerlesim/panel-section-card';
import { KampanyaFormuIstemcisi } from './kampanya-formu-istemcisi';
import { KampanyaListesi, type KampanyaOzet } from './kampanya-listesi';

export const metadata: Metadata = {
  title: 'E-posta Kampanyaları | Sahip Paneli',
  robots: { index: false, follow: false },
};

export default async function EpostaKampanyalariSayfasi() {
  const supabase = await createSupabaseServerClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) redirect('/giris?redirect=/sahip/pazarlama/eposta-kampanyalari');

  const businessIds = await getOwnerBusinessIds(supabase as any, user.id);
  const businessId = businessIds[0];
  if (!businessId) redirect('/sahip');

  const [{ data: etiketler }, { data: kampanyalarSonuc }] = await Promise.all([
    (supabase as any).rpc('list_customer_tags_v1', { p_business_id: businessId }) as Promise<{ data: string[] | null }>,
    (supabase as any).rpc('list_email_campaigns_v1', { p_business_id: businessId }) as Promise<{
      data: { total: number; items: KampanyaOzet[] } | null;
    }>,
  ]);

  return (
    <div className="flex flex-col gap-6">
      <PanelSayfaBasligi eyebrow="Pazarlama" title="E-posta Kampanyaları" description="Etiketlediğiniz veya takip eden müşterilerinize toplu e-posta gönderin" />
      <PanelIcerikYuzeyi>
        <div className="grid grid-cols-1 gap-5 md:grid-cols-[1fr_320px]">
          <PanelBolumKarti title="Yeni Kampanya">
            <KampanyaFormuIstemcisi businessId={businessId} etiketler={etiketler ?? []} />
          </PanelBolumKarti>
          <PanelBolumKarti title="Geçmiş Kampanyalar">
            <KampanyaListesi kampanyalar={kampanyalarSonuc?.items ?? []} />
          </PanelBolumKarti>
        </div>
      </PanelIcerikYuzeyi>
    </div>
  );
}
```

- [ ] **Step 4: Nav girişini ekle**

Modify `uygulamalar/web/src/ui/kabuk/sahip-kabuk-istemcisi.tsx`. Mevcut satır (42-43):

```tsx
      { href: '/sahip/pazarlama/kampanyalar', label: 'Pazarlama', icon: <MegaphoneIcon /> },
      { href: '/sahip/pazarlama/sadakat', label: 'Sadakat', icon: <GiftIcon /> },
```

Yeni satırla değiştir (araya ekle):

```tsx
      { href: '/sahip/pazarlama/kampanyalar', label: 'Pazarlama', icon: <MegaphoneIcon /> },
      { href: '/sahip/pazarlama/eposta-kampanyalari', label: 'E-posta Kampanyaları', icon: <MailIcon /> },
      { href: '/sahip/pazarlama/sadakat', label: 'Sadakat', icon: <GiftIcon /> },
```

`MegaphoneIcon` fonksiyon tanımının hemen altına (satır ~420, dosyanın icon tanımları bölümünde) yeni bir icon fonksiyonu ekle:

```tsx
function MailIcon() {
  return (
    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <rect x="3" y="5" width="18" height="14" rx="2" />
      <path d="m3 7 9 6 9-6" />
    </svg>
  );
}
```

- [ ] **Step 5: Typecheck and lint**

Run: `cd uygulamalar/web && pnpm run typecheck && pnpm run lint`
Expected: no new errors.

- [ ] **Step 6: Commit**

```bash
git add uygulamalar/web/app/sahip/pazarlama/eposta-kampanyalari/ uygulamalar/web/src/ui/kabuk/sahip-kabuk-istemcisi.tsx
git commit -m "feat(web): CRM v2 — e-posta kampanyaları owner sayfası ve nav girişi"
```

---

### Task 5: Doğrulama — gerçek gönderim testi

**Files:** Yok (yalnızca doğrulama, kod değişikliği yok).

- [ ] **Step 1: Production'a deploy et**

`supabase db push` ile Task 1'deki migration'ı deploy et (dry-run ile önce doğrula, bu depodaki standart akış — bkz. `docs/superpowers/plans/2026-08-13-crm-v2-zincir-capinda-gorunum.md` Task 1 emsali).

- [ ] **Step 2: `RESEND_API_KEY`/`EMAIL_FROM`/`UNSUBSCRIBE_HMAC_SECRET`'in tanımlı olduğunu doğrula**

Kullanıcının kendi Resend hesabından eklediği key'lerin Vercel production ortam değişkenlerinde olduğunu doğrula (bu plan onları eklemiyor — kullanıcı tarafı, bkz. design doc §Bağlam).

- [ ] **Step 3: Kendi hesabına test kampanyası gönder**

`/sahip/pazarlama/eposta-kampanyalari` sayfasından, kendi e-postana ulaşacak bir segment (örn. kendine bir CRM etiketi ekleyip `marketing_email_opt_in`'i `/bildirim-ayarlari`'ndan açarak) ile gerçek bir kampanya gönder.

- [ ] **Step 4: Doğrula**

E-postanın geldiğini, konunun/içeriğin doğru olduğunu, "Abonelikten çık" linkinin çalıştığını (tıklayınca `/abonelik-iptal` sayfasının "Abonelik İptal Edildi" mesajını gösterdiğini) doğrula.

- [ ] **Step 5: Kullanıcıya rapor**

Hangi senaryoların (çift onay filtresi, etiket segmenti, abonelik iptali) gerçek e-posta ile doğrulandığını özetle.

---

### Task 6: Son doğrulama

**Files:** (yalnızca doğrulama)

- [ ] **Step 1: Tam web doğrulaması**

Run: `cd uygulamalar/web && pnpm run test:ci`
Expected: typecheck + lint + unit + build hepsi geçer.

- [ ] **Step 2: Supabase tip dosyalarını yeniden üret**

Migration production'a deploy edildikten sonra `mcp__supabase__generate_typescript_types`, çıktıyı hem `database.types.ts` hem `veri-tanimlari.ts`'e yaz (bu depodaki ikili-dosya konvansiyonu).

- [ ] **Step 3: Kullanıcıya rapor**

CRM v1'in "Kapsam Dışı" bölümünde bırakılan 4 alt-özelliğin (not/etiket, arama/filtre, zincir-çapında görünüm, toplu e-posta) hepsinin artık tamamlandığını ve production'da doğrulandığını özetle.
