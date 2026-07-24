'use client';

import { useEffect, useRef } from 'react';
import * as maplibregl from 'maplibre-gl';
import 'maplibre-gl/dist/maplibre-gl.css';
import { ensurePmtilesProtocol, buildPmtilesStyle, buildRichMarkerEl } from '@/src/lib/harita-paylasim';
import type { BusinessLocation } from '@/src/lib/types/business';

export interface LeafletMapProps {
  location: BusinessLocation;
  name: string;
  logo_url?: string | null;
  address?: string | null;
  className?: string;
}

export default function LeafletMap({ location, name, logo_url, className }: LeafletMapProps) {
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
      new maplibregl.Marker({ element: buildRichMarkerEl(name, logo_url), anchor: 'bottom' })
        .setLngLat([lng, lat])
        .addTo(map);
    });

    mapRef.current = map;

    return () => {
      map.remove();
      mapRef.current = null;
    };
  }, [lat, lng, name, logo_url]);

  return (
    <div
      ref={containerRef}
      className={className ?? 'h-48 w-full rounded-xl'}
      aria-label={`${name} konumu`}
    />
  );
}
