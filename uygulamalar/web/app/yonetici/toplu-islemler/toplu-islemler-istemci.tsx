'use client';

import { useState, useTransition } from 'react';
import { useRouter } from 'next/navigation';

interface PendingBusiness {
  id: string; name: string; city: string; status: string; created_at: string;
  user_profiles: { display_name: string; email: string } | null;
}

interface FlaggedReview {
  id: string; content: string; rating: number; created_at: string;
  businesses: { name: string } | null;
  user_profiles: { display_name: string } | null;
}

interface SuspiciousUser {
  id: string; display_name: string; email: string; created_at: string;
  review_count?: number; flag_count?: number;
}

interface BulkOpLog {
  id: string; op_type: string; count: number; action: string; created_at: string; operator: string;
}

async function bulkModerateBusinesses(ids: string[], action: 'approve' | 'reject') {
  await fetch('/sunucu/yonetici/toplu-islemler', {
    method: 'PATCH',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ type: 'businesses', ids, action }),
  });
}

async function bulkModerateReviews(ids: string[], action: 'approve' | 'remove') {
  await fetch('/sunucu/yonetici/toplu-islemler', {
    method: 'PATCH',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ type: 'reviews', ids, action }),
  });
}

async function bulkModerateUsers(ids: string[], action: 'ban' | 'warn' | 'clear') {
  await fetch('/sunucu/yonetici/toplu-islemler', {
    method: 'PATCH',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ type: 'users', ids, action }),
  });
}

type TabType = 'businesses' | 'reviews' | 'users' | 'history';

export function TopluIslemlerIstemci({
  pendingBusinesses,
  flaggedReviews,
  suspiciousUsers = [],
  opHistory = [],
}: {
  pendingBusinesses: PendingBusiness[];
  flaggedReviews: FlaggedReview[];
  suspiciousUsers?: SuspiciousUser[];
  opHistory?: BulkOpLog[];
}) {
  const router = useRouter();
  const [isPending, startTransition] = useTransition();
  const [tab, setTab] = useState<TabType>('businesses');
  const [selectedBiz, setSelectedBiz] = useState<Set<string>>(new Set());
  const [selectedRev, setSelectedRev] = useState<Set<string>>(new Set());
  const [selectedUsers, setSelectedUsers] = useState<Set<string>>(new Set());
  const [feedback, setFeedback] = useState('');
  const [showPreview, setShowPreview] = useState(false);
  const [pendingAction, setPendingAction] = useState<{ type: string; ids: string[]; action: string } | null>(null);

  const toggleBiz = (id: string) =>
    setSelectedBiz(prev => { const s = new Set(prev); s.has(id) ? s.delete(id) : s.add(id); return s; });
  const toggleAllBiz = () =>
    setSelectedBiz(prev => prev.size === pendingBusinesses.length ? new Set() : new Set(pendingBusinesses.map(b => b.id)));

  const toggleRev = (id: string) =>
    setSelectedRev(prev => { const s = new Set(prev); s.has(id) ? s.delete(id) : s.add(id); return s; });
  const toggleAllRev = () =>
    setSelectedRev(prev => prev.size === flaggedReviews.length ? new Set() : new Set(flaggedReviews.map(r => r.id)));

  const toggleUser = (id: string) =>
    setSelectedUsers(prev => { const s = new Set(prev); s.has(id) ? s.delete(id) : s.add(id); return s; });
  const toggleAllUsers = () =>
    setSelectedUsers(prev => prev.size === suspiciousUsers.length ? new Set() : new Set(suspiciousUsers.map(u => u.id)));

  const requestBizAction = (action: 'approve' | 'reject') => {
    if (selectedBiz.size === 0) return;
    setPendingAction({ type: 'businesses', ids: [...selectedBiz], action });
    setShowPreview(true);
  };

  const requestRevAction = (action: 'approve' | 'remove') => {
    if (selectedRev.size === 0) return;
    setPendingAction({ type: 'reviews', ids: [...selectedRev], action });
    setShowPreview(true);
  };

  const requestUserAction = (action: 'ban' | 'warn' | 'clear') => {
    if (selectedUsers.size === 0) return;
    setPendingAction({ type: 'users', ids: [...selectedUsers], action });
    setShowPreview(true);
  };

  const confirmAction = () => {
    if (!pendingAction) return;
    setShowPreview(false);
    startTransition(async () => {
      if (pendingAction.type === 'businesses') {
        await bulkModerateBusinesses(pendingAction.ids, pendingAction.action as 'approve' | 'reject');
        setSelectedBiz(new Set());
        setFeedback(`${pendingAction.ids.length} işletme ${pendingAction.action === 'approve' ? 'onaylandı' : 'reddedildi'}`);
      } else if (pendingAction.type === 'reviews') {
        await bulkModerateReviews(pendingAction.ids, pendingAction.action as 'approve' | 'remove');
        setSelectedRev(new Set());
        setFeedback(`${pendingAction.ids.length} yorum ${pendingAction.action === 'approve' ? 'onaylandı' : 'kaldırıldı'}`);
      } else if (pendingAction.type === 'users') {
        await bulkModerateUsers(pendingAction.ids, pendingAction.action as 'ban' | 'warn' | 'clear');
        setSelectedUsers(new Set());
        const actionLabel = pendingAction.action === 'ban' ? 'yasaklandı' : pendingAction.action === 'warn' ? 'uyarıldı' : 'temizlendi';
        setFeedback(`${pendingAction.ids.length} kullanıcı ${actionLabel}`);
      }
      setPendingAction(null);
      router.refresh();
    });
  };

  const TABS: { key: TabType; label: string; count: number }[] = [
    { key: 'businesses', label: 'İşletmeler', count: pendingBusinesses.length },
    { key: 'reviews', label: 'Yorumlar', count: flaggedReviews.length },
    { key: 'users', label: 'Kullanıcılar', count: suspiciousUsers.length },
    { key: 'history', label: 'Geçmiş', count: opHistory.length },
  ];

  return (
    <div className="flex flex-col gap-4">
      {/* Feedback */}
      {feedback && (
        <div className="flex items-center justify-between rounded-xl bg-green-50 px-4 py-3">
          <span className="text-sm font-[700] text-green-700">✓ {feedback}</span>
          <button onClick={() => setFeedback('')} className="text-green-600 hover:text-green-800">✕</button>
        </div>
      )}

      {/* Preview confirmation modal */}
      {showPreview && pendingAction && (
        <div className="rounded-2xl border-2 border-primary bg-primary/5 p-5">
          <p className="mb-2 font-[800] text-textStrong">İşlem Onayı</p>
          <p className="mb-4 text-sm text-muted">
            <strong>{pendingAction.ids.length} {pendingAction.type === 'businesses' ? 'işletme' : pendingAction.type === 'reviews' ? 'yorum' : 'kullanıcı'}</strong> üzerinde{' '}
            <strong className={pendingAction.action === 'approve' || pendingAction.action === 'clear' ? 'text-green-700' : 'text-red-700'}>
&ldquo;{pendingAction.action === 'approve' ? 'Onayla' : pendingAction.action === 'reject' ? 'Reddet' : pendingAction.action === 'remove' ? 'Kaldır' : pendingAction.action === 'ban' ? 'Yasakla' : pendingAction.action === 'warn' ? 'Uyar' : 'Temizle'}&rdquo;
            </strong>{' '}
            işlemi yapılacak. Bu işlem geri alınamaz.
          </p>
          <div className="flex gap-2">
            <button
              disabled={isPending}
              onClick={confirmAction}
              className={`rounded-lg px-4 py-2 text-sm font-[800] text-white disabled:opacity-50 ${pendingAction.action === 'approve' || pendingAction.action === 'clear' ? 'bg-green-600 hover:bg-green-700' : 'bg-red-600 hover:bg-red-700'}`}
            >
              {isPending ? 'İşleniyor…' : 'Onayla ve Uygula'}
            </button>
            <button onClick={() => { setShowPreview(false); setPendingAction(null); }}
              className="rounded-lg border border-border px-4 py-2 text-sm font-[700] text-muted hover:text-textStrong">
              İptal
            </button>
          </div>
        </div>
      )}

      {/* Tabs */}
      <div className="flex gap-1 rounded-xl bg-zinc-100 p-1 dark:bg-zinc-800">
        {TABS.map(t => (
          <button key={t.key} onClick={() => setTab(t.key)}
            className={`flex-1 rounded-lg py-1.5 text-xs font-[700] transition-colors ${tab === t.key ? 'bg-white text-textStrong shadow dark:bg-zinc-700' : 'text-muted'}`}>
            {t.label}{t.count > 0 ? ` (${t.count})` : ''}
          </button>
        ))}
      </div>

      {/* Businesses Tab */}
      {tab === 'businesses' && (
        <div className="rounded-xl border border-border overflow-hidden">
          <div className="flex items-center justify-between border-b border-border bg-zinc-50 px-4 py-2 dark:bg-zinc-900/30">
            <div className="flex items-center gap-3">
              <input type="checkbox"
                checked={selectedBiz.size === pendingBusinesses.length && pendingBusinesses.length > 0}
                onChange={toggleAllBiz} className="rounded" />
              <span className="text-xs font-[700] text-muted">{selectedBiz.size > 0 ? `${selectedBiz.size} seçili` : 'Tümünü Seç'}</span>
            </div>
            {selectedBiz.size > 0 && (
              <div className="flex gap-2">
                <button disabled={isPending} onClick={() => requestBizAction('approve')}
                  className="rounded-lg bg-green-600 px-3 py-1 text-xs font-[800] text-white hover:bg-green-700 disabled:opacity-50">
                  Onayla ({selectedBiz.size})
                </button>
                <button disabled={isPending} onClick={() => requestBizAction('reject')}
                  className="rounded-lg bg-red-600 px-3 py-1 text-xs font-[800] text-white hover:bg-red-700 disabled:opacity-50">
                  Reddet ({selectedBiz.size})
                </button>
              </div>
            )}
          </div>
          {pendingBusinesses.length === 0 ? (
            <p className="py-8 text-center text-sm text-muted">Bekleyen işletme yok</p>
          ) : (
            <table className="w-full text-sm">
              <tbody className="divide-y divide-border">
                {pendingBusinesses.map(biz => (
                  <tr key={biz.id} className={`hover:bg-black/[0.02] ${selectedBiz.has(biz.id) ? 'bg-primary/5' : ''}`}>
                    <td className="w-10 px-4 py-3"><input type="checkbox" checked={selectedBiz.has(biz.id)} onChange={() => toggleBiz(biz.id)} /></td>
                    <td className="px-4 py-3">
                      <p className="font-[700] text-textStrong">{biz.name}</p>
                      <p className="text-xs text-muted">{biz.city} · {biz.user_profiles?.email ?? '—'}</p>
                    </td>
                    <td className="px-4 py-3 text-xs text-muted">{new Date(biz.created_at).toLocaleDateString('tr-TR')}</td>
                    <td className="px-4 py-3">
                      <div className="flex gap-1">
                        <button disabled={isPending} onClick={() => { setSelectedBiz(new Set([biz.id])); requestBizAction('approve'); }}
                          className="rounded bg-green-100 px-2 py-1 text-[10px] font-[800] text-green-700 hover:bg-green-200">✓</button>
                        <button disabled={isPending} onClick={() => { setSelectedBiz(new Set([biz.id])); requestBizAction('reject'); }}
                          className="rounded bg-red-100 px-2 py-1 text-[10px] font-[800] text-red-700 hover:bg-red-200">✕</button>
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          )}
        </div>
      )}

      {/* Reviews Tab */}
      {tab === 'reviews' && (
        <div className="rounded-xl border border-border overflow-hidden">
          <div className="flex items-center justify-between border-b border-border bg-zinc-50 px-4 py-2 dark:bg-zinc-900/30">
            <div className="flex items-center gap-3">
              <input type="checkbox"
                checked={selectedRev.size === flaggedReviews.length && flaggedReviews.length > 0}
                onChange={toggleAllRev} className="rounded" />
              <span className="text-xs font-[700] text-muted">{selectedRev.size > 0 ? `${selectedRev.size} seçili` : 'Tümünü Seç'}</span>
            </div>
            {selectedRev.size > 0 && (
              <div className="flex gap-2">
                <button disabled={isPending} onClick={() => requestRevAction('approve')}
                  className="rounded-lg bg-green-600 px-3 py-1 text-xs font-[800] text-white hover:bg-green-700 disabled:opacity-50">
                  Onayla ({selectedRev.size})
                </button>
                <button disabled={isPending} onClick={() => requestRevAction('remove')}
                  className="rounded-lg bg-red-600 px-3 py-1 text-xs font-[800] text-white hover:bg-red-700 disabled:opacity-50">
                  Kaldır ({selectedRev.size})
                </button>
              </div>
            )}
          </div>
          {flaggedReviews.length === 0 ? (
            <p className="py-8 text-center text-sm text-muted">Şikayet edilen yorum yok</p>
          ) : (
            <div className="divide-y divide-border">
              {flaggedReviews.map(review => (
                <div key={review.id} className={`flex gap-3 px-4 py-3 ${selectedRev.has(review.id) ? 'bg-primary/5' : 'hover:bg-black/[0.02]'}`}>
                  <input type="checkbox" checked={selectedRev.has(review.id)} onChange={() => toggleRev(review.id)} className="mt-1" />
                  <div className="flex-1 min-w-0">
                    <div className="flex items-center gap-2">
                      <span className="text-xs font-[700] text-textStrong">{review.businesses?.name ?? '—'}</span>
                      <span className="text-xs text-yellow-500">{'★'.repeat(review.rating)}</span>
                    </div>
                    <p className="mt-0.5 line-clamp-2 text-xs text-muted">{review.content}</p>
                    <p className="text-[10px] text-muted">{review.user_profiles?.display_name ?? '—'} · {new Date(review.created_at).toLocaleDateString('tr-TR')}</p>
                  </div>
                </div>
              ))}
            </div>
          )}
        </div>
      )}

      {/* Users Tab */}
      {tab === 'users' && (
        <div className="rounded-xl border border-border overflow-hidden">
          <div className="flex items-center justify-between border-b border-border bg-zinc-50 px-4 py-2 dark:bg-zinc-900/30">
            <div className="flex items-center gap-3">
              <input type="checkbox"
                checked={selectedUsers.size === suspiciousUsers.length && suspiciousUsers.length > 0}
                onChange={toggleAllUsers} className="rounded" />
              <span className="text-xs font-[700] text-muted">{selectedUsers.size > 0 ? `${selectedUsers.size} seçili` : 'Tümünü Seç'}</span>
            </div>
            {selectedUsers.size > 0 && (
              <div className="flex gap-2">
                <button disabled={isPending} onClick={() => requestUserAction('warn')}
                  className="rounded-lg bg-yellow-500 px-3 py-1 text-xs font-[800] text-white hover:bg-yellow-600 disabled:opacity-50">
                  Uyar ({selectedUsers.size})
                </button>
                <button disabled={isPending} onClick={() => requestUserAction('ban')}
                  className="rounded-lg bg-red-600 px-3 py-1 text-xs font-[800] text-white hover:bg-red-700 disabled:opacity-50">
                  Yasakla ({selectedUsers.size})
                </button>
                <button disabled={isPending} onClick={() => requestUserAction('clear')}
                  className="rounded-lg bg-zinc-500 px-3 py-1 text-xs font-[800] text-white hover:bg-zinc-600 disabled:opacity-50">
                  Temizle ({selectedUsers.size})
                </button>
              </div>
            )}
          </div>
          {suspiciousUsers.length === 0 ? (
            <p className="py-8 text-center text-sm text-muted">Şüpheli kullanıcı tespit edilmedi</p>
          ) : (
            <table className="w-full text-sm">
              <thead>
                <tr className="border-b border-border text-left">
                  <th className="w-10 px-4 py-3" />
                  <th className="px-4 py-3 text-[11px] font-[800] uppercase tracking-wide text-muted">Kullanıcı</th>
                  <th className="px-4 py-3 text-[11px] font-[800] uppercase tracking-wide text-muted">Yorum</th>
                  <th className="px-4 py-3 text-[11px] font-[800] uppercase tracking-wide text-muted">Şikayet</th>
                  <th className="px-4 py-3 text-[11px] font-[800] uppercase tracking-wide text-muted">Kayıt</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-border">
                {suspiciousUsers.map(user => (
                  <tr key={user.id} className={`hover:bg-black/[0.02] ${selectedUsers.has(user.id) ? 'bg-primary/5' : ''}`}>
                    <td className="w-10 px-4 py-3"><input type="checkbox" checked={selectedUsers.has(user.id)} onChange={() => toggleUser(user.id)} /></td>
                    <td className="px-4 py-3">
                      <p className="font-[700] text-textStrong">{user.display_name}</p>
                      <p className="text-xs text-muted">{user.email}</p>
                    </td>
                    <td className="px-4 py-3 text-xs">{user.review_count ?? 0}</td>
                    <td className="px-4 py-3">
                      {(user.flag_count ?? 0) > 0 ? (
                        <span className="inline-flex rounded-full bg-red-50 px-2 py-0.5 text-[10px] font-[700] text-red-700">
                          {user.flag_count} şikayet
                        </span>
                      ) : <span className="text-xs text-muted">—</span>}
                    </td>
                    <td className="px-4 py-3 text-xs text-muted">{new Date(user.created_at).toLocaleDateString('tr-TR')}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          )}
        </div>
      )}

      {/* History Tab */}
      {tab === 'history' && (
        <div className="rounded-xl border border-border overflow-hidden">
          {opHistory.length === 0 ? (
            <p className="py-8 text-center text-sm text-muted">Henüz işlem geçmişi yok</p>
          ) : (
            <table className="w-full text-sm">
              <thead>
                <tr className="border-b border-border text-left bg-zinc-50 dark:bg-zinc-900/40">
                  <th className="px-5 py-3 text-[11px] font-[800] uppercase tracking-wide text-muted">İşlem Tipi</th>
                  <th className="px-5 py-3 text-[11px] font-[800] uppercase tracking-wide text-muted">İşlem</th>
                  <th className="px-5 py-3 text-[11px] font-[800] uppercase tracking-wide text-muted">Sayı</th>
                  <th className="px-5 py-3 text-[11px] font-[800] uppercase tracking-wide text-muted">Operatör</th>
                  <th className="px-5 py-3 text-[11px] font-[800] uppercase tracking-wide text-muted">Tarih</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-border">
                {opHistory.map(log => (
                  <tr key={log.id} className="hover:bg-black/[0.02]">
                    <td className="px-5 py-3">
                      <span className={`inline-flex rounded-full px-2 py-0.5 text-[10px] font-[700] ${log.op_type === 'businesses' ? 'bg-blue-50 text-blue-700' : log.op_type === 'reviews' ? 'bg-purple-50 text-purple-700' : 'bg-orange-50 text-orange-700'}`}>
                        {log.op_type === 'businesses' ? 'İşletme' : log.op_type === 'reviews' ? 'Yorum' : 'Kullanıcı'}
                      </span>
                    </td>
                    <td className="px-5 py-3 text-xs text-textStrong">{log.action}</td>
                    <td className="px-5 py-3 font-[700]">{log.count}</td>
                    <td className="px-5 py-3 text-xs text-muted">{log.operator}</td>
                    <td className="px-5 py-3 text-xs text-muted">{new Date(log.created_at).toLocaleDateString('tr-TR')}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          )}
        </div>
      )}
    </div>
  );
}
