'use client';

import { useState, useTransition } from 'react';
import { PanelActionButton } from '@/src/ui/bilesenler/panel-eylem-dugmesi';
import { updateFisDurum } from './fis-moderasyon-islemi';
import { fisNoOlustur } from './fis-yardimcilari';
import { REVIEW_STATUS_LABELS, REVIEW_STATUS_STYLES, type FisGonderim } from '@/src/lib/veri/admin/fis-gonderimleri-types';

export function FisSatiriRow({
  row,
  selected,
  onToggleSelect,
}: {
  row: FisGonderim;
  selected: boolean;
  onToggleSelect: (id: string) => void;
}) {
  const [isPending, startTransition] = useTransition();
  const [durum, setDurum] = useState(row.review_status);

  function setStatus(status: 'reviewed' | 'needs_followup' | 'pending') {
    startTransition(async () => {
      await updateFisDurum(row.receipt_id, status);
      setDurum(status);
    });
  }

  return (
    <tr className="hover:bg-black/2">
      <td className="px-4 py-3">
        <input type="checkbox" checked={selected} onChange={() => onToggleSelect(row.receipt_id)} className="h-4 w-4 rounded border-border" />
      </td>
      <td className="px-4 py-3 text-xs text-muted whitespace-nowrap">{fisNoOlustur(row.receipt_id, row.created_at)}</td>
      <td className="px-4 py-3">
        <p className="font-bold text-textStrong">{row.business_name ?? '—'}</p>
        <p className="text-xs text-muted">{[row.district, row.city, row.chain_name].filter(Boolean).join(' · ')}</p>
      </td>
      <td className="px-4 py-3 font-mono text-xs text-muted">{row.submitter_display}</td>
      <td className="px-4 py-3">
        <span className={`text-sm font-extrabold ${row.matches_count === 0 ? 'text-red-500' : 'text-textStrong'}`}>{row.matches_count} ürün</span>
      </td>
      <td className="px-4 py-3 text-xs text-muted whitespace-nowrap">{new Date(row.created_at).toLocaleDateString('tr-TR')}</td>
      <td className="px-4 py-3 text-center">
        {row.image_url ? (
          <a href={row.image_url} target="_blank" rel="noreferrer" className="inline-flex min-h-8 items-center gap-1 rounded-lg border border-border px-2.5 text-xs font-extrabold text-textStrong transition-colors hover:border-primary/30 hover:text-primary">
            Gör
          </a>
        ) : (
          <span className="text-xs text-muted">—</span>
        )}
      </td>
      <td className="px-4 py-3">
        <span className={`rounded-full px-2 py-0.5 text-[10px] font-extrabold ${REVIEW_STATUS_STYLES[durum] ?? 'bg-zinc-100 text-zinc-500'}`}>
          {REVIEW_STATUS_LABELS[durum] ?? durum}
        </span>
      </td>
      <td className="px-4 py-3">
        <div className="flex items-center justify-end gap-1.5">
          {durum !== 'reviewed' && (
            <PanelActionButton variant="primary" loading={isPending} onClick={() => setStatus('reviewed')} className="py-1 text-xs">İncele</PanelActionButton>
          )}
          {durum !== 'needs_followup' && (
            <PanelActionButton variant="secondary" loading={isPending} onClick={() => setStatus('needs_followup')} className="py-1 text-xs">Takip</PanelActionButton>
          )}
          {durum !== 'pending' && (
            <button type="button" disabled={isPending} onClick={() => setStatus('pending')} className="rounded-lg border border-border px-2.5 py-1 text-[11px] font-extrabold text-muted transition-colors hover:border-zinc-300 disabled:opacity-50">
              Sıfırla
            </button>
          )}
        </div>
      </td>
    </tr>
  );
}
