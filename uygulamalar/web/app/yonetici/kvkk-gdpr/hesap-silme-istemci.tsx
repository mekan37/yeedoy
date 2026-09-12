'use client';

import { useState, useTransition } from 'react';
import { useRouter } from 'next/navigation';

interface AccountDeletionRequest {
  id: string;
  user_id: string;
  email: string | null;
  display_name: string | null;
  reason: string | null;
  status: string;
  requested_at: string;
  completed_at: string | null;
}

const STATUS_LABELS: Record<string, { label: string; color: string }> = {
  requested: { label: 'Bekliyor', color: 'bg-yellow-50 text-yellow-700' },
  in_review: { label: 'İşlemde', color: 'bg-blue-50 text-blue-700' },
  completed: { label: 'Tamamlandı', color: 'bg-green-50 text-green-700' },
  rejected: { label: 'Reddedildi', color: 'bg-red-50 text-red-700' },
  cancelled: { label: 'İptal', color: 'bg-zinc-100 text-zinc-500' },
};

export function HesapSilmeYonetimi({ requests }: { requests: AccountDeletionRequest[] }) {
  const router = useRouter();
  const [isPending, startTransition] = useTransition();
  const [filter, setFilter] = useState('all');
  const [selected, setSelected] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);

  const filtered = filter === 'all' ? requests : requests.filter((r) => r.status === filter);

  const review = (id: string, status: 'in_review' | 'rejected' | 'cancelled') => {
    setError(null);
    startTransition(async () => {
      const res = await fetch('/sunucu/yonetici/hesap-silme-talepleri', {
        method: 'PATCH',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ id, status }),
      });
      if (!res.ok) {
        setError('İşlem başarısız oldu.');
        return;
      }
      setSelected(null);
      router.refresh();
    });
  };

  const execute = (req: AccountDeletionRequest) => {
    const confirmed = window.confirm(
      `"${req.display_name ?? req.email ?? req.user_id}" kullanıcısının hesabı ve tüm verisi KALICI OLARAK silinecek. Bu işlem geri alınamaz. Devam edilsin mi?`,
    );
    if (!confirmed) return;

    setError(null);
    startTransition(async () => {
      const res = await fetch('/sunucu/yonetici/hesap-silme-talepleri', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ id: req.id }),
      });
      if (!res.ok) {
        const body = await res.json().catch(() => ({}));
        setError(body.error === 'auth_delete_failed'
          ? 'Uygulama verisi silindi ama hesap kaydı silinemedi — tekrar deneyin.'
          : 'İşlem başarısız oldu.');
        return;
      }
      setSelected(null);
      router.refresh();
    });
  };

  const daysSince = (dateStr: string) => Math.floor((Date.now() - new Date(dateStr).getTime()) / 86400000);

  return (
    <div className="flex flex-col">
      <div className="flex gap-2 border-b border-border px-5 py-3">
        {['all', 'requested', 'in_review', 'completed'].map((f) => (
          <button
            key={f}
            onClick={() => setFilter(f)}
            className={`rounded-lg px-3 py-1 text-xs font-bold transition-colors ${filter === f ? 'bg-primary text-white' : 'text-muted hover:text-textStrong'}`}
          >
            {f === 'all' ? `Tümü (${requests.length})` :
              f === 'requested' ? `Bekleyen (${requests.filter((r) => r.status === 'requested').length})` :
                STATUS_LABELS[f]?.label ?? f}
          </button>
        ))}
      </div>

      {error && (
        <div className="mx-5 mt-3 rounded-lg border border-red-200 bg-red-50 px-3 py-2 text-xs font-bold text-danger">
          {error}
        </div>
      )}

      <div className="divide-y divide-border">
        {filtered.length === 0 ? (
          <p className="px-5 py-8 text-center text-sm text-muted">Bu filtrede talep yok</p>
        ) : (
          filtered.map((req) => {
            const days = daysSince(req.requested_at);
            const overdue = days > 30 && ['requested', 'in_review'].includes(req.status);
            const statusInfo = STATUS_LABELS[req.status] ?? { label: req.status, color: 'bg-zinc-100 text-zinc-500' };
            const actionable = req.status === 'requested' || req.status === 'in_review';

            return (
              <div key={req.id}>
                <button
                  onClick={() => setSelected(selected === req.id ? null : req.id)}
                  className="flex w-full items-start gap-4 px-5 py-4 text-left hover:bg-black/2"
                >
                  <div className="min-w-0 flex-1">
                    <div className="flex flex-wrap items-center gap-2">
                      <span className={`inline-flex rounded-full px-2 py-0.5 text-[10px] font-bold ${statusInfo.color}`}>
                        {statusInfo.label}
                      </span>
                      {overdue && (
                        <span className="inline-flex items-center gap-1 rounded-full bg-red-50 px-2 py-0.5 text-[10px] font-bold text-red-600">
                          ⚠️ {days} gün — SLA aşıldı!
                        </span>
                      )}
                      {!overdue && <span className="text-[10px] text-muted">{days}g önce</span>}
                    </div>
                    <p className="mt-0.5 text-xs text-muted">
                      {req.display_name ?? '—'} · {req.email ?? req.user_id.slice(0, 8)}
                    </p>
                    {req.reason && <p className="mt-1 line-clamp-1 text-xs text-muted">{req.reason}</p>}
                  </div>
                  <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" className={`mt-1 shrink-0 text-muted transition-transform ${selected === req.id ? 'rotate-180' : ''}`}>
                    <polyline points="6 9 12 15 18 9" />
                  </svg>
                </button>

                {selected === req.id && (
                  <div className="bg-zinc-50 px-5 py-3">
                    {actionable ? (
                      <>
                        <p className="mb-2 text-xs font-bold text-muted">İşlem</p>
                        <div className="flex flex-wrap gap-2">
                          {req.status === 'requested' && (
                            <button
                              type="button"
                              disabled={isPending}
                              onClick={() => review(req.id, 'in_review')}
                              className="rounded-lg bg-blue-100 px-3 py-1.5 text-xs font-bold text-blue-700 disabled:opacity-40"
                            >
                              İşleme Al
                            </button>
                          )}
                          <button
                            type="button"
                            disabled={isPending}
                            onClick={() => execute(req)}
                            className="rounded-lg bg-red-600 px-3 py-1.5 text-xs font-bold text-white disabled:opacity-40"
                          >
                            Kalıcı Sil (Onayla)
                          </button>
                          <button
                            type="button"
                            disabled={isPending}
                            onClick={() => review(req.id, 'rejected')}
                            className="rounded-lg bg-red-50 px-3 py-1.5 text-xs font-bold text-red-700 disabled:opacity-40"
                          >
                            Reddet
                          </button>
                        </div>
                      </>
                    ) : (
                      <p className="text-xs text-muted">
                        {req.status === 'completed'
                          ? `Hesap ${req.completed_at ? new Date(req.completed_at).toLocaleDateString('tr-TR') : ''} tarihinde kalıcı olarak silindi.`
                          : 'Bu talep üzerinde başka işlem yapılamaz.'}
                      </p>
                    )}
                    <p className="mt-2 text-[10px] text-muted">
                      Talep {new Date(req.requested_at).toLocaleDateString('tr-TR')} tarihinde oluşturuldu.
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
