'use client';

import { useState, useTransition } from 'react';
import { PanelActionButton } from '@/src/ui/bilesenler/panel-eylem-dugmesi';
import { approvePriceSuggestion, rejectPriceSuggestion } from './fiyat-oneri-islemleri';
import { DURUM_ETIKETLERI, DURUM_RENKLERI, durumAnahtari, fiyatFormatla, type FiyatOneriSatiri } from './fiyat-onerileri-yardimcilari';

export function FiyatOneriSatiriRow({ row }: { row: FiyatOneriSatiri }) {
  const [isPending, startTransition] = useTransition();
  const [override, setOverride] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);
  const durum = durumAnahtari(override ?? row.status);

  function handleApprove() {
    setError(null);
    startTransition(async () => {
      const res = await approvePriceSuggestion(row.id);
      if (res.error) setError(res.error); else setOverride('approved');
    });
  }
  function handleReject() {
    setError(null);
    startTransition(async () => {
      const res = await rejectPriceSuggestion(row.id);
      if (res.error) setError(res.error); else setOverride('rejected');
    });
  }

  return (
    <tr className="hover:bg-black/2">
      <td className="px-5 py-3">
        <p className="font-bold text-textStrong">{row.itemName}</p>
        {row.note && <p className="max-w-[220px] truncate text-xs italic text-muted" title={row.note}>{row.note}</p>}
      </td>
      <td className="px-5 py-3 text-muted">{row.businessName ?? '—'}</td>
      <td className="px-5 py-3 text-muted">{fiyatFormatla(row.currentPriceCents, row.currentCurrency)}</td>
      <td className="px-5 py-3 font-extrabold text-textStrong">{fiyatFormatla(row.suggestedPriceCents, row.suggestedCurrency)}</td>
      <td className="px-5 py-3">
        <div className="flex items-center gap-1.5">
          <div className="h-1.5 w-16 overflow-hidden rounded-full bg-black/8">
            <div className="h-full bg-primary" style={{ width: `${Math.round((row.qualityConfidence ?? 0) * 100)}%` }} />
          </div>
          <span className="text-xs font-bold text-muted">%{Math.round((row.qualityConfidence ?? 0) * 100)}</span>
        </div>
        {row.onsiteVerified && <span className="mt-0.5 block text-[10px] font-extrabold text-emerald-600">Yerinde Doğrulandı</span>}
      </td>
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
