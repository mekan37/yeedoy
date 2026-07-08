'use client';

import { useEffect, useRef } from 'react';
import { MapContainer, TileLayer, Marker, useMap } from 'react-leaflet';
import L from 'leaflet';
import 'leaflet/dist/leaflet.css';

const pinIcon = L.icon({
  iconUrl: '/icons/map-marker.svg',
  iconSize: [32, 40],
  iconAnchor: [16, 40],
  popupAnchor: [0, -40],
});

// Konum değişince haritayı kaydıran iç bileşen
function MapUpdater({ center }: { center: [number, number] }) {
  const map = useMap();
  const prev = useRef<[number, number] | null>(null);
  useEffect(() => {
    if (!prev.current || prev.current[0] !== center[0] || prev.current[1] !== center[1]) {
      map.flyTo(center, 13, { duration: 0.8 });
      prev.current = center;
    }
  }, [center, map]);
  return null;
}

export default function KonumGoruntuleyici({ center }: { center: [number, number] }) {
  return (
    <MapContainer
      center={center}
      zoom={13}
      scrollWheelZoom={false}
      zoomControl={false}
      style={{ height: '100%', width: '100%', zIndex: 0 }}
      aria-label="Konum haritası"
    >
      <TileLayer
        url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
        attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a>'
        maxZoom={19}
      />
      <MapUpdater center={center} />
      <Marker position={center} icon={pinIcon} />
    </MapContainer>
  );
}
