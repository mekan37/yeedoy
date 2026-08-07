'use client';

import { useState } from 'react';
import Image from 'next/image';
import type { CokluSubeBranch } from '../coklu-sube-yardimcilari';
import { filterBranches, type SubeTab } from '../coklu-sube-yardimcilari';

export function SubeTablosu({
  branches,
  onRemove,
  onReorder,
  reorderMode,
}: {
  branches: CokluSubeBranch[];
  onRemove: (businessId: string) => void;
  onReorder: (businessId: string, newSortOrder: number) => void;
  reorderMode: boolean;
}) {
  const [tab, setTab] = useState<SubeTab>('tumu');
  const [search, setSearch] = useState('');
  const [draggedId, setDraggedId] = useState<string | null>(null);

  const visible = filterBranches(branches, search, tab);

  const tabs: Array<{ id: SubeTab; label: string }> = [
    { id: 'tumu', label: `Tümü (${branches.length})` },
    { id: 'aktif', label: `Aktif (${branches.filter((b) => b.is_active).length})` },
    { id: 'pasif', label: `Pasif (${branches.filter((b) => !b.is_active).length})` },
  ];

  function handleDrop(targetBranch: CokluSubeBranch) {
    if (!draggedId || draggedId === targetBranch.business_id) {
      setDraggedId(null);
      return;
    }
    onReorder(draggedId, targetBranch.chain_sort_order);
    setDraggedId(null);
  }

  return (
    <div className="rounded-2xl border border-border bg-card">
      <div className="flex flex-wrap items-center justify-between gap-3 border-b border-border p-4">
        <div className="flex flex-wrap gap-1">
          {tabs.map((t) => (
            <button
              key={t.id}
              type="button"
              onClick={() => setTab(t.id)}
              className={`rounded-lg px-3 py-1.5 text-xs font-bold cursor-pointer ${
                tab === t.id ? 'bg-primary text-white' : 'text-muted hover:bg-bg'
              }`}
            >
              {t.label}
            </button>
          ))}
        </div>
        <input
          value={search}
          onChange={(e) => setSearch(e.target.value)}
          placeholder="Şube adı, şehir veya adres ara..."
          className="min-w-[200px] flex-1 rounded-xl border border-border bg-bg px-3 py-2 text-sm text-textStrong placeholder:text-muted focus:outline-hidden focus:ring-2 focus:ring-primary/30"
        />
      </div>

      {reorderMode && (
        <div className="border-b border-border bg-primary/5 px-4 py-2 text-xs font-bold text-primary">
          Sıralama modu açık — satırları sürükleyerek şube sırasını değiştirin.
        </div>
      )}

      {visible.length === 0 ? (
        <div className="flex flex-col items-center gap-2 py-12 text-center">
          <p className="text-sm font-bold text-textStrong">Bu sekmede şube yok</p>
        </div>
      ) : (
        <div className="overflow-x-auto">
          <table className="w-full min-w-[720px] text-sm">
            <thead>
              <tr className="border-b border-border text-left text-xs font-bold uppercase tracking-wide text-muted">
                {reorderMode && <th className="w-8 px-3 py-2"></th>}
                <th className="px-3 py-2">Şube Adı</th>
                <th className="px-3 py-2">Şehir</th>
                <th className="px-3 py-2">Durum</th>
                <th className="px-3 py-2">Görüntülenme</th>
                <th className="px-3 py-2">Rezervasyon</th>
                <th className="px-3 py-2">İşlemler</th>
              </tr>
            </thead>
            <tbody>
              {visible.map((branch) => (
                <tr
                  key={branch.business_id}
                  draggable={reorderMode}
                  onDragStart={() => reorderMode && setDraggedId(branch.business_id)}
                  onDragOver={(e) => reorderMode && e.preventDefault()}
                  onDrop={() => reorderMode && handleDrop(branch)}
                  className={`border-b border-border last:border-0 hover:bg-bg/60 ${
                    draggedId === branch.business_id ? 'opacity-40' : ''
                  }`}
                >
                  {reorderMode && (
                    <td className="px-3 py-2 text-muted">
                      <span className="cursor-grab select-none" title="Sürükleyerek sırala">
                        ⠿
                      </span>
                    </td>
                  )}
                  <td className="px-3 py-2">
                    <div className="flex items-center gap-2">
                      {branch.logo_url ? (
                        <Image
                          src={branch.logo_url}
                          alt={branch.name}
                          width={32}
                          height={32}
                          className="h-8 w-8 rounded-lg object-cover"
                          unoptimized
                        />
                      ) : (
                        <div className="flex h-8 w-8 items-center justify-center rounded-lg border border-dashed border-border bg-bg text-[9px] font-bold text-muted">
                          Yok
                        </div>
                      )}
                      <div>
                        <p className="font-bold text-textStrong">
                          {branch.name}
                          {branch.is_main_branch && (
                            <span className="ml-2 rounded-full bg-primary/10 px-2 py-0.5 text-[10px] font-extrabold text-primary">
                              Ana Şube
                            </span>
                          )}
                        </p>
                        {branch.branch_label && <p className="text-xs text-muted">{branch.branch_label}</p>}
                      </div>
                    </div>
                  </td>
                  <td className="px-3 py-2 text-muted">{branch.city ?? '—'}</td>
                  <td className="px-3 py-2">
                    <span
                      className={`rounded-full px-2 py-0.5 text-[11px] font-extrabold ${
                        branch.is_active ? 'bg-green-50 text-green-700' : 'bg-zinc-100 text-zinc-500'
                      }`}
                    >
                      {branch.is_active ? 'Aktif' : 'Pasif'}
                    </span>
                  </td>
                  <td className="px-3 py-2 font-bold text-textStrong">{branch.views.toLocaleString('tr-TR')}</td>
                  <td className="px-3 py-2 font-bold text-textStrong">{branch.reservations.toLocaleString('tr-TR')}</td>
                  <td className="px-3 py-2">
                    <button
                      type="button"
                      onClick={() => {
                        if (confirm(`"${branch.name}" şubesini zincirden çıkarmak istediğinize emin misiniz?`)) {
                          onRemove(branch.business_id);
                        }
                      }}
                      className="rounded-lg border border-red-200 px-2 py-1 text-[11px] font-bold text-red-600 hover:bg-red-50 cursor-pointer"
                    >
                      Zincirden Çıkar
                    </button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </div>
  );
}
