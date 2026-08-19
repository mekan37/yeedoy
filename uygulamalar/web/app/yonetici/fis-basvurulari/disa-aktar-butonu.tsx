'use client';

import { fisCsvOlustur } from './fis-yardimcilari';
import type { FisGonderim } from '@/src/lib/veri/admin/fis-gonderimleri-types';

export function DisaAktarButonu({ rows }: { rows: FisGonderim[] }) {
  function disaAktar() {
    const csv = fisCsvOlustur(rows);
    const blob = new Blob(['﻿' + csv], { type: 'text/csv;charset=utf-8;' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `fis-basvurulari-${new Date().toISOString().slice(0, 10)}.csv`;
    a.click();
    URL.revokeObjectURL(url);
  }

  return (
    <button
      type="button"
      onClick={disaAktar}
      title="Bu sayfadaki (filtrelenmiş) satırları CSV olarak indir"
      className="flex items-center justify-between rounded-xl border border-border px-3 py-2.5 text-xs font-extrabold text-textStrong transition-colors hover:border-primary/30 hover:text-primary"
    >
      <span>Dışa Aktar<span className="block text-[10px] font-bold text-muted">Fiş başvurularını CSV olarak indir</span></span>
      <DownloadIcon />
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
