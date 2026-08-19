'use client';

import { useState, useTransition } from 'react';
import Link from 'next/link';
import { PanelActionButton } from '@/src/ui/bilesenler/panel-eylem-dugmesi';
import { DURUM_ETIKETLERI, DURUM_RENKLERI, type YorumSatiri, type YorumDurumu } from './yorumlar-yardimcilari';

export function YorumSatiriRow({
  row,
  selected,
  onToggleSelect,
}: {
  row: YorumSatiri;
  selected: boolean;
  onToggleSelect: (id: string) => void;
}) {
  const [isPending, startTransition] = useTransition();
  const [overrideStatus, setOverrideStatus] = useState<YorumDurumu | null>(null);
  const durum = (overrideStatus ?? row.status) as YorumDurumu;

  function updateStatus(action: 'approve' | 'remove') {
    startTransition(async () => {
      try {
        const res = await fetch('/sunucu/yonetici/toplu-islemler', {
          method: 'PATCH',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ type: 'reviews', ids: [row.id], action }),
        });
        if (res.ok) setOverrideStatus(action === 'approve' ? 'approved' : 'rejected');
      } catch { /* */ }
    });
  }

  const publicHref = row.businessSlug ? `/isletme/${encodeURIComponent(row.businessSlug)}` : null;
  const clampedRating = Math.max(0, Math.min(5, row.rating));

  return (
    <tr className="hover:bg-black/2">
      <td className="px-4 py-3">
        <input type="checkbox" checked={selected} onChange={() => onToggleSelect(row.id)} className="h-4 w-4 rounded border-border" />
      </td>
      <td className="max-w-xs px-5 py-3">
        {row.title && <p className="mb-0.5 text-xs font-extrabold text-textStrong">{row.title}</p>}
        <p className="line-clamp-2 text-xs text-muted">{row.content}</p>
        <div className="mt-1 flex items-center gap-2 text-[10px] text-muted">
          <span>👍 {row.helpfulCount}</span>
          {row.hasOwnerReply && <span className="rounded-full bg-blue-50 px-1.5 py-0.5 font-extrabold text-blue-700">Yanıtlandı</span>}
          {row.reportCount > 0 && <span className="rounded-full bg-red-50 px-1.5 py-0.5 font-extrabold text-red-700">{row.reportCount} rapor</span>}
        </div>
      </td>
      <td className="px-5 py-3">
        <p className="font-bold text-textStrong">{row.businessName ?? '—'}</p>
        {row.businessCategory && <span className="rounded-full bg-slate-100 px-1.5 py-0.5 text-[10px] font-extrabold text-slate-600">{row.businessCategory}</span>}
      </td>
      <td className="px-5 py-3 text-muted">{row.userName ?? '—'}</td>
      <td className="px-5 py-3">
        <span className="font-extrabold text-amber-500">{'★'.repeat(clampedRating)}{'☆'.repeat(5 - clampedRating)}</span>
      </td>
      <td className="px-5 py-3 text-xs text-muted">{new Date(row.createdAt).toLocaleDateString('tr-TR')}</td>
      <td className="px-5 py-3">
        <span className={`rounded-full px-2 py-0.5 text-[11px] font-extrabold ${DURUM_RENKLERI[durum]}`}>{DURUM_ETIKETLERI[durum]}</span>
      </td>
      <td className="px-5 py-3">
        <div className="flex items-center justify-end gap-1.5">
          {publicHref && (
            <Link href={publicHref} target="_blank" rel="noreferrer" title="İşletme sayfasında gör" className="flex h-8 w-8 items-center justify-center rounded-lg border border-border text-muted transition-colors hover:border-primary/30 hover:text-primary">
              <EyeIcon />
            </Link>
          )}
          {durum !== 'approved' && (
            <PanelActionButton variant="primary" loading={isPending} onClick={() => updateStatus('approve')} className="py-1 text-xs">Onayla</PanelActionButton>
          )}
          {durum !== 'rejected' && (
            <PanelActionButton variant="danger" loading={isPending} onClick={() => updateStatus('remove')} className="py-1 text-xs">Reddet</PanelActionButton>
          )}
        </div>
      </td>
    </tr>
  );
}

function EyeIcon() {
  return <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z" /><circle cx="12" cy="12" r="3" /></svg>;
}
