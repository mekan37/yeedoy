'use client';

import { useRouter, useSearchParams, usePathname } from 'next/navigation';
import { useCallback } from 'react';

const KATEGORILER = [
  'Restoran',
  'Kafe',
  'Tatlıcı',
  'Fast Food',
  'Kahvaltı',
  'Pastane',
  'Bar',
  'Fırın',
];


export function EnIyilerFiltreSidebar() {
  const router = useRouter();
  const pathname = usePathname();
  const searchParams = useSearchParams();

  const sort = searchParams.get('sort') ?? 'rating';
  const city = searchParams.get('city') ?? '';
  const category = searchParams.get('category') ?? '';

  const update = useCallback(
    (key: string, value: string) => {
      const params = new URLSearchParams(searchParams.toString());
      if (value) {
        params.set(key, value);
      } else {
        params.delete(key);
      }
      router.push(`${pathname}?${params.toString()}`);
    },
    [router, pathname, searchParams],
  );

  const handleCityChange = useCallback(
    (e: React.FormEvent<HTMLFormElement>) => {
      e.preventDefault();
      const form = e.currentTarget;
      const val = (form.elements.namedItem('city') as HTMLInputElement).value.trim();
      update('city', val);
    },
    [update],
  );

  const hasFilters = sort !== 'rating' || city || category;

  return (
    <aside className="w-full space-y-5 rounded-2xl border border-border bg-card p-5 shadow-yd1 lg:w-56 lg:shrink-0 lg:self-start lg:sticky lg:top-20">
      <p className="text-sm font-black text-textStrong">Filtrele</p>

      {/* Sırala */}
      <div className="space-y-1.5">
        <label className="text-xs font-extrabold text-muted">Sırala</label>
        <div className="relative">
          <select
            value={sort}
            onChange={(e) => update('sort', e.target.value)}
            className="w-full appearance-none rounded-xl border border-border bg-surface py-2.5 pl-3 pr-8 text-sm font-extrabold text-textStrong focus:border-primary focus:outline-hidden focus:ring-2 focus:ring-primary/20"
          >
            <option value="rating">En Yüksek Puan</option>
            <option value="reviews">En Çok Yorum</option>
          </select>
          <span className="pointer-events-none absolute inset-y-0 right-3 flex items-center text-muted" aria-hidden="true">
            <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round">
              <path d="m6 9 6 6 6-6" />
            </svg>
          </span>
        </div>
      </div>

      {/* Konum */}
      <div className="space-y-1.5">
        <label className="text-xs font-extrabold text-muted">Konum</label>
        <form onSubmit={handleCityChange}>
          <div className="relative">
            <span className="absolute inset-y-0 left-3 flex items-center text-muted" aria-hidden="true">
              <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round">
                <path d="M21 10c0 7-9 13-9 13s-9-6-9-13a9 9 0 0 1 18 0z" /><circle cx="12" cy="10" r="3" />
              </svg>
            </span>
            <input
              name="city"
              type="text"
              defaultValue={city}
              placeholder="Şehir filtrele"
              className="w-full rounded-xl border border-border bg-surface py-2.5 pl-8 pr-3 text-sm font-bold text-textStrong placeholder:text-muted focus:border-primary focus:outline-hidden focus:ring-2 focus:ring-primary/20"
            />
          </div>
        </form>
      </div>

      {/* Kategori */}
      <div className="space-y-1.5">
        <label className="text-xs font-extrabold text-muted">Kategori</label>
        <div className="relative">
          <select
            value={category}
            onChange={(e) => update('category', e.target.value)}
            className="w-full appearance-none rounded-xl border border-border bg-surface py-2.5 pl-3 pr-8 text-sm font-extrabold text-textStrong focus:border-primary focus:outline-hidden focus:ring-2 focus:ring-primary/20"
          >
            <option value="">Tümü</option>
            {KATEGORILER.map((k) => (
              <option key={k} value={k}>{k}</option>
            ))}
          </select>
          <span className="pointer-events-none absolute inset-y-0 right-3 flex items-center text-muted" aria-hidden="true">
            <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round">
              <path d="m6 9 6 6 6-6" />
            </svg>
          </span>
        </div>
      </div>

      {/* Temizle */}
      {hasFilters && (
        <button
          type="button"
          onClick={() => router.push(pathname)}
          className="flex w-full items-center justify-center gap-2 rounded-xl border border-border bg-surface py-2.5 text-xs font-extrabold text-muted transition-colors hover:border-danger/40 hover:text-danger"
        >
          <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" aria-hidden="true">
            <path d="M18 6 6 18M6 6l12 12" />
          </svg>
          Filtreleri Temizle
        </button>
      )}
    </aside>
  );
}
