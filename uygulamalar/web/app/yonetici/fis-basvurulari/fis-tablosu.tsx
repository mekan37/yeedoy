'use client';

import { useState, useTransition } from 'react';
import { useRouter } from 'next/navigation';
import { PanelActionButton } from '@/src/ui/bilesenler/panel-eylem-dugmesi';
import { updateFisDurum } from './fis-moderasyon-islemi';
import { FisSatiriRow } from './fis-satiri';
import type { FisGonderim } from '@/src/lib/veri/admin/fis-gonderimleri-types';

export function FisTablosu({ rows }: { rows: FisGonderim[] }) {
  const router = useRouter();
  const [selected, setSelected] = useState<Set<string>>(new Set());
  const [isPending, startTransition] = useTransition();

  const hepsiSecili = rows.length > 0 && rows.every((r) => selected.has(r.receipt_id));

  function toggleAll() {
    setSelected(hepsiSecili ? new Set() : new Set(rows.map((r) => r.receipt_id)));
  }
  function toggleOne(id: string) {
    setSelected((prev) => {
      const next = new Set(prev);
      if (next.has(id)) next.delete(id); else next.add(id);
      return next;
    });
  }
  function bulkAction(status: 'reviewed' | 'needs_followup') {
    startTransition(async () => {
      for (const id of Array.from(selected)) {
        await updateFisDurum(id, status);
      }
      setSelected(new Set());
      router.refresh();
    });
  }

  return (
    <div className="flex flex-col gap-3">
      {selected.size > 0 && (
        <div className="flex items-center justify-between rounded-xl border border-primary/20 bg-primary/5 px-4 py-2.5">
          <p className="text-xs font-extrabold text-textStrong">{selected.size} başvuru seçildi</p>
          <div className="flex items-center gap-2">
            <PanelActionButton variant="primary" loading={isPending} onClick={() => bulkAction('reviewed')} className="py-1 text-xs">Seçilenleri İncele</PanelActionButton>
            <PanelActionButton variant="secondary" loading={isPending} onClick={() => bulkAction('needs_followup')} className="py-1 text-xs">Takibe Al</PanelActionButton>
          </div>
        </div>
      )}
      <div className="overflow-x-auto">
        <table className="w-full text-sm">
          <thead>
            <tr className="border-b border-border text-left">
              <th className="px-4 py-3">
                <input type="checkbox" checked={hepsiSecili} onChange={toggleAll} disabled={rows.length === 0} className="h-4 w-4 rounded border-border" />
              </th>
              <th className="px-4 py-3 text-[11px] font-extrabold uppercase tracking-wide text-muted">Fiş No</th>
              <th className="px-4 py-3 text-[11px] font-extrabold uppercase tracking-wide text-muted">İşletme</th>
              <th className="px-4 py-3 text-[11px] font-extrabold uppercase tracking-wide text-muted">Kullanıcı</th>
              <th className="px-4 py-3 text-[11px] font-extrabold uppercase tracking-wide text-muted">Eşleşme</th>
              <th className="px-4 py-3 text-[11px] font-extrabold uppercase tracking-wide text-muted">Tarih</th>
              <th className="px-4 py-3 text-center text-[11px] font-extrabold uppercase tracking-wide text-muted">Fiş</th>
              <th className="px-4 py-3 text-[11px] font-extrabold uppercase tracking-wide text-muted">Durum</th>
              <th className="px-4 py-3 text-right text-[11px] font-extrabold uppercase tracking-wide text-muted">İşlemler</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-border">
            {rows.map((row) => (
              <FisSatiriRow key={row.receipt_id} row={row} selected={selected.has(row.receipt_id)} onToggleSelect={toggleOne} />
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}
