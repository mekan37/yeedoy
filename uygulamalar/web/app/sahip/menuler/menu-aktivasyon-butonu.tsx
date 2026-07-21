'use client';

import { useState, useTransition } from 'react';
import { activateMenu } from './menu-islemleri';

type Props = {
  menuId: string;
  businessId: string;
  isActive: boolean;
};

export function MenuAktivasyonButonu({ menuId, businessId, isActive }: Props) {
  const [isPending, startTransition] = useTransition();
  const [error, setError] = useState<string | null>(null);

  if (isActive) {
    return (
      <div className="flex items-center gap-1.5 rounded-xl bg-green-50 px-3 py-2 text-[12px] font-[800] text-green-700">
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
      if (result?.error) {
        setError(result.error);
      }
    });
  }

  return (
    <div className="flex flex-col gap-1">
      <button
        type="button"
        onClick={handleActivate}
        disabled={isPending}
        className="flex items-center justify-center gap-1.5 rounded-xl border-2 border-dashed border-[#dc2626]/40 bg-[#fef2f2] px-3 py-2 text-[12px] font-[800] text-[#dc2626] transition hover:border-[#dc2626] hover:bg-[#fef2f2] disabled:opacity-60"
      >
        {isPending ? (
          <>
            <svg className="animate-spin" width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5">
              <path d="M21 12a9 9 0 1 1-6.219-8.56" />
            </svg>
            Aktif yapılıyor…
          </>
        ) : (
          <>
            <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round">
              <circle cx="12" cy="12" r="10" />
              <polygon points="10 8 16 12 10 16 10 8" fill="currentColor" />
            </svg>
            Aktif Yap
          </>
        )}
      </button>
      {error && (
        <p className="text-center text-[11px] font-[600] text-[#dc2626]">{error}</p>
      )}
    </div>
  );
}
