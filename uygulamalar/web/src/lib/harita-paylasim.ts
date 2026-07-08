import { Protocol } from 'pmtiles';
import { addProtocol, type StyleSpecification } from 'maplibre-gl';
import { layers, namedTheme } from 'protomaps-themes-base';

const PMTILES_URL =
  process.env.NEXT_PUBLIC_YEEDOY_PMTILES_URL ??
  'https://maps.yeedoy.com/turkiye.pmtiles';

let _registered = false;

export function ensurePmtilesProtocol(): void {
  if (typeof window === 'undefined' || _registered) return;
  const protocol = new Protocol();
  addProtocol('pmtiles', protocol.tile as Parameters<typeof addProtocol>[1]);
  _registered = true;
}

export function buildPmtilesStyle(): StyleSpecification {
  return {
    version: 8,
    glyphs:
      'https://protomaps.github.io/basemaps-assets/fonts/{fontstack}/{range}.pbf',
    sprite: 'https://protomaps.github.io/basemaps-assets/sprites/v4/light',
    sources: {
      protomaps: {
        type: 'vector',
        url: `pmtiles://${PMTILES_URL}`,
        attribution: '© OpenStreetMap',
      },
    },
    layers: layers('protomaps', namedTheme('light')) as StyleSpecification['layers'],
  };
}

export function makeYeedoyMarkerEl(): HTMLDivElement {
  const el = document.createElement('div');
  el.style.cssText = `
    width:28px;height:28px;border-radius:50%;
    background:#7F1D1D;border:2px solid white;
    box-shadow:0 2px 6px rgba(0,0,0,.35);
    display:flex;align-items:center;justify-content:center;
    cursor:pointer;
  `;
  el.innerHTML = '<span style="color:white;font-size:11px;font-weight:800">Y</span>';
  return el;
}
