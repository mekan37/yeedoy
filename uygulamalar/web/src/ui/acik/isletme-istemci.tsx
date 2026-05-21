'use client';

import { useState, useEffect } from 'react';
import { toast } from '@/src/lib/toast-deposu';

/** Parse "09:00 - 22:00" → { open: 9*60, close: 22*60 } */
function parseHours(value: string): { open: number; close: number } | null {
  const m = value.match(/(\d{1,2}):(\d{2})\s*[-–]\s*(\d{1,2}):(\d{2})/);
  if (!m) return null;
  return {
    open:  parseInt(m[1]) * 60 + parseInt(m[2]),
    close: parseInt(m[3]) * 60 + parseInt(m[4]),
  };
}

export function AcikKapaliRozeti({ todayValue }: { todayValue?: string }) {
  const [status, setStatus] = useState<'acik' | 'kapali' | null>(null);

  useEffect(() => {
    if (!todayValue) { setStatus('kapali'); return; }
    if (/kapali/i.test(todayValue)) { setStatus('kapali'); return; }
    const range = parseHours(todayValue);
    if (!range) { setStatus(null); return; }
    const now = new Date();
    const minutes = now.getHours() * 60 + now.getMinutes();
    setStatus(minutes >= range.open && minutes < range.close ? 'acik' : 'kapali');
  }, [todayValue]);

  if (status === null) return null;
  return (
    <span
      className={
        status === 'acik'
          ? 'inline-flex items-center gap-1 rounded-full px-2.5 py-0.5 text-xs font-[800] bg-success/[0.12] text-success border border-success/25'
          : 'inline-flex items-center gap-1 rounded-full px-2.5 py-0.5 text-xs font-[800] bg-danger/[0.10] text-danger border border-danger/25'
      }
    >
      <span className={`h-1.5 w-1.5 rounded-full ${status === 'acik' ? 'bg-success' : 'bg-danger'}`} />
      {status === 'acik' ? 'Şu an açık' : 'Şu an kapalı'}
    </span>
  );
}

export function AdresKopyalaButonu({ address }: { address: string }) {
  const [copied, setCopied] = useState(false);

  async function handleCopy() {
    await navigator.clipboard.writeText(address).catch(() => undefined);
    setCopied(true);
    toast('Adres kopyalandı', 'success', 2000);
    setTimeout(() => setCopied(false), 2000);
  }

  return (
    <button
      type="button"
      onClick={handleCopy}
      aria-label="Adresi kopyala"
      className="inline-flex min-h-9 items-center gap-1.5 rounded-2xl border border-border px-3 text-xs font-[800] text-muted hover:border-primary/30 hover:text-primary transition-colors"
    >
      {copied ? (
        <svg viewBox="0 0 24 24" className="h-3.5 w-3.5 fill-none stroke-current stroke-2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
          <polyline points="20 6 9 17 4 12" />
        </svg>
      ) : (
        <svg viewBox="0 0 24 24" className="h-3.5 w-3.5 fill-none stroke-current stroke-2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
          <rect x="9" y="9" width="13" height="13" rx="2" ry="2" />
          <path d="M5 15H4a2 2 0 0 1-2-2V4a2 2 0 0 1 2-2h9a2 2 0 0 1 2 2v1" />
        </svg>
      )}
      {copied ? 'Kopyalandı' : 'Kopyala'}
    </button>
  );
}
