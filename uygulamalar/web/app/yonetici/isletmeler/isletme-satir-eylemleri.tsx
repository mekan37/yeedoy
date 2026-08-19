'use client';

import { useState, useTransition } from 'react';
import { useRouter } from 'next/navigation';
import Link from 'next/link';

export function IsletmeSatirEylemleri({
  id,
  isActive,
  publicHref,
}: {
  id: string;
  isActive: boolean;
  publicHref: string | null;
}) {
  const router = useRouter();
  const [pending, startTransition] = useTransition();
  const [error, setError] = useState<string | null>(null);

  function toggleAktif() {
    setError(null);
    startTransition(async () => {
      try {
        const res = await fetch('/sunucu/yonetici/toplu-islemler', {
          method: 'PATCH',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ type: 'businesses', ids: [id], action: isActive ? 'reject' : 'approve' }),
        });
        if (!res.ok) {
          setError('İşlem başarısız oldu.');
          return;
        }
        router.refresh();
      } catch {
        setError('İşlem başarısız oldu.');
      }
    });
  }

  return (
    <div className="flex items-center justify-end gap-1.5">
      {error && <span className="text-[10px] font-bold text-red-600">{error}</span>}
      {publicHref && (
        <Link
          href={publicHref}
          target="_blank"
          rel="noreferrer"
          title="Genel sayfada gör"
          className="flex h-8 w-8 items-center justify-center rounded-lg border border-border text-muted transition-colors hover:border-primary/30 hover:text-primary"
        >
          <EyeIcon />
        </Link>
      )}
      <button
        type="button"
        onClick={toggleAktif}
        disabled={pending}
        title={isActive ? 'Pasife al' : 'Aktif et'}
        className={`flex h-8 w-8 items-center justify-center rounded-lg border transition-colors disabled:opacity-50 ${
          isActive
            ? 'border-border text-muted hover:border-red-300 hover:text-red-600'
            : 'border-border text-muted hover:border-emerald-300 hover:text-emerald-600'
        }`}
      >
        {isActive ? <PauseIcon /> : <PlayIcon />}
      </button>
    </div>
  );
}

function EyeIcon() {
  return (
    <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z" /><circle cx="12" cy="12" r="3" />
    </svg>
  );
}
function PauseIcon() {
  return (
    <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <rect x="6" y="4" width="4" height="16" /><rect x="14" y="4" width="4" height="16" />
    </svg>
  );
}
function PlayIcon() {
  return (
    <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <polygon points="5 3 19 12 5 21 5 3" />
    </svg>
  );
}
