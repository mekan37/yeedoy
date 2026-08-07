'use client';

import { useState, useTransition } from 'react';
import { zincirOlustur } from '../coklu-sube-islemleri';

export function ZincirOlusturFormu({ businessId, onSuccess }: { businessId: string; onSuccess: () => void }) {
  const [chainName, setChainName] = useState('');
  const [error, setError] = useState<string | null>(null);
  const [isPending, startTransition] = useTransition();

  function handleSubmit(e: React.FormEvent<HTMLFormElement>) {
    e.preventDefault();
    const trimmed = chainName.trim();
    if (!trimmed) {
      setError('Zincir adı boş olamaz');
      return;
    }
    setError(null);
    startTransition(async () => {
      const result = await zincirOlustur(businessId, trimmed);
      if ('error' in result) {
        setError(result.error);
        return;
      }
      onSuccess();
    });
  }

  return (
    <div className="flex flex-col items-center gap-4 rounded-2xl border border-dashed border-border bg-card p-10 text-center">
      <p className="text-lg font-black text-textStrong">Henüz bir zinciriniz yok</p>
      <p className="max-w-sm text-sm text-muted">
        Birden fazla şubeniz varsa, bir zincir oluşturup işletmelerinizi tek panelden yönetebilirsiniz.
      </p>
      <form onSubmit={handleSubmit} className="flex w-full max-w-sm flex-col gap-2">
        <input
          value={chainName}
          onChange={(e) => setChainName(e.target.value)}
          placeholder="Zincir adı (örn. No 18 Coffee Co.)"
          className="rounded-xl border border-border bg-bg px-3 py-2 text-sm text-textStrong placeholder:text-muted focus:outline-hidden focus:ring-2 focus:ring-primary/30"
        />
        {error && <p className="text-xs font-bold text-red-600">{error}</p>}
        <button
          type="submit"
          disabled={isPending}
          className="rounded-xl bg-primary px-3 py-2 text-sm font-bold text-white disabled:opacity-60 cursor-pointer"
        >
          {isPending ? 'Oluşturuluyor...' : 'Zincir Oluştur'}
        </button>
      </form>
    </div>
  );
}
