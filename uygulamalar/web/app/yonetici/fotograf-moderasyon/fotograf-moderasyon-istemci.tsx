'use client';

import { useState, useTransition } from 'react';
import { useRouter } from 'next/navigation';

interface Photo {
  id: string; business_id: string; user_id: string; url: string;
  status: string; created_at: string;
  businesses: { name: string } | null;
  user_profiles: { display_name: string } | null;
}

async function moderatePhoto(photoId: string, action: 'approve' | 'reject') {
  await fetch('/sunucu/yonetici/fotograf-moderasyon', {
    method: 'PATCH',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ photoId, action }),
  });
}

export function FotografModerasyon({ photos }: { photos: Photo[] }) {
  const router = useRouter();
  const [isPending, startTransition] = useTransition();
  const [selected, setSelected] = useState<Set<string>>(new Set());
  const [filter, setFilter] = useState<'all' | 'pending' | 'flagged'>('all');

  const filtered = photos.filter(p => filter === 'all' || p.status === filter);

  const toggle = (id: string) =>
    setSelected(prev => { const s = new Set(prev); s.has(id) ? s.delete(id) : s.add(id); return s; });

  const toggleAll = () =>
    setSelected(prev => prev.size === filtered.length ? new Set() : new Set(filtered.map(p => p.id)));

  const bulkAction = (action: 'approve' | 'reject') => {
    startTransition(async () => {
      await Promise.all([...selected].map(id => moderatePhoto(id, action)));
      setSelected(new Set());
      router.refresh();
    });
  };

  return (
    <div className="flex flex-col gap-4">
      {/* Filters + bulk */}
      <div className="flex flex-wrap items-center gap-3">
        {(['all', 'pending', 'flagged'] as const).map(f => (
          <button
            key={f}
            onClick={() => setFilter(f)}
            className={`rounded-lg px-3 py-1.5 text-xs font-[700] transition-colors ${filter === f ? 'bg-primary text-white' : 'bg-surface border border-border text-muted hover:text-textStrong'}`}
          >
            {f === 'all' ? 'Tümü' : f === 'pending' ? 'Bekleyen' : 'Şikayet Edilen'}
          </button>
        ))}
        {selected.size > 0 && (
          <div className="ml-auto flex items-center gap-2">
            <span className="text-xs text-muted">{selected.size} seçili</span>
            <button
              disabled={isPending}
              onClick={() => bulkAction('approve')}
              className="rounded-lg bg-green-600 px-3 py-1.5 text-xs font-[700] text-white hover:bg-green-700 disabled:opacity-50"
            >
              Toplu Onayla
            </button>
            <button
              disabled={isPending}
              onClick={() => bulkAction('reject')}
              className="rounded-lg bg-red-600 px-3 py-1.5 text-xs font-[700] text-white hover:bg-red-700 disabled:opacity-50"
            >
              Toplu Reddet
            </button>
          </div>
        )}
      </div>

      {filtered.length === 0 ? (
        <p className="py-12 text-center text-sm text-muted">Bu filtrede fotoğraf yok</p>
      ) : (
        <div className="grid grid-cols-2 gap-3 sm:grid-cols-3 lg:grid-cols-4">
          {filtered.map(photo => (
            <div
              key={photo.id}
              className={`relative overflow-hidden rounded-xl border-2 transition-colors ${selected.has(photo.id) ? 'border-primary' : 'border-border'}`}
            >
              {/* Checkbox */}
              <button
                onClick={() => toggle(photo.id)}
                className="absolute left-2 top-2 z-10 flex h-5 w-5 items-center justify-center rounded border-2 border-white bg-white/80 backdrop-blur"
              >
                {selected.has(photo.id) && (
                  <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="var(--yd-color-primary)" strokeWidth="3">
                    <polyline points="20 6 9 17 4 12" />
                  </svg>
                )}
              </button>

              {/* Status badge */}
              <span className={`absolute right-2 top-2 z-10 rounded-full px-2 py-0.5 text-[10px] font-[700] ${photo.status === 'flagged' ? 'bg-red-500 text-white' : 'bg-yellow-400 text-yellow-900'}`}>
                {photo.status === 'flagged' ? 'Şikayet' : 'Bekliyor'}
              </span>

              {/* Image */}
              <div className="aspect-square w-full bg-zinc-100">
                {/* eslint-disable-next-line @next/next/no-img-element */}
                <img
                  src={photo.url}
                  alt={photo.businesses?.name ?? 'Fotoğraf'}
                  className="h-full w-full object-cover"
                  loading="lazy"
                />
              </div>

              {/* Info + actions */}
              <div className="p-2">
                <p className="truncate text-xs font-[700] text-textStrong">{photo.businesses?.name ?? '—'}</p>
                <p className="truncate text-[10px] text-muted">{photo.user_profiles?.display_name ?? '—'}</p>
                <div className="mt-2 flex gap-1">
                  <button
                    disabled={isPending}
                    onClick={() => {
                      startTransition(async () => {
                        await moderatePhoto(photo.id, 'approve');
                        router.refresh();
                      });
                    }}
                    className="flex-1 rounded bg-green-100 py-1 text-[10px] font-[800] text-green-700 hover:bg-green-200 disabled:opacity-50"
                  >
                    Onayla
                  </button>
                  <button
                    disabled={isPending}
                    onClick={() => {
                      startTransition(async () => {
                        await moderatePhoto(photo.id, 'reject');
                        router.refresh();
                      });
                    }}
                    className="flex-1 rounded bg-red-100 py-1 text-[10px] font-[800] text-red-700 hover:bg-red-200 disabled:opacity-50"
                  >
                    Reddet
                  </button>
                </div>
              </div>
            </div>
          ))}
        </div>
      )}

      {/* Select all */}
      {filtered.length > 0 && (
        <button onClick={toggleAll} className="text-xs font-[600] text-muted hover:text-textStrong">
          {selected.size === filtered.length ? 'Seçimi Kaldır' : 'Tümünü Seç'}
        </button>
      )}
    </div>
  );
}
