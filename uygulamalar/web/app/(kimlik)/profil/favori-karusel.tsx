'use client';

import { useRef } from 'react';
import Link from 'next/link';

export type FavoriIsletme = {
  id: string;
  name: string;
  category: string | null;
  district: string | null;
  slug: string | null;
  logo_url: string | null;
  cover_url: string | null;
  avg_rating?: number | null;
  reviews_count?: number | null;
};

export function FavoriKarusel({ isletmeler }: { isletmeler: FavoriIsletme[] }) {
  const ref = useRef<HTMLDivElement>(null);

  function kaydir(yon: 'sol' | 'sag') {
    ref.current?.scrollBy({ left: yon === 'sag' ? 300 : -300, behavior: 'smooth' });
  }

  if (isletmeler.length === 0) {
    return (
      <div className="flex h-40 items-center justify-center rounded-2xl border border-dashed border-border text-sm font-[700] text-muted">
        Henüz favori mekan eklemedin.
      </div>
    );
  }

  return (
    <div className="relative">
      {/* Sol ok */}
      <button
        type="button"
        onClick={() => kaydir('sol')}
        aria-label="Geri"
        className="absolute -left-3 top-1/2 z-10 hidden -translate-y-1/2 md:flex h-9 w-9 items-center justify-center rounded-full border border-border bg-card shadow-yd2 text-textStrong transition hover:bg-primary hover:text-white hover:border-primary"
      >
        <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" aria-hidden="true">
          <path d="M15 18l-6-6 6-6" />
        </svg>
      </button>

      {/* Kaydırma kutusu */}
      <div
        ref={ref}
        className="flex gap-4 overflow-x-auto pb-2 scrollbar-hide"
        style={{ scrollSnapType: 'x mandatory' }}
      >
        {isletmeler.map((b) => {
          const href = b.slug ? `/m/${b.slug}` : '#';
          const img = b.logo_url ?? b.cover_url ?? null;

          return (
            <Link
              key={b.id}
              href={href}
              style={{ scrollSnapAlign: 'start' }}
              className="group w-44 shrink-0 overflow-hidden rounded-2xl border border-border bg-card shadow-yd1 transition hover:shadow-yd2 hover:-translate-y-0.5"
            >
              {/* Görsel */}
              <div className="relative h-28 w-full overflow-hidden bg-cardAlt">
                {img ? (
                  // eslint-disable-next-line @next/next/no-img-element
                  <img src={img} alt={b.name} className="h-full w-full object-cover transition-transform duration-300 group-hover:scale-105" />
                ) : (
                  <div className="flex h-full w-full items-center justify-center text-3xl">🍽️</div>
                )}
                {/* Kalp rozeti */}
                <div className="absolute right-2 top-2 flex h-7 w-7 items-center justify-center rounded-full bg-white/90 shadow-sm">
                  <svg width="14" height="14" viewBox="0 0 24 24" fill="#ef4444" stroke="#ef4444" strokeWidth="1.5" aria-hidden="true">
                    <path d="M20.84 4.61a5.5 5.5 0 0 0-7.78 0L12 5.67l-1.06-1.06a5.5 5.5 0 0 0-7.78 7.78l1.06 1.06L12 21.23l7.78-7.78 1.06-1.06a5.5 5.5 0 0 0 0-7.78z"/>
                  </svg>
                </div>
              </div>

              {/* Bilgi */}
              <div className="p-3">
                <p className="truncate text-[13px] font-[900] text-textStrong">{b.name}</p>
                <p className="mt-0.5 truncate text-[11px] font-[700] text-muted">
                  {[b.category, b.district].filter(Boolean).join(' · ')}
                </p>
                {b.avg_rating != null && (
                  <div className="mt-1.5 flex items-center gap-1">
                    <svg width="11" height="11" viewBox="0 0 24 24" fill="#f59e0b" aria-hidden="true">
                      <path d="M12 2l3.09 6.26L22 9.27l-5 4.87 1.18 6.88L12 17.77l-6.18 3.25L7 14.14 2 9.27l6.91-1.01L12 2z"/>
                    </svg>
                    <span className="text-[11px] font-[800] text-textStrong">{b.avg_rating.toFixed(1)}</span>
                    {b.reviews_count != null && (
                      <span className="text-[10px] font-[700] text-muted">({b.reviews_count})</span>
                    )}
                  </div>
                )}
              </div>
            </Link>
          );
        })}
      </div>

      {/* Sağ ok */}
      <button
        type="button"
        onClick={() => kaydir('sag')}
        aria-label="İleri"
        className="absolute -right-3 top-1/2 z-10 hidden -translate-y-1/2 md:flex h-9 w-9 items-center justify-center rounded-full border border-border bg-card shadow-yd2 text-textStrong transition hover:bg-primary hover:text-white hover:border-primary"
      >
        <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" aria-hidden="true">
          <path d="M9 18l6-6-6-6" />
        </svg>
      </button>
    </div>
  );
}
