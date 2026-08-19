'use client';

import { useState, useTransition } from 'react';
import { useRouter } from 'next/navigation';

export function KullaniciBanButonu({ userId, banned }: { userId: string; banned: boolean }) {
  const router = useRouter();
  const [pending, startTransition] = useTransition();
  const [error, setError] = useState<string | null>(null);

  function toggle() {
    setError(null);
    startTransition(async () => {
      try {
        const res = await fetch('/sunucu/yonetici/toplu-islemler', {
          method: 'PATCH',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ type: 'users', ids: [userId], action: banned ? 'clear' : 'ban' }),
        });
        if (!res.ok) { setError('İşlem başarısız.'); return; }
        router.refresh();
      } catch {
        setError('İşlem başarısız.');
      }
    });
  }

  return (
    <button
      type="button"
      onClick={toggle}
      disabled={pending}
      title={banned ? 'Engeli kaldır' : 'Kullanıcıyı engelle'}
      className={`flex h-8 w-8 items-center justify-center rounded-lg border transition-colors disabled:opacity-50 ${
        banned ? 'border-border text-muted hover:border-emerald-300 hover:text-emerald-600' : 'border-border text-muted hover:border-red-300 hover:text-red-600'
      }`}
    >
      {error ? '!' : banned ? <UnlockIcon /> : <BanIcon />}
    </button>
  );
}

function BanIcon() {
  return <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><circle cx="12" cy="12" r="10" /><line x1="4.9" y1="4.9" x2="19.1" y2="19.1" /></svg>;
}
function UnlockIcon() {
  return <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><rect x="3" y="11" width="18" height="11" rx="2" /><path d="M7 11V7a5 5 0 0 1 9.9-1" /></svg>;
}
