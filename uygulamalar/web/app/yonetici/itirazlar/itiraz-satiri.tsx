'use client';

import { useState, useTransition } from 'react';
import { PanelActionButton } from '@/src/ui/bilesenler/panel-eylem-dugmesi';
import { decideAppeal, setAppealReview } from './itiraz-islemleri';
import { itirazDurumu, itirazNoOlustur, DURUM_ETIKETLERI, DURUM_RENKLERI, KAYNAK_ETIKETLERI, type ItirazSatiri, type KaynakTuru } from './itirazlar-yardimcilari';

export function ItirazSatiriRow({
  row,
  selected,
  onToggleSelect,
}: {
  row: ItirazSatiri;
  selected: boolean;
  onToggleSelect: (id: string) => void;
}) {
  const [isPending, startTransition] = useTransition();
  const [override, setOverride] = useState<{ status: string; assignedToName: string | null } | null>(null);
  const effective = override ?? row;
  const durum = itirazDurumu(effective);
  const kaynak = row.sourceType as KaynakTuru;

  function handleDecide(decision: 'approved' | 'rejected') {
    startTransition(async () => {
      await decideAppeal(row.id, decision);
      setOverride({ status: decision, assignedToName: null });
    });
  }
  function handleReviewToggle() {
    startTransition(async () => {
      try {
        const yeni = durum !== 'reviewing';
        await setAppealReview(row.id, yeni);
        setOverride({ status: 'pending', assignedToName: yeni ? 'Siz' : null });
      } catch { /* */ }
    });
  }

  return (
    <tr className="hover:bg-black/2">
      <td className="px-4 py-3">
        <input type="checkbox" checked={selected} onChange={() => onToggleSelect(row.id)} disabled={durum === 'approved' || durum === 'rejected'} className="h-4 w-4 rounded border-border" />
      </td>
      <td className="px-4 py-3 text-xs text-muted whitespace-nowrap">{itirazNoOlustur(row.id, row.createdAt)}</td>
      <td className="px-4 py-3">
        <p className="text-xs font-bold text-textStrong">{row.appellantName ?? '—'}</p>
        <p className="text-[11px] text-muted">{row.appellantEmail ?? ''}</p>
      </td>
      <td className="px-4 py-3">
        <span className="rounded-full bg-slate-100 px-2 py-0.5 text-[10px] font-extrabold text-slate-700">{KAYNAK_ETIKETLERI[kaynak] ?? row.sourceType}</span>
      </td>
      <td className="max-w-[160px] px-4 py-3 text-xs text-muted">
        <p className="line-clamp-2">{row.contentLabel ?? '—'}</p>
      </td>
      <td className="max-w-[200px] px-4 py-3 text-xs text-muted">
        <p className="line-clamp-2">{row.reason}</p>
      </td>
      <td className="px-4 py-3 text-xs text-muted whitespace-nowrap">{new Date(row.createdAt).toLocaleDateString('tr-TR')}</td>
      <td className="px-4 py-3">
        <span className={`rounded-full px-2 py-0.5 text-[10px] font-extrabold ${DURUM_RENKLERI[durum]}`}>{DURUM_ETIKETLERI[durum]}</span>
        {durum === 'reviewing' && effective.assignedToName && <p className="mt-0.5 text-[10px] text-muted">{effective.assignedToName} inceliyor</p>}
      </td>
      <td className="px-4 py-3">
        {durum === 'pending' || durum === 'reviewing' ? (
          <div className="flex items-center justify-end gap-1.5">
            <PanelActionButton variant="primary" loading={isPending} onClick={() => handleDecide('approved')} className="py-1 text-xs">Onayla</PanelActionButton>
            <PanelActionButton variant="danger" loading={isPending} onClick={() => handleDecide('rejected')} className="py-1 text-xs">Reddet</PanelActionButton>
            <button
              type="button"
              onClick={handleReviewToggle}
              disabled={isPending}
              title={durum === 'reviewing' ? 'İncelemeden çıkar' : 'İncelemeye al'}
              className="flex h-8 w-8 items-center justify-center rounded-lg border border-border text-muted transition-colors hover:border-blue-300 hover:text-blue-700 disabled:opacity-50"
            >
              <EyeIcon />
            </button>
          </div>
        ) : (
          <span className="block text-right text-xs text-muted">İşlendi</span>
        )}
      </td>
    </tr>
  );
}

function EyeIcon() {
  return <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z" /><circle cx="12" cy="12" r="3" /></svg>;
}
