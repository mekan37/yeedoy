'use client';

import { useEffect } from 'react';

export function KonumIzniIstemcisi() {
  useEffect(() => {
    if (!('geolocation' in navigator)) return;
    navigator.geolocation.getCurrentPosition(
      (pos) => {
        try {
          sessionStorage.setItem(
            'yd_konum',
            JSON.stringify({ lat: pos.coords.latitude, lng: pos.coords.longitude }),
          );
        } catch {
          // sessionStorage unavailable — ignore
        }
      },
      () => {
        // İzin reddedildi veya hata — sessizce geç
      },
      { timeout: 10000, maximumAge: 5 * 60 * 1000 },
    );
  }, []);

  return null;
}
