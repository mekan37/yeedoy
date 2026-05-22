'use client';

import { createSupabaseBrowserClient } from '@/src/lib/taban/istemci';

import { useState, useTransition } from 'react';

async function markPerkUsed(perkId: string) {
  const supabase = createSupabaseBrowserClient();
  await (supabase as any).from('user_perks').update({ is_used: true }).eq('id', perkId);
}

export function AvantajKullanButonu({ perkId, disabled }: { perkId: string; disabled?: boolean }) {
  const [used, setUsed] = useState(false);
  const [confirm, setConfirm] = useState(false);
  const [pending, startTransition] = useTransition();

  if (disabled || used) {
    return <span className="rounded-full bg-border px-3 py-1 text-[11px] font-[700] text-muted">Kullanıldı</span>;
  }

  if (confirm) {
    return (
      <div className="flex items-center gap-2">
        <button
          type="button"
          onClick={() => {
            startTransition(async () => {
              await markPerkUsed(perkId);
              setUsed(true);
              setConfirm(false);
            });
          }}
          disabled={pending}
          className="rounded-xl bg-primary px-3 py-1.5 text-[11px] font-[900] text-white disabled:opacity-60"
        >
          {pending ? '…' : 'Onayla'}
        </button>
        <button
          type="button"
          onClick={() => setConfirm(false)}
          className="rounded-xl border border-border px-3 py-1.5 text-[11px] font-[700] text-muted"
        >
          İptal
        </button>
      </div>
    );
  }

  return (
    <button
      type="button"
      onClick={() => setConfirm(true)}
      className="rounded-xl border border-primary/30 bg-[var(--yd-color-primary-soft)] px-3 py-1.5 text-[11px] font-[900] text-primary hover:bg-primary/15"
    >
      Kullan
    </button>
  );
}
