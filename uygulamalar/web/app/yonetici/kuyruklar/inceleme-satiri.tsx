'use client';

import { useState, useTransition } from 'react';
import { PanelActionButton } from '@/src/ui/bilesenler/panel-eylem-dugmesi';
import { approveSubmission, rejectSubmission } from './inceleme-islemleri';

export interface IncelemeSatiriVerisi {
  id: string;
  name: string;
  category: string;
  city: string;
  district: string;
  status: string;
  createdAt: string;
  submittedByName: string | null;
}

const STATUS_LABELS: Record<string, { label: string; className: string }> = {
  new: { label: 'Beklemede', className: 'bg-amber-50 text-amber-700' },
  approved: { label: 'Onaylandı', className: 'bg-green-50 text-green-700' },
  rejected: { label: 'Reddedildi', className: 'bg-red-50 text-red-700' },
};

export function IncelemeSatiri({ row }: { row: IncelemeSatiriVerisi }) {
  const [isPending, startTransition] = useTransition();
  const [done, setDone] = useState<'approved' | 'rejected' | null>(null);
  const status = done ?? row.status;
  const statusConfig = STATUS_LABELS[status] ?? STATUS_LABELS.new;

  function handleApprove() {
    startTransition(async () => {
      try {
        await approveSubmission(row.id);
        setDone('approved');
      } catch {
        // hata durumunda durum aynı kalır, kullanıcı tekrar deneyebilir
      }
    });
  }
  function handleReject() {
    startTransition(async () => {
      try {
        await rejectSubmission(row.id);
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
            {row.name.charAt(0).toUpperCase()}
          </span>
          <div className="min-w-0">
            <p className="truncate font-bold text-textStrong">{row.name}</p>
            <p className="truncate text-xs text-muted">{row.submittedByName ?? '—'}</p>
          </div>
        </div>
      </td>
      <td className="px-5 py-3 text-muted">{row.category}</td>
      <td className="px-5 py-3 text-muted">{[row.district, row.city].filter(Boolean).join(', ') || '—'}</td>
      <td className="px-5 py-3 text-xs text-muted">{new Date(row.createdAt).toLocaleDateString('tr-TR')}</td>
      <td className="px-5 py-3">
        <span className={`rounded-full px-2 py-0.5 text-[11px] font-extrabold ${statusConfig.className}`}>{statusConfig.label}</span>
      </td>
      <td className="px-5 py-3">
        {status === 'new' ? (
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
