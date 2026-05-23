'use client';

import { useState } from 'react';

export function KoduGoster({ kod }: { kod: string }) {
  const [show, setShow] = useState(false);
  const [copied, setCopied] = useState(false);

  async function copy() {
    await navigator.clipboard.writeText(kod).catch(() => {});
    setCopied(true);
    setTimeout(() => setCopied(false), 2000);
  }

  if (!show) {
    return (
      <button
        type="button"
        onClick={() => setShow(true)}
        className="text-[11px] font-[700] text-muted hover:text-primary"
      >
        Kodu göster
      </button>
    );
  }

  return (
    <div className="flex items-center gap-1.5">
      <code className="rounded-lg border border-primary/20 bg-[var(--yd-color-primary-soft)] px-2.5 py-1 font-mono text-xs font-[900] tracking-widest text-primary">
        {kod}
      </code>
      <button
        type="button"
        onClick={copy}
        className="text-[10px] font-[700] text-muted hover:text-primary"
      >
        {copied ? '✓' : 'Kopyala'}
      </button>
    </div>
  );
}
