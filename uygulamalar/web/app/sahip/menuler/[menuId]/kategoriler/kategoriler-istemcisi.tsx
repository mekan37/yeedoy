'use client';

import { useState, useTransition } from 'react';
import { createSection, updateSection, deleteSection } from '../menu-islemleri';
import { categoryBadgeColor, TagIcon, PencilIcon, TrashIcon } from '../duzenle/menu-duzenleyici-istemcisi';

type Section = { id: string; title: string; sort_order: number };

function PlusIcon() {
  return <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><line x1="12" y1="5" x2="12" y2="19" /><line x1="5" y1="12" x2="19" y2="12" /></svg>;
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
  const [showNew, setShowNew] = useState(false);

  const sections = initSections;

  async function run(action: () => Promise<{ error: string } | null>) {
    setError(null);
    startTransition(async () => {
      const result = await action();
      if (result?.error) setError(result.error);
    });
  }

  return (
    <div className="flex flex-col gap-5">
      {error && <div className="rounded-xl bg-red-50 px-4 py-3 text-sm text-red-700">{error}</div>}

      <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
        {sections.map((section, i) => {
          const count = itemCounts[section.id] ?? 0;
          const isEditing = editingId === section.id;
          return (
            <div key={section.id} className="flex flex-col gap-3 rounded-2xl border border-border bg-card p-4">
              <div className="flex items-start gap-3">
                <span className={`flex h-11 w-11 shrink-0 items-center justify-center rounded-xl ${categoryBadgeColor(i)}`}>
                  <TagIcon />
                </span>
                <div className="min-w-0 flex-1">
                  {isEditing ? (
                    <form
                      className="flex items-center gap-1.5"
                      onSubmit={(e) => {
                        e.preventDefault();
                        const fd = new FormData(e.currentTarget);
                        const title = String(fd.get('title') ?? '');
                        run(() => updateSection(section.id, menuId, title));
                        setEditingId(null);
                      }}
                    >
                      <input
                        name="title"
                        defaultValue={section.title}
                        required
                        autoFocus
                        className="min-w-0 flex-1 rounded-lg border border-border bg-bg px-2 py-1 text-sm text-textStrong focus:outline-none focus:ring-2 focus:ring-primary/30"
                      />
                      <button type="submit" className="cursor-pointer rounded-lg bg-primary px-2 py-1 text-[11px] font-[700] text-white">Kaydet</button>
                      <button type="button" onClick={() => setEditingId(null)} className="cursor-pointer rounded-lg border border-border px-2 py-1 text-[11px] font-[700] text-textStrong">İptal</button>
                    </form>
                  ) : (
                    <>
                      <p className="truncate font-[800] text-textStrong">{section.title}</p>
                      <p className="text-[12px] text-muted">{count} ürün</p>
                    </>
                  )}
                </div>
              </div>
              {!isEditing && (
                <div className="flex items-center gap-2 border-t border-border pt-3">
                  <button
                    onClick={() => setEditingId(section.id)}
                    className="flex flex-1 cursor-pointer items-center justify-center gap-1.5 rounded-lg border border-border px-3 py-1.5 text-[12px] font-[700] text-textStrong hover:bg-bg"
                  >
                    <PencilIcon /> Düzenle
                  </button>
                  <button
                    onClick={() => {
                      if (confirm(`"${section.title}" kategorisini sil?`)) run(() => deleteSection(section.id, menuId));
                    }}
                    className="flex flex-1 cursor-pointer items-center justify-center gap-1.5 rounded-lg border border-red-200 px-3 py-1.5 text-[12px] font-[700] text-red-600 hover:bg-red-50"
                  >
                    <TrashIcon /> Sil
                  </button>
                </div>
              )}
            </div>
          );
        })}

        {showNew ? (
          <form
            className="flex flex-col gap-2 rounded-2xl border border-dashed border-primary/40 bg-card p-4"
            onSubmit={(e) => {
              e.preventDefault();
              const fd = new FormData(e.currentTarget);
              const title = String(fd.get('title') ?? '');
              run(() => createSection(menuId, title, sections.length));
              setShowNew(false);
            }}
          >
            <input
              name="title"
              required
              autoFocus
              placeholder="Ör: Tatlılar"
              className="rounded-lg border border-border bg-bg px-3 py-2 text-sm text-textStrong placeholder:text-muted focus:outline-none focus:ring-2 focus:ring-primary/30"
            />
            <div className="flex gap-2">
              <button type="submit" disabled={isPending} className="flex-1 cursor-pointer rounded-lg bg-primary px-3 py-2 text-xs font-[700] text-white disabled:opacity-60">Oluştur</button>
              <button type="button" onClick={() => setShowNew(false)} className="cursor-pointer rounded-lg border border-border px-3 py-2 text-xs font-[700] text-textStrong">İptal</button>
            </div>
          </form>
        ) : (
          <button
            onClick={() => setShowNew(true)}
            className="flex min-h-[92px] cursor-pointer flex-col items-center justify-center gap-1.5 rounded-2xl border border-dashed border-border bg-card text-sm font-[700] text-muted transition-colors hover:border-primary/40 hover:text-primary"
          >
            <PlusIcon />
            Yeni Kategori
          </button>
        )}
      </div>

      {sections.length === 0 && (
        <p className="text-center text-sm text-muted">Henüz kategori yok. Yukarıdaki karttan ilk kategorinizi oluşturun.</p>
      )}
    </div>
  );
}
