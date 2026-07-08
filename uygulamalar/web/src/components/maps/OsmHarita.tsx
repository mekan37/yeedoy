'use client';

import { useEffect, useRef } from 'react';
import maplibregl from 'maplibre-gl';
import 'maplibre-gl/dist/maplibre-gl.css';
import { ensurePmtilesProtocol, buildPmtilesStyle, makeYeedoyMarkerEl } from '@/src/lib/harita-paylasim';

export function OsmHarita({
  lat,
  lng,
  name,
  className,
}: {
  lat: number;
  lng: number;
  name: string;
  className?: string;
}) {
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
      interactive: false,
    });

    map.on('load', () => {
      new maplibregl.Marker({ element: makeYeedoyMarkerEl() })
        .setLngLat([lng, lat])
        .setPopup(new maplibregl.Popup({ offset: 20 }).setText(name))
        .addTo(map);
    });

    mapRef.current = map;

    return () => {
      map.remove();
      mapRef.current = null;
    };
  }, [lat, lng, name]);

  return (
    <div
      ref={containerRef}
      className={className}
      style={{ width: '100%', height: '100%' }}
      aria-label={`${name} haritası`}
    />
  );
}
