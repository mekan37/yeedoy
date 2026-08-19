'use client';

import { useState, useTransition } from 'react';
import { adminRestoreMenu, adminPermanentlyDeleteMenu } from './cop-kutusu-islemleri';
import { menuNoOlustur, type SilinmisMenuSatiri } from './cop-kutusu-yardimcilari';

export function MenuSatiriRow({
  row,
  selected,
  onToggleSelect,
}: {
  row: SilinmisMenuSatiri;
  selected: boolean;
  onToggleSelect: (id: string) => void;
}) {
  const [isPending, startTransition] = useTransition();
  const [gone, setGone] = useState(false);
  const [confirmDelete, setConfirmDelete] = useState(false);
  const [error, setError] = useState<string | null>(null);

  function handleRestore() {
    setError(null);
    startTransition(async () => {
      const res = await adminRestoreMenu(row.id);
      if (res.error) setError(res.error); else setGone(true);
    });
  }
  function handleDelete() {
    setError(null);
    startTransition(async () => {
      const res = await adminPermanentlyDeleteMenu(row.id);
      if (res.error) setError(res.error); else setGone(true);
    });
  }

  if (gone) {
    return (
      <tr>
        <td colSpan={7} className="px-5 py-3 text-xs italic text-muted">İşlendi — {row.title}</td>
      </tr>
    );
  }

  const suresiGecmis = row.activeTo && new Date(row.activeTo).getTime() < Date.now();

  return (
    <tr className="hover:bg-black/2">
      <td className="px-4 py-3">
        <input type="checkbox" checked={selected} onChange={() => onToggleSelect(row.id)} className="h-4 w-4 rounded border-border" />
      </td>
      <td className="px-5 py-3">
        <p className="font-bold text-textStrong">{row.title}</p>
        <p className="font-mono text-xs text-muted">{menuNoOlustur(row.id)}</p>
      </td>
      <td className="px-5 py-3">
        <p className="text-textStrong">{row.businessName ?? '—'}</p>
        <p className="text-xs text-muted">{[row.businessDistrict, row.businessCity].filter(Boolean).join(', ')}</p>
      </td>
      <td className="px-5 py-3">
        <p className="text-xs font-bold text-textStrong">{row.ownerName ?? '—'}</p>
      </td>
      <td className="px-5 py-3 text-xs text-muted">{new Date(row.updatedAt).toLocaleDateString('tr-TR')}</td>
      <td className="px-5 py-3">
        {row.activeTo ? (
          <span className={`text-xs font-bold ${suresiGecmis ? 'text-red-600' : 'text-muted'}`}>
            {new Date(row.activeTo).toLocaleDateString('tr-TR')}{suresiGecmis ? ' (geçti)' : ''}
          </span>
        ) : (
          <span className="text-xs text-muted">—</span>
        )}
      </td>
      <td className="px-5 py-3">
        <div className="flex items-center justify-end gap-1.5">
          {error && <span className="text-[10px] font-bold text-red-600">{error}</span>}
          <button
            type="button"
            disabled={isPending}
            onClick={handleRestore}
            title="Geri yükle"
            className="flex h-8 w-8 items-center justify-center rounded-lg border border-border text-muted transition-colors hover:border-emerald-300 hover:text-emerald-600 disabled:opacity-50"
          >
            <RestoreIcon />
          </button>
          {confirmDelete ? (
            <div className="flex items-center gap-1">
              <button type="button" disabled={isPending} onClick={handleDelete} className="rounded-lg bg-red-600 px-2 py-1.5 text-[11px] font-extrabold text-white disabled:opacity-50">
                Onayla
              </button>
              <button type="button" onClick={() => setConfirmDelete(false)} className="rounded-lg border border-border px-2 py-1.5 text-[11px] font-extrabold text-muted">
                Vazgeç
              </button>
            </div>
          ) : (
            <button
              type="button"
              disabled={isPending}
              onClick={() => setConfirmDelete(true)}
              title="Kalıcı olarak sil"
              className="flex h-8 w-8 items-center justify-center rounded-lg border border-border text-muted transition-colors hover:border-red-300 hover:text-red-600 disabled:opacity-50"
            >
              <TrashIcon />
            </button>
          )}
        </div>
      </td>
    </tr>
  );
}

function RestoreIcon() {
  return <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><polyline points="1 4 1 10 7 10" /><path d="M3.51 15a9 9 0 1 0 2.13-9.36L1 10" /></svg>;
}
function TrashIcon() {
  return <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><polyline points="3 6 5 6 21 6" /><path d="M19 6l-1 14a2 2 0 0 1-2 2H8a2 2 0 0 1-2-2L5 6" /></svg>;
}
