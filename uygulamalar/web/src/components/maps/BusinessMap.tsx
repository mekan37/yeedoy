'use client';

import dynamic from 'next/dynamic';
import type { BusinessLocation } from '@/src/lib/types/business';

// Leaflet requires the browser's `window` object and must never run on the server.
// dynamic() with ssr: false guarantees the import only executes client-side.
const LeafletMap = dynamic(() => import('./LeafletMap'), {
  ssr: false,
  loading: () => (
    <div
      className="h-48 w-full animate-pulse rounded-xl bg-slate-100"
      aria-hidden="true"
    />
  ),
});

export interface BusinessMapProps {
  location: BusinessLocation;
  name: string;
  address?: string | null;
  className?: string;
}

/**
 * Public-facing business location map.
 *
 * Usage:
 *   <BusinessMap location={{ lat: 41.015, lng: 28.979 }} name="Restoran Adı" address="Adres" />
 *
 * Renders nothing when lat/lng are absent.
 * Leaflet (~40 KB gzip) is lazy-loaded — no impact on initial page SSR.
 */
export function BusinessMap({ location, name, address, className }: BusinessMapProps) {
  if (!location?.lat || !location?.lng) return null;
  return (
    <LeafletMap
      location={location}
      name={name}
      address={address}
      className={className}
    />
  );
}
