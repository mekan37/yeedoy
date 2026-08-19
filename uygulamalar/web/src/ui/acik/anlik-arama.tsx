'use client';

import { useState, useEffect, useRef, useCallback } from 'react';
import Link from 'next/link';
import Image from 'next/image';
import { Utensils } from 'lucide-react';
import { buildMenuImageUrl } from '@/src/lib/medya-adresi';

// ── Tipler ───────────────────────────────────────────────────────────────────

type BizResult = {
  id: string;
  name: string;
  slug: string | null;
  category: string | null;
  city: string | null;
  district: string | null;
  logoUrl: string | null;
  coverUrl: string | null;
  isVerified: boolean;
  isOpenNow: boolean | null;
  distanceKm: number | null;
  avgRating: number | null;
};

type ItemResult = {
  id: string;
  name: string;
  description: string | null;
  price_cents: number | null;
  image_url: string | null;
  businessName: string;
  businessSlug: string;
};

type SearchResults = {
  businesses: BizResult[];
  items: ItemResult[];
};

const POPULAR = ['Adana Kebap', 'Pide', 'Döner', 'Burger', 'Kahvaltı', 'Pizza', 'Tatlı', 'Çorba'];

// ── Yardımcı ─────────────────────────────────────────────────────────────────

function fiyat(cents: number | null): string {
  if (cents == null) return '';
  return `₺${Math.round(cents / 100)}`;
}

function useDebounce<T>(value: T, ms: number): T {
  const [debounced, setDebounced] = useState(value);
  useEffect(() => {
    const timer = setTimeout(() => setDebounced(value), ms);
    return () => clearTimeout(timer);
  }, [value, ms]);
  return debounced;
}

// ── Ana bileşen ───────────────────────────────────────────────────────────────

export function AnlikArama({ className = '' }: { className?: string }) {
  const [query, setQuery] = useState('');
  const [results, setResults] = useState<SearchResults | null>(null);
  const [loading, setLoading] = useState(false);
  const [open, setOpen] = useState(false);
  const [coords, setCoords] = useState<{ lat: number; lng: number } | null>(null);
  const containerRef = useRef<HTMLDivElement>(null);
  const inputRef = useRef<HTMLInputElement>(null);

  const debouncedQuery = useDebounce(query, 280);

  // Konum izni
  useEffect(() => {
    if (!navigator.geolocation) return;
    const stored = sessionStorage.getItem('yd-coords');
    if (stored) {
      // sessionStorage okuması UI dışı bir kaynaktan senkronizasyon.
      // eslint-disable-next-line react-hooks/set-state-in-effect
      try { setCoords(JSON.parse(stored)); } catch { /* skip */ }
      return;
    }
    navigator.geolocation.getCurrentPosition(
      (pos) => {
        const c = { lat: pos.coords.latitude, lng: pos.coords.longitude };
        setCoords(c);
        sessionStorage.setItem('yd-coords', JSON.stringify(c));
      },
      () => { /* izin verilmedi — konumsuz arama */ },
      { timeout: 5000, maximumAge: 300_000 },
    );
  }, []);

  // Arama isteği
  const doSearch = useCallback(async (q: string) => {
    if (!q.trim()) { setResults(null); return; }
    setLoading(true);
    try {
      const url = new URL('/api/arama/anlik', window.location.origin);
      url.searchParams.set('q', q.trim());
      if (coords) {
        url.searchParams.set('lat', String(coords.lat));
        url.searchParams.set('lng', String(coords.lng));
      }
      const res = await fetch(url.toString());
      if (res.ok) setResults(await res.json());
    } catch {
      // hata — sessizce geç
    } finally {
      setLoading(false);
    }
  }, [coords]);

  useEffect(() => {
    // Debounce edilmiş sorguyla sunucudan arama sonucu çeker — dış sistemle senkronizasyon.
    // eslint-disable-next-line react-hooks/set-state-in-effect
    doSearch(debouncedQuery);
  }, [debouncedQuery, doSearch]);

  // Dışarı tıklama / ESC
  useEffect(() => {
    function onKey(e: KeyboardEvent) {
      if (e.key === 'Escape') { setOpen(false); inputRef.current?.blur(); }
    }
    function onPointer(e: PointerEvent) {
      if (containerRef.current && !containerRef.current.contains(e.target as Node)) {
        setOpen(false);
      }
    }
    document.addEventListener('keydown', onKey);
    document.addEventListener('pointerdown', onPointer);
    return () => {
      document.removeEventListener('keydown', onKey);
      document.removeEventListener('pointerdown', onPointer);
    };
  }, []);

  const hasResults = results && (results.businesses.length > 0 || results.items.length > 0);
  const showDropdown = open && (hasResults || loading || (query.trim().length === 0));

  return (
    <div ref={containerRef} className={`relative w-full ${className}`}>
      {/* Input */}
      <div className="relative">
        <span className="pointer-events-none absolute inset-y-0 left-4 flex items-center text-muted" aria-hidden="true">
          <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round">
            <circle cx="11" cy="11" r="8" /><path d="m21 21-4.35-4.35" />
          </svg>
        </span>
        <input
          ref={inputRef}
          type="search"
          placeholder="İşletme, yemek veya mutfak ara..."
          value={query}
          onChange={(e) => { setQuery(e.target.value); setOpen(true); }}
          onFocus={() => setOpen(true)}
          className="h-[52px] w-full rounded-2xl border border-border bg-card pl-12 pr-12 text-sm font-bold text-textStrong placeholder:text-muted focus:border-primary focus:outline-hidden focus:ring-2 focus:ring-primary/20 transition-all"
          role="combobox"
          aria-label="Ara"
          aria-expanded={showDropdown}
          aria-controls="anlik-arama-listbox"
          aria-haspopup="listbox"
          autoComplete="off"
        />
        {loading && (
          <span className="absolute inset-y-0 right-4 flex items-center" aria-hidden="true">
            <svg className="animate-spin text-primary" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5">
              <path d="M12 2v4M12 18v4M4.93 4.93l2.83 2.83M16.24 16.24l2.83 2.83M2 12h4M18 12h4M4.93 19.07l2.83-2.83M16.24 7.76l2.83-2.83" strokeLinecap="round" />
            </svg>
          </span>
        )}
        {query && !loading && (
          <button
            type="button"
            onClick={() => { setQuery(''); setResults(null); inputRef.current?.focus(); }}
            className="absolute inset-y-0 right-4 flex items-center text-muted hover:text-textStrong"
            aria-label="Temizle"
          >
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round">
              <path d="M18 6 6 18M6 6l12 12" />
            </svg>
          </button>
        )}
      </div>

      {/* Dropdown */}
      {showDropdown && (
        <div
          id="anlik-arama-listbox"
          className="absolute left-0 right-0 top-[calc(100%+6px)] z-50 overflow-hidden rounded-2xl border border-border bg-card shadow-yd3"
          role="listbox"
          aria-label="Arama sonuçları"
        >
          {/* Popüler aramalar — sorgu boşken */}
          {!query.trim() && (
            <div className="p-3">
              <p className="mb-2 px-2 text-[11px] font-black uppercase tracking-widest text-muted">Popüler Aramalar</p>
              <div className="flex flex-wrap gap-1.5">
                {POPULAR.map((term) => (
                  <button
                    key={term}
                    type="button"
                    onClick={() => { setQuery(term); setOpen(true); }}
                    className="rounded-full border border-border bg-surface px-3 py-1.5 text-xs font-extrabold text-textStrong hover:border-primary hover:text-primary transition-colors"
                  >
                    {term}
                  </button>
                ))}
              </div>
            </div>
          )}

          {/* Sonuçlar */}
          {query.trim() && hasResults && (
            <>
              {/* Restoranlar */}
              {results!.businesses.length > 0 && (
                <div>
                  <div className="flex items-center justify-between px-4 pb-1 pt-3">
                    <span className="text-[11px] font-black uppercase tracking-widest text-muted">Restoranlar</span>
                    <Link
                      href={`/kesif?q=${encodeURIComponent(query)}`}
                      className="text-[11px] font-extrabold text-primary hover:underline"
                      onClick={() => setOpen(false)}
                    >
                      Tümünü gör →
                    </Link>
                  </div>
                  <ul>
                    {results!.businesses.map((biz) => (
                      <BizSatiri key={biz.id} biz={biz} onSelect={() => setOpen(false)} />
                    ))}
                  </ul>
                </div>
              )}

              {/* Yemekler */}
              {results!.items.length > 0 && (
                <div className={results!.businesses.length > 0 ? 'border-t border-border' : ''}>
                  <div className="px-4 pb-1 pt-3">
                    <span className="text-[11px] font-black uppercase tracking-widest text-muted">Menü Kalemleri</span>
                  </div>
                  <ul>
                    {results!.items.map((item) => (
                      <YemekSatiri key={item.id} item={item} onSelect={() => setOpen(false)} />
                    ))}
                  </ul>
                </div>
              )}
            </>
          )}

          {/* Sonuç yok */}
          {query.trim() && !loading && results && !hasResults && (
            <div className="px-4 py-6 text-center">
              <p className="text-sm font-black text-textStrong">Sonuç bulunamadı</p>
              <p className="mt-1 text-xs font-bold text-muted">
                &ldquo;{query}&rdquo; için eşleşen işletme veya yemek yok
              </p>
              <Link
                href={`/kesif?q=${encodeURIComponent(query)}`}
                className="mt-3 inline-flex items-center gap-1 text-xs font-black text-primary hover:underline"
                onClick={() => setOpen(false)}
              >
                Gelişmiş aramayı dene →
              </Link>
            </div>
          )}

          {/* Alt köprü */}
          {query.trim() && hasResults && (
            <div className="border-t border-border px-4 py-2.5">
              <Link
                href={`/kesif?q=${encodeURIComponent(query)}`}
                className="flex items-center gap-2 text-xs font-black text-primary hover:underline"
                onClick={() => setOpen(false)}
              >
                <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round">
                  <circle cx="11" cy="11" r="8" /><path d="m21 21-4.35-4.35" />
                </svg>
                &ldquo;{query}&rdquo; için tüm sonuçları gör
              </Link>
            </div>
          )}
        </div>
      )}
    </div>
  );
}

// ── Restoran satırı ───────────────────────────────────────────────────────────

function BizSatiri({ biz, onSelect }: { biz: BizResult; onSelect: () => void }) {
  const imgSrc = buildMenuImageUrl(biz.logoUrl ?? biz.coverUrl ?? null, { width: 80, quality: 75 });
  const href = `/b/${biz.slug}`;

  return (
    <li role="option" aria-selected="false">
      <Link
        href={href}
        onClick={onSelect}
        className="flex items-center gap-3 px-4 py-2.5 hover:bg-surface transition-colors"
      >
        <div className="relative h-10 w-10 shrink-0 overflow-hidden rounded-xl bg-surface">
          {imgSrc ? (
            <Image src={imgSrc} alt={biz.name} fill sizes="40px" className="object-cover" />
          ) : (
            <div className="flex h-full w-full items-center justify-center text-muted" aria-hidden="true">
              <Utensils size={18} />
            </div>
          )}
        </div>
        <div className="flex-1 min-w-0">
          <div className="flex items-center gap-1">
            <p className="text-sm font-black text-textStrong truncate">{biz.name}</p>
            {biz.isVerified && (
              <span className="flex h-4 w-4 shrink-0 items-center justify-center rounded-full bg-primary text-white" aria-label="Doğrulandı">
                <svg width="8" height="8" viewBox="0 0 12 12" fill="none" aria-hidden="true">
                  <path d="M2 6l2.5 2.5L10 3.5" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" />
                </svg>
              </span>
            )}
          </div>
          <div className="flex items-center gap-2 text-[11px] font-bold text-muted">
            {biz.category && <span>{biz.category}</span>}
            {biz.district && <><span aria-hidden="true">·</span><span>{biz.district}</span></>}
            {biz.distanceKm != null && <><span aria-hidden="true">·</span><span>{biz.distanceKm} km</span></>}
          </div>
        </div>
        <div className="flex shrink-0 flex-col items-end gap-1">
          {biz.avgRating != null && (
            <span className="flex items-center gap-0.5 text-[11px] font-extrabold text-amber-600">
              <svg width="10" height="10" viewBox="0 0 24 24" fill="currentColor" aria-hidden="true">
                <path d="M12 2l3.09 6.26L22 9.27l-5 4.87 1.18 6.88L12 17.77l-6.18 3.25L7 14.14 2 9.27l6.91-1.01L12 2z" />
              </svg>
              {biz.avgRating.toFixed(1)}
            </span>
          )}
          {biz.isOpenNow != null && (
            <span className={`text-[10px] font-black ${biz.isOpenNow ? 'text-success' : 'text-danger'}`}>
              {biz.isOpenNow ? 'Açık' : 'Kapalı'}
            </span>
          )}
        </div>
      </Link>
    </li>
  );
}

// ── Yemek satırı ─────────────────────────────────────────────────────────────

function YemekSatiri({ item, onSelect }: { item: ItemResult; onSelect: () => void }) {
  const imgSrc = buildMenuImageUrl(item.image_url ?? null, { width: 80, quality: 75 });
  const href = `/b/${item.businessSlug}`;

  return (
    <li role="option" aria-selected="false">
      <Link
        href={href}
        onClick={onSelect}
        className="flex items-center gap-3 px-4 py-2.5 hover:bg-surface transition-colors"
      >
        <div className="relative h-10 w-10 shrink-0 overflow-hidden rounded-xl bg-surface">
          {imgSrc ? (
            <Image src={imgSrc} alt={item.name} fill sizes="40px" className="object-cover" />
          ) : (
            <div className="flex h-full w-full items-center justify-center text-muted" aria-hidden="true">
              <Utensils size={18} />
            </div>
          )}
        </div>
        <div className="flex-1 min-w-0">
          <p className="text-sm font-black text-textStrong truncate">{item.name}</p>
          <p className="text-[11px] font-bold text-muted truncate">{item.businessName}</p>
        </div>
        {item.price_cents != null && (
          <span className="shrink-0 text-sm font-black text-textStrong">{fiyat(item.price_cents)}</span>
        )}
      </Link>
    </li>
  );
}
