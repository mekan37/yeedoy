'use client';

import { useState, useTransition } from 'react';
import { PanelActionButton } from '@/src/ui/bilesenler/panel-eylem-dugmesi';
import { approveClaim, rejectClaim } from './itiraz-islemleri';

interface Claim {
  id: string;
  status: string;
  created_at: string;
  businesses: { id: string; name: string; slug: string | null } | null;
  user_profiles: { user_id: string; display_name: string | null; email?: string | null } | null;
}

interface Props {
  claims: Claim[];
  compact?: boolean;
}

const STATUS_LABELS: Record<string, { label: string; className: string }> = {
  pending: { label: 'Bekliyor', className: 'bg-amber-50 text-amber-700' },
  approved: { label: 'Onaylandı', className: 'bg-green-50 text-green-700' },
  rejected: { label: 'Reddedildi', className: 'bg-red-50 text-[color:var(--yd-color-danger)]' },
};

export function ClaimsTable({ claims, compact }: Props) {
  return (
    <div className="overflow-x-auto">
      <table className="w-full text-sm">
        <thead>
          <tr className="border-b border-border text-left">
            <th className="py-2 pr-4 text-[11px] font-[800] uppercase tracking-wide text-muted">İşletme</th>
            <th className="py-2 pr-4 text-[11px] font-[800] uppercase tracking-wide text-muted">Talep Eden</th>
            <th className="py-2 pr-4 text-[11px] font-[800] uppercase tracking-wide text-muted">Tarih</th>
            <th className="py-2 text-[11px] font-[800] uppercase tracking-wide text-muted">Durum</th>
            {!compact && <th className="py-2 text-[11px] font-[800] uppercase tracking-wide text-muted">İşlem</th>}
          </tr>
        </thead>
        <tbody className="divide-y divide-border">
          {claims.map((claim) => (
            <ClaimRow key={claim.id} claim={claim} compact={compact} />
          ))}
        </tbody>
      </table>
    </div>
  );
}

function ClaimRow({ claim, compact }: { claim: Claim; compact?: boolean }) {
  const [isPending, startTransition] = useTransition();
  const [done, setDone] = useState(false);
  const statusConfig = STATUS_LABELS[claim.status] ?? STATUS_LABELS.pending;
  const date = new Date(claim.created_at).toLocaleDateString('tr-TR');

  if (done) {
    return (
      <tr>
        <td colSpan={5} className="py-2 text-xs text-muted italic">İşlendi</td>
      </tr>
    );
  }

  function handleApprove() {
    startTransition(async () => {
      await approveClaim(claim.id);
      setDone(true);
    });
  }

  function handleReject() {
    startTransition(async () => {
      await rejectClaim(claim.id);
      setDone(true);
    });
  }

  return (
    <tr className="hover:bg-black/[0.02]">
      <td className="py-2.5 pr-4">
        <p className="font-[700] text-textStrong">{claim.businesses?.name ?? '—'}</p>
        <p className="text-xs text-muted">{claim.businesses?.slug ?? '—'}</p>
      </td>
      <td className="py-2.5 pr-4">
        <p className="text-textStrong">{claim.user_profiles?.display_name ?? '—'}</p>
        <p className="text-xs text-muted">{claim.user_profiles?.email ?? '—'}</p>
      </td>
      <td className="py-2.5 pr-4 text-xs text-muted">{date}</td>
      <td className="py-2.5">
        <span className={`rounded-full px-2 py-0.5 text-[11px] font-[800] ${statusConfig.className}`}>
          {statusConfig.label}
        </span>
      </td>
      {!compact && claim.status === 'pending' && (
        <td className="py-2.5">
          <div className="flex items-center gap-2">
            <PanelActionButton
              variant="primary"
              loading={isPending}
              onClick={handleApprove}
              className="py-1 text-xs"
            >
              Onayla
            </PanelActionButton>
            <PanelActionButton
              variant="danger"
              loading={isPending}
              onClick={handleReject}
              className="py-1 text-xs"
            >
              Reddet
            </PanelActionButton>
          </div>
        </td>
      )}
      {!compact && claim.status !== 'pending' && <td />}
    </tr>
  );
}
