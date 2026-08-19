'use client';

import { useState, useTransition } from 'react';
import { useRouter } from 'next/navigation';
import { kindEtiket, STATUS_ETIKETLERI, STATUS_RENKLERI, fotografCsvOlustur, type ModerasyonFotografi } from './fotograf-moderasyon-yardimcilari';

async function moderatePhoto(photoId: string, action: 'approve' | 'reject') {
  return fetch('/sunucu/yonetici/fotograf-moderasyon', {
    method: 'PATCH',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ photoId, action }),
  });
}

export function FotografModerasyon({ photos }: { photos: ModerasyonFotografi[] }) {
  const router = useRouter();
  const [isPending, startTransition] = useTransition();
  const [selected, setSelected] = useState<Set<string>>(new Set());

  const toggle = (id: string) =>
    setSelected((prev) => { const s = new Set(prev); s.has(id) ? s.delete(id) : s.add(id); return s; });

  const toggleAll = () =>
    setSelected((prev) => (prev.size === photos.length ? new Set() : new Set(photos.map((p) => p.id))));

  const bulkAction = (action: 'approve' | 'reject') => {
    startTransition(async () => {
      await Promise.all([...selected].map((id) => moderatePhoto(id, action)));
      setSelected(new Set());
      router.refresh();
    });
  };

  const disaAktar = () => {
    const csv = fotografCsvOlustur(photos);
    const blob = new Blob(['﻿' + csv], { type: 'text/csv;charset=utf-8;' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `fotograf-moderasyon-${new Date().toISOString().slice(0, 10)}.csv`;
    a.click();
    URL.revokeObjectURL(url);
  };

  return (
    <div className="flex flex-col gap-4">
      <div className="flex flex-wrap items-center gap-3">
        <button onClick={toggleAll} className="text-xs font-bold text-muted hover:text-textStrong">
          {selected.size === photos.length ? 'Seçimi Kaldır' : 'Tümünü Seç'}
        </button>
        <button onClick={disaAktar} className="ml-auto flex items-center gap-1.5 rounded-lg border border-border px-3 py-1.5 text-xs font-extrabold text-textStrong hover:border-primary/30 hover:text-primary">
          <DownloadIcon /> Dışa Aktar
        </button>
        {selected.size > 0 && (
          <div className="flex items-center gap-2 rounded-xl border border-primary/30 bg-primary/5 px-3 py-2">
            <span className="text-xs font-extrabold text-textStrong">{selected.size} seçili</span>
            <button
              disabled={isPending}
              onClick={() => bulkAction('approve')}
              className="rounded-lg bg-emerald-600 px-3 py-1.5 text-xs font-bold text-white hover:bg-emerald-700 disabled:opacity-50"
            >
              Toplu Onayla
            </button>
            <button
              disabled={isPending}
              onClick={() => bulkAction('reject')}
              className="rounded-lg bg-red-600 px-3 py-1.5 text-xs font-bold text-white hover:bg-red-700 disabled:opacity-50"
            >
              Toplu Reddet
            </button>
          </div>
        )}
      </div>

      <div className="grid grid-cols-2 gap-3 sm:grid-cols-3 lg:grid-cols-4">
        {photos.map((photo) => (
          <div
            key={photo.id}
            className={`relative overflow-hidden rounded-xl border-2 bg-card transition-colors ${selected.has(photo.id) ? 'border-primary' : 'border-border'}`}
          >
            <button
              onClick={() => toggle(photo.id)}
              className="absolute left-2 top-2 z-10 flex h-5 w-5 items-center justify-center rounded border-2 border-white bg-white/80 backdrop-blur-xs"
              aria-label="Seç"
            >
              {selected.has(photo.id) && (
                <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="var(--yd-color-primary)" strokeWidth="3">
                  <polyline points="20 6 9 17 4 12" />
                </svg>
              )}
            </button>

            <span className={`absolute right-2 top-2 z-10 rounded-full px-2 py-0.5 text-[10px] font-bold ${photo.is_hidden ? 'bg-red-500 text-white' : STATUS_RENKLERI[photo.status] ?? 'bg-zinc-100 text-zinc-600'}`}>
              {photo.is_hidden ? 'Gizli' : (STATUS_ETIKETLERI[photo.status] ?? photo.status)}
            </span>

            <div className="aspect-square w-full bg-zinc-100">
              {/* eslint-disable-next-line @next/next/no-img-element */}
              <img
                src={photo.url_thumb || photo.url}
                alt={photo.business_name ?? 'Fotoğraf'}
                className="h-full w-full object-cover"
                loading="lazy"
              />
            </div>

            <div className="p-2">
              <p className="truncate text-xs font-bold text-textStrong">{photo.business_name ?? '—'}</p>
              <p className="flex items-center gap-1 truncate text-[10px] text-muted">
                {photo.business_category ?? '—'} · {kindEtiket(photo.kind)}
              </p>
              <p className="text-[10px] text-muted">{new Date(photo.created_at).toLocaleDateString('tr-TR')}</p>
              <div className="mt-2 flex gap-1">
                <button
                  disabled={isPending}
                  onClick={() => startTransition(async () => { await moderatePhoto(photo.id, 'approve'); router.refresh(); })}
                  className="flex-1 rounded bg-emerald-100 py-1 text-[10px] font-extrabold text-emerald-700 hover:bg-emerald-200 disabled:opacity-50"
                >
                  Onayla
                </button>
                <button
                  disabled={isPending}
                  onClick={() => startTransition(async () => { await moderatePhoto(photo.id, 'reject'); router.refresh(); })}
                  className="flex-1 rounded bg-red-100 py-1 text-[10px] font-extrabold text-red-700 hover:bg-red-200 disabled:opacity-50"
                >
                  Reddet
                </button>
              </div>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}

function DownloadIcon() {
  return (
    <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4" /><polyline points="7 10 12 15 17 10" /><line x1="12" y1="15" x2="12" y2="3" />
    </svg>
  );
}
