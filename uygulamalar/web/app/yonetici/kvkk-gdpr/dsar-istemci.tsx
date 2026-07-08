'use client';

import { useState, useTransition } from 'react';
import { useRouter } from 'next/navigation';

interface DsarRequest {
  id: string; request_type: string; status: string; details: string | null;
  created_at: string; updated_at: string;
  user_profiles: { display_name: string | null; email: string | null } | null;
}

const STATUS_OPTIONS = [
  { value: 'in_review', label: 'İşleme Al', color: 'bg-blue-100 text-blue-700' },
  { value: 'resolved',  label: 'Tamamlandı', color: 'bg-green-100 text-green-700' },
  { value: 'rejected',   label: 'Reddedildi', color: 'bg-red-100 text-red-700' },
];

const STATUS_LABELS: Record<string, { label: string; color: string }> = {
  submitted:  { label: 'Bekliyor',    color: 'bg-yellow-50 text-yellow-700' },
  in_review:  { label: 'İşlemde',     color: 'bg-blue-50 text-blue-700' },
  resolved:   { label: 'Çözüldü',     color: 'bg-green-50 text-green-700' },
  rejected:   { label: 'Reddedildi',  color: 'bg-red-50 text-red-700' },
  cancelled:  { label: 'İptal',       color: 'bg-zinc-100 text-zinc-500' },
};

export function DsarYonetimi({ requests, requestTypeLabels }: {
  requests: DsarRequest[];
  requestTypeLabels: Record<string, string>;
}) {
  const router = useRouter();
  const [isPending, startTransition] = useTransition();
  const [filter, setFilter] = useState('all');
  const [selected, setSelected] = useState<string | null>(null);

  const filtered = filter === 'all' ? requests : requests.filter(r => r.status === filter);

  const updateStatus = (id: string, status: string) => {
    startTransition(async () => {
      await fetch('/sunucu/yonetici/dsar', {
        method: 'PATCH',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ id, status }),
      });
      setSelected(null);
      router.refresh();
    });
  };

  // Days since request
  const daysSince = (dateStr: string) => Math.floor((Date.now() - new Date(dateStr).getTime()) / 86400000);

  return (
    <div className="flex flex-col">
      {/* Filter bar */}
      <div className="flex gap-2 border-b border-border px-5 py-3">
        {['all', 'submitted', 'in_review', 'resolved'].map(f => (
          <button key={f} onClick={() => setFilter(f)}
            className={`rounded-lg px-3 py-1 text-xs font-[700] transition-colors ${filter === f ? 'bg-primary text-white' : 'text-muted hover:text-textStrong'}`}>
            {f === 'all' ? `Tümü (${requests.length})` :
             f === 'submitted' ? `Bekleyen (${requests.filter(r => r.status === 'submitted').length})` :
             STATUS_LABELS[f]?.label ?? f}
          </button>
        ))}
      </div>

      <div className="divide-y divide-border">
        {filtered.length === 0 ? (
          <p className="px-5 py-8 text-center text-sm text-muted">Bu filtrede talep yok</p>
        ) : (
          filtered.map(req => {
            const days = daysSince(req.created_at);
            const overdue = days > 30 && !['resolved', 'rejected', 'cancelled'].includes(req.status);
            const statusInfo = STATUS_LABELS[req.status] ?? { label: req.status, color: 'bg-zinc-100 text-zinc-500' };

            return (
              <div key={req.id}>
                <button
                  onClick={() => setSelected(selected === req.id ? null : req.id)}
                  className="flex w-full items-start gap-4 px-5 py-4 text-left hover:bg-black/[0.02]"
                >
                  <div className="flex-1 min-w-0">
                    <div className="flex flex-wrap items-center gap-2">
                      <span className={`inline-flex rounded-full px-2 py-0.5 text-[10px] font-[700] ${statusInfo.color}`}>
                        {statusInfo.label}
                      </span>
                      <span className="text-xs font-[700] text-textStrong">
                        {requestTypeLabels[req.request_type] ?? req.request_type}
                      </span>
                      {overdue && (
                        <span className="inline-flex items-center gap-1 rounded-full bg-red-50 px-2 py-0.5 text-[10px] font-[700] text-red-600">
                          ⚠️ {days} gün — SLA aşıldı!
                        </span>
                      )}
                      {!overdue && <span className="text-[10px] text-muted">{days}g önce</span>}
                    </div>
                    <p className="mt-0.5 text-xs text-muted">
                      {req.user_profiles?.display_name ?? '—'} · {req.user_profiles?.email ?? req.id.slice(0, 8)}
                    </p>
                    {req.details && <p className="mt-1 line-clamp-1 text-xs text-muted">{req.details}</p>}
                  </div>
                  <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" className={`mt-1 shrink-0 text-muted transition-transform ${selected === req.id ? 'rotate-180' : ''}`}>
                    <polyline points="6 9 12 15 18 9" />
                  </svg>
                </button>

                {selected === req.id && (
                  <div className="bg-zinc-50 px-5 py-3">
                    <p className="mb-2 text-xs font-[700] text-muted">Durum Güncelle</p>
                    <div className="flex flex-wrap gap-2">
                      {STATUS_OPTIONS.map(opt => (
                        <button key={opt.value} disabled={isPending || req.status === opt.value}
                          onClick={() => updateStatus(req.id, opt.value)}
                          className={`rounded-lg px-3 py-1.5 text-xs font-[700] ${opt.color} disabled:opacity-40`}>
                          {opt.label}
                        </button>
                      ))}
                      <a href={req.user_profiles?.email ? `mailto:${req.user_profiles.email}?subject=DSAR Yanıtı — ${requestTypeLabels[req.request_type] ?? req.request_type}` : '#'}
                        className="rounded-lg border border-border px-3 py-1.5 text-xs font-[700] text-muted hover:text-textStrong">
                        E-posta Gönder
                      </a>
                    </div>
                    <p className="mt-2 text-[10px] text-muted">
                      Talep {new Date(req.created_at).toLocaleDateString('tr-TR')} tarihinde oluşturuldu ·
                      Son güncelleme: {new Date(req.updated_at).toLocaleDateString('tr-TR')}
                    </p>
                  </div>
                )}
              </div>
            );
          })
        )}
      </div>
    </div>
  );
}
