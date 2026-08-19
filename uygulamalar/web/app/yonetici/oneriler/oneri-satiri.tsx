'use client';

import { useState, useTransition } from 'react';
import { PanelActionButton } from '@/src/ui/bilesenler/panel-eylem-dugmesi';
import { approveSuggestion, rejectSuggestion } from './oneri-islemleri';
import { DURUM_ETIKETLERI, DURUM_RENKLERI, durumAnahtari, type OneriSatiri } from './oneriler-yardimcilari';

export function OneriSatiriRow({ row }: { row: OneriSatiri }) {
  const [isPending, startTransition] = useTransition();
  const [override, setOverride] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);
  const durum = durumAnahtari(override ?? row.status);

  function handleApprove() {
    setError(null);
    startTransition(async () => {
      const res = await approveSuggestion(row.id);
      if (res.error) setError(res.error); else setOverride('approved');
    });
  }
  function handleReject() {
    setError(null);
    startTransition(async () => {
      const res = await rejectSuggestion(row.id);
      if (res.error) setError(res.error); else setOverride('rejected');
    });
  }

  return (
    <tr className="hover:bg-black/2">
      <td className="px-5 py-3">
        <div className="flex items-start gap-2.5">
          <span className="mt-0.5 flex h-8 w-8 shrink-0 items-center justify-center rounded-lg bg-primary/10 text-primary">
            <LightbulbIcon />
          </span>
          <div className="min-w-0">
            <p className="font-bold text-textStrong">{row.name}</p>
            <p className="max-w-[320px] truncate text-xs text-muted" title={row.note ?? undefined}>
              {row.note || [row.district, row.city].filter(Boolean).join(', ') || '—'}
            </p>
          </div>
        </div>
      </td>
      <td className="px-5 py-3">
        <span className="rounded-full bg-black/5 px-2 py-0.5 text-[11px] font-bold text-textStrong">{row.category ?? '—'}</span>
      </td>
      <td className="px-5 py-3 text-textStrong">{row.submitterName ?? '—'}</td>
      <td className="px-5 py-3 text-xs text-muted">{new Date(row.createdAt).toLocaleDateString('tr-TR')}</td>
      <td className="px-5 py-3">
        <span className={`rounded-full px-2 py-0.5 text-[11px] font-extrabold ${DURUM_RENKLERI[durum]}`}>{DURUM_ETIKETLERI[durum]}</span>
      </td>
      <td className="px-5 py-3">
        {durum === 'pending' ? (
          <div className="flex items-center justify-end gap-1.5">
            {error && <span className="text-[10px] font-bold text-red-600">{error}</span>}
            <PanelActionButton variant="primary" loading={isPending} onClick={handleApprove} className="py-1 text-xs">Onayla</PanelActionButton>
            <PanelActionButton variant="danger" loading={isPending} onClick={handleReject} className="py-1 text-xs">Reddet</PanelActionButton>
          </div>
        ) : (
          <span className="block text-right text-xs text-muted">İşlendi</span>
        )}
      </td>
    </tr>
  );
}

function LightbulbIcon() {
  return (
    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <line x1="9" y1="18" x2="15" y2="18" /><line x1="10" y1="22" x2="14" y2="22" />
      <path d="M15.09 14c.18-.98.65-1.74 1.41-2.5A4.65 4.65 0 0 0 18 8 6 6 0 0 0 6 8c0 1 .23 2.23 1.5 3.5A4.61 4.61 0 0 1 8.91 14" />
    </svg>
  );
}
