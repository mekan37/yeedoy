'use client';

import { useState, useTransition } from 'react';
import { useRouter } from 'next/navigation';
import { PanelActionButton } from '@/src/ui/bilesenler/panel-eylem-dugmesi';
import { adminRestoreMenu, adminPermanentlyDeleteMenu } from './cop-kutusu-islemleri';
import { MenuSatiriRow } from './menu-satiri';
import type { SilinmisMenuSatiri } from './cop-kutusu-yardimcilari';

export function MenulerTablosu({ rows }: { rows: SilinmisMenuSatiri[] }) {
  const router = useRouter();
  const [selected, setSelected] = useState<Set<string>>(new Set());
  const [isPending, startTransition] = useTransition();
  const [confirmBulkDelete, setConfirmBulkDelete] = useState(false);

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
  function bulkRestore() {
    startTransition(async () => {
      for (const id of Array.from(selected)) await adminRestoreMenu(id);
      setSelected(new Set());
      router.refresh();
    });
  }
  function bulkDelete() {
    startTransition(async () => {
      for (const id of Array.from(selected)) await adminPermanentlyDeleteMenu(id);
      setSelected(new Set());
      setConfirmBulkDelete(false);
      router.refresh();
    });
  }

  return (
    <div className="flex flex-col gap-3">
      {selected.size > 0 && (
        <div className="flex items-center justify-between rounded-xl border border-primary/20 bg-primary/5 px-4 py-2.5">
          <p className="text-xs font-extrabold text-textStrong">{selected.size} menü seçildi</p>
          <div className="flex items-center gap-2">
            <PanelActionButton variant="secondary" loading={isPending} onClick={bulkRestore} className="py-1 text-xs">Toplu Geri Yükle</PanelActionButton>
            {confirmBulkDelete ? (
              <>
                <PanelActionButton variant="danger" loading={isPending} onClick={bulkDelete} className="py-1 text-xs">Onayla — Kalıcı Sil</PanelActionButton>
                <button type="button" onClick={() => setConfirmBulkDelete(false)} className="rounded-lg border border-border px-2.5 py-1 text-xs font-bold text-muted">Vazgeç</button>
              </>
            ) : (
              <PanelActionButton variant="danger" onClick={() => setConfirmBulkDelete(true)} className="py-1 text-xs">Toplu Kalıcı Sil</PanelActionButton>
            )}
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
              <th className="px-5 py-3 text-[11px] font-extrabold uppercase tracking-wide text-muted">Menü Adı</th>
              <th className="px-5 py-3 text-[11px] font-extrabold uppercase tracking-wide text-muted">İşletme</th>
              <th className="px-5 py-3 text-[11px] font-extrabold uppercase tracking-wide text-muted">Menü Sahibi</th>
              <th className="px-5 py-3 text-[11px] font-extrabold uppercase tracking-wide text-muted">Arşivlenme</th>
              <th className="px-5 py-3 text-[11px] font-extrabold uppercase tracking-wide text-muted">Süre Bitişi</th>
              <th className="px-5 py-3 text-right text-[11px] font-extrabold uppercase tracking-wide text-muted">İşlemler</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-border">
            {rows.map((row) => (
              <MenuSatiriRow key={row.id} row={row} selected={selected.has(row.id)} onToggleSelect={toggleOne} />
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}
