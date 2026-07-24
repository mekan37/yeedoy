'use client';

import { useRouter } from 'next/navigation';

export function ForbiddenActions() {
  const router = useRouter();

  return (
    <>
      <button
        type="button"
        onClick={() => router.back()}
        className="flex h-12 items-center gap-2 rounded-xl bg-[#dc2626] px-7 text-sm font-extrabold text-white shadow-[0_2px_8px_rgba(220,38,38,0.28)] transition hover:bg-[#b91c1c] active:scale-[0.98]"
      >
        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round">
          <line x1="19" y1="12" x2="5" y2="12" />
          <polyline points="12 19 5 12 12 5" />
        </svg>
        Panele Dön
      </button>

      <button
        type="button"
        className="flex h-12 items-center gap-2 rounded-xl border border-[#e5e7eb] bg-white px-7 text-sm font-bold text-[#374151] transition hover:bg-[#f9fafb] hover:border-[#d1d5db] active:scale-[0.98]"
      >
        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
          <path d="M3 18v-6a9 9 0 0 1 18 0v6" />
          <path d="M21 19a2 2 0 0 1-2 2h-1a2 2 0 0 1-2-2v-3a2 2 0 0 1 2-2h3zM3 19a2 2 0 0 0 2 2h1a2 2 0 0 0 2-2v-3a2 2 0 0 0-2-2H3z" />
        </svg>
        Destek ile İletişime Geç
      </button>
    </>
  );
}
