'use client';

import { useEffect, useRef, useCallback } from 'react';
import maplibregl from 'maplibre-gl';
import 'maplibre-gl/dist/maplibre-gl.css';
import { ensurePmtilesProtocol, buildPmtilesStyle } from '@/src/lib/harita-paylasim';
import type { HaritaIsletme } from '@/src/lib/veri/harita-okuma';

// Türkiye merkezi — Ankara
const DEFAULT_CENTER: [number, number] = [32.8597, 39.9334];
const DEFAULT_ZOOM = 6;
const FETCH_DEBOUNCE_MS = 500;
const MAX_MARKERS = 150;

interface Props {
  initialBusinesses: HaritaIsletme[];
}

export function HaritaIstemcisi({ initialBusinesses }: Props) {
  const containerRef = useRef<HTMLDivElement>(null);
  const mapRef = useRef<maplibregl.Map | null>(null);
  const markersRef = useRef<maplibregl.Marker[]>([]);
  const debounceRef = useRef<ReturnType<typeof setTimeout> | null>(null);

  const clearMarkers = useCallback(() => {
    markersRef.current.forEach((m) => m.remove());
    markersRef.current = [];
  }, []);

  const addMarkers = useCallback(
    (businesses: HaritaIsletme[]) => {
      if (!mapRef.current) return;
      clearMarkers();

      const limited = businesses.slice(0, MAX_MARKERS);
      limited.forEach((b) => {
        const el = document.createElement('div');
        el.className = 'yeedoy-marker';
        el.style.cssText = `
          width:28px;height:28px;border-radius:50%;
          background:#7F1D1D;border:2px solid white;
          box-shadow:0 1px 4px rgba(0,0,0,.3);
          cursor:pointer;display:flex;align-items:center;justify-content:center;
        `;
        el.innerHTML =
          '<span style="color:white;font-size:12px;font-weight:700">Y</span>';

        const popup = new maplibregl.Popup({ offset: 18 }).setHTML(
          `<div style="font-family:sans-serif;min-width:140px;">
            <p style="margin:0 0 2px;font-weight:600;font-size:13px">${b.name}</p>
            <p style="margin:0;font-size:11px;color:#6B7280">${b.category}</p>
            ${b.avg_rating ? `<p style="margin:4px 0 0;font-size:11px">⭐ ${b.avg_rating.toFixed(1)}</p>` : ''}
            <a href="/b/${b.slug}" style="display:block;margin-top:6px;font-size:11px;color:#7F1D1D;text-decoration:none;font-weight:600">Detaylar →</a>
          </div>`,
        );

        const marker = new maplibregl.Marker({ element: el })
          .setLngLat([b.lng, b.lat])
          .setPopup(popup)
          .addTo(mapRef.current!);

        markersRef.current.push(marker);
      });
    },
    [clearMarkers],
  );

  const fetchAndUpdate = useCallback(async () => {
    if (!mapRef.current) return;
    const center = mapRef.current.getCenter();
    try {
      const res = await fetch(
        `/api/harita-isletmeler?lat=${center.lat}&lng=${center.lng}&radius=50`,
      );
      if (!res.ok) return;
      const data: HaritaIsletme[] = await res.json();
      addMarkers(data);
    } catch {
      // sessizce geç
    }
  }, [addMarkers]);

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
      addMarkers(initialBusinesses);
    });

    map.on('moveend', onMoveEnd);

    mapRef.current = map;

    return () => {
      if (debounceRef.current) clearTimeout(debounceRef.current);
      clearMarkers();
      map.remove();
      mapRef.current = null;
    };
  }, [initialBusinesses, addMarkers, onMoveEnd, clearMarkers]);

  return (
    <div
      ref={containerRef}
      style={{ width: '100%', height: '100%', minHeight: '500px' }}
    />
  );
}

export default HaritaIstemcisi;
