'use client';

import { createSupabaseBrowserClient } from '@/src/lib/taban/istemci';

import { useState, useTransition } from 'react';
import { useRouter } from 'next/navigation';

export function TakipteCikButonu({ followedId }: { followedId: string }) {
  const router = useRouter();
  const [confirm, setConfirm] = useState(false);
  const [pending, startTransition] = useTransition();

  if (confirm) {
    return (
      <div className="flex items-center gap-1.5">
        <button
          type="button"
          disabled={pending}
          onClick={() => {
            startTransition(async () => {
              const supabase = createSupabaseBrowserClient();
              const { data: { user } } = await supabase.auth.getUser();
              if (user) {
                await (supabase as any).from('user_follows').delete()
                  .eq('follower_id', user.id)
                  .eq('followed_id', followedId);
              }
              router.refresh();
            });
          }}
          className="rounded-xl bg-danger px-3 py-1.5 text-[11px] font-[900] text-white disabled:opacity-60"
        >
          {pending ? '…' : 'Takibi Bırak'}
        </button>
        <button type="button" onClick={() => setConfirm(false)} className="text-[11px] text-muted hover:text-primary">İptal</button>
      </div>
    );
  }

  return (
    <button
      type="button"
      onClick={() => setConfirm(true)}
      className="rounded-xl border border-border px-3 py-1.5 text-[11px] font-[700] text-muted hover:border-danger/30 hover:text-danger"
    >
      Takipten Çık
    </button>
  );
}
