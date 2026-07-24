'use client';

import { useTransition } from 'react';
import { adminMenuGeriAl } from './admin-geri-al-islemleri';

export function AdminMenuGeriAlDugmesi({ menuId }: { menuId: string }) {
  const [isPending, startTransition] = useTransition();

  return (
    <button
      disabled={isPending}
      onClick={() => startTransition(async () => { await adminMenuGeriAl(menuId); })}
      className="rounded-lg border border-border px-3 py-1 text-xs font-bold text-textStrong transition-colors hover:bg-black/4 disabled:cursor-not-allowed disabled:opacity-50"
    >
      {isPending ? '…' : 'Geri Al'}
    </button>
  );
}
