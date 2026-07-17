'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';

type Props = {
  menuId: string;
  businessId: string;
  isActive: boolean;
};

export function ActivateMenuButton({ menuId, businessId, isActive }: Props) {
  const router = useRouter();
  const [pending, setPending] = useState(false);
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

  async function handleActivate() {
    setPending(true);
    setError(null);
    try {
      const res = await fetch(`/api/owner/menus/${menuId}/activate`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ business_id: businessId }),
      });
      if (!res.ok) {
        const body = await res.json().catch(() => ({})) as { error?: string };
        setError(body.error ?? 'Hata oluştu');
        return;
      }
      router.refresh();
    } catch {
      setError('Bağlantı hatası');
    } finally {
      setPending(false);
    }
  }

  return (
    <div className="flex flex-col gap-1">
      <button
        type="button"
        onClick={handleActivate}
        disabled={pending}
        className="flex items-center justify-center gap-1.5 rounded-xl border-2 border-dashed border-[#dc2626]/40 bg-[#fef2f2] px-3 py-2 text-[12px] font-[800] text-[#dc2626] transition hover:border-[#dc2626] hover:bg-[#fef2f2] disabled:opacity-60"
      >
        {pending ? (
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
