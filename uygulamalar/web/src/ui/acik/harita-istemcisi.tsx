'use client';

import { MapContainer, TileLayer, CircleMarker, Popup } from 'react-leaflet';
import 'leaflet/dist/leaflet.css';
import type { HaritaIsletme } from '@/src/lib/veri/harita-okuma';

// NOTE: This component is already behind a dynamic() ssr:false boundary
// in the harita page. Do not use it in Server Components directly.

export function HaritaIstemcisi({ businesses }: { businesses: HaritaIsletme[] }) {
  return (
    <MapContainer
      center={[39.2, 35.3]}
      zoom={6}
      scrollWheelZoom
      style={{ height: '100%', width: '100%', minHeight: 480 }}
      aria-label="Türkiye işletme haritası"
    >
      <TileLayer
        url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
        attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors'
        maxZoom={19}
      />
      {businesses.map((biz) => (
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
              <p style={{ fontSize: 12, color: '#64748b', margin: '0 0 8px' }}>
                {[biz.category, biz.district ?? biz.city].filter(Boolean).join(' · ')}
              </p>
              <a
                href={`/isletme/${biz.slug}`}
                style={{ fontWeight: 900, fontSize: 13, color: '#7f1d1d', textDecoration: 'none' }}
              >
                Detay →
              </a>
            </div>
          </Popup>
        </CircleMarker>
      ))}
    </MapContainer>
  );
}
