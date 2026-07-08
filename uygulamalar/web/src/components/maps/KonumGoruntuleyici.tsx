'use client';

import { useEffect, useRef } from 'react';
import maplibregl from 'maplibre-gl';
import 'maplibre-gl/dist/maplibre-gl.css';
import { ensurePmtilesProtocol, buildPmtilesStyle, makeYeedoyMarkerEl } from '@/src/lib/harita-paylasim';

export default function KonumGoruntuleyici({ center }: { center: [number, number] }) {
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

    map.on('load', () => {
      const marker = new maplibregl.Marker({ element: makeYeedoyMarkerEl() })
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
