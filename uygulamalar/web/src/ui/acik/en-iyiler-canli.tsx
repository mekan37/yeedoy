'use client';

import { useState, useEffect, useCallback, useRef } from 'react';
import Image from 'next/image';
import Link from 'next/link';
import { buildMenuImageUrl } from '@/src/lib/medya-adresi';

// ── Tipler ───────────────────────────────────────────────────────────────────

type Isletme = {
  id: string; name: string; slug: string;
  category: string | null; city: string | null; district: string | null;
  logoUrl: string | null; coverUrl: string | null;
  isVerified: boolean; reviewsCount: number; avgRating: number | null;
};

// ── Sabitler ─────────────────────────────────────────────────────────────────

const KATEGORILER = ['Restoran', 'Kafe', 'Kahvaltı', 'Tatlıcı', 'Mekan', 'Balık / Et'];

const KAT_TABS = [
  { value: '', label: 'Tümü', icon: <svg width="13" height="13" viewBox="0 0 24 24" fill="currentColor" aria-hidden="true"><path d="M12 2l3.09 6.26L22 9.27l-5 4.87 1.18 6.88L12 17.77l-6.18 3.25L7 14.14 2 9.27l6.91-1.01L12 2z" /></svg> },
  { value: 'Restoran', label: 'Restoran', icon: <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" aria-hidden="true"><path d="M3 11l19-9-9 19-2-8-8-2z" /></svg> },
  { value: 'Kafe', label: 'Kafe', icon: <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" aria-hidden="true"><path d="M17 8h1a4 4 0 1 1 0 8h-1" /><path d="M3 8h14v9a4 4 0 0 1-4 4H7a4 4 0 0 1-4-4Z" /></svg> },
  { value: 'Kahvaltı', label: 'Kahvaltı', icon: <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" aria-hidden="true"><circle cx="12" cy="12" r="10" /><path d="M12 6v6l4 2" /></svg> },
  { value: 'Tatlıcı', label: 'Tatlıcı', icon: <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" aria-hidden="true"><circle cx="12" cy="12" r="10" /><path d="M8 14s1.5 2 4 2 4-2 4-2" /><line x1="9" y1="9" x2="9.01" y2="9" /><line x1="15" y1="9" x2="15.01" y2="9" /></svg> },
  { value: 'Mekan', label: 'Mekan', icon: <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" aria-hidden="true"><path d="M3 9l9-7 9 7v11a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z" /></svg> },
  { value: 'Balık / Et', label: 'Balık & Et', icon: <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" aria-hidden="true"><path d="M18 7v13H6V7M4 7h16M9 7V4h6v3" /></svg> },
];

const SIRALAMA = [
  { value: 'rating',  label: 'En Yüksek Puan' },
  { value: 'reviews', label: 'En Çok Yorum' },
  { value: 'az',      label: 'İsme Göre A-Z' },
];

const MIN_PUAN = [
  { value: 0,   label: 'Tümü' },
  { value: 3,   label: '3+' },
  { value: 3.5, label: '3.5+' },
  { value: 4,   label: '4+' },
  { value: 4.5, label: '4.5+' },
];

const RANK_COLORS: Record<number, { bg: string; text: string }> = {
  1: { bg: '#F59E0B', text: '#fff' },
  2: { bg: '#94A3B8', text: '#fff' },
  3: { bg: '#CD7F32', text: '#fff' },
};

const FALLBACK_CAT: Record<string, string> = {
  kafe: '/category-images/cafe.webp',
  kahvaltı: '/category-images/kahvalti.webp',
  'tatlıcı': '/category-images/tatli.webp',
};

function coverFallback(cat: string | null) {
  if (!cat) return '/category-images/restoran.webp';
  return FALLBACK_CAT[cat.toLowerCase()] ?? '/category-images/restoran.webp';
}

function useDebounce<T>(v: T, ms: number) {
  const [d, setD] = useState(v);
  useEffect(() => { const t = setTimeout(() => setD(v), ms); return () => clearTimeout(t); }, [v, ms]);
  return d;
}

// ── Sıralı kart ───────────────────────────────────────────────────────────────

function IsletmeKarti({ biz, rank }: { biz: Isletme; rank: number }) {
  const cover = buildMenuImageUrl(biz.coverUrl ?? biz.logoUrl ?? null, { width: 640, quality: 78 })
    ?? coverFallback(biz.category);
  const rankStyle = RANK_COLORS[rank] ?? { bg: '#1E293B', text: '#fff' };

  return (
    <article className="group flex flex-col overflow-hidden rounded-[20px] border border-border bg-card shadow-yd1 transition-all hover:-translate-y-0.5 hover:shadow-yd2">
      <div className="relative w-full overflow-hidden" style={{ aspectRatio: '4/3' }}>
        <Image
          src={cover}
          alt={biz.name}
          fill
          sizes="(max-width: 640px) 50vw, 300px"
          className="object-cover transition-transform group-hover:scale-105"
        />
        <div
          className="absolute left-2.5 top-2.5 flex h-8 w-8 items-center justify-center rounded-full text-xs font-[900] shadow-md"
          style={{ background: rankStyle.bg, color: rankStyle.text }}
          aria-label={`${rank}. sıra`}
        >
          {rank}
        </div>
        <Link href={`/m/${biz.slug}`} tabIndex={-1}
          className="absolute right-2.5 top-2.5 flex h-8 w-8 items-center justify-center rounded-full bg-white/90 text-muted shadow-md backdrop-blur hover:text-primary"
          aria-label={`${biz.name} menüsüne git`}>
          <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" aria-hidden="true">
            <path d="M20.84 4.61a5.5 5.5 0 0 0-7.78 0L12 5.67l-1.06-1.06a5.5 5.5 0 0 0-7.78 7.78l1.06 1.06L12 21.23l7.78-7.78 1.06-1.06a5.5 5.5 0 0 0 0-7.78z" />
          </svg>
        </Link>
      </div>
      <Link href={`/m/${biz.slug}`} className="flex flex-1 flex-col gap-2 p-3">
        <div>
          <div className="flex items-start gap-1.5">
            <p className="line-clamp-1 flex-1 text-sm font-[900] text-textStrong">{biz.name}</p>
            {biz.isVerified && (
              <span className="mt-0.5 flex h-4 w-4 shrink-0 items-center justify-center rounded-full bg-primary" aria-label="Doğrulandı">
                <svg width="8" height="8" viewBox="0 0 12 12" fill="none" aria-hidden="true"><path d="M2 6l2.5 2.5L10 3.5" stroke="white" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" /></svg>
              </span>
            )}
          </div>
          {(biz.category || biz.city) && (
            <p className="mt-0.5 line-clamp-1 text-[11px] font-[700] text-muted">
              {[biz.category, biz.district ?? biz.city].filter(Boolean).join(' · ')}
            </p>
          )}
        </div>
        {biz.avgRating != null && biz.avgRating > 0 && (
          <div className="flex items-center gap-1.5">
            <span className="flex items-center gap-1 text-xs font-[800] text-amber-600">
              <svg width="11" height="11" viewBox="0 0 24 24" fill="currentColor" aria-hidden="true"><path d="M12 2l3.09 6.26L22 9.27l-5 4.87 1.18 6.88L12 17.77l-6.18 3.25L7 14.14 2 9.27l6.91-1.01L12 2z" /></svg>
              {biz.avgRating.toFixed(1)}
            </span>
            {biz.reviewsCount > 0 && (
              <span className="text-[11px] font-[700] text-muted">({biz.reviewsCount.toLocaleString('tr-TR')})</span>
            )}
          </div>
        )}
        <div className="mt-auto flex items-center gap-1.5 border-t border-border pt-2">
          <svg width="11" height="11" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" className="shrink-0 text-muted" aria-hidden="true"><path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z" /></svg>
          <span className="text-[11px] font-[800] text-muted">
            {biz.reviewsCount > 0 ? `${biz.reviewsCount.toLocaleString('tr-TR')} yorum` : 'Henüz yorum yok'}
          </span>
          {biz.isVerified && (
            <><span className="text-border" aria-hidden="true">·</span>
            <span className="text-[11px] font-[800] text-success">✓ Doğrulandı</span></>
          )}
        </div>
      </Link>
    </article>
  );
}

function IsletmeSkelton() {
  return (
    <div className="overflow-hidden rounded-[20px] border border-border bg-card">
      <div className="w-full animate-pulse bg-border" style={{ aspectRatio: '4/3' }} />
      <div className="space-y-2 p-3">
        <div className="h-4 w-3/4 animate-pulse rounded bg-border" />
        <div className="h-3 w-1/2 animate-pulse rounded bg-border" />
        <div className="mt-3 h-8 animate-pulse rounded-lg bg-border" />
      </div>
    </div>
  );
}

// ── Ana bileşen ───────────────────────────────────────────────────────────────

export function EnIyilerCanli() {
  const [category, setCategory]   = useState('');
  const [city, setCity]           = useState('');
  const [sort, setSort]           = useState('rating');
  const [minRating, setMinRating] = useState(0);
  const [verified, setVerified]   = useState(false);

  const [results, setResults] = useState<Isletme[]>([]);
  const [loading, setLoading] = useState(true);
  const [total, setTotal]     = useState(0);

  const debouncedCity = useDebounce(city, 400);
  const abortRef      = useRef<AbortController | null>(null);

  const fetch_ = useCallback(async () => {
    abortRef.current?.abort();
    const ctrl = new AbortController();
    abortRef.current = ctrl;

    setLoading(true);
    try {
      const p = new URLSearchParams();
      if (category)      p.set('category', category);
      if (debouncedCity) p.set('city', debouncedCity);
      if (sort !== 'rating') p.set('sort', sort);
      if (minRating > 0) p.set('minRating', String(minRating));
      if (verified)      p.set('verified', 'true');
      p.set('limit', '24');

      const res = await window.fetch(`/api/isletmeler?${p}`, { signal: ctrl.signal });
      if (!res.ok) return;
      const json = await res.json() as { data: Isletme[]; total: number };
      setResults(json.data);
      setTotal(json.total);
    } catch {
      // abort
    } finally {
      setLoading(false);
    }
  }, [category, debouncedCity, sort, minRating, verified]);

  useEffect(() => { fetch_(); }, [fetch_]);

  const temizle = () => {
    setCategory(''); setCity(''); setSort('rating'); setMinRating(0); setVerified(false);
  };

  const hasFilter = category || city || sort !== 'rating' || minRating > 0 || verified;

  return (
    <div>
      {/* Kategori tab'ları */}
      <nav className="mb-6 flex gap-1.5 overflow-x-auto pb-1 [-ms-overflow-style:none] [scrollbar-width:none] [&::-webkit-scrollbar]:hidden" aria-label="Kategori filtresi">
        {KAT_TABS.map((tab) => (
          <button
            key={tab.value}
            type="button"
            onClick={() => setCategory(tab.value)}
            className={`flex shrink-0 items-center gap-1.5 rounded-full px-3.5 py-2 text-xs font-[800] transition-all ${
              category === tab.value
                ? 'bg-primary text-white shadow-yd1'
                : 'border border-border bg-card text-textStrong hover:border-primary/35 hover:text-primary'
            }`}
          >
            {tab.icon}
            {tab.label}
          </button>
        ))}
      </nav>

      {/* 2-kolon */}
      <div className="flex flex-col gap-6 lg:flex-row lg:items-start">

        {/* Sidebar */}
        <aside className="w-full space-y-5 rounded-2xl border border-border bg-card p-5 shadow-yd1 lg:w-56 lg:shrink-0 lg:sticky lg:top-20 lg:self-start">
          <p className="text-sm font-[900] text-textStrong">Filtrele</p>

          {/* Sıralama */}
          <div className="space-y-1.5">
            <label className="text-xs font-[800] text-muted">Sıralama</label>
            <div className="relative">
              <select value={sort} onChange={(e) => setSort(e.target.value)}
                className="w-full appearance-none rounded-xl border border-border bg-surface py-2.5 pl-3 pr-8 text-sm font-[800] text-textStrong focus:border-primary focus:outline-none focus:ring-2 focus:ring-primary/20">
                {SIRALAMA.map((s) => <option key={s.value} value={s.value}>{s.label}</option>)}
              </select>
              <span className="pointer-events-none absolute inset-y-0 right-3 flex items-center text-muted" aria-hidden="true">
                <svg width="11" height="11" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round"><path d="m6 9 6 6 6-6" /></svg>
              </span>
            </div>
          </div>

          {/* Şehir */}
          <div className="space-y-1.5">
            <label className="text-xs font-[800] text-muted">Şehir</label>
            <div className="relative">
              <span className="pointer-events-none absolute inset-y-0 left-3 flex items-center text-muted" aria-hidden="true">
                <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round"><path d="M21 10c0 7-9 13-9 13s-9-6-9-13a9 9 0 0 1 18 0z" /><circle cx="12" cy="10" r="3" /></svg>
              </span>
              <input type="text" value={city} onChange={(e) => setCity(e.target.value)}
                placeholder="Ankara, İstanbul..."
                className="w-full rounded-xl border border-border bg-surface py-2.5 pl-9 pr-3 text-sm font-[700] text-textStrong placeholder:text-muted focus:border-primary focus:outline-none focus:ring-2 focus:ring-primary/20" />
            </div>
          </div>

          {/* Kategori dropdown */}
          <div className="space-y-1.5">
            <label className="text-xs font-[800] text-muted">Kategori</label>
            <div className="relative">
              <select value={category} onChange={(e) => setCategory(e.target.value)}
                className="w-full appearance-none rounded-xl border border-border bg-surface py-2.5 pl-3 pr-8 text-sm font-[800] text-textStrong focus:border-primary focus:outline-none focus:ring-2 focus:ring-primary/20">
                <option value="">Tümü</option>
                {KATEGORILER.map((k) => <option key={k} value={k}>{k}</option>)}
              </select>
              <span className="pointer-events-none absolute inset-y-0 right-3 flex items-center text-muted" aria-hidden="true">
                <svg width="11" height="11" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round"><path d="m6 9 6 6 6-6" /></svg>
              </span>
            </div>
          </div>

          {/* Minimum Puan */}
          <div className="space-y-1.5">
            <p className="text-xs font-[800] text-muted">Minimum Puan</p>
            <div className="flex flex-wrap gap-1.5">
              {MIN_PUAN.map((p) => (
                <button key={p.value} type="button" onClick={() => setMinRating(p.value)}
                  className={`rounded-lg border px-2.5 py-1.5 text-[11px] font-[900] transition-all ${
                    minRating === p.value
                      ? 'border-primary bg-primary text-white'
                      : 'border-border bg-surface text-textStrong hover:border-primary/40 hover:text-primary'
                  }`}>
                  {p.label}
                </button>
              ))}
            </div>
          </div>

          {/* Doğrulanmış */}
          <label className="flex cursor-pointer items-center gap-2.5">
            <input type="checkbox" checked={verified} onChange={(e) => setVerified(e.target.checked)} className="h-4 w-4 cursor-pointer rounded accent-primary" />
            <span className="text-sm font-[700] text-textStrong">Sadece Doğrulanmış</span>
          </label>

          {hasFilter && (
            <button type="button" onClick={temizle}
              className="flex w-full items-center justify-center gap-2 rounded-xl border border-border bg-surface py-2.5 text-xs font-[800] text-muted transition-colors hover:border-danger/40 hover:text-danger">
              <svg width="11" height="11" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" aria-hidden="true"><path d="M18 6 6 18M6 6l12 12" /></svg>
              Filtreleri Temizle
            </button>
          )}
        </aside>

        {/* Sağ içerik */}
        <div className="flex-1 min-w-0">
          {!loading && (
            <p className="mb-4 text-xs font-[800] text-muted">{total} işletme listelendi</p>
          )}

          {loading ? (
            <ol className="grid grid-cols-1 gap-4 sm:grid-cols-2 xl:grid-cols-3">
              {Array.from({ length: 6 }).map((_, i) => <li key={i}><IsletmeSkelton /></li>)}
            </ol>
          ) : results.length === 0 ? (
            <div className="rounded-2xl border border-border bg-card p-12 text-center">
              <p className="text-base font-[900] text-textStrong">Sonuç bulunamadı</p>
              <p className="mt-2 text-sm font-[700] text-muted">Farklı filtreler deneyin</p>
              {hasFilter && (
                <button type="button" onClick={temizle} className="mt-4 text-sm font-[900] text-primary hover:underline">
                  Filtreleri temizle →
                </button>
              )}
            </div>
          ) : (
            <ol className="grid grid-cols-1 gap-4 sm:grid-cols-2 xl:grid-cols-3">
              {results.map((biz, i) => (
                <li key={biz.id}><IsletmeKarti biz={biz} rank={i + 1} /></li>
              ))}
            </ol>
          )}
        </div>
      </div>
    </div>
  );
}
