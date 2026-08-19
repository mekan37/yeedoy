'use client';

import { useState, useTransition } from 'react';
import { PanelActionButton } from '@/src/ui/bilesenler/panel-eylem-dugmesi';
import { approveSubmission, rejectSubmission, setSubmissionReview } from '../kuyruklar/inceleme-islemleri';
import { basvuruNoOlustur, durumAnahtari, DURUM_ETIKETLERI, DURUM_RENKLERI, type BasvuruSatiri } from './basvurular-yardimcilari';

export function BasvuruSatiriRow({
  row,
  selected,
  onToggleSelect,
}: {
  row: BasvuruSatiri;
  selected: boolean;
  onToggleSelect: (id: string) => void;
}) {
  const [isPending, startTransition] = useTransition();
  const [override, setOverride] = useState<{ status: string; assignedToName: string | null } | null>(null);
  const effective = override ?? row;
  const durum = durumAnahtari(effective);

  function handleApprove() {
    startTransition(async () => {
      try { await approveSubmission(row.id); setOverride({ status: 'approved', assignedToName: null }); } catch { /* toast yok, kart durumda kalır */ }
    });
  }
  function handleReject() {
    startTransition(async () => {
      try { await rejectSubmission(row.id); setOverride({ status: 'rejected', assignedToName: null }); } catch { /* */ }
    });
  }
  function handleReviewToggle() {
    startTransition(async () => {
      try {
        const yeniDurum = durum !== 'reviewing';
        await setSubmissionReview(row.id, yeniDurum);
        setOverride({ status: 'new', assignedToName: yeniDurum ? 'Siz' : null });
      } catch { /* */ }
    });
  }

  return (
    <tr className="hover:bg-black/2">
      <td className="px-4 py-3">
        <input type="checkbox" checked={selected} onChange={() => onToggleSelect(row.id)} disabled={durum !== 'pending' && durum !== 'reviewing'} className="h-4 w-4 rounded border-border" />
      </td>
      <td className="px-5 py-3">
        <div className="flex items-center gap-2.5">
          <span className="flex h-9 w-9 shrink-0 items-center justify-center rounded-lg bg-primary/10 text-xs font-black text-primary">
            {row.name.charAt(0).toUpperCase()}
          </span>
          <div className="min-w-0">
            <p className="truncate font-bold text-textStrong">{row.name}</p>
            <p className="truncate text-xs text-muted">{row.submittedByName ?? '—'}</p>
          </div>
        </div>
      </td>
      <td className="px-5 py-3 text-xs text-muted">{basvuruNoOlustur(row.id)}</td>
      <td className="px-5 py-3 text-xs text-muted">{new Date(row.createdAt).toLocaleDateString('tr-TR')} {new Date(row.createdAt).toLocaleTimeString('tr-TR', { hour: '2-digit', minute: '2-digit' })}</td>
      <td className="px-5 py-3">
        <span className={`rounded-full px-2 py-0.5 text-[11px] font-extrabold ${DURUM_RENKLERI[durum]}`}>{DURUM_ETIKETLERI[durum]}</span>
        {durum === 'reviewing' && effective.assignedToName && (
          <p className="mt-0.5 text-[10px] text-muted">{effective.assignedToName} inceliyor</p>
        )}
      </td>
      <td className="px-5 py-3">
        {durum === 'pending' || durum === 'reviewing' ? (
          <div className="flex items-center justify-end gap-1.5">
            <PanelActionButton variant="primary" loading={isPending} onClick={handleApprove} className="py-1 text-xs">Onayla</PanelActionButton>
            <PanelActionButton variant="danger" loading={isPending} onClick={handleReject} className="py-1 text-xs">Reddet</PanelActionButton>
            <button
              type="button"
              onClick={handleReviewToggle}
              disabled={isPending}
              title={durum === 'reviewing' ? 'İncelemeden çıkar' : 'İncelemeye al'}
              className="flex h-8 w-8 items-center justify-center rounded-lg border border-border text-muted transition-colors hover:border-violet-300 hover:text-violet-700 disabled:opacity-50"
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
  return (
    <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z" /><circle cx="12" cy="12" r="3" />
    </svg>
  );
}
