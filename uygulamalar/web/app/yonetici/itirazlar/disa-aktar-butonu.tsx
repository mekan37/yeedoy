'use client';

import { itirazlarCsvOlustur, type ItirazSatiri } from './itirazlar-yardimcilari';

export function DisaAktarButonu({ rows }: { rows: ItirazSatiri[] }) {
  function disaAktar() {
    const csv = itirazlarCsvOlustur(rows);
    const blob = new Blob(['﻿' + csv], { type: 'text/csv;charset=utf-8;' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `itirazlar-${new Date().toISOString().slice(0, 10)}.csv`;
    a.click();
    URL.revokeObjectURL(url);
  }

  return (
    <button
      type="button"
      onClick={disaAktar}
      title="Bu sayfadaki (filtrelenmiş) satırları CSV olarak indir"
      className="flex w-full items-center justify-center rounded-xl border border-border bg-card px-4 py-2.5 text-xs font-extrabold text-textStrong transition-colors hover:border-primary/30 hover:text-primary"
    >
      Raporla
    </button>
  );
}
