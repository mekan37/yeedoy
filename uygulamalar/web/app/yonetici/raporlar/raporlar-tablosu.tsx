'use client';

import { useState, useTransition } from 'react';
import { useRouter } from 'next/navigation';
import { PanelActionButton } from '@/src/ui/bilesenler/panel-eylem-dugmesi';
import { bulkUpdateReportStatus } from './rapor-islemleri';
import { RaporSatiriRow } from './rapor-satiri';
import type { RaporSatiri } from './raporlar-yardimcilari';

export function RaporlarTablosu({ rows }: { rows: RaporSatiri[] }) {
  const router = useRouter();
  const [selected, setSelected] = useState<Set<string>>(new Set());
  const [isPending, startTransition] = useTransition();

  const secilebilirler = rows.filter((r) => r.status !== 'closed');
  const hepsiSecili = secilebilirler.length > 0 && secilebilirler.every((r) => selected.has(r.id));

  function toggleAll() {
    setSelected(hepsiSecili ? new Set() : new Set(secilebilirler.map((r) => r.id)));
  }
  function toggleOne(id: string) {
    setSelected((prev) => {
      const next = new Set(prev);
      if (next.has(id)) next.delete(id); else next.add(id);
      return next;
    });
  }
  function bulkAction(status: 'reviewing' | 'closed') {
    startTransition(async () => {
      try { await bulkUpdateReportStatus(Array.from(selected), status); } catch { /* */ }
      setSelected(new Set());
      router.refresh();
    });
  }

  return (
    <div id="toplu-islemler" className="flex flex-col gap-3 scroll-mt-20">
      {selected.size > 0 && (
        <div className="flex items-center justify-between rounded-xl border border-primary/20 bg-primary/5 px-4 py-2.5">
          <p className="text-xs font-extrabold text-textStrong">{selected.size} rapor seçildi</p>
          <div className="flex items-center gap-2">
            <PanelActionButton variant="secondary" loading={isPending} onClick={() => bulkAction('reviewing')} className="py-1 text-xs">İncelemeye Al</PanelActionButton>
            <PanelActionButton variant="primary" loading={isPending} onClick={() => bulkAction('closed')} className="py-1 text-xs">Kapat</PanelActionButton>
          </div>
        </div>
      )}
      <div className="overflow-x-auto">
        <table className="w-full text-sm">
          <thead>
            <tr className="border-b border-border text-left">
              <th className="px-4 py-3">
                <input type="checkbox" checked={hepsiSecili} onChange={toggleAll} disabled={secilebilirler.length === 0} className="h-4 w-4 rounded border-border" />
              </th>
              <th className="px-5 py-3 text-[11px] font-extrabold uppercase tracking-wide text-muted">Rapor No</th>
              <th className="px-5 py-3 text-[11px] font-extrabold uppercase tracking-wide text-muted">Raporlayan</th>
              <th className="px-5 py-3 text-[11px] font-extrabold uppercase tracking-wide text-muted">Hedef</th>
              <th className="px-5 py-3 text-[11px] font-extrabold uppercase tracking-wide text-muted">Neden</th>
              <th className="px-5 py-3 text-[11px] font-extrabold uppercase tracking-wide text-muted">Tarih</th>
              <th className="px-5 py-3 text-[11px] font-extrabold uppercase tracking-wide text-muted">Durum</th>
              <th className="px-5 py-3 text-right text-[11px] font-extrabold uppercase tracking-wide text-muted">İşlemler</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-border">
            {rows.map((row) => (
              <RaporSatiriRow key={row.id} row={row} selected={selected.has(row.id)} onToggleSelect={toggleOne} />
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}
