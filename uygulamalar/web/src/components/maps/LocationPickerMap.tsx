'use client';

import { useEffect, useRef, useCallback, useState } from 'react';
import * as maplibregl from 'maplibre-gl';
import 'maplibre-gl/dist/maplibre-gl.css';
import { ensurePmtilesProtocol, buildPmtilesStyle } from '@/src/lib/harita-paylasim';

const DEFAULT_LAT = 41.015;
const DEFAULT_LNG = 28.979;

interface LocationPickerMapProps {
  initialLat?: number | null;
  initialLng?: number | null;
  onChange?: (lat: number, lng: number) => void;
  className?: string;
}

export default function LocationPickerMap({
  initialLat,
  initialLng,
  onChange,
  className,
}: LocationPickerMapProps) {
  const containerRef = useRef<HTMLDivElement>(null);
  const mapRef = useRef<maplibregl.Map | null>(null);
  const markerRef = useRef<maplibregl.Marker | null>(null);
  const onChangeRef = useRef(onChange);
  onChangeRef.current = onChange;

  const [position, setPosition] = useState<[number, number]>([
    initialLat ?? DEFAULT_LAT,
    initialLng ?? DEFAULT_LNG,
  ]);

  const handleMove = useCallback((lat: number, lng: number) => {
    setPosition([lat, lng]);
    onChangeRef.current?.(lat, lng);
  }, []);

  useEffect(() => {
    if (!containerRef.current || mapRef.current) return;
    ensurePmtilesProtocol();

    const startLng = initialLng ?? DEFAULT_LNG;
    const startLat = initialLat ?? DEFAULT_LAT;

    const map = new maplibregl.Map({
      container: containerRef.current,
      style: buildPmtilesStyle(),
      center: [startLng, startLat],
      zoom: 13,
      dragRotate: false,
    });

    map.addControl(new maplibregl.NavigationControl({ showCompass: false }), 'top-right');

    const markerEl = document.createElement('div');
    markerEl.style.cssText = `
      width:32px;height:40px;cursor:grab;
    `;
    markerEl.innerHTML = `
      <svg viewBox="0 0 24 30" xmlns="http://www.w3.org/2000/svg" width="32" height="40">
        <path d="M12 0C7.6 0 4 3.6 4 8c0 5.4 8 22 8 22s8-16.6 8-22c0-4.4-3.6-8-8-8z"
          fill="#7F1D1D" stroke="white" stroke-width="1"/>
        <circle cx="12" cy="8" r="3.5" fill="white"/>
      </svg>`;

    const marker = new maplibregl.Marker({ element: markerEl, draggable: true })
      .setLngLat([startLng, startLat])
      .addTo(map);

    marker.on('dragend', () => {
      const { lat, lng } = marker.getLngLat();
      handleMove(lat, lng);
    });

    map.on('click', (e) => {
      const { lat, lng } = e.lngLat;
      marker.setLngLat([lng, lat]);
      handleMove(lat, lng);
    });

    mapRef.current = map;
    markerRef.current = marker;

    return () => {
      map.remove();
      mapRef.current = null;
      markerRef.current = null;
    };
  // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  return (
    <div className={className}>
      <div
        ref={containerRef}
        style={{ height: 320, borderRadius: 12 }}
        aria-label="Konum seçici harita"
      />
      <p className="mt-2 text-xs text-muted">
        Haritaya tıkla veya işaretçiyi sürükle — Enlem: {position[0].toFixed(5)}, Boylam:{' '}
        {position[1].toFixed(5)}
      </p>
    </div>
  );
}
