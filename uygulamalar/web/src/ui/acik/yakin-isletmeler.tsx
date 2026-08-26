'use client';

import { useEffect, useState } from 'react';
import Image from 'next/image';
import Link from 'next/link';
import { Star, CheckCircle, MapPin, ChevronRight } from 'lucide-react';
import { buildMenuImageUrl } from '@/src/lib/medya-adresi';
import type { AcikIsletmeKarti } from '@/src/ui/acik/tipler';

const CATEGORY_IMAGES: Record<string, string> = {
  kafe: '/category-images/cafe.webp',
  cafe: '/category-images/cafe.webp',
  restoran: '/category-images/restoran.webp',
  dönerci: '/category-images/doner.webp',
  döner: '/category-images/doner.webp',
  burger: '/category-images/burger.webp',
  pizza: '/category-images/pizza.webp',
  kebap: '/category-images/kebap.webp',
  pide: '/category-images/pide.webp',
  lahmacun: '/category-images/lahmacun.webp',
  'pide / lahmacun': '/category-images/pide.webp',
  kahvaltı: '/category-images/kahvalti.webp',
  tatlı: '/category-images/tatli.webp',
  pastane: '/category-images/tatlici.webp',
  çorba: '/category-images/corba.webp',
  mantı: '/category-images/manti.webp',
};

function categoryFallback(cat?: string | null) {
  if (!cat) return '/category-images/restoran.webp';
  return CATEGORY_IMAGES[cat.toLowerCase().trim()] ?? '/category-images/restoran.webp';
}

function PriceLevelBadge({ priceLevel }: { priceLevel?: string | null }) {
  const map: Record<string, string> = { budget: '₺', mid: '₺₺', premium: '₺₺₺' };
  const label = priceLevel ? (map[priceLevel] ?? null) : null;
  if (!label) return null;
  return (
    <span className="rounded-full border border-border bg-bg px-2 py-0.5 text-[10px] font-extrabold text-muted">
      {label}
    </span>
  );
}

function BizCard({ biz }: { biz: AcikIsletmeKarti }) {
  const slug = biz.publicSlug ?? biz.slug;
  const coverSrc =
    buildMenuImageUrl(biz.coverUrl ?? biz.logoUrl, { width: 600, quality: 80 }) ??
    categoryFallback(biz.category);
  return (
    <Link
      href={`/isletme/${slug}`}
      className="group flex flex-col overflow-hidden rounded-[20px] border border-border bg-card shadow-yd1 transition-all hover:-translate-y-0.5 hover:shadow-yd2"
    >
      <div className="relative w-full overflow-hidden" style={{ aspectRatio: '16/10' }}>
        <Image
          src={coverSrc}
          alt={biz.name}
          fill
          sizes="(max-width: 640px) 50vw, 300px"
          className="object-cover transition-transform group-hover:scale-105"
        />
        {biz.avgRating != null && (
          <div className="absolute left-2 top-2 flex items-center gap-1 rounded-xl bg-white/92 px-2 py-1 text-xs font-extrabold shadow-xs backdrop-blur-sm">
            <Star size={11} className="fill-amber-400 text-amber-400" aria-hidden="true" />
            <span className="text-textStrong">{biz.avgRating.toFixed(1)}</span>
          </div>
        )}
        {biz.isOpenNow != null && (
          <div className={`absolute right-2 top-2 rounded-xl px-2 py-1 text-[10px] font-black backdrop-blur-sm ${biz.isOpenNow ? 'bg-success/15 text-success' : 'bg-danger/15 text-danger'}`}>
            {biz.isOpenNow ? 'Açık' : 'Kapalı'}
          </div>
        )}
        {biz.distanceKm != null && (
          <div className="absolute bottom-2 left-2 flex items-center gap-1 rounded-xl bg-black/50 px-2 py-1 text-[10px] font-extrabold text-white backdrop-blur-sm">
            <MapPin size={10} aria-hidden="true" />
            {biz.distanceKm < 1
              ? `${Math.round(biz.distanceKm * 1000)} m`
              : `${biz.distanceKm.toFixed(1)} km`}
          </div>
        )}
      </div>
      <div className="flex flex-1 flex-col gap-1 p-3">
        <p className="line-clamp-1 text-sm font-black text-textStrong">{biz.name}</p>
        <p className="line-clamp-1 text-xs text-muted">
          {[biz.category, biz.city].filter(Boolean).join(' · ')}
        </p>
        <div className="mt-auto flex items-center gap-2 pt-1">
          <PriceLevelBadge priceLevel={biz.priceLevel} />
          {biz.isVerified && (
            <span className="flex items-center gap-1 text-[10px] font-extrabold text-primary">
              <CheckCircle size={11} aria-hidden="true" /> Doğrulandı
            </span>
          )}
        </div>
      </div>
    </Link>
  );
}

type State =
  | { status: 'idle' }
  | { status: 'locating' }
  | { status: 'loading'; lat: number; lng: number }
  | { status: 'done'; businesses: AcikIsletmeKarti[]; lat: number; lng: number }
  | { status: 'denied' }
  | { status: 'error' };

export function YakindakiIsletmeler() {
  const [state, setState] = useState<State>({ status: 'idle' });

  useEffect(() => {
    // navigator.geolocation kontrolü UI dışı bir kaynaktan senkronizasyon.
    if (!('geolocation' in navigator)) {
      // eslint-disable-next-line react-hooks/set-state-in-effect
      setState({ status: 'denied' });
      return;
    }

    setState({ status: 'locating' });

    // Try sessionStorage first (set by KonumIzniIstemcisi)
    try {
      const cached = sessionStorage.getItem('yd_konum');
      if (cached) {
        const { lat, lng } = JSON.parse(cached) as { lat: number; lng: number };
        if (isFinite(lat) && isFinite(lng)) {
          fetchNearby(lat, lng);
          return;
        }
      }
    } catch {
      // ignore
    }

    navigator.geolocation.getCurrentPosition(
      (pos) => {
        const { latitude: lat, longitude: lng } = pos.coords;
        try {
          sessionStorage.setItem('yd_konum', JSON.stringify({ lat, lng }));
        } catch { /* ignore */ }
        fetchNearby(lat, lng);
      },
      () => setState({ status: 'denied' }),
      { timeout: 10000, maximumAge: 5 * 60 * 1000 },
    );

    function fetchNearby(lat: number, lng: number) {
      setState({ status: 'loading', lat, lng });
      fetch(`/api/yakin-isletmeler?lat=${lat}&lng=${lng}&r=15&limit=60`, { signal: AbortSignal.timeout(8_000) })
        .then((r) => r.json())
        .then(({ data }) => {
          setState({ status: 'done', businesses: data ?? [], lat, lng });
        })
        .catch(() => setState({ status: 'error' }));
    }
  }, []);

  if (state.status === 'idle' || state.status === 'locating') {
    return (
      <section className="border-t border-border py-8">
        <div className="mx-auto w-full max-w-6xl px-4 sm:px-6 lg:px-8">
          <div className="flex items-center gap-3 text-muted">
            <div className="h-4 w-4 animate-spin rounded-full border-2 border-border border-t-primary" />
            <p className="text-sm">Konumunuz alınıyor…</p>
          </div>
        </div>
      </section>
    );
  }

  if (state.status === 'denied') {
    return (
      <section className="border-t border-border py-8">
        <div className="mx-auto w-full max-w-6xl px-4 sm:px-6 lg:px-8">
          <div className="flex items-center gap-3 rounded-[20px] border border-border bg-card p-5">
            <MapPin size={20} className="shrink-0 text-muted" aria-hidden="true" />
            <div>
              <p className="text-sm font-black text-textStrong">Konum izni gerekiyor</p>
              <p className="mt-0.5 text-xs text-muted">
                Yakınındaki işletmeleri görmek için tarayıcı adres çubuğundaki konum iznine izin verin.
              </p>
            </div>
            <Link href="/kesif" className="ml-auto shrink-0 text-sm font-extrabold text-primary hover:underline">
              Tümünü gör
            </Link>
          </div>
        </div>
      </section>
    );
  }

  if (state.status === 'error') {
    return null;
  }

  if (state.status === 'done') {
    const { businesses } = state;
    if (businesses.length === 0) {
      return (
        <section className="border-t border-border py-8">
          <div className="mx-auto w-full max-w-6xl px-4 sm:px-6 lg:px-8">
            <div className="rounded-[20px] border border-border bg-card p-8 text-center">
              <MapPin size={32} className="mx-auto mb-3 text-muted" aria-hidden="true" />
              <p className="font-black text-textStrong">Yakında işletme bulunamadı</p>
              <p className="mt-1 text-sm text-muted">Arama yarıçapını genişletelim veya tüm işletmelere göz at.</p>
              <Link
                href="/kesif"
                className="mt-4 inline-flex items-center gap-1 text-sm font-extrabold text-primary hover:underline"
              >
                Tüm işletmeleri keşfet <ChevronRight size={14} aria-hidden="true" />
              </Link>
            </div>
          </div>
        </section>
      );
    }

    return (
      <section className="border-t border-border py-8">
        <div className="mx-auto w-full max-w-6xl px-4 sm:px-6 lg:px-8">
          <div className="mb-6 flex items-center justify-between">
            <div>
              <h2 className="text-xl font-black text-textStrong">Yakınındaki İşletmeler</h2>
              <p className="mt-0.5 flex items-center gap-1 text-sm text-muted">
                <MapPin size={13} aria-hidden="true" />
                {businesses.length} işletme listelendi
              </p>
            </div>
            <Link href="/kesif" className="flex items-center gap-1 text-sm font-extrabold text-primary hover:underline">
              Tümünü keşfet <ChevronRight size={14} aria-hidden="true" />
            </Link>
          </div>
          <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4">
            {businesses.map((biz) => (
              <BizCard key={biz.id} biz={biz} />
            ))}
          </div>
        </div>
      </section>
    );
  }

  return null;
}
