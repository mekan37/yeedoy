'use client';

import { useState, useTransition } from 'react';
import { useRouter } from 'next/navigation';
import { createSupabaseBrowserClient } from '@/src/lib/taban/istemci';
import { toast } from '@/src/lib/toast-deposu';

export function OturumKapatButonu() {
  const router = useRouter();
  const [pending, startTransition] = useTransition();
  const [confirmAll, setConfirmAll] = useState(false);

  function signOut(scope: 'local' | 'global') {
    startTransition(async () => {
      const supabase = createSupabaseBrowserClient();
      await supabase.auth.signOut({ scope });
      toast(
        scope === 'global' ? 'Tüm cihazlardan çıkış yapıldı' : 'Oturum kapatıldı',
        'success',
      );
      router.push('/giris');
    });
  }

  return (
    <div className="flex flex-col gap-2">
      <button
        type="button"
        onClick={() => signOut('local')}
        disabled={pending}
        className="inline-flex min-h-[40px] items-center rounded-xl border border-border bg-bg px-4 text-sm font-[700] text-muted hover:border-danger/30 hover:text-danger disabled:opacity-60"
      >
        {pending ? 'İşleniyor…' : 'Bu Cihazda Oturumu Kapat'}
      </button>

      {!confirmAll ? (
        <button
          type="button"
          onClick={() => setConfirmAll(true)}
          disabled={pending}
          className="inline-flex min-h-[40px] items-center rounded-xl border border-danger/30 bg-danger/[0.06] px-4 text-sm font-[700] text-danger hover:bg-danger/[0.12] disabled:opacity-60"
        >
          Tüm Cihazlarda Oturumu Kapat
        </button>
      ) : (
        <div className="rounded-xl border border-danger/30 bg-danger/[0.06] p-4">
          <p className="mb-3 text-sm font-[800] text-danger">
            Tüm cihazlarda ve tarayıcılarda oturumunuz kapatılacak. Devam etmek istiyor musunuz?
          </p>
          <div className="flex gap-2">
            <button
              type="button"
              onClick={() => signOut('global')}
              disabled={pending}
              className="rounded-xl bg-danger px-4 py-2 text-sm font-[800] text-white hover:brightness-95 disabled:opacity-60"
            >
              {pending ? 'İşleniyor…' : 'Evet, Tüm Cihazlarda Kapat'}
            </button>
            <button
              type="button"
              onClick={() => setConfirmAll(false)}
              className="rounded-xl border border-border bg-card px-4 py-2 text-sm font-[700] text-textStrong"
            >
              Vazgeç
            </button>
          </div>
        </div>
      )}
    </div>
  );
}
