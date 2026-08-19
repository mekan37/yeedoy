'use client';

import { yorumlarCsvOlustur, type YorumSatiri } from './yorumlar-yardimcilari';

export function DisaAktarButonu({ rows }: { rows: YorumSatiri[] }) {
  function disaAktar() {
    const csv = yorumlarCsvOlustur(rows);
    const blob = new Blob(['﻿' + csv], { type: 'text/csv;charset=utf-8;' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `yorumlar-${new Date().toISOString().slice(0, 10)}.csv`;
    a.click();
    URL.revokeObjectURL(url);
  }

  return (
    <button
      type="button"
      onClick={disaAktar}
      title="Bu sayfadaki (filtrelenmiş) satırları CSV olarak indir"
      className="inline-flex min-h-11 items-center gap-1.5 rounded-xl border border-border bg-card px-4 text-sm font-extrabold text-textStrong transition-colors hover:border-primary/30 hover:text-primary"
    >
      <DownloadIcon /> Dışa Aktar
    </button>
  );
}

function DownloadIcon() {
  return (
    <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4" /><polyline points="7 10 12 15 17 10" /><line x1="12" y1="15" x2="12" y2="3" />
    </svg>
  );
}
