'use client';

import { useState, useTransition } from 'react';
import { useRouter } from 'next/navigation';
import { PanelActionButton } from '@/src/ui/bilesenler/panel-eylem-dugmesi';
import { IsletmeSatirEylemleri } from './isletme-satir-eylemleri';
import { getPublicBusinessHref, type IsletmeSatiri } from './isletmeler-yardimcilari';

async function topluGuncelle(ids: string[], action: 'approve' | 'reject') {
  const res = await fetch('/sunucu/yonetici/toplu-islemler', {
    method: 'PATCH',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ type: 'businesses', ids, action }),
  });
  if (!res.ok) throw new Error('İşlem başarısız');
}

export function IsletmelerTablosu({ rows }: { rows: IsletmeSatiri[] }) {
  const router = useRouter();
  const [selected, setSelected] = useState<Set<string>>(new Set());
  const [isPending, startTransition] = useTransition();
  const [error, setError] = useState<string | null>(null);

  const hepsiSecili = rows.length > 0 && rows.every((r) => selected.has(r.id));

  function toggleAll() {
    setSelected(hepsiSecili ? new Set() : new Set(rows.map((r) => r.id)));
  }
  function toggleOne(id: string) {
    setSelected((prev) => {
      const next = new Set(prev);
      if (next.has(id)) next.delete(id); else next.add(id);
      return next;
    });
  }
  function bulkAction(action: 'approve' | 'reject') {
    setError(null);
    startTransition(async () => {
      try {
        await topluGuncelle(Array.from(selected), action);
        setSelected(new Set());
        router.refresh();
      } catch {
        setError('Toplu işlem başarısız oldu.');
      }
    });
  }

  return (
    <div id="toplu-islemler" className="flex flex-col gap-3 scroll-mt-20">
      {selected.size > 0 && (
        <div className="flex flex-wrap items-center justify-between gap-2 rounded-xl border border-primary/20 bg-primary/5 px-4 py-2.5">
          <p className="text-xs font-extrabold text-textStrong">{selected.size} işletme seçildi</p>
          <div className="flex items-center gap-2">
            {error && <span className="text-[10px] font-bold text-red-600">{error}</span>}
            <PanelActionButton variant="secondary" loading={isPending} onClick={() => bulkAction('approve')} className="py-1 text-xs">Toplu Aktif Et</PanelActionButton>
            <PanelActionButton variant="danger" loading={isPending} onClick={() => bulkAction('reject')} className="py-1 text-xs">Toplu Pasif Et</PanelActionButton>
          </div>
        </div>
      )}
      <div className="overflow-x-auto">
        <table className="w-full text-sm">
          <thead>
            <tr className="border-b border-border text-left">
              <th className="px-4 py-3">
                <input type="checkbox" checked={hepsiSecili} onChange={toggleAll} disabled={rows.length === 0} className="h-4 w-4 rounded border-border" />
              </th>
              <th className="px-5 py-3 text-[11px] font-extrabold uppercase tracking-wide text-muted">İşletme</th>
              <th className="px-5 py-3 text-[11px] font-extrabold uppercase tracking-wide text-muted">Kategori</th>
              <th className="px-5 py-3 text-[11px] font-extrabold uppercase tracking-wide text-muted">Konum</th>
              <th className="px-5 py-3 text-[11px] font-extrabold uppercase tracking-wide text-muted">Sahip</th>
              <th className="px-5 py-3 text-[11px] font-extrabold uppercase tracking-wide text-muted">Durum</th>
              <th className="px-5 py-3 text-[11px] font-extrabold uppercase tracking-wide text-muted">Tarih</th>
              <th className="px-5 py-3 text-right text-[11px] font-extrabold uppercase tracking-wide text-muted">İşlemler</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-border">
            {rows.map((b) => {
              const publicHref = getPublicBusinessHref(b);
              return (
                <tr key={b.id} className="hover:bg-black/2">
                  <td className="px-4 py-3">
                    <input type="checkbox" checked={selected.has(b.id)} onChange={() => toggleOne(b.id)} className="h-4 w-4 rounded border-border" />
                  </td>
                  <td className="px-5 py-3">
                    <div className="flex items-center gap-2.5">
                      <span className="flex h-9 w-9 shrink-0 items-center justify-center overflow-hidden rounded-lg bg-primary/10 text-xs font-black text-primary">
                        {b.logoUrl ? (
                          // eslint-disable-next-line @next/next/no-img-element
                          <img src={b.logoUrl} alt={b.name} className="h-full w-full object-cover" />
                        ) : (
                          b.name.charAt(0).toUpperCase()
                        )}
                      </span>
                      <div className="min-w-0">
                        <p className="truncate font-bold text-textStrong">{b.name}</p>
                        {b.phone && <p className="text-xs text-muted">{b.phone}</p>}
                      </div>
                    </div>
                  </td>
                  <td className="px-5 py-3 text-muted">{b.category}</td>
                  <td className="px-5 py-3 text-muted">{[b.district, b.city].filter(Boolean).join(', ') || '—'}</td>
                  <td className="px-5 py-3 text-muted">{b.ownerName ?? '—'}</td>
                  <td className="px-5 py-3">
                    <div className="flex flex-wrap items-center gap-1.5">
                      <span className={`rounded-full px-2 py-0.5 text-[11px] font-extrabold ${b.is_active ? 'bg-green-50 text-green-700' : 'bg-zinc-100 text-zinc-500'}`}>
                        {b.is_active ? 'Aktif' : 'Pasif'}
                      </span>
                      <span className={`rounded-full px-2 py-0.5 text-[11px] font-extrabold ${b.is_verified ? 'bg-blue-50 text-blue-700' : 'bg-amber-50 text-amber-700'}`}>
                        {b.is_verified ? 'Doğrulandı' : 'Doğrulanmadı'}
                      </span>
                    </div>
                  </td>
                  <td className="px-5 py-3 text-xs text-muted">{new Date(b.created_at).toLocaleDateString('tr-TR')}</td>
                  <td className="px-5 py-3">
                    <IsletmeSatirEylemleri id={b.id} isActive={b.is_active} publicHref={publicHref} />
                  </td>
                </tr>
              );
            })}
          </tbody>
        </table>
      </div>
    </div>
  );
}
