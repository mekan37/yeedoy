'use client';

import { createSupabaseBrowserClient } from '@/src/lib/taban/istemci';

import { useState, useTransition } from 'react';
import { useRouter } from 'next/navigation';

export function AlarmToggle({ alertId, isActive }: { alertId: string; isActive: boolean }) {
  const router = useRouter();
  const [active, setActive] = useState(isActive);
  const [pending, startTransition] = useTransition();

  function toggle() {
    const next = !active;
    setActive(next);
    startTransition(async () => {
      await (createSupabaseBrowserClient() as any).from('price_alerts').update({ is_active: next }).eq('id', alertId);
      router.refresh();
    });
  }

  return (
    <button
      type="button"
      onClick={toggle}
      disabled={pending}
      className={`relative h-6 w-11 shrink-0 rounded-full transition-colors duration-200 disabled:opacity-60 ${active ? 'bg-primary' : 'bg-border'}`}
      aria-checked={active}
      role="switch"
    >
      <span className={`absolute top-0.5 h-5 w-5 rounded-full bg-white shadow transition-transform duration-200 ${active ? 'translate-x-5' : 'translate-x-0.5'}`} />
    </button>
  );
}

export function AlarmSilButonu({ alertId }: { alertId: string }) {
  const router = useRouter();
  const [pending, startTransition] = useTransition();
  const [confirm, setConfirm] = useState(false);

  if (confirm) {
    return (
      <div className="flex items-center gap-1.5">
        <button
          type="button"
          disabled={pending}
          onClick={() => {
            startTransition(async () => {
              await createSupabaseBrowserClient().from('price_alerts' as any).delete().eq('id', alertId);
              router.refresh();
            });
          }}
          className="rounded-lg bg-danger px-2.5 py-1 text-[11px] font-[900] text-white disabled:opacity-60"
        >
          {pending ? '…' : 'Sil'}
        </button>
        <button type="button" onClick={() => setConfirm(false)} className="text-[11px] text-muted hover:text-primary">İptal</button>
      </div>
    );
  }

  return (
    <button
      type="button"
      onClick={() => setConfirm(true)}
      className="rounded-lg border border-border px-2.5 py-1 text-[11px] font-[700] text-muted hover:border-danger/40 hover:text-danger"
    >
      Sil
    </button>
  );
}
