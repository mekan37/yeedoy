'use client';

import { MapContainer, TileLayer, CircleMarker, Popup } from 'react-leaflet';
import 'leaflet/dist/leaflet.css';
import type { HaritaIsletme } from '@/src/lib/veri/harita-okuma';
import { getPriceLevelFromBusiness } from '@/src/lib/fiyat-seviyesi';

// NOTE: This component is already behind a dynamic() ssr:false boundary
// in the harita-sarmalayici. Do not use it in Server Components directly.

// Türkiye ortası — koordinatlı işletme yoksa varsayılan merkez
const TURKEY_CENTER: [number, number] = [39.2, 35.3];
const TURKEY_ZOOM = 6;

function computeCenter(businesses: HaritaIsletme[]): [number, number] {
  if (businesses.length === 0) return TURKEY_CENTER;
  const latSum = businesses.reduce((s, b) => s + b.lat, 0);
  const lngSum = businesses.reduce((s, b) => s + b.lng, 0);
  return [latSum / businesses.length, lngSum / businesses.length];
}

function computeZoom(businesses: HaritaIsletme[]): number {
  if (businesses.length === 0) return TURKEY_ZOOM;
  // Tek şehirdeyse yaklaştır, çok şehirdeyse uzaklaştır
  const cities = new Set(businesses.map((b) => b.city));
  if (cities.size <= 1) return 13;
  if (cities.size <= 3) return 10;
  return TURKEY_ZOOM;
}

export function HaritaIstemcisi({ businesses }: { businesses: HaritaIsletme[] }) {
  const center = computeCenter(businesses);
  const zoom = computeZoom(businesses);

  if (businesses.length === 0) {
    return (
      <div className="flex h-full w-full flex-col items-center justify-center gap-3 bg-cardAlt">
        <span className="text-3xl" aria-hidden="true">🗺</span>
        <p className="text-sm font-[900] text-textStrong">Haritada gösterilecek işletme bulunamadı</p>
        <p className="text-xs text-muted">Koordinat verisi olan işletmeler burada görünür</p>
      </div>
    );
  }

  return (
    <MapContainer
      center={center}
      zoom={zoom}
      scrollWheelZoom
      style={{ height: '100%', width: '100%', minHeight: 480 }}
      aria-label="Türkiye işletme haritası"
    >
      <TileLayer
        url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
        attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors'
        maxZoom={19}
      />
      {businesses.map((biz) => {
        const { level: priceLevel } = getPriceLevelFromBusiness(biz.priceLevel, biz.medianPriceCents);
        const openLabel =
          biz.isOpenNow === true ? 'Açık' : biz.isOpenNow === false ? 'Kapalı' : null;
        const openColor =
          biz.isOpenNow === true ? '#16a34a' : biz.isOpenNow === false ? '#dc2626' : '#64748b';

        return (
          <CircleMarker
            key={biz.id}
            center={[biz.lat, biz.lng]}
            radius={10}
            pathOptions={{
              fillColor: '#7f1d1d',
              fillOpacity: 0.92,
              color: '#fff',
              weight: 2,
            }}
          >
            <Popup maxWidth={240}>
              <div style={{ fontFamily: 'system-ui', lineHeight: 1.4, padding: '2px 0' }}>
                <p style={{ fontWeight: 900, fontSize: 14, margin: '0 0 2px' }}>
                  {biz.name}
                </p>
                <p style={{ fontSize: 12, color: '#64748b', margin: '0 0 6px' }}>
                  {[biz.category, biz.district ?? biz.city].filter(Boolean).join(' · ')}
                </p>
                {/* Rozet satırı: açık/kapalı + fiyat seviyesi */}
                {(openLabel || priceLevel) ? (
                  <div style={{ display: 'flex', gap: 6, marginBottom: 8, flexWrap: 'wrap' }}>
                    {openLabel ? (
                      <span
                        style={{
                          fontSize: 11,
                          fontWeight: 900,
                          color: '#fff',
                          background: openColor,
                          borderRadius: 6,
                          padding: '2px 7px',
                        }}
                      >
                        {openLabel}
                      </span>
                    ) : null}
                    {priceLevel ? (
                      <span
                        style={{
                          fontSize: 11,
                          fontWeight: 900,
                          color: '#334155',
                          background: '#f1f5f9',
                          border: '1px solid #e2e8f0',
                          borderRadius: 6,
                          padding: '2px 7px',
                        }}
                      >
                        {priceLevel}
                      </span>
                    ) : null}
                  </div>
                ) : null}
                <a
                  href={`/isletme/${biz.slug}`}
                  style={{ fontWeight: 900, fontSize: 13, color: '#7f1d1d', textDecoration: 'none' }}
                >
                  Detay →
                </a>
              </div>
            </Popup>
          </CircleMarker>
        );
      })}
    </MapContainer>
  );
}
