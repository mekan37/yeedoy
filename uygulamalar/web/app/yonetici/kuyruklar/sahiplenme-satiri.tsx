'use client';

import { useState, useTransition } from 'react';
import { PanelActionButton } from '@/src/ui/bilesenler/panel-eylem-dugmesi';
import { approveClaim, rejectClaim } from '../itirazlar/claims/itiraz-islemleri';

export interface SahiplenmeSatiriVerisi {
  id: string;
  businessName: string;
  businessSlug: string | null;
  currentOwnerName: string | null;
  claimantName: string | null;
  claimantEmail: string | null;
  claimantPhone: string | null;
  status: string;
  createdAt: string;
  evidenceUrl: string | null;
}

const STATUS_LABELS: Record<string, { label: string; className: string }> = {
  pending: { label: 'Beklemede', className: 'bg-amber-50 text-amber-700' },
  approved: { label: 'Onaylandı', className: 'bg-green-50 text-green-700' },
  rejected: { label: 'Reddedildi', className: 'bg-red-50 text-red-700' },
};

export function SahiplenmeSatiri({ row }: { row: SahiplenmeSatiriVerisi }) {
  const [isPending, startTransition] = useTransition();
  const [done, setDone] = useState<'approved' | 'rejected' | null>(null);
  const status = done ?? row.status;
  const statusConfig = STATUS_LABELS[status] ?? STATUS_LABELS.pending;

  function handleApprove() {
    startTransition(async () => {
      try {
        await approveClaim(row.id);
        setDone('approved');
      } catch {
        // hata durumunda durum aynı kalır
      }
    });
  }
  function handleReject() {
    startTransition(async () => {
      try {
        await rejectClaim(row.id);
        setDone('rejected');
      } catch {
        // hata durumunda durum aynı kalır
      }
    });
  }

  return (
    <tr className="hover:bg-black/2">
      <td className="px-5 py-3">
        <div className="flex items-center gap-2.5">
          <span className="flex h-9 w-9 shrink-0 items-center justify-center rounded-lg bg-primary/10 text-xs font-black text-primary">
            {row.businessName.charAt(0).toUpperCase()}
          </span>
          <div className="min-w-0">
            <p className="truncate font-bold text-textStrong">{row.businessName}</p>
            <p className="truncate text-xs text-muted">{row.businessSlug ?? '—'}</p>
          </div>
        </div>
      </td>
      <td className="px-5 py-3 text-muted">{row.currentOwnerName ?? '—'}</td>
      <td className="px-5 py-3">
        <p className="text-xs font-bold text-textStrong">{row.claimantName ?? '—'}</p>
        <p className="text-xs text-muted">{row.claimantEmail ?? '—'}</p>
        {row.claimantPhone && <p className="text-xs text-muted">{row.claimantPhone}</p>}
      </td>
      <td className="px-5 py-3 text-xs text-muted">{new Date(row.createdAt).toLocaleDateString('tr-TR')}</td>
      <td className="px-5 py-3">
        {row.evidenceUrl ? (
          <a href={row.evidenceUrl} target="_blank" rel="noreferrer" className="text-xs font-bold text-primary hover:underline">Belgeyi Gör</a>
        ) : (
          <span className="text-xs text-muted">—</span>
        )}
      </td>
      <td className="px-5 py-3">
        <span className={`rounded-full px-2 py-0.5 text-[11px] font-extrabold ${statusConfig.className}`}>{statusConfig.label}</span>
      </td>
      <td className="px-5 py-3">
        {status === 'pending' ? (
          <div className="flex items-center justify-end gap-2">
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
