'use client';

import { useState, useTransition } from 'react';
import { activateMenu } from './menu-islemleri';

type Props = {
  menuId: string;
  businessId: string;
  isActive: boolean;
};

// Menü listesinden atomik yayına alma: aynı işletmenin önceden yayınlanmış
// diğer menüleri otomatik taslağa çekilir (bkz. menu-islemleri.ts activateMenu).
export function ActivateMenuButton({ menuId, businessId, isActive }: Props) {
  const [isPending, startTransition] = useTransition();
  const [error, setError] = useState<string | null>(null);

  if (isActive) {
    return (
      <div className="flex items-center gap-1.5 rounded-xl bg-green-50 px-3 py-2 text-xs font-[800] text-green-700">
        <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round">
          <polyline points="20 6 9 17 4 12" />
        </svg>
        Aktif Menü
      </div>
    );
  }

  function handleActivate() {
    setError(null);
    startTransition(async () => {
      const result = await activateMenu(menuId, businessId);
      if (result?.error) setError(result.error);
    });
  }

  return (
    <div className="flex flex-col gap-1">
      <button
        type="button"
        onClick={handleActivate}
        disabled={isPending}
        className="flex items-center justify-center gap-1.5 rounded-xl border-2 border-dashed border-primary/40 bg-primary/5 px-3 py-2 text-xs font-[800] text-primary transition hover:border-primary disabled:cursor-not-allowed disabled:opacity-60"
      >
        {isPending ? 'Aktifleştiriliyor…' : 'Aktif Yap'}
      </button>
      {error && (
        <p className="text-center text-[11px] font-[600] text-danger">{error}</p>
      )}
    </div>
  );
}
