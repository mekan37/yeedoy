# Destek Sistemi (Owner) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Owner panelinde (`app/sahip/**`) mevcut admin-only `support_tickets`/`support_ticket_messages` tablolarını owner'ın kendi destek talebini açıp takip edebileceği bir sayfaya (`/sahip/destek`) bağlamak.

**Architecture:** Yeni migration `support_tickets`'a `business_id` ekliyor + owner-facing RLS policy'leri + `touch_support_ticket_v1` RPC'si ekliyor. Web tarafında saf yardımcı fonksiyonlar (`destek-yardimcilari.ts`), server action'lar (`destek-islemleri.ts`), ve orkestratör + `bilesenler/` alt klasöründe küçük bileşenler (menü düzenleyici planındaki aynı desen). Admin tarafına (`app/yonetici/musteri-destek/`) sadece bir e-posta bildirimi eklemek dışında dokunulmuyor.

**Tech Stack:** Next.js 15 (App Router, Server Actions), Supabase (Postgres/RLS), TypeScript, Vitest, Tailwind (semantic tokens).

**Spec:** `docs/superpowers/specs/2026-08-06-destek-sistemi-design.md`

---

### Task 0: Migration — business_id, owner RLS policy'leri, touch RPC

**Files:**
- Create: `supabase/migrations/20260806000001_destek_sistemi_owner.sql`

- [ ] **Step 1: Migration dosyasını yaz**

Create `supabase/migrations/20260806000001_destek_sistemi_owner.sql`:

```sql
-- Destek Sistemi (Owner) — support_tickets'a business_id + owner-facing RLS + touch RPC.
-- Admin tarafı (support_tickets/support_ticket_messages, 20260520000001) değişmiyor,
-- sadece owner'ın kendi taleplerine eriştiği yeni policy'ler ekleniyor.

ALTER TABLE public.support_tickets
  ADD COLUMN IF NOT EXISTS business_id uuid REFERENCES public.businesses(id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS idx_support_tickets_business_id ON public.support_tickets(business_id);

DROP POLICY IF EXISTS support_tickets_owner_select ON public.support_tickets;
CREATE POLICY support_tickets_owner_select ON public.support_tickets
  FOR SELECT TO authenticated USING (user_id = auth.uid());

DROP POLICY IF EXISTS support_tickets_owner_insert ON public.support_tickets;
CREATE POLICY support_tickets_owner_insert ON public.support_tickets
  FOR INSERT TO authenticated WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS support_ticket_messages_owner_select ON public.support_ticket_messages;
CREATE POLICY support_ticket_messages_owner_select ON public.support_ticket_messages
  FOR SELECT TO authenticated USING (
    EXISTS (SELECT 1 FROM public.support_tickets t WHERE t.id = ticket_id AND t.user_id = auth.uid())
  );

DROP POLICY IF EXISTS support_ticket_messages_owner_insert ON public.support_ticket_messages;
CREATE POLICY support_ticket_messages_owner_insert ON public.support_ticket_messages
  FOR INSERT TO authenticated WITH CHECK (
    sender = 'user'
    AND EXISTS (SELECT 1 FROM public.support_tickets t WHERE t.id = ticket_id AND t.user_id = auth.uid())
  );

-- Owner kendi ticket'ının updated_at'ini güncelleyemez (support_tickets_admin_all
-- FOR ALL policy'si sadece admin'e UPDATE izni veriyor) — mesaj gönderdiğinde
-- sıralamanın güncel kalması için dar kapsamlı bir SECURITY DEFINER RPC.
CREATE OR REPLACE FUNCTION public.touch_support_ticket_v1(p_ticket_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'unauthorized' USING ERRCODE = 'P0002';
  END IF;

  UPDATE public.support_tickets
  SET updated_at = now()
  WHERE id = p_ticket_id AND user_id = auth.uid();
END;
$$;

REVOKE ALL ON FUNCTION public.touch_support_ticket_v1(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.touch_support_ticket_v1(uuid) TO authenticated;
COMMENT ON FUNCTION public.touch_support_ticket_v1 IS
  'Owner: kendi destek talebinin updated_at alanını günceller (yeni mesaj sonrası). Called by: app/sahip/destek/destek-islemleri.ts.';
```

- [ ] **Step 2: Lokal Supabase'i sıfırla ve doğrula**

Run: `supabase db reset`
Expected: Hatasız biter.

Run (doğrulama):
```bash
psql "postgresql://postgres:postgres@127.0.0.1:54322/postgres" -c "\d public.support_tickets" | grep business_id
```
Expected: `business_id` kolonu listelenir.

- [ ] **Step 3: Commit**

```bash
git add supabase/migrations/20260806000001_destek_sistemi_owner.sql
git commit -m "feat(db): destek sistemi — support_tickets'a business_id, owner RLS policy'leri, touch_support_ticket_v1"
```

---

### Task 1: Saf yardımcı fonksiyonlar + testler

**Files:**
- Create: `uygulamalar/web/app/sahip/destek/destek-yardimcilari.ts`
- Test: `uygulamalar/web/test/lib/destek-yardimcilari.test.ts`

- [ ] **Step 1: Başarısız testi yaz**

`uygulamalar/web/test/lib/destek-yardimcilari.test.ts`:

```ts
import { describe, it, expect } from 'vitest';
import { ticketMatchesTab, formatTicketNo } from '@/app/sahip/destek/destek-yardimcilari';

describe('ticketMatchesTab', () => {
  it('tumu her durumu kapsar', () => {
    expect(ticketMatchesTab('open', 'tumu')).toBe(true);
    expect(ticketMatchesTab('closed', 'tumu')).toBe(true);
  });

  it('acik sadece open durumunu kapsar', () => {
    expect(ticketMatchesTab('open', 'acik')).toBe(true);
    expect(ticketMatchesTab('in_progress', 'acik')).toBe(false);
  });

  it('beklemede sadece in_progress durumunu kapsar', () => {
    expect(ticketMatchesTab('in_progress', 'beklemede')).toBe(true);
    expect(ticketMatchesTab('open', 'beklemede')).toBe(false);
  });

  it('cozuldu resolved ve closed durumlarını kapsar', () => {
    expect(ticketMatchesTab('resolved', 'cozuldu')).toBe(true);
    expect(ticketMatchesTab('closed', 'cozuldu')).toBe(true);
    expect(ticketMatchesTab('open', 'cozuldu')).toBe(false);
  });
});

describe('formatTicketNo', () => {
  it('id\'nin ilk 8 karakterini # ile büyük harfli döner', () => {
    expect(formatTicketNo('abcdef12-3456-7890-abcd-ef1234567890')).toBe('#ABCDEF12');
  });
});
```

- [ ] **Step 2: Testin başarısız olduğunu doğrula**

Run: `cd uygulamalar/web && pnpm vitest run test/lib/destek-yardimcilari.test.ts`
Expected: FAIL — modül bulunamadı hatası.

- [ ] **Step 3: Yardımcı modülü yaz**

`uygulamalar/web/app/sahip/destek/destek-yardimcilari.ts`:

```ts
export type TicketTab = 'tumu' | 'acik' | 'beklemede' | 'cozuldu';

export function ticketMatchesTab(status: string, tab: TicketTab): boolean {
  if (tab === 'tumu') return true;
  if (tab === 'acik') return status === 'open';
  if (tab === 'beklemede') return status === 'in_progress';
  return status === 'resolved' || status === 'closed';
}

export function formatTicketNo(id: string): string {
  return '#' + id.slice(0, 8).toUpperCase();
}

export const STATUS_MAP: Record<string, { label: string; color: string }> = {
  open: { label: 'Açık', color: 'bg-blue-50 text-blue-700' },
  in_progress: { label: 'İşlemde', color: 'bg-yellow-50 text-yellow-700' },
  resolved: { label: 'Çözüldü', color: 'bg-green-50 text-green-700' },
  closed: { label: 'Kapatıldı', color: 'bg-zinc-100 text-zinc-500' },
};

export const CATEGORY_OPTIONS = ['Fatura/Ödeme', 'Teknik Sorun', 'Özellik Talebi', 'Hesap/Erişim', 'Diğer'] as const;
export type DestekKategori = (typeof CATEGORY_OPTIONS)[number];

export const FAQ_ITEMS: Array<{ q: string; a: string }> = [
  {
    q: "İşletmemi Yeedoy'a nasıl ekletirim?",
    a: '"İşletmeni Ekle" sayfasından başvurunuzu yapabilirsiniz. Ekibimiz en kısa sürede inceleyip size geri dönecektir.',
  },
  {
    q: 'Menü ve fiyatlarımı nasıl yönetirim?',
    a: 'İşletme sahipliğinizi doğruladıktan sonra sahip panelinden menülerinizi, ürünlerinizi ve fiyatlarınızı kolayca güncelleyebilirsiniz.',
  },
  {
    q: 'Destek talebimin durumunu nereden takip ederim?',
    a: 'Bu sayfadaki "Destek Taleplerim" bölümünden tüm taleplerinizin durumunu ve yanıtlarını görebilirsiniz.',
  },
  {
    q: 'Destek talebime ne zaman yanıt alırım?',
    a: 'Destek ekibimiz Pazartesi–Cuma 09:00–18:00 saatleri arasında taleplerinizi yanıtlar. Yanıt geldiğinde e-posta ile bilgilendirilirsiniz.',
  },
  {
    q: 'Birden fazla işletmem varsa talebi hangisi için açtığımı nasıl belirtirim?',
    a: 'Yeni talep oluştururken açılan "İşletme" alanından ilgili işletmenizi seçebilirsiniz.',
  },
];

export const POPULER_KONULAR = [
  { title: 'İşletme Bilgileri', description: 'İşletme profilinizi düzenleyin.', href: '/sahip/isletmeler' },
  { title: 'Menü Yönetimi', description: 'Ürün ekleme, düzenleme ve fiyat güncelleme.', href: '/sahip/menuler' },
  { title: 'QR Menü & Kod', description: 'QR menü oluşturma ve baskı materyalleri.', href: '/sahip/karekod' },
  { title: 'İstatistikler', description: 'Görüntülenme, tıklama ve performans raporları.', href: '/sahip/analitik' },
  { title: 'Rezervasyonlar', description: 'Rezervasyon ayarları ve yönetimi.', href: '/sahip/rezervasyonlar' },
] as const;
```

- [ ] **Step 4: Testin geçtiğini doğrula**

Run: `cd uygulamalar/web && pnpm vitest run test/lib/destek-yardimcilari.test.ts`
Expected: PASS — 6 test.

- [ ] **Step 5: Commit**

```bash
git add uygulamalar/web/app/sahip/destek/destek-yardimcilari.ts uygulamalar/web/test/lib/destek-yardimcilari.test.ts
git commit -m "feat(web): destek sistemi — saf yardımcı fonksiyonlar (tab eşleme/etiketler/SSS/popüler konular) + testler"
```

---

### Task 2: Server actions

**Files:**
- Create: `uygulamalar/web/app/sahip/destek/destek-islemleri.ts`
- Test: `uygulamalar/web/test/lib/destek-islemleri.test.ts`

- [ ] **Step 1: Server action dosyasını yaz**

`uygulamalar/web/app/sahip/destek/destek-islemleri.ts`:

```ts
'use server';

import { revalidatePath } from 'next/cache';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { getOwnerBusinessIds } from '@/src/lib/veri/owner/sahip-isletmeleri';

export type DestekTicket = {
  id: string;
  subject: string;
  status: string;
  category: string;
  business_id: string | null;
  created_at: string;
  updated_at: string;
};

export type DestekMesaj = {
  id: string;
  sender: 'user' | 'agent';
  message: string;
  created_at: string;
};

async function requireUser() {
  const supabase = await createSupabaseServerClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) return { ok: false as const, error: 'Oturum bulunamadı' };
  return { ok: true as const, supabase, user };
}

export async function destekTalebiOlustur(
  businessId: string | null,
  category: string,
  subject: string,
  message: string,
): Promise<{ error: string } | { ticketId: string }> {
  const context = await requireUser();
  if (!context.ok) return { error: context.error };
  const { supabase, user } = context;

  if (businessId) {
    const ownerBusinessIds = await getOwnerBusinessIds(supabase, user.id);
    if (!ownerBusinessIds.includes(businessId)) {
      return { error: 'Bu işletme için yetkiniz yok' };
    }
  }

  const trimmedSubject = subject.trim();
  const trimmedMessage = message.trim();
  if (!trimmedSubject || !trimmedMessage) {
    return { error: 'Konu ve mesaj boş olamaz' };
  }

  const { data: profile } = (await (supabase as any)
    .from('user_profiles')
    .select('display_name')
    .eq('user_id', user.id)
    .maybeSingle()) as { data: { display_name: string | null } | null };

  const { data: ticket, error: ticketError } = (await (supabase as any)
    .from('support_tickets')
    .insert({
      user_id: user.id,
      business_id: businessId,
      requester_name: profile?.display_name ?? null,
      requester_email: user.email ?? null,
      subject: trimmedSubject,
      category,
    })
    .select('id')
    .single()) as { data: { id: string } | null; error: { message: string } | null };

  if (ticketError) return { error: ticketError.message };
  const ticketId = ticket?.id ?? '';

  const { error: messageError } = (await (supabase as any).from('support_ticket_messages').insert({
    ticket_id: ticketId,
    sender: 'user',
    message: trimmedMessage,
    created_by: user.id,
  })) as { error: { message: string } | null };

  if (messageError) return { error: messageError.message };

  revalidatePath('/sahip/destek');
  return { ticketId };
}

export async function destekTalebiListele(): Promise<{ error: string } | { tickets: DestekTicket[] }> {
  const context = await requireUser();
  if (!context.ok) return { error: context.error };
  const { supabase, user } = context;

  const { data, error } = (await (supabase as any)
    .from('support_tickets')
    .select('id, subject, status, category, business_id, created_at, updated_at')
    .eq('user_id', user.id)
    .order('updated_at', { ascending: false })) as {
    data: DestekTicket[] | null;
    error: { message: string } | null;
  };

  if (error) return { error: error.message };
  return { tickets: data ?? [] };
}

export async function destekTalebiDetay(
  ticketId: string,
): Promise<{ error: string } | { ticket: DestekTicket; messages: DestekMesaj[] }> {
  const context = await requireUser();
  if (!context.ok) return { error: context.error };
  const { supabase, user } = context;

  const { data: ticket, error: ticketError } = (await (supabase as any)
    .from('support_tickets')
    .select('id, subject, status, category, business_id, created_at, updated_at')
    .eq('id', ticketId)
    .eq('user_id', user.id)
    .maybeSingle()) as { data: DestekTicket | null; error: { message: string } | null };

  if (ticketError) return { error: ticketError.message };
  if (!ticket) return { error: 'Talep bulunamadı' };

  const { data: messages, error: messagesError } = (await (supabase as any)
    .from('support_ticket_messages')
    .select('id, sender, message, created_at')
    .eq('ticket_id', ticketId)
    .order('created_at', { ascending: true })) as {
    data: DestekMesaj[] | null;
    error: { message: string } | null;
  };

  if (messagesError) return { error: messagesError.message };
  return { ticket, messages: messages ?? [] };
}

export async function destekMesajGonder(ticketId: string, message: string): Promise<{ error: string } | null> {
  const context = await requireUser();
  if (!context.ok) return { error: context.error };
  const { supabase, user } = context;

  const trimmedMessage = message.trim();
  if (!trimmedMessage) return { error: 'Mesaj boş olamaz' };

  const { data: ticket, error: ticketError } = (await (supabase as any)
    .from('support_tickets')
    .select('id')
    .eq('id', ticketId)
    .eq('user_id', user.id)
    .maybeSingle()) as { data: { id: string } | null; error: { message: string } | null };

  if (ticketError) return { error: ticketError.message };
  if (!ticket) return { error: 'Talep bulunamadı' };

  const { error: messageError } = (await (supabase as any).from('support_ticket_messages').insert({
    ticket_id: ticketId,
    sender: 'user',
    message: trimmedMessage,
    created_by: user.id,
  })) as { error: { message: string } | null };

  if (messageError) return { error: messageError.message };

  // best-effort — mesaj zaten kaydedildi, updated_at güncellemesi kritik değil
  await (supabase as any).rpc('touch_support_ticket_v1', { p_ticket_id: ticketId });

  revalidatePath('/sahip/destek');
  return null;
}
```

- [ ] **Step 2: Test yaz**

`uygulamalar/web/test/lib/destek-islemleri.test.ts`:

```ts
import { describe, it, expect } from 'vitest';
import {
  destekTalebiOlustur,
  destekTalebiListele,
  destekTalebiDetay,
  destekMesajGonder,
} from '@/app/sahip/destek/destek-islemleri';

describe('destek server action\'ları', () => {
  it('fonksiyonlar export edilir', () => {
    expect(typeof destekTalebiOlustur).toBe('function');
    expect(typeof destekTalebiListele).toBe('function');
    expect(typeof destekTalebiDetay).toBe('function');
    expect(typeof destekMesajGonder).toBe('function');
  });
});
```

(Bu codebase'de server action'lar için genel konvansiyon budur — gerçek DB davranışı Task 12'deki manuel/dev-server doğrulamasında test edilir, bkz. `menu-islemleri.ts` için de ayrı bir DB-entegrasyon testi yok.)

- [ ] **Step 3: Typecheck + test çalıştır**

Run: `cd uygulamalar/web && pnpm run typecheck && pnpm vitest run test/lib/destek-islemleri.test.ts`
Expected: PASS.

- [ ] **Step 4: Commit**

```bash
git add uygulamalar/web/app/sahip/destek/destek-islemleri.ts uygulamalar/web/test/lib/destek-islemleri.test.ts
git commit -m "feat(web): destek sistemi — owner server action'ları (talep oluştur/listele/detay/mesaj gönder)"
```

---

### Task 3: Popüler Konular bileşeni

**Files:**
- Create: `uygulamalar/web/app/sahip/destek/bilesenler/populer-konular.tsx`

- [ ] **Step 1: Bileşeni yaz**

```tsx
import Link from 'next/link';
import { POPULER_KONULAR } from '../destek-yardimcilari';

export function PopulerKonular() {
  return (
    <div>
      <h2 className="mb-3 text-sm font-black text-textStrong">Popüler Konular</h2>
      <div className="grid grid-cols-2 gap-3 sm:grid-cols-3 lg:grid-cols-5">
        {POPULER_KONULAR.map((konu) => (
          <Link
            key={konu.href}
            href={konu.href}
            className="flex flex-col gap-2 rounded-2xl border border-border bg-card p-4 transition-colors hover:border-primary/30"
          >
            <p className="text-sm font-bold text-textStrong">{konu.title}</p>
            <p className="text-xs text-muted">{konu.description}</p>
          </Link>
        ))}
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
git add uygulamalar/web/app/sahip/destek/bilesenler/populer-konular.tsx
git commit -m "feat(web): destek sistemi — popüler konular bileşeni"
```

---

### Task 4: SSS widget bileşeni

**Files:**
- Create: `uygulamalar/web/app/sahip/destek/bilesenler/sss-widget.tsx`

- [ ] **Step 1: Bileşeni yaz**

```tsx
import { FAQ_ITEMS } from '../destek-yardimcilari';

export function SssWidget() {
  return (
    <div className="rounded-2xl border border-border bg-card p-4">
      <h3 className="mb-3 text-sm font-black text-textStrong">Sıkça Sorulan Sorular</h3>
      <div className="flex flex-col divide-y divide-border">
        {FAQ_ITEMS.map((item) => (
          <details key={item.q} className="group py-2.5 first:pt-0 last:pb-0">
            <summary className="flex cursor-pointer list-none items-center justify-between gap-2 text-xs font-bold text-textStrong [&::-webkit-details-marker]:hidden">
              <span>{item.q}</span>
              <span className="shrink-0 text-muted transition-transform group-open:rotate-180">⌄</span>
            </summary>
            <p className="mt-2 text-xs leading-relaxed text-muted">{item.a}</p>
          </details>
        ))}
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
git add uygulamalar/web/app/sahip/destek/bilesenler/sss-widget.tsx
git commit -m "feat(web): destek sistemi — SSS widget bileşeni"
```

---

### Task 5: Hızlı İletişim bileşeni

**Files:**
- Create: `uygulamalar/web/app/sahip/destek/bilesenler/hizli-iletisim.tsx`

- [ ] **Step 1: Bileşeni yaz**

```tsx
export function HizliIletisim() {
  return (
    <div className="rounded-2xl border border-border bg-card p-4">
      <h3 className="mb-1 text-sm font-black text-textStrong">Hızlı İletişim</h3>
      <p className="mb-3 text-xs text-muted">
        Pazartesi–Cuma 09:00–18:00 saatleri arasında size yardımcı olmaktan mutluluk duyarız.
      </p>
      <a
        href="mailto:destek@yeedoy.com"
        className="flex items-center justify-center gap-2 rounded-xl border border-border bg-bg px-3 py-2 text-xs font-bold text-textStrong hover:border-primary/30 hover:text-primary"
      >
        destek@yeedoy.com
      </a>
    </div>
  );
}
```

- [ ] **Step 2: Typecheck**

Run: `cd uygulamalar/web && pnpm run typecheck`
Expected: PASS.

- [ ] **Step 3: Commit**

```bash
git add uygulamalar/web/app/sahip/destek/bilesenler/hizli-iletisim.tsx
git commit -m "feat(web): destek sistemi — hızlı iletişim bileşeni"
```

---

### Task 6: Talep Listesi bileşeni

**Files:**
- Create: `uygulamalar/web/app/sahip/destek/bilesenler/talep-listesi.tsx`

- [ ] **Step 1: Bileşeni yaz**

```tsx
'use client';

import { useState } from 'react';
import type { DestekTicket } from '../destek-islemleri';
import { STATUS_MAP, ticketMatchesTab, formatTicketNo, type TicketTab } from '../destek-yardimcilari';

export function TalepListesi({
  tickets,
  onSelect,
  onYeniTalep,
}: {
  tickets: DestekTicket[];
  onSelect: (ticketId: string) => void;
  onYeniTalep: () => void;
}) {
  const [tab, setTab] = useState<TicketTab>('tumu');
  const visible = tickets.filter((t) => ticketMatchesTab(t.status, tab));

  const tabs: Array<{ id: TicketTab; label: string }> = [
    { id: 'tumu', label: `Tümü (${tickets.length})` },
    { id: 'acik', label: `Açık (${tickets.filter((t) => ticketMatchesTab(t.status, 'acik')).length})` },
    { id: 'beklemede', label: `Beklemede (${tickets.filter((t) => ticketMatchesTab(t.status, 'beklemede')).length})` },
    { id: 'cozuldu', label: `Çözüldü (${tickets.filter((t) => ticketMatchesTab(t.status, 'cozuldu')).length})` },
  ];

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
        <button
          type="button"
          onClick={onYeniTalep}
          className="rounded-xl bg-primary px-3 py-2 text-xs font-bold text-white cursor-pointer"
        >
          + Yeni Talep Oluştur
        </button>
      </div>

      {visible.length === 0 ? (
        <div className="flex flex-col items-center gap-2 py-12 text-center">
          <p className="text-sm font-bold text-textStrong">Bu sekmede talep yok</p>
        </div>
      ) : (
        <div className="overflow-x-auto">
          <table className="w-full min-w-[560px] text-sm">
            <thead>
              <tr className="border-b border-border text-left text-xs font-bold uppercase tracking-wide text-muted">
                <th className="px-4 py-2">Talep No</th>
                <th className="px-4 py-2">Konu</th>
                <th className="px-4 py-2">Durum</th>
                <th className="px-4 py-2">Son Güncelleme</th>
              </tr>
            </thead>
            <tbody>
              {visible.map((ticket) => (
                <tr
                  key={ticket.id}
                  onClick={() => onSelect(ticket.id)}
                  className="cursor-pointer border-b border-border last:border-0 hover:bg-bg/60"
                >
                  <td className="px-4 py-3 font-mono text-xs text-muted">{formatTicketNo(ticket.id)}</td>
                  <td className="px-4 py-3 font-bold text-textStrong">{ticket.subject}</td>
                  <td className="px-4 py-3">
                    <span
                      className={`rounded-full px-2 py-0.5 text-[11px] font-extrabold ${STATUS_MAP[ticket.status]?.color ?? ''}`}
                    >
                      {STATUS_MAP[ticket.status]?.label ?? ticket.status}
                    </span>
                  </td>
                  <td className="px-4 py-3 text-xs text-muted">
                    {new Date(ticket.updated_at).toLocaleDateString('tr-TR', {
                      day: '2-digit',
                      month: 'short',
                      year: 'numeric',
                    })}
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
Expected: PASS (bu bileşen henüz hiçbir yerden import edilmiyor, sadece kendi içinde derlenebilir olmalı).

- [ ] **Step 3: Commit**

```bash
git add uygulamalar/web/app/sahip/destek/bilesenler/talep-listesi.tsx
git commit -m "feat(web): destek sistemi — sekmeli talep listesi bileşeni"
```

---

### Task 7: Talep Detay bileşeni

**Files:**
- Create: `uygulamalar/web/app/sahip/destek/bilesenler/talep-detay.tsx`

- [ ] **Step 1: Bileşeni yaz**

```tsx
'use client';

import { useState, useTransition } from 'react';
import type { DestekTicket, DestekMesaj } from '../destek-islemleri';
import { destekMesajGonder } from '../destek-islemleri';
import { STATUS_MAP } from '../destek-yardimcilari';

export function TalepDetay({
  ticket,
  messages,
  onBack,
  onMessageSent,
}: {
  ticket: DestekTicket;
  messages: DestekMesaj[];
  onBack: () => void;
  onMessageSent: (message: DestekMesaj) => void;
}) {
  const [reply, setReply] = useState('');
  const [error, setError] = useState<string | null>(null);
  const [isPending, startTransition] = useTransition();

  function handleSend() {
    const trimmed = reply.trim();
    if (!trimmed) return;
    setError(null);
    startTransition(async () => {
      const result = await destekMesajGonder(ticket.id, trimmed);
      if (result?.error) {
        setError(result.error);
        return;
      }
      onMessageSent({
        id: `temp-${Date.now()}`,
        sender: 'user',
        message: trimmed,
        created_at: new Date().toISOString(),
      });
      setReply('');
    });
  }

  return (
    <div className="rounded-2xl border border-border bg-card">
      <div className="flex items-center gap-3 border-b border-border p-4">
        <button type="button" onClick={onBack} className="text-muted hover:text-textStrong cursor-pointer" aria-label="Geri">
          ←
        </button>
        <div className="min-w-0 flex-1">
          <p className="truncate font-bold text-textStrong">{ticket.subject}</p>
          <p className="text-xs text-muted">{ticket.category}</p>
        </div>
        <span className={`shrink-0 rounded-full px-2 py-0.5 text-[11px] font-extrabold ${STATUS_MAP[ticket.status]?.color ?? ''}`}>
          {STATUS_MAP[ticket.status]?.label ?? ticket.status}
        </span>
      </div>

      <div className="flex flex-col gap-3 p-4">
        {messages.length === 0 ? (
          <p className="text-xs text-muted">Henüz mesaj yok.</p>
        ) : (
          messages.map((msg) => (
            <div key={msg.id} className={`flex ${msg.sender === 'user' ? 'justify-end' : 'justify-start'}`}>
              <div
                className={`max-w-[75%] rounded-2xl px-3 py-2 text-sm ${
                  msg.sender === 'user' ? 'bg-primary text-white' : 'bg-bg text-textStrong'
                }`}
              >
                <p>{msg.message}</p>
                <p className={`mt-1 text-[10px] ${msg.sender === 'user' ? 'text-white/70' : 'text-muted'}`}>
                  {new Date(msg.created_at).toLocaleString('tr-TR')}
                </p>
              </div>
            </div>
          ))
        )}
      </div>

      {error && <p className="px-4 text-xs font-bold text-red-600">{error}</p>}

      <div className="flex gap-2 border-t border-border p-4">
        <textarea
          value={reply}
          onChange={(e) => setReply(e.target.value)}
          placeholder="Yanıtınızı yazın..."
          rows={2}
          className="flex-1 rounded-xl border border-border bg-bg px-3 py-2 text-sm text-textStrong placeholder:text-muted focus:outline-hidden focus:ring-2 focus:ring-primary/30"
        />
        <button
          type="button"
          onClick={handleSend}
          disabled={isPending || !reply.trim()}
          className="rounded-xl bg-primary px-4 py-2 text-xs font-bold text-white disabled:opacity-60 cursor-pointer"
        >
          {isPending ? 'Gönderiliyor...' : 'Gönder'}
        </button>
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
git add uygulamalar/web/app/sahip/destek/bilesenler/talep-detay.tsx
git commit -m "feat(web): destek sistemi — talep detay (mesaj akışı + yanıt) bileşeni"
```

---

### Task 8: Yeni Talep Formu bileşeni

**Files:**
- Create: `uygulamalar/web/app/sahip/destek/bilesenler/yeni-talep-formu.tsx`

- [ ] **Step 1: Bileşeni yaz**

```tsx
'use client';

import { useState, useTransition } from 'react';
import { destekTalebiOlustur } from '../destek-islemleri';
import { CATEGORY_OPTIONS } from '../destek-yardimcilari';

export function YeniTalepFormu({
  businesses,
  onSuccess,
  onCancel,
}: {
  businesses: Array<{ id: string; name: string }>;
  onSuccess: (ticketId: string) => void;
  onCancel: () => void;
}) {
  const [isPending, startTransition] = useTransition();
  const [error, setError] = useState<string | null>(null);

  function handleSubmit(e: React.FormEvent<HTMLFormElement>) {
    e.preventDefault();
    const fd = new FormData(e.currentTarget);
    const businessId = String(fd.get('businessId') ?? '') || null;
    const category = String(fd.get('category') ?? '');
    const subject = String(fd.get('subject') ?? '');
    const message = String(fd.get('message') ?? '');
    setError(null);
    startTransition(async () => {
      const result = await destekTalebiOlustur(businessId, category, subject, message);
      if ('error' in result) {
        setError(result.error);
        return;
      }
      onSuccess(result.ticketId);
    });
  }

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
      <div className="absolute inset-0 bg-black/30" onClick={onCancel} />
      <div className="relative z-10 w-full max-w-md rounded-2xl bg-card p-5 shadow-2xl">
        <h2 className="mb-4 text-sm font-black text-textStrong">Yeni Destek Talebi</h2>
        <form className="flex flex-col gap-3" onSubmit={handleSubmit}>
          {businesses.length > 1 && (
            <div className="flex flex-col gap-1">
              <label className="text-xs font-bold text-muted">İşletme</label>
              <select name="businessId" className="rounded-xl border border-border bg-bg px-3 py-2 text-sm text-textStrong">
                <option value="">Genel (işletmeye özel değil)</option>
                {businesses.map((b) => (
                  <option key={b.id} value={b.id}>
                    {b.name}
                  </option>
                ))}
              </select>
            </div>
          )}
          {businesses.length === 1 && <input type="hidden" name="businessId" value={businesses[0].id} />}

          <div className="flex flex-col gap-1">
            <label className="text-xs font-bold text-muted">Kategori</label>
            <select
              name="category"
              required
              defaultValue={CATEGORY_OPTIONS[0]}
              className="rounded-xl border border-border bg-bg px-3 py-2 text-sm text-textStrong"
            >
              {CATEGORY_OPTIONS.map((c) => (
                <option key={c} value={c}>
                  {c}
                </option>
              ))}
            </select>
          </div>

          <div className="flex flex-col gap-1">
            <label className="text-xs font-bold text-muted">Konu</label>
            <input
              name="subject"
              required
              maxLength={160}
              placeholder="Kısa bir başlık"
              className="rounded-xl border border-border bg-bg px-3 py-2 text-sm text-textStrong placeholder:text-muted"
            />
          </div>

          <div className="flex flex-col gap-1">
            <label className="text-xs font-bold text-muted">Mesaj</label>
            <textarea
              name="message"
              required
              maxLength={4000}
              rows={4}
              placeholder="Sorununuzu detaylı anlatın"
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
              {isPending ? 'Gönderiliyor...' : 'Talebi Gönder'}
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
git add uygulamalar/web/app/sahip/destek/bilesenler/yeni-talep-formu.tsx
git commit -m "feat(web): destek sistemi — yeni talep formu (modal) bileşeni"
```

---

### Task 9: Orkestratör + sayfa

**Files:**
- Create: `uygulamalar/web/app/sahip/destek/destek-istemci.tsx`
- Create: `uygulamalar/web/app/sahip/destek/page.tsx`

- [ ] **Step 1: Orkestratörü yaz**

`uygulamalar/web/app/sahip/destek/destek-istemci.tsx`:

```tsx
'use client';

import { useState } from 'react';
import type { DestekTicket, DestekMesaj } from './destek-islemleri';
import { destekTalebiDetay } from './destek-islemleri';
import { PopulerKonular } from './bilesenler/populer-konular';
import { SssWidget } from './bilesenler/sss-widget';
import { HizliIletisim } from './bilesenler/hizli-iletisim';
import { TalepListesi } from './bilesenler/talep-listesi';
import { TalepDetay } from './bilesenler/talep-detay';
import { YeniTalepFormu } from './bilesenler/yeni-talep-formu';

export function DestekIstemci({
  initialTickets,
  businesses,
}: {
  initialTickets: DestekTicket[];
  businesses: Array<{ id: string; name: string }>;
}) {
  const tickets = initialTickets;
  const [selected, setSelected] = useState<{ ticket: DestekTicket; messages: DestekMesaj[] } | null>(null);
  const [showForm, setShowForm] = useState(false);
  const [loadError, setLoadError] = useState<string | null>(null);

  async function openTicket(ticketId: string) {
    setLoadError(null);
    const result = await destekTalebiDetay(ticketId);
    if ('error' in result) {
      setLoadError(result.error);
      return;
    }
    setSelected(result);
  }

  function handleNewTicketSuccess(ticketId: string) {
    setShowForm(false);
    void openTicket(ticketId);
  }

  function handleMessageSent(message: DestekMesaj) {
    if (!selected) return;
    setSelected({ ...selected, messages: [...selected.messages, message] });
  }

  return (
    <div className="flex flex-col gap-6 lg:flex-row lg:items-start">
      <div className="flex min-w-0 flex-1 flex-col gap-6">
        <PopulerKonular />

        {loadError && <p className="text-xs font-bold text-red-600">{loadError}</p>}

        {selected ? (
          <TalepDetay
            ticket={selected.ticket}
            messages={selected.messages}
            onBack={() => setSelected(null)}
            onMessageSent={handleMessageSent}
          />
        ) : (
          <TalepListesi tickets={tickets} onSelect={openTicket} onYeniTalep={() => setShowForm(true)} />
        )}
      </div>

      <div className="flex w-full flex-col gap-4 lg:w-80 lg:shrink-0">
        <SssWidget />
        <HizliIletisim />
      </div>

      {showForm && (
        <YeniTalepFormu businesses={businesses} onSuccess={handleNewTicketSuccess} onCancel={() => setShowForm(false)} />
      )}
    </div>
  );
}
```

- [ ] **Step 2: Sayfayı yaz**

`uygulamalar/web/app/sahip/destek/page.tsx`:

```tsx
import type { Metadata } from 'next';
import { redirect } from 'next/navigation';
import { createSupabaseServerClient } from '@/src/lib/taban-sunucu';
import { getOwnerBusinessIds } from '@/src/lib/veri/owner/sahip-isletmeleri';
import { PanelSayfaBasligi } from '@/src/ui/yerlesim/panel-page-header';
import { PanelIcerikYuzeyi } from '@/src/ui/yerlesim/panel-section-card';
import { DestekIstemci } from './destek-istemci';
import type { DestekTicket } from './destek-islemleri';

export const metadata: Metadata = {
  title: 'Destek | Sahip Paneli',
  robots: { index: false, follow: false },
};

export default async function DestekSayfasi() {
  const supabase = await createSupabaseServerClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) redirect('/giris?redirect=%2Fsahip%2Fdestek');

  const businessIds = await getOwnerBusinessIds(supabase, user.id);
  const { data: businessRows } =
    businessIds.length > 0
      ? await (supabase as any).from('businesses').select('id, name').in('id', businessIds)
      : { data: [] };
  const businesses = (businessRows ?? []) as Array<{ id: string; name: string }>;

  const { data: ticketRows } = await (supabase as any)
    .from('support_tickets')
    .select('id, subject, status, category, business_id, created_at, updated_at')
    .eq('user_id', user.id)
    .order('updated_at', { ascending: false });
  const tickets = (ticketRows ?? []) as DestekTicket[];

  return (
    <div className="flex flex-col">
      <PanelSayfaBasligi
        eyebrow="Destek"
        title="Yeedoy Destek"
        description="Sorularınız için buradayız! Size nasıl yardımcı olabiliriz?"
      />
      <PanelIcerikYuzeyi className="pt-6">
        <DestekIstemci initialTickets={tickets} businesses={businesses} />
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
git add uygulamalar/web/app/sahip/destek/destek-istemci.tsx uygulamalar/web/app/sahip/destek/page.tsx
git commit -m "feat(web): destek sistemi — orkestratör + /sahip/destek sayfası"
```

---

### Task 10: Sidebar navigasyon

**Files:**
- Modify: `uygulamalar/web/src/ui/kabuk/sahip-kabuk-istemcisi.tsx`

- [ ] **Step 1: Nav öğesini ekle**

`uygulamalar/web/src/ui/kabuk/sahip-kabuk-istemcisi.tsx` içinde `'Yönetim'` bölümündeki `items` dizisinde, `/sahip/ayarlar` satırından hemen önce ekle:

```tsx
      { href: '/sahip/destek', label: 'Destek', icon: <HeadsetIcon /> },
      { href: '/sahip/ayarlar', label: 'Ayarlar', icon: <SettingsIcon /> },
```

- [ ] **Step 2: İkon fonksiyonunu ekle**

Dosyanın sonunda, `function SettingsIcon()` fonksiyonunun hemen üstüne veya altına ekle:

```tsx
function HeadsetIcon() {
  return (
    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <path d="M3 18v-6a9 9 0 0 1 18 0v6" />
      <path d="M21 19a2 2 0 0 1-2 2h-1a2 2 0 0 1-2-2v-3a2 2 0 0 1 2-2h3zM3 19a2 2 0 0 0 2 2h1a2 2 0 0 0 2-2v-3a2 2 0 0 0-2-2H3z" />
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
git commit -m "feat(web): destek sistemi — sahip panel sidebar'a Destek nav öğesi ekle"
```

---

### Task 11: Admin yanıt route'una e-posta bildirimi

**Files:**
- Modify: `uygulamalar/web/app/sunucu/yonetici/musteri-destek/route.ts`

- [ ] **Step 1: Importları ekle**

Dosyanın en üstüne ekle:

```ts
import { sendEmail } from '@/src/lib/eposta';
import { appConfig } from '@/src/lib/ayarlar';
```

- [ ] **Step 2: POST handler'ının sonuna e-posta gönderimi ekle**

Mevcut (dosyanın sonu):

```ts
  if (error) return NextResponse.json({ error: 'internal_error' }, { status: 500 });
  await supabaseAny
    .from('support_tickets')
    .update({ status: 'in_progress', updated_at: new Date().toISOString(), assigned_to: user?.id })
    .eq('id', ticketId);

  return NextResponse.json({ ok: true });
}
```

şununla değiştir:

```ts
  if (error) return NextResponse.json({ error: 'internal_error' }, { status: 500 });
  await supabaseAny
    .from('support_tickets')
    .update({ status: 'in_progress', updated_at: new Date().toISOString(), assigned_to: user?.id })
    .eq('id', ticketId);

  // best-effort — e-posta gönderimi başarısız olsa da yanıt akışını engellemez
  const { data: ticketRow } = await supabaseAny
    .from('support_tickets')
    .select('subject, requester_email')
    .eq('id', ticketId)
    .maybeSingle();
  if (ticketRow?.requester_email) {
    await sendEmail({
      to: ticketRow.requester_email,
      subject: `Destek talebinize yanıt geldi: ${ticketRow.subject}`,
      html: `<p>Merhaba,</p><p>"${ticketRow.subject}" konulu destek talebinize yeni bir yanıt geldi.</p><p><a href="${appConfig.siteUrl()}/sahip/destek">Talebi görüntülemek için tıklayın</a>.</p>`,
    });
  }

  return NextResponse.json({ ok: true });
}
```

- [ ] **Step 3: Typecheck + lint**

Run: `cd uygulamalar/web && pnpm run typecheck && pnpm run lint`
Expected: İkisi de hatasız biter.

- [ ] **Step 4: Commit**

```bash
git add uygulamalar/web/app/sunucu/yonetici/musteri-destek/route.ts
git commit -m "feat(web): destek sistemi — admin yanıtında owner'a e-posta bildirimi gönder"
```

---

### Task 12: Son doğrulama

**Files:** Yok (sadece doğrulama)

- [ ] **Step 1: Tam doğrulama paketini çalıştır**

Run: `cd uygulamalar/web && pnpm run test:ci`
Expected: typecheck + lint + unit + build hepsi başarılı.

- [ ] **Step 2: Supabase migration zincirinin baştan sona temiz kurulduğunu doğrula**

Run: `supabase db reset`
Expected: Hatasız biter, `20260806000001_destek_sistemi_owner` migration'ı sırayla uygulanır.

- [ ] **Step 3: RLS çapraz erişim testi**

Local Supabase'de iki farklı test kullanıcısıyla (`psql` + `set_config('request.jwt.claims', ...)` deseni, bu oturumda daha önce kullanıldı):
1. Kullanıcı A bir destek talebi oluşturur (`support_tickets` INSERT + `support_ticket_messages` INSERT, `sender='user'`).
2. Kullanıcı A kendi talebini SELECT ile görebiliyor mu — evet olmalı.
3. Kullanıcı B (farklı `auth.uid()`) aynı talebi SELECT ile görmeye çalışır — RLS nedeniyle 0 satır dönmeli.
4. Kullanıcı B, Kullanıcı A'nın talebine mesaj eklemeye çalışır (`support_ticket_messages` INSERT, `ticket_id` = A'nın talebi) — RLS `WITH CHECK` nedeniyle reddedilmeli.

- [ ] **Step 4: Dev server ile uçtan uca manuel senaryo**

`pnpm run dev` başlat (ve gerekiyorsa `supabase start`), bir owner hesabıyla:
1. `/sahip/destek` sayfasını aç — Popüler Konular, SSS, Hızlı İletişim görünüyor mu.
2. "Yeni Talep Oluştur" ile bir talep aç.
3. `/yonetici/musteri-destek`'te (admin hesabıyla) bu talebin göründüğünü doğrula.
4. Admin yanıt verir — owner panelinde talebin durumu "İşlemde"ye geçiyor mu, mesaj görünüyor mu.
5. (RESEND_API_KEY tanımlıysa) e-posta bildirimi gitti mi kontrol et; tanımlı değilse `logger.warn` ile "e-posta gönderilmedi" logunun best-effort olarak akışı engellemediğini doğrula.

Ortam bu testi desteklemiyorsa (`.env.local` production'a bağlıysa, `RESEND_API_KEY` yoksa vb.), bunu raporda açıkça belirt.

- [ ] **Step 5: Nihai commit (gerekirse temizlik)**

Doğrulama sırasında küçük düzeltmeler gerekirse, ayrı commit'ler halinde yap.

---

## Kapsam Dışı (bu planda yok)

- Canlı chat/WebSocket, telefon/WhatsApp iletişim satırı, "Yardım Kaynakları" (video/kılavuz/duyuru)
- SLA takibi, otomatik önceliklendirme, üçüncü parti helpdesk entegrasyonu
- Admin panelinin (`app/yonetici/musteri-destek/`) yeniden tasarımı
