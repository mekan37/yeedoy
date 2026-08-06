'use client';

import { useMemo, useState, useTransition } from 'react';
import {
  updateMenuTitle,
  publishMenu,
  createSection,
  deleteItem,
  reorderItem,
  bulkSetAvailability,
  bulkMoveSection,
  bulkDeleteItems,
  duplicateItem,
} from './menu-islemleri';
import {
  type Section,
  type Item,
  type StatusFilter,
  type SortMode,
  computeStats,
  filterItems,
  sortItems,
} from './menu-duzenleyici-yardimcilari';
import { IstatistikKartlari } from './bilesenler/istatistik-kartlari';
import { KategoriSekmeleri } from './bilesenler/kategori-sekmeleri';
import { AracCubugu } from './bilesenler/arac-cubugu';
import { UrunTablosu } from './bilesenler/urun-tablosu';
import { UrunPaneli } from './bilesenler/urun-paneli';
import { KategoriWidgeti } from './bilesenler/kategori-widgeti';
import { CanliOnizlemeWidgeti } from './bilesenler/canli-onizleme-widgeti';

export function MenuEditorClient({
  menuId,
  businessId,
  initialTitle,
  initialStatus,
  sections: initSections,
  items: initItems,
  allergenMap,
  ingredientMap,
}: {
  menuId: string;
  businessId: string;
  initialTitle: string;
  initialStatus: 'draft' | 'published' | 'archived';
  sections: Section[];
  items: Item[];
  allergenMap: Record<string, string[]>;
  ingredientMap: Record<string, string[]>;
}) {
  const [isPending, startTransition] = useTransition();
  const [error, setError] = useState<string | null>(null);
  const [showTitleEdit, setShowTitleEdit] = useState(false);
  const [showNewSection, setShowNewSection] = useState(false);

  const sections = initSections;
  const items = initItems;

  const [activeSectionId, setActiveSectionId] = useState<string | null>(null);
  const [search, setSearch] = useState('');
  const [status, setStatus] = useState<StatusFilter>('all');
  const [sortMode, setSortMode] = useState<SortMode>('manual');
  const [selectedIds, setSelectedIds] = useState<Set<string>>(new Set());
  const [editingItemId, setEditingItemId] = useState<string | null>(null);
  const [addingSectionId, setAddingSectionId] = useState<string | null>(null);
  const [previewItemId, setPreviewItemId] = useState<string | null>(null);

  const stats = useMemo(() => computeStats(sections, items), [sections, items]);

  const itemCountsBySection = useMemo(() => {
    const counts: Record<string, number> = {};
    for (const item of items) counts[item.section_id] = (counts[item.section_id] ?? 0) + 1;
    return counts;
  }, [items]);

  const visibleItems = useMemo(() => {
    const filtered = filterItems(items, { search, sectionId: activeSectionId, status });
    return sortItems(filtered, sortMode);
  }, [items, search, activeSectionId, status, sortMode]);

  const editingItem = editingItemId ? items.find((i) => i.id === editingItemId) ?? null : null;
  const previewItem = previewItemId
    ? items.find((i) => i.id === previewItemId) ?? null
    : visibleItems[0] ?? null;

  function run(action: () => Promise<{ error: string } | null>) {
    setError(null);
    startTransition(async () => {
      const result = await action();
      if (result?.error) setError(result.error);
    });
  }

  function toggleSelect(itemId: string) {
    setSelectedIds((prev) => {
      const next = new Set(prev);
      if (next.has(itemId)) next.delete(itemId); else next.add(itemId);
      return next;
    });
  }

  function toggleSelectAll() {
    setSelectedIds((prev) => {
      const allSelected = visibleItems.length > 0 && visibleItems.every((i) => prev.has(i.id));
      if (allSelected) return new Set();
      return new Set(visibleItems.map((i) => i.id));
    });
  }

  async function handleDuplicate(itemId: string) {
    setError(null);
    startTransition(async () => {
      const result = await duplicateItem(itemId, menuId);
      if ('error' in result) setError(result.error);
    });
  }

  return (
    <div className="flex flex-col gap-6 lg:flex-row lg:items-start">
      <div className="flex min-w-0 flex-1 flex-col gap-4">
        {/* Menü başlığı + yayın kontrolleri */}
        <div className="flex flex-wrap items-center gap-3 rounded-2xl border border-border bg-card p-4">
          {showTitleEdit ? (
            <form
              className="flex flex-1 items-center gap-2"
              onSubmit={(e) => {
                e.preventDefault();
                const fd = new FormData(e.currentTarget);
                run(() => updateMenuTitle(menuId, String(fd.get('title') ?? '')));
                setShowTitleEdit(false);
              }}
            >
              <input name="title" defaultValue={initialTitle} required className="flex-1 rounded-xl border border-border bg-bg px-3 py-2 text-sm text-textStrong focus:outline-hidden focus:ring-2 focus:ring-primary/30" />
              <button type="submit" className="rounded-xl bg-primary px-3 py-2 text-xs font-bold text-white cursor-pointer">Kaydet</button>
              <button type="button" onClick={() => setShowTitleEdit(false)} className="rounded-xl border border-border px-3 py-2 text-xs font-bold text-textStrong cursor-pointer">İptal</button>
            </form>
          ) : (
            <>
              <span className="flex-1 font-bold text-textStrong">{initialTitle}</span>
              <button onClick={() => setShowTitleEdit(true)} className="rounded-xl border border-border px-3 py-1.5 text-xs font-bold text-textStrong hover:bg-bg cursor-pointer">Başlığı Düzenle</button>
            </>
          )}
          <div className="flex items-center gap-2">
            {initialStatus !== 'published' && (
              <button onClick={() => run(() => publishMenu(menuId, 'published'))} disabled={isPending} className="rounded-xl bg-green-600 px-3 py-1.5 text-xs font-bold text-white disabled:opacity-60 cursor-pointer">Yayınla</button>
            )}
            {initialStatus === 'published' && (
              <button onClick={() => run(() => publishMenu(menuId, 'draft'))} disabled={isPending} className="rounded-xl border border-amber-300 bg-amber-50 px-3 py-1.5 text-xs font-bold text-amber-700 disabled:opacity-60 cursor-pointer">Taslağa Al</button>
            )}
            {initialStatus !== 'archived' && (
              <button onClick={() => run(() => publishMenu(menuId, 'archived'))} disabled={isPending} className="rounded-xl border border-border px-3 py-1.5 text-xs font-bold text-muted hover:bg-bg disabled:opacity-60 cursor-pointer">Arşivle</button>
            )}
          </div>
        </div>

        {/* Ekleme butonları */}
        <div className="flex justify-end gap-2">
          {showNewSection ? (
            <form
              className="flex flex-1 items-center gap-2 rounded-xl border border-dashed border-border bg-card p-2"
              onSubmit={(e) => {
                e.preventDefault();
                const fd = new FormData(e.currentTarget);
                run(() => createSection(menuId, String(fd.get('title') ?? ''), sections.length));
                setShowNewSection(false);
              }}
            >
              <input name="title" required autoFocus placeholder="Kategori adı" className="min-w-0 flex-1 rounded-lg border border-border bg-bg px-2 py-1.5 text-sm text-textStrong" />
              <button type="submit" className="rounded-lg bg-primary px-3 py-1.5 text-xs font-bold text-white cursor-pointer">Ekle</button>
              <button type="button" onClick={() => setShowNewSection(false)} className="rounded-lg border border-border px-3 py-1.5 text-xs font-bold text-textStrong cursor-pointer">İptal</button>
            </form>
          ) : (
            <button type="button" onClick={() => setShowNewSection(true)} className="rounded-xl border border-border bg-card px-3 py-2 text-sm font-bold text-textStrong hover:bg-bg cursor-pointer">
              + Kategori Ekle
            </button>
          )}
          <button
            type="button"
            disabled={sections.length === 0}
            onClick={() => setAddingSectionId(activeSectionId ?? sections[0]?.id ?? null)}
            className="rounded-xl bg-primary px-3 py-2 text-sm font-bold text-white disabled:cursor-not-allowed disabled:opacity-50 cursor-pointer"
          >
            + Yeni Ürün Ekle
          </button>
        </div>

        {error && <div className="rounded-xl bg-red-50 px-4 py-3 text-sm text-red-700">{error}</div>}

        <IstatistikKartlari stats={stats} />

        <KategoriSekmeleri
          sections={sections}
          itemCounts={itemCountsBySection}
          activeSectionId={activeSectionId}
          onChange={setActiveSectionId}
        />

        <AracCubugu
          search={search}
          onSearchChange={setSearch}
          sections={sections}
          sectionId={activeSectionId}
          onSectionChange={setActiveSectionId}
          status={status}
          onStatusChange={setStatus}
          sortMode={sortMode}
          onSortModeChange={setSortMode}
          selectedCount={selectedIds.size}
          onBulkSetAvailability={(isAvailable) => {
            run(() => bulkSetAvailability([...selectedIds], menuId, isAvailable));
            setSelectedIds(new Set());
          }}
          onBulkMoveSection={(sectionId) => {
            run(() => bulkMoveSection([...selectedIds], menuId, sectionId));
            setSelectedIds(new Set());
          }}
          onBulkDelete={() => {
            run(() => bulkDeleteItems([...selectedIds], menuId));
            setSelectedIds(new Set());
          }}
        />

        <UrunTablosu
          items={visibleItems}
          sections={sections}
          sortMode={sortMode}
          selectedIds={selectedIds}
          onToggleSelect={toggleSelect}
          onToggleSelectAll={toggleSelectAll}
          onReorder={(itemId, newSortOrder) => run(() => reorderItem(itemId, menuId, newSortOrder))}
          onEdit={(itemId) => { setPreviewItemId(itemId); setEditingItemId(itemId); }}
          onDuplicate={handleDuplicate}
          onDelete={(itemId) => run(() => deleteItem(itemId, menuId))}
        />
      </div>

      <div className="flex w-full flex-col gap-4 lg:w-80 lg:shrink-0">
        <KategoriWidgeti menuId={menuId} sections={sections} itemCounts={itemCountsBySection} />
        <CanliOnizlemeWidgeti item={previewItem} />
      </div>

      {(editingItem || addingSectionId) && (
        <UrunPaneli
          menuId={menuId}
          sectionId={editingItem?.section_id ?? addingSectionId ?? sections[0]?.id ?? ''}
          businessId={businessId}
          itemId={editingItem?.id}
          initialValues={editingItem ? {
            name: editingItem.name,
            description: editingItem.description,
            image_url: editingItem.image_url,
            price_cents: editingItem.price_cents,
            is_available: editingItem.is_available,
            calories_min: editingItem.calories_min,
            portion_size: editingItem.portion_size,
            portion_unit: editingItem.portion_unit,
          } : undefined}
          initialAllergens={editingItem ? allergenMap[editingItem.id] ?? [] : []}
          initialIngredients={editingItem ? ingredientMap[editingItem.id] ?? [] : []}
          submitLabel={editingItem ? 'Kaydet' : 'Ürün Ekle'}
          onSuccess={() => { setEditingItemId(null); setAddingSectionId(null); }}
          onCancel={() => { setEditingItemId(null); setAddingSectionId(null); }}
        />
      )}
    </div>
  );
}
