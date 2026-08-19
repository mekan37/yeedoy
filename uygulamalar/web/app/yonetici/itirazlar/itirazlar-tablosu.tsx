'use client';

import { useState, useTransition } from 'react';
import { useRouter } from 'next/navigation';
import { PanelActionButton } from '@/src/ui/bilesenler/panel-eylem-dugmesi';
import { decideAppeal } from './itiraz-islemleri';
import { ItirazSatiriRow } from './itiraz-satiri';
import { itirazDurumu, type ItirazSatiri } from './itirazlar-yardimcilari';

export function ItirazlarTablosu({ rows }: { rows: ItirazSatiri[] }) {
  const router = useRouter();
  const [selected, setSelected] = useState<Set<string>>(new Set());
  const [isPending, startTransition] = useTransition();

  const secilebilirler = rows.filter((r) => { const d = itirazDurumu(r); return d === 'pending' || d === 'reviewing'; });
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
  function bulkAction(decision: 'approved' | 'rejected') {
    startTransition(async () => {
      for (const id of Array.from(selected)) {
        try { await decideAppeal(id, decision); } catch { /* */ }
      }
      setSelected(new Set());
      router.refresh();
    });
  }

  return (
    <div className="flex flex-col gap-3">
      {selected.size > 0 && (
        <div className="flex items-center justify-between rounded-xl border border-primary/20 bg-primary/5 px-4 py-2.5">
          <p className="text-xs font-extrabold text-textStrong">{selected.size} itiraz seçildi</p>
          <div className="flex items-center gap-2">
            <PanelActionButton variant="primary" loading={isPending} onClick={() => bulkAction('approved')} className="py-1 text-xs">Seçilenleri Onayla</PanelActionButton>
            <PanelActionButton variant="danger" loading={isPending} onClick={() => bulkAction('rejected')} className="py-1 text-xs">Seçilenleri Reddet</PanelActionButton>
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
              <th className="px-4 py-3 text-[11px] font-extrabold uppercase tracking-wide text-muted">İtiraz No</th>
              <th className="px-4 py-3 text-[11px] font-extrabold uppercase tracking-wide text-muted">İtiraz Sahibi</th>
              <th className="px-4 py-3 text-[11px] font-extrabold uppercase tracking-wide text-muted">İlgili Tür</th>
              <th className="px-4 py-3 text-[11px] font-extrabold uppercase tracking-wide text-muted">İlgili İçerik</th>
              <th className="px-4 py-3 text-[11px] font-extrabold uppercase tracking-wide text-muted">Neden</th>
              <th className="px-4 py-3 text-[11px] font-extrabold uppercase tracking-wide text-muted">Tarih</th>
              <th className="px-4 py-3 text-[11px] font-extrabold uppercase tracking-wide text-muted">Durum</th>
              <th className="px-4 py-3 text-right text-[11px] font-extrabold uppercase tracking-wide text-muted">İşlemler</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-border">
            {rows.map((row) => (
              <ItirazSatiriRow key={row.id} row={row} selected={selected.has(row.id)} onToggleSelect={toggleOne} />
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}
