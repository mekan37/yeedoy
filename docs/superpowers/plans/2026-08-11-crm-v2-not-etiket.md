# CRM v2 — Müşteri Notu ve Etiketleme Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Owner'ın müşteri detay sayfasında zaman damgalı not ve serbest metin etiket ekleyebilmesi; etiketlerin liste sayfasında rozet olarak, notların zaman çizelgesinde yeni bir olay tipi olarak görünmesi.

**Architecture:** İki yeni tablo (`customer_notes`, `customer_tags`), RLS enabled + policy yok (tüm erişim `SECURITY DEFINER` RPC üzerinden). Üç yeni RPC (`add_customer_note_v1`, `add_customer_tag_v1`, `remove_customer_tag_v1`) + mevcut iki RPC'nin (`get_business_customers_v1`, `get_customer_timeline_v1`) `CREATE OR REPLACE` ile genişletilmesi (imza değişmiyor, sadece dönüş içeriğine alan ekleniyor — breaking change değil).

**Tech Stack:** Supabase Postgres RPC, Next.js 15 Server Actions + Client Component.

---

### Task 1: DB — customer_notes/customer_tags tabloları + RPC'ler

**Files:**
- Create: `supabase/migrations/20260811000004_crm_v2_notes_and_tags.sql`

- [ ] **Step 1: Migration dosyasını yaz**

```sql
-- CRM v2 — müşteri notu ve etiketleme. bkz. docs/superpowers/specs/2026-08-11-crm-v2-not-etiket-design.md
--
-- İki yeni tablo, RLS enabled + policy yok (tüm erişim SECURITY
-- DEFINER RPC üzerinden — client'a doğrudan hiçbir GRANT yok).
-- Yetkilendirme CRM v1'deki desenle aynı: has_business_permission_v1
-- (p_business_id, 'menu_write') — editor+, staff erişemez.

CREATE TABLE public.customer_notes (
  id          uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses(id) on delete cascade,
  user_id     uuid not null references auth.users(id) on delete cascade,
  note        text not null,
  created_by  uuid references auth.users(id) on delete set null,
  created_at  timestamptz not null default now()
);
CREATE INDEX idx_customer_notes_business_user ON public.customer_notes(business_id, user_id, created_at DESC);
ALTER TABLE public.customer_notes ENABLE ROW LEVEL SECURITY;

CREATE TABLE public.customer_tags (
  id          uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses(id) on delete cascade,
  user_id     uuid not null references auth.users(id) on delete cascade,
  tag         text not null check (length(trim(tag)) > 0 and length(tag) <= 40),
  created_by  uuid references auth.users(id) on delete set null,
  created_at  timestamptz not null default now(),
  unique (business_id, user_id, tag)
);
CREATE INDEX idx_customer_tags_business_user ON public.customer_tags(business_id, user_id);
ALTER TABLE public.customer_tags ENABLE ROW LEVEL SECURITY;

-- ── add_customer_note_v1 ─────────────────────────────────────────────────────
CREATE FUNCTION public.add_customer_note_v1(p_business_id uuid, p_user_id uuid, p_note text)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_note_id uuid;
BEGIN
  IF NOT public.has_business_permission_v1(p_business_id, 'menu_write') THEN
    RAISE EXCEPTION 'unauthorized' USING ERRCODE = 'P0002';
  END IF;

  IF trim(coalesce(p_note, '')) = '' THEN
    RAISE EXCEPTION 'validation_error: not boş olamaz' USING ERRCODE = 'P0003';
  END IF;

  INSERT INTO public.customer_notes (business_id, user_id, note, created_by)
  VALUES (p_business_id, p_user_id, trim(p_note), auth.uid())
  RETURNING id INTO v_note_id;

  RETURN v_note_id;
END;
$$;

REVOKE ALL ON FUNCTION public.add_customer_note_v1(uuid, uuid, text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.add_customer_note_v1(uuid, uuid, text) TO authenticated;
REVOKE EXECUTE ON FUNCTION public.add_customer_note_v1(uuid, uuid, text) FROM anon;
COMMENT ON FUNCTION public.add_customer_note_v1 IS
  'Owner/yönetici (menu_write, editor+): müşteriye zaman damgalı not ekler. Called by: app/sahip/musteriler/[user_id] (not ekleme formu).';

-- ── add_customer_tag_v1 ──────────────────────────────────────────────────────
CREATE FUNCTION public.add_customer_tag_v1(p_business_id uuid, p_user_id uuid, p_tag text)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_tag_id uuid;
  v_tag    text;
BEGIN
  IF NOT public.has_business_permission_v1(p_business_id, 'menu_write') THEN
    RAISE EXCEPTION 'unauthorized' USING ERRCODE = 'P0002';
  END IF;

  v_tag := trim(coalesce(p_tag, ''));
  IF v_tag = '' OR length(v_tag) > 40 THEN
    RAISE EXCEPTION 'validation_error: etiket 1-40 karakter olmalı' USING ERRCODE = 'P0003';
  END IF;

  INSERT INTO public.customer_tags (business_id, user_id, tag, created_by)
  VALUES (p_business_id, p_user_id, v_tag, auth.uid())
  ON CONFLICT (business_id, user_id, tag) DO NOTHING
  RETURNING id INTO v_tag_id;

  IF v_tag_id IS NULL THEN
    RAISE EXCEPTION 'validation_error: bu etiket zaten ekli' USING ERRCODE = 'P0003';
  END IF;

  RETURN v_tag_id;
END;
$$;

REVOKE ALL ON FUNCTION public.add_customer_tag_v1(uuid, uuid, text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.add_customer_tag_v1(uuid, uuid, text) TO authenticated;
REVOKE EXECUTE ON FUNCTION public.add_customer_tag_v1(uuid, uuid, text) FROM anon;
COMMENT ON FUNCTION public.add_customer_tag_v1 IS
  'Owner/yönetici (menu_write, editor+): müşteriye serbest metin etiket ekler. Aynı etiket tekrar eklenemez. Called by: app/sahip/musteriler/[user_id] (etiket ekleme formu).';

-- ── remove_customer_tag_v1 ───────────────────────────────────────────────────
CREATE FUNCTION public.remove_customer_tag_v1(p_tag_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_business_id uuid;
BEGIN
  SELECT business_id INTO v_business_id FROM public.customer_tags WHERE id = p_tag_id;

  IF v_business_id IS NULL THEN
    RAISE EXCEPTION 'not_found: etiket bulunamadı' USING ERRCODE = 'P0001';
  END IF;

  IF NOT public.has_business_permission_v1(v_business_id, 'menu_write') THEN
    RAISE EXCEPTION 'unauthorized' USING ERRCODE = 'P0002';
  END IF;

  DELETE FROM public.customer_tags WHERE id = p_tag_id;
END;
$$;

REVOKE ALL ON FUNCTION public.remove_customer_tag_v1(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.remove_customer_tag_v1(uuid) TO authenticated;
REVOKE EXECUTE ON FUNCTION public.remove_customer_tag_v1(uuid) FROM anon;
COMMENT ON FUNCTION public.remove_customer_tag_v1 IS
  'Owner/yönetici (menu_write, editor+): bir müşteri etiketini siler. Called by: app/sahip/musteriler/[user_id] (etiket rozeti üzerindeki x ikonu).';

-- ── get_business_customers_v1 (genişletildi: tags alanı eklendi) ────────────
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
BEGIN
  IF NOT public.has_business_permission_v1(p_business_id, 'menu_write') THEN
    RAISE EXCEPTION 'unauthorized' USING ERRCODE = 'P0002';
  END IF;

  v_program_id := public._resolve_loyalty_program_v1(p_business_id);

  IF v_program_id IS NOT NULL THEN
    SELECT reward_threshold INTO v_reward_threshold FROM public.loyalty_programs WHERE id = v_program_id;
  END IF;

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
          (SELECT coalesce(jsonb_agg(jsonb_build_object('id', ct.id, 'tag', ct.tag) ORDER BY ct.created_at), '[]'::jsonb)
             FROM public.customer_tags ct
             WHERE ct.business_id = p_business_id AND ct.user_id = ci.user_id) AS tags,
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

-- ── get_customer_timeline_v1 (genişletildi: 'note' olay tipi eklendi) ───────
CREATE OR REPLACE FUNCTION public.get_customer_timeline_v1(p_business_id uuid, p_user_id uuid)
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

        UNION ALL

        SELECT jsonb_build_object(
          'event_type', 'note',
          'occurred_at', cn.created_at,
          'summary', cn.note
        )
        FROM public.customer_notes cn
        WHERE cn.business_id = p_business_id AND cn.user_id = p_user_id
      ) sub
    ),
    '[]'::jsonb
  );
END;
$$;
```

- [ ] **Step 2: Local'de uygula**

Run (repo kökünden): `supabase db reset`
Expected: Tüm migration'lar hatasız uygulanır, `20260811000004_crm_v2_notes_and_tags.sql` dahil.

- [ ] **Step 3: Yetki doğrulaması**

Run:
```bash
docker exec supabase_db_yeedoy psql -U postgres -d postgres -c "
select
  has_function_privilege('anon', 'public.add_customer_note_v1(uuid,uuid,text)', 'EXECUTE') as anon_note,
  has_function_privilege('authenticated', 'public.add_customer_note_v1(uuid,uuid,text)', 'EXECUTE') as auth_note,
  has_function_privilege('anon', 'public.add_customer_tag_v1(uuid,uuid,text)', 'EXECUTE') as anon_tag,
  has_function_privilege('authenticated', 'public.add_customer_tag_v1(uuid,uuid,text)', 'EXECUTE') as auth_tag,
  has_function_privilege('anon', 'public.remove_customer_tag_v1(uuid)', 'EXECUTE') as anon_remove,
  has_function_privilege('authenticated', 'public.remove_customer_tag_v1(uuid)', 'EXECUTE') as auth_remove,
  has_table_privilege('anon', 'public.customer_notes', 'SELECT') as anon_notes_table,
  has_table_privilege('authenticated', 'public.customer_notes', 'SELECT') as auth_notes_table;
"
```
Expected: `anon_note=f`, `auth_note=t`, `anon_tag=f`, `auth_tag=t`, `anon_remove=f`, `auth_remove=t`, `anon_notes_table=f`, `auth_notes_table=f` (tabloya doğrudan erişim client'tan tamamen kapalı, sadece RPC üzerinden).

- [ ] **Step 4: Rol bazlı davranış testi (test fixture ile)**

Test fixture kur (owner + staff + müşteri + işletme). Owner rolüyle:
- `add_customer_note_v1` çağır → not eklenmeli, `get_customer_timeline_v1` çıktısında `event_type: 'note'` olarak görünmeli.
- `add_customer_tag_v1` çağır → etiket eklenmeli, `get_business_customers_v1` çıktısında `tags` alanında görünmeli.
- Aynı etiketi tekrar `add_customer_tag_v1` ile eklemeye çalış → `validation_error: bu etiket zaten ekli` hatası beklenir.
- `remove_customer_tag_v1` çağır → etiket silinmeli.

Staff rolüyle aynı RPC'leri çağır → hepsinde `unauthorized` hatası beklenir.

Test sonunda fixture'ı temizle (önce `customer_notes`/`customer_tags` kayıtlarını, sonra business/users'ı sil — CASCADE zaten temizler ama sırayı bilerek kontrol et).

- [ ] **Step 5: Commit**

```bash
git add supabase/migrations/20260811000004_crm_v2_notes_and_tags.sql
git commit -m "feat(db): CRM v2 — müşteri notu/etiketleme tabloları + RPC'leri"
```

---

### Task 2: Web — not/etiket server action'ları + form bileşeni

**Files:**
- Create: `uygulamalar/web/app/sahip/musteriler/musteriler-islemleri.ts`
- Create: `uygulamalar/web/app/sahip/musteriler/[user_id]/etiket-not-formu.tsx`
- Modify: `uygulamalar/web/app/sahip/musteriler/[user_id]/page.tsx`
- Modify: `uygulamalar/web/app/sahip/musteriler/musteri-listesi.tsx` (sadece tip eklemesi — bu adım Task 3'ün de ihtiyaç duyduğu `MusteriOzet.tags` alanını önceden ekler, iki task arasında sıralama bağımlılığı yaratmamak için)

- [ ] **Step 1: `MusteriOzet` tipine `tags` alanını ekle**

`musteri-listesi.tsx`'teki `MusteriOzet` tipine `loyalty_reward_threshold: number | null;` satırından hemen sonra (son alan olarak) ekle:

```ts
  tags: { id: string; tag: string }[];
```

(Bu adımda tabloya görsel bir sütun EKLEME — o Task 3'te yapılacak, burada sadece tip tanımı güncelleniyor.)

- [ ] **Step 2: Server action'ları yaz**

`uygulamalar/web/app/sahip/musteriler/musteriler-islemleri.ts`:

```ts
'use server';

import { z } from 'zod';
import { revalidatePath } from 'next/cache';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { withAuth } from '@/src/lib/sunucu-eylem-kimlik-dogrulama';
import { rateLimit } from '@/src/lib/oran-siniri';

const REVALIDATE_PREFIX = '/sahip/musteriler';

type EylemSonucu = { error: string } | { ok: true };

const NotEkleSemasi = z.object({
  business_id: z.string().uuid(),
  user_id: z.string().uuid(),
  note: z.string().min(1).max(1000),
});

export async function notEkle(businessId: string, userId: string, note: string): Promise<EylemSonucu> {
  const parsed = NotEkleSemasi.safeParse({ business_id: businessId, user_id: userId, note });
  if (!parsed.success) return { error: 'Geçersiz form verisi' };
  const d = parsed.data;

  return withAuth(async (ownerId) => {
    const limitResult = rateLimit(`musteri-not-ekle:${ownerId}`, 20, 60_000);
    if (!limitResult.ok) return { error: 'Çok fazla istek gönderildi. Lütfen daha sonra tekrar deneyin.' };

    const supabase = await createSupabaseServerClient();
    const { error } = (await (supabase as any).rpc('add_customer_note_v1', {
      p_business_id: d.business_id,
      p_user_id: d.user_id,
      p_note: d.note,
    })) as { error: { message: string } | null };

    if (error) return { error: error.message };
    revalidatePath(`${REVALIDATE_PREFIX}/${d.user_id}`);
    return { ok: true };
  });
}

const EtiketEkleSemasi = z.object({
  business_id: z.string().uuid(),
  user_id: z.string().uuid(),
  tag: z.string().min(1).max(40),
});

export async function etiketEkle(businessId: string, userId: string, tag: string): Promise<EylemSonucu> {
  const parsed = EtiketEkleSemasi.safeParse({ business_id: businessId, user_id: userId, tag });
  if (!parsed.success) return { error: 'Geçersiz form verisi' };
  const d = parsed.data;

  return withAuth(async (ownerId) => {
    const limitResult = rateLimit(`musteri-etiket-ekle:${ownerId}`, 20, 60_000);
    if (!limitResult.ok) return { error: 'Çok fazla istek gönderildi. Lütfen daha sonra tekrar deneyin.' };

    const supabase = await createSupabaseServerClient();
    const { error } = (await (supabase as any).rpc('add_customer_tag_v1', {
      p_business_id: d.business_id,
      p_user_id: d.user_id,
      p_tag: d.tag,
    })) as { error: { message: string } | null };

    if (error) return { error: error.message };
    revalidatePath(`${REVALIDATE_PREFIX}/${d.user_id}`);
    revalidatePath(REVALIDATE_PREFIX);
    return { ok: true };
  });
}

const EtiketSilSemasi = z.object({ tag_id: z.string().uuid(), user_id: z.string().uuid() });

export async function etiketSil(tagId: string, userId: string): Promise<EylemSonucu> {
  const parsed = EtiketSilSemasi.safeParse({ tag_id: tagId, user_id: userId });
  if (!parsed.success) return { error: 'Geçersiz parametre' };
  const d = parsed.data;

  return withAuth(async (ownerId) => {
    const limitResult = rateLimit(`musteri-etiket-sil:${ownerId}`, 20, 60_000);
    if (!limitResult.ok) return { error: 'Çok fazla istek gönderildi. Lütfen daha sonra tekrar deneyin.' };

    const supabase = await createSupabaseServerClient();
    const { error } = (await (supabase as any).rpc('remove_customer_tag_v1', {
      p_tag_id: d.tag_id,
    })) as { error: { message: string } | null };

    if (error) return { error: error.message };
    revalidatePath(`${REVALIDATE_PREFIX}/${d.user_id}`);
    revalidatePath(REVALIDATE_PREFIX);
    return { ok: true };
  });
}
```

- [ ] **Step 3: Form bileşenini yaz**

`uygulamalar/web/app/sahip/musteriler/[user_id]/etiket-not-formu.tsx`:

```tsx
'use client';

import { useState } from 'react';
import { notEkle, etiketEkle, etiketSil } from '../musteriler-islemleri';

export type MusteriEtiketi = { id: string; tag: string };

export function EtiketNotFormu({
  businessId,
  userId,
  mevcutEtiketler,
}: {
  businessId: string;
  userId: string;
  mevcutEtiketler: MusteriEtiketi[];
}) {
  const [yeniEtiket, setYeniEtiket] = useState('');
  const [etiketPending, setEtiketPending] = useState(false);
  const [etiketError, setEtiketError] = useState<string | null>(null);

  const [yeniNot, setYeniNot] = useState('');
  const [notPending, setNotPending] = useState(false);
  const [notError, setNotError] = useState<string | null>(null);
  const [notEklendi, setNotEklendi] = useState(false);

  return (
    <div className="flex flex-col gap-4 border-t border-border pt-4">
      <div>
        <p className="mb-2 text-xs font-bold uppercase tracking-wide text-muted">Etiketler</p>
        <div className="mb-2 flex flex-wrap gap-1.5">
          {mevcutEtiketler.map((t) => (
            <span
              key={t.id}
              className="inline-flex items-center gap-1 rounded-full bg-primary/10 px-2.5 py-1 text-xs font-bold text-primary"
            >
              {t.tag}
              <button
                type="button"
                aria-label={`${t.tag} etiketini kaldır`}
                onClick={async () => {
                  await etiketSil(t.id, userId);
                }}
                className="text-primary/60 hover:text-primary"
              >
                ×
              </button>
            </span>
          ))}
        </div>
        <div className="flex gap-2">
          <input
            value={yeniEtiket}
            onChange={(e) => setYeniEtiket(e.target.value)}
            placeholder="Etiket ekle — örn. VIP"
            maxLength={40}
            className="flex-1 rounded-lg border border-border bg-bg px-2 py-1 text-xs"
          />
          <button
            type="button"
            disabled={etiketPending || !yeniEtiket.trim()}
            onClick={async () => {
              setEtiketPending(true);
              setEtiketError(null);
              const result = await etiketEkle(businessId, userId, yeniEtiket.trim());
              setEtiketPending(false);
              if ('error' in result) {
                setEtiketError(result.error);
                return;
              }
              setYeniEtiket('');
            }}
            className="rounded-lg bg-primary px-3 py-1 text-xs font-bold text-white disabled:opacity-50"
          >
            Ekle
          </button>
        </div>
        {etiketError && <p className="mt-1 text-xs font-bold text-red-600">{etiketError}</p>}
      </div>

      <div>
        <p className="mb-2 text-xs font-bold uppercase tracking-wide text-muted">Not ekle</p>
        <textarea
          value={yeniNot}
          onChange={(e) => setYeniNot(e.target.value)}
          placeholder="Bu müşteri için bir not yazın..."
          maxLength={1000}
          rows={3}
          className="w-full rounded-lg border border-border bg-bg px-2 py-1 text-xs"
        />
        <button
          type="button"
          disabled={notPending || !yeniNot.trim()}
          onClick={async () => {
            setNotPending(true);
            setNotError(null);
            const result = await notEkle(businessId, userId, yeniNot.trim());
            setNotPending(false);
            if ('error' in result) {
              setNotError(result.error);
              return;
            }
            setYeniNot('');
            setNotEklendi(true);
          }}
          className="mt-2 rounded-lg bg-primary px-3 py-1 text-xs font-bold text-white disabled:opacity-50"
        >
          {notPending ? 'Kaydediliyor…' : 'Kaydet'}
        </button>
        {notError && <p className="mt-1 text-xs font-bold text-red-600">{notError}</p>}
        {notEklendi && <p className="mt-1 text-xs text-muted">Not eklendi, zaman çizelgesinde görünüyor.</p>}
      </div>
    </div>
  );
}
```

- [ ] **Step 4: `page.tsx`'e entegre et**

`uygulamalar/web/app/sahip/musteriler/[user_id]/page.tsx` içindeki `PanelIcerikYuzeyi`/sol panel bloğunu bul (Task 3'te `PanelBolumKarti` kullanacak şekilde revize edilmişti — mevcut yapıyı bozmadan, sol paneldeki müşteri bilgisi bloğunun ALTINA `<EtiketNotFormu businessId={businessId} userId={musteriId} mevcutEtiketler={musteri.tags} />` satırını ekle). İmport ekle: `import { EtiketNotFormu } from './etiket-not-formu';`. (`musteri.tags` bu noktada Step 1'de eklenen tipten geliyor, sorunsuz derlenmeli.)

- [ ] **Step 5: Typecheck + lint**

Run (uygulamalar/web içinden): `pnpm run typecheck && pnpm run lint`
Expected: Hata yok.

- [ ] **Step 6: Commit**

```bash
git add app/sahip/musteriler/musteriler-islemleri.ts app/sahip/musteriler/\[user_id\]/etiket-not-formu.tsx app/sahip/musteriler/\[user_id\]/page.tsx app/sahip/musteriler/musteri-listesi.tsx
git commit -m "feat(web): CRM v2 — not/etiket ekleme formu ve server action'ları"
```

---

### Task 3: Web — liste sayfası etiket sütunu + zaman çizelgesi not olayı

**Files:**
- Modify: `uygulamalar/web/app/sahip/musteriler/musteri-listesi.tsx` (sadece görsel sütun — tip Task 2'de zaten eklendi)
- Modify: `uygulamalar/web/app/sahip/musteriler/[user_id]/zaman-cizelgesi.tsx`

- [ ] **Step 1: Tabloya etiket sütunu ekle**

Tablo başlığına (`<th className="py-2">Sadakat</th>` satırından hemen sonra) yeni bir sütun ekle:

```tsx
            <th className="py-2">Etiketler</th>
```

Her satıra (`<td className="py-2 text-textStrong">{m.loyalty_progress ?? '—'}</td>` satırından hemen sonra) karşılık gelen hücreyi ekle:

```tsx
              <td className="py-2">
                <div className="flex flex-wrap gap-1">
                  {m.tags.map((t) => (
                    <span
                      key={t.id}
                      className="rounded-full bg-primary/10 px-2 py-0.5 text-xs font-bold text-primary"
                    >
                      {t.tag}
                    </span>
                  ))}
                </div>
              </td>
```

- [ ] **Step 2: `zaman-cizelgesi.tsx`'e `note` olay tipi ekle**

`ZamanCizelgesiOlayi` tipindeki union'a `'note'` ekle:

```ts
export type ZamanCizelgesiOlayi = {
  event_type: 'review' | 'reservation' | 'loyalty_scan' | 'loyalty_redeem' | 'follow' | 'note';
  occurred_at: string;
  summary: string;
};
```

`OLAY_ETIKETLERI` map'ine ekle:

```ts
  note: '📝 Not',
```

- [ ] **Step 3: Typecheck + lint**

Run (uygulamalar/web içinden): `pnpm run typecheck && pnpm run lint`
Expected: Hata yok.

- [ ] **Step 4: Commit**

```bash
git add app/sahip/musteriler/musteri-listesi.tsx app/sahip/musteriler/\[user_id\]/zaman-cizelgesi.tsx
git commit -m "feat(web): CRM v2 — liste sayfasında etiket rozetleri + zaman çizelgesinde not olayı"
```

---

### Task 4: Web — test kapsamı

**Files:**
- Create: `uygulamalar/web/test/lib/musteriler-islemleri.test.ts`

- [ ] **Step 1: Server action testlerini yaz**

`uygulamalar/web/test/lib/musteriler-islemleri.test.ts`:

```ts
import { describe, it, expect } from 'vitest';
import { notEkle, etiketEkle, etiketSil } from '@/app/sahip/musteriler/musteriler-islemleri';

describe('CRM v2 müşteri not/etiket server action\'ları', () => {
  it('fonksiyonlar export edilir', () => {
    expect(typeof notEkle).toBe('function');
    expect(typeof etiketEkle).toBe('function');
    expect(typeof etiketSil).toBe('function');
  });

  it('notEkle boş not için hata döner', async () => {
    const result = await notEkle('11111111-1111-1111-1111-111111111111', '22222222-2222-2222-2222-222222222222', '');
    expect(result).toEqual({ error: 'Geçersiz form verisi' });
  });

  it('etiketEkle 40 karakterden uzun etiket için hata döner', async () => {
    const result = await etiketEkle(
      '11111111-1111-1111-1111-111111111111',
      '22222222-2222-2222-2222-222222222222',
      'a'.repeat(41),
    );
    expect(result).toEqual({ error: 'Geçersiz form verisi' });
  });

  it('etiketSil geçersiz tag_id için hata döner', async () => {
    const result = await etiketSil('not-a-uuid', '22222222-2222-2222-2222-222222222222');
    expect(result).toEqual({ error: 'Geçersiz parametre' });
  });
});
```

- [ ] **Step 2: Testi çalıştır**

Run (uygulamalar/web içinden): `npx vitest run musteriler-islemleri`
Expected: PASS (4 test).

- [ ] **Step 3: Commit**

```bash
git add test/lib/musteriler-islemleri.test.ts
git commit -m "test(web): CRM v2 — not/etiket server action zod doğrulama testleri"
```

---

### Task 5: Doğrulama — gerçek tarayıcı testi + production push

**Files:** (yalnızca doğrulama, yeni kod yok)

- [ ] **Step 1: Local'de test fixture kur**

Local Supabase (Docker) çalışıyor olmalı. `curl -X POST http://127.0.0.1:54321/auth/v1/signup ...` ile test owner + müşteri hesabı oluştur (form-doldurma flakiness'inden kaçınmak için), SQL ile `owner_claims` + en az bir yorum ekle (müşterinin listede görünmesi için).

- [ ] **Step 2: Web'i local Supabase'e işaret ettir, dev server başlat**

Worktree kullanılıyorsa `.env.local` doğrudan local değerlerle oluşturulabilir (ana checkout'a dokunulmaz). `pnpm run dev` (farklı bir portta çalıştırmak gerekiyorsa `PORT=<port> pnpm run dev`).

- [ ] **Step 3: Tarayıcıda doğrula**

Test owner ile giriş yap, `/sahip/musteriler/[user_id]` (test müşterisinin sayfası) sayfasına git.
- Bir etiket ekle (örn. "VIP") → rozet olarak göründüğünü doğrula.
- Aynı etiketi tekrar eklemeyi dene → hata mesajı görünmeli.
- Bir not ekle → sağdaki zaman çizelgesinde `📝 Not` olayı olarak en üstte göründüğünü doğrula.
- Etiketin (x) ikonuna tıkla → etiket kaybolmalı.
- `/sahip/musteriler` liste sayfasına dön → eklenen etiketin (silinmemişse) tabloda rozet olarak göründüğünü doğrula.

- [ ] **Step 4: Temizlik**

Test fixture'ını SQL ile sil (önce `customer_notes`/`customer_tags`, sonra business/users). `.env.local`'ı gerekiyorsa geri al, dev server'ı durdur (Windows'ta arka planda kalan process'i `netstat -ano | grep :<port>` ile bulup `taskkill //PID <pid> //F` ile öldürmeyi unutma).

- [ ] **Step 5: Production'a uygula**

Migration geçmişinde CRM v1'de karşılaşılan senkron sorunuyla aynı durum varsa (`supabase db push --linked` "Remote migration versions not found" hatası verirse), `mcp__supabase__apply_migration` ile migration SQL'ini doğrudan uygula, ardından `supabase migration repair --status applied 20260811000004 --linked` ile gerçek dosya version'ını history tablosunda işaretle. Sorun yoksa doğrudan `supabase db push --linked` kullan.

Ardından `has_function_privilege`/`has_table_privilege` ile production'da doğrudan doğrula (advisor cache'ine güvenme).

- [ ] **Step 6: Kullanıcıya rapor**

Test sonucu, hangi dosyalar değişti — özetle.
