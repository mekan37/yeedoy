'use client';

import { useState, useTransition } from 'react';
import { useRouter } from 'next/navigation';
import { createSupabaseBrowserClient } from '@/src/lib/taban/istemci';

export function ZincirOnayButonu({ chainId, isVerified, className }: { chainId: string; isVerified: boolean; className?: string }) {
  const router = useRouter();
  const [pending, startTransition] = useTransition();
  const [error, setError] = useState<string | null>(null);

  function toggle() {
    setError(null);
    startTransition(async () => {
      const supabase = createSupabaseBrowserClient();
      const { error: rpcError } = await (supabase as any).rpc('admin_update_chain_v1', {
        p_chain_id: chainId,
        p_is_verified: !isVerified,
      });
      if (rpcError) {
        setError('İşlem başarısız oldu.');
        return;
      }
      router.refresh();
    });
  }

  return (
    <div className="inline-flex flex-col items-start gap-1">
      <button
        type="button"
        onClick={toggle}
        disabled={pending}
        className={className ?? `rounded-lg border px-2.5 py-1.5 text-xs font-extrabold transition-colors disabled:opacity-50 ${
          isVerified ? 'border-border text-muted hover:border-red-300 hover:text-red-600' : 'border-border text-muted hover:border-blue-300 hover:text-blue-700'
        }`}
      >
        {pending ? '...' : isVerified ? 'Onayı Kaldır' : 'Zinciri Onayla'}
      </button>
      {error && <span className="text-[10px] font-bold text-red-600">{error}</span>}
    </div>
  );
}
