'use client';

import { useState } from 'react';
import { Section, StatusFilter, SortMode } from '../menu-duzenleyici-yardimcilari';

export function AracCubugu({
  search,
  onSearchChange,
  sections,
  sectionId,
  onSectionChange,
  status,
  onStatusChange,
  sortMode,
  onSortModeChange,
  selectedCount,
  onBulkSetAvailability,
  onBulkMoveSection,
  onBulkDelete,
}: {
  search: string;
  onSearchChange: (value: string) => void;
  sections: Section[];
  sectionId: string | null;
  onSectionChange: (value: string | null) => void;
  status: StatusFilter;
  onStatusChange: (value: StatusFilter) => void;
  sortMode: SortMode;
  onSortModeChange: (value: SortMode) => void;
  selectedCount: number;
  onBulkSetAvailability: (isAvailable: boolean) => void;
  onBulkMoveSection: (sectionId: string) => void;
  onBulkDelete: () => void;
}) {
  const [bulkMenuOpen, setBulkMenuOpen] = useState(false);

  return (
    <div className="flex flex-wrap items-center gap-2">
      <input
        value={search}
        onChange={(e) => onSearchChange(e.target.value)}
        placeholder="Ürün ara..."
        className="min-w-[200px] flex-1 rounded-xl border border-border bg-bg px-3 py-2 text-sm text-textStrong placeholder:text-muted focus:outline-hidden focus:ring-2 focus:ring-primary/30"
      />
      <select
        value={sectionId ?? ''}
        onChange={(e) => onSectionChange(e.target.value || null)}
        className="rounded-xl border border-border bg-bg px-3 py-2 text-sm text-textStrong focus:outline-hidden focus:ring-2 focus:ring-primary/30"
      >
        <option value="">Tüm Kategoriler</option>
        {sections.map((s) => (
          <option key={s.id} value={s.id}>{s.title}</option>
        ))}
      </select>
      <select
        value={status}
        onChange={(e) => onStatusChange(e.target.value as StatusFilter)}
        className="rounded-xl border border-border bg-bg px-3 py-2 text-sm text-textStrong focus:outline-hidden focus:ring-2 focus:ring-primary/30"
      >
        <option value="all">Tümü</option>
        <option value="active">Aktif</option>
        <option value="passive">Pasif</option>
      </select>
      <select
        value={sortMode}
        onChange={(e) => onSortModeChange(e.target.value as SortMode)}
        className="rounded-xl border border-border bg-bg px-3 py-2 text-sm text-textStrong focus:outline-hidden focus:ring-2 focus:ring-primary/30"
      >
        <option value="manual">Manuel Sıralama</option>
        <option value="name">İsme Göre</option>
        <option value="price">Fiyata Göre</option>
        <option value="updated">Son Güncellemeye Göre</option>
      </select>

      <div className="relative">
        <button
          type="button"
          disabled={selectedCount === 0}
          onClick={() => setBulkMenuOpen((v) => !v)}
          className="rounded-xl border border-border bg-card px-3 py-2 text-sm font-bold text-textStrong disabled:cursor-not-allowed disabled:opacity-50 hover:bg-bg cursor-pointer"
        >
          Toplu İşlemler {selectedCount > 0 && `(${selectedCount})`}
        </button>
        {bulkMenuOpen && selectedCount > 0 && (
          <div className="absolute right-0 top-full z-10 mt-1 w-56 rounded-xl border border-border bg-card p-1 shadow-yd2">
            <button
              type="button"
              onClick={() => { onBulkSetAvailability(true); setBulkMenuOpen(false); }}
              className="block w-full rounded-lg px-3 py-2 text-left text-sm font-semibold text-textStrong hover:bg-bg cursor-pointer"
            >
              Aktif Yap
            </button>
            <button
              type="button"
              onClick={() => { onBulkSetAvailability(false); setBulkMenuOpen(false); }}
              className="block w-full rounded-lg px-3 py-2 text-left text-sm font-semibold text-textStrong hover:bg-bg cursor-pointer"
            >
              Pasif Yap
            </button>
            {sections.length > 0 && (
              <div className="border-t border-border px-3 py-2">
                <p className="mb-1 text-xs font-bold text-muted">Kategoriye Taşı</p>
                <select
                  onChange={(e) => {
                    if (e.target.value) { onBulkMoveSection(e.target.value); setBulkMenuOpen(false); }
                  }}
                  defaultValue=""
                  className="w-full rounded-lg border border-border bg-bg px-2 py-1.5 text-xs text-textStrong"
                >
                  <option value="" disabled>Kategori seç…</option>
                  {sections.map((s) => (
                    <option key={s.id} value={s.id}>{s.title}</option>
                  ))}
                </select>
              </div>
            )}
            <button
              type="button"
              onClick={() => {
                if (confirm(`${selectedCount} ürünü kalıcı olarak silmek istediğinize emin misiniz? Bu işlem geri alınamaz.`)) {
                  onBulkDelete();
                }
                setBulkMenuOpen(false);
              }}
              className="block w-full rounded-lg px-3 py-2 text-left text-sm font-semibold text-red-600 hover:bg-red-50 cursor-pointer"
            >
              Kalıcı Olarak Sil
            </button>
          </div>
        )}
      </div>
    </div>
  );
}
