'use client';

import dynamic from 'next/dynamic';

// Leaflet requires `window` — must not render on server.
const LocationPickerMap = dynamic(() => import('./LocationPickerMap'), {
  ssr: false,
  loading: () => (
    <div
      className="h-[320px] w-full animate-pulse rounded-xl bg-slate-100"
      aria-hidden="true"
    />
  ),
});

export interface LocationPickerMapClientProps {
  initialLat?: number | null;
  initialLng?: number | null;
  onChange?: (lat: number, lng: number) => void;
  className?: string;
}

/**
 * SSR-safe re-export of LocationPickerMap for use in Server Component trees.
 * Import this in panel forms, not LocationPickerMap directly.
 */
export function LocationPickerMapClient(props: LocationPickerMapClientProps) {
  return <LocationPickerMap {...props} />;
}
