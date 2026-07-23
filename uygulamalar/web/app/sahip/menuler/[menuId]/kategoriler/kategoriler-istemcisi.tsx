'use client';

import { useState, useTransition } from 'react';
import { createSection, updateSection, deleteSection } from '../duzenle/menu-islemleri';

type Section = { id: string; title: string; sort_order: number };

function PlusIcon() {
  return <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><line x1="12" y1="5" x2="12" y2="19" /><line x1="5" y1="12" x2="19" y2="12" /></svg>;
}
function PencilIcon() {
  return <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M17 3a2.85 2.83 0 1 1 4 4L7.5 20.5 2 22l1.5-5.5Z" /></svg>;
}
function TrashIcon() {
  return <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M3 6h18" /><path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2" /></svg>;
}

export function KategorilerClient({
  menuId,
  sections: initSections,
  itemCounts,
}: {
  menuId: string;
  sections: Section[];
  itemCounts: Record<string, number>;
}) {
  const [isPending, startTransition] = useTransition();
  const [error, setError] = useState<string | null>(null);
  const [editingId, setEditingId] = useState<string | null>(null);
  const [editTitle, setEditTitle] = useState('');
  const [showNew, setShowNew] = useState(false);
  const [newTitle, setNewTitle] = useState('');

  const sections = initSections;

  function run(action: () => Promise<{ error: string } | null>) {
    setError(null);
    startTransition(async () => {
      const result = await action();
      if (result?.error) setError(result.error);
    });
  }

  function handleCreate() {
    const title = newTitle.trim();
    if (!title) return;
    run(async () => {
      const result = await createSection(menuId, title, sections.length);
      if (!result) {
        setNewTitle('');
        setShowNew(false);
      }
      return result;
    });
  }

  function handleUpdate(sectionId: string) {
    const title = editTitle.trim();
    if (!title) return;
    run(async () => {
      const result = await updateSection(sectionId, menuId, title);
      if (!result) setEditingId(null);
      return result;
    });
  }

  function handleDelete(section: Section) {
    const count = itemCounts[section.id] ?? 0;
    const message = count > 0
      ? `"${section.title}" bölümünde ${count} ürün var. Silerseniz bu ürünler de silinir. Emin misiniz?`
      : `"${section.title}" bölümü silinsin mi?`;
    if (!confirm(message)) return;
    run(() => deleteSection(section.id, menuId));
  }

  return (
    <div className="flex flex-col gap-5">
      {error && <div className="rounded-xl bg-red-50 px-4 py-3 text-sm text-red-700">{error}</div>}

      <div className="flex flex-col gap-2">
        {sections.map((section) => (
          <div key={section.id} className="flex items-center justify-between gap-3 rounded-xl border border-border bg-card px-4 py-3">
            {editingId === section.id ? (
              <input
                autoFocus
                value={editTitle}
                onChange={(e) => setEditTitle(e.target.value)}
                onKeyDown={(e) => e.key === 'Enter' && handleUpdate(section.id)}
                className="min-h-[36px] flex-1 rounded-lg border border-border bg-bg px-2 text-sm font-[700] text-textStrong focus:outline-none focus:ring-2 focus:ring-primary/30"
              />
            ) : (
              <span className="text-sm font-[700] text-textStrong">{section.title}</span>
            )}
            <div className="flex shrink-0 items-center gap-3 text-xs text-muted">
              <span>{itemCounts[section.id] ?? 0} ürün</span>
              {editingId === section.id ? (
                <button type="button" disabled={isPending} onClick={() => handleUpdate(section.id)} className="font-[700] text-primary hover:underline cursor-pointer">Kaydet</button>
              ) : (
                <button type="button" disabled={isPending} onClick={() => { setEditingId(section.id); setEditTitle(section.title); }} aria-label={`${section.title} düzenle`} className="text-textStrong hover:text-primary cursor-pointer"><PencilIcon /></button>
              )}
              <button type="button" disabled={isPending} onClick={() => handleDelete(section)} aria-label={`${section.title} sil`} className="text-danger hover:opacity-70 cursor-pointer"><TrashIcon /></button>
            </div>
          </div>
        ))}
      </div>

      {showNew ? (
        <div className="flex items-center gap-2">
          <input
            autoFocus
            value={newTitle}
            onChange={(e) => setNewTitle(e.target.value)}
            onKeyDown={(e) => e.key === 'Enter' && handleCreate()}
            placeholder="Bölüm adı"
            className="min-h-[40px] flex-1 rounded-xl border border-border bg-bg px-3 text-sm text-textStrong focus:outline-none focus:ring-2 focus:ring-primary/30"
          />
          <button type="button" disabled={isPending} onClick={handleCreate} className="btn-primary rounded-xl px-4 py-2 text-sm font-[900] text-white cursor-pointer">Ekle</button>
          <button type="button" onClick={() => setShowNew(false)} className="rounded-xl border border-border px-4 py-2 text-sm font-[700] text-textStrong cursor-pointer">Vazgeç</button>
        </div>
      ) : (
        <button
          type="button"
          onClick={() => setShowNew(true)}
          className="flex items-center justify-center gap-2 rounded-xl border border-dashed border-border px-4 py-3 text-sm font-[700] text-muted hover:border-primary hover:text-primary cursor-pointer"
        >
          <PlusIcon /> Yeni Kategori
        </button>
      )}
    </div>
  );
}
