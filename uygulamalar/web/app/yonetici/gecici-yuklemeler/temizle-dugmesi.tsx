'use client';

import { useTransition, useState } from 'react';
import { surescDolanlariTemizle } from './temizle-islemleri';

export function TemizleDugmesi() {
  const [isPending, startTransition] = useTransition();
  const [result, setResult] = useState<string | null>(null);

  function handleClick() {
    startTransition(async () => {
      const res = await surescDolanlariTemizle();
      if (res.error) {
        setResult(`Hata: ${res.error}`);
      } else {
        setResult(`${res.deleted ?? 0} kayıt silindi`);
      }
    });
  }

  return (
    <div className="flex items-center gap-3">
      {result && (
        <span className="text-xs text-muted">{result}</span>
      )}
      <button
        type="button"
        disabled={isPending}
        onClick={handleClick}
        className="flex items-center gap-1.5 rounded-xl border border-border bg-card px-4 py-2 text-sm font-[700] text-textStrong transition-colors hover:bg-black/[0.04] disabled:cursor-not-allowed disabled:opacity-50"
      >
        <TrashIcon />
        {isPending ? 'Temizleniyor…' : 'Süresi Dolanları Temizle'}
      </button>
    </div>
  );
}

function TrashIcon() {
  return (
    <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <polyline points="3 6 5 6 21 6" />
      <path d="M19 6l-1 14a2 2 0 0 1-2 2H8a2 2 0 0 1-2-2L5 6" />
      <path d="M10 11v6M14 11v6M9 6V4a1 1 0 0 1 1-1h4a1 1 0 0 1 1 1v2" />
    </svg>
  );
}
