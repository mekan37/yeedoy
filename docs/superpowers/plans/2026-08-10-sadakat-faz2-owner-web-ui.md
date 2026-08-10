# Sadakat v1 — Faz 2: Owner Web UI Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Owner web panelinde gerçek bir sadakat programı kurulum + QR tarama + CRM üye listesi ekranı inşa etmek. `app/sahip/pazarlama/sadakat/page.tsx` şu an redirect stub'ı — bu Faz'da gerçek sayfaya dönüşüyor. Faz 1'in DB/RPC yüzeyi (production'da çalışıyor ve güvenlik açısından doğrulanmış) üzerine inşa edilir.

**Architecture:** Sunucu bileşeni (`page.tsx`) premium gating + program durumu + üye listesini sunucu tarafında çeker; 3 istemci bileşeni (kurulum formu, QR tarama, üye listesi tablosu — üye listesi aslında saf sunum, client değil) etkileşimi yönetir. Server action dosyası (`sadakat-islemleri.ts`) mevcut `kampanya-islemleri.ts` deseniyle aynı (zod + `withAuth` + `rateLimit`). QR tarama `qr-scanner` npm paketiyle (yeni bağımlılık) tarayıcı kamerasından okur; QR içeriği düz metin olarak müşterinin `user_id` UUID'sidir (Faz 3/4'te müşteri tarafında bu formatla üretilecek — bu plan bunu sabitliyor).

**Tech Stack:** Next.js 15 Server Actions, Zod, `qr-scanner` (yeni), mevcut panel-yerleşim bileşenleri (`PanelSayfaBasligi`, `PanelIcerikYuzeyi`, `PanelEmptyState`).

---

### Task 1: DB — owner'ın kendi program durumunu okuyan RPC

Faz 1'de owner'ın "bu işletmede zaten bir program var mı, taslak mı aktif mi" bilgisini okuyacağı bir RPC unutulmuş — `loyalty_programs`'ın public-read politikası artık sadece `is_active = true` gösteriyor (Faz 1'in son güvenlik düzeltmesi), yani owner kendi taslak programını bile doğrudan SELECT ile göremez. Bu RPC o boşluğu kapatıyor.

**Files:**
- Create: `supabase/migrations/20260810000009_sadakat_v1_get_program_config_rpc.sql`

- [ ] **Step 1: Migration dosyasını oluştur**

```sql
-- Sadakat v1 Faz 2 — owner'ın kendi programının (taslak dahil) durumunu okuması.
-- bkz. docs/superpowers/plans/2026-08-10-sadakat-faz2-owner-web-ui.md

CREATE OR REPLACE FUNCTION public.get_business_loyalty_program_v1(p_business_id uuid)
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_program_id uuid;
  v_result jsonb;
BEGIN
  IF NOT public.is_owner_of_business(p_business_id) THEN
    RAISE EXCEPTION 'unauthorized' USING ERRCODE = 'P0002';
  END IF;

  v_program_id := public._resolve_loyalty_program_v1(p_business_id);
  IF v_program_id IS NULL THEN
    RETURN NULL;
  END IF;

  SELECT jsonb_build_object(
    'id', id,
    'mode', mode,
    'name', name,
    'reward_desc', reward_desc,
    'reward_threshold', reward_threshold,
    'is_active', is_active
  ) INTO v_result
  FROM public.loyalty_programs
  WHERE id = v_program_id;

  RETURN v_result;
END;
$$;

REVOKE ALL ON FUNCTION public.get_business_loyalty_program_v1(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_business_loyalty_program_v1(uuid) TO authenticated;
REVOKE EXECUTE ON FUNCTION public.get_business_loyalty_program_v1(uuid) FROM anon;
COMMENT ON FUNCTION public.get_business_loyalty_program_v1 IS
  'Owner/personel: kendi işletmesinin (taslak dahil) sadakat programını okur. Called by: app/sahip/pazarlama/sadakat.';
```

**Kritik hatırlatma (bkz. design doc §Güvenlik):** Bu üç satır (REVOKE ALL FROM PUBLIC + GRANT TO authenticated + REVOKE FROM anon) hepsi zorunlu — sadece ilkini yazmak `anon`'u PUBLIC üzerinden mirasla yetkili bırakır (Faz 1'de production'da tam olarak bu hatayla bir güvenlik açığı bulundu).

- [ ] **Step 2: Local doğrulama**

Run: `supabase db reset`
Expected: Hatasız uygulanır.

- [ ] **Step 3: Production'da anon'un çalıştıramadığını doğrudan doğrula**

Bu RPC production'a push edildikten SONRA (Task'ların sonunda, tüm Faz 2 bittiğinde tek seferde push edilecek — bkz. Task 8), şu sorguyu `mcp__supabase__execute_sql` ile çalıştır:

```sql
select has_function_privilege('anon', 'public.get_business_loyalty_program_v1(uuid)', 'EXECUTE') as anon_can_execute;
```

Expected: `false`. Advisor raporuna güvenme (Faz 1'de cache nedeniyle yanlış pozitif/negatif gösterdiği görüldü) — doğrudan sorguyla doğrula.

- [ ] **Step 4: Commit**

```bash
git add supabase/migrations/20260810000009_sadakat_v1_get_program_config_rpc.sql
git commit -m "feat(db): sadakat v1 faz 2 — owner'ın kendi program durumunu okuduğu RPC"
```

---

### Task 2: Web — qr-scanner bağımlılığını ekle

**Files:**
- Modify: `uygulamalar/web/package.json` (pnpm add ile otomatik)

- [ ] **Step 1: Paketi ekle**

Run (uygulamalar/web içinden): `pnpm add qr-scanner`
Expected: `package.json`'a `"qr-scanner": "^1.4.2"` (veya güncel stabil sürüm) eklenir, `pnpm-lock.yaml` güncellenir.

- [ ] **Step 2: Commit**

```bash
git add package.json pnpm-lock.yaml
git commit -m "chore(web): sadakat v1 QR tarama için qr-scanner bağımlılığı eklendi"
```

(Not: `pnpm-lock.yaml` repo köküne yakın bir yerde olabilir — `pnpm add` çıktısında hangi dosyanın değiştiğini kontrol et, doğru yolu kullan.)

---

### Task 3: Web — sidebar'a Sadakat nav girişi ekle

**Files:**
- Modify: `uygulamalar/web/src/ui/kabuk/sahip-kabuk-istemcisi.tsx`

- [ ] **Step 1: "Büyüme" bölümüne nav girişini ekle**

Modify `uygulamalar/web/src/ui/kabuk/sahip-kabuk-istemcisi.tsx` — şu satırı bul:

```tsx
      { href: '/sahip/pazarlama/kampanyalar', label: 'Pazarlama', icon: <MegaphoneIcon /> },
```

Hemen altına ekle:

```tsx
      { href: '/sahip/pazarlama/kampanyalar', label: 'Pazarlama', icon: <MegaphoneIcon /> },
      { href: '/sahip/pazarlama/sadakat', label: 'Sadakat', icon: <GiftIcon /> },
```

- [ ] **Step 2: GiftIcon fonksiyonunu ekle**

Aynı dosyada, `function MegaphoneIcon() { ... }` bloğunun hemen altına ekle:

```tsx
function GiftIcon() {
  return (
    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <rect x="3" y="8" width="18" height="4" />
      <path d="M12 8v13M19 12v9H5v-9" />
      <path d="M7.5 8a2.5 2.5 0 1 1 0-5C10 3 12 8 12 8" />
      <path d="M16.5 8a2.5 2.5 0 1 0 0-5C14 3 12 8 12 8" />
    </svg>
  );
}
```

- [ ] **Step 3: Typecheck**

Run (uygulamalar/web içinden): `pnpm run typecheck`
Expected: Hata yok.

- [ ] **Step 4: Commit**

```bash
git add src/ui/kabuk/sahip-kabuk-istemcisi.tsx
git commit -m "feat(web): sahip panel sidebar'a Sadakat nav öğesi ekle"
```

---

### Task 4: Web — server actions (sadakat-islemleri.ts)

**Files:**
- Create: `uygulamalar/web/app/sahip/pazarlama/sadakat/sadakat-islemleri.ts`

- [ ] **Step 1: Dosyayı oluştur**

```typescript
'use server';

import { z } from 'zod';
import { revalidatePath } from 'next/cache';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { withAuth } from '@/src/lib/sunucu-eylem-kimlik-dogrulama';
import { rateLimit } from '@/src/lib/oran-siniri';

const REVALIDATE = '/sahip/pazarlama/sadakat';

type EylemSonucu = { error: string } | { ok: true };

const ProgramOlusturSemasi = z.object({
  business_id: z.string().uuid(),
  mode: z.enum(['stamp', 'points']),
  name: z.string().min(1).max(80),
  reward_desc: z.string().min(1).max(200),
  reward_threshold: z.coerce.number().int().min(1).max(1000),
});

export async function programOlustur(
  _prev: EylemSonucu | null,
  formData: FormData,
): Promise<EylemSonucu> {
  const parsed = ProgramOlusturSemasi.safeParse({
    business_id: formData.get('business_id'),
    mode: formData.get('mode'),
    name: formData.get('name'),
    reward_desc: formData.get('reward_desc'),
    reward_threshold: formData.get('reward_threshold'),
  });
  if (!parsed.success) return { error: 'Geçersiz form verisi' };
  const d = parsed.data;

  return withAuth(async (userId) => {
    const limitResult = rateLimit(`sadakat-program-olustur:${userId}`, 10, 60_000);
    if (!limitResult.ok) return { error: 'Çok fazla istek gönderildi. Lütfen daha sonra tekrar deneyin.' };

    const supabase = await createSupabaseServerClient();
    const { error } = (await (supabase as any).rpc('create_loyalty_program_v1', {
      p_business_id: d.business_id,
      p_mode: d.mode,
      p_name: d.name,
      p_reward_desc: d.reward_desc,
      p_reward_threshold: d.reward_threshold,
    })) as { error: { message: string } | null };

    if (error) return { error: error.message };
    revalidatePath(REVALIDATE);
    return { ok: true };
  });
}

const AktiflikSemasi = z.object({
  program_id: z.string().uuid(),
  is_active: z.coerce.boolean(),
});

export async function programAktiflikDegistir(
  programId: string,
  isActive: boolean,
): Promise<EylemSonucu> {
  const parsed = AktiflikSemasi.safeParse({ program_id: programId, is_active: isActive });
  if (!parsed.success) return { error: 'Geçersiz parametre' };
  const d = parsed.data;

  return withAuth(async (userId) => {
    const limitResult = rateLimit(`sadakat-aktiflik:${userId}`, 20, 60_000);
    if (!limitResult.ok) return { error: 'Çok fazla istek gönderildi. Lütfen daha sonra tekrar deneyin.' };

    const supabase = await createSupabaseServerClient();
    const { error } = (await (supabase as any).rpc('set_loyalty_program_active_v1', {
      p_program_id: d.program_id,
      p_is_active: d.is_active,
    })) as { error: { message: string } | null };

    if (error) return { error: error.message };
    revalidatePath(REVALIDATE);
    return { ok: true };
  });
}

const QrOkutSemasi = z.object({
  business_id: z.string().uuid(),
  user_id: z.string().uuid(),
});

export type QrOkutSonucu =
  | { error: string }
  | { ok: true; member_id: string; progress: number; reward_threshold: number; reward_ready: boolean };

export async function qrOkut(businessId: string, userId: string): Promise<QrOkutSonucu> {
  const parsed = QrOkutSemasi.safeParse({ business_id: businessId, user_id: userId });
  if (!parsed.success) return { error: 'Geçersiz QR içeriği' };
  const d = parsed.data;

  return withAuth(async (ownerId) => {
    const limitResult = rateLimit(`sadakat-qr-okut:${ownerId}`, 60, 60_000);
    if (!limitResult.ok) return { error: 'Çok fazla istek gönderildi. Lütfen daha sonra tekrar deneyin.' };

    const supabase = await createSupabaseServerClient();
    const { data, error } = (await (supabase as any).rpc('scan_loyalty_qr_v1', {
      p_business_id: d.business_id,
      p_user_id: d.user_id,
    })) as {
      data: { member_id: string; progress: number; reward_threshold: number; reward_ready: boolean } | null;
      error: { message: string } | null;
    };

    if (error) return { error: error.message };
    if (!data) return { error: 'Beklenmeyen yanıt' };
    revalidatePath(REVALIDATE);
    return {
      ok: true,
      member_id: data.member_id,
      progress: data.progress,
      reward_threshold: data.reward_threshold,
      reward_ready: data.reward_ready,
    };
  });
}

const OdulKullanSemasi = z.object({ member_id: z.string().uuid() });

export type OdulKullanSonucu = { error: string } | { ok: true; progress: number };

export async function odulKullan(memberId: string): Promise<OdulKullanSonucu> {
  const parsed = OdulKullanSemasi.safeParse({ member_id: memberId });
  if (!parsed.success) return { error: 'Geçersiz parametre' };
  const d = parsed.data;

  return withAuth(async (ownerId) => {
    const limitResult = rateLimit(`sadakat-odul-kullan:${ownerId}`, 30, 60_000);
    if (!limitResult.ok) return { error: 'Çok fazla istek gönderildi. Lütfen daha sonra tekrar deneyin.' };

    const supabase = await createSupabaseServerClient();
    const { data, error } = (await (supabase as any).rpc('redeem_loyalty_reward_v1', {
      p_member_id: d.member_id,
    })) as { data: { member_id: string; progress: number } | null; error: { message: string } | null };

    if (error) return { error: error.message };
    if (!data) return { error: 'Beklenmeyen yanıt' };
    revalidatePath(REVALIDATE);
    return { ok: true, progress: data.progress };
  });
}
```

- [ ] **Step 2: Typecheck**

Run (uygulamalar/web içinden): `pnpm run typecheck`
Expected: Hata yok.

- [ ] **Step 3: Commit**

```bash
git add app/sahip/pazarlama/sadakat/sadakat-islemleri.ts
git commit -m "feat(web): sadakat v1 — owner server action'ları (program oluştur/aktive et/QR okut/ödül kullan)"
```

---

### Task 5: Web — kurulum formu istemci bileşeni

**Files:**
- Create: `uygulamalar/web/app/sahip/pazarlama/sadakat/sadakat-kurulum-istemcisi.tsx`

- [ ] **Step 1: Dosyayı oluştur**

```tsx
'use client';

import { useActionState, useState } from 'react';
import { programOlustur, programAktiflikDegistir } from './sadakat-islemleri';

export type SadakatProgram = {
  id: string;
  mode: 'stamp' | 'points';
  name: string;
  reward_desc: string;
  reward_threshold: number;
  is_active: boolean;
};

export function SadakatKurulumIstemcisi({
  businessId,
  program,
}: {
  businessId: string;
  program: SadakatProgram | null;
}) {
  const [state, formAction, pending] = useActionState(programOlustur, null);
  const [mode, setMode] = useState<'stamp' | 'points'>('stamp');
  const [toggling, setToggling] = useState(false);
  const [toggleError, setToggleError] = useState<string | null>(null);

  if (program) {
    return (
      <div className="space-y-3">
        <div className="flex items-center justify-between gap-4">
          <div>
            <p className="text-sm font-black text-textStrong">{program.name}</p>
            <p className="text-xs text-muted">
              {program.reward_desc} — eşik: {program.reward_threshold}
            </p>
          </div>
          <button
            type="button"
            disabled={toggling}
            onClick={async () => {
              setToggling(true);
              setToggleError(null);
              const result = await programAktiflikDegistir(program.id, !program.is_active);
              if ('error' in result) setToggleError(result.error);
              setToggling(false);
            }}
            className={
              program.is_active
                ? 'rounded-full bg-emerald-50 px-3 py-1.5 text-xs font-bold text-emerald-700 disabled:opacity-50'
                : 'rounded-full bg-zinc-100 px-3 py-1.5 text-xs font-bold text-zinc-500 disabled:opacity-50'
            }
          >
            {program.is_active ? 'Aktif — kapat' : 'Pasif — aktive et'}
          </button>
        </div>
        {toggleError && <p className="text-xs font-bold text-red-600">{toggleError}</p>}
      </div>
    );
  }

  return (
    <form action={formAction} className="space-y-3">
      <input type="hidden" name="business_id" value={businessId} />
      <input type="hidden" name="mode" value={mode} />
      <div>
        <p className="mb-1.5 text-xs font-bold uppercase tracking-wide text-muted">Program Modu</p>
        <div className="flex gap-2">
          <button
            type="button"
            onClick={() => setMode('stamp')}
            className={
              mode === 'stamp'
                ? 'rounded-xl bg-primary px-3 py-2 text-sm font-bold text-white'
                : 'rounded-xl border border-border px-3 py-2 text-sm font-bold text-textStrong'
            }
          >
            Damga Kartı
          </button>
          <button
            type="button"
            onClick={() => setMode('points')}
            className={
              mode === 'points'
                ? 'rounded-xl bg-primary px-3 py-2 text-sm font-bold text-white'
                : 'rounded-xl border border-border px-3 py-2 text-sm font-bold text-textStrong'
            }
          >
            Puan Sistemi
          </button>
        </div>
      </div>
      <input
        name="name"
        placeholder="Program adı — örn. Kahve Sadakat"
        required
        maxLength={80}
        className="w-full rounded-xl border border-border bg-bg px-3 py-2 text-sm text-textStrong"
      />
      <input
        name="reward_desc"
        placeholder="Ödül açıklaması — örn. 1 bedava filtre kahve"
        required
        maxLength={200}
        className="w-full rounded-xl border border-border bg-bg px-3 py-2 text-sm text-textStrong"
      />
      <input
        name="reward_threshold"
        type="number"
        min={1}
        max={1000}
        placeholder={mode === 'stamp' ? 'Eşik — örn. 10 damga' : 'Eşik — örn. 500 puan'}
        required
        className="w-full rounded-xl border border-border bg-bg px-3 py-2 text-sm text-textStrong"
      />
      {state && 'error' in state && <p className="text-xs font-bold text-red-600">{state.error}</p>}
      <button
        type="submit"
        disabled={pending}
        className="rounded-xl bg-primary px-4 py-2 text-sm font-bold text-white hover:opacity-90 disabled:opacity-50"
      >
        {pending ? 'Oluşturuluyor…' : 'Programı Oluştur'}
      </button>
    </form>
  );
}
```

- [ ] **Step 2: Typecheck**

Run (uygulamalar/web içinden): `pnpm run typecheck`
Expected: Hata yok (bu adımda `page.tsx` henüz bu bileşeni import etmiyor olabilir, sorun değil — sıradaki task'ta bağlanacak).

- [ ] **Step 3: Commit**

```bash
git add app/sahip/pazarlama/sadakat/sadakat-kurulum-istemcisi.tsx
git commit -m "feat(web): sadakat v1 — kurulum formu + aktivasyon toggle istemci bileşeni"
```

---

### Task 6: Web — QR tarama istemci bileşeni

**Files:**
- Create: `uygulamalar/web/app/sahip/pazarlama/sadakat/sadakat-tarama-istemcisi.tsx`

- [ ] **Step 1: Dosyayı oluştur**

```tsx
'use client';

import { useEffect, useRef, useState } from 'react';
import QrScanner from 'qr-scanner';
import { qrOkut, odulKullan, type QrOkutSonucu } from './sadakat-islemleri';

const UUID_RE = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

type BasariliSonuc = Extract<QrOkutSonucu, { ok: true }>;

export function SadakatTaramaIstemcisi({
  businessId,
  program,
}: {
  businessId: string;
  program: { is_active: boolean };
}) {
  const videoRef = useRef<HTMLVideoElement>(null);
  const busyRef = useRef(false);
  const [error, setError] = useState<string | null>(null);
  const [result, setResult] = useState<BasariliSonuc | null>(null);
  const [busy, setBusy] = useState(false);
  const [redeemDone, setRedeemDone] = useState(false);

  useEffect(() => {
    if (!program.is_active || !videoRef.current) return;

    const scanner = new QrScanner(
      videoRef.current,
      async (scanResult) => {
        const userId = scanResult.data.trim();
        if (!UUID_RE.test(userId) || busyRef.current) return;

        busyRef.current = true;
        setBusy(true);
        setError(null);
        setRedeemDone(false);

        const outcome = await qrOkut(businessId, userId);

        busyRef.current = false;
        setBusy(false);

        if ('error' in outcome) {
          setError(outcome.error);
          return;
        }
        setResult(outcome);
      },
      { returnDetailedScanResult: true, highlightScanRegion: true },
    );

    scanner.start().catch(() => setError('Kamera açılamadı. Tarayıcı izinlerini kontrol edin.'));

    return () => {
      scanner.stop();
      scanner.destroy();
    };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [program.is_active, businessId]);

  if (!program.is_active) {
    return <p className="text-sm text-muted">QR taramak için önce programı aktive edin.</p>;
  }

  return (
    <div className="space-y-3">
      <div className="overflow-hidden rounded-xl border border-border bg-bg">
        <video ref={videoRef} className="h-56 w-full object-cover" muted />
      </div>
      {busy && <p className="text-xs text-muted">İşleniyor…</p>}
      {error && <p className="text-xs font-bold text-red-600">{error}</p>}
      {result && (
        <div className="space-y-2 rounded-xl border border-border bg-card p-3">
          <div className="h-2.5 overflow-hidden rounded-full bg-zinc-100">
            <div
              className="h-2.5 rounded-full bg-primary"
              style={{
                width: `${Math.min(100, Math.round((result.progress / result.reward_threshold) * 100))}%`,
              }}
            />
          </div>
          <p className="text-xs font-bold text-textStrong">
            {result.progress} / {result.reward_threshold}
          </p>
          <button
            type="button"
            disabled={!result.reward_ready || redeemDone}
            onClick={async () => {
              setBusy(true);
              const outcome = await odulKullan(result.member_id);
              setBusy(false);
              if ('error' in outcome) {
                setError(outcome.error);
                return;
              }
              setResult({ ...result, progress: outcome.progress, reward_ready: outcome.progress >= result.reward_threshold });
              setRedeemDone(true);
            }}
            className="w-full rounded-xl bg-primary px-3 py-2 text-sm font-bold text-white disabled:opacity-40"
          >
            {redeemDone ? 'Ödül Kullanıldı' : 'Ödülü Kullan'}
          </button>
        </div>
      )}
    </div>
  );
}
```

- [ ] **Step 2: Typecheck**

Run (uygulamalar/web içinden): `pnpm run typecheck`
Expected: Hata yok. `qr-scanner` paketi Task 2'de eklendiği için tip hatası çıkmamalı.

- [ ] **Step 3: Commit**

```bash
git add app/sahip/pazarlama/sadakat/sadakat-tarama-istemcisi.tsx
git commit -m "feat(web): sadakat v1 — tarayıcı kamerasıyla QR okuma + ödül kullanma istemci bileşeni"
```

---

### Task 7: Web — üye listesi bileşeni + sayfayı bağla

**Files:**
- Create: `uygulamalar/web/app/sahip/pazarlama/sadakat/uye-listesi.tsx`
- Modify: `uygulamalar/web/app/sahip/pazarlama/sadakat/page.tsx` (redirect stub'ı gerçek sayfaya dönüştür)

- [ ] **Step 1: uye-listesi.tsx'i oluştur**

```tsx
export type SadakatUyesi = {
  member_id: string;
  user_id: string;
  display_name: string;
  progress: number;
  redeemed_count: number;
};

export function UyeListesi({ members }: { members: SadakatUyesi[] }) {
  if (members.length === 0) {
    return <p className="text-sm text-muted">Henüz hiç üye yok.</p>;
  }

  return (
    <div className="overflow-x-auto">
      <table className="w-full text-sm">
        <thead>
          <tr className="border-b border-border text-left text-xs font-bold uppercase tracking-wide text-muted">
            <th className="py-2">Müşteri</th>
            <th className="py-2">İlerleme</th>
            <th className="py-2">Kullanılan Ödül</th>
          </tr>
        </thead>
        <tbody className="divide-y divide-border">
          {members.map((m) => (
            <tr key={m.member_id}>
              <td className="py-2 font-semibold text-textStrong">{m.display_name}</td>
              <td className="py-2 text-textStrong">{m.progress}</td>
              <td className="py-2 text-muted">{m.redeemed_count}</td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}
```

- [ ] **Step 2: page.tsx'i tamamen değiştir**

Replace the entire content of `uygulamalar/web/app/sahip/pazarlama/sadakat/page.tsx` (currently a redirect stub) with:

```tsx
import type { Metadata } from 'next';
import { redirect } from 'next/navigation';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { getOwnerBusinessIds } from '@/src/lib/veri/owner/sahip-isletmeleri';
import { PanelSayfaBasligi } from '@/src/ui/yerlesim/panel-page-header';
import { PanelIcerikYuzeyi } from '@/src/ui/yerlesim/panel-section-card';
import { PanelEmptyState } from '@/src/ui/bilesenler/panel-bos-durum';
import { SadakatKurulumIstemcisi, type SadakatProgram } from './sadakat-kurulum-istemcisi';
import { SadakatTaramaIstemcisi } from './sadakat-tarama-istemcisi';
import { UyeListesi, type SadakatUyesi } from './uye-listesi';

export const metadata: Metadata = {
  title: 'Sadakat Programı | Sahip Paneli',
  robots: { index: false, follow: false },
};

export default async function SadakatSayfasi() {
  const supabase = await createSupabaseServerClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) redirect('/giris?redirect=/sahip/pazarlama/sadakat');

  const businessIds = await getOwnerBusinessIds(supabase as any, user.id);
  const businessId = businessIds[0];
  if (!businessId) redirect('/sahip');

  const sb = supabase as any;

  const { data: plan } = (await sb.rpc('get_my_plan_v1', { p_business_id: businessId })) as {
    data: { plan_tier: string; features: Array<{ feature_key: string; enabled: boolean }> } | null;
  };
  const sadakatAcik = plan?.features.some((f) => f.feature_key === 'sadakat_programi' && f.enabled) ?? false;

  if (!sadakatAcik) {
    return (
      <div className="flex flex-col">
        <PanelSayfaBasligi eyebrow="Pazarlama" title="Sadakat Programı" />
        <PanelIcerikYuzeyi className="pt-6">
          <PanelEmptyState
            icon={<span>🎁</span>}
            title="Sadakat programı Standart ve üzeri planlarda"
            description="Müşterilerinize damga kartı veya puan sistemi sunmak için planınızı yükseltin."
            action={
              <a
                href="mailto:destek@yeedoy.com"
                className="rounded-xl bg-primary px-4 py-2 text-sm font-bold text-white hover:opacity-90"
              >
                Planı yükselt
              </a>
            }
          />
        </PanelIcerikYuzeyi>
      </div>
    );
  }

  const { data: program } = (await sb.rpc('get_business_loyalty_program_v1', {
    p_business_id: businessId,
  })) as { data: SadakatProgram | null };

  const { data: members } = program
    ? ((await sb.rpc('get_business_loyalty_members_v1', { p_business_id: businessId })) as {
        data: SadakatUyesi[] | null;
      })
    : { data: null };

  return (
    <div className="flex flex-col gap-6">
      <PanelSayfaBasligi
        eyebrow="Pazarlama"
        title="Sadakat Programı"
        description="Müşterilerinize damga kartı veya puan sistemi sunun"
      />
      <PanelIcerikYuzeyi>
        <SadakatKurulumIstemcisi businessId={businessId} program={program ?? null} />
      </PanelIcerikYuzeyi>
      {program && (
        <PanelIcerikYuzeyi>
          <SadakatTaramaIstemcisi businessId={businessId} program={program} />
        </PanelIcerikYuzeyi>
      )}
      {program && (
        <PanelIcerikYuzeyi>
          <UyeListesi members={members ?? []} />
        </PanelIcerikYuzeyi>
      )}
    </div>
  );
}
```

- [ ] **Step 3: Typecheck + lint**

Run (uygulamalar/web içinden): `pnpm run typecheck && pnpm run lint`
Expected: Hata yok.

- [ ] **Step 4: Commit**

```bash
git add app/sahip/pazarlama/sadakat/page.tsx app/sahip/pazarlama/sadakat/uye-listesi.tsx
git commit -m "feat(web): sadakat v1 — owner sayfası: kurulum + QR tarama + üye listesi bağlandı, redirect stub'ı kaldırıldı"
```

---

### Task 8: Doğrulama — dev server'da gerçek tarayıcı testi + production'a push

**Files:** (yalnızca doğrulama + deploy, yeni kod yok)

- [ ] **Step 1: Dev server'ı başlat**

Run (uygulamalar/web içinden, arka planda): `pnpm run dev`

- [ ] **Step 2: Claude in Chrome ile golden path testi**

`/sahip/pazarlama/sadakat` sayfasına git (test owner hesabıyla giriş yapılmış, standard/pro planlı bir işletme ile):
1. Kilitli değilse kurulum formu görünmeli (mode toggle, ad, ödül, eşik alanları).
2. Bir program oluştur → sayfa "Aktif — kapat" / "Pasif — aktive et" toggle'ına dönmeli.
3. Aktive et → QR tarama ekranı (kamera izni istemi) görünmeli.
4. Kamera izni yoksa/test ortamında kamera yoksa, bu adımı manuel QR simülasyonu olmadan sadece UI'ın hata mesajını doğru gösterdiğini kontrol et ("Kamera açılamadı...").
5. Free/starter planlı bir test işletmesiyle giriş yapılırsa kilitli empty-state (🎁 ikonu + "Planı yükselt" linki) görünmeli.

- [ ] **Step 3: Production'a migration'ı push et**

Run: `supabase migration list --linked` (Task 1'deki `20260810000009` migration'ının Remote'ta olmadığını doğrula), sonra:
Run: `supabase db push --linked`
Expected: Tek migration uygulanır, hata yok.

- [ ] **Step 4: Production'da anon erişimini doğrudan doğrula**

`mcp__supabase__execute_sql` ile:
```sql
select has_function_privilege('anon', 'public.get_business_loyalty_program_v1(uuid)', 'EXECUTE') as anon_can_execute;
```
Expected: `false`.

- [ ] **Step 5: TypeScript tiplerini yeniden üret**

`mcp__supabase__generate_typescript_types` çalıştır, sonucu `src/lib/supabase/database.types.ts` ve `src/lib/taban/veri-tanimlari.ts`'e yaz (Faz 1'deki gibi — JSON zarfını `data['types']` ile çıkarıp iki dosyaya da yazmayı unutma).

- [ ] **Step 6: Kullanıcıya rapor**

Golden path test sonucu, hangi dosyalar eklendi, production push sonucu — özetle. Faz 3'e (müşteri web UI) geçişe hazır olduğunu bildir; müşteri QR kodunun `user_id` UUID'sini düz metin olarak kodlaması gerektiğini hatırlat (bu Faz'da owner tarama tarafı bu formatı bekleyecek şekilde sabitlendi).
