'use client';

import { useState, useTransition } from 'react';
import { activateMenu } from './menu-islemleri';

type Props = {
  menuId: string;
  businessId: string;
};

// Menü listesinden atomik yayına alma: aynı işletmenin önceden yayınlanmış
// diğer menüleri otomatik taslağa çekilir (bkz. menu-islemleri.ts activateMenu).
export function ActivateMenuButton({ menuId, businessId }: Props) {
  const [isPending, startTransition] = useTransition();
  const [error, setError] = useState<string | null>(null);

  function handleActivate() {
    setError(null);
    startTransition(async () => {
      const result = await activateMenu(menuId, businessId);
      if (result?.error) setError(result.error);
    });
  }

  return (
    <div className="flex flex-col items-end gap-1">
      <button
        type="button"
        onClick={handleActivate}
        disabled={isPending}
        className="shrink-0 whitespace-nowrap rounded-full border border-dashed border-primary/40 bg-primary/5 px-2.5 py-1 text-[11px] font-[800] text-primary transition hover:border-primary hover:bg-primary/10 disabled:cursor-not-allowed disabled:opacity-60"
      >
        {isPending ? 'Aktifleştiriliyor…' : 'Aktif Yap'}
      </button>
      {error && (
        <p className="max-w-[160px] text-right text-[10px] font-[700] text-red-600">{error}</p>
      )}
    </div>
  );
}
