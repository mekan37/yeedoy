'use client';

import Image from 'next/image';
import { useState } from 'react';
import { Item, Section, formatPrice, SortMode } from '../menu-duzenleyici-yardimcilari';

const KATEGORI_RENKLERI = [
  'bg-orange-50 text-orange-700',
  'bg-blue-50 text-blue-700',
  'bg-pink-50 text-pink-700',
  'bg-emerald-50 text-emerald-700',
  'bg-violet-50 text-violet-700',
  'bg-amber-50 text-amber-700',
];

function kategoriRengi(sectionId: string, sections: Section[]): string {
  const index = sections.findIndex((s) => s.id === sectionId);
  if (index < 0) return 'bg-bg text-muted border border-border';
  return KATEGORI_RENKLERI[index % KATEGORI_RENKLERI.length];
}

export function UrunTablosu({
  items,
  sections,
  sortMode,
  selectedIds,
  onToggleSelect,
  onToggleSelectAll,
  onReorder,
  onEdit,
  onDuplicate,
  onDelete,
}: {
  items: Item[];
  sections: Section[];
  sortMode: SortMode;
  selectedIds: Set<string>;
  onToggleSelect: (itemId: string) => void;
  onToggleSelectAll: () => void;
  onReorder: (itemId: string, newSortOrder: number) => void;
  onEdit: (itemId: string) => void;
  onDuplicate: (itemId: string) => void;
  onDelete: (itemId: string) => void;
}) {
  const [draggedId, setDraggedId] = useState<string | null>(null);
  const sectionTitle = (sectionId: string) => sections.find((s) => s.id === sectionId)?.title ?? '—';
  const allSelected = items.length > 0 && items.every((i) => selectedIds.has(i.id));
  const manual = sortMode === 'manual';

  function handleDrop(targetItem: Item) {
    if (!draggedId || draggedId === targetItem.id) { setDraggedId(null); return; }
    onReorder(draggedId, targetItem.sort_order);
    setDraggedId(null);
  }

  if (items.length === 0) {
    return (
      <div className="flex flex-col items-center gap-2 rounded-2xl border border-dashed border-border py-12 text-center">
        <p className="text-sm font-bold text-textStrong">Bu filtrelerle eşleşen ürün yok</p>
        <p className="text-xs text-muted">Filtreleri temizleyin veya yeni bir ürün ekleyin.</p>
      </div>
    );
  }

  return (
    <div className="overflow-x-auto rounded-2xl border border-border">
      <table className="w-full min-w-[720px] border-collapse text-sm">
        <thead>
          <tr className="border-b border-border bg-bg text-left text-xs font-bold uppercase tracking-wide text-muted">
            <th className="w-8 px-3 py-2"></th>
            <th className="w-8 px-3 py-2">
              <input type="checkbox" checked={allSelected} onChange={onToggleSelectAll} className="rounded" aria-label="Tümünü seç" />
            </th>
            <th className="w-14 px-3 py-2">Görsel</th>
            <th className="px-3 py-2">Ürün Adı</th>
            <th className="px-3 py-2">Kategori</th>
            <th className="px-3 py-2">Fiyat</th>
            <th className="px-3 py-2">Durum</th>
            <th className="px-3 py-2">Son Güncelleme</th>
            <th className="px-3 py-2">İşlemler</th>
          </tr>
        </thead>
        <tbody>
          {items.map((item) => (
            <tr
              key={item.id}
              draggable={manual}
              onDragStart={() => setDraggedId(item.id)}
              onDragOver={(e) => manual && e.preventDefault()}
              onDrop={() => manual && handleDrop(item)}
              className={`border-b border-border last:border-0 hover:bg-bg/60 ${draggedId === item.id ? 'opacity-40' : ''}`}
            >
              <td className="px-3 py-2 text-muted">
                {manual ? <span className="cursor-grab select-none" title="Sürükleyerek sırala">⠿</span> : null}
              </td>
              <td className="px-3 py-2">
                <input
                  type="checkbox"
                  checked={selectedIds.has(item.id)}
                  onChange={() => onToggleSelect(item.id)}
                  className="rounded"
                  aria-label={`${item.name} seç`}
                />
              </td>
              <td className="px-3 py-2">
                {item.image_url ? (
                  <Image src={item.image_url} alt={item.name} width={40} height={40} className="h-10 w-10 rounded-lg object-cover" unoptimized />
                ) : (
                  <div className="flex h-10 w-10 items-center justify-center rounded-lg border border-dashed border-border bg-bg text-[9px] font-bold text-muted">Yok</div>
                )}
              </td>
              <td className="px-3 py-2">
                <p className="font-bold text-textStrong">{item.name}</p>
                {item.description && <p className="max-w-[220px] truncate text-xs text-muted">{item.description}</p>}
              </td>
              <td className="px-3 py-2">
                <span className={`rounded-full px-2 py-0.5 text-[11px] font-extrabold ${kategoriRengi(item.section_id, sections)}`}>
                  {sectionTitle(item.section_id)}
                </span>
              </td>
              <td className="px-3 py-2 font-bold text-textStrong">{formatPrice(item.price_cents)}</td>
              <td className="px-3 py-2">
                <span className={`rounded-full px-2 py-0.5 text-[11px] font-extrabold ${item.is_available ? 'bg-green-50 text-green-700' : 'bg-zinc-100 text-zinc-500'}`}>
                  {item.is_available ? 'Aktif' : 'Pasif'}
                </span>
              </td>
              <td className="px-3 py-2 text-xs text-muted">
                {new Date(item.updated_at).toLocaleDateString('tr-TR', { day: '2-digit', month: 'short', year: 'numeric' })}
              </td>
              <td className="px-3 py-2">
                <div className="flex items-center gap-1">
                  <button type="button" onClick={() => onEdit(item.id)} title="Düzenle" className="rounded-lg border border-border p-1.5 text-muted hover:bg-bg cursor-pointer">
                    <EditIcon />
                  </button>
                  <button type="button" onClick={() => onDuplicate(item.id)} title="Kopyala" className="rounded-lg border border-border p-1.5 text-muted hover:bg-bg cursor-pointer">
                    <CopyIcon />
                  </button>
                  <button
                    type="button"
                    onClick={() => { if (confirm(`"${item.name}" ürününü kalıcı olarak sil?`)) onDelete(item.id); }}
                    title="Sil"
                    className="rounded-lg border border-red-200 p-1.5 text-red-600 hover:bg-red-50 cursor-pointer"
                  >
                    <TrashIcon />
                  </button>
                </div>
              </td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}

function EditIcon() {
  return <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round"><path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"/><path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"/></svg>;
}
function CopyIcon() {
  return <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round"><rect x="9" y="9" width="13" height="13" rx="2"/><path d="M5 15H4a2 2 0 0 1-2-2V4a2 2 0 0 1 2-2h9a2 2 0 0 1 2 2v1"/></svg>;
}
function TrashIcon() {
  return <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round"><polyline points="3 6 5 6 21 6"/><path d="M19 6l-1 14a2 2 0 0 1-2 2H8a2 2 0 0 1-2-2L5 6"/><path d="M10 11v6M14 11v6"/></svg>;
}
