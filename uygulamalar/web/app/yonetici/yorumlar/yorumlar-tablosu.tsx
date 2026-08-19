'use client';

import { useState, useTransition } from 'react';
import { useRouter } from 'next/navigation';
import { PanelActionButton } from '@/src/ui/bilesenler/panel-eylem-dugmesi';
import { YorumSatiriRow } from './yorum-satiri';
import type { YorumSatiri } from './yorumlar-yardimcilari';

export function YorumlarTablosu({ rows }: { rows: YorumSatiri[] }) {
  const router = useRouter();
  const [selected, setSelected] = useState<Set<string>>(new Set());
  const [isPending, startTransition] = useTransition();

  const hepsiSecili = rows.length > 0 && rows.every((r) => selected.has(r.id));

  function toggleAll() {
    setSelected(hepsiSecili ? new Set() : new Set(rows.map((r) => r.id)));
  }
  function toggleOne(id: string) {
    setSelected((prev) => {
      const next = new Set(prev);
      if (next.has(id)) next.delete(id); else next.add(id);
      return next;
    });
  }
  function bulkAction(action: 'approve' | 'remove') {
    startTransition(async () => {
      try {
        await fetch('/sunucu/yonetici/toplu-islemler', {
          method: 'PATCH',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ type: 'reviews', ids: Array.from(selected), action }),
        });
      } catch { /* */ }
      setSelected(new Set());
      router.refresh();
    });
  }

  return (
    <div id="toplu-islemler" className="flex flex-col gap-3 scroll-mt-20">
      {selected.size > 0 && (
        <div className="flex items-center justify-between rounded-xl border border-primary/20 bg-primary/5 px-4 py-2.5">
          <p className="text-xs font-extrabold text-textStrong">{selected.size} yorum seçildi</p>
          <div className="flex items-center gap-2">
            <PanelActionButton variant="primary" loading={isPending} onClick={() => bulkAction('approve')} className="py-1 text-xs">Seçilenleri Onayla</PanelActionButton>
            <PanelActionButton variant="danger" loading={isPending} onClick={() => bulkAction('remove')} className="py-1 text-xs">Seçilenleri Reddet</PanelActionButton>
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
              <th className="px-5 py-3 text-[11px] font-extrabold uppercase tracking-wide text-muted">Yorum</th>
              <th className="px-5 py-3 text-[11px] font-extrabold uppercase tracking-wide text-muted">İşletme</th>
              <th className="px-5 py-3 text-[11px] font-extrabold uppercase tracking-wide text-muted">Kullanıcı</th>
              <th className="px-5 py-3 text-[11px] font-extrabold uppercase tracking-wide text-muted">Puan</th>
              <th className="px-5 py-3 text-[11px] font-extrabold uppercase tracking-wide text-muted">Tarih</th>
              <th className="px-5 py-3 text-[11px] font-extrabold uppercase tracking-wide text-muted">Durum</th>
              <th className="px-5 py-3 text-right text-[11px] font-extrabold uppercase tracking-wide text-muted">İşlemler</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-border">
            {rows.map((row) => (
              <YorumSatiriRow key={row.id} row={row} selected={selected.has(row.id)} onToggleSelect={toggleOne} />
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}
