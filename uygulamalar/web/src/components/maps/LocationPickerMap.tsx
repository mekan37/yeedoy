'use client';

/**
 * LocationPickerMap — Leaflet-based coordinate picker for the owner/admin panel.
 *
 * Usage:
 *   <LocationPickerMap
 *     initialLat={41.015}
 *     initialLng={28.979}
 *     onChange={(lat, lng) => { ... }}
 *   />
 *
 * The marker is draggable. Each time the user drops it, `onChange` fires with
 * the new coordinates. The component is SSR-safe via its own dynamic() wrapper
 * in LocationPickerMapClient.tsx.
 *
 * If a Google Maps version existed previously, keep it commented out below
 * and swap this component in its place in the form.
 */

import { useCallback, useState } from 'react';
import { MapContainer, TileLayer, Marker, useMapEvents } from 'react-leaflet';
import L from 'leaflet';
import 'leaflet/dist/leaflet.css';

const draggableMarkerIcon = L.icon({
  iconUrl: '/icons/map-marker.svg',
  iconSize: [32, 40],
  iconAnchor: [16, 40],
  popupAnchor: [0, -40],
});

interface LocationPickerMapProps {
  initialLat?: number | null;
  initialLng?: number | null;
  onChange?: (lat: number, lng: number) => void;
  className?: string;
}

/** Invisible component that captures map clicks and updates the marker position. */
function ClickHandler({
  onMove,
}: {
  onMove: (lat: number, lng: number) => void;
}) {
  useMapEvents({
    click(e) {
      onMove(e.latlng.lat, e.latlng.lng);
    },
  });
  return null;
}

const DEFAULT_LAT = 41.015;
const DEFAULT_LNG = 28.979;

export default function LocationPickerMap({
  initialLat,
  initialLng,
  onChange,
  className,
}: LocationPickerMapProps) {
  const [position, setPosition] = useState<[number, number]>([
    initialLat ?? DEFAULT_LAT,
    initialLng ?? DEFAULT_LNG,
  ]);

  const handleMove = useCallback(
    (lat: number, lng: number) => {
      setPosition([lat, lng]);
      onChange?.(lat, lng);
    },
    [onChange],
  );

  return (
    <div className={className}>
      <MapContainer
        center={position}
        zoom={13}
        scrollWheelZoom
        className="location-picker"
        style={{ height: 320, borderRadius: 12, zIndex: 0 }}
        aria-label="Konum seçici harita"
      >
        <TileLayer
          url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
          attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors'
          maxZoom={19}
        />
        <ClickHandler onMove={handleMove} />
        <Marker
          position={position}
          icon={draggableMarkerIcon}
          draggable
          eventHandlers={{
            dragend(e) {
              const latlng = (e.target as L.Marker).getLatLng();
              handleMove(latlng.lat, latlng.lng);
            },
          }}
        />
      </MapContainer>
      <p className="mt-2 text-xs text-muted">
        Haritaya tıkla veya marker&apos;ı sürükle — Enlem: {position[0].toFixed(5)}, Boylam:{' '}
        {position[1].toFixed(5)}
      </p>
    </div>
  );
}
