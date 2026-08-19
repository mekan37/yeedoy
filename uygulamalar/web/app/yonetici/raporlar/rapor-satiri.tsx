'use client';

import { useState, useTransition } from 'react';
import { PanelActionButton } from '@/src/ui/bilesenler/panel-eylem-dugmesi';
import { updateReportStatus } from './rapor-islemleri';
import { raporNoOlustur, DURUM_ETIKETLERI, DURUM_RENKLERI, HEDEF_ETIKETLERI, type RaporSatiri, type RaporDurumu, type HedefTuru } from './raporlar-yardimcilari';

export function RaporSatiriRow({
  row,
  selected,
  onToggleSelect,
}: {
  row: RaporSatiri;
  selected: boolean;
  onToggleSelect: (id: string) => void;
}) {
  const [isPending, startTransition] = useTransition();
  const [overrideStatus, setOverrideStatus] = useState<RaporDurumu | null>(null);
  const durum = (overrideStatus ?? row.status) as RaporDurumu;
  const hedef = row.targetType as HedefTuru;

  function handleReview() {
    startTransition(async () => {
      try { await updateReportStatus(row.id, 'reviewing'); setOverrideStatus('reviewing'); } catch { /* */ }
    });
  }
  function handleClose() {
    startTransition(async () => {
      try { await updateReportStatus(row.id, 'closed'); setOverrideStatus('closed'); } catch { /* */ }
    });
  }

  return (
    <tr className="hover:bg-black/2">
      <td className="px-4 py-3">
        <input type="checkbox" checked={selected} onChange={() => onToggleSelect(row.id)} disabled={durum === 'closed'} className="h-4 w-4 rounded border-border" />
      </td>
      <td className="px-5 py-3 text-xs text-muted">{raporNoOlustur(row.id)}</td>
      <td className="px-5 py-3">
        <p className="text-xs font-bold text-textStrong">{row.reporterName ?? '—'}</p>
      </td>
      <td className="px-5 py-3">
        <p className="truncate text-sm font-bold text-textStrong">{row.targetLabel ?? '—'}</p>
        <span className="rounded-full bg-slate-100 px-1.5 py-0.5 text-[10px] font-extrabold text-slate-600">{HEDEF_ETIKETLERI[hedef] ?? row.targetType}</span>
      </td>
      <td className="px-5 py-3">
        <p className="text-xs font-bold text-textStrong">{row.reason}</p>
        {row.details && <p className="truncate text-[11px] text-muted" title={row.details}>{row.details}</p>}
      </td>
      <td className="px-5 py-3 text-xs text-muted">{new Date(row.createdAt).toLocaleDateString('tr-TR')}</td>
      <td className="px-5 py-3">
        <span className={`rounded-full px-2 py-0.5 text-[11px] font-extrabold ${DURUM_RENKLERI[durum]}`}>{DURUM_ETIKETLERI[durum]}</span>
        {row.slaBreached && durum !== 'closed' && (
          <p className="mt-0.5 text-[10px] font-bold text-red-600">24s+ bekliyor</p>
        )}
      </td>
      <td className="px-5 py-3">
        {durum === 'closed' ? (
          <span className="block text-right text-xs text-muted">İşlendi</span>
        ) : (
          <div className="flex items-center justify-end gap-1.5">
            {durum === 'open' && (
              <PanelActionButton variant="secondary" loading={isPending} onClick={handleReview} className="py-1 text-xs">İncelemeye Al</PanelActionButton>
            )}
            <PanelActionButton variant="primary" loading={isPending} onClick={handleClose} className="py-1 text-xs">Kapat</PanelActionButton>
          </div>
        )}
      </td>
    </tr>
  );
}
