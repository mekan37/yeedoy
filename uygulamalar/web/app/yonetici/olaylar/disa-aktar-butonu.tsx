'use client';

import { olaylarCsvOlustur, type OlaySatiri } from './olaylar-yardimcilari';

export function DisaAktarButonu({ rows }: { rows: OlaySatiri[] }) {
  function disaAktar() {
    const csv = olaylarCsvOlustur(rows);
    const blob = new Blob(['﻿' + csv], { type: 'text/csv;charset=utf-8;' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `olaylar-${new Date().toISOString().slice(0, 10)}.csv`;
    a.click();
    URL.revokeObjectURL(url);
  }

  return (
    <button
      type="button"
      onClick={disaAktar}
      title="Bu sayfadaki (filtrelenmiş) olayları CSV olarak indir"
      className="flex min-h-11 items-center gap-2 rounded-xl border border-border bg-card px-4 text-sm font-extrabold text-textStrong transition-colors hover:border-primary/30 hover:text-primary"
    >
      <DownloadIcon />
      Dışa Aktar
    </button>
  );
}

function DownloadIcon() {
  return (
    <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4" /><polyline points="7 10 12 15 17 10" /><line x1="12" y1="15" x2="12" y2="3" />
    </svg>
  );
}
