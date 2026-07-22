'use client';

import { useRef, useState, useCallback } from 'react';

export interface PhotoItem {
  id: string;
  business_id: string;
  url: string;
  url_thumb: string | null;
  status: string;
  kind: string;
  created_at: string;
}

const PHOTO_LIMIT = 10;

/** Görseli WebP'ye dönüştürür ve boyutunu küçültür (max 1920px, %82 kalite). */
async function compressToWebP(file: File): Promise<File> {
  return new Promise((resolve, reject) => {
    const img = new Image();
    const objectUrl = URL.createObjectURL(file);
    img.onload = () => {
      URL.revokeObjectURL(objectUrl);
      const MAX = 1920;
      let { width, height } = img;
      if (width > MAX || height > MAX) {
        const ratio = Math.min(MAX / width, MAX / height);
        width  = Math.round(width  * ratio);
        height = Math.round(height * ratio);
      }
      const canvas = document.createElement('canvas');
      canvas.width  = width;
      canvas.height = height;
      canvas.getContext('2d')!.drawImage(img, 0, 0, width, height);
      canvas.toBlob(
        (blob) => {
          if (!blob) { reject(new Error('compress_failed')); return; }
          resolve(new File([blob], file.name.replace(/\.[^.]+$/, '.webp'), { type: 'image/webp' }));
        },
        'image/webp',
        0.82,
      );
    };
    img.onerror = () => { URL.revokeObjectURL(objectUrl); reject(new Error('load_failed')); };
    img.src = objectUrl;
  });
}

interface Props {
  initialPhotos: PhotoItem[];
  businesses: { id: string; name: string }[];
  defaultBusinessId: string | null;
}

const STATUS_INFO: Record<string, { label: string; color: string }> = {
  approved: { label: 'Onaylı',     color: 'bg-emerald-500' },
  pending:  { label: 'İncelemede', color: 'bg-amber-400' },
  rejected: { label: 'Reddedildi', color: 'bg-zinc-400' },
};

export function PhotosClient({ initialPhotos, businesses, defaultBusinessId }: Props) {
  const [photos, setPhotos]         = useState<PhotoItem[]>(initialPhotos);
  const [businessId, setBusinessId] = useState(defaultBusinessId ?? businesses[0]?.id ?? '');
  const [uploading, setUploading]   = useState(false);
  const [uploadError, setUploadError] = useState<string | null>(null);
  const [dragOver, setDragOver]     = useState(false);
  const [deletingId, setDeletingId] = useState<string | null>(null);
  const inputRef = useRef<HTMLInputElement>(null);

  const bizPhotoCount = photos.filter((p) => p.business_id === businessId && p.status !== 'rejected').length;
  const slotsLeft = PHOTO_LIMIT - bizPhotoCount;

  const handleFiles = useCallback(async (files: FileList | null) => {
    if (!files || files.length === 0 || !businessId) return;
    setUploadError(null);

    // Limit kontrolü
    const currentCount = photos.filter((p) => p.business_id === businessId && p.status !== 'rejected').length;
    if (currentCount >= PHOTO_LIMIT) {
      setUploadError(`Bu işletme için maksimum ${PHOTO_LIMIT} fotoğraf yüklenebilir.`);
      return;
    }
    const canUpload = Math.min(Array.from(files).length, PHOTO_LIMIT - currentCount);

    setUploading(true);
    const uploaded: PhotoItem[] = [];

    for (const file of Array.from(files).slice(0, canUpload)) {
      let compressed: File;
      try {
        compressed = await compressToWebP(file);
      } catch {
        setUploadError('Görsel işlenemedi, farklı bir dosya deneyin.');
        break;
      }

      const fd = new FormData();
      fd.append('businessId', businessId);
      fd.append('file', compressed);

      const res = await fetch('/sunucu/sahip/fotograflar', { method: 'POST', body: fd });
      if (!res.ok) {
        const data = await res.json().catch(() => ({}));
        const msg = data.error === 'photo_limit_reached'
          ? `Bu işletme için maksimum ${PHOTO_LIMIT} fotoğraf yüklenebilir.`
          : data.error === 'file_too_large'
          ? 'Dosya çok büyük.'
          : data.error === 'rate_limited'
          ? 'Günlük yükleme limitine ulaşıldı.'
          : 'Yükleme başarısız, tekrar deneyin.';
        setUploadError(msg);
        break;
      }
      const data = await res.json();
      if (data.photo) uploaded.push(data.photo as PhotoItem);
    }

    if (uploaded.length > 0) setPhotos((prev) => [...uploaded, ...prev]);
    setUploading(false);
    if (inputRef.current) inputRef.current.value = '';
  // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [businessId, photos]);

  async function handleDelete(photoId: string) {
    setDeletingId(photoId);
    const res = await fetch('/sunucu/sahip/fotograflar', {
      method: 'DELETE',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ id: photoId }),
    });
    if (res.ok) {
      setPhotos((prev) => prev.filter((p) => p.id !== photoId));
    }
    setDeletingId(null);
  }

  return (
    <div className="px-6 pb-10 pt-2 flex flex-col gap-6">
      {/* İşletme seçici (birden fazla varsa) */}
      {businesses.length > 1 && (
        <div className="flex items-center gap-3">
          <label className="text-xs font-[700] text-muted">İşletme</label>
          <select
            value={businessId}
            onChange={(e) => setBusinessId(e.target.value)}
            className="rounded-xl border border-border bg-card px-3 py-2 text-sm text-textStrong focus:outline-none"
          >
            {businesses.map((b) => (
              <option key={b.id} value={b.id}>{b.name}</option>
            ))}
          </select>
        </div>
      )}

      {/* Yükleme alanı */}
      <div
        onDragOver={(e) => { e.preventDefault(); setDragOver(true); }}
        onDragLeave={() => setDragOver(false)}
        onDrop={(e) => { e.preventDefault(); setDragOver(false); handleFiles(e.dataTransfer.files); }}
        onClick={() => !uploading && slotsLeft > 0 && inputRef.current?.click()}
        className={`relative flex flex-col items-center justify-center gap-3 rounded-2xl border-2 border-dashed py-12 text-center transition-colors select-none
          ${slotsLeft <= 0
            ? 'cursor-not-allowed border-border bg-[#fafafa] opacity-60'
            : dragOver
            ? 'cursor-pointer border-[#7f1d1d] bg-[#7f1d1d]/5'
            : 'cursor-pointer border-border bg-card hover:border-[#7f1d1d]/40 hover:bg-[#fafafa]'}`}
      >
        <input
          ref={inputRef}
          type="file"
          accept="image/jpeg,image/png,image/webp"
          multiple
          className="hidden"
          onChange={(e) => handleFiles(e.target.files)}
        />
        <div className="flex h-12 w-12 items-center justify-center rounded-2xl bg-[#fef2f2]">
          <UploadIcon />
        </div>
        {uploading ? (
          <div className="flex flex-col items-center gap-2">
            <SpinnerIcon large />
            <p className="text-sm font-[700] text-[#7f1d1d]">Sıkıştırılıyor ve yükleniyor…</p>
          </div>
        ) : slotsLeft <= 0 ? (
          <div>
            <p className="text-sm font-[800] text-textStrong">Limit doldu</p>
            <p className="mt-0.5 text-xs text-muted">Bu işletme için maksimum {PHOTO_LIMIT} fotoğraf yüklenebilir.</p>
          </div>
        ) : (
          <>
            <div>
              <p className="text-sm font-[800] text-textStrong">
                {dragOver ? 'Bırakın' : 'Fotoğraf Yükle'}
              </p>
              <p className="mt-0.5 text-xs text-muted">
                Sürükle & bırak veya tıkla — JPG, PNG, WebP — WebP&apos;ye dönüştürülür
              </p>
            </div>
            <span className="rounded-full bg-zinc-100 px-3 py-1 text-[11px] font-[700] text-muted">
              {bizPhotoCount} / {PHOTO_LIMIT} fotoğraf
            </span>
          </>
        )}
        {uploadError && (
          <p className="text-xs font-[700] text-red-500">{uploadError}</p>
        )}
      </div>

      {/* Fotoğraf sayısı + durum notu */}
      {photos.length > 0 && (
        <div className="flex items-center justify-between">
          <p className="text-sm font-[700] text-textStrong">{photos.length} fotoğraf</p>
          <p className="text-xs text-muted">Yüklenen fotoğraflar WebP formatında incelemeye gönderilir</p>
        </div>
      )}

      {/* Galeri grid */}
      {photos.length === 0 ? (
        <div className="flex flex-col items-center justify-center rounded-2xl border border-dashed border-border bg-[#fafafa] py-16 text-center">
          <GalleryEmptyIcon />
          <p className="mt-3 text-base font-[800] text-textStrong">Henüz fotoğraf yok</p>
          <p className="mt-1 text-sm text-muted">Yukarıdan fotoğraf yükleyerek başlayın.</p>
        </div>
      ) : (
        <div className="grid grid-cols-2 gap-3 sm:grid-cols-3 md:grid-cols-4 xl:grid-cols-5">
          {photos.map((photo) => {
            const thumb = photo.url_thumb ?? photo.url;
            const statusInfo = STATUS_INFO[photo.status] ?? STATUS_INFO['pending'];
            const isDeleting = deletingId === photo.id;
            return (
              <div key={photo.id} className="group relative overflow-hidden rounded-2xl border border-border bg-card aspect-square">
                {/* Görsel */}
                {/* eslint-disable-next-line @next/next/no-img-element */}
                <img
                  src={thumb}
                  alt=""
                  className="h-full w-full object-cover transition-transform duration-200 group-hover:scale-105"
                  loading="lazy"
                />

                {/* Durum rozeti */}
                <div className="absolute left-2 top-2">
                  <span className={`flex items-center gap-1 rounded-full px-2 py-0.5 text-[10px] font-[800] text-white ${statusInfo.color}`}>
                    <span className="h-1.5 w-1.5 rounded-full bg-white/70" />
                    {statusInfo.label}
                  </span>
                </div>

                {/* Hover overlay + sil butonu */}
                <div className="absolute inset-0 flex items-end justify-end bg-gradient-to-t from-black/60 via-transparent opacity-0 transition-opacity group-hover:opacity-100 p-2">
                  <button
                    onClick={() => !isDeleting && handleDelete(photo.id)}
                    disabled={isDeleting}
                    title="Fotoğrafı sil"
                    className="flex h-8 w-8 items-center justify-center rounded-xl bg-white/90 text-red-600 shadow-sm backdrop-blur-sm transition hover:bg-red-500 hover:text-white disabled:opacity-60"
                  >
                    {isDeleting ? <SpinnerIcon /> : <TrashIcon />}
                  </button>
                </div>
              </div>
            );
          })}
        </div>
      )}
    </div>
  );
}

// ── Icons ──────────────────────────────────────────────────────────────────

function UploadIcon() {
  return (
    <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="#dc2626" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4" />
      <polyline points="17 8 12 3 7 8" />
      <line x1="12" y1="3" x2="12" y2="15" />
    </svg>
  );
}

function TrashIcon() {
  return (
    <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <polyline points="3 6 5 6 21 6" />
      <path d="M19 6l-1 14H6L5 6" />
      <path d="M10 11v6M14 11v6" />
      <path d="M9 6V4h6v2" />
    </svg>
  );
}

function SpinnerIcon({ large }: { large?: boolean }) {
  const s = large ? 28 : 14;
  return (
    <svg width={s} height={s} viewBox="0 0 24 24" fill="none" stroke={large ? '#dc2626' : 'currentColor'} strokeWidth="2.5" strokeLinecap="round" className="animate-spin">
      <path d="M21 12a9 9 0 1 1-6.219-8.56" />
    </svg>
  );
}

function GalleryEmptyIcon() {
  return (
    <svg width="36" height="36" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round" className="text-muted">
      <rect x="3" y="3" width="18" height="18" rx="2" ry="2" />
      <circle cx="8.5" cy="8.5" r="1.5" />
      <polyline points="21 15 16 10 5 21" />
    </svg>
  );
}
