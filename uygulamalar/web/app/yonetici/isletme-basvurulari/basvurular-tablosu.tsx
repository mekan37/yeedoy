'use client';

import { useState, useTransition } from 'react';
import { useRouter } from 'next/navigation';
import { PanelActionButton } from '@/src/ui/bilesenler/panel-eylem-dugmesi';
import { approveSubmission, rejectSubmission } from '../kuyruklar/inceleme-islemleri';
import { BasvuruSatiriRow } from './basvuru-satiri';
import { durumAnahtari, type BasvuruSatiri } from './basvurular-yardimcilari';

export function BasvurularTablosu({ rows }: { rows: BasvuruSatiri[] }) {
  const router = useRouter();
  const [selected, setSelected] = useState<Set<string>>(new Set());
  const [isPending, startTransition] = useTransition();

  const secilebilirler = rows.filter((r) => {
    const d = durumAnahtari(r);
    return d === 'pending' || d === 'reviewing';
  });
  const hepsiSecili = secilebilirler.length > 0 && secilebilirler.every((r) => selected.has(r.id));

  function toggleAll() {
    if (hepsiSecili) {
      setSelected(new Set());
    } else {
      setSelected(new Set(secilebilirler.map((r) => r.id)));
    }
  }
  function toggleOne(id: string) {
    setSelected((prev) => {
      const next = new Set(prev);
      if (next.has(id)) next.delete(id); else next.add(id);
      return next;
    });
  }

  function bulkAction(action: 'approve' | 'reject') {
    startTransition(async () => {
      const ids = Array.from(selected);
      for (const id of ids) {
        try {
          if (action === 'approve') await approveSubmission(id);
          else await rejectSubmission(id);
        } catch {
          // bir kaydın başarısız olması diğerlerini durdurmaz
        }
      }
      setSelected(new Set());
      router.refresh();
    });
  }

  return (
    <div id="toplu-islemler" className="flex flex-col gap-3 scroll-mt-20">
      {selected.size > 0 && (
        <div className="flex items-center justify-between rounded-xl border border-primary/20 bg-primary/5 px-4 py-2.5">
          <p className="text-xs font-extrabold text-textStrong">{selected.size} kayıt seçildi</p>
          <div className="flex items-center gap-2">
            <PanelActionButton variant="primary" loading={isPending} onClick={() => bulkAction('approve')} className="py-1 text-xs">Seçilenleri Onayla</PanelActionButton>
            <PanelActionButton variant="danger" loading={isPending} onClick={() => bulkAction('reject')} className="py-1 text-xs">Seçilenleri Reddet</PanelActionButton>
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
              <th className="px-5 py-3 text-[11px] font-extrabold uppercase tracking-wide text-muted">İşletme Bilgileri</th>
              <th className="px-5 py-3 text-[11px] font-extrabold uppercase tracking-wide text-muted">Başvuru No</th>
              <th className="px-5 py-3 text-[11px] font-extrabold uppercase tracking-wide text-muted">Başvuru Tarihi</th>
              <th className="px-5 py-3 text-[11px] font-extrabold uppercase tracking-wide text-muted">Durum</th>
              <th className="px-5 py-3 text-right text-[11px] font-extrabold uppercase tracking-wide text-muted">İşlemler</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-border">
            {rows.map((row) => (
              <BasvuruSatiriRow key={row.id} row={row} selected={selected.has(row.id)} onToggleSelect={toggleOne} />
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}
