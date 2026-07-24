'use client';

import { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import { createSupabaseBrowserClient } from '@/src/lib/taban/istemci';

const WARN_BEFORE_SECS = 5 * 60; // 5 dakika önce uyar

export function OturumSuresiUyarisi() {
  const router = useRouter();
  const [secontsLeft, setSecondsLeft] = useState<number | null>(null);
  const [dismissed, setDismissed] = useState(false);

  useEffect(() => {
    const supabase = createSupabaseBrowserClient();
    let interval: ReturnType<typeof setInterval> | null = null;

    async function checkExpiry() {
      const { data: { session } } = await supabase.auth.getSession();
      if (!session) { setSecondsLeft(null); return; }

      const expiresAt = session.expires_at; // unix timestamp in seconds
      if (!expiresAt) return;
      const remaining = expiresAt - Math.floor(Date.now() / 1000);
      setSecondsLeft(remaining);
    }

    interval = setInterval(checkExpiry, 30_000);
    checkExpiry();

    return () => { if (interval) clearInterval(interval); };
  }, []);

  async function extend() {
    const supabase = createSupabaseBrowserClient();
    await supabase.auth.refreshSession();
    setDismissed(true);
    setSecondsLeft(null);
  }

  function signOut() {
    const supabase = createSupabaseBrowserClient();
    supabase.auth.signOut().then(() => router.push('/giris'));
  }

  if (dismissed || secontsLeft === null || secontsLeft > WARN_BEFORE_SECS || secontsLeft <= 0) {
    return null;
  }

  const minutes = Math.floor(secontsLeft / 60);

  return (
    <div
      role="alert"
      aria-live="assertive"
      className="fixed bottom-20 left-1/2 z-300 -translate-x-1/2 w-[calc(100%-2rem)] max-w-md rounded-[20px] border border-warning/30 bg-card shadow-yd3 p-4 md:bottom-6"
    >
      <div className="flex items-start gap-3">
        <svg viewBox="0 0 24 24" className="mt-0.5 h-5 w-5 shrink-0 fill-none stroke-warning stroke-2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
          <circle cx="12" cy="12" r="10" />
          <line x1="12" y1="8" x2="12" y2="12" />
          <line x1="12" y1="16" x2="12.01" y2="16" />
        </svg>
        <div className="flex-1 min-w-0">
          <p className="font-extrabold text-textStrong text-sm">Oturum {minutes} dakika içinde sona eriyor</p>
          <p className="mt-0.5 text-xs text-muted">Çalışmanızı kaybetmemek için oturumu uzatın.</p>
          <div className="mt-3 flex gap-2">
            <button
              type="button"
              onClick={extend}
              className="inline-flex min-h-9 items-center rounded-xl bg-primary px-3 text-xs font-extrabold text-white"
            >
              Oturumu Uzat
            </button>
            <button
              type="button"
              onClick={signOut}
              className="inline-flex min-h-9 items-center rounded-xl border border-border px-3 text-xs font-bold text-muted hover:text-textStrong"
            >
              Çıkış Yap
            </button>
            <button
              type="button"
              onClick={() => setDismissed(true)}
              className="ml-auto inline-flex min-h-9 items-center rounded-xl px-2 text-xs text-muted hover:text-textStrong"
              aria-label="Kapat"
            >
              ✕
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}
