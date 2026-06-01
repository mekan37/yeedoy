'use client';

import { useEffect } from 'react';
import { MapContainer, TileLayer, Marker, Popup, useMap } from 'react-leaflet';
import L from 'leaflet';
import 'leaflet/dist/leaflet.css';
import type { BusinessLocation } from '@/src/lib/types/business';

// Fix Leaflet default icon paths broken by webpack/Next.js asset hashing.
// We use our custom SVG marker from /icons/map-marker.svg instead.
const markerIcon = L.icon({
  iconUrl: '/icons/map-marker.svg',
  iconSize: [32, 40],
  iconAnchor: [16, 40],
  popupAnchor: [0, -40],
});

/**
 * Inner component that recenters the map whenever lat/lng props change.
 * Must be rendered inside <MapContainer>.
 */
function RecenterOnChange({ lat, lng }: { lat: number; lng: number }) {
  const map = useMap();
  useEffect(() => {
    map.setView([lat, lng]);
  }, [lat, lng, map]);
  return null;
}

export interface LeafletMapProps {
  location: BusinessLocation;
  name: string;
  address?: string | null;
  className?: string;
}

export default function LeafletMap({ location, name, address, className }: LeafletMapProps) {
  const { lat, lng } = location;

  return (
    <MapContainer
      center={[lat, lng]}
      zoom={15}
      scrollWheelZoom={false}
      className={className ?? 'h-48 w-full rounded-xl'}
      style={{ zIndex: 0 }}
      aria-label={`${name} konumu`}
    >
      <TileLayer
        url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
        attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors'
        maxZoom={19}
      />
      <Marker position={[lat, lng]} icon={markerIcon}>
        <Popup>
          <strong style={{ display: 'block', marginBottom: 2, fontSize: 13 }}>{name}</strong>
          {address && (
            <span style={{ fontSize: 12, color: '#64748b' }}>{address}</span>
          )}
        </Popup>
      </Marker>
      <RecenterOnChange lat={lat} lng={lng} />
    </MapContainer>
  );
}
