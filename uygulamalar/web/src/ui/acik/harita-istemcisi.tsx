'use client';

import { useEffect, useRef, useCallback, useState, type ChangeEvent } from 'react';
import * as maplibregl from 'maplibre-gl';
import 'maplibre-gl/dist/maplibre-gl.css';
import Supercluster from 'supercluster';
import { ensurePmtilesProtocol, buildPmtilesStyle, buildRichMarkerEl, buildClusterBadgeEl } from '@/src/lib/harita-paylasim';
import { toGeoJSONPoints } from '@/src/lib/harita-cluster';
import type { HaritaIsletme } from '@/src/lib/veri/harita-okuma';

interface IsletmeDetay {
  id: string;
  name: string;
  slug: string;
  description: string | null;
  logo_url: string | null;
  cover_url: string | null;
  category: string | null;
  city: string | null;
  district: string | null;
  address: string | null;
  phone: string | null;
  is_verified: boolean;
  avg_rating: number | null;
  reviews_count: number | null;
}

const DEFAULT_CENTER: [number, number] = [32.8597, 39.9334];
// Konum izni beklenirken (veya reddedilirse kalıcı olarak) gösterilen ilk görünüm.
// Eskiden 6'ydı (tüm Türkiye) — kullanıcı konumu paylaşmadan/GPS gelmeden önce
// tek bir dev cluster'dan başka bir şey görmüyordu. Şehir ölçeğine çekildi.
const DEFAULT_ZOOM = 12;
// Konum izni verildiğinde uçulan zoom seviyesi.
const GEOLOCATED_ZOOM = 14;
const FETCH_DEBOUNCE_MS = 500;
const MAX_MARKERS = 150;
// Supercluster yalnızca bu zoom'a kadar cluster ağacı kurar; ötesi (CLUSTER_MAX_ZOOM + 1)
// her zaman kümelenmemiş tekil noktaları döndürür. Küme tıklamasında
// getClusterExpansionZoom() sadece "ilk ayrışma" zoom'unu verir (ör. 30 → 16+14 gibi alt
// kümelere), tam tekilleşmeyi garanti etmez — bu yüzden tıklamada en az bu+1'e zoom'luyoruz.
const CLUSTER_MAX_ZOOM = 16;

const HARITA_KATEGORILERI = ['Restoran', 'Kafe', 'Kahvaltı', 'Tatlıcı', 'Mekan', 'Balık / Et'];


// ── Harita arama kutusu ──────────────────────────────────────────────────────

function HaritaArama({
  onSec,
}: {
  onSec: (isletme: HaritaIsletme) => void;
}) {
  const [sorgu, setSorgu] = useState('');
  const [sonuclar, setSonuclar] = useState<HaritaIsletme[]>([]);
  const [yukleniyor, setYukleniyor] = useState(false);
  const debounceRef = useRef<ReturnType<typeof setTimeout> | null>(null);

  useEffect(() => {
    if (debounceRef.current) clearTimeout(debounceRef.current);
    const trimmed = sorgu.trim();
    // Debounce edilmiş sunucu aramasının bir parçası — dış sistemle senkronizasyon.
    // eslint-disable-next-line react-hooks/set-state-in-effect
    if (!trimmed) { setSonuclar([]); return; }
    setYukleniyor(true);
    debounceRef.current = setTimeout(async () => {
      try {
        const res = await fetch(`/api/harita-arama?q=${encodeURIComponent(trimmed)}`);
        if (res.ok) setSonuclar(await res.json());
      } catch { /* sessiz */ }
      finally { setYukleniyor(false); }
    }, 300);
    return () => { if (debounceRef.current) clearTimeout(debounceRef.current); };
  }, [sorgu]);

  const temizle = () => { setSorgu(''); setSonuclar([]); };

  const ilkHarfEl = (name: string, size = 28) => (
    <div style={{
      width: size, height: size, borderRadius: '50%',
      background: '#7F1D1D', flexShrink: 0,
      display: 'flex', alignItems: 'center', justifyContent: 'center',
      overflow: 'hidden',
    }}>
      <span style={{ color: 'white', fontSize: size * 0.44, fontWeight: 800, fontFamily: 'system-ui,sans-serif' }}>
        {(name.charAt(0) || '?').toUpperCase()}
      </span>
    </div>
  );

  return (
    <div style={{ position: 'absolute', top: 10, left: 10, zIndex: 10, width: 280 }}>
      {/* Giriş satırı */}
      <div style={{
        display: 'flex', alignItems: 'center', gap: 6,
        background: 'white', borderRadius: 10,
        boxShadow: '0 2px 10px rgba(0,0,0,0.2)',
        padding: '0 10px',
      }}>
        <svg width="16" height="16" viewBox="0 0 20 20" fill="none" style={{ flexShrink: 0, opacity: 0.45 }}>
          <circle cx="8.5" cy="8.5" r="5.5" stroke="#111" strokeWidth="2"/>
          <path d="M13 13l3.5 3.5" stroke="#111" strokeWidth="2" strokeLinecap="round"/>
        </svg>
        <input
          type="text"
          placeholder="İşletme ara…"
          value={sorgu}
          onChange={(e: ChangeEvent<HTMLInputElement>) => setSorgu(e.target.value)}
          style={{
            border: 'none', outline: 'none',
            padding: '11px 4px', fontSize: 13, flex: 1,
            background: 'transparent', fontFamily: 'system-ui,sans-serif',
            color: '#111',
          }}
        />
        {sorgu && (
          <button
            onClick={temizle}
            aria-label="Temizle"
            style={{
              border: 'none', background: 'none', cursor: 'pointer',
              color: '#9CA3AF', fontSize: 18, lineHeight: 1,
              padding: 2, flexShrink: 0,
            }}
          >×</button>
        )}
        {yukleniyor && (
          <div style={{
            width: 14, height: 14, border: '2px solid #7F1D1D',
            borderTopColor: 'transparent', borderRadius: '50%',
            animation: 'spin 0.7s linear infinite', flexShrink: 0,
          }} />
        )}
      </div>

      {/* Sonuç listesi */}
      {sonuclar.length > 0 && (
        <div style={{
          background: 'white', borderRadius: 10,
          boxShadow: '0 4px 20px rgba(0,0,0,0.15)',
          marginTop: 4, overflow: 'hidden',
        }}>
          {sonuclar.map((b, i) => (
            <button
              key={b.id}
              onClick={() => { onSec(b); temizle(); }}
              style={{
                display: 'flex', alignItems: 'center', gap: 10,
                width: '100%', padding: '9px 12px',
                border: 'none', background: 'none', cursor: 'pointer',
                textAlign: 'left',
                borderBottom: i < sonuclar.length - 1 ? '1px solid #F3F4F6' : 'none',
              }}
            >
              {b.logo_url ? (
                <div style={{ width: 28, height: 28, borderRadius: '50%', overflow: 'hidden', flexShrink: 0 }}>
                  {/* eslint-disable-next-line @next/next/no-img-element */}
                  <img src={b.logo_url} alt="" style={{ width: '100%', height: '100%', objectFit: 'cover' }} />
                </div>
              ) : ilkHarfEl(b.name)}
              <div style={{ overflow: 'hidden' }}>
                <div style={{
                  fontWeight: 700, fontSize: 13, color: '#111',
                  fontFamily: 'system-ui,sans-serif',
                  whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis',
                }}>
                  {b.name}
                </div>
                {b.category && (
                  <div style={{ fontSize: 11, color: '#9CA3AF', fontFamily: 'system-ui,sans-serif' }}>
                    {b.category}
                  </div>
                )}
              </div>
            </button>
          ))}
        </div>
      )}

      {/* Sonuç yok */}
      {sorgu.trim() && !yukleniyor && sonuclar.length === 0 && (
        <div style={{
          background: 'white', borderRadius: 10,
          boxShadow: '0 4px 20px rgba(0,0,0,0.12)',
          marginTop: 4, padding: '12px 14px',
          fontSize: 13, color: '#9CA3AF', fontFamily: 'system-ui,sans-serif',
        }}>
          Sonuç bulunamadı
        </div>
      )}

      <style>{`@keyframes spin { to { transform: rotate(360deg); } }`}</style>
    </div>
  );
}

// ── Yan panel ────────────────────────────────────────────────────────────────

const PANEL_FONT = 'system-ui,-apple-system,sans-serif';

function StarRating({ rating }: { rating: number }) {
  const full = Math.floor(rating);
  const half = rating - full >= 0.3;
  return (
    <span style={{ display: 'inline-flex', alignItems: 'center', gap: 1 }}>
      {[1, 2, 3, 4, 5].map((i) => (
        <span key={i} style={{ color: i <= full ? '#F59E0B' : half && i === full + 1 ? '#F59E0B' : '#D1D5DB', fontSize: 13 }}>
          {i <= full ? '★' : half && i === full + 1 ? '⯨' : '☆'}
        </span>
      ))}
    </span>
  );
}

function PhoneIcon() {
  return (
    <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" style={{ flexShrink: 0, color: '#6B7280' }}>
      <path d="M22 16.92v3a2 2 0 01-2.18 2 19.79 19.79 0 01-8.63-3.07A19.5 19.5 0 013.07 10.8a19.79 19.79 0 01-3.07-8.63A2 2 0 012 0h3a2 2 0 012 1.72c.127.96.361 1.903.7 2.81a2 2 0 01-.45 2.11L6.09 7.91a16 16 0 006 6l1.27-1.27a2 2 0 012.11-.45c.907.339 1.85.573 2.81.7A2 2 0 0122 14.92z"/>
    </svg>
  );
}

function LocationIcon() {
  return (
    <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" style={{ flexShrink: 0, color: '#6B7280' }}>
      <path d="M21 10c0 7-9 13-9 13s-9-6-9-13a9 9 0 0118 0z"/>
      <circle cx="12" cy="10" r="3"/>
    </svg>
  );
}

function SkeletonLine({ width = '100%', height = 14, mb = 8 }: { width?: string | number; height?: number; mb?: number }) {
  return (
    <div style={{
      width, height, borderRadius: 6, background: 'linear-gradient(90deg,#F3F4F6 25%,#E5E7EB 50%,#F3F4F6 75%)',
      backgroundSize: '200% 100%', animation: 'shimmer 1.4s ease-in-out infinite',
      marginBottom: mb,
    }} />
  );
}

function IsletmePaneli({
  isletme,
  onKapat,
}: {
  isletme: HaritaIsletme;
  onKapat: () => void;
}) {
  const [detay, setDetay] = useState<IsletmeDetay | null>(null);
  const [yukleniyor, setYukleniyor] = useState(true);
  const ilkHarf = (isletme.name.charAt(0) || '?').toUpperCase();

  useEffect(() => {
    // Seçili işletme değiştiğinde sunucudan özet çeker — dış sistemle senkronizasyon.
    // eslint-disable-next-line react-hooks/set-state-in-effect
    setDetay(null);
    setYukleniyor(true);
    fetch(`/api/isletme-ozet?id=${encodeURIComponent(isletme.id)}`)
      .then((r) => (r.ok ? r.json() : null))
      .then((d: IsletmeDetay | null) => { setDetay(d); })
      .catch(() => {})
      .finally(() => setYukleniyor(false));
  }, [isletme.id]);

  const coverUrl = detay?.cover_url ?? isletme.cover_url;
  const logoUrl = detay?.logo_url ?? isletme.logo_url;
  const name = detay?.name ?? isletme.name;
  const slug = detay?.slug ?? isletme.slug;
  const category = detay?.category ?? isletme.category;
  const isVerified = detay?.is_verified ?? isletme.is_verified;
  const avgRating = detay?.avg_rating ?? isletme.avg_rating;

  const locationParts = [detay?.district, detay?.city].filter(Boolean);
  const locationStr = locationParts.length > 0 ? locationParts.join(', ') : null;

  return (
    <div
      style={{
        position: 'absolute',
        top: 0,
        right: 0,
        width: 'min(320px, 100%)',
        height: '100%',
        background: 'white',
        boxShadow: '-2px 0 32px rgba(0,0,0,0.15)',
        zIndex: 20,
        display: 'flex',
        flexDirection: 'column',
        overflow: 'hidden',
        fontFamily: PANEL_FONT,
      }}
    >
      {/* ── Hero ── */}
      <div style={{ position: 'relative', height: 160, flexShrink: 0, background: '#F9FAFB' }}>
        {coverUrl ? (
          // eslint-disable-next-line @next/next/no-img-element
          <img src={coverUrl} alt={name} style={{ width: '100%', height: '100%', objectFit: 'cover' }} />
        ) : (
          <div style={{
            width: '100%', height: '100%',
            background: 'linear-gradient(135deg,#7F1D1D 0%,#991B1B 60%,#B91C1C 100%)',
            display: 'flex', alignItems: 'center', justifyContent: 'center',
          }}>
            <span style={{ color: 'white', fontSize: 72, fontWeight: 900, opacity: 0.18, fontFamily: PANEL_FONT }}>
              {ilkHarf}
            </span>
          </div>
        )}

        {/* Gradient overlay for bottom fade */}
        <div style={{
          position: 'absolute', bottom: 0, left: 0, right: 0, height: 60,
          background: 'linear-gradient(to top, rgba(0,0,0,0.25), transparent)',
          pointerEvents: 'none',
        }} />

        {/* Kapat */}
        <button
          onClick={onKapat}
          aria-label="Kapat"
          style={{
            position: 'absolute', top: 10, right: 10,
            width: 30, height: 30, borderRadius: '50%',
            background: 'rgba(0,0,0,0.45)', border: 'none', cursor: 'pointer',
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            color: 'white', fontSize: 18, lineHeight: 1,
            backdropFilter: 'blur(4px)',
          }}
        >
          ×
        </button>
      </div>

      {/* ── Identity strip ── */}
      <div style={{ position: 'relative', zIndex: 1, padding: '0 16px', marginTop: -28, marginBottom: 12, flexShrink: 0, display: 'flex', alignItems: 'flex-end', gap: 10 }}>
        {/* Logo */}
        <div style={{
          width: 56, height: 56, borderRadius: '50%',
          border: '3px solid white', overflow: 'hidden',
          background: '#7F1D1D', flexShrink: 0,
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          boxShadow: '0 2px 12px rgba(0,0,0,0.22)',
        }}>
          {logoUrl ? (
            // eslint-disable-next-line @next/next/no-img-element
            <img src={logoUrl} alt="" style={{ width: '100%', height: '100%', objectFit: 'cover' }} />
          ) : (
            <span style={{ color: 'white', fontSize: 22, fontWeight: 800, fontFamily: PANEL_FONT }}>
              {ilkHarf}
            </span>
          )}
        </div>

        {/* Verified badge */}
        {isVerified && (
          <div style={{ paddingBottom: 4 }}>
            <span style={{
              display: 'inline-flex', alignItems: 'center', gap: 3,
              background: '#DBEAFE', color: '#1D4ED8',
              fontSize: 10, fontWeight: 700, padding: '3px 7px',
              borderRadius: 20, fontFamily: PANEL_FONT, letterSpacing: '0.01em',
            }}>
              <svg width="9" height="9" viewBox="0 0 12 12" fill="currentColor"><path d="M6 0L7.5 4.5H12L8.25 7.25L9.75 12L6 9.25L2.25 12L3.75 7.25L0 4.5H4.5L6 0Z"/></svg>
              Onaylı
            </span>
          </div>
        )}
      </div>

      {/* ── Scrollable content ── */}
      <div style={{ flex: 1, overflow: 'auto', padding: '0 16px' }}>

        {/* Name + category */}
        <h2 style={{ margin: '0 0 2px', fontSize: 18, fontWeight: 800, color: '#111', lineHeight: 1.3, fontFamily: PANEL_FONT }}>
          {name}
        </h2>
        {category && (
          <p style={{ margin: '0 0 12px', fontSize: 12, color: '#9CA3AF', fontFamily: PANEL_FONT, letterSpacing: '0.02em', textTransform: 'uppercase', fontWeight: 600 }}>
            {category}
          </p>
        )}

        {/* Stats row */}
        {(avgRating != null || (detay?.reviews_count != null)) && (
          <div style={{
            display: 'flex', alignItems: 'center', gap: 12,
            marginBottom: 14, padding: '8px 12px',
            background: '#FFF7ED', borderRadius: 10,
            border: '1px solid #FED7AA',
          }}>
            {avgRating != null && (
              <div style={{ display: 'flex', alignItems: 'center', gap: 5, flexShrink: 0 }}>
                <StarRating rating={avgRating} />
                <span style={{ fontWeight: 800, fontSize: 14, color: '#92400E', fontFamily: PANEL_FONT }}>
                  {avgRating.toFixed(1)}
                </span>
              </div>
            )}
            {detay?.reviews_count != null && detay.reviews_count > 0 && (
              <span style={{ fontSize: 12, color: '#92400E', fontFamily: PANEL_FONT, opacity: 0.75 }}>
                {detay.reviews_count.toLocaleString('tr-TR')} yorum
              </span>
            )}
          </div>
        )}

        {/* Loading skeleton */}
        {yukleniyor && !detay && (
          <div style={{ marginBottom: 12 }}>
            <SkeletonLine width="70%" />
            <SkeletonLine width="50%" />
            <SkeletonLine width="85%" />
          </div>
        )}

        {/* Description */}
        {detay?.description && (
          <p style={{
            margin: '0 0 14px', fontSize: 13, color: '#4B5563',
            fontFamily: PANEL_FONT, lineHeight: 1.55,
            display: '-webkit-box', WebkitLineClamp: 3, WebkitBoxOrient: 'vertical' as const,
            overflow: 'hidden',
          }}>
            {detay.description}
          </p>
        )}

        {/* Divider */}
        {detay && (detay.address || detay.phone || locationStr) && (
          <div style={{ height: 1, background: '#F3F4F6', marginBottom: 14 }} />
        )}

        {/* Location chips: city/district */}
        {locationStr && (
          <div style={{ display: 'flex', alignItems: 'flex-start', gap: 8, marginBottom: 10 }}>
            <div style={{ marginTop: 1 }}><LocationIcon /></div>
            <span style={{ fontSize: 13, color: '#374151', fontFamily: PANEL_FONT, lineHeight: 1.45 }}>
              {locationStr}
            </span>
          </div>
        )}

        {/* Address */}
        {detay?.address && (
          <div style={{ display: 'flex', alignItems: 'flex-start', gap: 8, marginBottom: 10 }}>
            <div style={{ marginTop: 2 }}>
              <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" style={{ flexShrink: 0, color: '#6B7280' }}>
                <path d="M3 9l9-7 9 7v11a2 2 0 01-2 2H5a2 2 0 01-2-2z"/>
                <polyline points="9 22 9 12 15 12 15 22"/>
              </svg>
            </div>
            <span style={{ fontSize: 13, color: '#374151', fontFamily: PANEL_FONT, lineHeight: 1.45 }}>
              {detay.address}
            </span>
          </div>
        )}

        {/* Phone */}
        {detay?.phone && (
          <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 10 }}>
            <PhoneIcon />
            <a
              href={`tel:${detay.phone}`}
              style={{ fontSize: 13, color: '#7F1D1D', fontFamily: PANEL_FONT, textDecoration: 'none', fontWeight: 600 }}
            >
              {detay.phone}
            </a>
          </div>
        )}

        <div style={{ height: 8 }} />
      </div>

      {/* ── CTA ── */}
      <div style={{ padding: '12px 16px 20px', flexShrink: 0, borderTop: '1px solid #F3F4F6', background: 'white' }}>
        <a
          href={`/isletme/${slug}`}
          style={{
            display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 6,
            background: '#7F1D1D', color: 'white',
            padding: '12px', borderRadius: 12,
            textDecoration: 'none', fontWeight: 700, fontSize: 14,
            fontFamily: PANEL_FONT, transition: 'background 0.15s',
          }}
        >
          Detayları Gör
          <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round">
            <path d="M5 12h14M12 5l7 7-7 7"/>
          </svg>
        </a>
      </div>

      <style>{`
        @keyframes shimmer {
          0% { background-position: 200% 0; }
          100% { background-position: -200% 0; }
        }
      `}</style>
    </div>
  );
}

// ── Ana bileşen ───────────────────────────────────────────────────────────────

interface Props {
  initialBusinesses: HaritaIsletme[];
}

export function HaritaIstemcisi({ initialBusinesses }: Props) {
  const containerRef = useRef<HTMLDivElement>(null);
  const mapRef = useRef<maplibregl.Map | null>(null);
  const markersRef = useRef<maplibregl.Marker[]>([]);
  const debounceRef = useRef<ReturnType<typeof setTimeout> | null>(null);
  const clusterRef = useRef<Supercluster<HaritaIsletme> | null>(null);
  const rafRef = useRef<number | null>(null);
  const [selected, setSelected] = useState<HaritaIsletme | null>(null);
  const [kategori, setKategori] = useState<string | null>(null);
  const kategoriRef = useRef<string | null>(null);
  useEffect(() => {
    kategoriRef.current = kategori;
  }, [kategori]);

  // Ref: renderClusters'ı her render'da yeniden oluşturmadan click state'ini günceller
  const onClickRef = useRef((_b: HaritaIsletme) => {});
  useEffect(() => {
    onClickRef.current = (b) => setSelected(b);
  }, []);

  const handleSearchSelect = useCallback((isletme: HaritaIsletme) => {
    setSelected(isletme);
    if (mapRef.current) {
      mapRef.current.flyTo({
        center: [isletme.lng, isletme.lat],
        zoom: 16,
        duration: 1000,
      });
    }
  }, []);

  const clearMarkers = useCallback(() => {
    markersRef.current.forEach((m) => m.remove());
    markersRef.current = [];
  }, []);

  const buildClusterIndex = useCallback((businesses: HaritaIsletme[]) => {
    clusterRef.current = new Supercluster<HaritaIsletme>({ radius: 60, maxZoom: CLUSTER_MAX_ZOOM }).load(
      toGeoJSONPoints(businesses.slice(0, MAX_MARKERS)),
    );
  }, []);

  const renderClusters = useCallback(() => {
    const map = mapRef.current;
    const index = clusterRef.current;
    if (!map || !index) return;

    clearMarkers();
    const bounds = map.getBounds();
    const bbox: [number, number, number, number] = [
      bounds.getWest(),
      bounds.getSouth(),
      bounds.getEast(),
      bounds.getNorth(),
    ];
    const zoom = Math.floor(map.getZoom());
    const features = index.getClusters(bbox, zoom);

    features.forEach((feature) => {
      const [lng, lat] = feature.geometry.coordinates;

      if ('cluster' in feature.properties && feature.properties.cluster) {
        const clusterId = feature.properties.cluster_id;
        const pointCount = feature.properties.point_count;
        const el = buildClusterBadgeEl(pointCount);
        el.addEventListener('click', (e) => {
          e.stopPropagation();
          // getClusterExpansionZoom yalnızca kümenin ilk ayrıştığı zoom'u verir; bu tek
          // tıklamada bireysel pin'lere kadar tam açılmayı garanti etmez (özellikle sık
          // paketlenmiş noktalarda). CLUSTER_MAX_ZOOM + 1'e zoom'lamak Supercluster'ın
          // artık hiç kümelemediği (tamamen tekil noktalar döndürdüğü) seviyeyi garantiler.
          const expansionZoom = Math.max(
            index.getClusterExpansionZoom(clusterId),
            CLUSTER_MAX_ZOOM + 1,
          );
          map.flyTo({
            center: [lng, lat],
            zoom: Math.min(expansionZoom, map.getMaxZoom()),
            duration: 500,
          });
        });
        const marker = new maplibregl.Marker({ element: el, anchor: 'center' })
          .setLngLat([lng, lat])
          .addTo(map);
        markersRef.current.push(marker);
        return;
      }

      const business = feature.properties as HaritaIsletme;
      const el = buildRichMarkerEl(business.name, business.logo_url, {
        isVerified: business.is_verified,
        avgRating: business.avg_rating,
        isOpenNow: business.is_open_now,
      });
      el.addEventListener('click', (e) => {
        e.stopPropagation();
        onClickRef.current(business);
      });
      const marker = new maplibregl.Marker({ element: el, anchor: 'bottom' })
        .setLngLat([lng, lat])
        .addTo(map);
      markersRef.current.push(marker);
    });
  }, [clearMarkers]);

  const onMapRender = useCallback(() => {
    if (rafRef.current !== null) return;
    rafRef.current = requestAnimationFrame(() => {
      rafRef.current = null;
      renderClusters();
    });
  }, [renderClusters]);

  const fetchAndUpdate = useCallback(async () => {
    if (!mapRef.current) return;
    const center = mapRef.current.getCenter();
    const kategoriQs = kategoriRef.current ? `&category=${encodeURIComponent(kategoriRef.current)}` : '';
    try {
      const res = await fetch(
        `/api/harita-isletmeler?lat=${center.lat}&lng=${center.lng}&radius=50${kategoriQs}`,
      );
      if (!res.ok) return;
      const data: HaritaIsletme[] = await res.json();
      buildClusterIndex(data);
      renderClusters();
    } catch {
      // sessizce geç
    }
  }, [buildClusterIndex, renderClusters]);

  const onMoveEnd = useCallback(() => {
    if (debounceRef.current) clearTimeout(debounceRef.current);
    debounceRef.current = setTimeout(fetchAndUpdate, FETCH_DEBOUNCE_MS);
  }, [fetchAndUpdate]);

  useEffect(() => {
    if (!containerRef.current || mapRef.current) return;

    ensurePmtilesProtocol();

    const map = new maplibregl.Map({
      container: containerRef.current,
      style: buildPmtilesStyle(),
      center: DEFAULT_CENTER,
      zoom: DEFAULT_ZOOM,
      minZoom: 4,
      maxZoom: 18,
    });

    map.addControl(new maplibregl.NavigationControl(), 'top-right');
    map.addControl(
      new maplibregl.GeolocateControl({
        positionOptions: { enableHighAccuracy: true },
        trackUserLocation: false,
      }),
      'top-right',
    );

    map.on('load', () => {
      buildClusterIndex(initialBusinesses);
      renderClusters();

      if ('geolocation' in navigator) {
        navigator.geolocation.getCurrentPosition(
          (pos) => {
            map.flyTo({
              center: [pos.coords.longitude, pos.coords.latitude],
              zoom: GEOLOCATED_ZOOM,
              duration: 1200,
            });
          },
          () => {},
          { timeout: 8000, maximumAge: 300_000 },
        );
      }
    });

    map.on('moveend', onMoveEnd);
    map.on('move', onMapRender);

    mapRef.current = map;

    return () => {
      if (debounceRef.current) clearTimeout(debounceRef.current);
      if (rafRef.current !== null) cancelAnimationFrame(rafRef.current);
      clearMarkers();
      map.remove();
      mapRef.current = null;
    };
  }, [initialBusinesses, buildClusterIndex, renderClusters, onMoveEnd, onMapRender, clearMarkers]);

  // Kategori değiştiğinde mevcut harita merkezinde yeniden getir (ilk mount'ta atla —
  // initialBusinesses zaten sunucudan filtresiz geldi).
  const kategoriIlkMount = useRef(true);
  useEffect(() => {
    if (kategoriIlkMount.current) { kategoriIlkMount.current = false; return; }
    fetchAndUpdate();
  }, [kategori, fetchAndUpdate]);

  return (
    <div style={{ position: 'relative', width: '100%', height: '100%', minHeight: '500px' }}>
      <div ref={containerRef} style={{ width: '100%', height: '100%' }} />
      <div
        style={{
          position: 'absolute', top: 64, left: 12, right: 12,
          display: 'flex', gap: 8, overflowX: 'auto',
          zIndex: 5, paddingBottom: 2,
        }}
      >
        <KategoriPili etiket="Tümü" secili={kategori === null} onClick={() => setKategori(null)} />
        {HARITA_KATEGORILERI.map((k) => (
          <KategoriPili key={k} etiket={k} secili={kategori === k} onClick={() => setKategori(k)} />
        ))}
      </div>
      <HaritaArama onSec={handleSearchSelect} />
      {selected && (
        <IsletmePaneli isletme={selected} onKapat={() => setSelected(null)} />
      )}
    </div>
  );
}

function KategoriPili({ etiket, secili, onClick }: { etiket: string; secili: boolean; onClick: () => void }) {
  return (
    <button
      type="button"
      onClick={onClick}
      style={{
        flexShrink: 0,
        padding: '7px 14px',
        borderRadius: 999,
        fontSize: 12.5,
        fontWeight: 700,
        fontFamily: 'system-ui,sans-serif',
        whiteSpace: 'nowrap',
        cursor: 'pointer',
        border: secili ? '1px solid transparent' : '1px solid rgba(0,0,0,0.08)',
        background: secili ? 'linear-gradient(135deg,#7F1D1D,#DC2626)' : 'white',
        color: secili ? 'white' : '#3c4148',
        boxShadow: secili ? '0 4px 12px rgba(127,29,29,0.28)' : '0 1px 4px rgba(0,0,0,0.14)',
      }}
    >
      {etiket}
    </button>
  );
}

export default HaritaIstemcisi;
