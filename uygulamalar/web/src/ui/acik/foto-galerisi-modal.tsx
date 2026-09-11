'use client';

import { useState, useEffect, useCallback, useRef } from 'react';
import { createPortal } from 'react-dom';
import Image from 'next/image';

export type GaleriPhoto = { url: string; name: string };

export function FotoGalerisiTetik({
  photos,
  index,
  children,
}: {
  photos: GaleriPhoto[];
  index: number;
  children: React.ReactNode;
}) {
  const [open, setOpen] = useState(false);
  const [current, setCurrent] = useState(index);
  const dialogRef = useRef<HTMLDivElement | null>(null);
  const triggerRef = useRef<HTMLButtonElement | null>(null);

  const prev = useCallback(
    () => setCurrent((i) => (i - 1 + photos.length) % photos.length),
    [photos.length],
  );
  const next = useCallback(
    () => setCurrent((i) => (i + 1) % photos.length),
    [photos.length],
  );

  useEffect(() => {
    if (!open) return;

    // Focus trap: Tab/Shift+Tab modal dışına çıkmasın (arkadaki sayfa
    // içeriği görsel olarak gizli ama hâlâ DOM'da ve tab-erişilebilir).
    function getFocusable(): HTMLElement[] {
      const root = dialogRef.current;
      if (!root) return [];
      return Array.from(
        root.querySelectorAll<HTMLElement>(
          'a[href], button:not([disabled]), textarea, input, select, [tabindex]:not([tabindex="-1"])',
        ),
      );
    }

    function onKey(e: KeyboardEvent) {
      if (e.key === 'Escape') { setOpen(false); return; }
      if (e.key === 'ArrowLeft') prev();
      if (e.key === 'ArrowRight') next();
      if (e.key !== 'Tab') return;

      const focusable = getFocusable();
      if (focusable.length === 0) return;
      const first = focusable[0];
      const last = focusable[focusable.length - 1];
      const activeEl = document.activeElement;

      if (e.shiftKey && activeEl === first) {
        e.preventDefault();
        last.focus();
      } else if (!e.shiftKey && activeEl === last) {
        e.preventDefault();
        first.focus();
      } else if (!root_contains(activeEl)) {
        // Odak modal dışına kaçtıysa (ör. içerik değişimiyle) başa döndür.
        e.preventDefault();
        first.focus();
      }
    }

    function root_contains(el: Element | null) {
      return !!el && !!dialogRef.current?.contains(el);
    }

    window.addEventListener('keydown', onKey);
    document.body.style.overflow = 'hidden';
    dialogRef.current?.focus();
    const triggerEl = triggerRef.current;

    return () => {
      window.removeEventListener('keydown', onKey);
      document.body.style.overflow = '';
      triggerEl?.focus();
    };
  }, [open, prev, next]);

  function handleOpen() {
    setCurrent(index);
    setOpen(true);
  }

  const photo = photos[current];

  return (
    <>
      <button
        ref={triggerRef}
        type="button"
        onClick={handleOpen}
        className="group relative block h-full w-full cursor-zoom-in"
        aria-label={`Fotoğrafı büyüt: ${photos[index].name}`}
      >
        {children}
      </button>

      {open &&
        typeof document !== 'undefined' &&
        createPortal(
          <div
            ref={dialogRef}
            role="dialog"
            aria-modal="true"
            aria-label="Fotoğraf galerisi"
            tabIndex={-1}
            className="fixed inset-0 z-9999 flex items-center justify-center bg-black/90 backdrop-blur-xs outline-hidden"
            onClick={() => setOpen(false)}
          >
            {/* Modal içi — tıklama yayılımını durdur */}
            <div
              className="relative flex max-h-screen w-full max-w-5xl flex-col items-center px-4 py-12"
              onClick={(e) => e.stopPropagation()}
            >
              {/* Kapat */}
              <button
                type="button"
                onClick={() => setOpen(false)}
                className="absolute right-4 top-2 flex h-10 w-10 items-center justify-center rounded-full bg-white/10 text-white hover:bg-white/25 transition-colors"
                aria-label="Kapat"
              >
                <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" aria-hidden="true">
                  <path d="M18 6 6 18M6 6l12 12" />
                </svg>
              </button>

              {/* Resim */}
              <div className="relative w-full" style={{ maxHeight: 'calc(100vh - 160px)' }}>
                <Image
                  key={photo.url}
                  src={photo.url}
                  alt={photo.name}
                  width={1200}
                  height={800}
                  className="mx-auto max-h-[calc(100vh-160px)] w-auto rounded-2xl object-contain shadow-2xl"
                  priority
                />
              </div>

              {/* Altta: başlık + sayaç */}
              <div className="mt-4 flex w-full items-center justify-between gap-4">
                <p className="truncate text-sm font-bold text-white/80">{photo.name}</p>
                <span className="shrink-0 text-xs font-extrabold text-white/50">
                  {current + 1} / {photos.length}
                </span>
              </div>

              {/* Thumbnail şeridi */}
              {photos.length > 1 && (
                <div className="mt-3 flex gap-2 overflow-x-auto pb-1">
                  {photos.map((p, i) => (
                    <button
                      key={i}
                      type="button"
                      onClick={() => setCurrent(i)}
                      className={`relative h-14 w-14 shrink-0 overflow-hidden rounded-[10px] transition-all ${i === current ? 'ring-2 ring-white opacity-100' : 'opacity-50 hover:opacity-80'}`}
                      aria-label={`Fotoğraf ${i + 1}: ${p.name}`}
                    >
                      <Image src={p.url} alt={p.name} fill sizes="56px" className="object-cover" />
                    </button>
                  ))}
                </div>
              )}
            </div>

            {/* Prev / Next okları */}
            {photos.length > 1 && (
              <>
                <button
                  type="button"
                  onClick={(e) => { e.stopPropagation(); prev(); }}
                  className="absolute left-2 top-1/2 -translate-y-1/2 flex h-12 w-12 items-center justify-center rounded-full bg-white/10 text-white hover:bg-white/25 transition-colors sm:left-6"
                  aria-label="Önceki fotoğraf"
                >
                  <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" aria-hidden="true">
                    <path d="m15 18-6-6 6-6" />
                  </svg>
                </button>
                <button
                  type="button"
                  onClick={(e) => { e.stopPropagation(); next(); }}
                  className="absolute right-2 top-1/2 -translate-y-1/2 flex h-12 w-12 items-center justify-center rounded-full bg-white/10 text-white hover:bg-white/25 transition-colors sm:right-6"
                  aria-label="Sonraki fotoğraf"
                >
                  <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" aria-hidden="true">
                    <path d="m9 18 6-6-6-6" />
                  </svg>
                </button>
              </>
            )}
          </div>,
          document.body,
        )}
    </>
  );
}
