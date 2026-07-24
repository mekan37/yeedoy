'use client';

import { useState, useEffect, useRef } from 'react';
import { AnlikArama } from '@/src/ui/acik/anlik-arama';

export function NavAramaButonu() {
  const [acik, setAcik] = useState(false);
  const modalRef = useRef<HTMLDivElement>(null);

  // Modal dışına tıklayınca kapat (pointerdown — click'ten önce çalışır)
  useEffect(() => {
    if (!acik) return;
    function handlePointer(e: PointerEvent) {
      if (modalRef.current && !modalRef.current.contains(e.target as Node)) {
        setAcik(false);
      }
    }
    // Sonraki tick'te kayıt yap: açma tıklaması tetiklemesin
    const id = setTimeout(() => {
      document.addEventListener('pointerdown', handlePointer);
    }, 0);
    return () => {
      clearTimeout(id);
      document.removeEventListener('pointerdown', handlePointer);
    };
  }, [acik]);

  // ESC ile kapat + body scroll kilitle
  useEffect(() => {
    if (!acik) return;
    const prev = document.body.style.overflow;
    document.body.style.overflow = 'hidden';
    function handleKey(e: KeyboardEvent) {
      if (e.key === 'Escape') setAcik(false);
    }
    document.addEventListener('keydown', handleKey);
    return () => {
      document.body.style.overflow = prev;
      document.removeEventListener('keydown', handleKey);
    };
  }, [acik]);

  // Ctrl+K / Cmd+K global kısayol
  useEffect(() => {
    function handleShortcut(e: KeyboardEvent) {
      if ((e.ctrlKey || e.metaKey) && e.key === 'k') {
        e.preventDefault();
        setAcik((v) => !v);
      }
    }
    document.addEventListener('keydown', handleShortcut);
    return () => document.removeEventListener('keydown', handleShortcut);
  }, []);

  // Modal açılınca input'u focus et
  useEffect(() => {
    if (!acik) return;
    const id = setTimeout(() => {
      modalRef.current?.querySelector<HTMLInputElement>('input[type="search"]')?.focus();
    }, 60);
    return () => clearTimeout(id);
  }, [acik]);

  return (
    <>
      {/* Navbar butonu */}
      <button
        type="button"
        onClick={() => setAcik(true)}
        aria-label="Ara (Ctrl+K)"
        title="Ara (Ctrl+K)"
        className="inline-flex min-h-[40px] min-w-[40px] items-center justify-center rounded-full border border-border bg-cardAlt text-muted transition-all duration-200 hover:border-primary/30 hover:text-textStrong focus-visible:outline-hidden focus-visible:ring-2 focus-visible:ring-primary/30"
      >
        <svg viewBox="0 0 24 24" className="h-4 w-4 fill-none stroke-current" strokeWidth="2" strokeLinecap="round" aria-hidden="true">
          <circle cx="11" cy="11" r="8" />
          <path d="m21 21-4.35-4.35" />
        </svg>
      </button>

      {/* Arama overlay */}
      {acik && (
        <div className="fixed inset-0 z-50" aria-modal="true" role="dialog" aria-label="Arama">
          {/* Görsel backdrop — pointer-events yok, tıklamayı engellemez */}
          <div className="absolute inset-0 bg-black/65" aria-hidden="true" />

          {/* Modal içerik — pointerdown burada yakalanır, dışarıya geçmez */}
          <div ref={modalRef} className="relative mx-auto mt-[72px] w-full max-w-2xl px-4">

            {/* Üst başlık */}
            <div className="mb-2 flex items-center justify-between px-1">
              <span className="text-xs font-extrabold text-white/60">Yeedoy&apos;da Ara</span>
              <div className="flex items-center gap-2">
                <span className="hidden rounded-md border border-white/20 bg-white/10 px-1.5 py-0.5 text-[10px] font-extrabold text-white/60 sm:inline">
                  ESC
                </span>
                <button
                  type="button"
                  onClick={() => setAcik(false)}
                  aria-label="Aramayı kapat"
                  className="flex h-7 w-7 items-center justify-center rounded-full bg-white/10 text-white/70 hover:bg-white/20 hover:text-white transition"
                >
                  <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" aria-hidden="true">
                    <line x1="18" y1="6" x2="6" y2="18" />
                    <line x1="6" y1="6" x2="18" y2="18" />
                  </svg>
                </button>
              </div>
            </div>

            {/* Arama kutusu */}
            <AnlikArama />
          </div>
        </div>
      )}
    </>
  );
}
