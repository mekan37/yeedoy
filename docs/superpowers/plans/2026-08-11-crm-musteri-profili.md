# CRM — Birleşik Müşteri Profili Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Sahip panelinde owner'ın işletmesiyle etkileşimi olan (yorum/rezervasyon/sadakat/takip) tüm müşterileri tek listede görebileceği ve bir müşteriye tıklayınca kronolojik zaman çizelgesini görebileceği `/sahip/musteriler` özelliğini eklemek.

**Architecture:** Yeni domain tablosu yok — mevcut `reviews`/`reservations`/`loyalty_members`/`loyalty_events`/`business_follows` tablolarını birleştiren iki salt-okunur `SECURITY DEFINER` RPC (`get_business_customers_v1`, `get_customer_timeline_v1`). Web tarafı sadakat'teki `/sadakat` (kimlik) sayfasıyla aynı desen: sunucu bileşeni, doğrudan RPC çağrısı, mutation yok.

**Tech Stack:** Supabase Postgres RPC, Next.js 15 Server Component.

---

### Task 1: DB — `get_business_customers_v1` ve `get_customer_timeline_v1` RPC'leri

**Files:**
- Create: `supabase/migrations/20260811000003_crm_musteri_profili_v1.sql`

- [ ] **Step 1: Migration dosyasını yaz**

```sql
-- CRM v1 — birleşik müşteri profili. bkz. docs/superpowers/specs/2026-08-11-crm-musteri-profili-design.md
--
-- Yeni domain tablosu yok. reviews/reservations/loyalty_members/
-- loyalty_events/business_follows tablolarını birleştiren iki
-- salt-okunur RPC. Yetkilendirme sadakat'teki desenle aynı:
-- has_business_permission_v1(p_business_id, 'menu_write') — editor+,
-- staff erişemez (müşteri verisi sayaç işlemi değil).

-- ── get_business_customers_v1 ────────────────────────────────────────────────
CREATE FUNCTION public.get_business_customers_v1(p_business_id uuid)
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_program_id uuid;
BEGIN
  IF NOT public.has_business_permission_v1(p_business_id, 'menu_write') THEN
    RAISE EXCEPTION 'unauthorized' USING ERRCODE = 'P0002';
  END IF;

  v_program_id := public._resolve_loyalty_program_v1(p_business_id);

  RETURN COALESCE(
    (
      WITH customer_ids AS (
        SELECT user_id FROM public.reviews
          WHERE business_id = p_business_id AND user_id IS NOT NULL AND status = 'approved'
        UNION
        SELECT user_id FROM public.reservations
          WHERE business_id = p_business_id AND user_id IS NOT NULL
        UNION
        SELECT user_id FROM public.business_follows
          WHERE business_id = p_business_id
        UNION
        SELECT lm.user_id FROM public.loyalty_members lm
          WHERE v_program_id IS NOT NULL AND lm.program_id = v_program_id
      ),
      summary AS (
        SELECT
          ci.user_id,
          (SELECT count(*) FROM public.reviews r
             WHERE r.business_id = p_business_id AND r.user_id = ci.user_id AND r.status = 'approved') AS review_count,
          (SELECT count(*) FROM public.reservations rs
             WHERE rs.business_id = p_business_id AND rs.user_id = ci.user_id) AS reservation_count,
          (SELECT lm.progress FROM public.loyalty_members lm
             WHERE v_program_id IS NOT NULL AND lm.program_id = v_program_id AND lm.user_id = ci.user_id) AS loyalty_progress,
          GREATEST(
            COALESCE((SELECT max(r.created_at) FROM public.reviews r
               WHERE r.business_id = p_business_id AND r.user_id = ci.user_id AND r.status = 'approved'), 'epoch'::timestamptz),
            COALESCE((SELECT max(rs.created_at) FROM public.reservations rs
               WHERE rs.business_id = p_business_id AND rs.user_id = ci.user_id), 'epoch'::timestamptz),
            COALESCE((SELECT max(bf.created_at) FROM public.business_follows bf
               WHERE bf.business_id = p_business_id AND bf.user_id = ci.user_id), 'epoch'::timestamptz),
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
          'loyalty_progress', s.loyalty_progress
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

REVOKE ALL ON FUNCTION public.get_business_customers_v1(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_business_customers_v1(uuid) TO authenticated;
REVOKE EXECUTE ON FUNCTION public.get_business_customers_v1(uuid) FROM anon;
COMMENT ON FUNCTION public.get_business_customers_v1 IS
  'Owner/yönetici (menu_write, editor+): işletmeyle etkileşimi olan (yorum/rezervasyon/sadakat/takip) tüm müşterilerin özet listesi. Called by: app/sahip/musteriler (liste sayfası).';

-- ── get_customer_timeline_v1 ─────────────────────────────────────────────────
CREATE FUNCTION public.get_customer_timeline_v1(p_business_id uuid, p_user_id uuid)
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_program_id uuid;
BEGIN
  IF NOT public.has_business_permission_v1(p_business_id, 'menu_write') THEN
    RAISE EXCEPTION 'unauthorized' USING ERRCODE = 'P0002';
  END IF;

  v_program_id := public._resolve_loyalty_program_v1(p_business_id);

  RETURN COALESCE(
    (
      SELECT jsonb_agg(evt ORDER BY (evt->>'occurred_at')::timestamptz DESC)
      FROM (
        SELECT jsonb_build_object(
          'event_type', 'review',
          'occurred_at', r.created_at,
          'summary', r.rating || ' yıldız' || CASE WHEN r.title IS NOT NULL AND trim(r.title) <> '' THEN ' — "' || r.title || '"' ELSE '' END
        ) AS evt
        FROM public.reviews r
        WHERE r.business_id = p_business_id AND r.user_id = p_user_id AND r.status = 'approved'

        UNION ALL

        SELECT jsonb_build_object(
          'event_type', 'reservation',
          'occurred_at', rs.created_at,
          'summary', rs.party_size || ' kişi, ' || to_char(rs.reservation_date, 'DD.MM.YYYY') || ' ' || to_char(rs.reservation_time, 'HH24:MI')
        )
        FROM public.reservations rs
        WHERE rs.business_id = p_business_id AND rs.user_id = p_user_id

        UNION ALL

        SELECT jsonb_build_object(
          'event_type', CASE WHEN le.source = 'redeem' THEN 'loyalty_redeem' ELSE 'loyalty_scan' END,
          'occurred_at', le.created_at,
          'summary', CASE WHEN le.source = 'redeem' THEN 'Ödül kullanıldı' ELSE '+' || le.amount || ' ilerleme' END
        )
        FROM public.loyalty_events le
        JOIN public.loyalty_members lm ON lm.id = le.member_id
        WHERE v_program_id IS NOT NULL AND lm.program_id = v_program_id AND lm.user_id = p_user_id

        UNION ALL

        SELECT jsonb_build_object(
          'event_type', 'follow',
          'occurred_at', bf.created_at,
          'summary', 'İşletmeyi takip etmeye başladı'
        )
        FROM public.business_follows bf
        WHERE bf.business_id = p_business_id AND bf.user_id = p_user_id
      ) sub
    ),
    '[]'::jsonb
  );
END;
$$;

REVOKE ALL ON FUNCTION public.get_customer_timeline_v1(uuid, uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_customer_timeline_v1(uuid, uuid) TO authenticated;
REVOKE EXECUTE ON FUNCTION public.get_customer_timeline_v1(uuid, uuid) FROM anon;
COMMENT ON FUNCTION public.get_customer_timeline_v1 IS
  'Owner/yönetici (menu_write, editor+): tek bir müşterinin işletmeyle olan tüm etkileşimlerinin kronolojik akışı. Called by: app/sahip/musteriler/[user_id] (detay sayfası).';
```

- [ ] **Step 2: Local'de uygula**

Run (repo kökünden): `supabase db reset`
Expected: Tüm migration'lar hatasız uygulanır, `20260811000003_crm_musteri_profili_v1.sql` dahil.

- [ ] **Step 3: Yetki doğrulaması**

Run:
```bash
docker exec supabase_db_yeedoy psql -U postgres -d postgres -c "
select
  has_function_privilege('anon', 'public.get_business_customers_v1(uuid)', 'EXECUTE') as anon_customers,
  has_function_privilege('authenticated', 'public.get_business_customers_v1(uuid)', 'EXECUTE') as auth_customers,
  has_function_privilege('anon', 'public.get_customer_timeline_v1(uuid,uuid)', 'EXECUTE') as anon_timeline,
  has_function_privilege('authenticated', 'public.get_customer_timeline_v1(uuid,uuid)', 'EXECUTE') as auth_timeline;
"
```
Expected: `anon_customers=f`, `auth_customers=t`, `anon_timeline=f`, `auth_timeline=t`.

- [ ] **Step 4: Rol bazlı davranış testi (test fixture ile)**

Test fixture kur (owner + staff + müşteri + işletme + bir yorum + bir rezervasyon), `set role authenticated` + `set_config('request.jwt.claim.sub', ...)` ile owner olarak `get_business_customers_v1` ve `get_customer_timeline_v1` çağır → beklenen özet/zaman çizelgesi dönmeli. Aynı fixture'da staff rolüyle aynı RPC'leri çağır → `unauthorized` hatası beklenir. Test sonunda fixture'ı temizle.

- [ ] **Step 5: Commit**

```bash
git add supabase/migrations/20260811000003_crm_musteri_profili_v1.sql
git commit -m "feat(db): CRM v1 — get_business_customers_v1 + get_customer_timeline_v1 RPC'leri"
```

---

### Task 2: Web — müşteri listesi sayfası + nav öğesi

**Files:**
- Create: `uygulamalar/web/app/sahip/musteriler/page.tsx`
- Create: `uygulamalar/web/app/sahip/musteriler/musteri-listesi.tsx`
- Modify: `uygulamalar/web/src/ui/kabuk/sahip-kabuk-istemcisi.tsx`

- [ ] **Step 1: Liste bileşenini yaz**

`uygulamalar/web/app/sahip/musteriler/musteri-listesi.tsx`:

```tsx
import Link from 'next/link';

export type MusteriOzet = {
  user_id: string;
  display_name: string;
  avatar_url: string | null;
  last_interaction_at: string;
  review_count: number;
  reservation_count: number;
  loyalty_progress: number | null;
};

export function MusteriListesi({ musteriler }: { musteriler: MusteriOzet[] }) {
  if (musteriler.length === 0) {
    return <p className="text-sm text-muted">Henüz hiç müşteri etkileşimi yok.</p>;
  }

  return (
    <div className="overflow-x-auto">
      <table className="w-full text-sm">
        <thead>
          <tr className="border-b border-border text-left text-xs font-bold uppercase tracking-wide text-muted">
            <th className="py-2">Müşteri</th>
            <th className="py-2">Son Etkileşim</th>
            <th className="py-2">Yorum</th>
            <th className="py-2">Rezervasyon</th>
            <th className="py-2">Sadakat</th>
          </tr>
        </thead>
        <tbody className="divide-y divide-border">
          {musteriler.map((m) => (
            <tr key={m.user_id}>
              <td className="py-2">
                <Link
                  href={`/sahip/musteriler/${m.user_id}`}
                  className="font-semibold text-textStrong hover:underline"
                >
                  {m.display_name}
                </Link>
              </td>
              <td className="py-2 text-muted">
                {new Date(m.last_interaction_at).toLocaleDateString('tr-TR')}
              </td>
              <td className="py-2 text-textStrong">{m.review_count}</td>
              <td className="py-2 text-textStrong">{m.reservation_count}</td>
              <td className="py-2 text-textStrong">{m.loyalty_progress ?? '—'}</td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}
```

- [ ] **Step 2: Sayfayı yaz**

`uygulamalar/web/app/sahip/musteriler/page.tsx`:

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

- [ ] **Step 3: Nav öğesini ekle**

`uygulamalar/web/src/ui/kabuk/sahip-kabuk-istemcisi.tsx` içinde `{ href: '/sahip/ekip', label: 'Ekip', icon: <UsersIcon /> },` satırının hemen altına ekle:

```tsx
      { href: '/sahip/musteriler', label: 'Müşteriler', icon: <ContactIcon /> },
```

Dosyanın altındaki ikon fonksiyonlarının bulunduğu bölüme (örn. `GiftIcon()` fonksiyonunun yanına) yeni bir ikon fonksiyonu ekle:

```tsx
function ContactIcon() {
  return (
    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
      <circle cx="12" cy="8" r="4" />
      <path d="M4 21c0-4 3.5-7 8-7s8 3 8 7" />
    </svg>
  );
}
```

- [ ] **Step 4: Typecheck + lint**

Run (uygulamalar/web içinden): `pnpm run typecheck && pnpm run lint`
Expected: Hata yok.

- [ ] **Step 5: Commit**

```bash
git add app/sahip/musteriler/page.tsx app/sahip/musteriler/musteri-listesi.tsx src/ui/kabuk/sahip-kabuk-istemcisi.tsx
git commit -m "feat(web): CRM v1 — müşteri listesi sayfası + sol menü nav öğesi"
```

---

### Task 3: Web — müşteri detay (zaman çizelgesi) sayfası

**Files:**
- Create: `uygulamalar/web/app/sahip/musteriler/[user_id]/page.tsx`
- Create: `uygulamalar/web/app/sahip/musteriler/[user_id]/zaman-cizelgesi.tsx`

- [ ] **Step 1: Zaman çizelgesi bileşenini yaz**

`uygulamalar/web/app/sahip/musteriler/[user_id]/zaman-cizelgesi.tsx`:

```tsx
export type ZamanCizelgesiOlayi = {
  event_type: 'review' | 'reservation' | 'loyalty_scan' | 'loyalty_redeem' | 'follow';
  occurred_at: string;
  summary: string;
};

const OLAY_ETIKETLERI: Record<ZamanCizelgesiOlayi['event_type'], string> = {
  review: '⭐ Yorum yaptı',
  reservation: '📅 Rezervasyon',
  loyalty_scan: '🎁 Sadakat',
  loyalty_redeem: '🎁 Ödül',
  follow: '❤️ Takip',
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

- [ ] **Step 2: Sayfayı yaz**

`uygulamalar/web/app/sahip/musteriler/[user_id]/page.tsx`:

```tsx
import type { Metadata } from 'next';
import { redirect, notFound } from 'next/navigation';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { getOwnerBusinessIds } from '@/src/lib/veri/owner/sahip-isletmeleri';
import { PanelSayfaBasligi } from '@/src/ui/yerlesim/panel-page-header';
import { PanelIcerikYuzeyi } from '@/src/ui/yerlesim/panel-section-card';
import { ZamanCizelgesi, type ZamanCizelgesiOlayi } from './zaman-cizelgesi';
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
    <div className="flex flex-col gap-6">
      <PanelSayfaBasligi eyebrow="Müşteriler" title={musteri.display_name} />
      <div className="grid grid-cols-1 gap-6 md:grid-cols-[280px_1fr]">
        <PanelIcerikYuzeyi>
          <div className="flex flex-col gap-2 text-sm">
            <p className="font-black text-textStrong">{musteri.display_name}</p>
            <p className="text-muted">Yorum: {musteri.review_count}</p>
            <p className="text-muted">Rezervasyon: {musteri.reservation_count}</p>
            {musteri.loyalty_progress !== null && (
              <p className="text-muted">Sadakat ilerlemesi: {musteri.loyalty_progress}</p>
            )}
          </div>
        </PanelIcerikYuzeyi>
        <PanelIcerikYuzeyi>
          <ZamanCizelgesi olaylar={olaylar ?? []} />
        </PanelIcerikYuzeyi>
      </div>
    </div>
  );
}
```

- [ ] **Step 3: Typecheck + lint**

Run (uygulamalar/web içinden): `pnpm run typecheck && pnpm run lint`
Expected: Hata yok.

- [ ] **Step 4: Commit**

```bash
git add app/sahip/musteriler/\[user_id\]
git commit -m "feat(web): CRM v1 — müşteri detay/zaman çizelgesi sayfası"
```

---

### Task 4: Web — test kapsamı

**Files:**
- Create: `uygulamalar/web/test/lib/musteri-listesi.test.ts`

- [ ] **Step 1: Bileşen exportlarını doğrulayan smoke test yaz**

`uygulamalar/web/test/lib/musteri-listesi.test.ts`:

```ts
import { describe, it, expect } from 'vitest';
import { MusteriListesi } from '@/app/sahip/musteriler/musteri-listesi';
import { ZamanCizelgesi } from '@/app/sahip/musteriler/[user_id]/zaman-cizelgesi';

describe('CRM müşteri bileşenleri', () => {
  it('bileşenler export edilir', () => {
    expect(typeof MusteriListesi).toBe('function');
    expect(typeof ZamanCizelgesi).toBe('function');
  });
});
```

- [ ] **Step 2: Testi çalıştır**

Run (uygulamalar/web içinden): `pnpm run test:unit -- musteri-listesi`
Expected: PASS.

- [ ] **Step 3: Commit**

```bash
git add test/lib/musteri-listesi.test.ts
git commit -m "test(web): CRM v1 — müşteri bileşenleri smoke test"
```

---

### Task 5: Doğrulama — gerçek tarayıcı testi + production push

**Files:** (yalnızca doğrulama, yeni kod yok)

- [ ] **Step 1: Local'de test fixture kur**

Local Supabase (Docker) çalışıyor olmalı. `curl -X POST http://127.0.0.1:54321/auth/v1/signup ...` ile test owner hesabı oluştur (form-doldurma flakiness'inden kaçınmak için — sadakat oturumunda öğrenilen ders), SQL ile `owner_claims` + `business_premium` ekle, en az bir onaylı yorum ve bir rezervasyon oluştur.

- [ ] **Step 2: Web `.env.local`'ı geçici olarak local Supabase'e işaret et, dev server başlat**

`NEXT_PUBLIC_SUPABASE_URL`/`NEXT_PUBLIC_SUPABASE_ANON_KEY`'i local değerlere çevir (önce production değerlerini yedekle), `pnpm run dev`.

- [ ] **Step 3: Tarayıcıda doğrula**

Test owner ile giriş yap, `/sahip/musteriler`'a git. Expected: test müşterisi listede görünür (yorum/rezervasyon sayıları doğru). Müşteriye tıkla → `/sahip/musteriler/[user_id]` açılır, zaman çizelgesinde yorum ve rezervasyon olayları doğru sırada (en yeni üstte) görünür.

- [ ] **Step 4: Temizlik**

Test fixture'ını SQL ile sil, `.env.local`'ı gerçek production değerlerine geri al, dev server'ı durdur (Windows'ta arka planda kalan `next dev` process'inin PID'ini `netstat -ano | grep :3000` ile bulup `taskkill //PID <pid> //F` ile öldürmeyi unutma — `TaskStop` tracked shell'i durdursa da alttaki process hayatta kalabiliyor).

- [ ] **Step 5: Production'a push**

```bash
supabase db push --linked
```

Ardından `mcp__supabase__execute_sql` ile `has_function_privilege('anon', ...)` / `has_function_privilege('authenticated', ...)` doğrudan doğrula (advisor cache'ine güvenme).

- [ ] **Step 6: Kullanıcıya rapor**

Test sonucu, hangi dosyalar değişti — özetle.
