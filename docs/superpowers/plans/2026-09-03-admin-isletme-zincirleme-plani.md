# Admin İşletme Zincirleme Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** `/yonetici/isletmeler` sayfasında checkbox ile seçilen işletmeleri admin'in var olan bir zincire eklemesini veya sıfırdan yeni bir zincir kurmasını sağlamak.

**Architecture:** Yeni bir `admin_add_businesses_to_chain_v1` Postgres RPC'si (çakışma kontrolü + atomik toplu atama), yeni bir server-actions dosyası (`isletme-zincir-islemleri.ts`), yeni bir modal bileşeni (`isletme-zincire-bagla-modal.tsx`), ve mevcut `isletmeler-tablosu.tsx`'in toplu işlem çubuğuna üçüncü bir buton.

**Tech Stack:** Next.js 15 (App Router, server actions), Supabase Postgres (plpgsql RPC), TypeScript.

**Spec:** `docs/superpowers/specs/2026-09-03-admin-isletme-zincirleme-design.md`

---

### Task 1: `admin_add_businesses_to_chain_v1` RPC migration

**Files:**
- Create: `supabase/migrations/20260903120000_admin_add_businesses_to_chain_v1.sql`

- [ ] **Step 1: Write the migration file**

```sql
-- ─────────────────────────────────────────────────────────────────────────────
-- ADMIN İŞLETME ZİNCİRLEME
-- Admin panelinde checkbox ile seçilen işletmeleri bir zincire ekler.
-- Owner tarafındaki owner_add_business_to_chain_v1 sadece onaylı sahiplik
-- gerektirdiği için admin panelinde kullanılamıyor — bu RPC is_admin() ile
-- yetkilendirilmiş, herhangi bir işletmeyi herhangi bir zincire ekleyebilir.
-- ─────────────────────────────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION public.admin_add_businesses_to_chain_v1(
  p_chain_id      uuid,
  p_business_ids  uuid[]
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_conflict_text  text;
  v_next_sort      integer;
  v_id             uuid;
BEGIN
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'unauthorized' USING ERRCODE = 'P0002';
  END IF;

  IF p_business_ids IS NULL OR array_length(p_business_ids, 1) IS NULL THEN
    RAISE EXCEPTION 'validation_error: en az bir işletme seçilmeli' USING ERRCODE = 'P0003';
  END IF;

  IF NOT EXISTS (SELECT 1 FROM public.chains WHERE id = p_chain_id) THEN
    RAISE EXCEPTION 'not_found: zincir bulunamadı' USING ERRCODE = 'P0001';
  END IF;

  -- Çakışma kontrolü: seçilenlerden biri zaten FARKLI bir zincirdeyse tüm işlem reddedilir
  SELECT string_agg(format('%s (%s)', b.name, c.name), ', ')
    INTO v_conflict_text
  FROM public.businesses b
  JOIN public.chains c ON c.id = b.chain_id
  WHERE b.id = ANY(p_business_ids)
    AND b.chain_id IS NOT NULL
    AND b.chain_id != p_chain_id;

  IF v_conflict_text IS NOT NULL THEN
    RAISE EXCEPTION 'validation_error: şu işletmeler zaten başka bir zincirde: %', v_conflict_text
      USING ERRCODE = 'P0003';
  END IF;

  SELECT COALESCE(MAX(chain_sort_order), -1) INTO v_next_sort
  FROM public.businesses WHERE chain_id = p_chain_id;

  FOREACH v_id IN ARRAY p_business_ids LOOP
    v_next_sort := v_next_sort + 1;
    UPDATE public.businesses
    SET chain_id = p_chain_id, chain_sort_order = v_next_sort
    WHERE id = v_id AND (chain_id IS NULL OR chain_id = p_chain_id);
  END LOOP;

  RETURN jsonb_build_object('ok', true, 'added_count', array_length(p_business_ids, 1));
END;
$$;

REVOKE ALL ON FUNCTION public.admin_add_businesses_to_chain_v1(uuid, uuid[]) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.admin_add_businesses_to_chain_v1(uuid, uuid[]) TO authenticated;
REVOKE EXECUTE ON FUNCTION public.admin_add_businesses_to_chain_v1(uuid, uuid[]) FROM anon;
COMMENT ON FUNCTION public.admin_add_businesses_to_chain_v1 IS
  'Admin: seçilen işletmeleri bir zincire ekler (farklı bir zincirdeyse reddeder). Called by: app/yonetici/isletmeler/isletme-zincir-islemleri.ts.';
```

- [ ] **Step 2: Apply the migration**

Use the `mcp__supabase__apply_migration` tool with:
- `name`: `admin_add_businesses_to_chain_v1`
- `query`: the full SQL from Step 1

- [ ] **Step 3: Verify the function was created with anon revoked**

Use `mcp__supabase__execute_sql` with:

```sql
SELECT
  p.proname,
  has_function_privilege('anon', p.oid, 'EXECUTE') AS anon_can_execute,
  has_function_privilege('authenticated', p.oid, 'EXECUTE') AS authenticated_can_execute
FROM pg_proc p
WHERE p.proname = 'admin_add_businesses_to_chain_v1';
```

Expected: one row, `anon_can_execute = false`, `authenticated_can_execute = true`.

- [ ] **Step 4: Manually verify the conflict-rejection path**

Use `mcp__supabase__execute_sql` to pick two real ids and confirm the logic (read-only, no admin JWT context available via SQL editor so `is_admin()` will fail as expected — this just confirms the function compiles and the conflict query itself is correct):

```sql
-- Sanity check the conflict-detection subquery in isolation (no is_admin() involved)
SELECT b.id, b.name, b.chain_id, c.name AS chain_name
FROM public.businesses b
LEFT JOIN public.chains c ON c.id = b.chain_id
WHERE b.chain_id IS NOT NULL
LIMIT 3;
```

Expected: returns up to 3 rows (or zero rows if no business is currently in a chain — either is fine, this just confirms the join is valid SQL). Real end-to-end conflict testing happens in Task 5 through the UI.

- [ ] **Step 5: Commit**

```bash
git add supabase/migrations/20260903120000_admin_add_businesses_to_chain_v1.sql
git commit -m "feat(supabase): admin_add_businesses_to_chain_v1 RPC eklendi"
```

---

### Task 2: Server actions — `isletme-zincir-islemleri.ts`

**Files:**
- Create: `uygulamalar/web/app/yonetici/isletmeler/isletme-zincir-islemleri.ts`

This file follows the exact pattern already used in `uygulamalar/web/app/yonetici/isletmeler/isletme-duzenle-islemleri.ts` (`checkAdminAccess()` guard, `createSupabaseServerClient()`, `sb.rpc(...)`, `logger.warn`, `revalidatePath`).

- [ ] **Step 1: Write the file**

```typescript
'use server';

import { revalidatePath } from 'next/cache';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { checkAdminAccess } from '@/src/lib/auth/admin-guard';
import { logger } from '@/src/lib/kayitci';

type IslemSonucu = { ok: true } | { ok: false; error: string };

type SbRpc = { rpc: (fn: string, args?: Record<string, unknown>) => Promise<{ data: unknown; error: unknown }> };

export interface ZincirAramaSonucu {
  id: string;
  name: string;
  category: string | null;
}

export async function zincirAra(query: string): Promise<ZincirAramaSonucu[]> {
  const guard = await checkAdminAccess();
  if (!guard.authorized) return [];

  const trimmed = query.trim();
  if (!trimmed) return [];

  const supabase = await createSupabaseServerClient();
  const { data, error } = await supabase
    .from('chains')
    .select('id, name, category')
    .ilike('name', `%${trimmed}%`)
    .order('name', { ascending: true })
    .limit(10);

  if (error) {
    logger.warn('zincirAra: sorgu hatası', { error, query: trimmed });
    return [];
  }

  return (data ?? []).map((c) => ({ id: c.id, name: c.name, category: c.category ?? null }));
}

function zincirHatasiCevir(mesaj: string | undefined): string {
  if (!mesaj) return 'İşlem başarısız oldu, tekrar deneyin.';
  if (mesaj.includes('unauthorized')) return 'Bu işlem için yetkiniz yok.';
  if (mesaj.includes('not_found')) return 'Zincir bulunamadı.';
  if (mesaj.includes('validation_error: en az bir işletme')) return 'En az bir işletme seçmelisiniz.';
  if (mesaj.includes('validation_error: şu işletmeler zaten başka bir zincirde:')) {
    return mesaj.split('validation_error: ')[1] ?? mesaj;
  }
  return 'İşlem başarısız oldu, tekrar deneyin.';
}

export async function isletmeleriZincireBagla(chainId: string, businessIds: string[]): Promise<IslemSonucu> {
  const guard = await checkAdminAccess();
  if (!guard.authorized) return { ok: false, error: 'Bu işlem için yetkiniz yok.' };
  if (!chainId) return { ok: false, error: 'Zincir seçilmedi.' };
  if (businessIds.length === 0) return { ok: false, error: 'En az bir işletme seçmelisiniz.' };

  const supabase = await createSupabaseServerClient();
  const sb = supabase as unknown as SbRpc;

  const { error } = await sb.rpc('admin_add_businesses_to_chain_v1', {
    p_chain_id: chainId,
    p_business_ids: businessIds,
  });

  if (error) {
    logger.warn('isletmeleriZincireBagla: RPC hatası', { error, chainId, businessIds });
    const mesaj = (error as { message?: string } | null)?.message;
    return { ok: false, error: zincirHatasiCevir(mesaj) };
  }

  revalidatePath('/yonetici/isletmeler');
  revalidatePath('/yonetici/zincirler');
  return { ok: true };
}

export async function yeniZincirKurVeBagla(name: string, businessIds: string[]): Promise<IslemSonucu> {
  const guard = await checkAdminAccess();
  if (!guard.authorized) return { ok: false, error: 'Bu işlem için yetkiniz yok.' };
  if (!name.trim()) return { ok: false, error: 'Zincir adı zorunlu.' };
  if (businessIds.length === 0) return { ok: false, error: 'En az bir işletme seçmelisiniz.' };

  const supabase = await createSupabaseServerClient();
  const sb = supabase as unknown as SbRpc;

  const { data: createData, error: createError } = await sb.rpc('admin_create_chain_v1', {
    p_name: name.trim(),
  });

  if (createError) {
    logger.warn('yeniZincirKurVeBagla: admin_create_chain_v1 hatası', { error: createError, name });
    return { ok: false, error: 'Zincir oluşturulamadı, tekrar deneyin.' };
  }

  const created = createData as { ok?: boolean; chain_id?: string } | null;
  if (!created?.ok || !created.chain_id) {
    return { ok: false, error: 'Zincir oluşturulamadı, tekrar deneyin.' };
  }

  return isletmeleriZincireBagla(created.chain_id, businessIds);
}
```

- [ ] **Step 2: Verify TypeScript compiles**

Run: `cd uygulamalar/web && pnpm run typecheck`
Expected: no errors referencing `isletme-zincir-islemleri.ts`.

- [ ] **Step 3: Commit**

```bash
git add uygulamalar/web/app/yonetici/isletmeler/isletme-zincir-islemleri.ts
git commit -m "feat(web): admin zincirleme server action'ları eklendi"
```

---

### Task 3: Modal component — `isletme-zincire-bagla-modal.tsx`

**Files:**
- Create: `uygulamalar/web/app/yonetici/isletmeler/isletme-zincire-bagla-modal.tsx`

This mirrors the visual structure of `uygulamalar/web/app/yonetici/isletmeler/isletme-birlestir-bolumu.tsx` (same debounced search pattern, same `PanelActionButton` usage, same semantic token classes) but as a full modal (fixed overlay) since it's triggered from the table's bulk toolbar rather than embedded inside the edit modal.

- [ ] **Step 1: Write the component**

```typescript
'use client';

import { useRef, useState } from 'react';
import { PanelActionButton } from '@/src/ui/bilesenler/panel-eylem-dugmesi';
import {
  zincirAra,
  isletmeleriZincireBagla,
  yeniZincirKurVeBagla,
  type ZincirAramaSonucu,
} from './isletme-zincir-islemleri';

type Sekme = 'mevcut' | 'yeni';

export function IsletmeZincireBaglaModal({
  businesses,
  onClose,
  onDone,
}: {
  businesses: { id: string; name: string }[];
  onClose: () => void;
  onDone: () => void;
}) {
  const [sekme, setSekme] = useState<Sekme>('mevcut');
  const [query, setQuery] = useState('');
  const [results, setResults] = useState<ZincirAramaSonucu[]>([]);
  const [searching, setSearching] = useState(false);
  const [selectedChain, setSelectedChain] = useState<ZincirAramaSonucu | null>(null);
  const [newChainName, setNewChainName] = useState('');
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const debounceRef = useRef<ReturnType<typeof setTimeout> | null>(null);
  const requestIdRef = useRef(0);

  const businessIds = businesses.map((b) => b.id);

  function handleSearch(q: string) {
    setQuery(q);
    setError(null);
    if (debounceRef.current) clearTimeout(debounceRef.current);

    if (!q.trim()) {
      requestIdRef.current += 1;
      setResults([]);
      setSearching(false);
      return;
    }

    debounceRef.current = setTimeout(() => {
      const requestId = ++requestIdRef.current;
      setSearching(true);
      zincirAra(q).then((sonuc) => {
        if (requestIdRef.current !== requestId) return;
        setResults(sonuc);
        setSearching(false);
      });
    }, 300);
  }

  function handleConfirmExisting() {
    if (!selectedChain) return;
    setSubmitting(true);
    setError(null);
    isletmeleriZincireBagla(selectedChain.id, businessIds).then((res) => {
      setSubmitting(false);
      if (!res.ok) {
        setError(res.error);
        return;
      }
      onDone();
    });
  }

  function handleConfirmNew() {
    if (!newChainName.trim()) return;
    setSubmitting(true);
    setError(null);
    yeniZincirKurVeBagla(newChainName, businessIds).then((res) => {
      setSubmitting(false);
      if (!res.ok) {
        setError(res.error);
        return;
      }
      onDone();
    });
  }

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4" onClick={onClose}>
      <div
        className="flex max-h-[85vh] w-full max-w-md flex-col gap-4 overflow-y-auto rounded-2xl border border-border bg-card p-5 shadow-yd2"
        onClick={(e) => e.stopPropagation()}
      >
        <div className="flex items-center justify-between">
          <h2 className="text-base font-black text-textStrong">Zincire Bağla</h2>
          <button type="button" onClick={onClose} className="text-xs font-bold text-muted hover:underline">
            Kapat
          </button>
        </div>

        <p className="text-xs font-bold text-muted">
          {businesses.length} işletme: {businesses.map((b) => b.name).join(', ')}
        </p>

        <div className="flex gap-1 rounded-xl border border-border bg-bg p-1">
          <button
            type="button"
            onClick={() => setSekme('mevcut')}
            className={`flex-1 rounded-lg px-3 py-1.5 text-xs font-bold transition-colors ${
              sekme === 'mevcut' ? 'bg-card text-textStrong shadow-yd' : 'text-muted'
            }`}
          >
            Var olan zincire ekle
          </button>
          <button
            type="button"
            onClick={() => setSekme('yeni')}
            className={`flex-1 rounded-lg px-3 py-1.5 text-xs font-bold transition-colors ${
              sekme === 'yeni' ? 'bg-card text-textStrong shadow-yd' : 'text-muted'
            }`}
          >
            Yeni zincir kur
          </button>
        </div>

        {sekme === 'mevcut' ? (
          <div className="flex flex-col gap-2">
            {!selectedChain ? (
              <>
                <input
                  value={query}
                  onChange={(e) => handleSearch(e.target.value)}
                  placeholder="Zincir adı ara..."
                  className="min-h-11 w-full rounded-xl border border-border bg-bg px-4 py-2 text-sm text-textStrong placeholder:text-muted focus:outline-hidden focus:ring-2 focus:ring-primary/30"
                />
                {searching && <p className="text-xs font-bold text-muted">Aranıyor...</p>}
                {results.length > 0 && (
                  <div className="flex flex-col gap-1 rounded-xl border border-border bg-bg p-1">
                    {results.map((c) => (
                      <button
                        key={c.id}
                        type="button"
                        onClick={() => setSelectedChain(c)}
                        className="flex items-center justify-between rounded-lg px-3 py-2 text-left text-sm hover:bg-black/4"
                      >
                        <span className="font-bold text-textStrong">{c.name}</span>
                        <span className="text-xs text-muted">{c.category || '—'}</span>
                      </button>
                    ))}
                  </div>
                )}
                {!searching && query.trim() && results.length === 0 && (
                  <p className="text-xs font-bold text-muted">Sonuç bulunamadı.</p>
                )}
              </>
            ) : (
              <div className="flex flex-col gap-3 rounded-xl border border-border bg-bg p-3">
                <div className="flex items-center justify-between gap-2">
                  <p className="text-sm font-black text-textStrong">{selectedChain.name}</p>
                  <button
                    type="button"
                    onClick={() => setSelectedChain(null)}
                    disabled={submitting}
                    className="shrink-0 text-xs font-bold text-muted hover:underline disabled:opacity-50"
                  >
                    Değiştir
                  </button>
                </div>
                <PanelActionButton variant="primary" loading={submitting} onClick={handleConfirmExisting}>
                  Bağla
                </PanelActionButton>
              </div>
            )}
          </div>
        ) : (
          <div className="flex flex-col gap-3">
            <input
              value={newChainName}
              onChange={(e) => setNewChainName(e.target.value)}
              placeholder="Zincir adı (ör. Sofra Kebap)"
              className="min-h-11 w-full rounded-xl border border-border bg-bg px-4 py-2 text-sm text-textStrong placeholder:text-muted focus:outline-hidden focus:ring-2 focus:ring-primary/30"
            />
            <PanelActionButton
              variant="primary"
              loading={submitting}
              onClick={handleConfirmNew}
              disabled={!newChainName.trim()}
            >
              Kur ve Bağla
            </PanelActionButton>
          </div>
        )}

        {error && <p className="text-xs font-bold text-(--yd-color-danger)">{error}</p>}
      </div>
    </div>
  );
}
```

- [ ] **Step 2: Verify TypeScript compiles**

Run: `cd uygulamalar/web && pnpm run typecheck`
Expected: no errors referencing `isletme-zincire-bagla-modal.tsx`. If `PanelActionButton`'s prop types don't include `disabled`, remove that prop from the "Kur ve Bağla" button and instead guard inside `handleConfirmNew` only (the function already checks `!newChainName.trim()` and returns early) — check `uygulamalar/web/src/ui/bilesenler/panel-eylem-dugmesi.tsx` for the exact prop signature before deciding.

- [ ] **Step 3: Commit**

```bash
git add uygulamalar/web/app/yonetici/isletmeler/isletme-zincire-bagla-modal.tsx
git commit -m "feat(web): işletmeleri zincire bağlama modalı eklendi"
```

---

### Task 4: Wire into `isletmeler-tablosu.tsx`

**Files:**
- Modify: `uygulamalar/web/app/yonetici/isletmeler/isletmeler-tablosu.tsx`

- [ ] **Step 1: Add the import and state**

In `uygulamalar/web/app/yonetici/isletmeler/isletmeler-tablosu.tsx`, add this import alongside the existing ones (after the `IsletmeDuzenleModal` import on line 7):

```typescript
import { IsletmeZincireBaglaModal } from './isletme-zincire-bagla-modal';
```

Add a new piece of state alongside the existing `duzenlenen` state (after line 24, `const [duzenlenen, setDuzenlenen] = useState<{ id: string; name: string } | null>(null);`):

```typescript
  const [zincirlemeAcik, setZincirlemeAcik] = useState(false);
```

- [ ] **Step 2: Add the button to the bulk toolbar**

Replace the bulk-action button group (lines 56-60):

```typescript
          <div className="flex items-center gap-2">
            {error && <span className="text-[10px] font-bold text-red-600">{error}</span>}
            <PanelActionButton variant="secondary" loading={isPending} onClick={() => bulkAction('approve')} className="py-1 text-xs">Toplu Aktif Et</PanelActionButton>
            <PanelActionButton variant="danger" loading={isPending} onClick={() => bulkAction('reject')} className="py-1 text-xs">Toplu Pasif Et</PanelActionButton>
          </div>
```

with:

```typescript
          <div className="flex items-center gap-2">
            {error && <span className="text-[10px] font-bold text-red-600">{error}</span>}
            <PanelActionButton variant="secondary" loading={isPending} onClick={() => setZincirlemeAcik(true)} className="py-1 text-xs">Zincire Bağla</PanelActionButton>
            <PanelActionButton variant="secondary" loading={isPending} onClick={() => bulkAction('approve')} className="py-1 text-xs">Toplu Aktif Et</PanelActionButton>
            <PanelActionButton variant="danger" loading={isPending} onClick={() => bulkAction('reject')} className="py-1 text-xs">Toplu Pasif Et</PanelActionButton>
          </div>
```

- [ ] **Step 3: Render the modal**

After the existing `{duzenlenen && (...)}` block (after line 147, before the closing `</div>` of the component return on line 148), add:

```typescript
      {zincirlemeAcik && (
        <IsletmeZincireBaglaModal
          businesses={rows.filter((r) => selected.has(r.id)).map((r) => ({ id: r.id, name: r.name }))}
          onClose={() => setZincirlemeAcik(false)}
          onDone={() => {
            setZincirlemeAcik(false);
            setSelected(new Set());
            router.refresh();
          }}
        />
      )}
```

- [ ] **Step 4: Verify TypeScript compiles and lint passes**

Run: `cd uygulamalar/web && pnpm run typecheck && pnpm run lint`
Expected: no errors.

- [ ] **Step 5: Commit**

```bash
git add uygulamalar/web/app/yonetici/isletmeler/isletmeler-tablosu.tsx
git commit -m "feat(web): işletme listesine toplu zincire bağlama butonu eklendi"
```

---

### Task 5: End-to-end verification

**Files:** none (verification only)

- [ ] **Step 1: Start the dev server**

Run: `cd uygulamalar/web && pnpm dev` (background)
Wait for `Ready` in the output.

- [ ] **Step 2: Browser walkthrough — happy path (new chain)**

Using the claude-in-chrome browser tools: navigate to `/yonetici/isletmeler`, log in as admin if needed, select 2 businesses via checkbox, click "Zincire Bağla", switch to "Yeni zincir kur", type a test chain name (e.g. `Test Zincir E2E`), click "Kur ve Bağla". Expected: modal closes, selection clears, table refreshes with no error banner.

- [ ] **Step 3: Verify in the database**

Use `mcp__supabase__execute_sql`:

```sql
SELECT b.name, b.chain_id, b.chain_sort_order, c.name AS chain_name
FROM public.businesses b
JOIN public.chains c ON c.id = b.chain_id
WHERE c.name = 'Test Zincir E2E';
```

Expected: 2 rows, `chain_sort_order` 0 and 1, both pointing to the new chain.

- [ ] **Step 4: Browser walkthrough — conflict path**

Select one of the same 2 businesses (already in `Test Zincir E2E`) plus one new, unrelated business. Click "Zincire Bağla" → "Var olan zincire ekle" → search for a different, pre-existing chain (any other row in `/yonetici/zincirler`) → select it → click "Bağla". Expected: an error message appears in the modal naming the conflicting business and its current chain (`Test Zincir E2E`), no row's `chain_id` changes.

- [ ] **Step 5: Clean up the test chain**

Use `mcp__supabase__execute_sql`:

```sql
UPDATE public.businesses SET chain_id = NULL, chain_sort_order = NULL
WHERE chain_id = (SELECT id FROM public.chains WHERE name = 'Test Zincir E2E');

DELETE FROM public.chains WHERE name = 'Test Zincir E2E';
```

- [ ] **Step 6: Run `mcp__supabase__get_advisors`**

Use `mcp__supabase__get_advisors` with `type: security`. Expected: no new findings referencing `admin_add_businesses_to_chain_v1` (specifically no "function has EXECUTE granted to anon" warning — confirms the Task 1 REVOKE actually took effect).

- [ ] **Step 7: Final commit (only if any cleanup files changed)**

If Steps 2-6 didn't require any code changes, there is nothing to commit here — this task is verification-only. If a bug was found and fixed during verification, commit that fix with its own descriptive message before finishing.
