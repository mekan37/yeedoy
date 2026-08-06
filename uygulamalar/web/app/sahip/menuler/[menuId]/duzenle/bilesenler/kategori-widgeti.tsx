'use client';

import { useState, useTransition } from 'react';
import Link from 'next/link';
import { Section } from '../menu-duzenleyici-yardimcilari';
import { createSection, updateSection, deleteSection } from '../menu-islemleri';

export function KategoriWidgeti({
  menuId,
  sections,
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

  function run(action: () => Promise<{ error: string } | null>) {
    setError(null);
    startTransition(async () => {
      const result = await action();
      if (result?.error) setError(result.error);
    });
  }

  return (
    <div className="rounded-2xl border border-border bg-card p-4">
      <h3 className="mb-3 text-sm font-black text-textStrong">Kategori Yönetimi</h3>
      {error && <p className="mb-2 text-xs font-bold text-red-600">{error}</p>}
      <div className="flex flex-col gap-1.5">
        {sections.map((section) => (
          <div key={section.id} className="flex items-center justify-between gap-2 rounded-xl border border-border px-3 py-2">
            {editingId === section.id ? (
              <form
                className="flex flex-1 items-center gap-1.5"
                onSubmit={(e) => {
                  e.preventDefault();
                  const fd = new FormData(e.currentTarget);
                  run(() => updateSection(section.id, menuId, String(fd.get('title') ?? '')));
                  setEditingId(null);
                }}
              >
                <input name="title" defaultValue={section.title} required autoFocus className="min-w-0 flex-1 rounded-lg border border-border bg-bg px-2 py-1 text-xs text-textStrong" />
                <button type="submit" className="rounded-lg bg-primary px-2 py-1 text-[11px] font-bold text-white cursor-pointer">Kaydet</button>
                <button type="button" onClick={() => setEditingId(null)} className="rounded-lg border border-border px-2 py-1 text-[11px] font-bold text-textStrong cursor-pointer">İptal</button>
              </form>
            ) : (
              <>
                <span className="truncate text-sm font-semibold text-textStrong">{section.title}</span>
                <div className="flex shrink-0 items-center gap-2">
                  <span className="text-xs font-bold text-muted">{itemCounts[section.id] ?? 0} ürün</span>
                  <button type="button" onClick={() => setEditingId(section.id)} className="text-xs font-bold text-primary hover:underline cursor-pointer">Düzenle</button>
                  <button
                    type="button"
                    onClick={() => { if (confirm(`"${section.title}" bölümünü sil?`)) run(() => deleteSection(section.id, menuId)); }}
                    className="text-xs font-bold text-red-600 hover:underline cursor-pointer"
                  >
                    Sil
                  </button>
                </div>
              </>
            )}
          </div>
        ))}
      </div>

      {showNew ? (
        <form
          className="mt-2 flex items-center gap-1.5"
          onSubmit={(e) => {
            e.preventDefault();
            const fd = new FormData(e.currentTarget);
            run(() => createSection(menuId, String(fd.get('title') ?? ''), sections.length));
            setShowNew(false);
          }}
        >
          <input name="title" required autoFocus placeholder="Kategori adı" className="min-w-0 flex-1 rounded-lg border border-border bg-bg px-2 py-1 text-xs text-textStrong" />
          <button type="submit" disabled={isPending} className="rounded-lg bg-primary px-2 py-1 text-[11px] font-bold text-white disabled:opacity-60 cursor-pointer">Ekle</button>
          <button type="button" onClick={() => setShowNew(false)} className="rounded-lg border border-border px-2 py-1 text-[11px] font-bold text-textStrong cursor-pointer">İptal</button>
        </form>
      ) : (
        <button type="button" onClick={() => setShowNew(true)} className="mt-2 text-xs font-bold text-primary hover:underline cursor-pointer">
          + Kategori Ekle
        </button>
      )}

      <Link href={`/sahip/menuler/${menuId}/kategoriler`} className="mt-3 block rounded-xl border border-border px-3 py-2 text-center text-xs font-bold text-textStrong hover:bg-bg">
        Tüm Kategorileri Yönet
      </Link>
    </div>
  );
}
