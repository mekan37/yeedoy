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
  logo_url?: string | null;
  address?: string | null;
  className?: string;
}

export function BusinessMap({ location, name, logo_url, address, className }: BusinessMapProps) {
  if (!location?.lat || !location?.lng) return null;
  return (
    <LeafletMap
      location={location}
      name={name}
      logo_url={logo_url}
      address={address}
      className={className}
    />
  );
}
