'use client';

import { useState, useEffect, useCallback, useRef } from 'react';
import { useSearchParams } from 'next/navigation';
import Image from 'next/image';
import Link from 'next/link';
import { buildMenuImageUrl } from '@/src/lib/medya-adresi';
import { MapPin, Star } from 'lucide-react';

// ── Tipler ───────────────────────────────────────────────────────────────────

type Isletme = {
  id: string; name: string; slug: string;
  category: string | null; city: string | null; district: string | null;
  logoUrl: string | null; coverUrl: string | null;
  isVerified: boolean; reviewsCount: number; avgRating: number | null;
};

// ── Sabitler ─────────────────────────────────────────────────────────────────

const KATEGORILER = ['Restoran', 'Kafe', 'Kahvaltı', 'Tatlıcı', 'Mekan', 'Balık / Et'];

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

const FALLBACK_CAT: Record<string, string> = {
  kafe: '/category-images/cafe.webp',
  kahvaltı: '/category-images/kahvalti.webp',
  'tatlıcı': '/category-images/tatli.webp',
  'balık / et': '/category-images/restoran.webp',
  mekan: '/category-images/restoran.webp',
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

// ── Kart ─────────────────────────────────────────────────────────────────────

function IsletmeKart({ biz }: { biz: Isletme }) {
  const cover = buildMenuImageUrl(biz.coverUrl ?? biz.logoUrl ?? null, { width: 640, quality: 78 })
    ?? coverFallback(biz.category);

  return (
    <Link
      href={`/isletme/${biz.slug}`}
      className="group flex flex-col overflow-hidden rounded-[20px] border border-border bg-card shadow-yd1 transition-all hover:-translate-y-0.5 hover:shadow-yd2"
    >
      <div className="relative w-full overflow-hidden" style={{ aspectRatio: '16/10' }}>
        <Image
          src={cover}
          alt={biz.name}
          fill
          sizes="(max-width: 640px) 50vw, 300px"
          className="object-cover transition-transform group-hover:scale-105"
        />
        {biz.avgRating != null && biz.avgRating > 0 && (
          <div className="absolute left-2 top-2 flex items-center gap-1 rounded-xl bg-white/92 px-2 py-1 text-xs font-extrabold shadow-xs backdrop-blur-sm">
            <svg width="10" height="10" viewBox="0 0 24 24" fill="#F59E0B" aria-hidden="true"><path d="M12 2l3.09 6.26L22 9.27l-5 4.87 1.18 6.88L12 17.77l-6.18 3.25L7 14.14 2 9.27l6.91-1.01L12 2z" /></svg>
            <span className="text-textStrong">{biz.avgRating.toFixed(1)}</span>
            {biz.reviewsCount > 0 && <span className="text-muted">({biz.reviewsCount.toLocaleString('tr-TR')})</span>}
          </div>
        )}
      </div>
      <div className="flex flex-1 flex-col gap-1 p-3">
        <div className="flex items-start gap-1.5">
          <p className="line-clamp-1 flex-1 text-sm font-black text-textStrong">{biz.name}</p>
          {biz.isVerified && (
            <span className="mt-0.5 flex h-4 w-4 shrink-0 items-center justify-center rounded-full bg-primary" aria-label="Doğrulandı">
              <svg width="8" height="8" viewBox="0 0 12 12" fill="none" aria-hidden="true"><path d="M2 6l2.5 2.5L10 3.5" stroke="white" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" /></svg>
            </span>
          )}
        </div>
        <p className="line-clamp-1 text-[11px] font-bold text-muted">
          {[biz.category, biz.district ?? biz.city].filter(Boolean).join(' · ')}
        </p>
        <div className="mt-auto flex items-center gap-1 border-t border-border pt-2">
          <svg width="11" height="11" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" className="text-muted" aria-hidden="true"><path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z" /></svg>
          <span className="text-[11px] font-extrabold text-muted">
            {biz.reviewsCount > 0 ? `${biz.reviewsCount.toLocaleString('tr-TR')} yorum` : 'Henüz yorum yok'}
          </span>
        </div>
      </div>
    </Link>
  );
}

// ── Yükleniyor iskelet ────────────────────────────────────────────────────────

function IsletmeSkelton() {
  return (
    <div className="overflow-hidden rounded-[20px] border border-border bg-card">
      <div className="w-full animate-pulse bg-border" style={{ aspectRatio: '16/10' }} />
      <div className="space-y-2 p-3">
        <div className="h-4 w-3/4 animate-pulse rounded bg-border" />
        <div className="h-3 w-1/2 animate-pulse rounded bg-border" />
        <div className="mt-3 h-7 animate-pulse rounded-lg bg-border" />
      </div>
    </div>
  );
}

// ── Ana bileşen ───────────────────────────────────────────────────────────────

export function KesifCanli() {
  const searchParams = useSearchParams();

  // Filtre state — URL'den başlatılır
  const [q, setQ]                 = useState(searchParams.get('q') ?? '');
  const [category, setCategory]   = useState(searchParams.get('category') ?? '');
  const [city, setCity]           = useState(searchParams.get('city') ?? '');
  const [sort, setSort]           = useState('rating');
  const [minRating, setMinRating] = useState(0);
  const [verified, setVerified]   = useState(false);
  const [sidebarOpen, setSidebarOpen] = useState(false);

  const [results, setResults]   = useState<Isletme[]>([]);
  const [loading, setLoading]   = useState(true);
  const [total, setTotal]       = useState(0);

  const debouncedQ    = useDebounce(q, 320);
  const debouncedCity = useDebounce(city, 400);
  const abortRef      = useRef<AbortController | null>(null);

  const fetch_ = useCallback(async () => {
    abortRef.current?.abort();
    const ctrl = new AbortController();
    abortRef.current = ctrl;

    setLoading(true);
    try {
      const p = new URLSearchParams();
      if (debouncedQ)    p.set('q', debouncedQ);
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
      // abort veya hata
    } finally {
      setLoading(false);
    }
  }, [debouncedQ, debouncedCity, category, sort, minRating, verified]);

  // Filtre/sıralama değiştiğinde sunucudan liste çeker — dış sistemle senkronizasyon.
  // eslint-disable-next-line react-hooks/set-state-in-effect
  useEffect(() => { fetch_(); }, [fetch_]);

  const temizle = () => {
    setQ(''); setCategory(''); setCity('');
    setSort('rating'); setMinRating(0); setVerified(false);
  };

  const hasFilter = q || category || city || sort !== 'rating' || minRating > 0 || verified;

  // ── Sidebar içeriği ───────────────────────────────────────────────────────

  const SidebarContent = (
    <div className="space-y-5">
      {/* Arama */}
      <div className="space-y-1.5">
        <label className="text-xs font-black text-textStrong">Arama</label>
        <div className="relative">
          <span className="pointer-events-none absolute inset-y-0 left-3 flex items-center text-muted" aria-hidden="true">
            <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round"><circle cx="11" cy="11" r="8" /><path d="m21 21-4.35-4.35" /></svg>
          </span>
          <input
            type="search"
            value={q}
            onChange={(e) => setQ(e.target.value)}
            placeholder="İşletme ara..."
            className="w-full rounded-xl border border-border bg-surface py-2.5 pl-9 pr-3 text-sm font-bold text-textStrong placeholder:text-muted focus:border-primary focus:outline-hidden focus:ring-2 focus:ring-primary/20"
          />
        </div>
      </div>

      {/* Kategori */}
      <div className="space-y-1.5">
        <p className="text-xs font-black text-textStrong">Kategori</p>
        <div className="space-y-2">
          <label className="flex cursor-pointer items-center gap-2">
            <input type="radio" name="kat" value="" checked={category === ''} onChange={() => setCategory('')} className="accent-primary" />
            <span className="text-sm font-bold text-textStrong">Tümü</span>
          </label>
          {KATEGORILER.map((k) => (
            <label key={k} className="flex cursor-pointer items-center gap-2">
              <input type="radio" name="kat" value={k} checked={category === k} onChange={() => setCategory(k)} className="accent-primary" />
              <span className="text-sm font-bold text-textStrong">{k}</span>
            </label>
          ))}
        </div>
      </div>

      {/* Şehir */}
      <div className="space-y-1.5">
        <label className="text-xs font-black text-textStrong">Şehir</label>
        <div className="relative">
          <span className="pointer-events-none absolute inset-y-0 left-3 flex items-center text-muted" aria-hidden="true">
            <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round"><path d="M21 10c0 7-9 13-9 13s-9-6-9-13a9 9 0 0 1 18 0z" /><circle cx="12" cy="10" r="3" /></svg>
          </span>
          <input
            type="text"
            value={city}
            onChange={(e) => setCity(e.target.value)}
            placeholder="İstanbul, Ankara..."
            className="w-full rounded-xl border border-border bg-surface py-2.5 pl-9 pr-3 text-sm font-bold text-textStrong placeholder:text-muted focus:border-primary focus:outline-hidden focus:ring-2 focus:ring-primary/20"
          />
        </div>
      </div>

      {/* Sıralama */}
      <div className="space-y-1.5">
        <label className="text-xs font-black text-textStrong">Sıralama</label>
        <div className="relative">
          <select
            value={sort}
            onChange={(e) => setSort(e.target.value)}
            className="w-full appearance-none rounded-xl border border-border bg-surface py-2.5 pl-3 pr-8 text-sm font-extrabold text-textStrong focus:border-primary focus:outline-hidden focus:ring-2 focus:ring-primary/20"
          >
            {SIRALAMA.map((s) => <option key={s.value} value={s.value}>{s.label}</option>)}
          </select>
          <span className="pointer-events-none absolute inset-y-0 right-3 flex items-center text-muted" aria-hidden="true">
            <svg width="11" height="11" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round"><path d="m6 9 6 6 6-6" /></svg>
          </span>
        </div>
      </div>

      {/* Minimum Puan */}
      <div className="space-y-1.5">
        <p className="text-xs font-black text-textStrong">Minimum Puan</p>
        <div className="flex flex-wrap gap-1.5">
          {MIN_PUAN.map((p) => (
            <button
              key={p.value}
              type="button"
              onClick={() => setMinRating(p.value)}
              className={`rounded-lg border px-2.5 py-1.5 text-[11px] font-black transition-all ${
                minRating === p.value
                  ? 'border-primary bg-primary text-white'
                  : 'border-border bg-surface text-textStrong hover:border-primary/40 hover:text-primary'
              }`}
            >
              {p.label}
            </button>
          ))}
        </div>
      </div>

      {/* Doğrulanmış */}
      <div>
        <label className="flex cursor-pointer items-center gap-2.5">
          <input
            type="checkbox"
            checked={verified}
            onChange={(e) => setVerified(e.target.checked)}
            className="h-4 w-4 cursor-pointer rounded accent-primary"
          />
          <span className="text-sm font-bold text-textStrong">Sadece Doğrulanmış</span>
        </label>
      </div>

      {/* Temizle */}
      {hasFilter && (
        <button
          type="button"
          onClick={temizle}
          className="flex w-full items-center justify-center gap-2 rounded-xl border border-border bg-surface py-2.5 text-xs font-extrabold text-muted transition-colors hover:border-danger/40 hover:text-danger"
        >
          <svg width="11" height="11" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" aria-hidden="true"><path d="M18 6 6 18M6 6l12 12" /></svg>
          Filtreleri Temizle
        </button>
      )}
    </div>
  );

  // ── Render ────────────────────────────────────────────────────────────────

  return (
    <div className="mx-auto max-w-6xl px-4 sm:px-6">

      {/* Mobil: filtre aç/kapat butonu */}
      <div className="mb-4 flex items-center justify-between xl:hidden">
        <p className="text-sm font-bold text-muted">
          {loading ? 'Aranıyor…' : `${total} işletme`}
        </p>
        <button
          type="button"
          onClick={() => setSidebarOpen((v) => !v)}
          className="flex items-center gap-2 rounded-xl border border-border bg-card px-3 py-2 text-sm font-extrabold text-textStrong shadow-yd1 hover:border-primary/30"
        >
          <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" aria-hidden="true">
            <line x1="4" y1="6" x2="20" y2="6" /><line x1="8" y1="12" x2="20" y2="12" /><line x1="4" y1="18" x2="20" y2="18" />
          </svg>
          Filtrele
          {hasFilter && <span className="flex h-4 w-4 items-center justify-center rounded-full bg-primary text-[9px] font-black text-white">{[q, category, city, sort !== 'rating', minRating > 0, verified].filter(Boolean).length}</span>}
        </button>
      </div>

      {/* Mobil filtre paneli */}
      {sidebarOpen && (
        <div className="mb-5 rounded-2xl border border-border bg-card p-4 shadow-yd2 xl:hidden">
          {SidebarContent}
        </div>
      )}

      <div className="flex gap-6">
        {/* Masaüstü sidebar */}
        <aside className="hidden w-56 shrink-0 xl:block">
          <div className="sticky top-24 rounded-2xl border border-border bg-card p-4 shadow-yd1">
            <p className="mb-4 text-sm font-black text-textStrong">Filtrele</p>
            {SidebarContent}
          </div>
        </aside>

        {/* Sonuçlar */}
        <div className="min-w-0 flex-1">
          {/* Aktif filtre chips */}
          {hasFilter && (
            <div className="mb-4 flex flex-wrap gap-1.5">
              {category && (
                <span className="flex items-center gap-1 rounded-full bg-primary/10 px-2.5 py-1 text-xs font-extrabold text-primary">
                  {category}
                  <button onClick={() => setCategory('')} className="ml-1 rounded-full hover:text-primary/60" aria-label="Kategoriyi kaldır">×</button>
                </span>
              )}
              {city && (
                <span className="flex items-center gap-1 rounded-full bg-primary/10 px-2.5 py-1 text-xs font-extrabold text-primary">
                  <MapPin className="h-3 w-3" aria-hidden="true" /> {city}
                  <button onClick={() => setCity('')} className="ml-1 rounded-full hover:text-primary/60" aria-label="Şehri kaldır">×</button>
                </span>
              )}
              {minRating > 0 && (
                <span className="flex items-center gap-1 rounded-full bg-amber-50 px-2.5 py-1 text-xs font-extrabold text-amber-700">
                  <Star className="h-3 w-3" aria-hidden="true" /> {minRating}+
                  <button onClick={() => setMinRating(0)} className="ml-1" aria-label="Puan filtresini kaldır">×</button>
                </span>
              )}
              {verified && (
                <span className="flex items-center gap-1 rounded-full bg-success/10 px-2.5 py-1 text-xs font-extrabold text-success">
                  ✓ Doğrulanmış
                  <button onClick={() => setVerified(false)} className="ml-1" aria-label="Doğrulanmış filtresini kaldır">×</button>
                </span>
              )}
            </div>
          )}

          {/* Sonuç sayısı */}
          {!loading && (
            <p className="mb-4 text-xs font-extrabold text-muted">{total} işletme listelendi</p>
          )}

          {loading ? (
            <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
              {Array.from({ length: 6 }).map((_, i) => <IsletmeSkelton key={i} />)}
            </div>
          ) : results.length === 0 ? (
            <div className="rounded-2xl border border-border bg-card p-12 text-center">
              <p className="text-base font-black text-textStrong">Sonuç bulunamadı</p>
              <p className="mt-2 text-sm font-bold text-muted">Farklı filtreler deneyin</p>
              {hasFilter && (
                <button type="button" onClick={temizle} className="mt-4 text-sm font-black text-primary hover:underline">
                  Filtreleri temizle →
                </button>
              )}
            </div>
          ) : (
            <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
              {results.map((biz) => <IsletmeKart key={biz.id} biz={biz} />)}
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
