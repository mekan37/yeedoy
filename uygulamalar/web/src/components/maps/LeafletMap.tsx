'use client';

import { useEffect, useRef } from 'react';
import maplibregl from 'maplibre-gl';
import 'maplibre-gl/dist/maplibre-gl.css';
import { ensurePmtilesProtocol, buildPmtilesStyle, makeYeedoyMarkerEl } from '@/src/lib/harita-paylasim';
import type { BusinessLocation } from '@/src/lib/types/business';

export interface LeafletMapProps {
  location: BusinessLocation;
  name: string;
  address?: string | null;
  className?: string;
}

export default function LeafletMap({ location, name, address, className }: LeafletMapProps) {
  const { lat, lng } = location;
  const containerRef = useRef<HTMLDivElement>(null);
  const mapRef = useRef<maplibregl.Map | null>(null);

  useEffect(() => {
    if (!containerRef.current || mapRef.current) return;
    ensurePmtilesProtocol();

    const map = new maplibregl.Map({
      container: containerRef.current,
      style: buildPmtilesStyle(),
      center: [lng, lat],
      zoom: 15,
      scrollZoom: false,
      dragRotate: false,
    });

    map.on('load', () => {
      const popup = new maplibregl.Popup({ offset: 20 }).setHTML(
        `<div style="font-family:sans-serif;min-width:120px;">
          <p style="margin:0 0 2px;font-weight:700;font-size:13px">${name}</p>
          ${address ? `<p style="margin:0;font-size:11px;color:#6B7280">${address}</p>` : ''}
        </div>`,
      );
      new maplibregl.Marker({ element: makeYeedoyMarkerEl() })
        .setLngLat([lng, lat])
        .setPopup(popup)
        .addTo(map);
    });

    mapRef.current = map;

    return () => {
      map.remove();
      mapRef.current = null;
    };
  }, [lat, lng, name, address]);

  return (
    <div
      ref={containerRef}
      className={className ?? 'h-48 w-full rounded-xl'}
      aria-label={`${name} konumu`}
    />
  );
}
