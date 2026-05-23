'use client';

import { useEffect, useRef } from 'react';
import type { HaritaIsletme } from '@/src/lib/veri/harita-okuma';

declare global {
  interface Window {
    L: any; // Leaflet loaded via CDN
  }
}

export function HaritaIstemcisi({ businesses }: { businesses: HaritaIsletme[] }) {
  const containerRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    let map: any = null;

    function mount() {
      if (!containerRef.current || !window.L) return;
      const L = window.L;

      // Prevent double-init if already a map on this element
      if ((containerRef.current as any)._leaflet_id) return;

      map = L.map(containerRef.current, { zoomControl: true }).setView([39.2, 35.3], 6);
      L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
        attribution: '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a>',
        maxZoom: 19,
      }).addTo(map);

      const primaryColor = getComputedStyle(document.documentElement)
        .getPropertyValue('--yd-color-primary')
        .trim() || '#7f1d1d';

      for (const biz of businesses) {
        const marker = L.circleMarker([biz.lat, biz.lng], {
          radius: 10,
          fillColor: primaryColor,
          fillOpacity: 0.92,
          color: '#fff',
          weight: 2,
        });
        const slug = biz.slug;
        const popup = L.popup({ maxWidth: 240 }).setContent(
          `<div style="font-family:system-ui;line-height:1.4;padding:2px 0">
            <p style="font-weight:900;font-size:14px;margin:0 0 2px">${escHtml(biz.name)}</p>
            <p style="font-size:12px;color:#64748b;margin:0 0 8px">${escHtml([biz.category, biz.district ?? biz.city].filter(Boolean).join(' · '))}</p>
            <a href="/isletme/${escHtml(slug)}" style="font-weight:900;font-size:13px;color:#7f1d1d;text-decoration:none">Detay →</a>
          </div>`,
        );
        marker.bindPopup(popup).addTo(map);
      }
    }

    if (!document.querySelector('[data-leaflet-css]')) {
      const link = document.createElement('link');
      link.rel = 'stylesheet';
      link.href = 'https://unpkg.com/leaflet@1.9.4/dist/leaflet.css';
      link.setAttribute('data-leaflet-css', 'true');
      document.head.appendChild(link);
    }

    if (window.L) {
      mount();
    } else {
      const existing = document.querySelector('[data-leaflet-js]');
      if (existing) {
        existing.addEventListener('load', mount);
      } else {
        const script = document.createElement('script');
        script.src = 'https://unpkg.com/leaflet@1.9.4/dist/leaflet.js';
        script.async = true;
        script.setAttribute('data-leaflet-js', 'true');
        script.addEventListener('load', mount);
        document.head.appendChild(script);
      }
    }

    return () => {
      if (map) {
        try { map.remove(); } catch { /* ignore */ }
      }
    };
  }, [businesses]);

  return (
    <div ref={containerRef} className="h-full w-full" style={{ minHeight: 480 }} />
  );
}

function escHtml(str?: string | null) {
  return (str ?? '')
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;');
}
