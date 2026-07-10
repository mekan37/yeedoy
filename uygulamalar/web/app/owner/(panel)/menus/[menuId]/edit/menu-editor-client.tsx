'use client';

import { useState, useTransition } from 'react';
import { createSection, updateSection, deleteSection, upsertItem, deleteItem, publishMenu, updateMenuTitle } from './actions';

type Section = { id: string; title: string; sort_order: number };
type Item = { id: string; name: string; description: string | null; price_cents: number; currency: string; is_available: boolean; section_id: string; sort_order: number };

function formatPrice(cents: number) {
  return (cents / 100).toLocaleString('tr-TR', { minimumFractionDigits: 2 }) + ' ₺';
}

function Input({ label, name, defaultValue = '', required = false, type = 'text', placeholder = '' }: {
  label: string; name: string; defaultValue?: string; required?: boolean; type?: string; placeholder?: string;
}) {
  return (
    <div className="flex flex-col gap-1">
      <label className="text-xs font-[700] text-muted">{label}</label>
      <input name={name} type={type} defaultValue={defaultValue} required={required} placeholder={placeholder}
        className="rounded-xl border border-border bg-bg px-3 py-2 text-sm text-textStrong placeholder:text-muted focus:outline-none focus:ring-2 focus:ring-primary/30" />
    </div>
  );
}

export function MenuEditorClient({ menuId, initialTitle, initialStatus, sections: initSections, items: initItems }: {
  menuId: string;
  initialTitle: string;
  initialStatus: 'draft' | 'published' | 'archived';
  sections: Section[];
  items: Item[];
}) {
  const [isPending, startTransition] = useTransition();
  const [error, setError] = useState<string | null>(null);
  const [editingSectionId, setEditingSectionId] = useState<string | null>(null);
  const [addItemSectionId, setAddItemSectionId] = useState<string | null>(null);
  const [editingItemId, setEditingItemId] = useState<string | null>(null);
  const [showNewSection, setShowNewSection] = useState(false);
  const [showTitleEdit, setShowTitleEdit] = useState(false);

  const sections = initSections;
  const items = initItems;

  function itemsFor(sectionId: string) {
    return items.filter((i) => i.section_id === sectionId).sort((a, b) => a.sort_order - b.sort_order);
  }

  async function run(action: () => Promise<{ error: string } | null>) {
    setError(null);
    startTransition(async () => {
      const result = await action();
      if (result?.error) setError(result.error);
    });
  }

  return (
    <div className="flex flex-col gap-6">
      {/* Menu title + publish controls */}
      <div className="flex flex-wrap items-center gap-3 rounded-2xl border border-border bg-card p-4">
        {showTitleEdit ? (
          <form className="flex items-center gap-2 flex-1" onSubmit={(e) => {
            e.preventDefault();
            const fd = new FormData(e.currentTarget);
            const title = String(fd.get('title') ?? '');
            run(() => updateMenuTitle(menuId, title));
            setShowTitleEdit(false);
          }}>
            <input name="title" defaultValue={initialTitle} required className="flex-1 rounded-xl border border-border bg-bg px-3 py-2 text-sm text-textStrong focus:outline-none focus:ring-2 focus:ring-primary/30" />
            <button type="submit" className="rounded-xl bg-primary px-3 py-2 text-xs font-[700] text-white cursor-pointer">Kaydet</button>
            <button type="button" onClick={() => setShowTitleEdit(false)} className="rounded-xl border border-border px-3 py-2 text-xs font-[700] text-textStrong cursor-pointer">İptal</button>
          </form>
        ) : (
          <>
            <span className="font-[700] text-textStrong flex-1">{initialTitle}</span>
            <button onClick={() => setShowTitleEdit(true)} className="rounded-xl border border-border px-3 py-1.5 text-xs font-[700] text-textStrong hover:bg-bg cursor-pointer">Başlığı Düzenle</button>
          </>
        )}
        <div className="flex items-center gap-2">
          {initialStatus !== 'published' && (
            <button onClick={() => run(() => publishMenu(menuId, 'published'))} disabled={isPending}
              className="rounded-xl bg-green-600 px-3 py-1.5 text-xs font-[700] text-white disabled:opacity-60 cursor-pointer">Yayınla</button>
          )}
          {initialStatus === 'published' && (
            <button onClick={() => run(() => publishMenu(menuId, 'draft'))} disabled={isPending}
              className="rounded-xl border border-amber-300 bg-amber-50 px-3 py-1.5 text-xs font-[700] text-amber-700 disabled:opacity-60 cursor-pointer">Taslağa Al</button>
          )}
          {initialStatus !== 'archived' && (
            <button onClick={() => run(() => publishMenu(menuId, 'archived'))} disabled={isPending}
              className="rounded-xl border border-border px-3 py-1.5 text-xs font-[700] text-muted hover:bg-bg disabled:opacity-60 cursor-pointer">Arşivle</button>
          )}
        </div>
      </div>

      {error && (
        <div className="rounded-xl bg-red-50 px-4 py-3 text-sm text-red-700">{error}</div>
      )}

      {/* Sections */}
      {sections.map((section) => (
        <div key={section.id} className="rounded-2xl border border-border bg-card">
          {/* Section header */}
          <div className="flex items-center justify-between border-b border-border px-5 py-3">
            {editingSectionId === section.id ? (
              <form className="flex flex-1 items-center gap-2" onSubmit={(e) => {
                e.preventDefault();
                const fd = new FormData(e.currentTarget);
                const title = String(fd.get('title') ?? '');
                run(() => updateSection(section.id, menuId, title));
                setEditingSectionId(null);
              }}>
                <input name="title" defaultValue={section.title} required className="flex-1 rounded-xl border border-border bg-bg px-3 py-1.5 text-sm text-textStrong focus:outline-none focus:ring-2 focus:ring-primary/30" />
                <button type="submit" className="rounded-xl bg-primary px-3 py-1.5 text-xs font-[700] text-white cursor-pointer">Kaydet</button>
                <button type="button" onClick={() => setEditingSectionId(null)} className="rounded-xl border border-border px-3 py-1.5 text-xs font-[700] text-textStrong cursor-pointer">İptal</button>
              </form>
            ) : (
              <>
                <span className="font-[800] text-textStrong">{section.title}</span>
                <div className="flex items-center gap-1.5">
                  <button onClick={() => setEditingSectionId(section.id)} className="rounded-lg border border-border px-2.5 py-1 text-[11px] font-[700] text-muted hover:bg-bg cursor-pointer">Düzenle</button>
                  <button onClick={() => { if (confirm(`"${section.title}" bölümünü sil?`)) run(() => deleteSection(section.id, menuId)); }}
                    className="rounded-lg border border-red-200 px-2.5 py-1 text-[11px] font-[700] text-red-600 hover:bg-red-50 cursor-pointer">Sil</button>
                </div>
              </>
            )}
          </div>

          {/* Items */}
          <div className="divide-y divide-border">
            {itemsFor(section.id).map((item) => (
              <div key={item.id}>
                {editingItemId === item.id ? (
                  <form className="p-4 flex flex-col gap-3" onSubmit={(e) => {
                    e.preventDefault();
                    const fd = new FormData(e.currentTarget);
                    fd.append('menuId', menuId);
                    fd.append('sectionId', section.id);
                    fd.append('itemId', item.id);
                    run(() => upsertItem(fd));
                    setEditingItemId(null);
                  }}>
                    <div className="grid grid-cols-2 gap-3">
                      <Input label="Ürün Adı" name="name" defaultValue={item.name} required placeholder="Ürün adı" />
                      <Input label="Fiyat (₺)" name="price" type="number" defaultValue={String(item.price_cents / 100)} required placeholder="0.00" />
                    </div>
                    <Input label="Açıklama (opsiyonel)" name="description" defaultValue={item.description ?? ''} placeholder="Kısa açıklama" />
                    <label className="flex items-center gap-2 text-sm text-textStrong cursor-pointer">
                      <input type="checkbox" name="is_available" defaultChecked={item.is_available} className="rounded" />
                      Satışta
                    </label>
                    <div className="flex gap-2">
                      <button type="submit" disabled={isPending} className="rounded-xl bg-primary px-3 py-2 text-xs font-[700] text-white disabled:opacity-60 cursor-pointer">Kaydet</button>
                      <button type="button" onClick={() => setEditingItemId(null)} className="rounded-xl border border-border px-3 py-2 text-xs font-[700] text-textStrong cursor-pointer">İptal</button>
                    </div>
                  </form>
                ) : (
                  <div className="flex items-center gap-4 px-5 py-3">
                    <div className="flex-1 min-w-0">
                      <div className="flex items-center gap-2">
                        <span className="font-[600] text-textStrong">{item.name}</span>
                        {!item.is_available && <span className="rounded-full bg-zinc-100 px-1.5 py-0.5 text-[10px] font-[700] text-zinc-500">Stok Dışı</span>}
                      </div>
                      {item.description && <p className="mt-0.5 text-[12px] text-muted truncate max-w-xs">{item.description}</p>}
                    </div>
                    <span className="shrink-0 font-[700] text-textStrong">{formatPrice(item.price_cents)}</span>
                    <div className="flex items-center gap-1.5 shrink-0">
                      <button onClick={() => setEditingItemId(item.id)} className="rounded-lg border border-border px-2.5 py-1 text-[11px] font-[700] text-muted hover:bg-bg cursor-pointer">Düzenle</button>
                      <button onClick={() => { if (confirm(`"${item.name}" ürününü sil?`)) run(() => deleteItem(item.id, menuId)); }}
                        className="rounded-lg border border-red-200 px-2.5 py-1 text-[11px] font-[700] text-red-600 hover:bg-red-50 cursor-pointer">Sil</button>
                    </div>
                  </div>
                )}
              </div>
            ))}
          </div>

          {/* Add item */}
          {addItemSectionId === section.id ? (
            <form className="border-t border-border p-4 flex flex-col gap-3" onSubmit={(e) => {
              e.preventDefault();
              const fd = new FormData(e.currentTarget);
              fd.append('menuId', menuId);
              fd.append('sectionId', section.id);
              run(() => upsertItem(fd));
              setAddItemSectionId(null);
            }}>
              <div className="grid grid-cols-2 gap-3">
                <Input label="Ürün Adı" name="name" required placeholder="Ürün adı" />
                <Input label="Fiyat (₺)" name="price" type="number" required placeholder="0.00" />
              </div>
              <Input label="Açıklama (opsiyonel)" name="description" placeholder="Kısa açıklama" />
              <label className="flex items-center gap-2 text-sm text-textStrong cursor-pointer">
                <input type="checkbox" name="is_available" defaultChecked className="rounded" />
                Satışta
              </label>
              <div className="flex gap-2">
                <button type="submit" disabled={isPending} className="rounded-xl bg-primary px-3 py-2 text-xs font-[700] text-white disabled:opacity-60 cursor-pointer">Ürün Ekle</button>
                <button type="button" onClick={() => setAddItemSectionId(null)} className="rounded-xl border border-border px-3 py-2 text-xs font-[700] text-textStrong cursor-pointer">İptal</button>
              </div>
            </form>
          ) : (
            <div className="border-t border-border px-5 py-3">
              <button onClick={() => setAddItemSectionId(section.id)} className="text-sm font-[700] text-primary hover:underline cursor-pointer">+ Ürün Ekle</button>
            </div>
          )}
        </div>
      ))}

      {/* New section form */}
      {showNewSection ? (
        <form className="rounded-2xl border border-dashed border-border bg-card p-5 flex flex-col gap-3"
          onSubmit={(e) => {
            e.preventDefault();
            const fd = new FormData(e.currentTarget);
            const title = String(fd.get('title') ?? '');
            run(() => createSection(menuId, title, sections.length));
            setShowNewSection(false);
          }}>
          <Input label="Bölüm Adı" name="title" required placeholder="Ör: Başlangıçlar, Ana Yemekler…" />
          <div className="flex gap-2">
            <button type="submit" disabled={isPending} className="rounded-xl bg-primary px-3 py-2 text-sm font-[700] text-white disabled:opacity-60 cursor-pointer">Bölüm Oluştur</button>
            <button type="button" onClick={() => setShowNewSection(false)} className="rounded-xl border border-border px-3 py-2 text-sm font-[700] text-textStrong cursor-pointer">İptal</button>
          </div>
        </form>
      ) : (
        <button onClick={() => setShowNewSection(true)}
          className="flex items-center justify-center gap-2 rounded-2xl border border-dashed border-border bg-card px-5 py-4 text-sm font-[700] text-muted hover:border-primary/40 hover:text-primary transition-colors cursor-pointer">
          <span className="text-lg">+</span> Yeni Bölüm Ekle
        </button>
      )}
    </div>
  );
}
