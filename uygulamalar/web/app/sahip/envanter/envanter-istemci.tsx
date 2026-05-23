'use client';

import { useState, useTransition } from 'react';
import { useRouter } from 'next/navigation';

interface StockItem {
  id: string; name: string; is_available: boolean; stock_count: number | null; price: number;
  reorder_threshold?: number | null; supplier?: string | null;
  menus: { id: string; name: string; businesses: { id: string; name: string } | null } | null;
}

export function EnvanterIstemci({
  items,
  alertLevel,
}: {
  items: StockItem[];
  alertLevel: 'critical' | 'warning' | 'none';
}) {
  const router = useRouter();
  const [isPending, startTransition] = useTransition();
  const [editing, setEditing] = useState<string | null>(null);
  const [editVal, setEditVal] = useState('');
  const [editThreshold, setEditThreshold] = useState('');
  const [editSupplier, setEditSupplier] = useState('');
  const [editMode, setEditMode] = useState<'stock' | 'threshold' | 'supplier'>('stock');
  const [search, setSearch] = useState('');
  const [bulkReplenish, setBulkReplenish] = useState(false);
  const [bulkTarget, setBulkTarget] = useState('20');
  const [selected, setSelected] = useState<Set<string>>(new Set());
  const [sortBy, setSortBy] = useState<'name' | 'stock' | 'price'>('stock');

  const filtered = (search
    ? items.filter(i => i.name.toLowerCase().includes(search.toLowerCase()) || (i.supplier ?? '').toLowerCase().includes(search.toLowerCase()))
    : items
  ).sort((a, b) => {
    if (sortBy === 'stock') return (a.stock_count ?? 999) - (b.stock_count ?? 999);
    if (sortBy === 'price') return b.price - a.price;
    return a.name.localeCompare(b.name, 'tr');
  });

  const updateStock = (itemId: string, count: number) => {
    startTransition(async () => {
      await fetch('/sunucu/sahip/envanter', {
        method: 'PATCH',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ itemId, stockCount: count }),
      });
      setEditing(null);
      router.refresh();
    });
  };

  const updateThreshold = (itemId: string, threshold: number) => {
    startTransition(async () => {
      await fetch('/sunucu/sahip/envanter', {
        method: 'PATCH',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ itemId, reorderThreshold: threshold }),
      });
      setEditing(null);
      router.refresh();
    });
  };

  const updateSupplier = (itemId: string, supplier: string) => {
    startTransition(async () => {
      await fetch('/sunucu/sahip/envanter', {
        method: 'PATCH',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ itemId, supplier }),
      });
      setEditing(null);
      router.refresh();
    });
  };

  const toggleAvailability = (itemId: string, current: boolean) => {
    startTransition(async () => {
      await fetch('/sunucu/sahip/envanter', {
        method: 'PATCH',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ itemId, isAvailable: !current }),
      });
      router.refresh();
    });
  };

  const doBulkReplenish = () => {
    const target = parseInt(bulkTarget, 10);
    if (isNaN(target) || target <= 0) return;
    const ids = selected.size > 0 ? Array.from(selected) : filtered.filter(i => (i.stock_count ?? 0) <= 5).map(i => i.id);
    startTransition(async () => {
      await Promise.all(ids.map(id =>
        fetch('/sunucu/sahip/envanter', {
          method: 'PATCH',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ itemId: id, stockCount: target }),
        })
      ));
      setBulkReplenish(false);
      setSelected(new Set());
      router.refresh();
    });
  };

  const exportCsv = () => {
    const rows = [['Ürün', 'Menü', 'İşletme', 'Stok', 'Eşik', 'Tedarikçi', 'Fiyat', 'Müsaitlik']];
    for (const item of items) {
      rows.push([
        item.name,
        item.menus?.name ?? '',
        item.menus?.businesses?.name ?? '',
        String(item.stock_count ?? ''),
        String(item.reorder_threshold ?? ''),
        item.supplier ?? '',
        String(item.price),
        item.is_available ? 'Aktif' : 'Pasif',
      ]);
    }
    const csv = rows.map(r => r.map(c => `"${c.replace(/"/g, '""')}"`).join(',')).join('\n');
    const blob = new Blob(['﻿' + csv], { type: 'text/csv;charset=utf-8' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a'); a.href = url; a.download = 'envanter.csv'; a.click();
    URL.revokeObjectURL(url);
  };

  const toggleSelect = (id: string) =>
    setSelected(prev => { const s = new Set(prev); s.has(id) ? s.delete(id) : s.add(id); return s; });

  const openEdit = (item: StockItem, mode: 'stock' | 'threshold' | 'supplier') => {
    setEditing(item.id);
    setEditMode(mode);
    if (mode === 'stock') setEditVal(String(item.stock_count ?? ''));
    else if (mode === 'threshold') setEditThreshold(String(item.reorder_threshold ?? ''));
    else setEditSupplier(item.supplier ?? '');
  };

  if (items.length === 0) return (
    <p className="px-5 py-8 text-center text-sm text-muted">Bu kategoride ürün yok</p>
  );

  const belowThreshold = filtered.filter(i => (i.reorder_threshold ?? 0) > 0 && (i.stock_count ?? 0) <= (i.reorder_threshold ?? 0));

  return (
    <div>
      {alertLevel === 'none' && (
        <div className="flex flex-wrap items-center gap-2 border-b border-border px-5 py-3">
          <input
            value={search}
            onChange={e => setSearch(e.target.value)}
            placeholder="Ürün veya tedarikçi ara…"
            className="flex-1 min-w-48 rounded-lg border border-border bg-surface px-3 py-1.5 text-sm focus:border-primary focus:outline-none"
          />
          <select value={sortBy} onChange={e => setSortBy(e.target.value as 'name' | 'stock' | 'price')}
            className="rounded-lg border border-border bg-surface px-2 py-1.5 text-sm focus:border-primary focus:outline-none">
            <option value="stock">Stoka Göre</option>
            <option value="name">İsme Göre</option>
            <option value="price">Fiyata Göre</option>
          </select>
          <button
            onClick={() => setBulkReplenish(!bulkReplenish)}
            className="rounded-lg border border-border px-3 py-1.5 text-xs font-[700] text-muted hover:text-textStrong"
          >
            Toplu Yenile
          </button>
          <button
            onClick={exportCsv}
            className="rounded-lg border border-border px-3 py-1.5 text-xs font-[700] text-muted hover:text-textStrong"
          >
            CSV İndir
          </button>
        </div>
      )}

      {/* Bulk replenish panel */}
      {bulkReplenish && (
        <div className="flex items-center gap-3 border-b border-border bg-blue-50 px-5 py-3 dark:bg-blue-900/10">
          <p className="text-xs font-[700] text-blue-700">
            {selected.size > 0 ? `${selected.size} seçili ürünü` : 'Düşük stoktaki ürünleri'} stok hedefine getir:
          </p>
          <input
            type="number" min="1" value={bulkTarget}
            onChange={e => setBulkTarget(e.target.value)}
            className="w-20 rounded-lg border border-border px-2 py-1 text-sm focus:border-primary focus:outline-none"
          />
          <button
            disabled={isPending}
            onClick={doBulkReplenish}
            className="rounded-lg bg-blue-600 px-3 py-1.5 text-xs font-[800] text-white hover:bg-blue-700 disabled:opacity-50"
          >
            {isPending ? 'Güncelleniyor…' : 'Uygula'}
          </button>
          <button onClick={() => setBulkReplenish(false)} className="text-xs text-muted hover:text-textStrong">İptal</button>
        </div>
      )}

      {/* Below threshold warning */}
      {alertLevel === 'none' && belowThreshold.length > 0 && (
        <div className="flex items-center gap-2 border-b border-yellow-200 bg-yellow-50 px-5 py-2">
          <span className="text-xs font-[700] text-yellow-700">⚡ {belowThreshold.length} ürün sipariş eşiğinin altında</span>
        </div>
      )}

      <table className="w-full text-sm">
        <thead>
          <tr className="border-b border-border text-left">
            {alertLevel === 'none' && <th className="w-8 px-4 py-3" />}
            <th className="px-5 py-3 text-[11px] font-[800] uppercase tracking-wide text-muted">Ürün</th>
            <th className="px-5 py-3 text-[11px] font-[800] uppercase tracking-wide text-muted">Menü / İşletme</th>
            <th className="px-5 py-3 text-[11px] font-[800] uppercase tracking-wide text-muted">Stok</th>
            {alertLevel === 'none' && <th className="px-5 py-3 text-[11px] font-[800] uppercase tracking-wide text-muted">Eşik</th>}
            {alertLevel === 'none' && <th className="px-5 py-3 text-[11px] font-[800] uppercase tracking-wide text-muted">Tedarikçi</th>}
            <th className="px-5 py-3 text-[11px] font-[800] uppercase tracking-wide text-muted">Müsait</th>
            <th className="px-5 py-3 text-[11px] font-[800] uppercase tracking-wide text-muted" />
          </tr>
        </thead>
        <tbody className="divide-y divide-border">
          {filtered.map(item => {
            const atThreshold = (item.reorder_threshold ?? 0) > 0 && (item.stock_count ?? 0) <= (item.reorder_threshold ?? 0);
            return (
              <tr key={item.id} className={`hover:bg-black/[0.02] ${atThreshold ? 'bg-yellow-50/30' : ''}`}>
                {alertLevel === 'none' && (
                  <td className="px-4 py-3">
                    <input type="checkbox" checked={selected.has(item.id)} onChange={() => toggleSelect(item.id)}
                      className="rounded border-border" />
                  </td>
                )}
                <td className="px-5 py-3">
                  <p className="font-[700] text-textStrong">{item.name}</p>
                  <p className="text-xs text-muted">₺{item.price.toLocaleString('tr-TR', { minimumFractionDigits: 2 })}</p>
                </td>
                <td className="px-5 py-3 text-xs text-muted">
                  <p>{item.menus?.name ?? '—'}</p>
                  <p className="text-[10px]">{item.menus?.businesses?.name ?? ''}</p>
                </td>
                <td className="px-5 py-3">
                  {editing === item.id && editMode === 'stock' ? (
                    <div className="flex items-center gap-1">
                      <input type="number" min="0" value={editVal} onChange={e => setEditVal(e.target.value)}
                        autoFocus className="w-16 rounded-lg border border-primary px-2 py-1 text-sm focus:outline-none" />
                      <button disabled={isPending} onClick={() => updateStock(item.id, parseInt(editVal, 10) || 0)}
                        className="rounded bg-primary px-2 py-1 text-[10px] font-[700] text-white disabled:opacity-50">✓</button>
                      <button onClick={() => setEditing(null)} className="text-xs text-muted">✕</button>
                    </div>
                  ) : (
                    <button onClick={() => openEdit(item, 'stock')} className="flex items-center gap-1 group">
                      <span className={`inline-flex rounded-full px-2 py-0.5 text-xs font-[800] ${
                        item.stock_count === 0 ? 'bg-red-100 text-red-700' :
                        (item.stock_count ?? 99) <= 5 ? 'bg-yellow-100 text-yellow-700' :
                        'bg-green-100 text-green-700'
                      }`}>
                        {item.stock_count ?? '∞'}
                      </span>
                      <svg width="10" height="10" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" className="text-muted opacity-0 group-hover:opacity-100">
                        <path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7" /><path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z" />
                      </svg>
                    </button>
                  )}
                </td>
                {alertLevel === 'none' && (
                  <td className="px-5 py-3">
                    {editing === item.id && editMode === 'threshold' ? (
                      <div className="flex items-center gap-1">
                        <input type="number" min="0" value={editThreshold} onChange={e => setEditThreshold(e.target.value)}
                          autoFocus className="w-16 rounded-lg border border-primary px-2 py-1 text-sm focus:outline-none" />
                        <button disabled={isPending} onClick={() => updateThreshold(item.id, parseInt(editThreshold, 10) || 0)}
                          className="rounded bg-primary px-2 py-1 text-[10px] font-[700] text-white disabled:opacity-50">✓</button>
                        <button onClick={() => setEditing(null)} className="text-xs text-muted">✕</button>
                      </div>
                    ) : (
                      <button onClick={() => openEdit(item, 'threshold')} className="flex items-center gap-1 group text-xs text-muted hover:text-textStrong">
                        {item.reorder_threshold ? `≤${item.reorder_threshold}` : '—'}
                        <svg width="10" height="10" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" className="opacity-0 group-hover:opacity-100">
                          <path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7" /><path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z" />
                        </svg>
                      </button>
                    )}
                  </td>
                )}
                {alertLevel === 'none' && (
                  <td className="px-5 py-3 max-w-[120px]">
                    {editing === item.id && editMode === 'supplier' ? (
                      <div className="flex items-center gap-1">
                        <input value={editSupplier} onChange={e => setEditSupplier(e.target.value)}
                          autoFocus placeholder="Tedarikçi adı"
                          className="w-24 rounded-lg border border-primary px-2 py-1 text-xs focus:outline-none" />
                        <button disabled={isPending} onClick={() => updateSupplier(item.id, editSupplier)}
                          className="rounded bg-primary px-2 py-1 text-[10px] font-[700] text-white disabled:opacity-50">✓</button>
                        <button onClick={() => setEditing(null)} className="text-xs text-muted">✕</button>
                      </div>
                    ) : (
                      <button onClick={() => openEdit(item, 'supplier')} className="flex items-center gap-1 group max-w-full">
                        <span className="truncate text-xs text-muted group-hover:text-textStrong">{item.supplier || '—'}</span>
                        <svg width="10" height="10" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" className="shrink-0 opacity-0 group-hover:opacity-100 text-muted">
                          <path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7" /><path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z" />
                        </svg>
                      </button>
                    )}
                  </td>
                )}
                <td className="px-5 py-3">
                  <button
                    disabled={isPending}
                    onClick={() => toggleAvailability(item.id, item.is_available)}
                    className={`rounded-full px-2 py-0.5 text-[10px] font-[700] transition-colors ${item.is_available ? 'bg-green-100 text-green-700 hover:bg-green-200' : 'bg-red-100 text-red-700 hover:bg-red-200'} disabled:opacity-50`}
                  >
                    {item.is_available ? 'Aktif' : 'Pasif'}
                  </button>
                </td>
                <td className="px-5 py-3">
                  {atThreshold && <span className="text-[9px] font-[700] text-yellow-600">⚡ Sipariş ver</span>}
                </td>
              </tr>
            );
          })}
        </tbody>
      </table>
    </div>
  );
}
