'use client';

import { useEffect, useRef } from 'react';
import * as maplibregl from 'maplibre-gl';
import 'maplibre-gl/dist/maplibre-gl.css';
import { ensurePmtilesProtocol, buildPmtilesStyle, buildRichMarkerEl } from '@/src/lib/harita-paylasim';

interface Props {
  center: [number, number];
  name?: string;
  logo_url?: string | null;
}

export default function KonumGoruntuleyici({ center, name, logo_url }: Props) {
  const containerRef = useRef<HTMLDivElement>(null);
  const mapRef = useRef<maplibregl.Map | null>(null);
  const markerRef = useRef<maplibregl.Marker | null>(null);

  useEffect(() => {
    if (!containerRef.current || mapRef.current) return;
    ensurePmtilesProtocol();

    const map = new maplibregl.Map({
      container: containerRef.current,
      style: buildPmtilesStyle(),
      center: [center[1], center[0]],
      zoom: 13,
      scrollZoom: false,
      dragRotate: false,
    });

    const markerEl = name
      ? buildRichMarkerEl(name, logo_url)
      : (() => {
          const el = document.createElement('div');
          el.innerHTML = `<svg viewBox="0 0 24 30" xmlns="http://www.w3.org/2000/svg" width="28" height="35"><path d="M12 0C7.6 0 4 3.6 4 8c0 5.4 8 22 8 22s8-16.6 8-22c0-4.4-3.6-8-8-8z" fill="#7F1D1D" stroke="white" stroke-width="1"/><circle cx="12" cy="8" r="3.5" fill="white"/></svg>`;
          return el;
        })();

    map.on('load', () => {
      const marker = new maplibregl.Marker({ element: markerEl, anchor: name ? 'bottom' : 'bottom' })
        .setLngLat([center[1], center[0]])
        .addTo(map);
      markerRef.current = marker;
    });

    mapRef.current = map;

    return () => {
      map.remove();
      mapRef.current = null;
      markerRef.current = null;
    };
  // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  // Merkez değişince flyTo ile güncelle
  useEffect(() => {
    const map = mapRef.current;
    const marker = markerRef.current;
    if (!map || !marker) return;
    const lngLat: [number, number] = [center[1], center[0]];
    map.flyTo({ center: lngLat, zoom: 13, duration: 800 });
    marker.setLngLat(lngLat);
  }, [center]);

  return (
    <div
      ref={containerRef}
      style={{ height: '100%', width: '100%' }}
      aria-label="Konum haritası"
    />
  );
}
